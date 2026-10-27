--
-- Author: jkp
-- Date: 2023-02
--

local ascensionSendai = {

    rootNode = nil,
    rootItems = nil,
    touchPriority = -103,

    animationManager = nil,
    mapGeneral = nil,
    point_now = 0,
    point_now_x = 1,
    point_now_y = 1,

    isContentScroll = false,
    isscrolltouched = false,

    normalCellSize = {x = 1080, y = 270},

    sxtMapTypeConfig = {},

    mapData = {},       --地图数据
    mapConfig = {},     --地图配置
    cellItems = nil,

    nowPlayerPoint = nil,--玩家当前所在格子坐标
    player_sxt_id = 0,  --玩家所在格子
    player_sxt_point = {i=0,j=0}, --玩家所在格子二维数据
    pointState = 0, --当前格子状态

    playerOriginPointId = 0, --玩家的原点格子id

    touchLayerHeight = 0,



    selectId = 1,    --选择的关卡id
    selectMode = 1,  --1：冒险，2：深渊
    selectConfig = {},
    listTableView = nil,

    dieOn = 0,

    param = nil,

    nowEventOn = true, --当前事件是否执行

    sendaiGenerals = 0,

    pointPath = {},
}

function ascensionSendai.init(self,parent,toppos,param)

    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("shengxiantai/shengxiantai", nil, true, "shengxiantai")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.param = param

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)

    self.touchLayerHeight = toppos

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width, self.touchLayerHeight))
    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width, self.touchLayerHeight))

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","ascensionSendai",touchbegin)

    local function touchend(pos)
        if self.rootItems.touchLayer and ui.isTouched(self.rootItems.touchLayer,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","ascensionSendai",touchend)

    -- 返回
    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority - 1)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    -- 说明
    self.rootItems["infobutton"]:setSwallowsTouch(true)
    self.rootItems["infobutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["infobutton"]:addHandleOfControlEvent(function()
        -- ui.popCommonRule(664)
        gameWindows:openWindow("shengxiantai_rule")
    end, CCControlEventTouchUpInside)
   
    -- 升仙商店
    self.rootItems["sendaiShopBtn"]:setSwallowsTouch(true)
    self.rootItems["sendaiShopBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["sendaiShopBtn"]:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(665)
    end, CCControlEventTouchUpInside)

    -- 点仙
    self.rootItems["sendaiFairyBtn"]:setSwallowsTouch(true)
    self.rootItems["sendaiFairyBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["sendaiFairyBtn"]:addHandleOfControlEvent(function()

        GameScene:shiftLayer("ascensionSendaiSlot",nil)

    end, CCControlEventTouchUpInside)

    -- 飞升仙术
    self.rootItems["sendaiSkillBtn"]:setSwallowsTouch(true)
    self.rootItems["sendaiSkillBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["sendaiSkillBtn"]:addHandleOfControlEvent(function()
        
        gameWindows:openWindow("ascension_xianshu",{toppos = self.toppos})

    end, CCControlEventTouchUpInside)

    self:setTouch()
    self:makeConfig()

    UIRequest({type = 8851})

end

function ascensionSendai.setTouch(self)
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)
        -- print("cy = ", self.rootItems.container:getPositionY())
        local a = self.rootItems.container:getContentSize().height
        local b = self.rootItems.container:getPositionY()
        self.rootItems.mapnode:setPositionY(b * (4320 - self.toppos) / (a - self.toppos))
    end

    local function ccTouchEnded(x, y)
        if math.abs(y - self.touchY) > 30 then
            self.isContentScroll = true
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
    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority-1, false)
    self.rootItems.touchLayer:setTouchPriority(self.touchPriority-1)
    self.rootItems.touchLayer:setTouchEnabled(true)
end

function ascensionSendai.makeConfig(self)
    self.sxtMapTypeConfig = gamedata.config.shengxian_type or {}
end

