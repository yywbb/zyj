--
-- Author: songyibo
-- Date: 2019-03-18 14:58:21
--
local feisheng = {
    touchPriority  = -101
}

function feisheng.init(self,parent,toppos,param)

    printT(GameScene.protagonist,"feisheng")
    
    self.rootNode,self.rootItems = CCBReaderLoad("devil/feisheng", nil, true, "feisheng")
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.data = table.copy(GameScene.protagonist)
    self:showPage()
    self:setPage_feisheng()
    self:loadGeneral()
    self:initFixedString()
end


function feisheng.refreshFunc(self)
    print("refreshFunc")
    
    local hasdata = false
    local haschange = false
    if self.data.level2 and self.data.level2 > 0 then
        hasdata = true
        
        if GameScene.protagonist.train ~= self.data.train then
            haschange = true
        end
        if GameScene.protagonist.general and GameScene.protagonist.general.cid and ( GameScene.protagonist.general.cid ~= self.data.general.cid ) then
            haschange = true
        end
        if GameScene.protagonist.w_l ~= self.data.w_l or GameScene.protagonist.w_c ~= self.data.w_c then
            haschange = true
        end
        
        if GameScene.protagonist.general and GameScene.protagonist.general.level2 and ( GameScene.protagonist.general.level2 ~= self.data.general.level2 ) then
            haschange = true
        end
    end

    self.data = table.copy(GameScene.protagonist)
    if self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, gamedata.config.protagonist_awaken[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, gamedata.config.protagonist_awaken[tostring(self.data.general.skilllevel)].stage,18)    
    end

    local _str = CCUserDefault:sharedUserDefault():getStringForKey("useWingEffect"..GameScene.roleinfo.id)
    print("jkp-_str feisheng == ",_str)
    if _str == "0" or _str == "1" then
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data.general.cid)].animationid)].name
        if string.find(generalName,"zhujue") or string.find(generalName,"shizhuang") then
            hasdata = true
            haschange = true
        end
    end
    
    if (not hasdata) or haschange then
        self.data = table.copy(GameScene.protagonist)
        self:loadGeneral()
    end
end

function feisheng.showPage(self)
    -- self.rootItems.button_back:setSwallowsTouch(true)
    -- self.rootItems.button_back:setTouchPriority(self.touchPriority - 1)
    -- self.rootItems.button_back:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("slotsInfo","up")
    -- end, CCControlEventTouchUpInside)
end

function feisheng.initFixedString(self)
    ui.setLabelString(self.rootItems.feishengtext,gameConfig.strings:string_common("general",48),19)
end

function feisheng.loadGeneral(self)
    if not self.feishengItems then
        return
    end
    self.feishengItems.feishenggeneral:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data.general.cid)].animationid)].name
    local wing = {level = self.data.w_l, color = self.data.w_c}
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.6)
    Gneral1:setPosition(0,0)
    self.feishengItems.feishenggeneral:addChild(Gneral1.root or Gneral1)


    if self.rootItems.name then
        self.rootItems.name:setString(ui.leadName(GameScene.protagonist.level2))
        if gamedata.config.general[tostring(self.data.general.cid)].quality and gamedata.config.general[tostring(self.data.general.cid)].quality >= 7 then
            ui.setLabelString(self.rootItems.name,nil, 213)
        else    
            ui.setLabelString(self.rootItems.name,nil, gamedata.config.general[tostring(self.data.general.cid)].quality~=0 and 2*gamedata.config.general[tostring(self.data.general.cid)].quality-1 or 1)
        end
    end

    if self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, gamedata.config.protagonist_awaken[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, gamedata.config.protagonist_awaken[tostring(self.data.general.skilllevel)].stage,18)    
    end
end

