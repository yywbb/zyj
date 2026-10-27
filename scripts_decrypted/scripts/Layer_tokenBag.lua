
local tokenBag = {

    resource = nil,


    rootNode = nil,
    rootItems = nil,
   

    normalCellSize = {x=1080,y=270},
    detailCellSize = {x=1080,y=402},

    pageconfig = {"token","fragments"},--"exchange"} ,
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            --加新页签需要加
            config = {
                title2 = {632},
            },
        },
    },
    pagename = {gameConfig.strings:string_common("token",1),gameConfig.strings:string_common("token",2)},
    selectpage = "token",

    tokendata = {},
    fragmentdata= {},
    fragmentsListTableView = nil,
    tokenListTableView = nil,

    isscrolltouched = false,

}

function tokenBag.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("tianjiling/tianjilingBag", nil, true, "tianjilingBag")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.gotonode:setPositionY(toppos/2)
    self.rootItems.titlebgbottom:setVisible(false)

    self.rootItems.bagbg1:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-350))
    self.rootItems.tokenNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-600))
    self.rootItems.fragmentsNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-600))
 

    ui.setLabelString(self.rootItems.gotoTokenSetText,nil,13)
    self.rootItems.gotoTokenSetBtn:setSwallowsTouch(true)
    self.rootItems.gotoTokenSetBtn:setTouchPriority(-103)
    self.rootItems.gotoTokenSetBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("tokenMain", "up", {page = "token", sid =  1, slotdata = {}})
    end, CCControlEventTouchUpInside)


    self.tokenConfig = gamedata.config.token
    self.token_fragmentConfig = gamedata.config.token_fragment



    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","tokenBag",touchbegin)
    local function touchend(pos)
        if self.rootItems.tokenNode and ui.isTouched(self.rootItems.tokenNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.fragmentsNode and ui.isTouched(self.rootItems.fragmentsNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
       
    end
    gameTouch:rigistFunc("end","tokenBag",touchend)

    self.selectpage = self.selectpage or "token"
    self:shiftPage(self.selectpage)

end

function tokenBag.clear(self)

    self.hasprops = {}

    gameTouch:UnrigistFunc("begin","tokenBag")
    gameTouch:UnrigistFunc("end","tokenBag")    
    self.isscrolltouched = false    
    self.rootItems = nil
    self.fragmentsListTableView = nil
    self.tokenListTableView = nil

    self.selectpage = "token"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

-- 列表
function tokenBag.settokenCell(self,data,items,index,selectpage)
    print("settokenCell",index,selectpage)
    printT(data)
    local key_Ex
    local id = index-1
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end
    ui.sethint(items["i_hint"..key_Ex],false)
    if selectpage == "token" then
        ui.setPropIcon(items, {cid = data.cid, num = data.num}, index-1, data)
        local configdata = ui.IDconfig(data.cid) or {}
        ui.setLabelString(items["i_name"..key_Ex],configdata.name, 1)
        if items["i_isonNode"..key_Ex] then
            items["i_isonNode"..key_Ex]:setVisible(false)
        end

    elseif selectpage == "fragments" then
        ui.setPropIcon(items, {cid = data.cid, num = "", staffType = "token_fragment"}, index-1)
        setSpriteFrameByName(items["i_soulsprite"..key_Ex], "b_sprite1")
        local configdata = ui.IDconfig(data.cid) or {}


        if items["barNode"..key_Ex] then
            items["barNode"..key_Ex]:setVisible(true)
            -- ui.sethint(items["i_hint"..key_Ex],configdata.neednum <= data.num)
            -- items["i_hint"..key_Ex]:setPosition(160,-45)
            ui.setLabelString(items["barLabel"..key_Ex], data.num.."/"..configdata.neednum, 14)
            ui.setSpriteTextureRect2(items["bar_bright"..key_Ex],0,0,154*(data.num < configdata.neednum and data.num/configdata.neednum or 1),30)
        end
    end

    items["i_button"..key_Ex]:setTouchPriority(-104)
    -- items["i_button"..key_Ex]:setSwallowsTouch(true)
    items["i_button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        -- pageconfig = {"generals","fragments","redfragments"}
        if self.selectpage == "token" then
            ui.setPopwindowByCid(data.cid,data)
        elseif self.selectpage == "fragments" then
            ui.setPopwindowByCid(data.cid,data)
        end
        -- 
    end, CCControlEventTouchUpInside)
end

function tokenBag.createTokenList(self)
    print("createTokenList")
    local celldict = {}
    local tokenListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general/cell_general_icon", nil, true, "cell_general_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.tokenListTableView,cellCCB,self.normalCellSize.x/2+30,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            for i=4,0,-1 do

                if self.tokendata[(a1+1)*5-i] or self.tokendata[tostring((a1+1)*5-i)] then
                    self:settokenCell(self.tokendata[(a1+1)*5-i] or self.tokendata[tostring((a1+1)*5-i)],ccbDocumentControler,5-i,"token")
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end

            if self.tokenListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2+30, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.tokendata)/5)
            print("numberOfCells",r)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.tokenListTableView = ui.createLuaTableView({
        handle = tokenListHandle,
        viewwidth = self.rootItems.tokenNode:getContentSize().width,
        viewheight = self.rootItems.tokenNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.tokenNode:addChild(self.tokenListTableView)
    self.tokenListTableView:setTouchPriority(-101)
end

function tokenBag.ReloadGenerals(self,data)
    self.generalsdata = data

end

function tokenBag.showToken(self)

    if self.tokenConfig and next(self.tokenConfig) then
        local cids = {}
        for k,v in pairs(self.tokenConfig) do
            table.insert(cids,v.id)
        end
        printT(cids,"showToken")
        UIRequest({type = 12001, order = 34306, cids = cids})
    end
end

function tokenBag.showTokenfragment(self)
    if self.token_fragmentConfig and next(self.token_fragmentConfig) then
        local cids = {}
        for k,v in pairs(self.token_fragmentConfig) do
            table.insert(cids,v.id)
        end
        printT(cids,"showTokenfragment")
        UIRequest({type = 12001, order = 34306, cids = cids})
    end
end



function tokenBag.showTokens(self)
    printT(self.tokendata,"tokendata")
    if self.rootItems then
        if table.getTableLength(self.tokendata) > 0 then
            local sort = function(a,b)
                return a.cid>b.cid
            end
            table.sort(self.tokendata,sort)
            printT(self.tokendata,"tokendata")
            if not self.tokenListTableView then
                self:createTokenList()
            else
                self.tokenListTableView:reloadData()
            end
        end
        ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.tokendata) == 0,"token")
    end
