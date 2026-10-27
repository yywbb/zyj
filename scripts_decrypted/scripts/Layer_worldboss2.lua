--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/24
-- Time: 下午6:36
-- To change this template use File | Settings | File Templates.
--

local worldboss = {

    rootNode = nil,
    rootItems = nil,

    pages = {"normal","start","battle"},
    choosepage = "normal",

    isauto = false,
    hasjoin = false,

    -- statusdata = {},
    -- realrank = {},
    -- prerank = {},
    -- notifys = {}

    infos ={},

    startsec = 12.5*3600,

    bosshp = 0,

    lastid  = 0,

    ListTableView = nil,

    refreshNum = 0, --在非开启时间开启后 控制刷新时间

    -- methodconfig = {
    --     [0] = "已经复活",
    --     [2] = "立即复活",
    --     [10] = "浴火重生",
    -- }
    pageconfig = {"onepage","twopage"} ,
    pagename = {"",""},
    selectpage = "onepage",
    methodconfig = {
        [0] = gameConfig.strings:string_common("worldboss",0),
        [2] = gameConfig.strings:string_common("worldboss",1),
        [10] = gameConfig.strings:string_common("worldboss",2),
    },

    data = {
        onepage = {
            statusdata= {}, realrank= {}, prerank= {}, notifys={}, 
            --json="jinyankongquelongwang/jinyankongquelongwang.json", atlas = "jinyankongquelongwang/jinyankongquelongwang.atlas", 
            bossconfignum = 30001, begintimenum = "12:00", endtimenum = 12.5,
            request0=3400, request1=3401, request2=3402, request3=3403, request4=3404,
            worldbossattack = "worldbossattack1"
        },
        twopage = {
            statusdata= {}, realrank= {}, prerank= {}, notifys={}, 
            --json="zhuque/zhuque.json", atlas = "zhuque/zhuque.atlas",
            bossconfignum = 31001, begintimenum = "21:00", endtimenum = 21.5,
            request0=3410, request1=3411, request2=3412, request3=3413, request4=3414,
            worldbossattack = "worldbossattack2"
        },
    },

}

function worldboss.shiftPage(self,type)
    print("i...am..shiftPage",type)
    if type and self.selectpage == type then
        print("nothing..change")
        return
    end
    print("shiftPagexxxboss2",type)
    if type then
        self.selectpage = type
    end
    
    local scale = 2.5 -- + 0.5*(GameScene.topposY-1620)/300

    local bossconfig = gamedata.config.boss2[tostring(self.data[self.selectpage].bossconfignum)]
    local bossName = gamedata.config.generalanimation[tostring(bossconfig.animationid)].name

    self:stopNextAllEvent()

    self.rootItems.bossnode:removeAllChildrenWithCleanup(true)
    self.long = nil

    self.long = CCSkeletonAnimation:create(bossName.."/"..bossName..".json", bossName.."/"..bossName..".atlas", 1)
    self.long:setAnimation("stand",true,0)
    self.rootItems.bossnode:addChild(self.long)
    self.rootItems.bossnode:setScaleX((bossName == "jinyankongquelongwang" and 1 or -1)*scale)
    self.rootItems.bossnode:setScaleY(scale)

    local bossTem = gamedata.config.boss2[tostring(self.data[self.selectpage].bossconfignum)]
    print("bossTem")
    -- printT(bossTem)

    ui.setLabelString(self.rootItems.topNameLabel, bossTem.name,21)
    ui.setLabelString(self.rootItems.middleNameLabel, bossTem.name,21)
    ui.setLabelString(self.rootItems.bottomNameLabel, bossTem.name,7)

    ui.setLabelString(self.rootItems.rewarddecLable, nil,7)

    self.rootItems.begintime:setString(self.data[self.selectpage].begintimenum)

    UIRequest({type = self.data[self.selectpage].request4})
    UIRequest({type = self.data[self.selectpage].request0})


end

