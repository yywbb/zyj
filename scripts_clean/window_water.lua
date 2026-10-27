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

    usenum = 10,

    data = {},
}

function buy.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhongshu/water", nil, true, "water")

    self.touchPriority = touchPriority

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,self.touchPriority,function (num)
        self.usenum = 0
        self:numchange(num)
    end) 

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("water")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
        self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
        self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)


    -- ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("water")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.usenum >0 then
            gameWindows:closeWindowDirect("water")
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
    self.rootItems.buynum:setString(self.usenum)
end

function buy.numchange(self,num)
    if self.usenum+num > self.hasnum then
        runGamePrompt({msg = "达到可使用上限"})
    end
    self.usenum = self.usenum + num

    if self.usenum > self.hasnum then
        self.usenum =  self.usenum-num
    end
    
    if self.usenum <= 0 then
        self.usenum = 0
    end
    self:setbuydata()
end

function buy.setPropdata(self,data)
    self.data = data
    local configdata = ui.IDconfig(data.id)
    
    self.hasnum = data.total
    self.rootItems["hasnum"]:setString("当前拥有"..configdata.name..":"..self.hasnum)
end

function buy.reload(self,data,callback)
    self.callback = callback
    self:setPropdata(data)
    self:setbuydata()
end

function buy.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    --self.needeffect = nil

    if self.callback then
        self.callback(self.usenum)
    end
    self.usenum = 10
end

return buy