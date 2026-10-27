--工会商店
local guildshop = {
	buttontouch = -100,
	data = {},
	gangdata = {},
	normalCellSize = {x = 1080, y = 280},
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
        	if self.gangdata["level"] >= v.display_level then
        		if (self.gangdata["level"] or 0) >= v["gang_level"] then
        			v.tempSort = v.priority
        		else
        			v.tempSort = 1000 + v.priority
        		end
            	table.insert(self.configdata,v)
            end
        end

        local function sortbylevel(a,b)
            --if a.gang_level == b.gang_level then
            --if (self.gangdata["level"] or 0) >= a["gang_level"] then
                return a.tempSort < b.tempSort
            --else
            --    return a.gang_level < b.gang_level
            --end
        end
        table.sort(self.configdata,sortbylevel)
    end
end

--初始化
-- function guildshop.init(self,parent,toppos)
function guildshop.init(self,size)
	print("guildshopinit===")
    self.contentsize = size
    self.show = true
	self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/gonghui_shop", nil, true, "gonghuishop")
	-- self.rootNode:setPosition(540,0)
	-- parent:addChild(self.rootNode)
	-- self.rootItems.topnode:setPositionY(toppos)
	self.rootItems.topnode:setPositionY(self.contentsize.y-180)
	--商品node的初始化

    self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-gameConfig.maiscenebottomheight-825))


	-- self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
 --    self.rootItems.scrollnode:setTouchPriority(self.buttontouch)
 --    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

 --    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-180-500))

 --    self.rootItems.container:setContentSize(CCSize(1080,1000))

 --    self.scrollNode, self.scrollItems = CCBReaderLoad("tanchuang/map4", nil, true, "map4")
 --    self.scrollNode:setPosition(0,0)
 --    -- self.scrollNode:setVisible(false)
 --    self.rootItems.container:addChild(self.scrollNode)
 --    printT(self.rootItems.container,"container===")
 --    printT(self.rootItems,"rootItems===")
 --    printT(self.scrollItems,"scrollnode===")

 --    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,toppos-180-500-180 - 1000),0)

    -- self.rootItems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,toppos-180-500-180))


	-- self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-375))
	--人物动画
	-- local Gneral1 = CCSkeletonAnimation:create("hexiangu/hexiangu.json","hexiangu/hexiangu.atlas",1)
	-- Gneral1:setAnimation("stand",true,0)
	-- Gneral1:setScale(1.8)
	-- Gneral1:setPosition(0,0)
	-- self.rootItems.general:addChild(Gneral1)
	--描边
	-- ui.setLabelString(self.rootItems["currentgdLv"],nil,150)
	-- ui.setLabelString(self.rootItems["currentContb"],nil,150)
	--返回按钮
	ui.setLabelString(self.rootItems.backText,nil,18)
	self.rootItems.backBtn:setTouchPriority(-102)
	self.rootItems.backBtn:setSwallowsTouch(true)
	self.rootItems.backBtn:addHandleOfControlEvent(function()
		--GameScene:shiftLayer("gang_main","up")
        UIRequest({type = 2230, param = "main"})
	end,CCControlEventTouchUpInside)

    --UIRequest({type = 2252})
    UIRequest({type = 2230})

	return self.rootNode
end



