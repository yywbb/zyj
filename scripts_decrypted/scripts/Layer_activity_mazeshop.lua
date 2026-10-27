--迷宫商店
--zhangzhixin
--
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:09
-- To change this template use File | Settings | File Templates.
--

local mazeshop = {
    isscrolltouched = false,
    show =  false,
    buttontouch = -103,
    CellSize = {x = 1080 ,y = 320},
    canRefreshTimes = 2,
}

function mazeshop.init(self,size)
    print("mazeshop.init============" )    
    self.contentsize = size
    self.show = true
    self.shopConfig = gamedata.config.maze_shop
    -- printT(self.shopConfig,"self.shopConfig ========")
    self.propsConfig = gamedata.config.props
    self.refreshGoldNum = tonumber(gamedata.config.global_kv.maze_shop_refreshgold.value)
    self.coverccb, self.coveritems = CCBReaderLoad("migong/migong_shop",nil, true, "migong_shop")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.scrollnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-500-180-10))
    ui.setLabelString(self.coveritems.hundanText,nil,21)
    ui.setLabelString(self.coveritems.hundan_Label,nil,31) --????
    ui.setLabelString(self.coveritems.refreshText,nil,14)
    ui.setLabelString(self.coveritems.shuaxindescText,"每天可以获得2次免费次数，之后可用元宝刷新",21)
    ui.setLabelString(self.coveritems.gotolianhuaText,nil,18)
    self.coveritems.gotolianhuaBtn:addHandleOfControlEvent(function()
        print("跳转到迷宫")
        GameScene:shiftLayer("maze","up")
    end, CCControlEventTouchUpInside)
    self.coveritems.gotolianhuaBtn:setSwallowsTouch(true)
    self.coveritems.gotolianhuaBtn:setTouchPriority(self.buttontouch)

    self.coveritems.resetbutton:addHandleOfControlEvent(function()
        print("刷新商店")
        UIRequest({type = 3810 ,refreshGold = self.refreshGoldNum})
    end, CCControlEventTouchUpInside)
    self.coveritems.resetbutton:setSwallowsTouch(true)
    self.coveritems.resetbutton:setTouchPriority(self.buttontouch)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","mazeshop",touchbegin)

    local function touchend(pos)
        if self.coveritems.scrollnode and ui.isTouched(self.coveritems.scrollnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","mazeshop",touchend)
    --

    return self.coverccb
end



function mazeshop.reloaddata(self,data,isreload)
    print(self.show)
    if not self.show then return end

    self.data = data.data
    self.num = data.num
    print("reloaddata===")
    printT(self.data)
    ui.setLabelString(self.coveritems.hundan_Label,self.num,31)
    ui.setLabelString(self.coveritems.refresh_Label,self.data.refeshTimes.."/"..self.canRefreshTimes,14)
    if self.data.refeshTimes > 0 then
        self.coveritems.freeNumNode:setVisible(true)
        self.coveritems.spendGoldNode:setVisible(false)
        ui.setLabelString(self.coveritems.freeNumText,nil,14)
        ui.setLabelString(self.coveritems.freeNum_Label, self.data.refeshTimes,14)
    else
        self.coveritems.freeNumNode:setVisible(false)
        self.coveritems.spendGoldNode:setVisible(true)  
        ui.setLabelString(self.coveritems.spendGoldText,nil,14) 
        ui.setLabelString(self.coveritems.spendGold_Label,self.refreshGoldNum,14)
    end
    self.coveritems.spendlingpaiNode:setVisible(false)
    if isreload == true then
        self.listTableView:reloadData()
    else
        self:createShopList()
    end
end

function mazeshop.clear(self)
    gameTouch:UnrigistFunc("begin","mazeshop")
    gameTouch:UnrigistFunc("end","mazeshop")
    if self.coverccb then
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end

    if self.scrollNode then
        self.scrollNode = nil
        self.scrollItems = nil
    end
    
    self.show = false
    self.data = nil
end

function mazeshop.createShopList(self)
    local celldict = {}

    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellNode = 0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellNode = ui.createNode({ w = self.CellSize.x,h = self.CellSize.y,})
                celldict[a2] = {cellNode=cellNode }

                -- ui.tableviewAnimation(self.listTableView,cellNode,0, 0,a1)
            else
                first = false
                cellNode = celldict[a2].cellNode
            end
            self:setCell(cellNode,self.data.items[tostring(a1*2+1)],self.data.items[tostring(a1*2+2)],a1)

            if self.listTableView then
                cellNode:setPosition(0,0)
            end

            if first then
                a2:addChild(cellNode)
            end
            r = a2

        elseif fn == "numberOfCells" then
            r =  math.ceil(table.getTableLength(self.data.items)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.coveritems.scrollnode:getContentSize().width,
        viewheight = self.coveritems.scrollnode:getContentSize().height,
        dire = 1
    })
    self.coveritems.scrollnode:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.buttontouch)

