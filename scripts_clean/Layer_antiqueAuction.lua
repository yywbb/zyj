local auction = {

    coverccb = nil,
    coveritems = nil,

    activityTimeId = "110",
    touchPriority = -101,
    spineType = {
        [1] = "stand",
        [2] = "bidding",
        [3] = "dialogue",
        [4] = "sneer",
    },
    npcSpine = {},
}

function auction.UIUpdateData(self, isreset)
    self:closeWindow("activityAuctionRule")
    self:closeWindow("activityAuctionRecording")
    self:closeWindow("activityAuctionChooseAntique")
end

function auction.closeWindow(self, name)
    if gameWindows.windows[name].show then
        gameWindows:closeWindow(name)
    end
end

function auction.clear(self)
    gameTouch:UnrigistFunc("begin", "activityAuction")
    gameTouch:UnrigistFunc("end", "activityAuction")

    self.isAppraiser = nil

    self.coverccb:removeAllChildrenWithCleanup(true)
    self.coverccb:removeFromParentAndCleanup(true)
    self.coverccb = nil
    self.coveritems = nil

end

function auction.init(self,parent,toppos)
    self:initNode(parent,toppos)
    self:initConfig()
    self:initActivityGeneralAnimation()
    self:initDapanAnimation()
    self:initActivityScroll()
    self:initFixedString()
    self:initNpcAnimation()
    self:initEventBtn()
    
    UIRequest({type = 5410})
end

function auction.initNode(self,parent, toppos)
    self.coverccb, self.coveritems = CCBReaderLoad("activitygudong/activitygudong", nil, true, "activitygudong")
    self.coverccb1, self.coveritems1 = CCBReaderLoad("activitygudong/gudong_paimai", nil, true, "gudong_paimai")
    self.coveritems.topnode:setPositionY(toppos)
    self.coverccb:setPositionX(-gameConfig.originSize.width/2)
    self.coveritems.clinchNode:addChild(self.coverccb1)
    parent:addChild(self.coverccb)
end

function auction.initConfig(self)
    self.antiqueAppraisal = gamedata.config.antique_appraisal
    self.antiqueNpc = gamedata.config.antique_npc
    self.antiqueNpcAnimation = gamedata.config.antique_npc_animation
    self.antiqueOriginalItem = gamedata.config.antique_item
    self.antiqueItem = self:setAntiqueItem()
    self.props = gamedata.config.props
end

function auction.setAntiqueItem()
    local _antiqueItem = {}

    for k,v in pairs(gamedata.config.antique_item) do
        table.insert(_antiqueItem, v)
    end

    local _tableSort = function(left, right)
        return left.cid < right.cid
    end

    table.sort(_antiqueItem, _tableSort)

    return _antiqueItem
end

function auction.initActivityGeneralAnimation(self)
    local _activityConfig = gamedata.config.activity_time
    local _generalConfig = gamedata.config.generalanimation

    if _activityConfig[self.activityTimeId].generalanimation and _activityConfig[self.activityTimeId].generalanimation > 0 then
        local _name = _generalConfig[tostring(_activityConfig[tostring(self.activityTimeId)].generalanimation)].name
        local _gneral = CCSkeletonAnimation:create(_name .."/" .. _name .. ".json", _name .."/" .. _name .. ".atlas", 1)
        _gneral:setAnimation("stand", true, 0)
        _gneral:setScale(2)
        _gneral:setPosition(0, 0)
        self.coveritems["generalNode"]:addChild(_gneral)
    end
end

function auction.initDapanAnimation(self)
    local _name = "gudongNPCdapan"
    local _gneral = CCSkeletonAnimation:create(_name .."/" .. _name .. ".json", _name .."/" .. _name .. ".atlas", 1)
    _gneral:setAnimation("stand", true, 0)
    _gneral:setScale(1)
    _gneral:setPosition(0, 0)
    self.coveritems["rootNodeDapan"]:addChild(_gneral)
end

