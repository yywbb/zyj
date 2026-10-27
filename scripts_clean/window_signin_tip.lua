--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/14
-- Time: 下午4:50
-- To change this template use File | Settings | File Templates.
--

local signin = {
    rootNode = nil,
    rootItems = nil,
    needcallback = true,
    data= {},
}

function signin.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitysignin_new/signin_qiandao", nil, true, "signin")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function signin.reload(self,data,callback)
    self.callback = callback
    local configdata = gamedata.config.build[tostring(132)]
    local Gneral = CCSkeletonAnimation:create("monvyemei/monvyemei.json","monvyemei/monvyemei.atlas",1)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(2)
    Gneral:setPosition(0,0)
    self.rootItems.general:addChild(Gneral)

--    setSpriteFrameByName(self.rootItems.icon,configdata.icon or "alpha")
    ui.setLabelString(self.rootItems.name,gamedata.config.activity_time[tostring(19)].name,1)
    ui.setLabelString(self.rootItems.fixstring,"今日还未完成",14)

    ui.setLabelString(self.rootItems.buttontext,"稍 后",19)
    self.rootItems.button:setSwallowsTouch(true)
    self.rootItems.button:setTouchPriority(self.touchPriority)
    self.rootItems.button:addHandleOfControlEvent(function()
        gameWindows:closeWindow("signin_tip")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.gotobuttontext,"前 往",19)
    self.rootItems.gotobutton:setSwallowsTouch(true)
    self.rootItems.gotobutton:setTouchPriority(self.touchPriority)
    self.rootItems.gotobutton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("signin_tip")
        GameScene:shiftLayerById(132)
    end, CCControlEventTouchUpInside)
end

function signin.close(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return signin