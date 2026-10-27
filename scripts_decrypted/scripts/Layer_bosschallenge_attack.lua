--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/24
-- Time: 下午6:36
-- To change this template use File | Settings | File Templates.
--

local bosschallenge_attack = {

    rootNode = nil,
    rootItems = nil,

    isauto = false,

    bossid = 0,
    bosshp = 0,

    long = nil,

    realrank = {},

    ListTableView = nil,
    notifys = {},

    lastid = 0,
    minlv = 0,

    r_over = false,
}



function bosschallenge_attack.setauto(self,isauto)
    self.isauto = isauto
    self.rootItems.autosprite:setVisible(self.isauto)
end

function bosschallenge_attack.setAttackstatus(self)

    if GameScene.layers["bosschallenge_attack"].show then
        ui.addGray("CCControlButton", self.rootItems.attackbutton)
    end

    if self.heroboss.status == 1 then
        if gameTimer.times["herobossattack"] == nil or  gameTimer.times["herobossattack"] <= 0 then
            if self.isauto then
                if GameScene.herobossenter and (GameScene.herobossenter > 0) and (GameScene.herobossenter ~= self.bossid) then
                    if GameScene.layers["bosschallenge_attack"].show then
                        self:setauto(false)
                        runGamePrompt({msg = "已加入另一个BOSS的挑战"})
                        GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
                    end
                elseif GameScene.herobossdouble and GameScene.herobossdouble == 1 and GameScene.herobossenter and GameScene.herobosschallengenum and (GameScene.herobossenter == 0) and (GameScene.herobosschallengenum < 2) then
                    if GameScene.layers["bosschallenge_attack"].show then
                        self:setauto(false)
                        runGamePrompt({msg = "双倍参战次数不足"})
                        GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
                    end
                elseif GameScene.herobossenter and GameScene.herobosschallengenum and (GameScene.herobossenter == 0) and (GameScene.herobosschallengenum < 1) then
                    if GameScene.layers["bosschallenge_attack"].show then
                        self:setauto(false)
                        runGamePrompt({msg = "参战次数不足"})
                        GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
                    end
                elseif gamedata.config.heroboss[tostring(self.bossid)].level_limit and (gamedata.config.heroboss[tostring(self.bossid)].level_limit > self.minlv) and GameScene.herobossenter and (GameScene.herobossenter == 0) then
                    if GameScene.layers["bosschallenge_attack"].show then
                        self:setauto(false)
                        runGamePrompt({msg = "需要阵容中的全部伙伴等级达到"..gamedata.config.heroboss[tostring(self.bossid)].level_limit.."级"})
                        GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
                    end
                else
                    --gameTimer:rigistTime("herobossattack",5)
                    UIRequest({type = 5204, bossid = self.bossid, method = 0, isauto = self.isauto})
                end
            elseif GameScene.layers["bosschallenge_attack"].show then
                ui.removeGray("CCControlButton", self.rootItems.attackbutton)
            end
        end
    end

end