function auction.initActivityScroll(self)
    local function touchBegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    local function touchEnd(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        else
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("begin", "activityAuction", touchBegin)
    gameTouch:rigistFunc("end", "activityAuction", touchEnd)
end

function auction.initFixedString(self)
    ui.setLabelString(self.coveritems.infoTxt, gameConfig.strings:string_common("activityAuction", 6), 14) 
end

function auction.initNpcAnimation(self)
    for i = 0, 9 do
        self:setNpcAnimation(i, self.spineType[1], true)
    end
end

function auction.initEventBtn(self)
    self:initRuleBtn()
    self:initRecordingBtn()
end


function auction.initRuleBtn(self)
    local _cb = function()
        gameTouch:clickprofbytime(1)
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("activityAuctionRule")
    end

    self:commonBtn(self.coveritems, "btnRule", _cb)
end

function auction.initRecordingBtn(self)
    local _cb = function()
        gameTouch:clickprofbytime(1)
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("activityAuctionRecording")
    end

    self:commonBtn(self.coveritems, "btnRecording", _cb)
end

function auction.initChooseAntiqueBtn(self)
    local _cb = function()
        gameTouch:clickprofbytime(1)
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("activityAuctionChooseAntique")
    end

    self:commonBtn(self.coveritems1, "chooseAntiqueBtn", _cb)
end

function auction.initResultBtn(self)
    local _cb = function()
        gameTouch:clickprofbytime(1)
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if self.isCanClick == false then return end
        self:setAddAntiueBtnIsShow(false)
        self:setClinchBtnIsShow(false)
        gameTimer:UnrigistTime("activityAuctionTimer")
        gameTimer:UnrigistTimeFunc("activityAuctionTimer")
        local _clinchAnimation = getAnimationManager(self.coveritems1)

        _clinchAnimation:setAnimationCompletedCallback(function()
            -- _clinchAnimation:runAnimationsForSequenceNamed("stand")
            UIRequest({type = 5411})
        end)

        _clinchAnimation:runAnimationsForSequenceNamed("play")
    end
    
    
    self:commonBtn(self.coveritems1, "resultBtn", _cb)
end

function auction.inityijianpaimaiBtn(self)
    
    local _cb = function()
        gameTouch:clickprofbytime(1)
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if self.isCanClick == false then return end


        gameWindows:openWindow("activityantiqueOnekey")



    end
    
    self:commonBtn(self.coveritems1, "yijianpaimaiBtn", _cb)
end


function auction.reloadData(self, data)
    self:initReload()
    self:initChooseAntiqueBtn()
    self:initResultBtn()
    self:inityijianpaimaiBtn()

    self.auctionStatus = data.auctionStatus
    self.auctionId = data.auctionId
    self.auctionQueue = data.auctionQueue
    if self.auctionId then
        self.AppraisalType = gamedata.config.antique_item[tostring(self.auctionId)].appraisalID
        GameScene.antiqueResultType = self.antiqueOriginalItem[tostring(self.auctionId)].coinID
    end

    self:setTimeLine()
    self:setMaxRoundAndResult()
    self:getRound()
    GameScene.auctionPastRound = self.currentRound
    self:setCurrentPrice()
    self:chooseAuctionType()
end

function auction.initReload(self)
    self.isCanClick = true
    self.isAppraiser = nil
    self.dialogueZorder = 100
    self.closeClinchBtn = -1
    self.coveritems["jiandingNode"]:removeAllChildrenWithCleanup(true)
    self.coveritems1["chooseAntiqueNode"]:removeAllChildrenWithCleanup(true)
    self.coveritems["dialogueNode"]:removeAllChildrenWithCleanup(true)

    self.coveritems.clinchNode:removeAllChildrenWithCleanup(true)
    self.coverccb1, self.coveritems1 = CCBReaderLoad("activitygudong/gudong_paimai",nil, true, "gudong_paimai")
    self.coveritems.clinchNode:addChild(self.coverccb1)
end

function auction.getRound(self)
    if self.auctionStatus == 0 then
        self.auctionStatus = -1
        self.currentRound = -1

        return self.currentRound
    elseif self.auctionStatus == 2 then
        self.auctionStatus = -1
        self.currentRound = 0

        return self.currentRound
    else
        for i = self.maxRound, 1, -1 do
            if gamedata:time() >= self.auctionQueue[tostring(i)].time then
                self.auctionStatus = -1
                self.currentRound = i

                return self.currentRound
            end
        end
    end
end

function auction.setMaxRoundAndResult(self)
    if self.auctionQueue and next(self.auctionQueue) then
        self.maxRound = table.getTableLength(self.auctionQueue)
        self.result = self.auctionQueue[tostring(self.maxRound)].trueOrFalse
    end
end

function auction.chooseAuctionType(self)
    -- 拍卖前
    if self.currentRound == -1 then
        self:setAuctionType(true, false)
    -- 拍卖刚刚开始
    elseif self.currentRound == 0 then
        self:setAuctionType(false, false, 1, true)
    -- 拍卖中layer_activity_auc
    elseif self.currentRound > 0 then
        self:setAuctionType(false, true, 2, true)
    -- 鉴定师
    elseif self.currentRound == self.maxRound and self.maxRound ~= 0 then
        self:setAuctionType(false, false, 2, true)
    end
end

function auction.setTimeLine(self)
    if self.auctionQueue and next(self.auctionQueue) then
        self.timeLine = {}

        local _diffTime = 0

        if GameScene.roleinfo then
            local _time = CCUserDefault:sharedUserDefault():getIntegerForKey("activityAuctionTimer_"..gameWindows.windows["roleinfo"].module.SelectedServer.id..GameScene.roleinfo.id)

            if _time and _time ~= 0 then
                _time = _time + self.antiqueAppraisal[tostring(self.AppraisalType)][tostring(1)]["interval"]
                _diffTime = _time - self.auctionQueue[tostring(1)].time
            end
        end

        for i = 1, table.getTableLength(self.auctionQueue) do
            self.timeLine[i] = {}
            self.auctionQueue[tostring(i)].time = self.auctionQueue[tostring(i)].time + _diffTime
            self:setBidderTimeLine(i)
            self:setNpcTimeLine(i)
        end
    end

    printT(self.timeLine)
end

function auction.setBidderTimeLine(self, num)
    local _time = self.auctionQueue[tostring(num)].time
    local _npcId = self.auctionQueue[tostring(num)].npcId
    local _endTime = _time + self.antiqueNpcAnimation[tostring(_npcId)].brand_time

    self.timeLine[num].bidderStart = _time
    self.timeLine[num].bidderEnd = _endTime
    self.timeLine[num].bidderNpcId = self.auctionQueue[tostring(num)].npcId
    self.timeLine[num].price = self.auctionQueue[tostring(num)].price
end

function auction.setNpcTimeLine(self, num)
    local _time = self.auctionQueue[tostring(num)].time
    local _npcId = self.auctionQueue[tostring(num)].npcId
    local _start = _time + self.antiqueNpcAnimation[tostring(_npcId)].start
    local _end = _start + self.antiqueNpcAnimation[tostring(_npcId)].continued
    local _wight = {}

    _wight[0] = 0
    for i = 1, table.getTableLength(self.antiqueNpcAnimation) - 1 do
        table.insert(_wight, _wight[i - 1] + self.antiqueNpcAnimation[tostring(i)].rest)
    end

    local _result = 0

    repeat
        local _temp = math.random(1, _wight[#_wight])

        for i = 1, #_wight - 1 do
            if _temp <= _wight[i] then
                _result = i
                break
            end
        end
    until (_result ~= _npcId) and (_result ~= 0)

    self.timeLine[num].npcStart = _start
    self.timeLine[num].npcEnd = _end
    self.timeLine[num].npcId = _result
end

function auction.setCurrentPrice(self)
    if self.auctionQueue and next(self.auctionQueue) and (self.currentRound > 0 or self.currentRound == -2) then
        self:setCoinIcon(self:getCurrentPrice())
        self.coveritems.coinIcon:setVisible(true)
        if GameScene.antiqueResultType == 1000 then
            self.coveritems["currentPrice"]:setString(self:getCurrentPrice()..gameConfig.strings:string_common("activityAuction", 5))
        elseif GameScene.antiqueResultType == 1001 then
            self.coveritems["currentPrice"]:setString(self:getCurrentPrice())
        end
    else
        self.coveritems.coinIcon:setPositionX(-48)
        self.coveritems["currentPrice"]:setString("")
        self.coveritems.coinIcon:setVisible(false)
    end
end

function auction.setStartPrice(self)
    if self.auctionId then
        local _startPrice = self:getStartPrice()

        self:setCoinIcon(_startPrice)
        self.coveritems.coinIcon:setVisible(true)

        if GameScene.antiqueResultType == 1000 then
            self.coveritems["currentPrice"]:setString(_startPrice..gameConfig.strings:string_common("activityAuction", 5))
        elseif GameScene.antiqueResultType == 1001 then
            self.coveritems["currentPrice"]:setString(_startPrice)
        end
    end
end

function auction.setCoinIcon(self, price)
    if price > 10000 then
        self.coveritems.coinIcon:setPositionX(-115)
    elseif price > 1000 then
        self.coveritems.coinIcon:setPositionX(-98)
    elseif price > 100 then
        self.coveritems.coinIcon:setPositionX(-80)
    elseif price > 10 then
        self.coveritems.coinIcon:setPositionX(-65)
    elseif price > 0 then
        self.coveritems.coinIcon:setPositionX(-48)
    end

    if GameScene.antiqueResultType == 1000 then
        setSpriteFrameByName(self.coveritems.coinIcon, "obj_s_coin")
    elseif GameScene.antiqueResultType == 1001 then
        setSpriteFrameByName(self.coveritems.coinIcon, "obj_s_gold")
    end
end

function auction.getStartPrice(self)
    if GameScene.antiqueResultType == 1000 then
        return self.antiqueOriginalItem[tostring(self.auctionId)].normPrice / 10000
    elseif GameScene.antiqueResultType == 1001 then
        return self.antiqueOriginalItem[tostring(self.auctionId)].normPrice
    end
end

function auction.getCurrentPrice(self)
    if self.currentRound and self.currentRound >= 0 then
        if GameScene.antiqueResultType == 1000 then
            return self.auctionQueue[tostring(self.currentRound)].price / 10000
        elseif GameScene.antiqueResultType == 1001 then
            return self.auctionQueue[tostring(self.currentRound)].price
        end
    else
        return ""
    end
end

-- npc 动画
function auction.setNpcAnimation(self, id, animationType, isInit)
    if isInit then
        local _node = self.antiqueNpcAnimation[tostring(id)].spinenode
        self.coveritems[_node]:removeAllChildrenWithCleanup(true)
        local _spineName = self.antiqueNpcAnimation[tostring(id)].animationccb
        self.npcSpine[id] = CCSkeletonAnimation:create(_spineName.."/".._spineName..".json", _spineName.."/".._spineName..".atlas", 1)
    end

    if animationType == self.spineType[1] then
        self.npcSpine[id]:setAnimation(animationType, true, 0)
    else
        self.npcSpine[id]:setAnimation(animationType, false, 0)
        self.npcSpine[id]:addAnimation(self.spineType[1], true, 0, 0)
    end
    self.npcSpine[id]:setScale(1.0)
    self.npcSpine[id]:setPosition(0,0)

    if isInit then
        local _node = self.antiqueNpcAnimation[tostring(id)].spinenode
        self.coveritems[_node]:addChild(self.npcSpine[id])
    end
end

function auction.setAuctionType(self, antiueIsShow, clinchIsShow, animationType, isSetAnimationType)
    self:setAddAntiueBtnIsShow(antiueIsShow)
    self:setClinchBtnIsShow(clinchIsShow)

    if animationType then
        self:chooseAntiqueAnimation(animationType)
    end

    if isSetAnimationType == true then
        self:setAnimaitonTimer()
    end
end

function auction.setAddAntiueBtnIsShow(self, isShow)
    if self and self.coveritems1 and self.coveritems1["addAntiqueIcon"] then
        self.coveritems1["addAntiqueIcon"]:setVisible(isShow)
    end

    if self and self.coveritems1 and self.coveritems1["chooseAntiqueBtn"] then
        self.coveritems1["chooseAntiqueBtn"]:setVisible(isShow)
    end

    if self and self.coveritems1 and self.coveritems1["yijianNode"] then
        self.coveritems1["yijianNode"]:setVisible(isShow)
    end
end

function auction.setClinchBtnIsShow(self, isShow)
    if self and self.coveritems1 and self.coveritems1["resultBtn"] then
        self.coveritems1["resultBtn"]:setVisible(isShow)
    end
end

function auction.chooseAntiqueAnimation(self, animationType)
    self.coveritems1["chooseAntiqueNode"]:removeAllChildrenWithCleanup(true)

    local _ccbNode, _ccItems = CCBReaderLoad("activitygudong/gudongfangru.ccbi", nil, true, "gudongfangru")
    self.coveritems1["chooseAntiqueNode"]:addChild(_ccbNode)
    local _ccbAntiqueNode, _ccbAntiqueItem = CCBReaderLoad("UIEffect/gudong/"..self:getAntiqueCCB(), nil, true, self:getAntiqueCCB())
    _ccItems.antiqueNode:addChild(_ccbAntiqueNode)

    local _playAnimation = getAnimationManager(_ccItems)
    
    if animationType == 1 then
        --动画完成回调
        _playAnimation:setAnimationCompletedCallback(function()
            _playAnimation:runAnimationsForSequenceNamed("free")
            local _ccbBillBoardNode, _ccBillBillBoardItems = CCBReaderLoad("activitygudong/gudong_gaoshipai.ccbi", nil, true, "gudong_gaoshipai")
            self.coveritems.billBoard:addChild(_ccbBillBoardNode)

            local _playAnimation1 = getAnimationManager(_ccBillBillBoardItems)
            local _name = self.antiqueOriginalItem[tostring(self.auctionId)].name
            local _str1 = gameConfig.strings:string_common("activityAuction", 7)
            local _startPrice = self:getStartPrice()
            local _str2 = ""

            if GameScene.antiqueResultType == 1000 then
                _str2 = gameConfig.strings:string_common("activityAuction", 5)
            end

            ui.setLabelString(_ccBillBillBoardItems.name, _name, 18)
            _ccBillBillBoardItems.priceTxt:setString(_str1)

            if GameScene.antiqueResultType == 1000 then
                setSpriteFrameByName(_ccBillBillBoardItems.coinIcon, "obj_s_coin")
            elseif GameScene.antiqueResultType == 1001 then
                setSpriteFrameByName(_ccBillBillBoardItems.coinIcon, "obj_s_gold")
            end

            _ccBillBillBoardItems.coinIcon:setVisible(true)
            _ccBillBillBoardItems.price:setString(_startPrice.._str2)
            _playAnimation1:setAnimationCompletedCallback(function()
                self:setStartPrice()
                self.coveritems.billBoard:removeAllChildrenWithCleanup(true)
            end)
            _playAnimation1:runAnimationsForSequenceNamed("play")
        end)
        _playAnimation:runAnimationsForSequenceNamed("play")
    elseif animationType == 2 then
        _playAnimation:runAnimationsForSequenceNamed("free")
    end

    local _playAntiqueAnimation = getAnimationManager(_ccbAntiqueItem)
    _playAntiqueAnimation:runAnimationsForSequenceNamed("Default Timeline")
end

function auction.getAntiqueCCB(self)
    for i = 1, table.getTableLength(self.antiqueItem) do
        if self.antiqueItem[i].cid == self.auctionId then
            return self.antiqueItem[i].ccb_name
        end
    end
end

function auction.setAnimaitonTimer(self)
    if self.currentRound >= 0 then
        if gameTimer.times["activityAuctionTimer"] == nil then
            gameTimer:rigistTime("activityAuctionTimer", tonumber(999999))
            gameTimer:rigistTimeFunc("activityAuctionTimer", function()
                self:getRound()
                self.closeClinchBtn = self.closeClinchBtn - 1

                if self.closeClinchBtn == 0 then
                    -- if GameScene.layers["activity"].module.pageTable[tonumber(self.activityTimeId)] and
                    --     GameScene.layers["activity"].module.pageTable[tonumber(self.activityTimeId)].module.show then

                    if GameScene.layers["antiqueAuction"].show then
                        gameTouch:clickprofbytime(11)-- 成交按钮不可点击
                        self:setAddAntiueBtnIsShow(false)
                        self:setClinchBtnIsShow(false)
                        
                        self.isCanClick = false
                        self.closeClinchBtn = -1

                        self.currentRound = self.maxRound
                        self:Appraiser()
                        GameScene.auctionPastRound = nil
                        gameTimer:UnrigistTime("activityAuctionTimer")
                        gameTimer:UnrigistTimeFunc("activityAuctionTimer")
                        self.isAppraiser = true
                    end
                end

                if GameScene.auctionPastRound and 
                   GameScene.auctionPastRound ~= self.currentRound and
                   gamedata:time() >= self.timeLine[self.currentRound].bidderStart then
                    GameScene.auctionPastRound = self.currentRound

                    -- 拍卖进行中
                    if self.currentRound > 0 and self.currentRound ~= self.maxRound then
                        if self.maxRound - self.currentRound == 1 then
                            self.closeClinchBtn = 2
                        end

                        -- if GameScene.layers["activity"].module.pageTable[tonumber(self.activityTimeId)] and
                        --    GameScene.layers["activity"].module.pageTable[tonumber(self.activityTimeId)].module.show then
                        if GameScene.layers["antiqueAuction"].show then
                            self:setAddAntiueBtnIsShow(false)
                            self:setClinchBtnIsShow(true)

                            -- 叫价
                            self:setBidding(self.currentRound)

                            -- 喊话
                            self:setBiddingDialogue(self.currentRound)
                            self:setNpcDialogue()
                        end
                    -- 鉴定师出现
                    -- elseif self.currentRound > 0 and self.currentRound == self.maxRound then
                    --     self:Appraiser()
                    --     GameScene.auctionPastRound = nil
                    --     gameTimer:UnrigistTime("activityAuctionTimer")
                    --     gameTimer:UnrigistTimeFunc("activityAuctionTimer")
                    --     self.isAppraiser = true
                    end
                else
                    if self.currentRound > 0 and self.currentRound == self.maxRound and self.isAppraiser ~= true then
                        self:Appraiser()
                        GameScene.auctionPastRound = nil
                        gameTimer:UnrigistTime("activityAuctionTimer")
                        gameTimer:UnrigistTimeFunc("activityAuctionTimer")
                        self.isAppraiser = true
                    end
                end
            end)
        end
    end
end

-- 叫价
function auction.setBidding(self, round)
    self:setCurrentPrice()

    self:setNpcAnimation(self.timeLine[self.currentRound].bidderNpcId, self.spineType[2])
end

-- 叫价人喊话
function auction.setBiddingDialogue(self, round)
    local _currentNpc = self.timeLine[self.currentRound].bidderNpcId
    local _currentDialogue = self.antiqueNpcAnimation[tostring(_currentNpc)]
    local _priceType = 0
    local _priceDiscrimination = 0

    if round == 1 then

        _priceDiscrimination = self:getCurrentPrice()
    else
        if GameScene.antiqueResultType == 1000 then
            _priceDiscrimination = self:getCurrentPrice() - self.auctionQueue[tostring(round - 1)].price / 10000
        elseif GameScene.antiqueResultType == 1001 then
            _priceDiscrimination = self:getCurrentPrice() - self.auctionQueue[tostring(round - 1)].price
        end
    end

    if round == self.maxRound then
        _priceType = 1
    else
        local _diffPrice = self:getStartPrice() * self.antiqueAppraisal[tostring(self.AppraisalType)][tostring(round)]["senior"]

        if _priceDiscrimination < _diffPrice then
            _priceType = 0
        else
            _priceType = 1
        end
    end

    local _price = ""

    if GameScene.antiqueResultType == 1000 then
        _price = string.format(_currentDialogue.voice, self:getCurrentPrice()..gameConfig.strings:string_common("activityAuction", 5))
    else
        _price = string.format(_currentDialogue.voice, self:getCurrentPrice())
    end
    
    self:setDialogueAnimation1(_currentNpc, 0, self.timeLine[self.currentRound].bidderEnd - self.timeLine[self.currentRound].bidderStart, _price, _priceType, round)
end

-- npc起哄或嘲讽
function auction.setNpcDialogue(self)
    local _bidderNpcId = self.timeLine[self.currentRound].bidderNpcId
    local _npcId = self.timeLine[self.currentRound].npcId
    local _currentDialogue = self.antiqueNpcAnimation[tostring(_bidderNpcId)]
    local _startTime = self.timeLine[self.currentRound].npcStart - self.timeLine[self.currentRound].bidderStart
    local _endTime = self.timeLine[self.currentRound].npcEnd - self.timeLine[self.currentRound].npcStart

    -- 起哄
    if _currentDialogue["action".._npcId] == 1 then
        self:setDialogueAnimation2(_npcId, _startTime, _endTime, _currentDialogue["say".._npcId], self.spineType[3])
    -- 嘲讽
    elseif _currentDialogue["action".._npcId] == 2 then
        self:setDialogueAnimation2(_npcId, _startTime, _endTime, _currentDialogue["say".._npcId], self.spineType[4])
    end
end

function auction.setDialogueAnimation1(self, npcId, startTime, endTime, dialogue, priceType, round)
    local _direction = "L"
    if self.antiqueNpcAnimation[tostring(npcId)].direction == 0 then
        _direction = "L"
    elseif self.antiqueNpcAnimation[tostring(npcId)].direction == 1 then
        _direction = "R"
    end

    local _ccbNode, _ccItems = CCBReaderLoad("activitygudong/renwuduihua_".._direction..".ccbi", nil, true, "renwuduihua_".._direction)
    self.coveritems["dialogueNode"]:addChild(_ccbNode)
    _ccbNode:setPosition(self.coveritems["dialogueNode"..npcId]:getPosition())

    _ccItems["dialog".._direction]:setString(dialogue)
    _ccItems["dialog".._direction]:setFontSize(45)

    if priceType == 0 then
        _ccItems["dialog".._direction]:setColor(ccc3(148,82,0))
    elseif priceType == 1 then
        _ccItems["dialog".._direction]:setColor(ccc3(255,147,0))
    end

    local _playAnimation = getAnimationManager(_ccItems)

    _playAnimation:runAnimationsForSequenceNamed("open")
    _playAnimation:setAnimationCompletedCallback(function()
        if priceType == 0 then
            _playAnimation:runAnimationsForSequenceNamed("stand")
        elseif priceType == 1 then
            _playAnimation:runAnimationsForSequenceNamed("stand_big")
        end
    end)
    
    self.coveritems["dialogueNode"..npcId]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(endTime), CCCallFunc:create(function()
        if _ccItems then
            local _playAnimation1 = getAnimationManager(_ccItems)
            if _playAnimation1 then
                _playAnimation1:setAnimationCompletedCallback(function()
                    self.coveritems["dialogueNode"]:removeChild(_ccbNode, true)
                end)
                _playAnimation1:runAnimationsForSequenceNamed("close")
            end
        end
        
        if npcId == 0 then
            -- 播放鉴定动画
            self:identify()
        end
    end)))
end

function auction.setDialogueAnimation2(self, npcId, startTime, endTime, dialogue, spineType)
    local _playAnimation = nil
    
    local _startCb = function()
        self:setNpcAnimation(npcId, spineType)

        local _direction = "L"
        if self.antiqueNpcAnimation[tostring(npcId)].direction == 0 then
            _direction = "L"
        elseif self.antiqueNpcAnimation[tostring(npcId)].direction == 1 then
            _direction = "R"
        end

        local _ccbNode, _ccItems = CCBReaderLoad("activitygudong/renwuduihua_".._direction..".ccbi", nil, true, "renwuduihua_".._direction)
        self.coveritems["dialogueNode"]:addChild(_ccbNode)
        _ccbNode:setPosition(self.coveritems["dialogueNode"..npcId]:getPosition())
        _ccbNode:setZOrder(self.dialogueZorder)
        self.dialogueZorder = self.dialogueZorder + 50
        _ccItems["dialog".._direction]:setString(dialogue)
        _ccItems["dialog".._direction]:setFontSize(45)
        _ccItems["dialog".._direction]:setColor(ccc3(148,82,0))

        _playAnimation = getAnimationManager(_ccItems)
        _playAnimation:runAnimationsForSequenceNamed("open")
        _playAnimation:setAnimationCompletedCallback(function()
            _playAnimation:runAnimationsForSequenceNamed("stand")
        end)

        self.coveritems["dialogueNode"..npcId]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(endTime), CCCallFunc:create(function()
            if _ccItems then
                local _playAnimation1 = getAnimationManager(_ccItems)
                if _playAnimation1 then
                    _playAnimation1:setAnimationCompletedCallback(function()
                        self.coveritems["dialogueNode"]:removeChild(_ccbNode, true)
                    end)
                    _playAnimation1:runAnimationsForSequenceNamed("close")
                end
            end
        end)))
    end
    
    self.coveritems["dialogueNode"..npcId]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(startTime), CCCallFunc:create(function()
         _startCb()
    end)))
