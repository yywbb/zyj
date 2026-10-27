-- 耐力密码

local nailicode = {
    rootNode = nil,
    rootItems = nil,

    callback = nil,

    index = 0,
}

function nailicode.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/2weima", nil, true, "2weima")
    self.callback  = callback

    ui.setLabelString(self.rootItems.tishi_lab, nil, 11, 32)
    
    --返回
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("nailicode")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --复制1
    self.rootItems.copybutton1:addHandleOfControlEvent(function()
        if ui.setStringToPasteBoard("NLMMYYDS") then
            runGamePrompt({msg = "复制成功"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.copybutton1:setSwallowsTouch(true)
    self.rootItems.copybutton1:setTouchPriority(self.touchPriority)

    --复制2
    self.rootItems.copybutton2:addHandleOfControlEvent(function()
        if self.index == 1 then --金奖
            if ui.setStringToPasteBoard("耐力and作妖") then
                runGamePrompt({msg = "复制成功"})
            end
        elseif self.index == 2 then --银奖
            if ui.setStringToPasteBoard("NLMM&ZYJ") then
                runGamePrompt({msg = "复制成功"})
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.copybutton2:setSwallowsTouch(true)
    self.rootItems.copybutton2:setTouchPriority(self.touchPriority)

    --说明
    self.rootItems.infobutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("nailicode_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.infobutton:setSwallowsTouch(true)
    self.rootItems.infobutton:setTouchPriority(self.touchPriority)

    --播放
    self.rootItems.playerButton:addHandleOfControlEvent(function()
        gamedata.sdk:forceUpdate("https://rescdn.zyj.52muyou.com/android/compress/zyj_20230202_sp.mp4")
    end, CCControlEventTouchUpInside)
    self.rootItems.playerButton:setSwallowsTouch(true)
    self.rootItems.playerButton:setTouchPriority(self.touchPriority)

    UIRequest({type = 8245})
        
    self.root:addChild(self.rootNode)

    return self.root
end

function nailicode.reloadData(self, data)

    if data and next(data) and GameScene.nailiactivity ~= 1 then
        local config = gamedata.config.mystery_rank
        local num = table.getTableLength(config)
        local jinjiang = {}
        local yinjiang = {}
        for i=1,num do
            local reward = config[tostring(i)].reward
            if string.find(reward,"192661") then
                local jin = {}
                jin.id = config[tostring(i)].id
                jin.rank = config[tostring(i)].rank
                table.insert(jinjiang, jin)
            end
            if string.find(reward,"192662") then
                local yin = {}
                yin.id = config[tostring(i)].id
                yin.rank = config[tostring(i)].rank
                table.insert(yinjiang, yin)
            end
        end
        local sortfunc = function (a,b)
            return a.id < b.id
        end
        table.sort(jinjiang,sortfunc)
        table.sort(yinjiang,sortfunc)

        printT(jinjiang,"jinjiang")
        printT(yinjiang,"yinjiang")

        if tonumber(data.rank) <= tonumber(yinjiang[table.getTableLength(yinjiang)].rank) then
            self.index = 2
        end
        if tonumber(data.rank) <= tonumber(jinjiang[table.getTableLength(jinjiang)].rank) then
            self.index = 1
        end
    end

    self.rootItems.anyu2:setVisible(false)
    self.rootItems.anyu3:setVisible(false)
    self.rootItems.copybutton2:setVisible(false)
    if self.index == 1 then
        self.rootItems.anyu3:setVisible(true)
        self.rootItems.copybutton2:setVisible(true)
    elseif self.index == 2 then
        self.rootItems.anyu2:setVisible(true)
        self.rootItems.copybutton2:setVisible(true)
    end
end

function nailicode.close(self) 
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.index = 0

    if self.callback then
        self.callback()
    end
end

return nailicode