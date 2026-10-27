local honorBuff = {

    rootNode = nil,
    rootItems = nil,
}

function honorBuff.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.listTableView = nil
    self.rootNode = nil
    self.rootItems = nil
end

function honorBuff.open(self, touchPriority, data, callback)
    self:initNode(touchPriority,data)
    self:initEventBtn()

    --self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    --self.rootItems.scrollnode:setTouchPriority(touchPriority)
    --self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0, 1230-1780),0)
    --ui.createRichLabel({
    --    {fontID = 905,content = gamedata.config.system_intro["47"].intro},
    --},self.rootItems.labelNode,true,{min_line_dis = 1})
    local breakskillConfig =  gamedata.config.breakskill
    self.data = data;
    --print()
    self.rootItems.label_info1:setString(breakskillConfig[tostring(self.data.buff_one)].desc)
    self.rootItems.label_info_two:setString(breakskillConfig[tostring(self.data.buff_two)].desc)
    self.rootItems.label_info_three:setString(breakskillConfig[tostring(self.data.buff_three)].desc)
    
    ui.setLabelString(self.rootItems.label_title1,nil,14)
    ui.setLabelString(self.rootItems.label_title2,nil,14)
    ui.setLabelString(self.rootItems.label_title3,nil,14)
    return self.rootNode
end

function honorBuff.initNode(self, touchPriority,data)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/tc_buffinfo", nil, true, "tc_buffinfo")
    self.touchPriority = touchPriority
    ui.setLabelString(self.rootItems.titleTxt,"第"..data.number.."届BUFF详情",65)
end

function honorBuff.initEventBtn(self)
    self:initCloseBtn()
end

function honorBuff.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorBuff")
    end

    self:commonBtn(self.rootItems, "closeBtn", _cb)
end

function honorBuff.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return honorBuff