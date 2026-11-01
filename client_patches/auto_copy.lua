-- 普通主线自动挑战只在本次页面中运行，服务器仍逐场结算。
local autoCopy = {active = false, pending = nil, layer = nil}
local autoCopyInterval = 3.1  -- 客户端1306限流要求跨越3个整秒。

local function autoCopyLabel(text)
    local layer = autoCopy.layer
    if layer and layer.autoCopyButton then
        setControlButtonTitle(layer.autoCopyButton, autoCopy.active and "停止推图" or "自动推图")
        layer.autoCopyLabel:setString(text or "")
    end
end

function AutoCopyIsRunning()
    return autoCopy.active
end

function AutoCopyBlockManual()
    if autoCopy.active or autoCopy.pending then
        runGamePrompt({msg = "自动推图或上一场挑战尚未结束"})
        return true
    end
    return false
end

function AutoCopyStop(reason)
    local wasActive = autoCopy.active
    autoCopy.active = false
    local layer = autoCopy.layer
    if layer and layer.autoCopyTimer then layer.autoCopyTimer:stopAllActions() end
    autoCopyLabel(autoCopy.pending and "等待本场结果" or "")
    if wasActive and reason then runGamePrompt({msg = reason}) end
end

function AutoCopyLocalReject(t)
    if autoCopy.pending and t.localAutoCopy and (t.msgtype == "shortphysical" or t.msgtype == "shortCopyChallenge") then
        autoCopy.pending = nil
        AutoCopyStop(t.msgtype == "shortphysical" and "自动推图已停止：体力不足" or "自动推图已停止：挑战次数不足")
        return true
    end
    return false
end

function AutoCopyServerError(t)
    if autoCopy.pending and t.request_opcode == 1306 then autoCopy.pending = nil end
    AutoCopyStop("自动推图已停止：请求失败")
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
    if not layer or not layer.rootNode or GameScene.presentLayer ~= "copy_map" or not GameScene.layers.copy_map.show then
        AutoCopyStop("自动推图已停止：已离开普通副本")
        return false
    end
    if guide and guide.controller and guide.controller.isOnGuide then
        AutoCopyStop("自动推图已停止：请先完成当前引导")
        return false
    end
    for _, window in pairs(gameWindows.windows) do
        if window.show then
            AutoCopyStop("自动推图已停止：请先处理当前弹窗")
            return false
        end
    end
    return true
end

local function autoCopyRequest(map, point, stamina, data)
    if not autoCopy.active or not autoCopyReady() then return end
    local config = gamedata.config.copy[tostring(map)]
    config = config and config[tostring(point)]
    if not config or not data or data.star ~= 0 then
        AutoCopyStop("自动推图已停止：没有可继续的未通关关卡")
        return
    end
    if not stamina or stamina < config.physical then
        AutoCopyStop("自动推图已停止：体力不足")
        return
    end
    if (data.kill or 0) >= config.challenge then
        AutoCopyStop("自动推图已停止：挑战次数不足")
        return
    end
    autoCopy.pending = {map = map, point = point}
    autoCopyLabel("地图"..map.." 第"..point.."关")
    autoCopySchedule(20, function()
        if autoCopy.pending then AutoCopyStop("自动推图已停止：等待挑战结果超时，请检查网络") end
    end)
    UIRequest({type = 1306, map = map, point = point, local_auto_copy = 1})
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

