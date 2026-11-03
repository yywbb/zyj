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
import re

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
    code = code.replace(marker, '''    cclog("[LocalFriendCopy] net recv seq=%s bytes=%d", tostring(fd.ser), #fd.rbuf)
    local friendcopyData = localfriendcopy_pb.Ids()''')
    marker = "\n    gamedata:FriendCopies(friendcopyData)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''
    gamedata.cache.localFriendCopyHelpers = {}
    local helperCount = 0
    if friendcopyData.local_helpers ~= "" then
        local helpers = friends_pb.Friends()
        helpers:ParseFromString(friendcopyData.local_helpers)
        for _,v in ipairs(helpers.friends) do
            gamedata.cache.localFriendCopyHelpers[v.rid] = {
                rid=v.rid, name=v.name, level=v.level, profile=v.profile, use=v.use,
                params={{i=v.params.params[1].i}}
            }
            helperCount = helperCount + 1
        end
    end
    cclog("[LocalFriendCopy] net ready attempts=%s maps=%d helpers=%d",
        tostring(gamedata.cache.friendcopy.kill), #gamedata.cache.friendcopy.maps, helperCount)
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
    code = read_script("UIFriendCopy").decode("utf-8").replace("\r\n", "\n")
    marker = "\nfunction UIFriendCopyQuery(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    cclog("[LocalFriendCopy] ui recv shown=%s attempts=%s maps=%d",
        tostring(GameScene.layers["friendcopy"].show), tostring(t.friendcopy.kill),
        table.getTableLength(t.friendcopy.maps))
''')
    patched["UIFriendCopy"] = code
    code = read_script("Layer_friendcopy2").decode("utf-8").replace("\r\n", "\n")
    marker = "    self.copydata = data.friendcopy\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    cclog("[LocalFriendCopy] render attempts=%s maps=%d existingView=%s",
        tostring(self.copydata.kill), table.getTableLength(self.copydata.maps), tostring(self.listTableView ~= nil))
''')
    patched["Layer_friendcopy2"] = code
    return patched


def patch_activity_copy_scripts():
    patched = {}
    code = read_script("Layer_copy_chapter").decode("utf-8").replace("\r\n", "\n")
    marker = '''        if self.activitydata ~= nil then
        else
            UIRequest({type = 1340})
        end'''
    assert code.count(marker) == 1
    code = code.replace(marker, "        UIRequest({type = 1340})")
    patched["Layer_copy_chapter"] = code

    code = read_script("UICopyActivity").decode("utf-8").replace("\r\n", "\n")
    start = code.index('    if t.temptype and t.temptype == "coin" then\n')
    end = code.index("\nend", start)
    assert code[start:end].count("activityReload(v)") == 6
    code = code[:start] + '''    local window = gameWindows.windows.copyacivity
    if window.show then
        for _,row in pairs(t.data) do
            if row.aid == window.module.data.aid then
                window.module:activityReload(row)
                return
            end
        end
        gameWindows:closeWindow("copyacivity")
    end
''' + code[end:]
    marker = '    end\n    RunbattleCallBack('
    assert code.count(marker) == 6
    code = code.replace(marker, '        UIRequest({type = 1340})\n' + marker)
    patched["UICopyActivity"] = code
    return patched


def patch_arena_scripts():
    code = read_script("GameAthletics").decode("utf-8").replace("\r\n", "\n")
    start = code.index("function UIAthleticsRewardsQuery3Callback(uireq)\n")
    end = code.index("\nend", start) + len("\nend")
    assert "return 1, 1613, nil" in code[start:end]
    code = code[:start] + "function UIAthleticsRewardsQuery3Callback(uireq)\n    return 1, 1613, nil\nend" + code[end:]
    start = code.index("function NetAthleticsList2Callback(fd)\n")
    marker = "    local ranklist,top10 = Athletics(athleticsData)\n"
    pos = code.index(marker, start) + len(marker)
    code = code[:pos] + '''    local boss = athleticsData.my.params and athleticsData.my.params.params[3]
    gamedata.cache.vipstatus.athletics_boss = boss and boss.i or 0
''' + code[pos:]
    patched = {"GameAthletics": code}

    code = read_script("UIAthletics").decode("utf-8").replace("\r\n", "\n")
    marker = "UIRequest({type = 999900,reqs = {1610,1613}})"
    assert code.count(marker) == 2
    code = code.replace(marker, "UIRequest({type = 1610})\n        UIRequest({type = 1613})")
    marker = '    RunbattleCallBack("sports", t)'
    assert code.count(marker) == 1
    code = code.replace(marker, '''    RunbattleCallBack("sports", t, function()
        UIRequest({type = 1610})
    end)''')
    marker = "    UIRequest({type = 1001})\n    UIRequest({type = 1610})\nend"
    assert code.count(marker) == 1
    code = code.replace(marker, "    UIRequest({type = 1001})\nend")
    patched["UIAthletics"] = code

    code = read_script("Layer_sports").decode("utf-8").replace("\r\n", "\n")
    marker = """    local status = 0
    if not isTop10 then
        status = data.status
    end"""
    assert code.count(marker) == 1
    code = code.replace(marker, "    local status = data.status")
    marker = "            isPlayFight = 0;"
    assert code.count(marker) == 1
    code = code.replace(marker, "            -- 本地低排名重打仍是真实战斗，保留胜负播放。")
    marker = 'items.buttontext:setString(gameConfig.strings:string_common("sports",21))'
    assert code.count(marker) == 1
    code = code.replace(marker, 'items.buttontext:setString(gameConfig.strings:string_common("sports",4))')
    start = code.index('    if self.selectpage == "rank" then\n', code.index("function sports.shiftPage(self,type)\n"))
    end = code.index("\nend", start)
    assert "self.firstrewardListTableView:reloadData()" in code[start:end]
    code = code[:start] + '''    if type == "rank" or type == "top10" then
        UIRequest({type = 1610})
    elseif type == "reward" then
        UIRequest({type = 1613})
    elseif type == "first" then
        UIRequest({type = 1615})
    end''' + code[end:]
    patched["Layer_sports"] = code

    code = read_script("Layer_sports_shop").decode("utf-8").replace("\r\n", "\n")
    marker = '    self.rootNode,self.rootItems = CCBReaderLoad("tanchuang/sports_shop", nil, true, "sports_shop")\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '    ui.setLabelString(self.rootItems.descText,"跨日进入结算日奖，离线不累积",13)\n')
    patched["Layer_sports_shop"] = code

    code = read_script("window_buyProperty").decode("utf-8").replace("\r\n", "\n")
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
    marker = "function buy.reloadData(self,data)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localVipPending = false\n")
    patched["window_buyProperty"] = code
    return patched


def patch_cornucopia_scripts():
    code = read_script("GameActivityCornucopia").decode("utf-8").replace("\r\n", "\n")
    marker = '    local reward, used, ext = gamedata:SomethingProcess(SomeThings,"cornucopia")\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    ext = {}
    local state = SomeThings.pext1 and SomeThings.pext1[1]
    if state then
        for i=6,#state.ids do table.insert(ext,state.ids[i]) end
    end
''')
    return {"GameActivityCornucopia": code}


def patch_single_boss_scripts():
    code = read_script("GameSingleBoss").decode("utf-8").replace("\r\n", "\n")
    marker = 'local ids_pb = require("ids_pb")\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + 'local somethings_pb = require("somethings_pb")\n')
    start = code.index("function UISingleBossQuaryCallback(uireq)\n")
    end = code.index("\nfunction NetSingleBossQuaryCallback", start)
    assert "return 1, 3700, nil" in code[start:end]
    code = code[:start] + "function UISingleBossQuaryCallback(uireq)\n    return 1, 3700, nil\nend\n" + code[end:]
    marker = "    gamedata:SingleBoss(idsData)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    gamedata.cache.singleBoss.bought = idsData.ids[6] or 0
    gamedata.cache.vipstatus.personalboss_times = gamedata.cache.singleBoss.bought
''')
    marker = "    t.reward = gamedata:SomethingProcess(getData)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    local counts = getData.pext1[1]
    t.attempts = counts and counts.ids[1] or 0
    t.wins = counts and counts.ids[2] or 0
''')
    patched = {"GameSingleBoss": code}

    code = read_script("GameSlotArrange").decode("utf-8").replace("\r\n", "\n")
    marker = "    if gamedata.cache.commonSlots[uireq.id..uireq.param] then"
    assert code.count(marker) == 1
    code = code.replace(marker, "    if uireq.id ~= 140 and gamedata.cache.commonSlots[uireq.id..uireq.param] then")
    patched["GameSlotArrange"] = code

    code = read_script("UIsingleBoss").decode("utf-8").replace("\r\n", "\n")
    marker = "function UISingleBossQuary(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    GameScene.vipstatus.personalboss_times = t.boss.bought or 0\n")
    marker = "function UIKingmanOnekeyChallengeBack(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    UIRequest({type = 3700})
    runGamePrompt({msg = "实际挑战"..(t.attempts or 0).."次，胜利"..(t.wins or 0).."次；失败不消耗次数"})
''')
    patched["UIsingleBoss"] = code

    code = read_script("Layer_singleBoss").decode("utf-8").replace("\r\n", "\n")
    start = code.index('            -- gameWindows:openWindow("kingfoot",{type = "kingselect", data = self.data})\n')
    end = code.index("        end\n    end, CCControlEventTouchUpInside)", start)
    assert "UIRequest({type = 3701,id = bossconfig.id})" in code[start:end]
    code = code[:start] + '            gameWindows:openWindow("kingfoot",{type = "kingselect", data = self.data})\n' + code[end:]
    marker = "        if self.data.isFirst and self.data.isFirst == 1 then\n"
    assert code.count(marker) == 1
    code = code.replace(marker, '''        if self.battletimes <= 0 then
            singlebossBuyTimes()
            return
        end
''' + marker)
    for node in ("oneFinishBtn", "oneFinishText"):
        marker = f"    self.rootItems.{node}:setVisible(false)"
        assert code.count(marker) == 1
        code = code.replace(marker, f"    self.rootItems.{node}:setVisible(true)")
    patched["Layer_singleBoss"] = code

    code = read_script("window_kingmanOnekeyChallenge").decode("utf-8").replace("\r\n", "\n")
    marker = "\tself.data = data.boss or {}\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if (self.data.openlevel or 0) == 0 then
        gameWindows:closeWindow("kingmanOnekeyChallenge")
        return
    end
    self.bosstpye = self.data.openlevel
    self:setBossLevelTable(self.data.bosstype)
    self.rootItems.buylevel:setString(tostring(self.attConfigData[tostring(self.bosstpye)].level))
''')
    patched["window_kingmanOnekeyChallenge"] = code
    return patched


def patch_equip_baptize_scripts():
    code = read_script("GameEquipRefine").decode("utf-8").replace("\r\n", "\n")
    for name in ("Preview", "Confirm", "Automatic"):
        marker = f"function UIEquipBaptize{name}CallBack(uireq)\n"
        assert code.count(marker) == 1
        code = code.replace(marker, marker + '''    if gamedata.ext.localBaptizeBusy then
        return 0,503,{type=503,msg="洗炼正在结算，请等待回复；超时请重进游戏"}
    end
