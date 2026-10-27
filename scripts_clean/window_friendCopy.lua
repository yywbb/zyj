--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/24
-- Time: 下午5:04
-- To change this template use File | Settings | File Templates.
--


local friendcopy = {
    rootNode = nil,
    rootItems = nil,

    isscrolltouched = false,
}

function friendcopy.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    if data.type == "rule" then
        self.rootNode, self.rootItems = CCBReaderLoad("copyFriend/copyfriendrule", nil, true, "copyfriendrule")
        self:reloadRule(data,callback)
    elseif data.type == "select" then
        self.rootNode, self.rootItems = CCBReaderLoad("copyFriend/tc_haoyouxuanze", nil, true, "tc_haoyouxuanze")
        self:reloadSelect(data,callback)
    end
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","friendcopy",touchbegin)
    local function touchend(pos)
        --两个滚动层大小一样，不会同时在一起
        if self.rootItems.listNode and ui.isTouched(self.rootItems.listNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end       
    end
    gameTouch:rigistFunc("end","friendcopy",touchend) 
    self.root:addChild(self.rootNode)

    return self.root
end

function friendcopy.reloadRule(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("friendcopy")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end

function friendcopy.reloadSelect(self,data,callback)

    ui.setLabelString(self.rootItems.des,nil,49)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("friendcopy")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local selectfriend  = nil
    local selectindex = -1
    local ListTableView

    -- ui.setLabelString(self.rootItems.buttontext,"确 认",18)
    ui.setLabelString(self.rootItems.buttontext,gameConfig.strings:string_common("popups","zhandou"),18)
    self.rootItems.button:addHandleOfControlEvent(function()

        if not selectfriend then
            self.callback = nil
            -- gameWindows:closeWindow("friendcopy")
            runGamePrompt({msg = "请选择好友参加战斗"})
        else
            self.callback = function()
                if GameScene.layers["friendcopy"].show then
                    GameScene.layers["friendcopy"].module:attack(selectfriend)
                end
            end
            gameWindows:closeWindowDirect("friendcopy")
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.button:setSwallowsTouch(true)
    self.rootItems.button:setTouchPriority(self.touchPriority)

    --
    -- ui.setLabelString(self.rootItems.buttontext1,"去加好友",18)
    ui.setLabelString(self.rootItems.buttontext1,gameConfig.strings:string_common("popups","addfr"),18)
    self.rootItems.button1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("friendcopy")
        GameScene:shiftLayer("friends","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.button1:setSwallowsTouch(true)
    self.rootItems.button1:setTouchPriority(self.touchPriority)
    --

    local dataTable = data.data.data

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(932, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("copyFriend/cell_haoyouxuanze", nil, true, "cell_haoyouxuanze")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local data = dataTable[tostring(a1+1)]
            ui.setIconLv(ccbDocumentControler,{cid = data.profile,level = data.level,title = data.title,iconBox = data.iconBox})
            ui.setLabelString(ccbDocumentControler.name,data.name,1)


            if data.use ==0  then
                -- ui.setLabelString(ccbDocumentControler.des,"今日助战次数已用尽",21)
                ui.setLabelString(ccbDocumentControler.des,gameConfig.strings:string_common("popups","perout"),21)
                ccbDocumentControler.powernode:setVisible(false)
            else
                ui.setLabelString(ccbDocumentControler.des,"",21)
                ui.setLabelString(ccbDocumentControler.power,data.power,21)
                ccbDocumentControler.powernode:setVisible(true)
            end

            ccbDocumentControler.isselect:setVisible(selectindex == a1+1)

            ccbDocumentControler.selectbutton:setTouchPriority(self.touchPriority-1)
            ccbDocumentControler.selectbutton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                if data.use ==0  then
                    -- runGamePrompt({msg = "今日助战次数已用尽"})
                    runGamePrompt({msg = gameConfig.strings:string_common("popups","perout")})
                else

                    if selectindex == a1+1 then
                        selectfriend = nil
                        selectindex = -1
                    else
                        selectfriend = data
                        selectindex = a1+1
                    end
                    ListTableView:reloadData()
                end
            end, CCControlEventTouchUpInside)

            cellCCB:setPosition(932/2, 0)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(dataTable)
        elseif fn == "cellTouched" then
        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listNode:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)
end

function friendcopy.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    gameTouch:UnrigistFunc("begin","friendcopy")
    gameTouch:UnrigistFunc("end","friendcopy")    
    self.isscrolltouched = false
    if self.callback then
        self.callback()
    end
end

return friendcopy