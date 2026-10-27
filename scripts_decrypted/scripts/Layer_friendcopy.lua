--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/27
-- Time: 上午10:41
-- To change this template use File | Settings | File Templates.
--

local friendcopy = {

    resource = nil,
    retainresource  = {"copyfriend/copyfriend"},

    rootNode = nil,
    rootItems = nil,

    mapconfig = nil,

    friendcopy_propcid_1 = 20048,
    friendcopy_propcid_2 = 20049,
    friendcopy_propcid_3 = 20050,

    --propconfig = {20048,20049,20050},
    --propactive = {
    --    [20048] = false,
    --    [20049] = false,
    --    [20050] = false,
    --},
    propSelectData = {
        [1] = {revive = 0,recove = 0,strengthen = 0, },
        [2] = {revive = 0,recove = 0,strengthen = 0, },
        [3] = {revive = 0,recove = 0,strengthen = 0, },
        [4] = {revive = 0,recove = 0,strengthen = 0, },
        [5] = {revive = 0,recove = 0,strengthen = 0, },
        [6] = {revive = 0,recove = 0,strengthen = 0, },
        [7] = {revive = 0,recove = 0,strengthen = 0, },
    },


    copydata = nil,
    propdata = nil,
    slotGenerals = nil,
    slotdata = {},
    selecteMap = 1,
    selecteHelp = nil,

    typeconfig = {"list","select","prop"},
    selectedtype = nil,

    ruleStatus = false,

    selectccb = nil,
    selectitem = nil,
    propccb = nil,
    propitem = nil,

    listTableView = nil,
    listCellSize = {x =1080,y=250},

}

function friendcopy.shifPage(self,type)
    self.selectedtype = type

    for k,v in ipairs(self.typeconfig) do
        if v == type then
            self.rootItems[v.."node"]:setVisible(true)
            self.rootItems[v.."node"]:setPosition(0,0)
        else
            self.rootItems[v.."node"]:setVisible(false)
            self.rootItems[v.."node"]:setPosition(9999,0)
        end
    end
end

