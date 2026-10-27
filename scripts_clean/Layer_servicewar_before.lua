--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/2/4
-- Time: 14:31
-- To change this template use File | Settings | File Templates.
--

local servicewarBefore = {
    propid = 20346,
    propnum = 0,

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    buttontouch = -103,

    worldwarprepare = {},
    worldwarstatus = {},

    preparepushinfo = {},
}

function servicewarBefore.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_before", nil, true, "kuafuzhan_before")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY(((GameScene.topposY-1620)/2)+620)

    if GameScene.priorLayer == "limitedset" or GameScene.priorLayer == "daily" then
        self.priorLayer = GameScene.priorLayer
    end
    if self.rootItems.closeButton then
        self.rootItems.closeButton:setTouchPriority(-103)
        self.rootItems.closeButton:addHandleOfControlEvent(function()
           if self.priorLayer then
                GameScene:shiftLayer(self.priorLayer)
            else
                GameScene:shiftLayer("main","down")
            end
        end, CCControlEventTouchUpInside)
    end

    --
    local Gneral1 = CCSkeletonAnimation:create("jinyankongquelongwang/jinyankongquelongwang.json", "jinyankongquelongwang/jinyankongquelongwang.atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.2)
    Gneral1:setScaleX(-1.2)
    Gneral1:setPosition(0,0)
    self.rootItems["generalnode"]:addChild(Gneral1)
    --

    self.rootItems.propiconbutton:setTouchPriority(self.buttontouch)
    self.rootItems.propiconbutton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        ui.setPopwindowByCid(self.propid)
    end, CCControlEventTouchUpInside)

    for i=1,6 do
        ui.setLabelString(self.rootItems["fixedStr"..i],nil,14)
        self.rootItems["scheduleBtn"..i]:setTouchPriority(self.buttontouch)
        self.rootItems["scheduleBtn"..i]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if i <= 1 then
                --runGamePrompt({msg = "已经是当前页面"})
            else
                runGamePrompt({msg = "当前赛事未开启"})
            end

        end, CCControlEventTouchUpInside)

    end


    if GameScene.hintdata[tostring(212)] == 0 then
        ui.sethint(self.rootItems.hint_servicewarAfter,false)
    else
        ui.sethint(self.rootItems.hint_servicewarAfter,true)
    end

    --
    self:setPushData()
    --
    UIRequest({type = 4700})
    UIRequest({type = 4717})

end

function servicewarBefore.ReloadData(self,data)
    if data and data.worldwarstatus then
        self.worldwarstatus = data.worldwarstatus or {}
    end
    if data and data.worldwarprepare then
        self.worldwarprepare = data.worldwarprepare or {}
    end
    if data and data.propnum then
        self.propnum = data.propnum or 0
    end

    if self.worldwarstatus.list > 0 and self.worldwarstatus.status > gameConfig.serverWarStage.Upload_Array then
        GameScene:shiftLayer("main","down")
        return
    end

