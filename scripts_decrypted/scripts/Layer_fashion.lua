--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local fashion = {

    resource = nil,

    titleCellSize = {x=180,y=180},
    fashionListTableView = nil,

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"fashion","up"},
    pagename = {"时 装","强 化"},

    selectpage = "fashion",
    fashionindex = 1,
    fashions = {},
    protagonist = {},
    fashiondata = {},
    roleid = 10101,
    up_needprops = {},
    up_needcoin = 0,

    firstshow = true,
}

function fashion.shiftPage(self,type)

    self.selectpage = type
    if self.selectpage == "up" then
        self.rootItems.backButton:setVisible(true)
        self:setPage_up()
    else
        self.rootItems.backButton:setVisible(false)
        self:setPage_fashion()
    end

end

function fashion.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shizhuang/shizhuang", nil, true, "fashion")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    local fixh = (toppos-1540)/2
    self.rootItems.page_fashion:setPositionY(fixh)

    if  self.rootItems.previewNode then
        self.rootItems.previewNode:setPositionY(toppos-(1920-1400))
    end
    ----
    self.rootItems.backButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        self:shiftPage("fashion")
    end, CCControlEventTouchUpInside)
    self.rootItems.backButton:setSwallowsTouch(true)
    self.rootItems.backButton:setTouchPriority(-103)
    ----

    if param and param.page then
        self.selectpage = param.page
    end

    --
    UIRequest({type = 1070})

end

function fashion.clear(self)
    for k,v in ipairs(self.fashions) do
        if gameTimer.times["fashionbacktimer"..v.cover_id] then
            gameTimer:UnrigistTimeFunc("fashionbacktimer"..v.cover_id)
        end
    end
    gameTimer:UnrigistTimeFunc("fashionbacktimer")
    self.up_needprops = {}
    self.up_needcoin = 0
    self.fashionindex = 1
    self.fashions = {}
    self.protagonist = {}
    self.fashiondata = {}
    self.selectpage = "fashion"
    self.fashionListTableView = nil
    self.firstshow = true
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end


----------------------------------------------------------------------------
function fashion.reloadFashionList(self,alldata)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon.ccbi", nil, true, "generalIcon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }

                ui.tableviewAnimationH(self.fashionListTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setScale(0.9)

            ccbDocumentControler.i_selectEffect:removeAllChildrenWithCleanup(true)
            ui.setNewIcon(ccbDocumentControler,{cid = self.fashions[a1+1].coat_id})

            if self.fashions[a1+1].cover_id == self.fashiondata.fashionid then
                ccbDocumentControler.i_isonNode:setVisible(true)
                ui.setLabelString(ccbDocumentControler["i_isonLab"],nil,13)
            else
                ccbDocumentControler.i_isonNode:setVisible(false)
            end

            if self.fashiondata.fashions[tostring(self.fashions[a1+1].cover_id)] then
                ui.removeGray("CCSprite",ccbDocumentControler.i_icon)
                ui.removeGray("CCSprite",ccbDocumentControler.i_k_quality)
                ui.removeGray("CCSprite",ccbDocumentControler.i_quality)
                ccbDocumentControler["i_num"]:setVisible(true)
                ui.setLabelString(ccbDocumentControler["i_num"], "等级." .. (self.fashiondata.fashions[tostring(self.fashions[a1+1].cover_id)] and self.fashiondata.fashions[tostring(self.fashions[a1+1].cover_id)].level or 1), 13)
            else
                ui.addGray("CCSprite",ccbDocumentControler.i_icon)
                ui.addGray("CCSprite",ccbDocumentControler.i_k_quality)
                ui.addGray("CCSprite",ccbDocumentControler.i_quality)
                ccbDocumentControler["i_num"]:setVisible(false)
            end

            if self.fashionindex == a1+1 then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                eccb:setScale(1.1)
                ccbDocumentControler.i_selectEffect:addChild(eccb)
            end


            if self.fashionListTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.fashions)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)

            if a1:getIdx()+1<= table.getTableLength(self.fashions) then
                self:setFashionIndex(a1:getIdx()+1,true)
            else

            end

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.fashionListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.listscroll:addChild(self.fashionListTableView)
    self.fashionListTableView:setTouchPriority(-102)
    --
    if self.fashionindex > 5 then
        self.fashionListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.fashionindex-5) ,0),0.2)
    end
