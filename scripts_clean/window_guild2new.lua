--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local guildnew = {
    rootNode = nil,
    rootItems = nil,
}

function guildnew.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_tc_chuangjian", nil, true, "create")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function guildnew.reload(self,data,callback)
    self.callback = callback

    -- self.rootItems.des2:setString("达到"..(gamedata.config.global_kv and tonumber(gamedata.config.global_kv.gang_establish_level.value) or 0).."级")
    self.rootItems.des2:setString(gameConfig.strings:dadaoLV((gamedata.config.global_kv and tonumber(gamedata.config.global_kv.gang_establish_level.value) or 0)))
    self.rootItems.coin:setString(gamedata.config.global_kv and tonumber(gamedata.config.global_kv.gang_establish_coin.value) or 0)
    ui.setLabelString(self.rootItems.des1,nil,23)
    ui.setLabelString(self.rootItems.des2,nil,23)
    ui.setLabelString(self.rootItems.coin,nil,14)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildnew")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local inputcontent = ""
    local beginFunc = function()
        inputcontent = ""
    end

    local endFunc = function(text)
        inputcontent = text
    end

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 40,
            -- PlaceHolder = "点击输入公会名字",
            PlaceHolder = gameConfig.strings:string_common("popups","enterGuid"),
            length = 12
        })
    self.input:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.createLab,nil,19)
    self.rootItems.createButton:addHandleOfControlEvent(function()
        if inputcontent == "" then
            -- runGamePrompt({msg = "输入公会名字"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","guidName")})
        elseif (gamedata.config.global_kv and tonumber(gamedata.config.global_kv.gang_establish_coin.value) or 0) > GameScene.roleinfo.gold then
            shortGold()
        else
            gameWindows:closeWindowDirect("guildnew")
            UIRequest({type = 2231, name = inputcontent})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.createButton:setSwallowsTouch(true)
    self.rootItems.createButton:setTouchPriority(self.touchPriority)
end

function guildnew.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return guildnew

