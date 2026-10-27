--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/29
-- Time: 下午3:54
-- To change this template use File | Settings | File Templates.
--


local soulIntroduction = {
    rootNode = nil,
    rootItems = nil,

    ListTableView = nil,

     data = {
         [1] = {},
         [2] = {},
         [3] = {},
         [4] = {},
         [5] = {},
         [6] = {},
         [7] = {},
     },
    
     desdata = {
         [1] = {},
         [2] = {},
         [3] = {},
         [4] = {},
         [5] = {},
         [6] = {},
         [7] = {},
     },
    onedata = {},
    isscrolltouched = false,
}

function soulIntroduction.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("soul/soulIntroduction", nil, true, "soulIntroduction")

    self.touchPriority = touchPriority
    self:reload(data,callback)
    --
    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end
    gameTouch:rigistFunc("begin","soulIntroduction",touchbegin)
    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.rootItems.listNode and ui.isTouched(self.rootItems.listNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","soulIntroduction",touchend)
    --
    return self.rootNode
end

function soulIntroduction.makeData(self)
    for k,v in pairs(gamedata.config.soul) do
        if v.id ~= 70000 then
            for i=1, 6 do
                if v["rang"..i] and v["rang"..i]~=0 then
                    table.insert(self.data[i],v)
                    if not self.desdata[i][v.quality] then
                        self.desdata[i][v.quality] = v.quality
                    end
                end
            end
        end
    end

    for i=1,6  do
        ui.sortData(self.data[i],"quality")
        local des = ""
        for k,v in pairs(self.desdata[i]) do
            des = (des)..gameConfig.strings.quality[v]
        end
        -- self.desdata[i]  = gamedata.config.soul_hunt[tostring(i)].name.."可以猎出"..des.."命格"
        self.desdata[i]  = gameConfig.strings:liechuMingge(gamedata.config.soul_hunt[tostring(i)].name,des)
    end

    --
    for k,v in pairs(gamedata.config.soul_integrate) do
        table.insert(self.data[7],gamedata.config.soul[tostring(v.id)])
    end  

    self.desdata[7] = ""
end

function soulIntroduction.setIcon(self,item,data)
    setSpriteFrameByName(item["s_kuang"], "b_iconk"..(data.quality and data.quality>1 and data.quality or 1))
    setSpriteFrameByName(item["s_quality"], "b_iconbg"..(data.quality and data.quality>1 and data.quality or 1))

    -- 增加弹出窗口
    item.s_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gamedata.config.soul_integrate and gamedata.config.soul_integrate[tostring(data.id)] and gamedata.config.soul_integrate[tostring(data.id)].main_id and gamedata.config.soul_integrate[tostring(data.id)].main_id > 0 then
            gameWindows:openWindow("soulintegrate",{opt = 2,data = {cid = gamedata.config.soul_integrate[tostring(data.id)].main_id},allData = {}})
        else
            ui.setPopwindowByCid(data.id) 
        end
    end, CCControlEventTouchUpInside)
    --item.s_button:setSwallowsTouch(true)
    item.s_button:setTouchPriority(self.touchPriority)

    item["s_soulnode"]:removeAllChildrenWithCleanup(true)
    local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..data.icon..".ccbi", nil, true, data.icon)
    item["s_soulnode"]:addChild(ccb)
    ui.setLabelString(item.s_name,data.name, data.quality and 2*data.quality-1 or 1)
end

function soulIntroduction.reload(self,data,callback)
    self.callback = callback


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("soulIntroduction")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    if not self.data[1][1] then self:makeData() end

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(760, 205)
        elseif fn == "cellAtIndex" then

            local CCB,item = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                for i=1,4 do
                    CCB[i],item[i] = CCBReaderLoad("soul/soulIconName.ccbi", nil, true, "soulIconName")
                    CCB[i]:setScale(0.85)
                end
                celldict[a2] = {CCB=CCB,item=item }
            else
                first = false
                CCB = celldict[a2].CCB
                item = celldict[a2].item
            end

            for i =1, 4 do
                if self.onedata[4*(a1) +i] then
                    CCB[i]:setVisible(true)
                    local celldata =  self.onedata[4*(a1) +i]
                    self:setIcon(item[i],celldata)
                else
                    CCB[i]:setVisible(false)
                    item[i].s_button:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                    end, CCControlEventTouchUpInside)
                    item[i].s_button:setTouchPriority(self.touchPriority)
                end

                CCB[i]:setPosition(5+185*(i-0.5), 130)
                if first then
                    a2:addChild(CCB[i])
                end
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.onedata)/4)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.ListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listNode:addChild(self.ListTableView)

    for i=1,7 do
        self.rootItems["button"..i]:addHandleOfControlEvent(function()
             self:shiftPage(i)
        end, CCControlEventTouchUpInside)

        self.rootItems["button"..i]:setSwallowsTouch(true)
        self.rootItems["button"..i]:setTouchPriority(self.touchPriority)
        ui.setLabelString(self.rootItems["name"..i],nil, 121)
        self.rootItems["bg"..i] = tolua.cast(self.rootItems["bg"..i], "CCScale9Sprite")
    end

    self:shiftPage(1,true)
end

function soulIntroduction.shiftPage(self,i,isfirst)
    self.onedata = self.data[i]
    self.rootItems.des:setString(self.desdata[i])

    for ii=1,7 do
        self.rootItems["bg"..ii]:setColor(ii == i and ccc3(255,255,255) or ccc3(100,100,100))
        self.rootItems["sprite"..ii]:setColor(ii == i and ccc3(255,255,255) or ccc3(100,100,100))
        self.rootItems["name"..ii]:setColor(ii == i and ccc3(255,255,255) or ccc3(100,100,100))
    end

    self.ListTableView:reloadData()
    self.ListTableView:setLuaContentOffset(0,  self.rootItems.listNode:getContentSize().height - 205*math.ceil(table.getTableLength(self.onedata)/4) )

end

function soulIntroduction.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil
    gameTouch:UnrigistFunc("begin","soulIntroduction")
    gameTouch:UnrigistFunc("end","soulIntroduction")  
    if self.callback then
        self.callback()
    end
end

return soulIntroduction