-- 复用加速弹窗的原生底板和游戏按钮，不保存自动付费选择。
local window = {}
local modes = {{"progress","自动推图"},{"stars","扫描补星"},{"sweep","循环扫荡"}}

local function title(button, text)
    for _, state in ipairs({CCControlStateNormal,CCControlStateHighlighted,CCControlStateDisabled}) do
        button:setTitleForState(text,state)
    end
end

function window.open(self, priority, data)
    self.mode, self.buy, self.reset, self.pill = "progress", false, false, false
    self.rootNode = CCNode:create()
    self.rootNode:setContentSize(CCSizeMake(800,840))
    self.rootNode:setAnchorPoint(ccp(0.5,0.5))
    local background = CCScale9Sprite:createWithSpriteFrame(CCSprite:create("GM/GMTool/GMTool_bg1.png"):displayFrame())
    background:setPreferredSize(CCSizeMake(800,840))
    background:setPosition(ccp(400,420))
    self.rootNode:addChild(background)
    local function label(text,y,size)
        self.rootNode:addChild(ui.createLabel({text=text,x=400,y=y,fontsize=size or 26}))
    end
    local function button(text,x,y,width,callback)
        local b = CCControlButton:create(text,"Helvetica-Bold",28)
        b:setPreferredSize(CCSizeMake(width,76))
        b:setPosition(ccp(x,y))
        setControlButtonFrame(b,"b_n_button5")
        setControlButtonTitleColor(b,ccc3(82,42,14))
        b:setTouchPriority(priority)
        b:setSwallowsTouch(true)
        b:addHandleOfControlEvent(callback,CCControlEventTouchUpInside)
        self.rootNode:addChild(b)
        return b
    end
    label("普通副本挂机",770,34)
    label("打开面板即暂停；在途操作仍正常结算",716,24)
    self.modeButtons = {}
    for i, row in ipairs(modes) do
        local key = row[1]
        self.modeButtons[key] = button(row[2],400,664-(i-1)*86,640,function()
            self.mode = key
            for _, item in ipairs(modes) do title(self.modeButtons[item[1]],(item[1] == key and "已选：" or "")..item[2]) end
        end)
    end
    title(self.modeButtons.progress,"已选：自动推图")
    self.pillButton = button("自动用体力丹：关",400,408,640,function()
        self.pill = not self.pill;title(self.pillButton,"自动用体力丹："..(self.pill and "开" or "关"))
    end)
    self.buyButton = button("自动买体力：关",230,322,320,function()
        self.buy = not self.buy;title(self.buyButton,"自动买体力："..(self.buy and "开" or "关"))
    end)
    self.resetButton = button("自动重置：关",570,322,320,function()
        self.reset = not self.reset;title(self.resetButton,"自动重置："..(self.reset and "开" or "关"))
    end)
    label("补星每轮每关一次；扫荡选择进度最靠后的三星关",266,24)
    label("买体力按当前报价；重置每次挑战次数×5元宝",232,24)
    label("体力丹按缺口优先使用；开启补给可能连续消耗元宝",198,24)
    self.startButton = button("开始挂机",230,118,280,function()
        local mode, buy, reset, pill = self.mode, self.buy, self.reset, self.pill
        gameWindows:closeWindowDirect("localAutoCopy")
        AutoCopyStart(mode,buy,reset,pill)
    end)
    self.startButton:setEnabled(not (data and data.pending))
    self.stopButton = button("停止挂机",570,118,280,function()
        AutoCopyStop("挂机已停止，已发出的操作仍会正常结算")
        gameWindows:closeWindowDirect("localAutoCopy")
    end)
    self.closeButton = button("关闭",692,770,130,function() gameWindows:closeWindow("localAutoCopy") end)
    return self.rootNode
end

function window.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode, self.modeButtons = nil, nil
    self.buyButton, self.resetButton, self.pillButton, self.startButton, self.stopButton, self.closeButton = nil,nil,nil,nil,nil,nil
end

return window
