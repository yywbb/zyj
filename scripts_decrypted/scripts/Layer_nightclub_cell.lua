--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local clubcell = {
    rootNode = nil,
    rootItems = nil,

    m_iCellType = nil,
    m_iIndex = nil,

    m_iSeleteTimes = nil, -- 选择时间
    m_iSeleteTypes = nil, -- 选择类型

    m_tTimeConfig = nil,

    titleCellSize = {x = 180,y = 180},
    fwCellSize = {x = 960,y = 140}
}


function clubcell.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("nightclub/nightclub", nil, true, "clubcell")
    parent:addChild(self.rootNode)
    self.rootAnimate = getAnimationManager(self.rootItems)

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.downnode:setPositionY(160)

    self.rootItems.backButton:setTouchPriority(-105)
    self.rootItems.backButton:setSwallowsTouch(true)
    self.rootItems.backButton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        gameTouch:clickprofbytime(0.5)
        GameScene:shiftLayer("nightclub","up",{_pointy = param._pointy})
    end, CCControlEventTouchUpInside)

    self.m_oSpecialNode,self.m_oSpecialRoot = CCBReaderLoad("nightclub/nightclub_special", nil, true, "nightclub_special")
    self.m_oSpecialAnimation = getAnimationManager(self.m_oSpecialRoot)
    self.m_oSpecialNode:setVisible(false)
    self.rootItems.midNode:addChild(self.m_oSpecialNode)

    self.rootItems.choose:setSwallowsTouch(false)
    self.rootItems.type1bt:setSwallowsTouch(false)
    for i=1,3 do
        self.rootItems["type3_bt"..i]:setSwallowsTouch(false)
    end
    self.rootItems["type3_bt"]:setSwallowsTouch(false)
    self.rootItems["type3_choose"]:setSwallowsTouch(false)
    self.rootItems["type4_bt4"]:setSwallowsTouch(false)


    self.m_tStandMan = param._stand

    self:resetStage(param)
end

function getRandomNum(destMax,destBi)
    return 1+(math.floor((math.random()*destMax))%destBi)
end

function clubcell.resetStage(self,data)
    self.m_iCellType = data._data["1"]
    self.m_iIndex = data._index
    self.m_iSelet = data._selet
    local tmpConfig = gamedata.config.tiantingyz_guanqia[tostring(self.m_iIndex)]
    setSpriteFrameByName(self.rootItems.m_oBgSpr, tmpConfig.picture..".jpg","public/bg")
    setSpriteFrameByName(self.rootItems.m_oTitlePic, tmpConfig.word_icon,"public/publicsprite")
    if data._selet then
        self.m_iCellType = 3
        self:reloaddata()
    else
        UIRequest({type = 4501,_id = self.m_iIndex})
    end
end

