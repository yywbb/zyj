local honorTime = {

    rootNode = nil,
    rootItems = nil,
}

function honorTime.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.listTableView = nil
    self.rootNode = nil
    self.rootItems = nil
end

function honorTime.open(self, touchPriority, data, callback)
    self:initNode(touchPriority)
    self:initEventBtn()
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(touchPriority)
    self.rootItems.scrollnode:setTouchEnabled(false)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0, 1230-1780),0)
    ui.createRichLabel({
        {fontID = 905,content = gamedata.config.system_intro["48"].intro},
    },self.rootItems.labelNode,true,{min_line_dis = 1})

    return self.rootNode
end

function honorTime.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_rule", nil, true, "rongyaozhizhan_jiangli")
    self.touchPriority = touchPriority
    ui.setLabelString(self.rootItems.titleTxt,"对战时间",65)
end

function honorTime.initEventBtn(self)
    self:initCloseBtn()
end

function honorTime.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorTime")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

function honorTime.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return honorTime