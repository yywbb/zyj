--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local servicewar_championlist = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    championListTableView = nil,
    joinedListTableView = nil,


    renListTableView = nil,
    tianListTableView = nil,
    shenListTableView = nil,
    xianListTableView = nil,
    diListTableView = nil,

    pages = {"ren","di","tian","xian","shen"},
    choosepage = "ren",


    myServiceListTableView = nil,
    allServiceListTableView = nil,

    sevicepages = {"myservice","allservice",},
    sevicename = {"本服积分排名","跨服积分排名",},
    sevicechoosepage = "allservice",
    worldwarstatus = 0,


    rewardshowListTableView = nil,
}

function servicewar_championlist.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.params = data

    if data.index == "champion" then
        print("i...am...champion")
        -- self.data  = data.data
        -- self.data = {{rank=1,name="有钱就任性01",servicename="ios6服",championnum=55,mobainum=15000},
        --                 {rank=2,name="有钱就任性02",servicename="ios7服",championnum=16,mobainum=1800},
        --                 {rank=3,name="有钱就任性03",servicename="ios7服",championnum=15,mobainum=1600},
        --                 {rank=4,name="有钱就任性04",servicename="ios8服",championnum=14,mobainum=1500},
        --             }
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_lijieguanjun.ccbi", nil, true, "kuafuzhan_lijieguanjun")
        -- self:championreload()
        gameTouch:clickprofbytime(0.5)
        UIRequest({type = 4706})
    elseif data.index == "joined" then 
        -- self.data = {{rank=1,name="有钱就是任性01",scorenum=15000,id = 10001},
        --                 {rank=2,name="有钱就任性02",scorenum=1800,id = 10002},
        --                 {rank=3,name="有钱就任性03",scorenum=1600,id = GameScene.roleinfo.id},
        --                 {rank=4,name="有钱就任性04",scorenum=1500,id = 10004},
        --             }
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_beisaijifen.ccbi", nil, true, "wing_tishi")
        -- self:joinedreload(callback)
        gameTouch:clickprofbytime(0.5)
        UIRequest({type = 4705 })
    elseif data.index == "matchinfo" then 
        -- self.data = { mydata = {ranktype = 1,name="ios22服－水帘洞"},

        --                 rank1 = {{ranktype=1,name="ios6服－洞庭湖"},
        --                             {ranktype=1,name="ios7服－雷鸣山"},
        --                             -- {rank=3,name="ios8服－水帘洞",scorenum=1800,id = 10002}
        --                         },
        --                 rank2 = {{ranktype=2,name="ios9服－烽火台"},
        --                             {ranktype=2,name="ios10服－炎黄城"},
        --                             {ranktype=2,name="ios11服－暴风城"},
        --                         },
        --                 rank3 = {{ranktype=3,name="ios12服－水帘洞"},
        --                             {ranktype=3,name="ios13服－武侯叱"},
        --                             {ranktype=3,name="ios14服－方太寺"},
        --                             {ranktype=3,name="ios15服－菩提洞"},
        --                             {ranktype=3,name="ios16服－雷音寺"},
        --                         },

        --             }
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_saiquinfo.ccbi", nil, true, "kuafuzhan_saiquinfo")
        -- self:matchinforeload()

        gameTouch:clickprofbytime(0.5)
        UIRequest({type = 4707})
    elseif data.index == "scorerank" then 
        -- self.data = { 
        --                 -- mydata = {ranktype = 1,name="ios22服－水帘洞"},

        --                 rank1 = {{rank=1,name="这个名字怎么01",servicename="ios6服",score=56789},
        --                             {rank=2,name="这个名字怎么02",servicename="ios7服",score=56789},
        --                             -- {rank=3,name="ios8服－水帘洞",scorenum=1800,id = 10002}
        --                         },
        --                 rank2 = {{rank=1,name="这什么情况01",servicename="ios6服",score=56789},
        --                             {rank=2,name="这什么情况02",servicename="ios7服",score=55555},
        --                             {rank=3,name="这什么情况03",servicename="ios8服",score=45555},
        --                             {rank=4,name="这什么情况04",servicename="ios9服",score=35555},
        --                             {rank=5,name="这什么情况05",servicename="ios10服",score=25555},
        --                         },

        --             }
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_cansaimingdan.ccbi", nil, true, "kuafuzhan_cansaimingdan")
        gameTouch:clickprofbytime(0.5)
        self.worldwarstatus = data.worldwarstatus or 0
        --self:initFixedString_3()
        UIRequest({type = 4715})
        -- self:serviceScoreReload()
    elseif data.index == "scorerank_s" then
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_cansaimingdan.ccbi", nil, true, "kuafuzhan_cansaimingdan")
        gameTouch:clickprofbytime(0.5)
        self.sevicechoosepage = "myservice"
        self.worldwarstatus = data.worldwarstatus or 0
        --self:initFixedString_3()
        UIRequest({type = 4728})
        self.rootItems.titleNode1:setVisible(false)
        self.rootItems.titleNode2:setVisible(false)
        self.rootItems.titleNode3:setVisible(true)
    elseif data.index == "rewardshow" then 
        -- self.data = {{rank=1,name="决赛",reward="20017,100;20283,50;",
        --                 {rank=2,name="半决赛",reward="20017,101;20283,50;"},
        --                 {rank=3,name="冠军赛4强",reward="20017,102;20283,50;"},
        --                 {rank=4,name="小组赛8强",reward="20017,103;20283,50;"},
        --                 {rank=5,name="小组赛16强",reward="20017,104;20283,50;"},
        --                 {rank=6,name="小组赛32强",reward="20017,105;20283,50;"},
        --             }
        self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_jiangli.ccbi", nil, true, "kuafuzhan_jiangli")
        self:rewardshowreload()
    end
    
    
    
    self.root:addChild(self.rootNode)
    return self.root
end



------------------------------- 奖励预览 ------------------------------------------
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function servicewar_championlist.rewardshowreload(self)
    printT(self.data,"rewardshowreload===")
    self.rootItems.rankText:setString("排名")
    self.rootItems.rewardText:setString("奖励内容")
    ui.setLabelString(self.rootItems.descText,"每轮比赛结束后发送对应奖励",18)

    self.data = self.params.shenbang and gamedata.config.cross_battle_champion_rankreward or gamedata.config.cross_battle_rankreward

    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarchampionlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)



    if self.rewardshowListTableView == nil then
        self:createRewardshowList()
    else
        self.rewardshowListTableView:reloadData()
    end
