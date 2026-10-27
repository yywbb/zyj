local pointShop = {
	rootItems = nil,
    rootNode = nil,
    touchPriority = -110,
    activityId = 161,
    activityTable = {26, 27, 37, 36, 207},
    requestTable = {1610, 1001, 3822, 2710, 8856},
    module = {"Layer_sports_shop", "Layer_guild_shop2", "Layer_passkill_shop", "Layer_activity_championshop", "Layer_activity_ascensionSendai_shop"},
    pageId = 1,
}

function pointShop.clear(self)
    self.show = false

    if self.currentPage then
		self.currentPage:clear()
	end

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootItems = nil
        self.rootNode = nil
    end
end

function pointShop.init(self, size, realPageId, pageId)
	self.contentsize = size
    self.show = true

    self:initNode()
    self:initConfig()
    self:initPage(pageId)
    self:reloadHint()

    return self.rootNode
end

function pointShop.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/generalshop", nil, true, "generalshop")
    self.rootItems.topnode:setPositionY(self.contentsize.y - 180)
end

function pointShop.initConfig(self)
	self.activityTimeConfig = gamedata.config.activity_time
end

function pointShop.initPage(self, pageId)
	self:makePage(pageId)

	if #self.tempActivityTable > 0 then
		self:shiftPage()
		self:initPageBtn()
	else

	end
end

function pointShop.makePage(self, pageId)
	self.tempActivityTable = {}
	self.tempRequestTable = {}
	self.tempModule = {}
	self.activityName = {}

	for i,v in ipairs(self.activityTable) do
		if GameScene.activityStatus[tostring(v)].status == 1 then
			table.insert(self.tempActivityTable, v)
			table.insert(self.tempRequestTable, self.requestTable[i])
			table.insert(self.tempModule, self.module[i])
			table.insert(self.activityName, self.activityTimeConfig[tostring(v)].name)
		end
	end

	local _len = #self.tempActivityTable

	if self.pageId > _len then
		self.pageId = _len
	end

	for i = 1, 5 do
		if i <= _len then
			self.rootItems["btnnode"..i]:setVisible(true)
			self.rootItems["plantitle"..i]:setString(self.activityName[i])
		else
			self.rootItems["btnnode"..i]:setVisible(false)
		end
	end

	for i = 1, #self.tempActivityTable do
		if self.tempActivityTable[i] == pageId then
			self.pageId = i
		end
	end
end

function pointShop.shiftPage(self, page)
	if page then
		if self.pageId == page then
			return
		else
			self.pageId = page
		end
	end

	if self.currentPage then
		self.currentPage:clear()
	end

	self.currentPage = require(self.tempModule[self.pageId])
	local _node = self.currentPage:init(self.contentsize)

	self.rootItems["addNode"]:addChild(_node)
	UIRequest({type = self.tempRequestTable[self.pageId]})

	for i = 1, #self.tempActivityTable do
		if i == self.pageId then
			setSpriteFrameByName(self.rootItems["btnspr"..i], "b_n_shangdianbiaoqian2")
		else
			setSpriteFrameByName(self.rootItems["btnspr"..i], "b_n_shangdianbiaoqian1")
		end
	end

	if guide.controller then
        guide.controller:NewSystem(gamedata.config.activity_time[tostring(self.tempActivityTable[self.pageId])].systemid)
    end
end

function pointShop.initPageBtn(self)
	for i = 1, #self.tempActivityTable do
		local _cb = function()

			self:shiftPage(i)
		end

		ui.commonBtn(self, self.rootItems, "planbutton"..i, _cb)
	end
end

function pointShop.reloadHint(self)
	for i = 1, #self.tempActivityTable do
		ui.sethint(self.rootItems["hint"..i],GameScene.hintdata[tostring(gamedata.config.activity_time[tostring(self.tempActivityTable[i])].systemid)] and GameScene.hintdata[tostring(gamedata.config.activity_time[tostring(self.tempActivityTable[i])].systemid)] ~= 0)
	end
end

function pointShop.refreshFunc(self,pageId)
	for i = 1, #self.tempActivityTable do
		if self.tempActivityTable[i] == tonumber(pageId) then
			self:shiftPage(i)
			break
		end
	end

end

function pointShop.reloadData(self, data)
	if self.currentPage then
		self.currentPage:reloadData(data)
	end
end

function pointShop.reloadRewards(self, data)
	if self.currentPage and self.currentPage.reloadRewards then
		self.currentPage:reloadRewards(data)
	end
end

return pointShop