function bosschallenge_attack.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("bosschallenge/bosschallenge_attack", nil, true, "bosschallenge_attack")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((GameScene.topposY-1620)*0.3 + 1000)

    if param and param.bossid then
        self.bossid = param.bossid
    end
    if param and param.minlv then
        self.minlv = param.minlv
    end

    self:setauto(self.isauto)

    self.rootItems.autobutton:setTouchPriority(-101)
    self.rootItems.autobutton:addHandleOfControlEvent(function()
        self:setauto(not self.isauto)
        self:setAttackstatus()
    end, CCControlEventTouchUpInside)


    self.rootItems.rewardListBtn:setTouchPriority(-101)
    self.rootItems.rewardListBtn:addHandleOfControlEvent(function()
        print("rewardListBtn")
        gameWindows:openWindow("bosschallenge_rewardlist",{bossid = self.bossid},nil)
    end, CCControlEventTouchUpInside)

    self.rootItems.rulebutton:setTouchPriority(-101)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        print("rulebutton")
        gameWindows:openWindow("bosschallenge_rule",{bossid = self.bossid},nil)
    end, CCControlEventTouchUpInside)

    --
    local scale = 2.5
    local bossconfig = gamedata.config.heroboss[tostring(self.bossid)]
    local bossName = bossconfig.icon

    ui.setLabelString(self.rootItems.topNameLabel,bossconfig.name,21)
    self.rootItems.bosslv:setString(bossconfig.level_limit)

    self.rootItems.bossnode:removeAllChildrenWithCleanup(true)
    self.long = nil

    self.long = CCSkeletonAnimation:create(bossName.."/"..bossName..".json", bossName.."/"..bossName..".atlas", 1)
    self.long:setAnimation("stand",true,0)
    self.rootItems.bossnode:addChild(self.long)
    self.rootItems.bossnode:setScaleX(scale*-1)
    self.rootItems.bossnode:setScaleY(scale)
    --

    ui.setLabelString(self.rootItems.attacktext,nil,19)
    self.rootItems.attackbutton:setTouchPriority(-101)
    self.rootItems.attackbutton:addHandleOfControlEvent(function()
        print("i...attackbutton:")
        if self.heroboss.status == 1 then
            if bossconfig.level_limit and (bossconfig.level_limit > self.minlv) and GameScene.herobossenter and (GameScene.herobossenter == 0) then
                runGamePrompt({msg = "需要阵容中的全部伙伴等级达到"..bossconfig.level_limit.."级"})
                GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
            elseif GameScene.herobossenter and (GameScene.herobossenter > 0) and (GameScene.herobossenter ~= self.bossid) then
                runGamePrompt({msg = "已参加另一个BOSS的挑战"})
                GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
            elseif GameScene.herobossdouble and GameScene.herobossdouble == 1 and GameScene.herobossenter and GameScene.herobosschallengenum and (GameScene.herobossenter == 0) and (GameScene.herobosschallengenum < 2) then
                    runGamePrompt({msg = "双倍参战次数不足"})
                    GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
            elseif GameScene.herobossenter and GameScene.herobosschallengenum and (GameScene.herobossenter == 0) and (GameScene.herobosschallengenum < 1) then
                runGamePrompt({msg = "参战次数不足"})
                GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
            elseif gameTimer.times["herobossattack"] == nil or  gameTimer.times["herobossattack"] <= 0 then
                if self.isauto then
                    runGamePrompt({msg = "自动战斗中..."})
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 5204, bossid = self.bossid, method = 1, isauto = self.isauto})
                end
            else
                runGamePrompt({msg = "队伍复活中..."})
            end
        else
            runGamePrompt({msg = "BOSS已被击杀，正在复活中..."})
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.cheertext,nil,19)
    self.rootItems.cheerbutton:setTouchPriority(-101)
    self.rootItems.cheerbutton:addHandleOfControlEvent(function()
        print("i...cheerbutton:")
        gameTouch:clickprofbytime(0.5)
        if self.heroboss.status == 1 then
            if self.heroboss and self.heroboss.attackcount and self.heroboss.attackcount > 0 then
                gameWindows:openWindow("bosschallenge_cheer",{cheernum = self.heroboss.bosslevel})
            else
                runGamePrompt({msg = "需先参与本次BOSS挑战"})
            end
        else
            runGamePrompt({msg = "BOSS已被击杀，正在复活中..."})
        end
    end, CCControlEventTouchUpInside)

    --
    self.rootItems.backButton:setTouchPriority(-101)
    self.rootItems.backButton:addHandleOfControlEvent(function()
        print("i...backButton:")
        gameTouch:clickprofbytime(1)
        GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
    end, CCControlEventTouchUpInside)
    --

    ui.setLabelString(self.rootItems.damage_text,nil,21)
    ui.setLabelString(self.rootItems.name_text,nil,21)
    ui.setLabelString(self.rootItems.atkrank_text,nil,21)
    ui.setLabelString(self.rootItems.reliveCD_text,nil,21)
    ui.setLabelString(self.rootItems.reliveCD," ",3)
    ui.setLabelString(self.rootItems.attackcd_text,nil,21)
    ui.setLabelString(self.rootItems.attackcd," ",3)
    ui.setLabelString(self.rootItems.string1,nil,14)
    ui.setLabelString(self.rootItems.string2,nil,14)
    ui.setLabelString(self.rootItems.string3,nil,14)
    ui.setLabelString(self.rootItems.myrankstring,nil,14)
    ui.setLabelString(self.rootItems.rankdesc,nil,14)
    ui.setLabelString(self.rootItems.overCD_text,nil,21)


    --auto
    if GameScene.herobossenter and GameScene.herobossenter ~= self.bossid then
        self:setauto(true)
    end
    --
    gameTouch:clickprofbytime(1)
    UIRequest({type = 5203,id = self.bossid})

end

function bosschallenge_attack.reloaddata(self,data)

    if data and data.heroboss then
        self.heroboss = data.heroboss
    end
end

