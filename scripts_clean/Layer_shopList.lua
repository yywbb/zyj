--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local shopList = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    propsListTableView = nil,
    giftListTableView = nil,
    fashionListTableView = nil,

    propsData = nil,
    giftData = nil,
    fashionData = nil,
    priceid = 0,

    recruitData = nil,
    showgiftData = {},

    triggergift = {},

    pageconfig = {"recruit","props","gift","fashion"} ,
    pagename = {"招 募","道 具","礼 包","时 装",},
    selectpage = "recruit",

    normalCellSize = {x=1080,y=242},

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {11},
                title2 = {41},
                title3 = {42,253},
            },
        },
    },
    shopPriceNum = 0,
    isscrolltouched = false,

    rigistTime = {},

    ccbDocument = {},

    giftpage = 1,
    weekgiftData = nil,
    weekgiftListTableView = nil,
}

function shopList.shiftPage(self,type)
    self.selectpage = type
    print("shifPage")
    self.rootItems.topsprite:setVisible(false)

    if self.rootItems.giftTopNode then
        self.rootItems.giftTopNode:setVisible(false)
    end

--    for k,v in ipairs(self.pageconfig) do
--        if v == type then
--            self.rootItems[v.."Node"]:setVisible(true)
--            self.rootItems[v.."Node"]:setPositionX(0)
--        else
--            self.rootItems[v.."Node"]:setVisible(false)
--            self.rootItems[v.."Node"]:setPositionX(9999)
--        end
--    end
    
    if self.selectpage == "recruit" then

        self.rootItems["recruitNode"]:setVisible(true)
        self.rootItems["recruitNode"]:setPositionX(0)
        self.rootItems["propsNode"]:setVisible(false)
        self.rootItems["propsNode"]:setPositionX(9999)
        self.rootItems["fashionNode"]:setVisible(false)
        self.rootItems["fashionNode"]:setPositionX(9999)
        self.rootItems["giftNode"]:setVisible(false)
        self.rootItems["giftNode"]:setPositionX(9999)
        if self.rootItems["weekgiftNode"] then
            self.rootItems["weekgiftNode"]:setVisible(false)
            self.rootItems["weekgiftNode"]:setPositionX(9999)
        end
        if self.rootItems["jifentimeNode"] then
            self.rootItems["jifentimeNode"]:setVisible(true)
        end
        --
        if not self.recruitData then
            UIRequest({type = 1402})
            UIRequest({type = 7110})

            self:recruitshopquery()
        end
    elseif self.selectpage == "props" then
        if self.rootItems["jifentimeNode"] then
            self.rootItems["jifentimeNode"]:setVisible(false)
        end
        self.rootItems["propsNode"]:setVisible(true)
        self.rootItems["propsNode"]:setPositionX(0)
        self.rootItems["recruitNode"]:setVisible(false)
        self.rootItems["recruitNode"]:setPositionX(9999)
        self.rootItems["fashionNode"]:setVisible(false)
        self.rootItems["fashionNode"]:setPositionX(9999)
        self.rootItems["giftNode"]:setVisible(false)
        self.rootItems["giftNode"]:setPositionX(9999)
        if self.rootItems["weekgiftNode"] then
            self.rootItems["weekgiftNode"]:setVisible(false)
            self.rootItems["weekgiftNode"]:setPositionX(9999)
        end

        if not self.propsData then
            UIRequest({type = 3200})
        end
    elseif self.selectpage == "gift" then
        if self.rootItems["jifentimeNode"] then
            self.rootItems["jifentimeNode"]:setVisible(false)
        end
        self.rootItems["recruitNode"]:setVisible(false)
        self.rootItems["recruitNode"]:setPositionX(9999)
        self.rootItems["fashionNode"]:setVisible(false)
        self.rootItems["fashionNode"]:setPositionX(9999)
        self.rootItems["propsNode"]:setVisible(false)
        self.rootItems["propsNode"]:setPositionX(9999)
        if self.giftpage and self.giftpage == 2 then
            self.rootItems["giftNode"]:setVisible(false)
            self.rootItems["giftNode"]:setPositionX(9999)
            if self.rootItems["weekgiftNode"] then
                self.rootItems["weekgiftNode"]:setVisible(true)
                self.rootItems["weekgiftNode"]:setPositionX(0)
                self.rootItems["Onpoint1"]:setVisible(false)
                self.rootItems["Onpoint2"]:setVisible(true)
                self.rootItems["Onbg1"]:setVisible(false)
                self.rootItems["Onbg2"]:setVisible(true)
            end
        else
            self.rootItems["giftNode"]:setVisible(true)
            self.rootItems["giftNode"]:setPositionX(0)
            if self.rootItems["weekgiftNode"] then
                self.rootItems["weekgiftNode"]:setVisible(false)
                self.rootItems["weekgiftNode"]:setPositionX(9999)
                self.rootItems["Onpoint1"]:setVisible(true)
                self.rootItems["Onpoint2"]:setVisible(false)
                self.rootItems["Onbg1"]:setVisible(true)
                self.rootItems["Onbg2"]:setVisible(false)
            end
        end

        if not self.giftData then
            UIRequest({type = 3210})
        else
            self:ReloadGiftData()
        end

        if not self.weekgiftData then
            UIRequest({type = 4890})
        else
            self:ReloadWeekGiftData()
        end

    elseif self.selectpage == "fashion" then
        if self.rootItems["jifentimeNode"] then
            self.rootItems["jifentimeNode"]:setVisible(false)
        end
        self.rootItems["fashionNode"]:setVisible(true)
        self.rootItems["fashionNode"]:setPositionX(0)
        self.rootItems["propsNode"]:setVisible(false)
        self.rootItems["propsNode"]:setPositionX(9999)
        self.rootItems["recruitNode"]:setVisible(false)
        self.rootItems["recruitNode"]:setPositionX(9999)
        self.rootItems["giftNode"]:setVisible(false)
        self.rootItems["giftNode"]:setPositionX(9999)
        if self.rootItems["weekgiftNode"] then
            self.rootItems["weekgiftNode"]:setVisible(false)
            self.rootItems["weekgiftNode"]:setPositionX(9999)
        end

        if not self.fashionData then
            UIRequest({type = 1076})
        end
    end

