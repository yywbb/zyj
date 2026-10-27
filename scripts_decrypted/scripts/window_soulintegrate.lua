--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/5
-- Time: 16:05
-- To change this template use File | Settings | File Templates.
--


local soulintegrate = {
    rootNode = nil,
    rootItems = nil,
    data = {},
    allData = {},
}

function soulintegrate.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("soul2/soulhecheng", nil, true, "soulhecheng")
    self.animationManager = getAnimationManager(self.rootItems)
    self.animationManager:runAnimationsForSequenceNamed("free")

    self.touchPriority = touchPriority
    self:reload(data,callback)
    --
    return self.rootNode
end

function soulintegrate.reload(self,data,callback)
    self.callback = callback
    self.data = data.data or {}
    self.allData = data.allData or {}
    --
    local cid1,cid2 = 0,0
    --
    ui.setLabelString(self.rootItems.desc,nil,18)
    ui.setLabelString(self.rootItems.okLab,nil,18)
    ui.setLabelString(self.rootItems.doLab,nil,18)
    self.rootItems.okNode:setVisible(false)
    self.rootItems.doNode:setVisible(true)
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("soulintegrate")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.okButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("soulintegrate")
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)
    --

    local configdata =  gamedata.config.soul[tostring(self.data.cid)]
    local integrateconfig = gamedata.config.soul_integrate and gamedata.config.soul_integrate[tostring(configdata.relation)] or {}

    if integrateconfig.main_id and integrateconfig.main_id > 0 then
        cid1 = integrateconfig.main_id
        local config = gamedata.config.soul[tostring(integrateconfig.main_id)]
        ui.setNewIcon(self.rootItems,{cid = integrateconfig.main_id})
        ui.setLabelString(self.rootItems.level1,"等级."..integrateconfig.cond,14)
        ui.setLabelString(self.rootItems.name1,config.name, config.quality and 2*config.quality-1 or 1)
        --
        self.rootItems["i_button"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(integrateconfig.main_id,{level = integrateconfig.cond})
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"]:setSwallowsTouch(true)
        self.rootItems["i_button"]:setTouchPriority(self.touchPriority)
    end

    if integrateconfig.assist_id and integrateconfig.assist_id > 0 then
        cid2 = integrateconfig.assist_id
        local config = gamedata.config.soul[tostring(integrateconfig.assist_id)]
        ui.setNewIcon(self.rootItems,{cid = integrateconfig.assist_id},1)
        ui.setLabelString(self.rootItems.level2,"等级."..integrateconfig.cond,14)
        ui.setLabelString(self.rootItems.name2,config.name, config.quality and 2*config.quality-1 or 1)
        --
        self.rootItems["i_button_1"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(integrateconfig.assist_id,{level = integrateconfig.cond})
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button_1"]:setSwallowsTouch(true)
        self.rootItems["i_button_1"]:setTouchPriority(self.touchPriority)
    end

    if integrateconfig.id and integrateconfig.id > 0 then
        local config = gamedata.config.soul[tostring(integrateconfig.id)]
        ui.setNewIcon(self.rootItems,{cid = integrateconfig.id},2)
        ui.setLabelString(self.rootItems.level3,"等级."..integrateconfig.cond,14)
        ui.setLabelString(self.rootItems.name3,config.name, config.quality and 2*config.quality-1 or 1)
        --
        ui.setLabelString(self.rootItems.levelLab,gameConfig.strings:string_common("godStoneInfo",3),21)
        ui.setLabelString(self.rootItems.level,integrateconfig.cond,14)

        if config.attr1 and config.attr1 ~= "" then
            ui.setLabelString(self.rootItems.attr1,gameConfig.strings.attr_type[config.attr1].."：",21)
            ui.setLabelString(self.rootItems.num1,(config["attr1_grow"..integrateconfig.cond] or 0)*(config.method1 == "value" and 1 or 100)..(config.method1 == "value" and "" or "%"),14)
        else
            ui.setLabelString(self.rootItems.attr1,"",21)
            ui.setLabelString(self.rootItems.num1,"",14)
        end

        if config.attr2 and config.attr2 ~= "" then
            ui.setLabelString(self.rootItems.attr2,gameConfig.strings.attr_type[config.attr2].."：",21)
            ui.setLabelString(self.rootItems.num2,(config["attr2_grow"..integrateconfig.cond] or 0)*(config.method2 == "value" and 1 or 100)..(config.method2 == "value" and "" or "%"),14)
        else
            ui.setLabelString(self.rootItems.attr2,"",21)
            ui.setLabelString(self.rootItems.num2,"",14)
        end

        --
        self.rootItems["i_button_2"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(integrateconfig.id,{level = integrateconfig.cond})
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button_2"]:setSwallowsTouch(true)
        self.rootItems["i_button_2"]:setTouchPriority(self.touchPriority)

    end
    --

    if data.opt and data.opt == 2 then
        --
        self.rootItems["i_k_quality"]:setColor(ccc3(255,255,255))
        self.rootItems["i_quality"]:setColor(ccc3(255,255,255))
        self.rootItems["i_icon"]:setColor(ccc3(255,255,255))
        self.rootItems.nohas1:setVisible(false)
        --
        self.rootItems["i_k_quality_1"]:setColor(ccc3(255,255,255))
        self.rootItems["i_quality_1"]:setColor(ccc3(255,255,255))
        self.rootItems["i_icon_1"]:setColor(ccc3(255,255,255))
        self.rootItems.nohas2:setVisible(false)
        --
        self.rootItems["i_k_quality_2"]:setColor(ccc3(255,255,255))
        self.rootItems["i_quality_2"]:setColor(ccc3(255,255,255))
        self.rootItems["i_icon_2"]:setColor(ccc3(255,255,255))
        self.rootItems.nohas3:setVisible(false)
        --
        self.rootItems.okNode:setVisible(false)
        self.rootItems.doNode:setVisible(false)
    else    
        local iid1,iid2 = 0,0
        for k,v in pairs(self.allData) do
            if v.generalcid and (v.generalcid == self.data.generalcid) then
                if (cid1 == v.cid) and (v.level >= integrateconfig.cond) then
                    iid1 = v.iid
                elseif (cid2 == v.cid) and (v.level >= integrateconfig.cond) then
                    iid2 = v.iid
                end
            end
        end
        --
        if iid1 > 0 then
            self.rootItems["i_k_quality"]:setColor(ccc3(255,255,255))
            self.rootItems["i_quality"]:setColor(ccc3(255,255,255))
            self.rootItems["i_icon"]:setColor(ccc3(255,255,255))
            self.rootItems.nohas1:setVisible(false)
        else
            self.rootItems["i_k_quality"]:setColor(ccc3(100,100,100))
            self.rootItems["i_quality"]:setColor(ccc3(100,100,100))
            self.rootItems["i_icon"]:setColor(ccc3(100,100,100))
            self.rootItems.nohas1:setVisible(true)
        end
        --
        if iid2 > 0 then
            self.rootItems["i_k_quality_1"]:setColor(ccc3(255,255,255))
            self.rootItems["i_quality_1"]:setColor(ccc3(255,255,255))
            self.rootItems["i_icon_1"]:setColor(ccc3(255,255,255))
            self.rootItems.nohas2:setVisible(false)
        else
            self.rootItems["i_k_quality_1"]:setColor(ccc3(100,100,100))
            self.rootItems["i_quality_1"]:setColor(ccc3(100,100,100))
            self.rootItems["i_icon_1"]:setColor(ccc3(100,100,100))
            self.rootItems.nohas2:setVisible(true)
        end
        --
        self.rootItems["i_k_quality_2"]:setColor(ccc3(100,100,100))
        self.rootItems["i_quality_2"]:setColor(ccc3(100,100,100))
        self.rootItems["i_icon_2"]:setColor(ccc3(100,100,100))
        self.rootItems.nohas3:setVisible(true)
        --
        if iid1 > 0 and iid2 > 0 then
            ui.removeGray("CCControlButton",self.rootItems.doButton)
            self.rootItems.doButton:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 2507, iid1 = iid1, iid2 = iid2})
            end, CCControlEventTouchUpInside)
            self.rootItems.doButton:setSwallowsTouch(true)
            self.rootItems.doButton:setTouchPriority(self.touchPriority)
        else
            ui.addGray("CCControlButton",self.rootItems.doButton)
            self.rootItems.doButton:addHandleOfControlEvent(function()
                --runGamePrompt({msg="未满足合成条件"})
                runGamePrompt({msg=gameConfig.strings:string_common("soul",16)})
            end, CCControlEventTouchUpInside)
            self.rootItems.doButton:setSwallowsTouch(true)
            self.rootItems.doButton:setTouchPriority(self.touchPriority)
        end
        --
    end

