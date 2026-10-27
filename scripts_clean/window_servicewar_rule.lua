--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/22
-- Time: 18:26
-- To change this template use File | Settings | File Templates.
--

local servicewarrule = {
    rootNode = nil,
    rootItems = nil,
}

function servicewarrule.open(self,touchPriority,data,callback)
    printT(data,"servicewarrule")
    if data and data.opt and data.opt == 3 then
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_rule3", nil, true, "kuafuzhan_rule3")
        ui.createRichLabel({
            {fontID = 905,content = gamedata.config.system_intro["27"].intro},
        },self.rootItems.labelNode,true,{min_line_dis = 1})
    elseif data and data.opt and data.opt == 2 then
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_rule2", nil, true, "kuafuzhan_rule2")
         ui.createRichLabel({
            {fontID = 905,content = gamedata.config.system_intro["26"].intro},
        },self.rootItems.labelNode,true,{min_line_dis = 1})
    elseif data and data.opt and data.opt == 4 then
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_rule", nil, true, "kuafuzhan_rule")
        self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
        self.rootItems.scrollnode:setTouchPriority(touchPriority)
        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0, 1230-2500),0)
        ui.createRichLabel({
            {fontID = 905,content = data.shenbang and gamedata.config.system_intro["93"].intro or gamedata.config.system_intro["91"].intro},
        },self.rootItems.labelNode,true,{min_line_dis = 1})
    else
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_rule", nil, true, "kuafuzhan_rule")
        self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
        self.rootItems.scrollnode:setTouchPriority(touchPriority)
        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0, 1230-2500),0)
        ui.createRichLabel({
            {fontID = 905,content = data.shenbang and gamedata.config.system_intro["92"].intro or gamedata.config.system_intro["25"].intro},
        },self.rootItems.labelNode,true,{min_line_dis = 1})
    end
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function servicewarrule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("servicewarrule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    if data and data.opt and data.opt == 1 then
        local config = gamedata.config.cross_battle_interval or {}
        local time1 = config["1"].time or 0
        local time2 = config["2"].time or 0
        local time3 = config["3"].time or 0
        if self.rootItems.time1 then
            self.rootItems.time1:setString(time1.."~"..(time2-1))
        end
        if self.rootItems.time2 then
            self.rootItems.time2:setString(time2.."~"..(time3-1))
        end
        if self.rootItems.time3 then
            self.rootItems.time3:setString(time3)
        end
    end

end

function servicewarrule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return servicewarrule