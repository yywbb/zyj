--工会商店
local guildshop = {
	--buttontouch = -103,
	data = {},
	gangdata = {},
	normalCellSize = {x = 1080, y = 260},
	rootItems = nil,
	rootNode = nil,
	--商品列表
	ListTableView = nil,
	--配置表
	configdata = {},
}

function guildshop.makeConfig(self)
    if not next(self.configdata) then
        for k,v in pairs(gamedata.config.gang2_shop) do
            table.insert(self.configdata,v)
        end
        local function sortbylevel(a,b)
            if a.gang_level == b.gang_level then
                return a.priority < b.priority
            else
                return a.gang_level < b.gang_level
            end
        end
        table.sort(self.configdata,sortbylevel)
    end
end

--初始化
function guildshop.init(self,parent,toppos)
	self.show = true
	self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_shop", nil, true, "gonghuishop")
	self.rootNode:setPosition(0,0)
	parent:addChild(self.rootNode)
	self.rootItems.topnode:setPositionY(toppos)
	--商品node的初始化
	self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-375))
	--人物动画
	local Gneral1 = CCSkeletonAnimation:create("hexiangu/hexiangu.json","hexiangu/hexiangu.atlas",1)
	Gneral1:setAnimation("stand",true,0)
	Gneral1:setScale(1.8)
	Gneral1:setPosition(0,0)
	self.rootItems.general:addChild(Gneral1)
	--描边
	ui.setLabelString(self.rootItems["currentgdLv"],nil,21)
	ui.setLabelString(self.rootItems["currentContb"],nil,14)
	--返回按钮
	self.rootItems.backButton:setTouchPriority(-102)
	self.rootItems.backButton:setSwallowsTouch(true)
	self.rootItems.backButton:addHandleOfControlEvent(function()
		GameScene:shiftLayer("gang_main","up")
	end,CCControlEventTouchUpInside)

    self:makeConfig()

	UIRequest({type = 2252})
	--self:reloaddata()
end

--创建表
function  guildshop.createList(self)
	local  celldict = {}
	local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
		local r
		if fn == "cellSize" then
			r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
		elseif fn == "cellAtIndex" then
			local cellCCB,ccbDocumentControler = 0,0
			local first = true
			if not a2 then
				a2 = CCTableViewCell:create()
				cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_gonghui_shop",nil,true,"cell_a_gonghuishop")
				celldict[a2] = {cellCCB = cellCCB,ccbDocumentControler = ccbDocumentControler}
			else
				first = false
				cellCCB = celldict[a2].cellCCB
				ccbDocumentControler = celldict[a2].ccbDocumentControler
			end
			self:setCell(ccbDocumentControler,self.configdata[a1+1],a1+1)
			cellCCB:setPosition(self.normalCellSize.x/2,0)
			if first then
				a2:addChild(cellCCB)
			end
			r = a2
		elseif fn=="numberOfCells" then
			r = table.getTableLength(self.configdata)
		elseif fn == "cellTouched" then

		elseif fn == "scrollViewDidScroll" then

		end
		return r
	end)
	self.ListTableView = ui.createLuaTableView({
		handle = ListHandle,
		viewwidth = self.rootItems.listnode:getContentSize().width,
		viewheight = self.rootItems.listnode:getContentSize().height,
		dire = 1
	})

	self.rootItems.listnode:addChild(self.ListTableView)
	self.ListTableView:setTouchPriority(-101)
end