end

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
------------------------------- 奖励预览 ------------------------------------------


------------------------------- 跨服积分排名 ------------------------------------------
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
function servicewar_championlist.serviceScoreReload(self,data)
    self.data = data

    printT(self.data,"serviceScoreReload===")
    self.rootItems.rankText:setString("排名")
    self.rootItems.playernameText:setString("玩家名称")
    self.rootItems.servicenameText:setString("所在服务器")
    self.rootItems.scoreText:setString("杯赛积分")

    --self.rootItems.servicescoreDescText:setString(gameConfig.strings:string_common("fixedString","servicewar",55))


    -- if self.worldwarstatus > 1 and self.worldwarstatus <= 23 then
    --     self.rootItems.servicescoreDescText:setString(gameConfig.strings:string_common("fixedString","servicewar",18))
    -- elseif self.worldwarstatus >= 34 and self.worldwarstatus <= 55 then
    --     self.rootItems.servicescoreDescText:setString(gameConfig.strings:string_common("fixedString","servicewar",19))
    -- elseif self.worldwarstatus >= 55 then
    --     self.rootItems.servicescoreDescText:setString("")
    -- else
    --     self.rootItems.servicescoreDescText:setString("")
    -- end


    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarchampionlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)

    for i,v in ipairs(self.sevicepages) do
        print("page===",i,v)
        self.rootItems[v.."Btn"]:addHandleOfControlEvent(function()
            print("page===222",i,v)
            self:shiftServiceScoreNode(v)
        end, CCControlEventTouchUpInside)
        self.rootItems[v.."Btn"]:setSwallowsTouch(true)
        self.rootItems[v.."Btn"]:setTouchPriority(self.touchPriority-1)

        self.rootItems[v.."Text"]:setString(self.sevicename[i])
    end
    print("sevicechoosepage==",self.sevicechoosepage)
    self:shiftServiceScoreNode(self.sevicechoosepage)

