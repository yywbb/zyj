--
-- Author: songyibo
-- Date: 2018-09-01 16:39:31
--

local GameHttpRequest = require "GameHttpRequest"

local tradingShop = {

    rootNode = nil,
    rootItems = nil,

    menuCellSize = {x= 250,y=102},
    childCellSize = {x= 210,y=74},
    menuViewSize = {x= 240,y=900},
    bellHeight = 120, --铃铛高度

    touchPriority = -103,

    goodsShowNum = 10,  --每页商品显示数量
    sellShowNum = 16,   --出售道具显示数量
    requestPage = 2,    --请求页数

    pageconfig = {"buy","sell","record"} ,
    pagename = {"购买道具","出售道具","交易记录"},

    selectpage = "buy",


    buyMenus = nil,
    sellMenus = nil,

    buyMenuPos1 = 0,
    buyMenuPos2 = 0,

    sellMenuPos1 = 0,
    sellMenuPos2 = 0,

    --道具出售页签
    propListCCB = nil,
    propListItems = nil,

    myPropListCCB = nil,
    myPropListItems = nil,

    selectId = -1,  --筛选Id
    sortId = -1 ,   --排序Id

    searchText = "",
    selectPropIndex = nil,


    curPage = 1,
    maxPage = 1,

    --当前货币
    currency = 0,

    --当前展示的商品
    curShowShopData = {},

    --关注商品
    focusGoods = {},

    --我的货架
    mySellGoods = {},

    --我的背包数据(以过滤能上架的) 分多级页签 在 reoladSellMenu 初始化表结构
    myCanSellGoods = {},

    --背包商品保护期数据
    goodsProtectData = {},


    --交易记录
    myRecordData = nil,
    myRecordListView = nil,

    --物品信息tip
    propInfoCCB = nil,
    propInfoItems = nil,

    allPropInfoCCB = {},
    allPropInfoItems = {},

    ruleVisable = false, --说明默认隐藏


}

function tradingShop.init(self,parent,toppos)

    self:initNode(parent,toppos)
    self:makeScreenConfig()
    self:initFixedString()
    self:requestCurrencyData()
    ui.setLabelString(self.rootItems.currency,0,92)
    --道具购买保护期数据
    UIRequest({ type = 6123})
    self:shiftPage("buy")
end

function tradingShop.initNode(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("shanghui/shanghui", nil, true, "shanghui")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(toppos)


    self.rootItems["closeButton"]:addHandleOfControlEvent(function()
        GameScene:shiftLayer("main","down")
    end, CCControlEventTouchUpInside)
    self.rootItems["closeButton"]:setSwallowsTouch(true)
    self.rootItems["closeButton"]:setTouchPriority(self.touchPriority)

    --购买
    self.rootItems["buyButton"]:addHandleOfControlEvent(function()
        print("购买")
        if self.selectPropIndex then
            local data = self.curShowShopData[(self.curPage - 1)*self.goodsShowNum + self.selectPropIndex]
            if data then
                gameWindows:openWindow("tradingShopBuy",{data = data,currency = self.currency})
            else
                runGamePrompt({msg=gameConfig.strings:string_common("tradingShop",29)})
            end
            
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["buyButton"]:setSwallowsTouch(true)
    self.rootItems["buyButton"]:setTouchPriority(self.touchPriority)

    --搜索
    local inputcontent = ""
    local beginFunc = function()
        inputcontent = ""
    end

    local endFunc = function(text)
        inputcontent = text
        self.searchText = text
    end

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 40,
            fontColor = ccc3(255, 255, 255),
            -- PlaceHolder = "点击输入",
            PlaceHolder = gameConfig.strings:string_common("popups","put_wd"),
            length = 12
        })
    self.input:setTouchPriority(self.touchPriority)


    --搜索
    self.rootItems["searchbutton"]:addHandleOfControlEvent(function()
        print("搜索")


        if self.searchText == "" then
            runGamePrompt({msg=gameConfig.strings:string_common("tradingShop",37)})
            return
        end

        self:resetMenuData()

    end, CCControlEventTouchUpInside)
    self.rootItems["searchbutton"]:setSwallowsTouch(true)
    self.rootItems["searchbutton"]:setTouchPriority(self.touchPriority)


    --关注
    self.rootItems["focusbutton"]:addHandleOfControlEvent(function()
        self:touchfocus()
    end, CCControlEventTouchUpInside)
    self.rootItems["focusbutton"]:setSwallowsTouch(true)
    self.rootItems["focusbutton"]:setTouchPriority(self.touchPriority)


    --我的货架
    self.rootItems["shelvesbutton"]:addHandleOfControlEvent(function()
        
        self:touchshelves()
    end, CCControlEventTouchUpInside)
    self.rootItems["shelvesbutton"]:setSwallowsTouch(true)
    self.rootItems["shelvesbutton"]:setTouchPriority(self.touchPriority)

    --说明
    self.rootItems["rulebutton"]:addHandleOfControlEvent(function()
        self:rule()
    end, CCControlEventTouchUpInside)
    self.rootItems["rulebutton"]:setSwallowsTouch(true)
    self.rootItems["rulebutton"]:setTouchPriority(self.touchPriority-3)
    

     --刷新按钮
    self.rootItems["freshbutton"]:addHandleOfControlEvent(function()
        self:resetMenuData()
    end, CCControlEventTouchUpInside)
    self.rootItems["freshbutton"]:setSwallowsTouch(true)
    self.rootItems["freshbutton"]:setTouchPriority(self.touchPriority)

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchy = y
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(y - self.touchy) > 10 then
            self.isContentScroll = true
        end
    end

    local function ccTouchEnded(x, y)

        if self.propInfoCCB and (not ui.isTouched(self.propInfoCCB,x,y)) then
            self.propInfoCCB:setVisible(false)
        end

        self:rule(true)
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority - 1, false)
    self.rootItems.touchLayer:setTouchEnabled(true)
end

function tradingShop.requestCurrencyData(self)
    --currency 当前货币数量
    self:requestData("currency",{},true)
end

function tradingShop.setGoodsProtectData(self,data)
    self.goodsProtectData = data
end

function tradingShop.rule(self,close)
    if close and not self.ruleVisable then
        return
    end

    local animationManager = getAnimationManager(self.rootItems)
    animationManager:runAnimationsForSequenceNamed(self.ruleVisable and "close" or "open")
    self.ruleVisable = (not self.ruleVisable)
    gameTouch:clickprofbytime(0.3)
end

--点击关注按钮

function tradingShop.resetFocusData(self)
    self.focusGoods = {}
    self:requestData("query",self:makeRequestParam(1),true)
