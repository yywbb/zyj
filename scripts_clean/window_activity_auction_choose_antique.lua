auctionChooseAntique = {
    
}

function auctionChooseAntique.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function auctionChooseAntique.open(self, touchPriority, data, callback)
	self:initNode(touchPriority)
	self:initConfig()
	self:initEventBtn()
	self:initFixedString()
	self:reloadData()

    return self.rootNode
end

function auctionChooseAntique.initNode(self, touchPriority)
	self.rootNode, self.rootItems = CCBReaderLoad("activitygudong/gudong_select", nil, true, "gudong_select")
	self.touchPriority = touchPriority
end

function auctionChooseAntique.initConfig(self)
	self.antiqueItem = {}

    for k,v in pairs(gamedata.config.antique_item) do
        table.insert(self.antiqueItem, v)
    end

    local _tableSort = function(left, right)
        return left.cid < right.cid
    end

    table.sort(self.antiqueItem, _tableSort)
end

function auctionChooseAntique.initEventBtn(self)
	self:initCloseBtn()
	self:initStartAuctionBtn()
end

function auctionChooseAntique.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("activityAuctionChooseAntique")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function auctionChooseAntique.initStartAuctionBtn(self)
	local _cb = function()
		if self.currentItem then
			UIRequest({type = 5410, cid = self.items[self.currentItem].cid})
            if GameScene.roleinfo then
                CCUserDefault:sharedUserDefault():setIntegerForKey("activityAuctionTimer_"..gameWindows.windows["roleinfo"].module.SelectedServer.id..GameScene.roleinfo.id, gamedata:time())
            end
		else
			runGamePrompt({msg = gameConfig.strings:string_common("activityAuction", 2)})
		end
	end

	self:commonBtn(self.rootItems, "startAuctionBtn", _cb)
end

function auctionChooseAntique.initFixedString(self)
	ui.setLabelString(self.rootItems.startAuctionTxt, gameConfig.strings:string_common("activityAuction", 1),18)
end

function auctionChooseAntique.reloadData(self, data)
	self.currentItem = nil
	self.antiqueItemTableLength = table.getTableLength(self.antiqueItem)

    if not data then
    	local _cids = {}

    	for i = 1, self.antiqueItemTableLength do

       		table.insert(_cids, self.antiqueItem[i].cid)
    	end

       	UIRequest({type = 12001, order = 33012, cids = _cids})

        return 
    end

    self.items = {}

    for i = 1, self.antiqueItemTableLength do
    	self.items[i] = {}
    	self.items[i].cid = self.antiqueItem[i].cid
    	self.items[i].num = data[tostring(self.antiqueItem[i].cid)] or 0
    	self:setItem(i)
    	self:setEffect(self.rootItems["choose"..i], false)
    end
end

function auctionChooseAntique.setEffect(self, item, isShow)
	item:setVisible(isShow)
end

-- 设置奖励
function auctionChooseAntique.setItem(self, index)
    local _key_Ex = ""
    
    if index == 1 then
        _key_Ex = ""
    else
        _key_Ex = "_"..(index - 1)
    end

    ui.setNewIconName(self.rootItems, {cid = self.items[index].cid, num = self.items[index].num}, index - 1)

    local _cb = function()
    	self:setCurrentItem(index, self.items[index].num)
    end

    if self:checkItemIsCanUse(index, self.items[index].num) then
    	ui.addGray("CCSprite", self.rootItems["in_quality".._key_Ex])
    	ui.addGray("CCSprite", self.rootItems["in_icon".._key_Ex])
    	ui.addGray("CCSprite", self.rootItems["in_k_quality".._key_Ex])
    end

    self:commonBtn(self.rootItems, "i_button".._key_Ex, _cb)
end

function auctionChooseAntique.setCurrentItem(self, index, num)
	if self:checkItemIsCanUse(index, num) then
        if GameScene.roleinfo.level < self.antiqueItem[index].level then
            runGamePrompt({msg = gameConfig.strings:activityAuctionChoose(self.antiqueItem[index].level)})
        end

		return
	end

	if self.currentItem then
		self:setEffect(self.rootItems["choose"..self.currentItem], false)
	end

	self.currentItem = index
	self:setEffect(self.rootItems["choose"..self.currentItem], true)
end

function auctionChooseAntique.checkItemIsCanUse(self, index, num)
    return (num <= 0) or (GameScene.roleinfo.level < self.antiqueItem[index].level)
end

-- 通用按钮
function auctionChooseAntique.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(toucnhPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return auctionChooseAntique