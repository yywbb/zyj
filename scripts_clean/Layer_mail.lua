--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/24
-- Time: 下午6:36
-- To change this template use File | Settings | File Templates.
--

local mail = {

    rootNode = nil,
    rootItems = nil,

    listtableview = nil,

    pageconfig = {"system","battle","friend"} ,
    -- pagename = {"系 统","战 斗","玩 家",},
    pagename = {gameConfig.strings:string_common("mail",0),gameConfig.strings:string_common("mail",1),gameConfig.strings:string_common("mail",2),},
    selectpage = "system",

    data = {
        system = {},
        battle = {},
        friend = {}
    },

    -- datastatus = {
    --     system = {isallread = true, id = -1, text = "领取",},
    --     battle = {isallread = true, id = -2, text = "批阅",},
    --     friend = {isallread = true, id = -3, text = "查看",}
    -- },
    datastatus = {
        system = {isallread = true, id = -1, text = gameConfig.strings:string_common("mail",3),},
        battle = {isallread = true, id = -2, text = gameConfig.strings:string_common("mail",4),},
        friend = {isallread = true, id = -3, text = gameConfig.strings:string_common("mail",5),}
    },

    selectStatus = {
        name = "system",
        data = {},
        status = {},
    },
    
    CellSize = {x= 1080,y = 370 },

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {38},
                title2 = {80},
                title3 = {81},
            },
        },
    },
    isscrolltouched = false,
}

function mail.shiftPage(self,type)
    if self.listtableview then
        self.datastatus[self.selectStatus.name].location = self.listtableview:getLuaContentOffsetY()
    else
        self.datastatus[self.selectStatus.name].location = self.rootItems.listScroll:getContentSize().height - table.getTableLength(self.selectStatus.data) * self.CellSize.y
    end

    self.selectStatus.name = type
    self.selectpage = type
    self.selectStatus.data = self.data[self.selectStatus.name]

    -- if self.datastatus[self.selectStatus.name].location and self.datastatus[self.selectStatus.name].height then
    --     local newheight = table.getTableLength(self.selectStatus.data) * self.CellSize.y
    --     self.datastatus[self.selectStatus.name].location = self.datastatus[self.selectStatus.name].location + self.datastatus[self.selectStatus.name].height - newheight
    --     self.datastatus[self.selectStatus.name].height =  newheight
    -- else
        local newheight = table.getTableLength(self.selectStatus.data) * self.CellSize.y
        self.datastatus[self.selectStatus.name].height = newheight
        self.datastatus[self.selectStatus.name].location = self.rootItems.listScroll:getContentSize().height - newheight
    -- end

    self.selectStatus.status = self.datastatus[self.selectStatus.name]
    ui.setLabelString(self.rootItems.mailnum, table.getTableLength(self.selectStatus.data).."/60", 18)

    if not self.selectStatus.status.isallread then
        -- ui.setLabelString(self.rootItems.allbuttontext, "全部"..self.selectStatus.status.text ,18)
        ui.setLabelString(self.rootItems.allbuttontext, gameConfig.strings:complem(self.selectStatus.status.text) ,18)
        self.rootItems.allbutton:addHandleOfControlEvent(function()
            UIRequest({type = 3101, ids = {self.selectStatus.status.id}})
        end, CCControlEventTouchUpInside)
    else
        -- ui.setLabelString(self.rootItems.allbuttontext, "全部删除",18)
        ui.setLabelString(self.rootItems.allbuttontext, gameConfig.strings:string_common("mail",6),18)
        self.rootItems.allbutton:addHandleOfControlEvent(function()
            if table.getTableLength(self.selectStatus.data) >0 then
                -- 邮件全部删除
                local callBack = function()
                    UIRequest({type = 3102, ids = {self.selectStatus.status.id}})
                end
                gameWindows:openWindow("confirm",{msg = "是否删除全部邮件?"}, callBack)
                gamedata.music:PlayOptSound("scyj")
            end
        end, CCControlEventTouchUpInside)
    end

    if self.listtableview then
        self.listtableview:reloadData()
    else
        self:createListview()
    end
    self.listtableview:setLuaContentOffset(0, self.selectStatus.status.location )
end

