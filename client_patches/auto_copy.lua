-- 普通副本挂机仅在本次页面运行，所有战斗、扫荡和费用仍由服务器结算。
local autoCopy = {active = false, pending = nil, layer = nil, page = 0, serial = 0}
-- 本地服务端不限流，原生1306/1307三秒闸门已在gameloop2解除；仅留一帧避免同帧重入。
local autoCopyInterval = 0.05
local autoCopyModes = {progress = "自动推图", stars = "扫描补星", sweep = "循环扫荡"}

local function autoCopyLabel(text)
    local layer = autoCopy.layer
    if layer and layer.autoCopyButton then
        local title = autoCopy.active and "挂机中" or "副本挂机"
        -- 旧标题辅助函数传CCString，与当前原生绑定要求的Lua字符串不兼容。
        for _, state in ipairs({CCControlStateNormal, CCControlStateHighlighted, CCControlStateDisabled}) do
            layer.autoCopyButton:setTitleForState(title, state)
            layer.autoCopyButton:setTitleColorForState(ccc3(82,42,14), state)
        end
        layer.autoCopyLabel:setString(text or "")
    end
end

function AutoCopyIsRunning()
    return autoCopy.active
end

function AutoCopyBlockManual()
    if autoCopy.active or autoCopy.pending then
        runGamePrompt({msg = "挂机或上一笔操作尚未结束；结果未知时请重进游戏"})
        return true
    end
    return false
end

function AutoCopyStop(reason)
    local wasActive = autoCopy.active
    autoCopy.active = false
    local layer = autoCopy.layer
    if layer and layer.autoCopyTimer then layer.autoCopyTimer:stopAllActions() end
    autoCopyLabel(autoCopy.pending and "等待操作结果" or "")
    if wasActive and reason then runGamePrompt({msg = reason}) end
end

function AutoCopyLocalReject(t)
    local pending = autoCopy.pending
    if pending and t.localAutoCopy == pending.local_auto_copy and t.localAutoOpcode == pending.type then
        autoCopy.pending = nil
        AutoCopyStop(t.msg or "挂机已停止：资源不足或操作正在结算")
        autoCopyLabel("")
        return true
    end
    return false
end

function AutoCopyServerError(t)
    local pending = autoCopy.pending
    if pending and t.request_opcode == pending.type and t.localAutoCopy == pending.local_auto_copy then
        autoCopy.pending = nil
        AutoCopyStop("挂机已停止：请求被拒绝，未自动重试")
        autoCopyLabel("")
    end
end

local function autoCopySchedule(seconds, callback)
    local timer = autoCopy.layer and autoCopy.layer.autoCopyTimer
    if not timer then return end
    timer:stopAllActions()
    -- 全局加速会缩短CCDelayTime；按真实整秒检查，并留一秒取整余量。
    local deadline = os.time() + math.ceil(seconds) + 1
    local function checkTime()
        local remaining = deadline - os.time()
        if remaining > 0 then
            timer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(remaining), CCCallFunc:create(checkTime)))
        else
            callback()
        end
    end
    timer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(seconds), CCCallFunc:create(checkTime)))
end

local function autoCopyReady()
    local layer = autoCopy.layer
    if not layer or not layer.rootNode or layer.datatype ~= "normal" or GameScene.presentLayer ~= "copy_map" or not GameScene.layers.copy_map.show then
        AutoCopyStop("挂机已停止：已离开普通副本")
        return false
    end
    if guide and guide.controller and guide.controller.isOnGuide then
        AutoCopyStop("挂机已停止：请先完成当前引导")
        return false
    end
    if getbattlecallbackactive and getbattlecallbackactive() then
        AutoCopyStop("挂机已停止：请先结束当前战斗")
        return false
    end
    for _, window in pairs(gameWindows.windows) do
        if window.show then
            AutoCopyStop("挂机已停止：请先处理当前弹窗")
            return false
        end
    end
    return true
end

local function autoCopyPoint(copy, map, point)
    for sectionID, section in pairs(copy or {}) do
        for mapID, row in pairs(section.maps or {}) do
            if row.id == map then
                for _, data in pairs(row.points or {}) do
                    if data.id == point then return data, tonumber(sectionID), tonumber(mapID) end
                end
            end
        end
    end
end

local function autoCopyTarget()
    if autoCopy.mode == "sweep" and autoCopy.target then return autoCopy.target end
    local target
    for _, section in pairs(autoCopy.copy or {}) do
        for _, map in pairs(section.maps or {}) do
            for _, point in pairs(map.points or {}) do
                local eligible = autoCopy.mode == "progress" and map.id >= autoCopy.startMap and point.star == 0
                    or autoCopy.mode == "stars" and point.star > 0 and point.star < 3 and not autoCopy.visited[map.id..":"..point.id]
                    or autoCopy.mode == "sweep" and point.star == 3
                local later = target and (map.id > target.map or map.id == target.map and point.id > target.point)
                if eligible and (not target or (autoCopy.mode == "sweep" and later) or
                        (autoCopy.mode ~= "sweep" and not later)) then
                    target = {map = map.id, point = point.id}
                end
            end
        end
    end
    return target
