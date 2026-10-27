--
-- Author: songyibo
-- Date: 2019-08-31 11:02:54
--

local shangguyiji = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    createdItems = {},
    sid = 1,
    maxsid = 0,
    isContentScroll = false,
    touchX = 0,
    contentoffsetx = 0,
    xnum = 0,
    data = {}
}

function shangguyiji.clear(self)

    for k,v in pairs(self.createdItems) do
        self:removePage(k)
    end
    self.data = {}
    self.createdItems = {}
    self.sid = 1
    self.maxsid = 0
    self.iconListTableView = nil
    self.isContentScroll = false
    self.touchX = 0
    self.contentoffsetx = 0
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    gameTimer:UnrigistTimeFunc("ancientRuinsDialog")
end

function shangguyiji.init(self,parent,toppos,data)
    printT(data,"shangguyiji")
    
    self.toppos = toppos
    self.rootNode,self.rootItems = CCBReaderLoad("shangguyiji/shangguyiji", nil, true, "shangguyiji")
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos - 430))

    self.rootItems.mapScroll = tolua.cast(self.rootItems.scroll, "CCScrollView")
    self.rootItems.mapScroll:setTouchPriority(-101)
    self.rootItems.mapScroll:setTouchEnabled(false)

    if self.toppos < 1720 then
        self.rootItems.mapScroll:setPositionY(250)
    end

    self.rootItems.btnRule:setTouchPriority(-101)
    self.rootItems.btnRule:addHandleOfControlEvent(function()
        gameWindows:openWindow("ancientRuinsRule")
    end, CCControlEventTouchUpInside)

    local function ccTouchBegan(x, y)
        self.touching = true
        self.isContentScroll = false
        self.touchX = x
        self.contentoffsetx = self.rootItems.mapScroll:getContentOffset().x
        return true
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end

        local mapData = self.data.map[tostring(self.sid)]
        if x - self.touchX < -30 then

            print("ccTouchMoved",x - self.touchX,mapData.deadPos["0"],self.sid,self.maxsid,self.touching)
            if not mapData.deadPos["0"] then
                if self.touching then
                    self.touching = false
                    runGamePrompt({msg = "Boss未挑战成功"})
                end
                return
            end
        end

        if self.sid == 1 and x - self.touchX > 0 then
            self.touching = false
            return
        end

        if self.sid == self.maxsid and x - self.touchX < 0 then
            if self.touching then
                self.touching = false
                runGamePrompt({msg = "已达到最底层"})
            end
            return
        end

        if math.abs(x - self.touchX) > 30 then
            local offsetX = self.contentoffsetx + (x - self.touchX)
                    self.rootItems.mapScroll:setContentOffset(ccp(offsetX, self.rootItems.mapScroll:getContentOffset().y))
        end


    end

    local function ccTouchEnded(x, y)
        if not self.touching then
            return
        end

        self.touching = false
        if self.touchX - x > 20 then
            if self.sid+1 <= self.maxsid then
                local mapData = self.data.map[tostring(self.sid)]
                if not mapData.deadPos["0"] then
                    return
                end
                self:reload(self.sid+1)
            else
                self:reload(self.sid)
            end
        elseif self.touchX - x < -20 then
            if self.sid-1 >0 then
                self:reload(self.sid-1)
            else
                self:reload(self.sid)
            end
        else
            --self:reload(self.sid)
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -101, false)
    self.rootItems.touchLayer:setTouchPriority(-101)
    self.rootItems.touchLayer:setTouchEnabled(true)

    
    local luckSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("sta_18.png"))
    self.rootItems.process = CCProgressTimer:create(luckSpr);
    self.rootItems.process:setAnchorPoint(ccp(0.5,0.5))
    self.rootItems.process:setType(kCCProgressTimerTypeBar)
    self.rootItems.process:setMidpoint(ccp(0,0.5))
    self.rootItems.process:setBarChangeRate(ccp(1,0))
    self.rootItems.process:setPosition(ccp(0,0))
    self.rootItems.process:setScaleX(1.092)
    self.rootItems.process:setScaleY(1.5)
    self.rootItems.process:setPercentage(0)
    self.rootItems.processNode:addChild(self.rootItems.process)

    
    self.data = data
    self.sid = 1
    for i=1,5 do
        if self.data.map[tostring(i)] then
            self.sid = i
            if not self.data.map[tostring(i)].deadPos["0"] then
                break
            end
        end
    end

    -- UIRequest({type=7080})
    self:reloadData(data)
    self:startPlayDialog()
