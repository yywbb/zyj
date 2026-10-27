--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/7/31
-- Time: 17:36
-- To change this template use File | Settings | File Templates.
--



local zidong_rule = {
    rootNode = nil,
    rootItems = nil,
}

function zidong_rule.open(self,touchPriority,data,callback)
    if data.doType and data.doType == 2 then
        self.rootNode, self.rootItems = CCBReaderLoad("magic/zidong_rule", nil, true, "zidong_rule")
        if self.rootItems.labelNode then
            ui.createRichLabel({
                {fontID = 905,content = gamedata.config.system_intro["51"].intro},
            },self.rootItems.labelNode,true,{min_line_dis = 1})
        end
    elseif data.doType and data.doType == 3 then
        self.rootNode, self.rootItems = CCBReaderLoad("general_new/zidong_rule", nil, true, "zidong_rule")
        if self.rootItems.labelNode then
            ui.createRichLabel({
                --todo：：修改武将培养的说明配置
                {fontID = 905,content = gamedata.config.system_intro["69"].intro},
            },self.rootItems.labelNode,true,{min_line_dis = 1})
        end
    else
        self.rootNode, self.rootItems = CCBReaderLoad("equip_new/zidong_rule", nil, true, "zidong_rule")
        if self.rootItems.labelNode then
            ui.createRichLabel({
                {fontID = 905,content = gamedata.config.system_intro["50"].intro},
            },self.rootItems.labelNode,true,{min_line_dis = 1})
        end
    end
    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function zidong_rule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("zidong_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function zidong_rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end


return zidong_rule