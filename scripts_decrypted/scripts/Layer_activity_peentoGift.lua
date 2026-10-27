--
-- Created by IntelliJ IDEA.
-- User: lipurpose
-- Date: 18/5/28
-- Time: 20:00
-- To change this template use File | Settings | File Templates.
--

local peentoGift = {
    consumeId = 20621,
    buttontouch = -103,
    actionDelay = 2,
    yulanindex = 0,
    data = {},
}




function peentoGift.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("pantaoxianli/pantaoxianli",nil, true, "pantaoxianli")
    self.animationManager = getAnimationManager(self.coveritems)

    
    self:initFixedString()
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.centerNode:setPositionY(self.contentsize.y/2)
    self:setTimeShow()
    self:addNode()
    local function reSetFunc()
        
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if not self.data.peentoData then
            return
        end
        gameTouch:clickprofbytime(0.5)
        local limit = gamedata.config.global_kv.peentogiftawards_onekey_vip_limit and tonumber(gamedata.config.global_kv.peentogiftawards_onekey_vip_limit.value) or 0
        if GameScene.roleinfo.vip < limit then
            return runGamePrompt({msg = "贵族"..limit.."可使用一键扭蛋。"})
        end


        if self.data.num < 8 then
            return runGamePrompt({msg = "蟠桃币不足8个，无法使用一键扭蛋"})
        end

        local num = 0
        for k,v in pairs(self.data.peentoData.getPosition) do
            if v > 0 then
                num = num + 1
            end
        end
        if num > 0 then
            return runGamePrompt({msg = "奖励不足8个，无法使用一键扭蛋"})
        end

        gameWindows:openWindow("peentoSurePanel",{num = 8},function ()
            UIRequest{type = 5402,pos = 0,useId = self.consumeId,useNum = 8}
        end)
    end
    self.resetItems.btnReset:setTouchPriority(self.buttontouch)
    self.resetItems.btnReset:addHandleOfControlEvent(reSetFunc, CCControlEventTouchUpInside)

    self.coveritems.btnPreShow:setTouchPriority(self.buttontouch)
    self.coveritems.btnPreShow:addHandleOfControlEvent(function (  )
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("peentoGiftPreShow",{day = self.data.peentoData.currentDay or 1,peentoData = self.data.peentoData})
    end, CCControlEventTouchUpInside)

    self.coveritems.btnRule:setTouchPriority(self.buttontouch)
    self.coveritems.btnRule:addHandleOfControlEvent(function (  )
        if GameScene.layers["activity"].module.isContentScroll then  return end
        ui.popCommonRule(365)
        -- UIRequest({type = 5403})
    end, CCControlEventTouchUpInside)

    if self.coveritems.btnPantao then
        self.coveritems.btnPantao:setTouchPriority(self.buttontouch)
        self.coveritems.btnPantao:addHandleOfControlEvent(function (  )
            ui.setPopwindowByCid(self.consumeId)
        end, CCControlEventTouchUpInside)
    end
    

    self.coveritems.button_stop:setTouchPriority(self.buttontouch)
    self.coveritems.button_stop:addHandleOfControlEvent(function (  )
        
    end, CCControlEventTouchUpInside)
    self.coveritems.button_stop:setSwallowsTouch(true)

    self.coveritems.sureBtn:setTouchPriority(self.buttontouch - 1)
    self.coveritems.sureBtn:addHandleOfControlEvent(function (  )
        if GameScene.layers["activity"].module.isContentScroll then  return end
        --self.coveritems.surePanel:setScale(0.0)
        self.skeleton:setAnimation("stand",true,0)
        self.animationManager:runAnimationsForSequenceNamed("free")
    end, CCControlEventTouchUpInside)
    self.coveritems.sureBtn:setSwallowsTouch(true)

    self.coveritems["sureBtn_1"]:setTouchPriority(self.buttontouch - 1)
    self.coveritems["sureBtn_1"]:addHandleOfControlEvent(function (  )
        if GameScene.layers["activity"].module.isContentScroll then  return end
        --self.coveritems.surePanel:setScale(0.0)
        self.skeleton:setAnimation("stand",true,0)
        self.animationManager:runAnimationsForSequenceNamed("free")
    end, CCControlEventTouchUpInside)
    self.coveritems["sureBtn_1"]:setSwallowsTouch(true)

    --
    self.coveritems.itemscroll:setTouchEnabled(false)
    self:setPantao()

    --琨
    local configKun = gamedata.config.peentogiftawards
    local id,count = ui.getIDandNUM(configKun["1"]["reward"..8])
    ui.setNewIcon(self.coveritems,{cid = id},0)

    self.coveritems["i_button"]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(id)
    end, CCControlEventTouchUpInside)
    self.coveritems["i_button"]:setTouchPriority(self.buttontouch - 1)

    for i=1,9 do
        self.coveritems["i_button_"..i]:setSwallowsTouch(true)
        self.coveritems["i_button_"..i]:addHandleOfControlEvent(function()
            
        end, CCControlEventTouchUpInside)
        self.coveritems["i_button_"..i]:setTouchPriority(self.buttontouch - 10)
    end

    return self.coverccb