function AutoCopyHandle(t)
    local pending = autoCopy.pending
    if not pending or not t.localAutoCopy or t.map ~= pending.map or t.point ~= pending.point then
        AutoCopyStop("自动推图已停止：收到其他战斗结果")
        return false
    end
    autoCopy.pending = nil
    local layer = autoCopy.layer
    if layer and layer.autoCopyTimer then layer.autoCopyTimer:stopAllActions() end
    if not autoCopy.active then autoCopyLabel(""); return false end
    if t.result ~= 1 or not t.exp or t.exp.newlevel ~= t.exp.oldlevel or (t.encounters and next(t.encounters))
            or not autoCopyReady() then
        AutoCopyStop(t.result ~= 1 and "自动推图已停止：本场未获胜" or "自动推图已暂停：请处理当前战斗或升级")
        return false
    end

    copyDataReload(t)
    updateDataLife(t.reward or {})
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})
    setTriggerGiftEnable(true)

    local map, point = t.map, t.point + 1
    if not gamedata.config.copy[tostring(map)][tostring(point)] then
        map, point = map + 1, 1
    end
    local data, sectionID, mapID = autoCopyPoint(t.copy, map, point)
    if layer and layer.reloadnormalData then
        layer:reloadnormalData(t.copy, data and {datatype = "normal", section = sectionID, map = mapID, point = point} or nil)
    end
    if not data then
        AutoCopyStop("自动推图已停止：没有下一关")
        return true
    end
    autoCopySchedule(autoCopyInterval, function() autoCopyRequest(map, point, t.localAutoStamina, data) end)
    return true
end

function AutoCopyAttach(layer, toppos)
    autoCopy.layer = layer
    layer.autoCopyTimer = CCNode:create()
    layer.rootNode:addChild(layer.autoCopyTimer)
    layer.autoCopyLabel = ui.createLabel({text = "", fontsize = 22, x = gameConfig.originSize.width - 120, y = toppos - 150})
    layer.rootNode:addChild(layer.autoCopyLabel)
    layer.autoCopyButton = CCControlButton:create("自动推图", "Helvetica-Bold", 26)
    layer.autoCopyButton:setPreferredSize(CCSizeMake(190, 70))
    layer.autoCopyButton:setAnchorPoint(ccp(0.5, 0.5))
    layer.autoCopyButton:setPosition(ccp(gameConfig.originSize.width - 120, toppos - 100))
    setControlButtonFrame(layer.autoCopyButton, "b_n_button5")
    layer.autoCopyButton:addHandleOfControlEvent(function()
            if autoCopy.active then AutoCopyStop("自动推图已停止，本场结果仍会正常结算"); return end
            if AutoCopyBlockManual() then return end
            if layer.datatype ~= "normal" or not layer.data or not layer.data.points then
                runGamePrompt({msg = "请先进入普通副本的关卡列表"}); return
            end
            if guide and guide.controller and guide.controller.isOnGuide then
                runGamePrompt({msg = "请先完成当前引导"}); return
            end
            if getbattlecallbackactive and getbattlecallbackactive() then
                runGamePrompt({msg = "请先结束当前战斗"}); return
            end
            local first
            for _, data in pairs(layer.data.points) do
                if data.star == 0 and (not first or data.id < first.id) then first = data end
            end
            if not first then runGamePrompt({msg = "当前地图没有未通关关卡，请进入下一张地图"}); return end
            local map, point = layer.data.id, first.id
            gameWindows:openWindow("confirm", {msg = "从当前未通关主线连续挑战并跳过战报？每场消耗体力，失败、升级或体力不足时停止；不购买或使用体力丹。"}, function()
                if autoCopy.layer ~= layer or autoCopy.pending or autoCopy.active
                        or (getbattlecallbackactive and getbattlecallbackactive()) then return end
                autoCopy.active = true
                autoCopyLabel("准备挑战")
                autoCopySchedule(autoCopyInterval, function() autoCopyRequest(map, point, GameScene.roleinfo and GameScene.roleinfo.stamina, first) end)
            end)
        end, CCControlEventTouchUpInside)
    layer.autoCopyButton:setTouchPriority(-102)
    layer.autoCopyButton:setSwallowsTouch(true)
    layer.rootNode:addChild(layer.autoCopyButton)
    autoCopyLabel(autoCopy.pending and "等待本场结果" or "")
end

function AutoCopyDetach(layer)
    if autoCopy.layer ~= layer then return end
    AutoCopyStop()
    autoCopy.layer = nil
    layer.autoCopyButton, layer.autoCopyLabel, layer.autoCopyTimer = nil, nil, nil
end
