--

--
local bosschallenge = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    generalsListTableView = nil,

    generalsSelected = nil,

    generalsdata = {},
    heroboss = {},

    minlv = 0,

    normalCellSize = {x=1080,y=250},
    detailCellSize = {x=1080,y=500},

    pageconfig = {"boss","generals"},
    pagename = {"群仙屠龙","英雄挑战"},

    --selectpage = "boss",

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title2 = {357},
            },
        },
    },

    unrecycleCell = {},

    isscrolltouched = false,

    bosstime = {
        [1] = {beginT = 12*3600,endT = 12.5*3600,openTipText = "每日12:00开启"},
        [2] = {beginT = 21*3600,endT = 21.5*3600,openTipText = "每日21:00开启"},
    },
}



function bosschallenge.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("bosschallenge/bosschallenge", nil, true, "bosschallenge")

    --
    local c_bossid1 = 30001
    local c_bossconfig1 = gamedata.config.boss2[tostring(c_bossid1)]
    local c_bossName1 = gamedata.config.generalanimation[tostring(c_bossconfig1.animationid)].name
    if self.rootItems.nianshou1 then
        self.rootItems.nianshou1:setVisible(c_bossName1 == "nianshou")
    end
    --
    local c_bossid2 = 31001
    local c_bossconfig2 = gamedata.config.boss2[tostring(c_bossid2)]
    local c_bossName2 = gamedata.config.generalanimation[tostring(c_bossconfig2.animationid)].name
    if self.rootItems.nianshou2 then
        self.rootItems.nianshou2:setVisible(c_bossName2 == "nianshou")
    end
    --
    if (c_bossName1 == "nianshou") or (c_bossName2 == "nianshou") then
        self.pagename[1] = "打粘兽"
    end    
    --

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.bossNode:setPositionY(toppos-gameConfig.labelnodeheight+50)

    self.rootItems.generalsNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))

    self.generalsdata = {}

    print("self.generalsdata1",table.getTableLength(self.generalsdata))
    local tb = {}
    for k,v in pairs(table.copy(gamedata.config.heroboss)) do
        table.insert(tb,v)
    end

    table.sort(tb,function (a,b)
        return a.order < b.order
    end)

    for i,v in ipairs(tb) do
        self.generalsdata[tostring(i)] = v
    end

    print("self.generalsdata2",table.getTableLength(tb))
    printT(tb,"gamedata.config.heroboss")


    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","bosschallenge",touchbegin)
    local function touchend(pos)
        if self.rootItems.generalsNode and ui.isTouched(self.rootItems.generalsNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","bosschallenge",touchend)


    if param and param.selectpage then
        self.selectpage = param.selectpage
    elseif not self.selectpage then
        if GameScene:checkopenlevelbyId(357,true) then
            self.selectpage = "generals"
            -- if self.generalsdata["1"].level_limit and (self.generalsdata["1"].level_limit > self.minlv) then
            --     ui.sethint(self.rootItems.hint_title2,false)
            -- end     
        else
            self.selectpage = "boss"
        end
    end

    self.selectpage = self.selectpage or "boss"
    self:shiftPage(self.selectpage)

    --
    ui.setLabelString(self.rootItems.numstring,nil,14)

    --

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(-102)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)


    self.rootItems.addButton:setTouchPriority(-102)
    self.rootItems.addButton:setSwallowsTouch(true)
    self.rootItems.addButton:addHandleOfControlEvent(function()
        HeroBossBuyTimes()
    end, CCControlEventTouchUpInside)

    --boss
    self.rootItems.bossButton1:setTouchPriority(-102)
    self.rootItems.bossButton1:setSwallowsTouch(true)
    self.rootItems.bossButton1:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(21,{page = "onepage"})
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.bossButton2:setTouchPriority(-102)
    self.rootItems.bossButton2:setSwallowsTouch(true)
    self.rootItems.bossButton2:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(21,{page = "twopage"})
    end, CCControlEventTouchUpInside)

    --
    ui.setLabelString(self.rootItems.bosstimedesc1,self.bosstime[1].openTipText,14)
    ui.setLabelString(self.rootItems.bosstimedesc2,self.bosstime[2].openTipText,14)

    ui.setLabelString(self.rootItems.bosstime1,"",14)
    ui.setLabelString(self.rootItems.bosstime1,"",14)
    --time
    --
    gameTimer:rigistTime("worldbossbegintimer",99999)
    gameTimer:rigistTimeFunc("worldbossbegintimer",function()
        local nowtime = os.date("*t", gamedata:time())
        local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

        for i = 1,2 do

            if nowtimesec <= self.bosstime[i].beginT then
                ui.setLabelString(self.rootItems["bosstime"..i],"开启倒计时："..ui.makeTimeText(self.bosstime[i].beginT-nowtimesec),26)
            elseif nowtimesec >= self.bosstime[i].endT then
                ui.setLabelString(self.rootItems["bosstime"..i],"开启倒计时："..ui.makeTimeText(self.bosstime[i].beginT+86400-nowtimesec),26)
            elseif (nowtimesec > self.bosstime[i].beginT) and (nowtimesec < self.bosstime[i].endT) then
                if GameScene.layers["main"].module and GameScene.layers["main"].module.isBossOver then
                    ui.setLabelString(self.rootItems["bosstime"..i],"已被击杀！",12)
                else
                    ui.setLabelString(self.rootItems["bosstime"..i],"已经开始啦！",26)
                end
            else
                ui.setLabelString(self.rootItems["bosstime"..i],"",14)
            end

        end

        if gameTimer.times["worldbossbegintimer"] <= 0 then
            gameTimer:rigistTime("worldbossbegintimer",99999)
        end
    end)

    --
    if self.rootItems.worldboss_desc and gamedata.config.global_kv.worldboss_desc then
        ui.setLabelString(self.rootItems.worldboss_desc,gamedata.config.global_kv.worldboss_desc.value,27)
    end    


    gameTouch:clickprofbytime(1)
    UIRequest({type = 5201})

