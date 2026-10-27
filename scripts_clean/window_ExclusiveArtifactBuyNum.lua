--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/11/3
-- Time: 下午2:17
-- To change this template use File | Settings | File Templates.
--

local exclusiveArtifactBuyNum = {
    rootNode = nil,
    rootItems = nil,

    buynum = 0,
    totalprice = 0,

    data = {},
}

function exclusiveArtifactBuyNum.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_goumaicishu", nil, true, "tc_goumaicishu")

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
        [1] = {key = "device_soul",name="device_soul_copy_cost",nameS="挑战\"1\"次"}, -- 器魂挑战次数购买
    }

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("exclusiveArtifactBuyNum")
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
        gameWindows:closeWindow("exclusiveArtifactBuyNum")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.buynum > 0 then
            if self.totalprice > GameScene.roleinfo.g_gold then
                runGamePrompt({msg = gameConfig.strings:string_common("babelTower",2)})
            else
                UIRequest({type = 7010,sysId = 614, times = self.buynum, spend = self.totalprice})
                gameWindows:closeWindowDirect("exclusiveArtifactBuyNum")
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

function exclusiveArtifactBuyNum.setbuydata(self)
    self.rootItems.buynum:setString(self.buynum)
    self.rootItems.totalprice:setString(self.totalprice)
    self.rootItems.totalprice:setColor(self.totalprice > GameScene.roleinfo.g_gold and ccc3(255,0,0) or ccc3(135,81,25))
    self.rootItems.totalprice1:setString(GameScene.roleinfo.g_gold)
end

function exclusiveArtifactBuyNum.numchange(self,num)
    self.buynum = self.buynum+num
    local restcount = self.totalcount - self.nowcount

    if self.buynum > restcount then
        runGamePrompt({msg = "达到今日购买次数上限"})
        self.buynum = restcount
    elseif self.buynum < 0 then
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

function exclusiveArtifactBuyNum.setPropdata(self,data)
    self.data = data

    self.nowcount = GameScene.vipstatus[self.proprety[self.data.id].key]
    self.totalcount = gamedata.config.vip[tostring(GameScene.vip.vip)][self.proprety[self.data.id].key]

    setSpriteFrameByName(self.rootItems.VIP,"b_n_vip_"..GameScene.vip.vip)
    ui.setLabelString(self.rootItems.name,self.proprety[self.data.id].nameS, 9)

    ui.setLabelString(self.rootItems.buytime, self.totalcount - self.nowcount, self.totalcount - self.nowcount>0 and 22 or 24)

    if gameConfig:checkBuildOpen(154) then
        self.rootItems.hasnum:setString("VIP"..GameScene.vip.vip.."每日可购买"..self.totalcount.."次")
    else
        self.rootItems.hasnum:setString("每日可购买"..self.totalcount.."次")
    end
end

function exclusiveArtifactBuyNum.reload(self,data,callback)
    self.callback = callback
    self:setPropdata(data)
    self:setbuydata()
end

function exclusiveArtifactBuyNum.reloadData(self,data)
    self:setPropdata(data)
    self:numchange(0-self.buynum)
end

function exclusiveArtifactBuyNum.close(self)
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

return exclusiveArtifactBuyNum