--



local bosschallenge_ranklist = {
    rootNode = nil,
    rootItems = nil,

    ListTableView = nil,
    isscrolltouched = false,
}

function bosschallenge_ranklist.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("bosschallenge/bosschallenge_bigjiangli", nil, true, "rank")

    self.touchPriority = touchPriority
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","bosschallenge_ranklist",touchbegin)
    local function touchend(pos)
        if self.rootItems.listworld and ui.isTouched(self.rootItems.listworld,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listguild and ui.isTouched(self.rootItems.listguild,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","bosschallenge_ranklist",touchend)
    self:reload(data,callback)

    return self.rootNode
end

function bosschallenge_ranklist.reload(self,data,callback)
    self.data = data and data.list or {}

    ui.setLabelString(self.rootItems.desc,nil,14)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("bosschallenge_ranklist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 240)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("bosschallenge/cell_bigjiangli", nil, true, "cell_rank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.setLabelString(ccbDocumentControler.name,self.data[tostring(a1+1)].name,1)
            ui.setLabelString(ccbDocumentControler.num,self.data[tostring(a1+1)].params["1"].s or "",22)
            ui.setLabelString(ccbDocumentControler.desc,nil,13)
            ui.setNewIcon(ccbDocumentControler,{cid = self.data[tostring(a1+1)].profile})
            --time
            if self.data[tostring(a1+1)].params["2"].i and self.data[tostring(a1+1)].params["2"].i > 0 then
                local timetab = os.date("*t", self.data[tostring(a1+1)].params["2"].i or 0)
                local timeString = timetab.month.."月"..timetab.day.."日 "..timetab.hour.."时"..timetab.min.."分"..timetab.sec.."秒"
                ui.setLabelString(ccbDocumentControler.time,"获奖时间："..timeString,14)
            else
                ui.setLabelString(ccbDocumentControler.time,"",14)
            end

            cellCCB:setPosition(920/2, 10)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

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

function bosschallenge_ranklist.close(self)
    gameTouch:UnrigistFunc("begin","bosschallenge_ranklist")
    gameTouch:UnrigistFunc("end","bosschallenge_ranklist")
    self.isscrolltouched = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.ListTableView = nil

    if self.callback then
        self.callback()
    end
end

return bosschallenge_ranklist