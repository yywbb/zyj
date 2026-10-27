--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 上午10:10
-- To change this template use File | Settings | File Templates.
--

local zhongshuRank = {
    rootNode = nil,
    rootItems = nil,
    rainScore = 0,
    rankData = nil
}

function zhongshuRank.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhongshu/zhongshu_rank", nil, true, "zhongshuRank")
    self.touchPriority = touchPriority
    self:initFixedString()
    self:setButtonFunc(callback)
    self.rainScore = data or 0
    self:shiftToPage(1,data)

    return self.rootNode
end

function zhongshuRank.setButtonFunc(self,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("zhongshuRank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.button1:addHandleOfControlEvent(function ()
        self:shiftToPage(1)
    end,CCControlEventTouchUpInside)
    self.rootItems.button1:setSwallowsTouch(true)
    self.rootItems.button1:setTouchPriority(self.touchPriority)

    self.rootItems.button2:addHandleOfControlEvent(function ()
        self:shiftToPage(2)
    end,CCControlEventTouchUpInside)
    self.rootItems.button2:setSwallowsTouch(true)
    self.rootItems.button2:setTouchPriority(self.touchPriority)

    self.rootItems.rankRefreshBtn:addHandleOfControlEvent(function ()
        UIRequest{type = 5331}
    end,CCControlEventTouchUpInside)
    self.rootItems.rankRefreshBtn:setSwallowsTouch(true)
    self.rootItems.rankRefreshBtn:setTouchPriority(self.touchPriority)
end

function zhongshuRank.shiftToPage(self,type,data)
    
    self.rootItems.button1:setTouchEnabled(type == 2)
    self.rootItems.button2:setTouchEnabled(type == 1)
    setSpriteFrameByName(self.rootItems["buttonsprite"..type], gameConfig.images.pageButtonON)
    setSpriteFrameByName(self.rootItems["buttonsprite"..(2 - type + 1)], gameConfig.images.pageButtonOFF)
    self.rootItems.rankAward:setVisible(type == 1)
    self.rootItems.rankNum:setVisible(type == 2)

    self.rootItems.rankAward:setPositionX(type == 1 and 0 or 9999)
    self.rootItems.rankNum:setPositionX(type == 2 and 0 or 9999)
    
    self:reload(type,data)
end

function zhongshuRank.setRandAward(self,data)
    --设置结束时间
    local des = ""
    if gamedata.config.activity_time["102"] and gamedata.config.activity_time["102"].extra_time then
        local year,mon,day,hour = ui.getDate(gamedata.config.activity_time["102"]["end"])
        local endt = os.time({year=tonumber(year), month=tonumber(mon),day=tonumber(day),hour=tonumber(hour),min=0,sec=0,isdst = false})
        local endtimediff = endt + tonumber(gamedata.config.activity_time["102"].extra_time - 1) * 86700

        local endtimd = os.date("*t",endtimediff)
        des = endtimd.month.."月"..endtimd.day.."日".."01时结算奖励"
    else
        local year,mon,day,hour = ui.getDate(gamedata.config.activity_time["102"]["end"])
        des = mon.."月"..day.."日"..hour.."时结算奖励"
    end

    self.rootItems.endTime:setString(des)

    if self.rootItems.ListTableView1 then
        return
    end
    local config = gamedata.config.zhongshu_list
    if not config then
        return
    end

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 200)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhongshu/cell_zhongshurank1", nil, true, "cell_zhongshurank1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            local currentConfig = config[tostring(a1 + 1)]
            local beforeR = config[tostring(a1)] and config[tostring(a1)].rank or 0
            if currentConfig.rank == beforeR + 1 then
                ccbDocumentControler.rankImg:setVisible(true)
                ccbDocumentControler.rankLabel:setVisible(false)
                setSpriteFrameByName(ccbDocumentControler.rankImg,"b_n_zxt_"..currentConfig.rank) 
            else
                ccbDocumentControler.rankImg:setVisible(false)
                ccbDocumentControler.rankLabel:setVisible(true)
                ccbDocumentControler.rankLabel:setString((beforeR + 1).."~"..currentConfig.rank)
            end
            
            local rewardData = ui.getIDandNUMs(currentConfig.reward)
            for i = 1,#rewardData do
                ccbDocumentControler["rewardItem"..i]:setVisible(true)
                ui.setNewIcon(ccbDocumentControler,rewardData[i],i - 1)

                local k_add = (i - 1 == 0) and "" or "_"..(i-1)
                ccbDocumentControler["i_button"..k_add]:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end  
                    ui.setPopwindowByCid(rewardData[i].cid)
                end, CCControlEventTouchUpInside)
                ccbDocumentControler["i_button"..k_add]:setTouchPriority(self.touchPriority)
            end
            for i = #rewardData + 1,4 do
                ccbDocumentControler["rewardItem"..i]:setVisible(false)
            end

            
            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(config)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
           
        end
        return r
    end)

    self.rootItems.ListTableView1 = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode1:getContentSize().width,
        viewheight = self.rootItems.listnode1:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode1:addChild(self.rootItems.ListTableView1)
    self.rootItems.ListTableView1:setTouchPriority(self.touchPriority)
