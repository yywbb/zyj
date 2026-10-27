#!/usr/bin/env python3
import os
import io
import zipfile
import struct
import hashlib
import zlib
import json
import subprocess

DELTA = 0x9E3779B9
XXTEA_KEY = b"3c883f7813a3ee68"

def to_uint_array(b):
    length = len(b)
    n = (((length - 1) >> 2) + 1)
    return list(struct.unpack(f"<{n}I", b.ljust(n * 4, b"\x00")))

def xxtea_encrypt(data, key):
    # 原版格式: 明文补零到 4 字节对齐, 末尾追加 4 字节(小端)原文长度, 再整体 XXTEA 加密。
    # 引擎解密后按最后一个字取回原文长度, 缺少该长度字会导致脚本静默加载失败。
    orig_len = len(data)
    pad_len = (4 - (orig_len % 4)) % 4
    data = data + b"\x00" * pad_len + struct.pack("<I", orig_len)

    v = to_uint_array(data)
    k = to_uint_array(key)[:4]
    while len(k) < 4: k.append(0)

    n = len(v)
    if n <= 1: return data
    rounds = 6 + 52 // n
    sum_val = 0
    z = v[n - 1]
    for _ in range(rounds):
        sum_val = (sum_val + DELTA) & 0xFFFFFFFF
        e = (sum_val >> 2) & 3
        for p in range(n - 1):
            y = v[p + 1]
            v[p] = (v[p] + (((z >> 5 ^ y << 2) + (y >> 3 ^ z << 4)) ^ ((sum_val ^ y) + (k[(p & 3) ^ e] ^ z)))) & 0xFFFFFFFF
            z = v[p]
        y = v[0]
        v[n - 1] = (v[n - 1] + (((z >> 5 ^ y << 2) + (y >> 3 ^ z << 4)) ^ ((sum_val ^ y) + (k[((n - 1) & 3) ^ e] ^ z)))) & 0xFFFFFFFF
        z = v[n - 1]

    return struct.pack(f"<{len(v)}I", *v)

def xxtea_decrypt(data, key):
    v = to_uint_array(data)
    k = to_uint_array(key)[:4]
    while len(k) < 4: k.append(0)
    n = len(v)
    rounds = 6 + 52 // n
    sum_val = (rounds * DELTA) & 0xFFFFFFFF
    y = v[0]
    for _ in range(rounds):
        e = (sum_val >> 2) & 3
        for p in range(n - 1, 0, -1):
            z = v[p - 1]
            v[p] = (v[p] - (((z >> 5 ^ y << 2) + (y >> 3 ^ z << 4)) ^ ((sum_val ^ y) + (k[(p & 3) ^ e] ^ z)))) & 0xFFFFFFFF
            y = v[p]
        z = v[n - 1]
        v[0] = (v[0] - (((z >> 5 ^ y << 2) + (y >> 3 ^ z << 4)) ^ ((sum_val ^ y) + (k[(0 & 3) ^ e] ^ z)))) & 0xFFFFFFFF
        y = v[0]
        sum_val = (sum_val - DELTA) & 0xFFFFFFFF
    return struct.pack(f"<{n}I", *v)

SRC_APK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "z7_7_4.apk")

def read_script(rel):
    """从原版 APK 解密脚本, 并按末尾长度字截取真实原文(磁盘上的 scripts_decrypted/*.lua 末尾带有填充垃圾, 不能直接使用)。"""
    with zipfile.ZipFile(SRC_APK) as z:
        raw = z.read("assets/scripts/" + rel + ".so")
    d = xxtea_decrypt(raw, XXTEA_KEY)
    return d[:struct.unpack("<I", d[-4:])[0]]

