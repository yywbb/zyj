--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/24
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--

local soul = {

    resource = nil,


    rootNode = nil,
    rootItems = nil,

    pageconfig = {"hunt","list","exchange" } ,
    -- pagename = {"猎 命","命 格","兑 换",},
    pagename = {gameConfig.strings:string_common("soul",0),gameConfig.strings:string_common("soul",1),gameConfig.strings:string_common("soul",2),},
    selectpage = "hunt",

    listpageconfig = {"all","star2","star3","star4","star5",},
    listpageselect = "all",
    listshowData = {},
    listallData = {},
    liststar2Data = {},
    liststar3Data = {},
    liststar4Data = {},
    liststar5Data = {},

    huntget = false,
    ListTableView = nil,
    exchangeTableView = nil,
    huntlistView = nil,

    CellSize = {x=1080,y=242},

    huntData = {},

    exchangeData = {},

    oncedata = {},
    addedget = {},

    priorStatus = 0,

    mainstatus = 15,

    attr_type ={
        hp = 5,
        subdmg = 4,
        adddmg = 3,
        def = 2,
        atk = 1,
    },

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {9},
            },
        },
    },
    soulCellData = {    --保存每种等级出的魂魄等级
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {},
        [5] = {},
        [6] = {}
    },

    General = nil,
    isscrolltouched = false,
    systemId = 9,
    itemNum = 0,
}

function soul.makeexchangelist(self)
    if next(self.exchangeData) then return end
    for k, v in pairs(gamedata.config.soul_exchange) do
        table.insert(self.exchangeData,table.merge(gamedata.config.soul[tostring(k)],{exchangenum = v.num}))
    end
    ui.sortData(self.exchangeData,"quality")
end

function soul.shiftPage(self,type)
    self.selectpage = type

    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPosition(0,0)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPosition(9999,0)
        end
    end

    if type == "hunt" then

    elseif type == "list" then
        if not GameScene:checkUpdate(10026) then
            self:shiftListPage(self.listpageselect)
        end
    end

    -- if type == "list" and self.listpageselect == "all" then
    --     local soulnum = table.getTableLength(self.listshowData)
    --     if soulnum>gameConfig.bagLimit_soul then
    --         -- runGamePrompt({msg="您的命格已超过"..gameConfig.bagLimit_soul.."件，请及时处理。"})
    --         runGamePrompt({msg=gameConfig.strings:soulUp(gameConfig.bagLimit_soul)})
    --     end
    -- end
    if type == "exchange" then
        if self.exchangeTableView then
            self.exchangeTableView:reloadData()
        end
    end
end

function soul.shiftListPage(self,type)
    type = type or self.listpageselect
    self.listpageselect = type
    self.listshowData =  self["list"..type.."Data"]

    if (not GameScene:checkUpdate(10026,"all")) and (not GameScene:checkUpdate(10026,type)) then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:setLuaContentOffset(0, self.rootItems.listscroll:getContentSize().height - table.getTableLength(self.listshowData)*self.CellSize.y)
            self.ListTableView:reloadData()
        end
    end

    for k,v in ipairs(self.listpageconfig) do
        if v == type then
            self.rootItems[v.."Onbg"]:setVisible(true)
            self.rootItems[v.."Onpoint"]:setVisible(true)
        else
            self.rootItems[v.."Onbg"]:setVisible(false)
            self.rootItems[v.."Onpoint"]:setVisible(false)
        end
    end
end

