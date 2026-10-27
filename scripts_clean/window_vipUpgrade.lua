--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/26
-- Time: 下午4:02
-- To change this template use File | Settings | File Templates.
--

local vipUpgrade = {
    rootNode = nil,
    rootItems = nil,

    -- cancelTip = "vipUpgrade",
}

function vipUpgrade.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/vipget", nil, true, "vipget")

    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function vipUpgrade.reload(self, data, callback)
	local configVip = gamedata.config:getConfigByName("vip")[tostring(data.vip)].gift
	-- local configProps = gamedata.config:getConfigByName("props")
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("vipUpgrade")
        -- UIRequest({type = 10012})            --    打印人物的信息 
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local shareshow = gameConfig:checkBuildOpen(153)

    if shareshow then
        ui.setLabelString(self.rootItems.shareText, "分 享", 19)
        self.rootItems.shareBtn:addHandleOfControlEvent(function()
            print("分享")
            gameWindows:closeWindow("vipUpgrade")
        -- UIRequest({type = 10012})
        end, CCControlEventTouchUpInside)
        self.rootItems.shareBtn:setSwallowsTouch(true)
        self.rootItems.shareBtn:setTouchPriority(self.touchPriority)
    else
        self.rootItems.shareNode:setVisible(false)
    end

    self.rootItems.confirmNode:setPositionX(shareshow and 744 or 540)

    -- 确定
    ui.setLabelString(self.rootItems.confirmtext, gameConfig.strings:string_common("popups","queding"),19)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        gameWindows:closeWindow("vipUpgrade")
        -- UIRequest({type = 10012})
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)    

    self.rootItems.toBuyBtn:addHandleOfControlEvent(function()
        -- 跳商城
        GameScene:shiftLayerById(42)
        gameWindows:closeWindow("vipUpgrade")
    end, CCControlEventTouchUpInside)
    self.rootItems.toBuyBtn:setSwallowsTouch(true)
    self.rootItems.toBuyBtn:setTouchPriority(self.touchPriority) 

    ui.setNewIcon(self.rootItems,{cid = configVip},0)

    if data.vip < 10 then
    	-- 显示个位
    	self.rootItems.vipLab1:setVisible(true)
    	self.rootItems.vipLab2:setVisible(false)
    	setSpriteFrameByName(self.rootItems.vipLab1, ("n_vip" .. data.vip) or "alpha")
    else
    	-- 显示十位 个位
    	self.rootItems.vipLab1:setVisible(true)
    	self.rootItems.vipLab2:setVisible(true)
    	setSpriteFrameByName(self.rootItems.vipLab1, ("n_vip" .. math.floor(data.vip/10)) or "alpha")
    	setSpriteFrameByName(self.rootItems.vipLab2, ("n_vip" .. (data.vip%10)) or "alpha")
    end
end

function vipUpgrade.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    -- if guide.controller then
    --     guide.controller:UIComplete(8048)
    -- end

    -- if self.callback then
    --     self.callback()
    -- end
end

return vipUpgrade