''')
        marker = f"function NetEquipBaptize{name}CallBack(fd)\n"
        assert code.count(marker) == 1
        code = code.replace(marker, marker + "    gamedata.ext.localBaptizeBusy = false\n")
    marker = "    gamedata.ext.EquipBaptizeid = uireq.iid\n\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if uireq.method == 0 and uireq.xlnum == 0 then
        gamedata.ext.EquipBaptizeXprops = {}
        gamedata.ext.localBaptizeBusy = true
        return 1,1120,equipBaptizeData:SerializeToString()
    end
''')
    marker = "    local equip = gamedata:equipData(equipsData)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    equip.preview_token = equipsData.ids[14] or 0\n")
    start = code.index("    table.insert(equipBaptizeData.ids, uireq.method)", code.index("function UIEquipBaptizeConfirmCallBack"))
    end = code.index("    return 1, 1121,", start)
    assert "if uireq.iid then" in code[start:end]
    code = code[:start] + '''    local iid = uireq.iid or uireq.id
    if not iid or not uireq.token or uireq.token <= 0 then
        return 0,503,{type=503,msg="请重新打开装备查看洗炼预览"}
    end
    table.insert(equipBaptizeData.ids, uireq.method)
    table.insert(equipBaptizeData.ids, iid)
    table.insert(equipBaptizeData.ids, uireq.token)
    gamedata.ext.EquipBaptizeid = iid

''' + code[end:]
    for mid in (1120, 1121, 1124):
        marker = f"    return 1, {mid}, equipBaptizeData:SerializeToString()"
        assert code.count(marker) == 1
        code = code.replace(marker, "    gamedata.ext.localBaptizeBusy = true\n" + marker)
    patched = {"GameEquipRefine": code}

    code = read_script("Layer_equip_up").decode("utf-8").replace("\r\n", "\n")
    marker = 'function equipUp.setPage_strengthen(self)\n\tprint("显示洗练页面")\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    self.localBaptizeToken = nil
    self.xlselectbtn = self.xlselectbtn or 1
    self.dotimes = GameScene.roleinfo.level >= tonumber(gamedata.config.global_kv.baptize_leve_limit.value) and 50 or 10
''')
    for method in (0, 1):
        marker = f"UIRequest({{type = 1121, id = self.data.iid, method = {method},}})"
        assert code.count(marker) == 1
        code = code.replace(marker, f"UIRequest({{type = 1121, iid = self.data.iid, method = {method}, token = self.localBaptizeToken}})")
    marker = "    self.rootItems.xl_Button3:addHandleOfControlEvent(function()\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''        if self.hasXLPreview then
            runGamePrompt({msg = "请先保留或替换当前洗炼预览"})
            return
        end
''')
    marker = "    self.rootItems.xl_addStone:setTouchPriority(self.touchPriority)\t\nend"
    assert code.count(marker) == 1
    code = code.replace(marker, marker[:-3] + '''    if equipquality >= 3 then
        UIRequest({type=1120,iid=self.data.iid,method=0,xlnum=0})
    end
end''')
    marker = "function equipUp.setXilianPreview(self,data)\n    if not data then return end\n    self.hasXLPreview = true\n"
    assert code.count(marker) == 1
    code = code.replace(marker, '''function equipUp.setXilianPreview(self,data)
    if not data or not self.data or self.data.iid ~= data.iid or self.selectpage ~= "xilian" then return end
    self.localBaptizeToken = data.preview_token
    self.hasXLPreview = (data.preview_token or 0) > 0
    if not self.hasXLPreview then return end
''')
    start = code.index("    if not hasup then", code.index("function equipUp.setXilianPreview("))
    end = code.index("\nend", start)
    assert "if not hasdown then" in code[start:end]
    code = code[:start] + '''    self.rootItems.xl_Button_no:setEnabled(true)
    ui.removeGray("CCControlButton",self.rootItems.xl_Button_no)
    ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab_no)
    self.rootItems.xl_Button_yes:setEnabled(hasup or hasdown)
    if hasup or hasdown then
        ui.removeGray("CCControlButton",self.rootItems.xl_Button_yes)
        ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab_yes)
    else
        ui.addGray("CCControlButton",self.rootItems.xl_Button_yes)
        ui.addGray("CCLabelTTF",self.rootItems.xl_Lab_yes)
    end
''' + code[end:]
    patched["Layer_equip_up"] = code

    code = read_script("UIEquips").decode("utf-8").replace("\r\n", "\n")
    for name in ("Preview", "Confirm", "Automatic"):
        start = code.index(f"function UIEquipBaptize{name}(t)\n")
        end = code.index("\nend", start)
        block = code[start:end]
        assert block.count("    UIRequest({type = 10322})") == 1
        block = block.replace("    UIRequest({type = 10322})", "").replace("    UIRequest({type = 1001})", "")
        if name != "Preview":
            marker = '    if GameScene.layers["equipsup"].show then\n'
            assert block.count(marker) == 1
            block = block.replace(marker, '''    local layer = GameScene.layers["equipsup"]
    if layer.show and layer.module.data and layer.module.data.iid == t.equip.iid then
''')
        if name == "Automatic":
            marker = '    if gameWindows.windows["equipbaptize"].show then\n'
            assert block.count(marker) == 1
            block = block.replace(marker, '''    local window = gameWindows.windows["equipbaptize"]
    if window.show and window.module.iid == t.equip.iid then
''')
        code = code[:start] + block + code[end:]
    for name in ("UITreasureStrengthen", "UITreasureStrengthebyprop", "UITreasureRefine2"):
        start = code.index(f"function {name}(")
        end = code.index("\nend", start)
        block = code[start:end]
        assert block.count("    UIRequest({type = 10322})") == 1
        block = block.replace("    UIRequest({type = 10322})", "").replace("    UIRequest({type = 1001})", "")
        block = block.replace("    GameScene:addUpdate(1001)", "    GameScene:addUpdate(1200)")
        marker = '    if GameScene.layers["treasureup"].show then\n'
        assert block.count(marker) == 1
        block = block.replace(marker, '''    local layer = GameScene.layers["treasureup"]
    if layer.show and layer.module.data and layer.module.data.iid == t.equip.iid then
''')
        code = code[:start] + block + code[end:]
    patched["UIEquips"] = code

    code = read_script("window_equipBaptizeAutomatic").decode("utf-8").replace("\r\n", "\n")
    marker = "    local donum = self.donum + num\n"
    assert code.count(marker) == 1
    code = code.replace(marker, "    local donum = math.floor((self.donum + num)/10)*10\n")
    patched["window_equipBaptizeAutomatic"] = code
    return patched


def patch_sigil_scripts():
    code = read_script("GameMofu").decode("utf-8").replace("\r\n", "\n")
    marker = "    for k,v in pairs(uireq.choose) do\n"
    assert code.count(marker) == 1
    code = code.replace(marker, "    for k,v in ipairs(uireq.choose) do\n")
    marker = "    local data = getMofuCanLevelData(uireq.data)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    data.iid = uireq.data.iid\n")
    for name, mid, message in (("LevelUp", 1140, "idsData"), ("ChangePos", 1141, "idsData")):
        marker = f"function UISigil{name}CallBack(uireq)\n"
        assert code.count(marker) == 1
        code = code.replace(marker, marker + '''    if gamedata.ext.localSigilBusy then
        return 0,503,{type=503,msg="魔符正在结算，请等待回复；超时请重进游戏"}
    end
''')
        marker = f"    return 1, {mid}, {message}:SerializeToString()"
        assert code.count(marker) == 1
        code = code.replace(marker, "    gamedata.ext.localSigilBusy = true\n" + marker)
        marker = f"function NetSigil{name}CallBack(fd)\n"
        assert code.count(marker) == 1
        code = code.replace(marker, marker + "    gamedata.ext.localSigilBusy = false\n")
    patched = {"GameMofu": code}

    code = read_script("GameSlots").decode("utf-8").replace("\r\n", "\n")
    marker = "    local gems = table.copy(gamedata.cache.gems)\n    for ak,av in pairs(gamedata.cache.slotgems) do\n"
    assert code.count(marker) == 1
    code = code.replace(marker, "    local gems = table.copy(gamedata.cache.gems)\n    for _,gem in pairs(gems) do gem.ison = 0 end\n    for ak,av in pairs(gamedata.cache.slotgems) do\n")
    start = code.index("function NetSlotsAllInfoCallBack(fd)\n")
    end = code.index("\nfunction ", start + 1)
    block = code[start:end]
    marker = "    gamedata:SlotInfoProcess(info)\n"
    assert block.count(marker) == 1
    block = block.replace(marker, "    gamedata.cache.gems = {}\n    gamedata.cache.slotgems = {}\n" + marker)
    code = code[:start] + block + code[end:]
    patched["GameSlots"] = code

    code = read_script("UIMofu").decode("utf-8").replace("\r\n", "\n")
    marker = '    UIRequest({type = 10322,param = {"gem"}})'
    assert code.count(marker) == 2
    code = code.replace(marker, "")
    marker = '    gameWindows.windows["mofulevelup"].module:selectdataReload({data=data.selectlistdata})'
    assert code.count(marker) == 1
    code = code.replace(marker, "")
    marker = '    if gameWindows.windows["mofulevelup"].show then\n'
    assert code.count(marker) == 2
    code = code.replace(marker, '''    local window = gameWindows.windows["mofulevelup"]
    if window.show and window.module.data and window.module.data.iid == t.iid then
        window.module:selectdataReload({data=data.selectlistdata})
''', 1)
    for name, field in (("mofuproperty", "infodata"), ("mofulevelup", "data")):
        marker = f'    if gameWindows.windows["{name}"].show then\n'
        assert code.count(marker) == 1
        code = code.replace(marker, f'''    local window = gameWindows.windows["{name}"]
    if window.show and window.module.{field} and window.module.{field}.iid == t.data.iid then
''')
    patched["UIMofu"] = code

    code = read_script("window_MofuLevelUp").decode("utf-8").replace("\r\n", "\n")
    marker = "        if #(self.chooseData) == 0 then\n"
    assert code.count(marker) == 1
    code = code.replace(marker, "        if #(self.chooseData) == 0 and self.data.exp < self.data.temp.exp then\n")
    patched["window_MofuLevelUp"] = code

    code = read_script("window_mofuProperty").decode("utf-8").replace("\r\n", "\n")
    marker = '    self.rootNode, self.rootItems = CCBReaderLoad("mofu/mofu_info", nil, true, "mofu_info")\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localLevelUpX = self.rootItems.levelupNode:getPositionX()\n")
    marker = "    self.infodata = data.infodata\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.ison = 0\n    self.rootItems.changeBtn:setEnabled(false)\n")
    marker = "function mofuproperty.setCanLevelUpGemsReload(self,data)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    if data.iid and data.iid ~= self.infodata.iid then return end\n")
    marker = "\n    self.canlevelup = data.canlevelup\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.rootItems.changeBtn:setEnabled(self.ison > 0)\n")
    start = code.index('    elseif data.page == "slot" then\n')
    end = code.index('    elseif data.page == "other" then\n', start)
    block = code[start:end]
    assert block.count("self.rootItems.changeNode:setVisible(false)") == 1
    assert block.count("self.rootItems.levelupNode:setPositionX(540)") == 1
    block = block.replace("self.rootItems.changeNode:setVisible(false)", "self.rootItems.changeNode:setVisible(true)")
    block = block.replace("self.rootItems.levelupNode:setPositionX(540)", "self.rootItems.levelupNode:setPositionX(self.localLevelUpX)")
    code = code[:start] + block + code[end:]
    marker = "    -- 去掉更换功能\n"
    assert code.count(marker) == 1
    code = code.replace(marker, '''    ui.setLabelString(self.rootItems.changeText,"卸下",19)
    self.rootItems.changeBtn:addHandleOfControlEvent(function()
        if self.ison and self.ison > 0 then
            UIRequest({type=1141,pos=self.ison*10+self.infodata.type,iid=0})
            gameWindows:closeWindow("mofuproperty")
        end
    end,CCControlEventTouchUpInside)
    self.rootItems.changeBtn:setSwallowsTouch(true)
    self.rootItems.changeBtn:setTouchPriority(self.touchPriority)
''' + marker)
    patched["window_mofuProperty"] = code

    code = read_script("Layer_slotsInfo").decode("utf-8").replace("\r\n", "\n")
    marker = "function slotsInfo.updateAutoQuery( self,data )\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    if not self.quickItems then return end\n")
    patched["Layer_slotsInfo"] = code

    code = read_script("GameTimeBag").decode("utf-8").replace("\r\n", "\n")
    start = code.index("    elseif uireq.opt == 2 then\n")
    end = code.index("    elseif uireq.opt == 3 then\n", start)
    block = code[start:end]
    marker = "            if v.type==uireq.opt \n"
    assert block.count(marker) == 1
    code = code[:start] + block.replace(marker, "            if v.type==uireq.opt and v.id==130010\n") + code[end:]
    patched["GameTimeBag"] = code
    return patched


