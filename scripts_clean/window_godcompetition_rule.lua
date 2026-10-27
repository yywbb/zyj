local godcompetitionRule = {

    rootNode = nil,
    rootItems = nil,
}

function godcompetitionRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.listTableView = nil
    self.rootNode = nil
    self.rootItems = nil
end

function godcompetitionRule.open(self, touchPriority, data, callback)
    self:initNode(touchPriority)
    self:initEventBtn()

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(touchPriority)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0, 1230-2050),0)
    ui.createRichLabel({
        {fontID = 905,content = gamedata.config.system_intro["101"].intro},
    },self.rootItems.labelNode,true,{min_line_dis = 1})

    return self.rootNode
end

function godcompetitionRule.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/fengshensai_rule", nil, true, "fengshensai_rule")
    self.touchPriority = touchPriority
    ui.setLabelString(self.rootItems.titleTxt,"说 明",65)
end

function godcompetitionRule.initEventBtn(self)
    self:initCloseBtn()
end

function godcompetitionRule.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("godcompetitionRule")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

function godcompetitionRule.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return godcompetitionRule