function clubcell.reloaddata(self,data)
    if self.stepGneral1 ~= nil then
        self.stepGneral1:removeFromParentAndCleanup(true)
        self.stepGneral1 = nil
    end
    if data then
        self.data = data
        self.m_iCellType = data["1"]
        if self.m_iSelet == nil then
            if self.m_iCellType == 3 then
                self.m_iCellType = 4
            end
        end
        self:ReloadGenerals(data.generals)
    end

    --
    local generalsdata = {}
    if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
        generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
    end

    -- printT(data,"data====:")
    -- print("self.m_iCellType===:",self.m_iCellType,self.m_iIndex)
    self.rootAnimate:runAnimationsForSequenceNamed(tostring(self.m_iCellType))
    self.rootItems.type4_fight:setContentSize(CCSizeMake(0,0))
    local tmpConfig = gamedata.config.tiantingyz_guanqia[tostring(self.m_iIndex)]
    if self.m_iCellType == 1 then
        -- printT(tmpConfig,"tmpConfig====:")
        local tmpQuName = ui.getIDandNUMs(tmpConfig["item"])
        local tmpEnemyId = tmpConfig["image"]
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(tmpEnemyId)].animationid)].name
        self.stepGneral1 = CCNode:create()
        local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral1:addChild(general)
        self.stepGneral1:setPosition(0,0)
        self.rootItems.heronode:addChild(self.stepGneral1)

        self.rootItems.wordlabel:setString(tmpConfig.desc)

        self.rootItems.type1bt:setTouchPriority(-105)
        self.rootItems.type1bt:setSwallowsTouch(true)
        self.rootItems.type1bt:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 4502,_id = self.m_iIndex,_items = self.m_iIndex})
        end, CCControlEventTouchUpInside)
        self.rootItems.type1info:setString(gameConfig.strings:string_common("nightclub",9)..tmpConfig.Introduction)
        ui.setLabelString(self.rootItems.type1btlab,gameConfig.strings:string_common("friendcopy",0),14)
        ui.setLabelString(self.rootItems.type1tips,gameConfig.strings:string_common("zhuxiantai",38)..tmpConfig.power,14)
        for i=1,3 do
            if tmpQuName[i] then
                ui.setNewIconName(self.rootItems,tmpQuName[i],i-1)
            else
                self.rootItems["type1_o_icon"..i]:setVisible(false)
            end
        end
    elseif self.m_iCellType == 2 then
        self.m_tLowTable = {}
        self.m_tHigTable = {}
        local tmpLowItem1 = ui.getNeedWithFuhao(tmpConfig.drop1_low,";")
        local tmpHigItem2 = ui.getNeedWithFuhao(tmpConfig.drop1_up,";")
        for i,v in ipairs(tmpLowItem1) do
            self.m_tLowTable[tostring(i)] = {ui.getIDandNUM(gamedata.config.tiantingyz_diaoluo[v].item)}
        end
        for i,v in ipairs(tmpHigItem2) do
            self.m_tHigTable[tostring(i)] = {ui.getIDandNUM(gamedata.config.tiantingyz_diaoluo[v].item)}
        end

        self.rootItems.choose:setTouchPriority(-105)
        self.rootItems.choose:setSwallowsTouch(true)
        self.rootItems.choose:addHandleOfControlEvent(function()
            local function callback(destSelet)
                if destSelet ~= nil then
                    local tmpPassData = {}
                    tmpPassData["1"] = "3"
                    tmpPassData["2"] = "3"
                    self:resetStage({_index = self.m_iIndex,_data = tmpPassData,_selet = destSelet})
                end
            end
            gameWindows:openWindow("clubchoose",self.generalsdata,callback)
        end, CCControlEventTouchUpInside)
        local function dealOneBt(destInfo,destIndex)
            if destInfo then
                self.rootItems["type2_bf"..destIndex]:setVisible(true)
                ui.setNewIconName(self.rootItems,{cid = destInfo[1]},destIndex-1)
            else
                self.rootItems["type2_bf"..destIndex]:setVisible(false)
            end
        end
        local tmpBeganIndex = 3
        for i=1,4 do
            dealOneBt(self.m_tLowTable[tostring(i)],tmpBeganIndex+i)
        end
        tmpBeganIndex = 7
        for i=1,4 do
            dealOneBt(self.m_tHigTable[tostring(i)],tmpBeganIndex+i)
        end
    elseif self.m_iCellType == 3 then
        self.rootItems.choose:setTouchPriority(-105)
        self.rootItems.choose:setSwallowsTouch(true)
        self.rootItems.choose:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            local function callback(destSelet)
                if destSelet ~= nil then
                    local tmpPassData = {}
                    tmpPassData["1"] = "3"
                    tmpPassData["2"] = "3"
                    self:resetStage({_index = self.m_iIndex,_data = tmpPassData,_selet = destSelet})
                end
            end
            gameWindows:openWindow("clubchoose",self.generalsdata,callback)
        end, CCControlEventTouchUpInside)
        self.m_tInfoTable = {}
        local tmpLowItem1 = ui.getNeedWithFuhao(tmpConfig.drop1_low,";")
        local tmpHigItem2 = ui.getNeedWithFuhao(tmpConfig.drop1_up,";")
        local tII = 1
        local function insertOneItem(destItem)
            if destItem then
                local tmpCid ,tmpNum = ui.getIDandNUM(destItem)
                local tmpCandoThis = true
                for k,v in pairs(self.m_tInfoTable) do
                    if tmpCid == v.cid then
                        tmpCandoThis = false
                        break
                    end
                end
                if tmpCandoThis then
                    tII = tII + 1
                    self.m_tInfoTable[tostring(tII)] = {cid = tmpCid}
                end
            end
        end
        for i,v in ipairs(tmpHigItem2) do
            insertOneItem(gamedata.config.tiantingyz_diaoluo[v].item)
        end
        for i,v in ipairs(tmpLowItem1) do
            insertOneItem(gamedata.config.tiantingyz_diaoluo[v].item)
        end
        if self.m_iSelet then
            local tmpEnemyId = tonumber(self.generalsdata[tostring(self.m_iSelet)].cid) 
            local fcid = gamedata.getOriginCid(tmpEnemyId)
            self.m_tInfoTable[tostring(1)] = {cid = gamedata:findFragmentCid(fcid),
                                                num = gamedata.config.tiantingyz_time[tostring(1)]["soul_small"]
                                                .."~"..gamedata.config.tiantingyz_time[tostring(1)]["soul_big"]}
            -- 设置头像
            local generalConfig = gamedata.config.general[tostring(tmpEnemyId)]
            local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
            if self.generalsdata[tostring(self.m_iSelet)].illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, self.generalsdata[tostring(self.m_iSelet)])
            end
            -- local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(tmpEnemyId)].animationid)].name
            self.stepGneral1 = CCNode:create()
            local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            general:setAnimation("stand",true,0)
            general:setScale(1.6)
            self.stepGneral1:addChild(general)
            self.stepGneral1:setPosition(0,0)
            self.rootItems.heronode:addChild(self.stepGneral1)
        end

        -- 对话
        local tmpChats = ui.getNeedWithFuhao(tmpConfig.dialogue_id,";")
        local tmpIndexs = getRandomNum(#tmpChats,100)
        self.rootItems.wordlabel:setString(gamedata.config.tiantingyz_duihua[tostring(tmpChats[tmpIndexs])].desc)

        self.m_tTimeConfig = {}
        for k,v in pairs(gamedata.config.tiantingyz_time) do
            local tmpBigIndex = math.ceil(tonumber(k)/3)
            local tmpLitIndex = (tonumber(k)%3)
            if tmpLitIndex == 0 then
                tmpLitIndex = 3
            end
            if not self.m_tTimeConfig[tostring(tmpBigIndex)] then
                self.m_tTimeConfig[tostring(tmpBigIndex)] = {}
            end
            self.m_tTimeConfig[tostring(tmpBigIndex)][tostring(tmpLitIndex)] = {
                _time = tonumber(v.time),
                _shaq = tonumber(v.murderous),
                _gold = tonumber(v.Ingots),
            }
        end
        self:update3Times(1)
        self:update3Type(1)
        --self:updateItem(self.m_iCellType,self.m_tInfoTable)
        for i=1,3 do
            ui.setLabelString(self.rootItems["type3_lable"..i],string.format(gameConfig.strings:string_common("nightclub",1),self.m_tTimeConfig[tostring(self.m_iSeleteTypes)][tostring(i)]._time),14)
            self.rootItems["type3_bt"..i]:setTouchPriority(-105)
            self.rootItems["type3_bt"..i]:setSwallowsTouch(true)
            self.rootItems["type3_bt"..i]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                self:update3Times(i)
            end, CCControlEventTouchUpInside)
        end

        ui.setLabelString(self.rootItems["type3_lable"],gameConfig.strings:string_common("nightclub",5),14)
        self.rootItems["type3_bt"]:setTouchPriority(-105)
        self.rootItems["type3_bt"]:setSwallowsTouch(true)
        self.rootItems["type3_bt"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            local tmpTimeIndex = (self.m_iSeleteTypes - 1) * 3 + self.m_iSeleteTimes
            UIRequest({type = 4503,_id = self.m_iIndex,_time = tmpTimeIndex,
                                   _cid = self.generalsdata[tostring(self.m_iSelet)].iid,
                                   _shaNum = self.m_i3InsertNum,
                                   _shaType = self.m_i3InsertType})
        end, CCControlEventTouchUpInside)

        self.rootItems["type3_left"]:setTouchPriority(-105)
        self.rootItems["type3_left"]:setSwallowsTouch(true)
        self.rootItems["type3_left"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.NavigationTableView then
                local tmpPoint = self.NavigationTableView:getContentOffset()
                local tmpWidth = self.rootItems.type3_scroll:getContentSize().width - table.getTableLength(self.realPageTable) * self.titleCellSize.x
                local tmpMoveX = tmpWidth
                if tmpPoint.x > tmpWidth then
                    if tmpPoint.x - self.titleCellSize.x < tmpWidth then
                        tmpMoveX = tmpPoint.x + (tmpWidth - tmpPoint.x)
                    else
                        tmpMoveX = tmpPoint.x - self.titleCellSize.x
                    end
                end
                self.NavigationTableView:setContentOffsetInDuration(ccp(tmpMoveX,0),0.5)
            end
        end, CCControlEventTouchUpInside)

        self.rootItems["type3_right"]:setTouchPriority(-105)
        self.rootItems["type3_right"]:setSwallowsTouch(true)
        self.rootItems["type3_right"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.NavigationTableView then
                local tmpPoint = self.NavigationTableView:getContentOffset()
                local tmpMoveX = 0
                if tmpPoint.x < 0 then
                    if self.titleCellSize.x + tmpPoint.x < 0 then
                        tmpMoveX = tmpPoint.x + self.titleCellSize.x
                    end
                end
                self.NavigationTableView:setContentOffsetInDuration(ccp(tmpMoveX,0),0.5)
            end
        end, CCControlEventTouchUpInside)

        self.rootItems["type3_choose"]:setTouchPriority(-105)
        self.rootItems["type3_choose"]:setSwallowsTouch(true)
        self.rootItems["type3_choose"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            local function callback(destSelet)
                self:update3Type(destSelet)
            end
            gameWindows:openWindow("clubselet",self.m_iSeleteTypes,callback)
        end, CCControlEventTouchUpInside)
    elseif self.m_iCellType == 4 then
        self.rootItems.type4_fight:setContentSize(CCSizeMake(self.fwCellSize.x,self.fwCellSize.y))
        self.m_tInfoTable = {}
        self.m_tFightTable= {}
        self.m_iEnemyCid = nil
        if data["2"] and data["2"] > 0 then
            gameTouch:clickprofbytime(3.5)
            self.m_oSpecialAnimation:setAnimationCompletedCallback(function()
                self.m_oSpecialNode:setVisible(false)
                gameWindows:openWindow("clubchance",{_index = self.m_iIndex,_type = data["2"]})
            end)
            self.m_oSpecialAnimation:runAnimationsForSequenceNamed("loop")
            self.m_oSpecialNode:setVisible(true)
        end
        local tmpEnemyId = data["5"]
        local tmpEnemyNum = data["8"]
        local tmpTotalTimes = data["4"]
        self.seleTotalTimes = gamedata.config.tiantingyz_time[tostring(tmpTotalTimes)]["income_time"] * 60

        if tmpEnemyId and tmpEnemyId > 0 then
            local fcid = gamedata.getOriginCid(tmpEnemyId)
            self.m_iEnemyCid = tonumber(tmpEnemyId)
            self.m_tInfoTable[tostring(1)] = {cid = gamedata:findFragmentCid(fcid),num = tmpEnemyNum}
            self.m_tFightTable[tostring(1)] = gameConfig.strings:string_common("nightclub",21)
            -- 设置头像
            local generalConfig = gamedata.config.general[tostring(tmpEnemyId)]
            local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
            if generalConfig.fashion_id == 0 then --非时装
                local gdata = {}
                for k,v in pairs(generalsdata) do
                    if tmpEnemyId  == v.cid then
                        if v.illusionGeneralCid == nil then
                            gdata = v
                        end
                        break
                    end
                end
                if next(gdata) then
                    generalName = ui.getGeneralAnimationid(generalName, gdata)
                end
            end
            -- local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(tmpEnemyId)].animationid)].name
            self.stepGneral1 = CCNode:create()
            local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            general:setAnimation("stand",true,0)
            general:setScale(1.6)
            self.stepGneral1:addChild(general)
            self.stepGneral1:setPosition(0,0)
            self.rootItems.heronode:addChild(self.stepGneral1)
        end

        local tmpLowItem1 = ui.getNeedWithFuhao(tmpConfig.drop1_low,";")
        local tmpHigItem2 = ui.getNeedWithFuhao(tmpConfig.drop1_up,";")
        local tII = 1
        local fII = 1
        local tmpLens = #tmpLowItem1
        for k,v in pairs(data) do
            local tmpIndex = tonumber(k)
            if tmpIndex then
                if tmpIndex == 6 then
                    if v > 0 then
                        self.rootItems["type4_lable4"]:setVisible(true)
                        ui.addGray("CCControlButton",self.rootItems["type4_bt4"])
                        self:updatetimeFunc(self.rootItems["type4_lable4"],self.rootItems["type4_lable2"],v)
                    else
                        gameTimer.times["nightcell_1"] = 0
                        ui.removeGray("CCControlButton",self.rootItems["type4_bt4"])
                        ui.setLabelString(self.rootItems["type4_lable2"],"00:00:00",14)
                        self.rootItems["type4_lable4"]:setVisible(false)
                    end
                elseif tmpIndex > 8 then
                    if tmpIndex % 2 == 0 then
                        tII = tII + 1
                        local tmpCid ,tmpNum = ui.getIDandNUM(gamedata.config.tiantingyz_diaoluo[tostring(v)].item)
                        if data["3"] ~= 0 then
                            tmpNum = tmpNum + tmpNum
                        end
                        self.m_tInfoTable[tostring(tII)] = {cid = tmpCid,num = tmpNum}
                    else
                        fII = fII + 1
                        self.m_tFightTable[tostring(fII)] = gamedata.config.tiantingyz_zhanbao[tostring(v)].desc
                    end
                end
            end
        end

        -- 对话
        local tmpChats = ui.getNeedWithFuhao(tmpConfig.dialogue_id,";")
        local tmpIndexs = getRandomNum(#tmpChats,100)
        self.rootItems.wordlabel:setString(gamedata.config.tiantingyz_duihua[tostring(tmpChats[tmpIndexs])].desc)

        ui.setLabelString(self.rootItems["type4_lable1"],gameConfig.strings:string_common("nightclub",6),14)

        self.rootItems["type4_left"]:setTouchPriority(-105)
        self.rootItems["type4_left"]:setSwallowsTouch(true)
        self.rootItems["type4_left"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.NavigationTableView then
                local tmpPoint = self.NavigationTableView:getContentOffset()
                local tmpWidth = self.rootItems.type4_scroll:getContentSize().width - table.getTableLength(self.realPageTable) * self.titleCellSize.x
                if tmpWidth > 0 then
                    tmpWidth = 0
                end
                local tmpMoveX = tmpWidth
                if tmpPoint.x > tmpWidth then
                    if tmpPoint.x - self.titleCellSize.x < tmpWidth then
                        tmpMoveX = tmpPoint.x + (tmpWidth - tmpPoint.x)
                    else
                        tmpMoveX = tmpPoint.x - self.titleCellSize.x
                    end
                end
                self.NavigationTableView:setContentOffsetInDuration(ccp(tmpMoveX,0),1)
            end
        end, CCControlEventTouchUpInside)

        self.rootItems["type4_right"]:setTouchPriority(-105)
        self.rootItems["type4_right"]:setSwallowsTouch(true)
        self.rootItems["type4_right"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.NavigationTableView then
                local tmpPoint = self.NavigationTableView:getContentOffset()
                local tmpMoveX = 0
                if tmpPoint.x < 0 then
                    if self.titleCellSize.x + tmpPoint.x < 0 then
                        tmpMoveX = tmpPoint.x + self.titleCellSize.x
                    else
                        tmpMoveX = tmpPoint.x + self.titleCellSize.x + tmpPoint.x
                    end
                end
                self.NavigationTableView:setContentOffsetInDuration(ccp(tmpMoveX,0),1)
            end
        end, CCControlEventTouchUpInside)

        self.rootItems["type4_bt4"]:setTouchPriority(-105)
        self.rootItems["type4_bt4"]:setSwallowsTouch(true)
        self.rootItems["type4_bt4"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if gameTimer.times["nightcell_1"] and gameTimer.times["nightcell_1"] > 0 then

            else
                UIRequest({type = 4504,_id = self.m_iIndex})
            end
        end, CCControlEventTouchUpInside)
        ui.setLabelString(self.rootItems["type4_lable3"],gameConfig.strings:string_common("buttontext","lingqu"),14)
        self.m_iInfoLens = tII
        self:updateItem(self.m_iCellType,self.m_tInfoTable)
    end
end

function clubcell.ReloadGenerals(self,data)
    if data then
        local tmpBasicNum = 5000000
        self.generalsdata = {}
        local generals = {}
        for k,v in pairs(data) do
            if gamedata.config.general[tostring(v.cid)].quality > 0 then
                v.showorder = tmpBasicNum + tonumber(k) + (9 - v.quality) * 10000
                for i,p in ipairs(self.m_tStandMan) do
                    if v.ison == 2 then
                        v.showorder = v.showorder - 200000
                    elseif v.ison == 1 then
                        v.showorder = v.showorder - 100000
                    end
                    if p == v.cid then
                        v.isClub = true
                        v.showorder = v.showorder + 5000000
                    end
                end
                table.insert(generals,v)
            end
        end

        local sortByK = function(a,b)
            return a.showorder < b.showorder 
        end
        table.sort(generals, sortByK)

        for i = 1, table.getTableLength(generals) do
            self.generalsdata[tostring(i)] = generals[i]
        end
    end
end

function clubcell.play(self,data)
    self:reloaddata(data)
    -- if data.result and data.result > 0 then
    --     if self.m_iIndex then
    --         -- print("gamedata.ext.clubItems====:",self.m_iIndex)
    --         local tmpConfig = gamedata.config.tiantingyz_guanqia[tostring(self.m_iIndex)]
    --         -- printT(tmpConfig,"tmpConfig===:")
    --         local tmpQuName = gamedata.getIDandNUMs(tmpConfig["item"])
    --         showRewardPopupWindow(tmpQuName,nil,nil)
    --     end
    -- end
end

function clubcell.refresh(self,data)
    local function tmpActionDone()
        if self.m_iEnemyCid then
            for i,p in ipairs(self.m_tStandMan) do
                if p == self.m_iEnemyCid then
                    table.remove(self.m_tStandMan,i)
                    break
                end
            end
        end
        UIRequest({type = 4501,_id = self.m_iIndex})
    end
    showRewardPopupWindow(data._reward,nil,tmpActionDone)
end

function clubcell.getSizeTable(self,chats)
    local label = ui.createLabel({
        fontsize = 35,
        font = "Helvetica-Bold",
    })


    local sizeTable = {}
    local totalheight = 0

    for i,v in pairs(chats) do
        label:setString(v)
        local height = label:getContentSize().height
        local width = label:getContentSize().width

        if width > self.fwCellSize.x then
            sizeTable[tostring(i)] = {w = self.fwCellSize.x, h = math.ceil(width/self.fwCellSize.x)*height+20}
        else
            local tmpLen = string.len(v)
            sizeTable[tostring(i)] = {w = self.fwCellSize.x, h = height+20}
        end
        totalheight = totalheight + sizeTable[tostring(i)].h
    end

    return sizeTable,totalheight
end

function clubcell.updateItem(self,destType,destTable)
    if self.NavigationTableView ~= nil then
        self.FightTableView:removeAllChildrenWithCleanup(true)
        self.FightTableView:removeFromParentAndCleanup(true)
        self.FightTableView = nil
        self.m_oFristConTroller = nil
        self.NavigationTableView:removeAllChildrenWithCleanup(true)
        self.NavigationTableView:removeFromParentAndCleanup(true)
        self.NavigationTableView = nil
    end
    local tmpTimesss = 0
    if self.realPageTable then
        for k,v in pairs(self.realPageTable) do
            v = nil
        end
    end
    if self.realFightTable then
        for k,v in pairs(self.realFightTable) do
            v = nil
        end
    end
    self.realPageTable = {}
    self.realFightTable = {}
    if destType == 4 then
        tmpTimesss = self.m_iInfoLens - math.ceil(gameTimer.times["nightcell_1"]/self.seleTotalTimes)
        -- print("lailailailai =======:",self.m_iInfoLens,math.ceil(gameTimer.times["nightcell_1"]/self.seleTotalTimes))
        
        local tmpUserName = gamedata.config.general[tostring(self.data["5"])].name
        local tmpAddsIndex = 1
        for i=1,tmpTimesss do
            local tmpIndex = tostring(i)
            local tmpCandoThat = true
            for k,v in pairs(self.realPageTable) do
                if v.cid == destTable[tmpIndex].cid then
                    v.num = v.num + destTable[tmpIndex].num
                    tmpCandoThat = false
                end
            end
            if tmpCandoThat then
                self.realPageTable[tostring(tmpAddsIndex)] = {cid = destTable[tmpIndex].cid,num = destTable[tmpIndex].num}
                tmpAddsIndex = tmpAddsIndex + 1
            end
            local tmpItmeConfig = ui.IDconfig(destTable[tmpIndex].cid)
            local tmpItemName = nil
            if tmpItmeConfig.staffType == "general_fragment" then
                tmpItemName = tmpItmeConfig.name..gameConfig.strings:string_common("ui",69).."x"..destTable[tmpIndex].num
            else
                tmpItemName = tmpItmeConfig.name.."x"..destTable[tmpIndex].num
            end
            -- print("self.m_tFightTable[tmpIndex]===:",self.m_tFightTable[tmpIndex])
            self.realFightTable[tmpIndex] = string.format(self.m_tFightTable[tmpIndex],tmpUserName,tmpItemName)
        end
        self.realSizeT = self:getSizeTable(self.realFightTable)
    else
        tmpTimesss = self.m_iInfoLens
        self.realPageTable = destTable
    end
    -- print("哈哈哈哈哈进来了=====:")
    local activityTable = {}
    local NavigationHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler,tmpSprite = 0,0,nil
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_iconName2", nil, true, "new_iconName2")
                local tmpNode = CCNode:create()
                local tmpSize = cellCCB:getContentSize()
                if a1 == 0 then
                    self.m_oFristConTroller = ccbDocumentControler
                    tmpSprite = CCSprite:create("public/language/nightclub_zi_15.png")
                    tmpSprite:setAnchorPoint(ccp(0,1))
                    tmpSprite:setPosition(0,tmpSize.height)
                    tmpNode:addChild(tmpSprite)
                end
                cellCCB:addChild(tmpNode,1,10086)
                activityTable[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler,tmpSprite = tmpSprite }
            else
                first = false
                cellCCB = activityTable[a2].cellCCB
                ccbDocumentControler = activityTable[a2].ccbDocumentControler
                tmpSprite = activityTable[a2].tmpSprite
            end
            ui.setNewIconName(ccbDocumentControler,self.realPageTable[tostring(a1+1)])
            if tmpSprite then
                if a1 == 0 then
                    tmpSprite:setVisible(true)
                else
                    tmpSprite:setVisible(false)
                end
            end

            if first then
                a2:addChild(cellCCB)
                cellCCB:setAnchorPoint(ccp(0.5, 0.5))
                cellCCB:setScale(1)                
                cellCCB:setPositionY(self.titleCellSize.y/2 + 60)
                cellCCB:setPositionX(self.titleCellSize.x/2)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.realPageTable)
        elseif fn == "cellTouched" then
        elseif fn == "scrollViewDidScroll" then
            if self.NavigationTableView then
                local tmpPoints = self.NavigationTableView:getContentOffset()
                if tmpPoints.x < -self.titleCellSize.x then
                    self.m_oFristConTroller = nil
                else
                    for k,v in pairs(activityTable) do
                        if v.tmpSprite ~= nil then
                            self.m_oFristConTroller = v.ccbDocumentControler
                        end
                    end
                end
            end
        end
        return r
    end)
    local tmpBiLayer = nil
    if destType == 3 then
        tmpBiLayer = self.rootItems.type3_scroll
    elseif destType == 4 then
        tmpBiLayer = self.rootItems.type4_scroll
    end
    if tmpBiLayer ~= nil then
        self.NavigationTableView = ui.createLuaTableView({
            handle = NavigationHandle,
            viewwidth = tmpBiLayer:getContentSize().width,
            viewheight = tmpBiLayer:getContentSize().height,
            dire = 0
        })
        tmpBiLayer:addChild(self.NavigationTableView)
        self.NavigationTableView:setTouchPriority(-106)
    end

    local wordfightTable = {}
    local WFHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            r = CCSizeMake(self.fwCellSize.x, self.realSizeT[tostring(a1+1)].h)
        elseif fn == "cellAtIndex" then
            local cellCCB = 0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB = CCLabelTTF:create("","Helvetica-Bold",35)
                cellCCB:setContentSize(CCSizeMake(self.fwCellSize.x, self.realSizeT[tostring(a1+1)].h))
                cellCCB:setHorizontalAlignment(0)
                cellCCB:setVerticalAlignment(0)
                activityTable[a2] = {cellCCB=cellCCB }
                cellCCB:setAnchorPoint(ccp(0,1))
                cellCCB:setPosition(0,0)

            else
                first = false
                cellCCB = activityTable[a2].cellCCB
            end
            cellCCB:setDimensions(CCSizeMake(self.fwCellSize.x, self.realSizeT[tostring(a1+1)].h))
            cellCCB:setString(self.realFightTable[tostring(a1+1)])

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.realFightTable)
        elseif fn == "cellTouched" then
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)
    local tmpWFLayer = self.rootItems["type4_fight"]
    self.FightTableView = ui.createLuaTableView({
        handle = WFHandle,
        viewwidth = tmpWFLayer:getContentSize().width,
        viewheight = tmpWFLayer:getContentSize().height,
        dire = 1
    })
    tmpWFLayer:addChild(self.FightTableView)
    self.FightTableView:setTouchPriority(-106)
    self.FightTableView:setContentOffset(ccp(0,0))

