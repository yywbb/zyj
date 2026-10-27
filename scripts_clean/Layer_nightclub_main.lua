--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local nightclub = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    m_tConfig = nil,
    buttontouch = -1,

    m_tBuildCell = nil,
    rewardData = {},

}

local QRIL_CLUB_MAINLEN = 0


function nightclub.init(self,parent,toppos,param)
    self.m_tConfig = {}
    local tmpConfig = gamedata.config.tiantingyz_guanqia
    -- printT(tmpConfig,"tmpConfig========:")
    for k,v in pairs(tmpConfig) do
        if QRIL_CLUB_MAINLEN < tonumber(k) then
            QRIL_CLUB_MAINLEN = tonumber(k)
        end
        self.m_tConfig[k] = {
            pic = v.icon,
            name = v.name,
            level = tonumber(v.level),
        }
    end

    self.rootNode,self.rootItems = CCBReaderLoad("nightclub/nightclub_main", nil, true, "nightclub")
    parent:addChild(self.rootNode)

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.bgscroll = tolua.cast(self.rootItems.bgscroll, "CCScrollView")
    self.rootItems.bgscroll:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
    if param and param._pointy then
        self.rootItems.bgscroll:setContentOffsetInDuration(ccp(0,param._pointy),0)
    end

    if gameConfig:checkBuildOpen(331)  then
        self.rootItems.OneKeyAddBtn:setVisible(true)
        self.rootItems.OneKeyReceiveBtn:setVisible(true)
    else
        self.rootItems.OneKeyAddBtn:setVisible(false)
        self.rootItems.OneKeyReceiveBtn:setVisible(false)
    end
    --一键添加
    self.rootItems.OneKeyAddBtn:setSwallowsTouch(true)
    self.rootItems.OneKeyAddBtn:setTouchPriority(-106)
    self.rootItems.OneKeyAddBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("oneAddclub","up")
    end, CCControlEventTouchUpInside)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(-106)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    --一键收取
    self.rootItems.OneKeyReceiveBtn:setSwallowsTouch(true)
    self.rootItems.OneKeyReceiveBtn:setTouchPriority(-106)
    self.rootItems.OneKeyReceiveBtn:addHandleOfControlEvent(function()
        if self.rewardData and next(self.rewardData) then
            GameScene:shiftLayer("oneAddclub","up",self.rewardData)
            --UIRequest({type = 4510,data = self.rewardData})
        else
            GameScene:shiftLayer("oneAddclub","up")
            --runGamePrompt({msg = gameConfig.strings:string_common("fixedString","nightclub",12)})
        end
    end, CCControlEventTouchUpInside)

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchy = y
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(y - self.touchy) > 10 then
            self.isContentScroll = true
        end
    end

    local function ccTouchEnded(x, y)
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -2, false)
    self.rootItems.touchLayer:setTouchPriority(-2)
    self.rootItems.touchLayer:setTouchEnabled(true)

    self.m_tBuildCell = {}
    local function tmpDoneOnce(destIndex)
        if self.isContentScroll then return end
        local tmpIndex = tostring(destIndex)
        if GameScene.roleinfo.level < self.m_tConfig[tmpIndex].level then 
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("nightclub",15),self.m_tConfig[tostring(destIndex)].level)})
            return 
        end
        if self.data and self.data[tmpIndex] then
            if self.data[tmpIndex]["1"] == 0 then
                runGamePrompt({msg = string.format(gameConfig.strings:string_common("nightclub",16),self.m_tConfig[tostring(destIndex-1)].name)})
            else
                GameScene:shiftLayer("clubclubcell","up",{_index = destIndex,
                                        _data = self.data[tmpIndex],
                                        _stand = self.m_tStandMan,
                                        _pointy = self.rootItems.bgscroll:getContentOffset().y})
            end
        end
    end

    for i=1,QRIL_CLUB_MAINLEN do
        local tmpIndex = tostring(i)
        local tmpNode , tmpRoot = CCBReaderLoad("nightclub/nightclub_building", nil, true, "building")
        ui.setLabelString(tmpRoot.namelable,self.m_tConfig[tostring(i)].name,21)
        setSpriteFrameByName(tmpRoot.sprite, self.m_tConfig[tostring(i)].pic)
        local tmpAnimate = getAnimationManager(tmpRoot)
        self.rootItems["m_oMapCell"..i]:addChild(tmpNode)
        tmpRoot.baobutton:setTouchPriority(-105)
        tmpRoot.baobutton:setSwallowsTouch(true)
        tmpRoot.button:setTouchPriority(-105)
        tmpRoot.button:setSwallowsTouch(true)
        tmpRoot.baobutton:addHandleOfControlEvent(function()
            tmpDoneOnce(i)
        end, CCControlEventTouchUpInside)
        tmpRoot.button:addHandleOfControlEvent(function()
            tmpDoneOnce(i)
        end, CCControlEventTouchUpInside)
        self.m_tBuildCell[tmpIndex] = {tmpNode , tmpRoot , tmpAnimate}
    end

    UIRequest({type = 4500})
    -- self:reloaddata({4,2,3,4,0,0,0,0,0,0})