end

----------------------------------------------------------------------------
function fashion.setFashionIndex(self,index)
    self.fashionindex = index
    self:shiftPage(self.selectpage)
    self.fashionListTableView:reloadData()
end


function fashion.ReloadData(self,data)

    local levelchange = false

    if data then
        if self.fashiondata and self.fashiondata.fashions and data.fashion and data.fashion.fashions then
            for k,v in pairs(self.fashiondata.fashions) do
                if data.fashion.fashions[tostring(v.id)] and data.fashion.fashions[tostring(v.id)].level > v.level then
                    levelchange = true
                end
            end
        end
        --
        self.protagonist = data.protagonist or {}
        self.fashiondata = data.fashion or {}
        --
        local fashionconfig = gamedata.config.fashioncoat or {}
        if self.protagonist and self.protagonist.general and self.protagonist.general.cid and self.protagonist.general.cid > 0 then
            if (self.protagonist.general.cid >= 10101 and self.protagonist.general.cid <= 10115) or (self.protagonist.general.cid >= 10997 and self.protagonist.general.cid <= 10999) or (self.protagonist.general.cid >= 162001 and self.protagonist.general.cid <= 162003) then
                self.roleid = self.protagonist.general.cid
            else
                for k,v in pairs(fashionconfig) do
                    for k1,v1 in pairs(v) do
                        if v1.coat_id == self.protagonist.general.cid then
                            self.roleid = v1.role_id
                        end
                    end
                end
            end
        end
        self.fashions = {}
        for k,v in pairs(fashionconfig) do
            if v[tostring(self.roleid)] then
                table.insert(self.fashions,v[tostring(self.roleid)])
            end
        end
        local sortfunc = function (a,b)
            if self.fashiondata.fashions[tostring(a.cover_id)] and not self.fashiondata.fashions[tostring(b.cover_id)] then
                return true
            elseif self.fashiondata.fashions[tostring(b.cover_id)] and not self.fashiondata.fashions[tostring(a.cover_id)] then
                return false
            else
                return a.cover_id < b.cover_id
            end
        end
        table.sort(self.fashions,sortfunc)

    end
    --
    if self.firstshow then
        self.firstshow = false
        if self.fashions and self.fashiondata then
            for k,v in ipairs(self.fashions) do
                if self.fashiondata.fashionid and self.fashiondata.fashionid == v.cover_id then
                    self.fashionindex = k
                end
            end
        end
    end
    --
    if not self.fashionListTableView then
        self:reloadFashionList()
    else
        self.fashionListTableView:reloadData()
    end

    if levelchange then
        local effectccb,effectitem = CCBReaderLoad("UIEffect/renwushengji/renwushengji", nil, true, "renwushengji")
        self.rootItems.effectnode_top:removeAllChildrenWithCleanup(true)
        self.rootItems.effectnode_top:addChild(effectccb)
        --
        self.rootItems.effectnode_top:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.8),CCCallFunc:create(function()
            self:shiftPage(self.selectpage)
        end)))
    else
        self:shiftPage(self.selectpage)
    end

    self:updatatime()
    self:updatatime2()
end

function fashion.setGeneralNode(self)
    if not self.fashions[self.fashionindex] then return end
    --
    ui.setLabelString(self.rootItems.generalname,self.fashions[self.fashionindex].name,1)
    --
    if self.fashions[self.fashionindex].coat_id and self.fashions[self.fashionindex].coat_id > 0 then
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.fashions[self.fashionindex].coat_id)].animationid)].name
        local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        general:setPosition(0,0)
        self.rootItems.general:removeAllChildrenWithCleanup(true)
        self.rootItems.general:addChild(general)
    end
    --

end