function soul.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("soul2/soul2", nil, true, "soul")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.toptitle:setPositionY(toppos)
    self.rootItems.listtopnode:setPositionY(toppos)
    self.rootItems.extopnode:setPositionY(toppos)

    self.rootItems.huntmid1:setPositionY((GameScene.topposY-1620)*0.3-200)
    self.rootItems.huntmid2:setPositionY((GameScene.topposY-1620)*0.3-200)
    self.rootItems.huntmid_top:setPositionY(toppos)
    self.rootItems.generalNode:setPositionY((GameScene.topposY-1620)*0.3-200+1140)
    self.rootItems.generalEffectNode:setPositionY((GameScene.topposY-1620)*0.3-200+1100)

    self.rootItems.huntlistScroll:setContentSize(CCSizeMake(980,320))

    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    self.General = CCSkeletonAnimation:create("houyi/houyi.json","houyi/houyi.atlas",1) -- houyi
    self.General:setAnimation("stand",true,0)
    self.General:setScale(1.2)
    self.General:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(self.General)

    self.rootItems.listscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-130))
    self.rootItems.exchangescroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))

    self.rootItems.huntstatusNode:removeAllChildrenWithCleanup(true)
    self.statusNode,self.statusItems = CCBReaderLoad("soul2/soul2_zhuan", nil, true, "soul_zhuan")
    self.statusNode:setPosition(0,0)
    self.rootItems.huntstatusNode:addChild(self.statusNode)

    self.rootItems.gotoEquipBtn:setSwallowsTouch(true)
    self.rootItems.gotoEquipBtn:setTouchPriority(-101)
    self.rootItems.gotoEquipBtn:addHandleOfControlEvent(function()
        print("去阵容猎命页面")
        GameScene:shiftLayerById(5)
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.itemLab,gameConfig.strings:string_common("fixedString","shop",27),18)
    ui.setLabelString(self.rootItems.listLab,gameConfig.strings:string_common("fixedString","shop",22),18)
    self.rootItems.haveFixedText:setString(gameConfig.strings:string_common("fixedString","shop",8,11))

    for i=1,5 do
        ui.setLabelString(self.statusItems["zhuanLab"..i],gameConfig.strings:string_common("soulName",i),2*i)
    end

    ui.setLabelString(self.rootItems.text1,nil,14)
    ui.setLabelString(self.rootItems.text2,nil,14)
    ui.setLabelString(self.rootItems.text3,nil,14)
    self.rootItems.goldhunteffectnode:setVisible(false)
    self.rootItems.coinhunteffectnode:setVisible(true)
    self:makeSoulCellData()

    --
    if self.rootItems.listLab and self.rootItems.listButton then
        ui.setLabelString(self.rootItems.listLab,nil,18)
        self.rootItems.listButton:setTouchPriority(-101)
        self.rootItems.listButton:setSwallowsTouch(true)
        self.rootItems.listButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            gameWindows:openWindow("turntablerecord",{systemId = self.systemId},nil)
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.buyItem:setTouchPriority(-101)
    self.rootItems.buyItem:setSwallowsTouch(true)
    self.rootItems.buyItem:addHandleOfControlEvent(function()

        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
            if data.id == self.itemId then
                self:setItemNum({[tostring(data.id)] = data.num})
            end
        end)

    end, CCControlEventTouchUpInside)
    --

    for k,v in ipairs(self.listpageconfig) do
        self.rootItems[v.."Button"]:setTouchPriority(-110)
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            self:shiftListPage(v)
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.to15:setTouchPriority(-101)
    self.rootItems.to15:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        self:shiftmainStatus(15)
    end, CCControlEventTouchUpInside)
    self.rootItems.to6:setTouchPriority(-101)
    self.rootItems.to6:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        self:shiftmainStatus(6)
    end, CCControlEventTouchUpInside)

    self.rootItems.introduceButton:setSwallowsTouch(true)
    self.rootItems.introduceButton:setTouchPriority(-121)
    self.rootItems.introduceButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("soulIntroduction",nil,nil)
    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.resolvetext,"批量分解",18)
    ui.setLabelString(self.rootItems.resolvetext,gameConfig.strings:string_common("soul",3),18)
    self.rootItems.resolveButton:setTouchPriority(-110)
    self.rootItems.resolveButton:setSwallowsTouch(true)
    self.rootItems.resolveButton:addHandleOfControlEvent(function()
        if not next(self.listallData) then
            -- runGamePrompt({msg="无命格可分解"})
            runGamePrompt({msg=gameConfig.strings:string_common("soul",4)})
        else
            GameScene:shiftLayer("soulResolveList","up",{souls=self.listallData})
        end

    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.hunt1Text,"猎 命",18)
    ui.setLabelString(self.rootItems.hunt1Text,gameConfig.strings:string_common("soul",0),18)
    self.rootItems.hunt1:setTouchPriority(-101)
    self.rootItems.hunt1:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.mainstatus == 15 then
            --if gameTimer.times["soulTimer"..self.huntData.hunt] and gameTimer.times["soulTimer"..self.huntData.hunt] > 0 then
                UIRequest({type = 2502, param = 1, isfree = false})