--加载数据
function guildshop.reloadData(self,data)
	printT(data,"guildshop===")
	if not data then
		return
	end
	if not self.show then return end
	-- 数据
	self.data = data.data or {}
	--工会信息
	self.gangdata = data.gangdata or {}
	--工会等级
	self.rootItems.gonghuiLv:setString(tostring(self.gangdata["level"] or "无公会"))
	-- ui.setLabelString(self.rootItems.gonghuiLv,nil,150)
	--当前贡献值
	self.rootItems.contribution:setString(tostring(self.gangdata["contribution"] or 0))
	-- ui.setLabelString(self.rootItems.contribution,nil,14)

	self:makeConfig()
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

	-- for i=1, 6 do
 --        self:setone(self.scrollItems,self.configdata[i],i)
 --    end
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
				cellCCB, ccbDocumentControler = CCBReaderLoad("tanchuang/cell_gonghui_shop2",nil,true,"cell_a_gonghuishop")
				celldict[a2] = {cellCCB = cellCCB,ccbDocumentControler = ccbDocumentControler}
			else
				first = false
				cellCCB = celldict[a2].cellCCB
				ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            if self.configdata[(a1+1)*2-1] then
                ccbDocumentControler.propnode1:setVisible(true)
			    self:setCell(ccbDocumentControler,self.configdata[(a1+1)*2-1],1)
            else
                ccbDocumentControler.propnode1:setVisible(false)
            end
            if self.configdata[(a1+1)*2] then
                ccbDocumentControler.propnode2:setVisible(true)
			    self:setCell(ccbDocumentControler,self.configdata[(a1+1)*2],2)
            else
                ccbDocumentControler.propnode2:setVisible(false)
            end
			cellCCB:setPosition(self.normalCellSize.x/2,-8)
			if first then
				a2:addChild(cellCCB)
			end
			r = a2
		elseif fn=="numberOfCells" then
			r = math.ceil(table.getTableLength(self.configdata)/2)
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

