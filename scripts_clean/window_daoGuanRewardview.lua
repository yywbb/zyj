local daoGuanRewardview = {
    rootNode = nil,
    rootItems = nil,
}

-- 打开弹窗
function daoGuanRewardview.open(self, touchPriority, data, callback)
    printT(data)
    self.rootNode, self.rootItems = CCBReaderLoad("daoguanshouwei/daoguanshouwei_jiangli", nil, true, "shouweijiangli")
    self:initFixedString()
    self:initEvent(touchPriority)
    self:reload(data, callback)

    return self.rootNode
end

-- 初始化点击事件
function daoGuanRewardview.initEvent(self, touchPriority)
    self.touchPriority = touchPriority
    self:initCloseBtn()
    self:initGetRewardBtn()
end

-- 初始化关闭按钮
function daoGuanRewardview.initCloseBtn(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("daoGuanRewardview")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

-- 初始化领取按钮
function daoGuanRewardview.initGetRewardBtn(self)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        -- self.callback = nil
        -- gameWindows:closeWindow("daoGuanRewardview")
        -- 领取奖励按钮
        if self.data.rewardstatus == 1 then
            UIRequest({type = 5302})
        elseif self.data.rewardstatus == 2 then
            runGamePrompt({msg = gameConfig.strings:string_common("daoguanshouwei", 31)})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("daoguanshouwei", 32)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
end

-- 重新读取
function daoGuanRewardview.reload(self, data, callback)
    self.callback = callback
    self.data = data

    -- 添加灰度
    if data.rewardstatus == 1 then
        ui.removeGray("CCControlButton",self.rootItems.doButton)
    else
        ui.addGray("CCControlButton",self.rootItems.doButton)
    end
    if data.rewardstatus == 2 then
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("buttontext", "yilingqu"),19)
    else
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("buttontext", "lingqu"),19)
    end

    local metalnum = 0
    for k,v in pairs(data.list) do
        if v>0 then 
            metalnum = 1
            break
        end
    end

    ui.setLabelString(self.rootItems.txtField1, gameConfig.strings:string_common("daoguanshouwei", 15).." ("..metalnum.."/1)", 21)
    
    
    local reward = gamedata.config.global_kv.hall_reward.value
    local t = ui.Split(reward, ";")
    local usedata = {}

    for k,v in pairs(t) do
        if v ~= "" or v == nil then
            table.insert(usedata, ui.Split(v, ","))
        end
    end

    -- printT(usedata,"  daoGuanRewardview  ")
    local len = table.getTableLength(usedata)
    print("  len  "..len)
    printT(self.rootItems,"  self.rootItems  ")

    for i = 1, 4 do
        self.rootItems["reward"..i]:setVisible(false)
    end
    
    for i = 1, len do
        self.rootItems["reward"..i]:setVisible(true)
        ui.setNewIcon(self.rootItems, {cid = usedata[i][1], num = usedata[i][2]}, i - 1)
    end
end

function daoGuanRewardview.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function daoGuanRewardview.initFixedString( self )
    ui.setLabelString(self.rootItems.title, gameConfig.strings:string_common("daoguanshouwei", 14), 14)

end

return daoGuanRewardview