--设置主角
function ascensionSendai.initGeneral(self)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.protagonist.general.cid)].animationid)].name
    local wing = {level = GameScene.protagonist.w_l, color = GameScene.protagonist.w_c}
    local general = ui.itemcache:loadSkeleton(generalName, wing)
    general:setAnimation("stand",true,0)
    general:setScale(0.6)
    general:setPosition(0,0)
    return general.root or general
end

-- 数据加载
function ascensionSendai.reloadData(self, data)
    if not data then
        UIRequest({type = 8851})
        return
    end

    self.mapData = data.data
    self.pointState = self.mapData.pointstate
    self.selectId = self.mapData.maplevel
    self.selectMode = self.mapData.difficulty
    self.sendaiGenerals = self.mapData.sendaiGenerals
    if self.mapData.pointStr then
        self.pointPath = ui.getIDSFromStr(self.mapData.pointStr)
    end

    if self.mapData.maplevel == 0 or self.mapData.difficulty == 0 then
        self:initSelect(self.toppos, self.mapData)
        for i=1,7 do
            CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id, 0)
        end
        self.rootItems.level_nandu_node:setVisible(false)
        self.rootItems.shengxianyu_node:setVisible(false)
    else
        self.rootItems.level_nandu_node:setVisible(true)
        self.rootItems.shengxianyu_node:setVisible(true)
        self.rootItems.levelnum:setString(gamedata.config.shengxian_interval[tostring(self.selectId)].level.."级")
        if self.selectMode == 1 then
            self.rootItems.maoxian:setVisible(true)
            self.rootItems.shenyuan:setVisible(false)
        elseif self.selectMode == 2 then
            self.rootItems.maoxian:setVisible(false)
            self.rootItems.shenyuan:setVisible(true)
        end
        ui.setLabelString(self.rootItems.shengxianyuNum, self.mapData.sxynum, 18, 34)
    end

    --倒计时
    gameTimer:rigistTime("ascensionSendai", self.mapData.time)
    gameTimer:rigistTimeFunc("ascensionSendai",function()
        if gameTimer.times["ascensionSendai"] >= 0 then
            self.rootItems.sxt_time:setString(ui.makeTimeDayText(gameTimer.times["ascensionSendai"], "day"))
        end
        if gameTimer.times["ascensionSendai"] == 0 then
            self.cellItems = nil
            UIRequest({type = 8851})
            gameTimer:UnrigistTimeFunc("ascensionSendai")
        end
    end)

    local mapconfig = gamedata.config["shengxian_map"..self.mapData.mapid] or gamedata.config.shengxian_map1
    for i=1,table.getTableLength(mapconfig) do
        self.mapConfig[i] = mapconfig[tostring(i)]
    end

    if self.cellItems == nil then
        self.cellItems = {}
        self.rootItems.container:removeAllChildrenWithCleanup(true)
        local contentH = #self.mapConfig * self.normalCellSize.y
        local moveY = self.toppos - self.normalCellSize.y*5
        self.rootItems.container:setContentSize(CCSizeMake(self.normalCellSize.x, contentH + moveY ))
        -- self.rootItems.container:setPositionY(self.touchLayerHeight - contentH)

        for i=1,#self.mapConfig do
            local node,items = CCBReaderLoad("shengxiantai/cell_shengxiantai_map", nil, true, "cell_shengxiantai_map")
            node:setPosition(self.normalCellSize.x/2, (#self.mapConfig - i) * self.normalCellSize.y)
            self.rootItems.container:addChild(node)
            self.cellItems[i] = items
            --初始主角信息
            if i == #self.mapConfig then
                for j=1,5 do
                    if self.mapConfig[i]["line_"..j] and self.mapConfig[i]["line_"..j] ~= "" then
                        local key = (j-1) == 0 and "" or "_"..(j-1)
                        if items["sxt_generalnode"..key] then
                            self.mapGeneral = nil
                            items["sxt_generalnode"..key]:removeAllChildrenWithCleanup(true)
                            self.mapGeneral = self:initGeneral()
                            items["sxt_generalnode"..key]:addChild(self.mapGeneral)
                            local point = items["sxt_generalnode"..key]:convertToNodeSpace(ccp(items["sxt_generalnode"..key]:getPositionX(), items["sxt_generalnode"..key]:getPositionY()))
                            if self.nowPlayerPoint == nil then
                                self.nowPlayerPoint = point
                            end
                            print("nowPlayerPoint.x = ",self.nowPlayerPoint.x)
                            print("nowPlayerPoint.y = ",self.nowPlayerPoint.y)
                            self.player_sxt_id = (i-1)*5+j
                            self.player_sxt_point.i = i
                            self.player_sxt_point.j = j
                            self.playerOriginPointId = (i-1)*5+j
                        end
                    end
                end
            end    
            self:setCellDisplay(i)
        end

        --设置当前进度
        if self.mapData.newpoint > 0 then
            for i=1,#self.mapConfig do
                for j=1,5 do
                    local pointId = (i-1)*5+j
                    if pointId == self.mapData.newpoint then
                        local key = (j-1) == 0 and "" or "_"..(j-1)
                        local point = self.cellItems[i]["sxt_generalnode"..key]:convertToNodeSpace(ccp(self.cellItems[i]["sxt_generalnode"..key]:getPositionX(), self.cellItems[i]["sxt_generalnode"..key]:getPositionY()))
                        local sxt_x = self.nowPlayerPoint.x - point.x
                        local sxt_y = self.nowPlayerPoint.y - point.y - self.rootItems.container:getPositionY()
                        self.mapGeneral:setPosition(sxt_x, sxt_y)
                        self.player_sxt_id = self.mapData.newpoint
                        self.player_sxt_point.i = i
                        self.player_sxt_point.j = j
                    end
                    --事件完成路径
                    if self.pointPath then
                        for k,v in ipairs(self.pointPath) do
                            if self.player_sxt_id ~= v and v == pointId then
                                local key = (j-1) == 0 and "" or "_"..(j-1)
                                self.cellItems[i]["finish_img"..key]:setVisible(true)
                                ui.addGray("CCSprite", self.cellItems[i]["sxt_icon"..key])
                            end
                        end
                    end
                end
            end
        end
        self:updateScrollnodeLocation((#self.mapConfig) - self.player_sxt_point.i)
    end

    --返回升仙台后继续进行相应的事件（点仙返回、战斗返回）
    if self.param and next(self.param) then
        printT(self.param)
        if self.param.bossResult and self.param.bossResult == 1 then
            runGamePrompt({msg = "恭喜通关本轮升仙台"})
        end

        if self.param.eventId and self.param.eventId > 0 then
            local eventConfig = self.sxtMapTypeConfig[tostring(self.param.eventId)]
            self:eventProcessing(eventConfig)
        end
        self.param = nil
    end
end

function ascensionSendai.updateScrollnodeLocation(self,cell)

    local index = 0
    if cell > (#self.mapConfig) - 5 then
        index = (#self.mapConfig) - 5
    elseif cell > 3 and cell <= (#self.mapConfig) - 5 then
        index = cell - 1
    else 
        index = 0
    end
    print("index = ", index)
    local contentH = index * self.normalCellSize.y
    self.rootItems.container:setPositionY(-contentH )

    local a = self.rootItems.container:getContentSize().height
    local b = self.rootItems.container:getPositionY()
    self.rootItems.mapnode:setPositionY(b * (4320 - self.toppos) / (a - self.toppos))

end

function ascensionSendai.setCellDisplay(self,i)
    local items = self.cellItems[i]
    local sxtData = self.mapConfig[i]

    for j=1,5 do
        local id = j-1
        local key_Ex
        if id == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..id
        end
        if sxtData["line_"..j] and sxtData["line_"..j] ~= "" then
            local roadData = ui.getIDSFromStr(sxtData["line_"..j])
            items["taizi"..j]:setVisible(true)
            for k=1,3 do
                if roadData[k] > 0 then
                    local x = roadData[k]%5
                    if x == 0 then
                        x = 5
                    end
                    if self.mapConfig[i+1] then
                        local next_sxtData = self.mapConfig[i+1]
                        if next_sxtData["line_"..x] and next_sxtData["line_"..x] ~= "" then
                            items["sxt_taizi"..k..key_Ex]:setVisible(true)
                        else
                            items["sxt_taizi"..k..key_Ex]:setVisible(false)
                        end
                    else
                        items["sxt_taizi"..k..key_Ex]:setVisible(false)
                    end
                else
                    items["sxt_taizi"..k..key_Ex]:setVisible(false)
                end
            end
            --设置图标
            if sxtData["event_"..j] and tonumber(sxtData["event_"..j]) > 0 then
                local iconName = self.sxtMapTypeConfig[tostring(sxtData["event_"..j])].icon
                -- setSpriteFrameByName(items["sxt_icon"..key_Ex], iconName)
                items["sxt_icon"..key_Ex]:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(iconName..".png"))
                items["sxt_icon"..key_Ex]:setVisible(true)
            else
                items["sxt_icon"..key_Ex]:setVisible(false)
            end
            --跳台子
            items["sxt_button"..key_Ex]:setTouchPriority(self.touchPriority+1)
            items["sxt_button"..key_Ex]:addHandleOfControlEvent(function()
                if self.isContentScroll then return end
                gameTouch:clickprofbytime(0.5)
                print("到这来 ~ . ~")

                if gameTimer.times["ascensionSendai"] <= 600 then
                    runGamePrompt({msg = "本轮升仙台挑战时间已结束"})
                    return
                end

                local touchsxtId = (i-1)*5+j
                print("touchsxtId = ", touchsxtId)
                print("player_sxt_id = ", self.player_sxt_id)
                if touchsxtId == self.player_sxt_id then
                    print("原地触发事件")
                    if sxtData["event_"..j] and tonumber(sxtData["event_"..j]) > 0 then
                        local eventConfig = self.sxtMapTypeConfig[tostring(sxtData["event_"..j])]
                        self:eventProcessing(eventConfig)
                    end
                    return
                else
                    local canGo = 0
                    local roadData = ui.getIDSFromStr(sxtData["line_"..j])
                    printT(roadData,"jkp-roadData")
                    --判断是否可以到达
                    for k=1,3 do
                        if roadData[k] and roadData[k] == self.player_sxt_id then
                            canGo = canGo + 1
                        end
                    end
                    if canGo == 0 then
                        runGamePrompt({msg = "无法到达该升仙台"})
                        return
                    end
                    --判断当前任务是否完成
                    canGo = 0
                    if self.pointState == 0 then
                        for k=1,3 do
                            if roadData[k] and roadData[k] == self.playerOriginPointId then
                                canGo = canGo + 1
                            end
                        end
                        if canGo == 0 then
                            runGamePrompt({msg = "需要完成当前任务才能继续前进"})
                            return
                        end
                    end
                end

                print("前进触发事件")
                local point = items["sxt_generalnode"..key_Ex]:convertToNodeSpace(ccp(items["sxt_generalnode"..key_Ex]:getPositionX(), items["sxt_generalnode"..key_Ex]:getPositionY()))
                local sxt_x = self.nowPlayerPoint.x - point.x
                local sxt_y = self.nowPlayerPoint.y - point.y - self.rootItems.container:getPositionY()
                local raise = 300
                -- if math.abs(self.nowPlayerPoint.y - point.y) < 2 then
                --     raise = 120
                -- end
                raise = raise*GameScene.scaleNum --高度
                local gmoveto = CCJumpTo:create(0.33, ccp(sxt_x, sxt_y), raise, 1)
                self.mapGeneral:runAction(CCSequence:createWithTwoActions(gmoveto, CCCallFunc:create(function()
                    self.player_sxt_id = (i-1)*5+j
                    table.insert(self.pointPath, self.player_sxt_id)
                    self.player_sxt_point.i = i
                    self.player_sxt_point.j = j
                    if sxtData["event_"..j] and tonumber(sxtData["event_"..j]) > 0 then
                        self.nowEventOn = true
                        local eventConfig = self.sxtMapTypeConfig[tostring(sxtData["event_"..j])]
                        self:eventProcessing(eventConfig)
                    end
                end)))
                -- self.mapGeneral:setPosition(sxt_x, sxt_y)
            end, CCControlEventTouchUpInside)

        else
            items["taizi"..j]:setVisible(false)
        end
    end

end

function ascensionSendai.gotoSendaiSlot(self)
    GameScene:shiftLayer("ascensionSendaiSlot",nil)
end

-- 事件处理
function ascensionSendai.eventProcessing(self, event)
    if self.nowEventOn then
        print("事件类型 = ", event.type)
        UIRequest({type = 8853, pointId = self.player_sxt_id, event = {id = event.id, type = event.type}})
    else
        runGamePrompt({msg = "当前事件已完成"})
    end
end

function ascensionSendai.updataPointState(self, data)
    if data.pointState then
        self.pointState = data.pointState
    end
    --事件完成路径
    for i=1,#self.mapConfig do
        for j=1,5 do
            if self.pointPath then
                local pointId = (i-1)*5+j
                for k,v in ipairs(self.pointPath) do
                    if self.player_sxt_id ~= v and v == pointId then
                        local key = (j-1) == 0 and "" or "_"..(j-1)
                        self.cellItems[i]["finish_img"..key]:setVisible(true)
                        ui.addGray("CCSprite", self.cellItems[i]["sxt_icon"..key])
                    end
                end
            end
        end
    end
end

--随机事件二次处理
function ascensionSendai.adventure_event_secondary(self, data)
    print("随机事件") 
    local eventConfig = self.sxtMapTypeConfig[tostring(data.eventdata.id)]
    self:eventProcessing(eventConfig)
end

--打开商店
function ascensionSendai.adventure_event_openShop(self, data)
    print("打开商店1") 
    if data.eventdata.buyid and data.eventdata.buyid > 0 then
        runGamePrompt({msg = "当前事件已完成"})
        self.nowEventOn = false
    else
        local buyId, prob = ui.getIDandNUM(self.sxtMapTypeConfig[tostring(data.event.id)]["difficult"..self.selectId.."_"..self.selectMode])
        local buyConfig = gamedata.config.shengxian_buy[tostring(buyId)]
        local callback = function(selectId)
            UIRequest({type = 8854, pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}, selectId = data.eventdata["buyBuffId"..selectId]})
        end
        gameWindows:openWindow("sendai_allType",{id = 1, config = buyConfig, eventdata = data.eventdata}, callback)
    end
end

--选择仙术
function ascensionSendai.adventure_event_selectBuff(self, data)
    print("选择仙术2")
    if data.eventdata.selectid and data.eventdata.selectid > 0 then
        runGamePrompt({msg = "当前事件已完成"})
        self.nowEventOn = false
    else
        local buffIds = table.copy(data.eventdata) --随机的三个buffId
        local callback = function(selectId)
            local sid = buffIds["buffId"..selectId]
            UIRequest({type = 8854, pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}, selectId = sid })
        end
        gameWindows:openWindow("sendai_allType",{id = 2, config = {}, eventdata = buffIds}, callback)
    end
end

--选择助战伙伴
function ascensionSendai.adventure_event_selectCheer(self, data)
    print("选择助战伙伴3")
    if data.eventdata.selectid and data.eventdata.selectid > 0 then
        runGamePrompt({msg = "当前事件已完成"})
        self.nowEventOn = false
    else
        local cheerIds = table.copy(data.eventdata) --随机的四个助战Id
        local callback = function(selectId)
            local sid = cheerIds["cheerId"..selectId]
            UIRequest({type = 8854, pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}, selectId = sid })
        end
        gameWindows:openWindow("sendai_allType",{id = 3, config = {}, eventdata = cheerIds}, callback)
    end
end

function ascensionSendai.adventure_event_encounter(self, data)
    print("仙遇事件4")
    if data.eventdata.encounter_complete and data.eventdata.encounter_complete > 0 then
        runGamePrompt({msg = "当前事件已完成"})
        self.nowEventOn = false
    else
        -- local encounterId, prob = ui.getIDandNUM(self.sxtMapTypeConfig[tostring(data.event.id)]["difficult"..self.selectId.."_"..self.selectMode])
        print("encounterId = ", data.eventdata.encounterId)
        local encounterConfig = gamedata.config.shengxian_praram[tostring(data.eventdata.encounterId)]
        
        local callback = function(selectId)
            UIRequest({type = 8854, pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}, selectId = selectId })
        end
        gameWindows:openWindow("sendai_allType",{id = 4, config = encounterConfig, eventdata = data.eventdata}, callback)
    end
end

function ascensionSendai.adventure_event_recover(self, data)
    print("恢复事件5")
    if data.eventdata.recoverid and data.eventdata.recoverid > 0 then
        runGamePrompt({msg = "当前事件已完成"})
        self.nowEventOn = false
    else
        local recoverId, prob = ui.getIDandNUM(self.sxtMapTypeConfig[tostring(data.event.id)]["difficult"..self.selectId.."_"..self.selectMode])
        print("recoverId = ", recoverId)
        local recoverConfig = gamedata.config.shengxian_recover[tostring(recoverId)]
        local callback = function(selectId)
            UIRequest({type = 8854, pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}, selectId = selectId })
        end
        gameWindows:openWindow("sendai_allType",{id = 5, config = recoverConfig, eventdata = data.eventdata}, callback)
    end
end

function ascensionSendai.adventure_event_revive(self, data)
    print("复活事件6")
    if data.eventdata.reviveid and data.eventdata.reviveid > 0 then
        runGamePrompt({msg = "当前事件已完成"})
        self.nowEventOn = false
    else
        local reviveId, prob = ui.getIDandNUM(self.sxtMapTypeConfig[tostring(data.event.id)]["difficult"..self.selectId.."_"..self.selectMode])
        print("reviveId = ", reviveId)
        local reviveConfig = gamedata.config.shengxian_recover[tostring(reviveId)]
        local callback = function(selectId, dieOn)
            self.dieOn = dieOn
            UIRequest({type = 8854, pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}, selectId = selectId })
        end
        gameWindows:openWindow("sendai_allType",{id = 6, config = reviveConfig, eventdata = data.eventdata}, callback)
    end
