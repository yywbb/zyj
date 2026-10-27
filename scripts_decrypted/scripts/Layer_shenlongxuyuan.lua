--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/11/8
-- Time: 16:27
-- To change this template use File | Settings | File Templates.
--

local shenlongxuyuan = {

    rootNode = nil,
    rootItems = nil,

    mapNode = nil,
    mapItems = nil,

    shaiziCCB = nil,
    shaiziItem = nil,

    animationManager_shaizi = nil,
    animationManager_map = nil,

    mappoints = {},
    pointnow = 1,

    dice_cost = 0,

    dragonwishing = {},
    mapconfig = {},

    maxpx = 2305*2,
    maxpy = 1292*2,

    fixpx = 0,
    fixpy = 0,

    olddata = nil,

    mapSpecial = {
        [1] = {
            flipx1 = {26,27,28,29,30,31,32,94,95,96,97,98,99,100,101},
            flipx2 = {65,66,67,68,69,70},
            flipx3 = {102,103,104},

            directionTab = {9,17,29,49,64,82},
            directionTab2 = {["9"]={[10] ="shang",[8]="xia",[26]="zuo",[71]= "you"},
                             ["17"]={[18]="shang",[16]="xia",[70]="zuo",[104]="you"},
                             ["29"]={[30]="zuo",[28]="you",[57]= "shang"},
                             ["49"]={[50]="shang",[67]="xia",[48]="zuo"},
                             ["64"]={[68]="you",[63]="xia",[65]="shang"},
                             ["82"]={[83]="you",[102]="zuo",[81]="xia"}},
        },
        [2] = {
            flipx1 = {20,21,33,35,48,49,62,65,66,67,106,107,108,113,114,115,118,120,122,124,125,126,127,128,129,131,133},
            flipx2 = {19},
            flipx3 = {68},

            directionTab = {4,7,19,23,26,31,68,92,99},
            directionTab2 = {["4"]={[5] = "shang", [3] = "xia", [77] = "you"},
                             ["7"]={[6] = "xia", [8] = "zuo", [50] = "you"},
                             ["19"]={[18] = "xia", [20] = "zuo", [68] = "you"},
                             ["23"]={[24] = "shang", [22] = "xia", [32] = "zuo"},
                             ["26"]={[27] = "shang", [25] = "xia", [45] = "you"},
                             ["31"]={[30] = "xia", [44] = "zuo", [136] = "you"},
                             ["68"]={[69] = "shang", [19] = "zuo", [67] = "you"},
                             ["92"]={[93] = "shang", [91] = "xia", [102] = "you"},
                             ["99"]={[100] = "shang", [98] = "xia", [109] = "you"}},
        },
    },
    
    shijianFangxiangNode = nil,
    shijianFangxiangItems = nil,
    shijianFangxiangAnimationManager =nil,

    diceNum = 0,
    roadPoint = nil,

    longEffect = 0,
    m_bIsAutoGame = nil, -- 自动游戏

}
local QRIL_AUTO_NONE = -1
local QRIL_AUTO_TRUE = 0
local QRIL_AUTO_PAUSE= 1


