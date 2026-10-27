--
-- Created by IntelliJ IDEA.
-- User: lipurpose
-- Date: 17/7/31
-- Time: 下午4:31
-- To change this template use File | Settings | File Templates.
--

local propSelect = {
    rootNode = nil,
    rootItems = nil,
    selectPos = nil,
}

function propSelect.setFixedString(self)
    ui.setLabelString(self.rootItems.startAuctionTxt, gameConfig.strings:string_common("fixedString","nightclub", 4),19)
end

function propSelect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_caiiaoselect", nil, true, "tc_caiiaoselect")
    self.touchPriority = touchPriority
    --
    --setSpriteFrameByName(self.rootItems.titleSp,"xuanzecailiaobiaoti")
    self:setFixedString()
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("propSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    
    self.rootItems.startAuctionBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("propSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.startAuctionBtn:setSwallowsTouch(true)
    self.rootItems.startAuctionBtn:setTouchPriority(self.touchPriority)

    self:reload(data,callback)
    return self.rootNode
end

function propSelect.reload(self,data,callback)
    self.callback = callback
    local props = data.props
    local propNums = data.propNums
    local propSelect = data.propSelect
    local idSet = {}
    for i = 1,3 do
        if propSelect[i] then
            idSet[propSelect[i]] = i
        end
    end
    self.selectPos = nil
    for i = 1,3 do
        if not idSet[i] then
            self.selectPos = i
            break
        end
    end
    self.selectPos = self.selectPos or 1
    for i = 1,3 do
        local key_Ex = ""
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i - 1)
        end
        ui.setNewIconName(self.rootItems,{cid = props[i].cid, num = propNums[tostring(props[i].cid)]},i-1)
        self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
            if self.selectPos then
                self.rootItems["choose"..self.selectPos]:setVisible(false)
            end
            self.selectPos = i
            self.rootItems["choose"..self.selectPos]:setVisible(true)
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority)

        if idSet[i] then
            ui.addGray("CCSprite", self.rootItems["in_quality"..key_Ex])
            ui.addGray("CCSprite", self.rootItems["in_icon"..key_Ex])
            ui.addGray("CCSprite", self.rootItems["in_k_quality"..key_Ex])
        end
        self.rootItems["choose"..i]:setVisible(false)
        self.rootItems["notOn"..i]:setVisible(idSet[i] ~= nil)
        if idSet[i] then
            self.rootItems["selectTxt"..i]:setString(gameConfig.strings:string_common("artifact",90 + idSet[i]))
        end

        self.rootItems["goTo"..i]:addHandleOfControlEvent(function()
            gameWindows:openWindow("dropTips",{cid = props[i].cid},nil)
        end, CCControlEventTouchUpInside)
        self.rootItems["goTo"..i]:setSwallowsTouch(true)
        self.rootItems["goTo"..i]:setTouchPriority(self.touchPriority)
    end
    self.rootItems["choose"..self.selectPos]:setVisible(true)
end

function propSelect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    
    if self.callback then
        self.callback(self.selectPos)
    end
    self.selectPos = nil
end

return propSelect