end

function ascensionSendai.adventure_event_battle(self, data)
    if data.eventdata.battleTobuff and data.eventdata.battleTobuff > 0 then
        print("战斗事件 转 仙术事件")
        local eventConfig = self.sxtMapTypeConfig[tostring(data.eventdata.battleTobuff)]
        self:eventProcessing(eventConfig)
    else
        print("战斗事件7")
        if data.eventdata.battleOver and data.eventdata.battleOver > 0 then
            runGamePrompt({msg = "当前事件已完成"})
            self.nowEventOn = false
        else
            --没有点仙，先去点仙
            local battleId, prob = ui.getIDandNUM(self.sxtMapTypeConfig[tostring(data.event.id)]["difficult"..self.selectId.."_"..self.selectMode])
            print("battleId = ", battleId)
            if self.sendaiGenerals > 0 then
                local battleConfig = gamedata.config.shengxian_battle[tostring(battleId)]
                gameWindows:openWindow("sendai_battle",{id = 1, config = battleConfig, pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}})
            else
                local function callback()
                    GameScene:shiftLayer("ascensionSendaiSlot", nil, {pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}, battleId = battleId})
                end
                gameWindows:openWindow("confirm",{msg = "需前往点仙页面进行点仙，是否确认？"}, callback)
            end
        end
    end
