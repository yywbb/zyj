--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

--  0不换  1换
local copyexchange = {
    rootNode = nil,
    rootItems = nil,
    ischange = 0,
}

function copyexchange.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui3/tc_exchange_exp", nil, true, "tc_exchange_exp")

    self.ischange = data.ischange or 0
    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function copyexchange.reload(self,data,callback)

    
    self:setbtnStatus(self.ischange)

    --是
    self.rootItems.yesBtn:addHandleOfControlEvent(function()
        self:setbtnStatus(1)
    end,CCControlEventTouchUpInside)
    self.rootItems.yesBtn:setSwallowsTouch(true)
    self.rootItems.yesBtn:setTouchPriority(self.touchPriority)

    --否
    self.rootItems.noBtn:addHandleOfControlEvent(function()
       self:setbtnStatus(0)
    end,CCControlEventTouchUpInside)
    self.rootItems.noBtn:setSwallowsTouch(true)
    self.rootItems.noBtn:setTouchPriority(self.touchPriority)

   
    --关闭
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("feastExpChange")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),19)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
    	UIRequest({type = 2278,method = self.ischange})
        self.callback = callback
        gameWindows:closeWindowDirect("feastExpChange")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)
end


function copyexchange.setbtnStatus(self,isyes)

    self.rootItems.yessprite:setVisible(isyes == 1)
    self.rootItems.nosprite:setVisible(isyes == 0)
    self.ischange = isyes

end


function copyexchange.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return copyexchange

