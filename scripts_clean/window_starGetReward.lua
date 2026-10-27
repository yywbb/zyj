local starGetReward = {
    rootNode = nil,
    rootItems = nil,
}

function starGetReward.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitystar/star_lingqu", nil, true, "starGetReward")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function starGetReward.reload(self,data,callback)
    self.callback = callback

    if data and data.starnum then
        self.rootItems.hasstarnum:setString(data.starnum)
        ui.setLabelString(self.rootItems.hasstarnum,nil,14)
        ui.setLabelString(self.rootItems.text1,nil,121)
    end

    if self.rootItems.upNode then
        ui.setLabelString(self.rootItems.uptext,nil,18)
        self.rootItems.upNode:setVisible(false)
    end

    local rewardlevel = 1
    local upneed = {}
    if data and data.rewardlevel and self.rootItems.upNode then
        rewardlevel = data.rewardlevel
        --
        local lvconfig = gamedata.config.watchstar_lv_reward or {}
        if self.rootItems.title then
            self.rootItems.title:setString(lvconfig[tostring(rewardlevel)] and lvconfig[tostring(rewardlevel)].name or "")
        end
        --
        if rewardlevel < table.getTableLength(lvconfig) then
            self.rootItems.upNode:setVisible(true)
            self.rootItems.needlevel:setString("队伍"..(lvconfig[tostring(rewardlevel)] and lvconfig[tostring(rewardlevel)].interval or 0).."级")
            --
            if lvconfig[tostring(rewardlevel)] and lvconfig[tostring(rewardlevel)].interval and lvconfig[tostring(rewardlevel)].interval > GameScene.roleinfo.level then
                ui.setLabelString(self.rootItems.needlevel,nil,24)
            else
                ui.setLabelString(self.rootItems.needlevel,nil,22)
            end
            --
            if lvconfig[tostring(rewardlevel)] and lvconfig[tostring(rewardlevel)].cost then
                upneed = ui.getIDandNUMs(lvconfig[tostring(rewardlevel)].cost)
            end
            --
            self.rootItems.needcoin:setVisible(false)
            self.rootItems.needgold:setVisible(false)
            ui.setLabelString(self.rootItems.neednum,"",13)
            --
            local StarGold = "元宝"

            if upneed and upneed[1] and upneed[1].cid then
                if upneed[1].cid == 1000 then
                    StarGold = "金币"
                    self.rootItems.needcoin:setVisible(true)
                    ui.setLabelString(self.rootItems.neednum,upneed[1].num,upneed[1].num > GameScene.roleinfo.coin and 24 or 13)
                elseif upneed[1].cid == 1001 then
                    StarGold = "元宝"
                    self.rootItems.needgold:setVisible(true)
                    ui.setLabelString(self.rootItems.neednum,upneed[1].num,upneed[1].num > GameScene.roleinfo.gold and 24 or 13)
                end
            end
            --
            self.rootItems.upButton:addHandleOfControlEvent(function()
                if lvconfig[tostring(rewardlevel)] and lvconfig[tostring(rewardlevel)].interval and lvconfig[tostring(rewardlevel)].interval > GameScene.roleinfo.level then
                    runGamePrompt({msg = "队伍等级不足"})
                else
                    local cb = function()
                        gameTouch:clickprofbytime(1)
                        UIRequest({type = 2068, need = upneed})
                    end
                    if upneed and upneed[1] then
                        gameWindows:openWindow("guildmsg",{msg = "是否消耗"..upneed[1].num.. StarGold .. "升级奖励？" },cb)
                    else
                        gameWindows:openWindow("guildmsg",{msg = "是否升级奖励？" },cb)
                    end
                end
            end, CCControlEventTouchUpInside)
            self.rootItems.upButton:setSwallowsTouch(true)
            self.rootItems.upButton:setTouchPriority(self.touchPriority)
        end
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("starGetReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.yulanButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("starGetReward")
        gameWindows:openWindow("starGetRewardPreview",data)
    end, CCControlEventTouchUpInside)
    self.rootItems.yulanButton:setSwallowsTouch(true)
    self.rootItems.yulanButton:setTouchPriority(self.touchPriority)

    local hasreward = false
    for k, v in pairs(gamedata.config.watchstar_reward) do

        local star = v.star;
        local rewards = ui.getIDandNUMs(v["rewards"..rewardlevel] or v.rewards)
        ui.setNewIconGuanxin(self.rootItems,{num = rewards[1].num,cid = rewards[1].cid,starnum = star},tonumber(k)-1)
        self.rootItems["i_button"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setTouchPriority(self.touchPriority)
        self.rootItems["i_button"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(rewards[1].cid)
        end,CCControlEventTouchUpInside)
        self.rootItems["starnum"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setString(tostring(star).."星辰")

        if data.rewardstatus and data.rewardstatus[tostring(k)] == 2 then
            self.rootItems["lingqu"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setVisible(true)
        else
            self.rootItems["lingqu"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setVisible(false)
        end

        if data.rewardstatus and data.rewardstatus[tostring(k)] == 1 then
            self.rootItems["kelingqu"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setVisible(true)
            hasreward = true
        else
            self.rootItems["kelingqu"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setVisible(false)
        end

    end

    if hasreward then
        ui.removeGray("CCControlButton",self.rootItems.forecastButton)
    else
        ui.addGray("CCControlButton",self.rootItems.forecastButton)
    end
    -- ui.setLabelString(self.rootItems.forecasttext,"一键领取",18)
    ui.setLabelString(self.rootItems.forecasttext,nil,18)
    self.rootItems.forecastButton:addHandleOfControlEvent(function()
        if hasreward then
            --gameWindows:closeWindowDirect("starGetReward")
            gameTouch:clickprofbytime(1)
            UIRequest({type = 2066})
        else
            -- runGamePrompt({msg = "没有可领取的奖励"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","noAwardget")})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.forecastButton:setSwallowsTouch(true)
    self.rootItems.forecastButton:setTouchPriority(self.touchPriority)
end

function starGetReward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return starGetReward