end

function ascensionSendai.adventure_event_boss(self, data)
    print("BOSS战斗事件8")
    if data.eventdata.bossOver and data.eventdata.bossOver > 0 then
        runGamePrompt({msg = "当前事件已完成"})
        self.nowEventOn = false
    else
        local battleId, prob = ui.getIDandNUM(self.sxtMapTypeConfig[tostring(data.event.id)]["difficult"..self.selectId.."_"..self.selectMode])
        print("battleId = ", battleId)
        local battleConfig = gamedata.config.shengxian_battle[tostring(battleId)]
        gameWindows:openWindow("sendai_battle",{id = 2, config = battleConfig, pointId = self.player_sxt_id, event = {id = data.event.id, type = data.event.type}})
    end
end

--恢复事件 8854 UI
function ascensionSendai.secondary_event_recover(self, data)
    local name = gamedata.config.general[tostring(data.eventdata.cid)].name
    runGamePrompt({msg = "「"..name.."」生命恢复"})
end

--复活事件 8854 UI
function ascensionSendai.secondary_event_revive(self, data)
    local name = gamedata.config.general[tostring(data.eventdata.cid)].name
    if self.dieOn == 1 then
        runGamePrompt({msg = "「"..name.."」已复活，可继续上阵"})
    else
        runGamePrompt({msg = "「"..name.."」生命恢复"})
    end
