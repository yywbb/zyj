--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/7/12
-- Time: 下午12:05
-- To change this template use File | Settings | File Templates.
--

local buypropbyid = {
    rootNode = nil,
    rootItems = nil,
}

function buypropbyid.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shop/buypropById", nil, true, "buypropById")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function buypropbyid.reload(self,data,callback)
    self.callback = callback

    local config = ui.IDconfig(data.cid)

    ui.setLabelString(self.rootItems.name,config.name.."x"..data.num, config.quality~=0 and 2*config.quality-1 or 1)

    ui.setIconLv(self.rootItems,{cid = data.cid})

    local totalprice = data.num*gamedata.config.shop[tostring(data.seq)].gold

    self.rootItems.totalprice:setString(totalprice)
    if totalprice > GameScene.roleinfo.gold then
        self.rootItems.totalprice:setColor(ccc3(255,0,0))
    end


    -- ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("buypropById")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        if data.num and data.num >0 then
            UIRequest({type = 3201,id = data.seq, num = data.num, updatetable = data.updatetable})
            self.callback = nil
            gameWindows:closeWindow("buypropById")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("buypropById")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function buypropbyid.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return buypropbyid