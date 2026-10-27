--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/1/19
-- Time: 15:13
-- To change this template use File | Settings | File Templates.
--

local island = {
    buttontouch = -103,
    rootNode = nil,
    rootItems = nil,
    shaiziCCB = nil,
    shaiziItem = nil,
    toppos = 0,
    point_now = 1,
    animationManager = nil,
    animationManager_shaizi = nil,
    map = {},
    data = {},
    olddata = nil,
    buttonenable = true,
    dicepropcid = 20262,
    dicepropnum = 1,
    dicehasnum = 0,
    isVipAuto = false;
    m_bIsAutoGame = nil, -- 自动游戏

    -- 是否正在发送
    m_isMessage = false,
    resolvequality = 2,--翻牌类型 2为手动翻牌3为免费翻牌4为一键翻牌
}
local QRIL_MAP_MOVE_TIME = 0.33 -- 地图移动速率
local QRIL_AUTO_NONE = -1
local QRIL_AUTO_TRUE = 0
local QRIL_AUTO_PAUSE= 1

function island.clear(self)
    self.dicepropcid = 20262
    self.dicepropnum = 1
    self.dicehasnum = 0
    self.buttonenable = true
    self.olddata = nil
    self.data = {}
    self.map = {}
    self.point_now = 1
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.shaiziCCB = nil
    self.shaiziItem = nil
    self.animationManager = nil
    self.animationManager_shaizi = nil
end

