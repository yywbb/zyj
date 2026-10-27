--公会动态

local guildlegion = {
    rootNode = nil,
    rootItems = nil,
    --表的项
    data = {},
    ListTableView = nil,
    normalCellSize = {x = 1000, y = 200},
    sizeT = {},
    allsizeH = 0,
    --上香的类型
    -- incense = {"土鸡蛋", "三黄鸡", "叫花鸡"},
    incense = {gameConfig.strings:string_common("popups","ege"), gameConfig.strings:string_common("popups","shj"), gameConfig.strings:string_common("popups","jhj")},
    --香的颜色品质
    incensecolor = {3, 7, 9},

    updatatypeNum = 0,
}

function guildlegion.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_ganglegion",nil,true,"ganglegion")
    --self.rootItems.listNode:setContentSize(CCSizeMake(1000,1000))
    self.touchPriority = touchPriority

    self.callback = callback
    --关闭按钮
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildlegion")
    end,CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.passLab,nil,14)
    self.rootItems.passButton:addHandleOfControlEvent(function()
        --
        if GameScene.passganglegion then
            GameScene.passganglegion = false
        else
            GameScene.passganglegion = true
        end

        self:reload(data,callback)
    end,CCControlEventTouchUpInside)
    self.rootItems.passButton:setSwallowsTouch(true)
    self.rootItems.passButton:setTouchPriority(self.touchPriority)

    self:reload(data,callback)
    return self.rootNode
end

function guildlegion.reload(self,data,callback)
	print("datajjjjjjjjjjjjj")
	printT(data)

    if GameScene.passganglegion then
        self.rootItems.passStatus:setVisible(false)
    else
        self.rootItems.passStatus:setVisible(true)
    end

	self.data = {}
	--self.data = data.gangsLegion or {}
	--数据排序
	local sortTable ={}
    for k, v in pairs(data.gangsLegion) do
    	if v and type(v) == "table" then
            if GameScene.passganglegion and v.opt == 9 then
            else
        	    table.insert(self.data,v)
            end
    	end
    end 
	local sortfunc = function(a,b)
			if a.times > b.times then
				return true
			else
				return false
			end
	end
    table.sort(self.data,sortfunc)
	-- printT(self.data)


    --创建richlabel 和创建表
    self:getSizeTable()
    --创建表
    if self.ListTableView then
        self.ListTableView:reloadData()
        self.ListTableView:setLuaContentOffset(0, self.rootItems.listNode:getContentSize().height - self.allsizeH)
    else
        self:createList()
    end
end

function guildlegion.getSizeTable(self)
	-- if next(self.sizeT) then return end
	-- print("numnum====",self.updatatypeNum,self.data[1]["times"])
	if self.updatatypeNum ~= 0 and self.data[1] and self.updatatypeNum == self.data[1]["times"] then
		--return
	end
	if self.data[1] then
		self.updatatypeNum = self.data[1]["times"]
	end

    self.allsizeH = 0
    self.sizeT = {}
	print("getSizeTable====")
	-- printT(self.data)
	for i= 1, table.getTableLength(self.data) do
	-- for i= 1, 20 do
		if self.data[i] and self.data[i].opt then
			local str = self:ctRichLabel(self.data[i])
			local container = CCNode:create()
			container:setAnchorPoint(ccp(0,1))
			container:setContentSize(CCSizeMake(900,20))
			container:retain()
			self.sizeT[i] = {
				height = ui.createRichLabel(str,container,false)+50,
				container = container
            }
            self.allsizeH = self.allsizeH + self.sizeT[i].height
		end
	end
		-- printT(self.sizeT)
end


