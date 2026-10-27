--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local guildlist = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    ganglisttableview = nil,
    ganglist = {},
    buttontouch = -103,

    pageconfig = {"list",} ,
    -- pagename = {"公会列表",},
    pagename = {gameConfig.strings:string_common("guild_list",0),},
    selectpage = "list",

    gangsearch = {},

    gangshow = {},

    opentype = 0,
    iscd = 0,
    isscrolltouched = false,
}

function guildlist.shiftPage(self,type)

    local relocated = self.selectpage ~= type
    self.selectpage = type
    self.gangshow = self["gang"..type]

    if self.ganglisttableview then
        if relocated then
            self.ganglisttableview:setLuaContentOffset(0, self.rootItems.listscroll:getContentSize().height - table.getTableLength(self.gangshow)*250)
        end
        self.ganglisttableview:reloadData()
    else
        self:createganglisttableview()
    end

end

function guildlist.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui", nil, true, "gonghui")
    parent:addChild(self.rootNode)

    self.opentype = param and param.opt or 0

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.listscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-590))
    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-590))


    self.rootItems.backbutton:setTouchPriority(self.buttontouch)
    self.rootItems.backbutton:setSwallowsTouch(true)
    self.rootItems.backbutton:addHandleOfControlEvent(function()
        print("back")
        if self.selectpage == "search" then
            self:shiftPage("list")
        elseif self.opentype == 2 then
            UIRequest({type = 2230,param = "main"})
        else
            GameScene:shiftLayer("main","down")
        end

    end, CCControlEventTouchUpInside)


    if self.opentype == 2 then
        self.rootItems.createbutton:setVisible(false)
        self.rootItems.timenode:setVisible(false)
    end

    self.rootItems.createbutton:setTouchPriority(self.buttontouch)
    self.rootItems.createbutton:setSwallowsTouch(true)
    self.rootItems.createbutton:addHandleOfControlEvent(function()
        print("create")

        if GameScene.roleinfo.level < (gamedata.config.global_kv and tonumber(gamedata.config.global_kv.gang_establish_level.value) or 0) then
            -- runGamePrompt({msg = "等级到达"..tonumber(gamedata.config.global_kv.gang_establish_level.value).."级以上才可创建公会"})
            runGamePrompt({msg = gameConfig.strings:lvgetGuild(gamedata.config.global_kv.gang_establish_level.value)})
        elseif self.iscd and self.iscd == 1 then
            -- runGamePrompt({msg = "退出公会"..ui.makeTimeText2(math.abs(tonumber(gamedata.config.global_kv.gang_quit_limit.value) or 0)).."后才可创建公会"})
            runGamePrompt({msg = gameConfig.strings:quitGuild(ui.makeTimeText2(math.abs(tonumber(gamedata.config.global_kv.gang_quit_limit.value) or 0)))})
        else
            gameWindows:openWindow("guildnew",nil)
        end
    end, CCControlEventTouchUpInside)

    if self.rootItems.guildreqLab and self.rootItems.guildreqBtn then
        ui.setLabelString(self.rootItems.guildreqLab,nil,18)
        self.rootItems.guildreqBtn:setTouchPriority(self.buttontouch)
        self.rootItems.guildreqBtn:setSwallowsTouch(true)
        self.rootItems.guildreqBtn:addHandleOfControlEvent(function()
            print("guildreqBtn")
            gameTouch:clickprofbytime(1)
            if self.iscd and self.iscd == 1 then
                runGamePrompt({msg = gameConfig.strings:addGuild(ui.makeTimeText2(math.abs(tonumber(gamedata.config.global_kv.gang_quit_limit.value) or 0)))})
            else
                UIRequest({type = 2233})
            end
        end, CCControlEventTouchUpInside)
    end

    local inputcontent = ""
    local beginFunc = function()
        inputcontent = ""
    end

    local endFunc = function(text)
        inputcontent = text
    end

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 32,
            -- PlaceHolder = "点击输入公会名字",
            PlaceHolder = gameConfig.strings:string_common("guild_list",1),
            length = 12,
            fontColor = ccc3(255,255,255),
            PlaceholderFontColor = ccc3(200,200,200),
        })
    self.input:setTouchPriority(-102)

    ui.setLabelString(self.rootItems.searchLab,nil,18)
    self.rootItems.searchbutton:addHandleOfControlEvent(function()
        if inputcontent == "" then
            -- runGamePrompt({msg = "输入公会名字"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_list",2)})
        else
            UIRequest({type = 2243, name = inputcontent})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.searchbutton:setSwallowsTouch(true)
    self.rootItems.searchbutton:setTouchPriority(-102)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","guildlist",touchbegin)
    local function touchend(pos)
        if self.rootItems.listscroll and ui.isTouched(self.rootItems.listscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","guildlist",touchend)

    UIRequest({type = 2232})
end

function guildlist.setganglistcell(self,items,data)
    print("setcell")

    items.power:setString(data.power)
    items.president:setString(data.leadername)
    items.membersnum:setString(data.num.."/"..(gamedata.config.gang2_level[tostring(data.level)] and gamedata.config.gang2_level[tostring(data.level)].people or "?"))
    items.desc:setString(data.declaration)

    -- ui.setLabelString(items.name, data.name,21)

    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(items,data,0,37/34,21)


    ui.setLabelString(items.level, data.level,14)

    if self.opentype == 2 then
        items.buttonnode:setVisible(false)
        items.reqnode:setVisible(false)
    else

        -- ui.setLabelString(items.buttonLab, "申 请",19)
        ui.setLabelString(items.cancelText, "取消申请",19)
        ui.setLabelString(items.buttonLab, gameConfig.strings:string_common("moreCommon","shenqing"),19)
        items["button"]:setTouchPriority(-2)
        items["button"]:setSwallowsTouch(true)
        items["cancelBtn"]:setTouchPriority(-2)
        items["cancelBtn"]:setSwallowsTouch(true)
        if data.param == 1 then
            items.buttonnode:setVisible(false)
            items.reqnode:setVisible(true)
            items["cancelBtn"]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                -- 取消申请
                UIRequest({type = 2267, id = data.id})
            end, CCControlEventTouchUpInside)
        else
            items.buttonnode:setVisible(true)
            items.reqnode:setVisible(false)
            items["button"]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                if self.iscd and self.iscd == 1 then
                    -- runGamePrompt({msg = "退出公会"..ui.makeTimeText2(math.abs(tonumber(gamedata.config.global_kv.gang_quit_limit.value) or 0)).."后才可加入新公会"})
                    runGamePrompt({msg = gameConfig.strings:addGuild(ui.makeTimeText2(math.abs(tonumber(gamedata.config.global_kv.gang_quit_limit.value) or 0)))})
                elseif data.num >= gamedata.config.gang2_level[tostring(data.level)].people then
                    -- runGamePrompt({msg = "人数已满，无法加入"})
                    runGamePrompt({msg = gameConfig.strings:string_common("guild_list",5)})
                else
                    UIRequest({type = 2233, id = data.id})
                end
            end, CCControlEventTouchUpInside)
        end

    end
end


function guildlist.createganglisttableview(self,data)
    local celldict = {}
    local unrecycleCell = {cell = {}}
    local gangListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 250)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_gonghui_shenqing", nil, true, "cell_shenqing")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setganglistcell(ccbDocumentControler,self.gangshow[tostring(a1+1)])

            cellCCB:setPosition(1080/2, 0)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.gangshow)

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ganglisttableview = ui.createLuaTableView({
        handle = gangListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.ganglisttableview:setTouchPriority(-1)
    self.rootItems.listscroll:addChild(self.ganglisttableview)
end

function guildlist.reloaddata(self,data)
    self.ganglist = data.gangs or {}
    self.gang2CDstatus = data.gang2CDstatus or {}
    --
    self.iscd = 0
    local ntime = 0
    if self.gang2CDstatus.type and self.gang2CDstatus.type == 2 then
        ntime = gamedata:time() - self.gang2CDstatus.time
        if ntime < (tonumber(gamedata.config.global_kv.gang_quit_limit.value) or 0) then
            self.iscd = 1
        end
    end
    --
    if self.iscd == 1 then
        if ((tonumber(gamedata.config.global_kv.gang_quit_limit.value) or 0)-ntime) > 0 then
            gameTimer:rigistTime("gangQuitLimit",(tonumber(gamedata.config.global_kv.gang_quit_limit.value) or 0)-ntime)
        end

        if gameTimer.times["gangQuitLimit"] and gameTimer.times["gangQuitLimit"] > 0 then
            self.rootItems.timenode:setVisible(true)
            ui.setLabelString(self.rootItems.timeLab,nil,26)
            gameTimer:rigistTimeFunc("gangQuitLimit",function()
                if gameTimer.times["gangQuitLimit"] > 0 then
                    ui.setLabelString(self.rootItems.time,ui.makeTimeText(gameTimer.times["gangQuitLimit"]),26)
                else
                    self.iscd = 0
                    self.rootItems.timenode:setVisible(false)
                end
            end)
        else
            self.iscd = 0
            self.rootItems.timenode:setVisible(false)
        end
    else
        self.rootItems.timenode:setVisible(false)
    end
    --
    self:shiftPage("list")
end

function guildlist.searchResult(self,data)
    if next(data) then
        self.gangsearch = data
        self:shiftPage("search")
    else
        -- runGamePrompt({msg = "查无此公会！"})
        runGamePrompt({msg = gameConfig.strings:string_common("guild_list",3)})
    end
end

function guildlist.reqResult(self,t)
    for k,v in pairs(self.ganglist) do
        if t.id and t.id ~= 0 then
            if v.id == t.id then
                v.param = 1
            end
        else
            for kk,vv in pairs(t.idTable) do
                if v.id == vv then
                    v.param = 1
                end
            end
        end
    end

    for k,v in pairs(self.gangsearch) do
        if t.id and t.id ~= 0 then
            if v.id == t.id then
                v.param = 1
            end
        else
            for kk,vv in pairs(t.idTable) do
                if v.id == vv then
                    v.param = 1
                end
            end
        end
    end
    self:shiftPage(self.selectpage)
end

function guildlist.clear(self)
    gameTouch:UnrigistFunc("begin","guildlist")
    gameTouch:UnrigistFunc("end","guildlist")    
    self.isscrolltouched = false    
    if gameTimer.times["gangQuitLimit"] then
        gameTimer:UnrigistTimeFunc("gangQuitLimit")
    end
    self.iscd = 0
    self.opentype = 0
    self.selectpage = "list"
    self.ganglist = {}
    self.gangsearch={}
    self.ganglisttableview = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return guildlist 3  