--            else
--                UIRequest({type = 2502, param = 1, isfree = true})
--            end
        elseif self.mainstatus == 6 then
            if self.itemFCNum > self.itemNum then
                gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                    if data.id == self.itemId then
                        self:setItemNum({[tostring(data.id)] = data.num})
                    end
                end)
            else
                gameTouch:clickprofbytime(1)
                UIRequest({type = 2502, param = 6,useId = self.itemId,useNum = self.itemFCNum})
            end
        end
    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.hunt10Text,"快速猎命",18)
    ui.setLabelString(self.rootItems.hunt10Text,gameConfig.strings:string_common("soul",17),18)
    self.rootItems.hunt10:setTouchPriority(-101)
    self.rootItems.hunt10:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --
        local config = gamedata.config.soul_hunt
        if self.mainstatus == 15 then
            gameWindows:openWindow("soulfast",{hunt = 1, xnum = config[tostring(self.huntData.hunt)].coin},nil)
        elseif self.mainstatus == 6 then
            gameWindows:openWindow("soulfast",{hunt = 6, xnum = 100},nil)
        end

    end, CCControlEventTouchUpInside)

    --概率说明
    self.rootItems.ruleBtn:setTouchPriority(-101)
    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --
        ui.popCommonRule(9)
    end, CCControlEventTouchUpInside)

    self:makeexchangelist()

    if param and param.page then self.selectpage =  param.page end
    self:shiftPage(self.selectpage)
    self:shiftmainStatus(self.mainstatus,true)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","soul",touchbegin)
    local function touchend(pos)
        if self.rootItems.exchangescroll and ui.isTouched(self.rootItems.exchangescroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listscroll and ui.isTouched(self.rootItems.listscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","soul",touchend)

    UIRequest({type = 2501})
    self:requestItemNum()

    guide.controller:addComplete(9,function()
        UIRequest({type = 2882,opt=1,sysID=9})
    end)
end

function soul.requestItemNum(self)
    if not self.itemId then
        local config = gamedata.config.gambling_items[tostring(self.systemId)]["1"]
        if config then
            
            local id,num = ui.getIDandNUM(config.once2)
            self.itemId = id
            self.itemFCNum = num
        end
    end
    if self.itemId then
        UIRequest({type = 12001, order = 33007, cids = {self.itemId}})
    end
end

function soul.setItemNum(self,itemNum)
    if itemNum[tostring(self.itemId)] then
        self.itemNum = itemNum[tostring(self.itemId)] or 0
        if self.rootItems then
            self.rootItems.haveFixedNum:setString(tostring(self.itemNum))
            ui.setLabelString(self.rootItems.hunt1consumNum2,self.itemFCNum,self.itemNum < self.itemFCNum and 24 or 13)
        end
    end
end

function soul.setlistCell(self,items,data)

    ui.setIconLv(items,data)
    local configdata =  gamedata.config.soul[tostring(data.cid)]
    ui.setLabelString(items.name,configdata.name, configdata.quality and 2*configdata.quality-1 or 1)

    if data.generalcid and data.generalcid > 0 then
        -- if gamedata.config.general[tostring(data.generalcid)].name == "主角" then
        --     items.generalname:setString("装备于: "..GameScene.roleinfo.name)
        -- else
        --     items.generalname:setString("装备于: "..gamedata.config.general[tostring(data.generalcid)].name)
        -- end
        if gamedata.config.general[tostring(data.generalcid)].name == gameConfig.strings:string_common("soul",6) then
            items.generalname:setString(gameConfig.strings:equipName(GameScene.roleinfo.name))
        else
            items.generalname:setString(gameConfig.strings:equipName(gamedata.config.general[tostring(data.generalcid)].name))
        end
        items.notOn:setVisible(false)
    else
        items.generalname:setString("")
        items.notOn:setVisible(true)
    end

    ui.setSoulPromote(items["att1"],items["att2"],data)

    items.il_button:setTouchPriority(-102)
    items.il_button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        print("iconButton clicked")
        gameWindows:openWindow("soulInfo",table.merge(data,{fromtype = "soullist",pagetype = "info"}) )
    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(items.buttontext1,"强 化",18)
    ui.setLabelString(items.buttontext1,gameConfig.strings:string_common("soul",7),18)
    items.button1:setTouchPriority(-102)
    items.button1:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        print("strengthenButton clicked")
        gameWindows:openWindow("soulInfo",table.merge(data,{fromtype = "soullist",pagetype = "up"}) )
    end, CCControlEventTouchUpInside)

    --
    ui.setLabelString(items.buttontext2,gameConfig.strings:string_common("buttontext","hecheng"),18)
    if gameConfig:checkBuildOpen(255) and GameScene:checkopenlevelbyId(255,true) and configdata.relation and configdata.relation > 0 then
        items.buttonnode2:setVisible(true)
        items.button2:setTouchPriority(-102)
        local integrateconfig = gamedata.config.soul_integrate and gamedata.config.soul_integrate[tostring(configdata.relation)] or {}
        if data.level < integrateconfig.cond then
            ui.addGray("CCControlButton",items.button2)
            items.button2:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                if not self.isscrolltouched then return end
                --runGamePrompt({msg="该命格未达到"..integrateconfig.cond.."级"})
                runGamePrompt({msg=gameConfig.strings:need_soul_lv(integrateconfig.cond)})
            end, CCControlEventTouchUpInside)
        elseif not (data.generalcid and data.generalcid > 0) then
            ui.addGray("CCControlButton",items.button2)
            items.button2:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                if not self.isscrolltouched then return end
                --runGamePrompt({msg="该命格未装备"})
                runGamePrompt({msg=gameConfig.strings:string_common("soul",15)})
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",items.button2)
            items.button2:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                if not self.isscrolltouched then return end
                gameWindows:openWindow("soulintegrate",{data = table.copy(data),allData = table.copy(self.listallData)})
            end, CCControlEventTouchUpInside)
        end
    else
        items.buttonnode2:setVisible(false)
    end

