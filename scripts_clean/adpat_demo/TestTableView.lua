--
-- Author: songyibo
-- Date: 2018-07-05 15:13:22
--

local TestTableView = class("TestTableView", function ()
    return cc.Layer:create()
end)

function TestTableView:ctor()
	self:init()
end

function TestTableView:init()
    

	self.rootNode,self.rootItems = CCBReaderLoad("UI/rank/paihangbang2", nil, true, "paihangbang")
    self:addChild(self.rootNode)
    self.rootNode:setPosition(cc.p(540,0))

    -- self:CPlusTableView()

    -- self:LuaTableView()
    self:LuaTableViewRecycle()

    
end
 
function TestTableView:LuaTableView( )
    local sizeScroll = self.rootItems.listNode:getContentSize()


    local celldict = {}
    local unrecycleCell = {}
    local _h = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 134)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("UI/rank/cell_paihangbang_2", nil, true, "cell_paihangbang_2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setPosition(1080/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = 20
        elseif fn == "cellTouched" then
            print("cellTouched")
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    local args = {
        handle = _h,
        viewwidth = sizeScroll.width,
        viewheight = sizeScroll.height,
        dire = 1,
        page = 0
    }

    local tableview = LuaTableView:createWithHandler(args.handle, CCSizeMake(args.viewwidth or 0, args.viewheight or 0), nil,
        CCString:create("" .. (args.dire or 1) .. (args.page or 0)))
    self.rootItems.listNode:addChild(tableview)
end

function TestTableView:LuaTableViewRecycle( )
    local sizeScroll = self.rootItems.listNode:getContentSize()


    self.celldict = {}
    self.unrecycleCell = {}
    local _h = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSizeForIndex" then
            local index = a1 + 1
            if index%15 == 0 then
                r = CCSizeMake(1080, 300)
            else
                r = CCSizeMake(1080, 134)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    return false
                end
            end
            return true
        elseif fn == "cellAtIndex" then
            if (a1+1)%15 == 0 then
                local ccb, items
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("UI/rank/cell_paihangbang_1", nil, true, "cell_paihangbang_1")
                    ccb:setPosition(1080/2,0)
                    a2:addChild(ccb)

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                end
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("UI/rank/cell_paihangbang_2", nil, true, "cell_paihangbang_2")
                    self.celldict[a2] = {cell = a2, cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                else
                    first = false
                    cellCCB = self.celldict[a2].cellCCB
                    ccbDocumentControler = self.celldict[a2].ccbDocumentControler
                end
                if first then
                    cellCCB:setPosition(1080/2,0)
                    a2:addChild(cellCCB)
                end
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = 50
        elseif fn == "cellTouched" then
            print("cellTouched",a1:getIdx()+1)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    local args = {
        handle = _h,
        viewwidth = sizeScroll.width,
        viewheight = sizeScroll.height,
        dire = 1,
        page = 0
    }

    local tableview = LuaTableView:createWithHandler(args.handle, CCSizeMake(args.viewwidth or 0, args.viewheight or 0), nil,
        CCString:create("" .. (args.dire or 1) .. (args.page or 0)))

    tableview:setTouchPriority(-106)
    self.rootItems.listNode:addChild(tableview)
end

function TestTableView:CPlusTableView()
    --scroll的尺寸
    self.celldict = {}
    self.unrecycleCell = {}


    local sizeScroll = self.rootItems.listNode:getContentSize()
 
    --创建TableView
    self.m_tableView = cc.TableView:create( cc.size( sizeScroll.width, sizeScroll.height) )
    --TabelView添加到PanleMain
	self.rootItems.listNode:addChild(self.m_tableView);
	self.m_tableView:setPosition(0,0);
    --设置滚动方向
	self.m_tableView:setDirection( cc.SCROLLVIEW_DIRECTION_VERTICAL );
    --竖直从上往下排列
	self.m_tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN);
    --设置代理
	-- self.m_tableView:setDelegate()
 
    self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll),cc.SCROLLVIEW_SCRIPT_SCROLL);           --滚动时的回掉函数
	self.m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX);             --列表项的尺寸
	self.m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX);              --创建列表项
	self.m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW); --列表项的数量
 	self.m_tableView:registerScriptHandler(handler(self, self.isRecycleOfCellsInTableView), cc.TABLECELL_ISRECYCLE_AT_INDEX);


    self.m_tableView:reloadData();
end

function TestTableView:isRecycleOfCellsInTableView(view,idx,cell)
	for k,v in pairs (self.unrecycleCell) do
        if cell == v.cell then
            return false
        end
    end
    return true
end

function TestTableView:scrollViewDidScroll(view)
end
 
function TestTableView:cellSizeForTable(view, idx)
	local index = idx + 1
	if index%15 == 0 then
		return 1080, 300
	else
		return 1080, 134
	end
end
 
function TestTableView:numberOfCellsInTableView(view)
	return 50  --10个列表项
end
 
function TestTableView:tableCellAtIndex(view, idx)
	local index = idx + 1
    local cell
    if index%15 == 0 then
        if self.unrecycleCell.detailCell == nil then
            cell = cc.TableViewCell:new()
            --创建列表项
            local ccb,items = CCBReaderLoad("UI/rank/cell_paihangbang_1", nil, true, "cell_paihangbang_1")
            ccb:setPosition(1080/2,0)
            cell:addChild(ccb)

            self.unrecycleCell.detailCell={cell = cell, ccb =ccb, items=items}
            self.unrecycleCell.detailCell.cell:retain()
        else
            cell = self.unrecycleCell.detailCell.cell
        end
    else
        cell = view:dequeueCell()

        if nil == cell then
            cell = cc.TableViewCell:new()
            --创建列表项
            local ccb,items = CCBReaderLoad("UI/rank/cell_paihangbang_2", nil, true, "cell_paihangbang_2")
            self.celldict[cell] = {cellCCB = ccb, cellItem = items }

            ccb:setPosition(1080/2,0)
            cell:addChild(ccb)
        else
            local ccb,item = self.celldict[cell].cellCCB,self.celldict[cell].cellItem
            
        end
    end
 
	return cell
end
 
--设置排行榜名次
function TestTableView:resetLabelNum(panelRankItem, iRankNum)
end
 

function TestTableViewMain()
    print("TestTableViewMain")
    local scene = cc.Scene:create()
    scene:addChild(TestTableView.new())
    scene:addChild(CreateBackMenuItem())
    return scene
end


