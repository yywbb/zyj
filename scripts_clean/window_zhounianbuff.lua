--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local buff = {
    rootNode = nil,
    rootItems = nil,

    listview = nil,
}

function buff.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("2zhounian/2zhounian_buff", nil, true, "cdk")
    --self.rootNode, self.rootItems = CCBReaderLoad("yuandanqifu/yuandanqifu_buff", nil, true, "yuandanqifu_buff")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function buff.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("zhounianbuff")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local buffs = gamedata.config.Anniversary_double


    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("2zhounian/cell_2zhounianbuff", nil, true, "cell_2zhounian")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,buffs[a1+1] or buffs[tostring(a1+1)])

            cellCCB:setPosition(460, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(buffs)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listNode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

function buff.setCell( self,items,data )
    ui.setNewIcon(items,{icon = data.icon})

    items.name:setString(data.name)
    items.desc:setString(data.name..gameConfig.strings:string_common("activity_zhounian",11)..data.multiple)

    ui.setLabelString(items.gettext,gameConfig.strings:string_common("buttontext","qianwang"),18)
    items.getbutton:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(data.systemid)
    end, CCControlEventTouchUpInside)
    items.getbutton:setSwallowsTouch(true)
    items.getbutton:setTouchPriority(self.touchPriority-1)
end

function buff.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.listview = nil

    if self.callback then
        self.callback()
    end
end

return buff

