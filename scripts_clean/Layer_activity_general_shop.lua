local generalShop = {
	rootItems = nil,
    rootNode = nil,
    touchPriority = -110,
    activityId = 161,
    activityTable = {136,20,133, 137},
    requestTable = {6911,3650,6451, 7017},
    module = {"Layer_activity_shizhuangshop","Layer_activity_secretshop", "Layer_activity_jinghuashop", "Layer_activity_babelTowerShop"},
    pageId = 1,
}

function generalShop.clear(self)
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

function generalShop.init(self, size, realPageId, pageId)
	self.contentsize = size
    self.show = true

    self:initNode()
    self:initConfig()
    self:initPage(pageId)
    self:reloadHint()
    return self.rootNode
end

function generalShop.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/generalshop", nil, true, "generalshop")
    self.rootItems.topnode:setPositionY(self.contentsize.y - 180)
end

function generalShop.initConfig(self)
	self.activityTimeConfig = gamedata.config.activity_time
end

function generalShop.initPage(self, pageId)
	self:makePage(pageId)

	if #self.tempActivityTable > 0 then
		self:shiftPage()
		self:initPageBtn()
	else

	end
end

function generalShop.makePage(self, pageId)
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
		if self.tempActivityTable[i] == tonumber(pageId) then
			self.pageId = i
		end
	end
end

function generalShop.shiftPage(self, page)
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

function generalShop.initPageBtn(self)
	for i = 1, #self.tempActivityTable do
		local _cb = function()

			self:shiftPage(i)
		end

		ui.commonBtn(self, self.rootItems, "planbutton"..i, _cb)
	end
end

function generalShop.reloadHint(self)
	for i = 1, #self.tempActivityTable do
		ui.sethint(self.rootItems["hint"..i],GameScene.hintdata[tostring(gamedata.config.activity_time[tostring(self.tempActivityTable[i])].systemid)] and GameScene.hintdata[tostring(gamedata.config.activity_time[tostring(self.tempActivityTable[i])].systemid)] ~= 0)
	end
end

function generalShop.refreshFunc(self,pageId)
	for i = 1, #self.tempActivityTable do
		if self.tempActivityTable[i] == tonumber(pageId) then
			self:shiftPage(i)
			break
		end
	end

end

function generalShop.reloadData(self, data)
	if self.currentPage then
		self.currentPage:reloadData(data)
	end
end

return generalShop