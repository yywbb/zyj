--
-- Author: songyibo
-- Date: 2019-12-20 10:01:56
--

local xuanyueTreasures = {

    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,

    ListTableView = nil,
    isContentScroll = false,
    normalCellSize = {x = 1040,y = 212},

    activeAction = -1,

    cellItems = {},
    progressItems = {},
    jifenItems = {}
}

function xuanyueTreasures.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("xuanyuemibao/xuanyuemibao", nil, true, "xuanyuemibao")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
   
    self.rootItems["rulebutton"]:setSwallowsTouch(true)
    self.rootItems["rulebutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["rulebutton"]:addHandleOfControlEvent(function()
        print("rulebutton")
        gameWindows:openWindow("xuanyueTreasuresRule")
    end, CCControlEventTouchUpInside)

    self.rootItems["goBtn"]:setSwallowsTouch(true)
    self.rootItems["goBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["goBtn"]:addHandleOfControlEvent(function()
        GameScene:shiftLayer("task","up")
    end, CCControlEventTouchUpInside)

    self:setTouch()
    self:initFixedString()

    self:makeConfig()
    -- self:reload(param)

    self:initNode()

    UIRequest({type=7063})
end

function xuanyueTreasures.setTouch(self)
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)
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

function xuanyueTreasures.makeConfig(self)
    self.treasuresConfig = {}
    for i=1,table.getTableLength(gamedata.config:getConfigByName("xuanyue2_reward")) do
        self.treasuresConfig[i] = table.copy(gamedata.config:getConfigByName("xuanyue2_reward")[tostring(i)])
    end

    printT(self.treasuresConfig,"treasuresConfig")
end

