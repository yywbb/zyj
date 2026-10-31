#!/usr/bin/env python3
import os
import io
import zipfile
import struct
import hashlib
import zlib
import json
import subprocess
import argparse
import ipaddress
import shutil

from zyj_server.configuration import iter_config_bytes

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

def read_script(rel, folder="scripts"):
    """从原版 APK 解密脚本, 并按末尾长度字截取真实原文(磁盘上的 scripts_decrypted/*.lua 末尾带有填充垃圾, 不能直接使用)。"""
    with zipfile.ZipFile(SRC_APK) as z:
        raw = z.read("assets/" + folder + "/" + rel + ".so")
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


def parse_server_ip(text):
    address = ipaddress.IPv4Address(text)
    if not address.is_private or address.is_loopback or address.is_link_local or address.is_unspecified or address.is_reserved:
        raise ValueError("请使用电脑的局域网 IPv4 地址，不能使用回环或公网地址")
    return str(address)

def patch_game_server_json(raw_bytes, server_ip, accounts):
    original = json.loads(raw_bytes.decode("utf-8"))
    template = next(iter(original.values()))
    servers = {str(i): dict(template, id=i, ip=server_ip, port=14600, name=f"账号 {i}", status="online")
               for i in range(1, accounts + 1)}
    print(f"  [GameServer] {accounts} account slots -> {server_ip}:14600 (no ADB)")
    return json.dumps(servers, ensure_ascii=False, indent=2).encode("utf-8")

def patch_combo_animation_script(code):
    marker = "local posconfig = {"
    assert code.count(marker) == 1
    code = code.replace(marker, '''-- 原包缺少两组新增合体及成员资源；仅兼容战斗显示，不改CID、技能或结算。
local localSkillVisuals = {[13124]=12989,[13125]=12638,[12281]=12517,[12282]=12523,[12283]=12511,[12284]=12415}
local localGeneralVisuals = {[10853]=10517,[10854]=10524,[10855]=10511,[10856]=10415}
local function localBattleSkillAnimation(skill, animationid)
    local animation = skillanimationConfig[tostring(animationid or skill.animationid)]
    local replacement = localSkillVisuals[skill.id]
    if replacement and not CCFileUtils:sharedFileUtils():isFileExist(animation.name.."/"..animation.name..".json") then
        local row = (skill.id==13124 or skill.id==13125) and combskillConfig[tostring(replacement)] or skillConfig[tostring(replacement)]
        animation = skillanimationConfig[tostring(row.animationid)]
    end
    return animation
end
local function localBattleGeneralAnimation(info)
    local row = GeneralConfig[tostring(info.cid)]
    local animation = animationConfig[tostring(row.animationid)]
    local replacement = localGeneralVisuals[row.init_cid] or localGeneralVisuals[info.cid]
    if replacement and not CCFileUtils:sharedFileUtils():isFileExist(animation.name.."/"..animation.name.."_time.json") then
        animation = animationConfig[tostring(GeneralConfig[tostring(replacement)].animationid)]
    end
    return animation
end

local posconfig = {''')
    marker = "animation = animationConfig[tostring(GeneralConfig[tostring(generalInfo.cid)].animationid)]"
    assert code.count(marker) == 1
    code = code.replace(marker, "animation = localBattleGeneralAnimation(generalInfo)")
    marker = "local skillanimation =  skillanimationConfig[tostring(_animationid)]"
    assert code.count(marker) == 1
    code = code.replace(marker, "local skillanimation = localBattleSkillAnimation(skill, _animationid)")
    marker = "    local skillanimation =  skillanimationConfig[tostring(skill.animationid)]"
    assert code.count(marker) == 3
    return code.replace(marker, "    local skillanimation = localBattleSkillAnimation(skill)")


def patch_recharge_script(code):
    start = code.index("function recharge.createlist(self)\n")
    end = code.index("function recharge.setPage_vip(self)\n", start)
    original = code[start:end]
    assert "LuaEventHandler:create(function(fn, myTable, a1, a2)" in original
    assert "r = a2" in original and "self.listview = ui.createLuaTableView({" in original
    render_start = original.index("            local data = self.recharge[a1+1]")
    render_end = original.index("            cellCCB:setPosition(810/2+10, 0)")
    render = original[render_start:render_end]
    payment_start = render.index('                    print("idCardStatus",gamedata.sdk.idCardStatus)')
    payment_end = render.index('                end, CCControlEventTouchUpInside)', payment_start)
    assert 'sdk:isValid()' in render[payment_start:payment_end]
    assert 'UIRequest({type = 115, cid = data.id})' in render[payment_start:payment_end]
    render = render[:payment_start] + '''                    UIRequest({type = 115, cid = data.id})
                    gamedata.music:PlayOptSound("czcg")
''' + render[payment_end:]
    # 充值仅八个可见档位，直接生成节点，避开已发生 SIGSEGV 的原生 tableCellAtIndex 回调。
    replacement = '''function recharge.createlist(self)
    self.infoItems.scroll:removeAllChildrenWithCleanup(true)
    local size = self.infoItems.scroll:getContentSize()
    local height = math.max(size.height, #self.recharge * 190)
    local container = ui.createNode({w = 810, h = height})
    for a1 = 0, #self.recharge - 1 do
        local cellCCB, ccbDocumentControler = CCBReaderLoad("recharge/cell_recharge_info_new", nil, true, "cell_recharge_info_new")
''' + render + '''
        cellCCB:setPosition(810/2+10, height - (a1+1) * 190)
        container:addChild(cellCCB)
    end
    self.listview = CCScrollView:create(size, container)
    self.listview:setDirection(1)
    self.listview:setContentOffset(ccp(0, size.height - height))
    self.infoItems.scroll:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

'''
    code = code[:start] + replacement + code[end:]
    old = 'if self.listview and self.pagetype == "info" then\n        self.listview:reloadData()'
    assert code.count(old) == 1
    return code.replace(old, 'if self.listview and self.pagetype == "info" then\n        self:createlist()')