end

function servicewar_championlist.setServiceScorePageSprite( self,choose )

    for i,v in ipairs(self.sevicepages) do
        print("setpage===",choose,v)
        if v == choose then
            setSpriteFrameByName(self.rootItems[v.."Sprite"], gameConfig.images.pageButtonON)
        else
            setSpriteFrameByName(self.rootItems[v.."Sprite"], gameConfig.images.pageButtonOFF)
        end
    end

end

function servicewar_championlist.shiftServiceScoreNode(self,type)
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
function servicewar_championlist.myserviceReload(self)
    if self.params.index == "scorerank_s" then
        ui.setLabelString(self.rootItems.servicescoreDescText,gameConfig.strings:string_common("fixedString","servicewar",77),14)
        self.rootItems.scoreText:setString("比赛积分")
    else
        ui.setLabelString(self.rootItems.servicescoreDescText,gameConfig.strings:string_common("fixedString","servicewar",75),14)
        self.rootItems.scoreText:setString("杯赛积分")
    end
    
    self:setmyrank(1)

    if self.myServiceListTableView == nil then
        self:createMyServiceList()
    else
        self.myServiceListTableView:reloadData()
    end
end
function servicewar_championlist.allserviceReload(self)
    ui.setLabelString(self.rootItems.servicescoreDescText,gameConfig.strings:string_common("fixedString","servicewar",76),14)
    self.rootItems.scoreText:setString("比赛积分")
    self:setmyrank(2)

    if self.allServiceListTableView == nil then
        self:createAllServiceList()
    else
        self.allServiceListTableView:reloadData()
    end
end

function servicewar_championlist.setmyrank(self,list_type)
    local myservername = ""
    local myrank = 0
    local mypoint = 0
    local myname = GameScene.roleinfo.name or ""

    if self.data.rank1 and self.data.rank1["1"] then
        myservername = self.data.rank1["1"].servicename or ""
    end

    if list_type and list_type == 1 then
        for k,v in pairs(self.data.rank1 or {}) do
            if v.is_self and v.is_self == 1 then
                myrank = tonumber(k)

                if self.params.index and self.params.index == "scorerank_s" then
                    mypoint = tostring(v.servicescorenum or 0)
                else
                    mypoint = tostring(v.cupscorenum or 0)
                end
            end
        end
    elseif list_type and list_type == 2 then
        for k,v in pairs(self.data.rank2 or {}) do
            if v.is_self and v.is_self == 1 then
                myrank = v.rank
                mypoint = tostring(v.servicescorenum or 0)
            end
        end
    end

    --
    self.rootItems.c_bg:setVisible(false)
    self.rootItems.c_bg_self:setVisible(true)
    if myrank == 0 then
        self.rootItems.c_rank_top:setVisible(false)
        self.rootItems.c_rank:setVisible(true)
        self.rootItems.c_rank:setString("未上榜")
    elseif myrank <= 3 then
        self.rootItems.c_rank_top:setVisible(true)
        self.rootItems.c_rank:setVisible(false)
        local spritestring = "b_n_zxt_"..myrank
        setSpriteFrameByName(self.rootItems.c_rank_top, spritestring)
    else
        self.rootItems.c_rank_top:setVisible(false)
        self.rootItems.c_rank:setVisible(true)
        self.rootItems.c_rank:setString(myrank)
    end

    self.rootItems.c_name:setString(myname)
    self.rootItems.c_servicename:setString(myservername)
    self.rootItems.c_point:setString(mypoint)



end
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
--------------------------------- 跨服积分排名 ----------------------------------------




