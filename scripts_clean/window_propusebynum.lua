--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/11/2
-- Time: 下午5:37
-- To change this template use File | Settings | File Templates.
--

local buy = {
    rootNode = nil,
    rootItems = nil,

    usenum = 1,
    isOnce = true,
    data = {},
}

function buy.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("equip_new/tc_daoju2", nil, true, "tc_daoju")

    self.touchPriority = touchPriority
    self.isOnce = true

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.usenum,self.touchPriority,function (num)
        self.usenum = 0
        self:numchange(num)
    end)
    
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("propusebynum")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
        self:numchange(10)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    self.rootItems.add100:addHandleOfControlEvent(function()
        self:numchange(100)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.add100:setSwallowsTouch(true)
    self.rootItems.add100:setTouchPriority(self.touchPriority)

    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
        self:numchange(-10)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)

    self.rootItems.sub100:addHandleOfControlEvent(function()
        self:numchange(-100)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.sub100:setSwallowsTouch(true)
    self.rootItems.sub100:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("propusebynum")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.usenum >0 then
            if self.usenum <= self.hasnum then
                UIRequest({type = 1201,cid = self.data.id, num = self.usenum})
            end
            if self.usenum == self.hasnum then
                gameWindows:closeWindowDirect("propusebynum")
            end
        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    self:reload(data,callback)

    return self.rootNode
end

function buy.setbuydata(self)
    self.rootItems.usenum:setString(self.usenum)
end

function buy.numchange(self,num)
    if self.usenum == self.hasnum and self.usenum+num > self.hasnum then
        runGamePrompt({msg = "达到可使用上限"})
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

    if self.usenum > self.hasnum then
        self.usenum =  self.hasnum
    end
    
    if self.usenum <= 0 then
        self.usenum = 1
    elseif self.usenum > 100 then
        self.usenum = 100
        runGamePrompt({msg = "一次最多使用100个"})
    end
    self:setbuydata()
end

function buy.setPropdata(self,data)
    self.data = data
    local configdata = ui.IDconfig(data.id)
    ui.setIconLv(self.rootItems,{cid = data.id})
    ui.setLabelString(self.rootItems.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)

    if configdata.type == "keybox" then
        UIRequest({type = 12001, order = 12011, cids = {data.id,tonumber(configdata.param1)}})
    else
        UIRequest({type = 12001, order = 12011, cids = {data.id}})
    end

end

function buy.setpropNum(self,data)
    self.hasnum = data[tostring(self.data.id)] or 0
    printT(data)
    for k,v in pairs(data) do
        self.hasnum = math.min(self.hasnum,v)
    end
    self.rootItems["hasnum"]:setString(tostring(self.hasnum))
    if not self.needeffect then
        self.needeffect = true
    else
        local scaleTo1 = CCScaleTo:create(0.2, 1.7,1.7)
        local scaleTo2 = CCScaleTo:create(0.2, 1,1)
        self.rootItems["hasnum"]:runAction(CCSequence:createWithTwoActions(scaleTo1,scaleTo2))
    end
end

function buy.reload(self,data,callback)
    self.callback = callback
    self:setPropdata(data)
    self:setbuydata()
end

function buy.reloadData(self,data)
    self:setPropdata(data)
    self:numchange(0-self.usenum+1)
end

function buy.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.needeffect = nil
     self.isOnce = true
    if self.callback then
        self.callback()
    end
    self.usenum = 1
end

return buy