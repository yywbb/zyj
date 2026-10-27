--公会技能
--zhangzhixin

local guildskill = {
	normalCellSize = {x = 1080, y = 260},
	rootItems = nil,
	rootNode = nil,
	cellNum = 0, --总cell个数
 	maxLevel = 0, --最大等级
 	isscrolltouched = false,
}


function guildskill.init(self,parent,toppos)
	self.show = true
	self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_skill", nil, true, "gonghuiskill")
	self.rootNode:setPosition(-GameScene.viewSize.width*0.5,0)
	parent:addChild(self.rootNode)
	self.rootItems.topnode:setPositionY(toppos)
	--商品node的初始化
	self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-400))
	--返回按钮
	self.rootItems.backButton:setTouchPriority(-102)
	self.rootItems.backButton:setSwallowsTouch(true)
	self.rootItems.backButton:addHandleOfControlEvent(function()
		GameScene:shiftLayer("gang_main","up")
	end,CCControlEventTouchUpInside)

    self:makeConfig()

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","guildskill",touchbegin)

    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","guildskill",touchend)
	UIRequest({type = 2262})
	-- self:reloaddata()

end

--清空数据
function guildskill.clear(self)
    gameTouch:UnrigistFunc("begin","guildskill")
    gameTouch:UnrigistFunc("end","guildskill")  	
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootItems = nil
	self.rootNode = nil
	self.ListTableView = nil
 	self.maxLevel = 0
 	self.cellNum = 0	
 	self.isscrolltouched = false
end

function guildskill.makeConfig(self)
 	self.skillLevelConfig = gamedata.config.gang2_skill_level
 	local skillOpenConfig = gamedata.config.gang2_skill_open
 	self.maxLevel = table.getTableLength(self.skillLevelConfig)
 	self.cellNum = 0
 	self.skillOpenConfig = {}
 	for k,v in pairs(skillOpenConfig) do 
 		table.insert(self.skillOpenConfig,v)
		self.cellNum = self.cellNum + 1
 	end
 	local sortFunc = function(a,b)
		if a.id >= b.id then
			return false
		else
			return true
		end
 	end
 	table.sort(self.skillOpenConfig,sortFunc)
end

function guildskill.reloaddata(self,data)
	self.guildData = data.gang2status
	self.skillData = data.gang2skill
	if self.rootItems then 
		if not self.ListTableView then
			self:createList()
		else
			self.ListTableView:reloadData()
		end
	end
	self.rootItems.devoteText:setString("个人贡献："..self.guildData.contribution)
	ui.setLabelString(self.rootItems.guildLevelText,"当前公会等级："..self.guildData.level,21)	
end