function worldboss.stopNextAllEvent(self)
        gameTimer:UnrigistTimeFunc("worldbossstart")
        gameTimer:UnrigistTimeFunc(self.data[self.selectpage].worldbossattack)
        gameTimer:UnrigistTimeFunc("worldbossnotify")
        gameTimer:UnrigistTimeFunc("worldbossendtime")
        
        self.data[self.selectpage].notifys = {}
        if self.ListTableView then
            self.ListTableView:removeAllChildrenWithCleanup(true)
            self.ListTableView:removeFromParentAndCleanup(true)
            self.ListTableView = nil
        end
        
end


function worldboss.shiftNode(self,type)
    print("i...am..shiftNode",type)

    self.choosepage = type
    if type == "normal" then
        self.rootItems.bossbloodNode:setVisible(false)
        self.rootItems.autoBtnNode:setVisible(false)
    elseif type == "start" then
        self.rootItems.bossbloodNode:setVisible(true)
        self.rootItems.autoBtnNode:setVisible(false) 
    else
        self.rootItems.bossbloodNode:setVisible(true)
        self.rootItems.autoBtnNode:setVisible(true) 
    end
    for k,v in ipairs(self.pages) do
        if v == self.choosepage then
            self.rootItems[v.."node"]:setPosition(ccp(0,0))
            self.rootItems[v.."node"]:setVisible(true)
        else
            self.rootItems[v.."node"]:setPosition(ccp(9999,-460))
            self.rootItems[v.."node"]:setVisible(false)
        end
    end

    if self.choosepage == "battle" then
        -- self:setBattle(self.data[self.selectpage].statusdata)
    else
    end
end

function worldboss.setauto(self,isauto)
    self.isauto = isauto
    self.rootItems.autosprite:setVisible(self.isauto)
end

function worldboss.setstarttimer(self)

    if gameTimer.times["worldbossstart"] and gameTimer.times["worldbossstart"] > 0 then
        gameTimer:rigistTimeFunc("worldbossstart",function()
            if gameTimer.times["worldbossstart"] > 0 then
                ui.setLabelString(self.rootItems.starttime,ui.makeTimeText(gameTimer.times["worldbossstart"]),26)
            else
                -- self:shiftNode("start")
                print("i....am....time..over")
                ui.setLabelString(self.rootItems.starttime,ui.makeTimeText(gameTimer.times["worldbossstart"]),26)
                gameTimer:UnrigistTimeFunc("worldbossstart")

                self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
                    UIRequest({type = self.data[self.selectpage].request4})
                    UIRequest({type = self.data[self.selectpage].request0})
                end)))
            end
        end)
    end
end

function worldboss.setendtimer( self ) 
    print("setendtimer")
    local endtime = 0
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    -- if self.selectpage == "onepage" then

    --     endtime = 12.5*3600 - nowtimesec
    -- else
    --     endtime = 21.5*3600 - nowtimesec
    -- end
    endtime = self.data[self.selectpage].endtimenum*3600 - nowtimesec  
    print("timenum",endtime)
    gameTimer:rigistTime("worldbossendtime", endtime)
    gameTimer:rigistTimeFunc("worldbossendtime",function()
    
        if gameTimer.times["worldbossendtime"] >= 0 then
            ui.setLabelString(self.rootItems.endCD,ui.makeTimeText(gameTimer.times["worldbossendtime"],"minute"),29)
        end
    end)
end