function island.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("island3/island3", nil, true, "island")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.buttontouch)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)
    
    --
    self.animationManager = getAnimationManager(self.rootItems)
    --self.animationManager:runAnimationsForSequenceNamed("jump")
    --
    self.rootItems["general"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.protagonist.general.cid)].animationid)].name
    local wing = {level = GameScene.protagonist.w_l,color = GameScene.protagonist.w_c}
    --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1)
    Gneral1:setPosition(0,0)
    self.rootItems["general"]:addChild(Gneral1.root or Gneral1)
    --
    self.rootItems["generalNode"]:setPosition(self.rootItems["p_"..self.point_now]:getPositionX(),self.rootItems["p_"..self.point_now]:getPositionY()+self.rootItems["mapnode"]:getPositionY())
    --
    local dicepropcid,dicepropnum = ui.getIDandNUM(gamedata.config.global_kv.penglai3_diceid.value)
    self.dicepropcid = dicepropcid or 20262
    self.dicepropnum = dicepropnum or 1
    --
    ui.setNewIcon(self.rootItems,{cid = self.dicepropcid})
    if gamedata.config.penglai3_type["16"] then
        local rewarddata = ui.penglaiCidNum(gamedata.config.penglai3_type["16"].param,gamedata.config.build["22"].level)
        setSpriteFrameByName(self.rootItems["rewardIcon"], gamedata.config.props[tostring(rewarddata.cid)].icon or "alpha" )
    end
    --
    self.rootItems.rolleffectNode:removeAllChildrenWithCleanup(true)
    self.shaiziCCB, self.shaiziItem = CCBReaderLoad("UIEffect/shaizi/shaizi.ccbi", nil, true, "shaizi")
    self.shaiziCCB:setAnchorPoint(ccp(0.0,0.0))
    self.shaiziCCB:setPosition(ccp(0,0))
    self.rootItems.rolleffectNode:addChild(self.shaiziCCB)
    --
    self.animationManager_shaizi = getAnimationManager(self.shaiziItem)
    --
    self.rootItems.rollBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        self.isVipAuto = false;
        if self.quickstatus == true then
            self.quickstatus = false;
            self:resetquicknode("close");
        end
        if self.buttonenable then
            UIRequest({type = 2121})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.rollBtn:setSwallowsTouch(true)
    self.rootItems.rollBtn:setTouchPriority(self.buttontouch)
    --

    if not gameConfig:checkBuildOpen(154) then
        self.rootItems.autoButton:setVisible(false)
        self.rootItems.exwRevers:setVisible(false)
    end
    self.tmpNVip = 100
    for k,v in pairs(gamedata.config.vip) do
        print("你大爷====:",k,gamedata.config.vip[tostring(k)].penglai3_onekey)
        if gamedata.config.vip[tostring(k)].penglai3_onekey > 0 then
            if tonumber(k) < self.tmpNVip then
                self.tmpNVip = tonumber(k)
            end
        end
    end
    self.tmpNLevel = tonumber(gamedata.config.global_kv.penglai_onekey_openlv.value)
    local tmpTips = string.format(gameConfig.strings:string_common("fairycave",10),self.tmpNVip)
    ui.setLabelString(self.rootItems.exwRevers,tmpTips,13)
    self.m_bIsAutoGame = QRIL_AUTO_NONE
    self.rootItems.autoButton:addHandleOfControlEvent(function()

        if self.buttonenable then
            gameTouch:clickprofbytime(1)
            if self.quickstatus == true then
                self.quickstatus = false;
                self:resetquicknode("close");
            end
            self:autoMove(true,false);
        end
        
        -- if self.buttonenable then
        --     if GameScene.vip.vip >= tmpNVip or GameScene.roleinfo.level >= tmpNLevel then
        --         self.m_bIsAutoGame = QRIL_AUTO_TRUE
        --         UIRequest({type = 2121})
        --     else
        --         runGamePrompt({msg = string.format(gameConfig.strings:string_common("island",14),tmpNVip,tmpNLevel)})
        --     end
        -- end
    end, CCControlEventTouchUpInside)
    self.rootItems.autoButton:setSwallowsTouch(true)
    self.rootItems.autoButton:setTouchPriority(self.buttontouch)

    self.rootItems.diceButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.buttonenable then
            if self.dicehasnum+0 < self.dicepropnum+0 then
                --runGamePrompt({msg = "道具不足"})
                gameWindows:openWindow("dropTips",{cid = self.dicepropcid},nil)
                return
            end

            local cb = function(value)
                if value and value > 0 then
                    self.isVipAuto =false;

                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 2121,dice = value})
                end
            end
            gameWindows:openWindow("isLand",{page = "xuanze",},cb)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.diceButton:setSwallowsTouch(true)
    self.rootItems.diceButton:setTouchPriority(self.buttontouch)
    --
    self.buttonenable = false
    --
    self.rootItems.rewardButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.buttonenable then
            if self.data.penglai.reward and self.data.penglai.reward == 2 then

            elseif self.data.penglai.reward and self.data.penglai.reward == 1 then
                UIRequest({type = 2122})
            end
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.rewardButton:setSwallowsTouch(true)
    self.rootItems.rewardButton:setTouchPriority(self.buttontouch)
    --
    self.rootItems.resetButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.buttonenable then
            if self.data.penglai.count >= gamedata.config.vip[tostring(GameScene.vip.vip)].penglai3_times and  GameScene.vip.vip == 12 then
                runGamePrompt({msg = "重置次数已用完"})
            elseif  self.data.penglai.count >= gamedata.config.vip[tostring(GameScene.vip.vip)].penglai3_times and  GameScene.vip.vip < 12 then
                if not gameConfig:checkBuildOpen(154) then
                    runGamePrompt({msg = "重置次数已用完"})
                else
                    runGamePrompt({msg = "提高VIP可以增加重置次数"})
                end
            elseif self.data.penglai.reward and self.data.penglai.reward == 1 then
                --runGamePrompt({msg = "领取奖励后可重置"})
                local cb = function()
                    gameWindows:openWindow("island2Confirm",{count = self.data.penglai.count},function (  )
                        UIRequest({type = 2122})
                        UIRequest({type = 2123})
                    end)
                end
                gameWindows:openWindow("confirm",{msg = "星星奖励未领取，确定要领取并重置吗？"},cb)
            else
                gameWindows:openWindow("island2Confirm",{count = self.data.penglai.count},function (  )
                    UIRequest({type = 2123})
                end)
            end
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.resetButton:setSwallowsTouch(true)
    self.rootItems.resetButton:setTouchPriority(self.buttontouch)
    ui.setLabelString(self.rootItems.resetLab,nil,19)
    --
    ui.setLabelString(self.rootItems.rewardLab,nil,14)
    ui.setLabelString(self.rootItems.rewardGetLab,nil,14)
    ui.setLabelString(self.rootItems.rewardokLab,nil,14)
    --
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("penglaiRule",nil,nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:setTouchPriority(self.buttontouch)
    --
    self.isreset = false
    --
    UIRequest({type = 2120})

    self:doubleRewardSet()

    self.quickNode,self.quickItems = CCBReaderLoad("island3/island_fast", nil, true, "island_fast")
    self.rootItems.quicknode:addChild(self.quickNode) 
    self.quickani = getAnimationManager(self.quickItems)

    self.quickItems["q_node"..self.resolvequality]:setZOrder(1)

    for i=2,4 do
        self.quickItems["q_button"..i]:setSwallowsTouch(true)
        self.quickItems["q_button"..i]:setTouchPriority(self.resolvequality == i and -107 or -106)
        self.quickItems["q_button"..i]:addHandleOfControlEvent(function()
            print("q_button ----",i)
            print("  self.quickstatus   ",self.quickstatus)
            print(self.resolvequality);

            if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                runGamePrompt({msg = "当前无法操作"})
                return
            end

            if self.quickstatus == true then
                if i == 4 then
                    if self.resolvequality == i then
                        self.resolvequality = i
                        self.quickstatus = not self.quickstatus
                        self:resetquicknode(self.quickstatus and "open" or "close")
                    else
                        function offlineBattleRequest()
                            print(" 回调 =======  ")
                            -- 先关闭自动战斗，在进行离线战斗
                            self.resolvequality = i;
                            self.quickstatus = not self.quickstatus
                            self:resetquicknode(self.quickstatus and "open" or "close")
                        end
                        local str = {
                                {fontID = 48,content = "使用一键翻牌后，每次遇到“",},
                                {fontID = 11,content =  "?",},
                                {fontID = 48,content = "”会自动扣除",},
                                {fontID = 11,content =  "25元宝",},
                                {fontID = 48,content = "，并且获得全部奖励"},
                            }
                        gameWindows:openWindow("confirm",{rich = str}, offlineBattleRequest)
                    end
                else
                    self.resolvequality = i;
                    self.quickstatus = not self.quickstatus
                    self:resetquicknode(self.quickstatus and "open" or "close")
                end
            else
                self.quickstatus = not self.quickstatus
                self:resetquicknode(self.quickstatus and "open" or "close")
            end
        end, CCControlEventTouchUpInside)
    end

end

function island.autoMove(self,isAuto,isOver)
    if isOver == true then
       local freetimes = tonumber(gamedata.config.global_kv.penglai3_freetimes.value) or 0
        if self.data.penglai.dice < freetimes then
            self.isVipAuto = isAuto;
            if self.isVipAuto == true and self.buttonenable then
                if GameScene.vip.vip >= self.tmpNVip or GameScene.roleinfo.level >= self.tmpNLevel then
                    self.m_bIsAutoGame = QRIL_AUTO_TRUE
                    UIRequest({type = 2121})
                else
                    runGamePrompt({msg = string.format(gameConfig.strings:string_common("island",14),self.tmpNVip,self.tmpNLevel)})
                end
            end
        end
    else
        self.isVipAuto = isAuto;
        if self.isVipAuto == true and self.buttonenable then
            if GameScene.vip.vip >= self.tmpNVip or GameScene.roleinfo.level >= self.tmpNLevel then
                self.m_bIsAutoGame = QRIL_AUTO_TRUE
                -- resolvequality = 2,--翻牌类型 2为手动翻牌3为免费翻牌4为一键翻牌


                local freetimes = tonumber(gamedata.config.global_kv.penglai3_freetimes.value) or 0
                local isHaveFree = freetimes > self.data.penglai.dice
                print("isHaveFree",isHaveFree)
                if self.resolvequality == 4 and isHaveFree then
                    UIRequest({type = 2128 ,curType = 1})
                elseif self.resolvequality == 3 and isHaveFree then
                    UIRequest({type = 2128 ,curType = 0})
                else
                    UIRequest({type = 2121})
                end

            else
                runGamePrompt({msg = string.format(gameConfig.strings:string_common("island",14),self.tmpNVip,self.tmpNLevel)})
            end
        end
    end
 
    
end

function island.resetquicknode( self,status)
    -- print("  status 111111  ",status," self.resolvequality ",self.resolvequality);
    if status == "open" then
        local index = 1
        for i=2,4 do
            self.quickItems["q_node"..i]:stopAllActions()
            if i==self.resolvequality then
                self.quickItems["q_node"..i]:setZOrder(1)
                -- self.quickItems["q_node"..i]:setPosition(60,0)
                self.quickItems["q_node"..i]:setPosition(0,0)
            else
                -- local moveto = CCMoveTo:create(0.5,ccp(60,index*68))
                local moveto = CCMoveTo:create(0.5,ccp(0,index*68))
                local backout = CCEaseBackOut:create(moveto)
                self.quickItems["q_node"..i]:setZOrder(0)
                self.quickItems["q_node"..i]:runAction(backout)
                index = index +1
            end
        end
        self.quickstatus = true
    else
        for i=2,4 do
            self.quickItems["q_node"..i]:stopAllActions()
            if i==self.resolvequality then
                self.quickItems["q_node"..i]:setZOrder(1)
                self.quickItems["q_button"..i]:setTouchPriority(-107)
            else
                self.quickItems["q_node"..i]:setZOrder(0)
                self.quickItems["q_button"..i]:setTouchPriority(-106)
            end
            -- local moveto = CCMoveTo:create(0.3,ccp(60,0))
            local moveto = CCMoveTo:create(0.3,ccp(0,0))
            local backout = CCEaseBackIn:create(moveto)
            self.quickItems["q_node"..i]:runAction(backout)
        end
        self.quickstatus = false
    end

end


-- 双倍活动2016年7月活动
function island.doubleRewardSet(self)
    -- if not self.data.isrewarddouble or self.data.isrewarddouble == false then return end
    if not self.rootItems.isrewarddouble then return end

    local datatmp = ui.CheckHuodongByParam(5)
    -- local datatmp = ui.CheckHuodongByParam(1)

    if datatmp then
        self.rootItems.isrewarddouble:setVisible(true)
        ui.setLabelString(self.rootItems.isrewarddouble,gameConfig.strings:string_common("doublereward",1),24)
    else
        self.rootItems.isrewarddouble:setVisible(false)
    end

end

function island.reload(self,data)
    --printT(data)

    self.data = data or self.data

    local mapconfig = gamedata.config.penglai3_map or {}

    --
    self.map = {}
    for i = 1,32 do
        if mapconfig[tostring(i)] and mapconfig[tostring(i)]["map"..self.data.penglai.map] then
           table.insert(self.map,mapconfig[tostring(i)]["map"..self.data.penglai.map])
        end
    end
    --
    for i = 1,4 do
       if i <= self.data.penglai.battle then
           setSpriteFrameByName(self.rootItems["xing"..i],"obj_xing")
       else
           setSpriteFrameByName(self.rootItems["xing"..i],"xingbg")
       end
    end
    --
    if gamedata.config.penglai3_type["16"] then
        local rewarddata = ui.penglaiCidNum(gamedata.config.penglai3_type["16"].param,gamedata.config.build["22"].level)
        setSpriteFrameByName(self.rootItems["rewardIcon"], gamedata.config.props[tostring(rewarddata.cid)].icon or "alpha" )
        self.rootItems.rewardLab:setVisible(true)
        self.rootItems.rewardGet:setVisible(false)
        self.rootItems.rewardok:setVisible(false)
        if self.data.penglai.reward and self.data.penglai.reward == 2 then
            self.rootItems.rewardLab:setVisible(false)
            self.rootItems.rewardGet:setVisible(true)
            self.rootItems.rewardok:setVisible(false)
        elseif self.data.penglai.reward and self.data.penglai.reward == 1 then
            self.rootItems.rewardLab:setVisible(false)
            self.rootItems.rewardGet:setVisible(false)
            self.rootItems.rewardok:setVisible(true)
        end
    end
    --
    if self.data.penglai.count then
        ui.setLabelString(self.rootItems.reset_num,"可重置次数: "..(gamedata.config.vip[tostring(GameScene.vip.vip)].penglai3_times-self.data.penglai.count).."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].penglai3_times,(self.data.penglai.count >= gamedata.config.vip[tostring(GameScene.vip.vip)].penglai3_times) and 24 or 13)
        local reset_gold = 0
        if gamedata.config.buycount_price and gamedata.config.buycount_price[tostring(self.data.penglai.count+1)] then
            reset_gold = gamedata.config.buycount_price[tostring(self.data.penglai.count+1)].penglai3reset or 0
        end
        if reset_gold+0 > 0 then
            ui.setLabelString(self.rootItems.reset_goldnum,reset_gold,14)
            self.rootItems.reset_goldnum:setPositionX(-11.8)
            self.rootItems.reset_gold:setVisible(true)
        else
            ui.setLabelString(self.rootItems.reset_goldnum,"免费",14)
            self.rootItems.reset_goldnum:setPositionX(28.2)
            self.rootItems.reset_gold:setVisible(false)
        end
        if self.data.penglai.count >= gamedata.config.vip[tostring(GameScene.vip.vip)].penglai3_times then
            ui.addGray("CCControlButton", self.rootItems.resetButton)
            self.rootItems.reset_gold:setVisible(false)
            ui.setLabelString(self.rootItems.reset_goldnum,"",14)
        else
            ui.removeGray("CCControlButton", self.rootItems.resetButton)
        end
    end
    --
    local freetimes = tonumber(gamedata.config.global_kv.penglai3_freetimes.value) or 0
    if self.data.penglai.dice < freetimes then
        self.rootItems.freeNode:setVisible(true)
        self.rootItems.spendNode:setVisible(false)
        self.rootItems.spendNode_Onekey:setVisible(false)
        ui.setLabelString(self.rootItems.freenumText,"免费 "..(freetimes-self.data.penglai.dice).." 次" ,14)
    else
        self.m_bIsAutoGame = QRIL_AUTO_NONE
        self.rootItems.freeNode:setVisible(false)
        self.rootItems.spendNode:setVisible(true)
        self.rootItems.spendNode_Onekey:setVisible(true)
        if gamedata.config.buycount_price and gamedata.config.buycount_price[tostring(self.data.penglai.dice+1-freetimes)] then
            ui.setLabelString(self.rootItems.spendText,"花费 "..gamedata.config.buycount_price[tostring(self.data.penglai.dice+1-freetimes)].penglai3cost ,14)
            ui.setLabelString(self.rootItems.spendText_Onekey,"花费 "..gamedata.config.buycount_price[tostring(self.data.penglai.dice+1-freetimes)].penglai3cost ,14)
        end
    end
    --
    UIRequest({type = 12001, order = 14001, cids = {self.dicepropcid}})
    --
    self:setpoint()
    --
    self:setlocation()
    --
    if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
        UIRequest({type = 2121})
    end
end

function island.setpoint(self)
    local typeconfig = gamedata.config.penglai3_type or {}

    for i = 1,32 do
        self.rootItems["p_p_"..i]:removeAllChildrenWithCleanup(true)

        if typeconfig[tostring(self.map[i])] and typeconfig[tostring(self.map[i])].icon and typeconfig[tostring(self.map[i])].icon ~= "" then
            setSpriteFrameByName(self.rootItems["p_t_"..i], typeconfig[tostring(self.map[i])].icon )
        end

        if self.data.penglai.status[tostring(i)] and self.data.penglai.status[tostring(i)] > 0 then
            if typeconfig[tostring(self.map[i])].type == "card" then
                local Node,Items = CCBReaderLoad("island3/icon_card", nil, true, "card")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
            end
        elseif typeconfig[tostring(self.map[i])] and typeconfig[tostring(self.map[i])].type and typeconfig[tostring(self.map[i])].type ~= "" then
            --
            if typeconfig[tostring(self.map[i])].type == "start" then
                local Node,Items = CCBReaderLoad("island3/icon_start", nil, true, "start")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
            elseif typeconfig[tostring(self.map[i])].type == "across" then
                local Node,Items = CCBReaderLoad("island3/icon_chuansongmen", nil, true, "across")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
            elseif typeconfig[tostring(self.map[i])].type == "card" then
                local Node,Items = CCBReaderLoad("island3/icon_card", nil, true, "card")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
            elseif typeconfig[tostring(self.map[i])].type == "monster" then
                local Node,Items = CCBReaderLoad("island3/icon_monster", nil, true, "monster")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
            elseif typeconfig[tostring(self.map[i])].type == "brave" then
                local Node,Items = CCBReaderLoad("island3/icon_brave", nil, true, "brave")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
            elseif typeconfig[tostring(self.map[i])].type == "boss" then
                local Node,Items = CCBReaderLoad("island3/icon_boss", nil, true, "boss")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
            elseif typeconfig[tostring(self.map[i])].type == "prop" then
                local Node,Items = CCBReaderLoad("island3/icon_box", nil, true, "prop")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
                --
                local props = {}
                local props1 = ui.getIDandNUMs(typeconfig[tostring(self.map[i])].param) or {}
                for k,v in pairs(props1) do
                    local itemdata = ui.penglaiCidNum(typeconfig[tostring(v.cid)].param,gamedata.config.build["22"].level)
                    if itemdata then
                       table.insert(props,itemdata)
                    end
                end
                Items.icon_button:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    -- 双倍掉率
                    local datatmp = ui.CheckHuodongByParam(5)
                    local timesnum = ui.GetHuodongModulus(5)
                    -- local datatmp = ui.CheckHuodongByParam(1)
                    -- local timesnum = ui.GetHuodongModulus(1)
                    if datatmp then
                        for k,v in pairs(props) do
                            v.num = v.num * tonumber(timesnum)
                        end
                    end
                    gameWindows:openWindow("getStaff", {data = props,type = "可能获得", isrewarddouble = datatmp},nil)
                end, CCControlEventTouchUpInside)
                Items.icon_button:setSwallowsTouch(true)
                Items.icon_button:setTouchPriority(self.buttontouch+1)

            elseif typeconfig[tostring(self.map[i])].type == "box" then
                local Node,Items = CCBReaderLoad("island3/icon_prop", nil, true, "box")
                Node:setPosition(0,0)
                self.rootItems["p_p_"..i]:addChild(Node)
                --
                local itemdata = ui.penglaiCidNum(typeconfig[tostring(self.map[i])].param,gamedata.config.build["22"].level)
                setSpriteFrameByName(Items["icon_prop"], gamedata.config.props[tostring(itemdata.cid)].icon or "alpha" )
                --
                Items.icon_button:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    ui.setPopwindowByCid(itemdata.cid)
                end, CCControlEventTouchUpInside)
                Items.icon_button:setSwallowsTouch(true)
                Items.icon_button:setTouchPriority(self.buttontouch+1)
            end
        end
    end
