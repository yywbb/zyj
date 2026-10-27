--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/6/14
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local jewelUp = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {x=200,y=200},
    jewelConfig = {"attack","defence","life","skill"},
    selectPage = "attack",
    selectId = nil,
    canCommpondNum = 0,
    jewelConfigs = nil,
    jewelDatas = nil,
    jewelUpUseId = 20680,
    props = {},
}

function jewelUp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_baoshihecheng", nil, true, "tc_baoshihecheng")
    
    self:initFixedString()
    --
    self.touchPriority = touchPriority
    self.selectItem = nil
    self.callback = callback
    --
    self:initBtnFuncs()
    --
    self.selectId = data.selectId
    if not self.jewelConfigs then
        self:initDatas()
    end
    self:getUseIdNum()
    return self.rootNode
end

function jewelUp.getUseIdNum(self,t)
    self.props = t or self.props
    if not self.props[tostring(self.jewelUpUseId)] then
        UIRequest({type = 12001, order = 33014, cids = {self.jewelUpUseId}})
        return
    end
    self:reloadData()
end

function jewelUp.checkIsNumOk(self)
    if not self.selectId then
        return false,0,runGamePrompt({msg = gameConfig.strings:string_common("artifact",109)})
        
    end
    local config = gamedata.config.trump_gem[tostring(self.selectId)]
    local data  = self.jewelDatas[tostring(self.selectId)]
    local useTable = {}
    if config.per_cid > 0 then
        useTable = ui.getIDandNUMs(config.gem_lv)
    end
    if #useTable <= 0 then
        return false,0, runGamePrompt({msg = gameConfig.strings:string_common("devour",13)})
    end
    local needPropNum,needJewelNum = 0,0
    for k,v in ipairs(useTable) do
        if v.cid == self.selectId then
            needJewelNum = v.num
            if not data or data.num < v.num then
                return false,0, runGamePrompt({msg = gameConfig.strings:string_common("artifact",110)})
            end
        elseif v.cid == self.jewelUpUseId then
            needPropNum = v.num
            if self.props[tostring(v.cid)] < v.num then
                local idConfig = ui.IDconfig(v.cid)
                return false,0,runGamePrompt({msg = gameConfig.strings:string_format({"artifact",111},{idConfig.name})})
            end
        end
    end
    if needPropNum > 0 then
        return true,math.floor(math.min(data.num/needJewelNum,self.props[tostring(self.jewelUpUseId)]/needPropNum))
    else
        return true,math.floor(data.num/needJewelNum)
    end
end

function jewelUp.initBtnFuncs(self)
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("jewelUp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.doButton1:addHandleOfControlEvent(function()
        if not self.jewelDatas then
            return
        end
        local isOk =  self:checkIsNumOk()
        if isOk then
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 5507,cid = self.selectId + 1,num = 1})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)
        
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        if not self.jewelDatas then
            return
        end
        local isOk,num =  self:checkIsNumOk()
        if isOk then
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 5507,cid = self.selectId + 1,num = num})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    for i = 1,4 do
        self.rootItems[self.jewelConfig[i].."Btn"]:addHandleOfControlEvent(function()
            if self.selectPage ~= self.jewelConfig[i] then
                self:shiftPage(self.jewelConfig[i])
            end
        end, CCControlEventTouchUpInside)
        self.rootItems[self.jewelConfig[i].."Btn"]:setSwallowsTouch(true)
        self.rootItems[self.jewelConfig[i].."Btn"]:setTouchPriority(self.touchPriority)
    end

    for i = 1,2 do
        self.rootItems["caiShiBtn"..i]:addHandleOfControlEvent(function()
            gameWindows:openWindow("dropTips",{cid = self.jewelUpUseId},nil)
        end, CCControlEventTouchUpInside)
        self.rootItems["caiShiBtn"..i]:setSwallowsTouch(true)
        self.rootItems["caiShiBtn"..i]:setTouchPriority(self.touchPriority)
    end
end

function jewelUp.initDatas(self)
    local configs = gamedata.config.trump_gem
    self.jewelConfigs = {}
    self.jewelConfigs.attack = {}
    self.jewelConfigs.defence = {}
    self.jewelConfigs.life = {}
    self.jewelConfigs.skill = {}
    for k,v in pairs(configs) do
        table.insert(self.jewelConfigs[self.jewelConfig[v.type]],v)
    end
    local sortFunc = function (a,b)
        return a.id < b.id
    end
    for i = 1,4 do
        table.sort(self.jewelConfigs[self.jewelConfig[i]],sortFunc)
    end
end

function jewelUp.reloadData(self,t)
    if not GameScene.layers["artifactList"].module.jewelData then 
        GameScene:addUpdate(10031)
    end
    if GameScene:checkUpdate(10031) then
        return
    end
    self.jewelDatas = GameScene.layers["artifactList"].module.jewelData.primeData
    if self.selectId then
        local config = gamedata.config.trump_gem[tostring(self.selectId)]
        self:shiftPage(self.jewelConfig[config.type])
    else
        self.selectId = nil
        self:shiftPage(self.jewelConfig[1])
    end
    