function worldboss.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("worldboss2/worldboss2.ccbi", nil, true, "worldboss2")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    local config = gamedata.config.boss2
    self.pagename = {config[tostring(self.data[self.pageconfig[1]].bossconfignum)].name,config[tostring(self.data[self.pageconfig[2]].bossconfignum)].name}

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((GameScene.topposY-1620)*0.3 + 1000)

    ui.setLabelString(self.rootItems.desgetText, nil,21)

    if param and param.page then
        self.selectpage = param.page
    end
    self:shiftPage()

    self:setauto(self.isauto)

    self.rootItems.autobutton:setTouchPriority(-101)
    self.rootItems.autobutton:addHandleOfControlEvent(function()

        if ui.getVipLevelByStr("b_sjbszd") > GameScene.vip.vip and (gamedata.config.global_kv.worldboss_autolv and tonumber(gamedata.config.global_kv.worldboss_autolv.value) > GameScene.roleinfo.level) then
            -- runGamePrompt({msg = "VIP"..ui.getVipLevelByStr("mieshendian_sweep").."以上,或者队伍等级"..(gamedata.config.global_kv.worldboss_autolv.value).."以上可使用扫荡功能"})
            local autodesString = gameConfig.strings:string_common("worldboss",9)..ui.getVipLevelByStr("b_sjbszd")..gameConfig.strings:string_common("worldboss",10)..(gamedata.config.global_kv.worldboss_autolv.value)..gameConfig.strings:string_common("worldboss",11)
            
            runGamePrompt({msg = autodesString})
            return
        end
        -- if ui.getVipLevelByStr("b_sjbszd") > GameScene.vip.vip and  then
        --     runGamePrompt({msg = gameConfig.strings:getvipLv(ui.getVipLevelByStr("b_sjbszd"))})
        --     return
        -- end
        self:setauto(not self.isauto)

        if gameTimer.times[self.data[self.selectpage].worldbossattack]==nil or  gameTimer.times[self.data[self.selectpage].worldbossattack] <= 0 then
            print("点击自动战斗后如果没有倒计时，那么直接进入战斗获奖模式")
            if self.isauto then
                UIRequest({type = self.data[self.selectpage].request1, method = 0, isauto = self.isauto})
            end
            self:setAttackstatus(true)
        end



    end, CCControlEventTouchUpInside)


    self.rootItems.prerankbutton:setTouchPriority(-101)
    self.rootItems.prerankbutton:addHandleOfControlEvent(function()
        print("i...am ...pre")
         gameWindows:openWindow("worldbossrank",{index = "rank", data = self.data[self.selectpage].prerank,selectpage = ""},nil)
    end, CCControlEventTouchUpInside)

    
    self.rootItems.rewardListBtn:setTouchPriority(-101)
    self.rootItems.rewardListBtn:addHandleOfControlEvent(function()
        print("i...am ...pre")
         gameWindows:openWindow("worldbossrank",{index = "reward", data = {},selectpage = self.selectpage},nil)
    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.startdec_text,nil,18)

    ui.setLabelString(self.rootItems.starttext,nil,19)
    self.rootItems.startbutton:setTouchPriority(-101)
    self.rootItems.startbutton:addHandleOfControlEvent(function()
        print("i...startbutton:")
        gameTouch:clickprofbytime(0.5)
        self.hasjoin = true
        if self.data[self.selectpage].statusdata.status and self.data[self.selectpage].statusdata.status == 1 then
            self:shiftNode("battle")
        end

    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.attacktext,nil,19)
    self.rootItems.attackbutton:setTouchPriority(-101)
    self.rootItems.attackbutton:addHandleOfControlEvent(function()
        print("i...attackbutton:")
        -- if self.selectpage == "onepage" then
        --     UIRequest({type = 3401, method = 0, isauto = self.isauto})
        -- elseif self.selectpage == "twopage" then
        --     UIRequest({type = 3411, method = 0, isauto = self.isauto})
        -- end
        gameTouch:clickprofbytime(0.5)
        UIRequest({type = self.data[self.selectpage].request1, method = 0, isauto = self.isauto})
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.goldrelivebuttontext,nil,19)
    self.rootItems.goldrelivebutton:setTouchPriority(-101)
    self.rootItems.goldrelivebutton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if tonumber(self.data[self.selectpage].statusdata.bosshp) == 0 then
            -- runGamePrompt({msg = "当前boss已被杀死"})
            runGamePrompt({msg = gameConfig.strings:string_common("worldboss",7)})
            return
        end
        -- if self.selectpage == "onepage" then
        --     UIRequest({type = 3401, method = 10, isauto = self.isauto})
        -- elseif self.selectpage == "twopage" then
        --     UIRequest({type = 3411, method = 10, isauto = self.isauto})
        -- end
        
        UIRequest({type = self.data[self.selectpage].request1, method = 10, isauto = self.isauto})
    end, CCControlEventTouchUpInside)

    
    
    

    ui.setLabelString(self.rootItems.damage_text,nil,21)
    ui.setLabelString(self.rootItems.name_text,nil,21)
    ui.setLabelString(self.rootItems.atkrank_text,nil,21)


    ui.setLabelString(self.rootItems.spendgold_Label,gamedata.config.global_kv.worldboss_gold.value,18)
    -- ui.setLabelString(self.rootItems.spendgold_Label,nil,18)
    ui.setLabelString(self.rootItems.spendgold_text,nil,18)



    ui.setLabelString(self.rootItems.endCD_text,nil,29)

    if gameConfig:checkBuildOpen(154) then
        -- VIP5或队伍等级40级可自动战斗
            -- runGamePrompt({msg = "VIP"..ui.getVipLevelByStr("mieshendian_sweep").."以上,或者队伍等级"..(gamedata.config.global_kv.worldboss_autolv.value).."以上可使用扫荡功能"})
        local autodesString = gameConfig.strings:string_common("worldboss",9)..ui.getVipLevelByStr("b_sjbszd")..gameConfig.strings:string_common("worldboss",10)..(gamedata.config.global_kv.worldboss_autolv.value)..gameConfig.strings:string_common("worldboss",11)
        ui.setLabelString(self.rootItems.autodec_text,autodesString,21)
    else
        self.rootItems.autodec_text:setVisible(false)
    end

    ui.setLabelString(self.rootItems.reliveCD_text,nil,21)


    ui.setLabelString(self.rootItems.reliveCDdesc_Text,nil,7)
    
    ui.setLabelString(self.rootItems.reliveCD," ",3)