function xuanyueTreasures.setCountDown(self)


    local timediff = 0
    local config = gamedata.config:getConfigByName("peak_time")[tostring(16)]
    if config.param == 3 and config["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(config["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    elseif config.param == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(config["continued_time"]-self.days.cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    end
    print("timediff",timediff)
    if timediff > 0 then
        gameTimer:rigistTime("xuanyueTreasuresTime2",timediff)        
        gameTimer:rigistTimeFunc("xuanyueTreasuresTime2", function()
            if gameTimer.times["xuanyueTreasuresTime2"] <= 0 then
                self.rootItems.timeLab:setString(gameConfig.strings:string_common("xuanyueTreasures",15))
                gameTimer:UnrigistTimeFunc("xuanyueTreasuresTime2")
            else
                self.rootItems.timeLab:setString(ui.makeTimeDayText(gameTimer.times["xuanyueTreasuresTime2"],"day3"))
            end
        end)
    else
        self.rootItems.timeLab:setString(gameConfig.strings:string_common("xuanyueTreasures",15))
    end
end

function xuanyueTreasures.openTreasuresBuy(self)

    local id = nil
    for i,v in ipairs(self.data) do
        if v == 0 then
            break
        end
        id = i
    end
    if id then
        gameWindows:openWindow("xuanyueTreasuresBuy2",{id = id})
    end
end

function xuanyueTreasures.setData(self,data)
    self.wishValue = data.data.score
    self.isHight = data.data.isHight
    self.days = data.day

    self.data = {
    }
    for i=1,table.getTableLength(data.data.status) do
        self.data[i] = data.data.status[tostring(i)]
    end
end

function xuanyueTreasures.awardCallback(self,data)
    self.data[data.awardId] = data.data
    self:setCellDisplay(data.awardId)
end

function xuanyueTreasures.initNode(self)
    local height = self.toppos - 160 - 500
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,height))

    local offy = 30
    local contentH = #self.treasuresConfig * self.normalCellSize.y + (#self.treasuresConfig - 1) * offy
    self.rootItems.container:setContentSize(CCSize(1040,contentH))
    self.rootItems.container:setPositionY(height - contentH)
    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,height - contentH),0)

    -- self.rootItems.scale9_sp:setPositionY(self.rootItems.scrollnode:getPositionY() + height + 15)
    
    for i=1,#self.treasuresConfig do
        local node,items = CCBReaderLoad("xuanyuemibao/cell_mibaojiangli", nil, true, "cell_mibaojiangli")
        node:setPosition(self.normalCellSize.x/2,(#self.treasuresConfig - i) * (offy + self.normalCellSize.y))
        self.rootItems.container:addChild(node)
        self.cellItems[i] = items

        local config = gamedata.config:getConfigByName("xuanyue2_reward")[tostring(i)]
        local lowReward = ui.getIDandNUMs(config.reward1)
        local highReward = ui.getIDandNUMs(config.reward2)

        ui.setNewIcon(items, {cid = lowReward[1].cid, num = lowReward[1].num})
        items["i_button"]:setTouchPriority(self.touchPriority)
        items["i_button"]:addHandleOfControlEvent(function()
            if self.isContentScroll then return end
            ui.setPopwindowByCid(lowReward[1].cid)
        end, CCControlEventTouchUpInside)

        for i=1,2 do
            if highReward[i] then
                items["iconnode"..(i+1)]:setVisible(true)
                ui.setNewIcon(items, {cid = highReward[i].cid, num = highReward[i].num},i)

                items["i_button_"..i]:setTouchPriority(self.touchPriority)
                items["i_button_"..i]:addHandleOfControlEvent(function()
                    if self.isContentScroll then return end
                    ui.setPopwindowByCid(highReward[i].cid)
                end, CCControlEventTouchUpInside)
            else
                items["iconnode"..(i+1)]:setVisible(false)
            end
        end
    end
    
    for i=1,#self.treasuresConfig - 1 do
        local node,items = CCBReaderLoad("xuanyuemibao/jindutiao", nil, true, "jifen")
        node:setPosition(90,(#self.treasuresConfig - i) * (offy + self.normalCellSize.y) + self.normalCellSize.y/2)
        self.rootItems.container:addChild(node)
        self.progressItems[i] = items
    end

    for i=1,#self.treasuresConfig do
        local node,items = CCBReaderLoad("xuanyuemibao/jifen", nil, true, "jifen")
        node:setPosition(90,(#self.treasuresConfig - i) * (offy + self.normalCellSize.y) + self.normalCellSize.y/2)
        self.rootItems.container:addChild(node)
        self.jifenItems[i] = items
    end
end

function xuanyueTreasures.reload(self,data)

    if data.day and data.day.isopen and data.day.isopen ~= 1 then
        runGamePrompt({msg = "活动已结束"})
        GameScene:shiftLayer("main","down")
        return
    end

    if not data.data then
        return
    end

    self:setData(data)
    self:setCountDown()

    -- self.wishValue = 350
    -- self.isHight = 1
    -- self.data = {
    --     [1] =  0,
    --     [2] =  1,
    --     [3] =  2,
    --     [4] =  3,
    --     [5] =  3,
    --     [6] =  1,
    --     [7] =  2,
    --     [8] =  2,
    --     [9] =  3,
    --     [10] = 1,
    -- }
    self.rootItems.boxSp_on:setVisible(self.isHight == 1)
    self.rootItems.boxSp_off:setVisible(self.isHight ~= 1)
    self.rootItems.buyNode:setVisible(self.isHight ~= 1)

    


    self.rootItems.buyBtn:addHandleOfControlEvent(function()
        self:openTreasuresBuy()
    end, CCControlEventTouchUpInside)
    self.rootItems.buyBtn:setSwallowsTouch(true)
    self.rootItems.buyBtn:setTouchPriority(self.touchPriority)

    self.rootItems.score:setString(self.wishValue)

    -- local height = self.toppos - 160 - 550
    -- self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    -- self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    -- self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,height))

    -- local offy = 30
    -- local contentH = #self.treasuresConfig * self.normalCellSize.y + (#self.treasuresConfig - 1) * offy
    -- self.rootItems.container:setContentSize(CCSize(1040,contentH))
    -- self.rootItems.container:setPositionY(height - contentH)
    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,height - contentH),0)

    -- self.rootItems.scale9_sp:setPositionY(self.rootItems.scrollnode:getPositionY() + height + 15)
    
    for i=1,#self.treasuresConfig do
        self:setCellDisplay(i)
    end

    self:setProgressDisplay()

    for i=1,#self.treasuresConfig do
        self:setScoreDisplay(i)
    end
end


function xuanyueTreasures.setCellDisplay(self,i)
    
    local id = i

    local items = self.cellItems[i]

    items.hintnode1:setVisible(false)
    items.hintnode2:setVisible(false)
    items.hintnode3:setVisible(false)

    items.canAward1:setVisible(false)
    items.canAward2:setVisible(false)
    items.canAward3:setVisible(false)

    local function setLowStatus(status)
        if status == 1 then
            items.canAward1:setVisible(true)
        elseif status == 2 then
            items.hintnode1:setVisible(true)
        end
    end

    local function setHightStatus(status)
        for i=2,3 do

            if self.isHight == 1 then
                items["suo"..i]:setVisible(false)
                items["suoBtn"..i]:setPositionX(99999)
            else
                items["suo"..i]:setVisible(true)
                items["suoBtn"..i]:setPosition(items["suo"..i]:getPosition())
                items["suoBtn"..i]:addHandleOfControlEvent(function()
                    if self.isContentScroll then return end
                    self:openTreasuresBuy()
                end, CCControlEventTouchUpInside)
                items["suoBtn"..i]:setSwallowsTouch(true)
                items["suoBtn"..i]:setTouchPriority(self.touchPriority)
            end

            if status == 1 and self.isHight == 1 then
                items["canAward"..i]:setVisible(true)
            elseif status == 2 then
                items["hintnode"..i]:setVisible(true)
            end
        end
    end
    --0不可领取/1可领取/2已领取/3继续领取/4普通奖励可领取
    items.btnhint:setVisible(false)
    ui.removeGray("CCControlButton",items.dobutton)

    if self.data[i] == 0 then
        setLowStatus(0)
        setHightStatus(0)
        ui.setLabelString(items.doLab,gameConfig.strings:string_common("xuanyueTreasures",3),19)
        ui.addGray("CCControlButton",items.dobutton)
    elseif self.data[i] == 1 then
        setLowStatus(1)
        setHightStatus(1)
        ui.setLabelString(items.doLab,gameConfig.strings:string_common("xuanyueTreasures",3),19)
    elseif self.data[i] == 2 then
        setLowStatus(2)
        setHightStatus(2)
        items.buttonNode:setVisible(false)
        items.btnhint:setVisible(true)
    elseif self.data[i] == 3 then
        setLowStatus(2)
        setHightStatus(0)
        ui.setLabelString(items.doLab,gameConfig.strings:string_common("xuanyueTreasures",4),19)
    elseif self.data[i] == 4 then
        setLowStatus(1)
        setHightStatus(2)
        ui.setLabelString(items.doLab,gameConfig.strings:string_common("xuanyueTreasures",3),19)
    end

    items.dobutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        if self.data[i] == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("xuanyueTreasures",5)})
        elseif self.data[i] == 1 then
            print("领取",i)
            UIRequest({type=7064, id = i})
        elseif self.data[i] == 3 then
            print("继续领取",i)
            -- UIRequest({type=7061, id = i})
            self:openTreasuresBuy()
        elseif self.data[i] == 4 then
            UIRequest({type=7064, id = i})
        end
    end, CCControlEventTouchUpInside)
    items.dobutton:setTouchPriority(self.touchPriority)

