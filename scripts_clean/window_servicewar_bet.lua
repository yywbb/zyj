--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/19
-- Time: 下午12:00
-- To change this template use File | Settings | File Templates.
--

local servicewar_bet = {
    rootNode = nil,
    rootItems = nil,
    battlefieldid1 = 0,
    battlefieldid2 = 0,
    playerdata = {},
    data = {},
}

function servicewar_bet.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    printT(data,"cup===data")

    self.shenbang = data.shenbang
    self.division = data.division

    if data.index == "bet" then   
        self.battlefieldid1 = data.battlefieldid1
        self.battlefieldid2 = data.battlefieldid2
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhanbet", nil, true, "kuafuzhanbet")
        -- self:reloadBet(data.data,callback)
        self.root:addChild(self.rootNode)
        
        gameTouch:clickprofbytime(0.5)

        if self.shenbang then
            UIRequest({type = 4726, id = data.battleid})
        else
            UIRequest({type = 4713, id = data.battleid,division = self.division})
        end

    elseif data.index == "battleinfo" then 
        self.battlefieldid1 = data.battlefieldid1
        self.battlefieldid2 = data.battlefieldid2
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_bisaiinfo", nil, true, "kuafuzhan_bisaiinfo")
        -- self:reloadBet(data.data,callback)
        self.root:addChild(self.rootNode)

        gameTouch:clickprofbytime(0.5)

        if self.shenbang then
            UIRequest({type = 4725, id = data.battleid})
        else
            UIRequest({type = 4710, id = data.battleid,division = self.division})
        end

    end
    

    return self.root, true
end


function servicewar_bet.reloadWatchData(self,data)
    self.playerdata = data

    self.rootItems.battleText1:setString("第一场")
    self.rootItems.battleText2:setString("第二场")
    self.rootItems.battleText3:setString("第三场")

    ui.setLabelString(self.rootItems.slotLab1,"观 看",18)
    ui.setLabelString(self.rootItems.slotLab2,"观 看",18)
    ui.setLabelString(self.rootItems.slotLab3,"观 看",18)


    ui.setLabelString(self.rootItems.servicenameLab1,self.playerdata.player1.server_name,14)
    ui.setLabelString(self.rootItems.servicenameLab2,self.playerdata.player2.server_name,14)

    ui.setLabelString(self.rootItems.playernameLab1,self.playerdata.player1.name,21)
    ui.setLabelString(self.rootItems.playernameLab2,self.playerdata.player2.name,21)

    local winnum1 = 0
    local winnum2 = 0
    for i=1,3 do
        local sultnum = tonumber(self.playerdata.basicdata["battleresult"..i])
        if sultnum == 1 then
            print("num===",(2*i-1),(2*i))
            self.rootItems["fightnode"..i]:setVisible(true)
            self.rootItems["winnode"..(2*i-1)]:setVisible(true)
            self.rootItems["winText"..(2*i-1)]:setString("胜")

            self.rootItems["winnode"..(2*i)]:setVisible(false)
            self.rootItems["winText"..(2*i)]:setString("胜")

            local data1 = {cid = self.playerdata.player1.profile,num = self.playerdata.player1.level}
            local data2 = {cid = self.playerdata.player2.profile,num = self.playerdata.player2.level}

            ui.setNewIcon(self.rootItems,data1,2*(i-1))
            ui.setNewIcon(self.rootItems,data2,2*(i-1)+1)

            winnum1 = winnum1 + 1
        elseif sultnum == 0 then
            self.rootItems["fightnode"..i]:setVisible(true)
            self.rootItems["winnode"..(2*i-1)]:setVisible(false)
            self.rootItems["winText"..(2*i-1)]:setString("胜")

            self.rootItems["winnode"..(2*i)]:setVisible(true)
            self.rootItems["winText"..(2*i)]:setString("胜")

            local data1 = {cid = self.playerdata.player1.profile,num = self.playerdata.player1.level}
            local data2 = {cid = self.playerdata.player2.profile,num = self.playerdata.player2.level}

            ui.setNewIcon(self.rootItems,data1,2*(i-1))
            ui.setNewIcon(self.rootItems,data2,2*(i-1)+1)
            winnum2 = winnum2 + 1
        else
            self.rootItems["fightnode"..i]:setVisible(false)
        end
    end

    if (winnum1 + winnum2) == 3 then
        if winnum1 > winnum2 then
            ui.setLabelString(self.rootItems.fightnumLab1,winnum1,11)
            ui.setLabelString(self.rootItems.fightnumLab2,winnum2,3)
        else
            ui.setLabelString(self.rootItems.fightnumLab1,winnum1,3)
            ui.setLabelString(self.rootItems.fightnumLab2,winnum2,11)
        end
    else
        ui.setLabelString(self.rootItems.fightnumLab1,winnum1,3)
        ui.setLabelString(self.rootItems.fightnumLab2,winnum2,3)
    end
    
    self.rootItems.slotButton1:addHandleOfControlEvent(function()

        gameTouch:clickprofbytime(0.5)
        if self.shenbang then
            UIRequest({type = 4727, id = self.playerdata.basicdata.battleid1})
        else
            UIRequest({type = 4711, id = self.playerdata.basicdata.battleid1})
        end

        print("观战1111")
    end, CCControlEventTouchUpInside)
    self.rootItems.slotButton1:setSwallowsTouch(true)
    self.rootItems.slotButton1:setTouchPriority(self.touchPriority)


    self.rootItems.slotButton2:addHandleOfControlEvent(function()

        gameTouch:clickprofbytime(0.5)
        if self.shenbang then
            UIRequest({type = 4727, id = self.playerdata.basicdata.battleid2})
        else
            UIRequest({type = 4711, id = self.playerdata.basicdata.battleid2})
        end

        print("观战2222")
    end, CCControlEventTouchUpInside)
    self.rootItems.slotButton2:setSwallowsTouch(true)
    self.rootItems.slotButton2:setTouchPriority(self.touchPriority)


    self.rootItems.slotButton3:addHandleOfControlEvent(function()

        gameTouch:clickprofbytime(0.5)
        if self.shenbang then
            UIRequest({type = 4727, id = self.playerdata.basicdata.battleid3})
        else
            UIRequest({type = 4711, id = self.playerdata.basicdata.battleid3})
        end
        print("观战3333")
    end, CCControlEventTouchUpInside)
    self.rootItems.slotButton3:setSwallowsTouch(true)
    self.rootItems.slotButton3:setTouchPriority(self.touchPriority)


    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarbet")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end


