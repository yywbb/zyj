--一键添加，一键领取

local oneAddclub = {
    rootNode = nil,
    rootItems = nil,
    m_iCellType = nil,
    m_iSeleteTimes = nil, -- 选择时间
    m_iSeleteTypes = nil, -- 选择类型
    m_tTimeConfig = nil,
    titleCellSize = {x = 180,y = 180},
    fwCellSize = {x = 960,y = 140},
    addClubStatus = false,
    addClubTab = {},
    m_tConfig = {},
    m_tStandMan = nil,
    generalsdata = nil,
    maxNum = 0,
    selectData = nil,
    typeData = {},
    generalsdata2 = nil,
    m_tLowTable = nil,
    m_tHigTable = nil,
    m_oFristConTroller = {},
    NavigationTableView = nil,
    selectType = nil,
    m_oSpecialAnimation = nil,
    m_oSpecialNode = nil,
    m_oSpecialRoot = nil,
    rewardData = nil,
    rewardStage = nil,
    nightClubAutoget = {},
}
local QRIL_CLUB_MAINLEN = 0

function oneAddclub.clear(self)

    local tmpStr = "oneAddclub"
    for i=1,QRIL_CLUB_MAINLEN do
        if gameTimer.times[tmpStr..i] then
            gameTimer:UnrigistTimeFunc(tmpStr..i)
        end
    end

    if self.NavigationTableView ~= nil then
        self.NavigationTableView:removeFromParentAndCleanup(true)
        self.NavigationTableView = nil
    end

    self.rootNode:removeFromParentAndCleanup(true)
    self.rootAnimate = nil
    self.rootNode = nil
    self.rootItems = nil
    self.m_tStandMan = nil
    self.m_tLowTable = nil
    self.m_tHigTable = nil
    self.m_iSeleteTimes = nil

    self.addClubStatus = false
    self.addClubTab = {}
    self.m_tConfig = {}
    self.generalsdata = nil
    self.maxNum = 0
    self.selectData = nil
    self.typeData = {}
    self.generalsdata2 = nil
    self.m_iCellType = nil
    self.m_iSeleteTypes = nil
    self.m_tTimeConfig = nil
    self.m_oFristConTroller = {}
    self.selectType = nil

    self.m_oSpecialAnimation = nil
    self.m_oSpecialNode = nil
    self.m_oSpecialRoot = nil
    self.rewardData = nil
    self.rewardStage = nil
    self.nightClubAutoget = {}
end

