--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/1/13
-- Time: 17:01
-- To change this template use File | Settings | File Templates.
--

local glory_battle_achievement = {
    rootNode = nil,
    rootItems = nil,
}

function glory_battle_achievement.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/tc_dianfengchengjiu", nil, true, "tc_dianfengchengjiu")
    self.touchPriority = touchPriority
    self.callback = callback

    ui.setNewIcon(self.rootItems,{cid = 12427})
    self.rootItems["i_button"]:addHandleOfControlEvent(function()
        local g_data = {}
        g_data.general = {}
        g_data.general.cid = 160016
        g_data.general.skill = {}
        g_data.general.skill.cid = 12427
        gameWindows:openWindow("generalInfoSkill",{data = g_data ,sid = 1, pagetype = "skillinfo",skilltype = "skill" })
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button"]:setSwallowsTouch(true)
    self.rootItems["i_button"]:setTouchPriority(self.touchPriority)


    self.rootItems["general"]:removeAllChildrenWithCleanup(true)
    local name = "yuanshitianzun_sz1"
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.3)
    Gneral1:setPosition(0,0)
    self.rootItems["general"]:addChild(Gneral1)


    UIRequest({type = 6518})

    return self.rootNode
end

function glory_battle_achievement.reload(self,data,callback)

    local config = gamedata.config.glory_battle_achievement and gamedata.config.glory_battle_achievement["1"] or {}
    local task = data.task and data.task["1"] or {}

    self.rootItems.num:setString(config.numerical)
    self.rootItems.pos:setString((task.now > config.numerical and config.numerical or task.now).."/"..config.numerical)

    if task.status == 1 then
        ui.removeGray("CCControlButton",self.rootItems.getBtn)
        ui.setLabelString(self.rootItems.getBtnTxt,"领 取",19)
    elseif task.status == 2 then
        ui.addGray("CCControlButton",self.rootItems.getBtn)
        ui.setLabelString(self.rootItems.getBtnTxt,"已领取",19)
    else 
        ui.addGray("CCControlButton",self.rootItems.getBtn)
        ui.setLabelString(self.rootItems.getBtnTxt,"未达成",19)   
    end    

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("glory_battle_achievement")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --

    self.rootItems.getBtn:addHandleOfControlEvent(function()
        if task.status == 1 then
            gameTouch:clickprofbytime(1)
            UIRequest({type = 6519, id = 1})
        elseif task.status == 2 then
            runGamePrompt({msg = "已领取"})
        else
            runGamePrompt({msg = "未达成"})
        end   
        --gameWindows:closeWindowDirect("glory_battle_achievement")
    end, CCControlEventTouchUpInside)
    self.rootItems.getBtn:setSwallowsTouch(true)
    self.rootItems.getBtn:setTouchPriority(self.touchPriority)


end

function glory_battle_achievement.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return glory_battle_achievement