function mail.init(self,parent,toppos)

    self.rootNode,self.rootItems = CCBReaderLoad("mails/mail", nil, true, "mail")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))
    
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","mail",touchbegin)
    local function touchend(pos)
        if self.rootItems.listScroll and ui.isTouched(self.rootItems.listScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","mail",touchend)
    --self:shiftPage(self.selectStatus.name)
    UIRequest({type =3100})
end

function mail.clear(self)
    gameTouch:UnrigistFunc("begin","mail")
    gameTouch:UnrigistFunc("end","mail")    
    self.isscrolltouched = false    
    self.selectpage = "system"
    self.selectStatus.name = "system"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.listtableview = nil
    self.rootNode = nil
    self.rootItems = nil
end

function mail.setIcon(self,item,config)
    setSpriteFrameByName(item["i_k_quality"], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
    setSpriteFrameByName(item["i_quality"], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
    setSpriteFrameByName(item["i_icon"], config.icon and config.icon or "alpha")
    ui.setSpriteTextureRect(item["i_icon"],0,0,150,150)
end

function mail.setSystemCell(self,item,data)
    --printT(data)
    item.name:setString(data.title)
    self:setIcon(item,{icon = (not next(data.attachment) or data.status == 2) and "box2_2" or "box2_1"})
    if not next(data.attachment) then
        item.rewardnode:setVisible(false)
    else
        item.rewardnode:setVisible(true)
        item.rewards:removeAllChildrenWithCleanup(true)
        local rewars = {}
        for k,v in pairs(data.attachment) do
            local cid = tonumber(k)
            local config = ui.IDconfig(cid)
            print("systemcid===",cid)
            printT(config,"config===")
            if cid >=1000 and cid <=1003 then
                table.insert(rewars,{fontID = 0, content = gameConfig.images["s_icon_"..cid],scale = 0.6})
                table.insert(rewars,{fontID = 151, content = " "..v.."   "})
            elseif cid ==1023 then
                table.insert(rewars,{fontID = 0, content = "wangzhezhizhanpoint",scale = 0.3})
                table.insert(rewars,{fontID = 151, content = " "..v.."   "})
            else
                table.insert(rewars,{fontID = 42, content = config.name..((config.staffType == "general_fragment") and "魂魄" or "")})
                table.insert(rewars,{fontID = 151, content = " "..v.."   "})
            end
        end

        ui.createRichLabel(rewars,item.rewards)

--        local rewars = {}
--        for k,v in pairs(data.attachment) do
--            table.insert(rewars,{cid = tonumber(k), num = v})
--        end
--        local function sortbyid(a,b) return a.cid<b.cid end
--        table.sort(rewars,sortbyid)
--        for i=1,3 do
--            item["reward"..i]:removeAllChildrenWithCleanup(true)
--            if rewars[i] then
--                local prop = ui.IDconfig(rewars[i].cid)
--                if rewars[i].cid >=1000 and rewars[i].cid <=1003 then
--                    local ccb,eitem = CCBReaderLoad("mails/reward_icon.ccbi", nil, true, "reward_icon")
--                    item["reward"..i]:addChild(ccb)
--                    setSpriteFrameByName(eitem.r_icon, gameConfig.images["s_icon_"..rewars[i].cid])
--                    eitem.r_num:setString(rewars[i].num)
--                else
--                    local ccb, eitem = CCBReaderLoad("mails/reward_name.ccbi", nil, true, "reward_name")
--                    item["reward"..i]:addChild(ccb)
--                    eitem.r_name:setString(prop.name)
--                    eitem.r_num:setString(rewars[i].num)
--
--                    eitem.r_num:setPositionX(eitem.r_name:getContentSize().width+20)
--                end
--                if i== #rewars then
--                    self:setIcon(item,prop)
--                end
--            end
--        end
    end

    item.buttonnode1:setVisible(true)
    item.buttonnode2:setVisible(false)

    if not next(data.attachment) or data.status == 2 then
        setControlButtonFrame(item.button1, "b_s_button1", "b_s_button1_h","b_s_button1")
        -- ui.setLabelString(item.buttontext1, "删 除" ,18)
        ui.setLabelString(item.buttontext1, gameConfig.strings:string_common("mail",7) ,18)
        item.button1:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            UIRequest({type = 3102, ids = {data.id}})
            gamedata.music:PlayOptSound("scyj")
        end, CCControlEventTouchUpInside)
    else
        setControlButtonFrame(item.button1, "b_s_button2", "b_s_button2_h","b_s_button2")
        -- ui.setLabelString(item.buttontext1, "领 取" ,18)
        ui.setLabelString(item.buttontext1, gameConfig.strings:string_common("mail",8) ,18)
        item.button1:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            UIRequest({type = 3101, ids = {data.id}, typename = "system"})
        end, CCControlEventTouchUpInside)
    end

    --
    if item.moreButton then
        item.moreButton:setTouchPriority(-101)
        item.moreButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            gameWindows:openWindow("mailmoretext",{text = data.content or ""},nil)
        end, CCControlEventTouchUpInside)
    end

