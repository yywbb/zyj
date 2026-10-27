--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/2
-- Time: 下午1:48
-- To change this template use File | Settings | File Templates.
--



local singleboss = {

    rootNode = nil,
    rootItems = nil,

    data = {},
    attBossData = {},

    buttontouch = -103,
    battletimes = 0,
    rolelv = 0,
    viplv = 0,


}

function singleboss.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("kingman/kingman_rulai", nil, true, "kingman_rulai")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((GameScene.topposY-1620)*0.4+500)

    self.rootItems.history:setSwallowsTouch(true)
    self.rootItems.history:setTouchPriority(self.buttontouch-1)
    self.rootItems.history:addHandleOfControlEvent(function()
        gameWindows:openWindow("kingfoot",{type = "kingfoot"})
    end, CCControlEventTouchUpInside)

    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.buttontouch-1)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
         GameScene:shiftLayer("daily","down")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.battletext,nil,19)
    self.rootItems.battlebtn:setSwallowsTouch(true)
    self.rootItems.battlebtn:setTouchPriority(self.buttontouch-1)
    self.rootItems.battlebtn:addHandleOfControlEvent(function()

        if guide.controller then
            guide.controller:UIComplete(8013)
        end

        if self.data.isFirst and self.data.isFirst == 1 then
            UIRequest({type = 3702,id = 140,param = self.data.bosstype})
        else
            -- gameWindows:openWindow("kingfoot",{type = "kingselect", data = self.data})
            local bossconfig = {}
            if self.data.openlevel == 0 then
                bossconfig = self.attBossData[1]
            else
                local curidx = (self.data.openlevel+1)%100
                if curidx > #self.attBossData then
                    bossconfig = self.attBossData[#self.attBossData]
                else
                    bossconfig = self.attBossData[curidx]
                end
            end
            UIRequest({type = 3701,id = bossconfig.id})
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.slottext,nil,19)
    self.rootItems.slotbtn:setSwallowsTouch(true)
    self.rootItems.slotbtn:setTouchPriority(self.buttontouch-1)
    self.rootItems.slotbtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if next(self.data) then
            UIRequest({type = 3702,id = 140,param = self.data.bosstype})
        end
    end, CCControlEventTouchUpInside)

    -- 有阵容 80级或vip5
    ui.addGray("CCControlButton",self.rootItems.oneFinishBtn)
    ui.setLabelString(self.rootItems.oneFinishText,nil,19)
    self.rootItems.oneFinishBtn:setSwallowsTouch(true)
    self.rootItems.oneFinishBtn:setTouchPriority(self.buttontouch-1)
    self.rootItems.oneFinishBtn:addHandleOfControlEvent(function()

        if self.rolelv >=80 or self.viplv >=5 then
            if self.data.openlevel and self.data.openlevel == 0 then
                 runGamePrompt({msg = "需成功通关第一关后可使用一键挑战"})
                return
            end
            gameWindows:openWindow("kingmanOnekeyChallenge",{ times = self.battletimes, data = self.data })
        else
            runGamePrompt({msg = "队伍等级80级或VIP5可使用一键挑战"})
            return
        end    
    end, CCControlEventTouchUpInside)
    self.rootItems.oneFinishBtn:setVisible(false)
    self.rootItems.oneFinishText:setVisible(false)

    self.rootItems.showitem:setSwallowsTouch(true)
    self.rootItems.showitem:setTouchPriority(self.buttontouch-1)
    

    self.rootItems.addTimes:setSwallowsTouch(true)
    self.rootItems.addTimes:setTouchPriority(self.buttontouch-1)
    self.rootItems.addTimes:addHandleOfControlEvent(function()
        singlebossBuyTimes()
    end, CCControlEventTouchUpInside)

    self.data = param
    self:reloadData()

    UIRequest({type = 1040})
end

function singleboss.reloadlv(self,data)
    print(reloadlv," reloadlv")
    printT(data)
    if data then
        print(reloadlv," reloadlv1")
        self.rolelv = data.rolelv or 0
        self.viplv = data.viplv or 0
         print(reloadlv," reloadlv2")
        if self.rolelv >=80 or self.viplv >=5 then
            print(reloadlv," reloadlv3")
            ui.removeGray("CCControlButton",self.rootItems.oneFinishBtn)
        end    
    end    