function feisheng.setPage_feisheng(self)

    if not self.data.general then
        return
    end


    self:setFeishengEffectShow()

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local level = self.data.general.level8
    --角色是否能飞升
    local curFeishengConfig = gamedata.config.passive_soaring[tostring(level)]
    local nextFeishengConfig = gamedata.config.passive_soaring[tostring(level + 1)]
    
    --飞升最大等级
    if not nextFeishengConfig then
        self.rootItems.feishengattnode:setPositionX(20)
        self.rootItems.feishengnextattnode:setVisible(false)
        self.rootItems.feisheng_maxTitle:setVisible(true)
        self.rootItems.feishengconsumenode:setVisible(false)

        self.rootItems.feisheng_level:setString(curFeishengConfig.name)
        self.rootItems.feisheng_att1:setString(curFeishengConfig["xianadk"])
        self.rootItems.feisheng_att2:setString(curFeishengConfig["xiandef"])
        self.rootItems.feisheng_att3:setString(curFeishengConfig["xianhp"])
        self.rootItems.feisheng_att4:setString(curFeishengConfig["speed"])

    else
        self.rootItems.feishengattnode:setPositionX(-230)
        self.rootItems.feishengnextattnode:setVisible(true)
        self.rootItems.feisheng_maxTitle:setVisible(false)
        self.rootItems.feishengconsumenode:setVisible(true)

        self.rootItems.feisheng_level:setString(curFeishengConfig.name)
        self.rootItems.feisheng_att1:setString(curFeishengConfig["xianadk"])
        self.rootItems.feisheng_att2:setString(curFeishengConfig["xiandef"])
        self.rootItems.feisheng_att3:setString(curFeishengConfig["xianhp"])
        self.rootItems.feisheng_att4:setString(curFeishengConfig["speed"])
        self.rootItems.feisheng_next_level:setString(nextFeishengConfig.name)
        self.rootItems.feisheng_next_att1:setString(nextFeishengConfig["xianadk"])
        self.rootItems.feisheng_next_att2:setString(nextFeishengConfig["xiandef"])
        self.rootItems.feisheng_next_att3:setString(nextFeishengConfig["xianhp"])
        self.rootItems.feisheng_next_att4:setString(nextFeishengConfig["speed"])

        --突破要求
        if nextFeishengConfig.breach and nextFeishengConfig.breach > 0 then

            self.rootItems.feisheng_condition:setString("进阶等级："..nextFeishengConfig.breach.."级")
            
            -- if nextFeishengConfig.breach >= 21 and nextFeishengConfig.breach <= 23 then
            --     self.rootItems.feisheng_condition:setString("进阶等级：红+"..(nextFeishengConfig.breach - 20))
            -- elseif nextFeishengConfig.breach >= 24 then
            --     self.rootItems.feisheng_condition:setString("进阶等级：彩金+"..(nextFeishengConfig.breach - 23))
            -- else
            --     self.rootItems.feisheng_condition:setString("进阶等级："..nextFeishengConfig.breach.."级")
            -- end
            --判断突破等级
            if self.data.general.level2 < nextFeishengConfig.breach then
                self.rootItems.feisheng_condition:setColor(ccc3(255, 0, 0))
            else
                self.rootItems.feisheng_condition:setColor(ccc3(0, 255, 0))
            end
        else
            self.rootItems.feisheng_condition:setString("")
        end
        
        --无进修要求
        self.rootItems.feisheng_condition2:setString("")

        --消耗
        local cids = {}
        local consume = ui.getIDandNUMs(nextFeishengConfig["consume"])
        for i,v in ipairs(consume) do
            table.insert(cids,v.cid)
        end
        UIRequest({type = 12001, order = 32004, cids = cids})

        for i=1,4 do
            self.rootItems["feishengMaterial"..i]:setVisible(false)
        end
    end



    local nextSpeedConfig = nil
    for i=level + 1,table.getTableLength(gamedata.config.passive_soaring) do
        local config = gamedata.config.passive_soaring[tostring(i)]
        if config and config.speed > gamedata.config.passive_soaring[tostring(level)].speed then
            nextSpeedConfig = config
            break
        end
    end
    if nextSpeedConfig then
        self.rootItems.feishengDetailText:setVisible(true)
        ui.setLabelString(self.rootItems.feishengDetailText,nextSpeedConfig.name.."：速度+"..nextSpeedConfig.speed,48)
    else
        self.rootItems.feishengDetailText:setVisible(false)
    end

end

function feisheng.setFeiShengConsume(self,t)

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local level = self.data.general.level8
    local nextFeishengConfig = gamedata.config.passive_soaring[tostring(level + 1)]

    local goldNum = 0
    local consume = ui.getIDandNUMs(nextFeishengConfig["consume"])
    local showConsume = {}
    for i,v in ipairs(consume) do
        if v.cid ~= 1000 then
            table.insert(showConsume,v)
        else
            goldNum = v.num
        end
    end

    self.rootItems.feisheng_coin:setString(goldNum)
    if GameScene.roleinfo.coin >= goldNum then
        self.rootItems.feisheng_coin:setColor((ccc3(255,255,255)))
    else
        self.rootItems.feisheng_coin:setColor((ccc3(255,8,8)))
    end

    for i=1,4 do
        if showConsume[i] then
            self.rootItems["feishengMaterial"..i]:setVisible(true)
            

            local havePropNum = t[tostring(showConsume[i].cid)] or 0
            local needPropNum = showConsume[i].num or 0

            local key_Ex
            if (i-1 == 0) then
                key_Ex = ""
            else
                key_Ex = "_"..(i-1)
            end
            ui.setNewIcon(self.rootItems,{cid =showConsume[i].cid},i-1)
             
            ui.setLabelString(self.rootItems["i_num"..key_Ex],havePropNum.."/"..needPropNum,havePropNum >= needPropNum and 13 or 27)

            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority - 1)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(showConsume[i].cid)
            end, CCControlEventTouchUpInside)
        else
            self.rootItems["feishengMaterial"..i]:setVisible(false)
        end
    end

    self.rootItems.feishengbuntton:setSwallowsTouch(true)
    self.rootItems.feishengbuntton:setTouchPriority(self.touchPriority - 1)
    self.rootItems.feishengbuntton:addHandleOfControlEvent(function()
        
        printT(self.data.general,"feisheng")
        --判断突破等级
        if self.data.general.level2 < nextFeishengConfig.breach then
            runGamePrompt({msg = gameConfig.strings:string_common("general",54)})
            return
        end
       
        --判断道具
        for i,v in ipairs(consume) do
            if not (t[tostring(v.cid)] and t[tostring(v.cid)] >= v.num) then
                local propconfig = ui.IDconfig(v.cid)
                runGamePrompt({msg = propconfig.name..gameConfig.strings:string_common("general",49)})
                return
            end
        end
        gameTouch:clickprofbytime(2)
        UIRequest({type = 7001,iid = self.data.general.iid,isLead = 1})

    end, CCControlEventTouchUpInside)