end
function tradingShop.touchfocus(self)
    printT(self.focusGoods,"关注")
    
    self.rootItems.sortnode:setVisible(false)
    self.rootItems.searchnode:setVisible(false)
    self.rootItems.selectnode:removeAllChildrenWithCleanup(true)

    self:resetTurningForFixed(1)
    self:resetMenuStatus(0,self.buyMenuPos2)

    if self.focusGoods.data and next(self.focusGoods.data) then
        self:responseFocusGoods()
    else
        self:requestData("query",self:makeRequestParam(1),true)
    end
end


function tradingShop.resetShelvesData(self)
    self.mySellGoods = {}
    self:requestData("query",self:makeRequestParam(3),true)
end

--点击货架按钮
function tradingShop.touchshelves(self)

    printT(self.mySellGoods,"我的货架")
    ui.setLabelString(self.rootItems.tiplabel,gameConfig.strings:string_common("tradingShop",12),93)

        --选中 我的货架
    self.rootItems.proplist:setVisible(true)
    self.rootItems.myproplist:setVisible(false)

    self:resetTurningForFixed(1)
    self:resetMenuStatus(0,self.sellMenuPos2)

    if self.mySellGoods.data and next(self.mySellGoods.data) then
        self:responseMySellGoods()
    else
        self:requestData("query",self:makeRequestParam(3),true)
    end

end

function tradingShop.resetSearch(self)
    self.searchText = ""
    self.input:setText("")
end

function tradingShop.reloadSelectMenu(self )

    self.rootItems.selectnode:removeAllChildrenWithCleanup(true)
    self.selectId = -1

    if self.selectpage ~= "buy" or self.buyMenuPos1 == 0 then
        return
    end


    local config = gamedata.config.transaction_search[tostring(self.buyMenuPos1)][tostring(self.buyMenuPos2)]
    if config.number ~= 1 then
        local selectdata = {}
        selectdata[1] = {name = gameConfig.strings:string_common("tradingShop",28)}
        for i=1,config.number do
            if config["sortName"..i] ~= "" then
                table.insert(selectdata,{name = config["sortName"..i]})
            end
        end


        local node = ui.createDropdownList(selectdata,self.touchPriority-1,function (i)
            if i == 1 then
                self.selectId = -1
            else
                self.selectId = i-1
            end
            
            self.curShowShopData = {}
            self:requestData("query",self:makeRequestParam(2),true)
        end)
        self.rootItems.selectnode:addChild(node)

    end
end

function tradingShop.reloadSortButton(self)

    --排序状态  self.sortId 1-单价升序， 2-单价降序 ，3-关注度升序， 4-关注度降序

    if self.selectpage ~= "buy" or self.buyMenuPos1 == 0 then
        self.rootItems.sortnode:setVisible(false)
        return
    end

    self.sortId = -1

    self.rootItems.sortnode:setVisible(true)

    local function setSortStatus()
        for i=1,4 do
            if self.sortId == i then
                setSpriteFrameByName(self.rootItems["sort_sp"..i],"shanghuijiantou1")
            else
                setSpriteFrameByName(self.rootItems["sort_sp"..i],"shanghuijiantou2")
            end
        end
    end

    local config = gamedata.config.transaction_search[tostring(self.buyMenuPos1)][tostring(self.buyMenuPos2)]


    if config.priceAscending == 1 then  --默认单价升序 不显示其他按钮并且单价排序按钮不能点
        self.rootItems["sortnode1"]:setVisible(true)
        self.rootItems["sortnode2"]:setVisible(false)
        self.sortId = 1
        self.rootItems["sortbutton1"]:setTouchEnabled(false)
        setSortStatus()
        return
    else
        self.rootItems["sortnode1"]:setVisible(true)
        self.rootItems["sortnode2"]:setVisible(config.attentionDegreeSort == 1)
        self.rootItems["sortbutton1"]:setTouchEnabled(true)
    end

    setSortStatus()

    --单价排序
    self.rootItems["sortbutton1"]:addHandleOfControlEvent(function()
        
        if self.sortId ~= 1 then
            self.sortId = 1
        else
            self.sortId = 2
        end
        setSortStatus()
        self:resetMenuData()
    end, CCControlEventTouchUpInside)
    self.rootItems["sortbutton1"]:setSwallowsTouch(true)
    self.rootItems["sortbutton1"]:setTouchPriority(self.touchPriority)

    --关注排序
    self.rootItems["sortbutton2"]:addHandleOfControlEvent(function()

        if self.sortId ~= 3 then
            self.sortId = 3
        else
            self.sortId = 4
        end

        setSortStatus()
        self:resetMenuData()

    end, CCControlEventTouchUpInside)
    self.rootItems["sortbutton2"]:setSwallowsTouch(true)
    self.rootItems["sortbutton2"]:setTouchPriority(self.touchPriority)

end


function tradingShop.makeScreenConfig(self)
    local top = 475     --物品列表离屏幕顶部的距离
    local bottom = 340  --物品列表离屏幕底部的距离
    local height = gameConfig.topposY - top - bottom
    -- 1010
    -- 840

    print(height,"makeScreenConfig")

    local listwidth = 840
    local listheight = height

    if height > 1100 then
        self.goodsShowNum = 12
        self.sellShowNum = 20

        self.adpat = 2

        listheight = 1120
    else
        self.goodsShowNum = 10
        self.sellShowNum = 16

        self.adpat = 1

        listheight = 940
    end

    self.listheight = listheight

    print("makeScreenConfig",bottom + height/2)

    self.rootItems.sortnode:setPositionY(listheight/2 + 60)
    self.rootItems.listnode:setPositionY(bottom + height/2)
    self.rootItems.recordnode:setPositionY(bottom + height/2)
    self.rootItems.proplistbg = tolua.cast(self.rootItems.proplistbg, "CCScale9Sprite")
    self.rootItems.proplistbg:setPreferredSize(CCSizeMake(listwidth,listheight))

end

local sortParams = {
    [1] = "item_price-asc",
    [2] = "item_price-desc",
    [3] = "favorites-asc",
    [4] = "favorites-desc",
}

function tradingShop.makeRequestParam(self,_type)
    local params = { type = _type,num = self:requestNumStr(_type)}

    if _type == 2 then
        params.menu = self["buyMenuPos1"].."-"..self["buyMenuPos2"]
        params.keyword = self.searchText
        params.filter = self.selectId ~= -1 and self.selectId or ""
        params.sort = sortParams[self.sortId] or ""
    end
    return params
end

function tradingShop.requestNumStr(self,_type)
    if _type == 1 then
        return "1-"..tonumber(gamedata.config.global_kv.trade_focus.value)
    elseif _type == 3 then
        return "1-"..tonumber(gamedata.config.global_kv.trade_sell_num.value)
    else
        local maxnum = #self.curShowShopData
        local startIndex = math.floor(maxnum/self.goodsShowNum) * self.goodsShowNum + 1
        local endIndex = startIndex + self.goodsShowNum*self.requestPage - 1
        return startIndex.."-"..endIndex
    end
end