end

function peentoGift.addNode(self)
    local resetNode
    resetNode,self.resetItems = CCBReaderLoad("pantaoxianli/pantaoxianli_chongzhibt",nil, true, "pantaoxianli_chongzhibt")
    self.coveritems.resetAddNode:addChild(resetNode)
    resetNode:setPosition(ccp(352.0,-180))
    self.resetAnimationManager = getAnimationManager(self.resetItems)
    --
    self.lightNodes = {}
    self.lightAnimationManagers = {}
    for i = 1,8 do
        local lightItems
        self.lightNodes[i],lightItems = CCBReaderLoad("pantaoxianli/pantaoxianli_dapan_deng",nil, true, "pantaoxianli_dapan_deng")
        self.coveritems.lightNode:addChild(self.lightNodes[i])
        self.lightAnimationManagers[i] = getAnimationManager(lightItems)
        if i > 4 then
            self.lightNodes[i]:setPosition(ccp(-236 + (i - 4 - 1)*160,-196))
        else
            self.lightNodes[i]:setPosition(ccp(-236 + (i - 1)*160,44))
        end
    end
    --
    self.panTaoAnimationManagers = {}
    for i = 1,8 do
        local panTaoNode,panTaoItems
        panTaoNode,panTaoItems = CCBReaderLoad("pantaoxianli/pantaoxianli_dapan",nil, true, "pantaoxianli_dapan")
        self.panTaoAnimationManagers[i] = getAnimationManager(panTaoItems)
        if i > 4 then
            self.coveritems.pantaoPNode2:addChild(panTaoNode)
            panTaoNode:setPosition(ccp(-240 + (i - 4 - 1)*160,15))
        else
            panTaoNode:setPosition(ccp(-240 + (i - 1)*160,15))
            self.coveritems.pantaoPNode1:addChild(panTaoNode)
        end

        panTaoItems["button_slot"]:addHandleOfControlEvent(function ()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if self.data.peentoData and (not self.data.peentoData.getPosition[tostring(i)] or self.data.peentoData.getPosition[tostring(i)] < 1)  then
                if self.data.num < self.data.cost then
                    local config = ui.IDconfig(self.consumeId)
                    local idname = config.name
                    return runGamePrompt({msg = gameConfig.strings:nameBuzu(idname)})
                end
                gameWindows:openWindow("peentoSurePanel",{num = self.data.cost or 1},function ()
                    gameTouch:clickprofbytime(0.5)
                    --print("lipurposes",i,self.consumeId,self.data.cost)
                    UIRequest{type = 5402,pos = i,useId = self.consumeId,useNum = self.data.cost}
                end)
            end
           
        end, CCControlEventTouchUpInside)
        panTaoItems["button_slot"]:setTouchPriority(self.buttontouch)
    end
end

function peentoGift.setPantao( self )
    local name = "pantaojing"
    local skeleton = CCSkeletonAnimation:create(name.."/"..name..".json",name.."/"..name..".atlas",1)
    skeleton:setAnimation("stand",true,0)
    self.skeleton = skeleton
    self.coveritems["pantaoGeneral"]:addChild(skeleton)
end