end

function soul.setexchangeCell(self,configdata,items)

    ui.setIconLv(items,{cid = configdata.id})
    --
    items.il_button:setTouchPriority(-104)
    items.il_button:setSwallowsTouch(true)
    items.il_button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end        
        ui.setPopwindowByCid(configdata.id)
    end, CCControlEventTouchUpInside)
    --
    ui.setLabelString(items.name,configdata.name, configdata.quality and 2*configdata.quality-1 or 1)

    ui.setSoulPromote(items["att1"],items["att2"],{cid = configdata.id})

    items.selectButton:setTouchPriority(-102)

    -- items.exchangenum:setString(configdata.exchangenum)
    ui.setLabelString(items.exchangenum,configdata.exchangenum,22)

    -- ui.setLabelString(items.selecttext,"兑 换",18)
    ui.setLabelString(items.selecttext,gameConfig.strings:string_common("soul",8),18)
    if configdata.exchangenum > self.huntData.soul then
        -- ui.addGray("CCControlButton",items.selectButton)
        -- ui.addGray("CCLabelTTF",items.selecttext)
        ui.setLabelString(items.exchangenum,nil,24)
        items.selectButton:addHandleOfControlEvent(function()
             -- runGamePrompt({msg = "元命不足"})
            if gameTouch.isScrollling then return end
            if not self.isscrolltouched then return end             
            runGamePrompt({msg = gameConfig.strings:string_common("soul",9)})
        end, CCControlEventTouchUpInside)
    else
        -- ui.removeGray("CCControlButton",items.selectButton)
        -- ui.removeGray("CCLabelTTF",items.selecttext)
        items.selectButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            if not self.isscrolltouched then return end
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 2503, ids = {configdata.id}})
        end, CCControlEventTouchUpInside)
    end