end

local function autoCopySend(req)
    if not autoCopy.active or autoCopy.pending or not autoCopyReady() then return end
    autoCopy.serial = autoCopy.serial + 1
    req.local_auto_copy = autoCopy.serial
    autoCopy.pending = req
    autoCopySchedule(20, function()
        if autoCopy.pending == req then AutoCopyStop("挂机已停止：操作结果未知，请重进游戏；不会自动重试扣费") end
    end)
    UIRequest(req)
end

local function autoCopyRefresh()
    if not autoCopy.active or not autoCopyReady() then return end
    -- 1001强制读取先于1300回复，购买/重置后的绝对资源及跨日次数在下一笔前校准。
    UIRequest({type = 1001, param = "error"})
    autoCopySend({type = 1300, update = true})
end

local function autoCopyContinue()
    local timer = autoCopy.layer and autoCopy.layer.autoCopyTimer
    if not timer then return end
    timer:stopAllActions()
    timer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(autoCopyInterval), CCCallFunc:create(autoCopyRefresh)))
end

local function autoCopyRun(role, vipstatus, now)
    if not autoCopyReady() then return end
    local target = autoCopyTarget()
    if not target then
        AutoCopyStop(autoCopy.mode == "stars" and "本轮补星扫描完成；未满三星的关卡可下轮再试" or "挂机已停止：没有符合模式的关卡")
        return
    end
    autoCopy.target = target
    local map, point = target.map, target.point
    local data = autoCopyPoint(autoCopy.copy, map, point)
    local config = gamedata.config.copy[tostring(map)]
    config = config and config[tostring(point)]
    if not data or not config or not role then AutoCopyStop("挂机已停止：关卡或资源状态无效"); return end
    if autoCopy.mode == "sweep" then
        local vip = gamedata.config.vip[tostring(role.vip)]
        if data.star ~= 3 or not vip or (role.level < tonumber(gamedata.config.global_kv.copy_wipe_level10.value) and vip.copy_sweep == 0) then
            AutoCopyStop("挂机已停止：尚未解锁此关卡批量扫荡"); return
        end
    end
    autoCopyLabel(autoCopyModes[autoCopy.mode].." "..map.."-"..point)
    local shortStamina = role.stamina < config.physical
    local shortChallenge = (data.kill or 0) >= config.challenge
    if shortChallenge and not autoCopy.reset then AutoCopyStop("挂机已停止：挑战次数不足"); return end
    if shortStamina and not autoCopy.buy then AutoCopyStop("挂机已停止：体力不足"); return end
    local resetPrice = shortChallenge and config.challenge * 5 or 0
    if shortStamina then
        if not vipstatus then autoCopySend({type = 300, update = true}); return end
        local used = vipstatus.b_physical
        local vip = gamedata.config.vip[tostring(role.vip)]
        if not used or not vip or used >= vip.b_physical then AutoCopyStop("挂机已停止：今日体力购买次数已达上限"); return end
        local price = gamedata.config.buycount_price[tostring(used + 1)]
        if not price or not now then AutoCopyStop("挂机已停止：体力报价无效"); return end
        price = price.stamina
        local weekday = (math.floor((now + 28800) / 86400) + 3) % 7 + 1
        for _, row in pairs(gamedata.config.activity_huodong) do
            if row.param == 3 and row.open_time == weekday then price = math.floor(price * row.modulus); break end
        end
        if role.gold < price + resetPrice then AutoCopyStop("挂机已停止：元宝不足以购买体力及所需重置"); return end
        autoCopySend({type = 301, cid = 2, count = 1, gold = price})
    elseif shortChallenge then
        if role.gold < resetPrice then AutoCopyStop("挂机已停止：重置所需元宝不足"); return end
        autoCopySend({type = 1305, map = map, point = point})
    else
        autoCopySend({type = autoCopy.mode == "sweep" and 1307 or 1306, map = map, point = point, method = autoCopy.mode == "sweep" and 1 or 0, exchange = 0})
    end
end

function AutoCopyHandle(t)
    if t.localAutoCopyIgnored then return true end
    if not t.localAutoCopy then
        if t.type == 1306 or t.type == 1307 then AutoCopyStop("挂机已停止：收到手动战斗结果") end
        return false
    end
    local pending = autoCopy.pending
    if not pending or t.localAutoCopy ~= pending.local_auto_copy or t.type ~= pending.type
            or pending.map and (t.map ~= pending.map or t.point ~= pending.point) then return true end
    autoCopy.pending = nil
    local layer = autoCopy.layer
    if layer and layer.autoCopyTimer then layer.autoCopyTimer:stopAllActions() end
    if not autoCopy.active then
        autoCopyLabel("")
        return t.type ~= 1306 and t.type ~= 1307
    end
    if t.copy then
        autoCopy.copy = t.copy
        copyDataReload(t)
    end
    if t.type == 1300 or t.type == 300 then
        autoCopyRun(t.localAutoRole, t.type == 300 and t.vipstatus or nil, t.localAutoTime)
        return true
    end
    if t.type == 1306 or t.type == 1307 then
        if (t.type == 1306 and t.result ~= 1) or t.result == 0 or not t.exp or (autoCopy.mode ~= "sweep" and t.exp.newlevel ~= t.exp.oldlevel)
                or (t.encounters and next(t.encounters)) or not autoCopyReady() then
            AutoCopyStop(t.result == 0 and "挂机已停止：本场未获胜" or "挂机已暂停：请处理当前战斗或升级")
            return false
        end
        autoCopy.visited[t.map..":"..t.point] = true
        updateDataLife(t.reward or {})
        GameScene:addUpdate(10021)
        GameScene:addUpdate(1012)
        GameScene:addUpdate(10023)
        setTriggerGiftEnable(true)
    end
    if layer and t.copy then
        local target = autoCopyTarget()
        local data, section, map
        if target then data, section, map = autoCopyPoint(t.copy, target.map, target.point) end
        layer:reloadnormalData(t.copy, data and {datatype = "normal", section = section, map = map, point = data.id} or nil)
    end
    autoCopyContinue()
    return true
