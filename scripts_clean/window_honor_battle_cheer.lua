local honorBattleCheer = {

    rootNode = nil,
    rootItems = nil,

    xiaohuobanListTableView = nil,
}

function honorBattleCheer.close(self)
    self.xiaohuobanListTableView = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil
end

function honorBattleCheer.open(self, touchPriority, data, callback)
    self.xiaohuobanListTableView = nil
    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:initFixedString()

    self:reloadData()

    return self.rootNode
end

-- 初始化界面
function honorBattleCheer.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_cheer", nil, true, "tc_bisaiinfo")
    self.touchPriority = touchPriority

    ui.setLabelString(self.rootItems.titleTxt,"助阵信息",65)
end


-- 初始化配置表
function honorBattleCheer.initConfig(self)
    -- self.rewardTable = gamedata.config.king_reward
end

function honorBattleCheer.reloadData(self,data)

    self.cheerdata = table.copy(GameScene.layers["slotsInfo"].module.cheerdata)
    self.slotdata = table.copy(GameScene.layers["slotsInfo"].module.slotdata)

    local item = self.rootItems

    for i=1,8 do
        -- 设置头像
        -- printT(self.cheerdata[tostring(i)],"jkp-cheerdata")
        if self.cheerdata[tostring(i)].general then
            if self.cheerdata[tostring(i)].general.illusionGeneralCid then
                local configGeneral = gamedata.config.general[tostring(self.cheerdata[tostring(i)].general.illusionGeneralCid)]
                local gdata = ui.getConfigGeneralSion(self.cheerdata[tostring(i)].general)
                if next(gdata) and configGeneral.fashion_id == 0 then
                    ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1,gdata)
                else
                    ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1)
                end
            else
                local configGeneral = gamedata.config.general[tostring(self.cheerdata[tostring(i)].general.cid)]
                local gdata = ui.getConfigGeneral(self.cheerdata[tostring(i)].general)
                if next(gdata) and configGeneral.fashion_id == 0 then
                    ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1,gdata)
                else
                    ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1)
                end
            end
        else
            ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1)
        end
    end

    item.xhbTabLab:setString("伙伴缘分效果")
    if self.xiaohuobanListTableView then
        self.xiaohuobanListTableView:reloadData()
    else
        self:creatxhbdeslist(item)
    end            
    item.listscroll:setVisible(true)
end

function honorBattleCheer.creatxhbdeslist(self,item)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(550, 650)
        elseif fn == "cellAtIndex" then

            local cellCCB,items = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, items = CCBReaderLoad("slotsInfo/slot-xhb_des.ccbi", nil, true, "slot-xhb_des")
                celldict[a2] = {cellCCB=cellCCB,items=items }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                items = celldict[a2].items
            end

            if self.slotdata[tostring(a1+1)].general then
                local data = self.slotdata[tostring(a1+1)]
                local configdata = gamedata.config.general[tostring(data.general.cid)]
                items.generalname:setString(configdata.name)
                for i = 1, 6 do
                    local name = (configdata["cond"..tostring(i).."name"] and configdata["cond"..tostring(i).."name"] ~= "") and configdata["cond"..tostring(i).."name"].."：" or " "
                    items["name"..tostring(i)]:setString(name)
                    items["des"..tostring(i)]:setString(configdata["cond"..tostring(i).."desc"] or " ")
                    items["name"..tostring(i)]:setColor(ccc3(124,120,109))
                    items["des"..tostring(i)]:setColor(ccc3(124,120,109))
                    if data.relation[tostring(i)] then
                        if data.relation[tostring(i)].activate >1  then
                            items["name"..tostring(i)]:setColor(ccc3(115, 66, 25))
                            items["des"..tostring(i)]:setColor(ccc3(115, 66, 25))
                        end
                    end
                end
            else
                for i = 1, 6 do
                    items["name"..tostring(i)]:setString(" ")
                    items["des"..tostring(i)]:setString(" ")
                end
                items.generalname:setString("")
            end


            cellCCB:setPosition(550/2, 49)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = GameScene.layers["slotsInfo"].module.maxsid
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.xiaohuobanListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = item.listscroll:getContentSize().width,
        viewheight = item.listscroll:getContentSize().height,
        dire = 1
    })
    item.listscroll:addChild(self.xiaohuobanListTableView)
    self.xiaohuobanListTableView:setTouchPriority(self.touchPriority - 1)
end

-- 初始化按钮点击事件
function honorBattleCheer.initEventBtn(self)
    self:initCloseBtn()
end

-- 初始化关闭按钮
function honorBattleCheer.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorBattleCheer")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

-- 固定文字
function honorBattleCheer.initFixedString(self)

end

-- 通用按钮
function honorBattleCheer.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return honorBattleCheer