end

function soul.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("soul/cell_soul", nil, true, "cell_soul")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.ListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setlistCell(ccbDocumentControler,self.listshowData[tostring(a1+1)])

            if self.ListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.listshowData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

function soul.createexchange(self)
    local celldict = {}
    local exchangeListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("soul/cell_exchange", nil, true, "cell_exchange")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setexchangeCell(self.exchangeData[a1+1],ccbDocumentControler)

            cellCCB:setPosition(self.CellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.exchangeData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.exchangeTableView = ui.createLuaTableView({
        handle = exchangeListHandle,
        viewwidth = self.rootItems.exchangescroll:getContentSize().width,
        viewheight = self.rootItems.exchangescroll:getContentSize().height,
        dire = 1
    })
    self.exchangeTableView:setTouchPriority(-101)
    self.rootItems.exchangescroll:addChild(self.exchangeTableView)
end

function soul.setIcon(self,item,data)
    --setSpriteFrameByName(item["s_kuang"], "b_iconk"..(data.quality and data.quality>1 and data.quality or 1))
    --setSpriteFrameByName(item["s_quality"], "b_iconbg"..(data.quality and data.quality>1 and data.quality or 1))

    item["s_soulnode"]:removeAllChildrenWithCleanup(true)
    setSpriteFrameByName(item["s_icon"], "alpha")
    if data.staffType =="soul" then
        local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..data.icon..".ccbi", nil, true, data.icon)
        item["s_soulnode"]:addChild(ccb)
    elseif data.staffType =="yuanming" then
        setSpriteFrameByName(item["s_icon"], data.icon)
    end
    ui.setLabelString(item.s_name,data.name, data.quality and 2*data.quality-1 or 1)
end

function soul.makeHuntAnimation(self,hunt)

    local animationManager = getAnimationManager(self.statusItems)
    if self.priorStatus == 0 then
        animationManager:setAnimationCompletedCallback(function()
            --gameTouch:setClickProf(false)
        end)
        animationManager:runAnimationsForSequenceNamed(tostring(hunt))
    elseif  hunt == 1 then
        animationManager:setAnimationCompletedCallback(function()
            animationManager:runAnimationsForSequenceNamed(tostring(hunt))
            --gameTouch:setClickProf(false)
        end)
        animationManager:runAnimationsForSequenceNamed(self.priorStatus.."-1")
    elseif hunt > self.priorStatus then
        local index =  self.priorStatus
        local function onestep()
            if index >= hunt then
                animationManager:runAnimationsForSequenceNamed(tostring(hunt))
                --gameTouch:setClickProf(false)
                return
            else
                index = index +1
                animationManager:setAnimationCompletedCallback(function()
                    onestep()
                end)
                animationManager:runAnimationsForSequenceNamed((index-1).."-"..index)
            end
        end
        onestep()
    else
        animationManager:setAnimationCompletedCallback(function()
            local index =  1
            local function onestep()
                if index >= hunt then
                    animationManager:runAnimationsForSequenceNamed(tostring(hunt))
                    --gameTouch:setClickProf(false)
                    return
                else
                    index = index +1
                    animationManager:setAnimationCompletedCallback(function()
                        onestep()
                    end)
                    animationManager:runAnimationsForSequenceNamed((index-1).."-"..index)
                end
            end
            onestep()
        end)
        animationManager:runAnimationsForSequenceNamed(self.priorStatus.."-1")
    end

end

