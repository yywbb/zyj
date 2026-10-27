--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/2/17
-- Time: 11:29
-- To change this template use File | Settings | File Templates.
--


local cangjingge_qualityup = {
    rootNode = nil,
    rootItems = nil,
}

function cangjingge_qualityup.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("cangjingge/cangjingge_pinzhiup", nil, true, "cangjingge_qualityup")
    self.touchPriority = touchPriority

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.rootItems.container:setPositionY(-280)

    self:reload(data,callback)
    return self.rootNode
end

function cangjingge_qualityup.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("cangjingge_qualityup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --

    for i = 1,5 do
        if gamedata.config.home_building[tostring(data.buildtype)] and gamedata.config.home_building[tostring(data.buildtype)][tostring(i)] then
            self.rootItems["t"..i.."_node"]:setVisible(true)
            ui.setLabelString(self.rootItems["t"..i.."_upquality_lab"],gameConfig.strings:string_common("cangjingge",11),18)
            self.rootItems["t"..i.."_upquality_button"]:addHandleOfControlEvent(function()
                gameWindows:closeWindowDirect("cangjingge_qualityup")
                GameScene:shiftLayerById(263)
            end, CCControlEventTouchUpInside)
            self.rootItems["t"..i.."_upquality_button"]:setSwallowsTouch(true)
            self.rootItems["t"..i.."_upquality_button"]:setTouchPriority(self.touchPriority)
            --

            local config_building = gamedata.config.home_building[tostring(data.buildtype)][tostring(i)] or {}
            ui.setLabelString(self.rootItems["t"..i.."_building_name"],gameConfig.strings:string_common("cangjinggequality",i),i == 5 and 213 or i*2+3)
            setSpriteFrameByName(self.rootItems["t"..i.."_building_sprite"], "c_b_jianzhu"..data.buildtype.."_"..i)
            local qstr = config_building.extra_attr
            local extnum = config_building.reward_up or 0
            self.rootItems["t"..i.."_quality_attr0"]:setAnchorPoint(ccp(1, 0.5))
            if extnum > 0 then
                self.rootItems["t"..i.."_quality_attr0"]:setString(gameConfig.strings:string_common("cangjingge",(data.buildtype == 1) and 30 or 29)..":")
                self.rootItems["t"..i.."_quality_attrnum0"]:setString(extnum)
            elseif (data.buildtype == 2) and (i > 1) then
                self.rootItems["t"..i.."_quality_attr0"]:setAnchorPoint(ccp(0.5, 0.5))
                self.rootItems["t"..i.."_quality_attr0"]:setString(gameConfig.strings:string_common("cangjingge",48))
                self.rootItems["t"..i.."_quality_attrnum0"]:setString("")
            else
                self.rootItems["t"..i.."_quality_attr0"]:setString("")
                self.rootItems["t"..i.."_quality_attrnum0"]:setString("")
            end

            if qstr and qstr ~= "" then
                ui.setLabelString(self.rootItems["t"..i.."_qualityattrlab"],gameConfig.strings:string_common("cangjingge",1),i == 5 and 213 or i*2+3)
                local attrs = ui.getSTRandNUMs(qstr)
                for j = 1,4 do
                    if self.rootItems["t"..i.."_quality_attr"..j] and self.rootItems["t"..i.."_quality_attrnum"..j] then
                        if attrs[j] then
                            self.rootItems["t"..i.."_quality_attr"..j]:setString(gameConfig.strings.attr_type[attrs[j].str]..":")
                            self.rootItems["t"..i.."_quality_attrnum"..j]:setString((attrs[j].num < 1) and ((attrs[j].num*100).."%") or attrs[j].num)
                        else
                            self.rootItems["t"..i.."_quality_attr"..j]:setString("")
                            self.rootItems["t"..i.."_quality_attrnum"..j]:setString("")
                        end
                    end
                end
            else
                ui.setLabelString(self.rootItems["t"..i.."_qualityattrlab"],gameConfig.strings:string_common("cangjingge",((extnum > 0) or (i > 1)) and 1 or 2),i == 5 and 213 or i*2+3)
                self.rootItems["t"..i.."_quality_attr1"]:setString("")
                self.rootItems["t"..i.."_quality_attr2"]:setString("")
                self.rootItems["t"..i.."_quality_attr3"]:setString("")
                self.rootItems["t"..i.."_quality_attrnum1"]:setString("")
                self.rootItems["t"..i.."_quality_attrnum2"]:setString("")
                self.rootItems["t"..i.."_quality_attrnum3"]:setString("")
            end

            --
            if i < data.buildquality then
                self.rootItems["t"..i.."_upqualitynode"]:setVisible(false)
                self.rootItems["t"..i.."_updesc"]:setVisible(false)
            elseif i == data.buildquality then
                self.rootItems["t"..i.."_upqualitynode"]:setVisible(false)
                self.rootItems["t"..i.."_updesc"]:setVisible(true)
                ui.setLabelString(self.rootItems["t"..i.."_updesc"],gameConfig.strings:string_common("cangjingge",45),3)
            elseif data.buildquality < i-1 then
                self.rootItems["t"..i.."_upqualitynode"]:setVisible(false)
                self.rootItems["t"..i.."_updesc"]:setVisible(true)
                ui.setLabelString(self.rootItems["t"..i.."_updesc"],gameConfig.strings:cangjingge_qualitylimit(config_building.name or "",gameConfig.strings:string_common("cangjinggequality",(i-1)>1 and (i-1) or 1)),11)
            elseif data.buildlevel < config_building.level_limit then
                self.rootItems["t"..i.."_upqualitynode"]:setVisible(false)
                self.rootItems["t"..i.."_updesc"]:setVisible(true)
                ui.setLabelString(self.rootItems["t"..i.."_updesc"],gameConfig.strings:cangjingge_uplimit(config_building.name or "",config_building.level_limit),11)
            else
                self.rootItems["t"..i.."_upqualitynode"]:setVisible(true)
                self.rootItems["t"..i.."_updesc"]:setVisible(false)
            end

        else
            self.rootItems["t"..i.."_node"]:setVisible(false)
        end
    end

end

function cangjingge_qualityup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return cangjingge_qualityup