def patch_login_scene(code):
    enter = "        self:loginGame()\n"
    assert code.count(enter) == 1
    code = code.replace(enter, "        self:showUserInput(11)\n")
    init = "function loginScene.init(self,loginscene,isrelog)\n"
    assert code.count(init) == 1
    code = code.replace(init, init + "    self.localLoginHandlers = false\n    self.localAutoLoginOffered = false\n    self.localLoginPending = false\n")
    select = '        self:showServerList()\n'
    assert code.count(select) == 1
    code = code.replace(select, '        self:showUserInput(11)\n')
    label = '    ui.setLabelString(self.enterLayerItem.touchConstituencyLab, nil, 22)\n'
    assert code.count(label) == 1
    code = code.replace(label, '    ui.setLabelString(self.enterLayerItem.touchConstituencyLab, "切换账号", 22)\n')
    marker = 'end\n\nfunction loginScene.checkOnlineTime(self,first)'
    assert code.count(marker) == 1
    code = code.replace(marker, '    if t then self:offerLocalLogin() end\n' + marker)
    start = code.index("function loginScene.showUserInput(self,requestType)\n")
    end = code.index("function loginScene.egameabout(self)\n", start)
    assert 'acctest:userlogin()' in code[start:end]
    # 登录状态集中在原生场景；只有 1000 认证成功才能保存下一次自动登录凭据。
    return code[:start] + '''function loginScene.offerLocalLogin(self)
    if self.localAutoLoginOffered then return end
    self.localAutoLoginOffered = true
    local defaults = CCUserDefault:sharedUserDefault()
    local password = defaults:getStringForKey("local_password", "")
    if not defaults:getBoolForKey("local_auto_login", false) or #password < 8 or
            #password > 64 or password:find("[^!-~]") then
        self:showUserInput(11)
        return
    end
    self.localAutoLoginPending = true
    runGamePrompt({msg="2秒后自动登录，可点“切换账号”取消"})
    self.rootLayer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2), CCCallFunc:create(function()
        if not self.localAutoLoginPending then return end
        self.localAutoLoginPending = false
        self:startLocalLogin(self.SelectedServer.id, password)
    end)))
end

function loginScene.startLocalLogin(self,account,password)
    if self.localLoginPending then return end
    local selected = {}
    for key,value in pairs(gamedata.serverlist["1"] or gamedata.serverlist[1]) do
        selected[key] = value
    end
    selected.id = account
    selected.name = "账号 " .. tostring(account)
    self.SelectedServer = selected
    gamedata.local_account = account
    gamedata.local_password = password
    gamedata.local_login_failed = false
    self.localLoginPending = true
    local defaults = CCUserDefault:sharedUserDefault()
    defaults:setBoolForKey("local_auto_login", false)
    defaults:flush() -- 失败或进程中断后停在表单，成功才重新启用自动登录。
    self:hideUserInput()
    self:loginGame()
    self.rootLayer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(15), CCCallFunc:create(function()
        if self.localLoginPending then
            self:failLocalLogin("连接失败，请检查电脑服务与局域网后重试。", false)
        end
    end)))
end

function loginScene.rememberLocalLogin(self)
    if not self.localLoginPending or gamedata.local_login_failed then return end
    self.localLoginPending = false
    local defaults = CCUserDefault:sharedUserDefault()
    -- shortcut: 自用局域网凭据保存在设备设置；公网版本需独立令牌与安全存储。
    defaults:setIntegerForKey("local_account", gamedata.local_account)
    defaults:setStringForKey("local_password", gamedata.local_password)
    defaults:setBoolForKey("local_auto_login", true)
    defaults:flush()
end

function loginScene.failLocalLogin(self,message,rejected)
    if gamedata.local_login_failed then return end
    self.localLoginPending = false
    gamedata.local_login_failed = true
    gamedata.local_password = nil
    local defaults = CCUserDefault:sharedUserDefault()
    defaults:setBoolForKey("local_auto_login", false)
    if rejected then defaults:setStringForKey("local_password", "") end
    defaults:flush()
    UIRequest({type=777777}) -- 停止网络线程的自动重连，确认提示后重建登录页。
    loading:exitGame(message, true)
end

function loginScene.showUserInput(self,requestType)
    self.localAutoLoginPending = false
    self:hideUserInput()
    gamedata.local_password = nil
    local defaults = CCUserDefault:sharedUserDefault()
    defaults:setBoolForKey("local_auto_login", false)
    defaults:flush()
    self.requestType = 11
    self.enterLayerItem.inputTitleSpr1:setVisible(false)
    self.enterLayerItem.inputTitleSpr2:setVisible(true)
    self.enterLayerItem.userinputName:setString("")
    self.enterLayerItem.userpassword:setString("")
    ui.setLabelString(self.enterLayerItem.quitLab, nil, 19)
    ui.setLabelString(self.enterLayerItem.determineLab, nil, 19)
    self:showNode(self.enterLayerItem.accountNode,true)
    local noop = function() end
    self.accountInputBox = ui.creatInputEditBoxBylable(self.enterLayerItem.userinputName,
        kEditBoxInputModePhoneNumber, noop, noop, {fontSize=40, fontColor=ccc3(255,255,255),
        nochecksensitive=true, length=4, PlaceHolder="账号编号 1–1000"})
    self.accountInputBox:setText(tostring(self.SelectedServer.id or 1))
    self.accountInputBox:setTouchPriority(-10)
    self.passwordInputBox = ui.creatInputEditBoxBylable(self.enterLayerItem.userpassword,
        kEditBoxInputModeSingleLine, noop, noop, {fontSize=40, fontColor=ccc3(255,255,255),
        nochecksensitive=true, length=64, PlaceHolder="后台设置的密码"})
    self.passwordInputBox:setInputFlag(0) -- PASSWORD；旧版全局常量未导出。
    self.passwordInputBox:registerScriptEditBoxHandler(noop) -- 通用回调会记录输入原文。
    self.passwordInputBox:setTouchPriority(-10)
    if self.SelectedServer.id == defaults:getIntegerForKey("local_account", 1) then
        self.passwordInputBox:setText(defaults:getStringForKey("local_password", ""))
    end
    if self.localLoginHandlers then return end
    self.localLoginHandlers = true
    self.enterLayerItem.userconfirm:addHandleOfControlEvent(function()
        if not self.accountInputBox or not self.passwordInputBox then return end
        local text = self.accountInputBox:getText()
        local account = tonumber(text)
        local password = self.passwordInputBox:getText()
        if not text:match("^[1-9]%d*$") or not account or account > 1000 then
            runGamePrompt({msg="请输入 1–1000 的账号编号"})
            return
        end
        if #password < 8 or #password > 64 or password:find("[^!-~]") then
            runGamePrompt({msg="密码须为 8–64 位英文字母、数字或符号，不含空格"})
            return
        end
        self.passwordInputBox:setText("")
        self:startLocalLogin(account, password)
    end, CCControlEventTouchUpInside)
    self.enterLayerItem.userconcel:addHandleOfControlEvent(function()
        gamedata.local_password = nil
        self:hideUserInput()
        self:showEnter()
    end, CCControlEventTouchUpInside)
end

''' + code[end:]


def patch_friend_copy_scripts():
    code = read_script("ids_pb", "pb").decode("utf-8").replace("\r\n", "\n")
    assert code.count("module('ids_pb')") == 1 and code.count("IDS.fields = {IDS_IDS_FIELD}") == 1
    code = code.replace("module('ids_pb')", "module('localfriendcopy_pb')").replace(".Ids", ".LocalFriendCopyQuery")
    code = code.replace('IDS.name = "Ids"', 'IDS.name = "LocalFriendCopyQuery"')
    code = code.replace("IDS.fields = {IDS_IDS_FIELD}", '''local IDS_HELPERS_FIELD = protobuf.FieldDescriptor()
IDS_HELPERS_FIELD.name = "local_helpers"
IDS_HELPERS_FIELD.full_name = ".LocalFriendCopyQuery.local_helpers"
IDS_HELPERS_FIELD.number = 2
IDS_HELPERS_FIELD.index = 1
IDS_HELPERS_FIELD.label = 1
IDS_HELPERS_FIELD.has_default_value = false
IDS_HELPERS_FIELD.default_value = ""
IDS_HELPERS_FIELD.type = 12
IDS_HELPERS_FIELD.cpp_type = 9
IDS.fields = {IDS_IDS_FIELD, IDS_HELPERS_FIELD}''')
    patched = {"localfriendcopy_pb": code}
    code = read_script("GameFriendCopy").decode("utf-8").replace("\r\n", "\n")
    marker = '\nlocal ids_pb = require("ids_pb")\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + 'local localfriendcopy_pb = require("localfriendcopy_pb")\nlocal friends_pb = require("friends_pb")\n')
    marker = "    local friendcopyData = ids_pb.Ids()"
    assert code.count(marker) == 1
    code = code.replace(marker, "    local friendcopyData = localfriendcopy_pb.Ids()")
    marker = "\n    gamedata:FriendCopies(friendcopyData)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''
    gamedata.cache.localFriendCopyHelpers = {}
    if friendcopyData.local_helpers ~= "" then
        local helpers = friends_pb.Friends()
        helpers:ParseFromString(friendcopyData.local_helpers)
        for _,v in ipairs(helpers.friends) do
            gamedata.cache.localFriendCopyHelpers[v.rid] = {
                rid=v.rid, name=v.name, level=v.level, profile=v.profile, use=v.use,
                title=gameConfig.defautTitleId, iconBox=gameConfig.defautIconBoxId,
                params={{i=v.params.params[1].i}}
            }
        end
    end