function guildskill.createList(self)
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
				cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_gonghui_skill",nil,true,"cell_gonghuiskill")
				celldict[a2] = {cellCCB = cellCCB,ccbDocumentControler = ccbDocumentControler}
			else
				first = false
				cellCCB = celldict[a2].cellCCB
				ccbDocumentControler = celldict[a2].ccbDocumentControler
			end
			self:setCell(ccbDocumentControler,self.skillOpenConfig[a1+1],a1+1)
			cellCCB:setPosition(self.normalCellSize.x/2,self.normalCellSize.y/2)
			if first then
				a2:addChild(cellCCB)
			end
			r = a2
		elseif fn=="numberOfCells" then
			r = self.cellNum
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
function guildskill.setCell(self,item,data,index)
	ui.setNewIcon(item,data)
	setSpriteFrameByName(item.i_icon,data.icon)
	ui.setLabelString(item.goodsName,data.name,21)
	local guildLevel = 0 --公会等级不足时修改
	local roleLevel = 0 --人物等级不足时修改
	local dovoteNum = 0 --个人贡献不足
	local resTable = {}
	if self.skillData[tostring(data.id)]["1"] < self.maxLevel  then
		local temp = ui.Split(self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"] + 1)][data.attr1.."_contribution"],";")	
		resTable = ui.Split(temp[1],",")
	end	
	if (self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"] + 1)] and
		self.guildData.level < self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"] + 1)][data.attr1.."_gang2_level"])  or 
		self.skillData[tostring(data.id)]["1"] >=  self.maxLevel  then

		ui.addGray("CCControlButton",item.getbutton)
	else
		ui.removeGray("CCControlButton",item.getbutton)
	end
	item.needDevoteText:setVisible(true)
	if self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"] + 1)] and  self.guildData.level < self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"] + 1)][data.attr1.."_gang2_level"] then
		--如果没有值 说明已经强化到最大等级 不需要再次判定次条件
		guildLevel = self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"] + 1)][data.attr1.."_gang2_level"]
		item.needDevoteText:setString(guildLevel..gameConfig.strings:string_common("guild_skill",5))
	elseif self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"] + 1)] and  GameScene.roleinfo.level < self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"] + 1)].team_level then
		--如果没有值 说明已经强化到最大等级 不需要再次判定次条件
		roleLevel = self.skillLevelConfig[tostring(self.skillData[tostring(data["id"])]["1"]+1)]["team_level"] 
		item.needDevoteText:setString(gameConfig.strings:string_common("guild_skill",7)..roleLevel..gameConfig.strings:string_common("guild_skill",6))
	elseif self.maxLevel > self.skillData[tostring(data["id"])]["1"] then
		item.needDevoteText:setString("消耗："..resTable[2] .."个人贡献")
		if self.guildData.contribution >= tonumber(resTable[2]) then
			item.needDevoteText:setColor(ccc3(134,83,32))
		else
			dovoteNum = 1
			item.needDevoteText:setColor(ccc3(255,0,0))
		end
	else
		item.needDevoteText:setVisible(false)
	end

	if self.skillData[tostring(data.id)]["1"] <= 0 then
		item.gettext:setString(gameConfig.strings:string_common("guild_skill",1))
		item.levelText:setString(gameConfig.strings:string_common("guild_skill",4))
		item.currentAttributeText:setString(gameConfig.strings:string_common("guild_skill",4))
		item.nextAttributeText:setString(data.desc.." + "..self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"]+1)][data.attr1])
		item.nextNameText:setVisible(true)
		item.nextAttributeText:setVisible(true)
	elseif self.skillData[tostring(data.id)]["1"] >=  self.maxLevel then
		item.gettext:setString(gameConfig.strings:string_common("guild_skill",3))
		item.levelText:setString(self.maxLevel.."/"..self.maxLevel)
		item.currentAttributeText:setString(data.desc.." + "..self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"])][data.attr1])
		item.nextNameText:setVisible(false)
		item.nextAttributeText:setVisible(false)
	else
		item.gettext:setString(gameConfig.strings:string_common("guild_skill",2))
		item.levelText:setString(self.skillData[tostring(data.id)]["1"].."/"..self.maxLevel)
		item.currentAttributeText:setString(data.desc.." + "..self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"])][data.attr1])
		item.nextAttributeText:setString(data.desc.." + "..self.skillLevelConfig[tostring(self.skillData[tostring(data.id)]["1"]+1)][data.attr1])
		item.nextNameText:setVisible(true)
		item.nextAttributeText:setVisible(true)
    end
    ui.setLabelString(item.gettext,nil,18)
	item.getbutton:setTouchPriority(-102)
	item.getbutton:setSwallowsTouch(true)
	item.getbutton:addHandleOfControlEvent(function()
		print("学习技能")
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
		if  guildLevel > 0 and self.skillData[tostring(data["id"])]["1"] <= 0   then
			runGamePrompt({msg = "您的公会等级不足"..guildLevel.."级，不可学习"})
		elseif  guildLevel > 0 and self.skillData[tostring(data["id"])]["1"] > 0   then 
			runGamePrompt({msg = "您的公会等级不足"..guildLevel.."级，不可升级"})
		elseif roleLevel > 0  and self.skillData[tostring(data["id"])]["1"] <= 0 then
			runGamePrompt({msg = "您的等级不足"..roleLevel.."级，不能学习"})
		elseif roleLevel > 0  and self.skillData[tostring(data["id"])]["1"] >0 then
			runGamePrompt({msg = "您的等级不足"..roleLevel.."级，不能升级"})			
		elseif dovoteNum > 0 and self.skillData[tostring(data.id)]["1"] <= 0 then
			runGamePrompt({msg = "您的个人贡献不足，不可学习"})
		elseif dovoteNum > 0 and self.skillData[tostring(data.id)]["1"]  > 0 then
			runGamePrompt({msg = "您的个人贡献不足，不可升级"})
		elseif self.maxLevel <= self.skillData[tostring(data["id"])]["1"] then
			runGamePrompt({msg = "此技能已满级"})	
		else
			UIRequest({type = 2263,index = self.skillData[tostring(data.id)]["2"] ,num = tonumber(resTable[2]),id = data.id})
		end
	end,CCControlEventTouchUpInside)	
end
return guildskill