end

function shopList.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shop/mallList", nil, true, "mallList")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    --
    if param then
        if param.selectpage then self.selectpage = param.selectpage end
        if param.giftpage then self.giftpage = param.giftpage end
    end

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.recruitnode1:setPositionY((GameScene.topposY-1620)*0.6+1190)
    self.rootItems.recruitnode2:setPositionY(9999)
    self.rootItems.recruitnode3:setPositionY((GameScene.topposY-1620)*0.5+785)
    self.rootItems.recruitnode4:setPositionY((GameScene.topposY-1620)*0.4+390)
    --self.rootItems.discounttime:setPositionY((GameScene.topposY-1620)+1390)

    self.rootItems.propsNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight + 75))
    self.rootItems.giftNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight + 75))
    self.rootItems.fashionNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight + 75))
    if self.rootItems.weekgiftNode then
        self.rootItems.weekgiftNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))
    end

    self.rootItems.topUpButton:setTouchPriority(-102)
    self.rootItems.topUpButton:setSwallowsTouch(true)
    self.rootItems.topUpButton:addHandleOfControlEvent(function()
        print("buyButton clicked")
        --GameScene:shiftLayer("recharge","up")
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)

    self.rootItems.pointBtn:setSwallowsTouch(true)
    self.rootItems.pointBtn:setTouchPriority(-103)
    self.rootItems.pointBtn:addHandleOfControlEvent(function()
        print("pointBtn clicked")
        
        gameWindows:openWindow("recruitshop",{data = self.recruitshopData})
    end, CCControlEventTouchUpInside)

    --
    local fashionconfig = gamedata.config.fashioncoat or {}
    if GameScene.protagonist and GameScene.protagonist.general and GameScene.protagonist.general.cid and GameScene.protagonist.general.cid > 0 then
        if (GameScene.protagonist.general.cid >= 10101 and GameScene.protagonist.general.cid <= 10115) or (GameScene.protagonist.general.cid >= 10997 and GameScene.protagonist.general.cid <= 10999) or (GameScene.protagonist.general.cid >= 162001 and GameScene.protagonist.general.cid <= 162003) then
            self.roleid = GameScene.protagonist.general.cid
        else
            for k,v in pairs(fashionconfig) do
                for k1,v1 in pairs(v) do
                    if v1.coat_id == GameScene.protagonist.general.cid then
                        self.roleid = v1.role_id
                    end
                end
            end
        end
    end
    --
    --192
    if gamedata.config.build[tostring(192)] and gamedata.config.build[tostring(192)].switch and gamedata.config.build[tostring(192)].switch == 1 then
        self.rootItems.buttonnode4:setVisible(true)
        self.rootItems.button4:setTouchEnabled(true)
    else
        self.rootItems.buttonnode4:setVisible(false)
        self.rootItems.button4:setTouchEnabled(false)
    end
    --
    -- 阵容推荐入口
    if gamedata.config.build[tostring(170)] and gamedata.config.build[tostring(170)].switch == 1 then
        self.rootItems.recommendBtn:setVisible(true)
    else
        self.rootItems.recommendBtn:setVisible(false)
    end
    self.rootItems.recommendBtn:setSwallowsTouch(true)
    self.rootItems.recommendBtn:setTouchPriority(-103)
    self.rootItems.recommendBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(170)
    end, CCControlEventTouchUpInside)

    --自动炼化
    self.rootItems.autorefinBtn:setVisible(GameScene:checkopenlevelbyId(606,true))
    self.rootItems.autorefinBtn:setSwallowsTouch(true)
    self.rootItems.autorefinBtn:setTouchPriority(-103)
    self.rootItems.autorefinBtn:addHandleOfControlEvent(function()
        gameWindows:openWindow("autorefining")
    end, CCControlEventTouchUpInside)

    --招募说明
    self.rootItems.shuomingBtn:setSwallowsTouch(true)
    self.rootItems.shuomingBtn:setTouchPriority(-103)
    self.rootItems.shuomingBtn:addHandleOfControlEvent(function()
        ui.popCommonRule(nil,nil,gamedata.config.activity_probability[tostring(11)][tostring(1)].instructions)
    end, CCControlEventTouchUpInside)

    self.shopPriceConfig = gamedata.config.shop_price
    printT(self.shopPriceConfig,"self.shopPriceConfig =======")
    self.shopPriceNum = table.getTableLength(self.shopPriceConfig)
    self:shiftPage(self.selectpage)

    -- 
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","shopList",touchbegin)
    local function touchend(pos)
        if self.rootItems.propsNode and ui.isTouched(self.rootItems.propsNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","shopList",touchend)    
    --
    if gameConfig:checkBuildOpen(253) then
        UIRequest({type = 4800})
    end
    --

    if self.rootItems.giftTopNode then
        if self.giftpage and self.giftpage == 2 then
            self.rootItems["Onpoint1"]:setVisible(false)
            self.rootItems["Onpoint2"]:setVisible(true)
            self.rootItems["Onbg1"]:setVisible(false)
            self.rootItems["Onbg2"]:setVisible(true)
        else
            self.rootItems["Onpoint1"]:setVisible(true)
            self.rootItems["Onpoint2"]:setVisible(false)
            self.rootItems["Onbg1"]:setVisible(true)
            self.rootItems["Onbg2"]:setVisible(false)
        end
        self.rootItems.OnButton1:setSwallowsTouch(true)
        self.rootItems.OnButton1:setTouchPriority(-103)
        self.rootItems.OnButton1:addHandleOfControlEvent(function()
            self.giftpage = 1
            self:shiftPage(self.selectpage)
        end, CCControlEventTouchUpInside)
        self.rootItems.OnButton2:setSwallowsTouch(true)
        self.rootItems.OnButton2:setTouchPriority(-103)
        self.rootItems.OnButton2:addHandleOfControlEvent(function()
            self.giftpage = 2
            self:shiftPage(self.selectpage)
        end, CCControlEventTouchUpInside)
    end

    --showcid
    local showcid = 10598
    if gamedata.config.recruit_basic and gamedata.config.recruit_basic["4"] and gamedata.config.recruit_basic["4"].show and gamedata.config.recruit_basic["4"].show > 0 then
        showcid = gamedata.config.recruit_basic["4"].show
    end
    if self.rootItems.fengshen_general then
        setSpriteFrameByName(self.rootItems.fengshen_general, "fengshen_"..showcid)
    end


    --
    if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
        if self.rootItems.gambling1 then
            -- self.rootItems.gambling1:setVisible(false)
            -- self.rootItems.gambling3:setVisible(false)
            -- self.rootItems.gambling5:setVisible(false)
            -- self.rootItems.gambling2:setVisible(true)
            -- self.rootItems.gambling4:setVisible(true)
            -- self.rootItems.gambling6:setVisible(true)
        end
    end

end

function shopList.clear(self)

    if gameTimer.times["recruitTimer2"] then
        gameTimer:UnrigistTimeFunc("recruitTimer2")
    end
    if gameTimer.times["recruitTimer3"] then
        gameTimer:UnrigistTimeFunc("recruitTimer3")
    end
    if gameTimer.times["recruitactivity"] then
        gameTimer:UnrigistTimeFunc("recruitactivity")
    end
    if gameTimer.times["recruitactivity2"] then
        gameTimer:UnrigistTimeFunc("recruitactivity2")
    end

    if gameTimer.times["discountactivity"] then
        gameTimer:UnrigistTimeFunc("discountactivity")
    end

    for k,v in pairs(self.rigistTime) do
        if gameTimer.times[k] then
            gameTimer:UnrigistTimeFunc(k)
        end
    end

    self.giftpage = 1
    self.weekgiftData = nil
    self.weekgiftListTableView = nil

    self.rigistTime = {}

    self.ccbDocument = {}

    self.propsListTableView = nil
    self.giftListTableView = nil
    self.fashionListTableView = nil
    self.selectpage = "recruit"

    self.priceid = 0
    self.giftData = nil
    self.fashionData = nil
    self.propsData = nil
    self.recruitData = nil
    self.recruitshopData = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    gameTouch:UnrigistFunc("begin","shopList")
    gameTouch:UnrigistFunc("end","shopList")    
end


function shopList.ReloadTriggerGiftData(self,data)
    print("ReloadTriggerGiftData")
    --
    self.triggergift = {}
    for k,v in pairs(data) do
        table.insert(self.triggergift,v)
    end

    local sortfunc = function (a,b)
        return (a["iid"] < b["iid"])
    end

    table.sort(self.triggergift,sortfunc)

end

function shopList.ReloadGiftData(self,data)
    print("ReloadGiftData")

    if data and data.giftbags then
        self.giftData = {}
        for k, v in pairs( data.giftbags ) do
            table.insert(self.giftData,v)
        end

        local sortfunc = function (a,b)
            return (a["cid"] < b["cid"])
        end

        table.sort(self.giftData,sortfunc)
    end

    self.showgiftData = {}
    if self.triggergift and next(self.triggergift) then
        for k,v in ipairs(self.triggergift) do
            table.insert(self.showgiftData,v)
        end
    end
    if self.giftData and next(self.giftData) then
        for k,v in ipairs(self.giftData) do
            table.insert(self.showgiftData,v)
        end
    end

    --
    if self.rootItems then
        if not self.giftListTableView then
            self:createGiftList()
        else
            if self.showgiftData and next(self.showgiftData) then
                self.giftListTableView:reloadData()
                self.giftListTableView:setLuaContentOffset(0, self.rootItems.giftNode:getContentSize().height - table.getTableLength(self.showgiftData)*self.normalCellSize.y)
            else
                for k,v in pairs(self.rigistTime) do
                    if gameTimer.times[k] then
                        gameTimer:UnrigistTimeFunc(k)
                    end
                end
                self.rigistTime = {}
                self.ccbDocument = {}
                self.giftListTableView:reloadData()
                self.giftListTableView = nil
            end
        end
    end
end


function shopList.createGiftList(self)
    print("createGiftList")

    local celldict = {}
    local unrecycleCell = {}
    local giftListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "isRecycle" then
            if celldict[a2] then
                if celldict[a2].index and self.showgiftData and next(self.showgiftData) then
                    if self.showgiftData[celldict[a2].index] and self.showgiftData[celldict[a2].index].iid and self.showgiftData[celldict[a2].index].iid > 0 then
                        if gameTimer.times["triggergift"..self.showgiftData[celldict[a2].index].iid] then
                            gameTimer:UnrigistTimeFunc("triggergift"..self.showgiftData[celldict[a2].index].iid)
                        end
                    end
                end
            end
            return false
        elseif fn == "cellAtIndex" then
            self.ccbDocument[tostring(a1+1)] = {}
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                self.ccbDocument[tostring(a1+1)].cellCCB, self.ccbDocument[tostring(a1+1)].ccbDocumentControler = CCBReaderLoad("shop/cell_shop", nil, true, "cell_shop")
                celldict[a2] = {cellCCB=self.ccbDocument[tostring(a1+1)].cellCCB,ccbDocumentControler=self.ccbDocument[tostring(a1+1)].ccbDocumentControler,index = a1+1 }
                ui.tableviewAnimation(self.giftListTableView,self.ccbDocument[tostring(a1+1)].cellCCB,self.normalCellSize.x/2, 0,a1)
            else
                first = false
                self.ccbDocument[tostring(a1+1)].cellCCB = celldict[a2].cellCCB
                self.ccbDocument[tostring(a1+1)].ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.showgiftData and next(self.showgiftData) then
                self:setGift(self.ccbDocument[tostring(a1+1)].ccbDocumentControler,self.showgiftData[a1+1],a1+1)
            end

            if self.giftListTableView then
                self.ccbDocument[tostring(a1+1)].cellCCB:setPosition(self.normalCellSize.x/2, 0)
            end
            if first then
                a2:addChild(self.ccbDocument[tostring(a1+1)].cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showgiftData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.giftListTableView = ui.createLuaTableView({
        handle = giftListHandle,
        viewwidth = self.rootItems.giftNode:getContentSize().width,
        viewheight = self.rootItems.giftNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.giftNode:addChild(self.giftListTableView)
    self.giftListTableView:setTouchPriority(-101)
end


function shopList.setGift(self,item,data,index)
    print("setGift")
    --
    if data and data.iid and data.iid > 0 then

        local config = gamedata.config.trigger_gift and gamedata.config.trigger_gift[tostring(data.cid)] or {}

        ui.setIconLv(item,{cid = 1000})
        setSpriteFrameByName(item["il_icon"], config.icon or "alpha")
        ui.setLabelString(item.name,config.name or "",1)
        item.desc:setString(config.desc or "")

        --
        local rewards = {}
        if config.gift_id and config.gift_id ~= "" then
            rewards = ui.getIDandNUMs(config.gift_id)
        end
        --

        item.il_button:setTouchPriority(-102)
        item.il_button:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            if next(rewards) then
                gameWindows:openWindow("getStaff",{data = rewards,type = "限时礼包"},nil)
            end
        end, CCControlEventTouchUpInside)

        --
        local price = {}
        if config.price and config.price ~= "" then
            price = ui.getIDandNUMs(config.price)
        end
        if price[1] then
            if price[1].cid == 1000 then
                if item.spritecoin and item.spritegold then
                    item.spritecoin:setVisible(true)
                    item.spritegold:setVisible(false)
                end
            elseif price[1].cid == 1001 then
                if item.spritecoin and item.spritegold then
                    item.spritecoin:setVisible(false)
                    item.spritegold:setVisible(true)
                end
            end
            item.price:setString(price[1].num)
        else
            item.price:setString("0")
            if item.spritecoin and item.spritegold then
                item.spritecoin:setVisible(false)
                item.spritegold:setVisible(true)
            end
        end

        --
        ui.setLabelString(item.buytext,gameConfig.strings:string_common("shop_list",3),18)
        item.buyButton:setTouchPriority(-102)
        item.buyButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4801, iid = data.iid, price = price})
            gamedata.music:PlayOptSound("ccgm")
        end, CCControlEventTouchUpInside)

        --
        item.buytimenode:setVisible(false)
        if item.time then
            item.time:setVisible(true)
        end

        local dataiid = data.iid
        local index = index
        if gameTimer.times["triggergift"..dataiid] and gameTimer.times["triggergift"..dataiid] > 0 then
            self.rigistTime["triggergift"..dataiid] = 1
            gameTimer:rigistTimeFunc("triggergift"..dataiid,function()
                if gameTimer.times["triggergift"..dataiid] > 0 then
                    if self.ccbDocument[tostring(index)] and self.ccbDocument[tostring(index)].ccbDocumentControler and self.ccbDocument[tostring(index)].ccbDocumentControler.time then
                        ui.setLabelString(self.ccbDocument[tostring(index)].ccbDocumentControler.time,"倒计时："..ui.makeTimeText(gameTimer.times["triggergift"..dataiid],"hour"),22)
                    end
                else
                    gameTimer:UnrigistTime("triggergift"..dataiid)
                    gameTimer:UnrigistTimeFunc("triggergift"..dataiid)
                    UIRequest({type = 4800})
                end
            end)
        else
            UIRequest({type = 4800})
        end
    else

        local giftdata = gamedata.config.gift_bag[tostring(data.cid)]
        local configdata =  gamedata.config.props[tostring(giftdata.id)]

        ui.setIconLv(item,{cid = giftdata.id})
        ui.setLabelString(item.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)

        item.desc:setString(configdata.desc)
        item.price:setString(tostring((data.discount and data.discount >0) and data.discount or data.gold))

        item.il_button:setTouchPriority(-102)
        item.il_button:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            if configdata.param2 then
               local reward = ui.getIDandNUMs(configdata.param2)
               gameWindows:openWindow("getStaff",{data = reward,type = configdata.name},nil)
            end
        end, CCControlEventTouchUpInside)

        item.buytimenode:setVisible(false)
        if item.time then
            item.time:setVisible(false)
        end
        if item.spritecoin and item.spritegold then
            item.spritecoin:setVisible(false)
            item.spritegold:setVisible(true)
        end

        -- ui.setLabelString(item.buytext,"购 买",18)
        ui.setLabelString(item.buytext,gameConfig.strings:string_common("shop_list",3),18)
        item.buyButton:setTouchPriority(-102)
        item.buyButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            print("buyButton clicked----1")
            gameTouch:clickprofbytime(0.5)
            -- UIRequest({type = 3211, id = giftdata.id, num = 1})
            --  if (i == 4) and (needvip > GameScene.vip.vip) then
            --     runGamePrompt({msg = "VIP"..needvip.."以上开启"})
            -- else
            local vip  = GameScene.vip.vip or 0 
            local gold = GameScene.roleinfo.gold or 0
            gamedata.music:PlayOptSound("ccgm")
            local propconfig = gamedata.config.props[tostring(giftdata.id)]
            if propconfig.type == "vipbox" and propconfig.param1+0 > vip+0 then
                runGamePrompt({msg = "贵族等级不够" })
                return
            end
            local shopconfig = gamedata.config.gift_bag[tostring(giftdata.id)]
            if shopconfig.discount > gold then
                shortGold()
                 return 
            end
            local names = item.name:getString() or ""
            local prices = item.price:getString() or "0"
            local cb = function()
                UIRequest({type = 3211, id = giftdata.id, num = 1})
            end
            local rich = {
                {fontID = 1,content = "是否消耗 ",},
                {fontID = 0,content = "obj_s_gold",},
                {fontID = 11,content = " "..prices,},
                {fontID = 1,content = "，购买 "},
                {fontID = 11,content = names},
                {fontID = 1,content = " ?"},
            }
            gameWindows:openWindow("confirm",{rich = rich}, cb)

        end, CCControlEventTouchUpInside)

    end
