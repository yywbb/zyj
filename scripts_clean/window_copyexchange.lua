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
    ischange = 1,
}

function copyexchange.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_exchange_copy", nil, true, "copyexchange")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function copyexchange.reload(self,data,callback)

    
    local issetting = CCUserDefault:sharedUserDefault():getStringForKey("normal_copychange")

    if issetting and issetting ~= ""  then
        self.ischange = tonumber(issetting)
    else
        self.ischange = 0 
    end

      print("issettingissetting:"..issetting)
    
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
        gameWindows:closeWindow("copyexchange")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()

        if self.ischange then
           CCUserDefault:sharedUserDefault():setStringForKey("normal_copychange", tostring(self.ischange))
        end    

        self.callback = callback
        gameWindows:closeWindowDirect("copyexchange")
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