function shenlongxuyuan.init(self,parent,toppos,data)
    print(self.mapNumber)
    self.mapNumber = data
    self.rootNode,self.rootItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan", nil, true, "shenlongxuyuan")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if self.mapNumber == 1 then
        self.mapNode, self.mapItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_map", nil, true, "map")
        setSpriteFrameByName(self.rootItems.miniMap, "shenlongxuyuan_11.png")
        self.maxpy = 1292*2
    elseif self.mapNumber == 2 then
        self.mapNode, self.mapItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_map2", nil, true, "map")
        setSpriteFrameByName(self.rootItems.miniMap, "shenlongbg2_xiaomap.jpg")
        self.maxpy = 1428*2
    end

    self.rootItems.container:setContentSize(CCSize(self.maxpx,self.maxpy))
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(-101)
    self.rootItems.scrollnode:setBounceable(false)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(-101)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    self.mapNode:setPosition(0,0)
    self.rootItems.container:addChild(self.mapNode)
    self.animationManager_map = getAnimationManager(self.mapItems)

    --
    self.fixpx = gameConfig.originSize.width/2
    self.fixpy = (toppos-160)/2
    --

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
    --

    self.mapItems["general"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.roleinfo.profile)].animationid)].name
    local wing = {level = GameScene.protagonist.w_l,color = GameScene.protagonist.w_c}
    --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(0.8)
    Gneral1:setPosition(0,0)
    self.mapItems["general"]:addChild(Gneral1.root or Gneral1)
    --
    self.mapItems["generalNode"]:setPosition(-9999,-9999)
    --

    --
    if self.mapNumber == 1 then
        self.maxMapPoint = 106
    elseif self.mapNumber == 2 then
        self.maxMapPoint = 139
    end

    for i = 1,self.maxMapPoint do
        if not self.mapItems["p"..i] then
            print("error point "..i)
        end
        local px = self.mapItems["p"..i] and self.mapItems["p"..i]:getPositionX() or -9999
        local py = self.mapItems["p"..i] and self.mapItems["p"..i]:getPositionY() or -9999
        self.mappoints[tostring(i)] = {x = px, y = py}
    end

    -- 介绍
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:setTouchPriority(-103)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        print("rulebutton")   --
        if self.longEffect and (self.longEffect == 1) then return end
        gameWindows:openWindow("shenlongxuyuan_rule",nil, nil)
    end, CCControlEventTouchUpInside)


    -- 骰子  shenlong_dice_cost
    self.rootItems.rollBtn:setSwallowsTouch(true)
    self.rootItems.rollBtn:setTouchPriority(-103)
    self.rootItems.rollBtn:addHandleOfControlEvent(function()
        print("rollBtn")
        if self.longEffect and (self.longEffect == 1) then return end
        gameTouch:clickprofbytime(1)
        --
        if self.dragonwishing.reward == 1 then
            runGamePrompt({msg = "召唤神龙后可继续前进"})
        else    
            UIRequest({type = 4902,xgold = self.dice_cost or 0})
        end

    end, CCControlEventTouchUpInside)

    local globConfig = gamedata.config.global_kv
    if GameScene.roleinfo.level >= tonumber(globConfig.shenlong_quick_complete_level.value) then
        self.rootItems.autoNode:setVisible(true)
    else
        self.rootItems.autoNode:setVisible(false)
    end

    self.m_bIsAutoGame = QRIL_AUTO_NONE
    local tmpVip = tonumber(globConfig.shenlong_quick_complete_vip.value)
    ui.setLabelString(self.rootItems.exwRevers,"",13)
    self.rootItems.autoButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if GameScene.roleinfo.level >= tonumber(globConfig.shenlong_quick_complete_level.value) then
            if self.dragonwishing.reward == 1 then
                runGamePrompt({msg = "召唤神龙后可继续前进"})
            elseif GameScene.roleinfo.level >= tonumber(globConfig.shenlong_quick_complete_level2.value) then
                self.m_bIsAutoGame = QRIL_AUTO_TRUE
                UIRequest({type = 4902,xgold = self.dice_cost or 0})
            else
                if GameScene.vip.vip >= tmpVip then
                    self.m_bIsAutoGame = QRIL_AUTO_TRUE
                    UIRequest({type = 4902,xgold = self.dice_cost or 0})
                else
                    runGamePrompt({msg = "需要队伍等级"..globConfig.shenlong_quick_complete_level2.value.."或VIP"..tmpVip.."开启"})
                end
            end
        else
            runGamePrompt({msg = "需要等级"..globConfig.shenlong_quick_complete_level.value.."开启"})
        end

        -- if GameScene.vip.vip >= tmpVip then
        --     self.m_bIsAutoGame = QRIL_AUTO_TRUE
        --     UIRequest({type = 4902,xgold = self.dice_cost or 0})
        -- else
        --     runGamePrompt({msg = "VIP等级不足"})
        -- end
        self:setAutoNode()
    end, CCControlEventTouchUpInside)
    self.rootItems.autoButton:setSwallowsTouch(true)
    self.rootItems.autoButton:setTouchPriority(-103)

    self.shijianFangxiangNode,self.shijianFangxiangItems = CCBReaderLoad("shenlongxuyuan/shijian_fangxiang", nil, true, "shijian_fangxiang")
    self.shijianFangxiangNode:setPosition(0,0)
    self.shijianFangxiangNode:setVisible(false)
    self.shijianFangxiangAnimationManager = getAnimationManager(self.shijianFangxiangItems)
    self.mapItems["generalfangxiang"]:addChild(self.shijianFangxiangNode)


    self:setAutoNode()
    --
    gameTouch:clickprofbytime(1)
    UIRequest({type = 4901})
end

function shenlongxuyuan.setAutoNode(self)
    if self.rootItems and self.rootItems.is_auto then
        if self.m_bIsAutoGame and self.m_bIsAutoGame > -1 then
            self.rootItems.autoNode:setVisible(false)
            self.rootItems.is_auto:setVisible(true)
        else
            self.rootItems.autoNode:setVisible(true)
            self.rootItems.is_auto:setVisible(false)
        end
    end    
end

--
function shenlongxuyuan.moveEndmap(self)
    gameTouch:clickprofbytime(1.5)

    self:movePoint(self.maxMapPoint)
    self.mapNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
        self:movePoint(self.dragonwishing.nowpoint or 1)
    end)))
end


