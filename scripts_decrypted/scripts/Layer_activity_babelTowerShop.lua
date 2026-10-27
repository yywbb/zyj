--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local shop = {
    CellSize = {x=1080, y=280},
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"one","two","three","four","five"} ,

    pagename = {"一层","二层","三层","四层","五层"},

    selectpage = "one",

    oneListTableView = nil,
    twoListTableView = nil,
    threeListTableView = nil,
    fourListTableView = nil,
    fiveListTableView = nil,

    oneRewardData = {},
    twoRewardData = {},
    threeRewardData = {},
    fourRewardData = {},
    fiveRewardData = {},

    gold = 0,

    rewardconfig = {},

    isscrolltouched = false,

}


--按钮高亮状态的显示
function  shop.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.rootItems["btnspr"..km], "b_n_shangdianzibiaoqian2")
            --self.rootItems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(self.rootItems["btnspr"..km], "b_n_shangdianzibiaoqian1")
            --self.rootItems["buttonnode"..km]:setZOrder(0)
        end
    end
end

function shop.shiftPage(self,type)
    if type and self.selectpage == type then
        return
    end

    if type then
        self.selectpage = type
    end

    self:shiftlayerpage(self.selectpage)

    print("i...am..shiftPage",self.selectpage)

    for k,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            self.rootItems[v.."Node"]:setPositionX(0)
            self.rootItems[v.."Node"]:setVisible(true)
        else
            self.rootItems[v.."Node"]:setPositionX(9999)
            self.rootItems[v.."Node"]:setVisible(false)
        end
    end
    if self.selectpage == "one" then 
        print("onelayer===")
        -- printT(self.oneRewardData)
        self:reloadOneData()
    elseif self.selectpage == "two" then
        print("twolayer===")
        -- printT(self.twoRewardData)
        self:reloadTwoData()
    elseif self.selectpage == "three" then
        print("threelayer===")
        -- printT(self.threeRewardData)
        self:reloadThreedData()
    elseif self.selectpage == "four" then
        print("fourlayer===")
        -- printT(self.fourRewardData)
        self:reloadFourData()
    elseif self.selectpage == "five" then
    	self:reloadFiveData()
    end

end


function shop.init(self,size)
    self.contentsize = size
    self.show = true
    self.rootNode,self.rootItems = CCBReaderLoad("tongtianta/shop", nil, true, "shop")
    
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    -- ui.setLabelString(self.rootItems.golddes, nil, 150)
    
    self.rootItems.oneNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    self.rootItems.twoNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    self.rootItems.threeNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    self.rootItems.fourNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    self.rootItems.fiveNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    
    self.rootItems.scrollnode_touch:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))

   
    --显示页签得按钮
    for k=1,5 do
        self.rootItems["plantitle"..k]:setString(self.pagename[k])
        self.rootItems["btnnode"..k]:setVisible(false)
    end

    -- 去哪按钮
    -- self.rootItems.gotoText:setString("去魔罩")
    ui.setLabelString(self.rootItems.gotoText,gameConfig.strings:string_common("activity_babelTower",2),18)
    self.rootItems.gotoBtn:setSwallowsTouch(true)
    self.rootItems.gotoBtn:setTouchPriority(-105)
    self.rootItems.gotoBtn:addHandleOfControlEvent(function()
        print("gotoBtn===")
        if gameTouch.isScrollling then return end
        -- GameScene:shiftLayerById(209)
        UIRequest({type = 7011})
    end, CCControlEventTouchUpInside)
    
    -- self.rootItems.titlenameLabel:setString(gamedata.config.activity_time[tostring(53)].name)
    -- ui.setLabelString(self.rootItems.activitytimeText, gameConfig.strings:string_common("safemaskshop",2), 13)
    -- self.rootItems.activitytimeText:setString(gameConfig.strings:string_common("safemaskshop",2))


    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","shop",touchbegin)

    local function touchend(pos)
        if self.rootItems.scrollnode_touch and ui.isTouched(self.rootItems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","shop",touchend)

    local _cb = function()
        GameScene:shiftLayerById(426)
    end

    ui.commonBtn(self, self.rootItems, "goBtn", _cb, -103)
    --
    
    return self.rootNode
    -- self:updatetimeFunc()
end


function shop.makeData(self,data)
    self.oneRewardData = {}
    self.twoRewardData = {}
    self.threeRewardData = {}
    self.fourRewardData = {}
    self.fiveRewardData = {}
	for i=1,table.getTableLength(data) do
		local config = gamedata.config.tongtianta_shangdian[tostring(i)]
		if config.page == 1 then
			table.insert(self.oneRewardData,{id = config.id,buyTimes = data[tostring(i)]})
		elseif config.page == 2 then
			table.insert(self.twoRewardData,{id = config.id,buyTimes = data[tostring(i)]})
		elseif config.page == 3 then
			table.insert(self.threeRewardData,{id = config.id,buyTimes = data[tostring(i)]})
		elseif config.page == 4 then
			table.insert(self.fourRewardData,{id = config.id,buyTimes = data[tostring(i)]})
		elseif config.page == 5 then
			table.insert(self.fiveRewardData,{id = config.id,buyTimes = data[tostring(i)]})	
		end
	end
end


function shop.reloadData(self, t)
    data = t.data
    maxMap = t.maxMap
    gold = t.gold
    g_gold = t.g_gold

    -- printT(data,"reloaddata===")
    print("gold===",gold)
    if not self.show then return end
    if gold then
        self.gold = gold
        self.rootItems.gold:setString(self.gold)
    end
    if g_gold then
        self.g_gold = g_gold
        self.rootItems.gold2:setString(self.g_gold)
    end

    if maxMap then
    	self.maxMap = maxMap
    	for i=1,5 do
            self.rootItems["btnnode"..i]:setVisible(true)
            if self.maxMap >= i then
                ui.removeGray("CCSprite",self.rootItems["btnspr"..i])
                ui.removeGray("CCLabelBMFont",self.rootItems["plantitle"..i])
            else
                ui.addGray("CCSprite",self.rootItems["btnspr"..i])
                ui.addGray("CCLabelBMFont",self.rootItems["plantitle"..i])
            end

            self.rootItems["planbutton"..i]:setSwallowsTouch(true)
            self.rootItems["planbutton"..i]:setTouchPriority(-102)
            self.rootItems["planbutton"..i]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                if self.maxMap < i then
                    local config = gamedata.config.tongtianta_dazhangjie[tostring(i)]
                    runGamePrompt({msg = string.format(gameConfig.strings:string_common("activity_babelTower",3), config.name)})
                    return
                end
                self:shiftPage(self.pageconfig[i])
            end,CCControlEventTouchUpInside)
    	end
    end
    self:makeData(data)

    self:shiftPage()