end


function shangguyiji.startPlayDialog(self)
    gameTimer:rigistTime("ancientRuinsDialog", 99999)
    gameTimer:rigistTimeFunc("ancientRuinsDialog",function()
        if gameTimer.times["ancientRuinsDialog"]%5 == 0 then
            self:setDialog()
        end
    end)
end

function shangguyiji.setDialog(self)
    
    print("setDialog")

    if not next(self.data) then
        return
    end

    if not self.createdItems[self.sid] then
        return
    end

    self.createdItems[self.sid].item.dialogNode:removeAllChildrenWithCleanup(true)

    local mapData = self.data.map[tostring(self.sid)]
    local mapConfig = gamedata.config.shanggu_stance[tostring(self.sid)][tostring(mapData.mapId)]



    local dialogPos = -1
    local dialogContent = ""

    if self.data["attackNum"..self.sid] >= mapConfig.need_num and not mapData.deadPos["0"] then
        dialogPos = 0
        dialogContent = gameConfig.strings:string_common("ancientRuins","boss_dialog",2)
    else

        local exitMonster = {}

        if not mapData.deadPos["0"] then
            table.insert(exitMonster,0)
        end
        
        for i=1,10 do
            if mapConfig["stance"..i] and mapConfig["stance"..i] > 0 then
                if not mapData.deadPos[tostring(i)] then
                    table.insert(exitMonster,mapConfig["stance"..i])
                end
            else
                break
            end
        end

        if #exitMonster > 0 then
            local index = math.random(1,#exitMonster)
            dialogPos = exitMonster[index]
        end

        if dialogPos == 0 then
            local index = math.random(1,2)
            if index == 1 then
                dialogContent =  string.format(gameConfig.strings:string_common("ancientRuins","boss_dialog",1), mapConfig.need_num - self.data["attackNum"..self.sid])
            else
                dialogContent = gameConfig.strings:string_common("ancientRuins","boss_dialog",2)
            end
        else
            dialogContent = gameConfig.strings.ancientRuins.monster_dialog[math.random(1,#gameConfig.strings.ancientRuins.monster_dialog)]
        end
    end


    --全部战死
    if dialogPos == -1 then
        return
    end

    local _direction = "R"
    if dialogPos == 0 or dialogPos >= 16 then
        _direction = "L"
    end

    local _ccbNode, _ccItems = CCBReaderLoad("shangguyiji/renwuduihua_".._direction..".ccbi", nil, true, "renwuduihua_".._direction)
    self.createdItems[self.sid].item.dialogNode:addChild(_ccbNode)

    if self.createdItems[self.sid].item["pos"..dialogPos] then
        _ccbNode:setPosition(self.createdItems[self.sid].item["pos"..dialogPos]:getPositionX(),self.createdItems[self.sid].item["pos"..dialogPos]:getPositionY() + 100)
    end
    
    _ccItems["dialog".._direction]:setString(dialogContent)
    local _playAnimation = getAnimationManager(_ccItems)

    _playAnimation:runAnimationsForSequenceNamed("open")
    

    self.createdItems[self.sid].item.dialogNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(3), CCCallFunc:create(function()
                local _playAnimation = getAnimationManager(_ccItems)
                if _playAnimation then
                    _playAnimation:runAnimationsForSequenceNamed("close")
                end
            end)))


end

function shangguyiji.reloadData(self, data)
    self.data = data

    if self.data.isopen and self.data.isopen == 0 then
        runGamePrompt({msg = "活动已结束"})
        GameScene:shiftLayer("main","down")
        return
    end


    for k,v in pairs(self.createdItems) do
        self:removePage(k)
    end

    self.maxsid = table.getTableLength(gamedata.config.shanggu_stance)

    self.rootItems.container:removeAllChildrenWithCleanup(true)
    self.createdItems = {}
    self.rootItems.container:setContentSize(CCSize(1080 * self.maxsid,self.toppos))

    if table.getTableLength(gamedata.config.shanggu_stance) == 0 then
        self.maxsid = 1
        local CCB, ccbDoc = CCBReaderLoad("shangguyiji/container.ccbi", nil, true, "container")
        self.rootItems.container:addChild(CCB)
        --self.rootItems.noSprite:setVisible(true)
        self.rootItems.mapScroll:setContentOffset(ccp(0, 0))
    else
        --self.rootItems.noSprite:setVisible(false)
        self:reload(self.sid,true)
    end
    
    self:setChallengeTime()
    self:setBox()

end

function shangguyiji.attackCallback(self,attackInfo,data)

    self.data = data
    self:setChallengeTime()
    self:setBox()

    self:setMap(self.createdItems[attackInfo.mapId].item,attackInfo.mapId)
        
    if attackInfo.result == 1 and attackInfo.pos == 0 and attackInfo.mapId < self.maxsid then
        print("首次通关",attackInfo.mapId)
        local moveto = CCMoveTo:create(0.5, ccp(-1080*(attackInfo.mapId), 0))
            self.rootItems.container:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
                self.sid = attackInfo.mapId + 1
                -- self:loadPages()
            end)))
    end


