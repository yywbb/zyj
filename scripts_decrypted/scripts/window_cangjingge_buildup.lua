--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/2/17
-- Time: 11:29
-- To change this template use File | Settings | File Templates.
--


local cangjingge_buildup = {
    rootNode = nil,
    rootItems = nil,
    material1 = 0,
    material2 = 0,
    levellimit = 0,
}

function cangjingge_buildup.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("cangjingge/cangjingge_buildup", nil, true, "cangjingge_buildup")
    self.touchPriority = touchPriority
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("cangjingge_buildup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --

    self:reload(data)
    return self.rootNode
end

function cangjingge_buildup.reload(self,data)

    if data and data.material1 then
        self.material1 = data.material1
    end
    if data and data.material2 then
        self.material2 = data.material2
    end
    if data and data.levellimit then
        self.levellimit = data.levellimit
    end

    --
    ui.setLabelString(self.rootItems.upquality_lab,gameConfig.strings:string_common("cangjingge",11),18)
    self.rootItems.upquality_button:addHandleOfControlEvent(function()
        gameWindows:openWindow("cangjingge_qualityup",data,nil)
        gameWindows:closeWindowDirect("cangjingge_buildup")
    end, CCControlEventTouchUpInside)
    self.rootItems.upquality_button:setSwallowsTouch(true)
    self.rootItems.upquality_button:setTouchPriority(self.touchPriority)
    --

    local config_building = gamedata.config.home_building and gamedata.config.home_building[tostring(data.buildtype)][tostring(data.buildquality > 0 and data.buildquality or 1)] or {}

    local labelparams = (data.buildquality > 0) and (data.buildquality*2+3) or 5

    ui.setLabelString(self.rootItems.building_name,config_building.name,data.buildquality == 5 and 213 or labelparams)
    setSpriteFrameByName(self.rootItems.building_sprite, "c_b_jianzhu"..data.buildtype.."_"..(data.buildquality > 0 and data.buildquality or 1))
    local qstr = config_building.extra_attr
    local extnum = config_building.reward_up or 0
    if extnum > 0 then
        self.rootItems["quality_attr0"]:setString(gameConfig.strings:string_common("cangjingge",(data.buildtype == 1) and 30 or 29)..":")
        self.rootItems["quality_attrnum0"]:setString(extnum)
    else
        self.rootItems["quality_attr0"]:setString("")
        self.rootItems["quality_attrnum0"]:setString("")
    end

    if qstr and qstr ~= "" then
        ui.setLabelString(self.rootItems.qualityattrlab,gameConfig.strings:string_common("cangjingge",1),(data.buildquality > 0) and (data.buildquality*2+3) or 5)
        local attrs = ui.getSTRandNUMs(qstr)
        for i = 1,4 do
            if self.rootItems["quality_attr"..i] and self.rootItems["quality_attrnum"..i] then
                if attrs[i] then
                    self.rootItems["quality_attr"..i]:setString(gameConfig.strings.attr_type[attrs[i].str]..":")
                    self.rootItems["quality_attrnum"..i]:setString((attrs[i].num < 1) and ((attrs[i].num*100).."%") or attrs[i].num)
                else
                    self.rootItems["quality_attr"..i]:setString("")
                    self.rootItems["quality_attrnum"..i]:setString("")
                end
            end
        end
    else
        ui.setLabelString(self.rootItems.qualityattrlab,gameConfig.strings:string_common("cangjingge",(extnum > 0) and 1 or 2),(data.buildquality > 0) and (data.buildquality*2+3) or 5)
        self.rootItems.quality_attr1:setString("")
        self.rootItems.quality_attr2:setString("")
        self.rootItems.quality_attr3:setString("")
        self.rootItems.quality_attrnum1:setString("")
        self.rootItems.quality_attrnum2:setString("")
        self.rootItems.quality_attrnum3:setString("")
    end

    if data.buildlevel > 0 then
        self.rootItems.title_build:setVisible(false)
        self.rootItems.title_up:setVisible(true)
        self.rootItems.upqualitynode:setVisible(true)
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("cangjingge",3),18)
    else
        self.rootItems.title_build:setVisible(true)
        self.rootItems.title_up:setVisible(false)
        self.rootItems.upqualitynode:setVisible(false)
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("cangjingge",4),18)
    end

    local nextlevel = data.buildlevel+1
    local config_buildingup = gamedata.config.home_building_attr or {}
    if data.buildlevel > 0 and config_buildingup[tostring(data.buildlevel+1)] and config_buildingup[tostring(data.buildlevel+1)]["update_cost"..data.buildtype] and config_buildingup[tostring(data.buildlevel+1)]["update_cost"..data.buildtype] ~= "" then
        self.rootItems.attrnode:setVisible(true)
        self.rootItems.next_attrnode:setPositionX(260)
        nextlevel = data.buildlevel+1
        --
        ui.setLabelString(self.rootItems.name,config_building.name.."（"..data.buildlevel..gameConfig.strings:string_common("cangjingge",6).."）",(data.buildquality > 0) and (data.buildquality*2+3) or 5)
        local attrstr = config_buildingup[tostring(data.buildlevel)] and config_buildingup[tostring(data.buildlevel)]["attr"..data.buildtype] or ""
        if attrstr and attrstr ~= "" then
            local attrs = ui.getSTRandNUMs(attrstr)
            for i = 1,4 do
                if attrs[i] then
                    ui.setLabelString(self.rootItems["attr"..i],gameConfig.strings.attr_type[attrs[i].str]..":",14)
                    ui.setLabelString(self.rootItems["attrnum"..i],(attrs[i].num < 1) and ((attrs[i].num*100).."%") or attrs[i].num,14)
                else
                    ui.setLabelString(self.rootItems["attr"..i],"",14)
                    ui.setLabelString(self.rootItems["attrnum"..i],"",14)
                end
            end
        else
            for i = 1,4 do
                ui.setLabelString(self.rootItems["attr"..i],"",14)
                ui.setLabelString(self.rootItems["attrnum"..i],"",14)
            end
        end
        if data.buildtype == 1 then
            local outputstr = config_buildingup[tostring(data.buildlevel)] and config_buildingup[tostring(data.buildlevel)]["output"] or ""
            if outputstr and outputstr ~= "" then
                local outputs = ui.getIDandNUMs(outputstr)
                --
                if outputs and outputs[1] then
                    ui.setLabelString(self.rootItems["material1"],ui.IDconfig(outputs[1].cid).name..gameConfig.strings:string_common("cangjingge",5)..":",14)
                    ui.setLabelString(self.rootItems["materialnum1"],outputs[1].num.."/"..gameConfig.strings:string_common("cangjingge",7),14)
                else
                    ui.setLabelString(self.rootItems["material1"],"",14)
                    ui.setLabelString(self.rootItems["materialnum1"],"",14)
                end
                --
                if outputs and outputs[2] then
                    ui.setLabelString(self.rootItems["material2"],ui.IDconfig(outputs[2].cid).name..gameConfig.strings:string_common("cangjingge",5)..":",14)
                    ui.setLabelString(self.rootItems["materialnum2"],outputs[2].num.."/"..gameConfig.strings:string_common("cangjingge",7),14)
                else
                    ui.setLabelString(self.rootItems["material2"],"",14)
                    ui.setLabelString(self.rootItems["materialnum2"],"",14)
                end
            else
                ui.setLabelString(self.rootItems["material1"],"",14)
                ui.setLabelString(self.rootItems["materialnum1"],"",14)
                ui.setLabelString(self.rootItems["material2"],"",14)
                ui.setLabelString(self.rootItems["materialnum2"],"",14)
            end
            --
            local maxoutputstr = config_buildingup[tostring(data.buildlevel)] and config_buildingup[tostring(data.buildlevel)]["store_limit"] or ""
            if maxoutputstr and maxoutputstr ~= "" then
                local maxoutputs = ui.getIDandNUMs(maxoutputstr)
                --
                if maxoutputs and maxoutputs[1] then
                    ui.setLabelString(self.rootItems["maxmaterial1"],ui.IDconfig(maxoutputs[1].cid).name..gameConfig.strings:string_common("cangjingge",8)..":",14)
                    ui.setLabelString(self.rootItems["maxmaterialnum1"],maxoutputs[1].num,14)
                else
                    ui.setLabelString(self.rootItems["maxmaterial1"],"",14)
                    ui.setLabelString(self.rootItems["maxmaterialnum1"],"",14)
                end
                --
                if maxoutputs and maxoutputs[2] then
                    ui.setLabelString(self.rootItems["maxmaterial2"],ui.IDconfig(maxoutputs[2].cid).name..gameConfig.strings:string_common("cangjingge",8)..":",14)
                    ui.setLabelString(self.rootItems["maxmaterialnum2"],maxoutputs[2].num,14)
                else
                    ui.setLabelString(self.rootItems["maxmaterial2"],"",14)
                    ui.setLabelString(self.rootItems["maxmaterialnum2"],"",14)
                end
            else
                ui.setLabelString(self.rootItems["maxmaterial1"],"",14)
                ui.setLabelString(self.rootItems["maxmaterialnum1"],"",14)
                ui.setLabelString(self.rootItems["maxmaterial2"],"",14)
                ui.setLabelString(self.rootItems["maxmaterialnum2"],"",14)
            end
        else
            ui.setLabelString(self.rootItems["material1"],"",14)
            ui.setLabelString(self.rootItems["materialnum1"],"",14)
            ui.setLabelString(self.rootItems["material2"],"",14)
            ui.setLabelString(self.rootItems["materialnum2"],"",14)
            ui.setLabelString(self.rootItems["maxmaterial1"],"",14)
            ui.setLabelString(self.rootItems["maxmaterialnum1"],"",14)
            ui.setLabelString(self.rootItems["maxmaterial2"],"",14)
            ui.setLabelString(self.rootItems["maxmaterialnum2"],"",14)
        end
    else
        self.rootItems.attrnode:setVisible(false)
        self.rootItems.next_attrnode:setVisible(true)
        self.rootItems.next_attrnode:setPositionX(0)
        nextlevel = (data.buildlevel > 0) and data.buildlevel or 1
    end

    --next
    ui.setLabelString(self.rootItems.next_name,config_building.name.."（"..nextlevel..gameConfig.strings:string_common("cangjingge",6).."）",(data.buildquality > 0) and (data.buildquality*2+3) or 5)
    local attrstr = config_buildingup[tostring(nextlevel)] and config_buildingup[tostring(nextlevel)]["attr"..data.buildtype] or ""
    if attrstr and attrstr ~= "" then
        local attrs = ui.getSTRandNUMs(attrstr)
        for i = 1,4 do
            if attrs[i] then
                ui.setLabelString(self.rootItems["next_attr"..i],gameConfig.strings.attr_type[attrs[i].str]..":",14)
                ui.setLabelString(self.rootItems["next_attrnum"..i],(attrs[i].num < 1) and ((attrs[i].num*100).."%") or attrs[i].num,(data.buildlevel > 0) and 23 or 14)
            else
                ui.setLabelString(self.rootItems["next_attr"..i],"",14)
                ui.setLabelString(self.rootItems["next_attrnum"..i],"",(data.buildlevel > 0) and 23 or 14)
            end
        end
    else
        for i = 1,4 do
            ui.setLabelString(self.rootItems["next_attr"..i],"",14)
            ui.setLabelString(self.rootItems["next_attrnum"..i],"",(data.buildlevel > 0) and 23 or 14)
        end
    end
    if data.buildtype == 1 then
        local outputstr = config_buildingup[tostring(nextlevel)] and config_buildingup[tostring(nextlevel)]["output"] or ""
        if outputstr and outputstr ~= "" then
            local outputs = ui.getIDandNUMs(outputstr)
            --
            if outputs and outputs[1] then
                ui.setLabelString(self.rootItems["next_material1"],ui.IDconfig(outputs[1].cid).name..gameConfig.strings:string_common("cangjingge",5)..":",14)
                ui.setLabelString(self.rootItems["next_materialnum1"],outputs[1].num.."/"..gameConfig.strings:string_common("cangjingge",7),(data.buildlevel > 0) and 23 or 14)
            else
                ui.setLabelString(self.rootItems["next_material1"],"",14)
                ui.setLabelString(self.rootItems["next_materialnum1"],"",(data.buildlevel > 0) and 23 or 14)
            end
            --
            if outputs and outputs[2] then
                ui.setLabelString(self.rootItems["next_material2"],ui.IDconfig(outputs[2].cid).name..gameConfig.strings:string_common("cangjingge",5)..":",14)
                ui.setLabelString(self.rootItems["next_materialnum2"],outputs[2].num.."/"..gameConfig.strings:string_common("cangjingge",7),(data.buildlevel > 0) and 23 or 14)
            else
                ui.setLabelString(self.rootItems["next_material2"],"",14)
                ui.setLabelString(self.rootItems["next_materialnum2"],"",(data.buildlevel > 0) and 23 or 14)
            end
        else
            ui.setLabelString(self.rootItems["next_material1"],"",14)
            ui.setLabelString(self.rootItems["next_materialnum1"],"",(data.buildlevel > 0) and 23 or 14)
            ui.setLabelString(self.rootItems["next_material2"],"",14)
            ui.setLabelString(self.rootItems["next_materialnum2"],"",(data.buildlevel > 0) and 23 or 14)
        end
        --
        local maxoutputstr = config_buildingup[tostring(nextlevel)] and config_buildingup[tostring(nextlevel)]["store_limit"] or ""
        if maxoutputstr and maxoutputstr ~= "" then
            local maxoutputs = ui.getIDandNUMs(maxoutputstr)
            --
            if maxoutputs and maxoutputs[1] then
                ui.setLabelString(self.rootItems["next_maxmaterial1"],ui.IDconfig(maxoutputs[1].cid).name..gameConfig.strings:string_common("cangjingge",8)..":",14)
                ui.setLabelString(self.rootItems["next_maxmaterialnum1"],maxoutputs[1].num,(data.buildlevel > 0) and 23 or 14)
            else
                ui.setLabelString(self.rootItems["next_maxmaterial1"],"",14)
                ui.setLabelString(self.rootItems["next_maxmaterialnum1"],"",(data.buildlevel > 0) and 23 or 14)
            end
            --
            if maxoutputs and maxoutputs[2] then
                ui.setLabelString(self.rootItems["next_maxmaterial2"],ui.IDconfig(maxoutputs[2].cid).name..gameConfig.strings:string_common("cangjingge",8)..":",14)
                ui.setLabelString(self.rootItems["next_maxmaterialnum2"],maxoutputs[2].num,(data.buildlevel > 0) and 23 or 14)
            else
                ui.setLabelString(self.rootItems["next_maxmaterial2"],"",14)
                ui.setLabelString(self.rootItems["next_maxmaterialnum2"],"",(data.buildlevel > 0) and 23 or 14)
            end
        else
            ui.setLabelString(self.rootItems["next_maxmaterial1"],"",14)
            ui.setLabelString(self.rootItems["next_maxmaterialnum1"],"",(data.buildlevel > 0) and 23 or 14)
            ui.setLabelString(self.rootItems["next_maxmaterial2"],"",14)
            ui.setLabelString(self.rootItems["next_maxmaterialnum2"],"",(data.buildlevel > 0) and 23 or 14)
        end
    else
        ui.setLabelString(self.rootItems["next_material1"],"",14)
        ui.setLabelString(self.rootItems["next_materialnum1"],"",(data.buildlevel > 0) and 23 or 14)
        ui.setLabelString(self.rootItems["next_material2"],"",14)
        ui.setLabelString(self.rootItems["next_materialnum2"],"",(data.buildlevel > 0) and 23 or 14)
        ui.setLabelString(self.rootItems["next_maxmaterial1"],"",14)
        ui.setLabelString(self.rootItems["next_maxmaterialnum1"],"",(data.buildlevel > 0) and 23 or 14)
        ui.setLabelString(self.rootItems["next_maxmaterial2"],"",14)
        ui.setLabelString(self.rootItems["next_maxmaterialnum2"],"",(data.buildlevel > 0) and 23 or 14)
    end
    --
    if nextlevel <= data.buildlevel then
        self.rootItems.donode:setVisible(false)
        self.rootItems.ismaxlevel:setVisible(true)
    else
        self.rootItems.donode:setVisible(true)
        self.rootItems.ismaxlevel:setVisible(false)
        --
        ui.setLabelString(self.rootItems["dodesc"],gameConfig.strings:string_common("cangjingge",9),14)
        local coststr = config_buildingup[tostring(nextlevel)] and config_buildingup[tostring(nextlevel)]["update_cost"..data.buildtype] or ""
        if coststr and coststr ~= "" then
            local cost = ui.getIDandNUMs(coststr)
            if cost and cost[1] then
                setSpriteFrameByName(self.rootItems.icon_material1, ui.IDconfig(cost[1].cid).icon)
                ui.setLabelString(self.rootItems.poslab_material1,self.material1.."/"..cost[1].num,14)
                ui.setSpriteTextureRect2(self.rootItems.pos_material1,0,0,491 * ((self.material1 >= cost[1].num) and 1 or (self.material1/cost[1].num)), 47)
            end
            if cost and cost[2] then
                setSpriteFrameByName(self.rootItems.icon_material2, ui.IDconfig(cost[2].cid).icon)
                ui.setLabelString(self.rootItems.poslab_material2,self.material2.."/"..cost[2].num,14)
                ui.setSpriteTextureRect2(self.rootItems.pos_material2,0,0,491 * ((self.material2 >= cost[2].num) and 1 or (self.material2/cost[2].num)), 47)
            end
            --
            if data.buildtype == 1 then
                if config_buildingup[tostring(nextlevel)].update_limit and config_buildingup[tostring(nextlevel)].update_limit > GameScene.roleinfo.level then
                    ui.addGray("CCControlButton",self.rootItems.doButton)
                    self.rootItems.doButton:addHandleOfControlEvent(function()
                        runGamePrompt({msg = gameConfig.strings:safemaskLevelUp(config_buildingup[tostring(nextlevel)].update_limit)})
                    end, CCControlEventTouchUpInside)
                    self.rootItems.doButton:setSwallowsTouch(true)
                    self.rootItems.doButton:setTouchPriority(self.touchPriority)
                elseif (cost[1] and self.material1 < cost[1].num) or (cost[2] and self.material2 < cost[2].num) then
                    ui.addGray("CCControlButton",self.rootItems.doButton)
                    self.rootItems.doButton:addHandleOfControlEvent(function()
                        runGamePrompt({msg = gameConfig.strings:string_common("cangjingge",10)})
                    end, CCControlEventTouchUpInside)
                    self.rootItems.doButton:setSwallowsTouch(true)
                    self.rootItems.doButton:setTouchPriority(self.touchPriority)
                else
                    ui.removeGray("CCControlButton",self.rootItems.doButton)
                    self.rootItems.doButton:addHandleOfControlEvent(function()
                        gameTouch:clickprofbytime(1)
                        UIRequest({type = 4822,id = data.buildtype,cost = cost})
                    end, CCControlEventTouchUpInside)
                    self.rootItems.doButton:setSwallowsTouch(true)
                    self.rootItems.doButton:setTouchPriority(self.touchPriority)
                end
            else
                if nextlevel > self.levellimit then
                    ui.addGray("CCControlButton",self.rootItems.doButton)
                    self.rootItems.doButton:addHandleOfControlEvent(function()
                        local config_building1 = gamedata.config.home_building and gamedata.config.home_building["1"]["1"] or {}
                        runGamePrompt({msg = gameConfig.strings:cangjingge_uplimit(config_building1.name or "",nextlevel)})
                    end, CCControlEventTouchUpInside)
                    self.rootItems.doButton:setSwallowsTouch(true)
                    self.rootItems.doButton:setTouchPriority(self.touchPriority)
                elseif (cost[1] and self.material1 < cost[1].num) or (cost[2] and self.material2 < cost[2].num) then
                    ui.addGray("CCControlButton",self.rootItems.doButton)
                    self.rootItems.doButton:addHandleOfControlEvent(function()
                        runGamePrompt({msg = gameConfig.strings:string_common("cangjingge",10)})
                    end, CCControlEventTouchUpInside)
                    self.rootItems.doButton:setSwallowsTouch(true)
                    self.rootItems.doButton:setTouchPriority(self.touchPriority)
                else
                    ui.removeGray("CCControlButton",self.rootItems.doButton)
                    self.rootItems.doButton:addHandleOfControlEvent(function()
                        gameTouch:clickprofbytime(1)
                        UIRequest({type = 4822,id = data.buildtype,cost = cost})
                    end, CCControlEventTouchUpInside)
                    self.rootItems.doButton:setSwallowsTouch(true)
                    self.rootItems.doButton:setTouchPriority(self.touchPriority)
                end
            end
        end
    end

end

function cangjingge_buildup.close(self)
    self.material1 = 0
    self.material2 = 0
    self.levellimit = 0
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return cangjingge_buildup

�S  