end

function clubcell.update3Type(self,destType)
    self.m_iSeleteTypes = destType
    self.rootItems["type3_choname"]:setString(gameConfig.strings:string_common("nightclub",22))
    self.rootItems["type3_chooselab"]:setString(gameConfig.strings:string_common("nightclub",self.m_iSeleteTypes+1))
    if self.m_iSeleteTypes == 1 then
        self.rootItems["type3_chooselab"]:setColor(ccc3(93,227,90))
    elseif self.m_iSeleteTypes == 2 then
        self.rootItems["type3_chooselab"]:setColor(ccc3(70,196,255))
    else
        self.rootItems["type3_chooselab"]:setColor(ccc3(209,102,247))
    end
    self:update3Times(self.m_iSeleteTimes)
    --
    local tmpConfig = gamedata.config.tiantingyz_guanqia[tostring(self.m_iIndex)]
    local temp1 = self.m_tInfoTable and self.m_tInfoTable["1"] or {}
    self.m_tInfoTable = {}
    local tmpLowItem1 = ui.getNeedWithFuhao(tmpConfig["drop"..self.m_iSeleteTypes.."_low"],";")
    local tmpHigItem2 = ui.getNeedWithFuhao(tmpConfig["drop"..self.m_iSeleteTypes.."_up"],";")
    local tII = 1
    local function insertOneItem(destItem)
        if destItem then
            local tmpCid ,tmpNum = ui.getIDandNUM(destItem)
            local tmpCandoThis = true
            for k,v in pairs(self.m_tInfoTable) do
                if tmpCid == v.cid then
                    tmpCandoThis = false
                    break
                end
            end
            if tmpCandoThis then
                tII = tII + 1
                self.m_tInfoTable[tostring(tII)] = {cid = tmpCid}
            end
        end
    end
    for i,v in ipairs(tmpHigItem2) do
        insertOneItem(gamedata.config.tiantingyz_diaoluo[v].item)
    end
    for i,v in ipairs(tmpLowItem1) do
        insertOneItem(gamedata.config.tiantingyz_diaoluo[v].item)
    end
    self.m_tInfoTable["1"] = temp1
    --
    self:updateItem(self.m_iCellType,self.m_tInfoTable)
