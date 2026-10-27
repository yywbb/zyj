--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/24
-- Time: 下午6:36
-- To change this template use File | Settings | File Templates.
--

local mofulist = {

    rootNode = nil,
    rootItems = nil,


    ListTableView = nil,

    pageconfig = {"mofu"},
    -- pagename = {"魔 符"},
    pagename = {gameConfig.strings:string_common("mofulist",1)},
    
    
    selectpage = "mofu",

    mofudata = {},
    slotmofudata = {},
    isscrolltouched = false,
}

function mofulist.shiftPage(self,type)
    -- print("i...am..shiftPage",type)
    if type and self.selectpage == type then
        -- print("nothing..change")
        return
    end
    -- print("shiftPagexxxboss2",type)
    if type then
        self.selectpage = type
    end
    

    if self.selectpage == "mofu" then
        -- print("selectpage==mofu")
        if not GameScene:checkUpdate(10022) and not GameScene:checkUpdate(10028) then
            -- print("pagemofu===")
            self:reloadstatus()
        end
    end
end


function mofulist.mofudataReload(self,data)
    -- print("mofudataReload==000")
    -- printT(data)
    -- self.mofudata = {}
    -- for k,v in pairs(data) do
    --     table.insert(self.mofudata,v)
    -- end
    self.mofudata = data
    -- print("mofudataReload==")
    -- printT(self.mofudata)
end

function mofulist.slotmofudataReload(self,data)
    -- print("slotmofudataReload==000")
    -- printT(data)
    -- self.slotmofudata = {}
    -- for k,v in pairs(data) do
    --     table.insert(self.slotmofudata,v)
    -- end
    -- print("slotmofudataReload==")
    -- printT(self.slotmofudata)
    self.slotmofudata = data
    -- print("slotmofudata===")
    -- printT(data)
end

function mofulist.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("mofu/mofu_beibao.ccbi", nil, true, "mofu_beibao")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.bagbg1:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-350))
    self.rootItems.scrollnode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-600))
    self.rootItems.gotonode:setPositionY(toppos/2-40)

    
    ui.setLabelString(self.rootItems.gotoMofuSetText,nil,13)
    self.rootItems.gotoMofuSetBtn:setSwallowsTouch(true)
    self.rootItems.gotoMofuSetBtn:setTouchPriority(-103)
    self.rootItems.gotoMofuSetBtn:addHandleOfControlEvent(function()
        -- gameWindows:openWindow("friendcopy",{type = "rule"},nil)
        GameScene:shiftLayerById(158)
    end, CCControlEventTouchUpInside)
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","mofulist",touchbegin)
    local function touchend(pos)
        if self.rootItems.scrollnode and ui.isTouched(self.rootItems.scrollnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","mofulist",touchend)
    self:shiftPage()

    -- self.rootItems.rewardListBtn:setTouchPriority(-101)
    -- self.rootItems.rewardListBtn:addHandleOfControlEvent(function()
        -- print("i...am ...pre")
    --      gameWindows:openWindow("mofulistrank",{index = "reward", data = {}},nil)
    -- end, CCControlEventTouchUpInside)


    -- ui.setLabelString(self.rootItems.startdec_text,nil,18)

end

function mofulist.setGeneralCell(self,data,items,index,selectpage)

    printT(data,"jkp-mofuData")
    local celldata = data
    celldata.temp = ui.IDconfig(celldata.cid)

    local key_Ex
    local id = index-1
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    ui.setPropIcon(items, {cid = data.cid, num = data.num}, index-1)

    if data.ison and data.ison ~= 0 then
        -- 镶嵌
        items["i_isonNode"..key_Ex]:setVisible(true)
        items["i_isonLab"..key_Ex]:setString("已镶嵌")
    else
        -- 未镶嵌
        items["i_isonNode"..key_Ex]:setVisible(false)
    end

    -- 点击icon弹出详情
    items["i_button"..key_Ex]:setTouchPriority(-103)
    items["i_button"..key_Ex]:addHandleOfControlEvent(function()
        -- print("魔符详情")
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        local selectlistdata = {}
        for k,v in pairs(self.mofudata) do
            v.temp = ui.IDconfig(v.cid)
            -- printT(v)
            if celldata.temp.type == v.temp.type and celldata.iid ~= v.iid and v.ison == 0 then
                table.insert(selectlistdata,v)
            end
        end

        local sortfunc = function( a,b )
            return a.temp.order > b.temp.order
        end
        table.sort(selectlistdata,sortfunc)
        -- printT(selectlistdata)
        gameWindows:openWindow("mofuproperty",{infodata = celldata,selectlistdata = selectlistdata,page = "list"},nil)
    end, CCControlEventTouchUpInside)

end


function mofulist.createList(self)
    -- print("createRankList==")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1040, 270)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                -- cellCCB, ccbDocumentControler = CCBReaderLoad("mofu/cell_mofu", nil, true, "cell_mofu")
                cellCCB, ccbDocumentControler = CCBReaderLoad("mofu/cell_mofu_icon", nil, true, "cell_mofu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.ListTableView,cellCCB,920/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            -- print("createRankListitem:",a1)
            -- printT(self.mofudata[tostring(a1+1)])

            for i=4,0,-1 do
                if self.mofudata[(a1+1)*5-i] or self.mofudata[tostring((a1+1)*5-i)] then
                    self:setGeneralCell(self.mofudata[(a1+1)*5-i] or self.mofudata[tostring((a1+1)*5-i)],ccbDocumentControler,5-i)
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end
            
            cellCCB:setPosition(1080/2 + 30, 0)

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.mofudata)
            r = math.ceil(table.getTableLength(self.mofudata)/5)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.scrollnode:getContentSize().width,
        viewheight = self.rootItems.scrollnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.scrollnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


function mofulist.reloadstatus(self)
    -- print("reloadstatus===")

    -- printT(self.mofudata)
    if self.ListTableView == nil then
        self:createList()
    else
        self.ListTableView:reloadData()
        if self.ListTableView:getLuaContentOffsetY() < self.rootItems.scrollnode:getContentSize().height - math.ceil(table.getTableLength(self.mofudata)/5)*270 then
             self.ListTableView:setLuaContentOffset(0, self.rootItems.scrollnode:getContentSize().height - math.ceil(table.getTableLength(self.mofudata)/5)*270)
        end
    end

    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.mofudata) == 0,self.selectpage)
end


function mofulist.clear(self)
    gameTouch:UnrigistFunc("begin","mofulist")
    gameTouch:UnrigistFunc("end","mofulist")    
    self.isscrolltouched = false
    
    self.ListTableView = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end



return mofulist  R"  