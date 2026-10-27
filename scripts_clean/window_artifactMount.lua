--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local artifactMount = {
    rootNode = nil,
    rootItems = nil,

}

function artifactMount.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("duanzaoshenqi/duanzaoshenqi_info", nil, true, "duanzaoshenqi_info")
    self.rootItems.equip1:setVisible(true)
    self.rootItems.equip2:setVisible(true)
    self.rootItems.equip3:setVisible(true)
    self.rootItems.equip4:setVisible(true)
    self.rootItems.jewelPanel:setVisible(false)
    self.rootItems.extPanel:setVisible(false)
    self:initFixedString()
    --
    self.touchPriority = touchPriority
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactMount")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.gotoButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactMount")
        GameScene:shiftLayer("artifactCreate","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton:setSwallowsTouch(true)
    self.rootItems.gotoButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.doNode:setVisible(true)
    self.rootItems.upNode:setVisible(false)
    self.rootItems.downNode:setVisible(false)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactMount")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    --
    self:reload(data,callback)
    return self.rootNode
end

function artifactMount.initFixedString(self)
    ui.setLabelString(self.rootItems.upLab,gameConfig.strings:string_common("artifact",6),19)
    self.rootItems.title:setString(gameConfig.strings:string_common("artifact",7))
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("battleScene",3),19)
    ui.setLabelString(self.rootItems.downLab,gameConfig.strings:string_common("artifact",5),19)
    self.rootItems.fixed1:setString(gameConfig.strings:string_common("generalInfo",34))
    self.rootItems.gotoLab:setString(gameConfig.strings:string_common("artifact",8))
    ui.setLabelString(self.rootItems.gotoLab,gameConfig.strings:string_common("artifact",8),18)
end

function artifactMount.setArtifactPromote(self,labName1,lab1,labName2,lab2)
    local config = ui.IDconfig(self.data.cid)
    if not config then
        return
    end
    local index = "effect"
    if self.data.ishigh and self.data.ishigh > 0 then
        index = "effect2"
    end

    local attrData = ui.getThreeSomeStrings(config[index])
    local type,num = "",""
    if attrData[1] then
        type = gameConfig.strings.attr_type[attrData[1][1]]..":"
        num = "+"..(attrData[1][3])*(attrData[1][2] == "value" and 1 or 100)..(attrData[1][2] == "value" and "" or "%")
        labName1:setString(type)
        lab1:setString(num)
    end
    
    if attrData[2] then
        type,num = "",""
        type = gameConfig.strings.attr_type[attrData[2][1]]..":"
        num = "+"..(attrData[2][3])*(attrData[2][2] == "value" and 1 or 100)..(attrData[2][2] == "value" and "" or "%")
        labName2:setString(type)
        lab2:setString(num)
    end
end

function artifactMount.setData(self)
    local config = gamedata.config.trump[tostring(self.data.cid)]
    setSpriteFrameByName(self.rootItems.icon,config.icon and config.icon or "alpha")
    ui.setLabelString(self.rootItems.name,config.name,9)
    self:setArtifactPromote(self.rootItems["attr1name"],self.rootItems["attr1"],
    self.rootItems["attr2name"],self.rootItems["attr2"],self.data)
    for i = 1,4 do
        self:setMountInfo(i,config)
    end
end

function artifactMount.reload(self,data,callback)
    self.callback = callback
    self.data = data.artifactData
    UIRequest({type = 10031})
end

