--
-- Author: songyibo
-- Date: 2020-02-11 14:41:05
--
local rule = {
    touchPriority = -101,
}

function rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function rule.open(self, touchPriority, data, callback)
	self:initNode(touchPriority)
	self:initConfig()
	self:initEventBtn()

    return self.rootNode
end

function rule.initNode(self, touchPriority)

	self.rootNode, self.rootItems = CCBReaderLoad("youxizhushou/rule", nil, true, "rule")
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(touchPriority)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0, 1030-2280),0)
    ui.createRichLabel({
        {fontID = 905,content = gamedata.config:getConfigByName("system_intro")["75"].intro},
    },self.rootItems.labelNode,true,{min_line_dis = 1})
	self.touchPriority = touchPriority

end

function rule.initConfig(self)
    self.systemIntro = gamedata.config:getConfigByName("system_intro")
end

function rule.initEventBtn(self)
	self:initCloseBtn()
end

function rule.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("gameHelperRule")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

-- 通用按钮
function rule.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return rule