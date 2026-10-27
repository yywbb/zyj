--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local safemaskshop = {
    CellSize = {x=1080, y=320},
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"one","two","three","four","five"} ,

    pagename = {},

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

    price1 = 10,
    price2 = 10,
    price3 = 10,
    price4 = 10,
    price5 = 10,
}


--按钮高亮状态的显示
function  safemaskshop.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.rootItems["btnspr"..km], gameConfig.images.pageButtonON)
            --self.rootItems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(self.rootItems["btnspr"..km], gameConfig.images.pageButtonOFF)
            --self.rootItems["buttonnode"..km]:setZOrder(0)
        end
    end
end

function safemaskshop.shiftPage(self,type)
    if type and self.selectpage == type then
        return
    end

    if type == "one" and GameScene.roleinfo.level < gamedata.config.mozhao_shoptype[tostring(1)]["openlv"] then
        runGamePrompt({msg = gameConfig.strings:RoleInfoLev(gamedata.config.mozhao_shoptype[tostring(1)]["openlv"])})
        return
    elseif type == "two" and GameScene.roleinfo.level < gamedata.config.mozhao_shoptype[tostring(2)]["openlv"] then
        runGamePrompt({msg = gameConfig.strings:RoleInfoLev(gamedata.config.mozhao_shoptype[tostring(2)]["openlv"])})
        return
    elseif type == "three" and GameScene.roleinfo.level < gamedata.config.mozhao_shoptype[tostring(3)]["openlv"] then
        runGamePrompt({msg = gameConfig.strings:RoleInfoLev(gamedata.config.mozhao_shoptype[tostring(3)]["openlv"])})
        return
    elseif type == "four" and GameScene.roleinfo.level < gamedata.config.mozhao_shoptype[tostring(4)]["openlv"] then
        runGamePrompt({msg = gameConfig.strings:RoleInfoLev(gamedata.config.mozhao_shoptype[tostring(4)]["openlv"])})
        return
    elseif type == "five" and GameScene.roleinfo.level < gamedata.config.mozhao_shoptype[tostring(5)]["openlv"] then
        runGamePrompt({msg = gameConfig.strings:RoleInfoLev(gamedata.config.mozhao_shoptype[tostring(5)]["openlv"])})
        return
    end

    
    if type then
        self.selectpage = type
    end

    self:shiftlayerpage(self.selectpage)

    for k=1,5 do
        if GameScene.roleinfo.level < gamedata.config.mozhao_shoptype[tostring(k)]["openlv"] then
            ui.addGray("CCSprite",self.rootItems["btnspr"..k])
        else
            ui.removeGray("CCSprite",self.rootItems["btnspr"..k])
        end
    end


    


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
        print("fivelayer===")
        -- printT(self.fiveRewardData)
        self:reloadFiveData()
    end

end