end    

function tokenBag.showFragments(self)
    printT(self.fragmentdata,"fragmentdata")
    if self.rootItems then
        if table.getTableLength(self.fragmentdata) > 0 then
            local sort = function(a,b)
                local configdata1 = ui.IDconfig(a.cid) or {}
                local configdata2 = ui.IDconfig(b.cid) or {}
        
                local isupgrade1,isupgrade2 = false
                if configdata1.neednum <= a.num then
                    isupgrade1 = true
                end    
                if configdata2.neednum <= b.num then
                    isupgrade2 = true
                end    
                
                if isupgrade1 and isupgrade2 then
                    return a.cid>b.cid
                end    
                 
                if isupgrade1 then
                    return true
                end    
                if isupgrade2 then
                    return false
                end    
        
                if not isupgrade1 and not isupgrade2 then
                    return a.cid>b.cid
                end    
        
            end
            table.sort(self.fragmentdata,sort)
            printT(self.fragmentdata,"fragmentdata")
            if not self.fragmentsListTableView then
                self:createFragmentsList()
            else
                if self.fragmentsListTableView:getLuaContentOffsetY() < self.rootItems.fragmentsNode:getContentSize().height - math.ceil(table.getTableLength(self.fragmentdata)/5)*self.normalCellSize.y then
                    self.fragmentsListTableView:setLuaContentOffset(0, self.rootItems.fragmentsNode:getContentSize().height - math.ceil(table.getTableLength(self.fragmentdata)/5)*self.normalCellSize.y)
                end
                self.fragmentsListTableView:reloadData()
            end
        end
        ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.fragmentdata) == 0,"tokenfragment")
    end
end



function tokenBag.shiftPage(self,type)
    self.selectpage = type
    print("shiftPage",self.selectpage)
    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(0)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(9999)
        end
    end

    if type == "token" then
        self:showToken()
    elseif type == "fragments" then
        self:showTokenfragment()
    end
end

function tokenBag.createFragmentsList(self)

    local celldict = {}
    local fragmentsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general/cell_general_icon", nil, true, "cell_fragment")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.fragmentsListTableView,cellCCB,self.normalCellSize.x/2+30,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            for i=4,0,-1 do
                if self.fragmentdata[(a1+1)*5-i] or self.fragmentdata[tostring((a1+1)*5-i)] then
                    self:settokenCell(self.fragmentdata[(a1+1)*5-i] or self.fragmentdata[tostring((a1+1)*5-i)],ccbDocumentControler,5-i,"fragments")
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end

            if self.fragmentsListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2+30, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.fragmentdata)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.fragmentsListTableView = ui.createLuaTableView({
        handle = fragmentsListHandle,
        viewwidth = self.rootItems.fragmentsNode:getContentSize().width,
        viewheight = self.rootItems.fragmentsNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.fragmentsNode:addChild(self.fragmentsListTableView)
    self.fragmentsListTableView:setTouchPriority(-101)
end



function tokenBag.ReloadData(self,data)
    printT(data,"ReloadData",self.selectpage)
    local changedata = {}  
    if self.selectpage and self.selectpage == "token" then
        if data then
            for k, v in pairs(data) do
                if v > 0 then 
                   table.insert(changedata,{cid = k,num = v})
                end
            end
         end  
        if changedata then self.tokendata = changedata end
        self:showTokens()
    elseif self.selectpage and self.selectpage == "fragments" then
        if data then
            for k, v in pairs(data) do
                table.insert(changedata,{cid = k,num = v})
            end
         end  
        if changedata then self.fragmentdata = changedata end
         self:showFragments()
    end
end

function tokenBag.UIUpdateData(self, isreset)
    print("tokenBag.UIUpdateData")
    self:shiftPage(self.selectpage)
end

return tokenBag
  n9  