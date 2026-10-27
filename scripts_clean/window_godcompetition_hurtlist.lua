--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local godCompetition_hurtlist = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    --伤害排行
    myServiceListTableView = nil,
    allServiceListTableView = nil,
    sevicepages = {"myservice","allservice",},
    sevicename = {"本服伤害排名","跨服伤害排名",},
    sevicechoosepage = "allservice",



    rewardshowListTableView = nil,


}

function godCompetition_hurtlist.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.params = data

    if data.index == "hurtlist" then --伤害排行
        self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_damgerank.ccbi", nil, true, "tc_damgerank")
        gameTouch:clickprofbytime(0.5)
        self.sevicechoosepage = "myservice"
        UIRequest({type = 8259})
    elseif data.index == "rewardshow" then 
        self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_jiangli.ccbi", nil, true, "tc_jiangli")
        self:rewardshowreload()
    end
    
    self:initActivityScroll()

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("godCompetition_hurtlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)
    
    self.root:addChild(self.rootNode)
    return self.root
end

function godCompetition_hurtlist.initActivityScroll(self)
    local function touchBegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    local function touchEnd(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        else
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("begin", "battleSeasonReward", touchBegin)
    gameTouch:rigistFunc("end", "battleSeasonReward", touchEnd)
end


------------------------------- 奖励预览 ------------------------------------------
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function godCompetition_hurtlist.rewardshowreload(self)
    printT(self.data,"rewardshowreload===")
    self.rootItems.rankText:setString("排名")
    self.rootItems.rewardText:setString("奖励内容")
    ui.setLabelString(self.rootItems.descText,"每轮比赛结束后发送对应奖励",18)

    self.data = self.params.shenbang and gamedata.config.apex_boss_rewards or gamedata.config.apex_battle_rankreward

    if self.rewardshowListTableView == nil then
        self:createRewardshowList()
    else
        self.rewardshowListTableView:reloadData()
    end
end

-- 奖励预览列表
function godCompetition_hurtlist.createRewardshowList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(990, 158)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_jiangli", nil, true, "cell_jiangli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data[tostring(a1+1)]


            -- local spritestring = gamedata.config.cross_battle_interval[tostring(celldata.ranktype)]["icon"] or "alpha"
            -- setSpriteFrameByName(ccbDocumentControler.icon, spritestring)
            

            ccbDocumentControler.rank:setString(celldata.name)
            local tempdata = ui.getIDandNUMs(celldata.win_reward)

            for i=1,6 do
                if ccbDocumentControler["ccb"..i] then
                    if tempdata[i] then
                        local _key_Ex = ""
                        if i == 1 then
                            _key_Ex = ""
                        else
                            _key_Ex = "_"..(i-1)
                        end
                        ccbDocumentControler["ccb"..i]:setVisible(true)
                        ui.setNewIcon(ccbDocumentControler,tempdata[i],i-1)

                        ccbDocumentControler["i_button".._key_Ex]:addHandleOfControlEvent(function()
                            if not self.isscrolltouched then return true end
                            if gameTouch.isScrollling then return true end

                            ui.setPopwindowByCid(tempdata[i].cid)
                        end, CCControlEventTouchUpInside)
                        ccbDocumentControler["i_button".._key_Ex]:setSwallowsTouch(true)
                        ccbDocumentControler["i_button".._key_Ex]:setTouchPriority(self.touchPriority-2)
                    else
                        ccbDocumentControler["ccb"..i]:setVisible(false)
                    end
                end
            end
            
            cellCCB:setPosition(990/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.rewardshowListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.rewardshownode:getContentSize().width,
        viewheight = self.rootItems.rewardshownode:getContentSize().height,
        dire = 1
    })
    self.rootItems.rewardshownode:addChild(self.rewardshowListTableView)
    self.rewardshowListTableView:setTouchPriority(self.touchPriority)
end
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
------------------------------- 奖励预览 ------------------------------------------


------------------------------- 封神赛伤害排名 ------------------------------------------
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
function godCompetition_hurtlist.serviceScoreReload(self,data)
    self.data = data

    printT(self.data,"serviceScoreReload===")
    self.rootItems.rankText:setString("排名")
    self.rootItems.playernameText:setString("玩家名称")
    self.rootItems.servicenameText:setString("所在服务器")
    self.rootItems.scoreText:setString("伤害值")


    for i,v in ipairs(self.sevicepages) do
        print("page===",i,v)
        self.rootItems[v.."Btn"]:addHandleOfControlEvent(function()
            print("page===222",i,v)
            self:shiftServiceScoreNode(v)
        end, CCControlEventTouchUpInside)
        self.rootItems[v.."Btn"]:setSwallowsTouch(true)
        self.rootItems[v.."Btn"]:setTouchPriority(self.touchPriority-1)
    end
    print("sevicechoosepage==",self.sevicechoosepage)
    self:shiftServiceScoreNode(self.sevicechoosepage)

end

function godCompetition_hurtlist.setServiceScorePageSprite( self,choose )

    for i,v in ipairs(self.sevicepages) do
        print("setpage===",choose,v)
        if v == choose then
            self.rootItems[v.."_bg"]:setVisible(true)
        else
            self.rootItems[v.."_bg"]:setVisible(false)
        end
    end

end

function godCompetition_hurtlist.shiftServiceScoreNode(self,type)
    print("i...am..shiftServiceScoreNode",type)

    self.sevicechoosepage = type
    self:setServiceScorePageSprite(self.sevicechoosepage)
    
    for k,v in ipairs(self.sevicepages) do
        if v == self.sevicechoosepage then
            self.rootItems[v.."node"]:setPositionX(50)
            self.rootItems[v.."node"]:setVisible(true)
        else
            self.rootItems[v.."node"]:setPositionX(9999)
            self.rootItems[v.."node"]:setVisible(false)
        end
    end
    if type == "myservice" then
        print("myservice...is....")
        self:myserviceReload()
    elseif type == "allservice" then
        print("allservice...is....")
        self:allserviceReload()
    else
        print("other===")
    end
end
    --todo
function godCompetition_hurtlist.myserviceReload(self)
    self.rootItems.scoreText:setString("伤害值")
    self:setmyrank(1)

    if self.myServiceListTableView == nil then
        self:createMyServiceList()
    else
        self.myServiceListTableView:reloadData()
    end
end


function godCompetition_hurtlist.allserviceReload(self)
    self.rootItems.scoreText:setString("伤害值")
    self:setmyrank(2)

    if self.allServiceListTableView == nil then
        self:createAllServiceList()
    else
        self.allServiceListTableView:reloadData()
    end
end

function godCompetition_hurtlist.setmyrank(self,list_type)
   local mydata = {}
   local defaultdata = {damage= 0, rid=0,serviceid = 0,name = "",rank= 0}
    -- temp.damage = pnData[1] and pnData[1].i or 0
    -- temp.rid = pnData[2] and pnData[2].i or 0
    -- temp.serviceid = pnData[3] and pnData[3].s or ""
    -- temp.name = pnData[4] and pnData[4].s or ""
    -- temp.rank = pnData[5] and pnData[5].i or 0

    if list_type and list_type == 1 then --本服务我的排行
        mydata= self.data.newdata.mydata or {}
    elseif list_type and list_type == 2 then --跨服我的排行
        mydata= self.data.serverdata.mydata or {}
    end
    if table.getTableLength(mydata) < 1 then
        mydata = defaultdata
    end    
    --
    if mydata.rank == 0 then
        self.rootItems.c_rank_top:setVisible(false)
        self.rootItems.c_rank:setVisible(true)
        self.rootItems.c_rank:setString("未上榜")
    elseif mydata.rank <= 3 then
        self.rootItems.c_rank_top:setVisible(true)
        self.rootItems.c_rank:setVisible(false)
        local spritestring = "b_n_zxt_"..mydata.rank
        setSpriteFrameByName(self.rootItems.c_rank_top, spritestring)
    else
        self.rootItems.c_rank_top:setVisible(false)
        self.rootItems.c_rank:setVisible(true)
        self.rootItems.c_rank:setString(mydata.rank)
    end

    self.rootItems.c_name:setString(mydata.name)
    self.rootItems.c_servicename:setString(mydata.serviceid)
    self.rootItems.c_point:setString(mydata.damage)

end

-- 封神赛伤害排名（本服
function godCompetition_hurtlist.createMyServiceList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(980, 100)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("fengshensai/cell_damgerank", nil, true, "cell_damgerank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.newdata.alldata[tostring(a1+1)]

            if (a1+1) <= 3 then
                ccbDocumentControler.c_rank_top:setVisible(true)
                ccbDocumentControler.c_rank:setVisible(false)

                local spritestring = "b_n_zxt_"..(a1+1)
                setSpriteFrameByName(ccbDocumentControler.c_rank_top, spritestring)
            else
               ccbDocumentControler.c_rank_top:setVisible(false) 
               ccbDocumentControler.c_rank:setVisible(true)

               ccbDocumentControler.c_rank:setString(a1+1)
            end

            ccbDocumentControler.c_name:setString(celldata.name)
            ccbDocumentControler.c_servicename:setString(celldata.serviceid)
           
            ccbDocumentControler.c_point:setString(celldata.damage)

            cellCCB:setPosition(980/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.newdata.alldata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.myServiceListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.myservicenode:getContentSize().width,
        viewheight = self.rootItems.myservicenode:getContentSize().height,
        dire = 1
    })
    self.rootItems.myservicenode:addChild(self.myServiceListTableView)
    self.myServiceListTableView:setTouchPriority(self.touchPriority)
end



-- 封神赛伤害排名（全服
function godCompetition_hurtlist.createAllServiceList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(980, 100)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("fengshensai/cell_damgerank", nil, true, "cell_damgerank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.serverdata.alldata[tostring(a1+1)]

            if celldata.rank == 0 then
                ccbDocumentControler.c_rank_top:setVisible(false) 
                ccbDocumentControler.c_rank:setVisible(true)

                ccbDocumentControler.c_rank:setString("未上榜")
            elseif celldata.rank <= 3 then
                ccbDocumentControler.c_rank_top:setVisible(true)
                ccbDocumentControler.c_rank:setVisible(false)

                local spritestring = "b_n_zxt_"..celldata.rank
                setSpriteFrameByName(ccbDocumentControler.c_rank_top, spritestring)
            else
               ccbDocumentControler.c_rank_top:setVisible(false) 
               ccbDocumentControler.c_rank:setVisible(true)

               ccbDocumentControler.c_rank:setString(celldata.rank)
            end

            ccbDocumentControler.c_name:setString(celldata.name)
            ccbDocumentControler.c_servicename:setString(celldata.serviceid)
            ccbDocumentControler.c_point:setString(celldata.damage)
            
            
            cellCCB:setPosition(980/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.serverdata.alldata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.allServiceListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.allservicenode:getContentSize().width,
        viewheight = self.rootItems.allservicenode:getContentSize().height,
        dire = 1
    })
    self.rootItems.allservicenode:addChild(self.allServiceListTableView)
    self.allServiceListTableView:setTouchPriority(self.touchPriority)
end
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
------------------------------- 封神赛伤害排名面板 ------------------------------------------





function godCompetition_hurtlist.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.worldwarstatus = 0


    self.myServiceListTableView = nil
    self.allServiceListTableView = nil

   
    self.rewardshowListTableView = nil



    self.sevicechoosepage = "allservice"
    self.data = {}
end

return godCompetition_hurtlist