--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local goddownrank = {

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"reward","score",} ,
    -- pagename = {"排名奖励","积分排名",},
    pagename = {gameConfig.strings:string_common("goddownrank",1),gameConfig.strings:string_common("goddownrank",2),},

    selectpage = "reward",
    RankListTableView = nil,
    RewardListTableView = nil,
    rewardconfig = {},
    rankdata = {},
    mydata = {},
    isscrolltouched = false,

    cpnum = 0,
    cpday = 0,

}


--按钮高亮状态的显示
function  goddownrank.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.rootItems["btnspr"..km], gameConfig.images.pageButtonON)
            --self.rootItems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(self.rootItems["btnspr"..km], gameConfig.images.pageButtonOFF)
            --self.rootItems["buttonnode"..km]:setZOrder(0)
        end
    end
end

function goddownrank.shiftPage(self,type)
    if type and self.selectpage == type then
        return
    end

    if type then
        self.selectpage = type
    end

    self:shiftlayerpage(self.selectpage)

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
        self:reloadRankData()
    elseif self.selectpage == "reward" then
        print("rewardlist===")
        self:reloadRewardData()
    end

end


function goddownrank.init(self,size)
    self.contentsize = size
    self.show = true
    self.rootNode,self.rootItems = CCBReaderLoad("activitypig/activitypig_rank", nil, true, "activitypig_rank")
    -- self.rootNode:setPosition(0,0)
    -- parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)
    self.rootItems.showNode:setPositionY((self.contentsize.y-180-200-160)/2+160)


    --显示页签得按钮
    for k=1,2 do
        self.rootItems["plantitle"..k]:setString(self.pagename[k])

        self.rootItems["planbutton"..k]:setSwallowsTouch(true)
        self.rootItems["planbutton"..k]:setTouchPriority(-102)
        self.rootItems["planbutton"..k]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            self:shiftPage(self.pageconfig[k])
        end,CCControlEventTouchUpInside)
    end


    -- 规则说明
    -- self.rootItems.gotoText:setString("八戒美梦")
    self.rootItems.gotoText:setString(gameConfig.strings:string_common("goddownrank",3))

    self.rootItems.gotoBtn:setSwallowsTouch(true)
    self.rootItems.gotoBtn:setTouchPriority(-105)
    self.rootItems.gotoBtn:addHandleOfControlEvent(function()
        print("gotoBtn===")
        if gameTouch.isScrollling then return end
        GameScene:shiftLayerById(313)
    end, CCControlEventTouchUpInside)


    -- self.rootItems.activitytimeText:setString("活动截止时间")
    -- self.rootItems.titlenameLabel:setString("八戒美梦排行榜")
    self.rootItems.activitytimeText:setString(gameConfig.strings:string_common("goddownrank",4))
    self.rootItems.titlenameLabel:setString(gameConfig.strings:string_common("goddownrank",5))


    local globalconfig = gamedata.config.global_kv
    -- local needscorestring = "总好感度需要达到"..globalconfig.goddown_rank_up.value.."才能进入排行榜"
    local needscorestring = gameConfig.strings:string_common("goddownrank",6)..globalconfig.goddown_rank_up.value..gameConfig.strings:string_common("goddownrank",7)
    ui.setLabelString(self.rootItems.needdescLabel,needscorestring,14)


    self.rootItems.ranknumText:setString(gameConfig.strings:string_common("goddownrank",8))
    self.rootItems.rankScoreText:setString(gameConfig.strings:string_common("goddownrank",9))
    self.rootItems.ranknameText:setString(gameConfig.strings:string_common("goddownrank",10))

    self.rootItems.rewardranknumText:setString(gameConfig.strings:string_common("goddownrank",8))
    self.rootItems.rewardrewardText:setString(gameConfig.strings:string_common("goddownrank",11))

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","activitygoddownrank",touchbegin)

    local function touchend(pos)
        if self.rootItems.rewardListNode and ui.isTouched(self.rootItems.rewardListNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","activitygoddownrank",touchend)
    --

    return self.rootNode
    -- self:updatetimeFunc()
end



function goddownrank.reloadData(self,data)
    if not self.show then return end

    self.cpnum = data and data.cpnum or 0
    self.cpday = data and data.cpday or 0

    self.rootItems.activitytimeLabel2:setString("")
    --
    local endString = ""
    if gamedata.config.activity_time["83"]["open_type"] and gamedata.config.activity_time["83"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        local timediff = nowtime + 86400*(gamedata.config.activity_time["83"]["continued_time"..((self.cpnum == 1) and ("_1") or "")]-self.cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        local endtab = os.date("*t", timediff-2)
        endString = endtab.month.."月"..endtab.day.."日24时"
    elseif gamedata.config.activity_time["83"]["open_type"] and gamedata.config.activity_time["83"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = 0
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["83"]["continued_time"]+(gamedata.config.activity_time["83"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["83"]["continued_time"]+(gamedata.config.activity_time["83"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        local endtab = os.date("*t", timediff-2)
        --endString = endtab.year..gameConfig.strings:string_common("goddownrank",13)..endtab.month..gameConfig.strings:string_common("goddownrank",14)..endtab.day..gameConfig.strings:string_common("goddownrank",15)
        endString = endtab.month.."月"..endtab.day.."日24时"
    elseif gamedata.config.activity_time["83"]["end"] and gamedata.config.activity_time["83"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["83"]["end"])
        endString = year.."."..month.."."..day
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 2
            local endtab = os.date("*t",endt)
            --endString = endtab.year.."."..endtab.month.."."..endtab.day
            endString = endtab.month.."月"..endtab.day.."日24时"
        end
    end
    self.rootItems.activitytimeLabel1:setString(endString)
    --


    self.rankdata = {}
    if data and data.rankdata then
        self.rankdata = data.rankdata
    end
    self.mydata = 0
    if data and data.mydata then
        self.mydata = data.mydata
    end

    self:shiftPage()
end


function goddownrank.reloadRankData(self)


    self.rootItems["rankRefreshBtn"]:setSwallowsTouch(true)
    self.rootItems["rankRefreshBtn"]:setTouchPriority(-102)
    self.rootItems["rankRefreshBtn"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        UIRequest({type = 5017})
    end,CCControlEventTouchUpInside)

    if self.RankListTableView == nil then

        self:createRankList()
    else
        -- if self.RankListTableView:getLuaContentOffsetY() < self.rootItems.scoreListNode:getContentSize().height - table.getTableLength(self.rankdata)*205 then
        self.RankListTableView:setLuaContentOffset(0, self.rootItems.scoreListNode:getContentSize().height - table.getTableLength(self.rankdata)*100)
        -- end
        self.RankListTableView:reloadData()
    end

    self:setMyRankData()
end



function goddownrank.setMyRankData(self)
    self.rootItems.myNode:setVisible(true)
    self.rootItems.otherNode:setVisible(false)


    local myranknum = 0
    for k,v in pairs(self.rankdata) do
        if v.rid == GameScene.roleinfo.id then
            myranknum = tonumber(k) or 0
            break
        end
    end
    printT(GameScene.roleinfo,"GameScene.roleinfo===")

    if myranknum == 0 then
        self.rootItems.myranknumLabel:setVisible(true)
        self.rootItems.myrankSpriteLabel:setVisible(false)

        -- ui.setLabelString(self.rootItems.myranknumLabel,"未上榜",14)
        ui.setLabelString(self.rootItems.myranknumLabel,gameConfig.strings:string_common("goddownrank",12),14)

    elseif myranknum <= 3 then
        self.rootItems.myranknumLabel:setVisible(false)
        self.rootItems.myrankSpriteLabel:setVisible(true)

        local spritename = "b_n_zxt_"..myranknum..".png"
        setSpriteFrameByName(self.rootItems.myrankSpriteLabel,spritename)
    else
        self.rootItems.myranknumLabel:setVisible(true)
        self.rootItems.myrankSpriteLabel:setVisible(false)
        --self.rootItems.myranknumLabel:setString(myranknum)
        ui.setLabelString(self.rootItems.myranknumLabel,myranknum,14)
    end
    ui.setLabelString(self.rootItems.myname,GameScene.roleinfo.name,14)
    ui.setLabelString(self.rootItems.mykillscoreLabel,self.mydata,14)

end

function goddownrank.reloadRewardData(self)
    print("reloadRewardData==")    --todo
    local templeconfig = gamedata.config.activity_time

    local nowtime = gamedata:time()
    local temp = os.date("*t", nowtime)
    local timediff = nowtime + 86400*(gamedata.config.activity_time["81"]["continued_time"..((self.cpnum == 1) and ("_1") or "")]-self.cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    local endtab = os.date("*t", timediff-2)
    local timestring = endtab.month.."月"..endtab.day.."日24时"..gameConfig.strings:string_common("goddownrank",16)

    print("timestring==",timestring)
    self.rootItems.rewardTimeDesc:setString(timestring)


    self.rewardconfig = {}
    for k,v in pairs(gamedata.config["goddown_rank"..(self.cpnum > 0 and ("_"..self.cpnum) or "")]) do
        -- if tonumber(v.rank) <= 50 then
        table.insert(self.rewardconfig,v)
        -- end

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



function goddownrank.createRankList(self)
    print("createRankList==")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(940, 100)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activitypig/cell_pigrank", nil, true, "cell_goddownrank1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.ListTableView,cellCCB,920/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            ccbDocumentControler.myNode:setVisible(false)
            ccbDocumentControler.otherNode:setVisible(true)

            -- print("createRankListitem:",a1)
            -- printT(self.mofudata[tostring(a1+1)])
            local celldata = self.rankdata[tostring(a1+1)]
            print("cellitem===",a1+1)
            printT(celldata,"celldata===")

            ccbDocumentControler.rankSpriteLabel:setVisible(false)
            ccbDocumentControler.ranknumLabel:setVisible(true)
            if (a1+1) <= 3 then
                ccbDocumentControler.rankSpriteLabel:setVisible(true)
                local spritename = "b_n_zxt_"..(a1+1)..".png"
                setSpriteFrameByName(ccbDocumentControler.rankSpriteLabel,spritename)
            end

            ccbDocumentControler.ranknumLabel:setString(a1+1)

            ccbDocumentControler.name:setString(celldata.name)
            ccbDocumentControler.killscoreLabel:setString(celldata.params["1"].i)


            cellCCB:setPosition(940/2,0)

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
        viewwidth = self.rootItems.scoreListNode:getContentSize().width,
        viewheight = self.rootItems.scoreListNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.scoreListNode:addChild(self.RankListTableView)
    self.RankListTableView:setTouchPriority(-101)
end

function goddownrank.createRewardList(self)
    print("createRewardList==")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(980, 150)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activitypig/cell_pigjiangli", nil, true, "cell_pigjiangli")
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
            ccbDocumentControler.rewardranknumLabel:setVisible(false)
            -- ccbDocumentControler.rewardranksmallnumLabel:setVisible(false)

            if (a1+1) <= 3 then
                ccbDocumentControler.rewardrankSpriteLabel:setVisible(true)
                ccbDocumentControler.rewardranknumLabel:setVisible(false)
                -- ccbDocumentControler.rewardranksmallnumLabel:setVisible(false)

                local spritename = "b_n_zxt_"..(a1+1)..".png"
                setSpriteFrameByName(ccbDocumentControler.rewardrankSpriteLabel,spritename)
            else
                ccbDocumentControler.rewardrankSpriteLabel:setVisible(false)
                ccbDocumentControler.rewardranknumLabel:setVisible(true)
                -- ccbDocumentControler.rewardranksmallnumLabel:setVisible(true)

                local celltempdata = self.rewardconfig[tonumber(a1)]
                local numString = (celltempdata.rank+1).."~"..celldata.rank
                ccbDocumentControler.rewardranknumLabel:setString(numString)
            end

            local rewarddata = ui.getIDandNUMs(celldata.reward) or {}
            printT(rewarddata,"rewarddata===")
            for i=1,5 do
                if i <= table.getTableLength(rewarddata) then
                    print("visibletrue",i)
                    ccbDocumentControler["props"..i]:setVisible(true)
                    ui.setNewIcon(ccbDocumentControler,rewarddata[i],i-1)

                    local key_Ex = ""
                    if i == 1 then
                        key_Ex = ""
                    else
                        key_Ex = "_"..(i-1)
                    end

                    ccbDocumentControler["i_button"..key_Ex]:setTouchPriority(-103)
                    ccbDocumentControler["i_button"..key_Ex]:addHandleOfControlEvent(function()
                    -- print("i...am ...gotolevelup")
                        if not self.isscrolltouched then return end
                        ui.setPopwindowByCid(rewarddata[i]["cid"])
                    end, CCControlEventTouchUpInside)
                else
                    print("visiblefalse",i)
                    ccbDocumentControler["props"..i]:setVisible(false)
                end
            end


            cellCCB:setPosition(980/2,0)

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
        viewwidth = self.rootItems.rewardListNode:getContentSize().width,
        viewheight = self.rootItems.rewardListNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.rewardListNode:addChild(self.RewardListTableView)
    self.RewardListTableView:setTouchPriority(-101)
end

function goddownrank.clear(self)
    gameTouch:UnrigistFunc("begin","activitygoddownrank")
    gameTouch:UnrigistFunc("end","activitygoddownrank")
    self.show = false

    self.RankListTableView = nil
    self.RewardListTableView = nil

    -- gameTimer:UnrigistTimeFunc("passkill_ranktime")

    self.rewardconfig = {}
    self.rankdata = {}
    self.mydata = 0

    -- self.selectpage = "reward"

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
end



return goddownrank