function friendcopy.init(self,parent,toppos)
    self.mapconfig = gamedata.config.expedition_map
    self.rootNode,self.rootItems = CCBReaderLoad("copyFriend/copyfriend.ccbi", nil, true, "copyfriend")
    parent:addChild(self.rootNode)

    self.toppos = toppos

    self.friendcopy_propcid_1 = gamedata.config.global_kv.friendcopy_tool_1_propcid and tonumber(gamedata.config.global_kv.friendcopy_tool_1_propcid.value) or 20048
    self.friendcopy_propcid_2 = gamedata.config.global_kv.friendcopy_tool_2_propcid and tonumber(gamedata.config.global_kv.friendcopy_tool_2_propcid.value) or 20049
    self.friendcopy_propcid_3 = gamedata.config.global_kv.friendcopy_tool_3_propcid and tonumber(gamedata.config.global_kv.friendcopy_tool_3_propcid.value) or 20050

    self.propconfig = {self.friendcopy_propcid_1,self.friendcopy_propcid_2,self.friendcopy_propcid_3}
    self.propactive = {
        [self.friendcopy_propcid_1] = false,
        [self.friendcopy_propcid_2] = false,
        [self.friendcopy_propcid_3] = false,
    },

    --printT(self.rootItems)
    self.rootItems.listtop:setPositionY(toppos)
    self.rootItems.selecttop:setPositionY(toppos)
    self.rootItems.proptop:setPositionY(toppos)

    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-130))

    ui.setLabelString(self.rootItems.selectdes,nil,49)
    ui.setLabelString(self.rootItems.propdes,nil,48)
    ui.setLabelString(self.rootItems.gold,nil,13)
    ui.setLabelString(self.rootItems.freeNode,nil,13)

    self.selectedtype = self.selectedtype or "list"
    self:shifPage(self.selectedtype)

    self.rootItems.backButton:setTouchPriority(-103)
    self.rootItems.backButton:addHandleOfControlEvent(function()
        self:shifPage("list")
    end, CCControlEventTouchUpInside)

    self.rootItems.rank:setTouchPriority(-103)
    self.rootItems.rank:addHandleOfControlEvent(function()
        print("rank")
        --gameWindows:openWindow("friendcopyrank",nil,nil)
        UIRequest({type= 1322})
    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.selectgotofighttext,"挑 战",18)
    ui.setLabelString(self.rootItems.selectgotofighttext,gameConfig.strings:string_common("friendcopy",0),18)
    self.rootItems.selectgotofight:setTouchPriority(-103)
    self.rootItems.selectgotofight:addHandleOfControlEvent(function()
        if self.selecteHelp then
            UIRequest({type= 1321,map = self.selecteMap, help = self.selecteHelp.iid, slot = self.propSelectData})
        else
           -- runGamePrompt({msg = "请选择武将"})
           runGamePrompt({msg = gameConfig.strings:string_common("friendcopy",1)})
        end
    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.propgotofighttext,"挑 战",18)
    ui.setLabelString(self.rootItems.propgotofighttext,gameConfig.strings:string_common("friendcopy",0),18)
    self.rootItems.propgotofight:setTouchPriority(-103)
    self.rootItems.propgotofight:addHandleOfControlEvent(function()
        UIRequest({type= 1321,map = self.selecteMap, slot = self.propSelectData})
    end, CCControlEventTouchUpInside)

    self.rootItems.ruleButton1:setTouchPriority(-103)
    self.rootItems.ruleButton1:addHandleOfControlEvent(function()
        gameWindows:openWindow("friendcopy",{type = "rule"},nil)
    end, CCControlEventTouchUpInside)

    for k,v in ipairs(self.propconfig) do
        self.rootItems["in_button"..(k-1 == 0 and "" or "_"..(k-1))]:setTouchPriority(-103)
        self.rootItems["in_button"..(k-1 == 0 and "" or "_"..(k-1))]:addHandleOfControlEvent(function()

            if self.propdata[tostring(v)] > 0 then
                for k_,v_ in ipairs(self.propconfig) do
                    if v_==v then
                        self.propactive[v_] = not self.propactive[v_]
                    else
                        self.propactive[v_] = false
                    end
                end
                self:setPropStatus()
                self:setGeneralStatus()
            else
                -- runGamePrompt({msg = "道具不足"})
                runGamePrompt({msg = gameConfig.strings:string_common("friendcopy",2)})
            end
            print(tostring(v),self.propactive[v])
        end, CCControlEventTouchUpInside)
    end


    UIRequest({type = 1320})
    UIRequest({type = 12001, order = 13201, cids = self.propconfig})
end

function friendcopy.clear(self)
    self.selectccb = nil
    self.propccb = nil
    self.listTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function friendcopy.creatList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.listCellSize.x, self.listCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("copyFriend/cell.ccbi", nil, true, "cell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.listTableView,cellCCB,self.listCellSize.x/2, self.listCellSize.y/2-10,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local totalnum =  table.getTableLength(self.copydata)
            local config = gamedata.config.expedition_map[tostring(totalnum - a1+43000)]
            -- ui.setLabelString(ccbDocumentControler.name,"第"..gameConfig.strings.bigNum[totalnum - a1].."关："..config.name,12)
            ui.setLabelString(ccbDocumentControler.name,gameConfig.strings:lvNum(gameConfig.strings.bigNum[totalnum-a1],config.name),12)
            setSpriteFrameByName(ccbDocumentControler.bg, config.basemap.."_cell")

            if a1 == 0 then
                ccbDocumentControler.new:setVisible(true)
            else
                ccbDocumentControler.new:setVisible(false)
            end

            if config.drop1 and config.drop1 ~= "" then
                ccbDocumentControler.dropnode:setVisible(true)
                ui.setNewIcon(ccbDocumentControler,{cid = tonumber(config.drop1)})
            else
                ccbDocumentControler.dropnode:setVisible(false)
            end

            -- ui.setLabelString(ccbDocumentControler.dropdes,"查看掉落",482)
            ui.setLabelString(ccbDocumentControler.dropdes,gameConfig.strings:string_common("friendcopy",3),482)

            local i=1
            local reward = {}
            while  config["drop"..i] and config["drop"..i] ~= 0 do
                reward[tostring(table.getTableLength(reward)+1)] = {cid = config["drop"..i],num = 1 }
                i = i+1
            end
            ccbDocumentControler.i_button:setTouchPriority(-103)
            ccbDocumentControler.i_button:setSwallowsTouch(true)
            ccbDocumentControler.i_button:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                --gameWindows:openWindow("getStaff",{data = reward,type = "可能掉落"},nil)
                gameWindows:openWindow("getStaff",{data = reward,type = gameConfig.strings:string_common("friendcopy",4)},nil)
                --showRewardPopupWindow({data = reward,type = "可能掉落"},nil,nil)
            end, CCControlEventTouchUpInside)

            if self.listTableView then
                cellCCB:setPosition(self.listCellSize.x/2, self.listCellSize.y/2-10)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.copydata)
        elseif fn == "cellTouched" then
            local totalnum =  table.getTableLength(self.copydata)
            self.selecteMap = totalnum - a1:getIdx()+43000

            self:shifPage("select")
            self:reloadSelect()

            if guide.controller then
                guide.controller:UIComplete(8045)
            end
        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.listTableView:setTouchPriority(-101)
    self.rootItems.listScroll:addChild(self.listTableView)