''')
    marker = "\n    local friends = table.copy(gamedata.cache.friends.friends)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, "\n    local friends = table.copy(gamedata.cache.localFriendCopyHelpers or {})\n")
    marker = "    gamedata.cache.friends.friends[gamedata.ext.friendcopyattack.help].use = 1"
    assert code.count(marker) == 1
    code = code.replace(marker, '''    local helper = (gamedata.cache.localFriendCopyHelpers or {})[gamedata.ext.friendcopyattack.help]
    if helper then helper.use = 1 end''')
    patched["GameFriendCopy"] = code
    code = read_script("window_friendCopy").decode("utf-8").replace("\r\n", "\n")
    marker = "    ui.setLabelString(self.rootItems.des,nil,49)"
    assert code.count(marker) == 1
    code = code.replace(marker, '    ui.setLabelString(self.rootItems.des,"NPC助战每日一次；补空位，满阵临时替换末位伙伴",49)')
    marker = '    ui.setLabelString(self.rootItems.buttontext1,gameConfig.strings:string_common("popups","addfr"),18)'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "\n    self.rootItems.button1:setVisible(false)")
    patched["window_friendCopy"] = code
    return patched


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

    # 1b. Reuse server selection for local accounts, remembering this device's last choice.
    t1b = b"function uisdklogin( t )\n    gamedata.sdk:Login()\n    LoginScene:showNode(LoginScene.enterLayerItem.channel_loginnode,true)\nend"
    r1b = b"""function uisdklogin( t )
    gamedata.local_password = nil
    print("[LocalMock] \xe7\x9b\xb4\xe6\x8e\xa5\xe5\x88\x86\xe5\x8f\x91\xe6\x9c\xac\xe5\x9c\xb0\xe7\x99\xbb\xe5\xbd\x95\xe6\x80\x81")
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename("LocalGameServer.json")
    local servers = LoadJsonFileToTable(path)
    assert(servers and servers["1"], "Missing local account list")
    local last = CCUserDefault:sharedUserDefault():getIntegerForKey("local_account", 1)
    if last < 1 or last > 1000 then last = 1 end
    local selected = {}
    for key,value in pairs(servers[tostring(last)] or servers["1"]) do selected[key] = value end
    selected.id = last
    selected.name = "\xe8\xb4\xa6\xe5\x8f\xb7 " .. tostring(last)
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
        serverlist = servers,
        recentlist = { ["1"] = selected }
    }
    UIResponse(mock_data)
end"""
    assert t1b in d
    d = d.replace(t1b, r1b)
    marker = b"            uuid = gamedata.uuid,\n"
    assert d.count(marker) == 1
    d = d.replace(marker, marker + b"            local_password = gamedata.local_password,\n")
    patched["assets/scripts/accbyhttp/service_ui.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched accbyhttp/service_ui.so (bypassed update & mock direct login)")

    code = read_script("accbyhttp/LoginScene").decode("utf-8").replace("\r\n", "\n")
    patched["assets/scripts/accbyhttp/LoginScene.so"] = xxtea_encrypt(patch_login_scene(code).encode("utf-8"), XXTEA_KEY)
    code = read_script("accbyhttp/service_net").decode("utf-8").replace("\r\n", "\n")
    marker = "                gamedata.role.uuid = uireq.uuid\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "                gamedata.local_password = uireq.local_password\n")
    patched["assets/scripts/accbyhttp/service_net.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    code = read_script("GameUserValid").decode("utf-8").replace("\r\n", "\n")
    marker = "    table.insert(params.params, param1)\n    if gamedata.reconnect_type then\n"
    assert code.count(marker) == 1
    code = code.replace(marker, '''    table.insert(params.params, param1)
    local credential = params_pb.ParamS.Param()
    credential.s = gamedata.local_password or ""
    table.insert(params.params, credential)
    if gamedata.reconnect_type then
