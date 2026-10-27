--

--

local champion = {
    buttontouch = -103,
    rootNode = nil,
    rootItems = nil,

    championconfig = {},
    data = {},
    olddata = nil,
    buttonenable = true,
    isscrolltouched = false,
    dekaron_times = 0,
    isauto = false,
}

function champion.clear(self)

    gameTouch:UnrigistFunc("begin","champion")
    gameTouch:UnrigistFunc("end","champion")

    self.buttonenable = true
    self.data = {}
    self.olddata = nil
    self.dekaron_times = 0
    self.mapNode:removeAllChildrenWithCleanup(true)
    self.mapNode:removeFromParentAndCleanup(true)
    self.mapNode = nil
    self.mapItems = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function champion.init(self,parent,toppos,data)
    self.rootNode,self.rootItems = CCBReaderLoad("chamipon/chamipon", nil, true, "champion")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
    --
    local c_config = gamedata.config.champion_produce or {}
    self.championconfig = c_config[tostring(GameScene.roleinfo.level)] or {}
    --
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.buttontouch)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-360-120))
    self.rootItems.container:setContentSize(CCSize(1080,2100))
    self.mapNode, self.mapItems = CCBReaderLoad("chamipon/chamipon_map", nil, true, "map")
    self.mapNode:setPosition(0,0)
    self.rootItems.container:addChild(self.mapNode)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    --
    self.rootItems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,toppos-360-120))
    --
    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end
    gameTouch:rigistFunc("begin","champion",touchbegin)
    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.rootItems.scrollnode_touch and ui.isTouched(self.rootItems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","champion",touchend)
    --
    -- if not self.isscrolltouched then return end
    --
    ui.setLabelString(self.rootItems.lab1,nil,14)
    ui.setLabelString(self.rootItems.lab2,nil,14)
    ui.setLabelString(self.rootItems.resetLab1,nil,13)
    ui.setLabelString(self.rootItems.resetLab,nil,19)
    ui.setLabelString(self.rootItems.nextLab,nil,19)
    ui.setLabelString(self.rootItems.yijianwancLab,nil,19)
    --
    self.rootItems.button_rule:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("championRule",nil,nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.button_rule:setSwallowsTouch(true)
    self.rootItems.button_rule:setTouchPriority(self.buttontouch)

    self.rootItems.button_shop:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        GameScene:shiftLayerById(184)
    end, CCControlEventTouchUpInside)
    self.rootItems.button_shop:setSwallowsTouch(true)
    self.rootItems.button_shop:setTouchPriority(self.buttontouch)

    --
    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.buttontouch)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)


    self.rootItems.nextButton:addHandleOfControlEvent(function()
        if self.data.status.boxstatus and self.data.status.boxstatus == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("champion","boxfree")})
        else
            gameTouch:clickprofbytime(1)
            UIRequest({type = 2702})
            self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.nextButton:setSwallowsTouch(true)
    self.rootItems.nextButton:setTouchPriority(self.buttontouch-1)

    --
    self.mapItems.box_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(0.5)
        --
        if self.data.status.boxstatus and self.data.status.boxstatus == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("champion","boxcannot")})
        elseif self.data.status.boxstatus and self.data.status.boxstatus == 3 then
            runGamePrompt({msg = gameConfig.strings:string_common("champion","boxall")})
        else
            gameWindows:openWindow("championbox",self.data,nil)
        end

    end, CCControlEventTouchUpInside)
    self.mapItems.box_button:setSwallowsTouch(true)
    self.mapItems.box_button:setTouchPriority(self.buttontouch)
    --
    --
    if self.rootItems.autobutton then
        self.rootItems.autosprite:setVisible(self.isauto)
        self.rootItems.autobutton:setSwallowsTouch(true)
        self.rootItems.autobutton:setTouchPriority(self.buttontouch-1)
        self.rootItems.autobutton:addHandleOfControlEvent(function()
            self.isauto = not self.isauto
            self.rootItems.autosprite:setVisible(self.isauto)
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.yijianwanchengButton:addHandleOfControlEvent(function()
        local path = CCUserDefault:sharedUserDefault():getIntegerForKey("ChampionPath"..GameScene.roleinfo.id)
        local times = CCUserDefault:sharedUserDefault():getIntegerForKey("ChampionTimes"..GameScene.roleinfo.id)

        if path and path ~= 0 then
            local price = 0
            for i=1, times do
                price = price + gamedata.config.buycount_price[tostring(i)].championbox_cost
            end
            
            if self.dekaron_times <= 0 then
                runGamePrompt({msg = gameConfig.strings:string_common("champion","res4")})
                return
            end

            if GameScene.roleinfo.level < tonumber(gamedata.config.global_kv.champion_level.value) and GameScene.roleinfo.vip < tonumber(gamedata.config.global_kv.champion_vip.value) then
                local msg = string.format(gameConfig.strings:string_common("champion","minLevel"), gamedata.config.global_kv.champion_vip.value, gamedata.config.global_kv.champion_level.value)
                runGamePrompt({msg = msg})
                return    
            end

            if price > GameScene.roleinfo.gold then
                runGamePrompt({msg = gameConfig.strings:string_common("champion","goldless")})
                return 
            end
            UIRequest({type = 2705, path = path, times = times, res = string.format("冠军试炼开%d宝箱", times), price = price})
        else
            gameWindows:openWindow("championSetting", 1, nil)
        end

    end, CCControlEventTouchUpInside)

    self.rootItems.yijianwanchengButton:setSwallowsTouch(true)
    self.rootItems.yijianwanchengButton:setTouchPriority(self.buttontouch - 1)
    
    self.rootItems.settingButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("championSetting", nil, nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.settingButton:setSwallowsTouch(true)
    self.rootItems.settingButton:setTouchPriority(self.buttontouch - 1)

    --
    if data then
        self:reload(data)
    else
        UIRequest({type = 2700})
    end
end

function champion.reload(self,data)
    self.data = data or self.data

    if not self.data.status then return end
    --

    if self.data.status.pass and self.data.status.pass >= 1 and self.data.status.pass <= 2 then
        ui.setLabelString(self.rootItems.pass,gameConfig.strings:getLevelBig(self.data.status.pass),21)
        for i = 1,2 do
            if self.data.status.pass == i then
                self.rootItems["page_s_"..i]:setVisible(true)
            else
                self.rootItems["page_s_"..i]:setVisible(false)
            end
        end
    end

    if self.data.status.dekaron then
        local champion_times = gamedata.config.global_kv.champion_times and tonumber(gamedata.config.global_kv.champion_times.value) or 0
        self.dekaron_times = champion_times - self.data.status.dekaron
        if champion_times - self.data.status.dekaron > 0 then
            ui.setLabelString(self.rootItems.dekaron,(champion_times - self.data.status.dekaron).."/"..champion_times,22)
        else
            ui.setLabelString(self.rootItems.dekaron,"0/"..champion_times,24)
        end
    end

    if self.data.status.reset then
        local reset_times = gamedata.config.vip[tostring(GameScene.vip.vip)] and gamedata.config.vip[tostring(GameScene.vip.vip)].champion_times or 0
        if reset_times - self.data.status.reset > 0 then
            local xgold = 0
            ui.setLabelString(self.rootItems.resetNum,reset_times - self.data.status.reset,21)
            if gamedata.config.buycount_price[tostring(self.data.status.reset+1)] and gamedata.config.buycount_price[tostring(self.data.status.reset+1)].champion_cost and gamedata.config.buycount_price[tostring(self.data.status.reset+1)].champion_cost > 0 then
                self.rootItems.goldnode:setVisible(true)
                ui.setLabelString(self.rootItems.resetgold,gamedata.config.buycount_price[tostring(self.data.status.reset+1)].champion_cost,21)
                xgold = gamedata.config.buycount_price[tostring(self.data.status.reset+1)].champion_cost+0
            else
                self.rootItems.goldnode:setVisible(false)
            end
            ui.removeGray("CCControlButton",self.rootItems.resetButton)
            --
            self.rootItems.resetButton:addHandleOfControlEvent(function()
                if self.data.status.boxstatus and self.data.status.boxstatus == 1 then
                    runGamePrompt({msg = gameConfig.strings:string_common("champion","boxfree")})
                else
                    local cb = function()
                        gameTouch:clickprofbytime(1)
                        UIRequest({type = 2703, xgold = xgold or 0,})
                        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
                    end
                    gameWindows:openWindow("guildmsg",{msg = gameConfig.strings:string_common("champion","resetmsg")},cb)
                end
            end, CCControlEventTouchUpInside)
            self.rootItems.resetButton:setSwallowsTouch(true)
            self.rootItems.resetButton:setTouchPriority(self.buttontouch-1)
        else
            ui.setLabelString(self.rootItems.resetNum,"0",21)
            self.rootItems.goldnode:setVisible(false)
            ui.addGray("CCControlButton",self.rootItems.resetButton)
            --
            self.rootItems.resetButton:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                runGamePrompt({msg = gameConfig.strings:string_common("popups","resetCountLess")})
            end, CCControlEventTouchUpInside)
            self.rootItems.resetButton:setSwallowsTouch(true)
            self.rootItems.resetButton:setTouchPriority(self.buttontouch)
        end
    end

    --
    if self.data.status.pass and self.data.status.pass <= 1 and self.data.status.boxstatus and self.data.status.boxstatus > 0 then
        self.rootItems.resetNode:setVisible(false)
        self.rootItems.nextNode:setVisible(true)
    else
        self.rootItems.resetNode:setVisible(true)
        self.rootItems.nextNode:setVisible(false)
    end
    --
    if self.data.status.boxstatus and (self.data.status.boxstatus == 1 or self.data.status.boxstatus == 2) then
        setSpriteFrameByName(self.mapItems.box_sprite,"box4_1")
    elseif self.data.status.boxstatus and self.data.status.boxstatus == 3 then
        setSpriteFrameByName(self.mapItems.box_sprite,"box4_2")
    else
        setSpriteFrameByName(self.mapItems.box_sprite,"box4_0")
    end
    --

    if self.data.points then
        for k,v in pairs(self.data.points) do
            self:setPoint(v,tonumber(k))
        end
    end
    --
end

function champion.setPoint(self, data, index)
    if not data or not index then return end
    if index < 1 or index > 9 then return end
    if not self.mapItems then return end
    --
    local key_Ex = ""
    if index == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(index-1)
    end
    --
    if not self.mapItems["name"..key_Ex] then return end
    --
    local integral = 0

    if self.championconfig[tostring(self.data.status.pass or 1)] and self.championconfig[tostring(self.data.status.pass or 1)]["stronghold"..index] then
        local idnums = ui.getIDandNUMs(self.championconfig[tostring(self.data.status.pass or 1)]["stronghold"..index])
        printT(idnums)
        for k,v in pairs(idnums) do
            if v.cid == 1009 then
                integral = v.num
            end
        end
    end
    ui.setLabelString(self.mapItems["integral"..key_Ex],integral,21)
    ui.setLabelString(self.mapItems["integralLab"..key_Ex],nil,13)
    ui.setLabelString(self.mapItems["powerLab"..key_Ex],nil,13)
    ui.setLabelString(self.mapItems["name"..key_Ex],data.name or "",13)
    ui.setLabelString(self.mapItems["power"..key_Ex],data.power or "",21)
    --
    if data.hp and data.hp >= 0 and data.hp <= 100 then
        ui.setSpriteTextureRect2(self.mapItems["hpSprite"..key_Ex],0,0,125 * data.hp / 100, 14)
        if self.mapItems["hpPos"..key_Ex] then
            ui.setLabelString(self.mapItems["hpPos"..key_Ex],data.hp.."%",13)
        end
    else
        ui.setSpriteTextureRect2(self.mapItems["hpSprite"..key_Ex],0,0,125,14)
        if self.mapItems["hpPos"..key_Ex] then
            ui.setLabelString(self.mapItems["hpPos"..key_Ex],"100%",13)
        end
    end
    --
    if data.status and data.status == 1 and data.hp and data.hp >= 0 and data.hp < 100 then
        self.mapItems["hpNode"..key_Ex]:setVisible(true)
    else
        self.mapItems["hpNode"..key_Ex]:setVisible(false)
    end
    --
    if data.status and data.status == 2 then
        self.mapItems["win"..key_Ex]:setVisible(true)
        self.mapItems["generalNode"..key_Ex]:setVisible(false)
    else
        self.mapItems["win"..key_Ex]:setVisible(false)
        self.mapItems["generalNode"..key_Ex]:setVisible(true)
    end
    --
    if data.status and data.status == 1 then
        self.mapItems["hasNode"..key_Ex]:setVisible(true)
    else
        self.mapItems["hasNode"..key_Ex]:setVisible(false)
    end
    --
    if data.profile and data.profile > 0 then
        self.mapItems["generalNode"..key_Ex]:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(data.profile).animationid)].name
        local wing = {level = data.w_l, color = data.w_c }
        local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
        --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(0.9)
        Gneral1:setPosition(0,0)
        self.mapItems["generalNode"..key_Ex]:addChild(Gneral1.root or Gneral1)
        --
        if data.status and data.status == 1 then
            ui.removeGray("CCNode",Gneral1)
        else
            ui.addGray("CCNode",Gneral1)
        end
    end
    --
    self.mapItems["button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if data.status and data.status == 1 then
            if self.dekaron_times and self.dekaron_times > 0 then
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 2701, id = index, isauto = self.isauto})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("popups","insufficientNumberOfChallenges")})
            end
        elseif data.status and data.status == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("champion","pointcannot")})
        end
    end, CCControlEventTouchUpInside)
    self.mapItems["button"..key_Ex]:setTouchPriority(self.buttontouch)
    --

end


function champion.battlechangeData(self)

    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
        UIRequest({type = 2700})
    end)))

end


function champion.UIUpdateData(self, isreset)
    if isreset then
        self.isreset = true
        --gameWindows:closeAllWindowDirect()
        UIRequest({type = 2700})
    end
end

return champion