function oneAddclub.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("nightclub/nightclub_oneAdd", nil, true, "nightclub_oneAdd")
    self:initFixedString()
    parent:addChild(self.rootNode)
    self.rootAnimate = getAnimationManager(self.rootItems)

    if param and next(param) then
        self.rewardData = param
    end

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.downnode:setPositionY(160)

    self.rootItems.backButton:setTouchPriority(-105)
    self.rootItems.backButton:setSwallowsTouch(true)
    self.rootItems.backButton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        gameTouch:clickprofbytime(0.5)
        if self.selectType then
            self.selectType = nil
            if self.selectData and next(self.selectData) then
                for k,v in ipairs(self.selectData) do
                    self.generalsdata[tostring(v)].selectSpr = nil
                end
                self.m_oFristConTroller = {}
                self.selectData = nil
                self:reloadData()
            end

        else
            GameScene:shiftLayer("nightclub","up")
        end
    end, CCControlEventTouchUpInside)

    self.m_tConfig = gamedata.config.tiantingyz_guanqia
    QRIL_CLUB_MAINLEN = table.getTableLength(self.m_tConfig)

    local function tmpDoneOnce(destIndex)
        if self.isContentScroll then return end
        local tmpIndex = tostring(destIndex)
        if GameScene.roleinfo.level < self.m_tConfig[tmpIndex].level then 
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("nightclub",15),self.m_tConfig[tostring(destIndex)].level)})
            return 
        end
        if self.data and self.data[tmpIndex] then

            if self.data[tmpIndex]["1"] == 2 and self.m_iCellType == 2 then
                local function callback(destSelet)
                    for k,v in pairs(self.generalsdata) do
                        if v.selectSpr then
                            v.selectSpr = nil
                        end
                    end

                    if destSelet then
                        self.selectData = destSelet
                        print("select data")
                        printT(self.selectData)
                        for k,v in ipairs(self.selectData) do
                            self.generalsdata[tostring(v)].selectSpr = 1
                        end
                        self:reloadData()
                    end
                end
                
                gameWindows:openWindow("oneAddclubchoose",{generals =self.generalsdata, num = self.maxNum},callback)
            else

                if self.selectType then
                    runGamePrompt({msg = gameConfig.strings:string_common("nightclub",33)})
                else
                    if self.selectData and next(self.selectData) then
                        runGamePrompt({msg = gameConfig.strings:string_common("nightclub",26)})
                    else
                        runGamePrompt({msg = gameConfig.strings:string_common("nightclub",34)})
                    end
                end
            end
        end
    end

    self.m_oSpecialNode,self.m_oSpecialRoot = CCBReaderLoad("nightclub/nightclub_special", nil, true, "nightclub_special")
    self.m_oSpecialAnimation = getAnimationManager(self.m_oSpecialRoot)
    self.m_oSpecialNode:setVisible(false)
    self.rootItems.midNode2:addChild(self.m_oSpecialNode)


    --展示伙伴
    for i=1,QRIL_CLUB_MAINLEN do
        self.addClubTab["yijianNode"..i],self.addClubTab["yijianItem"..i] = CCBReaderLoad("nightclub/cell_yijian", nil, true, "cell_yijian")
        self.addClubTab["yijianAnimation"..i] = getAnimationManager(self.addClubTab["yijianItem"..i])
        self.rootItems["addclubNode"..i]:addChild(self.addClubTab["yijianNode"..i])
        ui.setLabelString(self.addClubTab["yijianItem"..i].suolevel,gameConfig.strings:nightclubLevelOpen(self.m_tConfig[tostring(i)].level),14)
        ui.setLabelString(self.addClubTab["yijianItem"..i].getlabel,gameConfig.strings:string_common("nightclub",27),14)
        setSpriteFrameByName(self.addClubTab["yijianItem"..i].m_oTitlePic, self.m_tConfig[tostring(i)].word_icon or gameConfig.images.alpha)
        self.addClubTab["yijianItem"..i].button:setTouchPriority(-105)
        self.addClubTab["yijianItem"..i].button:setSwallowsTouch(true)
        self.addClubTab["yijianItem"..i].button:addHandleOfControlEvent(function()
            tmpDoneOnce(i)
        end, CCControlEventTouchUpInside)
    end
    
    UIRequest({type = 4511})

end

