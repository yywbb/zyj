--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/12/12
-- Time: 11:52
-- To change this template use File | Settings | File Templates.
--

local shenlongxuyuan_event = {
    rootNode = nil,
    rootItems = nil,
    ccbtype = 1,
}

function shenlongxuyuan_event.open(self,touchPriority,data,callback)

    self.ccbtype = data and data.ccbtype or 1

    if self.ccbtype == 2 then
        self.rootNode, self.rootItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_pop2", nil, true, "event")
    elseif self.ccbtype == 3 then
        self.rootNode, self.rootItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_pop3", nil, true, "event")
    else
        self.rootNode, self.rootItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_pop", nil, true, "event")
    end

    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function shenlongxuyuan_event.reload(self,data,callback)
    self.callback = callback
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shenlongxuyuan_event")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    --
    if self.ccbtype == 2 then
        self.rootItems["generalnode"]:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.roleinfo.profile)].animationid)].name
        local wing = {level = GameScene.protagonist.w_l,color = GameScene.protagonist.w_c}
        --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(1.2)
        Gneral1:setPosition(0,0)
        self.rootItems["generalnode"]:addChild(Gneral1.root or Gneral1)
        --
        ui.setLabelString(self.rootItems.doLab1,nil,19)
        self.rootItems.doButton1:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 4905})
            gameWindows:closeWindowDirect("shenlongxuyuan_event")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton1:setSwallowsTouch(true)
        self.rootItems.doButton1:setTouchPriority(self.touchPriority)
        --
        ui.setLabelString(self.rootItems.doLab2,nil,19)
        self.rootItems.doButton2:addHandleOfControlEvent(function()
            self.callback = nil
            --
            local cb = function()
                UIRequest({type = 4905})
            end
            gameWindows:openWindow("shenlongxuyuan_shop",{shop1 = data.shop1,shop2 = data.shop2,shop3 = data.shop3,shop4 = data.shop4,}, cb)
            gameWindows:closeWindowDirect("shenlongxuyuan_event")
            --
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton2:setSwallowsTouch(true)
        self.rootItems.doButton2:setTouchPriority(self.touchPriority)
    elseif self.ccbtype == 3 then
        local eventconfig = gamedata.config.shenlong_praram and gamedata.config.shenlong_praram[tostring(data.eventid)] or {}
        self.rootItems.desc:setString(eventconfig.desc)
        self.rootItems.desc1:setString(eventconfig.talk1)
        self.rootItems.desc2:setString(eventconfig.talk2)
        ui.setLabelString(self.rootItems.doLab1,eventconfig.button1,19)
        ui.setLabelString(self.rootItems.doLab2,eventconfig.button2,19)
        --
        self.rootItems["generalnode"]:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.roleinfo.profile)].animationid)].name
        local wing = {level = GameScene.protagonist.w_l,color = GameScene.protagonist.w_c}
        --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(1.2)
        Gneral1:setPosition(0,0)
        self.rootItems["generalnode"]:addChild(Gneral1.root or Gneral1)
        --
        self.rootItems["monsternode"]:removeAllChildrenWithCleanup(true)
        local generalName2 = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(eventconfig.image)].animationid)].name
        local wing2 = {level = GameScene.protagonist.w_l,color = GameScene.protagonist.w_c}
        --local Gneral2 = CCSkeletonAnimation:create(generalName2.."/"..generalName2..".json",generalName2.."/"..generalName2..".atlas",1)
        local Gneral2 = ui.itemcache:loadSkeleton(generalName2,wing2)
        Gneral2:setAnimation("stand",true,0)
        Gneral2:setScale(1.2)
        Gneral2:setPosition(0,0)
        self.rootItems["monsternode"]:addChild(Gneral2.root or Gneral2)
        --
        local animationManager = getAnimationManager(self.rootItems)
        animationManager:runAnimationsForSequenceNamed("start")
        --
        self.rootItems.doButton1:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 4904,opt = 1,})
            animationManager:runAnimationsForSequenceNamed("1")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton1:setSwallowsTouch(true)
        self.rootItems.doButton1:setTouchPriority(self.touchPriority)
        --
        self.rootItems.doButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 4904,opt = 2,})
            animationManager:runAnimationsForSequenceNamed("2")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton2:setSwallowsTouch(true)
        self.rootItems.doButton2:setTouchPriority(self.touchPriority)
        --
        ui.setLabelString(self.rootItems.doLab3,nil,19)
        self.rootItems.doButton3:addHandleOfControlEvent(function()
            gameWindows:closeWindow("shenlongxuyuan_event")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton3:setSwallowsTouch(true)
        self.rootItems.doButton3:setTouchPriority(self.touchPriority)
        --

    elseif self.ccbtype == 4 or self.ccbtype == 5 then
        self.rootItems["generalnode"]:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.roleinfo.profile)].animationid)].name
        local wing = {level = GameScene.protagonist.w_l,color = GameScene.protagonist.w_c}
        --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(1.2)
        Gneral1:setPosition(0,0)
        self.rootItems["generalnode"]:addChild(Gneral1.root or Gneral1)
        --
        self.rootItems["monsternode"]:removeAllChildrenWithCleanup(true)
        local generalcid = 0
        if gamedata.config.zodiac_new and gamedata.config.zodiac_new[tostring(data.eventid)] and gamedata.config.zodiac_new[tostring(data.eventid)]["1"] then
            generalcid = gamedata.config.zodiac_new[tostring(data.eventid)]["1"].monsterid or 0
        end
        if generalcid > 0 then
            local generalName2 = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(generalcid)].animationid)].name
            local wing2 = {level = 0,color = 0}
            --local Gneral2 = CCSkeletonAnimation:create(generalName2.."/"..generalName2..".json",generalName2.."/"..generalName2..".atlas",1)
            local Gneral2 = ui.itemcache:loadSkeleton(generalName2,wing2)
            Gneral2:setAnimation("stand",true,0)
            Gneral2:setScale(1.2)
            Gneral2:setPosition(0,0)
            self.rootItems["monsternode"]:addChild(Gneral2.root or Gneral2)
        end
        --
        self.rootItems.desc:setString("有我在此！谁也别想从这里过去！")
        --
        if self.ccbtype == 4 then
            ui.setLabelString(self.rootItems.doLab1,"溜 走",19)
            self.rootItems.doButton1:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                UIRequest({type = 4904,opt = 3,})
                gameWindows:closeWindowDirect("shenlongxuyuan_event")
            end, CCControlEventTouchUpInside)
            self.rootItems.doButton1:setSwallowsTouch(true)
            self.rootItems.doButton1:setTouchPriority(self.touchPriority)
        else
            ui.setLabelString(self.rootItems.doLab1,"战 斗",19)
            self.rootItems.doButton1:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                UIRequest({type = 4904,opt = 1,})
                gameWindows:closeWindowDirect("shenlongxuyuan_event")
            end, CCControlEventTouchUpInside)
            self.rootItems.doButton1:setSwallowsTouch(true)
            self.rootItems.doButton1:setTouchPriority(self.touchPriority)
        end
        --
        local cost = gamedata.config.global_kv.shenlong_skip and tonumber(gamedata.config.global_kv.shenlong_skip.value) or 0
        ui.setLabelString(self.rootItems.doLab2,"贿 赂",19)
        self.rootItems.doButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if GameScene.roleinfo.gold >= cost then
                UIRequest({type = 4904,opt = 2,xgold = cost})
                gameWindows:closeWindowDirect("shenlongxuyuan_event")
            else
                runGamePrompt({msg = "元宝不足"})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton2:setSwallowsTouch(true)
        self.rootItems.doButton2:setTouchPriority(self.touchPriority)
        --
        self.rootItems.spendNode:setVisible(true)
        ui.setLabelString(self.rootItems.spendText,cost,14)

    else
        self.rootItems["monsternode"]:removeAllChildrenWithCleanup(true)
        local generalcid = 10224
        if generalcid > 0 then
            local generalName2 = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(generalcid)].animationid)].name
            local wing2 = {level = 0,color = 0}
            --local Gneral2 = CCSkeletonAnimation:create(generalName2.."/"..generalName2..".json",generalName2.."/"..generalName2..".atlas",1)
            local Gneral2 = ui.itemcache:loadSkeleton(generalName2,wing2)
            Gneral2:setAnimation("stand",true,0)
            Gneral2:setScale(1.2)
            Gneral2:setPosition(0,0)
            self.rootItems["monsternode"]:addChild(Gneral2.root or Gneral2)
        end
        --
        self.rootItems["generalnode"]:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.roleinfo.profile)].animationid)].name
        local wing = {level = GameScene.protagonist.w_l,color = GameScene.protagonist.w_c}
        --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(1.2)
        Gneral1:setPosition(0,0)
        self.rootItems["generalnode"]:addChild(Gneral1.root or Gneral1)
        --
        self.rootItems.desc:setString("大王叫我来巡山～呔！前方何人？报上名来！")
        --
        ui.setLabelString(self.rootItems.doLab1,"溜 走",19)
        self.rootItems.doButton1:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 4904,opt = 2,})
            gameWindows:closeWindowDirect("shenlongxuyuan_event")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton1:setSwallowsTouch(true)
        self.rootItems.doButton1:setTouchPriority(self.touchPriority)

        ui.setLabelString(self.rootItems.doLab2,"战 斗",19)
        self.rootItems.doButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 4904,opt = 1,})
            gameWindows:closeWindowDirect("shenlongxuyuan_event")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton2:setSwallowsTouch(true)
        self.rootItems.doButton2:setTouchPriority(self.touchPriority)

        --
        self.rootItems.spendNode:setVisible(false)

    end



end

function shenlongxuyuan_event.close(self)
    self.ccbtype = 1
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return shenlongxuyuan_event