function soul.shiftmainStatus(self,status,isfirst)
    if status and status == 6 then
        self.rootItems.huntmid1:setVisible(false)
        self.rootItems.huntmid2:setVisible(true)
        self.rootItems.newtext:setString("灵石猎命每次奖励一个元命");
        self.rootItems.goldhunteffectnode:setVisible(true)
        self.rootItems.coinhunteffectnode:setVisible(false)
        self.rootItems.no15:setVisible(true)
        self.rootItems.no6:setVisible(false)
        self.rootItems.reListNode:setVisible(true)
        self.rootItems.buyItemNode:setVisible(true)
        self.rootItems.haveNode:setVisible(true)
    else
        self.rootItems.huntmid1:setVisible(true)
        self.rootItems.huntmid2:setVisible(false)
        self.rootItems.newtext:setString("");
        self.rootItems.goldhunteffectnode:setVisible(false)
        self.rootItems.coinhunteffectnode:setVisible(true)
        self.rootItems.no15:setVisible(false)
        self.rootItems.no6:setVisible(true)
        self.rootItems.reListNode:setVisible(false)
        self.rootItems.buyItemNode:setVisible(false)
        self.rootItems.haveNode:setVisible(false)
    end

    if self.mainstatus == status then return end
    self.mainstatus = status

    self:setStatus()
end

function soul.setConsum(self)
    local config = gamedata.config.soul_hunt
    if self.mainstatus == 6 then
        --ui.setLabelString(self.rootItems.cd,"",13)
        self.rootItems.hunt1consum2:setVisible(true)
        ui.setLabelString(self.rootItems.hunt1consumNum2,self.itemFCNum,self.itemNum < self.itemFCNum and 24 or 13)
        ui.setLabelString(self.rootItems.hunt1consumNum1,config[tostring(6)].coin,GameScene.roleinfo.coin < config[tostring(6)].coin and 24 or 13)

        --setSpriteFrameByName(self.rootItems.hunt10consumSprite, "obj_s_gold")
        --ui.setLabelString(self.rootItems.hunt10consumNum,"1000",GameScene.roleinfo.gold < 1000 and 24 or 13)
        -- if GameScene.roleinfo.coin < config[tostring(6)].coin or GameScene.roleinfo.gold < 100 then
        --     ui.addGray("CCControlButton",self.rootItems.hunt1)
        -- else
        --     ui.removeGray("CCControlButton",self.rootItems.hunt1)
        -- end

        -- if GameScene.roleinfo.gold < 1000 then
        --     ui.addGray("CCControlButton",self.rootItems.hunt10)
        -- else
        --     ui.removeGray("CCControlButton",self.rootItems.hunt10)
        -- end

    elseif self.mainstatus == 15 then
        self.rootItems.hunt1consum2:setVisible(false)

        --if gameTimer.times["soulTimer"..self.huntData.hunt] and gameTimer.times["soulTimer"..self.huntData.hunt] > 0 then
        --    ui.setLabelString(self.rootItems.cd,ui.makeTimeText(gameTimer.times["soulTimer"..self.huntData.hunt],"hour"),13)
            ui.setLabelString(self.rootItems.hunt1consumNum1,config[tostring(self.huntData.hunt)].coin,GameScene.roleinfo.coin < config[tostring(self.huntData.hunt)].coin and 24 or 13)

        --    gameTimer:rigistTimeFunc("soulTimer"..self.huntData.hunt,function()
        --        if self.mainstatus == 6 then return end
        --        if  gameTimer.times["soulTimer"..self.huntData.hunt] == 0 then
        --            ui.setLabelString(self.rootItems.cd,"",13)
        --            ui.setLabelString(self.rootItems.hunt1consumNum1,"0",13)
        --        else
        --            ui.setLabelString(self.rootItems.cd,ui.makeTimeText(gameTimer.times["soulTimer"..self.huntData.hunt],"hour"),13)
        --        end
        --    end)
        --else
        --    ui.setLabelString(self.rootItems.cd,"",13)
            --ui.setLabelString(self.rootItems.hunt1consumNum1,"0",13)
            -- ui.setLabelString(self.rootItems.hunt1consumNum1,"本次免费",13);
        --    ui.setLabelString(self.rootItems.hunt1consumNum1,gameConfig.strings:string_common("soul",10),13);
        --end

        --setSpriteFrameByName(self.rootItems.hunt10consumSprite, "obj_s_coin")
        --ui.setLabelString(self.rootItems.hunt10consumNum,config[tostring(self.huntData.hunt)].coin*10,GameScene.roleinfo.coin < config[tostring(self.huntData.hunt)].coin*10 and 24 or 13)

        -- if GameScene.roleinfo.coin < config[tostring(self.huntData.hunt)].coin then
        --     ui.addGray("CCControlButton",self.rootItems.hunt1)
        -- else
        --     ui.removeGray("CCControlButton",self.rootItems.hunt1)
        -- end

        -- if GameScene.roleinfo.coin < config[tostring(self.huntData.hunt)].coin*10 then
        --     ui.addGray("CCControlButton",self.rootItems.hunt10)
        -- else
        --     ui.removeGray("CCControlButton",self.rootItems.hunt10)
        -- end
    end