----------------------------------- 赛区面板 ----------------------------------------
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
function servicewar_championlist.matchinforeload(self,data)
    printT(self.data,"matchinforeload===")
    -- self.rootItems.rankText:setString("排名")
    -- self.rootItems.playernameText:setString("玩家名称")
    -- self.rootItems.championnumText:setString("冠军次数")
    -- self.rootItems.mobaiText:setString("被膜拜次数")
    self.data = data

    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarchampionlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)

    for i,v in ipairs(self.pages) do
        print("page===",i,v)
        self.rootItems[v.."Btn"]:addHandleOfControlEvent(function()
            print("page===222",i,v)
            self:shiftNode(v)
        end, CCControlEventTouchUpInside)
        self.rootItems[v.."Btn"]:setSwallowsTouch(true)
        self.rootItems[v.."Btn"]:setTouchPriority(self.touchPriority-1)
    end
    print("choosepage==",self.choosepage)
    self:shiftNode(self.choosepage)

    self:setSaiquMydata()
end

function servicewar_championlist.setSaiquMydata( self )

    local celldata = self.data.mydata

    self.rootItems.bg_1:setVisible(false)
    self.rootItems.bg_2:setVisible(true)

    local spritestring = "alpha"
    if celldata.ranktype and gamedata.config.cross_battle_interval[tostring(celldata.ranktype)] then
        spritestring = gamedata.config.cross_battle_interval[tostring(celldata.ranktype)]["icon"]
    end
    setSpriteFrameByName(self.rootItems.icon, spritestring)

    self.rootItems.name:setString(celldata.name or "")

    if celldata.division and celldata.division > 0 then
        self.rootItems.divisionNode:setVisible(true)
        self.rootItems.divisionLab:setString(gameConfig.strings:servicewar_division(celldata.division))
    else
        self.rootItems.divisionNode:setVisible(false)
    end   
end

function servicewar_championlist.setPageSprite( self,choose )

    for i,v in ipairs(self.pages) do
        setSpriteFrameByName(self.rootItems[v.."sprite"],v.."bang")--gamedata.config.cross_battle_interval[tostring(i)] and gamedata.config.cross_battle_interval[tostring(i)]["icon"] or "alpha")
        print("setpage===",choose,v)
        if choose == v then
            self.rootItems[v.."sprite"]:setVisible(false)
        else
            self.rootItems[v.."sprite"]:setVisible(true)
        end
    end

end

function servicewar_championlist.shiftNode(self,type)
    print("i...am..shiftNode",type)

    self.choosepage = type
    self:setPageSprite(self.choosepage)
    
    for k,v in ipairs(self.pages) do
        if v == self.choosepage then
            self.rootItems[v.."listnode"]:setPositionX(60)
            self.rootItems[v.."listnode"]:setVisible(true)
        else
            self.rootItems[v.."listnode"]:setPositionX(9999)
            self.rootItems[v.."listnode"]:setVisible(false)
        end
    end
    if type == "ren" then
        print("renNode...is....")
        self:renReload()
    elseif type == "tian" then
        print("tianNode...is....")
        self:tianReload()
    elseif type == "shen" then
        print("shenNode...is....")
        self:shenReload()
    elseif type == "xian" then
        print("xianNode...is....")
        self:xianReload()
    elseif type == "di" then
        print("diNode...is....")
        self:diReload()
    else
        print("other===")
    end

end

function servicewar_championlist.renReload(self)
    printT(gamedata.config.cross_battle_interval)
    ui.setLabelString(self.rootItems.openservicetimeLab,gamedata.config.cross_battle_interval[tostring(1)]["desc"],18)

    if self.renListTableView == nil then
        self:createRenList()
    else
        self.renListTableView:reloadData()
    end
end
function servicewar_championlist.tianReload(self)
    ui.setLabelString(self.rootItems.openservicetimeLab,gamedata.config.cross_battle_interval[tostring(3)]["desc"],18)
    
    if self.tianListTableView == nil then
        self:createTianList()
    else
        self.tianListTableView:reloadData()
    end
