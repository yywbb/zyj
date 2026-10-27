--
-- Author: songyibo
-- Date: 2019-02-22 16:12:43
--


local confirm = {
    rootNode = nil,
    rootItems = nil,
    isSelect = false,
    needcallback = true,
    selectToContinue = false,
}

function confirm.open(self,touchPriority,data,callback)

    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/tc_tishi", nil, true, "tc_tishi")
    self:initFixedString()
    self.touchPriority = touchPriority
    self.callback = callback

    self.rootItems.tip:setString(data.des)

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        
        gameWindows:closeWindow("confirmWithShield")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.noButton:addHandleOfControlEvent(function()
        
        gameWindows:closeWindow("confirmWithShield")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    self.rootItems.yesButton:addHandleOfControlEvent(function()
        self.selectToContinue = true
        gameWindows:closeWindowDirect("confirmWithShield")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

    self.rootItems.selectSp2:setVisible(self.isSelect)
    self.rootItems.selectUse:addHandleOfControlEvent(function()
        self.isSelect = not self.isSelect
        self.rootItems.selectSp2:setVisible(self.isSelect)
    end, CCControlEventTouchUpInside)
    self.rootItems.selectUse:setSwallowsTouch(true)
    self.rootItems.selectUse:setTouchPriority(self.touchPriority)

    
    return self.rootNode
end

function confirm.initFixedString(self)
    self.rootItems.tip3:setString(gameConfig.strings:string_common("artifact",121))
    ui.setLabelString(self.rootItems.starttext,gameConfig.strings:string_common("buttontext","fanhui"),19)
    ui.setLabelString(self.rootItems.starttext1,gameConfig.strings:string_common("buttontext","queding"),19)
end


function confirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    
    if self.callback then
        self.callback(self.isSelect,self.selectToContinue)
    end
    self.isSelect = false
    self.selectToContinue = false
end


return confirm