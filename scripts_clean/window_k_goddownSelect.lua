--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/7/5
-- Time: 15:31
-- To change this template use File | Settings | File Templates.
--

local k_goddownSelect = {
    rootNode = nil,
    rootItems = nil,
}

function k_goddownSelect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitypig/kuafuactivitypig_select", nil, true, "select")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    self:initFixedString()
    return self.rootNode
end

function k_goddownSelect.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("k_goddownSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    local config = gamedata.config.span_goddown_shangxiang
    if not config then return end

    for i = 1,3 do
        if config[tostring(i)] then
            local xgold = 0
            self.rootItems["selectNode"..i]:setVisible(true)
            ui.setLabelString(self.rootItems["fixlab"..i],config[tostring(i)].name,2*i+1)
            if config[tostring(i)].free and config[tostring(i)].free == 1 then
                xgold = 0
                self.rootItems["goldnode"..i]:setVisible(false)
                ui.setLabelString(self.rootItems["free"..i],gameConfig.strings:string_common("activity_goddown",6),23)
            else
                self.rootItems["goldnode"..i]:setVisible(true)
                ui.setLabelString(self.rootItems["free"..i],"",23)
                local cid,num = ui.getIDandNUM(config[tostring(i)].cost)
                ui.setLabelString(self.rootItems["xgold"..i],num,14)
                xgold = num
            end
            ui.setLabelString(self.rootItems["cdtime"..i],gameConfig.strings:string_common("activity_goddown",5)..gameConfig.strings:hourNum(config[tostring(i)].cd),111)
            local rewards = ui.getIDandNUMs(config[tostring(i)].bonus)
            for k,v in pairs(rewards) do
                if v.cid == 1000 then
                    ui.setLabelString(self.rootItems["coin"..i],v.num,14)
                elseif v.cid == 1020 then
                    ui.setLabelString(self.rootItems["point"..i],v.num,14)
                end
            end
            self.rootItems["selectbutton"..i]:addHandleOfControlEvent(function()
                print("selectbutton"..i)
                if xgold <= GameScene.roleinfo.gold then
                    gameWindows:closeWindowDirect("k_goddownSelect")
                end
                UIRequest({type = 4871, id = i, xgold = xgold})
            end, CCControlEventTouchUpInside)
            self.rootItems["selectbutton"..i]:setSwallowsTouch(true)
            self.rootItems["selectbutton"..i]:setTouchPriority(self.touchPriority)
        else
            self.rootItems["selectNode"..i]:setVisible(false)
        end
    end

end

function k_goddownSelect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function k_goddownSelect.initFixedString(self)
    ui.setLabelString(self.rootItems.fixlab0,gameConfig.strings:string_common("fixedString","goddown",9),21)
    ui.setLabelString(self.rootItems.fixlab4,gameConfig.strings:string_common("fixedString","goddown",10),21)
    ui.setLabelString(self.rootItems.closeLab,gameConfig.strings:string_common("fixedString","goddown",11),19)
end

return k_goddownSelect