end


function xuanyueTreasures.setProgressDisplay(self)

    local id = 1
    local pencent = 0
    for i=1,#self.treasuresConfig do
        if i > 1 then
            if self.wishValue >= self.treasuresConfig[i].need_num then
               id = i
            else
                pencent = (self.wishValue - self.treasuresConfig[i - 1].need_num)/(self.treasuresConfig[i].need_num - self.treasuresConfig[i - 1].need_num)
                break
            end
        end
    end

    for i=1,#self.progressItems do
        if id > i then
            self.progressItems[i].progressSp:setVisible(true)
        elseif id == i then
            ui.setSpriteTextureRect2(self.progressItems[i].progressSp,0,0,210*pencent,21)
        elseif id < i then
            self.progressItems[i].progressSp:setVisible(false)
        end
    end

end

function xuanyueTreasures.setScoreDisplay(self,i)

    local items = self.jifenItems[i]
    local config = self.treasuresConfig[i]


    local animationManager = getAnimationManager(items)
    if self.wishValue >= config.need_num then
        animationManager:runAnimationsForSequenceNamed("play")
    else
        animationManager:runAnimationsForSequenceNamed("free")
    end
    items.score:setString(config.need_num)
end

function xuanyueTreasures.initFixedString(self)
   self.rootItems.fixed3:setString(gameConfig.strings:string_common("xuanyueTreasures",9))
end

function xuanyueTreasures.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil
    self.isContentScroll = false

    self.cellItems = {}
    self.progressItems = {}
    self.jifenItems = {}

    gameTimer:UnrigistTimeFunc("xuanyueTreasuresTime2")
end

return xuanyueTreasures  B<  