function oneAddclub.reloadData(self,data)

    self.addClubStatus = false

    if data then
        self.data = data.data
        self.generalsdata2 = {}
        self.generalsdata2 = data.generalsdata
        self.typeData = {}
        self.m_oFristConTroller = {}
        self.nightClubAutoget = {}
        print("reloadData ")
    end
    if self.data and next(self.data) then
        self.maxNum = 0
        for k,v in pairs(self.data) do
            if v["1"] == 2 then
               self.addClubStatus = true
               self.maxNum = self.maxNum + 1
            end
        end
    end

    if self.selectType then
        self.m_iCellType = 3
    else
        self.m_iCellType = 2
    end

    if self.rewardData then
        self.m_iCellType = 4
    end

    if self.addClubStatus == true and (self.selectData and next(self.selectData)) then
        ui.removeGray("CCControlButton",self.rootItems.oneAddBtn)
        ui.removeGray("CCControlButton",self.rootItems.oneDeleteBtn)
        ui.removeGray("CCLabelTTF",self.rootItems.oneAddLab)
        ui.removeGray("CCLabelTTF",self.rootItems.oneDeleteLab)
    else
        ui.addGray("CCControlButton",self.rootItems.oneAddBtn)
        ui.addGray("CCControlButton",self.rootItems.oneDeleteBtn)
        ui.addGray("CCLabelTTF",self.rootItems.oneAddLab)
        ui.addGray("CCLabelTTF",self.rootItems.oneDeleteLab)
    end

    self:getNightClubOneAdd()
    
    if self.nightClubAutoAdd and next(self.nightClubAutoAdd) then
        ui.removeGray("CCControlButton",self.rootItems.autoAddBtn)
    else
        ui.addGray("CCControlButton",self.rootItems.autoAddBtn)
    end 

    --展示伙伴
    self.m_tStandMan = {}
    self.rewardStage = {}
    for i=QRIL_CLUB_MAINLEN,1,-1 do
        --self.addClubTab["yijianItem"..i].addgeneralNode:removeAllChildrenWithCleanup(true)
        self.addClubTab["yijianItem"..i].addgeneralNode:setVisible(false)
        local tmpIndex = tostring(i)
        if self.data[tmpIndex] then
            local tmpStageValue = self.data[tmpIndex]["1"]
            if tmpStageValue == 0 then
                if GameScene.roleinfo.level < self.m_tConfig[tmpIndex].level then

                else
                    self.addClubTab["yijianItem"..i].suolevel:setVisible(false)
                    -- self.addClubTab["yijianItem"..i].suoSpr:setVisible(false)
                end
            elseif tmpStageValue == 1 then
                if GameScene.roleinfo.level < self.m_tConfig[tmpIndex].level then
                    tmpStageValue = 0
                else

                end
            elseif tmpStageValue == 2 then
                local tmpStageValue2 = 2

                if self.selectData and next(self.selectData) then
                    for k,v in ipairs(self.selectData) do
                        if self.typeData[k] then
                            -- local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.generalsdata[tostring(v)].cid)].animationid)].name
                            -- local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                            -- general:setAnimation("stand",true,0)
                            -- general:setScale(1)
                            -- self.addClubTab["yijianItem"..self.typeData[k]].addgeneralNode:addChild(general)
                            self.addClubTab["yijianItem"..self.typeData[k]].addgeneralNode:setVisible(true)
                            -- 设置头像
                            if self.generalsdata[tostring(v)].illusionGeneralCid == nil then
                                local configGeneral = gamedata.config.general[tostring(self.generalsdata[tostring(v)].cid)]
                                local gdata = ui.getConfigGeneral(self.generalsdata[tostring(v)])
                                local gicon = configGeneral.icon
                                if next(gdata) and configGeneral.fashion_id == 0 then
                                    gicon = gdata.icon
                                end
                                ui.setNewIcon(self.addClubTab["yijianItem"..self.typeData[k]],{cid = self.generalsdata[tostring(v)].cid, icon = gicon})
                            else
                                ui.setNewIcon(self.addClubTab["yijianItem"..self.typeData[k]],{cid = self.generalsdata[tostring(v)].cid})
                            end

                            if tonumber(self.typeData[k]) == tonumber(i) then
                                tmpStageValue2 = 5
                            end
                        end
                    end
                else
                    table.insert(self.typeData,tmpIndex)
                end
                tmpStageValue = tmpStageValue2
            else
                if tmpStageValue == 3 and self.data[tmpIndex]["6"] then          
                    self:updatetimeFunc(self.addClubTab["yijianItem"..tmpIndex].timelable,i,self.data[tmpIndex]["6"])
                end

                if tmpStageValue == 3 or tmpStageValue == 4 then
                    -- local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data[tmpIndex]["5"])].animationid)].name
                    -- local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                    -- general:setAnimation("stand",true,0)
                    -- general:setScale(1)
                    -- self.addClubTab["yijianItem"..i].addgeneralNode:addChild(general)
                    self.addClubTab["yijianItem"..i].addgeneralNode:setVisible(true)
                    -- 设置头像
                    local configGeneral = gamedata.config.general[tostring(self.data[tmpIndex]["5"])]
                    local gdata = {}
                    for k,v in pairs(self.generalsdata2) do
                        if self.data[tmpIndex]["5"] == v.cid then
                            gdata = v
                            break
                        end
                    end
                    if gdata.illusionGeneralCid == nil then
                        gdata = ui.getConfigGeneral(gdata)
                        local gicon = configGeneral.icon
                        if next(gdata) and configGeneral.fashion_id == 0 then
                            gicon = gdata.icon
                        end
                        ui.setNewIcon(self.addClubTab["yijianItem"..i],{cid = self.data[tmpIndex]["5"], icon = gicon})
                    else
                        ui.setNewIcon(self.addClubTab["yijianItem"..i],{cid = self.data[tmpIndex]["5"]})
                    end
                end

                if tmpStageValue == 4 then
                    table.insert(self.rewardStage,self.data[tmpIndex])
                    local generalCid = self.data[tmpIndex]["5"]
                    print("generalCid:"..tostring(generalCid))
                    self.nightClubAutoget[tmpIndex] = generalCid
                end
            end
            self.addClubTab["yijianAnimation"..i]:runAnimationsForSequenceNamed(tostring(tmpStageValue))
            local tmpCid = self.data[tmpIndex]["5"]
            if tmpCid and tmpCid > 0 then
                table.insert(self.m_tStandMan,tmpCid)
            end
        end

    end

    print("self.m_iCellType --- ",self.m_iCellType)
    self.rootAnimate:runAnimationsForSequenceNamed("yijian"..self.m_iCellType)

    if self.addClubStatus then
        self:ReloadGenerals(self.generalsdata2)
    end

    local tmpConfig = gamedata.config.tiantingyz_guanqia

    --if self.addClubStatus then
        if self.m_iCellType == 2 then
            self.m_tLowTable = {}
            self.m_tHigTable = {}
            local tmpConfig2 = tmpConfig[tostring(self.typeData[1] or 1)]
            local tmpLowItem1 = ui.getNeedWithFuhao(tmpConfig2.drop1_low,";")
            local tmpHigItem2 = ui.getNeedWithFuhao(tmpConfig2.drop1_up,";")
            for i,v in ipairs(tmpLowItem1) do
                self.m_tLowTable[tostring(i)] = {ui.getIDandNUM(gamedata.config.tiantingyz_diaoluo[v].item)}
            end
            for i,v in ipairs(tmpHigItem2) do
                self.m_tHigTable[tostring(i)] = {ui.getIDandNUM(gamedata.config.tiantingyz_diaoluo[v].item)}
            end

            --全部清空
            self.rootItems.oneDeleteBtn:setTouchPriority(-105)
            self.rootItems.oneDeleteBtn:setSwallowsTouch(true)
            self.rootItems.oneDeleteBtn:addHandleOfControlEvent(function()
                if self.selectData and next(self.selectData) then
                    for k,v in ipairs(self.selectData) do
                        self.generalsdata[tostring(v)].selectSpr = nil
                    end
                    self.selectData = nil
                    --self.typeData = {}
                    self:reloadData()
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("nightclub",28)})
                end
            end, CCControlEventTouchUpInside)


             --自动添加
            self.rootItems.autoAddBtn:setTouchPriority(-105)
            self.rootItems.autoAddBtn:setSwallowsTouch(true)
            self.rootItems.autoAddBtn:addHandleOfControlEvent(function()
                print("自动添加")
                -- printT(self.generalsdata)
                -- printT(self.nightClubAutoAdd)
                print("generaldata2 自动添加")
                -- printT(self.generalsdata2)
                if self.nightClubAutoAdd and next(self.nightClubAutoAdd)  then
                    printT(self.generalsdata)
                    for k,v in pairs(self.generalsdata) do
                        v.selectSpr = nil
                    end
                    --判断自动添加的ID是否存在
                    self.selectData = {}
                    local _count = 0
                    for k,v in pairs(self.generalsdata) do 
                        if self.generalsdata[tostring(k)] and self.generalsdata[tostring(k)].cid then
                            -- print("可选择ID ："..tostring(self.generalsdata[tostring(i)].generalcid))
                            for kk,vv in pairs(self.nightClubAutoAdd) do
                                -- print("上次收获ID ："..tostring(w))
                                if tonumber(self.generalsdata[tostring(k)].cid) == tonumber(vv) and _count < self.maxNum then
                                    print("匹配缓存 key:",k)
                                    table.insert(self.selectData,k)
                                    _count = _count + 1
                                end   
                            end 
                        end   
                    end   
    
                    printT(self.selectData)
                    for i,v in ipairs(self.selectData) do
                        self.generalsdata[tostring(v)].selectSpr = 1
                    end
                    if (self.selectData and next(self.selectData)) then
                         self:reloadData()
                         ui.addGray("CCControlButton",self.rootItems.autoAddBtn)
                    else
                         runGamePrompt({msg = "当前没有选择伙伴"})
                    end
                else
                   runGamePrompt({msg = gameConfig.strings:string_common("nightclub",46)})
                end    
            end, CCControlEventTouchUpInside)



            self.rootItems.oneAddBtn:setTouchPriority(-105)
            self.rootItems.oneAddBtn:setSwallowsTouch(true)
            self.rootItems.oneAddBtn:addHandleOfControlEvent(function()
                if self.selectData and next(self.selectData) then
                    self.selectType = 3
                    self:reloadData()
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("nightclub",29)})   
                end
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

            self.m_tInfoTable = {}
            local tmpConfig2 = ""
            local tmpConfig3 = ""
            for k,v in ipairs(self.selectData) do
                if self.typeData[k] then 
                    tmpConfig2 = tostring(tmpConfig2) .. tostring(tmpConfig[self.typeData[k]].drop1_low) .. ";"
                    tmpConfig3 = tostring(tmpConfig3) .. tostring(tmpConfig[self.typeData[k]].drop1_up) .. ";"
                end
            end
            
            local tmpLowItem1 = ui.getNeedWithFuhao(tmpConfig2,";")
            local tmpHigItem2 = ui.getNeedWithFuhao(tmpConfig3,";")
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

            if self.selectData and next(self.selectData) then
                for k,v in ipairs(self.selectData) do
                    local tmpEnemyId = tonumber(self.generalsdata[tostring(v)].cid)
                    local fcid = gamedata.getOriginCid(tmpEnemyId)

                    self.m_tInfoTable[tostring(k)] = {cid = gamedata:findFragmentCid(fcid),
                                               num = gamedata.config.tiantingyz_time[tostring(1)]["soul_small"]
                                                  .."~"..
                                                  gamedata.config.tiantingyz_time[tostring(1)]["soul_big"]}
                end
               
            end

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
            for i=1,3 do
                ui.setLabelString(self.rootItems["type3_lable"..i],string.format(gameConfig.strings:string_common("nightclub",1),self.m_tTimeConfig[tostring(self.m_iSeleteTypes)][tostring(i)]._time),14)
                self.rootItems["type3_bt"..i]:setTouchPriority(-105)
                self.rootItems["type3_bt"..i]:setSwallowsTouch(true)
                self.rootItems["type3_bt"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    self:update3Times(i)
                end, CCControlEventTouchUpInside)
            end

            ui.setLabelString(self.rootItems["type3_lable"],gameConfig.strings:string_common("nightclub",5),19)
            self.rootItems["type3_bt"]:setTouchPriority(-105)
            self.rootItems["type3_bt"]:setSwallowsTouch(true)
            self.rootItems["type3_bt"]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                if self.selectData and next(self.selectData) then
                    local tmpTimeIndex = (self.m_iSeleteTypes - 1) * 3 + self.m_iSeleteTimes
                    local data = {}
                    for k,v in ipairs(self.selectData) do
                        data[tostring(self.typeData[k])] = self.generalsdata[tostring(v)].iid
                    end
                    UIRequest({type = 4509,_time = tmpTimeIndex,data = data,_shaNum = self.m_i3InsertType,_baoNum = self.m_i3InsertBao})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("nightclub",30)})
                end
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

            self.m_tInfoTable = {}
            self.m_iEnemyCid = {}
            local tII = 0
            if self.rewardStage and next(self.rewardStage) then
                for k,v in ipairs(self.rewardStage) do
                    local tmpEnemyId = v["5"]
                    local tmpEnemyNum = v["8"]
                    local fcid = gamedata.getOriginCid(tmpEnemyId)

                    tII = tII + 1
                    self.m_iEnemyCid[tostring(tII)] = tonumber(tmpEnemyId)
                    self.m_tInfoTable[tostring(tII)] = {cid = gamedata:findFragmentCid(fcid),num = tmpEnemyNum}
                end
            end

            if self.rewardStage and next(self.rewardStage) then
                for k,v in ipairs(self.rewardStage) do
                    for kk,vv in pairs(v) do
                        local tmpIndex = tonumber(kk)
                        if tmpIndex > 8 then
                            if tmpIndex % 2 == 0 then
                                tII = tII + 1
                                local tmpCid ,tmpNum = ui.getIDandNUM(gamedata.config.tiantingyz_diaoluo[tostring(vv)].item)
                                if v["3"] ~= 0 then
                                    tmpNum = tmpNum + tmpNum
                                end
                                self.m_tInfoTable[tostring(tII)] = {cid = tmpCid,num = tmpNum}
                            end
                        end
                    end
                end
            end

            local rewardTab = self.m_tInfoTable
            self.m_tInfoTable = {}
            if rewardTab and rewardTab then
                for i=1,table.getTableLength(rewardTab) do
                    print(i)    
                    if next(self.m_tInfoTable) then
                        local sameCid = 0
                        for kk,vv in pairs(self.m_tInfoTable) do
                            if rewardTab[tostring(i)].cid == vv.cid then
                                vv.num = vv.num + rewardTab[tostring(i)].num
                                sameCid = 1
                            else
                            end
                        end 
                        if sameCid == 0 then
                            table.insert(self.m_tInfoTable,rewardTab[tostring(i)])
                        end
                    else
                        table.insert(self.m_tInfoTable,rewardTab[tostring(i)])
                    end
                end
            end

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

                local _str = ""
                --领取之前缓存武将id
                for k,v in pairs(self.nightClubAutoget) do
                    _str = _str..k..","..v..";"
                end
                CCUserDefault:sharedUserDefault():setStringForKey("nightClubAddOne"..GameScene.roleinfo.id, _str)
                UIRequest({type = 4510,data = self.rewardData})

                


            end, CCControlEventTouchUpInside)
            ui.setLabelString(self.rootItems["type4_lable3"],gameConfig.strings:string_common("buttontext","lingqu"),18)

            self.m_iInfoLens = tII
            self:updateItem(self.m_iCellType,self.m_tInfoTable)

        end

    --end
