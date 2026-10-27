--
-- Created by IntelliJ IDEA.
-- User: lipurpose
-- Date: 17/5/3
-- Time: 下午4:31
-- To change this template use File | Settings | File Templates.
--

local buy = {
    rootNode = nil,
    rootItems = nil,

    buynum = 0,
    adjustLength = 260,
    normalSizes = {},
    data = {},
}

function buy.setFixedString(self)
    printT(self.rootItems,"lipurposes")
    self.rootItems.fixed1:setString(string.format(gameConfig.strings:string_common("fixedString","shop",17),1))
    self.rootItems.fixed1_1:setString(string.format(gameConfig.strings:string_common("fixedString","shop",17),2))
    self.rootItems.fixed1_2:setString(string.format(gameConfig.strings:string_common("fixedString","shop",17),3))

    ui.setLabelString(self.rootItems.m_obtttf,gameConfig.strings:string_common("fixedString","goddown",7),18)
    ui.setLabelString(self.rootItems.m_obtttf_1,gameConfig.strings:string_common("fixedString","goddown",7),18)
    ui.setLabelString(self.rootItems.m_obtttf_2,gameConfig.strings:string_common("fixedString","goddown",7),18)
    
    for i = 1,5 do
        self.normalSizes[i] = self.rootItems["scale9"..i]:getContentSize()
    end
end

function buy.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shop/tc_goumaidaoju", nil, true, "tc_goumaidaoju")
    self.touchPriority = touchPriority
    --
    self:setFixedString()
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindow("buyItem")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local function buyFunc(id)
        gameTouch:clickprofbytime(0.5)
        print("self.buynum = "..self.buynum)
        if self.data.idNums then
            --print("lipurposes buy use goldnum ",self.data.idNums[id].num)
            UIRequest({type = 5345,data = {id = self.data.id,num = id == 1 and 1 or (id == 2 and 10 or 100), 
            useId = self.data.idNums[id].id,useNum = self.data.idNums[id].num}})
        end
    end

    for i = 1,3 do
        local buttonNameAdd = i == 1 and "" or "_"..(i-1)
        self.rootItems["m_obutton"..buttonNameAdd]:addHandleOfControlEvent(function()
            buyFunc(i)
        end, CCControlEventTouchUpInside)
        self.rootItems["m_obutton"..buttonNameAdd]:setSwallowsTouch(true)
        self.rootItems["m_obutton"..buttonNameAdd]:setTouchPriority(self.touchPriority)
    end

    self:reload(data,callback)
    return self.rootNode
end


function buy.setPropNum(self,data)
    if not data then
        UIRequest({type = 12001, order = 32021, cids = {self.data.id}})
        return
    end
    local num = data[tostring(self.data.id)] or 0
    self.data.num = num
    self.rootItems["jifen_time"]:setString(gameConfig.strings:string_common("fixedString","shop",18))
    self.rootItems["hasnum"]:setString(num)
    --
    self.rootItems["hasnum"]:stopAllActions()
    local scaleTo1 = CCScaleTo:create(0.2, 1.7,1.7)
    local scaleTo2 = CCScaleTo:create(0.2, 1,1)
    self.rootItems["hasnum"]:runAction(CCSequence:createWithTwoActions(scaleTo1,scaleTo2))
end

function buy.buySuccess(self,data)
    --printT(data,"lipurposes buy Success")
    showRewardPopupWindow(data)
    for k,v in pairs(data) do
        if v.cid == self.data.id then
            --print("lipurposes enter in in ")
            self.data.num = (self.data.num or 0) + v.num
            if self.callback then self.callback(self.data) end
            self:setPropNum{[tostring(self.data.id)] = self.data.num}
        end
    end

    --
    setroleupdatacallback(function()
        if gameWindows.windows["buyItem"].show then
            self:reload(self.data,self.callback)
        end
    end)

    UIRequest({type = 1001})

end

function buy.reload(self,data,callback)
    self.callback = callback
    self.data  = data
    if data.num then
        self:setPropNum{[tostring(data.id)] = data.num}
    else
        self.data.num = 0
        self:setPropNum()
    end
    --
    local idCfg = gamedata.config.gambling_gold[tostring(data.id)]
    if not idCfg then
        return 
    end
    local idNums = {}
    for i = 1,3 do
        local useStr = i == 1 and "once1" or (i == 2 and "tenfold1" or "hundredfold1")
        local itemId,itemNum = ui.getIDandNUM(idCfg[useStr])
        if itemId and itemId > 0 then
            idNums[i] = {id = itemId,num = itemNum}
        end
    end
    self.data.idNums = idNums
    --
    local heightAdd = idNums[3] and self.adjustLength or 0
    for i = 1,5 do
        self.rootItems["scale9"..i]:setContentSize(CCSizeMake(self.normalSizes[i].width,self.normalSizes[i].height + heightAdd))
    end
    self.rootItems.item3:setVisible(idNums[3] ~= nil)
    --
    for i = 1 ,#idNums do
        local useNum = i == 2 and 10 or (i == 3 and 100 or 1)
        ui.setNewIcon(self.rootItems,{cid = idNums[i].id,num = idNums[i].num},i * 2 - 2)
        ui.setNewIcon(self.rootItems,{cid = data.id,num = useNum},i * 2 - 1)
        local k_add1 = i == 1 and "" or "_"..(i * 2-2)
        local k_add2 = "_"..(i * 2-1)
        self.rootItems["i_button"..k_add1]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end  
            ui.setPopwindowByCid(idNums[i].id)
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"..k_add1]:setTouchPriority(self.touchPriority)

        self.rootItems["i_button"..k_add2]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end  
            ui.setPopwindowByCid(data.id)
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"..k_add2]:setTouchPriority(self.touchPriority)

        --
        if (idNums[i].id == 1001) and (idNums[i].num > GameScene.roleinfo.gold) then
            ui.setLabelString(self.rootItems["i_num"..k_add1], nil, 12)   
        else    
            ui.setLabelString(self.rootItems["i_num"..k_add1], nil, 13)
        end

    end
end

function buy.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    
    if self.callback then
        --print("lipurposes set num ",self.data.num)
        self.callback(self.data)
    end
    
end

return buy