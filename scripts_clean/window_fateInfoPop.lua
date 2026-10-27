local fateInfoPop = {
    rootNode = nil,
    rootItems = nil,
}

function fateInfoPop.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/pop_fate_info", nil, true, "pop_fate_info")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function fateInfoPop.reload(self,data,callback)
    self.callback = callback

    local config = gamedata.config:getConfigByName("general")[tostring(data.cid)] or {}
    if not next(config) then return end

    local fatecids = {}
    table.insert(fatecids, data.cid)
    if config["cond"..data.id.."type"] == "person" then       -- 伙伴
        local cids = ui.Split(config["cond"..data.id.."ids"], ";") or {}
        for i=1,table.getTableLength(cids) do
            table.insert(fatecids, cids[i])
        end
    else        -- 装备
        table.insert(fatecids,config["cond"..data.id.."ids"])
    end


    for i=1,4 do
        if fatecids[i] and fatecids[i] ~= "" then 
            self.rootItems["fateicon_"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems, {cid = fatecids[i]}, i-1)

            local key_Ex = (i == 1) and "" or "_"..(i-1)

            self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)
            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority-1)
            if i == 1 or config["cond"..data.id.."type"] == "person" then 
                self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                    ui.setPopwindowByCid(fatecids[i])
                end, CCControlEventTouchUpInside)
            else
                self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                    gameWindows:openWindow("dropTips",{cid = fatecids[i]},nil)
                end, CCControlEventTouchUpInside)
            end
        else
            self.rootItems["fateicon_"..i]:setVisible(false)
        end
    end

    self.rootItems.name:setString(config["cond"..data.id.."name"] or "")
    self.rootItems.desc:setString(config["cond"..data.id.."desc"] or "")
end

function fateInfoPop.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return fateInfoPop