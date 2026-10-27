--
-- Created by Lipurpose.
-- User: f
-- Date: 19/4/2018
-- Time: 18:26
-- To change this template use File | Settings | File Templates.
--

local weekCardDouble = {
    rootNode = nil,
    rootItems = nil,
}

function weekCardDouble.open(self,touchPriority,data,callback)
    
    self.rootNode, self.rootItems = CCBReaderLoad("shop/zhouka_tequaninfo", nil, true, "zhouka_tequaninfo")
    
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function weekCardDouble.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("weekCardDouble")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local setP = 0
    for i = 1,12 do
        local config = gamedata.config.week_double[tostring(i)]
        if not config then
            break
        end
        if config.show > 0 then
            setP = setP + 1
            self.rootItems["tequan"..setP]:setString(config.name..": "..(config.param == 1 and gameConfig.strings:string_common("activity",13) 
            or gameConfig.strings:string_common("activity",14)))
        end
    end
    for i = setP + 1,12 do
        self.rootItems["tequan"..i]:setVisible(false)
    end
end

function weekCardDouble.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return weekCardDouble