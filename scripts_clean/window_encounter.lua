--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/14
-- Time: 下午4:50
-- To change this template use File | Settings | File Templates.
--

local encounter = {
    rootNode = nil,
    rootItems = nil,
    data= {},
}

function encounter.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("encounter2_new/tc_yudaoqiyu.ccbi", nil, true, "tc_yudaoqiyu")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode,true
end

function encounter.reload(self,data,callback)
    self.callback = callback
    self.data = data
    self.step = 0
    self:showOne()
end

function encounter.showOne(self)
    self.step = self.step + 1

    if self.data[tostring(self.step)] then
        local configdata = gamedata.config.encounter[tostring(self.data[tostring(self.step)].cid)]
        local Gneral = CCSkeletonAnimation:create("change/change.json","change/change.atlas",1)
        Gneral:setAnimation("stand",true,0)
        Gneral:setScale(2)
        Gneral:setPosition(0,0)
        self.rootItems.general:addChild(Gneral)

        setSpriteFrameByName(self.rootItems.icon,gameConfig.images["encounter_icon_"..configdata.type])
        self.rootItems.name:setString(gameConfig.strings.encounterType[configdata.type])

        ui.setLabelString(self.rootItems.buttontext,"知道了",18)
        self.rootItems.button:setSwallowsTouch(true)
        self.rootItems.button:setTouchPriority(self.touchPriority)
        self.rootItems.button:addHandleOfControlEvent(function()
            self:showOne()
        end, CCControlEventTouchUpInside)

        self.rootNode:setScale(0)
        local scaleTo = CCScaleTo:create(0.3, gameWindows.scaleNum )
        local backOut = CCEaseBackOut:create(scaleTo)
        self.rootNode:runAction(backOut)
    else
        gameWindows:closeWindow("encounter")
    end

end

function encounter.close(self)

    self.data = {}

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return encounter