def patch_treasure_scripts():
    code = read_script("GameTreasureUp").decode("utf-8").replace("\r\n", "\n")
    for name, opcode in (("TreasureStrengthen", 1118), ("TreasureStrengthenByProp", 1210), ("TreasureRefine2", 1119)):
        marker = f"function UI{name}CallBack("
        start = code.index(marker)
        end = code.index("\n", start)
        code = code[:end + 1] + '''    if gamedata.ext.localTreasureBusy then
        return 0,503,{type=503,msg="宝物正在结算，请等待回复；超时请重进游戏"}
    end
''' + code[end + 1:]
        marker = f"    return 1, {opcode}, "
        assert code.count(marker) == 1
        code = code.replace(marker, "    gamedata.ext.localTreasureBusy = true\n" + marker)
        marker = f"function Net{name}CallBack("
        start = code.index(marker)
        end = code.index("\n", start)
        code = code[:end + 1] + "    gamedata.ext.localTreasureBusy = false\n" + code[end + 1:]
    start = code.index("function UITreasureRefine2CallBack(")
    end = code.index("\nfunction NetTreasureRefine2CallBack(", start)
    block = code[start:end]
    marker = "    for k,v in pairs(uireq.ids) do"
    assert block.count(marker) == 1
    code = code[:start] + block.replace(marker, "    for k,v in ipairs(uireq.ids) do") + code[end:]
    return {"GameTreasureUp": code}


def patch_general_foster_scripts():
    original = read_script("GameGeneralFoster").decode("utf-8")
    for name in ("UIGeneralFosterPreviewCallBack", "NetGeneralFosterPreviewCallBack", "UIGeneralFosterConfirmCallBack",
                 "NetGeneralFosterConfirmCallBack", "UIGeneralAutoTrainCallBack", "NetGeneralAutoTrainCallBack"):
        assert original.count("function " + name + "(") == 1
    with open(os.path.join(os.path.dirname(__file__), "client_patches", "general_foster.lua"), encoding="utf-8") as stream:
        patched = {"GameGeneralFoster": stream.read()}
    for name, module in (("Layer_generalup", "generalup"), ("window_generalInfo", "generalInfo")):
        code = read_script(name).decode("utf-8").replace("\r\n", "\n")
        for opt in (0, 1):
            marker = f"UIRequest({{type = 1014, opt = {opt} }})"
            assert code.count(marker) == 2
            code = code.replace(marker, f"UIRequest({{type = 1014, opt = {opt}, id = self.data.general.iid, token = self.localFosterToken }})")
        start = code.index(f"function {module}.setPage_train(")
        end = code.index("\nend", start)
        code = code[:end] + '''
    self.localFosterToken = nil
    if not self.localFosterNoQuery and self.data.general.level1 > 1 then
        UIRequest({type=1013,id=self.data.general.iid,method=0})
    end
''' + code[end:]
        start = code.index(f"function {module}.setTrainResuit(")
        end = code.index("\nend", start)
        block = code[start:end]
        marker = "    self.trainResuit = true"
        assert block.count(marker) == 1
        block = block.replace(marker, "    self.localFosterToken = datas.token\n" + marker)
        block = block.replace("                self.trainResuit = false\n", "")
        code = code[:start] + block + code[end:]
        marker = '    gamedata.music:PlayOptSound("py")'
        if module == "generalInfo":
            assert code.count(marker) == 1
            code = code.replace(marker, '    if not datas.restored then gamedata.music:PlayOptSound("py") end')
        patched[name] = code
    code = read_script("UIGenerals").decode("utf-8").replace("\r\n", "\n")
    replacements = {
        "UIGeneralFosterPreview": '''function UIGeneralFosterPreview(t)
    local function show(entry,kind)
        local page = entry and entry.module
        if not entry or not entry.show or not page.data or not page.data.general or page.data.general.iid ~= t.extGeneralData.iid then return end
        if (kind == "layer" and page.selectpage ~= "train") or (kind == "window" and page.pagetype ~= "train") then return end
        if t.token > 0 then
            page:setTrainResuit(t)
            page:setTrainPropNum({["20009"]=t.remaining})
        elseif page.trainResuit then
            page.trainResuit = false
            page.localFosterNoQuery = true
            page:setPage_train()
            page.localFosterNoQuery = false
        end
    end
    show(GameScene.layers["generalup"],"layer")
    show(gameWindows.windows["generalInfo"],"window")
end''',
        "UIGeneralFosterConfirm": '''function UIGeneralFosterConfirm(t)
    for _,id in ipairs({10021,10024,10023,1200}) do GameScene:addUpdate(id) end
    local layer = GameScene.layers["generalup"]
    if layer.show and layer.module.data.general.iid == t.general.iid then layer.module:ReloadData(t) end
    local window = gameWindows.windows["generalInfo"]
    if window.show and window.module.data.general.iid == t.general.iid then window.module:reloaddata(t) end
end''',
        "UIGeneralFosterAutomatic": '''function UIGeneralFosterAutomatic(t)
    UIGeneralFosterConfirm(t)
    local window = gameWindows.windows["generalcultivate"]
    if window.show and window.module.iid == t.general.iid then window.module:reloadData(t) end
end'''}
    for name, replacement in replacements.items():
        start = code.index(f"function {name}(t)")
        end = code.index("\nend", start) + len("\nend")
        code = code[:start] + replacement + code[end:]
    patched["UIGenerals"] = code
    code = read_script("window_generalcultivateAuto").decode("utf-8").replace("\r\n", "\n")
    marker = 'gameConfig.strings:generalPeiyang(a1+1)'
    assert code.count(marker) == 1
    code = code.replace(marker, 'string.format("第%d组（实际%d次）",a1+1,data.count)')
    start = code.index('                if data["potential"] and data["potential"] > 0 then')
    end = code.index('\n            else\n                ccbDocumentControler["stop"]:setVisible(false)', start)
    code = code[:start] + '                ccbDocumentControler["stop"]:setString("培养已停止，仅扣实际执行次数")' + code[end:]
    patched["window_generalcultivateAuto"] = code
    return patched


def patch_magic_scripts():
    original = read_script("GameMagic").decode("utf-8")
    for name in ("UIInstrumentQueryCallback", "NetInstrumentQueryCallback", "UIInstrumentUnlockCallback", "NetInstrumentUnlockCallback",
                 "UIInstrumentForgePreview", "NetInstrumentForgePreview", "UIInstrumentForgeConfirm", "NetInstrumentForgeConfirm",
                 "UIInstrumentForgeAutomaticCallback", "NetInstrumentForgeAutomaticCallback", "UIBreakForgePreview", "NetBreakForgePreview"):
        assert original.count("function " + name + "(") == 1
    patched = {}
    for name, filename in (("GameMagic", "magic.lua"), ("UIMagic", "magic_ui.lua")):
        with open(os.path.join(os.path.dirname(__file__), "client_patches", filename), encoding="utf-8") as stream:
            patched[name] = stream.read()
    code = read_script("Layer_magic").decode("utf-8").replace("\r\n", "\n")
    assert code.count("return magic") == 1
    code = code.replace("selecetID", "selectID")
    for opcode, count in ((1361, 1), (1362, 6), (1363, 2), (1365, 1)):
        marker = f"type = {opcode},"
        assert code.count(marker) == count
        extra = " id=self.selectID, token=self.localMagicToken," if opcode == 1363 else ""
        code = code.replace(marker, marker + " view=self.localMagicView," + extra)
    marker = "UIRequest({type = 1360})"
    assert code.count(marker) == 1
    code = code.replace(marker, "UIRequest({type=1360,view=self.localMagicView})")
    marker = 'g_gold = self.g_gold},nil)'
    assert code.count(marker) == 1
    code = code.replace(marker, 'g_gold = self.g_gold,view=self.localMagicView},nil)')
    code = code.replace("return magic", '''
local localMagicInit = magic.init
function magic.init(self,...)
    self.localMagicView = (self.localMagicView or 0)+1
    localMagicInit(self,...)
    self.taskConfig = setmetatable({["0"]={desc="无额外条件",target="1"}},{__index=self.taskConfig})
end
local localMagicClear = magic.clear
function magic.clear(self,...)
    self.localMagicView = (self.localMagicView or 0)+1
    self.localMagicToken = nil
    return localMagicClear(self,...)
end
local localMagicLoad = magic.load
function magic.load(self,data)
    local unlocked = {}
    for _,row in pairs(data.data.unlock) do unlocked[tostring(row.id)] = row end
    data.data.unlock = unlocked
    return localMagicLoad(self,data)
end
local localMagicSelect = magic.setNodeVisible
function magic.setNodeVisible(self,id)
    self.localMagicToken = nil
    self.previeState = false
    local current = self.data.unlock[tostring(id)]
    local row = self.artifactConfigxian[tostring(id)][tostring(current and math.max(1,current.istupo) or 1)]
    for index=4,7 do
        self.globalData[index] = {}
        for _,cost in pairs(gamedata.getIDandNUMs(index == 4 and row.breach_consume or row["forging_consume"..(index-4)])) do
            self.globalData[index][tostring(cost.cid)] = cost.num
        end
    end
    localMagicSelect(self,id)
    self:setButtonShowType(0)
    if current then UIRequest({type=1362,id=id,typeIndex=0,times=0,view=self.localMagicView}) end
end
return magic''')
    patched["Layer_magic"] = code
    code = read_script("window_instrumentForgeAutomatic").decode("utf-8").replace("\r\n", "\n")
    marker = "function instrumentForgeAutomatic.open(self,touchPriority,data,callback)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localMagicView = data.view\n    self.localMagicWindow = (self.localMagicWindow or 0)+1\n")
    marker = "function instrumentForgeAutomatic.close(self)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localMagicWindow = (self.localMagicWindow or 0)+1\n")
    marker = "type = 1364,"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + " view=self.localMagicView, window=self.localMagicWindow,")
    marker = '"第"..(a1+1).."次".." (锻造x10)"'
    assert code.count(marker) == 1
    code = code.replace(marker, 'string.format("第%d组（实际%d次）",a1+1,data.count)')
    marker = "local donum = self.donum + num"
    assert code.count(marker) == 1
    code = code.replace(marker, "local donum = math.floor(self.donum + (tonumber(num) or 0))")
    patched["window_instrumentForgeAutomatic"] = code
    return patched