-- [1] = {status = 0,ccb = ccb,items = items,child = {{ccb = ccb,items = items},{ccb = ccb,items = items},{ccb = ccb,items = items}}},
-- [2] = {status = 0,ccb = ccb,items = items,child = {{ccb = ccb,items = items},{ccb = ccb,items = items},{ccb = ccb,items = items}}},
-- [3] = {status = 0,ccb = ccb,items = items,child = {{ccb = ccb,items = items},{ccb = ccb,items = items},{ccb = ccb,items = items}}},

function tradingShop.reoladBuyMenu(self)
    
    self.rootItems.buyScroll = tolua.cast(self.rootItems.buyScroll, "CCScrollView")
    self.rootItems.buyScroll:setViewSize(CCSizeMake(self.menuViewSize.x,self.menuViewSize.y))
    self.rootItems.buyScroll:setTouchPriority(self.touchPriority+1)

    printT(gamedata.config.transaction_search,"transaction_search")

    self.buyMenus = {
    }

    self.buyMenuNode = CCNode:create()
    self.buyMenuNode:setPositionY(self.bellHeight)  --120 铃铛高度
    self.rootItems.buycontainer:addChild(self.buyMenuNode)


    for i=1,table.getTableLength(gamedata.config.transaction_search) do
        local config = gamedata.config.transaction_search[tostring(i)]
        self.buyMenus[i] = {status = 0}
        self.buyMenus[i].ccb,self.buyMenus[i].items = CCBReaderLoad("shanghui/cell_button1", nil, true, "cell_button1")
        self.buyMenus[i].ccb:setPosition(self.menuCellSize.x/2,self.menuCellSize.y*table.getTableLength(gamedata.config.transaction_search) - self.menuCellSize.y*i)
        self.buyMenuNode:addChild(self.buyMenus[i].ccb)

        --最后一个现实铃铛
        if i == table.getTableLength(gamedata.config.transaction_search) then
            self.buyMenus[i].items.appendnode:setVisible(true)
        end

        setSpriteFrameByName(self.buyMenus[i].items.icon,"shanghuibt_"..i)


        self.buyMenus[i].items.menubutton:setTouchPriority(self.touchPriority)
        self.buyMenus[i].items.menubutton:addHandleOfControlEvent(function()
            if self.isContentScroll then return end
            self:touchMenu("buy",i,0)
        end, CCControlEventTouchUpInside)

        self.buyMenus[i].child = {}
        for j=1,(table.getTableLength(gamedata.config.transaction_search[tostring(i)]) - 1) do
            self.buyMenus[i].child[j] = {}
            local childConfig = gamedata.config.transaction_search[tostring(i)][tostring(j)]
            self.buyMenus[i].child[j].ccb,self.buyMenus[i].child[j].items = CCBReaderLoad("shanghui/cell_button2", nil, true, "cell_button2")
            self.buyMenus[i].child[j].ccb:setVisible(false)
            self.buyMenus[i].items.childnode:addChild(self.buyMenus[i].child[j].ccb)
            self.buyMenus[i].child[j].items.menuname:setString(childConfig.name)

            self.buyMenus[i].child[j].items.menubutton:setTouchPriority(self.touchPriority)
            self.buyMenus[i].child[j].items.menubutton:addHandleOfControlEvent(function()
                if self.isContentScroll then return end
                self:touchMenu("buy",i,j)
            end, CCControlEventTouchUpInside)
        end


    end


    self.rootItems.buyScroll:setContentSize(self:calculateMeunSize("buy"))
    self.rootItems.buyScroll:setContentOffset(ccp(0,self.menuViewSize.y  - self.bellHeight - self.menuCellSize.y*table.getTableLength(gamedata.config.transaction_search)))

end

function tradingShop.reoladSellMenu(self)
    
    self.rootItems.sellScroll = tolua.cast(self.rootItems.sellScroll, "CCScrollView")
    self.rootItems.sellScroll:setViewSize(CCSizeMake(self.menuViewSize.x,self.menuViewSize.y))
    self.rootItems.sellScroll:setTouchPriority(self.touchPriority+1)

    printT(gamedata.config.transaction_sell,"transaction_sell")

    self.sellMenus = {

    }

    self.myCanSellGoods = {
    }

    self.sellMenuNode = CCNode:create()
    self.sellMenuNode:setPositionY(self.bellHeight)
    self.rootItems.sellcontainer:addChild(self.sellMenuNode)

    for i=1,table.getTableLength(gamedata.config.transaction_sell) do
        local config = gamedata.config.transaction_sell[tostring(i)]
        self.sellMenus[i] = {status = 0}

        self.myCanSellGoods[i] = {}

        self.sellMenus[i].ccb,self.sellMenus[i].items = CCBReaderLoad("shanghui/cell_button1", nil, true, "cell_button1")
        self.sellMenus[i].ccb:setPosition(self.menuCellSize.x/2,self.menuCellSize.y*table.getTableLength(gamedata.config.transaction_sell) - self.menuCellSize.y*i)
        self.sellMenuNode:addChild(self.sellMenus[i].ccb)

        --最后一个现实铃铛
        if i == table.getTableLength(gamedata.config.transaction_sell) then
            self.sellMenus[i].items.appendnode:setVisible(true)
        end

        setSpriteFrameByName(self.sellMenus[i].items.icon,"shanghuibt_"..i)

        self.sellMenus[i].items.menubutton:setTouchPriority(self.touchPriority)
        self.sellMenus[i].items.menubutton:addHandleOfControlEvent(function()
            if self.isContentScroll then return end
            self:touchMenu("sell",i,0)
        end, CCControlEventTouchUpInside)

        self.sellMenus[i].child = {}
        for j=1,(table.getTableLength(gamedata.config.transaction_sell[tostring(i)]) - 1) do
            self.sellMenus[i].child[j] = {}

            local childConfig = gamedata.config.transaction_sell[tostring(i)][tostring(j)]
            self.sellMenus[i].child[j].ccb,self.sellMenus[i].child[j].items = CCBReaderLoad("shanghui/cell_button2", nil, true, "cell_button2")
            self.sellMenus[i].child[j].ccb:setVisible(false)
            self.sellMenus[i].items.childnode:addChild(self.sellMenus[i].child[j].ccb)
            self.sellMenus[i].child[j].items.menuname:setString(childConfig.name)

            self.sellMenus[i].child[j].items.menubutton:setTouchPriority(self.touchPriority)
            self.sellMenus[i].child[j].items.menubutton:addHandleOfControlEvent(function()
                if self.isContentScroll then return end
                self:touchMenu("sell",i,j)
            end, CCControlEventTouchUpInside)
        end
    end

    self.rootItems.sellScroll:setContentSize(self:calculateMeunSize("sell"))
    self.rootItems.sellScroll:setContentOffset(ccp(0,self.menuViewSize.y - self.bellHeight - self.menuCellSize.y*table.getTableLength(gamedata.config.transaction_sell)))