''')
    patched["assets/scripts/GameUserValid.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    code = read_script("GameErrorMessage", "common_lua").decode("utf-8").replace("\r\n", "\n")
    marker = "    local error = initPb(ids_pb, fd)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if error.ids[1] == 1000 then
        return {type = 9997, local_login_failed = true, msg = "登录失败：请检查账号密码、后台启用状态及旧设备是否已退出；连续失败请一分钟后重试。"}
    end
''')
    marker = "    return { type = 9999, errornum = error.ids[2], msg = cnMessage }"
    assert code.count(marker) == 1
    code = code.replace(marker, "    return { type = 9999, errornum = error.ids[2], msg = cnMessage, request_opcode = error.ids[1] }")
    patched["assets/common_lua/GameErrorMessage.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    code = read_script("UILogin").decode("utf-8").replace("\r\n", "\n")
    marker = "function judgeSelectedServerIDValid(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if gamedata.local_login_failed then return end
    if t.location == 0 then LoginScene:rememberLocalLogin() end
''')
    patched["assets/scripts/UILogin.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    code = read_script("UIErrorMessage").decode("utf-8").replace("\r\n", "\n")
    marker = "function UIErrorMessage(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    if AutoCopyServerError then AutoCopyServerError(t) end\n")
    marker = "function UIErrorMessage7(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if t.local_login_failed then
        LoginScene:failLocalLogin(t.msg, true)
        return 0, nil
    end
''')
    patched["assets/scripts/UIErrorMessage.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    code = read_script("UIPrompt").decode("utf-8").replace("\r\n", "\n")
    marker = "function UIPrompt(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    if AutoCopyLocalReject and AutoCopyLocalReject(t) then return end\n")
    for name in ("UIPromptTimeOut", "UIPromptNoSignal"):
        marker = "function " + name + "()\n"
        assert code.count(marker) == 1
        code = code.replace(marker, marker + '''    if LoginScene.localLoginPending then
        LoginScene:failLocalLogin("连接失败，请检查电脑服务与局域网后重试。", false)
        return 0, nil
    end
    if AutoCopyStop then AutoCopyStop("自动推图已停止：网络连接异常") end
''')
    patched["assets/scripts/UIPrompt.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched native login form, credential handoff and login rejection handling")

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
    r7 = b"""function http_entergame.entergame(self,params)
    if not gamedata.local_password then
        LoginScene:showUserInput(11)
        return false
    end
    local account = assert(tonumber(params.sid), "Missing local account")
    local data = { type = 5, uuid = "local_account_" .. tostring(account), section = 1 }
    UIResponse(data)
    return true
end
function http_entergame._old_entergame(self,params)
    self.geturl = gamedata.sdk.address.entergameAddress"""
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

    # 9. gameserver.lua (Use the selected account's LAN endpoint)
    with io.BytesIO(read_script("gameserver")) as f:
        d = f.read().replace(b"\r\n", b"\n")
    t9 = b"""function ProcessFromGameServer()\n    local gameserver = {\n        host = gamedata.serverlist[tonumber(gamedata.selectserver)].ip,\n        port = gamedata.serverlist[tonumber(gamedata.selectserver)].port, 10\n    }"""
    r9 = b"""function ProcessFromGameServer()
    local gameserver = {
        host = gamedata.serverlist[tonumber(gamedata.selectserver)].ip,
        port = gamedata.serverlist[tonumber(gamedata.selectserver)].port,
    }"""
    assert t9 in d, "t9 not found in gameserver"
    d = d.replace(t9, r9)
    marker = b"        UIReqeustClear()\n        if loopret == 999 then\n"
    assert d.count(marker) == 1
    d = d.replace(marker, b"        if loopret == 999 then\n            UIReqeustClear()\n")
    patched["assets/scripts/gameserver.so"] = xxtea_encrypt(d, XXTEA_KEY)
    print("  [Lua] Patched gameserver.so (selected account, direct LAN connection)")

    # 网络线程直接结束认证失败；重连清队列时不能丢掉 UI 的停止请求。
    code = read_script("gameloop2").decode("utf-8").replace("\r\n", "\n")
    marker = "                    UIReqeustClear()\n                    UIRequest_({ type = 1000 })"
    assert code.count(marker) == 1
    code = code.replace(marker, '''                    local request = uiqueue.getrequestfromui()
                    while request do
                        if request.type == 777777 then
                            fd.sock:close()
                            return 777777
                        end
                        request = uiqueue.getrequestfromui()
                    end
                    UIRequest_({ type = 1000 })''')
    marker = "                        uiqueue.setresponsetoui(uirep)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''                        if uirep.local_login_failed then
                            fd.sock:close()
                            return 777777
                        end
''')
    patched["assets/scripts/gameloop2.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

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

    code = patch_recharge_script(read_script("window_recharge").decode("utf-8").replace("\r\n", "\n"))
    patched["assets/scripts/window_recharge.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched window_recharge.so (plain scroll container for recharge rows)")

    code = read_script("logError").decode("utf-8").replace("\r\n", "\n")
    marker = "    errorFunc = {\n"
    assert code.count(marker) == 1 and "local function userMessageErr()" in code
    # 未实现请求只提示；默认刷新主城会再次发送未实现请求，形成错误循环。
    code = code.replace(marker, marker + "        [0] = userMessageErr,\n")
    patched["assets/scripts/logError.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched logError.so (invalid requests prompt without refreshing the page)")

    code = read_script("UIRecharge").decode("utf-8").replace("\r\n", "\n")
    start = code.index("function UIRechargePre(t)\n")
    end = code.index("function UIRechargeSucPre(t)\n", start)
    assert "sdk:Recharge(rechargeTb)" in code[start:end]
    code = code[:start] + '''function UIRechargePre(t)
    print("[LocalMock] 本地模拟支付成功")
    UIRequest({type = 116, order = t.rechargeData["1"].i})
end

''' + code[end:]
    start = code.index("function UIRechargefresh(t)\n")
    end = code.index("\nfunction ", start + 1)
    assert "UIRequest({type = 117, update = true})" in code[start:end]
    code = code[:start] + '''function UIRechargefresh(t)
    UIRequest({type = 1001})
    UIRequest({type = 117, update = true})
    UIRequest({type = 2090, update = true})
    UIRequest({type = 2092, update = true})
    UIRequest({type = 2099})
    UIRequest({type = 7091, update = true})
    UIRequest({type = 7094})
    UIRequest({type = 3643, update = true})
    for page, opcode in pairs({[78]=5000, [87]=5034, [101]=3680, [22]=3682, [169]=8075, [170]=8077, [153]=8026}) do
        local item = GameScene.layers["activity"].module.pageTable[page]
        if item and item.module.show then UIRequest({type = opcode, update = true}) end
    end
end
''' + code[end:]
    start = code.index("function UIMonthCard(t)\n")
    end = code.index("\nfunction UIMonthCardGet(t)", start)
    start = code.index('    if GameScene.layers["activity"].module.openPageTable then\n', start, end)
    assert all(f"type = {opcode}," in code[start:end] for opcode in (3680, 3684, 5531))
    # 保留月卡缓存/页面刷新，移除未实现活动的间接预加载。
    code = code[:start] + "end\n" + code[end:]
    patched["assets/scripts/UIRecharge.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched UIRecharge.so (local simulated payment and persisted entitlement refresh)")

    # 福利查询每次取服务端日/月状态，避免跨日仍使用上一次的已领缓存。
    callbacks = {
        "GameActivityMammon": (("UIActivityMammonQueryCallBack", 2015),),
        "GameEatChicken": (("UIActivityEatChickenQueryCallBack", 2010),),
        "GameActivityReward": (("UIContinue7QueryCallBack1", 214),),
        "GameSignIn": (("UISignIn2StatusCallBack", 3641), ("UILuxurySignInStatusCallBack", 3643)),
        "GameRecharge": (("UIVipStatusCallBack", 300), ("UIGrowPlan2CallBack", 7091)),
        "GameActivityMultipleRebate": (("UIMonthGrowQueryCallBack", 3680), ("UIMonthGrowWelfareQueryCallBack", 3682)),
        "GameGang": (("UIUserGang2PrayQueryCallBack", 2250),),
    }
    for name, replacements in callbacks.items():
        code = read_script(name).decode("utf-8").replace("\r\n", "\n")
        for callback, opcode in replacements:
            start = code.index(f"function {callback}(uireq)\n")
            end = code.index("\nend", start) + len("\nend")
            assert f"return 1, {opcode}, nil" in code[start:end]
            extra = '    gamedata.ext.signinParam = uireq.param or ""\n' if opcode == 3641 else ""
            code = code[:start] + f"function {callback}(uireq)\n{extra}    return 1, {opcode}, nil\nend" + code[end:]
        if name == "GameActivityMammon":
            marker = "    gamedata:Mammon(mammonData)"
            assert code.count(marker) == 1
            code = code.replace(marker, "    gamedata.cache.mammon = {}\n" + marker)
        if name == "GameGang":
            marker = "gamedata.cache.gang2status.totalcontribution+ids.ids[2]"
            assert code.count(marker) == 1
            code = code.replace(marker, "gamedata.cache.gang2status.totalcontribution+ids.ids[1]")
        if name == "GameRecharge":
            start = code.index("function UIUserBuyCallBack(uireq)\n")
            end = code.index("\nfunction NetUserBuyCallBack(fd)", start)
            buy = code[start:end]
            marker = '''    if uireq.count then
        table.insert(UserBuyData.ids, uireq.count)
    end'''
            assert buy.count(marker) == 1
            buy = buy.replace(marker, '''    if uireq.cid == 2 or uireq.cid == 3 then
        table.insert(UserBuyData.ids, uireq.count or 1)
        table.insert(UserBuyData.ids, uireq.gold or 0)
    elseif uireq.count then
        table.insert(UserBuyData.ids, uireq.count)
    end''')
            code = code[:start] + buy + code[end:]
            marker = "    local reward = gamedata:SomethingProcess(SomeThings)\n"
            start = code.index("function NetRechargeResultCallBack(fd)\n")
            pos = code.index(marker, start) + len(marker)
            code = code[:pos] + "    gamedata.ext.isrechare = false\n" + code[pos:]
        patched[f"assets/scripts/{name}.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_guild2_shangxiang").decode("utf-8").replace("\r\n", "\n")
    marker = "    UIRequest({type = 2250})\n"
    assert code.count(marker) == 2
    code = code.replace(marker, '''    self.prayTitles = {}
    for _,name in ipairs({"first", "second", "third"}) do
        self.prayTitles[name] = self.rootItems[name.."Text"]:getString()
    end
