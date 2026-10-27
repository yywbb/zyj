--
-- Author: songyibo
-- Date: 2018-09-13 15:42:12
--


local vipwelfare = {
    rootNode = nil,
    rootItems = nil,
    listview = nil,
}

function vipwelfare.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/vipfuli_fuli", nil, true, "vipfuli_fuli")
   	self.touchPriority = touchPriority
   	self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("vipwelfare")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab,nil,19)

    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("vipwelfare")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    


    local vipindex = tonumber(GameScene.roleinfo.vip)
    if vipindex < 1 then vipindex = 1 end


    self.vipconfig = {}
    self:makeConfig(vipindex)


    self:setVipBag(vipindex)
    self.rootItems.forward:addHandleOfControlEvent(function()
        if vipindex < (table.getTableLength(gamedata.config.vip)-1) then
            vipindex = vipindex + 1
            self:setVipBag(vipindex)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.forward:setSwallowsTouch(true)
    self.rootItems.forward:setTouchPriority(self.touchPriority)

    self.rootItems.back:addHandleOfControlEvent(function()
        if vipindex > 1 then
            vipindex = vipindex - 1
            self:setVipBag(vipindex)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.back:setSwallowsTouch(true)
    self.rootItems.back:setTouchPriority(self.touchPriority)


    return self.rootNode
end

function vipwelfare.makeConfig(self,vipindex)
	
    if self.vipconfig[vipindex] then
        return
    end

    self.vipconfig[vipindex] = {}


    local config = gamedata.config.vip_welfare[tostring(vipindex)]

    for k,v in pairs(config) do
        table.insert(self.vipconfig[vipindex],v)
    end

    table.sort(self.vipconfig[vipindex],function ( a,b)
        return a.battle_lv < b.battle_lv
    end)

    for k,v in pairs(self.vipconfig[vipindex]) do
        v.id = k
    end


    local level = GameScene.roleinfo.level
    local index = 1

    for i,v in ipairs(self.vipconfig[vipindex]) do
        if level > v.battle_lv then
            index = index + 1
        else
            break
        end
    end
    index = math.min(index,#self.vipconfig[vipindex])

    table.sort(self.vipconfig[vipindex],function ( a,b)

        if a.id == index and b.id ~= index then
            return true
        elseif  a.id ~= index and b.id == index  then
            return false
        elseif a.id > index and b.id < index then
            return true
        elseif a.id < index and b.id > index then
            return false
        elseif a.id > b.id then
            return false
        elseif a.id < b.id then
            return true
        end

    end)

	printT(self.vipconfig,"vip_welfare")

end

function vipwelfare.setVipBag(self,index)
	self.vipindex = index
    self:makeConfig(self.vipindex)
	ui.setLabelString(self.rootItems.title,string.format(gameConfig.strings:string_common("fixedString","vipfuli",6),self.vipindex),21)
	if not self.listview  then
		self:createlist()
	else
		self.listview:reloadData()
	end
end


function vipwelfare.createlist(self)
	local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(810, 120)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_vipfuli", nil, true, "cell_vipfuli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            

            self:setCell(ccbDocumentControler,a1+1)

            cellCCB:setPosition(810/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.vipconfig[self.vipindex]) + 1
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.scroll:getContentSize().width,
        viewheight = self.rootItems.scroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.scroll:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

function vipwelfare.setCell(self,item,index)

	local data
	local idnums
	if index == 1 then
		data = self.vipconfig[self.vipindex][1]
		idnums = ui.getIDandNUMs(data.free)

        item.tipnode1:setVisible(true)
        item.tipnode2:setVisible(false)

        ui.setLabelString(item.tip1,nil,13)
	else
		data = self.vipconfig[self.vipindex][index-1]
		idnums = ui.getIDandNUMs(data.pay)

        item.tipnode1:setVisible(false)
        item.tipnode2:setVisible(true)

        ui.setLabelString(item.tip2,nil,13)
	end

	printT(data,"setCell")
	for i=1,5 do
		item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
			if gameTouch.isScrollling then return end
            if idnums[i] then
                ui.setPopwindowByCid(idnums[i].cid)
            end
        end, CCControlEventTouchUpInside)
        item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)  
              
        if not idnums[i] then
            item["bagnode"..i]:setVisible(false)
        else
            item["bagnode"..i]:setVisible(true)
            ui.setNewIcon(item,{cid = idnums[i].cid, num = idnums[i].num},i-1)
        end
	end

	local str = ""
	if index == 1 then
		str = "1-130级"
	elseif index == 2 then
		str = gameConfig.strings:string_common("fixedString","vipfuli",7)
	else
		if data.id == 1 then
			str = "1-"..data.battle_lv.."级"
		else
			str = (self.vipconfig[self.vipindex][index -2].battle_lv + 1).."-"..data.battle_lv.."级"
		end
	end
	item.desc1:setString(str)

end

function vipwelfare.close(self)  
    self.listview = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end




return vipwelfare