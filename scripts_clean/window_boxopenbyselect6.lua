--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/12/28
-- Time: 10:15
-- To change this template use File | Settings | File Templates.
--

local boxselect = {
    rootNode = nil,
    rootItems = nil,

    usenum = 1,
    hasnum = 0,
    choose = 0,

    propcids = {},
    isOnce = true,
    data = {},
}

function boxselect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/tc_duocikaiqi6", nil, true, "tc_duocikaiqi")

    self.touchPriority = touchPriority

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.usenum,self.touchPriority,function (num)
        self.usenum = 0
        self:numchange(num)
    end)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("boxselect6")
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


    -- ui.setLabelString(self.rootItems.doLab,"确 定",19)
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("popups","queding"),19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if not (self.choose and tonumber(self.choose) > 0) then
            -- runGamePrompt({msg = "请选择一种获得物品"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","boxselect")})
        elseif self.usenum >0 then
            if self.usenum <= self.hasnum then
                UIRequest({type = 1201,cid = self.data.id, num = self.usenum, choose = self.choose})
            end

            gameWindows:closeWindowDirect("boxselect6")

        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    self:reload(data,callback)

    return self.rootNode
end

function boxselect.setbuydata(self)
    self.rootItems.usenum:setString("x"..self.usenum)
end

function boxselect.numchange(self,num)
    if self.usenum == self.hasnum and self.usenum+num > self.hasnum then
        runGamePrompt({msg = gameConfig.strings:string_common("popups","boxopenmax")})
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
    elseif self.usenum <= 0 then
        self.usenum = 0
    end
    self:setbuydata()
end

function boxselect.setPropdata(self)
    for i = 1,6 do
        if self.propcids[i] and self.propcids[i].cid and tonumber(self.propcids[i].cid) == tonumber(self.choose) then
            self.rootItems["select"..i]:setVisible(true)
        else
            self.rootItems["select"..i]:setVisible(false)
        end
    end
end

function boxselect.reload(self,data,callback)
    self.callback = callback

    if data then
        self.data = data
    end

    self.usenum = 1
    self.hasnum = self.data.num or 0
    self.choose = 0
    self.propcids = {}

    --
    local boxconfig = gamedata.config.props[tostring(self.data.id)] or {}
    if boxconfig["function"] and boxconfig["function"] == "box4" then
        self.propcids = ui.getIDandNUMs(boxconfig.param1)
    else
        self.propcids = ui.getGeneralID(boxconfig.param1)
    end    
    --
    for i = 1,6 do
        if self.propcids[i] and self.propcids[i].cid then
            self.rootItems["propnode"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,{cid = self.propcids[i].cid, num = self.propcids[i].num or 1},i-1)
            ui.setLabelString(self.rootItems["propname"..i],ui.IDconfig(self.propcids[i].cid).name or "",((ui.IDconfig(self.propcids[i].cid).quality and ui.IDconfig(self.propcids[i].cid).quality ~= 0) and ui.IDconfig(self.propcids[i].cid).quality or 1)*2)
            --
            self.rootItems["i_button"..(i<2 and "" or ("_"..(i-1)))]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(self.propcids[i].cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..(i<2 and "" or ("_"..(i-1)))]:setTouchPriority(self.touchPriority)
            --
            self.rootItems["selectButton"..i]:addHandleOfControlEvent(function()
                self.choose = self.propcids[i].cid or 0
                self:setPropdata()
            end, CCControlEventTouchUpInside)
            self.rootItems["selectButton"..i]:setSwallowsTouch(true)
            self.rootItems["selectButton"..i]:setTouchPriority(self.touchPriority-1)
        else
            self.rootItems["propnode"..i]:setVisible(false)
        end
    end

    self:setPropdata()
    self:setbuydata()
end


function boxselect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.isOnce = true
    if self.callback then
        self.callback()
    end

end

return boxselect
