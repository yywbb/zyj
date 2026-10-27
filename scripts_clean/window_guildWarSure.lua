--公会战的二次确认

local window_guildWarSure = {
    rootNode = nil,
    rootItems = nil,
}

function window_guildWarSure.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.data = data
    --if data.index == "queren" then
    self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/tc_two_sure", nil, true, "tc_two_sure")
    --end

    ui.setLabelString(self.rootItems.yesLab,nil,19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        if callback then
            callback()
        end
        gameWindows:closeWindow("guildWarSure")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.noLab,nil,19)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("guildWarSure")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("guildWarSure")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self:reload(self.data, callback)
    self.root:addChild(self.rootNode)

    return self.root
end

function window_guildWarSure.reload(self,data,callback)
    print("querenReload==")
    local globConfig = gamedata.config.global_kv
    if data.index == 1 then
        self.rootItems.desc:setString("21:00时拥有战斗资格社团的成员可自动进入战场无需再进行手动参战，是否消耗元宝购买一键参战功能。")
        local costData = gamedata.getIDandNUMs(globConfig.quick_war_cost.value)
        self.rootItems.costLab:setString("消耗元宝:".. costData[1].num)
        self.rootItems.title:setString("自动参战")
    elseif data.index == 2 then
        self.rootItems.desc:setString("21:00是拥有战斗资格的社团进入战场可获得鼓舞加成无需参战后进行手动鼓舞，是否消耗元宝和银币进行鼓舞。")
        local costData = gamedata.getIDandNUMs(globConfig.quick_Inspire_cost.value)
        self.rootItems.costLab:setString("消耗元宝:".. costData[1].num)
        self.rootItems.title:setString("一键鼓舞")
    end

end

function window_guildWarSure.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end


return window_guildWarSure