end

function worldboss.setrealrank(self,data)
    if data then self.data[self.selectpage].realrank = data end
    print("realrank==")
    -- printT(self.data[self.selectpage].realrank)
    if not next(data) then
        return
    end
    
    ui.setLabelString(self.rootItems.myrankLabel,"未进榜",14)
    for k,v in pairs(data) do
        if tonumber(v.rid) == tonumber(GameScene.roleinfo.id) then
            ui.setLabelString(self.rootItems.myrankLabel,tostring(k),22)
            break
        end
    end

    if not self.ListTableView then
        self:createRankList()
        print("create:")
    else
        print("reload:")
        self.ListTableView:reloadData()
        self.ListTableView:setLuaContentOffset(0, self.rootItems.rankscroll:getContentSize().height - table.getTableLength(self.data[self.selectpage].realrank)*self.CellSize.height)
    end
end

function worldboss.createRankList(self)
    print("createRankList==")
    -- printT(self.data[self.selectpage].realrank)
    
    
    -- printT(GameScene.roleinfo)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1000, 60)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("worldboss2/cell_n_worldboss_paiming", nil, true, "worldboss_paiming")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.ListTableView,cellCCB,920/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            print("createRankListitem:",a1)
            local itemdata = self.data[self.selectpage].realrank[tostring(a1+1)]
            -- printT(itemdata)
            print("rid = ",itemdata.rid)
            print("rid = ",GameScene.roleinfo.id)
            if tonumber(itemdata.rid) == tonumber(GameScene.roleinfo.id) then
                print("visible=true")
                ccbDocumentControler.myrankNode:setVisible(true)
            else
                print("visible=false")
                ccbDocumentControler.myrankNode:setVisible(false)
            end

            ccbDocumentControler.rankNumLabel:setString(a1+1)
            ccbDocumentControler.rankNameLabel:setString(itemdata.name)
            ccbDocumentControler.rankDamageLabel:setString(itemdata.param)



            cellCCB:setPosition(1000/2,60/2)
            if not self.CellSize then
                self.CellSize = cellCCB:getContentSize()
                print("height=",self.CellSize.height)
            end


            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data[self.selectpage].realrank)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.rankscroll:getContentSize().width,
        viewheight = self.rootItems.rankscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.rankscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

