--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 上午10:10
-- To change this template use File | Settings | File Templates.
--

local slotarrange = {
    rootNode = nil,
    rootItems = nil,

    needcallback = true
}

function slotarrange.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("slotsInfo/slotarrange2", nil, true, "slotarrange2")

    self.touchPriority = touchPriority
    --self.rootItems.title:setString("拖动布阵")
    self.awakenConfig = gamedata.config.general_awaken
    self:reload(data,callback)


    return self.rootNode
end

function slotarrange.reload(self,data,callback)
    self.callback = callback
    print("data=================")
    printT(data)
    
    local powertotal = 0
    for k,v in pairs(data) do
        powertotal = powertotal + v.power
    end
    -- self.rootItems.powerTotal:setString("总战力: "..powertotal)
    self.rootItems.powerTotal:setString(gameConfig.strings:TolPower(powertotal))
    ui.setLabelString(self.rootItems.des,nil,21)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindow("slotarrange")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local requesttable = {}
    local postable = {}

    for i=1,7 do
        postable[i] = {}
        if data[tostring(i)] and data[tostring(i)].general then
            postable[i].ccb, postable[i].item = CCBReaderLoad("slotsInfo/generalInfo", nil, true, "generalInfo")
            local config = gamedata.config.general[tostring(data[tostring(i)].general.cid)]
            local awakenicon,awakenstage = -1.-1
            if config.awaken > 0 and data[tostring(i)] and data[tostring(i)].general and data[tostring(i)].general.skilllevel > 0 and  tostring(data[tostring(i)].general.skilllevel) and  self.awakenConfig[tostring(data[tostring(i)].general.skilllevel)] then
                awakenicon = self.awakenConfig[tostring(data[tostring(i)].general.skilllevel)].icon
                awakenstage = self.awakenConfig[tostring(data[tostring(i)].general.skilllevel)].stage
            end
            local g_data = {
                quality = config.quality,
                icon = config.icon,
                name = config.name,
                actor = config.actor,
                level = data[tostring(i)].general.level1,
                level2 = data[tostring(i)].general.level2,
                awakenicon = awakenicon , 
                awakenstage = awakenstage ,
            }
            ui.setGeneralIconL2(g_data,postable[i].item)
            postable[i].x =self.rootItems["general"..i]:getPositionX()
            postable[i].y = self.rootItems["general"..i]:getPositionY()
            requesttable[i] = i
            postable[i].has = true
        else
            postable[i].ccb, postable[i].item = CCBReaderLoad("slotsInfo/generalInfo2", nil, true, "generalInfo2")
            postable[i].item.add:setVisible(not not data[tostring(i)])
            postable[i].item.lock:setVisible(not data[tostring(i)])
            postable[i].item.openlevel:setVisible(not data[tostring(i)])
            local slotconfig = gamedata.config.general_slot
            local nextlevel = slotconfig[tostring(i)]
            -- ui.setLabelString(postable[i].item.openlevel,nextlevel.."级开启",13)
            ui.setLabelString(postable[i].item.openlevel,gameConfig.strings:lvOpen(nextlevel),13)
        end
        postable[i].ccb:setPosition(175,90)
        self.rootItems["general"..i]:addChild(postable[i].ccb)
    end

    local touchedGeneral = nil

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchlayer,x,y) then
            for k,v in pairs(requesttable) do
                if postable[v].has and ui.isTouched(self.rootItems["general"..v],x,y) then
                    print(k,v)
                    touchedGeneral = {node = self.rootItems["general"..v], sid = k,touchx = x, touchy = y }
                    touchedGeneral.node:setZOrder(1)
                    return true
                end
            end
        end
    end

    local function ccTouchMoved(x, y)
        if touchedGeneral then
            touchedGeneral.node:setPosition(postable[touchedGeneral.sid].x+(x-touchedGeneral.touchx)/GameScene.scaleNum,postable[touchedGeneral.sid].y+(y-touchedGeneral.touchy)/GameScene.scaleNum)
        end
    end

    local function ccTouchEnded(x, y)
        if touchedGeneral then
            local haschange = false
            for k,v in pairs(requesttable) do
                if k ~= touchedGeneral.sid and postable[v].has and ui.iscontendbynode(self.rootItems["general"..v],touchedGeneral.node:getPositionX(),touchedGeneral.node:getPositionY()) then
                    haschange = true
                    print(v,touchedGeneral.sid)
                    local moveto =  CCMoveTo:create(0.2, ccp(postable[k].x,postable[k].y))
                    touchedGeneral.node:runAction(moveto)
                    local moveto2 =  CCMoveTo:create(0.2, ccp(postable[touchedGeneral.sid].x,postable[touchedGeneral.sid].y))
                    self.rootItems["general"..v]:runAction(moveto2)
                    local postemp = requesttable[k]
                    requesttable[k] = requesttable[touchedGeneral.sid]
                    requesttable[touchedGeneral.sid] = postemp
                    --                    touchedGeneral.node:setPosition(postable[i].x,postable[i].y)
                    --                    self.rootItems["general"..i]:setPosition(postable[touchedGeneral.sid].x,postable[touchedGeneral.sid].y)
                    break
                end
            end
            if not haschange then
                local moveto2 =  CCMoveTo:create(0.2, ccp(postable[touchedGeneral.sid].x,postable[touchedGeneral.sid].y))
                touchedGeneral.node:runAction(moveto2)
            end
            touchedGeneral.node:setZOrder(0)
            touchedGeneral = nil

            --确定变阵
            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
                printT(requesttable,"requesttable====")
                local needchange = false
                for k,v in pairs(requesttable) do
                    if k~=v then
                        needchange = true
                    end
                end
                self.callback = nil
                if needchange then
                    self.callback = function()
                        UIRequest{type = 1009, ids = requesttable}
                    end
                    if guide.controller then
                        guide.controller:UIComplete(8070)
                    end
                end
            end)))
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

    local touchPriority = (guide.controller and guide.controller.isOnGuide) and gameConfig.touchPriority.guide-1 or self.touchPriority

    self.rootItems.touchlayer:registerScriptTouchHandler(onTouch, false, touchPriority, false)
    self.rootItems.touchlayer:setTouchPriority(touchPriority)
    self.rootItems.touchlayer:setTouchEnabled(true)


    -- ui.setLabelString(self.rootItems.conceltext,"取 消",18)
    -- ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","quxiao"),18)
    -- self.rootItems.concel:addHandleOfControlEvent(function()
    --     for k,v in pairs(requesttable) do
    --         if k~=v then
    --             local moveto2 =  CCMoveTo:create(0.2, ccp(postable[k].x,postable[k].y))
    --             self.rootItems["general"..k]:runAction(moveto2)
    --             requesttable[k] = k
    --         end
    --     end
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.concel:setSwallowsTouch(true)
    -- self.rootItems.concel:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    -- self.rootItems.confirm:addHandleOfControlEvent(function()
    --     printT(requesttable,"requesttable")
    --     local needchange = false
    --     for k,v in pairs(requesttable) do
    --         if k~=v then
    --             needchange = true
    --         end
    --     end

    --     self.callback = nil
    --     if needchange then
    --         self.callback = function()
    --             UIRequest{type = 1009, ids = requesttable}
    --         end
    --     end

    --     gameWindows:closeWindow("slotarrange")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.confirm:setSwallowsTouch(true)
    -- self.rootItems.confirm:setTouchPriority(self.touchPriority)
end

function slotarrange.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return slotarrange