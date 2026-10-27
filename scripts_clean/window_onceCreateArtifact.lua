

local onceCreateArtifact = {
    rootNode = nil,
    rootItems = nil,

    usenum = 0,

    data = {},
    isSelectState = false,
    itemNum = 0,

}

function onceCreateArtifact.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_yijiandazao", nil, true, "tc_yijiandazao")
    self.touchPriority = touchPriority

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,self.touchPriority,function (num)
        self.usenum = 0
        self:numchange(num)
    end)    

    self.rootItems.autobutton1:addHandleOfControlEvent(function()
        self.isSelectState = false
        self:setSelectState()
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton1:setSwallowsTouch(true)
    self.rootItems.autobutton1:setTouchPriority(self.touchPriority)

    self.rootItems.autobutton2:addHandleOfControlEvent(function()
        self.isSelectState = true
        self:setSelectState()
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton2:setSwallowsTouch(true)
    self.rootItems.autobutton2:setTouchPriority(self.touchPriority)

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("onceCreateArtifact")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
        self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    
    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
        self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.noLab,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("onceCreateArtifact")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.usenum > 0 then
            if self.usenum <= self.exchangeNum then
                -- self.callback(self.usenum)
                self:onSendArtifactMessage()
                gameWindows:closeWindowDirect("onceCreateArtifact")
            end
        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

    self:reload(data,callback)

    return self.rootNode
end

function onceCreateArtifact.setSelectState(self)
    self.rootItems.autosprite1:setVisible(not self.isSelectState)
    self.rootItems.autosprite2:setVisible(self.isSelectState)

    self:numchange(0)
    if self.isSelectState == true then
        self.rootItems.exchangeNumLab:setString("当前可打造数量:"..self.itemNum)
    else
        self.rootItems.exchangeNumLab:setString("当前可打造数量:"..self.exchangeNum)
    end
end

-- 发送
function onceCreateArtifact.onSendArtifactMessage(self )
    -- body 打造神器的数量
    -- self.usenum
    local state = 0
    if self.isSelectState == true then
        state = 1
    end
    -- printT(" onceCreateArtifact self.data  ",self.data)
    UIRequest({type = 5515 ,curType = state,count = self.usenum,props = self.data.props})
end

function onceCreateArtifact.setbuydata(self)
    self.rootItems.buynum:setString(self.usenum)
end

function onceCreateArtifact.numchange(self,num)
    -- if self.usenum == self.exchangeNum and self.usenum+num > self.exchangeNum then
    --     runGamePrompt({msg = "达到可兑换上限"})
    -- end
    self.usenum = self.usenum + num
    if  self.usenum > self.exchangeNum or (self.isSelectState == true and self.usenum > self.itemNum) then
        -- runGamePrompt({msg = "材料不足"})
    end
    if self.usenum > self.exchangeNum then
        self.usenum =  self.exchangeNum
    end

    if self.isSelectState == true and self.usenum >= self.itemNum then
        self.usenum = self.itemNum
    end

    if self.usenum <= 0 then
        self.usenum = 0
    elseif self.usenum > tonumber(gamedata.config.trump_config.make_max.value) then
        runGamePrompt({msg = "达到可打造上限"})
        -- runGamePrompt({msg = "一次最多使用"..gamedata.config.trump_config.make_max.value.."个"})
        self.usenum = tonumber(gamedata.config.trump_config.make_max.value)
    end

    self:setbuydata()
end

function onceCreateArtifact.setPropdata(self,data)
    self.data = data
    printT(self.data,"self.data   --- ")
    self.exchangeNum = self.data.exchangeNum or 0
    self.itemNum = math.min(self.data.count,self.data.exchangeNum)
    self.rootItems.exchangeNumLab:setString("当前可打造数量:"..self.data.exchangeNum)

end


function onceCreateArtifact.reload(self,data,callback)
    self.callback = callback
    self:setPropdata(data)
    self:setbuydata()
    self:setSelectState()
end

function onceCreateArtifact.reloadData(self,data)
    self:setPropdata(data)
    self:numchange(0)
end

function onceCreateArtifact.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    -- self.isSelectState = false
    -- self.callback = nil
    -- if self.callback then
    --     self.callback(self.usenum)
    -- end
    self.usenum = 0
end

return onceCreateArtifact