--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--
local http_artifact_rank = require("http_artifact_rank")

local rank = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    ListTableView = nil,

    role = {},

    selectpage = "level",

    normalCellSize = {x=1080,y=210},

    isscrolltouched = false,

    rankconfig = {
        power   = {method = 2,typeext = gameConfig.strings:string_common("rank",2),name = gameConfig.strings:string_common("rank",0),typename = gameConfig.strings:string_common("rankext",0)},
        level   = {method = 1,typeext = gameConfig.strings:string_common("rank",3),name = gameConfig.strings:string_common("rank",1),typename = gameConfig.strings:string_common("rankext",1)},
        general = {method = 8,typeext = gameConfig.strings:string_common("rank",9),name = gameConfig.strings: string_common("rank",11),typename = gameConfig.strings:string_common("rankext",2)},
        wing    = {method = 5,typeext = gameConfig.strings:string_common("rank",2),name = gameConfig.strings:string_common("rank",4),typename = gameConfig.strings:string_common("rankext",5)},
        copy    = {method = 6,typeext = gameConfig.strings:string_common("rank",2),name = gameConfig.strings:string_common("rank",10),typename = gameConfig.strings:string_common("rankext",3)},
        cover   = {method = 7,typeext = gameConfig.strings:string_common("rank",9),name = gameConfig.strings:string_common("rank",5),typename = gameConfig.strings:string_common("rankext",4)},
        -- recharge = {method111 = 9,typeext = gameConfig.strings:string_common("rank",2),name = gameConfig.strings:string_common("rank",6),typename = gameConfig.strings:string_common("rankext",6)},
        gpower = {method = 19,typeext = gameConfig.strings:string_common("rank",2),name = gameConfig.strings:string_common("rank",14),typename = gameConfig.strings:string_common("rankext",8)},
        artifact = {method = 0,typeext = gameConfig.strings:string_common("rank",13),name = gameConfig.strings:string_common("rank",12),typename = gameConfig.strings:string_common("rankext",7)},
    },
}