function servicewar_bet.reloadData(self,data)

    self.data = data

    printT(self.data)

    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarbet")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.rootItems.tittleNameText:setString("竞猜")


    if self.data.basicdata and self.data.basicdata.petstatus == 0 then
        -- 可以下注
        ui.removeGray("CCControlButton",self.rootItems["bet_a_button"])
        ui.removeGray("CCControlButton",self.rootItems["bet_b_button"])
        self.rootItems.betNode:setVisible(true)
        self.rootItems.hasbetNode:setVisible(false)
        
        ui.setLabelString(self.rootItems.bet_a_buttontext,"下 注",18)
        self.rootItems.bet_a_button:addHandleOfControlEvent(function()
            -- gameWindows:closeWindowDirect("cup")
            print("左边下注＝＝")
            gameWindows:openWindow("servicewarbetchoose",{shenbang = self.shenbang,division = self.division,data = self.data, choose = 1})
        end, CCControlEventTouchUpInside)
        self.rootItems.bet_a_button:setSwallowsTouch(true)
        self.rootItems.bet_a_button:setTouchPriority(self.touchPriority)


        ui.setLabelString(self.rootItems.bet_b_buttontext,"下 注",18)
        self.rootItems.bet_b_button:addHandleOfControlEvent(function()
            -- gameWindows:closeWindowDirect("cup")
            print("右边下注＝＝")
            gameWindows:openWindow("servicewarbetchoose",{shenbang = self.shenbang,division = self.division,data = self.data, choose = 2})
        end, CCControlEventTouchUpInside)
        self.rootItems.bet_b_button:setSwallowsTouch(true)
        self.rootItems.bet_b_button:setTouchPriority(self.touchPriority)

        
        ui.setLabelString(self.rootItems.petmaxDescLab,"本轮比赛剩余最大押注限额："..((self.data.basicdata.maxbetmoneynum>self.data.basicdata.nowbetmoneynum) and (self.data.basicdata.maxbetmoneynum-self.data.basicdata.nowbetmoneynum) or 0),14)
        ui.setLabelString(self.rootItems.petDescText,"下注成功后，奖励将发至邮箱",21)
        local timeconfig1 = gamedata.config.cross_battle_time[tostring(self.battlefieldid1 or 1)]
        local timeconfig2 = gamedata.config.cross_battle_time[tostring(self.battlefieldid2 or 1)]
        local hour1,min1,sec1 = ui.getGangBattleTime(timeconfig1.open_time)
        local hour2,min2,sec2 = ui.getGangBattleTime(timeconfig2.over_time)
        if math.floor(min1/10) < 1 then
            min1 = "0"..min1
        end
        if math.floor(min2/10) < 1 then
            min2 = "0"..min2
        end
        local timestring = "比赛时间：周"..gameConfig.strings:string_common("wdayNum",(timeconfig1.open_week+1)>7 and 1 or (timeconfig1.open_week+1)).." "..hour1..":"..min1.." ~ ".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig2.over_week+1)>7 and 1 or (timeconfig2.over_week+1)).." "..hour2..":"..min2

        ui.setLabelString(self.rootItems.timeLab,timestring,14)
    else
        -- 已下注完毕
        self.rootItems.betNode:setVisible(false)
        self.rootItems.hasbetNode:setVisible(true)
        ui.addGray("CCControlButton",self.rootItems["bet_a_button"])
        ui.addGray("CCControlButton",self.rootItems["bet_b_button"])
        if self.data.basicdata and self.data.basicdata.petstatus == 1 then
            self.rootItems.bet_a:setVisible(true)
            self.rootItems.bet_b:setVisible(false)
        else
            self.rootItems.bet_a:setVisible(false)
            self.rootItems.bet_b:setVisible(true)
        end

        self.rootItems.bet_b_button:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",80)})
        end, CCControlEventTouchUpInside)
        self.rootItems.bet_b_button:setSwallowsTouch(true)
        self.rootItems.bet_b_button:setTouchPriority(self.touchPriority)

        self.rootItems.bet_a_button:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",80)})
        end, CCControlEventTouchUpInside)
        self.rootItems.bet_a_button:setSwallowsTouch(true)
        self.rootItems.bet_a_button:setTouchPriority(self.touchPriority)

    end

    ui.setLabelString(self.rootItems.name_a,self.data.player1.name,14)
    ui.setLabelString(self.rootItems.powerLab1,"战斗力："..self.data.player1.power,14)
    ui.setLabelString(self.rootItems.petchanceLab1,"倍率："..self.data.basicdata.petchance1.."倍",14)

    ui.setLabelString(self.rootItems.name_b,self.data.player2.name,14)
    ui.setLabelString(self.rootItems.powerLab2,"战斗力："..self.data.player2.power,14)
    ui.setLabelString(self.rootItems.petchanceLab2,"倍率："..self.data.basicdata.petchance2.."倍",14)


    self:setPetnum(self.data)

    for i=1,7 do
        if self.data.player1.generals[tostring(i)] then
            self.rootItems["il_root"..(i==1 and "" or "_"..(i-1))]:setVisible(true)
            -- 设置头像
            local generalData = self.data.player1.generals[tostring(i)]
            local oldcid = generalData.oldcid
            local oldconfigdata = {}
            if oldcid > 0 then
                oldconfigdata = gamedata.config.general[tostring(oldcid)]
            end
            if next(oldconfigdata) then
                ui.setIconLv(self.rootItems,{cid = self.data.player1.generals[tostring(i)].cid, level = self.data.player1.generals[tostring(i)].level1, quality = oldconfigdata.quality},i-1)
            else
                ui.setIconLv(self.rootItems,{cid = self.data.player1.generals[tostring(i)].cid, level = self.data.player1.generals[tostring(i)].level1},i-1)
            end
        else
            self.rootItems["il_root"..(i==1 and "" or "_"..(i-1))]:setVisible(false)
        end
    end

    for i=1,7 do
        if self.data.player2.generals[tostring(i)] then
            self.rootItems["il_root".."_"..(i+6)]:setVisible(true)
            -- 设置头像
            local generalData = self.data.player2.generals[tostring(i)]
            local oldcid = generalData.oldcid
            local oldconfigdata = {}
            if oldcid > 0 then
                oldconfigdata = gamedata.config.general[tostring(oldcid)]
            end
            if next(oldconfigdata) then
                ui.setIconLv(self.rootItems,{cid = self.data.player2.generals[tostring(i)].cid, level = self.data.player2.generals[tostring(i)].level1, quality = oldconfigdata.quality},i+6)
            else
                ui.setIconLv(self.rootItems,{cid = self.data.player2.generals[tostring(i)].cid, level = self.data.player2.generals[tostring(i)].level1},i+6)
            end
            self.rootItems["il_icon".."_"..(i+6)]:setScaleX(-1)
        else
            self.rootItems["il_root".."_"..(i+6)]:setVisible(false)
        end
    end

    -- UIRequest({type = 12001, cids = {self.xcid}, order=21001})

end

function servicewar_bet.setPetnum(self,data)
    ui.setLabelString(self.rootItems.petnumLab1,"押注人数："..data.basicdata.petnum1,14)
    ui.setLabelString(self.rootItems.petnumLab2,"押注人数："..data.basicdata.petnum2,14)
end


function servicewar_bet.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.battlefieldid1 = 0
    self.battlefieldid2 = 0
    self.playerdata = {}
    self.data = {}
end

return servicewar_bet