def patch_friends_scripts():
    patched = {}
    for name, filename in (("GameFriendManager", "friends_network.lua"), ("UIFriends", "friends_ui.lua")):
        code = read_script(name).decode("utf-8").replace("\r\n", "\n")
        assert "function " + ("UIFriendReqCallBack" if name == "GameFriendManager" else "UIFriendChatQuery") + "(" in code
        if name == "UIFriends":
            code, count = re.subn(r"UIRequest\(\{type\s*=\s*(23[01][0-9]|300[234]|6038)\b", r"UIRequest({type=\1, view=t.view", code)
            assert count == 15
            code = code.replace("type=3002, view=t.view", "type=3002, view=t.view, refresh=true")
        with open(os.path.join(os.path.dirname(__file__), "client_patches", filename), encoding="utf-8") as stream:
            patched[name] = code + "\n" + stream.read()
    code = read_script("Layer_friends").decode("utf-8").replace("\r\n", "\n")
    marker = "ui.setLabelString(self.rootItems.myid,GameScene.roleinfo.showid or GameScene.roleinfo.id,14)"
    assert code.count(marker) == 1
    code = code.replace(marker, 'ui.setLabelString(self.rootItems.myid,"...",14)')
    old = '''        if not self.frinedData or not next(self.frinedData) then
            UIRequest({type = 2300})
        elseif GameScene:checkhint(37) then
            UIRequest({type = 2300, param = 1})
        end'''
    assert code.count(old) == 1
    code = code.replace(old, "        UIRequest({type = 2300})")
    for key, opcode in (("recomendData", 2301), ("reqData", 2303), ("shieldData", 3002)):
        condition = f"not self.{key} or not next(self.{key})" + (" or GameScene:checkhint(37)" if opcode == 2303 else "")
        old = f"        if {condition} then\n            UIRequest({{type = {opcode}}})\n        end"
        assert code.count(old) == 1
        code = code.replace(old, f"        UIRequest({{type = {opcode}" + (", refresh=true" if opcode == 3002 else "") + "})")
    for marker in ("function friends.init(self,parent,toppos,data)\n", "function friends.clear(self)\n"):
        assert code.count(marker) == 1
        code = code.replace(marker, marker + "    self.localFriendView=(self.localFriendView or 0)+1\n")
    code, count = re.subn(r"UIRequest\(\{type\s*=\s*(23[01][0-9]|300[234]|6038|1022)\b", r"UIRequest({type=\1, view=self.localFriendView", code)
    assert count == 26
    patched["Layer_friends"] = code
    code = read_script("window_friend").decode("utf-8").replace("\r\n", "\n")
    for marker in ("function friend.open(self,touchPriority,data,callback)\n", "function friend.close(self)\n"):
        assert code.count(marker) == 1
        code = code.replace(marker, marker + "    self.localFriendGeneration=(self.localFriendGeneration or 0)+1\n")
    marker = "function friend.open(self,touchPriority,data,callback)\n"
    code = code.replace(marker, marker + "    self.localFriendKind=data.type\n")
    code, count = re.subn(r"UIRequest\(\{type\s*=\s*(23[01][0-9])\b", r"UIRequest({type=\1, generation=self.localFriendGeneration", code)
    assert count == 9
    patched["window_friend"] = code
    code = read_script("GameCheckOtherSlotsInfo").decode("utf-8").replace("\r\n", "\n")
    assert code.count("function UICheckOtherSlotsInfoCallBack(") == 1
    patched["GameCheckOtherSlotsInfo"] = code + '''
local localOtherSend,localOtherReceive=UICheckOtherSlotsInfoCallBack,NetCheckOtherSlotsInfoCallBack
function UICheckOtherSlotsInfoCallBack(req)
    gamedata.ext.localOtherSlotsRequests=gamedata.ext.localOtherSlotsRequests or {}
    table.insert(gamedata.ext.localOtherSlotsRequests,req)
    return localOtherSend(req)
end
function NetCheckOtherSlotsInfoCallBack(fd)
    local req=table.remove(gamedata.ext.localOtherSlotsRequests or {},1) or {}
    gamedata.ext.otherlevel=req.level
    local result=localOtherReceive(fd)
    result.rid,result.generation=req.rid,req.generation
    return result
end
'''
    code = read_script("Layer_slotsinfo_other").decode("utf-8").replace("\r\n", "\n")
    for marker in ("function slotsInfo.init(self,parent,toppos,param,index)\n", "function slotsInfo.clear(self)\n"):
        assert code.count(marker) == 1
        code = code.replace(marker, marker + "    self.localFriendGeneration=(self.localFriendGeneration or 0)+1\n")
    marker = "UIRequest({type = 1020,"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + " generation=self.localFriendGeneration,")
    patched["Layer_slotsinfo_other"] = code
    code = read_script("UISlots").decode("utf-8").replace("\r\n", "\n")
    marker = "function UICheckOtherSlotsInfo(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    local page=GameScene.templayers.other_slotinfo
    if not page or not page.show or t.generation~=page.localFriendGeneration or not page.palyerdata or t.rid~=page.palyerdata.rid then return end
''')
    patched["UISlots"] = code
    code = read_script("GameBattleOther").decode("utf-8").replace("\r\n", "\n")
    assert code.count("function UIBattleOtherCallback(") == 1
    patched["GameBattleOther"] = code + '''
local localSparSend,localSparReceive=UIBattleOtherCallback,NetBattleOtherCallback
function UIBattleOtherCallback(req)
    if gamedata.ext.localSparRequest then return 0,503,{type=503,msg="切磋战报生成中，请等待回复"} end
    gamedata.ext.localSparRequest=req
    return localSparSend(req)
end
function NetBattleOtherCallback(fd)
    local req=gamedata.ext.localSparRequest or {}
    gamedata.ext.localSparRequest=nil
    local result=localSparReceive(fd)
    result.view,result.rid=req.view,req.rid
    return result
end
'''
    code = read_script("UIBattleOther").decode("utf-8").replace("\r\n", "\n")
    marker = "function UIBattleOther(t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    local layer=GameScene.layers.friends
    if not layer or not layer.show or t.view~=layer.module.localFriendView then return end
''')
    code = code.replace("    UIRequest({type = 1001})\n", "")
    patched["UIBattleOther"] = code
    return patched


def patch_world_boss_scripts():
    patched = {}
    for name, filename in (("GameWorldBoss", "world_boss_network.lua"), ("UIWorldBoss", "world_boss_ui.lua"), ("Layer_worldboss2", "world_boss_layer.lua")):
        code = read_script(name).decode("utf-8").replace("\r\n", "\n")
        assert "worldboss" in code.lower()
        if name == "GameWorldBoss":
            assert code.count('os.date("*t", gamedata:time())') == 8
            code = code.replace('os.date("*t", gamedata:time())', 'os.date("!*t", gamedata:time()+28800)')
        if name == "Layer_worldboss2":
            marker = "    local scale = 2.5"
            assert code.count(marker) == 1
            code = code.replace(marker, '''    self.localWorldBossView=(self.localWorldBossView or 0)+1
    self.localWorldBossReady=0
    self.localWorldBossPlaying=false
    self.localWorldBossPoll=nil
    self.localWorldBossTick=nil
    self.isauto=false
    self.lastid=0
''' + marker)
            marker = "function worldboss.init(self,parent,toppos,param)\n"
            assert code.count(marker) == 1
            code = code.replace(marker, marker + "    self.localWorldBossBusy=nil\n    self.hasjoin=false\n")
            marker = "function worldboss.clear(self)\n"
            assert code.count(marker) == 1
            code = code.replace(marker, marker + "    self.localWorldBossView=(self.localWorldBossView or 0)+1\n    self:stoptnotify()\n    self.isauto=false\n")
            code, count = re.subn(r"(?m)^(\s*)UIRequest\(\{type\s*=\s*self.data\[self.selectpage\]", r"\1self:localWorldBossRequest({type=self.data[self.selectpage]", code)
            assert count == 15, count
            marker = "    self.data[self.selectpage].notifys[index] = nil"
            assert code.count(marker) == 1
            code = code.replace(marker, "    table.remove(self.data[self.selectpage].notifys,index)")
            marker = "for k,v in pairs(self.data[self.selectpage].notifys) do"
            assert code.count(marker) == 1
            code = code.replace(marker, "for k,v in ipairs(self.data[self.selectpage].notifys) do")
        with open(os.path.join(os.path.dirname(__file__), "client_patches", filename), encoding="utf-8") as stream:
            extra = stream.read()
        if name == "Layer_worldboss2":
            assert code.count("return worldboss") == 1
            code = code.replace("return worldboss", extra + "\nreturn worldboss")
        else:
            code += "\n" + extra
        patched[name] = code
    code = read_script("window_confirm").decode("utf-8").replace("\r\n", "\n")
    for marker, extra in (
        ('    self.rootItems.concel:addHandleOfControlEvent(function()\n', '''        if data.localWorldBossPick then
            self.callback=function() callback(2) end
            gameWindows:closeWindowDirect("confirm")
            return
        end
'''),
        ('    self.rootItems.confirm:addHandleOfControlEvent(function()\n', '''        if data.localWorldBossPick then
            self.callback=function() callback(10) end
            gameWindows:closeWindowDirect("confirm")
            return
        end
'''),
        ('    self.rootItems.confirm:setSwallowsTouch(true)\n', '''    if data.localWorldBossPick then
        ui.setLabelString(self.rootItems.conceltext,"5元宝复活",18)
        ui.setLabelString(self.rootItems.confirmtext,tostring(data.localWorldBossPrice).."元宝翻倍",18)
    end
''')):
        assert code.count(marker) == 1
        code = code.replace(marker, marker + extra)
    patched["window_confirm"] = code
    return patched