end

function shopList.createPropsList(self)
    print("createGiftList")

    local celldict = {}
    local unrecycleCell = {}
    local propsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shop/cell_shop", nil, true, "cell_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.propsListTableView,cellCCB,self.normalCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setProps(ccbDocumentControler,self.propsData[a1+1])

            if  self.propsListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.propsData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.propsListTableView = ui.createLuaTableView({
        handle = propsListHandle,
        viewwidth = self.rootItems.propsNode:getContentSize().width,
        viewheight = self.rootItems.propsNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.propsNode:addChild(self.propsListTableView)
    self.propsListTableView:setTouchPriority(-101)
end


function shopList.setProps(self,item,data)
    print("setProps")
    local configdata = ui.IDconfig(data.id)
    printT(data , "data ======")
    ui.setIconLv(item,{cid = data.id})
    ui.setLabelString(item.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)
    item.desc:setString(configdata.desc)

    item.buytimenode:setVisible(true)
    ui.setLabelString(item.buytime, data.canBuyMaxTime - data.usenum, 13)
    -- item.price:setString(tostring((data.discount and data.discount >0) and data.discount or data.gold))
    if data.discount and data.discount >0 then
        item.price:setString(data.discount)
    elseif data.usenum + 1 >= self.shopPriceNum then
        item.price:setString(self.shopPriceConfig[tostring(self.shopPriceNum)][data.seq.."_id"])
    else
        item.price:setString(self.shopPriceConfig[tostring(data.usenum + 1)][data.seq.."_id"])
    end
    item.il_button:setTouchPriority(-102)
    item.il_button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        print("iconButton clicked")
        -- 增加弹窗
        ui.setPopwindowByCid(data.id)
    end, CCControlEventTouchUpInside)


    if data.canBuyMaxTime - data.usenum > 0  then
        ui.removeGray("CCControlButton",item["buyButton"])
        ui.removeGray("CCLabelTTF",item["buytext"])
    else
        ui.addGray("CCControlButton",item["buyButton"])
        ui.addGray("CCLabelTTF",item["buytext"])
    end

    -- ui.setLabelString(item.buytext,"购 买",18)
    ui.setLabelString(item.buytext,gameConfig.strings:string_common("shop_list",3),18)
    item.buyButton:setTouchPriority(-102)
    item.buyButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end -- 增加超出无法点击
        print("buyButton clicked")
        if data.canBuyMaxTime - data.usenum > 0  then
            gameWindows:openWindow("shopbuy",data,nil)
        else
            -- runGamePrompt({msg = "今日购买个数已用完"})
            runGamePrompt({msg = gameConfig.strings:string_common("shop_list",4)})
        end

    end, CCControlEventTouchUpInside)

    --
    if item.timedesc then
        local endString = ""
        if data["end"] and data["end"] ~= "" then
            local year, month, day, hour, min, sec = ui.getDate(data["end"])
            if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
                local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 2
                local endtab = os.date("*t",endt)
                --endString = endtab.year.."."..endtab.month.."."..endtab.day
                endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时结束购买"
            end
        end
        ui.setLabelString(item.timedesc,endString,27)
    end
    --