end

function soul.setStatus(self)
    print("changeStatus",self.priorStatus,self.huntData.hunt)

    if self.huntData.hunt ~= self.priorStatus then
        self:makeHuntAnimation(self.huntData.hunt)
--    else
--        gameTouch:setClickProf(false)


    end

    self:showSoulCell(self.mainstatus)
  
    self:setConsum()

    self.priorStatus = self.huntData.hunt
end

function soul.relaodHunt(self,data)
    local oldnum = self.huntData.soul
    self.huntData = data.soulhunt
    --self:setStatus()
    if self.huntget and self.General then
        --
        gameTouch:clickprofbytime(2.5)
        --
        self.rootItems["hunteffectnode"..((self.mainstatus == 6) and 2 or 1)]:removeAllChildrenWithCleanup(true)
        local Node,Items = CCBReaderLoad("UIEffect/soul/soul_huode", nil, true, "do")
        Node:setPosition(9999,0)
        self.rootItems["hunteffectnode"..((self.mainstatus == 6) and 2 or 1)]:addChild(Node)
        local animationManager = getAnimationManager(Items)
        animationManager:setAnimationCompletedCallback(function()
            self.rootItems["hunteffectnode"..((self.mainstatus == 6) and 2 or 1)]:removeAllChildrenWithCleanup(true)
            self:setStatus()
        end)
        --
        Node:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2), CCCallFunc:create(function()
            Node:setPosition(0,0)
            animationManager:runAnimationsForSequenceNamed((self.mainstatus == 6) and "play_yuanbao" or "play_yinbi")
        end)))
        --
        --self.General:setAnimation("attack",false,0)
        --self.General:addAnimation("stand",true,0,0)
        --
        self.rootItems["generalEffectNode"]:removeAllChildrenWithCleanup(true)
        local Node1,Items1 = CCBReaderLoad("UIEffect/soul/soul_she", nil, true, "do")
        Node1:setPosition(0,0)
        self.rootItems["generalEffectNode"]:addChild(Node1)
        local animationManager1 = getAnimationManager(Items1)
        animationManager1:setAnimationCompletedCallback(function()
            self.rootItems["generalEffectNode"]:removeAllChildrenWithCleanup(true)
        end)
        animationManager1:runAnimationsForSequenceNamed((self.mainstatus == 6) and "soul_yuanbao" or "soul_yinbi")
        --
    else
        self:setStatus()
    end
    self.huntget = false
    self.rootItems.soulnum:setString(self.huntData.soul)


    if data.getnum and data.getnum>0 then
        -- runGamePrompt({msg = "获得元命"..(self.huntData.soul - oldnum)})
        runGamePrompt({msg = gameConfig.strings:getHp(data.getnum)})
    end

    if not self.exchangeTableView then
        self:createexchange()
    else
        self.exchangeTableView:reloadData()
    end
end