end
function servicewar_championlist.shenReload(self)
    ui.setLabelString(self.rootItems.openservicetimeLab,gamedata.config.cross_battle_interval[tostring(5)] and gamedata.config.cross_battle_interval[tostring(5)]["desc"],18)
    
    if self.shenListTableView == nil then
        self:createShenList()
    else
        self.shenListTableView:reloadData()
    end
end
function servicewar_championlist.xianReload(self)
    ui.setLabelString(self.rootItems.openservicetimeLab,gamedata.config.cross_battle_interval[tostring(4)] and gamedata.config.cross_battle_interval[tostring(4)]["desc"],18)
    
    if self.xianListTableView == nil then
        self:createXianList()
    else
        self.xianListTableView:reloadData()
    end
end
function servicewar_championlist.diReload(self)
    ui.setLabelString(self.rootItems.openservicetimeLab,gamedata.config.cross_battle_interval[tostring(2)] and gamedata.config.cross_battle_interval[tostring(2)]["desc"],18)
    
    if self.diListTableView == nil then
        self:createDiList()
    else
        self.diListTableView:reloadData()
    end
end
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
------------------------------- 赛区面板 ------------------------------------------


-- 提示面板
function servicewar_championlist.championreload(self,data)
    self.data = data

    printT(self.data,"championreload===")
    self.rootItems.rankText:setString("排名")
    self.rootItems.playernameText:setString("玩家名称")
    self.rootItems.championnumText:setString("冠军次数")
    self.rootItems.mobaiText:setString("被膜拜次数")


    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarchampionlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)



    if self.championListTableView == nil then
        self:championlistRank()
    else
        self.championListTableView:reloadData()
    end
end

function servicewar_championlist.joinedreload(self,data)
    self.data = data.palyers
    self.myscore = data.myscore
    self.number = data.number

    printT(self.data,"joinedreload===")
    self.rootItems.rankText:setString("排名")
    self.rootItems.playernameText:setString("玩家名称")
    self.rootItems.scoreText:setString("总积分数")


    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarchampionlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)



    if self.joinedListTableView == nil then
        self:joinedlistRank()
    else
        self.joinedListTableView:reloadData()
    end

    self:setmydata()
end

function servicewar_championlist.setmydata(self)
    self.rootItems.c_bg:setVisible(false)
    self.rootItems.c_bg_self:setVisible(true)

    local mydata = {}
    for k,v in pairs(self.data) do
        if v.id == GameScene.roleinfo.id then
            mydata = v
            break
        end
    end

    if not next(mydata) then

       self.rootItems.c_rank_top:setVisible(false) 
       self.rootItems.c_rank:setVisible(true)

       self.rootItems.c_rank:setString("未上榜")

    elseif (mydata.rank) <= 3 then
        self.rootItems.c_rank_top:setVisible(true)
        self.rootItems.c_rank:setVisible(false)

        local spritestring = "b_n_zxt_"..mydata.rank
        setSpriteFrameByName(self.rootItems.c_rank_top, spritestring)
    else
       self.rootItems.c_rank_top:setVisible(false) 
       self.rootItems.c_rank:setVisible(true)

       self.rootItems.c_rank:setString(mydata.rank)
    end

    self.rootItems.c_name:setString(GameScene.roleinfo.name)
    self.rootItems.c_point:setString(self.myscore)

    if self.rootItems.numberstring then
        ui.setLabelString(self.rootItems.numberstring,"上周杯赛积分最高的"..(self.number or 16).."名玩家作为本次参赛人员",14)
    end
            
end
-- 跨服积分排名（本服
function servicewar_championlist.createMyServiceList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_kuafuzhan_4", nil, true, "cell_kuafuzhan_4")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank1[tostring(a1+1)]

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
            ccbDocumentControler.c_servicename:setString(celldata.servicename)

            local cupscorenum = celldata.cupscorenum
            if self.params.index and self.params.index == "scorerank_s" then
                cupscorenum = celldata.servicescorenum
            end
            ccbDocumentControler.c_point:setString(cupscorenum)

            cellCCB:setPosition(980/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.rank1)
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
-- 跨服积分排名（全服
function servicewar_championlist.createAllServiceList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_kuafuzhan_4", nil, true, "cell_kuafuzhan_4")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank2[tostring(a1+1)]

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
            ccbDocumentControler.c_servicename:setString(celldata.servicename)
            ccbDocumentControler.c_point:setString(celldata.servicescorenum)
            
            
            
            cellCCB:setPosition(980/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.rank2)
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