def patch_cup_scripts():
    patched = {}
    for name, filename in (("GameCup", "cup_network.lua"), ("UICup", "cup_ui.lua")):
        code = read_script(name).decode("utf-8").replace("\r\n", "\n")
        assert "function UICup" in code
        if name == "GameCup":
            marker = "    for k,v in pairs(status.battles) do"
            assert code.count(marker) == 1
            code = code.replace(marker, "    for k,v in pairs(status.battles or {}) do")
        with open(os.path.join(os.path.dirname(__file__), "client_patches", filename), encoding="utf-8") as stream:
            patched[name] = code + "\n" + stream.read()
    code = read_script("Layer_cup").decode("utf-8").replace("\r\n", "\n")
    for marker in ("function cup.init(self,parent,toppos,params)\n", "function cup.clear(self)\n"):
        assert code.count(marker) == 1
        code = code.replace(marker, marker + "    self.localCupView=(self.localCupView or 0)+1\n    self.localCupNextRefresh=nil\n")
    for old, new in (("""        if not next(self.statusdata) then
            UIRequest({type = 2100})
        else
            self:reloadStatus()
        end""", "        UIRequest({type = 2100})"), ("""        if not next(self.topsdata) then
            if not next(self.statusdata) then
                UIRequest({type = 2100})
            end
            UIRequest({type = 2102})
        else
            self:reloadTops()
        end""", "        UIRequest({type = 2100})\n        UIRequest({type = 2102})"), ("""        if not next(self.rankdata) then
            UIRequest({type = 2107})
        else
            self:reloadRank()
        end""", "        UIRequest({type = 2107})")):
        assert code.count(old) == 1
        code = code.replace(old, new)
    start = code.index('    gameTimer:rigistTime("cuptimer",99)')
    end = code.index("\n-----", start)
    code = code[:start] + '''    gameTimer:rigistTime("cuptimer",99)
    gameTimer:rigistTimeFunc("cuptimer",function()
        if not GameScene.layers.cup.show then return end
        local now=gamedata:time()
        local hour=os.date("*t",now).hour
        self.canJoinCupTime=(hour>=9 and hour<23) and 1 or 0
        self:changeButton()
        if not self.localCupNextRefresh or now>=self.localCupNextRefresh then
            self.localCupNextRefresh=now+15
            UIRequest({type=2100})
            if self.selectpage=="tops" then UIRequest({type=2102,view=self.localCupView}) end
            if self.selectpage=="rank" then UIRequest({type=2107,view=self.localCupView}) end
        end
        if gameTimer.times.cuptimer<=0 then gameTimer:rigistTime("cuptimer",99) end
    end)
''' + code[end:]
    start = code.index("    if gameConfig:checkBuildOpen(154) then", code.index("function cup.reloadStatus("))
    end = code.index("\n    if table.getTableLength", start)
    code = code[:start] + '''    self.rootItems.des11:setString("本地玩家杯赛，报名冻结阵容")
    self.rootItems.des12:setString("")
    self.rootItems.des13:setString("不足2人不开赛，需手动报名")
''' + code[end:]
    marker = '            gameWindows:openWindow("cup",{type = "bet", data = data},nil)'
    assert code.count(marker) == 1
    code = code.replace(marker, '''            if data.status<0 then runGamePrompt({msg="比赛尚未结束；本地竞猜未开放"})
            else gameWindows:openWindow("cup",{type="bet",data=data,view=self.localCupView},nil) end''')
    marker = "function cup.setTopsPage(self,page)\n"
    assert code.count(marker) == 1
    # Native countdown is for betting; keep the bracket navigation, not fake betting availability.
    start = code.index("    --bettime", code.index(marker))
    end = code.index("\nend", start)
    code = code[:start] + '''    self.rootItems.bettime:setVisible(false)
    self.rootItems.bettime_desc:setVisible(false)
''' + code[end:]
    marker = "    self.rootItems.restbet:setString(self.betnum)"
    assert code.count(marker) == 1
    code = code.replace(marker, '    self.rootItems.restbet:setString("未开放")')
    marker = '            gameWindows:openWindow("servicewarrule",{opt = 2})'
    assert code.count(marker) == 1
    code = code.replace(marker, '            runGamePrompt({msg="本地累计胜场积分，每场真实胜利获得10分"})')
    marker = "    self:setWarTime()"
    assert code.count(marker) == 2
    code = code.replace(marker, '    self.rootItems.war_time:setString("本地累计胜场积分")', 1)
    marker = "function cup.initFixedString(self)\n"
    start = code.index("    if self.rootItems.cupRankInfo then", code.index(marker))
    end = code.index("\nend", start)
    code = code[:start] + '    self.rootItems.cupRankInfo:setVisible(false)\n' + code[end:]
    code, count = re.subn(r"(?m)^(\s*)UIRequest\(\{type\s*=\s*(210[0123467])\b", r"\1UIRequest({type=\2, view=self.localCupView", code)
    assert count == 12
    patched["Layer_cup"] = code
    code = read_script("window_cup").decode("utf-8").replace("\r\n", "\n")
    for marker in ("function cup.open(self,touchPriority,data,callback)\n", "function cup.close(self)\n"):
        assert code.count(marker) == 1
        code = code.replace(marker, marker + "    self.localCupGeneration=(self.localCupGeneration or 0)+1\n")
    marker = "    self.touchPriority = touchPriority\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localCupView=data.view\n")
    marker = '    self.rootItems.rewardTxt:setString("开服"..curTime.."天后奖励提升");'
    assert code.count(marker) == 1
    code = code.replace(marker, '    self.rootItems.rewardTxt:setString("仅真实胜场发奖，轮空不计")')
    start = code.index("    local curNum = tostring(self:getIndexByLevel())")
    end = code.index('    ui.setLabelString(self.rootItems.name_a', start)
    code = code[:start] + code[end:]
    start = code.index("    -- ui.setLabelString(self.rootItems.bet_a_buttontext")
    end = code.index("    for i=1,7 do", start)
    code = code[:start] + '''    self.rootItems.hasbetNode:setVisible(false)
    self.rootItems.betNode:setVisible(false)
    self.rootItems.palyNode:setVisible(data.status>=0)
    ui.setLabelString(self.rootItems.playlab,"重 播",18)
    self.rootItems.playbutton:addHandleOfControlEvent(function()
        if self.data.status>=0 then
            UIRequest({type=2103,round=self.data.round,id=self.data.id,view=self.localCupView,generation=self.localCupGeneration})
        end
    end,CCControlEventTouchUpInside)
    self.rootItems.playbutton:setSwallowsTouch(true)
    self.rootItems.playbutton:setTouchPriority(self.touchPriority)

''' + code[end:]
    marker = '    UIRequest({type = 12001, cids = {self.xcid}, order=21001})'
    assert code.count(marker) == 1
    patched["window_cup"] = code.replace(marker, "")
    code = read_script("language_CN").decode("utf-8").replace("\r\n", "\n")
    for old, new in (("玩家可以在每天9点到24点报名参加次日的杯赛", "每天9至23点报名次日杯赛，不足2人不开赛"),
                     ("竞猜阶段：", "淘汰阶段（本地不开放竞猜）：")):
        assert code.count(old) == 1
        code = code.replace(old, new)
    patched["language_CN"] = code
    return patched


def patch_collection_scripts():
    patched = {}
    code = read_script("GameCollect").decode("utf-8").replace("\r\n", "\n")
    assert "function UITeamRecomRewardCallBack(" in code
    with open(os.path.join(os.path.dirname(__file__), "client_patches", "progress_network.lua"), encoding="utf-8") as stream:
        patched["GameCollect"] = code + "\n" + stream.read()
    for name, module, generation, opcodes, expected in (
            ("Layer_collect", "collect", "localCollectionView", "1015|1103|3910|3911", 5),
            ("Layer_achievement", "task", "localAchievementView", "2400|2401", 3)):
        code = read_script(name).decode("utf-8").replace("\r\n", "\n")
        for signature in (f"function {module}.init(self,parent,toppos" + (", _type)" if module == "collect" else ")"),
                          f"function {module}.clear(self)"):
            marker = signature + (" -- 加了一个generalType 判断进哪个页面" if module == "collect" and ".init(" in signature else "") + "\n"
            assert code.count(marker) == 1
            code = code.replace(marker, marker + f"    self.{generation}=(self.{generation} or 0)+1\n")
        code, count = re.subn(r"(?m)^(\s*)UIRequest\(\{type\s*=\s*(" + opcodes + r")\b",
                             r"\1UIRequest({type=\2, view=self." + generation, code)
        assert count == expected
        patched[name] = code
    code = read_script("UICollect").decode("utf-8").replace("\r\n", "\n")
    patched["UICollect"] = code + '''
for _,name in ipairs({"UIGeneralCollect","UIEquipCollect","UITeamRecomQuery","UITeamRecomReward"}) do
    local original=_G[name]
    _G[name]=function(t)
        if t.localSkip then return end
        if t.view then
            local layer=GameScene.layers.collect
            if not layer or not layer.show or t.view~=layer.module.localCollectionView then return end
        end
        return original(t)
    end
end
'''
    code = read_script("UITask").decode("utf-8").replace("\r\n", "\n")
    patched["UITask"] = code + '''
local function localAchievementPage(t)
    local layer=GameScene.layers.achievement
    return not t.localSkip and layer and layer.show and (not t.view or t.view==layer.module.localAchievementView)
end
local localTaskQuery=UITaskQuery
function UITaskQuery(t)
    if localAchievementPage(t) then return localTaskQuery(t) end
end
function UITaskComplete(t)
    if not localAchievementPage(t) then return end
    showRewardPopupWindow(t.reward,nil,function()
        if localAchievementPage(t) then UIRequest({type=2400,view=t.view}) end
    end)
end
'''
    return patched


def patch_guild_gameplay_scripts(patched):
    def load(name):
        path = "assets/scripts/" + name + ".so"
        if path not in patched:
            return read_script(name).decode("utf-8").replace("\r\n", "\n")
        raw = xxtea_decrypt(patched[path], XXTEA_KEY)
        return raw[:struct.unpack("<I", raw[-4:])[0]].decode("utf-8")

    def put(name, code):
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, filename in (("GameGang", "guild_network.lua"), ("GameGuildWar", "guild_war_network.lua")):
        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "client_patches", filename), encoding="utf-8") as stream:
            put(name, load(name) + "\n" + stream.read())
    code = load("gameserver")
    marker = "    [5151] = NetGang2GroundStartCallBack,"
    assert code.count(marker) == 1
    put("gameserver", code.replace(marker, marker + "\n    [5152] = NetGang2GroundGetHogsCallBack,\n    [5153] = NetGang2GroundCatchHogCallBack,"))

    code = load("UIGang")
    marker = '    print("帮会2278，接受客户端数据")\n    runGamePrompt({msg = "设置成功"})'
    assert code.count(marker) == 1
    code = code.replace(marker, '''    print("帮会2278，接受客户端数据")
    runGamePrompt({msg=t.method==1 and "伙伴经验按20000兑换1颗神奇经验丹，余量保留" or "已关闭伙伴经验转换"})''')
    marker = "function UIGang2SkillStudy( t )\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    UIRequest({type=2262})\n    UIRequest({type=2230})\n")
    start = code.index("function UIGang2GetFeastReward( t )\n")
    end = code.index("--盛宴刷新", start)
    code = code[:start] + '''function UIGang2GetFeastReward(t)
    local layer = GameScene.layers["guildfeast"]
    if layer.show then
        layer.module.needoutext = false
        layer.module:awardCallback(t)
    elseif t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward)
    end
end

''' + code[end:]
    code += '''
local localGuardQuery = UIGang2GroundQuery
function UIGang2GroundQuery(t)
    localGuardQuery(t)
    if t.data.localRunning and GameScene.layers.gang_guard.show then
        UIRequest({type=5156, highScore=t.data.highScore})
    end
end
function UIGang2GroundGetHogs(t)
    local layer = GameScene.layers.gang_guard
    if not layer.show then return end
    if t.status == 3 then
        UIRequest({type=5156, highScore=layer.module.highScore})
    elseif t.mouseNum > 0 then
        layer.module:getMouseData(t)
    else
        layer.module.isAppear = 0
    end
end
function UIGang2GroundCatchHog(t)
    local layer = GameScene.layers.gang_guard
    if not layer.show then return end
    if t.mouseData and t.mouseData.hp then
        t.status=0
        layer.module:catchMouseData(t)
    end
end
'''
    put("UIGang", code)
    code = load("Layer_guild2_guard")
    marker = "function guildguard.getMouseData( self,data )\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    if not self.rootNode or not data.mouseTab or #data.mouseTab == 0 then self.isAppear=0; return end\n")
    marker = "            local i=v.point\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "            local targetToken=v.token\n            self.mouseHoleData[i].token=targetToken\n")
    marker = "UIRequest({type = 5153, point = i,status = 1})"
    assert code.count(marker) == 1
    code = code.replace(marker, "UIRequest({type=5153,point=i,status=1,token=self.mouseHoleData[i] and self.mouseHoleData[i].token})")
    marker = "UIRequest({type = 5153, point = i,status = 0})"
    assert code.count(marker) == 1
    code = code.replace(marker, "UIRequest({type=5153,point=i,status=0,token=targetToken})")
    marker = '            if self.mouseHoleData[i] then\n                self.mouseHoleTab["animationManager"..i]:setAnimationCompletedCallback(function()\n'
    assert code.count(marker) == 1
    code = code.replace(marker, '''            if self.mouseHoleData[i] then
                local clickedToken=self.mouseHoleData[i].token
                self.mouseHoleTab["animationManager"..i]:setAnimationCompletedCallback(function()
                    if not self.rootNode or not self.mouseHoleData[i] or self.mouseHoleData[i].token~=clickedToken then return end
''')
    marker = '            self.rootItems["mouseNode"..i]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(self:getGuardSpeed(self.scoreNum)), CCCallFunc:create(function()\n'
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '                if not self.rootNode or not self.mouseHoleData[i] or self.mouseHoleData[i].token~=targetToken then return end\n')
    put("Layer_guild2_guard", code)

    for name, obj, kind, opcode in (("Layer_guild_feast", "guildfeast", 1, 2274), ("Layer_guild_zaotang", "guildzaotang", 6, 2284)):
        code = load(name)
        pattern = r'UIRequest\(\{type = 3011, content = "[^"\n]+"\.\.self.roomId\}\)'
        code, count = re.subn(pattern, '-- 邀请由确认窗口发送一次', code)
        assert count == 2
        marker = f'{{barrageType = {kind}}},callback)'
        assert code.count(marker) == (1 if kind == 1 else 0)
        code = code.replace(marker, f'{{barrageType = {kind},params={{self.roomId}}}},callback)')
        if name == "Layer_guild_feast":
            start = code.index('    if isfirst == true then\n        for i = 1, 13 do\n')
            end = code.index('\nend\n', start)
            code = code[:start] + code[end:]
        # 原界面固定七个头像，其余席位仅显示实际总人数，不填造假成员。
        marker = 'local idx = v.params["1"].i'
        assert marker in code
        start = code.index(f"function {obj}.updataDaojishi(self)\n")
        end = code.index("\nend", start) + len("\nend")
        code = code[:start] + f'''function {obj}.updataDaojishi(self)
    local nextPoll=os.time()+5
    self.localRoomPoll=CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        if self.rootNode and os.time()>=nextPoll then
            nextPoll=os.time()+5
            if not self.isGetReward then
                UIRequest({{type={opcode},roomid=self.roomId}})
                if self.data and self.data.feastStatus~=1 and self.myFeastTime<=0 then self:award() end
            end
        end
    end,1,false)
end''' + code[end:]
        marker = f"function {obj}.clear(self)"
        start = code.index(marker)
        line_end = code.index("\n", start)
        code = code[:line_end + 1] + '''    if self.localRoomPoll then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.localRoomPoll)
        self.localRoomPoll=nil
    end
''' + code[line_end + 1:]
        put(name, code)