end

function oneAddclub.getNightClubOneAdd(self)
    local _str = CCUserDefault:sharedUserDefault():getStringForKey("nightClubAddOne"..GameScene.roleinfo.id)
    local _temp = ui.getIDandNUMs(_str)
    self.nightClubAutoAdd = {}
    
    if self.maxNum > 0 then
        for i,v in ipairs(_temp) do
            if self.generalsdata and next(self.generalsdata) then
                for k,vv in pairs(self.generalsdata) do
                    if v.num == vv.cid then
                        self.nightClubAutoAdd[tostring(v.cid)] = v.num
                    end
                end
            else
                self.nightClubAutoAdd[tostring(v.cid)] = v.num
            end
        end
    end

    if self.data and next(self.data) then
        for k,v in pairs(self.data) do
            for kk,vv in pairs(self.nightClubAutoAdd) do
                if v["5"] == vv then
                    self.nightClubAutoAdd[kk] = nil
                end
            end
        end
    end
end

--特殊事件
function oneAddclub.SpecialEventData( self,data )
    -- body
    self.speacialData = {}
    for k,v in pairs(data.data) do
        if v["2"] and v["2"] > 0 then
            for kk,vv in pairs(data.nightArrayData) do
                if vv == v["5"] then
                    table.insert(self.speacialData,{m_iIndex = kk,data = v})
                end
            end
        end
    end
    printT(self.speacialData,"speacialData")
    self:addSpecialEvent(1)
    