end

function friendcopy.setPropNum(self,data)
    self.propdata = data.nums

    for k,v in ipairs(self.propconfig) do
        ui.setNewIconName(self.rootItems,{
            cid = v,
            num = self.propdata[tostring(v)]
        },k-1)
    end
end


function friendcopy.reloadList(self,data)
    self.copydata = data.friendcopy
    self.slotGenerals = data.slotGenerals

    self:shifPage("list")
    self.propSelectData = {
        [1] = {revive = 0,recove = 0,strengthen = 0, },
        [2] = {revive = 0,recove = 0,strengthen = 0, },
        [3] = {revive = 0,recove = 0,strengthen = 0, },
        [4] = {revive = 0,recove = 0,strengthen = 0, },
        [5] = {revive = 0,recove = 0,strengthen = 0, },
        [6] = {revive = 0,recove = 0,strengthen = 0, },
        [7] = {revive = 0,recove = 0,strengthen = 0, },
    }


    if not self.listTableView then
        self:creatList()
    else
        self.listTableView:reloadData()
        self.listTableView:setLuaContentOffset(0,  self.rootItems.listScroll:getContentSize().height - self.listCellSize.y*table.getTableLength(self.copydata) )
    end

    for k,v in pairs( self.copydata) do
        if v.friend and v.friendgeneral then
            self.selecteMap = v.map

            self:shifPage("prop")
            self:reloadProp()
            break
        end
    end

end

function friendcopy.setOneSlot(self,data,item,id,type)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end
    if not data.open then item["g_rootnode"..key_Ex]:setVisible(false) return end

    item["g_heart"..key_Ex]:setVisible(data.help)
    item["g_noneNode"..key_Ex]:setVisible(data.selectActive and data.showselect)

    if data.has then
        local config = ui.IDconfig(data.cid)
        item["g_dataNode"..key_Ex]:setVisible(true)

        if gameConfig.images[config.actor] then
            setSpriteFrameByName(item["g_type"..key_Ex], gameConfig.images[config.actor])
        else
            setSpriteFrameByName(item["g_type"..key_Ex], gameConfig.images.alpha)
        end
        setSpriteFrameByName(item["g_quality"..key_Ex], gameConfig.images["l_g_q_back_"..config.quality])
        setSpriteFrameByName(item["g_icon"..key_Ex],config["icon"])

        item["g_level"..key_Ex]:setString("等级. "..data.level1)
        --item["g_level2"..key_Ex]:setString(data.level2<= 0 and "" or data.level2.."阶")
        -- ui.setLabelString(item["g_name"..key_Ex],config.name == "主角" and (data.help and data.friendname or GameScene.roleinfo.name) or config.name,(config.quality or 1)*2-1)
        ui.setLabelString(item["g_name"..key_Ex],config.name == gameConfig.strings:string_common("friendcopy",5) and (data.help and data.friendname or GameScene.roleinfo.name) or config.name,(config.quality or 1)*2-1)
    else
        setSpriteFrameByName(item["g_quality"..key_Ex], gameConfig.images["l_g_q_back_default"])
        item["g_dataNode"..key_Ex]:setVisible(false)
    end

    if data.hp then
        ui.setSpriteTextureRect2(item["g_bloodbar"..key_Ex],0,0,327 * data.hp/100,22)
    end
    setSpriteFrameByName(item["g_statusSprite"..key_Ex], data.status and gameConfig.images[data.status] or gameConfig.images.alpha)

