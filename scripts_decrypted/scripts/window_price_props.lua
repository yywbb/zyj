--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local price_props = {
    rootNode = nil,
    rootItems = nil,
}

--------------------------------添加的购买接口
--神石升级 1130
--竞技场攻击 7303
--真气升级 3731
--装备进阶 1122
--装备升星 1123
--武将觉醒 1025

function price_props.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_price_props", nil, true, "tc_price_props")
    self.touchPriority = touchPriority
    self.callback = callback
    -- local data = {}
    -- data.prop = {}
    -- data.prop[1] = {}
    -- data.prop[1].cid = 20017
    -- data.prop[1].num = 1200
    -- data.msg = "进行神石升级"
    self.sure = false

    self.propData = {}
    self.propData.prop = {}
    self.propData.msg = data.msg
    self.type = data.type

    local price_props = gamedata.config.price_props
    local cids = {}
    local canBuy = 1
    for i = 1, # data.prop do
        if price_props[tostring(data.prop[i].cid)] then
            table.insert(cids, data.prop[i].cid)
            table.insert(self.propData.prop, data.prop[i])
        end
    end

    UIRequest({type = 7501, cids = cids})

    return self.rootNode
end

function price_props.setData(self,buyData)
    local data = self.propData
    local price_props = gamedata.config.price_props
    for i = 1, #data.prop do
        local cid = data.prop[i].cid
        local buynum = data.prop[i].num
        local buynum_now = buyData[tostring(cid)]
        local config = price_props[tostring(cid)]
        local maxNum = table.getTableLength(config)

        local priceTable = {}
        for k ,v in pairs(config) do
            table.insert(priceTable, {tonumber(k), v})
        end
        table.sort(priceTable,function(a,b) return a[1] < b[1] end)

        local needNum = buynum
        local price = 0

        local startIdx = 0
        for j = 1, maxNum do
            if startIdx == 0 and priceTable[j][1] > buynum_now then
                startIdx = j
            end
        end

        if startIdx == 0 then
            price = needNum * priceTable[maxNum][2].gold
        else
            for j = startIdx, maxNum do
                if needNum > 0 then
                    local gold = priceTable[j][2].gold
                    local number = priceTable[j][1]
                    if number >= needNum + buynum_now then
                        price = price + needNum * gold
                        needNum = 0
                    else
                        needNum = needNum + buynum_now - number
                        price = price + (number - buynum_now) * gold
                        buynum_now = number
                    end
                end
            end
            if needNum > 0 then
                price = price + needNum * priceTable[maxNum][2].gold
            end
        end

        data.prop[i].price = math.ceil(price)
    end
    self.data = data

    self.gold = 0
    for i = 1, #data.prop do
        self.gold = self.gold + data.prop[i].price
    end

    self.dropData = {}
        
    for i = 1, #data.prop do
        local cid = data.prop[i].cid
        local dropConfig = gamedata.config.drop[tostring(cid)]
        if dropConfig then
            local tempTable = {}
            tempTable.type = "name"
            tempTable.name = ui.IDconfig(cid).name
            table.insert(self.dropData, tempTable)

            local tempTable = {}
            for k,v in pairs(dropConfig) do
                table.insert(tempTable, v)
            end

            table.sort(tempTable, function(a, b)
                return a.page < b.page
            end)

            for i = 1, #tempTable do
                local data = tempTable[i]
                data.type = "data"
                table.insert(self.dropData, data)
            end
        end
    end

end

function price_props.reload(self,buyData)
    self:setData(buyData)
    self:huoqutujing()

    local data = self.propData

    print("-------道具通用购买---------")
    printT(data)
    printT(self.dropData)

    local price_props = gamedata.config.price_props

    local rich = {}
    table.insert(rich, {fontID = 181,content = "是否"})

    for i = 1, #data.prop do
        local propId = data.prop[i].cid
        local price = data.prop[i].price
        table.insert(rich, {fontID = 181,content = "花费 "})
        table.insert(rich, {fontID = 0,content = "obj_s_gold.png"})
        table.insert(rich, {fontID = 211,content = price .. " "})
        --table.insert(rich, {fontID = 181,content = "，" })
        table.insert(rich, {fontID = 181,content = "购买 "})
        table.insert(rich, {fontID = 211,content = data.prop[i].num .. " "})
        table.insert(rich, {fontID = 181,content = "个" .. ui.IDconfig(propId).name .. "，"})

    end

    table.insert(rich, {fontID = 181,content = data.msg})

    if self.type == "devour" then
        self.rootItems.labelNode:setContentSize(CCSizeMake(1050,200))
        ui.createRichLabel(rich,self.rootItems.labelNode,false,{min_line_dis = 8})
        self.rootItems.labelNode:setScale(0.8)
        self.rootItems.labelNode:setPositionY(53)
    else
        ui.createRichLabel(rich,self.rootItems.labelNode,false,{min_line_dis = 30})
    end

    if data and data.button_lab then
        self.rootItems.yesLab:setString(data.button_lab)
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("price_props")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.noLab,nil,19)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("price_props")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,nil,19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        self.sure = true
        gameWindows:closeWindowDirect("price_props")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)