function safemaskshop.init(self,size)
    self.contentsize = size
    self.show = true
    self.rootNode,self.rootItems = CCBReaderLoad("safemask/safemask_shop", nil, true, "safemask_shop")
    -- self.rootNode:setPosition(0,0)
    -- parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)
    -- self.rootItems.oneNode:setPositionY(self.contentsize.y-180-540)
    -- self.rootItems.twoNode:setPositionY(self.contentsize.y-180-540)
    -- self.rootItems.threeNode:setPositionY(self.contentsize.y-180-540)
    -- self.rootItems.fourNode:setPositionY(self.contentsize.y-180-540)

    -- self.rootItems.topnode:setPositionY(toppos)
    -- scoreListNode
    -- rewardListNode

    -- self.rootItems.scoreListNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-380))
    self.rootItems.oneNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-520-160))
    self.rootItems.twoNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-520-160))
    self.rootItems.threeNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-520-160))
    self.rootItems.fourNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-520-160))
    self.rootItems.fiveNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-520-160))
    
    self.rootItems.scrollnode_touch:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-520-160))

    
    -- self:shiftPage()
    -- 页签名字设置
    for i=1,table.getTableLength(gamedata.config.mozhao_shoptype) do
        table.insert(self.pagename,gamedata.config.mozhao_shoptype[tostring(i)].name)
    end

    --显示页签得按钮
    for k=1,table.getTableLength(gamedata.config.mozhao_shoptype) do
        self.rootItems["plantitle"..k]:setString(self.pagename[k])

        self.rootItems["planbutton"..k]:setSwallowsTouch(true)
        self.rootItems["planbutton"..k]:setTouchPriority(-102)
        self.rootItems["planbutton"..k]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            self:shiftPage(self.pageconfig[k])
        end,CCControlEventTouchUpInside)  
    end


    -- 去哪按钮
    -- self.rootItems.gotoText:setString("去魔罩")
    ui.setLabelString(self.rootItems.gotoText,gameConfig.strings:string_common("safemaskshop",8),18)
    self.rootItems.gotoBtn:setSwallowsTouch(true)
    self.rootItems.gotoBtn:setTouchPriority(-105)
    self.rootItems.gotoBtn:addHandleOfControlEvent(function()
        print("gotoBtn===")
        if gameTouch.isScrollling then return end
        GameScene:shiftLayerById(4)
    end, CCControlEventTouchUpInside)

    
    self.rootItems.titlenameLabel:setString(gamedata.config.activity_time[tostring(53)].name)
    self.rootItems.activitytimeText:setString(gameConfig.strings:string_common("safemaskshop",2))




    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","safemaskshop",touchbegin)

    local function touchend(pos)
        if self.rootItems.scrollnode_touch and ui.isTouched(self.rootItems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","safemaskshop",touchend)
    --
    
    return self.rootNode
    -- self:updatetimeFunc()
end



function safemaskshop.reloaddata(self,data,gold)
    -- printT(data,"reloaddata===")
    print("gold===",gold)
    if not self.show then return end

    if gold then
        self.gold = gold
    end
    if data.onerankdata then
        self.oneRewardData = data.onerankdata
    end
    if data.tworankdata then
        self.twoRewardData = data.tworankdata
    end
    if data.threerankdata then
        self.threeRewardData = data.threerankdata
    end
    if data.fourrankdata then
        self.fourRewardData = data.fourrankdata
    end

    if data.fiverankdata then
        self.fiveRewardData = data.fiverankdata
    end


    --
    self.price1 = 10
    self.price2 = 10
    self.price3 = 10
    self.price4 = 10
    self.price5 = 10
    ui.setLabelString(self.rootItems.PriceTimeText,"",22)
    --
    for k,v in pairs(gamedata.config.mozhao_shop) do
        local ispricebegin = false
        local difftime = 0
        if v["week"] and v["week"] ~= "" then
            local nowtime = os.date("*t", gamedata:time())
            local wday = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
            local weeks = string.split(v["week"],";")
            for _i,_v in ipairs(weeks) do
                if wday == tonumber(_v) then
                    ispricebegin = true
                    break
                end
            end
        end

        if ispricebegin then
            self["price"..v.type] = v.labal
            --
            gameTimer:rigistTime("SafemaskshopPrice",difftime)
        end
    end
    --
    if gameTimer.times["SafemaskshopPrice"] and gameTimer.times["SafemaskshopPrice"] > 0 then
        gameTimer:rigistTimeFunc("SafemaskshopPrice", function()
            if gameTimer.times["SafemaskshopPrice"] <= 0 then
                if gameTimer.times["SafemaskshopPrice"] then
                    gameTimer:UnrigistTimeFunc("SafemaskshopPrice")
                    UIRequest({type = 3733})
                end
            else
                ui.setLabelString(self.rootItems.PriceTimeText,"折扣倒计时："..ui.makeTimeDayText(gameTimer.times["SafemaskshopPrice"],"day"),22)
            end
        end)
    end           
    --
    for i = 1,5 do
        if self["price"..i] and self["price"..i] < 10 then
            self.rootItems["zhe"..i]:setVisible(true)
            setSpriteFrameByName(self.rootItems["zhe"..i],self["price"..i].."zhe")
        else
            self.rootItems["zhe"..i]:setVisible(false)
        end
    end

    --
    self:shiftPage()
end


function safemaskshop.reloadOneData(self)
    print("reloadTwoData==")

    if self.oneListTableView == nil then
        self:createOneList()
    else
        -- if self.RankListTableView:getLuaContentOffsetY() < self.rootItems.scoreListNode:getContentSize().height - table.getTableLength(self.rankdata)*205 then
            -- self.RankListTableView:setLuaContentOffset(0, self.rootItems.scoreListNode:getContentSize().height - table.getTableLength(self.rankdata)*100)
        -- end
        self.oneListTableView:reloadData()
    end
end
function safemaskshop.reloadTwoData(self)
    print("reloadTwoData==")

    if self.twoListTableView == nil then
        self:createTwoList()
    else
        self.twoListTableView:reloadData()
    end
end
function safemaskshop.reloadThreedData(self)
    print("reloadThreedData==")

    if self.threeListTableView == nil then
        self:createThreeList()
    else
        self.threeListTableView:reloadData()
    end
end
function safemaskshop.reloadFourData(self)
    print("reloadFourData==")

    if self.fourListTableView == nil then
        self:createFourList()
    else
        self.fourListTableView:reloadData()
    end
end

function safemaskshop.reloadFiveData(self)
    print("reloadFiveData==")

    if self.fiveListTableView == nil then
        self:createFiveList()
    else
        self.fiveListTableView:reloadData()
    end
end

function safemaskshop.setone(self,data,items,index)
    print("index==",index)
    -- printT(data)
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
        -- print("notid===",data.id)
        return
    end

    local config = gamedata.config.mozhao_shop[tostring(data.id)]
    print("i..config...:")
    -- printT(config)
    if not config  then
        print("notid===",data.id)
        return
    end
    -- printT(items,"items===")
    -- print(key_Ex)
    local timesstring = gameConfig.strings:string_common("safemaskshop",3)..(config.times-data.num)..gameConfig.strings:string_common("safemaskshop",4)
    items["desc"..key_Ex]:setString(timesstring)
    if config.times-data.num == 0 then
        ui.setLabelString(items["desc"..key_Ex],nil,27)
    else
        ui.setLabelString(items["desc"..key_Ex],nil,14)
    end
    
    local spenddata = ui.getIDandNUMs(config.num)
    print(self.gold)
    print(spenddata[1].num)
    print()
    print()
    if self.gold >= math.floor(spenddata[1].num*self["price"..config.type]/10) then
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata[1].num*self["price"..config.type]/10),14)
    else
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata[1].num*self["price"..config.type]/10),27)
    end

    if data.status == 1 then
        items["hotnode"..key_Ex]:setVisible(true)
    else
        items["hotnode"..key_Ex]:setVisible(false)
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
        if config.times-data.num == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("safemaskshop",5)})
        elseif self.gold < math.floor(spenddata[1].num*self["price"..config.type]/10) then
            -- runGamePrompt({msg = gameConfig.strings:string_common("safemaskshop",5)})
            shortGold()
        else
            print("购买请求＝＝＝")
            --UIRequest({type = 3734, id = data.id, gold = math.floor(spenddata[1].num*self["price"..config.type]/10)})

            function shopExchangeRequest(num)
                if self.gold < math.floor(spenddata[1].num*self["price"..config.type]/10)*num then
                    shortGold()
                else
                    UIRequest({type = 3734, id = data.id,gold = math.floor(spenddata[1].num*self["price"..config.type]/10),num = num})
                end
            end
            local exchangeNum = config.times-data.num
            local spenddata2 = ui.getIDandNUMs(config.num)
            spenddata2[1].num = math.floor(spenddata2[1].num*self["price"..config.type]/10)
            if exchangeNum > 5 then
                gameWindows:openWindow("shopExchange",{cid = id,num = num,cost = spenddata2,exchangeNum = exchangeNum},shopExchangeRequest)
            else
            UIRequest({type = 3734, id = data.id,gold = math.floor(spenddata[1].num*self["price"..config.type]/10),num = 1})
            end    
        end

    end, CCControlEventTouchUpInside)

    if config.times-data.num == 0 then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    else
        ui.removeGray("CCControlButton",items["exchange"..key_Ex])
        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
    end