end

function clubcell.update3Times(self,destIndex)
    if self.m_iSeleteTimes ~= destIndex then
        if self.m_iSeleteTimes and self.m_iSeleteTimes ~= 0 then
            self.rootItems["type3_selete"..self.m_iSeleteTimes]:setVisible(false)
        end
        self.m_iSeleteTimes = destIndex
        self.rootItems["type3_selete"..self.m_iSeleteTimes]:setVisible(true)
    end
    if self.m_iSeleteTypes then
        -- print("self.m_iSeleteTypes==:",self.m_iSeleteTypes,destIndex)
        -- printT(self.m_tTimeConfig,"self.m_tTimeConfig====:")
        local tmpInserts = self.m_tTimeConfig[tostring(self.m_iSeleteTypes)][tostring(destIndex)]
        if tmpInserts._shaq == 0 then
            self.m_i3InsertType = 1
            self.rootItems.m_oBaoBao:setVisible(true)
            self.rootItems.m_oShaSha:setVisible(false)
            tmpInserts = tmpInserts._gold
        elseif tmpInserts._gold == 0 then
            self.m_i3InsertType = 0
            self.rootItems.m_oBaoBao:setVisible(false)
            self.rootItems.m_oShaSha:setVisible(true)
            tmpInserts = tmpInserts._shaq
        end
        self.m_i3InsertNum = tmpInserts
        ui.setLabelString(self.rootItems["type3_sha"],tostring(tmpInserts),14)
        local tmpTimeIndex = (self.m_iSeleteTypes - 1) * 3 + self.m_iSeleteTimes
        self.m_tInfoTable[tostring(1)].num = gamedata.config.tiantingyz_time[tostring(tmpTimeIndex)]["soul_small"]
                                             .."~"..
                                             gamedata.config.tiantingyz_time[tostring(tmpTimeIndex)]["soul_big"]
        if self.m_oFristConTroller ~= nil then
            ui.setLabelString(self.m_oFristConTroller["in_num"],self.m_tInfoTable[tostring(1)].num,14)
        end
    end