end

function bosschallenge.clear(self)

    for i = 1,20 do
        if gameTimer.times["bosstime"..i] then
            gameTimer:UnrigistTimeFunc("bosstime"..i)
        end
    end

    if gameTimer.times["bosschallengetime"] then
        gameTimer:UnrigistTimeFunc("bosschallengetime")
    end

    if gameTimer.times["worldbossbegintimer"] then
        gameTimer:UnrigistTimeFunc("worldbossbegintimer")
    end


    gameTouch:UnrigistFunc("begin","bosschallenge")
    gameTouch:UnrigistFunc("end","bosschallenge")
    self.isscrolltouched = false
    self.rootItems = nil
    self.generalsListTableView = nil

    self.generalsSelected = nil

    self.ListTableView = nil

    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}

    self.selectpage = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end



function bosschallenge.setNormal(self,item,data,index)


    item.showButton:setTouchPriority(-102)
    --item.showButton:setSwallowsTouch(true)
    item.showButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        local location
        self.generalsSelected,location = ui.tableviewLocation(
            self.generalsListTableView,
            table.getTableLength(self.generalsdata),
            index,
            self.rootItems.generalsNode,
            self.generalsSelected,
            self.detailCellSize.y,
            self.normalCellSize.y
        )
        self.generalsListTableView:reloadData()
        self.generalsListTableView:setLuaContentOffset(0,location)

    end, CCControlEventTouchUpInside)
    --
    --
    setSpriteFrameByName(item["bossname"], "bossname_"..data.icon)
    setSpriteFrameByName(item["bossicon"], "boss_"..data.icon)

    ui.setLabelString(item.needlv,"等级."..(data.level_limit or 0),21)

    ui.setLabelString(item.followstring,nil,14)
    local bossdata = self.heroboss.boss[tostring(data.id)] or {}

    if bossdata.num and bossdata.num > 0 then
        ui.setLabelString(item.num,"争夺："..(bossdata.num or 0).."人",21)
    else
        ui.setLabelString(item.num,"争夺："..(bossdata.num or 0).."人",14)
    end

    item.follow:setVisible(bossdata.follow == 1)
    item.killed:setVisible(bossdata.status == 0)
    item.enter:setVisible(bossdata.id == self.heroboss.enter)
    --
    item.followButton:setTouchPriority(-104)
    item.followButton:setSwallowsTouch(true)
    item.followButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        --
        gameTouch:clickprofbytime(1)
        if bossdata.follow == 1 then
            UIRequest({type = 5202,id = 0})
        elseif data.level_limit and (data.level_limit > self.minlv) then
            runGamePrompt({msg = "需要阵容中的全部伙伴等级达到"..data.level_limit.."级"})
        else
            UIRequest({type = 5202,id = data.id})
        end
    end, CCControlEventTouchUpInside)
    --
    item.listButton:setTouchPriority(-103)
    item.listButton:setSwallowsTouch(true)
    item.listButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        gameTouch:clickprofbytime(1)
        UIRequest({type = 5208,id = data.id})
    end, CCControlEventTouchUpInside)
    --
    item.rewardButton:setTouchPriority(-103)
    item.rewardButton:setSwallowsTouch(true)
    item.rewardButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("bosschallenge_rewardlist",{bossid = data.id},nil)
    end, CCControlEventTouchUpInside)
    --
    --
    if gameTimer.times["bosstime"..data.id] and gameTimer.times["bosstime"..data.id] > 0 then
        if bossdata.status == 1 then
            ui.setLabelString(item.time,"剩余挑战时间："..ui.makeTimeText(gameTimer.times["bosstime"..data.id]),4)
        else
            ui.setLabelString(item.time,"BOSS出现倒计时："..ui.makeTimeText(gameTimer.times["bosstime"..data.id]),12)
        end
        gameTimer:rigistTimeFunc("bosstime"..data.id,function()
            if gameTimer.times["bosstime"..data.id] <= 0 then
                gameTimer:UnrigistTimeFunc("bosstime"..data.id)
                ui.setLabelString(item.time,"",11)
--                gameTouch:clickprofbytime(1)
--                UIRequest({type = 5201})
            else
                if bossdata.status == 1 then
                    ui.setLabelString(item.time,"剩余挑战时间："..ui.makeTimeText(gameTimer.times["bosstime"..data.id]),4)
                else
                    ui.setLabelString(item.time,"BOSS出现倒计时："..ui.makeTimeText(gameTimer.times["bosstime"..data.id]),12)
                end
            end
        end)
    else
        gameTimer:UnrigistTimeFunc("bosstime"..data.id)
        ui.setLabelString(item.time,"",11)
    end

    --
    if bossdata.status == 0 then
        ui.addGray("CCSprite",item.bossbg)
        ui.addGray("CCSprite",item.bossicon)
    elseif data.level_limit and (data.level_limit > self.minlv) and not ((self.heroboss.enter > 0) and (self.heroboss.enter == data.id)) then
        ui.addGray("CCSprite",item.bossbg)
        ui.addGray("CCSprite",item.bossicon)
    else
        ui.removeGray("CCSprite",item.bossbg)
        ui.removeGray("CCSprite",item.bossicon)
    end