function guildshop.setCell(self,item,data,id)
	print("index==",id)
	printT(data)
	local key_Ex
	local i_key
    if id == nil or id == 1 then
        key_Ex = ""
        i_key = ""
    else
        key_Ex = "_2"
        i_key = "_1"
    end
    if not data then
    	print("notid===",data.id)
        return
    end
    ui.removeGray("CCControlButton", item["getbutton"..key_Ex])
	-- 兑换次数
	if data["alone_cycle"] == 0 then
		-- item.exchangeString:setString("今日可兑换")
		-- item.exchangeString:setString(gameConfig.strings:string_common("guild_shop",1))
		-- item["exchangeString"..key_Ex]:setString(gameConfig.strings:string_common("guild_shop",1))
	elseif data["alone_cycle"] == 1 then
		-- item.exchangeNum:setString("本周可兑换")
		-- item.exchangeNum:setString(gameConfig.strings:string_common("guild_shop",2))
		-- item["exchangeNum"..key_Ex]:setString(gameConfig.strings:string_common("guild_shop",2))
	elseif data["alone_cycle"] == 2 then
		-- item.exchangeNum:setString("这月可兑换")
		-- item.exchangeNum:setString(gameConfig.strings:string_common("guild_shop",3))
		-- item["exchangeNum"..key_Ex]:setString(gameConfig.strings:string_common("guild_shop",3))
	end
	--兑换次数得修改
	--以修改
	--item.exchangeNum:setString(data["number"])
	item["exchangeNum"..key_Ex]:setString(data["number"] - self.data[tostring(data.id)].num)
	-- if (data["number"] - self.data[tostring(data.id)].num) > 0 then
	-- 	ui.setLabelString(item["exchangeNum"..key_Ex],nil,22)
	-- else
	-- 	ui.setLabelString(item["exchangeNum"..key_Ex],nil,24)
	-- end

	--工会等级限制
	--做出判断(设置颜色的变化)
	item["guildlvopen"..key_Ex]:setString(tostring(data["gang_level"]))
	--要改 0改为当前的等级
	if (self.gangdata["level"] or 0) >= data["gang_level"] then
		-- ui.setLabelString(item["guildlvopen"..key_Ex],nil,22)
		item["shadowNode"..key_Ex]:setVisible(false)
	else
		-- ui.setLabelString(item["guildlvopen"..key_Ex],nil,24)
		ui.addGray("CCControlButton", item["getbutton"..key_Ex])
		item["shadowNode"..key_Ex]:setVisible(true)
	end
	--显示的道具以及数量和名称
	if data["award"] then
		local award = ui.getIDandNUMs(data["award"])
		ui.setNewIcon(item,{num = award[1].num,cid = award[1].cid},id-1)
		local propName = ui.IDconfig(award[1].cid)
		ui.setLabelString(item["goodsName"..key_Ex],propName.name,propName.quality*2 -1)
		
		item["i_button"..i_key]:setTouchPriority(-102)
		item["i_button"..i_key]:addHandleOfControlEvent(function()
			if gameTouch.isScrollling then return end
			if propName.staffType == "token_fragment" then
				ui.setPopwindowByCid(award[1].cid,{cid = award[1].cid})
			else
				ui.setPopwindowByCid(award[1].cid)
			end
		end,CCControlEventTouchUpInside)

	end
	--贡献度
	if data["consume"] then
		local consume = ui.getIDandNUMs(data["consume"])
		item["contributionNum"..key_Ex]:setString(tostring(consume[1]["num"]))
		ui.setLabelString(item["contributionNum"..key_Ex],nil,22)
		--判断贡献度(要改) 0改为当前的贡献度
		if (self.gangdata["contribution"] or 0) < consume[1]["num"] then
			ui.setLabelString(item["contributionNum"..key_Ex],nil,24)
			ui.addGray("CCControlButton", item["getbutton"..key_Ex])
		end

	end
	--兑换字体的描边
	ui.setLabelString(item["gettext"..key_Ex],nil,18)

    -- if item["fixstring1"..key_Ex] and item["fixstring2"..key_Ex] and item["fixstring3"..key_Ex] then
        -- ui.setLabelString(item["fixstring1"..key_Ex],nil,13)
        -- ui.setLabelString(item["fixstring2"..key_Ex],nil,13)
        -- ui.setLabelString(item["fixstring3"..key_Ex],nil,13)
        -- ui.setLabelString(item["exchangeString"..key_Ex],nil,13)
    -- end

	--兑换按钮
	item["getbutton"..key_Ex]:setTouchPriority(-102)
	item["getbutton"..key_Ex]:addHandleOfControlEvent(function()
		if gameTouch.isScrollling then return end
		gameTouch:clickprofbytime(0.5)
		local consume = ui.getIDandNUMs(data["consume"])
		--工会等级不足(工会等级)
		if (self.gangdata["level"] or 0) < data["gang_level"] then
			-- runGamePrompt({msg = "公会等级不足"})
			runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",8)..data["gang_level"]..gameConfig.strings:string_common("guild_shop",10)})
		elseif data["number"] <= self.data[tostring(data.id)].num then
			-- runGamePrompt({msg = "兑换次数已用完"})
			runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",6)})
		--贡献度是否足够
		elseif (self.gangdata["contribution"] or 0) < consume[1]["num"] then
			-- runGamePrompt({msg = "贡献度不足"})
			runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",5)})
		else
			--UIRequest({type = 2253, id = data.id,contribution = consume[1]["num"]})

			function shopExchangeRequest(num)
				if (self.gangdata["contribution"] or 0) < consume[1]["num"]*num then
					runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",5)})
				else
					UIRequest({type = 2253, id = data.id,contribution = consume[1]["num"],num = num})
				end
            end
            local exchangeNum = data["number"] - self.data[tostring(data.id)].num
            local awardData = ui.getIDandNUMs(data["award"])
            local consumeData = ui.getIDandNUMs(data["consume"])
            if exchangeNum > 5 then
            	gameWindows:openWindow("shopExchange",{cid = awardData[1].cid,num = awardData[1].num,cost = consumeData,exchangeNum = exchangeNum},shopExchangeRequest)
       		else
       			UIRequest({type = 2253, id = data.id,contribution = consume[1]["num"],num = 1})
       		end	
		end
		gamedata.music:PlayOptSound("wjdh")
	end,CCControlEventTouchUpInside)

	if data["number"] <= self.data[tostring(data.id)].num then
		ui.addGray("CCControlButton",item["getbutton"..key_Ex])
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
	if self.rootNode then
		self.rootNode:removeAllChildrenWithCleanup(true)
	    self.rootNode:removeFromParentAndCleanup(true)
		self.rootItems = nil
		self.rootNode = nil
	end
	
end

function guildshop.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 2252})
    end
end

return guildshop