end

function zhongshuRank.setRand(self,data)
    self.rankData = data
    --
    local showStr = gameConfig.strings:string_common("fixedString","activity",25)
    -- local showStr = "总祝福积分达到%d可进入排行榜"
    local showScore = tonumber(gamedata.config.global_kv.zhongshu_rank_up.value)
    showStr = string.format(showStr,showScore)
    self.rootItems.scoreLimit:setString(showStr)
    --
    local myrank = data.myrank
    local players = {}
    for k,v in pairs(data.players) do
         v.rank = tonumber(k)
         table.insert(players,v)
        if v.rid == GameScene.roleinfo.id then
            myrank = tonumber(k)
        end
    end
    local sortBy = function(a,b) 
        if a.rank == b.rank then
            return a.rid < b.rid
        end
        return a.rank < b.rank 
    end
    table.sort(players, sortBy)
    --
    if myrank > 0 then
        self.rootItems.rankImg:setVisible(myrank < 4)
        self.rootItems.rankLabel:setVisible(myrank > 3)
        if myrank > 3 then
            self.rootItems.rankLabel:setString(tostring(myrank))
        else
            setSpriteFrameByName(self.rootItems.rankImg,"b_n_zxt_"..myrank) 
        end
    else
        self.rootItems.rankImg:setVisible(false)
        self.rootItems.rankLabel:setString("未上榜")
    end
    self.rootItems.playerName:setString(GameScene.roleinfo.name)
    self.rootItems.rainScore:setString(tostring(self.rainScore))
    --

    if self.rootItems.ListTableView2 then
        self.rootItems.ListTableView2:reloadData()
        return
    end   

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 100)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhongshu/cell_zhongshurank2", nil, true, "cell_zhongshurank2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            
            ccbDocumentControler.playerName:setString(players[a1+1].name or "")
            ccbDocumentControler.rainScore:setString(players[a1+1]["params"]["1"].i or "")
            if players[a1+1].rank > 3 then
                ccbDocumentControler.rankLabel:setString(tostring(players[a1+1].rank))
            else
                setSpriteFrameByName(ccbDocumentControler.rankImg,"b_n_zxt_"..players[a1+1].rank) 
            end
            ccbDocumentControler.rankImg:setVisible(players[a1+1].rank < 4)
            ccbDocumentControler.rankLabel:setVisible(players[a1+1].rank > 3)
            
            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = #players
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
           
        end
        return r
    end)

    self.rootItems.ListTableView2 = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode2:getContentSize().width,
        viewheight = self.rootItems.listnode2:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode2:addChild(self.rootItems.ListTableView2)
    self.rootItems.ListTableView2:setTouchPriority(self.touchPriority)
end

function zhongshuRank.reload(self,type,data)
    if type == 1 then
        self:setRandAward(data)
    else
        if not data and not self.rankData then
            UIRequest{type = 5331}
            self.rootItems.selfRankCell:setVisible(false)
        else
            self.rootItems.selfRankCell:setVisible(true)
            if data then
                self:setRand(data)
            end
        end
    end
end

function zhongshuRank.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.rankData = nil

    if self.callback then
        self.callback()
    end
end

function zhongshuRank.initFixedString(self)
    self.rootItems.titleL:setString(gameConfig.strings:string_common("fixedString","rank",2))
    self.rootItems.buttontext1:setString(gameConfig.strings:string_common("guild_boss",13))
    self.rootItems.buttontext2:setString(gameConfig.strings:string_common("fixedString","rank",3))
    self.rootItems.rankL:setString(gameConfig.strings:string_common("fixedString","rank",4))
    self.rootItems.awardL:setString(gameConfig.strings:string_common("mazeReward",1))
    self.rootItems.rank1L:setString(gameConfig.strings:string_common("fixedString","rank",4))
    self.rootItems.playerNameL:setString(gameConfig.strings:string_common("fixedString","servicewar",53))
    self.rootItems.rainScoreL:setString(gameConfig.strings:string_common("nightclub",43))
    -- self.rootItems.rainScoreL:setString("祝福积分")
end



return zhongshuRank �-  