--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/2/28
-- Time: 15:17
-- To change this template use File | Settings | File Templates.
--

local redbag = {
    rootNode = nil,
    rootItems = nil,

    typeid = 1,
}

function redbag.open(self,touchPriority,data,callback)
    -- self.rootNode, self.rootItems = CCBReaderLoad("activityjieri/hongbao", nil, true, "redbag")
    self.rootNode, self.rootItems = CCBReaderLoad("7zhounian/7zhounian_tangguo", nil, true, "7zhounian_tangguo")
    self.touchPriority = touchPriority
    self.callback = callback
    self.typeid = data and data.id or 1
    -- --
    -- local pictype = {
    --         [1] = "hongbaoicon_wujiang",
    --         [2] = "hongbaoicon_daoju",
    --         [3] = "hongbaoicon_yinbi",
    --         [4] = "hongbaoicon_yuanbao",
    -- } 
    -- if self.rootItems.b_sprite then
    --     setSpriteFrameByName(self.rootItems.b_sprite,pictype[self.typeid],"public/language")
    -- end
    -- 

    --
    if self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindowDirect("redbag")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    --
    self.rootItems.openRedbagBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 6502, id = self.typeid})
    end, CCControlEventTouchUpInside)
    self.rootItems.openRedbagBtn:setSwallowsTouch(true)
    self.rootItems.openRedbagBtn:setTouchPriority(self.touchPriority)
    --
    if self.rootItems.closeRedbagLab then
        ui.setLabelString(self.rootItems.closeRedbagLab, nil, 19)
    end
    self.rootItems.closeRedbagBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("redbag")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeRedbagBtn:setSwallowsTouch(true)
    self.rootItems.closeRedbagBtn:setTouchPriority(self.touchPriority)
    --
    ui.setLabelString(self.rootItems.redBagDesc,nil,14)
    --
    --self:reload()
    if GameScene.holidaynum and (GameScene.holidaynum < gamedata.config.holiday_time["2"].num) then
        -- ui.setLabelString(self.rootItems.limitRedNum,"今日剩余红包开启次数："..(gamedata.config.holiday_time["2"].num-GameScene.holidaynum),14)
        self.rootItems.limitRedNum:setString("今日剩余开启糖果次数："..(gamedata.config.holiday_time["2"].num-GameScene.holidaynum))
    else  
        -- ui.setLabelString(self.rootItems.limitRedNum,"今日剩余红包开启次数：0",14)
        self.rootItems.limitRedNum:setString("今日剩余开启糖果次数：0")
    end

    return self.rootNode
end

function redbag.reload(self,data,callback)

    if callback then
        self.callback = callback
    end    
    
    if data and data.reward then
        for i = 1,3 do
            if data.reward[tostring(i)] then
                self.rootItems["reward"..i]:setVisible(true)
                ui.setNewIcon(self.rootItems,data.reward[tostring(i)],i-1)
            else
                self.rootItems["reward"..i]:setVisible(false)
            end
        end  
        --
        local animationManager = getAnimationManager(self.rootItems)
        animationManager:setAnimationCompletedCallback(function()
            if GameScene.holidaynum and (GameScene.holidaynum < gamedata.config.holiday_time["2"].num) then
                -- ui.setLabelString(self.rootItems.limitRedNum,"今日剩余红包开启次数："..(gamedata.config.holiday_time["2"].num-GameScene.holidaynum),14)
                self.rootItems.limitRedNum:setString("今日剩余开启糖果次数："..(gamedata.config.holiday_time["2"].num-GameScene.holidaynum))
            else  
                -- ui.setLabelString(self.rootItems.limitRedNum,"今日剩余红包开启次数：0",14)
                self.rootItems.limitRedNum:setString("今日剩余开启糖果次数：0")
            end
        end)
        -- animationManager:runAnimationsForSequenceNamed("opening")
        animationManager:runAnimationsForSequenceNamed("open")
    end

end

function redbag.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return redbag