def patch_manifest(raw_bytes):
    data = bytearray(raw_bytes)
    sp_type, sp_size = struct.unpack_from("<II", data, 8)
    string_count, style_count, flags, strings_start, styles_start = struct.unpack_from("<IIIII", data, 16)
    offsets = [struct.unpack_from("<I", data, 36 + 4*i)[0] for i in range(string_count)]
    base = 8 + strings_start

    for i, off in enumerate(offsets):
        pos = base + off
        length = struct.unpack_from("<H", data, pos)[0]
        s = data[pos + 2 : pos + 2 + length*2].decode("utf-16le", errors="ignore")
        if "com.ldfs.zyjyg.muyou" in s:
            new_s = s.replace("com.ldfs.zyjyg.muyou", "com.ldfs.zyjyg.local")
            print(f"  [Manifest] String {i}: {s} -> {new_s}")
            assert len(s) == len(new_s)
            data[pos + 2 : pos + 2 + length*2] = new_s.encode("utf-16le")

    return bytes(data)

def patch_arsc(raw_bytes):
    old_b = "com.ldfs.zyjyg.muyou".encode("utf-16le")
    new_b = "com.ldfs.zyjyg.local".encode("utf-16le")
    assert len(old_b) == len(new_b)
    cnt = raw_bytes.count(old_b)
    print(f"  [ARSC] Found {cnt} occurrences of old package name")
    assert cnt > 0
    return raw_bytes.replace(old_b, new_b)

def patch_dex(raw_bytes):
    data = bytearray(raw_bytes)
    old_slash = b"com/ldfs/zyjyg/muyou"
    new_slash = b"com/ldfs/zyjyg/local"
    old_dot = b"com.ldfs.zyjyg.muyou"
    new_dot = b"com.ldfs.zyjyg.local"
    assert len(old_slash) == len(new_slash)
    assert len(old_dot) == len(new_dot)

    data = bytearray(bytes(data).replace(old_slash, new_slash).replace(old_dot, new_dot))

    # Recalculate SHA1
    new_sha1 = hashlib.sha1(data[32:]).digest()
    data[12:32] = new_sha1

    # Recalculate Adler32
    new_adler = zlib.adler32(data[12:]) & 0xffffffff
    data[8:12] = struct.pack("<I", new_adler)

    print(f"  [DEX] Checksums updated: Adler32={hex(new_adler)}, SHA1={new_sha1.hex()}")
    return bytes(data)

def patch_config_json(raw_bytes):
    cfg = json.loads(raw_bytes.decode("utf-8", errors="ignore"))
    cfg["androidPackageName"] = "com.ldfs.zyjyg.local"
    cfg["isupdate"] = False  # 关闭热更检查与下载
    cfg["isshowlog"] = True  # 开启 Lua 日志
    cfg["isdebug"] = True
    print("  [Config] androidPackageName -> com.ldfs.zyjyg.local, isshowlog -> True, isupdate -> false")
    return json.dumps(cfg, ensure_ascii=False, indent=4).encode("utf-8")

# 引导里"关闭弹窗"类步骤的原始配置是 clickxy1="5000,5000"（热区在屏幕外）+ special="hide"，
# 设计意图是"隐藏引导层、让玩家自由点击"。
# 但 guide.setGuideLayerVisible(false) 只把 rootNode 设为不可见，并不解除触摸拦截；
# 而引导层 touchPriority = -800，恒高于普通窗口的 -200 ~ -500，于是永远先收到触摸，
# 并把"不在热区内"的点击坐标改写成 (-10000,-10000) 继续下传（swallowsTouches=false），
# 结果窗口上的按钮永远点不中 -> 引导卡死在该步骤。
# 修正方式（只改配置数据，不动任何客户端逻辑）：把热区对准该弹窗的"确定"按钮，
# 引导层就会按正常机制把点击重定向到按钮上，流程可继续推进。
GUIDE_CLOSE_STEPS = ("24", "41", "50", "53")
# 反推自 gameConfig: scaleNum=1152/1080, fixH=(topposY-2160)*0.5*scaleNum=36, topposY=2160
# 该值使引导层重定向落点为设备坐标(580,1710)，即"恭喜获得"弹窗确定按钮中心
GUIDE_CONFIRM_XY = "544,1329;"