function shenlongxuyuan.reloaddata(self,data)

    gameTouch:clickprofbytime(0.5)

    if data and data.dragonwishing then
        self.dragonwishing = data.dragonwishing
    end
    --

    --opt2 start
    --骰子数
    local dicemax = gamedata.config.global_kv.shenlong_dice_limit and tonumber(gamedata.config.global_kv.shenlong_dice_limit.value) or 0
    ui.setLabelString(self.rootItems.diceNum,"( "..(self.dragonwishing.dicenum or 0).." / "..dicemax.." )" ,14)
    --元宝
    if self.dragonwishing.dicenum and self.dragonwishing.dicenum > 0 then
        self.dice_cost = 0
        self.rootItems.spendNode:setVisible(false)
        self.rootItems.spendNode_Onekey:setVisible(false)
    else
        self.m_bIsAutoGame = QRIL_AUTO_NONE
        local dice_cost = 0
        if gamedata.config.buycount_price[tostring(self.dragonwishing.dicebuy+1)] and gamedata.config.buycount_price[tostring(self.dragonwishing.dicebuy+1)].shenlong_dice_cost then
            dice_cost = gamedata.config.buycount_price[tostring(self.dragonwishing.dicebuy+1)].shenlong_dice_cost
        elseif gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))] and gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].shenlong_dice_cost then
            dice_cost = gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].shenlong_dice_cost
        end
        self.dice_cost = dice_cost
        self.rootItems.spendNode:setVisible(self.dice_cost > 0)
        self.rootItems.spendNode_Onekey:setVisible(self.dice_cost > 0)
        ui.setLabelString(self.rootItems.spendText_Onekey,self.dice_cost,14)
        ui.setLabelString(self.rootItems.spendText,self.dice_cost,14)
    end
    --
    if self.dragonwishing.reward == 1 then
        self.m_bIsAutoGame = QRIL_AUTO_NONE
    end    
    --
    if  gameTimer.times["shenlongxuyuandice"] and gameTimer.times["shenlongxuyuandice"] > 0 then
        gameTimer:rigistTimeFunc("shenlongxuyuandice",function()
            if  gameTimer.times["shenlongxuyuandice"] > 0 then
                if self.dragonwishing.dicenum and self.dragonwishing.dicenum >= dicemax then
                    ui.setLabelString(self.rootItems.time," ",14)
                else
                    ui.setLabelString(self.rootItems.time,ui.makeTimeText(gameTimer.times["shenlongxuyuandice"],"minute"),14)
                end
            else
                ui.setLabelString(self.rootItems.time," ",14)
                gameTouch:clickprofbytime(1)
                UIRequest({type = 4901,opt = 2})
            end
        end)
    else
        ui.setLabelString(self.rootItems.time," ",14)
    end
    --opt2 end
    if data and data.opt and data.opt == 2 then
        return
    end

    --
    if self.rootItems.todaylongzhu then
        if self.dragonwishing.ballstatus and self.dragonwishing.ballstatus == 0 and self.dragonwishing.ballnum and self.dragonwishing.ballnum < 7 then
            self.rootItems.todaylongzhu:setPosition(self.rootItems["longzhu"..(self.dragonwishing.ballnum+1)]:getPositionX(),self.rootItems["longzhu"..(self.dragonwishing.ballnum+1)]:getPositionY())
            self.rootItems.todaylongzhu:setVisible(true)
        else
            self.rootItems.todaylongzhu:setVisible(false)
        end
    end
    if self.rootItems.lztodayLab and self.rootItems.lztoday then
        ui.setLabelString(self.rootItems.lztodayLab,nil,14)
        if self.dragonwishing.ballstatus and self.dragonwishing.ballstatus == 1 then
            ui.setLabelString(self.rootItems.lztoday,"(今日已获得)",3)
        else
            ui.setLabelString(self.rootItems.lztoday,"(今日未获得)",11)
        end
    end

    --longzhu
    if self.olddata and self.olddata.ballnum and self.olddata.ballnum < self.dragonwishing.ballnum then
        if self.dragonwishing.ballnum >= 1 and self.dragonwishing.ballnum <= 7 then
            local Node,Items = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_longzhu", nil, true, "effect")
            Node:setPosition(0,0)
            setSpriteFrameByName(Items.sprite1, "shenlongxuyuan_"..self.dragonwishing.ballnum)
            setSpriteFrameByName(Items.sprite2, "shenlongxuyuan_"..self.dragonwishing.ballnum)
            self.rootItems["longzhu"..self.dragonwishing.ballnum]:addChild(Node)
            local animationManager = getAnimationManager(Items)
            animationManager:setAnimationCompletedCallback(function()
                Node:removeFromParentAndCleanup(true)
            end)
            animationManager:runAnimationsForSequenceNamed("play")
            --
            runGamePrompt({msg = "获得今日龙珠"})
        end
    end

    --
    if data and data.startStaus and data.startStaus == 1 then
        local function callback()
            self.mapItems["generalNode"]:setVisible(false)
            self:moveEndmap()
            self.mapNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5),CCCallFunc:create(function()
                self.mapItems["generalNode"]:setVisible(true)
            end)))
        end
        gameWindows:openWindow("shenlongxuyuan_rule",nil,callback)
    else
        self:movePoint(self.dragonwishing.nowpoint or 1)
    end
    --
    --骰子
    local dicestatus = self.dragonwishing.dicestatus or 1
    self.rootItems.rolleffectNode:removeAllChildrenWithCleanup(true)
    self.shaiziCCB, self.shaiziItem = CCBReaderLoad("UIEffect/shaizi/shaizi"..((dicestatus > 1) and "2" or ""), nil, true, "shaizi")
    self.shaiziCCB:setAnchorPoint(ccp(0.0,0.0))
    self.shaiziCCB:setPosition(ccp(0,0))
    self.rootItems.rolleffectNode:addChild(self.shaiziCCB)
    --
    self.animationManager_shaizi = getAnimationManager(self.shaiziItem)
    self.animationManager_shaizi:runAnimationsForSequenceNamed("play")
    --
    if self.mapNumber == 1 then
        self.mapconfig = gamedata.config.shenlong_random and gamedata.config.shenlong_random[tostring(self.dragonwishing.map or 1)] or {}
    elseif self.mapNumber == 2 then
        self.mapconfig = gamedata.config.shenlong_random2 and gamedata.config.shenlong_random2[tostring(self.dragonwishing.map or 1)] or {}
    end
    --点

    for i = 1,self.maxMapPoint do
        if self.mapItems["p"..i] then
            --self.mapItems["p"..i]:removeAllChildrenWithCleanup(true)
            if self.mapconfig["point"..i] and self.mapconfig["point"..i] > 0 and self.dragonwishing.pointstatus and self.dragonwishing.pointstatus[tostring(i)] and self.dragonwishing.pointstatus[tostring(i)] > 0 then
                local typeccb = gamedata.config.shenlong_type and gamedata.config.shenlong_type[tostring(self.mapconfig["point"..i])].icon or "suiji"
                if i == self.maxMapPoint and self.dragonwishing.ballstatus and self.dragonwishing.ballstatus == 1 then
                    typeccb = "box2"
                end 
                local Node,Items = CCBReaderLoad("shenlongxuyuan/shijian_"..typeccb, nil, true, "shijian")
                Node:setPosition(0,0)
                if typeccb == "suiji" then
                    local animationManager = getAnimationManager(Items)
                    animationManager:runAnimationsForSequenceNamed("free")
                end
                --
                if Items.battleGeneral then
                    if i == self.maxMapPoint then
                        Node:setScale(1.3)
                        if Items.isboss then
                            Items.isboss:setVisible(true)
                        end
                    else
                        Node:setScale(1)
                        if Items.isboss then
                            Items.isboss:setVisible(false)
                        end
                    end
                    local isflipx = false
                    for k,v in ipairs(self.mapSpecial[self.mapNumber].flipx1) do
                        if v == i then
                            isflipx = true
                        end
                    end
                    Items.battleGeneral:removeAllChildrenWithCleanup(true)
                    local generalcid = 0
                    if gamedata.config.zodiac_new and gamedata.config.zodiac_new[tostring(self.dragonwishing.pointstatus[tostring(i)])] and gamedata.config.zodiac_new[tostring(self.dragonwishing.pointstatus[tostring(i)])]["1"] then
                        generalcid = gamedata.config.zodiac_new[tostring(self.dragonwishing.pointstatus[tostring(i)])]["1"].monsterid or 0
                    end
                    if generalcid > 0 then
                        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(generalcid)].animationid)].name
                        local wing = {level = 0,color = 0}
                        --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                        local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
                        Gneral1:setAnimation("stand",true,0)
                        Gneral1:setScale(0.8)
                        Gneral1:setScaleX(isflipx and 0.8 or -0.8)
                        Gneral1:setPosition(0,0)
                        Items.battleGeneral:addChild(Gneral1.root or Gneral1)
                    end
                    --
                    if self.olddata and self.olddata.pointstatus[tostring(i)] and self.dragonwishing.pointstatus[tostring(i)] == self.olddata.pointstatus[tostring(i)] then
                        print("has point")
                    else
                        self.mapItems["p"..i]:removeAllChildrenWithCleanup(true)
                        self.mapItems["p"..i]:addChild(Node)
                    end
                else
                    self.mapItems["p"..i]:removeAllChildrenWithCleanup(true)
                    self.mapItems["p"..i]:addChild(Node)
                end
            else
                self.mapItems["p"..i]:removeAllChildrenWithCleanup(true)
            end
        end
    end

    --olddata
    self.olddata = table.copy(self.dragonwishing)
    --

    --龙珠
    for i = 1,7 do
        if self.dragonwishing.ballnum >= i then
            self.rootItems["pic_longzhu"..i]:setVisible(true)
        else
            self.rootItems["pic_longzhu"..i]:setVisible(false)
        end
    end
    --大奖
    self.rootItems.isreward:setVisible(self.dragonwishing.reward == 1)
    self.rootItems.noreward:setVisible(self.dragonwishing.reward ~= 1)
    --
    self.rootItems.rewardButton:setSwallowsTouch(true)
    self.rootItems.rewardButton:setTouchPriority(-103)
    self.rootItems.rewardButton:addHandleOfControlEvent(function()
        print("rewardButton")
        if self.longEffect and (self.longEffect == 1) then return end
        if self.dragonwishing.reward == 1 then
            --
            gameTouch:clickprofbytime(7.5)
            self.rootItems.effect_do:removeAllChildrenWithCleanup(true)
            local Node,Items = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_longzhueffect", nil, true, "effect")
            Node:setPosition(0,0)
            self.rootItems.effect_do:addChild(Node)
            local animationManager = getAnimationManager(Items)
            animationManager:setAnimationCompletedCallback(function()
                --
                local Node1,Items1 = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_effect", nil, true, "effect")
                Node1:setPosition(self.fixpx,self.fixpy)
                self.rootNode:addChild(Node1)
                local animationManager1 = getAnimationManager(Items1)
                animationManager1:runAnimationsForSequenceNamed("start")
                self.longEffect = 1
                --
                Items1.button1:setSwallowsTouch(true)
                Items1.button1:setTouchPriority(-104)
                Items1.button1:addHandleOfControlEvent(function()
                    print("button1")
                    local cb = function()
                        self.longEffect = 0
                        gameTouch:clickprofbytime(1)
                        animationManager1:runAnimationsForSequenceNamed("end")
                        UIRequest({type = 4903,id = 1})
                    end
                    gameWindows:openWindow("shenlongxuyuan_reward",{select = 1}, cb)
                end, CCControlEventTouchUpInside)
                --
                Items1.button2:setSwallowsTouch(true)
                Items1.button2:setTouchPriority(-104)
                Items1.button2:addHandleOfControlEvent(function()
                    print("button2")
                    local cb = function()
                        self.longEffect = 0
                        gameTouch:clickprofbytime(1)
                        animationManager1:runAnimationsForSequenceNamed("end")
                        UIRequest({type = 4903,id = 2})
                    end
                    gameWindows:openWindow("shenlongxuyuan_reward",{select = 2}, cb)
                end, CCControlEventTouchUpInside)
                --
                Items1.button3:setSwallowsTouch(true)
                Items1.button3:setTouchPriority(-104)
                Items1.button3:addHandleOfControlEvent(function()
                    print("button3")
                    local cb = function()
                        self.longEffect = 0
                        gameTouch:clickprofbytime(1)
                        animationManager1:runAnimationsForSequenceNamed("end")
                        UIRequest({type = 4903,id = 3})
                    end
                    gameWindows:openWindow("shenlongxuyuan_reward",{select = 3}, cb)
                end, CCControlEventTouchUpInside)
                --
            end)
            --
            for i = 1,7 do
                self.rootItems["pic_longzhu"..i]:setVisible(false)
            end
            animationManager:runAnimationsForSequenceNamed("play")
        else
            --runGamePrompt({msg = "集齐七颗龙珠可以获得最终奖励"})
            gameWindows:openWindow("shenlongxuyuan_jiangli",nil, nil)
        end
    end, CCControlEventTouchUpInside)


    --
    if self.dragonwishing and self.dragonwishing.nowpoint then
        if self.mapconfig["point"..(self.dragonwishing.nowpoint)] and self.mapconfig["point"..(self.dragonwishing.nowpoint)] > 0 and self.dragonwishing.pointstatus and self.dragonwishing.pointstatus[tostring(self.dragonwishing.nowpoint)] and self.dragonwishing.pointstatus[tostring(self.dragonwishing.nowpoint)] > 0 then
            if self.dragonwishing.eventstatus and self.dragonwishing.eventstatus == 0 then
                if (self.mapconfig["point"..(self.dragonwishing.nowpoint)] == 1) or (self.mapconfig["point"..(self.dragonwishing.nowpoint)] == 3) or (self.mapconfig["point"..(self.dragonwishing.nowpoint)] == 4) or (self.mapconfig["point"..(self.dragonwishing.nowpoint)] == 5) then
                    if self.dragonwishing.eventid > 10000 then
                        if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                            self.m_bIsAutoGame = QRIL_AUTO_PAUSE
                        end
                        gameWindows:openWindow("shenlongxuyuan_event",{ccbtype = 3,eventid = self.dragonwishing.eventid,shop1 = self.dragonwishing.shopnum1,shop2 = self.dragonwishing.shopnum2,shop3 = self.dragonwishing.shopnum3,shop4 = self.dragonwishing.shopnum4,}, nil)
                    elseif self.dragonwishing.eventid == 3 then
                        if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                            self.m_bIsAutoGame = QRIL_AUTO_PAUSE
                        end
                        gameWindows:openWindow("shenlongxuyuan_event",{ccbtype = 2,eventid = self.dragonwishing.eventid,shop1 = self.dragonwishing.shopnum1,shop2 = self.dragonwishing.shopnum2,shop3 = self.dragonwishing.shopnum3,shop4 = self.dragonwishing.shopnum4,}, nil)
                    elseif self.dragonwishing.eventid == 5 then
                        if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                            self.m_bIsAutoGame = QRIL_AUTO_PAUSE
                        end
                        gameWindows:openWindow("shenlongxuyuan_event",{ccbtype = 1,eventid = self.dragonwishing.eventid,shop1 = self.dragonwishing.shopnum1,shop2 = self.dragonwishing.shopnum2,shop3 = self.dragonwishing.shopnum3,shop4 = self.dragonwishing.shopnum4,}, nil)
                    end
                elseif self.mapconfig["point"..(self.dragonwishing.nowpoint)] >= 6 and self.mapconfig["point"..(self.dragonwishing.nowpoint)] <= 8 then
                    if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                        self.m_bIsAutoGame = QRIL_AUTO_PAUSE
                    end
                    gameWindows:openWindow("shenlongxuyuan_event",{ccbtype = 4,eventid = self.dragonwishing.pointstatus[tostring(self.dragonwishing.nowpoint)],shop1 = self.dragonwishing.shopnum1,shop2 = self.dragonwishing.shopnum2,shop3 = self.dragonwishing.shopnum3,shop4 = self.dragonwishing.shopnum4,}, nil)
                elseif self.mapconfig["point"..(self.dragonwishing.nowpoint)] == 9 then
                    if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                        self.m_bIsAutoGame = QRIL_AUTO_PAUSE
                    end
                    gameWindows:openWindow("shenlongxuyuan_event",{ccbtype = 5,eventid = self.dragonwishing.pointstatus[tostring(self.dragonwishing.nowpoint)],shop1 = self.dragonwishing.shopnum1,shop2 = self.dragonwishing.shopnum2,shop3 = self.dragonwishing.shopnum3,shop4 = self.dragonwishing.shopnum4,}, nil)
                end
            end
        end
    end

    self:setAutoNode()

    if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
        gameTouch:clickprofbytime(1)
        if self.dragonwishing.reward == 1 then
            runGamePrompt({msg = "召唤神龙后可继续前进"})
        else    
            UIRequest({type = 4902,xgold = self.dice_cost or 0})
        end
    end
