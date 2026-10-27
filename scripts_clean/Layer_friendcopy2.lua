--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/12/26
-- Time: 上午11:48
-- To change this template use File | Settings | File Templates.
--

local friendcopy = {

    resource = nil,
    retainresource  = {"copyfriend/copyfriend"},

    rootNode = nil,
    rootItems = nil,

    mapconfig = nil,

    selecteMap = 1,
    selecteHelp = nil,


    listTableView = nil,
    listCellSize = {x =1080,y=250},
    isscrolltouched = false,

}

function friendcopy.init(self,parent,toppos)
    self.mapconfig = gamedata.config.expedition_map
    self.rootNode,self.rootItems = CCBReaderLoad("copyFriend/copyfriend.ccbi", nil, true, "copyfriend")
    parent:addChild(self.rootNode)

    self.toppos = toppos

    --printT(self.rootItems)
    self.rootItems.listtop:setPositionY(toppos)
    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-180))
    
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","friendcopy2",touchbegin)
    local function touchend(pos)
        if self.rootItems.listScroll and ui.isTouched(self.rootItems.listScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","friendcopy2",touchend)

    self.rootItems.rank:setVisible(false)

    self.rootItems.rank:setTouchPriority(-103)
    self.rootItems.rank:addHandleOfControlEvent(function()
        print("rank")
        --gameWindows:openWindow("friendcopyrank",nil,nil)
        UIRequest({type= 1322})
    end, CCControlEventTouchUpInside)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(-103)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)


    self.rootItems.ruleButton1:setTouchPriority(-103)
    self.rootItems.ruleButton1:addHandleOfControlEvent(function()
        gameWindows:openWindow("friendcopy",{type = "rule"},nil)
    end, CCControlEventTouchUpInside)

    --
    if self.rootItems.oneFinishBtn then
        self.rootItems.oneFinishBtn:setTouchPriority(-103)
        self.rootItems.oneFinishBtn:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)

            if gamedata.config.global_kv.friendcopy_quick_complete_vip and gamedata.config.global_kv.friendcopy_quick_complete_level and (tonumber(gamedata.config.global_kv.friendcopy_quick_complete_vip.value) > GameScene.vip.vip) and (tonumber(gamedata.config.global_kv.friendcopy_quick_complete_level.value) > GameScene.roleinfo.level) then
                runGamePrompt({msg = gamedata.config.global_kv.friendcopy_quick_complete_level.value.."级或VIP"..gamedata.config.global_kv.friendcopy_quick_complete_vip.value.."以上可使用一键完成功能"})
            else    
                if self.copydata.kill > 0 then
                    if self.copydata.maps["1"] and self.copydata.maps["1"].kill > -1 then
                        gameWindows:openWindow("friendcopy_onefinish",{data = self.copydata},nil)
                    else
                        runGamePrompt({msg = "通关第一关后可进行一键完成"})
                    end
                else
                    shortFriendCopykill()
                end
            end
        end, CCControlEventTouchUpInside)
    end

    UIRequest({type = 1323})
end

function friendcopy.clear(self)
    gameTouch:UnrigistFunc("begin","friendcopy2")
    gameTouch:UnrigistFunc("end","friendcopy2")    
    self.isscrolltouched = false
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
            -- 双倍掉率
            if ccbDocumentControler.isrewarddouble then
                local datatmp = ui.CheckHuodongByParam(7)
                -- local datatmp = ui.CheckHuodongByParam(1)
                if datatmp then
                    ccbDocumentControler.isrewarddouble:setVisible(true)
                    ui.setLabelString(ccbDocumentControler.isrewarddouble, gameConfig.strings:string_common("doublereward",1), 24)
                else
                    ccbDocumentControler.isrewarddouble:setVisible(false)
                end
            end

            local totalnum =  table.getTableLength(self.copydata.maps)
            local config = gamedata.config.expedition_map[tostring(totalnum - a1+43000)]
            -- ui.setLabelString(ccbDocumentControler.name,"第"..gameConfig.strings.bigNum[totalnum - a1].."关："..config.name,12)
            ui.setLabelString(ccbDocumentControler.name,gameConfig.strings:lvNum(totalnum-a1,config.name),121)
            setSpriteFrameByName(ccbDocumentControler.bg, config.basemap.."_cell")

            if a1 == 0 and (self.copydata.maps[tostring(totalnum)].kill == -1) then
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

            if ccbDocumentControler.t_power_n then
                if gamedata.config.expedition2 and gamedata.config.expedition2[tostring(totalnum - a1+43000)] and gamedata.config.expedition2[tostring(totalnum - a1+43000)].power then
                    ccbDocumentControler.t_power_n:setVisible(true)
                    --ui.setLabelString(ccbDocumentControler.t_power,gameConfig.strings:tjZdl(gamedata.config.expedition2[tostring(totalnum - a1+43000)].power),14)
                    ccbDocumentControler.t_power_n:setString(gameConfig.strings:tjZdl(gamedata.config.expedition2[tostring(totalnum - a1+43000)].power))
                else
                    ccbDocumentControler.t_power_n:setVisible(false)
                end
            end

            ccbDocumentControler.i_button:setTouchPriority(-103)
            ccbDocumentControler.i_button:setSwallowsTouch(true)
            ccbDocumentControler.i_button:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end

                local i=1
                local reward = {}
                while  config["drop"..i] and config["drop"..i] ~= 0 do
                    reward[tostring(table.getTableLength(reward)+1)] = {cid = config["drop"..i],num = config["number"..i] or 1 ,probability = config["drop"..i.."prob"]}
                    i = i+1
                end

                local datatmp = ui.CheckHuodongByParam(7)
                -- local datatmp = ui.CheckHuodongByParam(1)
                local timesnum = ui.GetHuodongModulus(7)
                if datatmp then
                    for k,v in pairs(reward) do
                        v.num = v.num * tonumber(timesnum)
                    end
                end

                --gameWindows:openWindow("getStaff",{data = reward,type = "可能掉落"},nil)
                gameWindows:openWindow("getStaff",{data = reward, type = gameConfig.strings:string_common("friendcopy",4), isrewarddouble = datatmp},nil)

            end, CCControlEventTouchUpInside)

            if self.listTableView then
                cellCCB:setPosition(self.listCellSize.x/2, self.listCellSize.y/2-10)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.copydata.maps)
        elseif fn == "cellTouched" then
            if self.copydata.kill >0 then
                local totalnum =  table.getTableLength(self.copydata.maps)
                self.selecteMap = totalnum - a1:getIdx()+43000
                UIRequest({type = 13201})

                if guide.controller then
                    guide.controller:UIComplete(8045)
                end
            else
                shortFriendCopykill()
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

function friendcopy.attack(self,help)
    gameTouch:clickprofbytime(0.5)
    UIRequest({type = 1324,map = self.selecteMap, help = help.rid})
end

function friendcopy.reloadList(self,data)
    self.copydata = data.friendcopy

    ui.setLabelString(self.rootItems.rest,self.copydata.kill,18)
    if not self.listTableView then
        self:creatList()
    else
        self.listTableView:reloadData()
        self.listTableView:setLuaContentOffset(0,  self.rootItems.listScroll:getContentSize().height - self.listCellSize.y*table.getTableLength(self.copydata.maps) )
    end

end

function friendcopy.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 1323})
    end
end

return friendcopy