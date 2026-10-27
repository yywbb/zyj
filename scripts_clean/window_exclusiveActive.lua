--
-- Author: songyibo
-- Date: 2021-03-24 17:25:45
--
local exclusiveActive = {
    rootNode = nil,
    rootItems = nil,
}

function exclusiveActive.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_zhuanshushenqijihuo", nil, true, "tc_zhuanshushenqijihuo")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    if guide.controller then
        guide.controller:NewSystem(611)
    end
    
    return self.rootNode
end

function exclusiveActive.reload(self,data,callback)
    self.callback = callback
    
    self.exclusiveCid = data.exclusiveCid
    self.generalCid = data.generalCid

	local generalConfig = ui.IDconfig(self.generalCid)
    local exclusiveConfig = ui.IDconfig(self.exclusiveCid)

    local skeleton = ui.createExclusiveSkeleton(exclusiveConfig.animation)
    if skeleton then
        skeleton:setAnimation("stand",true,0)
        self.rootItems.skeleton:addChild(skeleton)
    end
    self.rootItems.desc:setString(string.format(gameConfig.strings:string_common("exclusiveArtifactNew",18), generalConfig.name,exclusiveConfig.name))

    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("exclusiveActive")
    end, CCControlEventTouchUpInside)
end

function exclusiveActive.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return exclusiveActive