function rank.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("rank2/paihangbang2", nil, true, "rankList")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.listNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-690-40))

    if self.rootItems.rankdesc then
        ui.setLabelString(self.rootItems.rankdesc,nil,14)
    end

    for k,v in pairs(self.rankconfig) do
        self.rootItems["button_"..k]:setTouchPriority(-103)
        self.rootItems["button_"..k]:addHandleOfControlEvent(function()
            self:shiftPage(k)
        end, CCControlEventTouchUpInside)

        self.rootItems["text_"..k]:setString(v.name)
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","rank",touchbegin)
    local function touchend(pos)
        if self.rootItems.listNode and ui.isTouched(self.rootItems.listNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","rank",touchend)

    self:shiftPage(self.selectpage)
end

function rank.clear(self)
    gameTouch:UnrigistFunc("begin","rank")
    gameTouch:UnrigistFunc("end","rank")    
    self.isscrolltouched = false    

    self.ListTableView = nil
    self.selectpage = "level"
    for k,v in pairs(self.rankconfig) do
        v.listviewpos = nil
        if k ~= "artifact" then
            v.mydata = nil
        end
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function rank.shiftPage(self,type)
    if not self.rankconfig[type].method then
        runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng2")})
        return
    end
    if self.ListTableView then
        self.rankconfig[self.selectpage].listviewpos = self.ListTableView:getLuaContentOffsetY()
    end

    self.selectpage = type
    print("shifPage")

    for k,v in pairs(self.rankconfig) do
        self.rootItems["sprite_"..k]:setVisible(k == type)
    end

    local config = self.rankconfig[self.selectpage]

    if config.changed or not config.data then
        if self.selectpage == "artifact" then
            --todo
            print("artifact_rank")
            local cb = function(value)
                if value then
                    local players = table.copy(value)
                    self:setMyArtifactData(players)
                    self:ReloadData({method = 0,players = players})
                end
            end

            http_artifact_rank:getdata(cb)
        else    
            UIRequest({type = 3500, method = config.method, pos = 1, num = 50})
        end
        config.changed =false
    else
        self:ReloadData()
    end
end

function rank.setMyArtifactData(self,data)
    local myrank = 0
    local mydata = {
        rid = GameScene.roleinfo.id,
        showdata = "",
        showdata2 = "",
        numext = "",
    }

    if GameScene.roleinfo.id < 1000000 then
        if gameWindows.windows["roleinfo"].module.SelectedServer and gameWindows.windows["roleinfo"].module.SelectedServer.id and gameWindows.windows["roleinfo"].module.SelectedServer.id > 0 then
            mydata.rid = gameWindows.windows["roleinfo"].module.SelectedServer.id*1000000 + GameScene.roleinfo.id
        end    
    end    

    if data and next(data) then
        for k,v in ipairs(data) do
            if mydata.rid == v.rid then
                myrank = v.rank
                mydata.showdata = v.score or ""
                --mydata.numext = gamedata.config.trump[tostring(v.artifact.cid)] and gamedata.config.trump[tostring(v.artifact.cid)].name or ""
                local trumpconfig = gamedata.config.trump[tostring(v.artifact.cid)]
                mydata.numext = trumpconfig.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..trumpconfig.name or trumpconfig.name
                break
            end    
        end    
    end 
    --   
    self.rankconfig.artifact.myrank = myrank
    self.rankconfig.artifact.mydata = mydata
end

function rank.setMyRank(self,data)
    
    local config = self.rankconfig[self.selectpage]

    config.mydata = data or config.mydata


    self.rootItems.type2:setString(config.typename)

    if self.selectpage == "general" or self.selectpage == "cover" then
        ui.setLabelString(self.rootItems.type1,gameConfig.strings:string_common("rank",7),14)
    else
        ui.setLabelString(self.rootItems.type1,config.typeext,14)
    end

    ui.setLabelString(self.rootItems.num1,config.mydata.numext or "",14)

    if self.selectpage == "cover" then
        ui.setLabelString(self.rootItems.type1,"",14)
        ui.setLabelString(self.rootItems.num1,"",14)
    end    

    if self.selectpage == "wing" then
        self.rootItems.showdata:setString(gameConfig.strings:wingGrow(config.mydata.showdata,config.mydata.showdata2))
    elseif self.selectpage == "copy" then
        self.rootItems.showdata:setString(gameConfig.strings:copyProcess(config.mydata.showdata))
    else
        self.rootItems.showdata:setString(config.mydata.showdata or "")
    end


    if not config.myrank then
        config.myrank = 0
        for k,v in pairs(config.data or {}) do
            if v.rid == config.mydata.rid then
                if (config.myrank == 0) or (config.myrank > tonumber(k)) then
                    config.myrank = tonumber(k)
                end
            end
        end
    end

    if config.myrank and config.myrank >0 then
        self.rootItems.hasrank:setVisible(true)
        self.rootItems.norank:setVisible(false)
        self.rootItems.rank:setString(config.myrank)
    else
        self.rootItems.hasrank:setVisible(false)
        self.rootItems.norank:setVisible(true)
    end

    if self.rootItems.numnode and self.rootItems.typenode then
        if self.selectpage == "artifact" then
            if config.myrank and config.myrank >0 then 
                self.rootItems.numnode:setVisible(true)
                self.rootItems.typenode:setVisible(true)
            else
                self.rootItems.numnode:setVisible(false)
                self.rootItems.typenode:setVisible(false)    
            end
            if self.rootItems.rankdesc then
                ui.setLabelString(self.rootItems.rankdesc,"本排行榜为跨服，每小时刷新一次",14)
            end
        else
            self.rootItems.numnode:setVisible(true)
            self.rootItems.typenode:setVisible(true)
            if self.rootItems.rankdesc then
                ui.setLabelString(self.rootItems.rankdesc,"本排行榜每5分钟刷新一次",14)
            end
        end    
    end

end

function rank.ReloadData(self,data)
    print("ReloadData")

    local config = self.rankconfig[self.selectpage]

    if data and config.method ~= data.method then return end

    if data then
        config.data = data.players
    end

    if self.rootItems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
            self.ListTableView:setLuaContentOffset(0,config.listviewpos or self.rootItems.listNode:getContentSize().height-table.getTableLength(config.data)*self.normalCellSize.y)
        end
    end

    if config.mydata then
        self:setMyRank()
    else
        UIRequest({type = 35001, method = config.method})
    end
end

function rank.Rankchange( self )
    for k,v in pairs(self.rankconfig) do
        v.data = nil
        v.myrank = nil
    end
    if GameScene.layers["ranklist"].show and self.rootItems then
        self:shiftPage(self.selectpage)
    end
end

local function setlevel(item,data)
    item.showdata:setString(data.level)
    ui.setLabelString(item.num1,data.param,14)
end 
rank.rankconfig.level.setfunc = setlevel

local function setpower(item,data)
    item.showdata:setString(data.param)
    ui.setLabelString(item.num1,data.level,14)
end 
rank.rankconfig.power.setfunc = setpower

local function setgeneral(item,data)
    item.showdata:setString(data.params["3"].i)
    ui.setLabelString(item.num1,data.name,14)
end 
rank.rankconfig.general.setfunc = setgeneral

local function setcopy(item,data)
    item.showdata:setString(gameConfig.strings:copyProcess(data.params["1"].i))
    ui.setLabelString(item.num1,data.level,14)
end 
rank.rankconfig.copy.setfunc = setcopy

local function setwing(item,data)
    item.showdata:setString(gameConfig.strings:wingGrow(data.params["1"].i,data.params["2"].i))
    ui.setLabelString(item.num1,data.level,14)
end 
rank.rankconfig.wing.setfunc = setwing

local function setcover(item,data)
    item.showdata:setString(data.params["1"].i)
    ui.setLabelString(item.num1,data.name,14)
end 
rank.rankconfig.cover.setfunc = setcover

-- local function setrecharge(item,data)
--     item.showdata:setString(data.params["1"].i)
--     ui.setLabelString(item.num1,data.level,14)
-- end 
-- rank.rankconfig.recharge.setfunc = setrecharge

local function setgpower(item,data)
    item.showdata:setString(data.param)
    ui.setLabelString(item.num1,data.level,14)
end 
rank.rankconfig.gpower.setfunc = setgpower

local function setgang(item,data)
    item.showdata:setString(data.level)
    ui.setLabelString(item.num1,data.leadername,14)
end 

--todo
local function setartifact(item,data)
    item.showdata:setString(data.score)
    ui.setLabelString(item.num1,data.name,14)


end 
rank.rankconfig.artifact.setfunc = setartifact
--

function rank.createList(self)
    print("createPowerList")

    local celldict = {}
    local powerListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("rank2/cell_paihangbang2_1", nil, true, "cell_rank_power")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.ListTableView,cellCCB,self.normalCellSize.x/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.rankconfig[self.selectpage].data[tostring(a1+1)] or self.rankconfig[self.selectpage].data[(a1+1)]

            if a1+1 < 4 then
                ccbDocumentControler.istop:setVisible(true)
                ccbDocumentControler.notop:setVisible(false)
                setSpriteFrameByName(ccbDocumentControler.top_bg,"spr_"..(a1+10))
                setSpriteFrameByName(ccbDocumentControler.top_rank,"b_n_zxt_"..(a1+1))
                ccbDocumentControler.rank:setString("")
            else
                ccbDocumentControler.istop:setVisible(false)
                ccbDocumentControler.notop:setVisible(true)
                ccbDocumentControler.rank:setString(a1+1)
            end


            ccbDocumentControler.type2:setString(self.rankconfig[self.selectpage].typename)


            if self.selectpage == "artifact" then
                --
                ui.setLabelString(ccbDocumentControler.type1,"",14)
                ccbDocumentControler.num1:setPositionX(460)

                ccbDocumentControler.vipnode:setVisible(false)

                --ui.setLabelString(ccbDocumentControler.name,gamedata.config.trump[tostring(celldata.artifact.cid)] and gamedata.config.trump[tostring(celldata.artifact.cid)].name or "",14)
                local trumpconfig = gamedata.config.trump[tostring(celldata.artifact.cid)]
                local namestr = trumpconfig.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..trumpconfig.name or trumpconfig.name

                if celldata.artifact.level1 and celldata.artifact.level1 > 0 then
                    namestr = namestr.."+"..celldata.artifact.level1
                end

                ui.setLabelString(ccbDocumentControler.name,namestr,14)

                ui.setNewIcon(ccbDocumentControler,{cid = celldata.artifact.cid,title = celldata.title,iconBox = celldata.iconBox})

                ccbDocumentControler.name:setVisible(true)
                ccbDocumentControler.danweinode:setVisible(false)

                if ccbDocumentControler.duanNode then
                    ui.setWudaoPart(ccbDocumentControler,0)
                end

                if ccbDocumentControler.type3 then
                    ccbDocumentControler.type3:setVisible(true)
                    ccbDocumentControler.type3:setPositionY(50)
                    ccbDocumentControler.num1:setPositionY(90)
                    ccbDocumentControler.type1:setPositionY(90)
                    ui.setLabelString(ccbDocumentControler.type3,(celldata.server or "?").."区："..(celldata.server_name or ""),14)
                end    

                if ccbDocumentControler.i_button then
                    ccbDocumentControler.i_button:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        local newartifact = {
                                    iid = celldata.artifact.id or 0,
                                    cid = celldata.artifact.cid or 0,
                                    name = celldata.artifact.builder_name or "",
                                    attr1 = celldata.artifact.attr1_value or 0,
                                    attr2 = celldata.artifact.attr2_value or 0,
                                    levelHP = math.floor(celldata.artifact.attr3_value or 0),
                                    levelAttack =  math.floor(celldata.artifact.attr4_value or 0),
                                    levelDef =  math.floor(celldata.artifact.attr5_value or 0),
                                    resonanceActiveId1 = celldata.artifact.resonance1_id or 0,
                                    resonanceActiveId2 = celldata.artifact.resonance2_id or 0,
                                    resonanceActiveId3 = celldata.artifact.resonance3_id or 0,
                                    resonanceSkillNum = celldata.artifact.redskill_num or 0,
                                    level1 = celldata.artifact.level1 or 0,
                                    isChecked = celldata.artifact.authenticate or 0,
                                    skill1 = celldata.artifact.skill1_cid or 0,
                                    skill2 = celldata.artifact.skill2_cid or 0,
                                    skill3 = celldata.artifact.skill3_cid or 0,
                                    jewel1 = celldata.artifact.jewel1 or -1,
                                    jewel2 = celldata.artifact.jewel2 or -1,
                                    jewel3 = celldata.artifact.jewel3 or -1,
                                    jewel4 = celldata.artifact.jewel4 or -1,
                                    score = celldata.score or 0,
                        }
                        -- gameWindows:openWindow("artifactInfo",{artifactData = newartifact,isNoJewelGo = true},nil)

                        gameWindows:openWindow("artifactInfoOther",{artifactData = newartifact,isOther = true},nil)

                    end, CCControlEventTouchUpInside)
                    ccbDocumentControler.i_button:setSwallowsTouch(true)
                    ccbDocumentControler.i_button:setTouchPriority(-102)
                end

            else

                if ccbDocumentControler.type3 then
                    ccbDocumentControler.type3:setVisible(false)
                    ccbDocumentControler.type3:setPositionY(-20)
                    ccbDocumentControler.num1:setPositionY(70)
                    ccbDocumentControler.type1:setPositionY(70)
                end    

                if self.selectpage == "general"  then
                    --
                    ui.setLabelString(ccbDocumentControler.type1,"",14)
                    ccbDocumentControler.num1:setPositionX(460)

                    ccbDocumentControler.vipnode:setVisible(false)
                    local generalname = gamedata.config.general[tostring(celldata.params["1"].i)].name
                    ui.setLabelString(ccbDocumentControler.name,generalname or "",14)
                    ui.setNewIcon(ccbDocumentControler,{cid = celldata.params["1"].i,title = celldata.title,iconBox = celldata.iconBox})

                    ccbDocumentControler.name:setVisible(true)
                    ccbDocumentControler.danweinode:setVisible(false)

                    if ccbDocumentControler.duanNode then
                        ui.setWudaoPart(ccbDocumentControler,0)
                    end
                else
                    --
                    ui.setLabelString(ccbDocumentControler.type1,self.rankconfig[self.selectpage].typeext,14)
                    ccbDocumentControler.num1:setPositionX(550)

                    ccbDocumentControler.vipnode:setVisible(false)
                    -- if ccbDocumentControler.vipnode then
                    --     ccbDocumentControler.vipnode:setVisible(gameConfig:checkBuildOpen(154))
                    --     setSpriteFrameByName(ccbDocumentControler.vip,"b_n_vip_"..(celldata.vip or 1))
                    -- end

                    --ui.setLabelString(ccbDocumentControler.name,celldata.name or "",14)
                    ccbDocumentControler.name:setVisible(false)
                    ccbDocumentControler.danweinode:setVisible(true)
                    ui.setWudaoDuanweiRankEffect(ccbDocumentControler,celldata,0,(34/34)*1.2,14)

                    if ccbDocumentControler.duanNode then
                        ui.setWudaoPart(ccbDocumentControler,celldata.part_point or 0)
                    end

                    local profile = (celldata.profile) > 10100 and celldata.profile or 10101
                    ui.setNewIcon(ccbDocumentControler,{cid = profile,title = celldata.title,iconBox = celldata.iconBox})
                end

                if ccbDocumentControler.i_button then
                    if self.selectpage == "general" then
                        celldata.othertype = "togeneral"
                    else
                        celldata.othertype = nil
                    end
                    ccbDocumentControler.i_button:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        if not celldata.rid or GameScene.roleinfo.id == celldata.rid then return end
                        gameWindows:openWindow("chatpop",celldata,nil)
                    end, CCControlEventTouchUpInside)
                    ccbDocumentControler.i_button:setSwallowsTouch(true)
                    ccbDocumentControler.i_button:setTouchPriority(-102)
                end

            end

            self.rankconfig[self.selectpage].setfunc(ccbDocumentControler,celldata)



            if self.ListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rankconfig[self.selectpage].data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = powerListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listNode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


return rank