end

function shenlongxuyuan.specialEvent(self,data)
    print("shenlongxuyuan specialEvent")
    if self.m_bIsAutoGame == QRIL_AUTO_PAUSE then
        self.m_bIsAutoGame = QRIL_AUTO_TRUE
        if gameWindows.windows["shenlongxuyuan_event"].show then
            gameWindows:closeWindow("shenlongxuyuan_event")
        end
        --gameWindows:closeAllWindowDirect()
    end
    gameTouch:clickprofbytime(1)
    UIRequest({type = 4901})
end


function shenlongxuyuan.setDice(self,data)

    gameTouch:clickprofbytime(1)

    self.dicestatus = data.dicestatus or {}
    self.last_reward = data.reward or nil
    self.last_battlereward = data.battlereward or nil
    self.last_battlereport = data.battlereport or nil
    self.last_result = data.result or nil
    self.diceNum = self.dicestatus.dice1 + self.dicestatus.dice2
    self:getLastPoint(self.diceNum)

    if self.animationManager_shaizi then
        self.animationManager_shaizi:setAnimationCompletedCallback(function()
            local frameName1 = "shaizi"..self.dicestatus.dice1
            setSpriteFrameByName(self.shaiziItem.rollFrame, frameName1)
            if self.dicestatus.dice2 and self.dicestatus.dice2 > 0 and self.shaiziItem.rollFrame2 then
                local frameName2 = "shaizi"..self.dicestatus.dice2
                setSpriteFrameByName(self.shaiziItem.rollFrame2, frameName2)
            end
            self:moveNext(self.dicestatus.route or {},1)
        end)
        self.animationManager_shaizi:runAnimationsForSequenceNamed("rolleffect")
    end
