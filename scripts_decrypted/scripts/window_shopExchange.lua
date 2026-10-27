--多次兑换弹窗

local shopExchange = {
    rootNode = nil,
    rootItems = nil,

    usenum = 1,
    isOnce = true,
    data = {},
}

function shopExchange.open(self,touchPriority,data,callback)

    printT(data,"shopExchange")
    if data and data.ccbtype and data.ccbtype == 2 then
        self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_exchangeMore2", nil, true, "tc_exchangeMore2")
    else
        self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_exchangeMore", nil, true, "tc_exchangeMore")
        -- 添加输入数字功能 
        ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.usenum,touchPriority,function (num)
            self.usenum = 0
            self:numchange(num)
        end) 
    end

    self.touchPriority = touchPriority
    self.isOnce = true

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("shopExchange")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.add1:addHandleOfControlEvent(function()
        if not data.delaybutton then
            self:numchange(1)
        end
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
        if not data.delaybutton then
            self:numchange(10)
        end
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    
    self.rootItems.sub1:addHandleOfControlEvent(function()
        if not data.delaybutton then
            self:numchange(-1)
        end
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
        if not data.delaybutton then
            self:numchange(-10)
        end
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("shopExchange")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.usenum >0 then
            if self.usenum <= self.exchangeNum then
                --self.callback(self.usenum)
                gameWindows:closeWindow("shopExchange")
            end
        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    self:reload(data,callback)

    if data.delaybutton then
        self:createDelayButton()
    end
    return self.rootNode
end

function shopExchange.createDelayButton(self)
    local beginFunc = function(index,quick)

    end

    local endFunc = function(index)
        
    end
    local Func1 = function(donum)
        self:numchange(1)
    end

    local Func2 = function(donum)
        self:numchange(10)
    end

    local reduce1 = function(donum)
        self:numchange(-1)
    end

    local reduce2 = function(donum)
        self:numchange(-10)
    end

    ui.creatDelayButton(self.rootItems["add1"],self.touchPriority - 1,Func1,beginFunc,endFunc,1)
    ui.creatDelayButton(self.rootItems["add10"],self.touchPriority - 1,Func2,beginFunc,endFunc,2)

    ui.creatDelayButton(self.rootItems["sub1"],self.touchPriority - 1,reduce1)
    ui.creatDelayButton(self.rootItems["sub10"],self.touchPriority - 1,reduce2)
end

function shopExchange.setbuydata(self)
    if self.exchangeNum > 0 then
        if self.usenum <= 0 then
            self.usenum = 1
        end
    end
    self.rootItems.usenum:setString(self.usenum)

    for i=1,2 do
        if self.data and self.data.cost and self.data.cost[i] then
            self.rootItems["costLab"..i]:setString(self.data.cost[i].num*self.usenum)
        end
    end
end

function shopExchange.numchange(self,num)
    -- if self.usenum == self.exchangeNum and self.usenum+num > self.exchangeNum then
    --     runGamePrompt({msg = "达到可兑换上限"})
    -- end

    --消耗数量加限制
    if self.hasCostNum and self.hasCostNum > 0 and num > 0 then
        local _num = 1

        while num >= _num do
            if (self.usenum+_num) * self.data.cost[1].num > self.hasCostNum then
                break
            end
            _num = _num + 1
        end
        num = _num - 1

        print(self.hasCostNum,self.data.cost[1].num,_num)
    end


    if  self.usenum+num >= self.exchangeNum then
        runGamePrompt({msg = "达到可兑换上限"})
    end
    if self.usenum == 1 then
        if num == 10 and self.isOnce == true then
            self.usenum = 10
        else
            self.usenum = self.usenum + num
        end
    else
        self.usenum = self.usenum + num
    end

    if self.usenum > self.exchangeNum then
        self.usenum =  self.exchangeNum
    end
    
    if self.usenum <= 0 then
        self.usenum = 0
    elseif self.usenum > 100 then
        self.usenum = 100
        runGamePrompt({msg = "一次最多使用100个"})
    end

    self:setbuydata()
end

function shopExchange.setPropdata(self,data)
    self.data = data
    printT(self.data,"self.data   --- ")
    self.exchangeNum = self.data.exchangeNum or 0
    local configdata = ui.IDconfig(data.cid)
    ui.setNewIcon(self.rootItems,{cid = data.cid,num = self.data.num})
    ui.setLabelString(self.rootItems.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)
    self.rootItems.exchangeNumLab:setString("可兑换购买次数："..self.data.exchangeNum)

    for i=1,2 do
        if self.data and self.data.cost and self.data.cost[i] then
            self.rootItems["costNode"..i]:setVisible(true)
            local costconfig = ui.IDconfig(self.data.cost[i].cid)
            setSpriteFrameByName(self.rootItems["costSpr"..i],costconfig.icon)
            self.rootItems["costLab"..i]:setString(self.data.cost[i].num)
        else
            self.rootItems["costNode"..i]:setVisible(false)
        end
    end

    if configdata.type == "keybox" then
        UIRequest({type = 12001, order = 33090, cids = {tonumber(data.cid),tonumber(configdata.param1)}})
    else
        local cids = {tonumber(data.cid)}
        --限制消耗道具数量不够 新加需求
        if self.data.limit_cost then
            if data.cost and data.cost[1] and data.cost[1].cid then
                table.insert(cids,data.cost[1].cid)
            end
        end
        UIRequest({type = 12001, order = 33090, cids = cids})
    end

end

function shopExchange.setpropNum(self,data)
    self.hasnum = data[tostring(self.data.cid)] or 0
    self.hasCostNum = nil
    if self.data.limit_cost then
        self.hasCostNum = data[tostring(self.data.cost[1].cid)] or 0
    end

    printT(data,"setpropNum  --- ")
    if not self.data.limit_cost then
        for k,v in pairs(data) do
            self.hasnum = math.min(self.hasnum,v)
        end
    end
    
    if ui.IDconfig(self.data.cid) and ui.IDconfig(self.data.cid).staffType == "sigil" then
        self.rootItems["hasnum"]:setString("")
    else    
        self.rootItems["hasnum"]:setString("当前拥有："..tostring(self.hasnum))
    end
end

function shopExchange.reload(self,data,callback)
    self.callback = callback
    self:setPropdata(data)
    self:setbuydata()
end

function shopExchange.reloadData(self,data)
    self:setPropdata(data)
    self:numchange(0-self.usenum+1)
end

function shopExchange.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.isOnce = true
    if self.callback then
        self.callback(self.usenum)
    end
    self.usenum = 1
end

return shopExchange
 _#  