--设置单元格的内容
function guildshop.setCell(self,item,data,index)
	-- 兑换次数
	if data["alone_cycle"] == 0 then
		-- item.exchangeString:setString("今日可兑换")
		item.exchangeString:setString(gameConfig.strings:string_common("guild_shop",1))
	elseif data["alone_cycle"] == 1 then
		-- item.exchangeNum:setString("本周可兑换")
		item.exchangeNum:setString(gameConfig.strings:string_common("guild_shop",2))
	elseif data["alone_cycle"] == 2 then
		-- item.exchangeNum:setString("这月可兑换")
		item.exchangeNum:setString(gameConfig.strings:string_common("guild_shop",3))
	end
	--兑换次数得修改
	--以修改
	--item.exchangeNum:setString(data["number"])
	item.exchangeNum:setString(data["number"] - self.data[tostring(data.id)].num)
	if (data["number"] - self.data[tostring(data.id)].num) > 0 then
		ui.setLabelString(item["exchangeNum"],nil,22)
	else
		ui.setLabelString(item["exchangeNum"],nil,24)
	end

	--工会等级限制
	--做出判断(设置颜色的变化)
	item.guildlvopen:setString(tostring(data["gang_level"]))
	--要改 0改为当前的等级
	if self.gangdata["level"] >= data["gang_level"] then
		ui.setLabelString(item["guildlvopen"],nil,22)
	else
		ui.setLabelString(item["guildlvopen"],nil,24)
	end
	--显示的道具以及数量和名称
	if data["award"] then
		local award = ui.getIDandNUMs(data["award"])
		ui.setNewIcon(item,{num = award[1].num,cid = award[1].cid},0)
		item.i_button:setTouchPriority(-102)
		item.i_button:addHandleOfControlEvent(function()
			if gameTouch.isScrollling then return end
			ui.setPopwindowByCid(award[1].cid)
		end,CCControlEventTouchUpInside)
		local propName = ui.IDconfig(award[1].cid)
		item.goodsName:setString(propName.name)
		ui.setLabelString(item.goodsName,propName.name,1)
	end
	--贡献度
	if data["consume"] then
		local consume = ui.getIDandNUMs(data["consume"])
		item.contributionNum:setString(tostring(consume[1]["num"]))
		ui.setLabelString(item["contributionNum"],nil,22)
		--判断贡献度(要改) 0改为当前的贡献度
		if self.gangdata["contribution"] < consume[1]["num"] then
			ui.setLabelString(item["contributionNum"],nil,24)
		end

	end
	--兑换字体的描边
	ui.setLabelString(item.gettext,nil,18)
	--兑换按钮
	item.getbutton:setTouchPriority(-102)
	item.getbutton:addHandleOfControlEvent(function()
		if gameTouch.isScrolling then return end
		gameTouch:clickprofbytime(0.5)
		local consume = ui.getIDandNUMs(data["consume"])
		--工会等级不足(工会等级)
		if self.gangdata["level"] < data["gang_level"] then
			-- runGamePrompt({msg = "公会等级不足"})
			runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",4)})
		--贡献度是否足够
		elseif self.gangdata["contribution"] < consume[1]["num"] then
			-- runGamePrompt({msg = "贡献度不足"})
			runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",5)})
		elseif data["number"] <= self.data[tostring(data.id)].num then
			-- runGamePrompt({msg = "兑换次数已用完"})
			runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",6)})
		else
			UIRequest({type = 2253, id = data.id,contribution = consume[1]["num"]})
		end
		gamedata.music:PlayOptSound("wjdh")
	end,CCControlEventTouchUpInside)

end

--加载数据
function guildshop.reloaddata(self,data)

	if not self.show then return end
	-- 数据
	self.data = data.data or {}
	--工会信息
	self.gangdata = data.gangdata
	--工会等级
	self.rootItems.gonghuiLv:setString(tostring(self.gangdata["level"]))
	ui.setLabelString(self.rootItems.gonghuiLv,nil,21)
	--当前贡献值
	self.rootItems.contribution:setString(tostring(self.gangdata["contribution"]))
	ui.setLabelString(self.rootItems.contribution,nil,14)

	--读取配置表
	--self.configdata = gamedata.config.gang2_shop or {}

	--表的排序
 	-- local sortfunc = function(a,b)
 	-- 	if a.priority < b.priority then 
 	-- 		return true
 	-- 	else
 	-- 		return false
 	-- 	end
 	-- end
 	-- table.sort(self.configdata,sortfunc)

	--创建表
	if self.rootItems then 
		if not self.ListTableView then
			self:createList()
		else
			self.ListTableView:reloadData()
		end
	end

end

--清空数据
function guildshop.clear(self)
	-- body
	self.show = false
	self.gangdata = {}
	self.configdata = {}
	self.data = {}
	self.ListTableView = nil
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootItems = nil
	self.rootNode = nil
end

function guildshop.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 2252})
    end
end

return guildshop