def patch_guide_step(raw_bytes):
    try:
        data = json.loads(raw_bytes.decode("utf-8"))
    except Exception:
        return raw_bytes
    sec1 = data.get("1")
    if not isinstance(sec1, dict):
        return raw_bytes
    changed = []
    for k in GUIDE_CLOSE_STEPS:
        v = sec1.get(k)
        if isinstance(v, dict) and "5000" in (v.get("clickxy1") or ""):
            v["clickxy1"] = GUIDE_CONFIRM_XY
            changed.append(k)
    if changed:
        print(f"  [Config] guide_step: 修正关闭类步骤热区 {changed} -> {GUIDE_CONFIRM_XY}")
        return json.dumps(data, ensure_ascii=False).encode("utf-8")
    return raw_bytes


def patch_game_server_json(raw_bytes):
    servers = json.loads(raw_bytes.decode("utf-8", errors="ignore"))
    for k, s in servers.items():
        s["ip"] = "127.0.0.1"
        s["port"] = 14600
        s["name"] = "忽而今夏"
    print("  [GameServer] Redirected all server targets to 127.0.0.1:14600")
    return json.dumps(servers, ensure_ascii=False, indent=2).encode("utf-8")

def get_patched_lua_scripts():
    scripts_dir = "/home/linux/games/zyj/scripts_decrypted/scripts"
    patched = {}

    # 1. service_ui.lua (Bypass update popup AND mock direct login to enter button)
    with io.BytesIO(read_script("accbyhttp/service_ui")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    
    # 1a. Bypass versionUpdate in uipost
    t1a = b"local function uipost( t )\n    print(\"\xe7\x99\xbb\xe9\x99\x86\xe5\x85\xac\xe5\x91\x8a\")\n    printT(t)\n\n    local function callback()\n        resourceupdate:checkifneedupdate()\n    end\n\n    if next(t.event) then\n        --todo \xe6\x89\x93\xe5\xbc\x80\xe4\xba\x8b\xe4\xbb\xb6\xe5\xbc\xb9\xe7\xaa\x97\xe5\xbc\xb9\xe7\xaa\x97  resourceCB \xe4\xb8\xba\xe5\x9b\x9e\xe8\xb0\x83\n        gameWindowslogin:openWindow(\"versionUpdate\",t.event,callback)\n    else\n        callback()\n    end\nend"
    r1a = b"local function uipost( t )\n    local function callback()\n        resourceupdate:checkifneedupdate()\n    end\n    callback()\nend"
    assert t1a in d
    d = d.replace(t1a, r1a)

    # 1b. Mock uisdklogin to directly dispatch login success state (type 3)
    t1b = b"function uisdklogin( t )\n    gamedata.sdk:Login()\n    LoginScene:showNode(LoginScene.enterLayerItem.channel_loginnode,true)\nend"
    r1b = b"""function uisdklogin( t )
    print("[LocalMock] \xe7\x9b\xb4\xe6\x8e\xa5\xe5\x88\x86\xe5\x8f\x91\xe6\x9c\xac\xe5\x9c\xb0\xe7\x99\xbb\xe5\xbd\x95\xe6\x80\x81")
    local local_srv = { id = 1, name = "\xe5\xbf\xbd\xe8\x80\x8c\xe4\xbb\x8a\xe5\xa4\x8f", ip = "127.0.0.1", port = 14600, status = "1" }
    local mock_data = {
        type = 3,
        user = "local_dev",
        uid = 10001,
        session = "mock_session_token",
        first = false,
        guid = "mock_guid",
        age = 18,
        onlinetime = 0,
        holidays = 0,
        serverlist = { ["1"] = local_srv },
        recentlist = { ["1"] = local_srv }
    }
    UIResponse(mock_data)
end"""
    assert t1b in d
    d = d.replace(t1b, r1b)
    patched["assets/scripts/accbyhttp/service_ui.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched accbyhttp/service_ui.so (bypassed update & mock direct login)")

    # 2. http_post.lua (Immediate success response without network call)
    with io.BytesIO(read_script("accbyhttp/http_post")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t2 = b"function http_post.checkpost(self)\n\n    UIResponse({type = 9998, log = \""
    r2 = b"function http_post.checkpost(self)\n    print(\"[LocalMock] \xe8\xb7\xb3\xe8\xbf\x87\xe5\x85\xac\xe5\x91\x8a HTTP \xe8\xaf\xb7\xe6\xb1\x82\")\n    UIResponse({type = 80, event = {}})\n    return true\nend\nfunction http_post._old_checkpost(self)\n    UIResponse({type = 9998, log = \""
    assert t2 in d
    d = d.replace(t2, r2)
    patched["assets/scripts/accbyhttp/http_post.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched accbyhttp/http_post.so (offline instant notice response)")

    # 3. http_updateresource.lua
    with io.BytesIO(read_script("accbyhttp/http_updateresource")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t3 = b"function resourcedownload.checkifneedupdate(self)\n\n    if not gamedata.gameconfig.isupdate then\n        self:clear()\n        return\n    end"
    r3 = b"function resourcedownload.checkifneedupdate(self)\n    self:clear()\n    return true\nend\nfunction resourcedownload._old_check(self)\n    if not gamedata.gameconfig.isupdate then\n        self:clear()\n        return\n    end"
    assert t3 in d
    d = d.replace(t3, r3)
    patched["assets/scripts/accbyhttp/http_updateresource.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched accbyhttp/http_updateresource.so (bypassed CDN download)")

    # 4. http_checkpackage.lua
    with io.BytesIO(read_script("accbyhttp/http_checkpackage")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t4 = b"function http_check.checkisvalid(self)\n\n    UIResponse({type = 9998, log = \""
    r4 = b"function http_check.checkisvalid(self)\n    UIResponse({type = 333333})\n    return true\nend\nfunction http_check._old_check(self)\n    UIResponse({type = 9998, log = \""
    assert t4 in d
    d = d.replace(t4, r4)
    patched["assets/scripts/accbyhttp/http_checkpackage.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched accbyhttp/http_checkpackage.so (bypassed signature check)")

    # 5. acccheckpackage.lua
    with io.BytesIO(read_script("acccheckpackage")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t5 = b"function http_check.checkisvalid(self,callback)\n    self.callback = callback\n\n    UIResponse({type = 9998, log = \""
    r5 = b"function http_check.checkisvalid(self,callback)\n    self.callback = callback\n    self:clear()\n    return true\nend\nfunction http_check._old_check(self,callback)\n    self.callback = callback\n    UIResponse({type = 9998, log = \""
    assert t5 in d
    d = d.replace(t5, r5)
    patched["assets/scripts/acccheckpackage.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched acccheckpackage.so (bypassed fallback check)")

    # 6. http_updateServerInfo.lua
    with io.BytesIO(read_script("accbyhttp/http_updateServerInfo")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t6 = b"function resourcedownload.checkifneedupdate(self)\n\n    UIResponse({type = 9998, log = \""
    r6 = b"function resourcedownload.checkifneedupdate(self)\n    self:clear()\n    return true\nend\nfunction resourcedownload._old_check(self)\n    UIResponse({type = 9998, log = \""
    assert t6 in d
    d = d.replace(t6, r6)
    patched["assets/scripts/accbyhttp/http_updateServerInfo.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched accbyhttp/http_updateServerInfo.so (bypassed server info update)")

    # 7. http_entergame.lua (Direct server selection success without HTTP call)
    with io.BytesIO(read_script("accbyhttp/http_entergame")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t7 = b"function http_entergame.entergame(self,params)\n\n    self.geturl = gamedata.sdk.address.entergameAddress"
    r7 = b"function http_entergame.entergame(self,params)\n    print(\"[LocalMock] \xe6\xa8\xa1\xe6\x8b\x9f\xe9\x80\x89\xe6\x9c\x8d\xe6\x88\x90\xe5\x8a\x9f\")\n    local data = { type = 5, uuid = \"local_mock_uuid_10001\", section = 1 }\n    UIResponse(data)\n    return true\nend\nfunction http_entergame._old_entergame(self,params)\n    self.geturl = gamedata.sdk.address.entergameAddress"
    assert t7 in d
    d = d.replace(t7, r7)
    patched["assets/scripts/accbyhttp/http_entergame.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched accbyhttp/http_entergame.so (offline instant entergame response)")

    # 8. http_updateconfig.lua (Bypass section config download)
    with io.BytesIO(read_script("accbyhttp/http_updateconfig")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t8 = b"function resourcedownload.checkifneedupdate(self,params)\n    UIResponse({type = 9998, log2 = \""
    r8 = b"function resourcedownload.checkifneedupdate(self,params)\n    print(\"[LocalMock] \xe8\xb7\xb3\xe8\xbf\x87\xe9\x85\x8d\xe7\xbd\xae\xe4\xb8\x8b\xe8\xbd\xbd\")\n    self.section = params.section\n    self:clearWithNormal()\n    return true\nend\nfunction resourcedownload._old_check(self,params)\n    UIResponse({type = 9998, log2 = \""
    assert t8 in d
    d = d.replace(t8, r8)
    patched["assets/scripts/accbyhttp/http_updateconfig.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched accbyhttp/http_updateconfig.so (offline instant section config)")

    # 9. gameserver.lua (Force GameServer TCP connection to 127.0.0.1:14600)
    with io.BytesIO(read_script("gameserver")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t9 = b"""function ProcessFromGameServer()\n    local gameserver = {\n        host = gamedata.serverlist[tonumber(gamedata.selectserver)].ip,\n        port = gamedata.serverlist[tonumber(gamedata.selectserver)].port, 10\n    }"""
    r9 = b"""function ProcessFromGameServer()\n    print("[LocalMock] \xe5\xbc\xba\xe5\x88\xb6\xe8\xbf\x9e\xe6\x8e\xa5\xe6\x9c\xac\xe5\x9c\xb0 Mock Server 127.0.0.1:14600")\n    local gameserver = {\n        host = "127.0.0.1",\n        port = 14600,\n    }"""
    assert t9 in d, "t9 not found in gameserver"
    d = d.replace(t9, r9)
    patched["assets/scripts/gameserver.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched gameserver.so (forced TCP connect to 127.0.0.1:14600)")

    # 10. log.so (Unmute Lua logging)
    with zipfile.ZipFile(SRC_APK) as z:
        raw = z.read("assets/common_lua/log.so")
    d = xxtea_decrypt(raw, XXTEA_KEY)
    orig_len = struct.unpack("<I", d[-4:])[0]
    code = d[:orig_len].decode("utf-8")
    code = code.replace("function echo(...)\n    if gamedata and not gamedata.isshowlog then return end", "function echo(...)")
    code = code.replace("function echoInfo(fmt, ...)\n    if gamedata and not gamedata.isshowlog then return end", "function echoInfo(fmt, ...)")
    patched["assets/common_lua/log.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched common_lua/log.so (unmuted Lua logging)")

    # 11. UILoadConfig.so (Robust config path resolution)
    code = read_script("UILoadConfig").decode("utf-8")
    old_uicfg = 'local filepath = gWPath .. "config/"..t.section .. "/" .. v .. ".json"\n        gamedata.config[v] = LoadJsonFileToTable(filepath)'
    new_uicfg = '''local relpath = "config/"..t.section .. "/" .. v .. ".json"
        local filepath = CCFileUtils:sharedFileUtils():fullPathForFilename(relpath)
        if filepath == relpath and gWPath then filepath = gWPath .. relpath end
        local ok, cfg = pcall(LoadJsonFileToTable, filepath)
        if ok and cfg then gamedata.config[v] = cfg end'''
    assert old_uicfg in code
    code = code.replace(old_uicfg, new_uicfg)
    patched["assets/scripts/UILoadConfig.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched UILoadConfig.so (robust asset config fallback)")

    # 12. guideControl.so (Defensive fallback to mainScene)
    code = read_script("guideControl").decode("utf-8")
    old_ginit = """function _guide.Init(self,guidedata)
    cclog("_guide.Init")
    self.data = guidedata or self.data
    self.config.section = gamedata.config.guide_section
    self.config.step = gamedata.config.guide_step
    if self._first then
        self._first = false
    end"""
    new_ginit = """function _guide.Init(self,guidedata)
    cclog("_guide.Init")
    self.data = guidedata or self.data
    self.config.section = gamedata.config.guide_section
    self.config.step = gamedata.config.guide_step
    if self._first then
        self._first = false
    end
    if not self.config.step or not self.config.section then
        cclog("[LocalMock] Missing guide_step/section config, jumping directly to mainScene!")
        self.isOnGuide = false
        GameScene:init(mainScene)
        return
    end"""
    assert old_ginit in code
    code = code.replace(old_ginit, new_ginit)

    old_gexec = """function _guide.ExcuteGuide(self,isrecover)
    if not self.isOnGuide then
        return
    end
    local stepConfig = self.config.step[tostring(self.excute.section)][tostring(self.excute.step)]"""
    new_gexec = """function _guide.ExcuteGuide(self,isrecover)
    if not self.isOnGuide then
        return
    end
    local sec_t = self.config.step and self.config.step[tostring(self.excute.section)]
    local stepConfig = sec_t and sec_t[tostring(self.excute.step)]
    if not stepConfig then
        cclog("[LocalMock] Missing stepConfig for sec %s step %s, fallback to mainScene!", tostring(self.excute.section), tostring(self.excute.step))
        self.isOnGuide = false
        GameScene:init(mainScene)
        return
    end"""
    assert old_gexec in code
    code = code.replace(old_gexec, new_gexec)

    patched["assets/scripts/guideControl.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched guideControl.so (defensive fallback on missing steps)")

    return patched


def _disabled_patches():
    """以下补丁已停用 —— 用户要求不改客户端逻辑，改为让服务端忠实复现官方抓包数据。
    保留在此仅作记录。"""
    code = read_script("GameRole").decode("utf-8")
    old_role = """function UIRoleInfoCallBack(uireq)
    print("请求角色信息1001 接收UI请求")"""
    new_role = """function UIRoleInfoCallBack(uireq)
    print("请求角色信息1001 接收UI请求")
    -- [LocalMock] 先把客户端当前的角色状态上报给 Mock 服务端持久化，
    -- 否则服务端回放录制数据时会把等级/银币冲回初始值。
    if gamedata and gamedata.cache and gamedata.cache.role and gamedata.cache.role.level then
        local _r = gamedata.cache.role
        UIRequest({type = 999898, level = _r.level or 0, exp = _r.exp or 0,
                   coin = _r.coin or 0, gold = _r.gold or 0, power = _r.power or 0})
    end
    -- [LocalMock] 登录后客户端用的是主城全量包里的旧数据，不会主动拉角色信息，
    -- 这里强制刷新一次，取回服务端已回填的正确等级/银币。
    if not _G.__zyj_role_refreshed then
        _G.__zyj_role_refreshed = true
        UIRequest({type = 1001, param = "resume"})
    end"""
    assert old_role in code, "old_role not found in GameRole"
    code = code.replace(old_role, new_role)

    # 收到服务端角色数据时，若本地进度更高则保留本地值（服务端回放的是旧录制数据）
    old_netrole = """function NetRoleInfoCallBack(fd)
    print("请求角色信息1001 接收服务器返回数据")
    local result = role_pb.Role()
    result:ParseFromString(fd.rbuf)"""
    new_netrole = """function NetRoleInfoCallBack(fd)
    print("请求角色信息1001 接收服务器返回数据")
    local result = role_pb.Role()
    result:ParseFromString(fd.rbuf)
    -- [LocalMock] 先记录本地已达成进度，稍后取较大值，防止被回放的旧数据冲掉
    local _oldr = (gamedata and gamedata.cache and gamedata.cache.role) or nil
    local _ol = (_oldr and _oldr.level) or 0
    local _oe = (_oldr and _oldr.exp) or 0
    local _oc = (_oldr and _oldr.coin) or 0
    local _og = (_oldr and _oldr.gold) or 0"""
    assert old_netrole in code, "old_netrole not found in GameRole"
    code = code.replace(old_netrole, new_netrole)

    old_roleafter = """    gamedata:RoleData(result, gamedata.role.uuid)
    gamedata.ext.RoleDataReceiveTime = gamedata:time()"""
    new_roleafter = """    gamedata:RoleData(result, gamedata.role.uuid)
    -- [LocalMock] 以本地已达成进度为准（Mock 服务端回放的是录制时的旧数据）
    if _oldr and gamedata.cache.role then
        if _ol > (gamedata.cache.role.level or 0) then gamedata.cache.role.level = _ol end
        if _oe > (gamedata.cache.role.exp or 0) then gamedata.cache.role.exp = _oe end
        if _oc > (gamedata.cache.role.coin or 0) then gamedata.cache.role.coin = _oc end
        if _og > (gamedata.cache.role.gold or 0) then gamedata.cache.role.gold = _og end
    end
    gamedata.ext.RoleDataReceiveTime = gamedata:time()"""
    assert old_roleafter in code, "old_roleafter not found in GameRole"
    code = code.replace(old_roleafter, new_roleafter)

    code += """

-- [LocalMock] 角色状态上报 (999898)
function UIRoleStateReportCallBack(uireq)
    local ids_pb2 = require("ids_pb")
    local d = ids_pb2.Ids()
    table.insert(d.ids, uireq.level or 0)
    table.insert(d.ids, uireq.exp or 0)
    table.insert(d.ids, uireq.coin or 0)
    table.insert(d.ids, uireq.gold or 0)
    table.insert(d.ids, uireq.power or 0)
    return 1, 999898, d:SerializeToString()
end

function NetRoleStateReportCallBack(fd)
    return { type = 999898 }
end
"""
    patched["assets/scripts/GameRole.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched GameRole.so (report role state via 999898)")

    # 14. gameserver.so (注册 999898 的 UI/Net 回调)
    with io.BytesIO(read_script("gameserver")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    # 用延迟查找的包裹函数，避免模块加载顺序导致全局函数尚未定义
    old_ui = b"game_ui_callback = {"
    new_ui = (b"game_ui_callback = {\n"
              b"    [999898] = function(...) return UIRoleStateReportCallBack(...) end,")
    assert old_ui in d, "game_ui_callback not found"
    d = d.replace(old_ui, new_ui, 1)

    old_net = b"game_net_callback = {"
    new_net = (b"game_net_callback = {\n"
               b"    [999898] = function(...) return NetRoleStateReportCallBack(...) end,")
    assert old_net in d, "game_net_callback not found"
    d = d.replace(old_net, new_net, 1)
    patched["assets/scripts/gameserver.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched gameserver.so (registered 999898 role state report)")

    return patched

def find_tool(name):
    """定位 Android 构建工具: 优先 PATH, 其次 ANDROID_HOME/build-tools/<ver>/"""
    exe = name + (".bat" if name == "apksigner" else ".exe")
    for base in os.environ.get("PATH", "").split(os.pathsep):
        cand = os.path.join(base.strip(), exe)
        if os.path.exists(cand):
            return cand
    android_home = os.environ.get("ANDROID_HOME", r"D:\Dev\Env\android")
    bt = os.path.join(android_home, "build-tools")
    if os.path.isdir(bt):
        for ver in sorted(os.listdir(bt), reverse=True):
            cand = os.path.join(bt, ver, exe)
            if os.path.exists(cand):
                return cand
    raise FileNotFoundError(f"未找到 {exe}，请安装 Android build-tools 并加入 PATH")

def run_tool(path, args):
    """执行构建工具（.bat 需要经 cmd /c 启动）"""
    cmd = ["cmd", "/c", path] + args if path.lower().endswith(".bat") else [path] + args
    subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def main():
    base = os.path.dirname(os.path.abspath(__file__))
    src_apk = os.path.join(base, "z7_7_4.apk")
    unaligned_apk = os.path.join(base, "zyj_local_unaligned.apk")
    final_apk = os.path.join(base, "zyj_local.apk")
    keystore = os.path.join(base, "debug.keystore")

    print("[1/4] Preparing patched Lua scripts...")
    patched_lua = get_patched_lua_scripts()

    print("[2/4] Packaging modified APK...")
    if os.path.exists(unaligned_apk):
        os.remove(unaligned_apk)

    with zipfile.ZipFile(src_apk, "r") as zin, zipfile.ZipFile(unaligned_apk, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            # Exclude old signature files
            if item.filename.startswith("META-INF/") and (item.filename.endswith(".SF") or item.filename.endswith(".RSA") or item.filename.endswith(".MF")):
                continue

            # Check if this item is in patched_lua
            if item.filename in patched_lua:
                zout.writestr(item, patched_lua[item.filename])
                continue

            data = zin.read(item.filename)

            if item.filename == "AndroidManifest.xml":
                data = patch_manifest(data)
            elif item.filename == "resources.arsc":
                data = patch_arsc(data)
            elif item.filename == "classes.dex":
                data = patch_dex(data)
            elif item.filename == "assets/config.json":
                data = patch_config_json(data)
            elif item.filename == "assets/GameServer.json":
                data = patch_game_server_json(data)

            zout.writestr(item, data)

        sec5_zip_path = os.path.join(base, "configs_sec5.zip")
        if os.path.exists(sec5_zip_path):
            print("  [Config] Injecting offline JSON configs into APK assets...")
            with zipfile.ZipFile(sec5_zip_path, "r") as zsec:
                count = 0
                for zitem in zsec.infolist():
                    base = os.path.basename(zitem.filename)
                    if base.endswith(".json"):
                        cdata = zsec.read(zitem.filename)
                        if base == "guide_step.json":
                            cdata = patch_guide_step(cdata)
                        zout.writestr(f"assets/config/1/{base}", cdata)
                        zout.writestr(f"assets/config/5/{base}", cdata)
                        count += 1
                print(f"  [Config] Successfully injected {count} configs into assets/config/1 & assets/config/5")

    print("[3/4] Running zipalign...")
    if os.path.exists(final_apk):
        os.remove(final_apk)
    run_tool(find_tool("zipalign"), ["-p", "-f", "4", unaligned_apk, final_apk])
    os.remove(unaligned_apk)

    print("[4/4] Signing APK with apksigner...")
    run_tool(find_tool("apksigner"), [
        "sign",
        "--ks", keystore,
        "--ks-pass", "pass:android",
        "--key-pass", "pass:android",
        final_apk
    ])

    # Verify signature
    apksigner = find_tool("apksigner")
    cmd = ["cmd", "/c", apksigner, "verify", final_apk] if apksigner.lower().endswith(".bat") else [apksigner, "verify", final_apk]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    print("Verification result:\n" + res.stdout)
    print("Build complete! Saved to:", final_apk)

if __name__ == "__main__":
    main()