end

function shangguyiji.awardCallback(self,data)
    self.data = data
    self:setBox()
end

function shangguyiji.setChallengeTime(self)
    self.rootItems.fixed2:setString(gameConfig.strings:string_common("ancientRuins",2))
    self.rootItems.time:setString(tonumber(gamedata.config.global_kv.shanggu_num.value) - self.data.challengeTime)
end

--设置宝箱
function shangguyiji.setBox(self)
    self.rootItems.fixed1:setString(gameConfig.strings:string_common("ancientRuins",1))
    self.rootItems.count:setString(self.data.yinghun)
    for i =1, 6 do
        self:setBoxOne(i)
    end

    local rewardConfig = gamedata.config.shanggu_reward
    local maxPoint = rewardConfig[tostring(table.getTableLength(rewardConfig))].need_num

    local pencent = math.min(self.data.yinghun/maxPoint*100,100)
    local processSpr = CCProgressFromTo:create(0.3,self.rootItems.process:getPercentage(),pencent)
    self.rootItems.process:runAction(processSpr)

end

function shangguyiji.setBoxOne(self,i)

    local status = self.data["box"..i] or 0

    local rewardConfig = gamedata.config.shanggu_reward
    local maxPoint = rewardConfig[tostring(table.getTableLength(rewardConfig))].need_num

    if self.rootItems["boxnode"..i] then
        self.rootItems["boxnode"..i]:setPositionX(943*(rewardConfig[tostring(i)].need_num/maxPoint) - 20)
    end

    ui.setLabelString(self.rootItems["boxdesc"..i],rewardConfig[tostring(i)].need_num or "",14)

    setSpriteFrameByName(self.rootItems["box"..i], "box"..(i>4 and 4 or i).."_"..status)


    self.rootItems["boxeffect"..i]:removeAllChildrenWithCleanup(true)
    if  status == 1 then
        local ccb, item = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu2.ccbi", nil, true, "baoxiangkelingqu")
        self.rootItems["boxeffect"..i]:addChild(ccb)
    end

    self.rootItems["s_button"..i]:setSwallowsTouch(true)
    self.rootItems["s_button"..i]:setTouchPriority(-102)
    self.rootItems["s_button"..i]:addHandleOfControlEvent(function()

        local tempdata = ui.getIDandNUMs(rewardConfig[tostring(i)].reward) or {}
        if status == 0 then
            gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("ancientRuins",3)},nil)
        elseif status == 1 then
            print("领奖"..i)
            UIRequest({type = 7082, id =i})
        elseif status == 2 then
            gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("moreCommon",5)},nil)
        end
    end, CCControlEventTouchUpInside)
end