end

function shenlongxuyuan.getLastPoint(self, diceNum)
    self.lastPoint = self.dicestatus.route[tostring(diceNum)]
end

function shenlongxuyuan.moveRoadNext(self,route,index)
    gameTouch:clickprofbytime(1)
    local lastpoint = self.pointnow or 0

    if lastpoint == self.lastPoint then
        local typeccb = gamedata.config.shenlong_type and gamedata.config.shenlong_type[tostring(self.mapconfig["point"..self.pointnow])] and gamedata.config.shenlong_type[tostring(self.mapconfig["point"..self.pointnow])].id or 0
        if 11 <= typeccb and typeccb <= 26 then
            gameTouch:clickprofbytime(1.5)
            if  11 <= typeccb and typeccb <= 14 then
                runGamePrompt({msg = "好运当头，前进一步！"})
            elseif  15 <= typeccb and typeccb <= 18 then
                runGamePrompt({msg = "雨天路滑，后退一步！"})
            elseif  19 <= typeccb and typeccb <= 22 then
                runGamePrompt({msg = "好运当头，前进两步！"})
            elseif  23 <= typeccb and typeccb <= 26 then
                runGamePrompt({msg = "雨天路滑，后退两步！"})
            end
            self.mapItems["p"..self.pointnow]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.8),CCCallFunc:create(function()
                print(" move "..index.." point "..route[tostring(index)] or 0)
                self:movePoint(route[tostring(index)],lastpoint)
                self.mapNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.4),CCCallFunc:create(function()
                    self:moveNext(route,index+1)
                end)))
            end)))
        else
            gameTouch:clickprofbytime(0.5)
            print(" move "..index.." point "..route[tostring(index)] or 0)
            self:movePoint(route[tostring(index)],lastpoint)
            self.mapNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.4),CCCallFunc:create(function()
                self:moveNext(route,index+1)
            end)))
        end

    else
        gameTouch:clickprofbytime(0.5)
        print(" move "..index.." point "..route[tostring(index)] or 0)
        self:movePoint(route[tostring(index)],lastpoint)
        self.mapNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.4),CCCallFunc:create(function()
            self:moveNext(route,index+1)
        end)))
    end