end

--
function ascensionSendai.clear(self)
    self.show = false

    if self.rootNode2 then
        self:clearSelect()
    end

    if gameTimer.times["ascensionSendai"] then
        gameTimer:UnrigistTimeFunc("ascensionSendai")
    end
    gameTouch:UnrigistFunc("begin","ascensionSendai")
    gameTouch:UnrigistFunc("end","ascensionSendai")

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.sxtMapTypeConfig = {}
    self.mapConfig = {}
    self.cellItems = nil
    self.mapGeneral = nil

    self.nowPlayerPoint = nil

    self.param = nil
    self.nowEventOn = true

    self.sendaiGenerals = 0
    self.pointPath = {}

end

-- 初始化选择难度界面
function ascensionSendai.initSelect(self, toppos, data)
    --难度选择
    if self.rootNode2 then
        return
    end
    self.rootNode2, self.rootItems2 = CCBReaderLoad("shengxiantai/shengxiantai_select", nil, true, "shengxiantai_select")
    self.rootNode2:setPosition(0,0)
    self.rootItems.selcetnode:addChild(self.rootNode2)

    self.rootItems2.topnode:setPositionY(toppos)
    self.rootItems2.midnode:setPositionY(toppos/2)

    self.rootItems2["touchbutton"]:setSwallowsTouch(true)
    self.rootItems2["touchbutton"]:setTouchPriority(self.touchPriority)
    self.rootItems2["touchbutton"]:addHandleOfControlEvent(function()

    end, CCControlEventTouchUpInside)

    -- 说明
    self.rootItems2["infobutton_select"]:setSwallowsTouch(true)
    self.rootItems2["infobutton_select"]:setTouchPriority(self.touchPriority - 2)
    self.rootItems2["infobutton_select"]:addHandleOfControlEvent(function()
        gameWindows:openWindow("shengxiantai_rule")
    end, CCControlEventTouchUpInside)

    self.rootItems2.common_back_btn:setSwallowsTouch(true)
    self.rootItems2.common_back_btn:setTouchPriority(self.touchPriority - 2)
    self.rootItems2.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    self.selectConfig = gamedata.config.shengxian_interval or {}
    -- printT(self.selectConfig,"jkp-selectConfig")

    --倒计时
    gameTimer:rigistTime("ascensionSendai_select", data.time)
    gameTimer:rigistTimeFunc("ascensionSendai_select",function()
        if gameTimer.times["ascensionSendai_select"] >= 0 then
            self.rootItems2.select_time:setString(ui.makeTimeDayText(gameTimer.times["ascensionSendai_select"], "day"))
        end
        if gameTimer.times["ascensionSendai_select"] == 0 then
            UIRequest({type = 8851})
            gameTimer:UnrigistTimeFunc("ascensionSendai_select")
        end
    end)

    if not self.listTableView then
        self:createList()
    end

    local index = 0
    local num = tonumber(table.getTableLength(self.selectConfig))
    if GameScene.roleinfo.level >= self.selectConfig[tostring(num-1)].level then
        index = num
        self.listTableView:setLuaContentOffset(self.rootItems2.selectListNode:getContentSize().width - index*390, 0)
    else
        for i=2,5 do
            if GameScene.roleinfo.level >= self.selectConfig[tostring(i)].level and GameScene.roleinfo.level < self.selectConfig[tostring(i+1)].level then
                index = i-1
            end
        end
        self.listTableView:setLuaContentOffset(0-index*390, 0)
    end
    if index > 0 then
        self.listTableView:reloadData()
    end

