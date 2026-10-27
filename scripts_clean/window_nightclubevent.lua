
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local clubevent = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    titleCellSize = {x = 1040, y = 230}
}


function clubevent.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.callback = callback
    self.typeindex = data._typeindex or 0
    
    self.m_tCinfog = gamedata.config.tiantingyz_sjtype[tostring(data._type)]

    self.rootNode, self.rootItems = CCBReaderLoad("nightclub/nightclub_event2", nil, true, "clubevent")
    if data._choose == 0 then
        self.rootItems.m_oTitle:setString(self.m_tCinfog.talk2)
    else
        self.rootItems.m_oTitle:setString(self.m_tCinfog.talk1)
    end
    self.rootItems.m_oTIps:setString(gameConfig.strings:string_common("nightclub",13))

    self.rootItems.m_oButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("clubevent")
    end, CCControlEventTouchUpInside)
    self.rootItems.m_oButton:setSwallowsTouch(true)
    self.rootItems.m_oButton:setTouchPriority(self.touchPriority)
    self.rootNode:setVisible(false)
    self.root:addChild(self.rootNode)
    return self.root
end

function clubevent.reload(self,data)
    self.rootNode:setVisible(true)
    if data.reward then
        ui.setNewIcon(self.rootItems,{cid = data.reward["1"].cid, num = data.reward["1"].num})
    else
        gameWindows:closeWindow("clubevent")
    end
end

function clubevent.close(self)  
    if self.callback then
        self.callback(self.typeindex+1)
    end
    self.m_tCinfog = nil
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return clubevent