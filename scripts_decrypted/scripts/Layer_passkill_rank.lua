--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local passkillrank = {

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"score","reward",} ,
    pagename = {"积分排名","排名奖励"},
    selectpage = "score",
    RankListTableView = nil,
    RewardListTableView = nil,
    rewardconfig = {},
    rankdata = {},
    mydata = {},
    isscrolltouched = false,
}


function passkillrank.shiftPage(self,type)


    if type and self.selectpage == type then
        return
    end

    if type then
        self.selectpage = type
    end


    print("i...am..shiftPage",type)

    for k,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            self.rootItems[v.."Node"]:setPositionX(0)
            self.rootItems[v.."Node"]:setVisible(true)
        else
            self.rootItems[v.."Node"]:setPositionX(9999)
            self.rootItems[v.."Node"]:setVisible(false)
        end
    end

    if self.selectpage == "score" then 
        -- self:reloadRankData()
        UIRequest({type = 3821})
    elseif self.selectpage == "reward" then
        self:reloadRewardData()
    end

end


function passkillrank.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("passkill/passkill_rank", nil, true, "passkill_rank")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    -- scoreNode
    -- rewardNode

    self.rootItems.scoreNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-380))
    self.rootItems.rewardNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-380))


    self:shiftPage()



    -- 规则说明
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(-105)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        print("backBtn===")
        GameScene:shiftLayer("passkillmain","up")
    end, CCControlEventTouchUpInside)


    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","passkillrank_list",touchbegin)

    local function touchend(pos)
        if ui.isTouched(self.rootItems.scoreNode,pos.x,pos.y) or ui.isTouched(self.rootItems.rewardNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","passkillrank_list",touchend)
    --

    -- timerLabel
    ui.setLabelString(self.rootItems.timerLabel,nil,26)

    self:updatetimeFunc()
end

function passkillrank.updatetimeFunc( self )
    local nowtime = os.date("*t", gamedata:time())
    local remaintime = 0
    if nowtime.wday == 1 then
        remaintime = 1*24*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec
    else
        remaintime = 8*24*3600-(nowtime.wday-1)*3600*24 - nowtime.hour*3600-nowtime.min*60-nowtime.sec
    end

    gameTimer:rigistTime("passkill_ranktime", remaintime)
    gameTimer:rigistTimeFunc("passkill_ranktime",function()
    
        if gameTimer.times["passkill_ranktime"] >= 0 then
            if nowtime.wday == 1 then
                ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeText(gameTimer.times["passkill_ranktime"],"hour"),26)
            else
                ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeDayText(gameTimer.times["passkill_ranktime"],"day"),26)
            end
        end
        if gameTimer.times["passkill_ranktime"] == 0 then
            -- print("passkill_ranktime===",0)
            -- UIRequest({type=3820})
            gameTimer:UnrigistTimeFunc("passkill_ranktime")
            self:updatetimeFunc()
        end
    end)
    
end


function passkillrank.reloadRankData(self,rankdata,mydata)
    self.rankdata = {}
    if rankdata then
        self.rankdata = rankdata
    end
    self.mydata = {}
    if mydata then
        self.mydata = mydata
    end

    if self.RankListTableView == nil then

        self:createRankList()
    else
        -- if self.RankListTableView:getLuaContentOffsetY() < self.rootItems.scoreNode:getContentSize().height - table.getTableLength(self.rankdata)*205 then
            self.RankListTableView:setLuaContentOffset(0, self.rootItems.scoreNode:getContentSize().height - table.getTableLength(self.rankdata)*205)
        -- end
        self.RankListTableView:reloadData()
    end
    
    self:setMyRankData()
end



