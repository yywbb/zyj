--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/1/13
-- Time: 17:01
-- To change this template use File | Settings | File Templates.
--

local auctionNum = {
    rootNode = nil,
    rootItems = nil,
    buynum = 0,
    addnum = 0,
    auction = 0,
    maximum = 0,
}

function auctionNum.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("paimaihang/jingjia", nil, true, "jingjia")
    self.touchPriority = touchPriority

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,touchPriority,function (num)
        self.buynum = 0
        self:numchange(num)
    end)

    self:reload(data,callback)
    return self.rootNode
end

function auctionNum.reload(self,data,callback)


    local _config = gamedata.config.auction_items
    local config = _config and _config[tostring(data.id)] or {}
    local reward = ui.getIDRandNum(config.reward)

    self.buynum = data.auction or 0
    self.addnum = config.single or 0
    self.auction = data.auction or 0
    self.maximum = config.maximum or 0

    if self.maximum > 0 then
        self.rootItems.priceNode:setVisible(true)
    else
        self.rootItems.priceNode:setVisible(false)
    end

    ui.setNewIcon(self.rootItems,{cid = reward[1], num = reward[2]})

    self.rootItems.name:setString(ui.IDconfig(reward[1]).name)

    self.rootItems.auction:setString(data.auction)
    self.rootItems.price:setString(config.maximum)

    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("auctionNum")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    ui.setLabelString(self.rootItems.doLab1,nil,19)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("auctionNum")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    --
    ui.setLabelString(self.rootItems.doLab2,nil,19)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 4811,id = data.id,num = self.buynum})
        gameWindows:closeWindow("auctionNum")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)
    --

    self.rootItems.subLab1:setString("-"..self.addnum)
    self.rootItems.subLab10:setString("-"..self.addnum*10)
    self.rootItems.addLab1:setString("+"..self.addnum)
    self.rootItems.addLab10:setString("+"..self.addnum*10)


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

    self:numchange(1)
end

function auctionNum.numchange(self,num)

    if (self.buynum + self.addnum*num) <= self.auction then
        runGamePrompt({msg = gameConfig.strings:string_common("auction",5)})
    elseif (self.maximum > 0) and ((self.buynum + self.addnum*num) >= self.maximum) then
        runGamePrompt({msg = gameConfig.strings:string_common("auction",6)})
    elseif (self.buynum + self.addnum*num) > GameScene.roleinfo.gold then
        shortGold()
    else
        self.buynum = self.buynum + self.addnum*num
    end

    self.rootItems.buynum:setString(self.buynum)

end

function auctionNum.close(self)
    self.buynum = 0
    self.addnum = 0
    self.auction = 0
    self.maximum = 0
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return auctionNum