end



function shenlongxuyuan.moveNext(self,l_route,l_index)
    gameTouch:clickprofbytime(1)
    local route = l_route or {}
    local index = l_index or 0
    local lastpoint = self.pointnow or 0

    if route and index and route[tostring(index)] and route[tostring(index)] > 0 then
--        print(" move "..index.." point "..route[tostring(index)] or 0)
--        self:movePoint(route[tostring(index)],lastpoint)
--        self.mapNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.4),CCCallFunc:create(function()
--            self:moveNext(route,index+1)
--        end)))

        for k,v in pairs(self.mapSpecial[self.mapNumber].directionTab) do
            if self.pointnow == v then
                self.roadPoint = self.pointnow
            end
        end

        if self.roadPoint and self.roadPoint ~= 0 then
            if route and route[tostring(index)] and route[tostring(index)] > 0 then
                gameTouch:clickprofbytime(1)
                --runGamePrompt({msg = "该走哪个路口呢？"})
                print(self.mapNumber, tostring(self.roadPoint), route[tostring(index)])
                local play_effectRoad = self.mapSpecial[self.mapNumber].directionTab2[tostring(self.roadPoint)][route[tostring(index)]]
                self.roadPoint = nil
                self.mapItems["generalfangxiang"]:stopAllActions()
                self.mapItems["generalfangxiang"]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.1),CCCallFunc:create(function()
                    self.shijianFangxiangNode:setVisible(true)
                    self.shijianFangxiangAnimationManager:setAnimationCompletedCallback(function()
                        self.shijianFangxiangNode:setVisible(false)
                        self:moveRoadNext(route,index)
                    end)
                    gameTouch:clickprofbytime(3.5)
                    if self.shijianFangxiangAnimationManager then
                        self.shijianFangxiangAnimationManager:runAnimationsForSequenceNamed("fangxiang_"..play_effectRoad)
                    end
                end)))

            end

        else
            self.roadPoint = nil
            self:moveRoadNext(route,index)
        end

    else
    --  
        print(" move end")
        local movecb = function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4901})
        end

        if self.last_battlereport then
            gameTouch:clickprofbytime(2)
            if self.rootItems.bosseffect and self.pointnow == self.maxMapPoint then
                self.rootItems.bosseffect:removeAllChildrenWithCleanup(true)
                local Node,Items = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_boss", nil, true, "boss")
                Node:setPosition(0,0)
                self.rootItems.bosseffect:addChild(Node)
                --
                gameTouch:clickprofbytime(5)
                self.mapItems["p"..self.pointnow]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(3),CCCallFunc:create(function()
                    RunbattleCallBack("penglai", {reward = self.last_battlereward or {}, battlereport = self.last_battlereport,result = self.last_result or 0}, movecb)
                end)))
            else
                RunbattleCallBack("penglai", {reward = self.last_battlereward or {}, battlereport = self.last_battlereport,result = self.last_result or 0}, movecb)
            end
        elseif self.last_reward and next(self.last_reward) then
            gameTouch:clickprofbytime(1)
            --showRewardPopupWindow(self.last_reward,nil,movecb)
            runGamePrompt({msg = "偶遇宝藏，获得奖励！"})
            self.mapItems["p"..self.pointnow]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.8),CCCallFunc:create(function()
                showRewardPopupWindow(self.last_reward,nil,movecb)
            end)))

        elseif self.dicestatus and self.dicestatus.eventid and self.dicestatus.eventid > 0 then
            --
            if self.dicestatus.eventid > 10000 then
                if self.mapconfig["point"..(self.pointnow)] == 1 then
                    runGamePrompt({msg = "途中偶遇，会碰到哪位仙子呢？"})
                    gameTouch:clickprofbytime(2.5)
                    self.mapItems["p"..self.pointnow]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.8),CCCallFunc:create(function()
                        self.mapItems["p"..self.pointnow]:removeAllChildrenWithCleanup(true)
                        local Node,Items = CCBReaderLoad("shenlongxuyuan/shijian_suiji", nil, true, "shijian")
                        Node:setPosition(0,0)
                        local animationManager = getAnimationManager(Items)
                        animationManager:setAnimationCompletedCallback(function()
                            movecb()
                        end)
                        --gameTouch:clickprofbytime(1.5)
                        animationManager:runAnimationsForSequenceNamed("play_select")
                        self.mapItems["p"..self.pointnow]:addChild(Node)
                    end)))
                else
                    gameTouch:clickprofbytime(1)
                    movecb()
                end    
            elseif self.dicestatus.eventid == 3 then
                if self.mapconfig["point"..(self.pointnow)] == 1 then
                    runGamePrompt({msg = "途中偶遇，会碰到哪位仙子呢？"})
                    gameTouch:clickprofbytime(2.5)
                    self.mapItems["p"..self.pointnow]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.8),CCCallFunc:create(function()
                        self.mapItems["p"..self.pointnow]:removeAllChildrenWithCleanup(true)
                        local Node,Items = CCBReaderLoad("shenlongxuyuan/shijian_suiji", nil, true, "shijian")
                        Node:setPosition(0,0)
                        local animationManager = getAnimationManager(Items)
                        animationManager:setAnimationCompletedCallback(function()
                            movecb()
                        end)
                        gameTouch:clickprofbytime(1.5)
                        animationManager:runAnimationsForSequenceNamed("play_shop")
                        self.mapItems["p"..self.pointnow]:addChild(Node)
                    end)))
                else
                    gameTouch:clickprofbytime(1)
                    movecb()
                end    
            elseif self.dicestatus.eventid == 5 then
                if self.mapconfig["point"..(self.pointnow)] == 1 then
                    runGamePrompt({msg = "途中偶遇，会碰到哪位仙子呢？"})
                    gameTouch:clickprofbytime(2.5)
                    self.mapItems["p"..self.pointnow]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.8),CCCallFunc:create(function()
                        self.mapItems["p"..self.pointnow]:removeAllChildrenWithCleanup(true)
                        local Node,Items = CCBReaderLoad("shenlongxuyuan/shijian_suiji", nil, true, "shijian")
                        Node:setPosition(0,0)
                        local animationManager = getAnimationManager(Items)
                        animationManager:setAnimationCompletedCallback(function()
                            movecb()
                        end)
                        gameTouch:clickprofbytime(1.5)
                        animationManager:runAnimationsForSequenceNamed("play_battle")
                        self.mapItems["p"..self.pointnow]:addChild(Node)
                    end)))
                else
                    gameTouch:clickprofbytime(1)
                    movecb()
                end    
            elseif self.dicestatus.eventid == 10 then
                gameTouch:clickprofbytime(1)
                runGamePrompt({msg = "如有天助，获得骰子！"})
                self.mapItems["p"..self.pointnow]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.8),CCCallFunc:create(function()
                    movecb()
                end)))
            else
                movecb()
            end
        else
            movecb()
        end

    end
