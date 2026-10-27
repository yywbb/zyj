--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/7/1
-- Time: 10:55
-- To change this template use File | Settings | File Templates.
--

local deploymentLevelUp = {
    rootNode = nil,
    rootItems = nil,
    showindex = 1,
    slotSpirit = {},
    xprops = {},
    addition = nil,
}

function deploymentLevelUp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("soulzhen/soulzhen_up", nil, true, "soulzhen_up")
    self.touchPriority = touchPriority
    self.callback = callback
    self.showindex = data.showindex or 1
    self.slotSpirit = data.slotSpirit or {}
    self:reload(self.slotSpirit)
    self:initFixedString()
    UIRequest{type = 4204, opt = "up"}
    return self.rootNode
end

function deploymentLevelUp.reloadAddition(self,data)
    if data then
        if self.addition then
            local temp = table.copy(data.activation)
            for k,v in pairs(temp) do
                for k1,v1 in pairs(self.addition.activation) do
                    if v == v1 then
                        temp[k] = nil
                    end
                end
            end
            local config = gamedata.config.lingzhentu_add or {}
            for k,v in pairs(temp) do
                if config[tostring(v)] then
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","deployment",11).." \""..(config[tostring(v)].desc or "").."\""})
                end
            end
        end
        self.addition = data
    end
end

function deploymentLevelUp.reload(self,data)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("deploymentLevelUp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    if not data then return end
    --
    if self.rootItems.effectNode then
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
    end
    if self.slotSpirit and self.slotSpirit.level and self.slotSpirit.level[tostring(self.showindex)] then
        if data and data.level and data.level[tostring(self.showindex)] and data.level[tostring(self.showindex)] > self.slotSpirit.level[tostring(self.showindex)] then
            if self.rootItems.effectNode then
                local eccb,eitem = CCBReaderLoad("UIEffect/up/shengjiup", nil, true, "shengjiup")
                self.rootItems.effectNode:addChild(eccb)
            end
        end
    end
    --
    self.slotSpirit = data
    --
    self:setSlotSpiritShow()


end

function deploymentLevelUp.setSlotSpiritShow(self)
    local zhenconfig = gamedata.config.lingzhentu_zhenfa or {}
    if not zhenconfig[tostring(self.showindex)] then return end
    --
    self.rootItems.zhenname:setString(zhenconfig[tostring(self.showindex)].name or "")
    ui.setLabelString(self.rootItems.desc,zhenconfig[tostring(self.showindex)].desc or "",14)
    ui.setLabelString(self.rootItems.next_desc,zhenconfig[tostring(self.showindex)].desc or "",14)
    ui.setLabelString(self.rootItems.maxlevel,nil,18)
    ui.setLabelString(self.rootItems.lab1,gameConfig.strings:string_common("fixedString","deployment",10),14)
    ui.setLabelString(self.rootItems.upLab,nil,18)
    --
    local level = 1
    if self.slotSpirit.level and self.slotSpirit.level[tostring(self.showindex)] then
        level = self.slotSpirit.level[tostring(self.showindex)]
    end
    ui.setLabelString(self.rootItems.level,"等级:"..level,14)
    local jihuoconfig = gamedata.config.lingzhentu_jihuo or {}
    if not jihuoconfig[tostring(self.showindex)] then return end
    for i = 1,7 do
        if jihuoconfig[tostring(self.showindex)][tostring(i)] and jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..level] and jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..level] ~= "" then
            ui.setLabelString(self.rootItems["activationLab"..i],gameConfig.strings:slotSpiritActivation(i),4)
            local attr,num = ui.getSTRandNUM(jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..level])
            ui.setLabelString(self.rootItems["activationAttr"..i],(gameConfig.strings.attr_type[attr] or "").." +"..(num or 0),2)
        else
            ui.setLabelString(self.rootItems["activationLab"..i],"",4)
            ui.setLabelString(self.rootItems["activationAttr"..i],"",2)
        end
    end
    --
    local lvconfig = gamedata.config.lingzhentu_lv or {}
    if lvconfig[tostring(level+1)] then
        self.rootItems.nextNode:setVisible(true)
        self.rootItems.nowNode:setPositionX(-250)
        self.rootItems.levelupNode:setVisible(true)
        self.rootItems.maxlevel:setVisible(false)
        for i = 1,7 do
            if jihuoconfig[tostring(self.showindex)][tostring(i)] and jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..(level+1)] and jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..(level+1)] ~= "" then
                ui.setLabelString(self.rootItems["next_activationLab"..i],gameConfig.strings:slotSpiritActivation(i),4)
                local attr,num = ui.getSTRandNUM(jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..(level+1)])
                ui.setLabelString(self.rootItems["next_activationAttr"..i],(gameConfig.strings.attr_type[attr] or "").." +"..(num or 0),2)
            else
                ui.setLabelString(self.rootItems["next_activationLab"..i],"",4)
                ui.setLabelString(self.rootItems["next_activationAttr"..i],"",2)
            end
        end
        --prop
        local lv_cond = lvconfig[tostring(level)].lv_cond or 0
        local propnum = 0
        local propstr = lvconfig[tostring(level)].cost
        local props = ui.getIDandNUMs(propstr)
        self.rootItems.coinNode:setVisible(false)
        for i = 1,5 do
            self.rootItems["prop"..i]:setVisible(false)
        end
        self.xprops = {}
        local cids = {}
        for k,v in pairs(props) do
            if v.cid == 1000 then
                self.rootItems.coinNode:setVisible(true)
                ui.setLabelString(self.rootItems.coin,v.num,(v.num > GameScene.roleinfo.coin) and 24 or 13)
            else
                propnum = propnum+1
                self.rootItems["prop"..propnum]:setVisible(true)
                ui.setNewIconName(self.rootItems,v,propnum-1)
                self.xprops[tostring(v.cid)] = {cid = v.cid, num = v.num, index = propnum, hasnum = 0, }
                table.insert(cids,v.cid)
                --
                self.rootItems["in_button"..((propnum > 1) and ("_"..(propnum-1)) or "")]:addHandleOfControlEvent(function()
                    ui.setPopwindowByCid(v.cid)
                end, CCControlEventTouchUpInside)
                self.rootItems["in_button"..((propnum > 1) and ("_"..(propnum-1)) or "")]:setSwallowsTouch(true)
                self.rootItems["in_button"..((propnum > 1) and ("_"..(propnum-1)) or "")]:setTouchPriority(self.touchPriority)
            end
        end
        UIRequest({type = 12001, order = 42021, cids = cids})
        self.rootItems.upButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            --
            if lv_cond > GameScene.roleinfo.level then
                runGamePrompt({msg = gameConfig.strings:deploymentLevelUp(lv_cond)})
            else
                UIRequest{type = 4202, id = self.showindex, props = props }
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.upButton:setSwallowsTouch(true)
        self.rootItems.upButton:setTouchPriority(self.touchPriority)
    else
        self.rootItems.nextNode:setVisible(false)
        self.rootItems.nowNode:setPositionX(0)
        self.rootItems.levelupNode:setVisible(false)
        self.rootItems.maxlevel:setVisible(true)
    end


    self:setSlotSpiritActivation()
