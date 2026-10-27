--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/4
-- Time: 上午10:35
-- To change this template use File | Settings | File Templates.
--

local gangmanager = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"ganginfo","member","req"} ,
    -- pagename = {"公会信息","公会成员","审 核"},
    pagename = {gameConfig.strings:string_common("guild_manager",11),gameConfig.strings:string_common("guild_manager",0),gameConfig.strings:string_common("guild_manager",12)},
    selectpage = "ganginfo",

    memberlistView = nil,
    reqlistView = nil,

    gangMembers = {},
    gang2status = {},
    reqlist= {},
    info = {},
    gangpost = {},
    mypost = 0,
    leader = "",

    buttontouch = -103,

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {163},
                title3 = {125},
            },
        },
    },
    isscrolltouched = false,
    selectguildLv = 0,
}

function gangmanager.shiftPage(self,type)
    self.selectpage = type
    if  type == "ganginfo" then
        self.rootItems.infonode:setVisible(true)
        self.rootItems.managlistScroll:setPositionX(9999)
        self.rootItems.reqlistScroll:setPositionX(9999)
        if not next(self.gangMembers) then
            UIRequest({type = 2236})
        end
    elseif type == "member" then
        self.rootItems.infonode:setVisible(false)
        self.rootItems.managlistScroll:setPositionX(0)
        self.rootItems.reqlistScroll:setPositionX(9999)
        if not next(self.gangMembers) then
            UIRequest({type = 2236})
        else
            self:reloadmemberlist()
        end
    elseif type == "req" then
        self.rootItems.infonode:setVisible(false)
        self.rootItems.managlistScroll:setPositionX(9999)
        self.rootItems.reqlistScroll:setPositionX(0)
        if self.mypost == 1 or self.mypost == 2 then
            UIRequest({type = 2234})
        else
            -- runGamePrompt({msg = "只有会长和副会长可处理请求"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_manager",10)})
        end
    end
end

function gangmanager.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui_manager", nil, true, "guild_manager")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if param and param.gang then
        self.gang = param.gang
    end

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.infonode:setPositionY(toppos/2+50)
    self.rootItems.managlistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-370))
    self.rootItems.reqlistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-370))

    self.rootItems.backbutton:setTouchPriority(self.buttontouch)
    self.rootItems.backbutton:setSwallowsTouch(true)
    self.rootItems.backbutton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("gang_main","down")
    end, CCControlEventTouchUpInside)




    --一键招人
    --local guildLv = gamedata.config.build[tostring(28)].level
    local guildLv = 1
    --self.rootItems.guildLvNum:setString(guildLv)
    local beginfunc = function(label)
        label:setString("")
    end

    local endfunc = function(label,text,box)
        if tonumber(text) then
            if tonumber(guildLv) <= tonumber(text) and tonumber(text) <= 120 then
                label:setString(text)
                box:setText("")
                UIRequest({type = 2265,status = self.selectguildLv,guildLv = tonumber(self.rootItems.guildLvNum:getString())})
            else
                runGamePrompt({msg = "请输入大于等于"..guildLv.."小于等于120的数字"})
                label:setString(guildLv)
                box:setText("")
                UIRequest({type = 2265})
            end
        else
            runGamePrompt({msg = "请输入大于等于"..guildLv.."小于等于120的数字"})
            label:setString(guildLv)
            box:setText("")
            UIRequest({type = 2265})
        end
    end

    if not self.accountInputBox then
        self.accountInputBox = ui.creatInputEditBoxBylable(self.rootItems.guildLvNum,kEditBoxInputModeSingleLine,beginfunc,endfunc,
            {
                fontSize = 36,
                fontColor = ccc3(255, 255, 255),
                nochecksensitive = true
            })
        self.accountInputBox:setTouchPriority(self.buttontouch)
    end

    self.rootItems.guildLvButton:setTouchPriority(self.buttontouch)
    self.rootItems.guildLvButton:setSwallowsTouch(true)
    self.rootItems.guildLvButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.selectguildLv == 1 then
            self.selectguildLv = 0
            --self.rootItems.guildlvSpr:setVisible(false)
        else
            self.selectguildLv = 1
            --self.rootItems.guildlvSpr:setVisible(true)
        end
        UIRequest({type = 2265,status = self.selectguildLv,guildLv = tonumber(self.rootItems.guildLvNum:getString())})
    end, CCControlEventTouchUpInside)









    local chuanwei = function(data)

        local cb = function()
            UIRequest({type = 2241,id = data.rid})
        end
        gameWindows:openWindow("guildmsg",{msg = "确定传位给 "..data.name.." ?"},cb)
    end

    local tuichu = function()
        local cb = function()
            UIRequest({type = 2242})
        end
        gameWindows:openWindow("confirm",{msg = "是否退出公会?"},cb)
    end

    local zhenrong = function(data)
        GameScene:addtempLayers("other_slotinfo",data,nil,2)
    end


    local chexiaozhuli = function(data)

        local cb = function()
            UIRequest({type = 2239,opt = 1, id = data.rid})
        end
        gameWindows:openWindow("guildmsg",{msg = "确定撤销 "..data.name.." 副会长职位?"},cb)
    end

    local shengzhuli = function(data)

        local cb = function()
            UIRequest({type = 2239,opt = 0, id = data.rid})
        end
        gameWindows:openWindow("guildmsg",{msg = "确定提升 "..data.name.." 为副会长?"},cb)
    end

    local kaichu = function(data)

        local cb = function()
            UIRequest({type = 2240,id = data.rid})
        end
        gameWindows:openWindow("guildmsg",{msg = "确定将 "..data.name.." 踢出公会?"},cb)
    end

    local jiesan = function(data)
        print("jiesan   ---  ")
        if self.gangMembers and table.getTableLength(self.gangMembers) > 1 then
            --runGamePrompt({msg = "传位后可退出公会"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_manager",14)})
        else
            local cb = function()
                UIRequest({type = 2266})
            end
            gameWindows:openWindow("confirm",{msg = "是否退出公会?"},cb)
        end
    end

    local tanhe = function(data)

        UIRequest({type = 2255})

    end

    -- self.manageConfig = {
    --     ["11"] = {{                              },{name = "解 散",func = tuichu}, },
    --     ["12"] = {{name = "传 位",func = chuanwei},{name = "降 职",func = chexiaozhuli},},
    --     ["10"] = {{name = "升 职",func = shengzhuli},{name = "开 除",func = kaichu},},
    --     ["21"] = {{                              },{name = "查 看",func = zhenrong},},
    --     ["22"] = {{                              },{name = "查 看",func = zhenrong},},
    --     ["20"] = {{name = "查 看",func = zhenrong},{name = "开 除",func = kaichu},},
    --     ["01"] = {{                              },{name = "查 看",func = zhenrong},},
    --     ["02"] = {{                              },{name = "查 看",func = zhenrong},},
    --     ["00"] = {{                              },{name = "查 看",func = zhenrong},},
    --     ["self"]  = {{                              },{name = "退 出",func = tuichu}, },
    -- }
    self.manageConfig = {
        ["11"] = {{                              },{name = gameConfig.strings:string_common("guild_manager",9),func = jiesan}, },
        ["12"] = {{name = gameConfig.strings:string_common("guild_manager",4),func = chuanwei},{name = gameConfig.strings:string_common("guild_manager",5),func = chexiaozhuli},},
        ["10"] = {{name = gameConfig.strings:string_common("guild_manager",6),func = shengzhuli},{name = gameConfig.strings:string_common("guild_manager",7),func = kaichu},},
        ["21"] = {{name = gameConfig.strings:string_common("guild_manager",15),func = tanhe   },{name = gameConfig.strings:string_common("guild_manager",8),func = zhenrong},},
        ["22"] = {{                              },{name = gameConfig.strings:string_common("guild_manager",8),func = zhenrong},},
        ["20"] = {{name = gameConfig.strings:string_common("guild_manager",8),func = zhenrong},{name = gameConfig.strings:string_common("guild_manager",7),func = kaichu},},
        ["01"] = {{name = gameConfig.strings:string_common("guild_manager",15),func = tanhe   },{name = gameConfig.strings:string_common("guild_manager",8),func = zhenrong},},
        ["02"] = {{                              },{name = gameConfig.strings:string_common("guild_manager",8),func = zhenrong},},
        ["00"] = {{                              },{name = gameConfig.strings:string_common("guild_manager",8),func = zhenrong},},
        ["self"]  = {{                              },{name = gameConfig.strings:string_common("guild_manager",9),func = tuichu}, },
    }

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","gangmanager",touchbegin)
    local function touchend(pos)
        if self.rootItems.managlistScroll and ui.isTouched(self.rootItems.managlistScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.reqlistScroll and ui.isTouched(self.rootItems.reqlistScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","gangmanager",touchend)

    self:shiftPage(self.selectpage)
end


function gangmanager.setmemberlistcell(self,ccbDocumentControler,data)

    printT(data,"setmemberlistcell")
    ccbDocumentControler.level:setString(data.level)
    ccbDocumentControler.power:setString(data.power)
    ccbDocumentControler.pointtotal:setString(data.pointtotal)
    ccbDocumentControler.pointtoday:setString(data.pointtoday)

    -- ui.setLabelString(ccbDocumentControler.name,data.name,21)
    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(ccbDocumentControler,data,0,37/34,21)

    --
    --todo
    --part
    if ccbDocumentControler.duanNode then
        ui.setWudaoPart(ccbDocumentControler,data.part_point or 0)
    end
    --
    ccbDocumentControler.i_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if data.rid+0 < 1 then return end
        if data.rid == GameScene.roleinfo.id then return end
        gameWindows:openWindow("chatpop",data,nil)
    end, CCControlEventTouchUpInside)
    ccbDocumentControler.i_button:setSwallowsTouch(true)
    ccbDocumentControler.i_button:setTouchPriority(self.buttontouch)
    --

    ccbDocumentControler.vipnode:setVisible(false)

    -- setSpriteFrameByName(ccbDocumentControler.vip,"b_n_vip_"..data.vip)
    --
    if data.post and data.post == 1 then
        setSpriteFrameByName(ccbDocumentControler.post, "obj_huizhang")
        ui.setNewIcon(ccbDocumentControler,{cid = data.profile,title = data.title,iconBox = data.iconBox})
    elseif data.post and data.post == 2 then
        setSpriteFrameByName(ccbDocumentControler.post, "obj_fuhuizhang")
        ui.setNewIcon(ccbDocumentControler,{cid = data.profile,title = data.title,iconBox = data.iconBox})
    else
        setSpriteFrameByName(ccbDocumentControler.post, "alpha")
        -- ccbDocumentControler.vipnode:setVisible(false)
        ui.setNewIcon(ccbDocumentControler,{cid = data.profile,title = data.title,iconBox = data.iconBox})
    end

    if data.secs == 0 then
        ccbDocumentControler.login:setVisible(false)
        ccbDocumentControler.islogin:setVisible(true)
    elseif data.secs == -1 then
        -- ccbDocumentControler.login:setString("很久未上线")
        ccbDocumentControler.login:setString(gameConfig.strings:string_common("guild_manager",16))
        ccbDocumentControler.login:setVisible(true)
        ccbDocumentControler.islogin:setVisible(false)
    else
        ccbDocumentControler.login:setString(ui.makeTimeDes1(math.abs(data.secs)))
        -- ccbDocumentControler.login:setString(gameConfig.strings:lvTm(ui.makeTimeDes1(math.abs(data.secs))))
        ccbDocumentControler.login:setVisible(true)
        ccbDocumentControler.islogin:setVisible(false)
    end

    local buttonconfig = {}
    --
    if GameScene.roleinfo.id == data.rid then
        if self.mypost == 1 and data.post == 1  then
            --if table.getTableLength(self.gangMembers) <= 1 then
            --    buttonconfig = self.manageConfig["self"]
            --else
                buttonconfig = self.manageConfig["11"]
            --end
        else
            buttonconfig = self.manageConfig["self"]
        end
    else
        buttonconfig = self.manageConfig[self.mypost..(data.post or 0)]
    end

    for i=1, 2 do
        if next(buttonconfig[i]) then
            ccbDocumentControler["buttonnode"..i]:setVisible(true)
            ccbDocumentControler["button"..i]:setTouchPriority(self.buttontouch)
            ui.setLabelString(ccbDocumentControler["buttontext"..i],buttonconfig[i].name,19)
            ccbDocumentControler["button"..i]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                buttonconfig[i].func(data,self)
            end, CCControlEventTouchUpInside)
        else
            ccbDocumentControler["buttonnode"..i]:setVisible(false)
        end
    end

end


function gangmanager.creatememberlistView(self)
    local celldict = {}
    local unrecycleCell = {cell = {}}
    local memberListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 290)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_gonghui_chengyuaninfo", nil, true, "cell_member")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setmemberlistcell(ccbDocumentControler,self.gangMembers[(a1+1)])

            cellCCB:setPosition(1080/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.gangMembers)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.memberlistView = ui.createLuaTableView({
        handle = memberListHandle,
        viewwidth = self.rootItems.managlistScroll:getContentSize().width,
        viewheight = self.rootItems.managlistScroll:getContentSize().height,
        dire = 1
    })
    self.memberlistView:setTouchPriority(-102)
    self.rootItems.managlistScroll:addChild(self.memberlistView)
end


function gangmanager.reloadlimitLv(self,data)
    printT(data,"reloadlimitLv  ---")
    if not data then
        return
    end
    self.selectguildLv = data.gangstatus
    self.limitGuildLv = data.ganglimitLv
    self.rootItems.guildLvNum:setString(self.limitGuildLv)

    if self.selectguildLv == 1 then
        self.rootItems.guildlvSpr:setVisible(true)
    else
        self.rootItems.guildlvSpr:setVisible(false)
    end

end


function gangmanager.setreqlistcell(self,ccbDocumentControler,data)
    -- ui.setLabelString(ccbDocumentControler.name,data.name,21)

    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(ccbDocumentControler,data,0,37/34,21)


    ccbDocumentControler.level:setString(data.level)
    ccbDocumentControler.power:setString(data.param)

    --todo
    --part
    if ccbDocumentControler.duanNode then
        ui.setWudaoPart(ccbDocumentControler,data.part_point or 0)
    end

    ccbDocumentControler.vipnode:setVisible(gameConfig:checkBuildOpen(154))
    setSpriteFrameByName(ccbDocumentControler.vip, "b_n_vip_"..(data.vip or 0))

    -- ui.setLabelString(ccbDocumentControler.accepttext,"同 意",19)
    ui.setLabelString(ccbDocumentControler.accepttext,gameConfig.strings:string_common("moreCommon","tongyi"),19)
    ccbDocumentControler.accept:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if self.gang and (self.mypost == 1 or self.mypost == 2) then
            UIRequest({type = 2235, id = data.rid, opt =0})
        else
            -- runGamePrompt({msg = "只有会长和副会长可处理请求"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_manager",10)})
        end
    end, CCControlEventTouchUpInside)
    ccbDocumentControler.accept:setSwallowsTouch(true)
    ccbDocumentControler.accept:setTouchPriority(self.buttontouch)

    ui.setLabelString(ccbDocumentControler.refusetext,nil,19)
    ccbDocumentControler.refuse:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if self.gang and (self.mypost == 1 or self.mypost == 2) then
            UIRequest({type = 2235, id = data.rid, opt =1})
        else
            -- runGamePrompt({msg = "只有会长和副会长可处理请求"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_manager",10)})
        end
    end, CCControlEventTouchUpInside)
    ccbDocumentControler.refuse:setSwallowsTouch(true)
    ccbDocumentControler.refuse:setTouchPriority(self.buttontouch)
end

function gangmanager.createreqlistView(self)
    local celldict = {}
    local unrecycleCell = {cell = {}}
    local reqListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 220)
        elseif fn == "isRecycle" then
            if a2 == unrecycleCell.cell.cell then
                print("unrecycleCELL ")
                return false
            end
            return true
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_gonghui_chengyuanshenqing", nil, true, "cell_req")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setreqlistcell(ccbDocumentControler,self.reqlist[tostring(a1+1)])

            cellCCB:setPosition(1080/2, 10)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.reqlist)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.reqlistView = ui.createLuaTableView({
        handle = reqListHandle,
        viewwidth = self.rootItems.reqlistScroll:getContentSize().width,
        viewheight = self.rootItems.reqlistScroll:getContentSize().height,
        dire = 1
    })
    self.reqlistView:setTouchPriority(-102)
    self.rootItems.reqlistScroll:addChild(self.reqlistView)
end

function gangmanager.reloadmemberlist(self,data)
    if data then
        self.mypost = 0
        self.leader = ""
        self.gang2status = data.gang2status or {}
        self.gangMembers = {}

        local showTable1 = {}
        local showTable2 = {}
        for k,v in pairs(data.gangmembers or {}) do
            v.post = 0
            v.order = 0
            v.order2 = 0
            if v.rid == data.gang2post.post1 then
                v.post = 1
                v.order = 2
                self.leader = v.name
                if v.rid == GameScene.roleinfo.id then self.mypost = 1 end
                table.insert(self.gangMembers,v)
            elseif v.rid == data.gang2post.post2_1 or v.rid == data.gang2post.post2_2 or v.rid == data.gang2post.post2_3 then
                v.post = 2
                v.order = 1
                if v.rid == GameScene.roleinfo.id then self.mypost = 2 end
                table.insert(showTable1,v)
            else
                table.insert(showTable2,v)
            end
        end
        self:sortData(showTable1,"secs","pointtotal","level")
        self:sortData(showTable2,"secs","pointtotal","level")
        for k,v in ipairs(showTable1) do
            if v.secs >= 0 then
                table.insert(self.gangMembers,v)
            end
        end
        for k,v in ipairs(showTable1) do
            if v.secs < 0 then
                table.insert(self.gangMembers,v)
            end
        end

        for k,v in ipairs(showTable2) do
            if v.secs >= 0 then
                table.insert(self.gangMembers,v)
            end
        end
        for k,v in ipairs(showTable2) do
            if v.secs < 0 then
                table.insert(self.gangMembers,v)
            end
        end
    end
    if self.memberlistView then
        self.memberlistView:setLuaContentOffset(0, self.rootItems.managlistScroll:getContentSize().height - table.getTableLength(self.gangMembers)*290)
        self.memberlistView:reloadData()
    else
        self:creatememberlistView()
    end
    --

    if self.mypost == 1 or self.mypost == 2 then
        self.rootItems.buttonnode3:setVisible(true)
    else
        self.rootItems.buttonnode3:setVisible(false)
    end
    --
    self:setganginfo()
end

function gangmanager.sortData(self,data, parm1, parm2, parm3)
    local sortfunc = function (a,b)
        if parm1 == nil then return false end
        if a[parm1] < b[parm1] then
            return true
        elseif a[parm1] > b[parm1] then
            return false
        elseif a[parm1] == b[parm1] then
            if parm2 == nil then return false end
            if a[parm2] > b[parm2] then
                return true
            elseif a[parm2] < b[parm2] then
                return false
            elseif a[parm2] == b[parm2] then
                if parm3 == nil then return false end
                return a[parm3] > b[parm3]
            end
        end
    end

    table.sort(data,sortfunc)
end


function gangmanager.reloadreqlist(self,data)
    if data then
        self.reqlist = data
    end
    if self.reqlistView then
        self.reqlistView:setLuaContentOffset(0, self.rootItems.reqlistScroll:getContentSize().height - table.getTableLength(self.reqlist)*220)
        self.reqlistView:reloadData()
    else
        self:createreqlistView()
    end
end

function gangmanager.setganginfo(self,data)
    self.rootItems.gang_name:setString(self.gang2status.name or "")
    self.rootItems.gang_leader:setString(self.leader or "")
    self.rootItems.gang_power:setString(self.gang2status.power or "")
    self.rootItems.gang_num:setString(self.gang2status.num or "")
    self.rootItems.gang_level:setString(self.gang2status.level or "")
    self.rootItems.gang_exp:setString(self.gang2status.exp or "")
    self.rootItems.gang_content:setString(self.gang2status.content or "")
    self.rootItems.gang_declaration:setString(self.gang2status.declaration or "")
    --
    self.rootItems.gang_num:setString(self.gang2status.num.." / "..(gamedata.config.gang2_level[tostring(self.gang2status.level)] and gamedata.config.gang2_level[tostring(self.gang2status.level)].people or "?"))
    ui.setLabelString(self.rootItems.gang_exp,self.gang2status.exp.." / "..gamedata.config.gang2_level[tostring(self.gang2status.level)].gang_exp,13)
    ui.setSpriteTextureRect2(self.rootItems.gang_exppos,0,0,280*(self.gang2status.exp < gamedata.config.gang2_level[tostring(self.gang2status.level)].gang_exp and self.gang2status.exp/gamedata.config.gang2_level[tostring(self.gang2status.level)].gang_exp or 1),36)
    --
    if self.mypost == 1 or self.mypost == 2 then
        self.rootItems.changeNameNode:setVisible(true)
        self.rootItems.changeContentNode:setVisible(true)
        self.rootItems.changeDeclarationNode:setVisible(true)
        if self.rootItems.guildLvNode then
            self.rootItems.guildLvNode:setVisible(true)
        end    
    else
        self.rootItems.changeNameNode:setVisible(false)
        self.rootItems.changeContentNode:setVisible(false)
        self.rootItems.changeDeclarationNode:setVisible(false)
        if self.rootItems.guildLvNode then
            self.rootItems.guildLvNode:setVisible(false)
        end    
    end
    --
    self.rootItems.changeName:addHandleOfControlEvent(function()
        if self.gang2status and (self.mypost == 1 or self.mypost == 2) then
            gameWindows:openWindow("guildsetname",nil)
        else
            -- runGamePrompt({msg = "只有会长和副会长可修改"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_manager",17)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.changeName:setSwallowsTouch(true)
    self.rootItems.changeName:setTouchPriority(self.buttontouch)
    --
    self.rootItems.changeContent:addHandleOfControlEvent(function()
        if self.gang2status and (self.mypost == 1 or self.mypost == 2) then
            gameWindows:openWindow("guildsetnotice",1)
        else
            -- runGamePrompt({msg = "只有会长和副会长可修改公告"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_manager",18)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.changeContent:setSwallowsTouch(true)
    self.rootItems.changeContent:setTouchPriority(self.buttontouch)
    --
    self.rootItems.changeDeclaration:addHandleOfControlEvent(function()
        if self.gang2status and (self.mypost == 1 or self.mypost == 2) then
            gameWindows:openWindow("guildsetnotice",2)
        else
            -- runGamePrompt({msg = "只有会长和副会长可修改宣言"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_manager",19)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.changeDeclaration:setSwallowsTouch(true)
    self.rootItems.changeDeclaration:setTouchPriority(self.buttontouch)


    --
    self.rootItems.rewardview:addHandleOfControlEvent(function()
        gameWindows:openWindow("guildrewardview",nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.rewardview:setSwallowsTouch(true)
    self.rootItems.rewardview:setTouchPriority(self.buttontouch)
    --

    ui.setLabelString(self.rootItems.rewardLab,nil,19)

    if self.gang2status.rewardstatus and self.gang2status.rewardstatus == 0 then
        ui.removeGray("CCControlButton",self.rootItems.rewardButton)
        ui.removeGray("CCLabelTTF",self.rootItems.rewardLab)
        self.rootItems.rewardButton:addHandleOfControlEvent(function()
            UIRequest({type = 2260})
        end, CCControlEventTouchUpInside)
        self.rootItems.rewardButton:setSwallowsTouch(true)
        self.rootItems.rewardButton:setTouchPriority(self.buttontouch)
    else
        ui.addGray("CCControlButton",self.rootItems.rewardButton)
        ui.addGray("CCLabelTTF",self.rootItems.rewardLab)
        self.rootItems.rewardButton:addHandleOfControlEvent(function()
            -- runGamePrompt({msg = "今日已领取过"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_manager",20)})
        end, CCControlEventTouchUpInside)
        self.rootItems.rewardButton:setSwallowsTouch(true)
        self.rootItems.rewardButton:setTouchPriority(self.buttontouch)
    end
end


function gangmanager.clear(self)
    gameTouch:UnrigistFunc("begin","gangmanager")
    gameTouch:UnrigistFunc("end","gangmanager")
    self.isscrolltouched = false    
    self.leader = ""
    self.gang2status = {}
    self.mypost = 0
    self.show = false
    self.reqlist = {}
    self.gangMembers = {}
    self.gangpost = {}
    self.memberlistView = nil
    self.reqlistView=nil
    self.selectpage = "ganginfo"
    ui.removeInputEditBox(self.accountInputBox)
    self.accountInputBox = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.selectguildLv = 0
end

return gangmanager