end


function shopList.ReloadPropsData(self,data)
    printT(data,"ReloadPropsData")

    self.propsData = {}
    for k, v in pairs( gamedata.config.shop ) do
        local showitem = true
        if v["begin"] and v["begin"] ~= "" then
            local year1,month1,day1,hour1,minute1,second1 = ui.getDate(v["begin"])
            local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
            local nowtime = gamedata:time()
            if time1-nowtime > 0 then
                showitem = false
            end
        end
        if v["end"] and v["end"] ~= "" then
            local year1,month1,day1,hour1,minute1,second1 = ui.getDate(v["end"])
            local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
            local nowtime = gamedata:time()
            if time1-nowtime <= 0 then
                showitem = false
            end
        end
        --
        if showitem then
            local  canBuyMaxTime = 0
            if v["vip"..GameScene.vip.vip .."_times"] ~= 0  then
                canBuyMaxTime = v["vip"..GameScene.vip.vip .."_times"]
            else
                canBuyMaxTime = v.num
            end
            table.insert(self.propsData,table.merge(v,{usenum = data.props[tostring(v.seq)] or 0,canBuyMaxTime = canBuyMaxTime}))
        end
    end

    local sortfunc = function (a,b)
        return a["seq"] > b["seq"]
    end

    table.sort(self.propsData,sortfunc)


    if self.rootItems then
        if not self.propsListTableView then
            self:createPropsList()
        else
            self.propsListTableView:reloadData()
        end
    end