end

function friendcopy.setSelectGeneral(self,general,pos)
    self.selecteHelp = general
    self.slotdata[pos] = table.merge(general,{help = true,open =true,has =true,selectActive = true,showselect = false})
    self:setOneSlot(self.slotdata[pos],self.selectitem,pos-1)
end

function friendcopy.arrangeSlot(self,items,height)
    for i=1,7 do
        items["slot"..i]:setPositionY(items["slot"..i]:getPositionY()*(height/770))
    end
end


function friendcopy.reloadSelect(self)

    self.selecteHelp = nil
    if not self.selectccb then
        self.selectccb, self.selectitem = CCBReaderLoad("copyFriend/copyfriend_slot.ccbi", nil, true, "copyfriend_slot")
        self.rootItems.selectslot:removeAllChildrenWithCleanup(true)
        self.rootItems.selectslot:addChild(self.selectccb)
        self:arrangeSlot(self.selectitem,self.toppos-630)
    end

    for i=1, 7 do
        if self.slotGenerals[tostring(i)] then
            if self.mapconfig[tostring(self.selecteMap)].friend == i then
                self.slotdata[i] = {help = true,open=true,has =false,selectActive = true,showselect = true}
            else
                if self.slotGenerals[tostring(i)].iid then
                    self.slotdata[i] = table.merge({help = false,open=true,has =true,selectActive = false},self.slotGenerals[tostring(i)])
                else
                    self.slotdata[i] = {help = false,open=true,has =false,selectActive = false}
                end
            end
        else
            self.slotdata[i] = {help = false,open=false,has =false,selectActive = false}
        end
        self:setOneSlot(self.slotdata[i],self.selectitem,i-1)
    end

    self.selectitem["g_button"]:setTouchPriority(-103)
    self.selectitem["g_button"]:addHandleOfControlEvent(function()
        if self.slotdata[1].selectActive then
            UIRequest({type = 13201,pos = 1})
        end
    end, CCControlEventTouchUpInside)

    self.selectitem["g_button_1"]:setTouchPriority(-103)
    self.selectitem["g_button_1"]:addHandleOfControlEvent(function()
        if self.slotdata[2].selectActive then
            UIRequest({type = 13201,pos = 2})
        end
    end, CCControlEventTouchUpInside)

    if self.copydata[tostring(self.selecteMap)].kill < 1 then
        self.rootItems.freeNode:setVisible(true)
        self.rootItems.goldNode:setVisible(false)
    else
        self.rootItems.freeNode:setVisible(false)
        self.rootItems.goldNode:setVisible(true)
    end

    -- self.rootItems.mapname1:setString("第"..(self.selecteMap-43000).."关："..self.mapconfig[tostring(self.selecteMap)].name)
    self.rootItems.mapname1:setString(gameConfig.strings:lvNum(self.selecteMap-43000,self.mapconfig[tostring(self.selecteMap)].name))
    self.rootItems.selectPoint1:setString((self.copydata[tostring(self.selecteMap)].point+1).."/"..table.getTableLength(gamedata.config.expedition[tostring(self.selecteMap)]))

end


function friendcopy.setPropStatus(self)
    for k_,v_ in ipairs(self.propconfig) do
        if self.propactive[v_] == true then
            self.rootItems["in_icon"..(k_-1 == 0 and "" or "_"..(k_-1))]:stopAllActions()
            local red = CCFadeTo:create(0.5,100)
            local back = CCFadeTo:create(0.5,255)
            local sq = CCSequence:createWithTwoActions(red,back)
            self.rootItems["in_icon"..(k_-1 == 0 and "" or "_"..(k_-1))]:runAction(CCRepeatForever:create(sq))
        else
            self.rootItems["in_icon"..(k_-1 == 0 and "" or "_"..(k_-1))]:stopAllActions()
            local back = CCFadeTo:create(0,255)
            self.rootItems["in_icon"..(k_-1 == 0 and "" or "_"..(k_-1))]:runAction(back)
        end
    end