end

function clubcell.updatetimeFunc(self,node1,node2,times)
    local tmpStr = "nightcell_1"

    if gameTimer.times[tmpStr] then
        gameTimer:UnrigistTimeFunc(tmpStr)
    end
    local tmpCandoThat = false
    local tmpTimeIndex = math.floor(times / self.seleTotalTimes)
    local tmpTimesss = times % self.seleTotalTimes
    ui.setLabelString(node2,ui.makeTimeText(tmpTimesss,"hour"),14)
    ui.setLabelString(node1,gameConfig.strings:string_common("nightclub",10)..ui.makeTimeText(times,"hour"),14)
    gameTimer:rigistTime(tmpStr, times)
    gameTimer:rigistTimeFunc(tmpStr,function()
        if gameTimer.times[tmpStr] >= 0 then
            tmpTimeIndex = math.floor(gameTimer.times[tmpStr] / self.seleTotalTimes)
            tmpTimesss = gameTimer.times[tmpStr] % self.seleTotalTimes
            ui.setLabelString(node1,gameConfig.strings:string_common("nightclub",10)..ui.makeTimeText(gameTimer.times[tmpStr],"hour"),14)
        end
        ui.setLabelString(node2,ui.makeTimeText(tmpTimesss,"hour"),14)
        if gameTimer.times[tmpStr] == 0 then
            UIRequest({type = 4501,_id = self.m_iIndex})
            gameTimer:UnrigistTimeFunc(tmpStr)
        else
            if tmpTimesss == 0 then
                if tmpTimeIndex * self.seleTotalTimes < times and tmpCandoThat then
                    self:updateItem(self.m_iCellType,self.m_tInfoTable)
                end
            else
                tmpCandoThat = true
            end
        end
    end)