end

function price_props.huoqutujing(self)
    local celldict = {}
    local rewardListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.dropData[a1 + 1].type == "data" then
                r = CCSizeMake(900, 180)
            else
                r = CCSizeMake(900, 50)
            end
        elseif fn == "isRecycle" then
            return false
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tanchuang/cell_huoqutujing", nil, true, "cell_zhongshurank2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            
            if self.dropData[a1 + 1].type == "data" then
                ccbDocumentControler.tujinginfo:setVisible(true)
                ccbDocumentControler.nameinfo:setVisible(false)
                cellCCB:setPosition(900/2, -180)
            else
                ccbDocumentControler.tujinginfo:setVisible(false)
                ccbDocumentControler.nameinfo:setVisible(true)
                cellCCB:setPosition(900/2, -50)
            end

            self:setCell(ccbDocumentControler, self.dropData[a1+ 1],a1 + 1 )
            
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = #self.dropData
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
           
        end
        return r
    end)

    self.rewardTableView = ui.createLuaTableView({
        handle = rewardListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rewardTableView:setTouchPriority(self.touchPriority - 2)
    self.rootItems.listnode:addChild(self.rewardTableView)
end

function price_props.setCell(self, item, data, index)
    printT(data,"setCell")
    ui.setLabelString(item.titleLabel,data.title or "",21)
    item.desLabel:setString(data.desc or "")
    if data.type == "name" then
        item.get:setString(data.name)
    end

    local _copyFriendDifficult = 2
    local _copyFriendChapter = 0
    local _copyFriendLevel = 0

    if data.systemid and data.systemid ~= 0 then
        local isopen = true
        local buildconfig = gamedata.config.build[tostring(data.systemid)]

        if buildconfig.level > GameScene.roleinfo.level then
            isopen = false
            -- ccbDocumentControler.des:setString(buildconfig.level.."级开启")
            item.des:setString(gameConfig.strings:lvOpen(buildconfig.level))
        else
            if buildconfig.type == "copy_chapter" or  buildconfig.type == "copy_map" then
                local map,point  = 0,0
                if data.param and data.param ~= "" then
                    local i = string.find(data.param,",")
                    if i then
                        map,point = ui.getIDandNUM(data.param)
                    else
                        map = tonumber(data.param)
                    end
                end
                if data.systemid == 12 or data.systemid == 13 then
                    if not self.mapmaxN then
                        self.mapmaxN,self.pointmaxN = ui.getCopyProcess("normal")
                    end
                    isopen = ui.isCopyOpen(map,point,self.mapmaxN,self.pointmaxN)
                elseif data.systemid == 15 or data.systemid == 16 then
                    if not self.mapmaxB then
                        self.mapmaxB,self.pointmaxB = ui.getCopyProcess("brave")
                    end
                    isopen = ui.isCopyOpen(map,point,self.mapmaxB,self.pointmaxB)
                elseif data.systemid == 148 then
                    if not self.mapmaxS then
                        self.mapmaxS,self.pointmaxS = ui.getCopyProcess("star")
                    end
                    isopen = ui.isCopyOpen(map,point,self.mapmaxS,self.pointmaxS)
                end
                -- item.des:setString("未到达")
                item.des:setString(gameConfig.strings:string_common("popups","weidadao"))
            end
        end

        item.in_goto:setVisible(isopen)
        item.des:setVisible(not isopen)
        item.in_button:setSwallowsTouch(true)
        item.in_button:setTouchPriority(self.touchPriority-3)
        item.in_button:addHandleOfControlEvent(function()
            GameScene:shiftLayerById(data.systemid,data.param)
        end, CCControlEventTouchUpInside)
    else
        item.in_goto:setVisible(false)
        item.des:setVisible(false)
    end

end

function price_props.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback and self.sure then
        self.callback(self.gold)
    end
end

return price_props

�/  