function fashion.setPage_fashion(self)
    self.rootItems.page_fashion:setVisible(true)
    self.rootItems.page_up:setVisible(false)
    --
    self:setGeneralNode()
    --
    local generalconfig = gamedata.config.general[tostring(self.fashions[self.fashionindex].coat_id)] or {}
    ui.setSkillIcon({status = 2, cid = generalconfig.skillid },self.rootItems)
    ui.setSkillIcon({status = 2, cid = generalconfig.combskillid > 0 and generalconfig.combskillid or generalconfig.combskillid2 },self.rootItems,1)

    local generaldata = {}
    generaldata.general = {}
    generaldata.general.cid = self.fashions[self.fashionindex].coat_id
    generaldata.general.skill = {}
    generaldata.general.skill.cid = generalconfig.skillid
    generaldata.general.combskill = {}
    generaldata.general.combskill.cid = generalconfig.combskillid > 0 and generalconfig.combskillid or generalconfig.combskillid2
    if generaldata.general.skill.cid and  generaldata.general.skill.cid > 0 then
        self.rootItems.skill1:setVisible(true)
    else
        self.rootItems.skill1:setVisible(false)
    end

    if generaldata.general.combskill.cid and  generaldata.general.combskill.cid > 0 then
        self.rootItems.skill2:setVisible(true)
    else
        self.rootItems.skill2:setVisible(false)
    end

    --
    self.rootItems.skillButton1:addHandleOfControlEvent(function()
        if generaldata.general.skill.cid and  generaldata.general.skill.cid > 0 then
            gameWindows:openWindow("generalInfoSkill",{data = generaldata, sid = 1, islead = 1, pagetype = "skillinfo", skilltype = "skill"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.skillButton1:setSwallowsTouch(true)
    self.rootItems.skillButton1:setTouchPriority(-103)
    --
    self.rootItems.skillButton2:addHandleOfControlEvent(function()
        if generaldata.general.combskill.cid and  generaldata.general.combskill.cid > 0 then
            gameWindows:openWindow("generalInfoSkill",{data = generaldata, sid = 1, islead = 1, pagetype = "skillinfo", skilltype = "leadskill"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.skillButton2:setSwallowsTouch(true)
    self.rootItems.skillButton2:setTouchPriority(-103)
    --

    --attr
    local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(self.fashions[self.fashionindex].cover_id)] or {}
    local levelnow = self.fashiondata.fashions[tostring(self.fashions[self.fashionindex].cover_id)] and self.fashiondata.fashions[tostring(self.fashions[self.fashionindex].cover_id)].level or 1
    if not upconfigall[tostring(levelnow)] then return end
    local upconfig = upconfigall[tostring(levelnow)] or {}
    ui.setLabelString(self.rootItems.att_basic,nil,14)
    ui.setLabelString(self.rootItems.att_up,nil,14)
    for i = 1,3 do
        if upconfig["intentify_add"..i] and upconfig["intentify_add"..i] ~= "" then
            local attr,num = ui.getATTRandNUM(upconfig["intentify_add"..i])
            ui.setLabelString(self.rootItems["basic_att"..i],gameConfig.strings.attr_type[attr] or "",13)
            ui.setLabelString(self.rootItems["basic_num"..i],"+"..num,21)
        else
            ui.setLabelString(self.rootItems["basic_att"..i],"",13)
            ui.setLabelString(self.rootItems["basic_num"..i],"",21)
        end
    end
    --
    local allnum = {
        atk = 0,
        def = 0,
        hp = 0,
        speed = 0,
        critical = 0,
        dodge = 0,
        parry = 0,
        subdmg = 0,
        adddmg = 0,
        adddmgpct = 0,
        subdmgpct = 0,
        hit = 0,
        criticaldmg = 0,
        resilience = 0,
        arp = 0,
        ap = 0,
        ap_atk_p = 0,
    }

    for i = 1,levelnow do
        if upconfigall[tostring(i)] and upconfigall[tostring(i)]["add_attribute"] and upconfigall[tostring(i)]["add_attribute"] ~= "" then
            local attr,num = ui.getATTRandNUM(upconfigall[tostring(i)]["add_attribute"])
            if allnum[attr] then
                allnum[attr] = allnum[attr] + num
            end
        end
    end

    for i = 1,5 do
        ui.setLabelString(self.rootItems["up_att"..i],"",13)
        ui.setLabelString(self.rootItems["up_num"..i],"",22)
    end

    local hasnum = 0
    for k,v in pairs(allnum) do
        if v > 0 then
            hasnum = hasnum+1
            if hasnum <= 5 then
                ui.setLabelString(self.rootItems["up_att"..hasnum],gameConfig.strings.attr_type[k] or "",13)
                ui.setLabelString(self.rootItems["up_num"..hasnum],"+"..((v > 0 and v < 1) and ((v*100).."%") or v),22)
            end
        end
    end

    if hasnum > 0 then
        self.rootItems.att_up:setVisible(true)
    else
        self.rootItems.att_up:setVisible(false)
    end
    --

    ui.setLabelString(self.rootItems["changeLab"],nil,19)
    self.rootItems.changeButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --
        if self.fashiondata.fashions[tostring(self.fashions[self.fashionindex].cover_id)] then
            if self.fashiondata.fashionid == self.fashions[self.fashionindex].cover_id then
                runGamePrompt({msg = "已装备该时装"})
            else
                UIRequest({type = 1073, id = self.fashions[self.fashionindex].cover_id})
            end
        else
            runGamePrompt({msg = "没有获得该时装"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.changeButton:setSwallowsTouch(true)
    self.rootItems.changeButton:setTouchPriority(-103)

    --
    ui.setLabelString(self.rootItems["toupLab"],nil,19)
    self.rootItems.toupButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        self:shiftPage("up")
    end, CCControlEventTouchUpInside)
    self.rootItems.toupButton:setSwallowsTouch(true)
    self.rootItems.toupButton:setTouchPriority(-103)
    --
    if self.fashiondata.fashions[tostring(self.fashions[self.fashionindex].cover_id)] then
        self.rootItems.fashion_hasno:setVisible(false)
        if self.fashions[self.fashionindex].cover_id == self.fashiondata.fashionid then
            self.rootItems.changeNode:setVisible(false)
            self.rootItems.fashion_ison:setVisible(true)
            self.rootItems.toupNode:setVisible(true)
        else
            self.rootItems.changeNode:setVisible(true)
            self.rootItems.fashion_ison:setVisible(false)
            self.rootItems.toupNode:setVisible(false)
        end
        if self.fashions[self.fashionindex].label and self.fashions[self.fashionindex].label == 1 then
            self.rootItems.fashion_backtime:setVisible(true)
        else
            self.rootItems.fashion_backtime:setVisible(false)
        end

        ui.setLabelString(self.rootItems.fashion_backtime2,"",26)
        if self.fashions[self.fashionindex].time and self.fashions[self.fashionindex].time ~= "" then
            self.rootItems.fashion_backtime2:setVisible(true)
        else
            self.rootItems.fashion_backtime2:setVisible(false)
        end
    else
        self.rootItems.fashion_ison:setVisible(false)
        self.rootItems.fashion_hasno:setVisible(true)
        self.rootItems.toupNode:setVisible(false)
        self.rootItems.changeNode:setVisible(false)
        self.rootItems.fashion_backtime:setVisible(false)
        self.rootItems.fashion_backtime2:setVisible(false)
    end

    --
    self:setPage_allattr()

end

function fashion.setPage_allattr(self)

    local allnum = {
        atk = 0,
        def = 0,
        hp = 0,
        speed = 0,
        critical = 0,
        dodge = 0,
        parry = 0,
        subdmg = 0,
        adddmg = 0,
        adddmgpct = 0,
        subdmgpct = 0,
        hit = 0,
        criticaldmg = 0,
        resilience = 0,
        arp = 0,
        ap = 0,
        ap_atk_p = 0,
    }

    if self.fashiondata.fashions then
        for k,v in pairs(self.fashiondata.fashions) do
            --attr
            local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(v.id)] or {}
            local levelnow = v.level or 1
            if not upconfigall[tostring(levelnow)] then break end
            local upconfig = upconfigall[tostring(levelnow)] or {}

            for i = 1,3 do
                if upconfig["intentify_add"..i] and upconfig["intentify_add"..i] ~= "" then
                    local attr,num = ui.getATTRandNUM(upconfig["intentify_add"..i])
                    if allnum[attr] then
                        allnum[attr] = allnum[attr] + num
                    end
                end
            end
            --
            for i = 1,levelnow do
                if upconfigall[tostring(i)] and upconfigall[tostring(i)]["add_attribute"] and upconfigall[tostring(i)]["add_attribute"] ~= "" then
                    local attr,num = ui.getATTRandNUM(upconfigall[tostring(i)]["add_attribute"])
                    if allnum[attr] then
                        allnum[attr] = allnum[attr] + num
                    end
                end
            end
        end
    end

    ui.setLabelString(self.rootItems.allattrstr,nil,18)

    for i = 1,3 do
        ui.setLabelString(self.rootItems["allattr"..i],"",14)
        ui.setLabelString(self.rootItems["allattrnum"..i],"",21)
    end

    local hasnum = 0
    for k,v in pairs(allnum) do
        if v > 0 then
            hasnum = hasnum+1
            if hasnum <= 3 then
                ui.setLabelString(self.rootItems["allattr"..hasnum],gameConfig.strings.attr_type[k] or "",14)
                ui.setLabelString(self.rootItems["allattrnum"..hasnum],"+"..((v > 0 and v < 1) and ((v*100).."%") or v),21)
            end
        end
    end

end

--up
function fashion.setPage_up(self)
    self.rootItems.page_fashion:setVisible(false)
    self.rootItems.page_up:setVisible(true)
    --
    self:setGeneralNode()
    --
    --attr
    local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(self.fashions[self.fashionindex].cover_id)] or {}
    local levelnow = self.fashiondata.fashions[tostring(self.fashions[self.fashionindex].cover_id)] and self.fashiondata.fashions[tostring(self.fashions[self.fashionindex].cover_id)].level or 1
    if not upconfigall[tostring(levelnow)] then return end
    local upconfig = upconfigall[tostring(levelnow)] or {}

    ui.setLabelString(self.rootItems["up_now_lv"],"等级",13)
    ui.setLabelString(self.rootItems["up_now_lvnum"],levelnow,21)

    for i = 1,3 do
        if upconfig["intentify_add"..i] and upconfig["intentify_add"..i] ~= "" then
            local attr,num = ui.getATTRandNUM(upconfig["intentify_add"..i])
            ui.setLabelString(self.rootItems["up_now_att"..i],gameConfig.strings.attr_type[attr] or "",13)
            ui.setLabelString(self.rootItems["up_now_num"..i],"+"..num,21)
        else
            ui.setLabelString(self.rootItems["up_now_att"..i],"",13)
            ui.setLabelString(self.rootItems["up_now_num"..i],"",21)
        end
    end

    self.rootItems.fashion_hasno:setVisible(false)
    if not self.fashiondata.fashions[tostring(self.fashions[self.fashionindex].cover_id)] then
        self.rootItems.fashion_hasno:setVisible(true)
        self.rootItems.up_node_more:setVisible(false)
        self.rootItems.up_node_next:setVisible(false)
        self.rootItems.up_controlnode:setVisible(false)
        self.rootItems.up_title:setString("")
    elseif upconfigall[tostring(levelnow+1)] then
        self.rootItems.up_node_next:setVisible(true)
        self.rootItems.up_controlnode:setVisible(true)
        self.rootItems.up_title:setString("强化材料")
        local upconfig1 = upconfigall[tostring(levelnow+1)] or {}

        ui.setLabelString(self.rootItems["up_next_lv"],"等级",13)
        ui.setLabelString(self.rootItems["up_next_lvnum"],levelnow+1,21)

        for i = 1,3 do
            if upconfig1["intentify_add"..i] and upconfig1["intentify_add"..i] ~= "" then
                local attr,num = ui.getATTRandNUM(upconfig1["intentify_add"..i])
                ui.setLabelString(self.rootItems["up_next_att"..i],gameConfig.strings.attr_type[attr] or "",13)
                ui.setLabelString(self.rootItems["up_next_num"..i],"+"..num,21)
            else
                ui.setLabelString(self.rootItems["up_next_att"..i],"",13)
                ui.setLabelString(self.rootItems["up_next_num"..i],"",21)
            end
        end
        if upconfig1["add_attribute"] and upconfig1["add_attribute"] ~= "" then
            local attr,num = ui.getATTRandNUM(upconfig1["add_attribute"])
            ui.setLabelString(self.rootItems["up_more_att"],gameConfig.strings.attr_type[attr] or "",13)
            ui.setLabelString(self.rootItems["up_more_num"],"+"..num,22)
            ui.setLabelString(self.rootItems["up_more_lab"],nil,21)
            self.rootItems.up_node_more:setVisible(true)
        else
            self.rootItems.up_node_more:setVisible(false)
        end

        --up
        self.up_needcoin = 0
        self.up_needprops = {}
        local needs = ui.getIDandNUMs(upconfig.use) or {}
        self.rootItems.coin_sprite:setVisible(false)
        ui.setLabelString(self.rootItems.up_coin,"",14)
        self.rootItems.up_propnode1:setVisible(false)
        local propnum = 0
        for k,v in pairs(needs) do
            if v.cid == 1000 then
                self.rootItems.coin_sprite:setVisible(true)
                -- ui.setLabelString(self.rootItems.up_coin,v.num,14)
                self.up_needcoin = v.num
                if GameScene.roleinfo.coin >= v.num then
                    ui.setLabelString(self.rootItems.up_coin,v.num,14)
                else
                    ui.setLabelString(self.rootItems.up_coin,v.num,24)
                end

            elseif  ui.IDconfig(v.cid).staffType == "props" then
                propnum = propnum+1
                if propnum == 1 or propnum == 2 then
                    self.rootItems["up_propnode"..propnum]:setVisible(true)
                    ui.setNewIcon(self.rootItems,{cid = v.cid},propnum-1)
                    ui.setLabelString(self.rootItems["up_propname"..propnum],ui.IDconfig(v.cid).name,1)
                    ui.setLabelString(self.rootItems["up_propnum"..propnum],"",1)
                    --
                    self.rootItems["i_button"..((propnum == 2) and "_1" or "")]:addHandleOfControlEvent(function()
                        gameWindows:openWindow("dropTips",{cid = v.cid},nil)
                    end, CCControlEventTouchUpInside)
                    self.rootItems["i_button"..((propnum == 2) and "_1" or "")]:setSwallowsTouch(true)
                    self.rootItems["i_button"..((propnum == 2) and "_1" or "")]:setTouchPriority(-103)
                    --
                end
                self.up_needprops[tostring(v.cid)] = {cid = v.cid, num = v.num, index = propnum, has = 0 }
                UIRequest({type = 12001, order = 10721, cids = {v.cid}})
            end
        end

        ui.setLabelString(self.rootItems["upLab"],nil,19)
        self.rootItems.upButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)

            if upconfig.troop and upconfig.troop > GameScene.roleinfo.level then
                runGamePrompt({msg = "队伍等级到达"..upconfig.troop.."级可强化"})
                return
            end

            for k,v in pairs(self.up_needprops) do
                if v.has < v.num then
                    runGamePrompt({msg = "强化道具不足"})
                    return
                end
            end
            gameTouch:clickprofbytime(1.5)
            UIRequest({type = 1072, id = self.fashions[self.fashionindex].cover_id, xcoin = self.up_needcoin, xprops = self.up_needprops})
        end, CCControlEventTouchUpInside)
        self.rootItems.upButton:setSwallowsTouch(true)
        self.rootItems.upButton:setTouchPriority(-103)

        ui.setLabelString(self.rootItems["upLab1"],nil,19)
        self.rootItems.upButton1:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)

            if upconfig.troop and upconfig.troop > GameScene.roleinfo.level then
                runGamePrompt({msg = "队伍等级到达"..upconfig.troop.."级可强化"})
                return
            end

            for k,v in pairs(self.up_needprops) do
                if v.has < v.num then
                    runGamePrompt({msg = "强化道具不足"})
                    return
                end
            end
            gameTouch:clickprofbytime(1.5)
            UIRequest({type = 1072, id = self.fashions[self.fashionindex].cover_id, xcoin = self.up_needcoin, xprops = self.up_needprops,curType = 5})
        end, CCControlEventTouchUpInside)
        self.rootItems.upButton1:setSwallowsTouch(true)
        self.rootItems.upButton1:setTouchPriority(-103)



        -- ui.removeGray("CCControlButton",self.rootItems.upButton)
        -- for k,v in pairs(self.up_needprops) do
        --     if v.has < v.num then
        --         ui.addGray("CCControlButton",self.rootItems.upButton)
        --     end
        -- end

        -- if upconfig.troop and upconfig.troop > GameScene.roleinfo.level then
        --     ui.addGray("CCControlButton",self.rootItems.upButton)
        -- end

    else
        self.rootItems.up_node_more:setVisible(false)
        self.rootItems.up_node_next:setVisible(false)
        self.rootItems.up_controlnode:setVisible(false)
        self.rootItems.up_title:setString("已满级")
    end

    --
    self.rootItems.previewButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("fashionPreview",{cover_id = self.fashions[self.fashionindex].cover_id, level = levelnow},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.previewButton:setSwallowsTouch(true)
    self.rootItems.previewButton:setTouchPriority(-103)


end

function fashion.setUpPropNum(self,pdata)

    for k,v in pairs(pdata) do
        if self.up_needprops[tostring(k)] then
            self.up_needprops[tostring(k)].has = v
        end
    end

    for k,v in pairs(self.up_needprops) do
        if v.has >= v.num then
            ui.setLabelString(self.rootItems["up_propnum"..v.index],v.has.."/"..v.num,3)
        else
            ui.setLabelString(self.rootItems["up_propnum"..v.index],v.has.."/"..v.num,11)
        end
    end

    -- ui.removeGray("CCControlButton",self.rootItems.upButton)
    -- for k,v in pairs(self.up_needprops) do
    --     if v.has < v.num then
    --         ui.addGray("CCControlButton",self.rootItems.upButton)
    --     end
    -- end

end

function fashion.updatatime(self)
    local tt = tostring(table.getTableLength(gamedata.config.cross_battle_time))
    local timeconfig = gamedata.config.cross_battle_time and gamedata.config.cross_battle_time[tt] or {}
    local back_week = timeconfig.open_week or 6
    local back_hour,back_min,back_sec = 20,0,0
    back_hour,back_min,back_sec = ui.getGangBattleTime(timeconfig.open_time)

    local wday = back_week+1
    if wday > 7 then wday = 1 end
    local nowtime = os.date("*t", gamedata:time())
    local diff = (wday-nowtime.wday)*86400+(back_hour-nowtime.hour)*3600+(back_min-nowtime.min)*60+back_sec-nowtime.sec
    if diff < 0 then diff = diff+86400*7 end

    gameTimer:rigistTime("fashionbacktimer",diff+2)
    gameTimer:rigistTimeFunc("fashionbacktimer",function()
        if gameTimer.times["fashionbacktimer"] <= 0 then
            ui.setLabelString(self.rootItems.fashion_backtime,"",26)
            UIRequest({type = 1070})
        else
            ui.setLabelString(self.rootItems.fashion_backtime,"回收倒计时："..ui.makeTimeDayText(gameTimer.times["fashionbacktimer"],"day"),26)
        end
    end)


end

function fashion.updatatime2(self)

    for k,v in ipairs(self.fashions) do
        if gameTimer.times["fashionbacktimer"..v.cover_id] then
            gameTimer:UnrigistTimeFunc("fashionbacktimer"..v.cover_id)
        end
        if v.time and v.time ~= "" and self.fashiondata.fashions[tostring(v.cover_id)] then
            local e_year,e_month,e_day,e_hour,e_minute,e_second = ui.getDate(tostring(v.time))
            local endt = os.time({year=tonumber(e_year), month=tonumber(e_month),day=tonumber(e_day),hour=tonumber(e_hour),min=tonumber(e_minute),sec=tonumber(e_second)})
            local diff = endt-gamedata:time()
            local cover_id = v.cover_id
            if diff > 0 then
                gameTimer:rigistTime("fashionbacktimer"..cover_id,diff+2)
                gameTimer:rigistTimeFunc("fashionbacktimer"..cover_id,function()
                    print(gameTimer.times["fashionbacktimer"..cover_id])
                    if gameTimer.times["fashionbacktimer"..cover_id] <= 0 then
                        UIRequest({type = 1070})
                    elseif self.fashions[self.fashionindex].cover_id == cover_id then
                        ui.setLabelString(self.rootItems.fashion_backtime2,"回收倒计时："..ui.makeTimeDayText(gameTimer.times["fashionbacktimer"..cover_id],"day"),26)
                    end
                end)
            end
        end
    end

end

return fashion
 �  