--    ui.setLabelString(self.rootItems.atknum,self.worldwarprepare.attr_atk or 0,14)
--    ui.setLabelString(self.rootItems.defnum,self.worldwarprepare.attr_def or 0,14)
--    ui.setLabelString(self.rootItems.hpnum,self.worldwarprepare.attr_hp or 0,14)
--    ui.setLabelString(self.rootItems.allnum,(self.worldwarprepare.attr_all or 0).."% ("..self.worldwarprepare.propnumall..")",14)
--    --
--    ui.setLabelString(self.rootItems.addLab,gameConfig.strings:string_common("fixedString","servicewar",1)..(gamedata.config.global_kv.cross_battle_bookenough and gamedata.config.global_kv.cross_battle_bookenough.value or "")..gameConfig.strings:string_common("fixedString","servicewar",2),22)
--    --
    ui.setLabelString(self.rootItems.handLab,gameConfig.strings:string_common("fixedString","servicewar",4),18)
    self.rootItems.handButton:setTouchPriority(self.buttontouch)
    local limitnum = (gamedata.config.global_kv.cross_battle_booknum and tonumber(gamedata.config.global_kv.cross_battle_booknum.value) or 0)-(self.worldwarprepare.propnum or 0)
    if limitnum < (gamedata.config.global_kv.cross_battle_book and tonumber(gamedata.config.global_kv.cross_battle_book.value) or 0) then
        if limitnum < 0 then
            limitnum = 0
        end
        ui.addGray("CCControlButton",self.rootItems.handButton)
        self.rootItems.handButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",5)})
        end, CCControlEventTouchUpInside)
    else
        ui.removeGray("CCControlButton",self.rootItems.handButton)
        self.rootItems.handButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4701})
        end, CCControlEventTouchUpInside)
    end
    ui.setLabelString(self.rootItems.propnumlimit,gameConfig.strings:string_common("fixedString","servicewar",3)..limitnum,13)
    --
    ui.setLabelString(self.rootItems.propnum,self.propnum.."/"..(gamedata.config.global_kv.cross_battle_book and tonumber(gamedata.config.global_kv.cross_battle_book.value) or 0),self.propnum >= (gamedata.config.global_kv.cross_battle_book and tonumber(gamedata.config.global_kv.cross_battle_book.value) or 0) and 22 or 24)
    --
    ui.setLabelString(self.rootItems.slotLab,gameConfig.strings:string_common("fixedString","servicewar",6),18)
    self.rootItems.slotButton:setTouchPriority(self.buttontouch)
    self.rootItems.slotButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 4704})
    end, CCControlEventTouchUpInside)
    --

    self.rootItems.title:setString( gameConfig.strings:servicewar_title_num(self.worldwarstatus.number) )
    --
    if self.worldwarstatus.list == 1 then
        self.rootItems.listSprite1:setVisible(true)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(false)
        self.rootItems.rankdescLab:setString("人榜")
    elseif self.worldwarstatus.list == 2 then
        self.rootItems.listSprite1:setVisible(false)
        self.rootItems.listSprite2:setVisible(true)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(false)
        self.rootItems.rankdescLab:setString("地榜")
    elseif self.worldwarstatus.list == 3 then
        self.rootItems.listSprite1:setVisible(false)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(true)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(false)
        self.rootItems.rankdescLab:setString("天榜")
    elseif self.worldwarstatus.list == 4 then
        self.rootItems.listSprite1:setVisible(false)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(true)
        self.rootItems.listSprite5:setVisible(false)
        self.rootItems.rankdescLab:setString("仙榜")
    elseif self.worldwarstatus.list == 5 then
        self.rootItems.listSprite1:setVisible(false)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(true)
        self.rootItems.rankdescLab:setString("神榜")
    else
        self.rootItems.listSprite1:setVisible(true)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(false)
        self.rootItems.rankdescLab:setString("人榜")
    end
    --
    local tt = tostring(table.getTableLength(gamedata.config.cross_battle_time))
    --
    if self.worldwarstatus.list > 0 then
        self.rootItems.handNode:setVisible(true)
        self.rootItems.nowarNode:setVisible(false)
        self.rootItems.slotNode:setVisible(true)
        self.rootItems.slotNode2:setVisible(false)
        if self.worldwarstatus.competition > 0 then
            self.rootItems.slotButtonNode:setVisible(true)
        else
            self.rootItems.slotButtonNode:setVisible(false)
        end
        tt = "1"
    else
        self.rootItems.handNode:setVisible(false)
        self.rootItems.nowarNode:setVisible(true)
        self.rootItems.slotNode:setVisible(false)
        self.rootItems.slotNode2:setVisible(true)
    end
    --

    local battleStatus = 1
    for i=1,6 do
        if self.worldwarstatus.list > 0 then
            if self.worldwarstatus.status then

                if self.worldwarstatus.status <= gameConfig.serverWarStage.Upload_Array then
                    battleStatus = 1
                elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Began_Audition and self.worldwarstatus.status <= gameConfig.serverWarStage.Show_Audition then
                    battleStatus = 2
                elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_64To32 and self.worldwarstatus.status <= gameConfig.serverWarStage.Battle_64To8_3 then
                    battleStatus = 3
                elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_8To4 and self.worldwarstatus.status <= (self.worldwarstatus.s_open == 1 and gameConfig.serverWarStage.Battle_8To4_3 or gameConfig.serverWarStage.Show_result_4) then
                    battleStatus = 4
                elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_4To2 and self.worldwarstatus.status <= gameConfig.serverWarStage.Battle_4To2_3 then
                    battleStatus = 5
                else
                    battleStatus = 6
                end
                if i == battleStatus then
                    self.rootItems["selectnum"..i]:setVisible(true)
                    setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4")
                else
                    self.rootItems["selectnum"..i]:setVisible(false)
                    setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
                end
            else
                self.rootItems["selectnum"..i]:setVisible(false)
                setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
            end
        else
            self.rootItems["selectnum"..i]:setVisible(false)
            setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
        end
    end



    local wday = gamedata.config.cross_battle_time[tt].over_week+1
    if wday > 7 then wday = 1 end
    local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tt].over_time)
    local nowtime = os.date("*t", gamedata:time())
    local diff = (wday-nowtime.wday)*86400+(hour-nowtime.hour)*3600+(min-nowtime.min)*60+sec-nowtime.sec
    if diff < 0 then diff = diff+86400*7 end

    gameTimer:rigistTime("worldwarbeforetimer",diff+1)
    gameTimer:rigistTimeFunc("worldwarbeforetimer",function()
        if gameTimer.times["worldwarbeforetimer"] <= 0 then
            self.rootItems.wartime:setString("")
            ui.setLabelString(self.rootItems.nexttime,"",14)
            UIRequest({type = 4702, param = "update"})
        else
            self.rootItems.wartime:setString(ui.makeTimeDayText(gameTimer.times["worldwarbeforetimer"],"day"))
            ui.setLabelString(self.rootItems.nexttime,ui.makeTimeDayText(gameTimer.times["worldwarbeforetimer"],"day"),14)
        end
    end)
    --
    --
    self.rootItems.listButton:setTouchPriority(self.buttontouch)
    self.rootItems.listButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 榜
        gameWindows:openWindow("servicewarchampionlist",{index = "matchinfo"})
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.ruleButton:setTouchPriority(self.buttontouch)
    self.rootItems.ruleButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 规则
        gameWindows:openWindow("servicewarrule",{opt = 1,shenbang = (self.worldwarstatus.s_open and self.worldwarstatus.s_open == 1)})
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.pastButton:setTouchPriority(self.buttontouch)
    self.rootItems.pastButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 历届冠军
        gameWindows:openWindow("servicewarchampionlist",{index = "champion"})
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.entryButton:setTouchPriority(self.buttontouch)
    self.rootItems.entryButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 参赛名单
        gameWindows:openWindow("servicewarchampionlist",{index = "joined"})
    end, CCControlEventTouchUpInside)
    --