def patch_cheer_scripts(patched):
    def load(name):
        path = "assets/scripts/" + name + ".so"
        if path not in patched:
            return read_script(name).decode("utf-8").replace("\r\n", "\n")
        raw = xxtea_decrypt(patched[path], XXTEA_KEY)
        return raw[:struct.unpack("<I", raw[-4:])[0]].decode("utf-8")

    def put(name, code):
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = load("gamedata")
    marker = "        self.cache.cheers[v.sid] = self:cheerData(v)"
    assert code.count(marker) == 1
    put("gamedata", code.replace(marker, "        self.cache.cheers[v.sid] = v.general and v.general > 0 and self:cheerData(v) or nil"))

    code = load("GameSlots")
    start = code.index("function NetSlotsAllInfoCallBack(fd)\n")
    end = code.index("\nfunction ", start + 1)
    block = code[start:end]
    marker = "    gamedata:SlotInfoProcess(info)\n"
    assert block.count(marker) == 1
    code = code[:start] + block.replace(marker, "    gamedata.cache.cheers = {}\n" + marker) + code[end:]
    start = code.index("function UIChangeCheerCallBack(uireq)\n")
    end = code.index("\nfunction ", start + 1)
    block = code[start:end]
    assert block.count("if uireq.iid then") == 1
    assert block.count("GeneralChangePos:SerializeToString()") == 1
    block = block.replace("if uireq.iid then", "if uireq.iid and uireq.iid ~= 0 then")
    # 撤下显式携带IID=0，不能依赖可选字段的默认值。
    block = block.replace("GeneralChangePos:SerializeToString()", 'GeneralChangePos:SerializeToString() .. (uireq.iid == 0 and string.char(24,0) or "")')
    code = code[:start] + block + code[end:]
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "client_patches", "cheer_network.lua"), encoding="utf-8") as stream:
        put("GameSlots", code + "\n" + stream.read())

    code = load("UISlots")
    marker = '    UIRequest({type = 10322,param = {"cheer"}})'
    assert code.count(marker) == 1
    put("UISlots", code.replace(marker, "    UIRequest({type = 10021})"))

    code = load("window_generalInfo_role")
    marker = "function generalInfo.reload(self,data,callback)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localCheerGeneration = (self.localCheerGeneration or 0) + 1\n")
    marker = "function generalInfo.close(self)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.localCheerGeneration = (self.localCheerGeneration or 0) + 1\n")
    marker = "function generalInfo.setPage_info(self)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    local cheerGeneration = self.localCheerGeneration\n    local cheerIID, cheerSID = self.data.general.iid, self.cheersid\n")
    marker = "            local cheersid = self.cheersid or 1\n            local callback = function(selectedData)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "                if not self.root or self.localCheerGeneration ~= cheerGeneration or self.data.general.iid ~= cheerIID or self.cheersid ~= cheerSID then return end\n")
    marker = "    self.infoItems.doButton4:addHandleOfControlEvent(function()\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''        if self.opt == 3 then
            if not self.root or self.localCheerGeneration ~= cheerGeneration or self.data.general.iid ~= cheerIID or self.cheersid ~= cheerSID or not GameScene:checkopenlevelbyId(135) then return end
            GameScene:shiftLayer("generalup","up",{cid=self.data.general.cid,page="up",sid=self.sid or 1})
            return
        end
''')
    marker = "    self.infoItems.doButton7:addHandleOfControlEvent(function()\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''        if self.opt == 3 then
            if not self.root or self.localCheerGeneration ~= cheerGeneration or self.data.general.iid ~= cheerIID or self.cheersid ~= cheerSID then return end
            UIRequest({type=1004,pos1=cheerSID,iid=0})
            self.callback = nil
            gameWindows:closeWindowDirect("generalInfoRole")
            return
        end
''')
    marker = "    self:getMessage(generalConfig)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, '''    if self.opt == 3 then
        ui.setLabelString(self.infoItems.doLab4,"升 级",19)
        ui.setLabelString(self.infoItems.doLab7,"撤 下",19)
        for _,i in ipairs({4,7}) do
            self.infoItems["doButton"..i]:setEnabled(true)
            ui.removeGray("CCControlButton",self.infoItems["doButton"..i])
            ui.removeGray("CCLabelTTF",self.infoItems["doLab"..i])
        end
        for _,i in ipairs({5,6}) do
            self.infoItems["doButton"..i]:setEnabled(false)
            ui.addGray("CCControlButton",self.infoItems["doButton"..i])
            ui.addGray("CCLabelTTF",self.infoItems["doLab"..i])
        end
    end
''' + marker)
    put("window_generalInfo_role", code)


def patch_soul_scripts(patched):
    def load(name, section="scripts"):
        path = f"assets/{section}/{name}.so"
        if path not in patched:
            return read_script(name, section).decode("utf-8").replace("\r\n", "\n")
        raw = xxtea_decrypt(patched[path], XXTEA_KEY)
        return raw[:struct.unpack("<I", raw[-4:])[0]].decode("utf-8")

    def put(name, code, section="scripts"):
        patched[f"assets/{section}/{name}.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    def replace(code, old, new, count=1):
        assert code.count(old) == count, old
        return code.replace(old, new)

    def generation(code, prefix, methods):
        for method in methods:
            marker = f"function {prefix}.{method}(self"
            start = code.index(marker)
            end = code.index("\n", start)
            code = code[:end+1] + "    self.localSoulGeneration = (self.localSoulGeneration or 0) + 1\n" + code[end+1:]
        return code

    code = load("gamedata")
    start = code.index("function gamedata.SoulHunt(self,data,param)\n")
    end = code.index("function gamedata.findcombskilllevel(", start)
    code = code[:start] + '''function gamedata.SoulHunt(self,data,param)
    local tokens = math.max(0,data.soul-(self.cache.soulhunt.soul or 0))
    self:SoulHuntQuery(data)
    return self:Souls(data.souls),tokens
end

''' + code[end:]
    put("gamedata", code)
    code = load("GameSlots")
    start = code.index("function NetSlotsAllInfoCallBack(fd)\n")
    end = code.index("\nfunction ", start+1)
    block = replace(code[start:end], "    gamedata:SlotInfoProcess(info)\n", "    gamedata.cache.souls = {}\n    gamedata:SlotInfoProcess(info)\n")
    code = code[:start] + block + code[end:]
    put("GameSlots", code)

    for name, filename in (("GameSoul", "soul_network.lua"), ("UISouls", "soul_ui.lua")):
        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "client_patches", filename), encoding="utf-8") as stream:
            put(name, load(name) + "\n" + stream.read())
    code = load("GameErrorMessage", "common_lua")
    marker = "    if gamedata and gamedata.ext and gamedata.ext.localFormationBusy"
    start = code.index(marker)
    code = code[:start] + '''    if gamedata and gamedata.ext then
        if gamedata.ext.localSoulBusy == error.ids[1] then gamedata.ext.localSoulBusy = nil end
        local queue = (gamedata.ext.localSoulPending or {})[error.ids[1]] or {}
        table.remove(queue,1)
    end
''' + code[start:]
    put("GameErrorMessage", code, "common_lua")
    code = load("UISlots")
    for first, last in (("UISlotChangeSoul", "UIQuickEquip"), ("UIQuickEquip", "UIUpgradeSkill")):
        start, end = code.index(f"function {first}(t)"), code.index(f"function {last}(t)")
        block = replace(code[start:end], "    UIRequest({type = 10322})", "    if t.method == 1 then UIRequest({type = 10322}) end" if first == "UIQuickEquip" else "    -- 服务端已返回真实命格/阵容，无需旧服战力重算接口。")
        code = code[:start] + block + code[end:]
    put("UISlots", code)
    code = load("UIProps")
    for order, name in ((25061, "soulInfo"), (33007, "soul"), (32021, "buyItem")):
        marker = f"    elseif t.order == {order} then\n"
        code = replace(code, marker, marker + f'        if not LocalSoulMatch(t.soulView,"{name}") then return end\n')
    put("UIProps", code)

    code = generation(load("Layer_soul"), "soul", ("init", "clear"))
    code = replace(code, "if data.level < integrateconfig.cond then", "if data.level ~= integrateconfig.cond then")
    code = replace(code, "elseif not (data.generalcid and data.generalcid > 0) then", "elseif data.generalcid and data.generalcid > 0 then")
    code = replace(code, 'runGamePrompt({msg=gameConfig.strings:string_common("soul",15)})', 'runGamePrompt({msg="合成需要两个闲置且恰好10级的命格，请先卸下"})')
    code = replace(code, 'runGamePrompt({msg=gameConfig.strings:need_soul_lv(integrateconfig.cond)})', 'runGamePrompt({msg="合成材料必须恰好10级，更高等级不能消耗"})')
    code = replace(code, 'self.rootItems.newtext:setString("灵石猎命每次奖励一个元命");', 'self.rootItems.newtext:setString("每次1灵石及2万银币，另获1元命");')
    for method in ("makeHuntAnimation", "relaodHunt"):
        start = code.index(f"function soul.{method}(")
        end = code.index("\nfunction ", start+1)
        block = code[start:end]
        line = block.index("\n")
        binding = "    self.localSoulAnimation = (self.localSoulAnimation or 0) + 1\n" if method == "relaodHunt" else ""
        block = block[:line+1] + binding + "    local generation,animation = self.localSoulGeneration,self.localSoulAnimation\n" + block[line+1:]
        for marker in ("setAnimationCompletedCallback(function()\n", "CCCallFunc:create(function()\n"):
            block = block.replace(marker, marker + "            if not self.rootNode or self.localSoulGeneration ~= generation or self.localSoulAnimation ~= animation then return end\n")
        code = code[:start] + block + code[end:]
    put("Layer_soul", code)

    code = generation(load("Layer_soulResolveList"), "soullist", ("init", "clear"))
    start = code.index("            UIRequest({type = 2506, ids = ids})")
    code = code[:start] + replace(code[start:], '            UIRequest({type = 2506, ids = ids})\n            gamedata.music:PlayOptSound("fj")', '            LocalSoulResolve(ids,"soulResolveList")')
    put("Layer_soulResolveList", code)

    code = generation(load("window_soulInfo"), "soulInfo", ("reload", "close"))
    start, end = code.index("    self.infoItems.resolveButton:addHandleOfControlEvent"), code.index("    self.infoItems.resolveButton:setSwallowsTouch")
    code = code[:start] + '''    local generation,iid = self.localSoulGeneration,self.data.iid
    self.infoItems.resolveButton:addHandleOfControlEvent(function()
        if not self.root or self.localSoulGeneration ~= generation or self.data.iid ~= iid then return end
        if self.data.fromtype == "slot" then
            UIRequest({type=1006,slot=self.data.sid,soulpos=self.data.soulpos,soulid=0})
            self.callback=nil
            gameWindows:closeWindowDirect("soulInfo")
        else LocalSoulResolve({iid},"soulInfo") end
    end, CCControlEventTouchUpInside)
