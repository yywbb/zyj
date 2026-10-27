--
-- Author: songyibo
-- Date: 2019-03-20 18:55:42
--

local babelTower = {

    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
}

function babelTower.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("tongtianta/tongtianta", nil, true, "tongtianta")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
   
    self.rootItems.container:setContentSize(CCSize(1080,3900))
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos - 160))
    -- self.rootItems.scrollnode:setTouchEnabled(false)

    self.mapNode, self.mapItems = CCBReaderLoad("tongtianta/tongtianta_map", nil, true, "tongtianta_map")
    self.mapNode:setPosition(0,0)
    self.rootItems.container:addChild(self.mapNode)
    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
        
    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority - 2)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    self.rootItems["btnRule"]:setSwallowsTouch(true)
    self.rootItems["btnRule"]:setTouchPriority(self.touchPriority-2)
    self.rootItems["btnRule"]:addHandleOfControlEvent(function()
        print("btnRule")
        gameWindows:openWindow("babelTowerRule")
    end, CCControlEventTouchUpInside)
    
    self.rootItems["btnAward"]:setSwallowsTouch(true)
    self.rootItems["btnAward"]:setTouchPriority(self.touchPriority-2)
    self.rootItems["btnAward"]:addHandleOfControlEvent(function()
        print("btnAward")
        gameWindows:openWindow("babelTowerAward",self.data)
    end, CCControlEventTouchUpInside)

    self.rootItems["shop"]:setSwallowsTouch(true)
    self.rootItems["shop"]:setTouchPriority(self.touchPriority-2)
    self.rootItems["shop"]:addHandleOfControlEvent(function()
        print("shop")
         GameScene:shiftLayerById(451)
    end, CCControlEventTouchUpInside)


    self.rootItems["btnRank"]:setSwallowsTouch(true)
    self.rootItems["btnRank"]:setTouchPriority(self.touchPriority-2)
    self.rootItems["btnRank"]:addHandleOfControlEvent(function()
        print("btnRank")
         gameWindows:openWindow("babelTowerRank")
    end, CCControlEventTouchUpInside)

    for i=1,6 do
        self.mapItems["mapbutton"..i]:setSwallowsTouch(false)
        self.mapItems["mapbutton"..i]:setTouchPriority(self.touchPriority)
        self.mapItems["mapbutton"..i]:addHandleOfControlEvent(function()
            if self.isContentScroll then return end

            if self.curSlidePoint == i then
                self:enterMapPoint(i)
            else
                self:scrollFixedPostion(i)
            end
            
        end, CCControlEventTouchUpInside)
    end

    self:reload(param)
    self:setTouch()
    self:setTipShow(true)

    self:scrollFixedPostion(self.data.maxPoint,true)
end

function babelTower.scrollFixedPostion(self,index,noAni)
    local diffY = gameConfig.topposY - 1920
    local offsetY = {
        [1] = 0,
        [2] = -300 + diffY,
        [3] = -800 + diffY,
        [4] = -1350 + diffY,
        [5] = -1790 + diffY,
        [6] = -2200 + diffY,
    }
    self.curSlidePoint = index
    if noAni then
        print("scrollFixedPostion",index,offsetY[self.curSlidePoint])
        local moveTo = CCMoveTo:create(0, ccp(self.rootItems.container:getPositionX(), offsetY[self.curSlidePoint]))
        self.rootItems.container:runAction(moveTo)
    else
        gameTouch:clickprofbytime(0.3)
        local moveTo = CCMoveTo:create(0.3, ccp(self.rootItems.container:getPositionX(), offsetY[self.curSlidePoint]))
        self.rootItems.container:runAction(moveTo)
    end
    self:setTipShow()
end

