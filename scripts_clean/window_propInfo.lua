--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local propInfo = {
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"info"},
    pagetype = "info",

}

function propInfo.open(self,touchPriority,data,callback)

    self.root = ui.createNode()

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.root
end

function propInfo.reload(self,data,callback)
    self.callback = callback
    self.data = data.prop or {}

    self.pagetype = data.pagetype or self.pagetype

    self:showPage(self.pagetype)

end

function propInfo.reloaddata(self,data)

    self.data = data.prop or {}
    self.pagetype = data.pagetype or self.pagetype
    self:showPage(self.pagetype)

end

function propInfo.close(self)
    self.pagetype = "info"
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function propInfo.showPage(self,type)
    self.pagetype = type

    if self.pagetype == "info" then
        self.rootNode, self.infoItems = CCBReaderLoad("shop/prop_info", nil, true, "prop_info")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_info()
    end

end


function propInfo.setPage_info(self)
    --local configdata =  gamedata.config.props[tostring(self.data.cid)]
    local configdata =  ui.IDconfig(self.data.cid) or {}
    -- 去获取 按钮
    ui.setLabelString(self.infoItems.getText,nil,18)
    self.infoItems.getBtn:addHandleOfControlEvent(function()
        self.callback = nil
        print("getBtn..is")
        gameWindows:openWindow("dropTips",{cid = self.data.cid},nil)
    end, CCControlEventTouchUpInside)
    self.infoItems.getBtn:setSwallowsTouch(true)
    self.infoItems.getBtn:setTouchPriority(self.touchPriority)


    ui.setNewIcon(self.infoItems,{cid = self.data.cid})

    self.infoItems.name:setString(configdata.name or "")
    self.infoItems.desc:setString(configdata.desc or "")

    ui.setLabelString(self.infoItems.name,nil,(configdata.quality > 0 and configdata.quality or 1)*2-1)

    -- self.infoItems.doLab:setString("确 定")
    self.infoItems.doLab:setString(gameConfig.strings:string_common("popups","queding"))
    ui.setLabelString(self.infoItems.doLab,nil,19)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("propInfo")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    self.infoItems.doButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("propInfo")
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton:setSwallowsTouch(true)
    self.infoItems.doButton:setTouchPriority(self.touchPriority)

end

return propInfo