local daoGuanAttack = {
    rootNode = nil,
    rootItems = nil,
}

-- 打开界面
function daoGuanAttack.open(self, touchPriority, data, callback)
    self.rootNode, self.rootItems = CCBReaderLoad("daoguanshouwei/daoguanshouwei_attack", nil, true, "slotarrange")
    self:initEvent(touchPriority)
    self.id = data.id
    self.position = data.position
    self.panelData = data.slots

    printT(self.panelData, "daoGuanAttack")
    self:reload(callback)

    return self.rootNode
end

-- 初始化点击事件
function daoGuanAttack.initEvent(self, touchPriority)
    self:initChellengeBtn(touchPriority)
end

-- 初始化挑战按钮点击事件
function daoGuanAttack.initChellengeBtn(self, touchPriority)
    self.touchPriority = touchPriority
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("daoGuanAttack")
    end, CCControlEventTouchUpInside)
end

function daoGuanAttack.reload(self, callback)
    self.callback = callback

    --
    local generalsdata = {}
    if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
        generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
    end

    local requesttable = {}
    local postable = {}

    for i = 1, 7 do
        -- 自己
        if self.panelData.generalsSelf[tostring(i)] and self.panelData.generalsSelf[tostring(i)].cid > 0 then
            self.rootItems["general"..i]:setVisible(true)
            -- 设置头像
            local configGeneral = gamedata.config.general[tostring(self.panelData.generalsSelf[tostring(i)].cid)]
            local gicon = configGeneral.icon
            local selsecData = {}
            for k,v in pairs(generalsdata) do
                local cid = v.illusionGeneralCid or v.cid
                if self.panelData.generalsSelf[tostring(i)].cid == cid then
                    selsecData = v
                    break
                end
            end
            if next(selsecData) then
                if selsecData.illusionGeneralCid then
                    local gdata = ui.getConfigGeneralSion(selsecData)
                    if next(gdata) and configGeneral.fashion_id == 0 then
                        gicon = gdata.icon
                    end
                else
                    local gdata = ui.getConfigGeneral(selsecData)
                    if next(gdata) and configGeneral.fashion_id == 0 then
                        gicon = gdata.icon
                    end
                end
            end
            ui.setNewIcon(self.rootItems, {cid = self.panelData.generalsSelf[tostring(i)].cid, icon = gicon}, i - 1)
            postable[i] = { x = self.rootItems["general"..i]:getPositionX(),
                            y = self.rootItems["general"..i]:getPositionY()}
            requesttable[i] = i
        else
            self.rootItems["general"..i]:setVisible(false)
        end

        -- 对手
        if self.panelData.generalsOpponent[tostring(i)] and self.panelData.generalsOpponent[tostring(i)] > 0 then
            self.rootItems["d_general"..i]:setVisible(true)
            -- 设置头像
            local oldcid = self.panelData.oldcid[tostring(i)] or 0
            local oldconfigdata = {}
            if oldcid > 0 then
                oldconfigdata = gamedata.config.general[tostring(oldcid)]
            end
            if next(oldconfigdata) then
                ui.setNewIcon(self.rootItems, {cid = self.panelData.generalsOpponent[tostring(i)], quality = oldconfigdata.quality}, i + 6)
            else
                ui.setNewIcon(self.rootItems, {cid = self.panelData.generalsOpponent[tostring(i)]}, i + 6)
            end
        else
            self.rootItems["d_general"..i]:setVisible(false)
        end
    end

    local touchedGeneral = nil

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchlayer,x,y) then
            for k,v in pairs(requesttable) do
                if self.rootItems["general"..v]:isVisible() and ui.isTouched(self.rootItems["general"..v], x, y) then
                    touchedGeneral = {node = self.rootItems["general"..v], sid = k, touch_x = x, touch_y = y }
                    touchedGeneral.node:setZOrder(1)
                    return true
                end
            end
        end
    end

    local function ccTouchMoved(x, y)
        if touchedGeneral then
            touchedGeneral.node:setPosition(postable[touchedGeneral.sid].x + x - touchedGeneral.touch_x,
                                            postable[touchedGeneral.sid].y + y - touchedGeneral.touch_y)
        end
    end

    local function ccTouchEnded(x, y)
        if touchedGeneral then
            local haschange = false

            for k,v in pairs(requesttable) do
                if k ~= touchedGeneral.sid and 
                   self.rootItems["general"..v]:isVisible() and
                   ui.iscontendbynode(self.rootItems["general"..v], touchedGeneral.node:getPositionX() ,touchedGeneral.node:getPositionY()) then
                    haschange = true
                    -- 移动数据
                    local _x, _y = postable[k].x, postable[k].y
                    local moveto =  CCMoveTo:create(0.2, ccp(_x, _y))
                    touchedGeneral.node:stopAllActions()
                    touchedGeneral.node:runAction(moveto)
                    local __x, __y = postable[touchedGeneral.sid].x, postable[touchedGeneral.sid].y
                    local moveto2 =  CCMoveTo:create(0.2, ccp(__x, __y))
                    self.rootItems["general"..v]:stopAllActions()
                    self.rootItems["general"..v]:runAction(moveto2)

                    -- 交换位置数据
                    requesttable[k], requesttable[touchedGeneral.sid] = requesttable[touchedGeneral.sid], requesttable[k]
                    
                    -- 交换iid, cid数据
                    local _first = tostring(k)
                    local _sccond = tostring(touchedGeneral.sid)

                    self.panelData.generalsSelf[_first].iid, self.panelData.generalsSelf[_sccond].iid = self.panelData.generalsSelf[_sccond].iid, self.panelData.generalsSelf[_first].iid
                    self.panelData.generalsSelf[_first].cid, self.panelData.generalsSelf[_sccond].cid = self.panelData.generalsSelf[_sccond].cid, self.panelData.generalsSelf[_first].cid

                    break
                end
            end

            if not haschange then
                local moveto2 =  CCMoveTo:create(0.2, ccp(postable[touchedGeneral.sid].x,postable[touchedGeneral.sid].y))
                touchedGeneral.node:runAction(moveto2)
            end

            touchedGeneral.node:setZOrder(0)
            touchedGeneral = nil
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchlayer:registerScriptTouchHandler(onTouch, false, self.touchPriority, false)
    self.rootItems.touchlayer:setTouchPriority(self.touchPriority)
    self.rootItems.touchlayer:setTouchEnabled(false)

    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("daoguanshouwei", 17),19)

    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("daoGuanAttack")
        UIRequest({type = 5304, id = self.id, position = self.position, generalsSelf = self.panelData.generalsSelf, pet = self.panelData.pet})
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
end

-- 关闭按钮
function daoGuanAttack.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return daoGuanAttack!  