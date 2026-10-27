--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/2/4
-- Time: 14:31
-- To change this template use File | Settings | File Templates.
--

local servicewarAfter = {


    resource = nil,

    rootNode = nil,
    rootItems = nil,

    buttontouch = -103,

    worldwarchampion = {},

    worldwarstatus = {},

}

function servicewarAfter.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_after", nil, true, "kuafuzhan_after")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY(((GameScene.topposY-1620)/2)+800)

    if self.rootItems.closeButton then
        self.rootItems.closeButton:setTouchPriority(-103)
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            GameScene:shiftLayer(GameScene.priorLayer,"up")
        end, CCControlEventTouchUpInside)
    end

    --
    self.rootItems.pastButton:setTouchPriority(self.buttontouch)
    self.rootItems.pastButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 历届冠军
        gameWindows:openWindow("servicewarchampionlist",{index = "champion"})
    end, CCControlEventTouchUpInside)
    --

    --
    if self.rootItems.ruleButton then
        self.rootItems.ruleButton:setTouchPriority(self.buttontouch)
        self.rootItems.ruleButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            --todo 规则
            gameWindows:openWindow("servicewarrule",{opt = 3})
        end, CCControlEventTouchUpInside)
    end
    --

    ui.setLabelString(self.rootItems.fixlab1,gameConfig.strings:string_common("fixedString","servicewar",25),19)
    ui.setLabelString(self.rootItems.fixlab2,gameConfig.strings:string_common("fixedString","servicewar",26),21)

    --
    UIRequest({type = 4717})

end