end
--创建名是遏制额
function mazeshop.setCell(self,aiItems,aiData,aiNextData,aiIndex)

    function cereateCell( items,data,index )
        local tData = self.shopConfig[tostring(data.id)]

        local t = ui.Split(tData.consume,";")
        local usedata,itemsdata = {},{} 
        for k,v in pairs(t) do
            if v ~= "" or v == nil then
                table.insert(usedata,ui.Split(v,","))
            end
        end
        t = ui.Split(tData.good,";")
        for k,v in pairs(t) do
            if v ~= "" or v == nil then
                table.insert(itemsdata,ui.Split(v,","))
            end
        end
        local canBuyTimes = tData.limit
        ui.setLabelString(items.buyDescText,nil,13)
        ui.setLabelString(items.buyBumText,canBuyTimes - data.buyTimes,13)
        ui.setLabelString(items.buyText,nil,18)
        if ui.IDconfig(tonumber(itemsdata[1][1])).staffType == "general_fragment" then
            ui.setLabelString(items.nameText,ui.IDconfig(tonumber(itemsdata[1][1])).name,ui.IDconfig(tonumber(itemsdata[1][1])).quality*2-1)
        elseif ui.IDconfig(tonumber(itemsdata[1][1])).staffType == "equip_fragment" then
            ui.setLabelString(items.nameText,ui.IDconfig(tonumber(itemsdata[1][1])).name,ui.IDconfig(tonumber(itemsdata[1][1])).quality*2-1)
        else
            ui.setLabelString(items.nameText,ui.IDconfig(tonumber(itemsdata[1][1])).name,ui.IDconfig(tonumber(itemsdata[1][1])).quality*2-1)
        end
        if usedata[1][1] == "20268" then
            setSpriteFrameByName(items.currencySpr,"migongbi.png" )
            items.currencySpr:setScale(0.503)
        elseif usedata[1][1] == "1001" then
            setSpriteFrameByName(items.currencySpr,"obj_s_gold.png" )
            items.currencySpr:setScale(1)
        elseif usedata[1][1] == "1000" then
            setSpriteFrameByName(items.currencySpr,"yuanbao1.png" )
            items.currencySpr:setScale(1)
        end
        ui.setLabelString(items.currencyNumText,usedata[1][2],1) 
        ui.setNewIcon(items,{cid = tonumber(itemsdata[1][1])})

        if data.buyTimes >= canBuyTimes then
            items.sellNode:setVisible(true)
        else
            items.sellNode:setVisible(false)
        end
        items.buyButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("请求购买 id = "..index)
            if data.buyTimes >= canBuyTimes then
                runGamePrompt({msg = gameConfig.strings:string_common("maze",2)})
            else
                UIRequest({ type = 3807,id  = index  ,usedata = usedata[1]  })
            end
        end, CCControlEventTouchUpInside)
        items.buyButton:setSwallowsTouch(true)
        items.buyButton:setTouchPriority(self.buttontouch -1)
    end

    if aiData ~= nil then
        local  cellCCB, ccbDocumentControler = CCBReaderLoad("migong/cell_shop", nil, true, "mazeShopCell")
        cereateCell(ccbDocumentControler,aiData,aiIndex*2 + 1)
        aiItems:addChild(cellCCB)
        cellCCB:setPosition(self.CellSize.x*0.25,self.CellSize.y*0.5)
    end    
    if aiNextData ~= nil then
        local  cellCCB, ccbDocumentControler = CCBReaderLoad("migong/cell_shop", nil, true, "mazeShopCell")
        cereateCell(ccbDocumentControler,aiNextData,aiIndex*2 + 2)
        aiItems:addChild(cellCCB)
        cellCCB:setPosition(self.CellSize.x*0.75,self.CellSize.y*0.5)
    end


end

function mazeshop.buyItem( self,aiData )
    self:reloaddata(aiData,true)
end

function mazeshop.refresh( self,aiData)
    print("mazeshop.refresh ===========")
    self:reloaddata(aiData,true)
end
return mazeshop   �$  