end

function island.gotonext(self,pos)
    self.buttonenable = false
    local pos = pos or 0

    if self.isreset then pos = 0 end

    if pos and pos > 0 then
        pos = pos-1
    else
        --self.buttonenable = true
        self:reload(self.data)
        return
    end

    self.point_now = self.point_now+1
    if self.point_now >= 33 then
        self.point_now = 1
    end
    local tmpTimes = QRIL_MAP_MOVE_TIME
    if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
        tmpTimes = tmpTimes / 2
    end

    if self.point_now <= 1 then
        local moveto1 =  CCMoveTo:create(tmpTimes, ccp(0, 0 + 330))
        self.rootItems["mapnode"]:runAction(moveto1)
        --
        local tmpX = self.rootItems["p_1"]:getPositionX()
        local tmpY = self.rootItems["p_1"]:getPositionY() + 330
        self.rootItems["generalNode"]:setPosition(tmpX,tmpY)
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
                self:gotonext(pos)
        end)))
    else
        local endY = self.rootItems["p_2"]:getPositionY()-self.rootItems["p_"..self.point_now]:getPositionY()-(self.point_now > 16 and self.rootItems["ppnode"]:getPositionY() or 0)
        if 6892+endY+160 + 330 < self.toppos-120 then
            endY = self.toppos-120-160-6892 - 330
        end
        local moveto1 =  CCMoveTo:create(tmpTimes, ccp(0, endY + 330))
        self.rootItems["mapnode"]:runAction(moveto1)
        --
        local tmpX = self.rootItems["p_"..self.point_now]:getPositionX()
        local tmpY = self.rootItems["p_"..self.point_now]:getPositionY()+endY+(self.point_now > 16 and self.rootItems["ppnode"]:getPositionY() or 0) + 330
        local moveto2 =  CCMoveTo:create(tmpTimes, ccp(tmpX,tmpY))
        self.rootItems["generalNode"]:runAction(moveto2)
        if self.animationManager then
            self.animationManager:setAnimationCompletedCallback(function()
                if self.point_now >= 32 then
                    self:gotonext(pos+1)
                else

                    local typeconfig = gamedata.config.penglai3_type or {}
                    local battlecb = function()
                        if self.last_result and self.last_result == 1 then
                            self.rootItems["p_p_"..self.point_now]:removeAllChildrenWithCleanup(true)
                            for i = 1,4 do
                                if i <= self.data.penglai.battle then
                                    setSpriteFrameByName(self.rootItems["xing"..i],"obj_xing")
                                else
                                    setSpriteFrameByName(self.rootItems["xing"..i],"xingbg")
                                end
                            end
                        end

                        self:gotonext(pos)

                    end
                    local function tmpDealBattle()
                        if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                            if self.last_result == 0 then
                                runGamePrompt({msg = gameConfig.strings:string_common("island",12)})
                            else
                                runGamePrompt({msg = gameConfig.strings:string_common("island",13)})
                            end
                            battlecb()
                        else
                            RunbattleCallBack("penglai", { battlereport = self.last_battlereport or {},result = self.last_result or 0}, battlecb)
                        end
                    end

                    if self.olddata.penglai.status[tostring(self.point_now)] and self.olddata.penglai.status[tostring(self.point_now)] == 0 then

                        if typeconfig[tostring(self.map[self.point_now])].type == "monster" then
                            tmpDealBattle()
                            -- RunbattleCallBack("penglai", { battlereport = self.last_battlereport or {},result = self.last_result or 0}, battlecb)
                        elseif typeconfig[tostring(self.map[self.point_now])].type == "brave" then
                            tmpDealBattle()
                            -- RunbattleCallBack("penglai", { battlereport = self.last_battlereport or {},result = self.last_result or 0}, battlecb)
                        elseif typeconfig[tostring(self.map[self.point_now])].type == "boss" then
                            tmpDealBattle()
                            -- RunbattleCallBack("penglai", { battlereport = self.last_battlereport or {},result = self.last_result or 0}, battlecb)
                        elseif pos and pos == 0 then
                            if typeconfig[tostring(self.map[self.point_now])].type == "prop" then
                                local function callback()
                                    self:gotonext(pos)
                                end
                                showRewardPopupWindow(self.last_reward,nil,callback)
                            elseif typeconfig[tostring(self.map[self.point_now])].type == "box" then
                                local function callback()
                                    self:gotonext(pos)
                                end
                                showRewardPopupWindow(self.last_reward,nil,callback)
                            else
                                self:gotonext(pos)
                            end
                        else
                            self:gotonext(pos)
                        end

                    else
                        self:gotonext(pos)
                    end
                end
            end)
            if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                self.animationManager:runAnimationsForSequenceNamed("fastjump")
            else
                self.animationManager:runAnimationsForSequenceNamed("jump")
            end
        end
    end