end

function mail.setBattleCell(self,item,data)
    printT(data)

    item.name:setString(data.title)
    item.rewardnode:setVisible(false)

    self:setIcon(item,{icon = gameConfig.images.losesprite})

    item.buttonnode1:setVisible(true)
    item.buttonnode2:setVisible(true)

    setControlButtonFrame(item.button1, "b_s_button1", "b_s_button1_h","b_s_button1")
    -- ui.setLabelString(item.buttontext1, "删 除" ,18)
    ui.setLabelString(item.buttontext1, gameConfig.strings:string_common("mail",7) ,18)
    item.button1:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        UIRequest({type = 3102, ids = {data.id}})
        gamedata.music:PlayOptSound("scyj")
    end, CCControlEventTouchUpInside)

    setControlButtonFrame(item.button2, "b_s_button4", "b_s_button4_h","b_s_button4")
    -- ui.setLabelString(item.buttontext2, "去复仇" ,18)
    ui.setLabelString(item.buttontext2, gameConfig.strings:string_common("mail",9) ,18)
    item.button2:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        UIRequest({type = 1022, rid = data.source.rid})
    end, CCControlEventTouchUpInside)
end

function mail.setFriendCell(self,item,data)
    printT(data)

    item.name:setString(data.source.name)
    item.rewardnode:setVisible(false)

    self:setIcon(item,{icon = ui.IDconfig(data.source.profile)})

    item.buttonnode1:setVisible(true)
    item.buttonnode2:setVisible(true)

    setControlButtonFrame(item.button1, "b_s_button1", "b_s_button1_h","b_s_button1")
    -- ui.setLabelString(item.buttontext1, "删 除" ,18)
    ui.setLabelString(item.buttontext1, gameConfig.strings:string_common("mail",7) ,18)
    item.button1:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        UIRequest({type = 3102, ids = {data.id}})
        gamedata.music:PlayOptSound("scyj")
    end, CCControlEventTouchUpInside)

    setControlButtonFrame(item.button2, "b_s_button2", "b_s_button2_h","b_s_button2")
    -- ui.setLabelString(item.buttontext2, "回 复" ,18)
    ui.setLabelString(item.buttontext2, gameConfig.strings:string_common("mail",10) ,18)
    item.button2:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("useropt",{type = "message"},nil)
    end, CCControlEventTouchUpInside)
end

function mail.createListview(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080,self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("mails/cell_mail.ccbi", nil, true, "cell_mail")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.listtableview,cellCCB,1080/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local data = self.selectStatus.data[tostring(a1+1)]

            ccbDocumentControler.content:setString(data.content)

            ccbDocumentControler.button1:setSwallowsTouch(true)
            ccbDocumentControler.button2:setSwallowsTouch(true)
            ccbDocumentControler.button1:setTouchPriority(-102)
            ccbDocumentControler.button2:setTouchPriority(-102)

            local t = os.date("*t", data.second);
            -- ccbDocumentControler.date:setString(t.month.."月"..t.day.."日")
            ccbDocumentControler.date:setString(gameConfig.strings:MonDay(t.month,t.day))
            local hour = t.hour<10 and "0"..t.hour  or t.hour
            local min = t.min<10 and "0"..t.min  or t.min
            ccbDocumentControler.time:setString(hour..":"..min)

            if data.type == 0 then
                self:setSystemCell(ccbDocumentControler,data)
            elseif data.type == 1 then
                self:setBattleCell(ccbDocumentControler,data)
            elseif data.type == 2 then
                self:setFriendCell(ccbDocumentControler,data)
            end

            if self.listtableview then
                cellCCB:setPosition(1080/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.selectStatus.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listtableview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.listtableview:setTouchPriority(-101)
    self.rootItems.listScroll:addChild(self.listtableview)
end

function mail.reloaddata(self,data)
    self.data = data.mails

    for k,v in ipairs(self.pageconfig) do
        self.datastatus[v].isallread = true
        for k_,v_ in pairs(self.data[v]) do
            if v == "system" then
                 if v_.status ~= 2 then
                     self.datastatus[v].isallread = false
                 end
            else
                if v_.status == 0 then
                    self.datastatus[v].isallread = false
                end
            end
        end
    end

    self:shiftPage(self.selectStatus.name)
end

return mail