--创建richlabel的模板
function guildlegion.ctRichLabel(self,richdata)
	local str = {}
	local richtime = os.date("(%Y-%m-%d %H:%M)",richdata.times) 
	if richdata.opt == 1 then
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 5, content = "  玩家《 "})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = " 》通过"})
		table.insert(str,{fontID = 3, content = "会长"})
		table.insert(str,{fontID = 5, content = "《 "})
		table.insert(str,{fontID = 1, content = richdata.name2})
		table.insert(str,{fontID = 5, content = "》的审核，加入了公会。"})
	elseif richdata.opt == 2 then
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 5, content = "  成员《 "})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = " 》退出了公会。"})
	elseif richdata.opt == 3 then
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 5, content = "  成员《 "})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = " 》使用了《 "})
		table.insert(str,{fontID = self.incensecolor[tonumber(richdata.name2)], content = self.incense[tonumber(richdata.name2)]})
		table.insert(str,{fontID = 5, content = " 》拜神,公会增加了 "})
		table.insert(str,{fontID = 3, content = richdata.content})
		table.insert(str,{fontID = 5, content = "点经验。"})
	elseif richdata.opt == 4 then
		-- print("提升为副会长===")
		-- printT(richdata)
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 3, content = "  会长"})
		table.insert(str,{fontID = 5, content = "下达命令,封《 "})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = " 》为"})
		table.insert(str,{fontID = 3, content = "副会长"})
	elseif richdata.opt == 5 then
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 3, content = "  会长"})
		table.insert(str,{fontID = 5, content = "下达命令,撤消了《 "})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = " 》"})
		table.insert(str,{fontID = 3, content = "副会长"})
		table.insert(str,{fontID = 5, content = "的职务。"})
	elseif richdata.opt == 6 then
		-- print("转让会长===")
		-- printT(richdata)
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 5, content = "  成员《 "})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = " 》很有管理经验"})
		table.insert(str,{fontID = 3, content = "会长"})
		table.insert(str,{fontID = 5, content = "经过斟酌后,将"})
		table.insert(str,{fontID = 3, content = "会长"})
		table.insert(str,{fontID = 5, content = "转让给《 "})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = " 》。"})
	elseif richdata.opt == 7 then
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 3, content = "  会长"})
		table.insert(str,{fontID = 5, content = "长期不在线,公会不可一日无主,《"})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = " 》发起弹劾，《 "})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = "》将成为"})
		table.insert(str,{fontID = 3, content = "新会长"})
		table.insert(str,{fontID = 5, content = "。"})
	elseif richdata.opt == 8 then
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 5, content = "  经过大家齐心协力的努力，公会提升到了"})
		table.insert(str,{fontID = 3, content = richdata.name1})
		table.insert(str,{fontID = 5, content = "级。"})
	elseif richdata.opt == 9 then
		local tbn = ui.IDconfig(tonumber(richdata.name2))
		local colorls = 0
		if tbn.quality == 2 then
			colorls = 3
		elseif tbn.quality == 3 then
			colorls = 5
		elseif tbn.quality == 4 then
			colorls = 7
		elseif tbn.quality == 5 then
			colorls = 9
		else
			colorls = 3
		end
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 5, content = "  成员《"})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = "》使用了("})
		table.insert(str,{fontID = colorls, content = tbn.name})
		table.insert(str,{fontID = 5, content = " )肥皂供大恐龙洗澡,"})
		table.insert(str,{fontID = 3, content = "公会"})
		table.insert(str,{fontID = 5, content = "增加了"})
		table.insert(str,{fontID = 3, content = richdata.status})
		table.insert(str,{fontID = 5, content = "点经验。"})
	elseif richdata.opt == 10 then
		table.insert(str,{fontID = 5, content = richtime})
		table.insert(str,{fontID = 3, content = "  会长"})
		table.insert(str,{fontID = 5, content = "下达命令，把成员《"})
		table.insert(str,{fontID = 1, content = richdata.name1})
		table.insert(str,{fontID = 5, content = "》踢出了公会。"})
    elseif richdata.opt == 11 then
        table.insert(str,{fontID = 5, content = richtime})
        table.insert(str,{fontID = 5, content = "《"})
        table.insert(str,{fontID = 1, content = richdata.name1})
        table.insert(str,{fontID = 5, content = "》在公会BOSS战中使用了元宝鼓舞。"})
    elseif richdata.opt == 12 then
        table.insert(str,{fontID = 5, content = richtime})
        table.insert(str,{fontID = 5, content = "《"})
        table.insert(str,{fontID = 1, content = richdata.name1})
        table.insert(str,{fontID = 5, content = "》击杀了公会BOSS。"})
	end
	return str
end

--创建表
function guildlegion.createList(self)
	print("createList")
	local celldict = {}
	local ListHandle = LuaEventHandler:create(function(fn,myTable,a1,a2)
		local r
		if fn == "cellSize" then
			--r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
		elseif fn == "hasFixedCellSize" then
            r = false
		elseif fn == "cellSizeForIndex" then
			r = CCSizeMake(self.normalCellSize.x, self.sizeT[a1+1].height)
	    elseif fn == "isRecycle" then
      
            return false
    
		elseif fn == "cellAtIndex" then
            -- a2 = CCTableViewCell:create()
            -- a2:addChild(self.sizeT[a1+1].container)
  			local cellCCB = 0
  			local first = true
  			if not a2 then
  				a2 = CCTableViewCell:create()
  				cellCCB = self.sizeT[a1+1].container

  				celldict[a2] = {cellCCB = cellCCB}
  			else
  				first =false
  				cellCCB = celldict[a2].cellCCB
  			end
  			if first then
  				a2:addChild(cellCCB)
   			end
   			r = a2
		elseif fn == "numberOfCells" then
			r = table.getTableLength(self.sizeT)
		elseif fn == "scrollViewDidScroll" then

		end
		return r
	end)
	self.ListTableView = ui.createLuaTableView({
		handle = ListHandle,
		viewwidth = self.rootItems.listNode:getContentSize().width,
		viewheight = self.rootItems.listNode:getContentSize().height,
		dire = 1
	})
	self.rootItems.listNode:addChild(self.ListTableView)
	self.ListTableView:setTouchPriority(self.touchPriority-1)
end

function guildlegion.close(self)
    self.allsizeH = 0
	self.data = {}
	self.ListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
    	self.callback()
    end
    -- self.sizeT = {}
end

return guildlegion



,  