end


function island.setlocation(self)
    self.point_now = self.data.penglai.location or 1

    if self.point_now <= 1 then
        self.rootItems["mapnode"]:setPosition(0,0 + 330)
        self.rootItems["generalNode"]:setPosition(self.rootItems["p_1"]:getPositionX(),self.rootItems["p_1"]:getPositionY() + 330)
    else
        local endY = self.rootItems["p_2"]:getPositionY()-self.rootItems["p_"..self.point_now]:getPositionY()-(self.point_now > 16 and self.rootItems["ppnode"]:getPositionY() or 0)
        if 6892+endY+160 + 330 < self.toppos-120 then
            endY = self.toppos-120-160-6892 - 330
        end
        --self.rootItems["mapnode"]:setPosition(0, endY)
        local moveto1 =  CCMoveTo:create(QRIL_MAP_MOVE_TIME, ccp(0, endY + 330))
        self.rootItems["mapnode"]:runAction(moveto1)
        --
        self.rootItems["generalNode"]:setPosition(self.rootItems["p_"..self.point_now]:getPositionX(),self.rootItems["p_"..self.point_now]:getPositionY()+endY+(self.point_now > 16 and self.rootItems["ppnode"]:getPositionY() or 0) + 330)
    end

    --
    local typeconfig = gamedata.config.penglai3_type or {}
    if typeconfig[tostring(self.map[self.point_now])].type == "card" then
        if self.data.penglai.status[tostring(self.point_now)] and self.data.penglai.status[tostring(self.point_now)] >= 5 then
            self.buttonenable = true
        else
            self.buttonenable = false
            if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
                self.m_bIsAutoGame = QRIL_AUTO_PAUSE
            end
            UIRequest({type = 2124})
        end
    else
        self.buttonenable = true
    end
    --
    if self.animationManager_shaizi then
        self.animationManager_shaizi:runAnimationsForSequenceNamed("play")
    end
    --
