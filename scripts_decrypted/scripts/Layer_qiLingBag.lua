--
-- Author: songyibo
-- Date: 2021-03-17 16:57:28
--
local qiLingBag = {

    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
    selectpage1 = 0, --镶嵌位置
    selectpage2 = 0, --器灵品质
    data = {
    },
    pagename = {"全 部","Ⅰ","Ⅱ","Ⅲ","Ⅳ","Ⅴ","Ⅵ"},
    showdata = {},
    listTableView = nil,
    normalCellSize = {x=1080,y=270},
    propnum = 0,
    newQiling = {}
}

function qiLingBag.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("zhuanshushenqi/zhuanshushenqi_bag", nil, true, "zhuanshushenqi_bag")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight - 730))
    self.rootItems.bagbg1:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-370))

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("main","up")
    end, CCControlEventTouchUpInside)

    self.rootItems.ronglian:setSwallowsTouch(true)
    self.rootItems.ronglian:setTouchPriority(self.touchPriority)
    self.rootItems.ronglian:addHandleOfControlEvent(function()
        GameScene:shiftLayer("qiLingRefining")
    end, CCControlEventTouchUpInside)

    self:initLayerpageshift()
    self:getQilingNew()
    self:reload()
end

function qiLingBag.getQilingNew(self)
    self.newQiling = getNewQilingFromSqlite()
    printT(self.newQiling,"newQiling")
end

function qiLingBag.initLayerpageshift(self)
	for k=0,6 do
        self.rootItems["buttontext"..(k + 1)]:setString(self.pagename[k+1])
        self.rootItems["button"..(k + 1)]:setSwallowsTouch(true)
	    self.rootItems["button"..(k + 1)]:setTouchPriority(self.touchPriority - 1)
	    self.rootItems["button"..(k + 1)]:addHandleOfControlEvent(function()
	       	if self.selectpage1 == k then return end
	       	self.selectpage1 = k
	        self:shiftlayerpage()
	        self:reload()
	    end, CCControlEventTouchUpInside)
	end

	for k=0,6 do
        self.rootItems["btn_"..(k + 1)]:setSwallowsTouch(true)
	    self.rootItems["btn_"..(k + 1)]:setTouchPriority(self.touchPriority - 1)
	    self.rootItems["btn_"..(k + 1)]:addHandleOfControlEvent(function()
	       	if self.selectpage2 == k then return end
	       	self.selectpage2 = k
	        self:shiftlayerpage()
	        self:reload()
	    end, CCControlEventTouchUpInside)
	end
	self:shiftlayerpage()
end

--按钮高亮状态的显示
function qiLingBag.shiftlayerpage(self)
	for k=0,6 do
		if k == self.selectpage1 then
			setSpriteFrameByName(self.rootItems["buttonsprite"..(k + 1)], "yeqian7_h")
		else
			setSpriteFrameByName(self.rootItems["buttonsprite"..(k + 1)], "yeqian7")
		end
	end
	self.rootItems.pointSpr:setPosition(self.rootItems["buttonnode2_"..(self.selectpage2 + 1)]:getPosition())
end

function qiLingBag.setQilingNum(self)
    local num = table.getTableLength(self.showdata[self.selectpage1][self.selectpage2])
    self.rootItems.haveNum:setString(num.."/"..1000)
end

function qiLingBag.reloadData(self,data,reset)
    -- printT(data,"qiLingBag_reloadData")
    if reset then
        self.data = {}
    end
    
	for k,v in pairs(data) do
		self.data[v.iid] = v
	end

	if GameScene.layers["qiLingBag"].show then
        self:reload()
    end
end

function qiLingBag.sortData(self)
	
	self.showdata = {}
	for i=1,7 do
		self.showdata[i-1] = {}
		for j=1,7 do
			self.showdata[i-1][j-1] = {}
		end
	end

	for k,v in pairs(self.data) do
		local config = gamedata.config.exclusive_device_spirit[tostring(v.cid)]
		if config then
			table.insert(self.showdata[0][0],v)
            
		end
	end
    gamedata.sortData(self.showdata[0][0],"ison","level","quality","cid",nil,nil,false,false,false,true)
    for i,v in ipairs(self.showdata[0][0]) do
        local config = gamedata.config.exclusive_device_spirit[tostring(v.cid)]
        table.insert(self.showdata[0][config.suit],v)
        table.insert(self.showdata[config.location][config.suit],v)
        table.insert(self.showdata[config.location][0],v)
    end