end

function clubcell.clear(self)
    if self.FightTableView ~= nil then
        self.FightTableView:removeFromParentAndCleanup(true)
        self.FightTableView = nil
    end
    if self.NavigationTableView ~= nil then
        self.NavigationTableView:removeFromParentAndCleanup(true)
        self.NavigationTableView = nil
    end
    if self.stepGneral1 ~= nil then
        self.stepGneral1:removeFromParentAndCleanup(true)
        self.stepGneral1 = nil
    end
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootAnimate = nil
    self.rootNode = nil
    self.rootItems = nil
    self.m_oSpecialAnimation = nil
    self.m_oSpecialNode = nil
    self.m_oSpecialRoot = nil
    self.m_oFristConTroller = nil

    self.m_tFightTable = nil
    self.m_tTimeConfig = nil
    self.m_tInfoTable = nil
    self.m_tLowTable = nil
    self.m_tHigTable = nil
    self.data = nil
    self.m_iCellType = nil
    self.m_iSelet = nil
    self.m_iIndex = nil
    self.realPageTable = nil
    self.generalsdata = nil
    self.m_iSeleteTimes = nil
    self.m_iSeleteTypes = nil
    self.m_i3InsertNum = nil
    self.m_i3InsertType = nil
    if gameTimer.times["nightcell_1"] then
        gameTimer:UnrigistTimeFunc("nightcell_1")
    end
end

return clubcellt�  