--
-- Author: songyibo
-- Date: 2019-03-21 14:44:34
--
local kingmanOnekeyChallenge = {
    rootNode = nil,
    rootItems = nil,
    battletimes = 0,
    showtimes = 0,
    bosstpye =0,
}

function kingmanOnekeyChallenge.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("kingman/tc_kingmantiaozhan", nil, true, "tc_kingmantiaozhan")
    self.attConfigData = gamedata.config.personalboss_att

    self.battletimes = data.times or 0
    self.nowcount = self.battletimes
    self.data = data.data
    self:setBossLevelTable(data.data.bosstype)
    self.bosstpye = self.data.openlevel

    

    printT(self.data,"self.data")

    -- singlebossBuyTimes()


    --减1
    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)


    --加1
    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)


    local openlevel = self.attConfigData[tostring(self.bosstpye)].level or 0
    self.rootItems.buynum:setString(tostring(self.nowcount))
    if self.nowcount<=0 then
        self.rootItems.buynum:setString("1")
    end    

    self.rootItems.buylevel:setString(tostring(openlevel))
    self.rootItems.havetime:setString(tostring(self.battletimes))
    if self.battletimes == 0 then
        self.rootItems.havetime:setColor(ccc3(255,8,8))
    else
        self.rootItems.havetime:setColor(ccc3(84,255,8))    
    end    

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("kingmanOnekeyChallenge")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.rootItems.oneFinishBtn:addHandleOfControlEvent(function()
       if self.nowcount > self.battletimes or  self.nowcount <= 0 then
            runGamePrompt({msg = "挑战次数不足"})
            return
       end 
       UIRequest({type = 3705, bossid = self.bosstpye, times = self.nowcount})
       gameWindows:closeWindow("kingmanOnekeyChallenge")

    end, CCControlEventTouchUpInside)
    self.rootItems.oneFinishBtn:setSwallowsTouch(true)
    self.rootItems.oneFinishBtn:setTouchPriority(self.touchPriority)

   

    self:initFixedString()
    return self.rootNode
end

function kingmanOnekeyChallenge.numchange(self,num)

    local battle = self.nowcount+num

    if num>0 and (self.battletimes == 0 or self.nowcount == self.battletimes )then --次数为0增加
        gameTouch:clickprofbytime(0.5)
        singlebossBuyTimes()
        return
    end    

    if battle <1 and num<0 and self.nowcount>0 then --1减不变
       self.nowcount = 1 
       self.rootItems.buynum:setString(tostring(self.nowcount))

    elseif battle <= self.battletimes and battle>0 then --在范围内加减
       self.nowcount = battle
       self.rootItems.buynum:setString(tostring(self.nowcount))
    end    
end


--获得当前boss数据
function kingmanOnekeyChallenge.setBossLevelTable(self,aiType)
    self.attBossData = {}
    for k,v in pairs(self.attConfigData) do
        if v["function"] == aiType then
            table.insert(self.attBossData,v)
        end
    end
    local sortfun = function(a,b)
        return a.id < b.id 
    end
    table.sort( self.attBossData,sortfun)
end


function kingmanOnekeyChallenge.reloaddata(self,data)
	self.data = data.boss or {}
    if (gamedata.config.vip[tostring(0)]["personalboss_times"]+GameScene.vipstatus.personalboss_times) > self.data.battlenum then
        self.battletimes = (gamedata.config.vip[tostring(0)]["personalboss_times"]-self.data.battlenum+GameScene.vipstatus.personalboss_times)
    else
        self.battletimes = (gamedata.config.vip[tostring(0)]["personalboss_times"]-self.data.battlenum+GameScene.vipstatus.personalboss_times)
    end
    self.nowcount = self.battletimes
    self.rootItems.buynum:setString(tostring(self.nowcount))


    self.rootItems.havetime:setString(tostring(self.nowcount))
    if self.nowcount == 0 then
        self.rootItems.havetime:setColor(ccc3(255,8,8))
    else
        self.rootItems.havetime:setColor(ccc3(84,255,8))    
    end  


end


function kingmanOnekeyChallenge.initFixedString(self)
	-- ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),19)
	-- ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),19)
end

function kingmanOnekeyChallenge.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.data = nil
    self.battletimes = 0
    self.nowcount = 0
    self.data = nil
    self.bosstpye = 0
   
    if self.callback then
        self.callback()
    end	
end
return kingmanOnekeyChallenge