end

function tradingShop.calculateMeunSize(self,type)
    local width = 240
    local hight = 0

    for i=1,table.getTableLength(self[type.."Menus"]) do
        hight = hight + self.menuCellSize.y
        if self[type.."Menus"][i].status == 1 then
            for j=1,table.getTableLength(self[type.."Menus"][i].child) do
                hight = hight + self.childCellSize.y
            end
        end
    end
    print(width,hight,"calculateMeunSize")
    return CCSizeMake(width,hight + self.bellHeight)
end


function tradingShop.showMenuAppend(self)
    if self.selectpage == "buy" or self.selectpage == "sell" then
        local menus = self[self.selectpage.."Menus"]

        local theLastOneMenuItem = menus[#menus].items


        local childNum = #(menus[#menus].child)
        local theLastOneChildItem = nil
        if childNum > 0 then
           theLastOneChildItem = menus[#menus].child[childNum].items
        end

         

        if menus[#menus].status == 0 then
            theLastOneMenuItem.appendnode:setVisible(true)

            if theLastOneChildItem then
                theLastOneChildItem.appendnode:setVisible(false)
            end
            
        else
            theLastOneMenuItem.appendnode:setVisible(false)
            if theLastOneChildItem then
                theLastOneChildItem.appendnode:setVisible(true)
            end
        end

    end

end

--重置按钮点击状态
function tradingShop.resetMenuStatus(self,pos1,pos2)

    print("resetMenuStatus",pos1,pos2)

    if self[self.selectpage.."MenuPos1"] ~= 0 then
        --之前按钮值为未选中状态
        -- if self[self.selectpage.."MenuPos2"] == 0 then
        --    self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].items.unselectnode:setVisible(true)
        -- else
        --     self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.unselectnode:setVisible(true)
        --     self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.selectnode:setVisible(false)
        --     self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.menuname:setColor(ccc3(51, 57, 70))
        -- end
        self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].items.unselectnode:setVisible(true)

        if #self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child > 0 then
            self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.unselectnode:setVisible(true)
            self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.selectnode:setVisible(false)
            self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.menuname:setColor(ccc3(51, 57, 70))
        end
        
    end


    self[self.selectpage.."MenuPos1"] = pos1
    self[self.selectpage.."MenuPos2"] = pos2


    if pos1 == 0 then
        return
    end

    --设置当前选中按钮状态
    -- if self[self.selectpage.."MenuPos2"] == 0 then
    --    self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].items.unselectnode:setVisible(false)
    -- else
    --     self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.unselectnode:setVisible(false)
    --     self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.selectnode:setVisible(true)
    --     self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.menuname:setColor(ccc3(240, 198, 127))
    -- end

    self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].items.unselectnode:setVisible(false)

    if #self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child > 0 then
        self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.unselectnode:setVisible(false)
        self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.selectnode:setVisible(true)
        self[self.selectpage.."Menus"][self[self.selectpage.."MenuPos1"]].child[self[self.selectpage.."MenuPos2"]].items.menuname:setColor(ccc3(240, 198, 127))
    end

    

end

--按钮列表点击
function tradingShop.touchMenu(self,type,pos1,pos2)
    print("touchMenu",type,pos1,pos2)
    local menus = self[type.."Menus"]
    local menuNode = self[type.."MenuNode"]

    local childNum = #menus[pos1].child
    if pos2 == 0 and childNum~=0 then --只做展开 或关闭
        pos2 = 1 --展开默认选中第一个
        gameTouch:clickprofbytime(0.3)

        if menus[pos1].status == 0 then --关闭状态

            local speed = 0.3/childNum

            for i,v in ipairs(menus[pos1].child) do
                v.ccb:setVisible(true)
                v.ccb:setPositionY(0)

                
                local delay = CCDelayTime:create((childNum-i)*speed)
                local move = CCMoveBy:create(speed*i,ccp(0,-self.childCellSize.y * i))
                v.ccb:runAction(CCSequence:createWithTwoActions(delay,move))
            end


            for i,v in ipairs(menus) do
                if i>pos1 then
                    local move = CCMoveBy:create(speed*childNum,ccp(0,-self.childCellSize.y * childNum))
                    menus[i].ccb:runAction(move)
                end
            end
            menus[pos1].status = 1

            menuNode:setPositionY(menuNode:getPositionY() + self.childCellSize.y * childNum)
        elseif menus[pos1].status == 1 then --打开状态
            for i,v in ipairs(menus[pos1].child) do
                v.ccb:setVisible(false)
            end

            for i,v in ipairs(menus) do
                if i>pos1 then
                    local action = CCMoveBy:create(0.1,ccp(0,self.childCellSize.y * childNum))
                    menus[i].ccb:runAction(action)
                end
            end
            menus[pos1].status = 0
            menuNode:setPositionY(menuNode:getPositionY() - self.childCellSize.y * childNum)

            -- self:resetMenuStatus(pos1,pos2)
            self.rootItems[type.."Scroll"]:setContentSize(self:calculateMeunSize(type))
            self.rootItems[type.."Scroll"]:setContentOffset(ccp(0,self.menuViewSize.y - self.rootItems[type.."Scroll"]:getContentSize().height))
            self:showMenuAppend()
            return
        end

        self.rootItems[type.."Scroll"]:setContentSize(self:calculateMeunSize(type))
        self.rootItems[type.."Scroll"]:setContentOffset(ccp(0,self.menuViewSize.y - self.rootItems[type.."Scroll"]:getContentSize().height))
        self:showMenuAppend()
    end

    self:resetMenuStatus(pos1,pos2)
    if type == "buy" then
        self:resetSearch()
        self:reloadSortButton()
        self:reloadSelectMenu()
        self:resetMenuData()
    elseif type == "sell" then
        ui.setLabelString(self.rootItems.tiplabel,gamedata.config.transaction_sell[tostring(self["sellMenuPos1"])][tostring(self["sellMenuPos2"])].dec,93)
        self.rootItems.proplist:setVisible(false)
        self.rootItems.myproplist:setVisible(true)
        self:resetTurningForFixed(2)
        self:reloadCanSellData()
    end
end