function worldboss.setbosshp(self,hp)
    if hp then self.bosshp = hp end
    if self.data[self.selectpage].statusdata.bosslevel == nil then
        return
    end
    -- print("BOSS的血量==", self.selectpage,self.data[self.selectpage].statusdata.bosslevel )
    -- printT(self.data)
    local bosshptotal = (self.data[self.selectpage].statusdata.bosslevel or 0) 
    ui.setLabelString(self.rootItems.bossblood,(self.bosshp or 0).."/"..bosshptotal,13)
    ui.setSpriteTextureRect2(self.rootItems.bossbloodbar,0,0,1008 * (self.bosshp or 0) / bosshptotal,41)
end

function worldboss.setAttackstatus(self,islive)
    print("setlivecdstatus==",islive)
    if not GameScene.layers["worldboss"].show then return end
    
    self.rootItems.livenode:setVisible(islive)
    self.rootItems.livenode:setPosition(islive and ccp(0,280) or ccp(9999,280))
    self.rootItems.deadnode:setVisible(not islive)
    self.rootItems.deadnode:setPosition((not islive) and ccp(0,280) or ccp(9999,280))
end

function worldboss.setattackCD(self,cd)
    self.attackcd = cd
    print("setlivecd==",self.attackcd)
    -- gameTimer:rigistTime(self.data[self.selectpage].worldbossattack,self.attackcd)
    print("worldbossattack=====",gameTimer.times[self.data[self.selectpage].worldbossattack])

    if cd and cd ~= 0 then
                    print("setlivecd000")
        self:setAttackstatus(false)

        if gameTimer.times[self.data[self.selectpage].worldbossattack] and gameTimer.times[self.data[self.selectpage].worldbossattack] > 0 then
            gameTimer:rigistTimeFunc(self.data[self.selectpage].worldbossattack,function()
                print("time===",gameTimer.times[self.data[self.selectpage].worldbossattack].."s")
                if GameScene.layers["worldboss"].show then
                    ui.setLabelString(self.rootItems.reliveCD,gameTimer.times[self.data[self.selectpage].worldbossattack].."s",3)
                end
                if gameTimer.times[self.data[self.selectpage].worldbossattack] <= 0 then
                    if self.isauto then
                        -- if self.selectpage == "onepage" then
                        --     UIRequest({type = 3401, method = 0, isauto = self.isauto})
                        -- elseif self.selectpage == "twopage" then
                        --     UIRequest({type = 3411, method = 0, isauto = self.isauto})
                        -- end

                        UIRequest({type = self.data[self.selectpage].request1, method = 0, isauto = self.isauto})
                        
                    end
                    self:setAttackstatus(true)
                    print("setlivecd111")
                end
            end)
        else
                    print("setlivecd222")
            self:setAttackstatus(true)
        end
    else
                    print("setlivecd333")
        self:setAttackstatus(true)
    end
end

function worldboss.setBattle(self,data)
    self.data[self.selectpage].statusdata = data
    print("setBattle not kill",self.data[self.selectpage].statusdata.status)
    if self.data[self.selectpage].statusdata.status == 0 then
        print("setBattle killed====")
        self:bosskilled()
        return
    end

    self:setbosshp(self.data[self.selectpage].statusdata.bosshp)
    self:setrealrank(self.data[self.selectpage].statusdata.ranks)
    self:setattackCD(self.data[self.selectpage].statusdata.cd)

    ui.setLabelString(self.rootItems.attacktime,data.attackcount,22)
    ui.setLabelString(self.rootItems.damage,data.damagesum,22)