end

function qiLingBag.showQilings(self)
    UIRequest({type = 12001,order = 33023,cids = {192091}})
end

function qiLingBag.setQilings(self,props)
    self.propnum = props["192091"] or 0
    for k,v in pairs(self.data) do
        v.hint_intensify = nil
        --镶嵌且可强化 提示红点
        if v.ison == 1 then
            local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(v.cid)]
            local nextIntensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(v.level + 1)]
            --满级
            if nextIntensifyConfig then
                local consumeProp = gamedata.getIDandNUMs(nextIntensifyConfig.consumption)[1]
                if self.propnum >= consumeProp.num then
                    v.hint_intensify = true
                end
            end
        end
    end

    -- printT(self.data,"setQilings")
    self:reload()
end

function qiLingBag.reload(self,update)

    if (not next(self.showdata) or update) then
        self:showQilings()
        self:sortData()
    end

    if not self.listTableView then
        self:createList()
    else
        self.listTableView:reloadData()
        local line = math.ceil(table.getTableLength(self.showdata[self.selectpage1][self.selectpage2])/5)
        self.listTableView:setLuaContentOffset(0,  self.rootItems.listnode:getContentSize().height - self.normalCellSize.y*line )
    end

    self:setQilingNum()
    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.showdata[self.selectpage1][self.selectpage2]) == 0,"qiling")
end

function qiLingBag.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuanshushenqi/cell_qiling_icon", nil, true, "cell_general_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.generalsListTableView,cellCCB,self.normalCellSize.x/2+30,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local data = self.showdata[self.selectpage1][self.selectpage2]
            for i=4,0,-1 do
                if data[(a1+1)*5-i] then
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                    self:setCell(data[(a1+1)*5-i],ccbDocumentControler,5-i)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end
            cellCCB:setPosition(self.normalCellSize.x/2+30, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.showdata[self.selectpage1][self.selectpage2])/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority)
end

function qiLingBag.setCell(self,data,items,index)
	local key_Ex
    local id = index-1
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    local config = ui.IDconfig(data.cid) 
    ui.setNewIconName(items,{cid = data.cid, num = data.level > 0 and "+"..data.level or ""},index-1)
    if items["in_isonNode"..key_Ex] then
    	items["in_isonNode"..key_Ex]:setVisible(data.ison and data.ison == 1)
    	items["in_isonLab"..key_Ex]:setString("已镶嵌")
    end

    items["in_button"..key_Ex]:setTouchPriority(self.touchPriority - 1)
    items["in_button"..key_Ex]:addHandleOfControlEvent(function()
        print("in_button"..key_Ex)
        if gameTouch.isScrollling then return end
        if self.newQiling[data.iid] then
            self.newQiling[data.iid] = nil
            items["new"..index]:removeAllChildrenWithCleanup(true)
        end
        gameWindows:openWindow("qilingInfo",{iid = data.iid,opt = 1})
    end, CCControlEventTouchUpInside)
    ui.sethint(items["hint"..index],data.hint_intensify)
    items["lockSp"..index]:setVisible(data.lock == 1)

    items["new"..index]:removeAllChildrenWithCleanup(true)
    if self.newQiling[data.iid] then
        local ccb,Items = CCBReaderLoad("talk/new", nil, true, "new")
        items["new"..index]:addChild(ccb)
    end
end

function qiLingBag.getQilingData(self,iid)
    if iid and self.data[iid] then
        return self.data[iid]
    end
    return self.data
end

function qiLingBag.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.selectpage1 = 0 --镶嵌位置
    self.selectpage2 = 0 --器灵品质
    self.showdata = {}
    self.listTableView = nil
    self.propnum = 0
    self.newQiling = {}
end

return qiLingBag  *(  