end

function soulintegrate.compound(self)
    --
    gameTouch:clickprofbytime(2)
    if self.animationManager then
        self.animationManager:setAnimationCompletedCallback(function()
            --
            self.rootItems["i_k_quality"]:setColor(ccc3(100,100,100))
            self.rootItems["i_quality"]:setColor(ccc3(100,100,100))
            self.rootItems["i_icon"]:setColor(ccc3(100,100,100))
            self.rootItems.nohas1:setVisible(true)
            --
            self.rootItems["i_k_quality_1"]:setColor(ccc3(100,100,100))
            self.rootItems["i_quality_1"]:setColor(ccc3(100,100,100))
            self.rootItems["i_icon_1"]:setColor(ccc3(100,100,100))
            self.rootItems.nohas2:setVisible(true)
            --
            self.rootItems["i_k_quality_2"]:setColor(ccc3(255,255,255))
            self.rootItems["i_quality_2"]:setColor(ccc3(255,255,255))
            self.rootItems["i_icon_2"]:setColor(ccc3(255,255,255))
            self.rootItems.nohas3:setVisible(false)
            --
            self.rootItems.okNode:setVisible(true)
            self.rootItems.doNode:setVisible(false)
        end)
        self.animationManager:runAnimationsForSequenceNamed("play")
    end

end


function soulintegrate.close(self)

    self.data = {}
    self.allData = {}

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end



return soulintegrate �*  