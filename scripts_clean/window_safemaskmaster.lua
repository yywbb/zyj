--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/6/30
-- Time: 18:24
-- To change this template use File | Settings | File Templates.
--

local safemaskmaster = {
    rootNode = nil,
    rootItems = nil,
}

function safemaskmaster.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("safemask/safemask_ach", nil, true, "safemask_ach")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    self:initFixedString()
    return self.rootNode
end

function safemaskmaster.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("safemaskmaster")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    if not data then return end
    --
    local achconfig = gamedata.config.mozhao_liandan or {}
    local master = {}
    local allatk,alldef,allhp = 0,0,0
    for i = 1,7 do
        if achconfig[tostring(i)] then
            for k,v in pairs(achconfig[tostring(i)]) do
                if v.id == data[tostring(i)].masterid then
                    local attrs = ui.getSTRandNUMs(v.effect)
                    for k,v in pairs(attrs) do
                        if v.str == "atk" then
                            allatk = allatk+v.num
                        elseif v.str == "def" then
                            alldef = alldef+v.num
                        elseif v.str == "hp" then
                            allhp = allhp+v.num
                        end
                    end
                end

                if v.id == data[tostring(i)].masterid then
                    v.activation = 1
                    table.insert(master,v)
                elseif v.id == (data[tostring(i)].masterid+1) then
                    v.activation = 0
                    table.insert(master,v)
                end
            end
        end
    end
    --
    if master and next(master) then
        local sortfunc = function (a,b)
            if a.type < b.type then
                return true
            elseif a.type > b.type then
                return false
            else
                return a.cond < b.cond
            end
        end
        table.sort(master,sortfunc)
    end
    --
    ui.setLabelString(self.rootItems["attr1"],"",111)
    ui.setLabelString(self.rootItems["attr2"],"",111)
    ui.setLabelString(self.rootItems["attr3"],"",111)
    ui.setLabelString(self.rootItems["attr4"],"",111)
    local has = 1
    if allatk > 0 then
        ui.setLabelString(self.rootItems["attr"..has],gameConfig.strings:string_common("attr_type","atk").." +"..allatk,111)
        has = has+1
    end
    if alldef > 0 then
        ui.setLabelString(self.rootItems["attr"..has],gameConfig.strings:string_common("attr_type","def").." +"..alldef,111)
        has = has+1
    end
    if allhp > 0 then
        ui.setLabelString(self.rootItems["attr"..has],gameConfig.strings:string_common("attr_type","hp").." +"..allhp,111)
        has = has+1
    end

    --
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(940, 210)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("safemask/cell_lianqiach", nil, true, "cell_lianqiach")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            --
            ui.setNewIcon(ccbDocumentControler,{cid = 1000})
            setSpriteFrameByName(ccbDocumentControler["i_icon"],"ach_liandan")
            ccbDocumentControler.desc:setString(master[a1+1].desc or "")

            local attrstr = ""
            local attrs = ui.getSTRandNUMs(master[a1+1].effect)
            for k,v in pairs(attrs) do
                attrstr = attrstr..gameConfig.strings:string_common("attr_type",v.str).." +"..v.num.."    "
            end
            ccbDocumentControler.attr:setString(attrstr)
            --
            if master[a1+1].activation and master[a1+1].activation == 1 then
                ccbDocumentControler.activation:setVisible(true)
            else
                ccbDocumentControler.activation:setVisible(false)
            end
            --
            cellCCB:setPosition(940/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then

            r = table.getTableLength(master)
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

function safemaskmaster.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function safemaskmaster.initFixedString(self)
    ui.setLabelString(self.rootItems.fixlab1,gameConfig.strings:string_common("fixedString","safemask",3),13)
end

return safemaskmaster