end

function servicewarBefore.setChampionNode(self,t)
   if t then
        self.rootItems.servicewarAfternode:setVisible(true)
   else
        self.rootItems.servicewarAfternode:setVisible(false)
   end

    self.rootItems.servicewarAfterBtn:setTouchPriority(self.buttontouch)
    self.rootItems.servicewarAfterBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        GameScene:shiftLayer("servicewarAfter","up")
    end, CCControlEventTouchUpInside)

end

function servicewarBefore.ReloadPushData(self,data)
    if data and data.preparepushinfo then
        self.preparepushinfo = data.preparepushinfo or {}
    end
    self:setPushData()
end

function servicewarBefore.setPushData(self)
    if self.preparepushinfo and self.preparepushinfo.time and self.preparepushinfo.time > 0 then
        local ptime = os.date("*t",self.preparepushinfo.time)
        self.rootItems.handtime:setString(gameConfig.strings:YearMinute(ptime.year,ptime.month,ptime.day,ptime.hour,ptime.min))
        self.rootItems.handdesc:setString(self.preparepushinfo.name.." "..gameConfig.strings:string_common("fixedString","servicewar",29)..(gamedata.config.global_kv.cross_battle_book and tonumber(gamedata.config.global_kv.cross_battle_book.value) or 0)..gameConfig.strings:string_common("fixedString","servicewar",30))
    else
        self.rootItems.handtime:setString("")
        self.rootItems.handdesc:setString("")
    end
end

function servicewarBefore.clear(self)
    gameTimer:UnrigistTimeFunc("worldwarbeforetimer")
    self.preparepushinfo = {}
    self.worldwarstatus = {}
    self.worldwarprepare = {}
    self.rootItems = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return servicewarBefore