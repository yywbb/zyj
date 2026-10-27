--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local favoritetransferselect = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    ListTableView = nil,

    generalsdata = {},

}

function favoritetransferselect.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("love/love_selectgeneral", nil, true, "love_selectgeneral")
    self.root:addChild(self.rootNode)
    self.callback = callback

    --
    if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
        self.generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
    end 

    self:reload(data)
    return self.root
end

function favoritetransferselect.reload(self, data )
    self.selectdata = data.data or {}

    self.constcid = data.constcid or 0

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("favoritetransferselect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.listdata = data.listdata
    self.listnum = #self.listdata

    printT(self.listdata,"self.listdata")

    self.cellnum = math.ceil(self.listnum/4)
 
    self:createList()

end


function favoritetransferselect.setcell( self,a1, a2, celldict )
    local cellCCB,ccbDocumentControler = 0,0
    local first = true
    if not celldict[a2] then
        a2 = CCTableViewCell:create()
        cellCCB, ccbDocumentControler = CCBReaderLoad("love/cell_love_general_4", nil, true, "love/cell_love_general_4")
        celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
    else
        first = false
        cellCCB = celldict[a2].cellCCB
        ccbDocumentControler = celldict[a2].ccbDocumentControler
    end

    for i=1,4 do
        local celldata = self.listdata[a1*4+i]

        if celldata then
            ccbDocumentControler["generalccb"..i]:setVisible(true)
            local cid = celldata.hascid > 0 and celldata.hascid or celldata.cid
            -- 设置头像
            local configGeneral = gamedata.config.general[tostring(cid)]
            local gicon = configGeneral.icon
            if configGeneral.fashion_id == 0 then --非时装
                for k,v in pairs(self.generalsdata) do
                    if cid == v.cid then
                        if v.illusionGeneralCid == nil then
                            local gdata = ui.getConfigGeneral(v)
                            gicon = gdata.icon
                        end
                        break
                    end
                end
            end
            ui.setNewIconName(ccbDocumentControler,{cid = cid, icon = gicon},i-1)

            local keyext = i==1 and "" or "_"..(i-1)
            ccbDocumentControler["onteamNode"..keyext]:setVisible(celldata.ison > 0)
            ccbDocumentControler["onteamLab"..keyext]:setString(gameConfig.strings:string_common("favoritegeneral",30))

            ui.setLabelString(ccbDocumentControler["favoriteNum"..keyext],celldata.level,22)

            local sourcecid,destcid = 0,0
            if self.selectdata.source then
                sourcecid = self.selectdata.source.hascid > 0 and self.selectdata.source.hascid or self.selectdata.source.cid
            end
            if self.selectdata.dest then
                destcid = self.selectdata.dest.hascid > 0 and self.selectdata.dest.hascid or self.selectdata.dest.cid
            end
            ccbDocumentControler["isSelect"..keyext]:setVisible((sourcecid ==cid) or (destcid == cid))

            ccbDocumentControler["in_button"..keyext]:setSwallowsTouch(true)
            ccbDocumentControler["in_button"..keyext]:setTouchPriority(self.touchPriority-1)
            ccbDocumentControler["in_button"..keyext]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end

                if cid == self.constcid then
                    runGamePrompt({msg =gameConfig.strings:string_common("favoritegeneral",33)})
                    return
                end

                local sourcecid,destcid = 0,0
                if self.selectdata.source then
                    sourcecid = self.selectdata.source.hascid > 0 and self.selectdata.source.hascid or self.selectdata.source.cid
                end
                if self.selectdata.dest then
                    destcid = self.selectdata.dest.hascid > 0 and self.selectdata.dest.hascid or self.selectdata.dest.cid
                end

                if sourcecid == cid then
                    self.selectdata.source = nil
                elseif destcid == cid then
                    self.selectdata.dest = nil
                elseif not self.selectdata.source then
                    self.selectdata.source = table.copy(celldata)
                    sourcecid = self.selectdata.source.hascid > 0 and self.selectdata.source.hascid or self.selectdata.source.cid
                elseif not self.selectdata.dest then
                    self.selectdata.dest = table.copy(celldata)
                    destcid = self.selectdata.dest.hascid > 0 and self.selectdata.dest.hascid or self.selectdata.dest.cid
                end

                ccbDocumentControler["isSelect"..keyext]:setVisible((sourcecid ==cid) or (destcid == cid))

                if self.selectdata.source and self.selectdata.dest then
                    gameWindows:closeWindow("favoritetransferselect")
                end
            end, CCControlEventTouchUpInside)
        else
            ccbDocumentControler["generalccb"..i]:setVisible(false)
        end
    end

    cellCCB:setPosition(450, 150)
    if first then
        a2:addChild(cellCCB)
    end

    return a2
end

function favoritetransferselect.createList( self )
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(900, 300)
        elseif fn == "cellAtIndex" then

            r= self:setcell(a1, a2, celldict)

        elseif fn == "numberOfCells" then
            r = self.cellnum
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end


function favoritetransferselect.close(self)
  
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil
    self.generalsdata = {}

    if self.callback then
        self.callback(self.selectedData)
    end

end

return favoritetransferselect