end

function friendcopy.activeGeneral(self,data,item,id,status)
    if not data.open then return end
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    if status then
        item["g_quality"..key_Ex]:stopAllActions()
        local red = CCFadeTo:create(0.5,100)
        local back = CCFadeTo:create(0.5,255)
        local sq = CCSequence:createWithTwoActions(red,back)
        item["g_quality"..key_Ex]:runAction(CCRepeatForever:create(sq))
    else
        item["g_quality"..key_Ex]:stopAllActions()
        local back = CCFadeTo:create(0,255)
        item["g_quality"..key_Ex]:runAction(back)
    end
end

function friendcopy.setGeneralStatus(self)
    if self.propactive[self.friendcopy_propcid_1] then
        for k,v in ipairs(self.slotdata) do
           if v.hp and v.hp == 0 and self.propdata[tostring(self.friendcopy_propcid_1)] > 0 then
               self:activeGeneral(v,self.propitem,k-1,true)
           else
               self:activeGeneral(v,self.propitem,k-1,false)
           end
        end
    elseif self.propactive[self.friendcopy_propcid_2] then
        for k,v in ipairs(self.slotdata) do
            if v.hp and v.hp > 0 and not v.hasadded and self.propdata[tostring(self.friendcopy_propcid_2)] > 0 then
                self:activeGeneral(v,self.propitem,k-1,true)
            else
                self:activeGeneral(v,self.propitem,k-1,false)
            end
        end

    elseif self.propactive[self.friendcopy_propcid_3] then
        for k,v in ipairs(self.slotdata) do
            if v.hp and v.hp > 0 and not v.haspromoted and self.propdata[tostring(self.friendcopy_propcid_3)] > 0 then
                self:activeGeneral(v,self.propitem,k-1,true)
            else
                self:activeGeneral(v,self.propitem,k-1,false)
            end
        end
    else
        for k,v in ipairs(self.slotdata) do
            self:activeGeneral(v,self.propitem,k-1,false)
        end
    end
end