end

function AutoCopyStart(mode, buy, reset)
    local layer, page = autoCopy.layer, autoCopy.page
    if not autoCopyModes[mode] or AutoCopyBlockManual() or not layer then return end
    if guide and guide.controller and guide.controller.isOnGuide then runGamePrompt({msg = "请先完成当前引导"}); return end
    if getbattlecallbackactive and getbattlecallbackactive() then runGamePrompt({msg = "请先结束当前战斗"}); return end
    local rules = mode == "progress" and "从当前地图开始连续挑战未通关主线；失败或升级时停止。"
        or mode == "stars" and "从头扫描已通关的1/2星关卡，每轮每关挑战一次；失败或升级时停止。"
        or "固定扫荡进度最靠后的三星关，每次按剩余次数和当前体力取最大可扫次数，不兑换经验；升级后继续。"
    rules = rules.."\n自动买体力："..(buy and "开（每次购买1份，按当前次数/星期报价，受VIP日限）" or "关")
        .."\n自动重置："..(reset and "开（每次关卡挑战次数×5元宝）" or "关")
        .."\n"..((buy or reset) and "可能连续消耗元宝直至不足；停止不能撤回已发出的扣费。" or "不购买体力、不用体力丹、不重置。")
    gameWindows:openWindow("confirm", {msg = rules}, function()
        if autoCopy.layer ~= layer or autoCopy.page ~= page or autoCopy.pending or autoCopy.active
                or (getbattlecallbackactive and getbattlecallbackactive()) then return end
        autoCopy.mode, autoCopy.buy, autoCopy.reset = mode, buy == true, reset == true
        autoCopy.startMap = layer.data.id
        autoCopy.target, autoCopy.visited = nil, {}
        autoCopy.active = true
        autoCopyLabel("准备"..autoCopyModes[mode])
        autoCopyContinue()
    end)
end

function AutoCopyAttach(layer, toppos)
    autoCopy.page = autoCopy.page + 1
    autoCopy.layer = layer
    layer.autoCopyTimer = CCNode:create()
    layer.rootNode:addChild(layer.autoCopyTimer)
    layer.autoCopyLabel = ui.createLabel({text = "", fontsize = 22, x = gameConfig.originSize.width - 400, y = toppos - 50})
    layer.rootNode:addChild(layer.autoCopyLabel)
    layer.autoCopyButton = CCControlButton:create("副本挂机", "Helvetica-Bold", 26)
    layer.autoCopyButton:setPreferredSize(CCSizeMake(190, 70))
    layer.autoCopyButton:setAnchorPoint(ccp(0.5, 0.5))
    layer.autoCopyButton:setPosition(ccp(gameConfig.originSize.width - 400, toppos - 100))
    setControlButtonFrame(layer.autoCopyButton, "b_n_button5")
    layer.autoCopyButton:addHandleOfControlEvent(function()
            if layer.datatype ~= "normal" or not layer.data or not layer.data.points then
                runGamePrompt({msg = "请先进入普通副本的关卡列表"}); return
            end
            if guide and guide.controller and guide.controller.isOnGuide then
                runGamePrompt({msg = "请先完成当前引导"}); return
            end
            if getbattlecallbackactive and getbattlecallbackactive() then
                runGamePrompt({msg = "请先结束当前战斗"}); return
            end
            AutoCopyStop()
            gameWindows:openWindow("localAutoCopy", {pending = autoCopy.pending ~= nil})
        end, CCControlEventTouchUpInside)
    layer.autoCopyButton:setTouchPriority(-102)
    layer.autoCopyButton:setSwallowsTouch(true)
    layer.rootNode:addChild(layer.autoCopyButton)
    autoCopyLabel(autoCopy.pending and "等待操作结果" or "")
end

function AutoCopyDetach(layer)
    if autoCopy.layer ~= layer then return end
    AutoCopyStop()
    gameWindows:closeWindowDirect("localAutoCopy")
    autoCopy.page = autoCopy.page + 1
    autoCopy.layer = nil
    layer.autoCopyButton, layer.autoCopyLabel, layer.autoCopyTimer = nil, nil, nil
end