function soul.playget(self,getsouls)
    gamedata.music:PlayOptSound("lmqy")
    self.huntget = true
    if #self.oncedata + table.getTableLength(getsouls) >10 then
        for k,v in ipairs(self.addedget) do
            v.ccb:setVisible(false)
        end
        self.oncedata = {}
    end

    for k,v in pairs(getsouls) do
        table.insert(self.oncedata,v)
        local i = #self.oncedata
        if i > 10 then
            break
        end
        if not self.addedget[i] then
            self.addedget[i] = {}
            self.addedget[i].ccb,self.addedget[i].item = CCBReaderLoad("soul2/soulIconName2.ccbi", nil, true, "soulIconName")
            self.addedget[i].ccb:setPosition(196*((i<=5 and i or i-5)-0.5), i<=5 and 240 or 80)
            self.rootItems.huntlistScroll:addChild(self.addedget[i].ccb)
        end
        self.addedget[i].ccb:setVisible(true)
        local propConfig =  ui.IDconfig(self.oncedata[i].cid)
        self:setIcon(self.addedget[i].item,propConfig)
        self.addedget[i].item.s_button:addHandleOfControlEvent(function()
             ui.setPopwindowByCid(self.oncedata[i].cid)
        end, CCControlEventTouchUpInside)

    end
end


function soul.relaodList(self,type,data)
    if data then
        self["list"..type.."Data"] = data
    end
end


function soul.clear(self)
    gameTouch:UnrigistFunc("begin","soul")
    gameTouch:UnrigistFunc("end","soul")    
    self.isscrolltouched = false    
    self.ListTableView = nil
    self.exchangeTableView = nil
    self.huntlistView = nil
    self.General = nil
    self.oncedata = {}
    self.addedget = {}
    self.huntget = false
    self.priorStatus = 0
    self.itemNum = 0
--    for i = 1,5 do
--        if gameTimer.times["soulTimer"..i] then
--            gameTimer:UnrigistTimeFunc("soulTimer"..i)
--        end
--    end

    self.selectpage = "hunt"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil
end

function soul.UIUpdateData(self, isreset)
    self:shiftPage(self.selectpage)
end
--获取每种rang 等级下 出的魂魄 quality
function soul.makeSoulCellData( self )
    for k,v in pairs(gamedata.config.soul) do
        if v.id ~= 70000 then
            for i= 1,6 do
                if v["rang"..i] > 0 and not self.soulCellData[i][v.quality] then
                    self.soulCellData[i][v.quality] = v.quality
                end
            end
        end
    end
end

function soul.showSoulCell(self,aiRangLevel)
    local count = 0
    if aiRangLevel == 6 then
        self.rootItems.goldhunteffectnode:setVisible(true)
        self.rootItems.coinhunteffectnode:setVisible(false)
        self.rootItems.goldhunteffectnode1:removeAllChildrenWithCleanup(true)
        for i = 6,1,-1 do
            if self.soulCellData[6][i]~=nil then
                local ccb,item = CCBReaderLoad("UIEffect/soul/soul_"..self.soulCellData[6][i], nil, true, "soul_")
                self.rootItems.goldhunteffectnode1:addChild(ccb)
                ccb:setScale(0.5)
                ccb:setPosition(130 + 60*count,-26)
                count = count + 1
            end
        end
    else
        self.rootItems.goldhunteffectnode:setVisible(false)
        self.rootItems.coinhunteffectnode:setVisible(true) 
        self.rootItems.coinhunteffectnode1:removeAllChildrenWithCleanup(true) 
        local level = self.huntData.hunt < 5 and self.huntData.hunt + 1 or self.huntData.hunt
        ui.setLabelString(self.rootItems.nameText,gameConfig.strings:string_common("soulName",level),level*2 -1)
        for i = 6,1,-1 do
            if self.soulCellData[self.huntData.hunt][i]~=nil then
                local ccb,item = CCBReaderLoad("UIEffect/soul/soul_"..self.soulCellData[self.huntData.hunt][i], nil, true, "soul_")
                self.rootItems.coinhunteffectnode1:addChild(ccb)
                ccb:setScale(0.5)
                ccb:setPosition(130 + 60*count,-57)
                count = count + 1
            end
        end              
    end
end
return soul  B�  