end


function shop.reloadOneData(self)
    print("reloadTwoData==")
    if self.oneListTableView == nil then
        self:createOneList()
    else
        self.oneListTableView:reloadData()
    end
end
function shop.reloadTwoData(self)
    print("reloadTwoData==")

    if self.twoListTableView == nil then
        self:createTwoList()
    else
        self.twoListTableView:reloadData()
    end
end
function shop.reloadThreedData(self)
    print("reloadThreedData==")

    if self.threeListTableView == nil then
        self:createThreeList()
    else
        self.threeListTableView:reloadData()
    end
end
function shop.reloadFourData(self)
    print("reloadFourData==")

    if self.fourListTableView == nil then
        self:createFourList()
    else
        self.fourListTableView:reloadData()
    end
end

function shop.reloadFiveData(self)
    print("reloadFiveData==")

    if self.fiveListTableView == nil then
        self:createFiveList()
    else
        self.fiveListTableView:reloadData()
    end
end


function shop.setone(self,data,items,index)
    print("index==",index)
    local key_Ex
    local icon_key
    if index == nil or index == 1 then
        key_Ex = ""
        icon_key = ""
    else
        key_Ex = "_2"
        icon_key = "_1"
    end

    if not data then
        print("notid===",data.id)
        return
    end

    local config = gamedata.config.tongtianta_shangdian[tostring(data.id)]
   
    if not config  then
        print("notid===",data.id)
        return
    end

    if config.times > 0 then
    	-- local timesstring = gameConfig.strings:string_common("safemaskshop",3)..(config.times-data.buyTimes)..gameConfig.strings:string_common("safemaskshop",4)
        local timesstring = gameConfig.strings:string_common("safemaskshop",3)..(config.times-data.buyTimes)
	    items["desc"..key_Ex]:setString(timesstring)

	    -- if config.times-data.buyTimes == 0 then
	    --     ui.setLabelString(items["desc"..key_Ex],nil,27)
	    -- else
	    --     ui.setLabelString(items["desc"..key_Ex],nil,14)
	    -- end
	    items["desc"..key_Ex]:setVisible(true)
    else
    	items["desc"..key_Ex]:setVisible(false)
    end
    
    local spenddata = ui.getIDandNUMs(config.num)
    local spendConfig = ui.IDconfig(spenddata[1].cid)
    local gold = 0
    if spenddata[1].cid == 20809 then
        gold = self.gold or 0
    elseif spenddata[1].cid == 1025 then
        gold =  self.g_gold or 0
    end
    setSpriteFrameByName(items["goldIcon"..key_Ex], spendConfig.icon)
    
    if gold >= math.floor(spenddata[1].num) then
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata[1].num),14)
    else
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata[1].num),27)
    end

    local id,num = ui.getIDandNUM(config.reward)

    ui.setNewIconName(items,{cid = id, num = num},index-1)
    --
    items["in_button"..icon_key]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end

        ui.setPopwindowByCid(id)
    end, CCControlEventTouchUpInside)
    items["in_button"..icon_key]:setTouchPriority(-102)
    --

    items["exchangeText"..key_Ex]:setString(gameConfig.strings:string_common("safemaskshop",6))
    ui.setLabelString(items["exchangeText"..key_Ex],nil,18)

    items["exchange"..key_Ex]:setTouchPriority(-102)
    items["exchange"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end

        gameTouch:clickprofbytime(0.5)
        if config.times ~= 0 and config.times-data.buyTimes == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("safemaskshop",5)})
        elseif config.times ~= 0 and gold < math.floor(spenddata[1].num) then
        	runGamePrompt({msg = spendConfig.name.."数量不足"})
        else
            print("购买请求＝＝＝")
            function shopExchangeRequest(num)
                if gold < math.floor(spenddata[1].num)*num then
                    runGamePrompt({msg = spendConfig.name.."数量不足"})
                else
                    UIRequest({type = 7018, id = data.id,num = num})
                end
            end
            local exchangeNum = config.times-data.buyTimes
            local spenddata2 = ui.getIDandNUMs(config.num)
            spenddata2[1].num = math.floor(spenddata2[1].num)

            if config.times == 0 then
            	exchangeNum = 999
            end
            if exchangeNum > 5 or config.times == 0 then
                gameWindows:openWindow("shopExchange",{cid = id,num = num,cost = spenddata2,exchangeNum = exchangeNum},shopExchangeRequest)
            else
            	UIRequest({type = 7018, id = data.id,num = 1})
            end    
        end

    end, CCControlEventTouchUpInside)

    if config.times == 0 then
    	ui.removeGray("CCControlButton",items["exchange"..key_Ex])
        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
    else
       	if config.times - data.buyTimes > 0 then
	    	ui.removeGray("CCControlButton",items["exchange"..key_Ex])
	        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
	    else
			ui.addGray("CCControlButton",items["exchange"..key_Ex])
	        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
	    end
    end
    