end


function island.setDice(self,data)
    self.isreset = false
    self.olddata = table.copy(self.data)
    self.data.penglai = data.penglai or self.data.penglai

    UIRequest({type = 12001, order = 14001, cids = {self.dicepropcid}})

    local dice = 0
    if self.olddata.penglai.location > self.data.penglai.location then
        dice = 31+self.data.penglai.location-self.olddata.penglai.location
    else
        dice = self.data.penglai.location-self.olddata.penglai.location
    end

    if dice < 1 or dice > 6 then return end

    self.last_reward = data.reward or {}

    self.last_battlereport = data.battlereport or {}
    self.last_result = data.result or {}

    if self.m_bIsAutoGame == QRIL_AUTO_TRUE then
        self.animationManager_shaizi:runAnimationsForSequenceNamed("auto")
        local frameName = "shaizi"..dice
        setSpriteFrameByName(self.shaiziItem.rollFrame, frameName)
        self:gotonext(dice)
    else
        if self.animationManager_shaizi then
            self.animationManager_shaizi:setAnimationCompletedCallback(function()
                local frameName = "shaizi"..dice
                setSpriteFrameByName(self.shaiziItem.rollFrame, frameName)
                self:gotonext(dice)
            end)
            self.animationManager_shaizi:runAnimationsForSequenceNamed("rolleffect")
        end
    end

    --
