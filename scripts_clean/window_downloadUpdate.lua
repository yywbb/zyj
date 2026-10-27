--新版本更新的显示

local downloadUpdate = {
	rootNode = nil,
	rootItems = nil,
}

function downloadUpdate.open(self,touchPriority,data,callback)
	self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_xiazai",nil,true,"xiazai")
	self.touchPriority = touchPriority
	self:reload(data,callback)
--	ui.setLabelString(self.rootItems["cancleLabel"],nil,19)
    ui.setLabelString(self.rootItems["certainLabel"],nil,19)
    --ui.isWiFI3G()wifi 返回2  没网返回0  手机网返回 1
    if ui.isWiFI3G() == 1 then
        print("mobleNet")
        -- self.rootItems.moblenet:setString("您现在不是WIFI环境")
        self.rootItems.moblenet:setString(gameConfig.strings:string_common("popups","nowifi"))
        ui.setLabelString(self.rootItems["moblenet"],nil,17)
        self.rootItems.wifiState:setVisible(true)
    elseif ui.isWiFI3G() == 2 then
        print("wifiNet")
        -- self.rootItems.moblenet:setString("您现在使用的是WIFI网络")
        self.rootItems.moblenet:setString(gameConfig.strings:string_common("popups","yeswifi"))
        ui.setLabelString(self.rootItems["moblenet"],nil,17)
        self.rootItems.wifiState:setVisible(false)
    else
        print("noprint")
        -- self.rootItems.moblenet:setString("你现在网络已经断开，请链接网络")
        self.rootItems.moblenet:setString(gameConfig.strings:string_common("popups","noweb"))
        ui.setLabelString(self.rootItems["moblenet"],nil,17)
        self.rootItems.wifiState:setVisible(true)
    end
    --更新的大小
    local length = data.length or 0

    if length < 1048576 then
        length = math.floor(length/1024)
        -- self.rootItems.gameupdate:setString("游戏需要下载大约"..length.."KB的更新")
        self.rootItems.gameupdate:setString(gameConfig.strings:downnumKB(length))
    elseif length >= 1048576 then 
        length = string.format("%0.1f",length/1048576)
        --length = math.floor(length/1048576)
        -- self.rootItems.gameupdate:setString("游戏需要下载大约"..length.."M的更新")
        self.rootItems.gameupdate:setString(gameConfig.strings:downnumM(length))
    end
    -- self.rootItems.gameupdate:setString("游戏需要下载大约".."100M".."的更新")
    ui.setLabelString(self.rootItems["gameupdate"],nil,17)
    return self.rootNode
end

function downloadUpdate.reload(self,data,callback)
	self.callback = callback

--    --取消按钮
--    self.rootItems.cancleButton:addHandleOfControlEvent(function()
--    	self.callback = nil
--        gameWindowslogin:closeWindowDirect("downloadUpdate")
--    end,CCControlEventTouchUpInside)
--    self.rootItems.cancleButton:setSwallowsTouch(true)
--    self.rootItems.cancleButton:setTouchPriority(self.touchPriority)

    --确定按钮
    self.rootItems.certainButton:addHandleOfControlEvent(function()
        -- self.callback = nil
        gameWindowslogin:closeWindowDirect("downloadUpdate")
    end,CCControlEventTouchUpInside)
    self.rootItems.certainButton:setSwallowsTouch(true)
    self.rootItems.certainButton:setTouchPriority(self.touchPriority)

end

function downloadUpdate.close(self)
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
    	self.callback()
    end
end

return downloadUpdate

