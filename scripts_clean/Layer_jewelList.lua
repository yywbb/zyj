--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/24
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--

local jewelList = {

    resource = nil,
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"skill","attack","defence","life"},
    pagename = {gameConfig.strings:string_common("fixedString","general",1),gameConfig.strings:string_common("attr_type","atk"),
    gameConfig.strings:string_common("attr_type","def"),gameConfig.strings:string_common("attr_type","hp")},
    selectpage = "skill",

    skillJewelData = nil,
    attackJewelData = nil,
    defenceJewelData = nil,
    lifeJewelData = nil,
   
    touchPriority = -102,
    CellSize = {x=1080,y=228},

}


function jewelList.shiftPage(self,type)
    self.selectpage = type or self.selectpage
    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:setLuaContentOffset(0, self.rootItems.listscroll:getContentSize().height - table.getTableLength(self[self.selectpage.."JewelData"])*self.CellSize.y)
        self.ListTableView:reloadData()
    end
end



function jewelList.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("duanzaoshenqi/baoshibag", nil, true, "baoshiList")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.listscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-120))
    UIRequest({type = 10031})
end



function jewelList.setlistCell(self,items,data)
    ui.setNewIcon(items,{cid = data.cid},0)
    items["i_button"]:addHandleOfControlEvent(function()
        gameWindows:openWindow("jewelInfo",{cid = data.cid,isUp = false},nil)
    end, CCControlEventTouchUpInside)
    items["i_button"]:setTouchPriority(self.touchPriority)
    local config =  gamedata.config.trump_gem[tostring(data.cid)]
    ui.setLabelString(items.name,config.name,1)

    ui.setAttrStr(items["attr"],data)
    ui.setLabelString(items.num,""..data.num,48)

    --
    local config = gamedata.config.trump_gem[tostring(data.cid + 1)]
    if not config then
        ui.addGray("CCControlButton",items.button1)
        items.button1:setTouchEnabled(false)
    else
        ui.removeGray("CCControlButton",items.button1)
        items.button1:setTouchEnabled(true)
    end
    items.button1:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        UIRequest({type = 5507,cid = data.cid + 1,num = 9999})
    end, CCControlEventTouchUpInside)
    items.button1:setSwallowsTouch(true)
    items.button1:setTouchPriority(self.touchPriority)
end



function jewelList.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("duanzaoshenqi/cell_baoshi", nil, true, "cell_baoshi")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.ListTableView,cellCCB,self.CellSize.x/2, 0,a1)
                self:initCellFixedString(ccbDocumentControler)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setlistCell(ccbDocumentControler,self[self.selectpage.."JewelData"][tostring(a1+1)])

            if self.ListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self[self.selectpage.."JewelData"])
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
    self.ListTableView:setTouchPriority(-101)
end

function jewelList.initCellFixedString(self,cellItems)
    cellItems.fixed1:setString(gameConfig.strings:string_common("general",12))
    ui.setLabelString(cellItems.buttontext1,gameConfig.strings:string_common("artifact",1),19)
end


function jewelList.reloadData(self,t)
    if t.jewelType then
        self[t.jewelType.."JewelData"] = t.data
        if self.selectpage == t.jewelType and GameScene.layers["jewel"].show then
            self:shiftPage()
        end
    else
        self.skillJewelData = t.data.skillJewelData
        self.attackJewelData = t.data.attackJewelData
        self.defenceJewelData = t.data.defenceJewelData
        self.lifeJewelData = t.data.lifeJewelData
        if GameScene.layers["jewel"].show then
            self:shiftPage()
        end
    end
  
end

function jewelList.commpondSuccess(self,data)
    local sStr = "消耗宝石：\n  "
    for k,v in pairs(data.uses) do
        local jewelConfig = gamedata.config.trump_gem[k]
        sStr = sStr..jewelConfig.name.." "..v.."   "
    end
    local config = gamedata.config.trump_gem[tostring(data.cid)]
    sStr = sStr.."\n".."生成".." "..config.name.." "..data.createNum
    gameWindows:openWindow("confirm",{msg = sStr,noShowCancel = true,fontId = 18})
end


function jewelList.clear(self)
    self.ListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil
end


return jewelList