--
-- Author: songyibo
-- Date: 2020-02-11 18:32:13
--
--
-- Author: songyibo
-- Date: 2020-02-11 17:08:23
--

local confirm = {
    rootNode = nil,
    rootItems = nil,
}

function confirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("youxizhushou/tc_tips", nil, true, "tc_tip")

    self.touchPriority = touchPriority
    self.callback = callback

    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","quxiao"),18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)

    self.rootItems.copyNode:setVisible(false)
	self.rootItems.confirmNode:setVisible(false)

	printT(data,"confirm")

    self:reloadConfirm(data)
    return self.rootNode
end

function confirm.reloadConfirm(self,data)

    local contents = {}

    local coinnum = data.data[1000] or 0
    local goldnum = data.data[1001] or 0
    local g_goldnum = data.data[1025] or 0

    contents[1] = {fontID = 131,content = "本次执行将消耗 ",fontSize = 40}

    if goldnum > 0 then
        table.insert(contents,{fontID = 0,content = gameConfig.images["s_icon_1001"],scale = 1})
        table.insert(contents,{fontID = 131,content = goldnum,fontSize = 40})
    end

    if g_goldnum > 0 then
        if goldnum > 0 then
            table.insert(contents,{fontID = 131,content = ", ",fontSize = 40})
        end
        table.insert(contents,{fontID = 0,content = gameConfig.images["s_icon_1025"],scale = 0.4})
        table.insert(contents,{fontID = 131,content = g_goldnum,fontSize = 40})
    end

    if coinnum > 0 then
        if goldnum > 0 or coinnum > 0 then
            table.insert(contents,{fontID = 131,content = ", ",fontSize = 40})
        end
        table.insert(contents,{fontID = 0,content = gameConfig.images["s_icon_1000"],scale = 1})
        table.insert(contents,{fontID = 131,content = coinnum,fontSize = 40})
    end
    table.insert(contents,{fontID = 131,content = " 是否执行？",fontSize = 40})

    ui.createRichLabel(contents,self.rootItems["richNode"],false,{horizontal = "center", vertical = "center"})

	-- self.rootItems.confirmNode:setVisible(true)
	-- local coinnum = data.data[1000] or 0
	-- local goldnum = data.data[1001] or 0

 --    self.rootItems.gold:setString(goldnum)
 --    self.rootItems.coin:setString(coinnum)

	-- --没有银币
	-- if coinnum > 0 and goldnum > 0 then
	-- 	self.rootItems.confirmNode:setPositionX(-30)
	-- 	self.rootItems.coinNode:setPositionX(130)
 --        self.rootItems.goldNode:setVisible(true)
 --        self.rootItems.coinNode:setVisible(true)
 --        self.rootItems.des2:setPositionX(260)
	-- elseif coinnum > 0 then
	-- 	self.rootItems.confirmNode:setPositionX(40)
	-- 	self.rootItems.coinNode:setPositionX(-40)
	-- 	self.rootItems.des2:setPositionX(90)
 --        self.rootItems.goldNode:setVisible(false)
 --        self.rootItems.coinNode:setVisible(true)
	-- elseif goldnum > 0 then
	-- 	self.rootItems.confirmNode:setPositionX(40)
	-- 	self.rootItems.goldNode:setPositionX(-40)
	-- 	self.rootItems.des2:setPositionX(90)
 --        self.rootItems.coinNode:setVisible(false)
 --        self.rootItems.goldNode:setVisible(true)
	-- else
	-- 	self.rootItems.confirmNode:setVisible(false)
	-- end

	self.rootItems.concel:addHandleOfControlEvent(function()
        gameWindows:closeWindow("gameHelperConfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("gameHelperConfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback()
        gameWindows:closeWindow("gameHelperConfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

end

function confirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end

return confirm