end

-- 鉴定师
function auction.Appraiser(self)
    -- if GameScene.layers["activity"].module.pageTable[tonumber(self.activityTimeId)] and GameScene.layers["activity"].module.pageTable[tonumber(self.activityTimeId)].module.show then
    if GameScene.layers["antiqueAuction"].show then
        gameWindows:closeWindow("activityAuctionRule")
        gameWindows:closeWindow("activityAuctionRecording")
        self.coveritems["dialogueNode"..0]:removeAllChildrenWithCleanup(true)
        gameTouch:clickprofbytime(11)-- 成交按钮不可点击
        self:setAddAntiueBtnIsShow(false)
        self:setClinchBtnIsShow(false)
        -- 鉴定师叫价
        self:setBidding(self.maxRound)
        self:setBiddingDialogue(self.maxRound)
    else
        if self.result == 0 then
            UIRequest({type = 5414})
        else
            local _resultPrice = self:getCurrentPrice()
            local _priceType = GameScene.antiqueResultType

            if _priceType == 1000 then
                _resultPrice = _resultPrice * 10000
            end 

            UIRequest({type = 5414, ResultType = 1, priceType = _priceType, resultPrice = _resultPrice})
        end
    end
end

-- 鉴定
function auction.identify(self)
    UIRequest({type = 5414})
    -- 鉴定成功动画
    if self.result == 1 then
        self:setIdentifyAnimation("success")
    -- 鉴定失败动画
    else
        self:setIdentifyAnimation("failed")
    end