end

function shopList.checkRecruitActivity(self)

    if gamedata.config.enlist then
        local now =  gamedata:time()
        local v = gamedata.config.enlist["1"] 
        local isactive,resttime = ui.checkDateActive(v.opentime,v.overtime,now)
        if isactive then
            local rewards = ui.getIDandNUMs(v.reward)
            local rewardsprite = ""
            for kk,vv in ipairs(rewards) do
                local tempstr = rewardsprite
                rewardsprite = tempstr..vv.cid
            end

            return rewardsprite, resttime
        end
    end
    return nil,nil
end

function shopList.checkRecruitActivity2( self )
    if gamedata.config.enlist 
        and gameConfig:checkBuildOpen(362) 
        and GameScene:checkopenlevelbyId(362,true) then

        local now =  gamedata:time()
        local v = gamedata.config.enlist["2"] 
        local isactive,resttime = ui.checkDateActive(v.opentime,v.overtime,now)
        if isactive then
            return true, resttime
        end
    end
    return false
end

function shopList.recruitshopquery( self )
    if self:checkRecruitActivity2() then
        UIRequest({type = 5321})
    end
end

function shopList.checkDiscountActivity(self)
    if gamedata.config.recruit_tenlottery then
        local now =  gamedata:time()
        for k,v in pairs(gamedata.config.recruit_tenlottery) do
            if v.open_type and v.open_type == 1 then
                local nowtime = gamedata:time()
                local temp = os.date("*t", GameScene.roleinfo.servertime)
                local timediff1 = GameScene.roleinfo.servertime + 86400*(v.days_later or 0) - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
                local timediff2 = GameScene.roleinfo.servertime + 86400*((v.days_later or 0)+v.continued_time) - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
                if timediff1 < 0 and timediff2 > 0 then
                    return  timediff2,v.discount
                end
            else
                local isactive,resttime = ui.checkDateActive(v.opentime,v.overtime,now)
                if isactive then
                    return  resttime,v.discount
                end
            end
        end
    end
    return nil,nil
