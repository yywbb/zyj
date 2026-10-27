--
-- Author: songyibo
-- Date: 2019-09-23 15:03:56
--


local ancientRuinsMonster = {
    rootNode = nil,
    rootItems = nil,
    data = {},
}

function ancientRuinsMonster.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shangguyiji/monster_info", nil, true, "monster_info")

    self.touchPriority = touchPriority
    self.callback = callback
    self.data = data

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("ancientRuinsMonster")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    printT(data,"ancientRuinsMonster")
    self.mapId = data.mapId
    self.pos = data.pos
    self.monsterId = data.monsterId
    self.mapData = data.data

    self:reload()
    return self.rootNode
end

function ancientRuinsMonster.reload(self,data)
        
    local mapConfig = gamedata.config.shanggu_stance[tostring(self.mapId)][tostring(self.mapData.map[tostring(self.mapId)].mapId)]
    if self.pos == 0 then
        self.rootItems.bossCondition:setString(gameConfig.strings:string_common("ancientRuins",4)..self.mapData["attackNum"..self.mapId].."/"..mapConfig.need_num)

        if self.mapData["attackNum"..self.mapId] >= mapConfig.need_num then
            ui.setLabelString(self.rootItems.bossCondition,nil,75)
        else
            ui.setLabelString(self.rootItems.bossCondition,nil,76)
        end
    else
        self.rootItems.bossCondition:setString("")
    end

    --
    self.config = gamedata.config.shanggu_monster[tostring(self.monsterId)]
    --
    ui.setLabelString(self.rootItems["generalName"],self.config.name,1)
    --
    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(self.config.icon).animationid)].name
    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.5)
    Gneral:setScaleX(1.5)
    Gneral:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral)
    --

    local dropdata = gamedata.getIDandNUMs(self.config.drop_no1)
    local key_Ex = ""
    for i = 1,4 do
        local index = i

        if dropdata[i] then
        	self.rootItems["reward"..i]:setVisible(true)
            ui.setNewIconName(self.rootItems,{cid = dropdata[i].cid, num = dropdata[i].num},i-1)
             if i == nil or i == 1 then
                 key_Ex = ""
             else
                 key_Ex = "_"..(i-1)
             end
            self.rootItems["i_button" .. key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(dropdata[i].cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button" .. key_Ex]:setSwallowsTouch(true)
            self.rootItems["i_button" .. key_Ex]:setTouchPriority(self.touchPriority) 
        else
       		self.rootItems["reward"..i]:setVisible(false)
        end
    end
    --
    ui.setLabelString(self.rootItems["lab1"],nil,21)
    ui.setLabelString(self.rootItems["battleLab"],nil,19)



    if (self.mapData.challengeTime >= tonumber(gamedata.config.global_kv.shanggu_num.value)) and self.pos ~= 0 then
        ui.addGray("CCControlButton",self.rootItems.battleButton)
    elseif self.mapData["attackNum"..self.mapId] < mapConfig.need_num and self.pos == 0 then
        ui.addGray("CCControlButton",self.rootItems.battleButton)
    else
        ui.removeGray("CCControlButton",self.rootItems.battleButton)
    end

    self.rootItems.battleButton:addHandleOfControlEvent(function()
        if (self.mapData.challengeTime >= tonumber(gamedata.config.global_kv.shanggu_num.value)) and self.pos ~= 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("ancientRuins",5)})
        elseif self.mapData["attackNum"..self.mapId] < mapConfig.need_num and self.pos == 0 then
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("ancientRuins",6),mapConfig.need_num )})
        else
            gameTouch:clickprofbytime(1)
            UIRequest({type = 7081, mapId = self.mapId, pos = self.pos})
            self:closedelay()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.battleButton:setSwallowsTouch(true)
    self.rootItems.battleButton:setTouchPriority(self.touchPriority)
    --
end

function ancientRuinsMonster.closedelay(self)
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        gameWindows:closeWindowDirect("ancientRuinsMonster")
    end))
    self.rootNode:runAction(sequence)
end

function ancientRuinsMonster.close(self)
    self.data = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return ancientRuinsMonster