--翻页功能重置 type 为请求数据类型 只针对查询
function tradingShop.resetTurningForRequest(self)
    --上一页
    self.curPage = 1
    self.maxPage = 1
    self:pageNumShow()

    self.rootItems["previousPage"]:addHandleOfControlEvent(function()
        print("上一页")
        if self.curPage == 1 then
            print("当前第一页")
            return
        end
        
        self.curPage = self.curPage - 1
        self:pageNumShow()
        self:freshShopPropShow()
        
    end, CCControlEventTouchUpInside)
    self.rootItems["previousPage"]:setSwallowsTouch(true)
    self.rootItems["previousPage"]:setTouchPriority(self.touchPriority)
        
    --下一页
    self.rootItems["nextPage"]:addHandleOfControlEvent(function()
        print("下一页")
        if self.curPage + 1 > self.maxPage then
            print("当前最后一页")
            return
        end
        self.curPage = self.curPage + 1
        self:pageNumShow()

        --先判断本页有没有数据 请求+loading  或者 当前页为最后一页 请求+loading
        if (not self.curShowShopData[(self.curPage-1)*self.goodsShowNum+1])  then
            print("没有数据 可能网络断开")
            self:requestData("query",self:makeRequestParam(2),true)
        elseif self.curPage == self.maxPage then
            print("当前最后一页,请求+loading")
            self:requestData("query",self:makeRequestParam(2),true)
        --     local params = self:makeRequestParam(2)
        --     local startIndex = (self.curPage - 1)*self.goodsShowNum + 1
        --     local endIndex = (self.curPage - 1)*self.goodsShowNum  + self.goodsShowNum * self.requestPage
        --     params.num = startIndex.."-"..endIndex
        --     print("当前最后一页，需要请求还有没有数据")
        --     self:requestData("query",params,true)
        else
            --判断本页是否是请求数据页 之前请求过的不在请求
            if (self.curPage%self.requestPage == 0) and (not self.curShowShopData[self.curPage*self.goodsShowNum + 1] ) then
                self:requestData("query",self:makeRequestParam(2))
            end
            self:freshShopPropShow()
        end

    end, CCControlEventTouchUpInside)
    self.rootItems["nextPage"]:setSwallowsTouch(true)
    self.rootItems["nextPage"]:setTouchPriority(self.touchPriority)
        
end

--固定数据的翻页
function tradingShop.resetTurningForFixed(self,type)
    --上一页
    self.curPage = 1
    self.maxPage = 1
    self:pageNumShow()

    self.rootItems["previousPage"]:addHandleOfControlEvent(function()
        print("上一页")
        if self.curPage == 1 then
            print("当前第一页")
            return
        end
        
        self.curPage = self.curPage - 1
        self:pageNumShow()

        if type == 1 then
            self:freshShopPropShow()
        elseif type == 2 then
            self:reloadCanSellData()
        end
        
    end, CCControlEventTouchUpInside)
    self.rootItems["previousPage"]:setSwallowsTouch(true)
    self.rootItems["previousPage"]:setTouchPriority(self.touchPriority)
        
    --下一页
    self.rootItems["nextPage"]:addHandleOfControlEvent(function()
        print("下一页")
        if self.curPage + 1 > self.maxPage then
            print("当前最后一页")
            return
        end

        self.curPage = self.curPage + 1
        self:pageNumShow()

        if type == 1 then
            self:freshShopPropShow()
        elseif type == 2 then
            self:reloadCanSellData()
        end

    end, CCControlEventTouchUpInside)
    self.rootItems["nextPage"]:setSwallowsTouch(true)
    self.rootItems["nextPage"]:setTouchPriority(self.touchPriority)
        
end

--当前页数 显示
function tradingShop.pageNumShow(self)

    if self.maxPage <= 0 then
        self.maxPage = 1
    end

    self.curPage = math.max(self.curPage,1)
    self.curPage = math.min(self.curPage,self.maxPage)

    self.rootItems.pageNum:setString(self.curPage.."/"..self.maxPage)
end

--点击按钮菜单重置
function tradingShop.resetMenuData(self)
    self.curShowShopData = {}
    self.rootItems.searchnode:setVisible(true)
    self:resetTurningForRequest()
    self:requestData("query",self:makeRequestParam(2),true)
end

function tradingShop.requestData(self,type,params,isloading)
    printT(params,"requestData")
    GameHttpRequest:request(type,params,isloading,function (responsedata)


        if responsedata and responsedata.status == "False" then
            print("验证不通过")
            runGamePrompt({msg=gameConfig.strings:string_common("tradingShop",39)})
            return
        end

        if type == "query" then

            if params.num then
                print(params.num,"params.num")
                local startIndex = tonumber(string.split(params.num,"-")[1])
                for i,v in ipairs(responsedata.data) do
                    v.rank = startIndex
                    startIndex = startIndex + 1
                end
            end

            if params.type == 1 then
                self:responseFocusGoods(responsedata,isloading)
            elseif params.type == 3 then
                self:responseMySellGoods(responsedata,isloading)
            elseif params.type == 2 then
                self:responseSearchGoods(responsedata,isloading)
            end
        elseif type == "currency" then
            self:responseCurrency(responsedata)
        elseif type == "tradingRecord" then
            self:responseMyRecordData(responsedata)
        elseif type == "focuses" then
            self:responseFocuses(responsedata,params.ext)
        elseif type == "worldMin" then
            self:responseWorldMinForGoods(responsedata,params.ext)
        end
    end)
end

