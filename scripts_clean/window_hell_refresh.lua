hellRefresh = {
	root = nil,
    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
}

-- 打开界面
function hellRefresh.open(self, touchPriority, data, callback)
    self.root = CCNode:create()
    self.data = data
    self.touchPriority = touchPriority
    self.priceConfig = gamedata.config.buycount_price
	self:initNode()
    self:initFixedString()
    self:initEvent()
    UIRequest({type = 6113, param = 0, gold = 0})

    return self.root
end

-- 初始化ccb
function hellRefresh.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("copyhell/copyhell_shuaxintishi", nil, true, "copyhell_shuaxintishi")
    self.rootNode:setPosition(0, 0)
	self.root:addChild(self.rootNode)
end

-- 初始化文字
function hellRefresh.initFixedString(self)
	ui.setLabelString(self.rootItems.titleTxt, gameConfig.strings:string_common("hell", 11), 69)
	self.rootItems.refreshTxt1:setString(gameConfig.strings:string_common("hell", 24)..self.data)
	self.rootItems.refreshTxt2:setString(gameConfig.strings:string_common("hell", 25))
	self.rootItems.refreshTxt3:setString(gameConfig.strings:string_common("hell", 26))
	ui.setLabelString(self.rootItems.cancelTxt, gameConfig.strings:string_common("hell", 27), 18)
	ui.setLabelString(self.rootItems.okTxt, gameConfig.strings:string_common("hell", 28), 18)
end

-- 初始化点击事件
function hellRefresh.initEvent(self)
	self:initCloseBtn()
	self:initOkBtn()
	self:initCancelBtn()
end

-- 初始化关闭按钮
function hellRefresh.initCloseBtn(self)
    local _callback = function()
        gameWindows:closeWindow("hellRefresh")
    end

    self:commonBtn("closeBtn", _callback)
end

-- 初始化关闭按钮
function hellRefresh.initOkBtn(self)
    local _callback = function()
    	UIRequest({type = 6113, param = 1, gold = self.data})
    	gameWindows:closeWindow("hellRefresh")
    end

    self:commonBtn("okBtn", _callback)
end

-- 初始化关闭按钮
function hellRefresh.initCancelBtn(self)
    local _callback = function()
        gameWindows:closeWindow("hellRefresh")
    end

    self:commonBtn("cancelBtn", _callback)
end

-- 关闭
function hellRefresh.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
end

-- 通用按钮
function hellRefresh.commonBtn(self, btnName, callback)
    self.rootItems[btnName]:setSwallowsTouch(true)
    self.rootItems[btnName]:setTouchPriority(self.touchPriority - 1)
    self.rootItems[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return hellRefresh