end

function island.setCard(self,data)
    --printT(data)
    self.flopPrice = {
        tonumber(gamedata.config.global_kv.penglai3_card_freetimes.value),
        tonumber(gamedata.config.global_kv.penglai3_card_paytimes.value),
        tonumber(gamedata.config.global_kv.penglai3_card_paytimes2.value),
        tonumber(gamedata.config.global_kv.penglai3_card_paytimes3.value),
        tonumber(gamedata.config.global_kv.penglai3_card_akey.value),
    }
    if self.resolvequality == 3 then
        UIRequest({type = 2127,curType = 0,gold=0})
    elseif self.resolvequality == 4 then
        if GameScene.roleinfo.gold >= 25 then
            UIRequest({type = 2127,curType = 1,gold=25})
        else
            local function tmpCardClose()
                if self.m_bIsAutoGame == QRIL_AUTO_PAUSE then
                    self.m_bIsAutoGame = QRIL_AUTO_TRUE
                end
                self:autoMove(self.isVipAuto,true);
            end

            if gameWindows.windows["isLand"].show then
                gameWindows.windows["isLand"].module:reload({page = "fanpaizi",card = data.card},tmpCardClose)
            else
                gameWindows:openWindow("isLand",{page = "fanpaizi",card = data.card},tmpCardClose)
            end
        end
    else
        local function tmpCardClose()
            if self.m_bIsAutoGame == QRIL_AUTO_PAUSE then
                self.m_bIsAutoGame = QRIL_AUTO_TRUE
            end
            self:autoMove(self.isVipAuto,true);
        end

        if gameWindows.windows["isLand"].show then
            gameWindows.windows["isLand"].module:reload({page = "fanpaizi",card = data.card},tmpCardClose)
        else
            gameWindows:openWindow("isLand",{page = "fanpaizi",card = data.card},tmpCardClose)
        end

    end