end

function jewelUp.shiftPage(self,type)
    local currentType = self.selectPage
    self.selectPage = type or self.selectPage
    self:setButtonState()
    if not self.listTableView then
        self:createList()
    else
        if currentType ~= self.selectPage then
            self.listTableView:setLuaContentOffset(0,0)
        end
        self.listTableView:reloadData()
    end
end


function jewelUp.setButtonState(self)
    for i = 1,4 do
        if self.selectPage == self.jewelConfig[i] then
           self.rootItems["bgOn"..i]:setVisible(true)
        else
            self.rootItems["bgOn"..i]:setVisible(false)
        end
    end
    local jewelData,config
    jewelData = self.selectId and self.jewelDatas[tostring(self.selectId)]
    config = self.selectId and gamedata.config.trump_gem[tostring(self.selectId)]
    local useTable = {}
    if config and config.per_cid > 0 then
        useTable = ui.getIDandNUMs(config.gem_lv)
    end
    local isOk = true
    self.canCommpondNum = 0
    local oneNeedProp = 0
    local oneNeedJewel = 0
    if #useTable > 0 then
        for k,v in ipairs(useTable) do
            if v.cid == self.selectId then
                oneNeedJewel = v.num
                ui.setLabelString(self.rootItems.fate,gameConfig.strings:string_format({"artifact",98},{v.num,1}),84)
                if not jewelData or jewelData.num < v.num then
                    isOk = false
                else
                    local num = math.floor(jewelData.num/v.num)
                    self.canCommpondNum = (self.canCommpondNum == 0 or num < self.canCommpondNum) and num or self.canCommpondNum
                end
            else
                oneNeedProp = v.num
                if self.props[tostring(v.cid)] and self.props[tostring(v.cid)] >= v.num then
                    local num = math.floor(self.props[tostring(v.cid)]/v.num)
                    self.canCommpondNum = (self.canCommpondNum == 0 or num < self.canCommpondNum) and num or self.canCommpondNum
                else
                    isOk = false
                end
            end
        end
        
    else
        isOk = false
        ui.setLabelString(self.rootItems.fate,"",84)
    end
    
    if isOk then
        --ui.removeGray("CCControlButton",self.rootItems.doButton1)
        --ui.removeGray("CCControlButton",self.rootItems.doButton2)
        ui.setLabelString(self.rootItems.heNum2,""..(oneNeedProp * self.canCommpondNum),14)
        ui.setLabelString(self.rootItems.heNum1,""..oneNeedProp,14)
    else
        --ui.addGray("CCControlButton",self.rootItems.doButton1)
        --ui.addGray("CCControlButton",self.rootItems.doButton2)
        if not jewelData or oneNeedJewel == 0 or math.floor(jewelData.num/oneNeedJewel) == 0 then
            local labN = self.props[tostring(self.jewelUpUseId)] >= oneNeedProp and 14 or 76
            ui.setLabelString(self.rootItems.heNum2,""..oneNeedProp,labN)
            ui.setLabelString(self.rootItems.heNum1,""..oneNeedProp,labN)
        else
            ui.setLabelString(self.rootItems.heNum2,""..(oneNeedProp * math.floor(jewelData.num/oneNeedJewel)),76)
            ui.setLabelString(self.rootItems.heNum1,""..oneNeedProp,76)
        end
    end
    
    --self.rootItems.upValueNum:setString(gameConfig.strings:string_common("artifact",53)..":"..(config.weight_lv * 100).."%")
    if self.selectId then
        ui.setNewIconName(self.rootItems,{cid=self.selectId,num=(jewelData and jewelData.num or 0)},0)
        self.rootItems["in_button"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(self.selectId)
        end, CCControlEventTouchUpInside)
        self.rootItems["in_button"]:setTouchPriority(self.touchPriority)
        self.rootItems["in_button"]:setSwallowsTouch(true)
    else
        setSpriteFrameByName(self.rootItems["in_k_quality"], "b_iconk1")
        setSpriteFrameByName(self.rootItems["in_quality"], "b_iconbg1")
        setSpriteFrameByName(self.rootItems["in_icon"],"alpha")
        self.rootItems["in_soulsprite"]:setVisible(false)
        if self.rootItems["titleicon"] then 
            self.rootItems["titleicon"]:setVisible(false)
        end
        self.rootItems["in_soulnode"]:removeAllChildrenWithCleanup(true)
        self.rootItems["in_suitNode"]:removeAllChildrenWithCleanup(true)
        ui.setLabelString(self.rootItems["in_num"],"",13)
        ui.setLabelString(self.rootItems["in_name"],"",1)

        self.rootItems["in_button"]:addHandleOfControlEvent(function()
            
        end, CCControlEventTouchUpInside)
        self.rootItems["in_button"]:setTouchPriority(self.touchPriority)
        self.rootItems["in_button"]:setSwallowsTouch(true)
    end

    if config and config.per_cid > 0 then
        self.rootItems.item2:setVisible(true)
        ui.setNewIconName(self.rootItems,{cid=config.per_cid},1)
        self.rootItems["in_button_1"]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(config.per_cid)
        end, CCControlEventTouchUpInside)
        self.rootItems["in_button_1"]:setTouchPriority(self.touchPriority)
        self.rootItems["in_button_1"]:setSwallowsTouch(true)
    else
        if self.selectId then
            self.rootItems.item2:setVisible(false)
        else
            setSpriteFrameByName(self.rootItems["in_k_quality_1"], "b_iconk1")
            setSpriteFrameByName(self.rootItems["in_quality_1"], "b_iconbg1")
            setSpriteFrameByName(self.rootItems["in_icon_1"],"alpha")
            self.rootItems["in_soulsprite_1"]:setVisible(false)
            if self.rootItems["titleicon_1"] then 
                self.rootItems["titleicon_1"]:setVisible(false)
            end
            self.rootItems["in_soulnode_1"]:removeAllChildrenWithCleanup(true)
            self.rootItems["in_suitNode_1"]:removeAllChildrenWithCleanup(true)
            ui.setLabelString(self.rootItems["in_num_1"],"",13)
            ui.setLabelString(self.rootItems["in_name_1"],"",1)

            self.rootItems["in_button_1"]:addHandleOfControlEvent(function()
               
            end, CCControlEventTouchUpInside)
            self.rootItems["in_button_1"]:setTouchPriority(self.touchPriority)
            self.rootItems["in_button_1"]:setSwallowsTouch(true)
        end
       
    end