function friendcopy.reloadProp(self)

    if not self.propccb then
        self.propccb, self.propitem = CCBReaderLoad("copyFriend/copyfriend_slot.ccbi", nil, true, "copyfriend_slot")
        self.rootItems.propslot:removeAllChildrenWithCleanup(true)
        self.rootItems.propslot:addChild(self.propccb)
        self:arrangeSlot(self.propitem,self.toppos-690)
    else
        self.propactive = {
            [self.friendcopy_propcid_1] = false,
            [self.friendcopy_propcid_2] = false,
            [self.friendcopy_propcid_3] = false,
        }
        self:setPropStatus()
        self:setGeneralStatus()
    end



    for i=1, 7 do
        if self.slotGenerals[tostring(i)] then
            if self.mapconfig[tostring(self.selecteMap)].friend == i then
                self.slotdata[i] = table.merge(self.copydata[tostring(self.selecteMap)].friendgeneral,{
                        help = true,
                        open=true,
                        has =true,
                        selectActive = false,
                        hp = self.copydata[tostring(self.selecteMap)].hps[tostring(i)]
                    })
                self.selecteHelp = self.slotdata[i]
            else
                if self.slotGenerals[tostring(i)].iid then
                    self.slotdata[i] =  table.merge(self.slotGenerals[tostring(i)],{
                        help = false,
                        open=true,
                        has =true,
                        selectActive = false,
                        hp = self.copydata[tostring(self.selecteMap)].hps[tostring(i)]
                    })
                else
                    self.slotdata[i] = {help = false,open=true,has =false,selectActive = false}
                end
            end
        else
            self.slotdata[i] = {help = false,open=false,has =false,selectActive = false}
        end
        if self.slotdata[i].hp and self.slotdata[i].hp ==0 then
            self.slotdata[i].status = "dead"
        end

        self:setOneSlot(self.slotdata[i],self.propitem,i-1)
        local key_Ex
        if i == nil or i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..i-1
        end

        self.propitem["g_button"..key_Ex]:setTouchPriority(-103)
        self.propitem["g_button"..key_Ex]:setVisible(true)
        self.propitem["g_button"..key_Ex]:addHandleOfControlEvent(function()
            --printT(self.slotdata[i])
            local usedPorp = 0
            if self.propactive[self.friendcopy_propcid_1] then
                if self.slotdata[i].hp ==0 then
                    -- if self.propdata[tostring(self.friendcopy_propcid_1)] <= 0 then runGamePrompt({msg = "道具不足"}) return end
                    if self.propdata[tostring(self.friendcopy_propcid_1)] <= 0 then runGamePrompt({msg = gameConfig.strings:string_common("friendcopy",2)}) return end
                    self.slotdata[i].hp = tonumber(gamedata.config.props[tostring(self.friendcopy_propcid_1)].param1)
                    self.slotdata[i].status = nil
                    self.propSelectData[i].revive = self.propSelectData[i].revive + 1
                    usedPorp = self.friendcopy_propcid_1
                end
            elseif self.propactive[self.friendcopy_propcid_2] then
                if self.slotdata[i].hp >0 and not self.slotdata[i].hasadded then
                    --if self.propdata[tostring(self.friendcopy_propcid_2)] <= 0 then runGamePrompt({msg = "道具不足"}) return end
                    if self.propdata[tostring(self.friendcopy_propcid_2)] <= 0 then runGamePrompt({msg = gameConfig.strings:string_common("friendcopy",2)}) return end
                    self.slotdata[i].hp = self.slotdata[i].hp + tonumber(gamedata.config.props[tostring(self.friendcopy_propcid_2)].param1)
                    if self.slotdata[i].hp > 100 then
                        self.slotdata[i].hp = 100
                    end
                    self.slotdata[i].hasadded = true
                    self.propSelectData[i].recove = self.propSelectData[i].recove + 1
                    usedPorp = self.friendcopy_propcid_2
                end
            elseif self.propactive[self.friendcopy_propcid_3] then
                if self.slotdata[i].hp >0 and not self.slotdata[i].haspromoted then
                    -- if self.propdata[tostring(self.friendcopy_propcid_3)] <= 0 then runGamePrompt({msg = "道具不足"}) return end
                    if self.propdata[tostring(self.friendcopy_propcid_3)] <= 0 then runGamePrompt({msg = gameConfig.strings:string_common("friendcopy",2)}) return end
                    if ui.IDconfig(self.slotdata[i].cid).actor == "tank" then
                        self.slotdata[i].status = "def_add"
                    elseif ui.IDconfig(self.slotdata[i].cid).actor == "dps" then
                        self.slotdata[i].status = "atk_add"
                    end
                    self.slotdata[i].haspromoted = true
                    self.propSelectData[i].strengthen = self.propSelectData[i].strengthen + 1
                    usedPorp = self.friendcopy_propcid_3
                end
            end
            if  usedPorp ~= 0 then
                self.propdata[tostring(usedPorp)] = self.propdata[tostring(usedPorp)] - 1
                ui.setNewIconName(self.rootItems,{
                    cid = usedPorp,
                    num = self.propdata[tostring(usedPorp)]
                },usedPorp-self.friendcopy_propcid_1)

                self:setOneSlot(self.slotdata[i],self.propitem,i-1)
                if self.propdata[tostring(usedPorp)] ==0 then
                    self.propactive[usedPorp] = false
                end
                self:setPropStatus()
                self:setGeneralStatus()
            end

        end, CCControlEventTouchUpInside)

    end

    -- self.rootItems.mapname2:setString("第"..(self.selecteMap-43000).."关："..self.mapconfig[tostring(self.selecteMap)].name)
    self.rootItems.mapname2:setString(gameConfig.strings:lvNum(self.selecteMap-43000,self.mapconfig[tostring(self.selecteMap)].name))
    self.rootItems.selectPoint2:setString((self.copydata[tostring(self.selecteMap)].point+1).."/"..table.getTableLength(gamedata.config.expedition[tostring(self.selecteMap)]))
end



return friendcopy   �d  