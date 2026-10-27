--
-- Author: songyibo
-- Date: 2018-09-28 10:49:48
--

local rank = {
    rootNode = nil,
    rootItems = nil,
    listview = nil,

    data = {},
}

function rank.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("chongbang/chongbang_ranktc", nil, true, "chongbang_ranktc")
    self.touchPriority = touchPriority
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("activityNewRank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.rootItems.fixedMy:setString(gameConfig.strings:string_common("fixedString","copyFiend",4))
    self.rootItems.norank:setString(gameConfig.strings:string_common("popups","weishangbang"))
    self.rootItems.fixedMing:setString(gameConfig.strings:string_common("fixedString","rank",1))

    if data then
        self:reloadData(data)
    end
    return self.rootNode
end

function rank.reloadData(self,data)

    printT(data,"rank")
    self.data = data

    self.rootItems.fixedTitle:setString(gameConfig.strings:string_common("fixedString","activityRank",200+self.data.rankId))

    self:setMyRank()
    local len = table.getTableLength(self.players)
    if len >= 1 then
        if not self.listview  then
            self:createList()
        else
            self.listview:reloadData()
        end
        self.rootItems.notPlayer:setVisible(false);
    else
        self.rootItems.notPlayer:setVisible(true);
    end
end


function rank.setMyRank(self)

    local myrank = 0
    local myscore = 0


    self.players = {}

    if self.data.mydata then
        myrank = self.data.mydata.rank
        myscore = self.data.mydata.score
    end

    for k,v in pairs(self.data.players) do
         v.rank = tonumber(k)
         table.insert(self.players,v)
    end
    local sortBy = function(a,b) return a.rank < b.rank end
    table.sort(self.players, sortBy)
    
    --删除自己
    if self.data.rankId == 12  then
        table.remove(self.players,#self.players)
    end
    
    printT(self.players,"self.players")

    self.rootItems.num1:setString(myscore)
    ui.setLabelString(self.rootItems.num1,nil,21)

    if self.data.rankId == 5 then
        if myscore == "0阶0星" then
            self.rootItems.num1:setVisible(false)
            self.rootItems.type1:setVisible(false)
        else
            self.rootItems.num1:setVisible(true)
            self.rootItems.type1:setVisible(true)
        end
    else
        if tonumber(myscore) == 0 then
            self.rootItems.num1:setVisible(false)
            self.rootItems.type1:setVisible(false)
        else
            self.rootItems.num1:setVisible(true)
            self.rootItems.type1:setVisible(true)
        end
    end
    

    if  myrank < 1 then
        self.rootItems.hasrank:setVisible(false)
        self.rootItems.norank:setVisible(true)
    else
        self.rootItems.hasrank:setVisible(true)
        self.rootItems.norank:setVisible(false)
        self.rootItems.rank:setString(myrank)
        ui.labelfollow(self.rootItems.fixedMing,self.rootItems.rank)
    end


    if gameConfig.strings:string_common("fixedString","activityRank",100+self.data.rankId) then
        self.rootItems.type1:setString(gameConfig.strings:string_common("fixedString","activityRank",100+self.data.rankId))
    end

    self.rootItems.num1:setPositionX(self.rootItems.type1:getPositionX()+self.rootItems.type1:getContentSize().width + 3)

end

local rankconfig = {}
local function setlevel(item,data)
    item.type:setString(gameConfig.strings:string_common("fixedString","activityRank",102))
    item.num:setString(data.param)
end
rankconfig[1] = {setfunc = setlevel}


local function setpower(item,data)

    item.num:setString(data.param)
    -- item.showdata:setString(data.param)
    -- ui.setLabelString(item.num1,data.level,14)
end 
rankconfig[2] = {setfunc = setpower}


local function setwing(item,data)
    item.num:setString(gameConfig.strings:wingGrow(data.params["1"].i,data.params["2"].i))
    -- item.showdata:setString(gameConfig.strings:wingGrow(data.params["1"].i,data.params["2"].i))
    -- ui.setLabelString(item.num1,data.level,14)
end
rankconfig[5] = {setfunc = setwing}


local function setcopy(item,data)
    item.num:setString(gameConfig.strings:copyProcess(data.params["1"].i))

    -- item.showdata:setString(gameConfig.strings:copyProcess(data.params["1"].i))
    -- ui.setLabelString(item.num1,data.level,14)
end 
rankconfig[6] = {setfunc = setcopy}

local function setcover(item,data)
    item.num:setString(data.params["1"].i)
    
end 
rankconfig[7] = {setfunc = setcover}


local function setgeneral(item,data)

    item.num:setString(data.params["3"].i)
    
end 
rankconfig[18] = {setfunc = setgeneral}


local function setpowergrow(item,data)
    -- item.num:setString(data.param)
    item.num:setString(data.params["1"].i);
    
end 
rankconfig[11] = {setfunc = setpowergrow}
rankconfig[13] = {setfunc = setpowergrow}
rankconfig[14] = {setfunc = setpowergrow}


local function setmofu(item,data)
    item.num:setString(data.params["1"].i)
end 
rankconfig[12] = {setfunc = setmofu}

local function setmingge(item,data)
    item.num:setString(data.params["1"].i)
end 
rankconfig[15] = {setfunc = setmingge}


local function setfabao(item,data)
    item.num:setString(data.params["1"].i)
end 
rankconfig[16] = {setfunc = setfabao}

local function setartifact(item,data)
    item.num:setString(data.params["2"].i)
end 
rankconfig[17] = {setfunc = setartifact}


function rank.createList(self)
    print("createRankList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 180)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("chongbang/cell_openServer_paihang2", nil, true, "cell_openServer_paihang2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --
            -- if data.method == 12 then
            --     ccbDocumentControler.floorLab2:setString(gameConfig.strings:string_common("activity",10))
            -- elseif data.method == 11  or data.method == 13 or data.method == 14 then
            --     ccbDocumentControler.floorLab2:setString(gameConfig.strings:string_common("activity",9))
            -- end
            ccbDocumentControler.name:setString(self.players[a1+1].name or "")
            ccbDocumentControler.lv:setString(self.players[a1+1].level or "")

            ccbDocumentControler.type:setString(gameConfig.strings:string_common("fixedString","activityRank",100+self.data.rankId))

            if rankconfig[self.data.rankId] then
                rankconfig[self.data.rankId].setfunc(ccbDocumentControler,self.players[a1+1])
                ccbDocumentControler.num:setPositionX(ccbDocumentControler.type:getPositionX()+ccbDocumentControler.type:getContentSize().width + 3)
            end

            ccbDocumentControler.rank1:setVisible(false)
            ccbDocumentControler.rank2:setVisible(false)
            ccbDocumentControler.rank3:setVisible(false)
            ccbDocumentControler.rankother:setVisible(false)

            if self.players[a1+1].rank == 1 then
                ccbDocumentControler.rank1:setVisible(true)
            elseif self.players[a1+1].rank == 2 then
                ccbDocumentControler.rank2:setVisible(true)
            elseif self.players[a1+1].rank == 3 then
                ccbDocumentControler.rank3:setVisible(true)
            else
                ccbDocumentControler.rankother:setVisible(true)
                ccbDocumentControler.rank:setString(self.players[a1+1].rank)
            end
            --

            if self.data.rankId == 17 then
                ui.setNewIcon(ccbDocumentControler,{cid = self.players[a1+1].params["1"].i})
            else
                ui.setNewIcon(ccbDocumentControler,{cid = self.players[a1+1].profile,iconBox = self.players[a1+1].iconBox})
            end

            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end                
                if self.players[a1+1].rid ~= GameScene.roleinfo.id then
                    gameWindows:openWindow("chatpop",self.players[a1+1],nil)
                end
            end, CCControlEventTouchUpInside)
            ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority)

            --
            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.players)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

function rank.close(self)  
    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode = nil
    self.rootItems = nil


    self.listview = nil
    self.playerdata = {}
    self.activityConfig = {}
    self.mydata = {}

    if self.callback then
        self.callback()
    end
end

return rank