function shangguyiji.setMap(self,items,sid)

    print("setMap",sid)
    setSpriteFrameByName(items.ccb_bg, "shangguyijibg"..sid..".jpg")

    items.dialogNode:removeAllChildrenWithCleanup(true)
    
    local mapData = self.data.map[tostring(sid)]
    local mapConfig = gamedata.config.shanggu_stance[tostring(sid)][tostring(mapData.mapId)]

    for i=1,20 do
        local pos = mapConfig["stance"..i]
        if not pos or pos == 0 then
            break
        end

        local monsterConfig = gamedata.config.shanggu_monster[tostring(mapConfig["monster"..i])]
            
        items["pos"..pos]:removeAllChildrenWithCleanup(true)



        if not mapData.deadPos[tostring(i)] then
            local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(monsterConfig.icon).animationid)].name
            local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            Gneral:setAnimation("stand",true,0)
            Gneral:setScale(1.2)
            Gneral:setScaleX(-1.2)
            Gneral:setPosition(0,-50)
            items["pos"..pos]:addChild(Gneral)

            items["posButton"..pos]:setPosition(items["pos"..pos]:getPositionX(),items["pos"..pos]:getPositionY())
            -- items["posButton"..pos]:setSwallowsTouch(true)
            items["posButton"..pos]:setTouchEnabled(true)
            items["posButton"..pos]:setTouchPriority(-102)
            items["posButton"..pos]:addHandleOfControlEvent(function()

                if self.isContentScroll then
                    return
                end
                gameWindows:openWindow("ancientRuinsMonster",{mapId = sid,pos = i,monsterId = mapConfig["monster"..i],data = self.data},nil)
            end, CCControlEventTouchUpInside)
        else
            items["posButton"..pos]:setPosition(0,9999)
        end

    end


    local bossConfig = gamedata.config.shanggu_monster[tostring(mapConfig["BOSS"])]
    items["pos0"]:removeAllChildrenWithCleanup(true)

    if not mapData.deadPos["0"] then
        local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(bossConfig.icon).animationid)].name
        local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        Gneral:setAnimation("stand",true,0)
        Gneral:setScale(1.2)
        Gneral:setScaleX(-1.2)
        Gneral:setPosition(0,-50)
        items["pos0"]:addChild(Gneral)

        local spr = ui.createSprite()
        spr:setPosition(0,180)
        spr:setScale(1.3)
        items["pos0"]:addChild(spr) 
        setSpriteFrameByName(spr, "zhongjibosszi1")


        items["posButton0"]:setPosition(items["pos0"]:getPositionX(),items["pos0"]:getPositionY())
        items["posButton0"]:setSwallowsTouch(true)
        items["posButton0"]:setTouchEnabled(true)
        items["posButton0"]:setTouchPriority(-102)
        items["posButton0"]:addHandleOfControlEvent(function()
            
            gameWindows:openWindow("ancientRuinsMonster",{mapId = sid,pos = 0,monsterId = mapConfig["BOSS"],data = self.data},nil)
        end, CCControlEventTouchUpInside)
    else
        items["posButton0"]:setPosition(0,9999)
    end
end


function shangguyiji.loadPage(self,sid)
    if not self.createdItems[sid] and sid >=1 and sid<= self.maxsid then
        local configdata = {type = ""}
        local CCB, ccbDoc = CCBReaderLoad("shangguyiji/map.ccbi", nil, true, "map")
        CCB:setPosition(1080*(sid-1),0)

        self:setMap(ccbDoc,sid)
        self.rootItems.container:addChild(CCB)
        self.createdItems[sid] = {ccb = CCB,item = ccbDoc}
    end
end

function shangguyiji.removePage(self,sid)
    if self.createdItems[sid] then
        -- gameTimer:UnrigistTime("encounter_"..self.encounterData[tostring(sid)].iid)
        -- gameTimer:UnrigistTimeFunc("encounter_"..self.encounterData[tostring(sid)].iid)
        self.createdItems[sid].ccb:removeAllChildrenWithCleanup(true)
        self.createdItems[sid].ccb:removeFromParentAndCleanup(true)
        self.createdItems[sid] = nil
    end
end

function shangguyiji.loadPages(self)
    for k,v in pairs(self.createdItems) do
        if k>= self.sid-1 and k<= self.sid+1 then
        else
            self:removePage(k)
        end
    end
    self:loadPage(self.sid)
    self:loadPage(self.sid+1)
    self:loadPage(self.sid-1)

    for k,v in pairs(self.createdItems) do
        if k == self.sid then
            v.ccb:setZOrder(2)
        else
            v.ccb:setZOrder(1)
        end
    end
end

function shangguyiji.reload(self,sid,isfirst)
    if sid > self.maxsid then
        sid = self.maxsid
    end
    self.sid = sid

    if self.rootItems then
        if isfirst then
            self.rootItems.container:setPosition(ccp(-1080*(self.sid-1), 0))
            self:loadPages()
        else
            local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.sid-1), 0))
            self.rootItems.container:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
                self:loadPages()
            end)))
        end
    end
end

function shangguyiji.initFixedString(self)
    self.rootItems.fixed1:setString(gameConfig.strings:string_common("ancientRuins",1))
    self.rootItems.fixed2:setString(gameConfig.strings:string_common("ancientRuins",2))
end

return shangguyiji