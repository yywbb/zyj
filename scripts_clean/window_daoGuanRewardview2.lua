--
-- Author: songyibo
-- Date: 2018-10-11 11:38:56
--
local daoGuanRewardview = {
    rootNode = nil,
    rootItems = nil,
}

-- 打开弹窗
function daoGuanRewardview.open(self, touchPriority, data, callback)
    printT(data)
    self.rootNode, self.rootItems = CCBReaderLoad("daoguanshouwei/daoguanshouwei_jiangliYulan", nil, true, "daoguanshouwei_jiangliYulan")
    self:initFixedString()
    self:initEvent(touchPriority)
    self:reload(data, callback)

    return self.rootNode
end

-- 初始化点击事件
function daoGuanRewardview.initEvent(self, touchPriority)
    self.touchPriority = touchPriority
    self:initCloseBtn()
end

-- 初始化关闭按钮
function daoGuanRewardview.initCloseBtn(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("daoGuanRewardview2")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

-- 重新读取
function daoGuanRewardview.reload(self, data, callback)
    self.callback = callback

    local reward2 = ui.getIDandNUMs(gamedata.config.daoguan_param[tostring(data.daoguanType)].reward2)

    for i=1,3 do
    	if reward2[i] then
    		self.rootItems["reward"..i]:setVisible(true)
    		ui.setNewIcon(self.rootItems,reward2[i],i-1)
    	else
    		self.rootItems["reward"..i]:setVisible(false)
    	end
    end

    local reward1 = ui.getIDandNUMs(gamedata.config.daoguan_param[tostring(data.daoguanType)].reward1)
    for i=4,6 do
    	if reward1[i-3] then
    		self.rootItems["reward"..i]:setVisible(true)
    		ui.setNewIcon(self.rootItems,reward1[i-3],i-1)
    	else
    		self.rootItems["reward"..i]:setVisible(false)
    	end
    end
    
    local reward3 = ui.getIDandNUMs(gamedata.config.daoguan_param[tostring(data.daoguanType)].reward3)
    for i=7,9 do
        if reward3[i-6] then
            self.rootItems["reward"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,reward3[i-6],i-1)
        else
            self.rootItems["reward"..i]:setVisible(false)
        end
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
    self.rootItems.txtField1:setString(gameConfig.strings:string_common("daoguanshouwei", 6))
    self.rootItems.txtField2:setString(gameConfig.strings:string_common("daoguanshouwei", 7))
    self.rootItems.txtField3:setString(gameConfig.strings:string_common("daoguanshouwei", 43))
end

return daoGuanRewardview