end

function bosschallenge.setDetail(self,item,data,index)

    ui.setLabelString(item.dropstring,"概率掉落",13)

    if self.heroboss.double and self.heroboss.double == 1 then
        ui.setLabelString(item.challengeLab,"双倍参战",19)
    else
        ui.setLabelString(item.challengeLab,"参 战",19)
    end

    local reward = ui.getIDRandNums(data.award) or {}

    for i = 1,5 do
        if item["prop"..i] then
            if reward[i] and reward[i][1] and reward[i][1] > 0 then
                local num = reward[i][2]
                if reward[i][3] and (reward[i][3] > reward[i][2]) then
                    num = reward[i][2].."~"..reward[i][3]
                end
                item["prop"..i]:setVisible(true)
                ui.setNewIcon(item,{cid = reward[i][1], num = num},i-1)
                local key_Ex = ""
                if i == 1 then
                    key_Ex = ""
                else
                    key_Ex = "_"..(i-1)
                end
                item["i_button"..key_Ex]:addHandleOfControlEvent(function()
                    ui.setPopwindowByCid(reward[i][1])
                end, CCControlEventTouchUpInside)
                item["i_button"..key_Ex]:setTouchPriority(-103)
            else
                item["prop"..i]:setVisible(false)
            end
        end
    end

    local bossdata = self.heroboss.boss[tostring(data.id)] or {}

    item.challengeButton:setTouchPriority(-103)
    item.challengeButton:setSwallowsTouch(true)

    if bossdata.status == 0 then
        ui.addGray("CCControlButton", item.challengeButton)
        item.challengeButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = "BOSS已被击杀，正在复活中..."})
        end, CCControlEventTouchUpInside)
    elseif data.level_limit and (data.level_limit > self.minlv) and not ((self.heroboss.enter > 0) and (self.heroboss.enter == data.id)) then
        ui.addGray("CCControlButton", item.challengeButton)
        item.challengeButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = "需要阵容中的全部伙伴等级达到"..data.level_limit.."级"})
        end, CCControlEventTouchUpInside)
    elseif (self.heroboss.enter > 0) and (self.heroboss.enter ~= data.id) then
        ui.addGray("CCControlButton", item.challengeButton)
        item.challengeButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = "已参加另一个BOSS的挑战"})
        end, CCControlEventTouchUpInside)
    elseif (self.heroboss.enter == 0) and (self.heroboss.challengenum < ((self.heroboss.double and self.heroboss.double == 1) and 2 or 1)) then
        ui.addGray("CCControlButton", item.challengeButton)
        item.challengeButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = "参战次数不足"})
        end, CCControlEventTouchUpInside)
    else
        ui.removeGray("CCControlButton", item.challengeButton)
        item.challengeButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            local minlv = self.minlv or 0
            GameScene:shiftLayer("bosschallenge_attack","up",{bossid = data.id, minlv = minlv})
        end, CCControlEventTouchUpInside)
    end