end

function oneAddclub.addSpecialEvent(self,index)

    if self.speacialData[index] and self.speacialData[index]["data"] and self.speacialData[index]["data"]["2"] > 0 then

        local function callback(destSelet)
            --UIRequest({type = 4511})
            self:addSpecialEvent(destSelet)
        end
        gameTouch:clickprofbytime(3.5)
        self.m_oSpecialAnimation:setAnimationCompletedCallback(function()
            self.m_oSpecialNode:setVisible(false)
            gameWindows:openWindow("clubchance",{_index = tonumber(self.speacialData[index].m_iIndex),_type = self.speacialData[index]["data"]["2"],_typeindex = index},callback)
        end)
        self.m_oSpecialAnimation:runAnimationsForSequenceNamed("loop")
        self.m_oSpecialNode:setVisible(true)
    else
        UIRequest({type = 4511})
    end
end



function oneAddclub.update3Times(self,destIndex)
    if self.m_iSeleteTimes ~= destIndex then
        if self.m_iSeleteTimes and self.m_iSeleteTimes ~= 0 then
            self.rootItems["type3_selete"..self.m_iSeleteTimes]:setVisible(false)
        end
        self.m_iSeleteTimes = destIndex
        self.rootItems["type3_selete"..self.m_iSeleteTimes]:setVisible(true)
    end
    if self.m_iSeleteTypes then

        --local costConfig = gamedata.config.tree_watering
        local tmpInserts = self.m_tTimeConfig[tostring(self.m_iSeleteTypes)][tostring(destIndex)]
        self.m_i3InsertType = 0

        if tmpInserts._shaq == 0 then
            self.m_i3InsertType = 1
            tmpInserts = tmpInserts._gold
        elseif tmpInserts._gold == 0 then
            self.m_i3InsertType = 0
            tmpInserts = tmpInserts._shaq
        end

        --self.m_i3InsertSha = self.m_i3InsertSha+tonumber(costdata["murderous"..((self.m_iSeleteTypes-1)*3+destIndex)]) or 0
        self.m_i3InsertBao = tmpInserts * table.getTableLength(self.selectData)
        
        -- self.m_i3InsertBao = 0
        -- for k,v in ipairs(self.selectData) do
        --     local costdata = costConfig[tostring(self.generalsdata[tostring(v)].cid)]
        --     self.m_i3InsertSha = self.m_i3InsertSha+tonumber(costdata["murderous"..((self.m_iSeleteTypes-1)*3+destIndex)]) or 0
        --     self.m_i3InsertBao = self.m_i3InsertBao+tonumber(costdata["Ingots"..((self.m_iSeleteTypes-1)*3+destIndex)]) or 0
        -- end

        -- if self.m_i3InsertBao > 0 then
        --     self.rootItems.m_oBaoBao:setVisible(true)
        --     self.rootItems.m_oShaSha:setPositionX(0)
        -- else
        --     self.rootItems.m_oBaoBao:setVisible(false)
        --     self.rootItems.m_oShaSha:setPositionX(180)
        -- end
        -- if self.m_i3InsertType > 0 then
        --     self.rootItems.m_oShaSha:setVisible(true)
        -- else
        --     self.rootItems.m_oShaSha:setVisible(false)
        -- end

        if self.m_i3InsertType == 0 then
            self.rootItems.m_oShaSha:setVisible(true)
            self.rootItems.m_oBaoBao:setVisible(false)
        else
            self.rootItems.m_oShaSha:setVisible(false)
            self.rootItems.m_oBaoBao:setVisible(true)
        end

        ui.setLabelString(self.rootItems["type3_sha"],self.m_i3InsertBao,14)
        local tmpTimeIndex = (self.m_iSeleteTypes - 1) * 3 + self.m_iSeleteTimes
        for k,v in ipairs(self.selectData) do
            self.m_tInfoTable[tostring(k)].num = gamedata.config.tiantingyz_time[tostring(tmpTimeIndex)]["soul_small"] .."~".. gamedata.config.tiantingyz_time[tostring(tmpTimeIndex)]["soul_big"]
            if self.m_oFristConTroller and next(self.m_oFristConTroller) then
                if self.m_oFristConTroller[tostring(k)] then
                   ui.setLabelString(self.m_oFristConTroller[tostring(k)]["in_num"],self.m_tInfoTable[tostring(k)].num,13)
                end
            end 
        end

    end