-- 冠军排行榜
function servicewar_championlist.championlistRank(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_kuafuzhan_5", nil, true, "cell_kuafuzhan_5")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data[tostring(a1+1)]

            if (a1+1) <= 3 then
                ccbDocumentControler.ranksprite:setVisible(true)
                ccbDocumentControler.ranknumLab:setVisible(false)

                local spritestring = "b_n_zxt_"..(a1+1)
                setSpriteFrameByName(ccbDocumentControler.ranksprite, spritestring)
            else
               ccbDocumentControler.ranksprite:setVisible(false) 
               ccbDocumentControler.ranknumLab:setVisible(true)

               ccbDocumentControler.ranknumLab:setString(celldata.rank)
            end

            ccbDocumentControler.nameLab:setString(celldata.name)
            ui.setLabelString(ccbDocumentControler.servicenameLab,celldata.servicename,26)
            ccbDocumentControler.winnumLab:setString(celldata.championnum)
            ccbDocumentControler.mobainumLab:setString(celldata.mobainum)
            
            
            cellCCB:setPosition(980/2, 0)
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

    self.championListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.championListTableView)
    self.championListTableView:setTouchPriority(self.touchPriority)
end

-- 参赛者名单界面
function servicewar_championlist.joinedlistRank(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_kuafuzhan_3", nil, true, "cell_kuafuzhan_3")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data[tostring(a1+1)]

            if (a1+1) <= 3 then
                ccbDocumentControler.c_rank_top:setVisible(true)
                ccbDocumentControler.c_rank:setVisible(false)

                local spritestring = "b_n_zxt_"..(a1+1)
                setSpriteFrameByName(ccbDocumentControler.c_rank_top, spritestring)
            else
               ccbDocumentControler.c_rank_top:setVisible(false) 
               ccbDocumentControler.c_rank:setVisible(true)

               ccbDocumentControler.c_rank:setString(celldata.rank)
            end

            ccbDocumentControler.c_bg:setVisible(true)
            ccbDocumentControler.c_bg_self:setVisible(false)

            ccbDocumentControler.c_name:setString(celldata.name)
            ccbDocumentControler.c_point:setString(celldata.scorenum)
            
            
            cellCCB:setPosition(980/2, 0)
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

    self.joinedListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.joinedlistnode:getContentSize().width,
        viewheight = self.rootItems.joinedlistnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.joinedlistnode:addChild(self.joinedListTableView)
    self.joinedListTableView:setTouchPriority(self.touchPriority)
end


-- 人榜列表
function servicewar_championlist.createRenList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(960, 110)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_saiquinfo", nil, true, "cell_kuafuzhan_3")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank1[tostring(a1+1)]

            ccbDocumentControler.bg_1:setVisible(true)
            ccbDocumentControler.bg_2:setVisible(false)

            local spritestring = gamedata.config.cross_battle_interval[tostring(celldata.ranktype)]["icon"] or "alpha"
            setSpriteFrameByName(ccbDocumentControler.icon, spritestring)
            

            ccbDocumentControler.name:setString(celldata.name)
            
            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.rank1)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.renListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.renlistnode:getContentSize().width,
        viewheight = self.rootItems.renlistnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.renlistnode:addChild(self.renListTableView)
    self.renListTableView:setTouchPriority(self.touchPriority)
end


-- 天榜列表
function servicewar_championlist.createTianList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(960, 110)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_saiquinfo", nil, true, "cell_kuafuzhan_3")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank3[tostring(a1+1)]

            ccbDocumentControler.bg_1:setVisible(true)
            ccbDocumentControler.bg_2:setVisible(false)

            local spritestring = gamedata.config.cross_battle_interval[tostring(celldata.ranktype)]["icon"] or "alpha"
            setSpriteFrameByName(ccbDocumentControler.icon, spritestring)
            

            ccbDocumentControler.name:setString(celldata.name)
            
            
            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.rank3)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.tianListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.tianlistnode:getContentSize().width,
        viewheight = self.rootItems.tianlistnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.tianlistnode:addChild(self.tianListTableView)
    self.tianListTableView:setTouchPriority(self.touchPriority)
