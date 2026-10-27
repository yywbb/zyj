--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/11
-- Time: 上午11:18
-- To change this template use File | Settings | File Templates.
--

local lvup = {
    rootNode = nil,
    rootItems = nil,
}

function lvup.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/player_up", nil, true, "player_up")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function lvup.reload(self,data,callback)
    self.callback = callback

    local oldconfig = gamedata.config.role_exp[tostring(data.oldlevel)]
    local newconfig = gamedata.config.role_exp[tostring(data.newlevel)]

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("userLevelup")
        --UIRequest({type = 10012})
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local shareshow =  gameConfig:checkBuildOpen(153) and (not guide.controller or not guide.controller.isOnGuide)



    if shareshow then
        -- ui.setLabelString(self.rootItems.confirmlab,"确 定",19)
        ui.setLabelString(self.rootItems.shareText, "分 享", 19)
        self.rootItems.shareBtn:addHandleOfControlEvent(function()
            print("分享")
            gameWindows:closeWindow("userLevelup")
            --UIRequest({type = 10012})
        end, CCControlEventTouchUpInside)
        self.rootItems.shareBtn:setSwallowsTouch(true)
        self.rootItems.shareBtn:setTouchPriority(self.touchPriority)
    else
        self.rootItems.shareNode:setVisible(false)
    end

    ui.setLabelString(self.rootItems.confirmlab,gameConfig.strings:string_common("popups","queding"),19)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        gameWindows:closeWindow("userLevelup")
        --UIRequest({type = 10012})
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

    self.rootItems.doNode:setPositionX(shareshow and 780 or 540)

    self.rootItems.newlevel:setString(data.newlevel)

    -- ui.setLabelString(self.rootItems.staminades,"体力上限",12)
    -- ui.setLabelString(self.rootItems.energydes,"杀气上限",12)
    -- ui.setLabelString(self.rootItems.leveldes,"伙伴装备等级上限",12)
    ui.setLabelString(self.rootItems.staminades,gameConfig.strings:string_common("popups","tilishangxian"),121)
    ui.setLabelString(self.rootItems.energydes,gameConfig.strings:string_common("popups","shaqishangxian"),121)
    ui.setLabelString(self.rootItems.leveldes,gameConfig.strings:string_common("popups","huobanshangxian"),121)

    ui.setLabelString(self.rootItems.coin,newconfig.c_reward,13)
    ui.setLabelString(self.rootItems.gold,newconfig.g_reward,13)


    ui.setLabelString(self.rootItems.oldstamina,oldconfig.maxstamina,13)
    ui.setLabelString(self.rootItems.oldenergy,oldconfig.maxenergy,13)
    ui.setLabelString(self.rootItems.oldgenerallevel,data.oldlevel*tonumber(gamedata.config.global_kv.equip_level.value),13)
    ui.setLabelString(self.rootItems.newstamina,newconfig.maxstamina,26)
    ui.setLabelString(self.rootItems.newenergy,newconfig.maxenergy,26)
    ui.setLabelString(self.rootItems.newgenerallevel,data.newlevel*tonumber(gamedata.config.global_kv.equip_level.value),26)

    --printT(gamedata.config.build_level)
    local config = gamedata.config.build_level[data.newlevel]


    local show = {}
    if config then
        for k,v in pairs(config) do
            if v.priority >0 and #show <=2 then
                table.insert(show,v)
            end
        end
    end
    ui.sortData(show,"priority")


    local nextlevel = data.newlevel+1

    while #show <3 and nextlevel<=table.getTableLength(gamedata.config.role_exp) do
        if gamedata.config.build_level[nextlevel] then
            for k,v in pairs(gamedata.config.build_level[nextlevel]) do
                if v.priority >0 and #show <3 then
                    table.insert(show,v)
                end
            end
        end
        nextlevel = nextlevel + 1
    end


    for i=1, 3  do
        if show[i] then
            self:setNew(self.rootItems,show[i],i-1,data.newlevel,newconfig)
        else
            self.rootItems["new"..i]:setVisible(false)
        end
    end

    if guide.controller then
        guide.controller:LevelUp3(data.newlevel)
    end

    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        if guide.controller then
            guide.controller:setGuideLayerVisible(true)
        end
    end)))

    gamedata.music:PlayOptSound("role_levelup")
end

function lvup.setNew(self,item,data,id,newlevel,newconfig)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    setSpriteFrameByName(item["in_icon"..key_Ex], data.icon or "alpha")
    item["in_name"..key_Ex]:setString(data.name or "")
    item["in_des"..key_Ex]:setString(data.des or "")

    if data.level == newlevel then
        item["in_goto"..key_Ex]:setVisible(true)
        item["in_openlevel"..key_Ex]:setVisible(false)
        item["in_button"..key_Ex]:addHandleOfControlEvent(function()
            if guide.controller then
                guide.controller:CompleteStep("click2",8061)
            end
            self.callback = nil
            setbattlecallbackactive(false)
            gameWindows:closeWindowDirect("userLevelup")
            --UIRequest({type = 10012})
            GameScene:shiftLayerById(data.id)
        end, CCControlEventTouchUpInside)
        item["in_button"..key_Ex]:setSwallowsTouch(true)
        item["in_button"..key_Ex]:setTouchPriority(self.touchPriority)
    else
        item["in_goto"..key_Ex]:setVisible(false)
        item["in_openlevel"..key_Ex]:setVisible(true)
        -- ui.setLabelString(self.rootItems["in_openlevel"..key_Ex],data.level.."级开启",28)
        ui.setLabelString(self.rootItems["in_openlevel"..key_Ex],gameConfig.strings:lvOpen(data.level),28)
    end

end

function lvup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if guide.controller then
        guide.controller:UIComplete(8048)
    end

    if self.callback then
        self.callback()
    end
end

return lvup