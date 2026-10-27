--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-7-28
-- Time: 下午1:36
-- To change this template use File | Settings | File Templates.
--


local vestGameScene = {
   
    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },
    viewSize = gameConfig.originSize,

    parent = nil,
    rootNode = nil,
    rootItems = nil,
    priorStatus = 0,

    mainstatus = 15,


    General = nil,
    isscrolltouched = false,
    huntnumber  = 1,
    isbuy  = 0,
    isinBuy = 0,
    rechage_time = nil 

}

function vestGameScene.clear(self)
   
end

local nowtime = 1
function vestGameScene.init(self,vestgamescene,topposY,isrelog)
    print("vestGameScene init"..topposY)
    self.parent = CCLayerColor:create(ccc4(0,0,0,255))
    self.parent:setColor(ccc3(0, 0, 0))
    self.parent:setContentSize(CCSizeMake(self.d_viewSize.width, self.d_viewSize.height))
    self.parent:setAnchorPoint(ccp(0,0))
    self.parent:setPosition(ccp(0,0))
    vestgamescene:addChild(self.parent)


    self.rootNode,self.rootItems = CCBReaderLoad("Login/soul2", nil, true, "loginsoul2")
    self.rootNode:setPosition(self.d_viewSize.width/2,0)
    self.parent:addChild(self.rootNode)
    self.rootNode:setScale(gameConfig.scaleNum)
    


    self.rootItems.no15:setVisible(true)
    self.rootItems.no6:setVisible(false)
    self.rootItems.to15:setTouchPriority(-101)
    self.rootItems.to15:addHandleOfControlEvent(function()
       self.rootItems.no15:setVisible(false)
       self.rootItems.no6:setVisible(true)
    end, CCControlEventTouchUpInside)
    self.rootItems.to6:setTouchPriority(-101)
    self.rootItems.to6:addHandleOfControlEvent(function()
        self.rootItems.no15:setVisible(true)
       self.rootItems.no6:setVisible(false)
    end, CCControlEventTouchUpInside)


    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    self.General = CCSkeletonAnimation:create("sunshangxiang/sunshangxiang.json","sunshangxiang/sunshangxiang.atlas",1) -- sunshangxiang
    self.General:setAnimation("stand",true,0)
    self.General:setScale(1.2)
    self.General:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(self.General)

    self.rootItems.huntstatusNode:removeAllChildrenWithCleanup(true)
    self.statusNode,self.statusItems = CCBReaderLoad("Login/soul2_zhuan", nil, true, "loginsoul_zhuan")
    self.statusNode:setPosition(0,5)
    self.rootItems.huntstatusNode:addChild(self.statusNode)

    self.rootItems.huntlistScroll:setContentSize(CCSizeMake(980,320))

        
    self.rootItems.hunt1:setTouchPriority(-101)
    self.rootItems.hunt1:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        self.General:setAnimation("attack",false,1)           
        huntnumber = math.random(1,4)
        self:makeHuntAnimation(huntnumber)
        self:relaodHunt()
        self:setHuntText(huntnumber)
     end, CCControlEventTouchUpInside)


    self.rootItems.hunt10:setTouchPriority(-101)
    self.rootItems.hunt10:addHandleOfControlEvent(function()
           gameTouch:clickprofbytime(1)
           self.General:setAnimation("attack",false,1)
           self:makeHuntAnimation(5)
           self:relaodHunt()
           self:setHuntText(5)
    end, CCControlEventTouchUpInside)
    -- self.isbuy = sdk:getMaJiaGold()
    -- print("vestGameScene isbuy "..self.isbuy)
    -- if self.isbuy == 0 then
    --     -- ui.addGray("CCControlButton",self.rootItems.hunt10)
    --     self.rootItems.hunt1consumNum2:setString("未购买月卡")
    --     self.rootItems.hunt10Text:setString("购买月卡")
    -- else
    --     ui.removeGray("CCControlButton",self.rootItems.hunt10)
    --     self.rootItems.hunt1consumNum2:setString("已经购买月卡")
    --     self.rootItems.hunt10Text:setString("高级狩猎")
    -- end    

    -- self.rootItems.hunt10:setTouchPriority(-101)
    -- self.rootItems.hunt10:addHandleOfControlEvent(function()
    --     if self.isbuy == 0 then
    --          if rechage_time then
    --          else  
    --             sdk:majiaBuy("com.ssj.zyj25")
    --             rechage_time = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
    --                 print("nowtime ======     ", nowtime)
    --                 nowtime = nowtime + 1
    --                 if nowtime == 60 then
    --                     runGamePrompt({msg = "响应超时"})
    --                     CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
    --                     rechage_time = nil
    --                     nowtime = 1
    --                 end
    --                 if nowtime%2==0 then
    --                     self.isbuy = sdk:getMaJiaGold()
    --                     if self.isbuy == 999 then
    --                         runGamePrompt({msg = "充值取消"})
    --                         CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
    --                         rechage_time = nil
    --                         nowtime = 1
    --                     elseif self.isbuy == 100 then
    --                         self.rootItems.hunt1consumNum2:setString("已经购买月卡")
    --                         self.rootItems.hunt10Text:setString("高级狩猎")
    --                         runGamePrompt({msg = "充值成功"})
    --                         CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
    --                         rechage_time = nil
    --                         nowtime = 1
    --                     end    
    --                 end
    --                 if  nowtime%20 == 0 then
    --                     runGamePrompt({msg = "充值中"})
    --                 end 
    --             end, 1, false)
    --          end   
    --     else
    --        gameTouch:clickprofbytime(1)
    --        self.General:setAnimation("attack",false,1)
    --        self:makeHuntAnimation(5)
    --        self:relaodHunt()
    --        self:setHuntText(5)
    --     end   
    -- end, CCControlEventTouchUpInside)