end

function oneAddclub.update3Type(self,destType)
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

    local tmpConfig = gamedata.config.tiantingyz_guanqia
    -- local temp1 = self.m_tInfoTable and self.m_tInfoTable["1"] or {}
    local temp = {}
    local tII = 0
    for k,v in ipairs(self.selectData) do
        temp[tostring(k)] = self.m_tInfoTable and self.m_tInfoTable[tostring(k)] or {}
        tII = tII + 1
    end

    self.m_tInfoTable = {}

    local tmpConfig2 = ""
    local tmpConfig3 = ""
    for k,v in ipairs(self.selectData) do
        if self.typeData[k] then 
            tmpConfig2 = tostring(tmpConfig2) .. tostring(tmpConfig[self.typeData[k]]["drop"..self.m_iSeleteTypes.."_low"]) .. ";"
            tmpConfig3 = tostring(tmpConfig3) .. tostring(tmpConfig[self.typeData[k]]["drop"..self.m_iSeleteTypes.."_up"]) .. ";"
        end
    end
    
    local tmpLowItem1 = ui.getNeedWithFuhao(tmpConfig2,";")
    local tmpHigItem2 = ui.getNeedWithFuhao(tmpConfig3,";")

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

    for k,v in ipairs(self.selectData) do
        self.m_tInfoTable[tostring(k)] = temp[tostring(k)]  
    end

    self:updateItem(self.m_iCellType,self.m_tInfoTable)