function servicewarAfter.ReloadData(self,data)

    if data then
        self.worldwarchampion = data.worldwarchampion or {}
        self.worldwarstatus = data.worldwarstatus or {}
    end

    self.rootItems.title:setString( gameConfig.strings:servicewar_title_num(self.worldwarchampion.number or 0) )

    --
    for i = 1,5 do
        if self.rootItems["champion"..i] then
            self.rootItems["champion"..i]:setVisible(true)
        end    
        self.rootItems["p_general"..(i>1 and ("_"..(i-1)) or "")]:removeAllChildrenWithCleanup(true)
        if data.worldwarchampion.champion and data.worldwarchampion.champion[tostring(i)] then
            local champion = data.worldwarchampion.champion[tostring(i)]
            ui.setLabelString(self.rootItems["p_num"..(i>1 and ("_"..(i-1)) or "")],champion.worship_num,14)
            ui.setLabelString(self.rootItems["p_name"..(i>1 and ("_"..(i-1)) or "")],champion.name,14)
            ui.setLabelString(self.rootItems["p_server_name"..(i>1 and ("_"..(i-1)) or "")],champion.server_name,13)
            ui.setLabelString(self.rootItems["p_list_name"..(i>1 and ("_"..(i-1)) or "")],gameConfig.strings:string_common("fixedString","servicewarlist",champion.group),(champion.group == 3) and 8 or (champion.group*6))
            if self.rootItems["p_list_name_bg"..(i>1 and ("_"..(i-1)) or "")] then
                self.rootItems["p_list_name_bg"..(i>1 and ("_"..(i-1)) or "")]:setString(gameConfig.strings:string_common("fixedString","servicewarlist",champion.group))
            end
            for j = 1,5 do
                if j == champion.group then
                    self.rootItems["p_list_icon"..j..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
                    if self.rootItems["p_list_bg"..j..(i>1 and ("_"..(i-1)) or "")] then
                        self.rootItems["p_list_bg"..j..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
                    end
                else
                    self.rootItems["p_list_icon"..j..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
                    if self.rootItems["p_list_bg"..j..(i>1 and ("_"..(i-1)) or "")] then
                        self.rootItems["p_list_bg"..j..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
                    end
                end
            end
            --
            ui.setLabelString(self.rootItems["p_button_lab"..(i>1 and ("_"..(i-1)) or "")],gameConfig.strings:string_common("fixedString","servicewar",27),21)
            --
            if self.rootItems["p_slots"..(i>1 and ("_"..(i-1)) or "")] then
                self.rootItems["p_slots"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.buttontouch)
                self.rootItems["p_slots"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    if champion.server_id and champion.server_id > 0 then
                        GameScene:addtempLayers("other_slotinfo",{othertype = "champion", rid = champion.group, name = champion.name, level = champion.level})
                    end
                end, CCControlEventTouchUpInside)
            end
            --
            if data.worldwarchampion.worship and data.worldwarchampion.worship == 0 then
                ui.removeGray("CCControlButton",self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")])
                self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.buttontouch)
                self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 4718,group = champion.group})
                end, CCControlEventTouchUpInside)
            else
                if data.worldwarchampion.worship == champion.group then
                    ui.setLabelString(self.rootItems["p_button_lab"..(i>1 and ("_"..(i-1)) or "")],gameConfig.strings:string_common("fixedString","servicewar",28),21)
                end
                ui.addGray("CCControlButton",self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")])
                self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.buttontouch)
                self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",25)})
                end, CCControlEventTouchUpInside)
            end
            --
            if self.rootItems["p_serverthis"..(i>1 and ("_"..(i-1)) or "")] then
                if self.worldwarstatus.server_id and self.worldwarstatus.server_id == champion.server_id then
                    self.rootItems["p_serverthis"..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
                else
                    self.rootItems["p_serverthis"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
                end
            end
            --
            local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(champion.profile).animationid)].name
            local wing = {level = champion.wing_l or 0, color = champion.wing_c or 0 }
            local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
            --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            Gneral1:setAnimation("stand",true,0)
            Gneral1:setScale(1.2)
            Gneral1:setPosition(0,0)
            self.rootItems["p_general"..(i>1 and ("_"..(i-1)) or "")]:addChild(Gneral1.root or Gneral1)
        else
            if self.rootItems["champion"..i] then
                self.rootItems["champion"..i]:setVisible(false)
            end    
            ui.setLabelString(self.rootItems["p_num"..(i>1 and ("_"..(i-1)) or "")],0,14)
            ui.setLabelString(self.rootItems["p_name"..(i>1 and ("_"..(i-1)) or "")],"",14)
            ui.setLabelString(self.rootItems["p_server_name"..(i>1 and ("_"..(i-1)) or "")],"",13)
            ui.setLabelString(self.rootItems["p_list_name"..(i>1 and ("_"..(i-1)) or "")],"",13)
            if self.rootItems["p_list_name_bg"..(i>1 and ("_"..(i-1)) or "")] then
                self.rootItems["p_list_name_bg"..(i>1 and ("_"..(i-1)) or "")]:setString("")
            end
            for j = 1,5 do
                self.rootItems["p_list_icon"..j..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
                if self.rootItems["p_list_bg"..j..(i>1 and ("_"..(i-1)) or "")] then
                    self.rootItems["p_list_bg"..j..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
                end
            end
            --
            ui.setLabelString(self.rootItems["p_button_lab"..(i>1 and ("_"..(i-1)) or "")],gameConfig.strings:string_common("fixedString","servicewar",27),21)
            --
            self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.buttontouch)
            self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)

            end, CCControlEventTouchUpInside)
            --
            if self.rootItems["p_slots"..(i>1 and ("_"..(i-1)) or "")] then
                self.rootItems["p_slots"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.buttontouch)
                self.rootItems["p_slots"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)

                end, CCControlEventTouchUpInside)
            end
            --
            ui.addGray("CCControlButton",self.rootItems["p_button"..(i>1 and ("_"..(i-1)) or "")])
            --
            if self.rootItems["p_serverthis"..(i>1 and ("_"..(i-1)) or "")] then
                self.rootItems["p_serverthis"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
            end
        end
    end


end

function servicewarAfter.clear(self)
    self.worldwarstatus = {}
    self.worldwarchampion = {}
    self.rootItems = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return servicewarAfter