function passkillrank.setMyRankData(self)
    local myranknum = 0
    for k,v in pairs(self.rankdata) do
        if v.rid == self.mydata.rid then
            myranknum = tonumber(k) or 0
            break
        end
    end

    if myranknum == 0 then
        self.rootItems.norankLabel:setVisible(true)
        self.rootItems.rankLabel:setVisible(false)
        self.rootItems.rankspriteLabel:setVisible(false)
    elseif myranknum <= 3 then
        self.rootItems.norankLabel:setVisible(false)
        self.rootItems.rankLabel:setVisible(false)
        self.rootItems.rankspriteLabel:setVisible(true)

        local spritename = "b_n_zxt_"..myranknum..".png"
        setSpriteFrameByName(self.rootItems.rankspriteLabel,spritename)
    else
        self.rootItems.norankLabel:setVisible(false)
        self.rootItems.rankLabel:setVisible(true)
        self.rootItems.rankspriteLabel:setVisible(false)

        self.rootItems.rankLabel:setString(myranknum)
    end
    ui.setLabelString(self.rootItems.mynameLabel,self.mydata.name,14)
    ui.setLabelString(self.rootItems.myscoreLabel,self.mydata.score,21)
    self.rootItems.mypowerLabel:setString(self.mydata.power)
    
end

function passkillrank.reloadRewardData(self)
    print("reloadRewardData==")
    self.rewardconfig = {}
    for k,v in pairs(gamedata.config.through_rewards) do
        if tonumber(v.rank) <= 50 then
            table.insert(self.rewardconfig,v)
        end
        
    end
    local function funcSort( a,b )
        return a.rank < b.rank
    end
    table.sort( self.rewardconfig,funcSort)


    -- printT(self.rewardconfig,"rewardconfig===")

    if self.RewardListTableView == nil then

        self:createRewardList()
    else
        self.RewardListTableView:reloadData()
    end

end