end

function shenlongxuyuan.movePoint(self,point,lastpoint)

    local pointnow = point or self.pointnow

    --
    local isflipx = false
    for k,v in ipairs(self.mapSpecial[self.mapNumber].flipx1) do
        --表里的点等于现在的点
        if v == pointnow then
            isflipx = true
        end
    end
    for k,v in ipairs(self.mapSpecial[self.mapNumber].flipx2) do
        if self.mapNumber == 1 then
            --表里的点等于现在的点
            --存在上一个点
            --上一个点大于现在的点或者上一个点等于17或49
            if (v == pointnow) and lastpoint and ((lastpoint > pointnow) or (lastpoint == 17) or (lastpoint == 49)) then
                isflipx = true
            end
        elseif self.mapNumber == 2 then
            --表里的点等于现在的点
            --存在上一个点
            --上一个点大于现在的点或者上一个点
            if (v == pointnow) and lastpoint and (lastpoint > pointnow) then
                isflipx = true
            end
        end
    end
    for k,v in ipairs(self.mapSpecial[self.mapNumber].flipx3) do
        if self.mapNumber == 1 then
            --表里的点等于现在的点
            --存在上一个点
            --上一个点小于现在的点或者上一个点不等于17
            if (v == pointnow) and lastpoint and ((lastpoint < pointnow) and (lastpoint ~= 17)) then
                isflipx = true
            end
        elseif self.mapNumber == 2 then
            --表里的点等于现在的点
            --存在上一个点
            --上一个点小于现在的点或者上一个点
            if (v == pointnow) and lastpoint and (lastpoint < pointnow) then
                isflipx = true
            end
        end
    end

    if self.mapNumber == 1 then
        if (pointnow == 17) and (lastpoint == 104) then
            isflipx = true
        end
    end

    if lastpoint then
        self.mapItems["generalNode"]:setScaleX(isflipx and -1 or 1)
        self.mapItems["generalfangxiang"]:setScaleX(isflipx and -1 or 1)
        if self.animationManager_map then
            self.animationManager_map:runAnimationsForSequenceNamed("jump")
        end
    end

    local tmpTimes = 0.3
    if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
        tmpTimes = tmpTimes / 1
    end
   
    local moveto =  CCMoveTo:create(tmpTimes, ccp(self.mappoints[tostring(pointnow)].x,self.mappoints[tostring(pointnow)].y))
    self.mapItems["generalNode"]:runAction(moveto)
    --
    local gotoX = self.fixpx-self.mappoints[tostring(pointnow)].x
    local gotoY = self.fixpy-self.mappoints[tostring(pointnow)].y
    if gotoX > 0 then
        gotoX = 0
    elseif gotoX < self.fixpx*2-self.maxpx then
        gotoX = self.fixpx*2-self.maxpx
    end
    if gotoY > 0 then
        gotoY = 0
    elseif gotoY < self.fixpy*2-self.maxpy then
        gotoY = self.fixpy*2-self.maxpy
    end

    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(gotoX,gotoY),0.3)

    self.pointnow = pointnow

    --小地图   434 243   /    2305*2  1292*2
    local mapscaleX = 434/(2305*2)
    local mapscaleY = 243/(1292*2)
    local mini_x = self.mappoints[tostring(self.pointnow)].x*mapscaleX
    local mini_y = self.mappoints[tostring(self.pointnow)].y*mapscaleY
    self.rootItems["mini_pointnow"]:setPosition(mini_x,mini_y)

end

function shenlongxuyuan.clear(self)

    gameTimer:UnrigistTimeFunc("shenlongxuyuandice")

    self.longEffect = 0
    self.diceNum = 0
    self.roadPoint = nil

    self.olddata = nil

    self.pointnow = 1
    self.dice_cost = 0

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.mapNode then
        self.mapNode = nil
        self.mapItems = nil
        self.animationManager_map = nil
    end
    if self.shaiziCCB then
        self.shaiziCCB = nil
        self.shaiziItem = nil
        self.animationManager_shaizi = nil
    end
    if self.shijianFangxiangNode then
        self.shijianFangxiangNode = nil
        self.shijianFangxiangItems = nil
        self.shijianFangxiangAnimationManager =nil
    end

end

function shenlongxuyuan.UIUpdateData(self, isreset)
    if isreset then
        gameTouch:clickprofbytime(1)
        UIRequest({type = 4907})
    end
end

return shenlongxuyuan
   �  