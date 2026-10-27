--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/12/12
-- Time: 15:40
-- To change this template use File | Settings | File Templates.
--


local shenlongxuyuan_shop = {
    rootNode = nil,
    rootItems = nil,
}

function shenlongxuyuan_shop.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_buy", nil, true, "shenlongxuyuan_buy")
    self.touchPriority = touchPriority
    self.callback = callback
    self:reload(data)
    return self.rootNode
end

function shenlongxuyuan_shop.reload(self,data)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shenlongxuyuan_shop")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    local levelnow = GameScene.roleinfo.level or 0
    local level = 999
    for k,v in pairs(gamedata.config.shenlong_discount) do
        if (levelnow <= v["1"].level) and (level > v["1"].level) then
            level = v["1"].level
        end
    end
    local levelreward = gamedata.config.shenlong_discount[tostring(level)] or {}
    --
    for i = 1,4 do
        if levelreward[tostring(i)] then
            local key_Ex = ""
            if (i-1) == 0 then
                key_Ex = ""
            else
                key_Ex = "_"..(i-1)
            end
            self.rootItems["prop"..i]:setVisible(true)
            local shopconfig = levelreward[tostring(i)]
            local target = ui.getIDandNUMs(shopconfig.target)
            local configdata = ui.IDconfig(target[1].cid)
            local buycount = ((shopconfig.count-data["shop"..i])>0) and (shopconfig.count-data["shop"..i]) or 0
            ui.setNewIcon(self.rootItems,{cid = target[1].cid,num = target[1].num},i-1)
            ui.setLabelString(self.rootItems["name"..key_Ex],configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)
            self.rootItems["desc"..key_Ex]:setString("还可购买 "..buycount.." 次")
            self.rootItems["gold"..key_Ex]:setString(shopconfig.gold)
            self.rootItems["price"..key_Ex]:setString(shopconfig.price)
            --
            ui.setLabelString(self.rootItems["buytext"..key_Ex],nil,18)

            if buycount > 0 then
                ui.removeGray("CCControlButton",self.rootItems["buyButton"..key_Ex])
                self.rootItems["buyButton"..key_Ex]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 4906,xgold = shopconfig.price or 0,id = i,num = 1})
                end, CCControlEventTouchUpInside)
                self.rootItems["buyButton"..key_Ex]:setSwallowsTouch(true)
                self.rootItems["buyButton"..key_Ex]:setTouchPriority(self.touchPriority)
            else
                ui.addGray("CCControlButton",self.rootItems["buyButton"..key_Ex])
                self.rootItems["buyButton"..key_Ex]:addHandleOfControlEvent(function()
                    runGamePrompt({msg = "购买次数已用完"})
                end, CCControlEventTouchUpInside)
                self.rootItems["buyButton"..key_Ex]:setSwallowsTouch(true)
                self.rootItems["buyButton"..key_Ex]:setTouchPriority(self.touchPriority)
            end
        else
            self.rootItems["prop"..i]:setVisible(false)
        end
    end
end

function shenlongxuyuan_shop.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return shenlongxuyuan_shop