--市场最低价
function tradingShop.responseWorldMinForGoods(self,responsedata,data)
    printT(responsedata,"responseWorldMinForGoods")
    gameWindows:openWindow("tradingShopSell",{data = data,alreadySellNum = #self.mySellGoods.data,minPrice = responsedata.price})
end


--关注接口
function tradingShop.responseFocuses(self,responsedata,data)
    printT(data,"responseFocuses")
    self.focusGoods = {} --关注内容置空

    if responsedata.status == "True" then
        runGamePrompt({msg=gameConfig.strings:string_common("tradingShop",27)})
    else
        runGamePrompt({msg=responsedata.msg})
    end

    self.curShowShopData[data.rank].isFocus = true
    self:freshShopPropShow()

end

function tradingShop.responseCurrency(self,data)
    printT(data,"responseCurrency")
    self.currency = data.consume

    ui.setLabelString(self.rootItems.currency,self.currency,92)
end

function tradingShop.responseFocusGoods(self,data)
    printT(data,"responseFocusGoods")

    if data then
        for i,v in ipairs(data.data) do
            v.isFocus = true
        end

        self.focusGoods = data
    end
    
    if self.selectpage == "buy" and self["buyMenuPos1"] == 0 then
        self.curShowShopData = self.focusGoods.data
        self.maxPage = math.max(1,math.ceil(self.focusGoods.total/self.goodsShowNum))
        self:pageNumShow()
        self:freshShopPropShow()
    end

end


function tradingShop.responseMySellGoods(self,data)
    printT(data,"responseMySellGoods")

    if data then
        self.mySellGoods = data
    end
    
    if self.selectpage == "sell" and self["sellMenuPos1"] == 0 then
        self.maxPage = math.max(1,math.ceil(self.mySellGoods.total/self.goodsShowNum))
        self:pageNumShow()

        self.curShowShopData = self.mySellGoods.data
        self:freshShopPropShow()
    end
end


function tradingShop.responseSearchGoods(self,data,isloading)
    printT(data,"responseSearchGoods")

    local foucusList = {}
    for i,v in ipairs(data.isFocus) do
        foucusList[v] = true
    end

    for i,v in pairs(data.data) do
        if foucusList[v.sell_id] then
            v.isFocus = true
        end
        self.curShowShopData[v.rank] = v
    end


    self.maxPage = math.max(1,math.ceil(data.total/self.goodsShowNum))



    self:pageNumShow()


    if isloading then

        if #self.curShowShopData == 0 then
            runGamePrompt({msg=gameConfig.strings:string_common("tradingShop",38)})
        end

        self:freshShopPropShow()

    end

    
end

--[[ 出售道具结构
{
    [1] = {
        [0] = {{iid = 1,cid = 1,item_num = 1},{iid = 1}}
    },
    [2] = {}
}
]]--

--出售回调
function tradingShop.sellCallback(self)
    
    self:resetShelvesData()

    
    if self.selectpage == "sell" and self.sellMenuPos1 ~= 0 then
        --请求数据
        UIRequest({ type = 61200, pos1 = self.sellMenuPos1, pos2 = self.sellMenuPos2})
    else
        --货架里面重新上架
        --更新可出售道具
        GameScene:addUpdate(61200)
    end
end

function tradingShop.requestCanSellData(self)
    if self.selectpage == "sell" and self.sellMenuPos1 ~= 0 then
        --请求数据
        UIRequest({ type = 61200, pos1 = self.sellMenuPos1, pos2 = self.sellMenuPos2})
    end
end

--加载出售页面
function tradingShop.reloadCanSellData(self,data)

    if GameScene:checkUpdate(61200,nil,true) then
        self:requestCanSellData()
        return
    end

    if data then
        self.myCanSellGoods[data.pos1][data.pos2] = data.data
    end

    printT(self.myCanSellGoods,"reloadCanSellData")
    if not self.myPropListCCB then
        self.myPropListCCB,self.myPropListItems = CCBReaderLoad(self.adpat == 1 and "shanghui/listprop2_1" or "shanghui/listprop2_2", nil, true, "listprop2")
        self.rootNode:setPosition(0,0)
        self.rootItems.myproplist:addChild(self.myPropListCCB)


        --此处没搞懂
        for i=1,self.sellShowNum do
            self.myPropListItems["prop"..i]:setVisible(false)
        end
    end

    --请求过数据
    if self.myCanSellGoods[self.sellMenuPos1][self.sellMenuPos2] then
            
        printT(self.myCanSellGoods[self.sellMenuPos1][self.sellMenuPos2],"self.myCanSellGoods[self.sellMenuPos1][self.sellMenuPos2]")

        if next(self.myCanSellGoods[self.sellMenuPos1][self.sellMenuPos2]) then
            self.maxPage = math.ceil(table.getTableLength(self.myCanSellGoods[self.sellMenuPos1][self.sellMenuPos2])/self.sellShowNum)

            print(self.maxPage,"self.maxPage")
            self:pageNumShow()

            --有数据直接显示
            for i=1,self.sellShowNum do

                local _data = self.myCanSellGoods[self.sellMenuPos1][self.sellMenuPos2][tostring((self.curPage-1) * self.sellShowNum + i)]

                if _data then
                    self.myPropListItems["prop"..i]:setVisible(true)
                    self:setMyPropCell(_data,i)
                else
                    self.myPropListItems["prop"..i]:setVisible(false)
                end
            end
        else
            for i=1,self.sellShowNum do
                self.myPropListItems["prop"..i]:setVisible(false)
            end
        end

        self:setTip()

    else
        --请求数据
        self:requestCanSellData()
    end
end



function tradingShop.setMyPropCell(self,data,index)

    self.myPropListItems["i_ext"..ui.ccbNameEx(index-1)]:removeAllChildrenWithCleanup(true)

    local transaction_itemConfig = gamedata.config.transaction_itemType[tostring(data.cid)]

    --添加保护期标题
    if transaction_itemConfig.itemType == 2 then
        local protectTime = nil
        if self.goodsProtectData[tostring(transaction_itemConfig.itemType)] then
            protectTime = self.goodsProtectData[tostring(transaction_itemConfig.itemType)][tostring(data.iid)]
        end
         
        if protectTime then
            
            if protectTime.endtime - gamedata:time() > 0 then
                data.protectTime = protectTime.endtime
                print("setMyPropCell",protectTime.endtime,gamedata:time(),index)
                local sprite = CCSprite:create()
                setSpriteFrameByName(sprite,"biaoti_baohuqi")
                sprite:setPosition(-36,36)
                self.myPropListItems["i_ext"..ui.ccbNameEx(index-1)]:addChild(sprite)
            end
        end
    end

    ui.setNewIcon(self.myPropListItems, {cid = data.cid, num = data.num}, index - 1)

    self.myPropListItems["i_button"..ui.ccbNameEx(index-1)]:addHandleOfControlEvent(function()
        self:requestData("worldMin",{cid = data.cid,type = data.extCond and data.extCond or "",ext = data},true)
    end, CCControlEventTouchUpInside)
    self.myPropListItems["i_button"..ui.ccbNameEx(index-1)]:setSwallowsTouch(true)
    self.myPropListItems["i_button"..ui.ccbNameEx(index-1)]:setTouchPriority(self.touchPriority)
end

function tradingShop.setTip(self)
    
    self.rootItems.noFocusTip:setVisible(false)
    self.rootItems.noCanBuyTip:setVisible(false)
    self.rootItems.noSellTip:setVisible(false)
    self.rootItems.noCanSellTip:setVisible(false)

    if self.selectpage == "buy" then

        if self.buyMenuPos1 == 0 then
            --关注
            self.rootItems.noFocusTip:setVisible(not next(self.curShowShopData))
        else
            --商品查询
            self.rootItems.noCanBuyTip:setVisible(not next(self.curShowShopData))
        end

    elseif self.selectpage == "sell" then
        if self.sellMenuPos1 == 0 then
            --货架
            self.rootItems.noSellTip:setVisible(not next(self.curShowShopData))
        else
            --背包数据
            self.rootItems.noCanSellTip:setVisible(not next(self.myCanSellGoods[self.sellMenuPos1][self.sellMenuPos2]))
        end

    end
end

--请求商店当前展示页面的数据 刷新当前页面显示 一般购买之后调用
--rank为商品的位置 只刷新商品后面的数据
function tradingShop.resetShopCurShow(self,rank)
    
    print("resetShopCurShow")

    for i=1,#self.curShowShopData do
        if i >= rank then
            self.curShowShopData[i] = nil
        end
    end
    if self.selectpage == "buy" then

        if self.buyMenuPos1 ~= 0 then
            local startIndex = (self.curPage - 1)*self.goodsShowNum + 1
            local endIndex = (self.curPage - 1)*self.goodsShowNum  + self.goodsShowNum * self.requestPage
            local params = self:makeRequestParam(2)
            params.num = startIndex.."-"..endIndex
            self:requestData("query",params,true)
        else
            --关注里面购买
            self:resetFocusData()
        end
        
    end
end


--刷新商店信息
function tradingShop.freshShopPropShow(self)

    printT(self.curShowShopData,"freshShopPropShow")
    print(self.curPage,"self.curPage")
    if not self.propListCCB then
        self.propListCCB,self.propListItems = CCBReaderLoad(self.adpat == 1 and "shanghui/listprop1_1" or "shanghui/listprop1_2", nil, true, "listprop")
        self.rootItems.proplist:addChild(self.propListCCB)
        
    end

    if self.selectPropIndex then
        self.propListItems["propSelect"..ui.ccbNameEx(self.selectPropIndex-1)]:setVisible(false)
    end
    
    self.selectPropIndex = nil
    self.rootItems.doNode:setVisible(false)

    -- self.propListItems["propSelect"..ui.ccbNameEx(self.selectPropIndex-1)]:setVisible(true)

    --计算第一个商品的起始index

    for i=1,self.goodsShowNum do

        local _data = self.curShowShopData[ (self.curPage-1) * self.goodsShowNum + i]

        if  _data then
            self.propListItems["prop"..i]:setVisible(true)
            self:setGoodsCell(_data,i)
        else
            self.propListItems["prop"..i]:setVisible(false)
        end
    end

    self:setTip()
end


function tradingShop.setGoodsCell(self,data,index)

    printT(data,"setGoodsCell")

    local config = ui.IDconfig(data.cid)
    ui.setNewIcon(self.propListItems, {cid = data.cid, num = data.item_num}, index - 1)

    self.propListItems["selectbutton"..ui.ccbNameEx(index-1)]:addHandleOfControlEvent(function()


        if self.sellMenuPos1 == 0 and self.selectpage == "sell"  then
            --我的货架 直接弹出下架窗口
            gameWindows:openWindow("tradingShopCancel",data)
        else

            if self.selectPropIndex then
                self.propListItems["propSelect"..ui.ccbNameEx(self.selectPropIndex-1)]:setVisible(false)
            end

            self.selectPropIndex = index
            self.propListItems["propSelect"..ui.ccbNameEx(self.selectPropIndex-1)]:setVisible(true)

            self.rootItems.doNode:setVisible(true)
        end

    end, CCControlEventTouchUpInside)
    self.propListItems["selectbutton"..ui.ccbNameEx(index-1)]:setSwallowsTouch(true)
    self.propListItems["selectbutton"..ui.ccbNameEx(index-1)]:setTouchPriority(self.touchPriority)


    --关注
    self.propListItems["focusbutton"..ui.ccbNameEx(index-1)]:addHandleOfControlEvent(function()

        if not data.isSelf then
            if table.getTableLength(self.focusGoods.data) >= tonumber(gamedata.config.global_kv.trade_focus.value) then
                runGamePrompt({msg=gameConfig.strings:string_common("tradingShop",23)})
            elseif data.isFocus then
                runGamePrompt({msg=gameConfig.strings:string_common("tradingShop",26)})
            else
                self:requestData("focuses",{sell_id = data.sell_id,ext = data},true)
            end
        else
            runGamePrompt({msg=gameConfig.strings:string_common("tradingShop",31)})
        end
        
        
    end, CCControlEventTouchUpInside)
    self.propListItems["focusbutton"..ui.ccbNameEx(index-1)]:setSwallowsTouch(true)
    self.propListItems["focusbutton"..ui.ccbNameEx(index-1)]:setTouchPriority(self.touchPriority-1)


    self.propListItems["i_button"..ui.ccbNameEx(index-1)]:addHandleOfControlEvent(function()

        self:showGoodsInfo(data)
        
        local x = 0
        local y = 0

        if index%2 == 1 then
            x = -330
        else
            x = -600
        end

        local curline = math.ceil(index/2)
        local allline = self.goodsShowNum/2
        if curline >  math.ceil(allline/2) then
            --向上
            self.propInfoCCB:setAnchorPoint(ccp(0,0))
        else
            self.propInfoCCB:setAnchorPoint(ccp(0,1))
        end

        y = self.listheight/2 - 170/2 - 170 * (curline-1)
        self.propInfoCCB:setPosition(x,y)
    end, CCControlEventTouchUpInside)
    self.propListItems["i_button"..ui.ccbNameEx(index-1)]:setSwallowsTouch(true)
    self.propListItems["i_button"..ui.ccbNameEx(index-1)]:setTouchPriority(self.touchPriority)

    if config.quality >= 7 then
        ui.setLabelString(self.propListItems["name"..ui.ccbNameEx(index-1)],config.name,213)
    else
        ui.setLabelString(self.propListItems["name"..ui.ccbNameEx(index-1)],config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
    end

    self.propListItems["price"..ui.ccbNameEx(index-1)]:setString(data.item_price or 0)
    
    if not self.propListItems["process"..index] then
        local luckSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("obj_xing.png"))
        local process = CCProgressTimer:create(luckSpr)
        process:setAnchorPoint(ccp(0.5,0.5))
        process:setType(kCCProgressTimerTypeBar)
        process:setMidpoint(ccp(1,0))
        process:setBarChangeRate(ccp(0,1))

        self.propListItems["process"..index] = process
        self.propListItems["favoritesnode"..ui.ccbNameEx(index-1)]:addChild(process)
    end

    --关注度最大显示90% 如果是自己关注 显示100%

    if data.isFocus then
        self.propListItems["process"..index]:setPercentage(100)
    else
        self.propListItems["process"..index]:setPercentage(math.min(9,data.favorites)/10*100)
    end


    print("showTimed",data.cid)
    local transaction_itemConfig = gamedata.config.transaction_itemType[tostring(data.cid)]
    local showTime = transaction_itemConfig["showTime"]

    if data.create_time + showTime <= gamedata:time() then
        setSpriteFrameByName(self.propListItems["title"..ui.ccbNameEx(index-1)],"biaoti_guoqi")
    elseif data.create_time + transaction_itemConfig.publicityTime > gamedata:time() then
        setSpriteFrameByName(self.propListItems["title"..ui.ccbNameEx(index-1)],"biaoti_gongshiqi")
    -- elseif conditions then 保护期
    else
        setSpriteFrameByName(self.propListItems["title"..ui.ccbNameEx(index-1)],gameConfig.images.alpha)
    end
end


--点击物品弹信息框
function tradingShop.showGoodsInfo(self,data)

    local transaction_config = gamedata.config.transaction_itemType[tostring(data.cid)]
    local config = ui.IDconfig(data.cid)

    if transaction_config.itemType == 2 then
        --神器
        if not self.allPropInfoCCB[2] then
            self.allPropInfoCCB[2],self.allPropInfoItems[2] = CCBReaderLoad("shanghui/shangpin_xiangqing2", nil, true, "shangpin_xiangqing")
            self.rootItems.proplist:addChild(self.allPropInfoCCB[2])
        end
        self.propInfoCCB = self.allPropInfoCCB[2]
        self.propInfoItems = self.allPropInfoItems[2]

        if data.content then
            local strT = (config.type == 1 and 83 or 82)

            self.propInfoItems.artifactType:setString(gameConfig.strings:string_common("artifact",76 + config.type))

            self.propInfoItems.ischeck:setString(data.content.authenticate == 1 and gameConfig.strings:string_common("artifact",30) or gameConfig.strings:string_common("artifact",31))
            self.propInfoItems.playerName:setString(data.content.builder_name or "")

            self.propInfoItems.attr1:setString(gameConfig.strings:attributeValue(config.attr1,config.attr1Type,data.content.attr1_value))
            self.propInfoItems.attr2:setString(gameConfig.strings:attributeValue(config.attr2,config.attr2Type,data.content.attr2_value))

        end

    else
        if not self.allPropInfoCCB[1] then
            self.allPropInfoCCB[1],self.allPropInfoItems[1] = CCBReaderLoad("shanghui/shangpin_xiangqing", nil, true, "shangpin_xiangqing")
            self.rootItems.proplist:addChild(self.allPropInfoCCB[1])
        end
        self.propInfoCCB = self.allPropInfoCCB[1]
        self.propInfoItems = self.allPropInfoItems[1]

    end

    for k,v in pairs(self.allPropInfoCCB) do
        v:setVisible(false)
    end

    self.propInfoCCB:setVisible(true)
    ui.setLabelString(self.propInfoItems.name,config.name,91)
    
    self.propInfoItems.des:setString(config.desc or "")
    ui.setNewIcon(self.propInfoItems, {cid = data.cid})

end


function tradingShop.shiftPage(self, type)
    print("shiftPage",type)
    self.selectpage = type

    if self.selectpage == "buy" then
        if not self.buyMenus then
            self:reoladBuyMenu()
        end

        if self.buyMenuPos1 == 0 then
            --第一次默认 请求关注信息
            self:touchfocus()
        else
            self:touchMenu("buy",self.buyMenuPos1,self.buyMenuPos2)
        end
        self:setTip()
        -- self:showMenuAppend()

        self.rootItems.proplist:setVisible(true)
        self.rootItems.myproplist:setVisible(false)


        self.rootItems.sellnode:setPositionX(99999)
        self.rootItems.recordnode:setPositionX(99999)

        self.rootItems.buybottomnode:setVisible(true)
        self.rootItems.buynode:setPositionX(0)
        self.rootItems.bottomnode:setVisible(true)
        self.rootItems.listnode:setVisible(true)
    elseif self.selectpage == "sell" then
        if not self.sellMenus then
            self:reoladSellMenu()
        end

        if self.sellMenuPos1 == 0 then
            --第一次默认 请求货架信息
            self:touchshelves()
        else
            self.rootItems.proplist:setVisible(false)
            self.rootItems.myproplist:setVisible(true)

        end
        self:setTip()
        -- self:showMenuAppend()

        self.rootItems.buynode:setPositionX(99999)
        self.rootItems.recordnode:setPositionX(99999)

        self.rootItems.sortnode:setVisible(false)
        self.rootItems.buybottomnode:setVisible(false)
        self.rootItems.bottomnode:setVisible(true)
        self.rootItems.sellnode:setPositionX(0)
        self.rootItems.listnode:setVisible(true)

        self.rootItems.selectnode:removeAllChildrenWithCleanup(true)
    elseif self.selectpage == "record" then

        self.rootItems.buynode:setPositionX(99999)
        self.rootItems.sellnode:setPositionX(99999)
        self.rootItems.bottomnode:setVisible(false)

        self.rootItems.sortnode:setVisible(false)
        self.rootItems.listnode:setVisible(false)
        self.rootItems.recordnode:setPositionX(0)

        self:requestData("tradingRecord",{offest = 20})
        self.rootItems.selectnode:removeAllChildrenWithCleanup(true)

    end

end


function tradingShop.responseMyRecordData(self,data)


    printT(data,"responseMyRecordData")
    if data then
        self.myRecordData = data.data

        table.sort(self.myRecordData,function ( a,b)
            return a.time > b.time
        end)
    end

    if not self.myRecordListView then
        self:createRecordList()
    else
        self.myRecordListView:reloadData()
    end

    self.rootItems.noRecordTip:setVisible(not next(self.myRecordData))
end

function tradingShop.createRecordList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1060, 250)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shanghui/cell_jiaoyijilu", nil, true, "cell_jiaoyijilu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setRecordCell(ccbDocumentControler,a1+1)

            cellCCB:setPosition(1060/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.myRecordData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.myRecordListView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.recordListNode:getContentSize().width,
        viewheight = self.rootItems.recordListNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.recordListNode:addChild(self.myRecordListView)
    self.myRecordListView:setTouchPriority(self.touchPriority)
end

function tradingShop.setRecordCell(self,items,index)

    items.time:setString(gameConfig.strings:timeStr2(self.myRecordData[index].time))
    items.order:setString(self.myRecordData[index].order_no)
    items.content:setString(self.myRecordData[index].content)

    items.copybtn:addHandleOfControlEvent(function()
        if ui.setStringToPasteBoard(self.myRecordData[index].order_no) then
            runGamePrompt({msg = "复制成功"})
        end
    end, CCControlEventTouchUpInside)
    items.copybtn:setSwallowsTouch(true)
    items.copybtn:setTouchPriority(self.touchPriority-1)

    
    -- items.copybtn
end

function tradingShop.initFixedString(self)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("tradingShop",17),19)
end

function tradingShop.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.selectpage = "buy"


    self.buyMenus = nil
    self.sellMenus = nil

    self.buyMenuPos1 = 0
    self.buyMenuPos2 = 0

    self.sellMenuPos1 = 0
    self.sellMenuPos2 = 0

    --道具出售页签
    self.propListCCB = nil
    self.propListItems = nil

    self.myPropListCCB = nil
    self.myPropListItems = nil

    self.selectId = -1  --筛选Id
    self.sortId = -1    --排序Id

    self.searchText = ""
    self.selectPropIndex = nil


    self.curPage = 1
    self.maxPage = 1

    --当前货币
    self.currency = 0

    --当前展示的商品
    self.curShowShopData = {}

    --关注商品
    self.focusGoods = {}

    --我的货架
    self.mySellGoods = {}

    --我的背包数据(以过滤能上架的) 分多级页签 在 reoladSellMenu 初始化表结构
    self.myCanSellGoods = {}

    --背包商品保护期数据
    self.goodsProtectData = {}


    --交易记录
    self.myRecordData = nil
    self.myRecordListView = nil

    --物品信息tip
    self.propInfoCCB = nil
    self.propInfoItems = nil

    self.allPropInfoCCB = {}
    self.allPropInfoItems = {}

    self.ruleVisable = false --说明默认隐藏
end

return tradingShop