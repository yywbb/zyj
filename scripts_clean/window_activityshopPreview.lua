--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/27
-- Time: 下午1:31
-- To change this template use File | Settings | File Templates.
--

local preview = {
    rootNode = nil,
    rootItems = nil,

    data = {},
    des = nil,
}

function preview.open(self,touchPriority,data,callback)

    self.touchPriority = touchPriority
    self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_shangpinyulan", nil, true, "tc_shangpinyulan")
    self:reload(data,callback)

    return self.rootNode
end

function preview.reload(self,data,callback)
    self.callback = callback
    if data and data.cpnum and data.cpnum > 0 then
        self.data = gamedata.config["limittime_shop_"..data.cpnum]
    else
        -- local config = gamedata.config.limittime_shop
        -- if GameScene.layers["activity"].module.dailyCpActivityTimeStatus[3] then
        --     local cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[3].cpnum or 0
        --     config = gamedata.config["limittime_shop".."_rc_"..cpnum] or {}
        -- end
        local config = gamedata.dailyCpActivityConfig("limittime_shop",3)

        self.data = config
    end
    local sortTable = {}
    for k, v in pairs(self.data) do
        local snapble = ui.IDconfig(v.id,v.num)
        if snapble.staffType == "equip" and (snapble.type == "treasure" or snapble.type == "accessory") then
            snapble.treasureId= 6
        elseif snapble.staffType == "equip" or snapble.staffType == "equip_fragment" then
            snapble.treasureId= 5
        elseif snapble.staffType == "props" then
            snapble.treasureId= 4
        else  
            snapble.treasureId= 3
        end
        if not snapble.id then
            snapble.id = v.id
        end
        --if not snapble.num then
            snapble.num = v.num
        --end
        table.insert(sortTable,snapble)
    end 
    ui.sortData(sortTable,"quality","treasureId","id")
    --printT(sortTable,"sortTable------------2")
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("activityshopPreview")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 300)
        elseif fn == "cellAtIndex" then

            local CCB,item = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                for i=1,4 do
                    CCB[i],item[i] = CCBReaderLoad("tanchuang/cell_shangpinyulan.ccbi", nil, true, "cell_shangpinyulan")
                end
                celldict[a2] = {CCB=CCB,item=item }
            else
                first = false

                CCB = celldict[a2].CCB
                item = celldict[a2].item
            end

            for i =1, 4 do
                --local data1 = self.data[tostring(4*(a1) +i)] or self.data[(4*(a1) +i)]
                local data1 = sortTable[tostring(4*(a1) +i)] or sortTable[(4*(a1) +i)]
                if data1 then
                    CCB[i]:setVisible(true)
                    ui.setNewIconName(item[i],{cid = data1.id,num = data1.num})
                    item[i].hot:setVisible(data1.hot and data1.hot ==1)
                else
                    CCB[i]:setVisible(false)
                end

                CCB[i]:setPosition(220*(i-0.5)+20, 200)
                if first then
                    a2:addChild(CCB[i])
                end
            end

            r = a2
        elseif fn == "numberOfCells" then
            --r = math.ceil(table.getTableLength(self.data)/4)
            r = math.ceil(table.getTableLength(sortTable)/4)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    ListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listScroll:addChild(ListTableView)

end

function preview.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return preview