end

-- 鉴定动画
function auction.setIdentifyAnimation(self, animationType)
    self.coveritems["jiandingNode"]:removeAllChildrenWithCleanup(true)
    
    local _ccbNode, _ccItems = CCBReaderLoad("activitygudong/gudongjianding.ccbi", nil, true, "gudongjianding")
    self.coveritems["jiandingNode"]:addChild(_ccbNode)
    local _ccbAntiqueNode, _ccbAntiqueItem = CCBReaderLoad("UIEffect/gudong/"..self:getAntiqueCCB(), nil, true, self:getAntiqueCCB())
    _ccItems.antiqueNode:addChild(_ccbAntiqueNode)

    -- setSpriteFrameByName(_ccItems.antiqueIcon, self.props[tostring(self.auctionId)].icon)
    local _playAnimation = getAnimationManager(_ccItems)
    local _playAntiqueAnimation = getAnimationManager(_ccbAntiqueItem)
    --动画完成回调
    local _resultPrice = self:getCurrentPrice()
    local _priceType = GameScene.antiqueResultType

    _playAnimation:setAnimationCompletedCallback(function()
        _playAnimation:runAnimationsForSequenceNamed(animationType)
        _playAnimation:setAnimationCompletedCallback(function()
            gameTouch:setClickProf(false)
            local _cb = function()
                UIRequest({type = 5410})
            end

            if animationType == "success" then
                if _priceType == 1000 then
                    showRewardPopupWindow({{cid = 1000, num = _resultPrice * 10000, order = 1}}, nil, _cb)
                elseif _priceType == 1001 then
                    showRewardPopupWindow({{cid = 1001, num = _resultPrice, order = 1}}, nil, _cb)
                end   
            else
                _cb()
            end
        end)
    end)
    _playAnimation:runAnimationsForSequenceNamed("play")
    _playAntiqueAnimation:runAnimationsForSequenceNamed("Default Timeline")
end

-- 通用按钮
function auction.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return auction