end
--获得当前boss数据
function singleboss.setBossLevelTable(self,aiType)
    self.attBossData = {}
    local attConfigData = gamedata.config:getConfigByName("personalboss_att")
    for k,v in pairs(attConfigData) do
        if v["function"] == aiType then
            table.insert(self.attBossData,v)
        end
    end
    local sortfun = function(a,b)
        return a.id < b.id 
    end
    table.sort( self.attBossData,sortfun)
end
function singleboss.reloadData(self,data)
    if data then self.data = data end
    
    self.rootItems.showitem:addHandleOfControlEvent(function()
        gameWindows:openWindow("bossDropDetail",{data = self.data})
    end, CCControlEventTouchUpInside)
    self:setBossLevelTable(self.data.bosstype)

    local config = gamedata.config:getConfigByName("personalboss_att")
    local bossconfig = {}
    
    if self.data.openlevel == 0 then
        bossconfig = self.attBossData[1]
    else
        local curidx = (self.data.openlevel+1)%100
        if curidx > #self.attBossData then
            bossconfig = self.attBossData[#self.attBossData]
        else
            bossconfig = self.attBossData[curidx]
        end
    end

    local bossname = gamedata.config:getConfigByName("generalanimation")[tostring(bossconfig.animationid)].name
    local bossskeleton = CCSkeletonAnimation:create(bossname.."/"..bossname..".json",bossname.."/"..bossname..".atlas",1)
    bossskeleton:setAnimation("stand",true,0)
    bossskeleton:setScale(2.2)
    self.rootItems.boss:removeAllChildrenWithCleanup(true)
    self.rootItems.boss:addChild(bossskeleton)
    self.rootItems.boss:setScaleX(-1)
    setSpriteFrameByName(self.rootItems.bossbg,"bg_"..bossname..".jpg")


    ui.setLabelString(self.rootItems.bossname2, bossconfig.name, bossconfig.quality*2-1)
    -- ui.setLabelString(self.rootItems.bossdes, bossconfig.desc, 21)--优化
    ui.setLabelString(self.rootItems.timedes, nil, 26)
    --等级
    ui.setLabelString(self.rootItems.bosslevel,"boss等级："..bossconfig.level, 21)
    print("timesnum===",gamedata.config:getConfigByName("vip")[tostring(0)]["personalboss_times"],GameScene.vipstatus.personalboss_times,self.data.battlenum)
    if (gamedata.config:getConfigByName("vip")[tostring(0)]["personalboss_times"]+GameScene.vipstatus.personalboss_times) > self.data.battlenum then
        ui.setLabelString(self.rootItems.battletimes,"剩余挑战次数: "..(gamedata.config:getConfigByName("vip")[tostring(0)]["personalboss_times"]-self.data.battlenum+GameScene.vipstatus.personalboss_times).."/"..gamedata.config:getConfigByName("vip")[tostring(0)]["personalboss_times"],13)
        self.battletimes = (gamedata.config:getConfigByName("vip")[tostring(0)]["personalboss_times"]-self.data.battlenum+GameScene.vipstatus.personalboss_times)
    else
        ui.setLabelString(self.rootItems.battletimes,"剩余挑战次数: "..(gamedata.config:getConfigByName("vip")[tostring(0)]["personalboss_times"]-self.data.battlenum+GameScene.vipstatus.personalboss_times).."/"..gamedata.config:getConfigByName("vip")[tostring(0)]["personalboss_times"],24)
        self.battletimes = (gamedata.config:getConfigByName("vip")[tostring(0)]["personalboss_times"]-self.data.battlenum+GameScene.vipstatus.personalboss_times)
    end

    local timetemp = os.date("*t", gamedata:time())
    local time = (23-timetemp.hour)*3600+(59-timetemp.min)*60+62-timetemp.sec

    gameTimer:rigistTime("singlebosschange",time)
    if gameTimer.times["singlebosschange"] and gameTimer.times["singlebosschange"] > 0 then
        gameTimer:rigistTimeFunc("singlebosschange",function()
            if gameTimer.times["singlebosschange"] > 0 then
                ui.setLabelString(self.rootItems.time,ui.makeTimeText(gameTimer.times["singlebosschange"]),13)
            else
                UIRequest({type = 3700})
            end
        end)
    end
    --突破技能
    local oldday = CCUserDefault:sharedUserDefault():getStringForKey("breakskillisopen")
    local curday = timetemp.day
    local id = bossconfig["breakskill"]
    local name = gamedata.config:getConfigByName("breakskill")[tostring(id)].name
    local desc = gamedata.config:getConfigByName("breakskill")[tostring(id)].desc
    local icon = bossconfig["breakskill_icon"]
    setSpriteFrameByName(self.rootItems["in_soulsprite"], "alpha")
    ui.setLabelString(self.rootItems["in_name"],name,21)
    setSpriteFrameByName(self.rootItems["in_icon"], icon or "alpha")
    self.rootItems["in_button"]:addHandleOfControlEvent(function()
        self:breakskillDetail(name, icon, desc)
    end, CCControlEventTouchUpInside)
    if self.data.openlevel == 0 and oldday ~= tostring(curday) then
        CCUserDefault:sharedUserDefault():setStringForKey("breakskillisopen", curday)
        self:breakskillDetail(name, icon, desc)
    end
    

    printT(bossconfig,"bossconfig")
    --几个普通技能
    for i=1,4 do
        local curSkillNode = self.rootItems["normalSkill"..i]
        if bossconfig["skill" .. i] ~= 0 then
            curSkillNode:setVisible(true)
            local id = bossconfig["skill" .. i]
            local name = gamedata.config:getConfigByName("combskill")[tostring(id)].name
            local icon = id
            local desc = gamedata.config:getConfigByName("combskill")[tostring(id)].desc
            local effect = gamedata.config:getConfigByName("combskill")[tostring(id)]["effect-desc"]
            -- self.bossSkillTab[i] = {icon = id, name = name, desc = desc, effect = effect}
            ui.setNewIconName(self.rootItems, {cid = icon}, i)
            self.rootItems["in_button_"..i]:addHandleOfControlEvent(function()
                -- gameWindows:openWindow("bossSkillInfo", {icon = id, name = name, desc = desc, effect = effect}, nil)
                self:breakskillDetail(name, gamedata.config:getConfigByName("combskill")[tostring(id)].icon, effect)
            end, CCControlEventTouchUpInside)
        else
            curSkillNode:setVisible(false)
        end
    end

end

--突破技能详情tip
function singleboss.breakskillDetail(self, name, icon, desc)
    -- body
    -- if self.rootItems.breakSkillNode:getChildrenCount() > 0 then
    --     self.rootItems.breakSkillNode:removeAllChildrenWithCleanup()
    --     return
    -- end
    
    local skillinfoCCB, ccbDocumentControler = CCBReaderLoad("kingman/tuposkillinfo.ccbi", nil, true, "tuposkillinfo")
    self.rootItems.breakSkillNode:addChild(skillinfoCCB)
    setSpriteFrameByName(ccbDocumentControler["in_soulsprite"], "alpha")
    setSpriteFrameByName(ccbDocumentControler["in_icon"], icon and icon or "alpha")
    -- ccbDocumentControler["in_name"]:setString(name)
    ui.setLabelString(ccbDocumentControler["in_name"],name,21)
    ccbDocumentControler.skillDesc:setString(desc)

    ccbDocumentControler.closebg:addHandleOfControlEvent(function()
       self.rootItems.breakSkillNode:removeAllChildrenWithCleanup(true)
    end, CCControlEventTouchUpInside)
end

function singleboss.clear(self)
    if gameTimer.times["singlebosschange"] then
        gameTimer:UnrigistTimeFunc("singlebosschange")
    end
    self.data = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function singleboss.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 3700})
    end
end

return singleboss