end


function feisheng.feiShengCallback(self,t)

    GameScene.protagonist.general = t
    self.data.general = t

    --是否升阶 升阶需要重新添加特效Node
    local isUpStage = false
    local level = t.level8

    if level <= 0 then
        return
    end

    if level >= 5 and level % 5 == 0 then
        isUpStage = true
    end

    local index = level%5 ~= 0 and level%5 or 5
    local effect = self.feishengEffectItems[index]

    local function func()

        local aniName = index == 5 and "5-1" or index.."-"..(index+1)
        local animationManager = getAnimationManager(self.feishengItems)
        animationManager:setAnimationCompletedCallback(function()
            if gamedata.config.passive_soaring[tostring(level + 1)] then
                self.isNoUpStage = true --标识不删除旧莲花
            end
            self:setPage_feisheng()
        end)

        if isUpStage then
            self:feishengUpStage()
        else
            print("aniName",aniName)
            animationManager:runAnimationsForSequenceNamed(aniName)
        end
    end

    local animationManager = getAnimationManager(effect[1].items)
    animationManager:setAnimationCompletedCallback(function()
        func()
    end)
    animationManager:runAnimationsForSequenceNamed("start")

    local animationManager = getAnimationManager(effect[2].items)
    animationManager:runAnimationsForSequenceNamed("start")
end


function feisheng.feishengUpStage(self)
    local nodeNames = {"node5_1","node4_1","node3_1","node2_1","node1_1","node5_2","node4_2","node3_2","node2_2","node1_2"}
    for i=1,10 do
        local ccb,items = CCBReaderLoad("UIEffect/feisheng/feisheng_lianhua_change.ccbi", nil, true, "feisheng_lianhua_change")
        self.feishengItems[nodeNames[i]]:addChild(ccb)

        local animationManager = getAnimationManager(items)
        animationManager:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("play")
    end

    local ccb,items = CCBReaderLoad("UIEffect/feisheng/feisheng_lianhua_change2.ccbi", nil, true, "feisheng_lianhua_change")
    ccb:setScale(2)
    self.feishengItems.feishenggeneral:addChild(ccb,3)

    local animationManager = getAnimationManager(items)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("play")
    
    gameTouch:clickprofbytime(1)
    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
                self:setPage_feisheng()
            end)))
end

function feisheng.setFeishengEffectShow(self)

    -- if self.feishengItems then
    --     return
    -- end
    if self.isNoUpStage then
        self.isNoUpStage = false
        return
    end

    if not self.feishengItems then
        self.rootItems.feisheng_effectNode:removeAllChildrenWithCleanup(true)
        local ccb,items = CCBReaderLoad("general_new/feisheng_zhuan.ccbi", nil, true, "feisheng_zhuan")
        self.rootItems.feisheng_effectNode:addChild(ccb)
        self.feishengItems = items
    else
        --清除所有特效node
        for i=1,5 do
            for j=1,2 do
                self.feishengEffectItems[i][j].ccb:removeFromParentAndCleanup(true)
            end
        end
    end

    local animationManager = getAnimationManager(self.feishengItems)
    --先播放动画
    local aniName = (self.data.general.level8 + 1)%5 ~= 0 and (self.data.general.level8 + 1)%5 or 5
    animationManager:runAnimationsForSequenceNamed(tostring(aniName))

    self.feishengEffectItems = {}

    local isMax = false
    if not gamedata.config.passive_soaring[tostring(self.data.general.level8+1)] then
        isMax = true
    end

    local stage = math.ceil((self.data.general.level8+1)/5)
    if isMax then
        stage = math.ceil((self.data.general.level8)/5)
    else
        stage = math.ceil((self.data.general.level8+1)/5)
    end

    local index = 1
    index = math.max(stage,1)
    --创建莲花特效
    for i=1,5 do
        self.feishengEffectItems[i] = {}
        for j=1,2 do
            local ccb,items = CCBReaderLoad("UIEffect/feisheng/feisheng_lianhua"..index, nil, true, "feisheng_lianhua")
            self.feishengItems["node"..i.."_"..j]:addChild(ccb)
            self.feishengEffectItems[i][j] = {ccb = ccb,items = items}

            local animationManager = getAnimationManager(items)
            local level = (stage - 1)*5 + i
            animationManager:runAnimationsForSequenceNamed(self.data.general.level8 < level and "free" or "play")
        end
    end
end

function feisheng.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.feishengItems = nil

end


return feisheng