end

function island.autoComplete(self,t)
    print("self.point_now",self.point_now)
    

    local showRewardTime = 0.5
    if t.penglai.location < self.point_now then

        local endY = self.rootItems["p_2"]:getPositionY()-self.rootItems["p_32"]:getPositionY()-self.rootItems["ppnode"]:getPositionY()
        if 6892+endY+160 + 330 < self.toppos-120 then
            endY = self.toppos-120-160-6892-330
        end
        local moveto1 =  CCMoveTo:create(0.3, ccp(0, endY + 330))
        self.rootItems["mapnode"]:runAction(moveto1)


        local tmpX = self.rootItems["p_32"]:getPositionX()
        local tmpY = self.rootItems["p_32"]:getPositionY()+endY+self.rootItems["ppnode"]:getPositionY() + 330
        local moveto2 =  CCMoveTo:create(0.3, ccp(tmpX,tmpY))
        self.rootItems["generalNode"]:runAction(moveto2)
        self.animationManager:runAnimationsForSequenceNamed("fastjump")

        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.4),CCCallFunc:create(function()
              
            local moveto1 =  CCMoveTo:create(0.5, ccp(0, 0 + 330))
            self.rootItems["mapnode"]:runAction(moveto1)
            --
            local tmpX = self.rootItems["p_1"]:getPositionX()
            local tmpY = self.rootItems["p_1"]:getPositionY() + 330
            self.rootItems["generalNode"]:setPosition(tmpX,tmpY)
        end)))

        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
            self:reload(t)
        end)))
        
        showRewardTime = 1.5

    else
        self:reload(t)
    end
    -- self:setDice(t)
    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(showRewardTime),CCCallFunc:create(function()
        if t.result == 0 then
            runGamePrompt({msg = "战斗失败"})
            if t.reward then
                showRewardPopupWindow(t.reward,nil)
            end
        else
            if t.reward then
                showRewardPopupWindow(t.reward,nil)
            end
        end
    end)))
end

function island.autoReload( self,t)
    local function callback()
        self:autoMove(self.isVipAuto,true);
    end
    showRewardPopupWindow(t.reward,nil,callback)
    UIRequest({type = 1001})
    UIRequest({type = 2126})
end



function island.setPropNum(self,data)
    self.dicehasnum = data[tostring(self.dicepropcid)] or 0
    ui.setNewIcon(self.rootItems,{cid = self.dicepropcid, num = self.dicehasnum.."/"..self.dicepropnum})
    ui.setLabelString(self.rootItems["i_num"],nil,self.dicehasnum+0>=self.dicepropnum+0 and 22 or 24)
end

function island.UIUpdateData(self, isreset)
    if isreset then
        self.isreset = true
        gameWindows:closeAllWindowDirect()
        UIRequest({type = 2120})
    end
end

return island  ��  