--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 上午10:10
-- To change this template use File | Settings | File Templates.
--

local zhuxiantaireward = {
    rootNode = nil,
    rootItems = nil,

    isscrolltouched = false,

    pageconfig = {"first","list" },
    selectpage = "first",
}

function zhuxiantaireward.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuxiantai2/zhuxiantai_jiangli", nil, true, "jiangli")

    self.touchPriority = touchPriority


    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","zhuxiantaireward",touchbegin)

    local function touchend(pos)
        if self.rootItems.firstnode and ui.isTouched(self.rootItems.firstnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","zhuxiantaireward",touchend)
    --

    self:reload(data,callback)

    return self.rootNode
end

function zhuxiantaireward.shiftpage(self,page)

    if self.selectpage ~= page then
        self.selectedData = {}
    end

    self.selectpage = page
    for k,v in ipairs(self.pageconfig) do
        if v == page then
            setSpriteFrameByName(self.rootItems["tabon"..k], gameConfig.images.pageButtonON)
        else
            setSpriteFrameByName(self.rootItems["tabon"..k], gameConfig.images.pageButtonOFF)
        end
    end

    if self.selectpage == "first" then
        self.rootItems.firstnode:setPositionX(540)
        self.rootItems.listnode:setPositionX(9999)
    else
        self.rootItems.firstnode:setPositionX(9999)
        self.rootItems.listnode:setPositionX(540)
    end
end


function zhuxiantaireward.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("zhuxiantaireward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local config = gamedata.config.mieshendian_reward or {}

    local rewarddata = {}
    for k,v in pairs(config) do
        table.insert(rewarddata,v)
    end
    local sortBy = function(a,b) return a.floor < b.floor end
    table.sort(rewarddata, sortBy)

    --
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(926, 224)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuxiantai2/cell_zhuxiantai_jiangli", nil, true, "cell_zhuxiantai_jiangli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --

            ccbDocumentControler.floor:setString(rewarddata[a1+1].floor)
            local rewards = ui.getIDandNUMs(rewarddata[a1+1].rewards) or {}
            for i = 1,4 do
                if rewards[i] and rewards[i].cid then
                    ccbDocumentControler["r"..i]:setVisible(true)
                    ui.setNewIcon(ccbDocumentControler,{cid = rewards[i].cid, num = rewards[i].num},i-1)

                    ccbDocumentControler["i_button"..(i==1 and "" or ("_"..(i-1)))]:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        ui.setPopwindowByCid(rewards[i].cid)
                    end, CCControlEventTouchUpInside)
                    --ccbDocumentControler["i_button"..(i==1 and "" or ("_"..(i-1)))]:setSwallowsTouch(true)
                    ccbDocumentControler["i_button"..(i==1 and "" or ("_"..(i-1)))]:setTouchPriority(self.touchPriority)
                else
                    ccbDocumentControler["r"..i]:setVisible(false)
                end
            end
            --
            cellCCB:setPosition(926/2, 224/2)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(rewarddata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)

    --
    --
    local config2 = gamedata.config.mieshendian_award or {}

    local rewarddata2 = {}
    for k,v in pairs(config2) do
        table.insert(rewarddata2,v)
    end
    local sortBy2 = function(a,b) return a.number < b.number end
    table.sort(rewarddata2, sortBy2)

    --
    local celldict2 = {}
    local ListHandle2 = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(926, 224)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuxiantai2/cell_zhuxiantai_jiangli", nil, true, "cell_zhuxiantai_jiangli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --

            ccbDocumentControler.floor:setString(rewarddata2[a1+1].number)
            local rewards = ui.getIDandNUMs(rewarddata2[a1+1].reward) or {}
            for i = 1,4 do
                if rewards[i] and rewards[i].cid then
                    ccbDocumentControler["r"..i]:setVisible(true)
                    ui.setNewIcon(ccbDocumentControler,{cid = rewards[i].cid, num = rewards[i].num},i-1)

                    ccbDocumentControler["i_button"..(i==1 and "" or ("_"..(i-1)))]:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        ui.setPopwindowByCid(rewards[i].cid)
                    end, CCControlEventTouchUpInside)
                    --ccbDocumentControler["i_button"..(i==1 and "" or ("_"..(i-1)))]:setSwallowsTouch(true)
                    ccbDocumentControler["i_button"..(i==1 and "" or ("_"..(i-1)))]:setTouchPriority(self.touchPriority)
                else
                    ccbDocumentControler["r"..i]:setVisible(false)
                end
            end
            --

            if ccbDocumentControler.hasnode then
                if data and data.maxfloor and data.maxfloor >= rewarddata2[a1+1].number then
                    ccbDocumentControler.hasnode:setVisible(true)
                    ui.setLabelString(ccbDocumentControler.hastext,nil,14)
                else
                    ccbDocumentControler.hasnode:setVisible(false)
                end
            end    

            --
            cellCCB:setPosition(926/2, 224/2)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(rewarddata2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView2 = ui.createLuaTableView({
        handle = ListHandle2,
        viewwidth = self.rootItems.firstnode:getContentSize().width,
        viewheight = self.rootItems.firstnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.firstnode:addChild(ListTableView2)
    ListTableView2:setTouchPriority(self.touchPriority)

    --

    for i = 1,2 do
        self.rootItems["tabbutton"..i]:addHandleOfControlEvent(function()
            self:shiftpage(self.pageconfig[i])
        end, CCControlEventTouchUpInside)
        self.rootItems["tabbutton"..i]:setSwallowsTouch(true)
        self.rootItems["tabbutton"..i]:setTouchPriority(self.touchPriority-2)
    end

    self:shiftpage(self.selectpage)

end

function zhuxiantaireward.close(self)
    gameTouch:UnrigistFunc("begin","zhuxiantaireward")
    gameTouch:UnrigistFunc("end","zhuxiantaireward")
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return zhuxiantaireward