''' + code[end:]
    code = replace(code, '''        self.infoItems.resolveNode:setVisible(false)
        self.infoItems.resolveButton:setEnabled(false)''', '''        self.infoItems.resolveNode:setVisible(true)
        self.infoItems.resolveButton:setEnabled(true)
        ui.setLabelString(self.infoItems.resolveLab,"卸 下",19)''')
    start = code.index("    self.infoItems.changeButton:addHandleOfControlEvent")
    end = code.index("    self.infoItems.changeButton:setSwallowsTouch", start)
    code = code[:start] + '''    self.infoItems.changeButton:addHandleOfControlEvent(function()
        local sid,pos = self.data.sid,self.data.soulpos
        gameWindows:closeWindowDirect("soulInfo")
        local closedGeneration = self.localSoulGeneration
        local callback = function(selectedData)
            if self.root or self.localSoulGeneration ~= closedGeneration then return end
            for _,item in pairs(selectedData) do UIRequest({type=1006,slot=sid,soulpos=pos,soulid=item.iid});break end
        end
        gameWindows:openWindow("selectlist",{type="changesoul",param={sid=sid,soulpos=pos,iid=iid}},callback)
    end, CCControlEventTouchUpInside)
''' + code[end:]
    marker = "function soulInfo.setPage_up(self)\n"
    code = replace(code, marker, marker + "    local generation,iid = self.localSoulGeneration,self.data.iid\n")
    marker = "    self.upItems.doButton:addHandleOfControlEvent(function()\n"
    code = replace(code, marker, marker + "        if not self.root or self.localSoulGeneration ~= generation or self.data.iid ~= iid then return end\n")
    put("window_soulInfo", code)

    code = generation(load("Layer_slotsInfo"), "slotsInfo", ("init", "clear"))
    marker = '            elseif self.status == "soul" then\n'
    code = replace(code, marker, marker + "                local generation,sid = self.localSoulGeneration,self.sid\n")
    marker = '                            UIRequest({type=1006,slot = slotdata.sid, soulpos =slotdata["s"..i].soulpos, soulid = v.iid})'
    code = replace(code, marker, '                            if not self.rootNode or self.localSoulGeneration ~= generation or self.sid ~= sid or self.status ~= "soul" then return end\n' + marker)
    put("Layer_slotsInfo", code)

    code = generation(load("window_soulintegrate"), "soulintegrate", ("reload", "close"))
    code = replace(code, "if v.generalcid and (v.generalcid == self.data.generalcid) then", "if not v.generalcid or v.generalcid == 0 then")
    code = replace(code, "v.level >= integrateconfig.cond", "v.level == integrateconfig.cond", 2)
    code = replace(code, "    local cid1,cid2 = 0,0", "    local generation = self.localSoulGeneration\n    local cid1,cid2 = 0,0")
    marker = "                UIRequest({type = 2507, iid1 = iid1, iid2 = iid2})"
    code = replace(code, marker, "                if not self.rootNode or self.localSoulGeneration ~= generation then return end\n" + marker)
    marker = "function soulintegrate.compound(self)\n"
    code = replace(code, marker, marker + "    local generation = self.localSoulGeneration\n")
    marker = "        self.animationManager:setAnimationCompletedCallback(function()\n"
    code = replace(code, marker, marker + "            if not self.rootNode or self.localSoulGeneration ~= generation then return end\n")
    put("window_soulintegrate", code)

    code = load("window_soul_fast")
    for count in (10, 100, 1000):
        code = replace(code, f"data.xnum and data.xnum*{count} or 0", '"按次计费"')
    marker = "    --\n    if data and data.hunt and data.hunt == 6 then"
    code = replace(code, marker, '    ui.setLabelString(self.rootItems.selectDesc,data.hunt == 6 and "每次1灵石及2万银币，另获1元命" or "银币按阶段逐次计费；不足整批回滚",1)\n' + marker)
    put("window_soul_fast", code)
    code = generation(load("window_buyItem"), "buy", ("reload", "close"))
    # 绝对Role随5345回复推送，避免旧角色回调重新打开/覆盖购买窗口。
    start, end = code.index("    setroleupdatacallback(function()"), code.index("\nend\n", code.index("function buy.buySuccess"))
    code = code[:start] + code[end:]
    put("window_buyItem", code)


def patch_equip_evolve_scripts(patched):
    def load(name, folder="scripts"):
        path = f"assets/{folder}/{name}.so"
        if path not in patched:
            return read_script(name, folder).decode("utf-8").replace("\r\n", "\n")
        raw = xxtea_decrypt(patched[path], XXTEA_KEY)
        return raw[:struct.unpack("<I", raw[-4:])[0]].decode("utf-8")

    def put(name, code, folder="scripts"):
        patched[f"assets/{folder}/{name}.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, filename in (("GameEquipStage", "equip_evolve_network.lua"), ("UIEquipStage", "equip_evolve_ui.lua")):
        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "client_patches", filename), encoding="utf-8") as stream:
            put(name, load(name) + "\n" + stream.read())

    code = load("GameErrorMessage", "common_lua")
    marker = "    if gamedata and gamedata.ext and gamedata.ext.localFormationBusy"
    assert code.count(marker) == 1
    index = code.index(marker)
    code = code[:index] + '''    if gamedata and gamedata.ext and gamedata.ext.localEquipGrowthBusy and gamedata.ext.localEquipGrowthBusy.opcode == error.ids[1] then
        gamedata.ext.localEquipGrowthBusy = nil
    end
''' + code[index:]
    put("GameErrorMessage", code, "common_lua")

    for name, prefix, methods, target in (
        ("Layer_equip_up", "equipUp", ("init", "reload", "reloaddata", "clear", "shiftPage"), "self.data"),
        ("Layer_equipstage", "equipstage", ("init", "reloadStatus", "clear"), "self.chooseData[1]"),
    ):
        code = load(name)
        for method in methods:
            start = code.index(f"function {prefix}.{method}(self")
            end = code.index("\n", start)
            code = code[:end+1] + "    self.localEquipGrowthGeneration = (self.localEquipGrowthGeneration or 0) + 1\n" + code[end+1:]
        start = code.index("                local limilvconfig = gamedata.config.equip_evolvelv")
        end = code.index("                UIRequest({type = 1122", start)
        assert "limilvconfig" in code[start:end] and "stage" in code[start:end]
        code = code[:start] + f'''                local targetCID,targetLevel = LocalEquipGrowthNext({target})
                if not targetCID then runGamePrompt({{msg="装备已达最高进阶"}});return end
                local quality = gamedata.config.equip[tostring(targetCID)].quality
                local needed = gamedata.config.equip_evolvelv[tostring(targetLevel)]["lv"..quality]
                if GameScene.roleinfo.level < needed then runGamePrompt({{msg="下一阶需要队伍"..needed.."级"}});return end
''' + code[end:]
        if prefix == "equipstage":
            for method in ("setHasItems", "setNothingItems"):
                start = code.index(f"function {prefix}.{method}(")
                end = code.index("\nfunction ", start+1)
                block = code[start:end]
                line = block.index("\n")
                block = block[:line+1] + "    local generation = self.localEquipGrowthGeneration\n" + block[line+1:]
                marker = "        local callback = function(selectedData)\n"
                assert block.count(marker) == 1
                block = block.replace(marker, marker + "            if not self.rootNode or self.localEquipGrowthGeneration ~= generation then return end\n")
                code = code[:start] + block + code[end:]
        put(name, code)

    code = load("UIProps")
    for order, next_order in ((14002, 14003), (14003, 14004)):
        start = code.index(f"    elseif t.order == {order} then")
        end = code.index(f"    elseif t.order == {next_order} then", start)
        block = code[start:end]
        for name in ("equipsup", "equipstage"):
            marker = f'if GameScene.layers["{name}"].show then'
            if marker in block:
                block = block.replace(marker, f'if LocalEquipGrowthPage(t.growthView,"{name}") then')
        code = code[:start] + block + code[end:]
    put("UIProps", code)


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
    marker = "    local error = initPb(ids_pb, fd)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if gamedata and gamedata.ext and gamedata.ext.localGuildBusy == error.ids[1] then gamedata.ext.localGuildBusy = nil end
    if gamedata and gamedata.ext then
        if gamedata.ext.localWorldBossBusy==error.ids[1] then gamedata.ext.localWorldBossBusy=nil end
        local pending=gamedata.ext.localWorldBossPending or {}
        local queue=pending[error.ids[1]] or {}
        table.remove(queue,1)
        if #queue==0 then pending[error.ids[1]]=nil end
    end
    if gamedata and gamedata.ext then
        if gamedata.ext.localCupBusy==error.ids[1] then gamedata.ext.localCupBusy=nil end
        local pending=gamedata.ext.localCupPending or {}
        local queue=pending[error.ids[1]] or {}
        table.remove(queue,1)
        if #queue==0 then pending[error.ids[1]]=nil end
    end
    if gamedata and gamedata.ext then
        if gamedata.ext.localProgressBusy==error.ids[1] then gamedata.ext.localProgressBusy=nil end
        local pending=gamedata.ext.localProgressPending or {}
        local queue=pending[error.ids[1]] or {}
        table.remove(queue,1)
        if #queue==0 then pending[error.ids[1]]=nil end
    end
    if gamedata and gamedata.ext then
        local pending=gamedata.ext.localFriendPending or {}
        local queue=pending[error.ids[1]] or {}
        table.remove(queue,1)
        if #queue==0 then pending[error.ids[1]]=nil end
        if gamedata.ext.localFriendBusy==error.ids[1] then gamedata.ext.localFriendBusy=nil end
        if error.ids[1]==1020 then table.remove(gamedata.ext.localOtherSlotsRequests or {},1) end
        if error.ids[1]==1022 then gamedata.ext.localSparRequest=nil end
    end
    if error.ids[1] == 1120 or error.ids[1] == 1121 or error.ids[1] == 1124 then
        gamedata.ext.localBaptizeBusy = false
    end
    if error.ids[1] == 1140 or error.ids[1] == 1141 then
        gamedata.ext.localSigilBusy = false
    end
    if error.ids[1] == 1118 or error.ids[1] == 1119 or error.ids[1] == 1210 then
        gamedata.ext.localTreasureBusy = false
    end
    if error.ids[1] == 1013 or error.ids[1] == 1014 or error.ids[1] == 1126 then
        gamedata.ext.localFosterBusy = nil
    end
    if gamedata and gamedata.ext and gamedata.ext.localMagicBusy and gamedata.ext.localMagicBusy.opcode == error.ids[1] then
        gamedata.ext.localMagicBusy = nil
    end
    if gamedata and gamedata.ext and gamedata.ext.localFormationBusy and gamedata.ext.localFormationBusy.opcode == error.ids[1] then
        gamedata.ext.localFormationBusy = nil
    end
''')
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
    code = code.replace(marker, marker + "    if AutoCopyServerError then AutoCopyServerError(t) end\n    if LocalWorldBossError then LocalWorldBossError(t) end\n")
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
    code = code.replace(marker, marker + "    if AutoCopyLocalReject and AutoCopyLocalReject(t) then return end\n    if LocalWorldBossError then LocalWorldBossError(t) end\n")
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
    marker = "    GameScene.vipstatus= t.vipstatus\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    local window = gameWindows.windows.buyProperty
    if window and window.show then window.module:reloadData(window.module.data) end
''')
    patched["assets/scripts/UIRecharge.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched UIRecharge.so (local simulated payment and persisted entitlement refresh)")

    # 福利查询每次取服务端日/月状态，避免跨日仍使用上一次的已领缓存。
    callbacks = {
        "GameActivityMammon": (("UIActivityMammonQueryCallBack", 2015),),
        "GameEatChicken": (("UIActivityEatChickenQueryCallBack", 2010),),
        "GameActivityReward": (("UIContinue7QueryCallBack1", 214),),
        "GameSignIn": (("UISignIn2StatusCallBack", 3641), ("UILuxurySignInStatusCallBack", 3643)),
        "GameRecharge": (("UIVipStatusCallBack", 300), ("UIMonthCardCallBack", 2090), ("UIGrowPlan2CallBack", 7091)),
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
            start = code.index("function UIUserGang2CallBack(uireq)\n")
            end = code.index("\nfunction NetUserGang2CallBack(fd)", start)
            assert "gamedata.ext.gang2statusparam" in code[start:end]
            code = code[:start] + '''function UIUserGang2CallBack(uireq)
    gamedata.ext.gang2statusparam = uireq.param
    return 1, 2230, nil