end

function oneAddclub.updateItem(self,destType,destTable)
    if self.NavigationTableView ~= nil then

        self.m_oFristConTroller = {}
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
    
    tmpTimesss = self.m_iInfoLens
    self.realPageTable = destTable
    
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
                
                if self.selectData and next(self.selectData) and a1 < table.getTableLength(self.selectData) then
                    self.m_oFristConTroller[tostring(a1+1)] = ccbDocumentControler
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
            ui.setNewIconName(ccbDocumentControler,self.realPageTable[tostring(a1+1)] or self.realPageTable[a1+1] )
            if tmpSprite then
                --if a1 == 0 then
                if self.selectData and next(self.selectData) and a1 < table.getTableLength(self.selectData) then
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
                -- local tmpPoints = self.NavigationTableView:getContentOffset()
                -- if tmpPoints.x < -self.titleCellSize.x then
                --     self.m_oFristConTroller = {}
                -- else
                --     for k,v in pairs(activityTable) do
                --         if v.tmpSprite ~= nil then
                --             self.m_oFristConTroller[tostring(k)] = v.ccbDocumentControler
                --         end
                --     end
                -- end
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

end


function oneAddclub.updatetimeFunc(self,label,index,times)
    local tmpStr = "oneAddclub"..index

    if gameTimer.times[tmpStr] then
        gameTimer:UnrigistTimeFunc(tmpStr)
    end
    ui.setLabelString(label,gameConfig.strings:string_common("nightclub",10)..ui.makeTimeText(times,"hour"),13)
    gameTimer:rigistTime(tmpStr, times)
    gameTimer:rigistTimeFunc(tmpStr,function()
        if gameTimer.times[tmpStr] >= 0 then
            ui.setLabelString(label,gameConfig.strings:string_common("nightclub",10)..ui.makeTimeText(gameTimer.times[tmpStr],"hour"),13)
        end
        if gameTimer.times[tmpStr] == 0 then
            UIRequest({type=4511})
            gameTimer:UnrigistTimeFunc(tmpStr)
        end
    end)