end

function worldboss.reloadstatus(self,data)
    self.data[self.selectpage].statusdata = data

    if self.data[self.selectpage].statusdata.status == 0 then
        self:setstarttimer()
        self:shiftNode("normal")
        self:setbosshp(self.data[self.selectpage].statusdata.bosshp)
    elseif self.data[self.selectpage].statusdata.status == 1 then

        self:setBattle(self.data[self.selectpage].statusdata)
        self:startnotify()
        self:setendtimer()
        print("battle.hasjoin",self.hasjoin)
        if self.hasjoin then
            self:shiftNode("battle")
        else
            self:shiftNode("start")
        end
        print("1111=",ui.getVipLevelByStr("b_sjbszd"))
        print("2222=",GameScene.vip.vip)
        print("3333=",gameTimer.times[self.data[self.selectpage].worldbossattack])
        if ui.getVipLevelByStr("b_sjbszd") <= GameScene.vip.vip then
            print("test000")
            if gameTimer.times[self.data[self.selectpage].worldbossattack] == nil or gameTimer.times[self.data[self.selectpage].worldbossattack] <= 0 then
                
                print("点击自动战斗后如果没有倒计时，那么直接进入战斗获奖模式111")
                if self.isauto then
            print("test111")
                    UIRequest({type = self.data[self.selectpage].request1, method = 0, isauto = self.isauto})
                end
            end 
            
            -- self:setAttackstatus(true)
        end
    end
end

function worldboss.reloadnotify(self,data)
    self.data[self.selectpage].notifys = data

    if self.data[self.selectpage].notifys.kill and self.data[self.selectpage].notifys.kill ~= 0 then
        print("boss is killed")
        UIRequest({type = self.data[self.selectpage].request4, killed = 1})        
    end
end

function worldboss.showOneNotify(self)
    local data = nil
    local index = 0
    if not self.data[self.selectpage].notifys or not next(self.data[self.selectpage].notifys) then
        -- if self.selectpage == "onepage" then
        --     UIRequest({type = 3403})
        -- elseif self.selectpage == "twopage" then
        --     UIRequest({type = 3413})
        -- end
        --UIRequest({type = self.data[self.selectpage].request3})
        
        return
    else
        for k,v in pairs(self.data[self.selectpage].notifys) do
            index = k
            data = v
            break
        end
    end
    if self.lastid == data.id then return end
    self.lastid = data.id

    local ccbconfig = {
        [0] = "attck"..math.random(1,7),
        [2] = "attck_fuhuo",
        [10] = "attck_yuhuo",
    }

    local ccb,item = CCBReaderLoad("worldboss2/"..ccbconfig[data.method]..".ccbi", nil, true, ccbconfig[data.method])
    ccb:setPosition(ccp(math.random(1,400),math.random(1,400)))
    ccb:setScale(1.5)
    self.rootItems.damagenode:addChild(ccb)
    item.damage:setString(data.damage)
    ui.setLabelString(item.name,data.rname,1)

    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("Default Timeline")

    local red = CCTintTo:create(0.2,255,0,0)
    local back = CCTintTo:create(0.3,255,255,255)
    local sq = CCSequence:createWithTwoActions(red,back)
    self.long:runAction(sq)
    print("not kill====",data.kill)
    if data.kill and data.kill ~= 0 then
        print("killed====")
        self:bosskilled()
    end

    self.data[self.selectpage].notifys[index] = nil
end

