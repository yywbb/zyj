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
    self.rootNode, self.rootItems = CCBReaderLoad("shop/tc_property", nil, true, "tc_property")

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
        [1] = {key = "b_athletics",name="athletics",nameS="挑战\""..tonumber(gamedata.config.global_kv.athletics_once_times.value).."\"次"},
        [2] = {key = "b_physical",name="stamina",nameS="体力\""..gamedata.config.global_kv.basic_buy_stamina.value.."\""},
        [3] = {key = "b_energy",name="energy",nameS="精力\""..gamedata.config.global_kv.basic_buy_energy.value.."\""},
        [4] = {key = "friendcopy_times",name="friendcopycost",nameS="挑战\"1\"次"},
        [5] = {key = "bzxtrst",name="mieshendian",nameS="重置\"1\"次"},
        [6] = {key = "personalboss_times",name="personalboss_cost",nameS="挑战\"1\"次"},
        [7] = {key = "coin_copy_times",name="coin_copy_cost",nameS="挑战\"1\"次"},
        [8] = {key = "exp_copy_times",name="exp_copy_cost",nameS="挑战\"1\"次"},
        [9] = {key = "stone_copy_times",name="stone_cost",nameS="挑战\"1\"次"},
        [10] = {key = "through_times",name="through_cost",nameS="挑战\"1\"次"},
        [11] = {key = "upstar_times",name="upstar_copy_cost",nameS="挑战\"1\"次"},
        [12] = {key = "zhenfu_times",name="zhenfu_copy_cost",nameS="挑战\"1\"次"},
        [13] = {key = "home_challenge_times",name="home_monster_cost",nameS="协助\"1\"次"},
        [14] = {key = "sociaty_boss_order",name="sociaty_boss_frequency",nameS="挑战\"1\"次"},
        [15] = {key = "b_hall",name="hall_challenge_consume",nameS="挑战\"1\"次"},
        [16] = {key = "b_hero_boss",name="heroboss_challenge",nameS=" "},
        [17] = {key = "forging_copy_times",name="forging_cost",nameS="挑战\"1\"次"},
        [18] = {key = "xianku_cishu",name="fuzhi_goumai_jiage",nameS="挑战\"1\"次"},

        [20] = {key = "game_2048_times",name="game_2048_price",nameS="挑战\"1\"次"}, --消耗元宝
    }

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("buyProperty")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
        self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
        self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("buyProperty")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.buynum >0 then
            if self.totalprice > GameScene.roleinfo.gold then
                shortGold()
            else
                UIRequest({type = 301,cid = self.data.id, count = self.buynum, gold = self.totalprice})
                gameWindows:closeWindowDirect("buyProperty")
            end
        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    self:reload(data,callback)

    return self.rootNode
end

function buy.setbuydata(self)
    self.rootItems.buynum:setString(self.buynum)
    self.rootItems.totalprice:setString(self.totalprice)
    self.rootItems.totalprice:setColor(self.totalprice > GameScene.roleinfo.gold and ccc3(255,0,0) or ccc3(135,81,25))
    if self.proprety[self.data.id].key == "game_2048_times" then
        self.rootItems.buynumtishi:setString("本期还可购买      次")
        self.rootItems.dayupdata:setVisible(false)
    else
        self.rootItems.dayupdata:setVisible(true)
    end
end

function buy.numchange(self,num)
    self.buynum = self.buynum+num
    local restcount = self.totalcount - self.nowcount

    if self.buynum > restcount then
        if self.proprety[self.data.id].key == "game_2048_times" then
            runGamePrompt({msg = "达到购买次数上限"})
        else
            runGamePrompt({msg = "达到今日购买次数上限"})
        end
        self.buynum = restcount
    elseif self.buynum <0 then
        self.buynum = 0
    end

    self.totalprice = 0
    if self.buynum >0 then
        for i= self.nowcount+1, self.nowcount+self.buynum do
            self.totalprice = self.totalprice + gamedata.config.buycount_price[tostring(i)][self.proprety[self.data.id].name]
        end
    end

    self:setbuydata()
end

function buy.setPropdata(self,data)
    self.data = data
    -- print("setPropdata===")
    -- printT(GameScene.vipstatus)
    self.nowcount = GameScene.vipstatus[self.proprety[self.data.id].key]
    self.totalcount = gamedata.config.vip[tostring(GameScene.vip.vip)][self.proprety[self.data.id].key]

    setSpriteFrameByName(self.rootItems.VIP,"b_n_vip_"..GameScene.vip.vip)
    ui.setLabelString(self.rootItems.name,self.proprety[self.data.id].nameS, 9)

    ui.setLabelString(self.rootItems.buytime, self.totalcount - self.nowcount, self.totalcount - self.nowcount>0 and 22 or 24)

    local buynumstr = "每日可购买"
    if self.proprety[self.data.id].key == "game_2048_times" then
        buynumstr = "可购买"
    end
    if gameConfig:checkBuildOpen(154) then
        self.rootItems.hasnum:setString("贵族"..GameScene.vip.vip..buynumstr..self.totalcount.."次")
    else
        self.rootItems.hasnum:setString(buynumstr..self.totalcount.."次")
    end

end

function buy.reload(self,data,callback)
    self.callback = callback
    self:setPropdata(data)
    self:setbuydata()
end

function buy.reloadData(self,data)
    self:setPropdata(data)
    self:numchange(0-self.buynum)
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

return buy  z   