function peentoGift.playResetAnimation(self)
    gameTouch:clickprofbytime(2)
    self.resetAnimationManager:runAnimationsForSequenceNamed("play")
    self.resetAnimationManager:setAnimationCompletedCallback(function()
        for i = 1,8 do
            self.lightAnimationManagers[i]:runAnimationsForSequenceNamed("chongzhi")
            self.panTaoAnimationManagers[i]:runAnimationsForSequenceNamed("chongzhi")
        end
    end)
    
end

function peentoGift.reSet(self,data)
    self.data.peentoData = data.data
    self:playResetAnimation()
    self:setConsumeNum()
    self:setRewardPreShow()
end

function peentoGift.setTimeShow(self)
    -- 活动时间
    local cpnum = 0
    local cpday = 0
    local timediff = 0
    if self.coveritems.timeNode then
        self.coveritems.timeNode:setVisible(true)
    end
    if self.coveritems.time and gamedata.config.activity_time["103"]["open_type"] and gamedata.config.activity_time["103"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(gamedata.config.activity_time["103"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["103"]["open_type"] and gamedata.config.activity_time["103"]["open_type"] == 2 then
        --self.coveritems.time:setString("")
        --self.coveritems.desc1:setString("")
        if self.coveritems.timeNode then
            self.coveritems.timeNode:setVisible(false)
        end
    elseif self.coveritems.time and gamedata.config.activity_time["103"]["open_type"] and gamedata.config.activity_time["103"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["103"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec

    elseif self.coveritems.time and gamedata.config.activity_time["103"]["end"] and gamedata.config.activity_time["103"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["103"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        if self.coveritems.timeNode then
            self.coveritems.timeNode:setVisible(false)
        end
    end

    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("ActivityPeentoGift",timediff)

        if gameTimer.times["ActivityPeentoGift"] and gameTimer.times["ActivityPeentoGift"] > 0 then
            gameTimer:rigistTimeFunc("ActivityPeentoGift", function()
                if gameTimer.times["ActivityPeentoGift"] <= 0 then
                    if gameTimer.times["ActivityPeentoGift"] then
                        gameTimer:UnrigistTimeFunc("ActivityPeentoGift")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["ActivityPeentoGift"],"day"))
                    ui.setLabelString(self.coveritems.time,nil,23)
                end
            end)
        end
    end

    ui.setLabelString(self.coveritems.time,nil,23)
    ui.setLabelString(self.coveritems.desc1,gameConfig.strings:string_common("fixedString","activity_fashion",18),14)
end

function peentoGift.initFixedString(self)
    --ui.setLabelString(self.coveritems.fixed1,gameConfig.strings:string_common("layer_copy",3),18)
    self.coveritems.fixed2:setString(gameConfig.strings:string_common("lead",10))
end


function peentoGift.reloadData(self,t)
    if not self.show then return end
    if gameWindows.windows["peentoGiftPreShow"].show then
        gameWindows:closeWindow("peentoGiftPreShow")
    end
    --self.coveritems.surePanel:setScale(0.0)
    self.skeleton:setAnimation("stand",true,0)

    self.animationManager:runAnimationsForSequenceNamed("free")

    self.data.peentoData = t.data
    local haveN = 0
    for k,v in pairs(t.data.getPosition) do
        if v > 0 then
            haveN = haveN + 1
        end
    end
    local cuT = t.data.cpTime
    --
    printT(gamedata.config.peentogiftawards,"lipurposes")
    
    for i = 1,8 do
        local pos = t.data.getPosition[tostring(i)]
        if pos and pos > 0 then
            self.panTaoAnimationManagers[i]:runAnimationsForSequenceNamed("kong")
            self.lightAnimationManagers[i]:runAnimationsForSequenceNamed("fangun")
        else
            self.panTaoAnimationManagers[i]:runAnimationsForSequenceNamed("free")
            self.lightAnimationManagers[i]:runAnimationsForSequenceNamed("free")
        end
    end
    --
   self:setConsumeNum()
   self:setRewardPreShow()
   self:setPropNum()
end

function peentoGift.setOneyulan(self,currentP,ccb,item,pos)
    self.yulanindex = self.yulanindex +1
    if self.yulanindex> 8 then
        self.yulanindex = 1
    end

    local tableP = {}
    if self.data.peentoData then
        for k,v in pairs(self.data.peentoData.getPosition) do
            if v > 0 then
                tableP[v] = 1
            end
        end
    end
    local config = gamedata.config.peentogiftawards[tostring(self.data.peentoData.currentDay)]
    local id,count
    id,count = ui.getIDandNUM(config["reward"..tostring(self.yulanindex)])
    --
    if id == 1000 then
        if tableP[self.yulanindex]  and tableP[self.yulanindex] > 0 then
            count = self.data.peentoData.silverNum
        else
            local silverConfig = gamedata.config.peentogift_silver
            local cuP
            local maxSilver = 0
            for k,v in pairs(silverConfig) do
                local level = tonumber(k)
                if GameScene.roleinfo.level <= level then
                    if not cuP then
                        cuP = k
                    else
                        if tonumber(cuP) > level then
                            cuP = k
                        end
                    end
                end
                if v.silver > maxSilver then
                    maxSilver = v.silver
                end
            end
            count = cuP and silverConfig[cuP].silver or maxSilver
        end
    end
    --
    ui.setNewIcon(item,{cid = id,num = count},0)
    item["isGet"]:setVisible((tableP[self.yulanindex] and tableP[self.yulanindex] > 0))
    self.rewardItems[currentP].id = self.yulanindex
    ccb:setPosition(pos)
end

function peentoGift.repeataction(self,ccb,item)
    self:setOneyulan(ccb,item,ccp(730,65))
    local first = CCMoveTo:create(8, ccp(-70, 65))
    ccb:runAction(CCSequence:createWithTwoActions(first, CCCallFunc:create(function()
        self:repeataction(ccb,item)
    end)))
end

function peentoGift.setRewardPreShow(self)
    self.coveritems.container:removeAllChildrenWithCleanup(true)
    self.rewardItems = {}
    self.yulanindex = 0
    -- if self.timer then
    --     CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
    --     self.timer = nil
    -- end
    -- for i = 1,5 do
    --     local itemccb,ccbitem = CCBReaderLoad("pantaoxianli/jianglizhanshiicon", nil, true, "jianglizhanshiicon")
    --     self.coveritems.container:addChild(itemccb)
    --     --itemccb:setPosition(ccp(730 + (i - 1)* 160,65))
    --     itemccb:setVisible(false)
    --     self.rewardItems[i] = {}
    --     self.rewardItems[i].ccb = itemccb
    --     self.rewardItems[i].item = ccbitem
    --     self:setOneyulan(i,itemccb,ccbitem,ccp(730 + (i - 1)* 160,65))

    --     --local beginTime = gamedata:time()
    -- end
    -- self.timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
    --     local det = 0.05
    --     local dis = 0.05 * 160
    --     for i = 1,5 do
    --         if not (self and self.rewardItems) then
    --             return
    --         end
    --         self.rewardItems[i].ccb:setPositionX(self.rewardItems[i].ccb:getPositionX() - dis)
    --         local currentPX = self.rewardItems[i].ccb:getPositionX()
    --         if currentPX < 730 and currentPX > -70 then
    --             self.rewardItems[i].ccb:setVisible(true)
    --         else
    --             self.rewardItems[i].ccb:setVisible(false)
    --         end
    --         if currentPX < -70 then
    --             local diff = -70 - currentPX 
    --             self:setOneyulan(i,self.rewardItems[i].ccb,self.rewardItems[i].item,ccp(730 - diff,65))
    --             self.rewardItems[i].ccb:setVisible(true)
    --         end
    --     end
    -- end, 1.0/30, false)
    
    local ccb,ccbItem = CCBReaderLoad("pantaoxianli/pantaoxianli_jianglizhanshi",nil,true,"jianglizhanshi")
    self.rewardItems = {}
    self.coveritems.container:addChild(ccb)
    ccb:setPosition(ccp(330,65))
    local config = gamedata.config.peentogiftawards[tostring(self.data.peentoData.currentDay)]
    local tableP = {}
    if self.data.peentoData then
        for k,v in pairs(self.data.peentoData.getPosition) do
            if v > 0 then
                tableP[v] = 1
            end
        end
    end
    for i = 1,8 do
        local k_add = i > 1 and "_"..(i - 1) or ""
        local id,count
        id,count = ui.getIDandNUM(config["reward"..tostring(i)])
        --
        if id == 1000 then
            if tableP[i]  and tableP[i] > 0 then
                count = self.data.peentoData.silverNum
            else
                local silverConfig = gamedata.config.peentogift_silver
                local cuP
                local maxSilver = 0
                for k,v in pairs(silverConfig) do
                    local level = tonumber(k)
                    if GameScene.roleinfo.level <= level then
                        if not cuP then
                            cuP = k
                        else
                            if tonumber(cuP) > level then
                                cuP = k
                            end
                        end
                    end
                    if v.silver > maxSilver then
                        maxSilver = v.silver
                    end
                end
                count = cuP and silverConfig[cuP].silver or maxSilver
            end
        end
        ui.setNewIcon(ccbItem,{cid = id,num = count},i - 1)
        self.rewardItems[i] = ccbItem["isGet"..k_add]
        self.rewardItems[i]:setVisible((tableP[i] and tableP[i] > 0))
    end
    
end

function peentoGift.setConsumeNum(self)
    local config = gamedata.config.buycount_price
    local key = "peentogift_consume"
    local cost = config[tostring(self.data.peentoData.cpTime)] and config[tostring(self.data.peentoData.cpTime)][key] or config[tostring(table.getTableLength(config))][key]
    local labelnum = 3
    if self.data.num then
        local labelnum = self.data.num >= cost and 3 or 29
    end
    self.data.cost = cost
    -- self.coveritems["useNum"]:setString("X"..cost)
    self.coveritems["useNum"]:setString("X8")
end


function peentoGift.getReward(self,t)
    gameTouch:clickprofbytime(4)
    self.animationManager:runAnimationsForSequenceNamed("huode")
    self.skeleton:setAnimation("celebrate",true,0)
    
    
    if t.propNum then
        self:setPropNum({[tostring(self.consumeId)] = t.propNum})
    end
    local isGetAllReward = false
    for k,v in pairs(t.data.getPosition) do
        if v > 0 and (not self.data.peentoData.getPosition[k] or self.data.peentoData.getPosition[k] < 1) then
            self.rewardItems[v]:setVisible(true)
            self.lightAnimationManagers[tonumber(k)]:runAnimationsForSequenceNamed("fangun")
            self.panTaoAnimationManagers[tonumber(k)]:runAnimationsForSequenceNamed("fangun")
        end
        if v == 0 then
            isGetAllReward = true
        end
    end

    local rewardNum = table.getTableLength(t.reward)
    self.coveritems.surePanel:setVisible(rewardNum > 1)
    self.coveritems.surePanel2:setVisible(rewardNum == 1)

    if rewardNum > 1 then
        for i=1,rewardNum do
            ui.setNewIcon(self.coveritems,t.reward[tostring(i)],1 + i)
        end
    elseif rewardNum == 1 then
        ui.setNewIcon(self.coveritems,t.reward["1"],1)
    end
    
    self.data.peentoData = t.data

    if isGetAllReward == false then
        UIRequest({type = 5403})
    end
end

function peentoGift.setPropNum(self,data)
    if not data then
        UIRequest({type = 12001, order = 33010, cids = {self.consumeId}})
        return
    end
    local num = data[tostring(self.consumeId)] or 0
    self.data.num = num
    ui.setLabelString(self.coveritems.propNum,"X"..num,19)
    --self.coveritems.propNum:setString("X"..num)
end

function peentoGift.clear(self)
    if gameTimer.times["ActivityPeentoGift"] then
        gameTimer:UnrigistTimeFunc("ActivityPeentoGift")
    end
    -- if self.timer then
    --     CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
    --     self.timer = nil
    -- end
    self.show = false
    self.tasklistview = nil
    self.tree = nil
    self.main = nil
    self.coverccb = nil
    self.coveritems = nil
    self.data = {}
    self.yulanindex= 0
end


return peentoGift  6U  