end


function oneAddclub.ReloadGenerals(self,data)
    printT(self.m_tStandMan)
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



function oneAddclub.initFixedString(self) 
    -- ui.setLabelString(self.rootItems.fixedback,gameConfig.strings:string_common("gamestar",10),16)
    -- self.rootItems.fixed1:setString(gameConfig.strings:string_common("fixedString","nightclub",1))
    -- self.rootItems.fixed2:setString(gameConfig.strings:string_common("fixedString","nightclub",2))
    -- self.rootItems.fixed3:setString(gameConfig.strings:string_common("fixedString","nightclub",7))
    -- self.rootItems.fixed4:setString(gameConfig.strings:string_common("fixedString","nightclub",2))
    -- ui.setLabelString(self.rootItems.fixed5,gameConfig.strings:string_common("fixedString","nightclub",8),28)
    -- self.rootItems.fixed6:setString(gameConfig.strings:string_common("fixedString","nightclub",9))
    -- self.rootItems.fixed8:setString(gameConfig.strings:string_common("fixedString","nightclub",11))
    ui.setLabelString(self.rootItems.oneAddLab,gameConfig.strings:string_common("nightclub",31),18)
    ui.setLabelString(self.rootItems.oneDeleteLab,gameConfig.strings:string_common("nightclub",32),18)
    ui.setLabelString(self.rootItems.autoAddLab,gameConfig.strings:string_common("nightclub",45),18)

end

return oneAddclub