end

-- createOneList createTwoList createThreeList createFourList
function safemaskshop.createOneList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("safemask/cell_safemaskshop.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.oneRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.oneRewardData[tostring((a1+1)*2)] then
                self:setone(self.oneRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
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

function safemaskshop.createTwoList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("safemask/cell_safemaskshop.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.twoRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.twoRewardData[tostring((a1+1)*2)] then
                self:setone(self.twoRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
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

function safemaskshop.createThreeList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("safemask/cell_safemaskshop.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.threeRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.threeRewardData[tostring((a1+1)*2)] then
                self:setone(self.threeRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
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

function safemaskshop.createFourList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("safemask/cell_safemaskshop.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.fourRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.fourRewardData[tostring((a1+1)*2)] then
                self:setone(self.fourRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
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

function safemaskshop.createFiveList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("safemask/cell_safemaskshop.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.fiveRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.fiveRewardData[tostring((a1+1)*2)] then
                self:setone(self.fiveRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
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

function safemaskshop.clear(self)

    if gameTimer.times["SafemaskshopPrice"] then
        gameTimer:UnrigistTimeFunc("SafemaskshopPrice")
    end

    gameTouch:UnrigistFunc("begin","safemaskshop")
    gameTouch:UnrigistFunc("end","safemaskshop")
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

    self.price1 = 10
    self.price2 = 10
    self.price3 = 10
    self.price4 = 10
    self.price5 = 10

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
end


return safemaskshop
