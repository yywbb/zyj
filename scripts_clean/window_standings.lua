--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 2016-01-27 
-- Time: 上午10:18
-- To change this temisLandate use File | Settings | File TemisLandates.
--

local standings = {
	rootNode = nil,
	rootItems = nil,

	dataInfo = {},
	guildTable = {},
	fightIdTable = {},
	indexId = nil,
	pointId = nil,
}

function standings.open(self, touchPriority, data, callback)
	print("公会战弹窗")
	self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/tc_chakanzhanbao", nil, true, "chakanzhanbao")
	self.touchPriority = touchPriority

	print("data.pointId", data.pointId)
	self.pointId = data.pointId
	self.dataInfo = data.GuildStandingsShow
	-- printT(data.GuildStandingsShow)
	self.guildTable = {
		{name = self.dataInfo[tostring(1)] and self.dataInfo[tostring(1)].guildName1 or "???", status = self.dataInfo[tostring(1)] and self.dataInfo[tostring(1)].status1 or 3},
		{name = self.dataInfo[tostring(1)] and self.dataInfo[tostring(1)].guildName2 or "???", status = self.dataInfo[tostring(1)] and self.dataInfo[tostring(1)].status2 or 3},
		{name = self.dataInfo[tostring(2)] and self.dataInfo[tostring(2)].guildName1 or "???", status = self.dataInfo[tostring(2)] and self.dataInfo[tostring(2)].status1 or 3},
		{name = self.dataInfo[tostring(2)] and self.dataInfo[tostring(2)].guildName2 or "???", status = self.dataInfo[tostring(2)] and self.dataInfo[tostring(2)].status2 or 3},
		{name = self.dataInfo[tostring(3)] and self.dataInfo[tostring(3)].guildName1 or "???", status = self.dataInfo[tostring(3)] and self.dataInfo[tostring(3)].status1 or 3},
		{name = self.dataInfo[tostring(3)] and self.dataInfo[tostring(3)].guildName2 or "???", status = self.dataInfo[tostring(3)] and self.dataInfo[tostring(3)].status2 or 3},
	}
	for k,v in pairs(self.guildTable) do
		if k < 3 then
			if v.status == 1 then
				self.guildTable[5].name = v.name
			end
		elseif k > 2 and k < 5 then
			if v.status == 1 then
				self.guildTable[6].name = v.name
			end						
		end
	end
	print("返回的公会数据")
	-- printT(self.dataInfo)
	for k,v in pairs(self.dataInfo) do
		print("数据", v.fightId)
		self.fightIdTable[k] = v.fightId
	end


	self.callback = callback
	-- 退出
	self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("standings")
	end, CCControlEventTouchUpInside)

	self.rootItems.closeButton:setSwallowsTouch(true)
	self.rootItems.closeButton:setTouchPriority(self.touchPriority)

	self:onStandingsShow()
	return self.rootNode   -- 少 animationNode 
end

function standings.onStandingsShow(self)
	for k,v in pairs(self.guildTable) do
		ui.setLabelString(self.rootItems["guildName" .. k], v.name, 14)
		print("胜负", v.status)
		if v.status == 1 then

			self.rootItems["winItem" .. k]:setVisible(true)
			self.rootItems["loseItem" .. k]:setVisible(false)
		elseif v.status == 0 then
			self.rootItems["winItem" .. k]:setVisible(false)
			self.rootItems["loseItem" .. k]:setVisible(true)			
		else
			-- 战斗未开启
			self.rootItems["winItem" .. k]:setVisible(false)
			self.rootItems["loseItem" .. k]:setVisible(false)
		end
	end

	for k=1,3 do
	-- for k,v in pairs(self.fightIdTable) do
		if self.guildTable[(k-1)*2 + 1].status == 1 or self.guildTable[(k-1)*2 + 2].status == 1 then
	        self.rootItems["viewBtn" .. k]:addHandleOfControlEvent(function()
				print("点击查看战报" .. k .. self.pointId .. self.fightIdTable[tostring(k)])
				self.indexId = k
				if self.pointId == 0 then
					print("数据不对")
				else
					UIRequest({type = 2140, id = self.pointId, fightId = self.fightIdTable[tostring(k)]})				
				end
		

			end, CCControlEventTouchUpInside)
	        self.rootItems["viewBtn" .. k]:setSwallowsTouch(true)
	        self.rootItems["viewBtn" .. k]:setTouchPriority(self.touchPriority)			
		else
			self.rootItems["viewBtn" .. k]:setTouchEnabled(false)
			ui.addGray("CCControlButton", self.rootItems["viewBtn" .. k])
		end

	end
end

function standings.onUpdataInfo(self, dataInfo)
	-- 发消息请求两个公会的人物对战信息

	local guildRoleInfo = dataInfo.GuildStandingsRoleShow

	if self.guildTable[(self.indexId-1)*2 + 1].status == 1 or self.guildTable[(self.indexId-1)*2 + 2].status == 1 then
		gameWindows:openWindow("standingsScroll", {num = self.indexId, data = guildRoleInfo, pointId = self.pointId}, nil)
	else
		print("战斗未开启")
		runGamePrompt({msg = "战斗未开启"})
	end
end

function standings.close(self, _type) -- 退出
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootNode = nil
	self.rootItems = nil
	self.pointId = nil
	self.dataInfo = {}
	self.guildTable = {}
	self.fightIdTable = {}
end

return standings