end

function shopList.reloadrecruitshop( self,t )
    local oldpoint = self.recruitshopData and self.recruitshopData.points or t.points
    self.recruitshopData = t
    if oldpoint<self.recruitshopData.points then
        runGamePrompt({msg = "积分+"..(self.recruitshopData.points-oldpoint)})
    end
end

function shopList.setFengshenHint(self,data)
    self.rootItems["hint4"]:setVisible(data.status == 0)
end

function shopList.reloadrecruit(self, data)

    self.recruitData = data

    local rewardsprite,resttime = self:checkRecruitActivity()
    print("checkRecruitActivity",rewardsprite,resttime)

    if rewardsprite then
        gameTimer:rigistTime("recruitactivity",resttime)
        if gameTimer.times["recruitactivity"] and gameTimer.times["recruitactivity"] > 0 then
            gameTimer:rigistTimeFunc("recruitactivity", function()
                if gameTimer.times["recruitactivity"] <= 0 then
                    if gameTimer.times["recruitactivity"] then
                        gameTimer:UnrigistTimeFunc("recruitactivity")
                    end
                    ui.setLabelString( self.rootItems.activitytime,"",26)
                    self:reloadrecruit(self.recruitData)
                else
                    ui.setLabelString( self.rootItems.activitytime,"新武将赠送结束倒计时："..ui.makeTimeDayText(gameTimer.times["recruitactivity"],"day"),26)
                end
            end)
        end
    end

    local pointactive,pointtime = self:checkRecruitActivity2()

    self.rootItems.point3:removeAllChildrenWithCleanup(true)
    self.rootItems.point4:removeAllChildrenWithCleanup(true)
    self.rootItems.pointBtn:setVisible(false)
    if self.rootItems.jifen_time then
        self.rootItems.jifen_time:setVisible(false)
    end
    if self.rootItems.jifen_des then
        self.rootItems.jifen_des:setVisible(false)
    end
    if pointactive then
        gameTimer:rigistTime("recruitactivity2",pointtime)
        if gameTimer.times["recruitactivity2"] and gameTimer.times["recruitactivity2"] > 0 then
            gameTimer:rigistTimeFunc("recruitactivity2", function()
                if gameTimer.times["recruitactivity2"] <= 0 then
                    if gameTimer.times["recruitactivity2"] then
                        gameTimer:UnrigistTimeFunc("recruitactivity2")
                    end
                    self:reloadrecruit(self.recruitData)
                    if self.rootItems.jifen_time then
                        ui.setLabelString( self.rootItems.jifen_time,"",26)
                    end
                elseif self.rootItems.jifen_time then
                    ui.setLabelString( self.rootItems.jifen_time,"积分商店活动结束倒计时："..ui.makeTimeDayText(gameTimer.times["recruitactivity2"],"day"),26)
                end
            end)
        end   

        local pointccb,pointitem = CCBReaderLoad("shop/songjifen", nil, true, "songjifen")
        self.rootItems.point3:addChild(pointccb)
        local pointccb2,pointitem2 = CCBReaderLoad("shop/songjifen", nil, true, "songjifen")
        self.rootItems.point4:addChild(pointccb2)
        self.rootItems.pointBtn:setVisible(true)
        if self.rootItems.jifen_time then
            self.rootItems.jifen_time:setVisible(true)
        end
        if self.rootItems.jifen_des then
            self.rootItems.jifen_des:setVisible(true)
            ui.setLabelString(self.rootItems.jifen_des," “活动积分”在活动结束后清零",27)
        end
    end



    local discounttime,discount = self:checkDiscountActivity()
    if discounttime then
        gameTimer:rigistTime("discountactivity",discounttime)
        if gameTimer.times["discountactivity"] and gameTimer.times["discountactivity"] > 0 then
            gameTimer:rigistTimeFunc("discountactivity", function()
                if gameTimer.times["discountactivity"] <= 0 then
                    if gameTimer.times["discountactivity"] then
                        gameTimer:UnrigistTimeFunc("discountactivity")
                    end
                    ui.setLabelString( self.rootItems.discounttime,"",26)
                    self:reloadrecruit(self.recruitData)
                else
                    ui.setLabelString( self.rootItems.discounttime,"十连抽"..discount.."折优惠（封神招募除外）\n结束倒计时："..ui.makeTimeDayText(gameTimer.times["discountactivity"],"day"),26)
                end
            end)
        end
    end

    if self.rootItems.needvip then
        self.rootItems.needvip:setVisible(false)
    end
    --local needvip = ui.getVipLevelByStr("recruit_limit")
    for i=1,4 do
        local celldata = self.recruitData[tostring(i)]
        local config = gamedata.config.recruit_basic[tostring(i)]
        self.rootItems["p_button_"..i]:setTouchPriority(-101)
        self.rootItems["p_button_"..i]:addHandleOfControlEvent(function()
            guide:setGuideProlayer(true)
            -- if (i == 4) and (needvip > GameScene.vip.vip) then
            --     runGamePrompt({msg = "VIP"..needvip.."以上开启"})
            -- else
                gameWindows:openWindow("recruit",{
                    type = "recruit",
                    data = {
                        pointactive = pointactive,
                        discounttime = discounttime, 
                        discount = (i < 4) and discount or nil,
                        index = i, 
                        data=celldata,
                        timer = gameTimer.times["recruitTimer"..i] or 0
                    }
                },nil)
            -- end
        end, CCControlEventTouchUpInside)


        if i == 1 then
            self.rootItems.num_1:setString(tostring(celldata.propnum))
            if celldata.propnum > 0 then
                self.rootItems.num_1:setColor(ccc3(220,176,61))
            else
                self.rootItems.num_1:setColor(ccc3(255,0,0))
            end
            self.rootItems["hint1"]:setVisible(celldata.propnum>0)
            ui.createRichLabel(LoadJsonStringToTable(config.rewarddesc),self.rootItems["lbnode"..i])
        elseif i == 4 then
            self.rootItems["lb_"..i]:setVisible(false)
            self.rootItems["num_"..i]:setVisible(false)
            self.rootItems["hint"..i]:setVisible(false)
            self.rootItems["newnode"..i]:setVisible(false)
            self.rootItems["oldnode"..i]:setVisible(true)
            ui.createRichLabel(LoadJsonStringToTable(config.rewarddesc),self.rootItems["lbnode"..i])
            --
            -- if self.rootItems.needvip and needvip > 0 then
            --     self.rootItems.needvipnum:setString("VIP"..needvip)
            --     self.rootItems.needvip:setVisible(true)
            -- end
            --
            if self.rootItems.cost_4 then
                self.rootItems.cost_4:setVisible(false)
                self.rootItems.cost_4N:setVisible(true)
                local _config = gamedata.config:getConfigByName("recruit_basic")["4"]
                if _config and _config.count > 0 then
                    setSpriteFrameByName(self.rootItems.costS4,"fengshenzhaomuling")
                
                    self.rootItems.costN4:setString(tostring(celldata.propnum))

                    if celldata.propnum > 0 then
                        self.rootItems.costN4:setColor(ccc3(220,176,61))
                    else
                        self.rootItems.costN4:setColor(ccc3(255,0,0))
                    end

                else
                    self.rootItems.cost_4N:setVisible(false)
                end
            end
        else
            if celldata.timer <= 0 then
                self.rootItems["lb_"..i]:setVisible(false)
                self.rootItems["num_"..i]:setVisible(true)
            else
                self.rootItems["lb_"..i]:setVisible(true)
                self.rootItems["num_"..i]:setVisible(false)
                self.rootItems["lb_"..i]:setString(gameConfig.strings:freetime(ui.makeTimeText(gameTimer.times["recruitTimer"..i],"hour")))
                self:setRecruitTimer(i)
            end
            
            self.rootItems["hint"..i]:setVisible(celldata.timer<=0 or celldata.propnum >= 10)

            if rewardsprite then
                setSpriteFrameByName(self.rootItems["status_sprite"..i],rewardsprite)
                self.rootItems["newnode"..i]:setVisible(true)
                self.rootItems["oldnode"..i]:setVisible(false)
            else
                self.rootItems["newnode"..i]:setVisible(false)
                self.rootItems["oldnode"..i]:setVisible(true)
                ui.createRichLabel(LoadJsonStringToTable(config.rewarddesc),self.rootItems["lbnode"..i])
            end
        end

    end