end

function jewelUp.commpondSuccess(self,t)
    if t.reward[tostring(1)] then
        showRewardPopupWindow(t.reward)
    else
        runGamePrompt({msg = gameConfig.strings:string_common("artifact",55)})
    end
    self.props = {}
    self.jewelDatas = nil
    self:getUseIdNum()
end


function jewelUp.initFixedString(self)
    ui.setLabelString(self.rootItems.title,gameConfig.strings:string_common("artifact",50),65)
    self.rootItems.fixed2:setString(gameConfig.strings:string_common("attr_type","atk"))
    self.rootItems.fixed3:setString(gameConfig.strings:string_common("attr_type","def"))
    self.rootItems.fixed4:setString(gameConfig.strings:string_common("attr_type","hp"))
    self.rootItems.fixed5:setString(gameConfig.strings:string_common("fixedString","general",1))
    ui.setLabelString(self.rootItems.fixed6,gameConfig.strings:string_common("artifact",107),125)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("artifact",51),19)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("artifact",52),19)
    self.rootItems.useL1:setString(gameConfig.strings:string_common("fixedString","devil",15))
    self.rootItems.useL2:setString(gameConfig.strings:string_common("fixedString","devil",15))
end

function jewelUp.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.x, self.cellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(cellCCB,ccbDocumentControler,self.jewelConfigs[self.selectPage][a1+1])

            if first then
                a2:addChild(cellCCB)
                cellCCB:setPosition(self.cellSize.x/2,self.cellSize.y/2 + 45)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = #self.jewelConfigs[self.selectPage]
        elseif fn == "cellTouched" then
            self.selectId = self.jewelConfigs[self.selectPage][a1:getIdx() + 1].id
            --print("lipurposes cellTouched ",a1:getIdx(),self.selectId)
            if not self.jewelDatas[tostring(self.selectId)] or self.jewelDatas[tostring(self.selectId)].num < 1 then
                runGamePrompt({msg = gameConfig.strings:string_common("artifact",112)})
                gameWindows:openWindow("dropTips",{cid = self.selectId},nil)
            end
            self:setButtonState()
            self.listTableView:reloadData()
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.jewelList:getContentSize().width,
        viewheight = self.rootItems.jewelList:getContentSize().height,
        dire = 0
    })
    self.rootItems.jewelList:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority)
end

function jewelUp.setCell(self,node,items,data)
    printT(items,"lipurposes are are")
    local num = self.jewelDatas[tostring(data.id)] and self.jewelDatas[tostring(data.id)].num or 0
    ui.setNewIcon(items,{cid=data.id,num=num},0)

    if not items.nameStr then
        items.nameStr = CCLabelTTF:create()
        items.nameStr:setPosition(90,-25)
        node:addChild(items.nameStr)
    end
    ui.setLabelString(items.nameStr,gameConfig.strings:string_format({"artifact",99},{data.lv}),(data.quality == 0 and 1 or data.quality) * 2)
    
    if not items.selectNode then
        local ccb, item = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
        node:addChild(ccb)
        ccb:setPosition(93,81)
        ccb:setScale(1.2)
        items.selectNode = ccb
    end
    items.selectNode:setVisible(data.id == self.selectId)
end


function jewelUp.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.listTableView = nil

    self.jewelDatas = nil
    self.selectId = nil
    self.props = {}
    self.canCommpondNum = 0
end

return jewelUp  *A  