end

-- 神榜列表
function servicewar_championlist.createShenList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(960, 110)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_saiquinfo", nil, true, "cell_kuafuzhan_3")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank5[tostring(a1+1)]

            ccbDocumentControler.bg_1:setVisible(true)
            ccbDocumentControler.bg_2:setVisible(false)

            local spritestring = gamedata.config.cross_battle_interval[tostring(celldata.ranktype)]["icon"] or "alpha"
            setSpriteFrameByName(ccbDocumentControler.icon, spritestring)
            

            ccbDocumentControler.name:setString(celldata.name)
            if celldata.division and celldata.division > 0 then
                ccbDocumentControler.divisionNode:setVisible(true)
                ccbDocumentControler.divisionLab:setString(gameConfig.strings:servicewar_division(celldata.division))
            else
                ccbDocumentControler.divisionNode:setVisible(false)
            end
            
            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.rank5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.shenListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.shenlistnode:getContentSize().width,
        viewheight = self.rootItems.shenlistnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.shenlistnode:addChild(self.shenListTableView)
    self.shenListTableView:setTouchPriority(self.touchPriority)
end

-- 仙榜列表
function servicewar_championlist.createXianList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(960, 110)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_saiquinfo", nil, true, "cell_kuafuzhan_3")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank4[tostring(a1+1)]

            ccbDocumentControler.bg_1:setVisible(true)
            ccbDocumentControler.bg_2:setVisible(false)

            local spritestring = gamedata.config.cross_battle_interval[tostring(celldata.ranktype)] and gamedata.config.cross_battle_interval[tostring(celldata.ranktype)]["icon"] or "alpha"
            setSpriteFrameByName(ccbDocumentControler.icon, spritestring)
            

            ccbDocumentControler.name:setString(celldata.name)
            
            
            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.rank4)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.xianListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.xianlistnode:getContentSize().width,
        viewheight = self.rootItems.xianlistnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.xianlistnode:addChild(self.xianListTableView)
    self.xianListTableView:setTouchPriority(self.touchPriority)
end

-- 仙榜列表
function servicewar_championlist.createDiList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(960, 110)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_saiquinfo", nil, true, "cell_kuafuzhan_3")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank2[tostring(a1+1)]

            ccbDocumentControler.bg_1:setVisible(true)
            ccbDocumentControler.bg_2:setVisible(false)

            local spritestring = gamedata.config.cross_battle_interval[tostring(celldata.ranktype)] and gamedata.config.cross_battle_interval[tostring(celldata.ranktype)]["icon"] or "alpha"
            setSpriteFrameByName(ccbDocumentControler.icon, spritestring)
            

            ccbDocumentControler.name:setString(celldata.name)
            
            
            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.data.rank2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.diListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.dilistnode:getContentSize().width,
        viewheight = self.rootItems.dilistnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.dilistnode:addChild(self.diListTableView)
    self.diListTableView:setTouchPriority(self.touchPriority)
end

-- 奖励预览列表
function servicewar_championlist.createRewardshowList(self)
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
                        ccbDocumentControler["ccb"..i]:setVisible(true)
                        ui.setNewIcon(ccbDocumentControler,tempdata[i],i-1)
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

function servicewar_championlist.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.worldwarstatus = 0

    self.championListTableView = nil
    self.joinedListTableView = nil

    self.renListTableView = nil
    self.tianListTableView = nil
    self.shenListTableView = nil
    self.xianListTableView = nil
    self.diListTableView = nil


    self.myServiceListTableView = nil
    self.allServiceListTableView = nil

    self.rewardshowListTableView = nil
    self.sevicechoosepage = "allservice"
    self.data = {}
end

return servicewar_championlist  j�  