end

--
function shopList.ReloadFashionData(self,data)
    print("ReloadFashionData")

    self.priceid = data.priceid or 0
    self.fashionData = {}
    for k, v in pairs( data.status ) do
        table.insert(self.fashionData,v)
    end

    local sortfunc = function (a,b)
        if a["id"] >= b["id"] then
            return false
        elseif a["id"] < b["id"] then
            return true
        end
    end

    table.sort(self.fashionData,sortfunc)

    if self.rootItems then
        if not self.fashionListTableView then
            self:createFashionList()
        else
            self.fashionListTableView:reloadData()
            self.fashionListTableView:setLuaContentOffset(0, self.rootItems.fashionNode:getContentSize().height - table.getTableLength(self.fashionData)*self.normalCellSize.y)
        end
    end
end


function shopList.createFashionList(self)
    print("createFashionList")

    local celldict = {}
    local unrecycleCell = {}
    local fashionListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shop/cell_shop", nil, true, "cell_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.fashionListTableView,cellCCB,self.normalCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setFashion(ccbDocumentControler,self.fashionData[a1+1])

            if self.fashionListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2, 0)
            end
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.fashionData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.fashionListTableView = ui.createLuaTableView({
        handle = fashionListHandle,
        viewwidth = self.rootItems.fashionNode:getContentSize().width,
        viewheight = self.rootItems.fashionNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.fashionNode:addChild(self.fashionListTableView)
    self.fashionListTableView:setTouchPriority(-101)
end


function shopList.setFashion(self,item,data)
    print("setFashion")

    local fashiondata = gamedata.config.fashion_gift_bag[tostring(data.id)]
    local fashionconfig = gamedata.config.fashioncoat or {}

    local coatconfig = {}
    for k,v in pairs(fashionconfig) do
        if (tonumber(k) == tonumber(data.id)) and v[tostring(self.roleid or 10101)] then
            coatconfig = v[tostring(self.roleid)] or {}
        end
    end

    ui.setIconLv(item,{cid = coatconfig.coat_id})
    ui.setLabelString(item.name,coatconfig.name, 1)

    


    --todo
    local xgold = fashiondata.gold or 0
    item.desc:setString(fashiondata.desc or "")

    if self.priceid == data.id then
        xgold = fashiondata.price
        item.desc:setString("限时折扣    原价:  "..fashiondata.gold.."元宝".."\n"..(fashiondata.desc or ""))
    end

    item.price:setString(xgold)

    item.il_button:setTouchPriority(-102)
    item.il_button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        print("iconButton clicked")
        -- 增加弹窗
        ui.setPopwindowByCid(data.id)
    end, CCControlEventTouchUpInside)

    item.buytimenode:setVisible(false)

    -- ui.setLabelString(item.buytext,"购 买",18)
    ui.setLabelString(item.buytext,gameConfig.strings:string_common("shop_list",3),18)

    if data.status == 1 then
        ui.removeGray("CCControlButton",item.buyButton)
        item.buyButton:setTouchPriority(-102)
        item.buyButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 1074,id = data.id, xgold = xgold})
            gamedata.music:PlayOptSound("ccgm")
        end, CCControlEventTouchUpInside)
    else
        ui.addGray("CCControlButton",item.buyButton)
        item.buyButton:setTouchPriority(-102)
        item.buyButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = "已拥有该时装"})
        end, CCControlEventTouchUpInside)
    end