function passkillrank.createRankList(self)
    print("createRankList==")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1040, 205)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("passkill/cell_passkillrank1", nil, true, "cell_passkillrank1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.ListTableView,cellCCB,920/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            -- print("createRankListitem:",a1)
            -- printT(self.mofudata[tostring(a1+1)])
            local celldata = self.rankdata[tostring(a1+1)]
            print("cellitem===",a1+1)
            
            ccbDocumentControler.rankSpriteLabel:setVisible(false)
            ccbDocumentControler.ranknumLabel:setVisible(true)
            if (a1+1) <= 3 then
                ccbDocumentControler.rankSpriteLabel:setVisible(true)
                local spritename = "b_n_zxt_"..(a1+1)..".png"
                setSpriteFrameByName(ccbDocumentControler.rankSpriteLabel,spritename)
            end

            ccbDocumentControler.ranknumLabel:setString(a1+1)

            -- ccbDocumentControler.vip:setString(celldata.vip)
            -- local vipstring = "b_n_vip_"..(celldata.vip or 0)..".png"
            -- setSpriteFrameByName(ccbDocumentControler.vip,vipstring)
            -- ccbDocumentControler.vip:setVisible(false)

            ccbDocumentControler.name:setString(celldata.name)
            ui.setLabelString(ccbDocumentControler.name,celldata.name,18)
            ui.setLabelString(ccbDocumentControler.killscoreLabel,celldata.params["1"].i,21)
            ccbDocumentControler.powerLabel:setString(celldata.param)


            ui.setNewIcon(ccbDocumentControler,{cid=celldata.profile,title = celldata.title,iconBox = celldata.iconBox})

            -- ui.setLabelString(ccbDocumentControler.nameLabel,celldata.temp.name,((celldata.temp.quality and celldata.temp.quality ~= 0) and celldata.temp.quality or 1)*2-1)
            
            -- ui.setNewIcon(ccbDocumentControler,{cid=celldata.cid})

            
            -- ui.setLabelString(ccbDocumentControler.gotolevelText, nil, 18)
            -- ccbDocumentControler.gotolevelBtn:setTouchPriority(-103)
            -- ccbDocumentControler.gotolevelBtn:addHandleOfControlEvent(function()
            --     -- print("i...am ...gotolevelup")
                


            -- end, CCControlEventTouchUpInside)
            

            cellCCB:setPosition(1080/2,0)

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            -- print("numberOfCells===",table.getTableLength(self.rankdata))
            r = table.getTableLength(self.rankdata)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.RankListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.scoreNode:getContentSize().width,
        viewheight = self.rootItems.scoreNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.scoreNode:addChild(self.RankListTableView)
    self.RankListTableView:setTouchPriority(-101)
end

function passkillrank.createRewardList(self)
    print("createRewardList==")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1040, 205)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("passkill/cell_passkillrank3", nil, true, "cell_passkillrank1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.ListTableView,cellCCB,920/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            -- print("createRankListitem:",a1)
            -- printT(self.mofudata[tostring(a1+1)])
            local celldata = self.rewardconfig[tonumber(a1+1)]
            print("cellitem===",a1+1)
            
            ccbDocumentControler.rewardrankSpriteLabel:setVisible(false)
            ccbDocumentControler.rewardranknumLabel:setVisible(true)
            ccbDocumentControler.rewardranksmallnumLabel:setVisible(false)

            if (a1+1) <= 3 then
                ccbDocumentControler.rewardrankSpriteLabel:setVisible(true)
                ccbDocumentControler.rewardranknumLabel:setVisible(false)
                ccbDocumentControler.rewardranksmallnumLabel:setVisible(false)

                local spritename = "b_n_zxt_"..(a1+1)..".png"
                setSpriteFrameByName(ccbDocumentControler.rewardrankSpriteLabel,spritename)
            end

            local numString = celldata.rank
            ccbDocumentControler.rewardranknumLabel:setString(numString)

            if (a1+1) > 10 then
                ccbDocumentControler.rewardrankSpriteLabel:setVisible(false)
                ccbDocumentControler.rewardranknumLabel:setVisible(false)
                ccbDocumentControler.rewardranksmallnumLabel:setVisible(true)

                local celltempdata = self.rewardconfig[tonumber(a1)]
                numString = (celltempdata.rank+1).."~"..celldata.rank
                ccbDocumentControler.rewardranksmallnumLabel:setString(numString)
            end


            local rewarddata = ui.getIDandNUMs(celldata.week)

            if ccbDocumentControler.prop1 then
                for i = 1,5 do
                    if rewarddata[i] then
                        ccbDocumentControler["prop"..i]:setVisible(true)
                        ui.setNewIcon(ccbDocumentControler,rewarddata[i],i-1)
                        ccbDocumentControler["i_button"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(-103)
                        ccbDocumentControler["i_button"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                            if not self.isscrolltouched then return end
                            ui.setPopwindowByCid(rewarddata[i].cid)
                        end, CCControlEventTouchUpInside)
                    else
                        ccbDocumentControler["prop"..i]:setVisible(false)
                    end
                end
            end
            --ui.setLabelString(ccbDocumentControler.rewardkillText,nil,14)
            --ui.setLabelString(ccbDocumentControler.rewardkillLabel,rewarddata[2]["num"],21)

            --ui.setLabelString(ccbDocumentControler.rewardcoinText,nil,14)
            --ui.setLabelString(ccbDocumentControler.rewardcoinLabel,rewarddata[1]["num"],21)
            


            -- ui.setLabelString(ccbDocumentControler.nameLabel,celldata.temp.name,((celldata.temp.quality and celldata.temp.quality ~= 0) and celldata.temp.quality or 1)*2-1)
            
            -- ui.setNewIcon(ccbDocumentControler,{cid=celldata.cid})

            
            -- ui.setLabelString(ccbDocumentControler.gotolevelText, nil, 18)
            -- ccbDocumentControler.gotolevelBtn:setTouchPriority(-103)
            -- ccbDocumentControler.gotolevelBtn:addHandleOfControlEvent(function()
            --     -- print("i...am ...gotolevelup")
                


            -- end, CCControlEventTouchUpInside)
            

            cellCCB:setPosition(1080/2,0)

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            -- print("numberOfCells===",table.getTableLength(self.rewardconfig))
            r = table.getTableLength(self.rewardconfig)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.RewardListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.rewardNode:getContentSize().width,
        viewheight = self.rootItems.rewardNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.rewardNode:addChild(self.RewardListTableView)
    self.RewardListTableView:setTouchPriority(-101)
end

function passkillrank.clear(self)

    gameTouch:UnrigistFunc("begin","passkillrank_list")
    gameTouch:UnrigistFunc("end","passkillrank_list")

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil


    self.RankListTableView = nil
    self.RewardListTableView = nil

    gameTimer:UnrigistTimeFunc("passkill_ranktime")


    self.rewardconfig = {}
    self.rankdata = {}
    self.mydata = {}

    self.selectpage = "score"
end

return passkillrank
 @  