function bosschallenge_attack.reloadstatus(self,data)

    if data and data.heroboss then
        self.heroboss = data.heroboss
    end

    if self.rootItems.doubleLabel then
        if GameScene.herobossdouble and GameScene.herobossdouble == 1 then
            ui.setLabelString(self.rootItems.doubleLabel,"双倍挑战",11)
        else
            ui.setLabelString(self.rootItems.doubleLabel,"",11)
        end
    end

    if self.heroboss.status == 0 then
        self.rootItems.bloodnode:setVisible(false)
        self.rootItems.bossdeadnode:setVisible(true)
        self.rootItems.bossovernode:setVisible(false)
        self:setstarttimer()
        self:stoptnotify()
        --
        if gameWindows.windows["bosschallenge_cheer"].show then
            gameWindows:closeWindowDirect("bosschallenge_cheer")
        end
        --
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
            if (not self.r_over) and not (battleScene and battleScene.show) then
                self.r_over = true
                gameTouch:clickprofbytime(2)
                runGamePrompt({msg = "本次挑战已结束，请前往邮件查收奖励"})
                self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2),CCCallFunc:create(function()
                    GameScene:shiftLayer("bosschallenge","up",{selectpage = "generals"})
                end)))
            end
        end)))
    elseif self.heroboss.status == 1 then
        self.rootItems.bloodnode:setVisible(true)
        self.rootItems.bossdeadnode:setVisible(false)
        self:startnotify()
        self:setovertimer()
    end
    self:setBattle()
    self:setattackCD()
    UIRequest({type = 5206,id = self.bossid})
end

function bosschallenge_attack.setstarttimer(self)

    if gameTimer.times["herobosstime"] and gameTimer.times["herobosstime"] > 0 then
        ui.setLabelString(self.rootItems.reliveCD,ui.makeTimeText(gameTimer.times["herobosstime"]),3)
        gameTimer:rigistTimeFunc("herobosstime",function()
            if GameScene.layers["bosschallenge_attack"].show then
                if gameTimer.times["herobosstime"] <= 0 then
                    gameTimer:UnrigistTimeFunc("herobosstime")
                    ui.setLabelString(self.rootItems.reliveCD,"",3)
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 5201})
                    UIRequest({type = 5203,id = self.bossid})
                else
                    ui.setLabelString(self.rootItems.reliveCD,ui.makeTimeText(gameTimer.times["herobosstime"]),3)
                end
            end
        end)
    else
        gameTimer:UnrigistTimeFunc("herobosstime")
        ui.setLabelString(self.rootItems.reliveCD,"",3)
    end
end

function bosschallenge_attack.setovertimer(self)

    if gameTimer.times["herobossovertime"] and gameTimer.times["herobossovertime"] > 0 then
        ui.setLabelString(self.rootItems.overCD,ui.makeTimeText(gameTimer.times["herobossovertime"]),3)
        self.rootItems.bossovernode:setVisible(true)
        gameTimer:rigistTimeFunc("herobossovertime",function()
            if GameScene.layers["bosschallenge_attack"].show then
                if gameTimer.times["herobossovertime"] <= 0 then
                    gameTimer:UnrigistTimeFunc("herobossovertime")
                    ui.setLabelString(self.rootItems.overCD,"",3)
                    gameTouch:clickprofbytime(1)
                    --UIRequest({type = 5201})
                    UIRequest({type = 5203,id = self.bossid})
                else
                    ui.setLabelString(self.rootItems.overCD,ui.makeTimeText(gameTimer.times["herobossovertime"]),3)
                end
            end
        end)
    else
        self.rootItems.bossovernode:setVisible(false)
        gameTimer:UnrigistTimeFunc("herobossovertime")
        ui.setLabelString(self.rootItems.overCD,"",3)
    end
end

function bosschallenge_attack.setBattle(self,data)

    if data and data.heroboss then
        self.heroboss = data.heroboss
    end

    self:setbosshp()

    ui.setLabelString(self.rootItems.attacktime,self.heroboss.attackcount,22)
    ui.setLabelString(self.rootItems.damage,self.heroboss.damagesum,22)

    if self.heroboss.status == 0 then
        self:bosskilled()
    end

end


function bosschallenge_attack.setbosshp(self,hp)
    if hp and self.heroboss and next(self.heroboss) then 
        self.heroboss.bosshp = hp
    end

    if self.heroboss and next(self.heroboss) then
        ui.setLabelString(self.rootItems.bossblood,(self.heroboss.bosshp or 0).." %",13)
        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar,0,0,1008 * (self.heroboss.bosshp or 0) / 100,41)
    else
        ui.setLabelString(self.rootItems.bossblood, "0".." %",13)
        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar,0,0,1008 * 0 / 100,41)
    end
end


function bosschallenge_attack.setattackCD(self,cd)

    if self.heroboss.status == 1 then
        if gameTimer.times["herobossattack"] and gameTimer.times["herobossattack"] > 0 then
            ui.setLabelString(self.rootItems.attackcd,gameTimer.times["herobossattack"].."s",3)
            self.rootItems.attackcdnode:setVisible(true)
            self:setAttackstatus()
            gameTimer:rigistTimeFunc("herobossattack",function()
                if gameTimer.times["herobossattack"] <= 0 then
                    if GameScene.layers["bosschallenge_attack"].show then
                        self.rootItems.attackcdnode:setVisible(false)
                    end
                    --
                    self:setAttackstatus()
                elseif GameScene.layers["bosschallenge_attack"].show then
                    ui.setLabelString(self.rootItems.attackcd,gameTimer.times["herobossattack"].."s",3)
                end
            end)
        else
            self.rootItems.attackcdnode:setVisible(false)
            self:setAttackstatus()
        end
    else
        self.rootItems.attackcdnode:setVisible(false)
        self:setAttackstatus()
    end