''' + marker, 1)
    marker = "    if tonumber(self.status) ~= 0 then"
    assert code.count(marker) == 1
    code = code.replace(marker, '''    if tonumber(self.status) == 0 then
        for _,name in ipairs({"first", "second", "third"}) do
            ui.removeGray("CCControlButton", self.rootItems[name.."Btn"])
            ui.setLabelString(self.rootItems[name.."Text"], self.prayTitles[name], 18)
        end
    end
''' + marker)
    patched["assets/scripts/Layer_guild2_shangxiang.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("window_buyPowerPop").decode("utf-8").replace("\r\n", "\n")
    marker = "function buy.open(self,touchPriority,data,callback)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localVipPending = true\n")
    marker = "        if self.buynum >0 then\n"
    assert code.count(marker) == 1
    code = code.replace(marker, '''        if self.localVipPending then
            runGamePrompt({msg = "正在刷新购买次数，请稍候"})
            return
        end
''' + marker)
    marker = "    self:reload(data,callback)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    UIRequest({type = 300, update = true})\n")
    marker = "function buy.reloadShowData(self)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localVipPending = false\n")
    patched["assets/scripts/window_buyPowerPop.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("GameQiankunlu").decode("utf-8").replace("\r\n", "\n")
    start = code.index("function UIGeneralResolveCallBack2(uireq)\n")
    end = code.index("function  NetGeneralResolveCallBack2(fd)\n", start)
    marker = '''    for k,v in pairs(uireq.fragments) do
        local fragment = GeneralFragmentDataTotal.idnums:add()
        fragment.id = v.cid
        fragment.num = v.num
    end'''
    assert code[start:end].count(marker) == 1
    replacement = '''    for k,v in pairs(uireq.fragments) do
        if not gamedata.config.general[tostring(v.cid)] then
            local fragment = GeneralFragmentDataTotal.idnums:add()
            fragment.id = v.cid
            fragment.num = v.num
        end
    end
    for _,iid in pairs(uireq.ids) do
        local general = GeneralFragmentDataTotal.idnums:add()
        general.id = iid
        general.num = -1
    end'''
    code = code[:start] + code[start:end].replace(marker, replacement) + code[end:]
    patched["assets/scripts/GameQiankunlu.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("GameActivitySecretShop").decode("utf-8").replace("\r\n", "\n")
    start = code.index("function UIActivitySecretShopQueryCallBack(uireq)\n")
    end = code.index("function NetActivitySecretShopQueryCallBack(fd)\n", start)
    assert "return 1, 3650, nil" in code[start:end]
    code = code[:start] + "function UIActivitySecretShopQueryCallBack(uireq)\n    return 1, 3650, nil\nend\n\n" + code[end:]
    patched["assets/scripts/GameActivitySecretShop.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("GameActivityQuery").decode("utf-8").replace("\r\n", "\n")
    marker = "    gamedata.ext.activityPageId = uireq.pageId\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '    if tostring(uireq.page) == "5" and uireq.ischeck ~= 1 then return 1,2000,nil end\n')
    patched["assets/scripts/GameActivityQuery.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_activity_multipleRebate").decode("utf-8").replace("\r\n", "\n")
    start = code.index("        self.pageconfig = {}\n", code.index("function multipleRebate.reloaddata("))
    end = code.index("        self:onStatusNode2(data)", start)
    assert "activationBtnStatus2 ~= 0" in code[start:end]
    # 购买期结束也保留两档预览；未激活不能冒充已购买，更不能清空档位后拼接nil。
    code = code[:start] + code[end:]
    marker = "ui.setLabelString(self.coveritems.getLab, nil, 18)"
    assert code.count(marker) == 1
    code = code.replace(marker, '''local status = self.signInTab.data["activationBtnStatus"..self.page]
    self.coveritems.getButton:setTouchEnabled(status == 2)
    if status == 0 then
        ui.addGray("CCControlButton", self.coveritems.getButton)
        ui.addGray("CCLabelTTF", self.coveritems.getLab)
    end
    ui.setLabelString(self.coveritems.getLab, status == 0 and "未激活" or "领取", 18)''')
    patched["assets/scripts/Layer_activity_multipleRebate.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_activity_welfareMonth").decode("utf-8").replace("\r\n", "\n")
    marker = '    self.deadline = year .. "年"'
    assert code.count(marker) == 1
    code = code.replace(marker, '    self.endAt = os.time({year=year,month=month,day=day,hour=hour,min=min,sec=sec,isdst=false})\n' + marker)
    marker = '\n\t\tif self.receiveStatus.data["btnStatus" .. i] == 0 then'
    assert code.count(marker) == 1
    code = code.replace(marker, '''
        local expired = gamedata:time() >= self.endAt
        self.coveritems["doButton"..i]:setTouchEnabled(not expired)
        if expired then
            ui.setLabelString(self.coveritems["doLab"..i], "已结束", 18)
        elseif self.receiveStatus.data["btnStatus" .. i] == 0 then''')
    patched["assets/scripts/Layer_activity_welfareMonth.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_activity_newcontinuous").decode("utf-8").replace("\r\n", "\n")
    marker = "self.coveritems.desc_muyou:setVisible(true)"
    assert code.count(marker) == 1
    code = code.replace(marker, "self.coveritems.desc_muyou:setVisible(false)")
    marker = "ui.setLabelString(self.coveritems.desc1,nil,1)"
    assert code.count(marker) == 1
    code = code.replace(marker, 'ui.setLabelString(self.coveritems.desc1,"连续登录，可获得 元宝和银币 ！\\n如天数中断，需要重新连续登录。\\n奖励仅限",1)')
    patched["assets/scripts/Layer_activity_newcontinuous.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_activity_peace").decode("utf-8").replace("\r\n", "\n")
    marker = '..(isdouble and " ("..gameConfig.strings:string_common("ui",13)..")" or "")'
    assert code.count(marker) == 1 and code.count("    local isdouble = ui.CheckHuodongByParam(5)\n") == 1
    code = code.replace(marker, "").replace("    local isdouble = ui.CheckHuodongByParam(5)\n", "")
    patched["assets/scripts/Layer_activity_peace.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("window_recruit").decode("utf-8").replace("\r\n", "\n")
    # 恢复原客户端已有的封神令不足时元宝支付分支，与本地扣费选择一致。
    for kind, field in (("One", "count"), ("Ten", "tentaverncount")):
        marker = f'        -- if self.fengshenzhaomuling >= config.{field} then\n'
        start = code.index(marker)
        end = code.index('        -- end\n', start) + len('        -- end\n')
        commented = code[start:end]
        assert f'self.type{kind} = "gold"' in commented
        branch = code.rindex('    elseif self.recruitdata.index == 4 then\n', 0, start)
        active = code[branch:start]
        assert f'self.type{kind} = "gaojizhaomuling"' in active
        code = code[:branch] + '    elseif self.recruitdata.index == 4 then\n' + commented.replace('        -- ', '        ') + code[end:]
    start = code.index('    if self.recruitdata.index == 4 then\n        ui.setLabelString(self.recruitItems.ongoldnum')
    end = code.index('    end\n', start) + len('    end\n')
    code = code[:start] + code[end:]
    marker = '        local config = gamedata.config:getConfigByName("recruit_basic")[tostring(self.onedata.pos)]\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''        if self.onedata.pos == 4 then
            local remaining = self.onedata.generalrecruit[tostring(self.onedata.pos)].propnum
            self.typeOne = remaining >= config.count and "gaojizhaomuling" or "gold"
        end
''')
    patched["assets/scripts/window_recruit.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched window_recruit.so (Fengshen token-first or configured gold cost)")

    code = read_script("GameShop").decode("utf-8").replace("\r\n", "\n")
    # 每次打开重新查询日/周限购；全量礼包响应必须移除已售完的旧缓存。
    for callback, cache, opcode in (("UIshopQueryCallback", "props", 3200), ("UIGiftBagQueryCallback", "giftbags", 3210)):
        start = code.index(f"function {callback}(uireq)\n")
        end = code.index("\nend", start) + len("\nend")
        assert f"next(gamedata.cache.shop.{cache})" in code[start:end]
        code = code[:start] + f"function {callback}(uireq)\n    return 1, {opcode}, nil\nend" + code[end:]
    for marker, cache in (("    gamedata:ShopProps(shopData.ids)", "props"), ("    gamedata:GiftBags(shopData.items)", "giftbags")):
        assert code.count(marker) == 1
        code = code.replace(marker, f"    gamedata.cache.shop.{cache} = {{}}\n" + marker)
    patched["assets/scripts/GameShop.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched GameShop.so (refresh account purchase limits and replace full lists)")

    code = read_script("GameRank").decode("utf-8").replace("\r\n", "\n")
    marker = "    table.insert(idsData.ids, uireq.num or 50)"
    assert code.count(marker) == 2
    code = code.replace(marker, marker + "\n    if uireq.activityRankId then table.insert(idsData.ids, uireq.activityRankId) end")
    marker = "        players=gamedata:players(playersData.players)"
    assert code.count(marker) == 2
    code = code.replace(marker, marker + '''
        if gamedata.ext.rankquery.method == 0 then
            for i,v in ipairs(players) do
                local a = gamedata:artifactData(v.params)
                v.rank, v.score = gamedata.ext.rankquery.pos + i - 1, a.score
                v.server, v.server_name = "本地", "局域网"
                v.artifact = {id=a.iid,cid=a.cid,builder_name=a.name,level1=a.level1,
                    attr1_value=a.attr1,attr2_value=a.attr2,attr3_value=a.levelHP,
                    attr4_value=a.levelAttack,attr5_value=a.levelDef,authenticate=a.isChecked,
                    skill1_cid=a.skill1,skill2_cid=a.skill2,skill3_cid=a.skill3,
                    jewel1=a.jewel1,jewel2=a.jewel2,jewel3=a.jewel3,jewel4=a.jewel4,
                    resonance1_id=a.resonanceActiveId1,resonance2_id=a.resonanceActiveId2,
                    resonance3_id=a.resonanceActiveId3,redskill_num=a.resonanceSkillNum}
            end
        end''')
    patched["assets/scripts/GameRank.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_rank2").decode("utf-8").replace("\r\n", "\n")
    assert code.count('local http_artifact_rank = require("http_artifact_rank")') == 1
    code = code.replace('local http_artifact_rank = require("http_artifact_rank")', "")
    start = code.index('        if self.selectpage == "artifact" then\n')
    end = code.index('        config.changed =false', start)
    assert "http_artifact_rank:getdata(cb)" in code[start:end]
    code = code[:start] + "        UIRequest({type = 3500, method = config.method, pos = 1, num = 50})\n" + code[end:]
    marker = '''    if config.changed or not config.data then
        UIRequest({type = 3500, method = config.method, pos = 1, num = 50})
        config.changed =false
    else
        self:ReloadData()
    end'''
    assert code.count(marker) == 1
    code = code.replace(marker, '''    config.myrank = nil
    config.mydata = nil
    UIRequest({type = 3500, method = config.method, pos = 1, num = 50})''')
    start = code.index("    if GameScene.roleinfo.id < 1000000 then")
    end = code.index("    if data and next(data) then", start)
    code = code[:start] + code[end:]
    code = code.replace("本排行榜为跨服，每小时刷新一次", "本地真实神器积分榜，重新打开刷新")
    code = code.replace("本排行榜每5分钟刷新一次", "本地已保存成绩，重新打开刷新")
    patched["assets/scripts/Layer_rank2.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("UIRank").decode("utf-8").replace("\r\n", "\n")
    marker = '    elseif GameScene.layers["ranklist"].show then\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''        if t.method == 0 then
            GameScene.layers["ranklist"].module:setMyArtifactData(t.players)
        end
''', 1)
    patched["assets/scripts/UIRank.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    path = "assets/scripts/GameActivityQuery.so"
    raw = xxtea_decrypt(patched[path], XXTEA_KEY)
    code = raw[:struct.unpack("<I", raw[-4:])[0]].decode("utf-8")
    marker = '        elseif v.id == 2 then    '
    assert code.count(marker) == 2
    code = code.replace(marker, '''        elseif v.id == 5601 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata.localRankOpenedAt = ids.ids[1]
''' + marker, 1)
    marker = "return {type=2000,status=UIActivityQueryReponse(),"
    assert code.count(marker) == 1
    code = code.replace(marker, "return {type=2000,localRankOpenedAt=gamedata.localRankOpenedAt,status=UIActivityQueryReponse(),")
    marker = "return 0,2000,{type=2000,status=UIActivityQueryReponse(),"
    assert code.count(marker) == 1
    code = code.replace(marker, "return 0,2000,{type=2000,localRankOpenedAt=gamedata.localRankOpenedAt,status=UIActivityQueryReponse(),")
    patched[path] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("UIActivity").decode("utf-8").replace("\r\n", "\n")
    marker = "function UIActivityQuery(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    GameScene.localRankOpenedAt = t.localRankOpenedAt or GameScene.localRankOpenedAt\n")
    patched["assets/scripts/UIActivity.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name in ("newrank", "powerRank", "sigilPowerRank", "powerGrowthRank", "powerGrowthRank_x1", "powerGrowthRank_x2",
                 "magicWeaponRank", "copyRank", "shieldRank", "wingRank", "minggeRank", "partnerPowerRank", "artifactRank"):
        script = "Layer_activity_" + name
        code = read_script(script).decode("utf-8").replace("\r\n", "\n")
        assert "GameScene.roleinfo.servertime" in code
        start = code.index('    if self.coveritems.time and gamedata.config.activity_time[self.panelID]["open_type"]')
        end = code.index('    self.isEnd = (timediff < 0)', start)
        code = code[:start] + '''    local opened = GameScene.localRankOpenedAt
    if opened then
        local days = gamedata.config.activity_time[self.panelID].continued_time
        timediff = (math.floor((opened+28800)/86400)+days)*86400-28800-gamedata:time()
    end

''' + code[end:]
        assert "self.isEnd = (timediff < 0)" in code
        code = code.replace("self.isEnd = (timediff < 0)", "self.isEnd = (timediff <= 0)")
        patched[f"assets/scripts/{script}.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("GameRob").decode("utf-8").replace("\r\n", "\n")
    marker = '    gamedata.sortData(t, "quality","cid")'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''
    -- 引导固定点击首行，开放更多宝物不能挤走搜神记。
    for i,v in ipairs(t) do
        if v.cid == 26102 then
            table.remove(t,i)
            table.insert(t,1,v)
            break
        end
    end''')
    marker = "local  isautoxh = uireq.isautoxh or 0"
    assert code.count(marker) == 1
    code = code.replace(marker, "local isautoxh = (uireq.isautoxh and uireq.isautoxh ~= 0) and 1 or 0")
    marker = "local totalenergy = energy1*20 + energy2*10"
    assert code.count(marker) == 1
    code = code.replace(marker, 'local totalenergy = energy1*tonumber(gamedata.config.props["20020"].param1) + energy2*tonumber(gamedata.config.props["20015"].param1)')
    for old, new in (("gamedata.ext.robrequest.cid and #reward >2", "gamedata.ext.robrequest.cid"),
                     ("gamedata.ext.robrequest.cid and not get and #v >2", "gamedata.ext.robrequest.cid and not get")):
        assert code.count(old) == 1
        code = code.replace(old, new)
    marker = "    for k,v in ipairs(reward) do\n        for kv,vv in ipairs(v) do"
    assert code.count(marker) == 1
    code = code.replace(marker, '''    for k,v in ipairs(reward) do
        coin[k], rob[k] = {cid=1000,num=0}, {cid=20255,num=0}
        for kv,vv in ipairs(v) do''')
    for old, new in (("table.insert(coin,vv)", "coin[k] = vv"), ("table.insert(rob,vv)", "rob[k] = vv")):
        assert code.count(old) == 1
        code = code.replace(old, new)
    patched["assets/scripts/GameRob.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("window_robresult").decode("utf-8").replace("\r\n", "\n")
    marker = "table.getTableLength(self.configdata.rob)"
    assert code.count(marker) == 2
    code = code.replace(marker, "self.configdata.energy")
    patched["assets/scripts/window_robresult.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("battleReportConvert").decode("utf-8").replace("\r\n", "\n")
    marker = "skilljson and skilljson.damage[tostring(ccbindex)] or nil"
    assert code.count(marker) == 1
    # 部分群攻只有六份目标时序，第七阵位仍须处理实际伤害和魔罩。
    code = code.replace(marker, 'skilljson and (skilljson.damage[tostring(ccbindex)] or skilljson.damage["1"]) or nil')
    code = patch_combo_animation_script(code)
    patched["assets/scripts/battleReportConvert.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("GameCopy").decode("utf-8").replace("\r\n", "\n")
    marker = '''    local challenge = 1
    if gamedata.ext.copyattackwipe.method == 1 then
        challenge = config[tostring(map)][tostring(point)].challenge - copy[map].points[point].kill
        challenge = math.min(challenge,math.floor(gamedata.cache.role.stamina/config[tostring(map)][tostring(point)].physical))
    end'''
    assert code.count(marker) == 1
    code = code.replace(marker, '''    -- 次数取已结算的将领经验，不能按过期的客户端体力重算。
    local challenge = math.floor(copyAttackResultPb.exp.generals[1].exp/config[tostring(map)][tostring(point)].xp)''')
    start = code.index("function UICopyAttack2Callback(uireq)")
    end = code.index("function UICopyAll3StarRewardCallback(uireq)", start)
    attack = code[start:end]
    marker = "    gamedata.ext.copyattack = {map = uireq.map, point = uireq.point }"
    assert attack.count(marker) == 1
    attack = attack.replace(marker, "    gamedata.ext.copyattack = {map = uireq.map, point = uireq.point, local_auto_copy = uireq.local_auto_copy}")
    for marker in ('msgtype = "shortphysical", param = gamedata.cache.props',
                   'msgtype = "shortCopyChallenge" , msg = "挑战次数不足！"'):
        assert attack.count(marker) == 1
        attack = attack.replace(marker, marker + ', localAutoCopy = uireq.local_auto_copy')
    marker = "    t.point = point\n"
    assert attack.count(marker) == 1
    attack = attack.replace(marker, marker + '''    t.localAutoCopy = gamedata.ext.copyattack.local_auto_copy
    t.localAutoStamina = gamedata.cache.role.stamina
''')
    code = code[:start] + attack + code[end:]
    patched["assets/scripts/GameCopy.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("UICopy").decode("utf-8").replace("\r\n", "\n")
    marker = "function UICopyAttack2(t)\n"
    assert code.count(marker) == 1
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "client_patches", "auto_copy.lua"), encoding="utf-8") as source:
        auto_copy = source.read()
    code = code.replace(marker, auto_copy + "\n" + marker + "    if AutoCopyHandle(t) then return end\n")
    patched["assets/scripts/UICopy.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_copy_list").decode("utf-8").replace("\r\n", "\n")
    marker = "    self:setParam(param)\n    self:reloaddata()\nend\n"
    assert code.count(marker) == 1
    code = code.replace(marker, "    self:setParam(param)\n    self:reloaddata()\n    if self.datatype == \"normal\" then AutoCopyAttach(self,toppos) end\nend\n")
    marker = "function copymap.clear(self)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    AutoCopyDetach(self)\n")
    for marker in ("function copymap.wipeFunc(self,data,method)\n", "    item.explore:addHandleOfControlEvent(function()\n",
                   '        self.rootItems["r_button"..i]:addHandleOfControlEvent(function()\n'):
        assert code.count(marker) == 1
        indent = "    " if marker.startswith("function") else "        " if marker.startswith("    item") else "            "
        code = code.replace(marker, marker + indent + "if AutoCopyBlockManual() then return end\n")
    patched["assets/scripts/Layer_copy_list.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("battlegeneral").decode("utf-8").replace("\r\n", "\n")
    start = code.index("function general.dodgeAction(self,data)")
    end = code.index("\nfunction general.addOneDamageEffect", start)
    dodge = code[start:end]
    assert dodge.count("self.SkeletonNode2 = CCNode:create()") == 1
    assert dodge.count("self.skeleton2 = CCSkeletonAnimation:create(") == 1
    dodge = dodge.replace("self.SkeletonNode2", "ghostNode").replace("self.skeleton2", "ghost")
    dodge = dodge.replace("    ghostNode = CCNode:create()", "    -- 残影与回调按次持有，旧闪避不能删除新残影。\n    local ghostNode = CCNode:create()")
    dodge = dodge.replace("    ghost = CCSkeletonAnimation:create(", "    local ghost = CCSkeletonAnimation:create(")
    marker = "self.SkeletonNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.15)"
    assert dodge.count(marker) == 1
    dodge = dodge.replace(marker, "ghostNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.15)")
    code = code[:start] + dodge + code[end:]
    patched["assets/scripts/battlegeneral.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("window_robonekeyresult").decode("utf-8").replace("\r\n", "\n")
    assert code.count("0.5*(i-1)") == 1 and code.count("您的精力值不足，无法继续挑战") == 1
    code = code.replace("0.5*(i-1)", "math.min(0.1*(i-1),3)")
    code = code.replace("您的精力值不足，无法继续挑战", "本批已结束，未集齐可继续挑战（每批最多100次）")
    patched["assets/scripts/window_robonekeyresult.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("GameMails").decode("utf-8").replace("\r\n", "\n")
    start = code.index("    if next(gamedata.cache.mails) and not uireq.update then")
    end = code.index("\nend", start)
    code = code[:start] + "    return 1, 3100, nil\n" + code[end:]
    marker = "    gamedata:Mails(mailsData)"
    assert code.count(marker) == 1
    code = code.replace(marker, "    gamedata.cache.mails = {}\n" + marker)
    patched["assets/scripts/GameMails.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("gamedata").decode("utf-8").replace("\r\n", "\n")
    start = code.index("function gamedata.Props(self,propsdata)")
    end = code.index("\nend", start) + len("\nend")
    assert "self.cache.props = {}" in code[start:end]
    code = code[:start] + '''function gamedata.Props(self,propsdata)
    local props = {}
    self.cache.props = {}
    self.cache.petsfragment = {}
    for _,v in ipairs(propsdata) do
        if v.id >= 91001 and v.id <= 92000 then
            self:updatePetsFragment({cid=v.id,num=v.num})
        else
            self.cache.props[v.id] = self:propData(v)
            table.insert(props,self.cache.props[v.id])
        end
    end
    return props
end''' + code[end:]
    patched["assets/scripts/gamedata.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("window_devourSelect").decode("utf-8").replace("\r\n", "\n")
    assert code.count('battleString = "已上阵"') == 1
    code = code.replace('battleString = "已上阵"', 'battleString = "休息"')
    marker = '''                    -- print("not...change==")
                    gameWindows:closeWindow("devourSelect")'''
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '\n                    UIRequest({type = 1043, iid = 0})')
    patched["assets/scripts/window_devourSelect.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_mochonglead").decode("utf-8").replace("\r\n", "\n")
    marker = "function mochonglead.shiftPage(self, page)\n"
    assert code.count(marker) == 1 and code.count("    local page = page or self.selectpage") == 1
    code = code.replace("    local page = page or self.selectpage", "")
    code = code.replace(marker, marker + '''    local page = page or self.selectpage
    if (page == "shengji" or page == "jinjie") and (not self.allPetsData or self.allPetsData.iid == 0) then
        runGamePrompt({msg = self.PromptString.notmochong})
        return
    end
''')
    patched["assets/scripts/Layer_mochonglead.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_activity").decode("utf-8").replace("\r\n", "\n")
    marker = "[57] = { request = 46111,"
    assert code.count(marker) == 1
    code = code.replace(marker, "[57] = { request = 300,")
    old = """function activity.createPagesExt(self)
    self:createOnePage(self.presentPage+1)
    self:createOnePage(self.presentPage-1)
end"""
    assert code.count(old) == 1
    # 点当前页不应初始化相邻活动；实际切页仍由 createPages 加载并查询。
    code = code.replace(old, "function activity.createPagesExt(self)\nend")
    patched["assets/scripts/Layer_activity.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched Layer_activity.so (query activities only when selected)")

    for name, code in patch_friend_copy_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

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
    names = (name, name + (".bat" if name == "apksigner" else ".exe"))
    if os.name == "nt":
        names = names[::-1]
    for executable in names:
        found = shutil.which(executable)
        if found:
            return found
    android_home = os.environ.get("ANDROID_HOME", r"D:\Dev\Env\android")
    bt = os.path.join(android_home, "build-tools")
    if os.path.isdir(bt):
        for ver in sorted(os.listdir(bt), reverse=True):
            for executable in names:
                cand = os.path.join(bt, ver, executable)
                if os.path.isfile(cand):
                    return cand
    raise FileNotFoundError(f"未找到 {name}，请安装 Android build-tools 并加入 PATH 或设置 ANDROID_HOME")

def run_tool(path, args):
    """执行构建工具（.bat 需要经 cmd /c 启动）"""
    cmd = ["cmd", "/c", path] + args if path.lower().endswith(".bat") else [path] + args
    subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def main(argv=None):
    parser = argparse.ArgumentParser(description="构建局域网多账号 APK，不依赖 ADB 映射")
    parser.add_argument("--server-ip", required=True, type=parse_server_ip, help="运行服务端的电脑局域网 IPv4 地址")
    parser.add_argument("--accounts", type=int, default=2, help="账号槽位数量，1~1000，默认 2")
    args = parser.parse_args(argv)
    if not 1 <= args.accounts <= 1000:
        parser.error("--accounts 必须为 1~1000")
    base = os.path.dirname(os.path.abspath(__file__))
    src_apk = os.path.join(base, "z7_7_4.apk")
    unaligned_apk = os.path.join(base, "zyj_local_unaligned.apk")
    final_apk = os.path.join(base, "zyj_local.apk")
    keystore = os.path.join(base, "debug.keystore")

    print("[1/4] Preparing patched Lua scripts...")
    patched_lua = get_patched_lua_scripts()
    config_data = dict(iter_config_bytes(os.path.join(base, "configs_sec5.zip")))
    config_entries = {f"assets/config/{section}/{name}" for section in (1, 5) for name in config_data}

    print("[2/4] Packaging modified APK...")
    if os.path.exists(unaligned_apk):
        os.remove(unaligned_apk)

    with zipfile.ZipFile(src_apk, "r") as zin, zipfile.ZipFile(unaligned_apk, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            # Exclude old signature files
            if item.filename.startswith("META-INF/") and (item.filename.endswith(".SF") or item.filename.endswith(".RSA") or item.filename.endswith(".MF")):
                continue
            if item.filename in config_entries:
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
                data = patch_game_server_json(data, args.server_ip, args.accounts)
                # 旧客户端缓存的 GameServer.json 会遮蔽新版 APK 中的局域网地址。
                zout.writestr("assets/LocalGameServer.json", data)

            zout.writestr(item, data)

        for filename, data in patched_lua.items():
            if filename not in zin.namelist():
                zout.writestr(filename, data)

        print("  [Config] Injecting offline JSON configs into APK assets...")
        count = 0
        for filename, cdata in config_data.items():
            if filename == "guide_step.json":
                cdata = patch_guide_step(cdata)
            zout.writestr(f"assets/config/1/{filename}", cdata)
            zout.writestr(f"assets/config/5/{filename}", cdata)
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
