--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/11/3
-- Time: 下午2:17
-- To change this template use File | Settings | File Templates.
--

local buy = {
    rootNode = nil,
    rootItems = nil,

    buynum = 0,
    totalprice = 0,

    data = {},

}

function buy.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/tc_tiligoumai", nil, true, "tiligoumai")

    self.touchPriority = touchPriority

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,self.touchPriority,function (num)
        self.buynum = 0
        self:numchange(num)
    end)

    if not gameConfig:checkBuildOpen(154) then
        self.rootItems.vipsprite:setVisible(false)
        self.rootItems.VIP:setVisible(false)
    end


    self.proprety = {
        [1] = {key = "b_athletics",name="athletics",nameS="挑战\"3\"次",title = "购买"},
        [2] = {key = "b_physical",name="stamina",nameS="体力\""..gamedata.config.global_kv.basic_buy_stamina.value.."\"",title = "购买体力"},
        [3] = {key = "b_energy",name="energy",nameS="精力\""..gamedata.config.global_kv.basic_buy_energy.value.."\"",title = "购买精力"},
        [4] = {key = "friendcopy_times",name="friendcopycost",nameS="挑战\"1\"次",title = "购买"},
        [5] = {key = "bzxtrst",name="mieshendian",nameS="重置\"1\"次",title = "购买"},
        [6] = {key = "personalboss_times",name="personalboss_cost",nameS="挑战\"1\"次",title = "购买"},
        [7] = {key = "coin_copy_times",name="coin_copy_cost",nameS="挑战\"1\"次",title = "购买"},
        [8] = {key = "exp_copy_times",name="exp_copy_cost",nameS="挑战\"1\"次",title = "购买"},
        [9] = {key = "stone_copy_times",name="stone_cost",nameS="挑战\"1\"次",title = "购买"},
        [10] = {key = "through_times",name="through_cost",nameS="挑战\"1\"次",title = "购买"},
        [11] = {key = "upstar_times",name="upstar_copy_cost",nameS="挑战\"1\"次",title = "购买"},
        [12] = {key = "zhenfu_times",name="zhenfu_copy_cost",nameS="挑战\"1\"次",title = "购买"},
        [13] = {key = "home_challenge_times",name="home_monster_cost",nameS="协助\"1\"次",title = "购买"},
        [14] = {key = "sociaty_boss_order",name="sociaty_boss_frequency",nameS="挑战\"1\"次",title = "购买"},
        [15] = {key = "b_hall",name="hall_challenge_consume",nameS="挑战\"1\"次",title = "购买"},
        [16] = {key = "b_hero_boss",name="heroboss_challenge",nameS=" ",title = "购买"},
        [17] = {key = "forging_copy_times",name="forging_cost",nameS="挑战\"1\"次",title = "购买"},
    }

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("buypower")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)


    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)


    -- ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    -- ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    -- self.rootItems.doButton1:addHandleOfControlEvent(function()
    --     self.callback = nil
    --     gameWindows:closeWindow("buyProperty")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.doButton1:setSwallowsTouch(true)
    -- self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.buynum >0 then
            if self.totalprice > GameScene.roleinfo.gold then
                shortGold()
            else
                UIRequest({type = 301,cid = self.data.id, count = self.buynum, gold = self.totalprice})
                -- gameWindows:closeWindowDirect("buyProperty")
            end
        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    self:reload(data,callback)

    self:doubleRewardSet()

    return self.rootNode
end

-- 双倍活动2016年7月活动
function buy.doubleRewardSet(self)
    -- if not self.data.isrewarddouble or self.data.isrewarddouble == false then return end
    if not self.rootItems.isrewarddouble then return end

    -- 双倍活动判断
    local datatmp = ui.CheckHuodongByParam(3)
    local timesnum = ui.GetHuodongModulus(3)
    -- local datatmp = ui.CheckHuodongByParam(1)
    -- local timesnum = ui.GetHuodongModulus(1)
    if datatmp then
        self.rootItems.isrewarddouble:setVisible(true)
        local doublestring = "("..gameConfig.strings:cutOff( timesnum*10 )..")"
        ui.setLabelString(self.rootItems.isrewarddouble, doublestring, 24)
    else
        self.rootItems.isrewarddouble:setVisible(false)
    end
end

function buy.setbuydata(self)
    self.rootItems.buynum:setString(self.buynum)
    self.rootItems.totalprice:setString(self.totalprice)
    self.rootItems.totalprice:setColor(self.totalprice > GameScene.roleinfo.gold and ccc3(255,0,0) or ccc3(135,81,25))
end

function buy.numchange(self,num)
    self.buynum = self.buynum+num
    local restcount = self.totalcount - self.nowcount

    if self.buynum > restcount then
        runGamePrompt({msg = "达到今日购买次数上限"})
        self.buynum = restcount
    elseif self.buynum <0 then
        self.buynum = 0
    end

    -- 双倍活动判断
    local datatmp = ui.CheckHuodongByParam(3)
    local timesnum = ui.GetHuodongModulus(3)
    -- local datatmp = ui.CheckHuodongByParam(1)
    -- local timesnum = ui.GetHuodongModulus(1)

    self.totalprice = 0
    if self.buynum >0 then
        for i= self.nowcount+1, self.nowcount+self.buynum do
            local pricenum = gamedata.config.buycount_price[tostring(i)][self.proprety[self.data.id].name]
            -- 双倍活动判断
            if datatmp then
                pricenum = math.floor(pricenum * timesnum)
            end
            self.totalprice = self.totalprice + pricenum
        end
    end

    self:setbuydata()
end

function buy.setShowData(self)
    -- self.data = data
    -- printT(GameScene.vipstatus,"setShowData==")
    
    self.rootItems.titlename_Label:setString(self.proprety[self.data.id].title)

    self.nowcount = GameScene.vipstatus[self.proprety[self.data.id].key]
    self.totalcount = gamedata.config.vip[tostring(GameScene.vip.vip)][self.proprety[self.data.id].key]

    setSpriteFrameByName(self.rootItems.VIP,"b_n_vip_"..GameScene.vip.vip)
    ui.setLabelString(self.rootItems.name,self.proprety[self.data.id].nameS, 9)

    ui.setLabelString(self.rootItems.buytime, self.totalcount - self.nowcount, self.totalcount - self.nowcount>0 and 22 or 24)

    if gameConfig:checkBuildOpen(154) then
        self.rootItems.hasnum:setString("贵族"..GameScene.vip.vip.."每日可购买"..self.totalcount.."次")
    else
        self.rootItems.hasnum:setString("每日可购买"..self.totalcount.."次")
    end
end

function buy.reload(self,data,callback)
    self.data = data
    self.callback = callback
    self:setShowData()
    self:setbuydata()
    --self:setPropdata(self.data.props)
    UIRequest({type = 12001,order = 10002,cids = {20019,20014,20020,20015}})

end

function buy.setPropdataNum(self,data)
    local props = {}
    for k,v in pairs(data) do
        props[tostring(k)] = {cid = tonumber(k),num = tonumber(v)}
    end    
    self:setPropdata(props)
end    

function buy.setPropdata(self,data)
    -- printT(data,"setPropdata===")
    local oneCid = 20019
    local twoCid = 20014
    if tonumber(self.data.id) == 3 then
        oneCid = 20020
        twoCid = 20015

    end
    local onestring = "当前拥有："..(data[tostring(oneCid)] and data[tostring(oneCid)].num or 0).."个"
    self.rootItems.leftNumLabel:setString(onestring)
    ui.setNewIcon(self.rootItems,{cid=oneCid,num=(data[tostring(oneCid)] and data[tostring(oneCid)].num or 0)},0)


    local twostring = "当前拥有："..(data[tostring(twoCid)] and data[tostring(twoCid)].num or 0).."个"
    self.rootItems.rightNumLabel:setString(twostring)
    ui.setNewIcon(self.rootItems,{cid=twoCid,num=(data[tostring(twoCid)] and data[tostring(twoCid)].num or 0)},1)


    ui.setLabelString(self.rootItems.leftLab,nil,19)
    self.rootItems.leftButton:addHandleOfControlEvent(function()
        -- self:numchange(-10)
        -- print("左边体力丹使用")
        if data[tostring(oneCid)] and data[tostring(oneCid)].num > 0 then
            -- usePropByid(oneCid,data[tostring(oneCid)].num,"体力不足")
            gameWindows:openWindow("propusebynum",{id = oneCid})
        else
            if tonumber(self.data.id) == 3 then
                runGamePrompt({msg = "没有精力丹可以使用"})
            else
                runGamePrompt({msg = "没有体力丹可以使用"})
            end
            
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.leftButton:setSwallowsTouch(true)
    self.rootItems.leftButton:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.rightLab,nil,19)
    self.rootItems.rightButton:addHandleOfControlEvent(function()
        -- self:numchange(10)
        -- print("右边体力丹使用")
        if data[tostring(twoCid)] and data[tostring(twoCid)].num > 0 then
            -- usePropByid(twoCid,data[tostring(twoCid)].num,"体力不足")

            -- runGamePrompt({msg = msg..",剩余"..num..ui.IDconfig(id).name.."可使用"})
            gameWindows:openWindow("propusebynum",{id = twoCid})

        else
            if tonumber(self.data.id) == 3 then
                runGamePrompt({msg = "没有精力丹可以使用"})
            else
                runGamePrompt({msg = "没有体力丹可以使用"})
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.rightButton:setSwallowsTouch(true)
    self.rootItems.rightButton:setTouchPriority(self.touchPriority)


    if data[tostring(oneCid)] == nil or data[tostring(oneCid)].num <= 0 then
        print("oneCid==hong")
        ui.setLabelString(self.rootItems.i_num,nil,24)
        
    end

    if data[tostring(twoCid)] == nil or data[tostring(twoCid)].num <= 0 then
        print("twoCid==hong")
        ui.setLabelString(self.rootItems.i_num_1,nil,24)
    end
end


function buy.reloadShowData(self)
    -- print("reloadData===")
    self.buynum = 0
    self.totalprice = 0
    self:setbuydata()
    self:setShowData()
end

function buy.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.needeffect = nil

    if self.callback then
        self.callback()
    end
    self.buynum = 0
    self.totalprice = 0
end

return buy