end

function deploymentLevelUp.setSlotSpiritActivation(self)
    if self.slotSpirit.use and self.slotSpirit.use == self.showindex then
        local activationNum = 0
        for k,v in pairs(self.slotSpirit.activation or {}) do
            if v == 1 then
                activationNum = activationNum+1
            end
        end
        for i = 1,7 do
            if activationNum >= i then
                -- ui.removeGray("CCLabelTTF",self.rootItems["activationLab"..i])
                -- ui.removeGray("CCLabelTTF",self.rootItems["activationAttr"..i])
                -- ui.removeGray("CCLabelTTF",self.rootItems["next_activationLab"..i])
                -- ui.removeGray("CCLabelTTF",self.rootItems["next_activationAttr"..i])

                ui.setLabelString(self.rootItems["activationLab"..i],nil,4)
                ui.setLabelString(self.rootItems["activationAttr"..i],nil,2)
                ui.setLabelString(self.rootItems["next_activationLab"..i],nil,4)
                ui.setLabelString(self.rootItems["next_activationAttr"..i],nil,2)
            else
                -- ui.addGray("CCLabelTTF",self.rootItems["activationLab"..i])
                -- ui.addGray("CCLabelTTF",self.rootItems["activationAttr"..i])
                -- ui.addGray("CCLabelTTF",self.rootItems["next_activationLab"..i])
                -- ui.addGray("CCLabelTTF",self.rootItems["next_activationAttr"..i])

                ui.setLabelString(self.rootItems["activationLab"..i],nil,13)
                ui.setLabelString(self.rootItems["activationAttr"..i],nil,13)
                ui.setLabelString(self.rootItems["next_activationLab"..i],nil,13)
                ui.setLabelString(self.rootItems["next_activationAttr"..i],nil,13)
            end
        end
    else
        for i = 1,7 do
            -- ui.addGray("CCLabelTTF",self.rootItems["activationLab"..i])
            -- ui.addGray("CCLabelTTF",self.rootItems["activationAttr"..i])
            -- ui.addGray("CCLabelTTF",self.rootItems["next_activationLab"..i])
            -- ui.addGray("CCLabelTTF",self.rootItems["next_activationAttr"..i])

            ui.setLabelString(self.rootItems["activationLab"..i],nil,13)
            ui.setLabelString(self.rootItems["activationAttr"..i],nil,13)
            ui.setLabelString(self.rootItems["next_activationLab"..i],nil,13)
            ui.setLabelString(self.rootItems["next_activationAttr"..i],nil,13)
        end
    end
end

function deploymentLevelUp.setPropNum(self,data)
    for k,v in pairs(self.xprops) do
        if data[tostring(v.cid)] then
            v.hasnum = data[tostring(v.cid)] or 0
            ui.setLabelString(self.rootItems["in_num"..((v.index > 1) and ("_"..(v.index-1)) or "")],v.hasnum.."/"..v.num,(v.num > v.hasnum) and 24 or 13)
        end
    end
end

function deploymentLevelUp.close(self)
    self.addition = nil
    self.showindex = 1
    self.slotSpirit = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function deploymentLevelUp.initFixedString(self)
    self.rootItems.fixlab2:setString(gameConfig.strings:string_common("fixedString","deployment",3))
    self.rootItems.fixlab3:setString(gameConfig.strings:string_common("fixedString","deployment",3))
end

return deploymentLevelUp