end

function nightclub.reloaddata(self,data)

    self.data = data
    self.rewardData = {}
    self.m_tStandMan = {}
    local irrigateStatus = 0
    for i=1,QRIL_CLUB_MAINLEN do
        local tmpIndex = tostring(i)
        if self.data[tmpIndex] then
            print("i=====:",tmpIndex,self.data[tmpIndex]["1"])
            local tmpStageValue = self.data[tmpIndex]["1"]
            if tmpStageValue == 0 then
                ui.addGray("CCSprite",self.m_tBuildCell[tmpIndex][2].sprite)
            else

                if self.data[tmpIndex]["1"] == 2 then
                    irrigateStatus = 1
                end

                if self.data[tmpIndex]["1"] == 3 and self.data[tmpIndex]["6"] then                    
                    self:updatetimeFunc(self.m_tBuildCell[tmpIndex][2].timelable,i,self.data[tmpIndex]["6"])
                end

                if self.data[tmpIndex]["1"] == 4 then
                    table.insert(self.rewardData,i)
                end

                ui.removeGray("CCSprite",self.m_tBuildCell[tmpIndex][2].sprite)
            end
            self.m_tBuildCell[tmpIndex][3]:runAnimationsForSequenceNamed(tostring(tmpStageValue))
            local tmpCid = self.data[tmpIndex]["5"]
            if tmpCid and tmpCid > 0 then
                table.insert(self.m_tStandMan,tmpCid)
            end
        end
    end

    if self.rewardData and next(self.rewardData) then
        ui.sethint(self.rootItems["hint_OneKeyReceive"],true)
    else
        ui.sethint(self.rootItems["hint_OneKeyReceive"],false)
    end

    if irrigateStatus and irrigateStatus == 1 then
        ui.sethint(self.rootItems["hint_OneKeyAdd"],true)
    else
        ui.sethint(self.rootItems["hint_OneKeyAdd"],false)
    end


end

function nightclub.updatetimeFunc(self,node,index,times)
    local tmpStr = "night_"..index

    if gameTimer.times[tmpStr] then
        gameTimer:UnrigistTimeFunc(tmpStr)
    end
    ui.setLabelString(node,gameConfig.strings:string_common("nightclub",10)..ui.makeTimeText(times,"hour"),14)
    gameTimer:rigistTime(tmpStr, times)
    gameTimer:rigistTimeFunc(tmpStr,function()
        if gameTimer.times[tmpStr] >= 0 then
            ui.setLabelString(node,gameConfig.strings:string_common("nightclub",10)..ui.makeTimeText(gameTimer.times[tmpStr],"hour"),14)
        end
        if gameTimer.times[tmpStr] == 0 then
            UIRequest({type=4500})
            gameTimer:UnrigistTimeFunc(tmpStr)
        end
    end)
end

function nightclub.clear(self)
    local tmpStr = "night_"
    for i=1,QRIL_CLUB_MAINLEN do
        self.m_tBuildCell[tostring(i)] = nil
        if gameTimer.times[tmpStr..i] then
            gameTimer:UnrigistTimeFunc(tmpStr..i)
        end
    end
    self.m_tStandMan = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.rewardData = {}
end

return nightclub