function artifactMount.setMountInfo(self,pos,artifactConfig)
    local jewelData = self.data["jewel"..pos]
    self:setJewelIcon(self.rootItems,jewelData,pos)

    local key_Ex = pos <= 1 and "" or "_"..(pos - 1)
    if jewelData > 0 then
        self.rootItems["attr"..key_Ex]:setVisible(true)
        ui.setAttrStr(self.rootItems["attr"..key_Ex],{cid = jewelData})
    else
        self.rootItems["attr"..key_Ex]:setVisible(false)
    end

    self.rootItems["tipName"..key_Ex]:removeAllChildrenWithCleanup(true)
    if jewelData == 0 then
        ui.setLabelString(self.rootItems["tipName"..key_Ex],gameConfig.strings:string_common("artifact",23),21)
    elseif jewelData > 0 then
        local config = gamedata.config.trump_gem[tostring(jewelData)]
        ui.setLabelString(self.rootItems["tipName"..key_Ex],config.name,1)
        --self.rootItems["tipName"..key_Ex]:setString(config.name)
    else
        if GameScene.roleinfo.level < artifactConfig["hole_lv"..pos] then
            ui.setLabelString(self.rootItems["tipName"..key_Ex],gameConfig.strings:lvOpen(artifactConfig["hole_lv"..pos]),21)
        else
            ui.setLabelString(self.rootItems["tipName"..key_Ex],gameConfig.strings:string_common("artifact",22),21)
        end
    end

    self.rootItems["touchBtn"..key_Ex]:addHandleOfControlEvent(function()
        if self.data["jewel"..pos] > 0 then
            gameWindows:openWindow("jewelInfo",{cid = self.data["jewel"..pos],artifact = self.data,isUp = true,pos = pos},nil)
        elseif self.data["jewel"..pos] == 0 then
            gameWindows:openWindow("jewelSelect",{artifact = self.data,pos = pos},nil)
        else
            if GameScene.roleinfo.level < artifactConfig["hole_lv"..pos] then
                runGamePrompt({msg = gameConfig.strings:lvOpen(artifactConfig["hole_lv"..pos])})
            else
                gameWindows:openWindow("artifactOpenPos",{artifact = self.data,pos = pos},nil)
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["touchBtn"..key_Ex]:setSwallowsTouch(true)
    self.rootItems["touchBtn"..key_Ex]:setTouchPriority(self.touchPriority)
end

function artifactMount.reloadData(self,t)
    local config = gamedata.config.trump[tostring(self.data.cid)]
    for i = 1,4 do
        if self.data["jewel"..i] ~= t.artifact["jewel"..i] then
            self.data["jewel"..i] = t.artifact["jewel"..i]
            self:setMountInfo(i,config)
        end
    end
end

function artifactMount.setJewelIcon(self,items,jewelData,number)
    local key_Ex = number <= 1 and "" or "_"..(number - 1)
    items["toMount"..key_Ex]:setVisible(jewelData == 0)
    if jewelData == 0 then
    ui.blink(items["soul_adddes"..key_Ex],1)
        ui.blink(items["soul_add"..key_Ex],1)
    else
        items["soul_adddes"..key_Ex]:stopAllActions()
        items["soul_add"..key_Ex]:stopAllActions()
    end
    items["suo"..key_Ex]:setVisible(jewelData < 0)
    items["i_notice"..key_Ex]:setVisible(jewelData > 0 and CheckCanUpgrade(jewelData + 1))
    if jewelData > 0 then
        local config = gamedata.config.trump_gem[tostring(jewelData)]
        setSpriteFrameByName(items["i_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(items["i_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(items["i_icon"..key_Ex], config.icon and config.icon or "alpha")
        ui.setSpriteTextureRect(items["i_icon"..key_Ex],0,0,150,150)
    else
        setSpriteFrameByName(items["i_k_quality"..key_Ex], "b_s_iconk1")
        setSpriteFrameByName(items["i_quality"..key_Ex], "b_iconbg8")
        setSpriteFrameByName(items["i_icon"..key_Ex], "obj_soul2")
    end
    -- items["i_button"]:addHandleOfControlEvent(function()
    --     if self.data["jewel"..number] > 0 then
    --         gameWindows:openWindow("jewelInfo",{cid = self.data["jewel"..number],isUp = true},nil)
    --     elseif self.data["jewel"..number] == 0 then
    --         gameWindows:openWindow("jewelSelect",{artifact = self.data,pos = number},nil)
    --     else

    --     end
    -- end, CCControlEventTouchUpInside)
    -- items["i_button"]:setSwallowsTouch(true)
    -- items["i_button"]:setTouchPriority(self.touchPriority)
end

function artifactMount.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return artifactMount