end


function bosschallenge.createGeneralsList(self)

    local celldict = {}
    local generalsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.generalsSelected and self.generalsSelected == a1+1 then
                r = CCSizeMake(self.detailCellSize.x, self.detailCellSize.y)
            else
                r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
            end
        elseif fn == "isRecycle" then
            if celldict[a2] then
                if celldict[a2].index then
                    if gameTimer.times["bosstime"..celldict[a2].index] then
                        gameTimer:UnrigistTimeFunc("bosstime"..celldict[a2].index)
                    end
                end           
            elseif self.unrecycleCell.detailCell then
                if self.unrecycleCell.detailCell.index then
                    if gameTimer.times["bosstime"..self.unrecycleCell.detailCell.index] then
                        gameTimer:UnrigistTimeFunc("bosstime"..self.unrecycleCell.detailCell.index)
                    end
                end
            end
            return false
        elseif fn == "cellAtIndex" then

            if self.generalsSelected and self.generalsSelected == a1+1 then
                local ccb, items,ccb1, items1
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("bosschallenge/cell_bosschallenge", nil, true, "bosschallenge")
                    ccb1, items1 =  CCBReaderLoad("bosschallenge/cell_bosschallenge2", nil, true, "bosschallenge2")

                    ccb1:setPosition(self.detailCellSize.x/2, -self.detailCellSize.y)
                    a2:addChild(ccb1)
                    ccb:setPosition(self.detailCellSize.x/2, -self.normalCellSize.y)
                    a2:addChild(ccb)

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1, index = self.generalsdata[tostring(a1+1)].id}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1
                    items1 = self.unrecycleCell.detailCell.items1
                    self.unrecycleCell.detailCell.index = self.generalsdata[tostring(a1+1)].id
                end

                self:setNormal(items,self.generalsdata[tostring(a1+1)],a1+1)
                self:setDetail(items1,self.generalsdata[tostring(a1+1)],a1+1)
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("bosschallenge/cell_bosschallenge", nil, true, "bosschallenge")
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler,index = self.generalsdata[tostring(a1+1)].id }
                    ui.tableviewAnimation(self.generalsListTableView,cellCCB,self.normalCellSize.x/2,-self.normalCellSize.y,a1)
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                    celldict[a2].index = self.generalsdata[tostring(a1+1)].id
                end

                self:setNormal(ccbDocumentControler,self.generalsdata[tostring(a1+1)],a1+1)

                if self.generalsListTableView then
                    cellCCB:setPosition(self.normalCellSize.x/2, -self.normalCellSize.y)
                end

                if first then
                    a2:addChild(cellCCB)
                end
            end
            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.generalsdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.generalsListTableView = ui.createLuaTableView({
        handle = generalsListHandle,
        viewwidth = self.rootItems.generalsNode:getContentSize().width,
        viewheight = self.rootItems.generalsNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.generalsNode:addChild(self.generalsListTableView)
    self.generalsListTableView:setTouchPriority(-101)
end


function bosschallenge.shiftPage(self,type)
    self.selectpage = type

    if self.selectpage == "boss" then
        self.rootItems["bossNode"]:setVisible(true)
        self.rootItems["bossNode"]:setPositionX(0)
        self.rootItems["generalsNode"]:setVisible(false)
        self.rootItems["generalsNode"]:setPositionX(9999)
        self.rootItems["generalsNode2"]:setVisible(false)
    else
        self.rootItems["bossNode"]:setVisible(false)
        self.rootItems["bossNode"]:setPositionX(9999)
        self.rootItems["generalsNode"]:setVisible(true)
        self.rootItems["generalsNode"]:setPositionX(0)
        self.rootItems["generalsNode2"]:setVisible(true)
    end

end

--

function bosschallenge.ReloadData(self,data)
    print("ReloadData")

    if data then
        self.heroboss = data.heroboss or {}
        self.minlv = data.minlv or 0
    end

    if self.rootItems.doubleNode then
        if self.heroboss.double and self.heroboss.double == 1 then
            self.rootItems.doublesprite:setVisible(true)
            self.rootItems.doublebutton:setTouchPriority(-102)
            self.rootItems.doublebutton:setSwallowsTouch(true)
            self.rootItems.doublebutton:addHandleOfControlEvent(function()
                if self.heroboss.enter == 0 then
                    UIRequest({type = 5211,opt = 0})
                else
                    runGamePrompt({msg = "正在挑战英雄BOSS中，无法变更双倍状态"})
                end
            end, CCControlEventTouchUpInside)
        else
            self.rootItems.doublesprite:setVisible(false)
            self.rootItems.doublebutton:setTouchPriority(-102)
            self.rootItems.doublebutton:setSwallowsTouch(true)
            self.rootItems.doublebutton:addHandleOfControlEvent(function()
                if self.heroboss.enter == 0 then
                    local viplimit = ui.getVipLevelByStr("hero_boss_double") or 0
                    if viplimit > GameScene.roleinfo.vip then
                        runGamePrompt({msg = "贵族"..viplimit.."以上可使用双倍挑战"})
                    else
                        --UIRequest({type = 5211,opt = 1})
                        gameWindows:openWindow("bosschallenge_double",nil,nil)
                    end
                else
                    runGamePrompt({msg = "正在挑战英雄BOSS中，无法变更双倍状态"})
                end
            end, CCControlEventTouchUpInside)
        end
    end

    ui.setLabelString(self.rootItems.num,(self.heroboss.challengenum > 0) and self.heroboss.challengenum or 0,21)

    if self.heroboss.time and self.heroboss.time > 0 then
        gameTimer:rigistTime("bosschallengetime",self.heroboss.time+1)
        gameTimer:rigistTimeFunc("bosschallengetime",function()
            if gameTimer.times["bosschallengetime"] <= 0 then
                gameTimer:UnrigistTimeFunc("bosschallengetime")
                ui.setLabelString(self.rootItems.time,"",14)
                gameTouch:clickprofbytime(1)
                UIRequest({type = 5201})
            else
                ui.setLabelString(self.rootItems.time,ui.makeTimeText(gameTimer.times["bosschallengetime"]).."后恢复一次",14)
            end
        end)
    else
        gameTimer:UnrigistTimeFunc("bosschallengetime")
        ui.setLabelString(self.rootItems.time,"",14)
    end
    --
    --
    for k,v in pairs(self.heroboss.boss) do
        --if v.time and v.time > 0 then
            gameTimer:rigistTime("bosstime"..v.id,v.time or 0)
        --end
    end
    --

    if self.rootItems then
        if not self.generalsListTableView then
            self:createGeneralsList()
        else
--            if self.generalsSelected then
--                self.generalsListTableView:setLuaContentOffset(0, self.generalsListTableView:getLuaContentOffsetY()+250)
--            end
--            if self.generalsListTableView:getLuaContentOffsetY() < self.rootItems.generalsNode:getContentSize().height - table.getTableLength(self.generalsdata)*self.normalCellSize.y then
--                self.generalsListTableView:setLuaContentOffset(0, self.rootItems.generalsNode:getContentSize().height - table.getTableLength(self.generalsdata)*self.normalCellSize.y)
--            end
            self.generalsListTableView:reloadData()
        end
    end
end

function bosschallenge.UIUpdateData(self, isreset)
    gameTouch:clickprofbytime(1)
    UIRequest({type = 5201})

end

return bosschallenge
�e  