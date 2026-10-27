--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/4/8
-- Time: 16:32
-- To change this template use File | Settings | File Templates.
--

local generalChangedRule = {
    rootNode = nil,
    rootItems = nil,
}

function generalChangedRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanhuan/wujiangzhuanhuan_rule", nil, true, "wujiangzhuanhuan_rule")
    self.touchPriority = touchPriority

    if self.rootItems.labelNode then
        local info = gamedata.config.system_intro["57"].intro
        if data and data.other and data.other == "swap" then
            info = gamedata.config.system_intro["84"].intro
        end
        ui.createRichLabel({
            {fontID = 905,content = info},
        },self.rootItems.labelNode,true,{min_line_dis = 1})
    end

    self:reload(data,callback)
    return self.rootNode
end

function generalChangedRule.reload(self,data,callback)
    self.callback = callback

    local _cb = function()
        gameWindows:closeWindow("generalChangedRule")
    end

    ui.commonBtn(self, self.rootItems, "closeBtn", _cb)
end

function generalChangedRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return generalChangedRule