function worldboss.startnotify(self)
    gameTimer:rigistTime("worldbossnotify",4000)

    gameTimer:rigistTimeFunc("worldbossnotify",function()
        self:showOneNotify()

        if math.mod(gameTimer.times["worldbossnotify"],5) ==0 then
            print("worldbossnotify===",gameTimer.times["worldbossnotify"])
            -- if self.selectpage == "onepage" then
            --     UIRequest({type = 3402})
            -- elseif self.selectpage == "twopage" then
            --     UIRequest({type = 3412})
            -- end

            UIRequest({type = self.data[self.selectpage].request2})
        end

        if gameTimer.times["worldbossnotify"] <= 0 then
            gameTimer:rigistTime("worldbossnotify",4000)
        end


        local nowtime = os.date("*t", gamedata:time())
        local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec
        -- if self.selectpage == "onepage" then
        --     if nowtimesec>12.5*3600 then
        --         UIRequest({type = 3404})
        --         UIRequest({type = 3400})
        --     end
        -- elseif self.selectpage == "twopage" then
        --     if nowtimesec>21.5*3600 then
        --         UIRequest({type = 3414})
        --         UIRequest({type = 3410})
        --     end
        -- end
        if nowtimesec>self.data[self.selectpage].endtimenum*3600 and self.refreshNum < 2 then
            print("end====",refreshNum)
            self.refreshNum = self.refreshNum + 1
            -- print("i...am...request4 0")
            UIRequest({type = self.data[self.selectpage].request4})
            UIRequest({type = self.data[self.selectpage].request0})
        end


    end)
end

function worldboss.stoptnotify(self)
    gameTimer:UnrigistTimeFunc("worldbossnotify")
end


function worldboss.reloadprerank(self,data)
    self.data[self.selectpage].prerank = data
    print("i...am reloadprerank0")
    -- printT(self.data[self.selectpage].prerank)

    if self.data[self.selectpage].prerank.time and self.data[self.selectpage].prerank.time ~= 0 and self.data[self.selectpage].prerank.kill and self.data[self.selectpage].prerank.kill.name~="" then
        self.rootItems.killerName:setString(self.data[self.selectpage].prerank.kill.name)
        self.rootItems.nonekillText:setVisible(false)
        self.rootItems.killerName:setVisible(true)
        self.rootItems.killerNameText:setVisible(true)
        
    else
        self.rootItems.killerName:setVisible(false)
        self.rootItems.killerNameText:setVisible(false)
        self.rootItems.nonekillText:setVisible(true)
    end

    for i=1,3 do
        self.rootItems["name"..i]:setString(self.data[self.selectpage].prerank.ranks[tostring(i)] and self.data[self.selectpage].prerank.ranks[tostring(i)].name or gameConfig.strings:string_common("moreCommon","wu"))
    end
end

function worldboss.bosskilled(self)
    print("bosskilled===")
    gameTimer:UnrigistTimeFunc("worldbossstart")
    gameTimer:UnrigistTimeFunc(self.data[self.selectpage].worldbossattack)
    gameTimer:UnrigistTimeFunc("worldbossnotify")
    gameTimer:UnrigistTimeFunc("worldbossendtime")

    
    self.data[self.selectpage].notifys = {}

    -- if self.selectpage == "onepage" then
    --     UIRequest({type = 3400})
    -- elseif self.selectpage == "twopage" then
    --     UIRequest({type = 3410})
    -- end 

    UIRequest({type = self.data[self.selectpage].request0})
    UIRequest({type = self.data[self.selectpage].request4, killed = 1})
end


function worldboss.clear(self)
    gameTimer:UnrigistTimeFunc("worldbossstart")
    -- gameTimer:UnrigistTimeFunc(self.data[self.selectpage].worldbossattack)
    gameTimer:UnrigistTimeFunc("worldbossnotify")
    gameTimer:UnrigistTimeFunc("worldbossendtime")


    self.ListTableView = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.long = nil

    self.data.onepage.statusdata = {}
    self.data.onepage.realrank = {}
    self.data.onepage.prerank = {}
    self.data.onepage.notifys = {}

    self.data.twopage.statusdata = {}
    self.data.twopage.realrank = {}
    self.data.twopage.prerank = {}
    self.data.twopage.notifys = {}

    self.refreshNum = 0
end



return worldbossLo  