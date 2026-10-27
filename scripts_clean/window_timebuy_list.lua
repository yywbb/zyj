--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/27
-- Time: 上午11:34
-- To change this template use File | Settings | File Templates.
--


local timebuy_list = {
    rootNode = nil,
    rootItems = nil,

    listdata = {},

    ListTableView = nil,
}

function timebuy_list.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityjieri/tc_goumaijilu", nil, true, "tc_goumaijilu")

    self.touchPriority = touchPriority
    self.callback = callback

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindowDirect("timebuy_list")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    UIRequest({type = 6802})
    --self:reload()

    return self.rootNode
end

function timebuy_list.reload(self,data)
    self.listdata = data and data.list or {}

    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
    end
    --

end    

function timebuy_list.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(900,120)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityjieri/cell_goumaijilu", nil, true, "cell_goumaijilu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            --
            local data = self.listdata[tostring(a1+1)] or {}
            local timetab = os.date("*t", data.time)
            local timeString = timetab.month.."月"..timetab.day.."日"..timetab.hour.."时"..timetab.min.."分"..timetab.sec.."秒"
            local itemcid,itemnum = ui.getIDandNUM(gamedata.config.time_buy[tostring(data.id)].item) 
            ui.createRichLabel({
                {fontID = 14,content = "您在 "},
                {fontID = 23,content = timeString},
                {fontID = 14,content = " 花费 "},
                {fontID = 21,content = data.num.."元宝"},
                {fontID = 14,content = " 购买了 \n"},
                {fontID = ((ui.IDconfig(itemcid).quality and ui.IDconfig(itemcid).quality ~= 0) and ui.IDconfig(itemcid).quality or 1)*2-1,content = ui.IDconfig(itemcid).name..((ui.IDconfig(itemcid).staffType == "general_fragment") and "魂魄" or "" ).."x"..itemnum},
            },ccbDocumentControler["message"],false)
            --

            cellCCB:setPosition(500, 40)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.listdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function timebuy_list.close(self)

    self.listdata = {}
    self.ListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return timebuy_list