end
''' + code[end:]
            for request, response, opcode in (
                ("UIUserGang2PrayCallBack", "NetUserGang2PrayCallBack", 2251),
                ("UIGuideShopBuyGoodsCallBack", "NetGuideShopBuyGoodsCallBack", 2253),
                ("UIUserGang2FishpondFeedCallBack", "NetUserGang2FishpondFeedCallBack", 2257),
                ("UIUserGang2FishpondRewardCallBack", "NetUserGang2FishpondRewardCallBack", 2258),
                ("UIUserGang2MSetNameCallBack", "NetUserGang2MSetNameCallBack", 2259),
                ("UIUserGang2DailyRewardCallBack", "NetUserGang2DailyRewardCallBack", 2260),
            ):
                marker = f"function {request}(uireq)\n"
                assert code.count(marker) == 1
                code = code.replace(marker, marker + '''    if gamedata.ext.localGuildBusy then
        return 0, 503, {type=503, msg="正在处理公会操作，请稍候"}
    end
''')
                start = code.index(marker)
                end = code.index("\nend", start)
                pattern = rf"(?m)^    return 1,\s*{opcode},"
                block, count = re.subn(pattern, f"    gamedata.ext.localGuildBusy = {opcode}\n    return 1, {opcode},", code[start:end])
                assert count == 1
                code = code[:start] + block + code[end:]
                marker = f"function {response}(fd)\n"
                assert code.count(marker) == 1
                code = code.replace(marker, marker + f"    if gamedata.ext.localGuildBusy == {opcode} then gamedata.ext.localGuildBusy = nil end\n")
        if name == "GameRecharge":
            start = code.index("function UIUserBuyCallBack(uireq)\n")
            end = code.index("\nfunction NetUserBuyCallBack(fd)", start)
            buy = code[start:end]
            marker = '''    if uireq.count then
        table.insert(UserBuyData.ids, uireq.count)
    end'''
            assert buy.count(marker) == 1
            buy = buy.replace(marker, '''    if uireq.cid == 1 or uireq.cid == 2 or uireq.cid == 3 or uireq.cid == 6 then
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

    code = read_script("window_guild2_xianchi").decode("utf-8").replace("\r\n", "\n")
    marker = "    if ListTableView then\n        ListTableView:reloadData()"
    assert code.count(marker) == 1
    code = code.replace(marker, "    if self.ListTableView then\n        self.ListTableView:reloadData()")
    patched["assets/scripts/window_guild2_xianchi.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_guild_shop2").decode("utf-8").replace("\r\n", "\n")
    marker = "function guildshop.makeConfig(self)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "    self.configdata = {}\n")
    marker = 'self.gangdata["level"] >= v.display_level'
    assert code.count(marker) == 1
    code = code.replace(marker, '(self.gangdata["level"] or 0) >= v.display_level')
    patched["assets/scripts/Layer_guild_shop2.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("UIGang").decode("utf-8").replace("\r\n", "\n")
    marker = '    GameScene.layers["gang_main"].module.gang = t.gang2status\n'
    assert code.count(marker) == 2
    code = code.replace(marker, marker + '''    if not t.gang2status.id or t.gang2status.id <= 0 then
        if GameScene.layers["gang_main"].show or (GameScene.layers["gang_xianchi"] and GameScene.layers["gang_xianchi"].show) then
            reloadGang(t.gang2status)
            return
        end
    elseif GameScene.layers["gang_main"].show then
        GameScene.layers["gang_main"].module:reloaddata(t.gang2status)
    end
''', 1)
    marker = '        GameScene.layers["gang_xianchi"].module:reloaddata(t.data)'
    assert code.count(marker) == 1
    code = code.replace(marker, '''        GameScene.layers["gang_xianchi"].module.gang = GameScene.layers["gang_main"].module.gang
''' + marker)
    marker = "    GameScene:addUpdate(1200)\n    UIRequest({type = 1001})\n"
    start = code.index("function UIGangUserGang2FishpondFeed(t)\n")
    end = code.index("function UIGangUserGang2FishpondReward(t)\n", start)
    assert code[start:end].count(marker) == 1
    code = code[:start] + code[start:end].replace(marker, marker + "    UIRequest({type = 2230})\n    UIRequest({type = 2256})\n") + code[end:]
    patched["assets/scripts/UIGang.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("GameChat").decode("utf-8").replace("\r\n", "\n")
    marker = "        opt = gangchatopt,\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + "        local_snapshot = gangchatopt == 1,\n")
    patched["assets/scripts/GameChat.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("Layer_chat").decode("utf-8").replace("\r\n", "\n")
    marker = "    UIRequest({type = 3010, opt = 1})\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    local nextGuildPoll = os.time() + 5
    self.localGuildPoll = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        if self.rootNode and GameScene.layers["chat"].show and self.selectpage == "guild" and os.time() >= nextGuildPoll then
            nextGuildPoll = os.time() + 5
            UIRequest({type = 3010})
        end
    end, 1, false)
''')
    marker = "function chat.clear(self)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if self.localGuildPoll then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.localGuildPoll)
        self.localGuildPoll = nil
    end
''')
    marker = "function chat.addNewChatguild(self,t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if t.local_snapshot then
        self.guildchatdata, self.guildplayerdata, self.guildsizeT, self.guildtotalT = {}, {}, {}, 0
    end
''')
    patched["assets/scripts/Layer_chat.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("window_chat_guildnew").decode("utf-8").replace("\r\n", "\n")
    marker = "function chat_guildnew.addNewChat(self,t)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    if t.local_snapshot then
        self.chatdata, self.playerdata, self.sizeT, self.totalT = {}, {}, {}, 0
    end
''')
    patched["assets/scripts/window_chat_guildnew.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

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
    marker = "    if not GeneralConfig or not next(GeneralConfig) then loadBattleConfig() end"
    assert code.count(marker) == 1
    code = code.replace(marker, "    loadBattleConfig()")
    patched["assets/scripts/battleReportConvert.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    code = read_script("GameCopy").decode("utf-8").replace("\r\n", "\n")
    marker = "    if next(gamedata.cache.copy) then\n"
    assert code.count(marker) == 1
    code = code.replace(marker, "    if next(gamedata.cache.copy) and not uireq.update then\n")
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

    daily_queries = "{" + ", ".join(f"[{opcode}]=true" for opcode in (
        214, 300, 2010, 2015, 2062, 2090, 2092, 2097, 3627, 3630, 3641, 3643, 3650,
        3680, 3682, 4615, 4810, 4813, 4814, 4890, 5000, 5010, 5015, 5017, 5020, 5022,
        5030, 5034, 5039, 7091, 7094, 8026, 8075, 8077)) + "}"
    code = read_script("GameScene").decode("utf-8").replace("\r\n", "\n")
    start = code.index("function gameScene.cacheresetrequest(self,order)\n")
    end = code.index("\nend", start) + len("\nend")
    assert "reqs= {1001,300,2300,1300" in code[start:end]
    code = code[:start] + '''function gameScene.cacheresetrequest(self,order)
    self:UICacheReset()
    local sent = {}
    local function query(opcode)
        if sent[opcode] then return end
        sent[opcode] = true
        UIRequest({type = opcode, update = true, param2 = opcode == 2000,
                   param = opcode == 1001 and "resume" or nil})
    end
    for _,opcode in ipairs({1001,300,1300,3610,1032,3200,3210,2410,2037,2000}) do
        query(opcode)
    end
    if self.layers.gang_xianchi and self.layers.gang_xianchi.show then query(2230) end
    for name,opcode in pairs({bloodbattle=3620, zhuxiantaiShop=3627, watchstar=2062,
                              starcopy_map=1350, gang_shangxiang=2250, gang_main=2230,
                              gang_xianchi=2256, shopList=4890, singleboss=3700}) do
        if self.layers[name] and self.layers[name].show then query(opcode) end
    end
    local chapter = self.layers.copy_chapter
    if chapter.show and chapter.module.selectpage == "star" then query(1350) end
    local layer = self.layers.activity
    if layer and layer.show then
        local activity = layer.module
        local page = activity.realPageTable[activity.presentPage]
        local opcode = page and page.request
        if page and page.id == 161 then
            opcode = page.module.tempRequestTable[page.module.pageId]
        end
        if page and page.id == 162 and page.module.tempActivityTable[page.module.pageId] == 27 then
            query(2230)
            query(2252)
        end
        local readable = ''' + daily_queries + '''
        if readable[opcode] then query(opcode) end
    end
end''' + code[end:]
    patched["assets/scripts/GameScene.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

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
    marker = "function activity.makepageconfig(self)\n"
    assert code.count(marker) == 1
    code = code.replace(marker, marker + '''    local readable = ''' + daily_queries + '''
    for _,page in pairs(self.activityPageconfig) do
        if readable[page.request] then page.needupdate = true end
    end
''')
    marker = "UIRequest({ type = self.realPageTable[page].request })"
    assert code.count(marker) == 2
    code = code.replace(marker, "UIRequest({ type = self.realPageTable[page].request, update = true })")
    patched["assets/scripts/Layer_activity.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    print("  [Lua] Patched Layer_activity.so (query activities only when selected)")

    code = read_script("Layer_activity_general_shop").decode("utf-8").replace("\r\n", "\n")
    start = code.index("function generalShop.refreshFunc(self,pageId)\n")
    end = code.index("\nend", start)
    assert "self:shiftPage(i)" in code[start:end]
    code = code[:end] + '''
    if self.tempRequestTable[self.pageId] == 3650 then UIRequest({type = 3650, update = true}) end
''' + code[end:]
    patched["assets/scripts/Layer_activity_general_shop.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_friend_copy_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_activity_copy_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_arena_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_cornucopia_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_single_boss_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_equip_baptize_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_sigil_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_treasure_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    for name, code in patch_general_foster_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    for name, code in patch_magic_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    for name, code in patch_friends_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    for name, code in patch_collection_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    for name, code in patch_cup_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    for name, code in patch_world_boss_scripts().items():
        patched["assets/scripts/" + name + ".so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    code = read_script("friends_pb", "pb").decode("utf-8").replace("\r\n", "\n")
    marker = "FRIENDS.fields = {FRIENDS_FRIENDS_FIELD, FRIENDS_MAX_FIELD}"
    assert code.count(marker) == 1
    code = code.replace(marker, '''local public_rid = protobuf.FieldDescriptor()
public_rid.name = "public_rid"
public_rid.full_name = ".Friends.public_rid"
public_rid.number = 3
public_rid.index = 2
public_rid.label = 1
public_rid.has_default_value = false
public_rid.default_value = 0
public_rid.type = 5
public_rid.cpp_type = 1
FRIENDS.fields = {FRIENDS_FRIENDS_FIELD, FRIENDS_MAX_FIELD, public_rid}''')
    patched["assets/pb/friends_pb.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)
    code = read_script("fosterconfirm_pb", "pb").decode("utf-8").replace("\r\n", "\n")
    marker = 'FOSTERCONFIRM.fields = {FOSTERCONFIRM_ID_FIELD, FOSTERCONFIRM_OPT_FIELD}'
    assert code.count(marker) == 1
    code = code.replace(marker, '''local token = protobuf.FieldDescriptor()
token.name = "token"
token.full_name = ".FosterConfirm.token"
token.number = 3
token.index = 2
token.label = 2
token.has_default_value = false
token.default_value = 0
token.type = 5
token.cpp_type = 1
FOSTERCONFIRM.fields = {FOSTERCONFIRM_ID_FIELD, FOSTERCONFIRM_OPT_FIELD, token}''')
    patched["assets/pb/fosterconfirm_pb.so"] = xxtea_encrypt(code.encode("utf-8"), XXTEA_KEY)

    patch_guild_gameplay_scripts(patched)
    patch_cheer_scripts(patched)
    patch_soul_scripts(patched)
    patch_equip_evolve_scripts(patched)
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