end



function vestGameScene.relaodHunt(self)
        gameTouch:clickprofbytime(2.5)
        self.rootItems["hunteffectnode"..((self.mainstatus == 6) and 2 or 1)]:removeAllChildrenWithCleanup(true)
        local Node,Items = CCBReaderLoad("UIEffect/soul/soul_huode", nil, true, "do")
        Node:setPosition(9999,0)
        self.rootItems["hunteffectnode"..((self.mainstatus == 6) and 2 or 1)]:addChild(Node)
        local animationManager = getAnimationManager(Items)
        animationManager:setAnimationCompletedCallback(function()
            self.rootItems["hunteffectnode"..((self.mainstatus == 6) and 2 or 1)]:removeAllChildrenWithCleanup(true)
            self:setStatus()
        end)
        Node:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2), CCCallFunc:create(function()
            Node:setPosition(0,0)
            animationManager:runAnimationsForSequenceNamed((self.mainstatus == 6) and "play_yuanbao" or "play_yinbi")
        end)))
        self.rootItems["generalEffectNode"]:removeAllChildrenWithCleanup(true)
        local Node1,Items1 = CCBReaderLoad("UIEffect/soul/soul_she", nil, true, "do")
        Node1:setPosition(0,0)
        self.rootItems["generalEffectNode"]:addChild(Node1)
        local animationManager1 = getAnimationManager(Items1)
        animationManager1:setAnimationCompletedCallback(function()
            self.rootItems["generalEffectNode"]:removeAllChildrenWithCleanup(true)
        end)
        animationManager1:runAnimationsForSequenceNamed((self.mainstatus == 6) and "soul_yuanbao" or "soul_yinbi")

end

function vestGameScene.setHuntText(self,huntnumber)

        self.rootItems.huntlistScroll:removeAllChildrenWithCleanup(true)
        local label = CCLabelTTF:create("勇士恭喜你射下：", "Helvetica", 40)
        label:setFontName("Helvetica-Bold")   
        label:setFontSize(40)

        local huntcontent = ""
        if huntnumber == 1 then
            huntcontent = "土星 \n土星－性情温厚笃实，而具有自信心。\n土性代表信，就是又诚实又温厚诚恳之意。"
            label:setColor(ccc3(128,138,135))
        elseif huntnumber == 2 then
            huntcontent = "木星 \n木星－好华美，且具有风雅的个性。木\n性代表仁，就是又慈爱，又行善的意思。"
            label:setColor(ccc3(0,255,0))
        elseif huntnumber == 3 then
            huntcontent = "水星 \n水星－人聪明，并能推测事物。水性代表智\n， 就是观察事物详细，对于任何事能\n预知前兆，善理权谋术事。 "
             label:setColor(ccc3(0,0,255))
        elseif huntnumber == 4  then
            huntcontent = "火 \n火星－性情急躁，而富有自尊心。火性代表礼\n，就是为人谦让谨慎，敬上而不欺下。 　"
            label:setColor(ccc3(160,32,240))
        elseif huntnumber == 5  then
            huntcontent = "金星 \n金星－性情刚强，而具有自尊心。金性代表义\n，就是崇善弃恶，事事都顺理。 "
            label:setColor(ccc3(255,215,0))
        end
        label:setString("舰娘舰娘，后羿为你射下："..huntcontent)
        label:setPosition(450, 200)
        self.rootItems.huntlistScroll:addChild(label,10000)
end

function vestGameScene.makeHuntAnimation(self,hunt)

    local animationManager = getAnimationManager(self.statusItems)
    if self.priorStatus == 0 then
        animationManager:setAnimationCompletedCallback(function()
            --gameTouch:setClickProf(false)
        end)
        animationManager:runAnimationsForSequenceNamed(tostring(hunt))
    elseif  hunt == 1 then
        animationManager:setAnimationCompletedCallback(function()
            animationManager:runAnimationsForSequenceNamed(tostring(hunt))
            --gameTouch:setClickProf(false)
        end)
        animationManager:runAnimationsForSequenceNamed(self.priorStatus.."-1")
    elseif hunt > self.priorStatus then
        local index =  self.priorStatus
        local function onestep()
            if index >= hunt then
                animationManager:runAnimationsForSequenceNamed(tostring(hunt))
                --gameTouch:setClickProf(false)
                return
            else
                index = index +1
                animationManager:setAnimationCompletedCallback(function()
                    onestep()
                end)
                animationManager:runAnimationsForSequenceNamed((index-1).."-"..index)
            end
        end
        onestep()
    else
        animationManager:setAnimationCompletedCallback(function()
            local index =  1
            local function onestep()
                if index >= hunt then
                    animationManager:runAnimationsForSequenceNamed(tostring(hunt))
                    --gameTouch:setClickProf(false)
                    return
                else
                    index = index +1
                    animationManager:setAnimationCompletedCallback(function()
                        onestep()
                    end)
                    animationManager:runAnimationsForSequenceNamed((index-1).."-"..index)
                end
            end
            onestep()
        end)
        animationManager:runAnimationsForSequenceNamed(self.priorStatus.."-1")
    end

end

function vestGameScene.reset(self)
   
end




return vestGameScene�,  