--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/2/17
-- Time: 11:29
-- To change this template use File | Settings | File Templates.
--


local cangjingge_guai = {
    rootNode = nil,
    rootItems = nil,
    isauto = 0,
}

function cangjingge_guai.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("cangjingge/cangjingge_guai", nil, true, "cangjingge_guai")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function cangjingge_guai.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("cangjingge_guai")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    if self.rootItems.autoBtnNode then
        self.rootItems.autosprite:setVisible(self.isauto == 1)
        self.rootItems.autobutton:addHandleOfControlEvent(function()
            self.isauto = (self.isauto > 0) and 0 or 1
            self.rootItems.autosprite:setVisible(self.isauto == 1)
        end, CCControlEventTouchUpInside)
        self.rootItems.autobutton:setSwallowsTouch(true)
        self.rootItems.autobutton:setTouchPriority(self.touchPriority)
    end
    --
    local monsterconfig = gamedata.config.home_monster[tostring(data.monster)] or {}
    --
    self.rootItems["monstergeneral"]:removeAllChildrenWithCleanup(true)
    local gcid = monsterconfig.monsterid or 10301
    local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(gcid).animationid)].name
    local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.rootItems["monstergeneral"]:addChild(Gneral1.root or Gneral1)
    --
    ui.setLabelString(self.rootItems.monstername,monsterconfig.monster_name,1)

    ui.setLabelString(self.rootItems.fixstring1,gameConfig.strings:string_common("cangjingge",31),14)
    ui.setLabelString(self.rootItems.fixstring2,gameConfig.strings:string_common("cangjingge",32),14)

    local reward = ui.getIDandNUMs(monsterconfig.loot)
    for i = 1,2 do
        if reward and reward[i] then
            setSpriteFrameByName(self.rootItems["rewardicon"..i],ui.IDconfig(reward[i].cid).icon)
            ui.setLabelString(self.rootItems["rewardnum"..i],"x"..reward[i].num,14)
        else
            setSpriteFrameByName(self.rootItems["rewardicon"..i], "alpha")
            ui.setLabelString(self.rootItems["rewardnum"..i],"",14)
        end
    end

    ui.setLabelString(self.rootItems.to1,"",14)
    ui.setLabelString(self.rootItems.to2,"",14)
    local randreward = {}
    if monsterconfig.random_loot and monsterconfig.random_loot ~= "" then
        randreward = ui.getIDRandNums(monsterconfig.random_loot)
    end
    local randreward2 = {}
    if GameScene.cangjingge and GameScene.cangjingge.building and GameScene.cangjingge.building["1"] and GameScene.cangjingge.building["1"].level and GameScene.cangjingge.building["1"].level > 0 then
        randreward2 = ui.getIDRandNums(gamedata.config.home_building_attr[tostring(GameScene.cangjingge.building["1"].level)].monster_reward)
    end
    local ddd = 1
    if randreward2[1] then
        ddd = 3
        ui.setLabelString(self.rootItems.to1,"~",14)
        self.rootItems["prop1"]:setVisible(true)
        ui.setNewIcon(self.rootItems,{cid = randreward2[1][1],num = randreward2[1][2]})
        self.rootItems["i_button"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(randreward2[1][1])
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"]:setTouchPriority(self.touchPriority)
        self.rootItems["prop2"]:setVisible(true)
        ui.setNewIcon(self.rootItems,{cid = randreward2[1][1],num = randreward2[1][3]},1)
        self.rootItems["i_button_1"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(randreward2[1][1])
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button_1"]:setTouchPriority(self.touchPriority)
    end
    if randreward2[2] then
        ddd = 5
        ui.setLabelString(self.rootItems.to2,"~",14)
        self.rootItems["prop3"]:setVisible(true)
        ui.setNewIcon(self.rootItems,{cid = randreward2[2][1],num = randreward2[2][2]},2)
        self.rootItems["i_button_2"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(randreward2[2][1])
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button_2"]:setTouchPriority(self.touchPriority)
        self.rootItems["prop4"]:setVisible(true)
        ui.setNewIcon(self.rootItems,{cid = randreward2[2][1],num = randreward2[2][3]},3)
        self.rootItems["i_button_3"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(randreward2[2][1])
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button_3"]:setTouchPriority(self.touchPriority)
    end

    for i = ddd,5 do
        if randreward and randreward[i] then
            self.rootItems["prop"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,{cid = randreward[i][1],num = randreward[i][2]},i-1)
            self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(randreward[i][1])
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)
        else
            self.rootItems["prop"..i]:setVisible(false)
        end
    end

    --local killcount = gamedata.config.global_kv.home_monster_kill_limit and tonumber(gamedata.config.global_kv.home_monster_kill_limit.value) or 0
    ui.setLabelString(self.rootItems.count_lab,gameConfig.strings:string_common("cangjingge",34),1)
    ui.setLabelString(self.rootItems.count,data.count or 0,14)
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("cangjingge",33),18)
    if (data.count or 0) > 0 then
        ui.removeGray("CCControlButton",self.rootItems.doButton)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            UIRequest({type = 4828,rid = data.rid,monsterpos = data.monsterpos,isauto = self.isauto or 0})
            gameWindows:closeWindowDirect("cangjingge_guai")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    else
        ui.addGray("CCControlButton",self.rootItems.doButton)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("cangjingge",35)})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    end
end

function cangjingge_guai.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return cangjingge_guai