function babelTower.setTouch(self)
    local scrollViewMidPos = (self.toppos - 160)/2
    self.curSlidePoint = 1

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)
        print("ccTouchMoved",self.rootItems.container:getPositionY(),scrollViewMidPos)
        if y - self.touchY > 0 then
            for i=1,6 do
                local middleNodePosy = self.mapItems["middleNode"..i]:getPositionY() + self.rootItems.container:getPositionY()
                if math.abs(middleNodePosy - scrollViewMidPos ) < 200 then
                    if self.curSlidePoint ~= i then
                        self.curSlidePoint = i
                        self:setTipShow()
                    end
                    break
                end
            end
        elseif y - self.touchY < 0 then
           for i=6,1,-1 do
                local middleNodePosy = self.mapItems["middleNode"..i]:getPositionY() + self.rootItems.container:getPositionY()
                if math.abs(middleNodePosy - scrollViewMidPos ) < 200 then
                    if self.curSlidePoint ~= i then
                        self.curSlidePoint = i
                        self:setTipShow()
                    end
                    break
                end
            end
        end
    end

    local function ccTouchEnded(x, y)
        if math.abs(y - self.touchY) > 30 then
            self.isContentScroll = true
        end
        -- if y - self.touchY > 70 then
        --     self.curSlidePoint = self.curSlidePoint - 1
        --     self.curSlidePoint = math.max(self.curSlidePoint,1)
        -- elseif y - self.touchY < -70 then
        --     self.curSlidePoint = self.curSlidePoint + 1
        --     self.curSlidePoint = math.min(self.curSlidePoint,5)
        -- end
        -- gameTouch:clickprofbytime(0.3)
        -- local moveTo = CCMoveTo:create(0.3, ccp(self.rootItems.container:getPositionX(), offsetY[self.curSlidePoint]))
        -- self.rootItems.container:runAction(moveTo)

        -- self:setTipShow()
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority-1, false)
    self.rootItems.touchLayer:setTouchPriority(self.touchPriority-1)
    self.rootItems.touchLayer:setTouchEnabled(true)
end

function babelTower.setTipShow(self,isfirst)
    for i=1,6 do
        if self.curSlidePoint == i then
            self.mapItems["blackbg"..i]:setVisible(false)
            self.mapItems["tip"..i]:setVisible(true)
        else
            self.mapItems["blackbg"..i]:setVisible(true)
            self.mapItems["tip"..i]:setVisible(false)
        end

        if i > self.data.maxPoint then
            self.mapItems["blackbg"..i]:setVisible(true)
        end
    end


    if not isfirst then
        local animationManager = getAnimationManager(self.mapItems)
        --动画完成操作
        animationManager:setAnimationCompletedCallback(function()
        end)
        --先播放动画
        animationManager:runAnimationsForSequenceNamed("play")
    end
end

function babelTower.enterMapPoint(self,index)
    print("enterMapPoint",i)
    if self.data.curPoint > 0 and self.data.curPoint ~= index  then
        runGamePrompt({msg = string.format(gameConfig.strings:string_common("babelTower", 3), self.data.curPoint)})
    else
        gameWindows:openWindow("babelTowerEnter",{enterMapId = index,mapData = self.data})
    end
end

function babelTower.reload(self,data)
    printT(data,"babelTower")
    self.data = data

    self:setChallengeTimes()
    
    self.rootItems["buyTime"]:setSwallowsTouch(true)
    self.rootItems["buyTime"]:setTouchPriority(self.touchPriority-1)
    self.rootItems["buyTime"]:addHandleOfControlEvent(function()
        print("buyTime")
        gameWindows:openWindow("babelTowerBuy",{buyTime = self.data.buyTime,challengeTime = self.data.challengeTime})
    end, CCControlEventTouchUpInside)
    

    for i=1,6 do
        if i > self.data.maxPoint then
            self.mapItems["suo"..i]:setVisible(true)
        else
            self.mapItems["suo"..i]:setVisible(false)
        end
        
    end

    local hint = false
    for i=1,6 do
        if self.data["awardStatus"..i] == 1 then
            hint = true
            break
        end
    end

    if hint then
        self.rootItems.hit_award:setVisible(true)
    else
        self.rootItems.hit_award:setVisible(false)
    end
end

function babelTower.setChallengeTimes(self)
    self.maxChallengeTime = gamedata.config.vip["0"].tongtianta_cishu + gamedata.config.vip[tostring(GameScene.vip.vip)].tongtianta_cishu

    local canChallengeTime = math.max(gamedata.config.vip["0"].tongtianta_cishu + self.data.buyTime - self.data.challengeTime,0)
    self.rootItems.challengeTime:setString(canChallengeTime)
    if canChallengeTime > 0 then
        self.rootItems.challengeTime:setColor(ccc3(255,255,255))
    else
        self.rootItems.challengeTime:setColor(ccc3(255,0,0))
    end
    self.rootItems.challengeMaxTime:setString("/"..self.maxChallengeTime)
end

function babelTower.freshChallengeTimes(self,times)
    self.data.buyTime = times
    self:setChallengeTimes()
end

function babelTower.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return babelTower