end
--

--todo
function shopList.ReloadWeekGiftData(self,data)
    print("ReloadWeekGiftData")

    if data and data.weekgift then
        self.weekgiftData = data.weekgift or {}
    end

    self.showweekgiftData = {}
    for k,v in pairs(gamedata.config.vip_weekgift or {}) do
        table.insert(self.showweekgiftData,v)
    end

    local sortfunc = function (a,b)
        if a["vip"] >= b["vip"] then
            return false
        elseif a["vip"] < b["vip"] then
            return true
        end
    end

    table.sort(self.showweekgiftData,sortfunc)
    --
    if self.rootItems then
        if not self.weekgiftListTableView then
            self:createWeekGiftList()
        else
            self.weekgiftListTableView:reloadData()
            --self.weekgiftListTableView:setLuaContentOffset(0, self.rootItems.weekgiftNode:getContentSize().height - table.getTableLength(self.showweekgiftData)*self.normalCellSize.y)
        end
    end
end


function shopList.createWeekGiftList(self)
    print("createWeekGiftList")

    local celldict = {}
    local unrecycleCell = {}
    local weekgiftListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shop/cell_shop", nil, true, "cell_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.weekgiftListTableView,cellCCB,self.normalCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setWeekGift(ccbDocumentControler,self.showweekgiftData[a1+1],a1+1)

            if  self.weekgiftListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showweekgiftData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.weekgiftListTableView = ui.createLuaTableView({
        handle = weekgiftListHandle,
        viewwidth = self.rootItems.weekgiftNode:getContentSize().width,
        viewheight = self.rootItems.weekgiftNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.weekgiftNode:addChild(self.weekgiftListTableView)
    self.weekgiftListTableView:setTouchPriority(-101)
end


function shopList.setWeekGift(self,item,data,index)
    print("setWeekGift")

    if item.buytypedesc then
        item.buytypedesc:setString("本周还可购买            次")
    end

    local giftdata = data or {}
    local configdata =  gamedata.config.props[tostring(giftdata.id)]

    ui.setIconLv(item,{cid = giftdata.id})
    ui.setLabelString(item.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)

    item.desc:setString(configdata.desc)
    item.price:setString(giftdata.gold)

    item.il_button:setTouchPriority(-102)
    item.il_button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if configdata.param2 then
            local reward = ui.getIDandNUMs(configdata.param2)
            gameWindows:openWindow("getStaff",{data = reward,type = configdata.name},nil)
        end
    end, CCControlEventTouchUpInside)

    item.buytimenode:setVisible(true)
    if item.time then
        item.time:setVisible(false)
    end
    if item.spritecoin and item.spritegold then
        item.spritecoin:setVisible(false)
        item.spritegold:setVisible(true)
    end

    item.buyButton:setTouchPriority(-102)
    ui.setLabelString(item.buytext,gameConfig.strings:string_common("shop_list",3),18)

    if self.weekgiftData and self.weekgiftData[tostring(index)] and (giftdata.num > self.weekgiftData[tostring(index)]) then
        ui.setLabelString(item.buytime, giftdata.num - self.weekgiftData[tostring(index)], 13)
        --
        if giftdata.vip > GameScene.vip.vip then
            ui.addGray("CCControlButton",item["buyButton"])
            ui.addGray("CCLabelTTF",item["buytext"])
            --
            item.buyButton:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                print("buyButton clicked")
                gameTouch:clickprofbytime(1)
                runGamePrompt({msg = "vip"..giftdata.vip.."以上可购买"})
                gamedata.music:PlayOptSound("ccgm")
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",item["buyButton"])
            ui.removeGray("CCLabelTTF",item["buytext"])
            --
            item.buyButton:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                print("buyButton clicked")
                gameTouch:clickprofbytime(1)
                UIRequest({type = 4891, vip = giftdata.vip, xgold = giftdata.gold})
                gamedata.music:PlayOptSound("ccgm")
            end, CCControlEventTouchUpInside)
        end
    else
        ui.setLabelString(item.buytime, "0", 13)
        --
        ui.addGray("CCControlButton",item["buyButton"])
        ui.addGray("CCLabelTTF",item["buytext"])
        --
        item.buyButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            print("buyButton clicked")
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = "本周购买次数已用完"})
            gamedata.music:PlayOptSound("ccgm")
        end, CCControlEventTouchUpInside)

    end
end


--todo

function shopList.setRecruitTimer(self,index)
    if gameTimer.times["recruitTimer"..index] and gameTimer.times["recruitTimer"..index] ~= 0 then
        gameTimer:rigistTimeFunc("recruitTimer"..index,function()

            if  gameTimer.times["recruitTimer"..index] == 0 then
                self.rootItems["lb_"..index]:setVisible(false)
                self.rootItems["num_"..index]:setVisible(true)
                self.rootItems["hint"..index]:setVisible(true)
            else
                self.rootItems["lb_"..index]:setVisible(true)
                self.rootItems["num_"..index]:setVisible(false)
                -- self.rootItems["lb_"..index]:setString(ui.makeTimeText(gameTimer.times["recruitTimer"..index],"hour").." 后免费"  )
                self.rootItems["lb_"..index]:setString(gameConfig.strings:freetime(ui.makeTimeText(gameTimer.times["recruitTimer"..index],"hour")))
            end
        end)
    end
end

function shopList.UIUpdateData(self,isreset)
    self.recruitData = nil
    self:shiftPage(self.selectpage)
end


return shopList