end


function bosschallenge_attack.startnotify(self)
    gameTimer:rigistTime("herobossnotify",4000)

    gameTimer:rigistTimeFunc("herobossnotify",function()
        self:showOneNotify()

        if math.mod(gameTimer.times["herobossnotify"],5) ==0 then
            UIRequest({type = 5206,id = self.bossid})
        end

        if gameTimer.times["herobossnotify"] <= 0 then
            gameTimer:rigistTime("herobossnotify",4000)
        end

    end)
end

function bosschallenge_attack.stoptnotify(self)

    gameTimer:UnrigistTimeFunc("herobossnotify")
end




function bosschallenge_attack.setrealrank(self,data)
    if data then
        self.realrank = data
    end

    ui.setLabelString(self.rootItems.myrankLabel,"未进榜",14)
    for k,v in pairs(self.realrank) do
        if tonumber(v.rid) == tonumber(GameScene.roleinfo.id) then
            ui.setLabelString(self.rootItems.myrankLabel,tostring(k),22)
            break
        end
    end

    if not self.ListTableView then
        self:createRankList()
    else
        self.ListTableView:reloadData()
        self.ListTableView:setLuaContentOffset(0, self.rootItems.rankscroll:getContentSize().height - table.getTableLength(self.realrank)*60)
    end
end

function bosschallenge_attack.createRankList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1000, 60)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("bosschallenge/cell_bosschallenge_paiming", nil, true, "cell_bosschallenge_paiming")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            local itemdata = self.realrank[tostring(a1+1)]

            if tonumber(itemdata.rid) == tonumber(GameScene.roleinfo.id) then
                ccbDocumentControler.myrankNode:setVisible(true)
            else
                ccbDocumentControler.myrankNode:setVisible(false)
            end

            ccbDocumentControler.rankNumLabel:setString(a1+1)
            ccbDocumentControler.rankNameLabel:setString(itemdata.name)
            ccbDocumentControler.rankDamageLabel:setString(itemdata.param)

            cellCCB:setPosition(1000/2,60/2)
            if not self.CellSize then
                self.CellSize = cellCCB:getContentSize()
            end

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.realrank)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.rankscroll:getContentSize().width,
        viewheight = self.rootItems.rankscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.rankscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


function bosschallenge_attack.reloadnotify(self,data)
    self.notifys = data or {}

end

function bosschallenge_attack.showOneNotify(self)
    local data = nil
    local index = 0
    if not self.notifys or not next(self.notifys) then
        return
    else
        for k,v in pairs(self.notifys) do
            index = k
            data = v
            break
        end
    end
    if self.lastid == data.id then return end
    self.lastid = data.id

    data.method = 0
    local ccbconfig = {
        [0] = "attck"..math.random(1,7),
        [2] = "attck_fuhuo",
        [10] = "attck_yuhuo",
    }

    local ccb,item = CCBReaderLoad("worldboss2/"..ccbconfig[data.method]..".ccbi", nil, true, ccbconfig[data.method])
    ccb:setPosition(ccp(math.random(1,400),math.random(1,400)))
    ccb:setScale(1.5)
    self.rootItems.damagenode:addChild(ccb)
    item.damage:setString(data.damage)
    ui.setLabelString(item.name,data.rname,1)

    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("Default Timeline")

    local red = CCTintTo:create(0.2,255,0,0)
    local back = CCTintTo:create(0.3,255,255,255)
    local sq = CCSequence:createWithTwoActions(red,back)
    self.long:runAction(sq)
    if data.kill and data.kill ~= 0 then
        self:bosskilled()
    end

    self.notifys[index] = nil
end


function bosschallenge_attack.bosskilled(self)

    self:stoptnotify()
    self.notifys = {}

end

function bosschallenge_attack.changedata(self)

    gameTouch:clickprofbytime(1)
    UIRequest({type = 5203,id = self.bossid})

end


function bosschallenge_attack.clear(self)

    gameTimer:UnrigistTimeFunc("herobossovertime")
    gameTimer:UnrigistTimeFunc("herobosstime")
    --gameTimer:UnrigistTimeFunc("herobossattack")
    gameTimer:UnrigistTimeFunc("herobossnotify")


    self.r_over = false
    self.long = nil
    self.realrank = {}
    self.notifys = {}

    self.ListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end



return bosschallenge_attack   �S  