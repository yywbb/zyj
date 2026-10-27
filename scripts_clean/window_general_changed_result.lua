local generalChangedResult = {
	rootNode = nil,
    rootItems = nil,
    needcallback = true,
}

function generalChangedResult.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
    	self.callback()
    end
end

function generalChangedResult.open(self, touchPriority, data, callback)
	self:initNode(touchPriority, callback)
	self:initData(data)
	self:initConfig()
	self:initSpine()
	self:initEventBtn()
	self:initGeneralInfo()

	return self.rootNode
end

function generalChangedResult.initNode(self, touchPriority, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("zhuanhuan/zhuanhuanchenggong", nil, true, "zhuanhuanchenggong")
	self.touchPriority = touchPriority
	self.callback = callback
end

function generalChangedResult.initData(self, data)
	self.data = data.general
	local generalConfig = gamedata.config.general[tostring(self.data.cid)]
	if self.data.level2 > 10 and self.data.level2 <= 13 then
		if data.opt and data.opt == 0 then
			ui.setLabelString(self.rootItems.fashionname,"激活红"..generalConfig.name.."皮肤",11,38)
			savePartnerfashionOnceToSqlite(self.data.cid,1)
		end
	elseif self.data.level2 > 13 then
		if data.opt and data.opt == 0 then
			ui.setLabelString(self.rootItems.fashionname,"激活彩金"..generalConfig.name.."皮肤",11,38)
			savePartnerfashionOnceToSqlite(self.data.cid,1)
		end
	else
		print("cid == ", self.data.cid)
		savePartnerfashionOnceToSqlite(self.data.cid,0)
	end
end

function generalChangedResult.initConfig(self)
	self.generalConfig = gamedata.config.general
end

-- 初始化spine
function generalChangedResult.initSpine(self)
    self.rootItems["general"]:removeAllChildrenWithCleanup(true)
    local _generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(self.data.cid).animationid)].name
    local _gneral = ui.itemcache:loadSkeleton(_generalName)
    _gneral:setAnimation("stand", true, 0)
    _gneral:setScale(1.8)
    self.rootItems["general"]:addChild(_gneral.root or _gneral)
end

function generalChangedResult.initEventBtn(self)
	self:initCloseBtn()
end

function generalChangedResult.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("generalChangedResult")
	end

	ui.commonBtn(self, self.rootItems, "closeButton", _cb)
end

function generalChangedResult.initGeneralInfo(self)
	local _config = self.generalConfig[tostring(self.data.cid)]

	self:setGeneralName(_config)
	self:setNodeShow()
	self:setNodeStatus()
end

function generalChangedResult.setGeneralName(self, config)
	if config.quality and config.quality >= 7 then
        ui.setLabelString(self.rootItems["generalname"], config.name..((self.data.level2 and self.data.level2 > 0) and " +"..self.data.level2 or ""), 213)
    else
        ui.setLabelString(self.rootItems["generalname"], config.name..((self.data.level2 and self.data.level2 > 0) and " +"..self.data.level2 or ""), config.quality and 2 * config.quality - 1 or 1)
    end
end

function generalChangedResult.checkNodeStatus(self)
	if GameScene.roleinfo.level >= 100 and (self.data.g_atk > 0 or self.data.g_defense > 0 or self.data.g_hp > 0) then
		return true
	else
		return false
	end
end

function generalChangedResult.setNodeShow(self)
	self.rootItems["node1"]:setVisible(not self:checkNodeStatus())
	self.rootItems["node2"]:setVisible(self:checkNodeStatus())
end

function generalChangedResult.setNodeStatus(self)
	if self:checkNodeStatus() then
		self.rootItems["attr_atk1"]:setString(gameConfig.strings:string_common("change", "general", "atk"))
		self.rootItems["atk1"]:setString(self.data["atk"])
		self.rootItems["attr_def1"]:setString(gameConfig.strings:string_common("change", "general", "def"))
		self.rootItems["def1"]:setString(self.data["defense"])
		self.rootItems["attr_hp1"]:setString(gameConfig.strings:string_common("change", "general", "hp"))
		self.rootItems["hp1"]:setString(self.data["hp"])
		self.rootItems["attr_speed1"]:setString(gameConfig.strings:string_common("change", "general", "speed"))
		self.rootItems["speed1"]:setString(self.data["speed"])

		self.rootItems["attr_atk2"]:setString(gameConfig.strings:string_common("change", "general", "g_atk"))
		self.rootItems["atk2"]:setString(self.data["g_atk"])
		self.rootItems["attr_def2"]:setString(gameConfig.strings:string_common("change", "general", "g_def"))
		self.rootItems["def2"]:setString(self.data["g_defense"])
		self.rootItems["attr_hp2"]:setString(gameConfig.strings:string_common("change", "general", "g_hp"))
		self.rootItems["hp2"]:setString(self.data["g_hp"])
	else
		self.rootItems["attr_atk"]:setString(gameConfig.strings:string_common("change", "general", "atk"))
		self.rootItems["atk"]:setString(self.data["atk"])
		self.rootItems["attr_def"]:setString(gameConfig.strings:string_common("change", "general", "def"))
		self.rootItems["def"]:setString(self.data["defense"])
		self.rootItems["attr_hp"]:setString(gameConfig.strings:string_common("change", "general", "hp"))
		self.rootItems["hp"]:setString(self.data["hp"])
		self.rootItems["attr_speed"]:setString(gameConfig.strings:string_common("change", "general", "speed"))
		self.rootItems["speed"]:setString(self.data["speed"])
	end
end

return generalChangedResult