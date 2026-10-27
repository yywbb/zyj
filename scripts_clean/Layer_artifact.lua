--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/7/30
-- Time: 10:57
-- To change this template use File | Settings | File Templates.
--

local artifact = {
    touchPriority  = -101,
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                artifactCast = {366},
                artifactCheck = {398},
            },
        },
    },
    
}

function artifact.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_main", nil, true, "shenqi_main")
    self:initFixedString()
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)

    if self.rootItems.btnRule then
        self.rootItems.btnRule:addHandleOfControlEvent(function()
            gameWindows:openWindow("artifactRule")
        end, CCControlEventTouchUpInside)
        self.rootItems.btnRule:setSwallowsTouch(true)
        self.rootItems.btnRule:setTouchPriority(self.touchPriority)
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("main","down")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.bookBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactBook","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.bookBtn:setSwallowsTouch(true)
    self.rootItems.bookBtn:setTouchPriority(self.touchPriority)


    self.rootItems.skillSwapBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactSkillSwop","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.skillSwapBtn:setSwallowsTouch(true)
    self.rootItems.skillSwapBtn:setTouchPriority(self.touchPriority - 1)
    
    
    self.rootItems.skillStrenBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactSkillStrengthen","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.skillStrenBtn:setSwallowsTouch(true)
    self.rootItems.skillStrenBtn:setTouchPriority(self.touchPriority - 1)


    -- 神器镶嵌
    -- self.rootItems.mountBtn:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("artifactMount","up")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.mountBtn:setSwallowsTouch(true)
    -- self.rootItems.mountBtn:setTouchPriority(self.touchPriority)

    -- 神器宝石背包
    -- self.rootItems.artifactBtn:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("artifactList","up","artifact")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.artifactBtn:setSwallowsTouch(true)
    -- self.rootItems.artifactBtn:setTouchPriority(self.touchPriority)




------------神器主界面按钮功能

    -- 神器打造
    self.rootItems.castBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactCreate","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.castBtn:setSwallowsTouch(true)
    self.rootItems.castBtn:setTouchPriority(self.touchPriority)
    -- 神器洗练
    -- wash
    self.rootItems.washBtn:addHandleOfControlEvent(function()
        -- GameScene:shiftLayer("artifactList","up","artifact")
        GameScene:shiftLayer("artifactWash","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.washBtn:setSwallowsTouch(true)
    self.rootItems.washBtn:setTouchPriority(self.touchPriority)

    guide.controller:addComplete(396,function()
        UIRequest({type = 2882,opt=1,sysID=396})
    end)

    -- 神器鉴定
    self.rootItems.checkBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactCheck","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.checkBtn:setSwallowsTouch(true)
    self.rootItems.checkBtn:setTouchPriority(self.touchPriority)

    -- 神器强化
    self.rootItems.strengthenBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactStrengthen","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.strengthenBtn:setSwallowsTouch(true)
    self.rootItems.strengthenBtn:setTouchPriority(self.touchPriority)

    -- 神器背包
    self.rootItems.jewelBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactList","up","artifact")
        -- GameScene:shiftLayer("artifactList","up","jewel")
    end, CCControlEventTouchUpInside)
    self.rootItems.jewelBtn:setSwallowsTouch(true)
    self.rootItems.jewelBtn:setTouchPriority(self.touchPriority)

end

function artifact.initFixedString(self)
    ui.setLabelString(self.rootItems.fixed1,gameConfig.strings:string_common("artifact",85),79)
    ui.setLabelString(self.rootItems.fixed2,gameConfig.strings:string_common("artifact",86),79)
    ui.setLabelString(self.rootItems.fixed3,gameConfig.strings:string_common("artifact",87),79)
    ui.setLabelString(self.rootItems.fixed4,gameConfig.strings:string_common("artifact",88),79)
    ui.setLabelString(self.rootItems.fixed5,gameConfig.strings:string_common("artifact",89),79)
end

function artifact.clear(self)
    self.animationManager = nil
    self.data = {}
   
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function artifact.reload(self,data)
    
end

function artifact.initFixedString(self)

end


return artifact