end

function ascensionSendai.createList(self)
    local celldict = {}
    local unrecycleCell = {}
    local callSize = {x = 390, y = 860}
    local propsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(callSize.x, callSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shengxiantai/cell_shengxiantai_select", nil, true, "cell_shengxiantai_select")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.listTableView,cellCCB,callSize.x/2, 0, a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setSelectCell(ccbDocumentControler,self.selectConfig[tostring(a1+1)])

            if self.listTableView then
                cellCCB:setPosition(0, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.selectConfig)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = propsListHandle,
        viewwidth = self.rootItems2.selectListNode:getContentSize().width,
        viewheight = self.rootItems2.selectListNode:getContentSize().height,
        dire = 0
    })
    self.rootItems2.selectListNode:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 2)
end

function ascensionSendai.setSelectCell(self, item, data)

    ui.setLabelString(item.maoxianLab, nil, 19)
    item.maoxianBtn:setSwallowsTouch(false)
    item.maoxianBtn:setTouchPriority(self.touchPriority - 3)
    item.maoxianBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if GameScene.roleinfo.level < data.level then
            runGamePrompt({msg = "队伍等级不足"})
        else
            local function callback()
                self.selectId = data.id
                self.selectMode = 1
                UIRequest({type = 8852, mode = self.selectMode, pointId = self.player_sxt_id, level = self.selectId})
            end
            gameWindows:openWindow("confirm",{msg = "即将进入「冒险模式」，选择后本轮活动不可更改，确定要继续吗？"}, callback)
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(item.shenyuanLab, nil, 19)
    item.shenyuanBtn:setSwallowsTouch(false)
    item.shenyuanBtn:setTouchPriority(self.touchPriority - 3)
    item.shenyuanBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if GameScene.roleinfo.level < data.level then
            runGamePrompt({msg = "队伍等级不足"})
        else
            local function callback()
                self.selectId = data.id
                self.selectMode = 2
                UIRequest({type = 8852, mode = self.selectMode, pointId = self.player_sxt_id, level = self.selectId})
            end
            if GameScene.roleinfo.level >= data.level and GameScene.roleinfo.vip <= 10 then
                gameWindows:openWindow("confirm",{msg = "即将进入「深渊模式」，选择后本轮活动不可更改；您当前战斗力过低，可能无法获得任何物品，确定要继续吗？"}, callback)
            else
                gameWindows:openWindow("confirm",{msg = "即将进入「深渊模式」，选择后本轮活动不可更改，确定要继续吗？"}, callback)
            end
        end
    end, CCControlEventTouchUpInside)

    item.level:setString(data.level)

    if GameScene.roleinfo.level < data.level then
        item.openstate:setVisible(true)
    else
        item.openstate:setVisible(false)
    end
end

function ascensionSendai.clearSelect(self)

    if gameTimer.times["ascensionSendai_select"] then
        gameTimer:UnrigistTimeFunc("ascensionSendai_select")
    end

    self.rootNode2:removeAllChildrenWithCleanup(true)
    self.rootNode2:removeFromParentAndCleanup(true)
    self.rootNode2 = nil
    self.rootItems2 = nil
    self.listTableView = nil

    if self.selectId > 0 and self.selectMode > 0 then
        self.rootItems.level_nandu_node:setVisible(true)
        self.rootItems.shengxianyu_node:setVisible(true)
        self.rootItems.levelnum:setString(gamedata.config.shengxian_interval[tostring(self.selectId)].level.."级")
        if self.selectMode == 1 then
            self.rootItems.maoxian:setVisible(true)
            self.rootItems.shenyuan:setVisible(false)
        elseif self.selectMode == 2 then
            self.rootItems.maoxian:setVisible(false)
            self.rootItems.shenyuan:setVisible(true)
        end
        ui.setLabelString(self.rootItems.shengxianyuNum, self.mapData.sxynum, 18, 34)
    end

end

return ascensionSendai