end

-- createOneList createTwoList createThreeList createFourList
function shop.createOneList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_shop2.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.oneRewardData[(a1+1)*2-1],ccbDocumentControler,1)

            if self.oneRewardData[(a1+1)*2] then
                self:setone(self.oneRewardData[(a1+1)*2],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.oneRewardData)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.oneListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.oneNode:getContentSize().width,
        viewheight = self.rootItems.oneNode:getContentSize().height,
        dire = 1
    })
    self.oneListTableView:setTouchPriority(-101)
    self.rootItems.oneNode:addChild(self.oneListTableView)
end

function shop.createTwoList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_shop2.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.twoRewardData[(a1+1)*2-1],ccbDocumentControler,1)

            if self.twoRewardData[(a1+1)*2] then
                self:setone(self.twoRewardData[(a1+1)*2],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.twoRewardData)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.twoListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.twoNode:getContentSize().width,
        viewheight = self.rootItems.twoNode:getContentSize().height,
        dire = 1
    })
    self.twoListTableView:setTouchPriority(-101)
    self.rootItems.twoNode:addChild(self.twoListTableView)
end

function shop.createThreeList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_shop2.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.threeRewardData[(a1+1)*2-1],ccbDocumentControler,1)

            if self.threeRewardData[(a1+1)*2] then
                self:setone(self.threeRewardData[(a1+1)*2],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.threeRewardData)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.threeListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.threeNode:getContentSize().width,
        viewheight = self.rootItems.threeNode:getContentSize().height,
        dire = 1
    })
    self.threeListTableView:setTouchPriority(-101)
    self.rootItems.threeNode:addChild(self.threeListTableView)
end

function shop.createFourList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_shop2.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.fourRewardData[(a1+1)*2-1],ccbDocumentControler,1)

            if self.fourRewardData[(a1+1)*2] then
                self:setone(self.fourRewardData[(a1+1)*2],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.fourRewardData)/2) 
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.fourListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.fourNode:getContentSize().width,
        viewheight = self.rootItems.fourNode:getContentSize().height,
        dire = 1
    })
    self.fourListTableView:setTouchPriority(-101)
    self.rootItems.fourNode:addChild(self.fourListTableView)
end


function shop.createFiveList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_shop2.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.fiveRewardData[(a1+1)*2-1],ccbDocumentControler,1)

            if self.fiveRewardData[(a1+1)*2] then
                self:setone(self.fiveRewardData[(a1+1)*2],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.fiveRewardData)/2) 
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.fiveListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.fiveNode:getContentSize().width,
        viewheight = self.rootItems.fiveNode:getContentSize().height,
        dire = 1
    })
    self.fiveListTableView:setTouchPriority(-101)
    self.rootItems.fiveNode:addChild(self.fiveListTableView)
end

function shop.clear(self)


    gameTouch:UnrigistFunc("begin","shop")
    gameTouch:UnrigistFunc("end","shop")
    self.show = false

    self.oneListTableView = nil
    self.twoListTableView = nil
    self.threeListTableView = nil
    self.fourListTableView = nil
    self.fiveListTableView = nil

    self.oneRewardData = {}
    self.twoRewardData = {}
    self.threeRewardData = {}
    self.fourRewardData = {}
    self.fiveRewardData = {}

    self.gold = 0

    self.rewardconfig = {}


    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
end


return shop
  a  