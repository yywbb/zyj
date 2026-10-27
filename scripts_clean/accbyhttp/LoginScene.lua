--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-7-28
-- Time: 下午1:36
-- To change this template use File | Settings | File Templates.
--


local loginScene = {

    maxRadio_size = gameConfig.maxRadio_size,

    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },
    viewSize = gameConfig.originSize,

    scaleNum  = 1,

    serverlist = {},
    recentlist = {},
    serverlist_1 = {},
    serverlist_1TableView = nil,

    SelectedServer = {},

    maincellSize = {width = 350,height = 130},
    subcellSize = {width = 550,height = 100},

    rootLayer = nil,

    enterLayer = nil,
    enterLayerItem = {},

    userCreateLayer = nil,
    userCreateLayerItem = {},

    status = false,

    accountInputBox = nil,
    passwordInputBox = nil,
    requestType = nil,

    isdebug = gamedata.isdebug,

    -- istencentPlat = gamedata.istencentPlat,

    -- isleshiPlat = gamedata.isleshiPlat,

    -- isaddLoginBtnPlat = gamedata.isaddLoginBtnPlat,

    isldfs = false,
    roleuid = 0,

    loadingtips = {
        "吕布貂蝉合体狂虐单身狗",
        "刘备，关羽，张飞桃园结义感天动地",
        "招募菩提祖师，宇宙飞船带你飞",
        "猴哥，师父啰嗦病又犯了，咋整？",
        "血气不足吗？何仙姑来补补补~！",
        "从前有个蓬莱洞，洞里有好多宝贝",
        "我要一步一步向上爬，我去，啥塔辣么高",
        "来来来，阎王土豪请吃辣条",
        "传说公会温泉能遇到美女",
        "放开观音姐姐，让我来！！！",
        "魔宫里看我的72变变变",
        "大乔神鞭一挥，做人，懂了吗？",
        "呵呵，董卓大爷给你笑一个",
        "后羿欧巴，不是说好要做彼此的天使吗",
        "月英你吓到我了，赔钱",
        "8颗北极星，亮瞎我的眼",
        "玉帝可带来最强大的装*力量",
    },

    logtag = 0,
    videoscene = nil,
    isfirstvideoscene = false,
}

function loginScene.showNode(self,node,isshow)
    if not node then return end
    node:setVisible(isshow)
    if node == self.enterLayerItem.loadingNode then
    else
        node:setPositionY(isshow and 0 or 10000)
    end

    if node == self.enterLayerItem.processNode and not isshow and not self.enterLayerItem.enterNode:isVisible() then
        self:showOpt()
    end

end

function loginScene.waiting(self,data)
    if not self.waitLayer then
        self.waitLayer,self.waitLayerItem = CCBReaderLoad("Login/loading_wait.ccbi", nil, true, "loading_wait")
        self.waitLayer:setPosition(self.d_viewSize.width/2,self.d_viewSize.height/2)
        self.rootLayer:addChild(self.waitLayer,3)
        self.waitLayer:setScale(gameConfig.scaleNum)
    end


--    if self.processLayerItem and next(self.processLayerItem) then
--        self.processLayerItem.percentNode:setVisible(false)
--    end

    self.waitLayerItem.total:setString(data.total)
    self.waitLayerItem.location:setString(data.location)
    -- self.waitLayerItem.time:setString("约"..math.floor(data.time/60).."分钟")
    self.waitLayerItem.time:setString(gameConfig.strings:Fdminute(math.floor(data.time/60)))

end

local  ProcesInfo = ""
function loginScene.setProcesInfo(self,info)
    if self.logtag < 5 then return end
    print(info)

    if self.processLayer and self.processLayerItem.tips then
        self.processLayerItem.tips:setString(ProcesInfo.."\n"..info)
        ProcesInfo= info
    end
end

local tipbgs={
    "loading_n_1",
    "loading_n_2",
    "loading_n_4",
    "loading_n_6",
    "loading_n_8",
}

local bgidx = math.random(1,#tipbgs)

function loginScene.settip( self, needmove)

    self.processLayerItem.bgnode:setPosition(0,0)
    bgidx = bgidx + 1
    if bgidx> #tipbgs then bgidx = 1 end
    setSpriteFrameByName(self.processLayerItem.bg,tipbgs[bgidx])

    local bgidx2 = bgidx + 1
    if bgidx2> #tipbgs then bgidx2 = 1 end
    setSpriteFrameByName(self.processLayerItem.bg2,tipbgs[bgidx2])

    if needmove then
        local moveTo = CCMoveTo:create(0.1, ccp(-1080, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.processLayerItem.bgnode:runAction(backOut)
    end

    if not self.loadingtips then
        self.processLayerItem.tips:setString("")
    else
        local index = math.random(1,#self.loadingtips)
        if not self.loadingtips[index] then index = 1 end

        self.processLayerItem.tips:setString(self.loadingtips[index])
    end
end

function loginScene.tipbytime( self,time )
    self.processLayerItem.bg:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(time), CCCallFunc:create(function()
        self:settip(true)
        self:tipbytime(4)
    end)))
end

function loginScene.showConfigProcess(self,rate)

    if not self.rootLayer then return end
    if not self.processLayer then
        self.processLayer,self.processLayerItem = CCBReaderLoad("Login/loading_login.ccbi", nil, true, "loading_login")
        self.processLayer:setPosition(self.d_viewSize.width/2,self.d_viewSize.height/2)
        self.rootLayer:addChild(self.processLayer,2)
        self.processLayer:setScale(gameConfig.scaleNum)

        if self.processLayerItem.topnode then
            self.processLayerItem.topnode:setPositionY(1920-(1920-gameConfig.topposY)/2)
        end


        self.processLayerItem.processprofbutton:setSwallowsTouch(true)
        self.processLayerItem.processprofbutton:setTouchPriority(-100)
        self.processLayerItem.processprofbutton:addHandleOfControlEvent(function()
        end, CCControlEventTouchUpInside)

        -- local ske = CCSkeletonAnimation:create("getstone/getstone.json","getstone/getstone.atlas",1)
        -- self.processLayerItem.skeletonNode:addChild(ske)
        -- ske:setAnimation("go",true,0)

        self:settip()
        self:tipbytime(4)

        local barsprite = CCSprite:createWithSpriteFrameName("loadingprocessbar.png")

        self.processLayerItem.processBar = CCProgressTimer:create(barsprite)
        self.processLayerItem.processBar:setAnchorPoint(ccp(0.5, 0.5))
        self.processLayerItem.processBar:setType(kCCProgressTimerTypeBar)
        self.processLayerItem.processBar:setMidpoint(ccp(0, 0.5))
        self.processLayerItem.processBar:setBarChangeRate(ccp(1, 0))
        self.processLayerItem.processBar:setPosition(ccp(540, 491))
        self.processLayerItem.processBar:setPercentage(0)
        self.processLayerItem.processBar:setScaleX(1)
        self.processLayerItem.processBar:setScaleY(1)
        self.processLayer:addChild(self.processLayerItem.processBar)
    end

    if not self.lasttype or self.lasttype ~= rate.type then
        self.processLayerItem.processBar:setPercentage(0)
        self.lasttype = rate.type
    end

    if rate.type == "config" then
        self.processLayerItem.tip:setString(gameConfig.strings:string_common("loginScene",2))
        -- local to = CCProgressTo:create(rate.time or 0.2,rate.index*100/rate.total)
        -- self.processLayerItem.processBar:runAction(to)
        self.processLayerItem.processBar:setPercentage(rate.index*100/rate.total)
    elseif rate.type == "updateconfig" then
        self.processLayerItem.tip:setString(gameConfig.strings:string_common("loginScene",1))
        -- local to = CCProgressTo:create(0.2,rate.index*100/rate.total)
        -- self.processLayerItem.processBar:runAction(to)
        self.processLayerItem.processBar:setPercentage(rate.index*100/rate.total)
    elseif rate.type == "datainit" then
        self.processLayerItem.tip:setString(gameConfig.strings:string_common("loginScene",3))
        self.processLayerItem.processBar:setPercentage(rate.index*100/rate.total)
    end

end

function loginScene.showDownloadProcess(self,rate)
    self.isdownlaoding = true
    if self.enterLayer then
        self:showNode(self.enterLayerItem.processNode,true)
        self:showNode(self.enterLayerItem.enterNode,false)
        self:showNode(self.enterLayerItem.serverlistNode,false)
        self:showNode(self.enterLayerItem.connectnode,false)
        self:showNode(self.enterLayerItem.tencentNode,false)
        self:showNode(self.enterLayerItem.userAgreement,false)  
        self:showNode(self.enterLayerItem.channel_loginnode,false)
    end

    if rate.type == "resource" then
        -- self.enterLayerItem.tip:setString("同步资源......")
        ui.setLabelString(self.enterLayerItem.tip,gameConfig.strings:string_common("loginScene",4),13)
        self.resourcerate = self.resourcerate + 1
        ui.setLabelString(self.enterLayerItem.persentage,math.ceil(self.resourcerate*100/rate.total).."%",13)
        ui.setSpriteTextureRect2(self.enterLayerItem.resourceprocess,0,0,921*(self.resourcerate/rate.total),33)

        self:showNode(self.enterLayerItem.loadingNode,math.ceil(self.resourcerate*100/rate.total)>=100)
    elseif rate.type == "loadresource" then
        -- self.enterLayerItem.tip:setString("加载资源......")
        ui.setLabelString(self.enterLayerItem.tip,gameConfig.strings:string_common("loginScene",5),13)
        self.loadresourcerate = self.loadresourcerate + 1
        ui.setLabelString(self.enterLayerItem.persentage,math.ceil(self.loadresourcerate*100/rate.total).."%",13)
        ui.setSpriteTextureRect2(self.enterLayerItem.resourceprocess,0,0,921*(self.loadresourcerate/rate.total),33)
    elseif rate.type == "config" or rate.type == "updateconfig" then

        self:showConfigProcess(rate)
    end

end

function loginScene.showEnter(self,t)
    if self.processLayer then
        self.processLayer:removeFromParentAndCleanup(true)
        self.processLayer = nil
    end

    if self.waitLayer then
        self.waitLayer:removeFromParentAndCleanup(true)
        self.waitLayer = nil
    end

    if self.egameaboutnode then
        self.egameaboutnode:removeFromParentAndCleanup(true)
        self.egameaboutnode = nil
    end    

    self:showNode(self.enterLayerItem.processNode,false)
    --self:showNode(self.enterLayerItem.enterNode,true)
    self:showNode(self.enterLayerItem.serverlistNode,false)
    self:showNode(self.enterLayerItem.connectnode,false)
    self:showNode(self.enterLayerItem.loadingNode,false)
    self:hideUserInput()
   
    self.userdata = t or self.userdata

    if t then
        self.recentlist = t.recentlist
        self.serverlist = t.serverlist

        if self.recentlist["1"] then
            self.SelectedServer = self.recentlist["1"]
        else
            for i=1, table.getTableLength(self.serverlist) do
                if self.serverlist[tostring(i)].status ~= "maintain" and self.serverlist[tostring(i)].status ~= "maintain2" then
                    self.SelectedServer=self.serverlist[tostring(i)]
                    break
                end
            end
        end
        self:checkOnlineTime(true)
    end

    ui.setLabelString(self.enterLayerItem.serverNum, gameConfig.strings:idStatus(self.SelectedServer.id), 14)
    ui.setLabelString(self.enterLayerItem.serverName, self.SelectedServer.name, 14)
    ui.setLabelString(self.enterLayerItem.touchConstituencyLab, nil, 22)
    --
    if self.SelectedServer.tag and self.SelectedServer.tag == "hot" then
        setSpriteFrameByName(self.enterLayerItem.status, "baoman")
    elseif self.SelectedServer.tag and self.SelectedServer.tag == "new" then
        setSpriteFrameByName(self.enterLayerItem.status, "tuijian")
    else
        setSpriteFrameByName(self.enterLayerItem.status, "xinfu")
    end
    --
    self.enterLayerItem.selectbutton:addHandleOfControlEvent(function()
        print("进入服务器列表")
        self:showServerList()
    end, CCControlEventTouchUpInside)

    self:showNode(self.enterLayerItem.enterNode,true)
    self:showNode(self.enterLayerItem.tencentNode,false)
    self:showNode(self.enterLayerItem.userAgreement,false)

     --乐视显示切换按钮
    if gamedata.device.channel == "leshi" or gamedata.device.channel == "yuewen" or gamedata.device.channel == "yuxiang" 
        or gamedata.device.channel == "cxsm" or gamedata.device.channel == "cxyx" or string.find(gamedata.device.channel,"17") then
    -- if self.isleshiPlat then
    self:showNode(self.enterLayerItem.leshiChangeCountNode,true)
    end

    if gamedata.device.channel == "anqu" or gamedata.device.channel == "zy" or gamedata.device.channel == "sogou" or gamedata.device.channel == "pyw" or gamedata.device.channel == "lenovo" or gamedata.device.channel == "chujiana" or gamedata.device.channel == "baiducmcj"
    or gamedata.device.channel == "xmgame"  or gamedata.device.channel == "linnyou"  or gamedata.device.channel == "51iyx" or gamedata.device.channel == "yuwan" or gamedata.device.channel == "jrtt" or gamedata.device.channel == "nhdz" 
     or gamedata.device.channel == "changba" or gamedata.device.channel == "wanke" or gamedata.device.channel == "lb" or gamedata.device.channel == "7k7k" or gamedata.device.channel == "tiantian" or gamedata.device.channel == "aphy" 
     or gamedata.device.channel == "sw" or gamedata.device.channel == "yuewen" or gamedata.device.channel == "anzhi" or (gamedata.device.platform == "android" and gamedata.device.channel == "x7sy") 
     or (gamedata.device.platform == "android" and gamedata.device.channel == "lhh") or gamedata.device.channel == "huawein"  or (gamedata.device.platform == "android" and string.find(gamedata.device.channel,"qiyu")) then
    --if self.isaddLoginBtnPlat then
    self:showNode(self.enterLayerItem.channel_loginnode,false)
    end

    UIResponse({type = 9998, log = "" })

     --是否包含视屏播放
     if gamedata.gameconfig.haveVideo and gamedata.gameconfig.haveVideo == "true" then
         if self.enterLayerItem.videoButton then
            self.enterLayerItem.videoButton:setVisible(true)
            self.enterLayerItem.videoButton:addHandleOfControlEvent(function()
                self:videoPlay()
            end,CCControlEventTouchUpInside)
         end   
     end
     
end

function loginScene.checkOnlineTime(self,first)
    print("checkOnlineTime")
    if gamedata.sdk then
        print("holidays",gamedata.holidays)
        print("age",gamedata.age)
        print("onlinetime",gamedata.onlinetime)
        print("idCardStatus",gamedata.sdk.idCardStatus)
        print("channelname",gamedata.sdk.channelname)
    end

    if not gamedata.holidays or not gamedata.age or not gamedata.onlinetime then
        return
    end

    if not (gamedata.sdk and (gamedata.sdk.channelname == "muyoutest" or gamedata.sdk.channelname == "zuoyaojiapple2" or gamedata.sdk.channelname == "muyoughqnxs")) then
        return
    end

    if gamedata.sdk and gamedata.sdk.idCardStatus ~= 1 then
        return
    end

    local totaltime = (gamedata.holidays == 1 and 3 or 1.5) * 3600
    local lasttime = math.max(0,totaltime - gamedata.onlinetime)

    local des = ""
    if  gamedata.holidays == 0 then
        des = "尊敬的玩家您好，根据国家相关规定，未成年玩家每日游戏时间不得超过1.5小时，剩余时间："
    else
        des = "尊敬的玩家您好，根据国家相关规定，未成年玩家节假日游戏时间不得超过3小时，剩余时间："
    end
    des = des..string.format("%.2d时%.2d分",math.floor(lasttime/3600),math.floor(lasttime%3600/60))
    
    if lasttime <= 0 then
        gameWindowslogin:openWindow("shiming",{page = "tishi",des = "今日游戏时长已耗尽，明天将会恢复，请好好休息。剩余时间：0分钟"})
        return true
    elseif first then
        gameWindowslogin:openWindow("shiming",{page = "tishi",des = des})
    end
end

function loginScene.makeServerList(self)

    if self.mainlist and next(self.mainlist) then return end

    self.mainlist = {}
    self.sublist = {}

    local other = {}
    local totalnum = table.getTableLength(self.serverlist)
    local newserverlist = {}
    local MAXindex = 1

    for i=1,totalnum do
        local v = self.serverlist[tostring(i)]

        if (v.status == "offline" and not self.isdebug) or v.status == "fault" then
        else
            if v.id > 5000 then
                other[#other+1] = v
            else
                local index = math.floor((v.id-1)/10)+1
                if not self.mainlist[index] then
                    self.mainlist[index] = {title = (index*10-9).."~"..(index*10).."区" }
                    self.sublist[index] = {}
                end
                self.sublist[index][#self.sublist[index]+1] = v
                if MAXindex < index then MAXindex = index end
            end

            newserverlist[tostring(table.getTableLength(newserverlist)+1)] = v
        end
    end
    self.serverlist = newserverlist

    for i=1,MAXindex do
        if not self.mainlist[i] then 
            self.mainlist[i] = {title = (i*10-9).."~"..(i*10).."区" } 
        end
        if not self.sublist[i] then 
            self.sublist[i] = {} 
        end
    end

    if next(other) then
        table.insert(self.mainlist,{title = gameConfig.strings:string_common("loginScene",18)})
        self.sublist[#self.sublist+1] = {}
        for k,v in ipairs(other) do
            self.sublist[#self.sublist][#self.sublist[#self.sublist]+1] = v
        end
    end

    if self.recentlist and next(self.recentlist) then
        table.insert(self.mainlist,{title = gameConfig.strings:string_common("loginScene",13),type = "resent"})
        self.sublist[#self.sublist+1] = {}
        for i=1,table.getTableLength(self.recentlist) do
            if self.recentlist[tostring(i)] then
                self.sublist[#self.sublist][#self.sublist[#self.sublist]+1] = self.recentlist[tostring(i)]
            end
        end
    end
end

function loginScene.showServerList(self)

    if self.egameaboutnode then
        self.egameaboutnode:removeFromParentAndCleanup(true)
        self.egameaboutnode = nil
    end 

    self:showNode(self.enterLayerItem.processNode,false)
    self:showNode(self.enterLayerItem.enterNode,true)
    
    --显示腾讯登录
    self:showNode(self.enterLayerItem.tencentNode,false)
    self:showNode(self.enterLayerItem.userAgreement,false)  

    self:showNode(self.enterLayerItem.serverlistNode,true)
    self:showNode(self.enterLayerItem.connectnode,false)
    self.enterLayerItem.serverlistNode:setPositionY(gameConfig.topposY*0.5)

    self.enterLayerItem.closeBtn:addHandleOfControlEvent(function()
        self:showEnter()
    end, CCControlEventTouchUpInside)
    self.enterLayerItem.closeBtn:setSwallowsTouch(true)
    self.enterLayerItem.closeBtn:setTouchPriority(-103)

    self:makeServerList()
    printT(self.mainlist)
    printT(self.sublist)

    if not self.mainidx or self.mainidx> #self.mainlist then
        if self.mainlist[#self.mainlist].type and self.mainlist[#self.mainlist].type == "resent" then
            self.mainidx = #self.mainlist
        else
            self.mainidx = #self.mainlist-1
        end
    end

    print(self.mainidx)
    if not self.mainlistTableView then
        self:setmainlist()
    else
        self.mainlistTableView:reloadData()
    end

    if not self.sublistTableView then
         self:setsublist()
    else
         self.sublistTableView:reloadData()
    end
end

function loginScene.setmainlist(self)
    local celldict = {}
    local serverListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.maincellSize.width, self.maincellSize.height)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("Login/servercell4.ccbi", nil, true, "servercell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler}

                cellCCB:setPosition(self.maincellSize.width/2, self.maincellSize.height/2)
                a2:addChild(cellCCB)
            else

                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.setLabelString(ccbDocumentControler.des, self.mainlist[#self.mainlist-a1].title, 48)
            ccbDocumentControler.select:setVisible(self.mainidx==#self.mainlist-a1)
            ccbDocumentControler.nonselect:setVisible(self.mainidx~=#self.mainlist-a1)
            r = a2

        elseif fn == "numberOfCells" then
            r = #self.mainlist
        elseif fn == "cellTouched" then
            self.mainidx = #self.mainlist-a1:getIdx()
            print(self.mainidx,#self.sublist[self.mainidx]*self.subcellSize.height)
            self.mainlistTableView:reloadData()
            self.sublistTableView:setContentOffset(ccp(0, self.enterLayerItem["sublistScroll"]:getContentSize().height-#self.sublist[self.mainidx]*self.subcellSize.height))
            self.sublistTableView:reloadData()
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.enterLayerItem["mainlistScroll"]:removeAllChildrenWithCleanup(true)

    self["mainlistTableView"] = ui.createLuaTableView({
        handle = serverListHandle,
        viewwidth = self.enterLayerItem["mainlistScroll"]:getContentSize().width,
        viewheight = self.enterLayerItem["mainlistScroll"]:getContentSize().height,
        dire = 1
    })
    self["mainlistTableView"]:setTouchPriority(-101)
    self.enterLayerItem["mainlistScroll"]:addChild(self["mainlistTableView"])
    self["mainlistTableView"]:reloadData()
end

function loginScene.setsublist(self)
    local celldict = {}
    local serverListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.subcellSize.width, self.subcellSize.height)
        elseif fn == "cellAtIndex" then
            local cellCCB,item = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, item = CCBReaderLoad("Login/servercell.ccbi", nil, true, "servercell")
                celldict[a2] = {cellCCB=cellCCB,item=item}

                cellCCB:setAnchorPoint(ccp(0.5,0.5))
                cellCCB:setPosition(self.subcellSize.width/2, self.subcellSize.height/2)
                a2:addChild(cellCCB)
            else

                first = false
                cellCCB = celldict[a2].cellCCB
                item = celldict[a2].item
            end

            local key_Ex = ""
            local data = self.sublist[self.mainidx][a1+1]

            ui.setLabelString(item["name"..key_Ex], data.name, 14)
            ui.setLabelString(item["num"..key_Ex], gameConfig.strings:idStatus(data.id), 14)

            if data.status and (data.status == "maintain" or data.status == "maintain2") then
                setSpriteFrameByName(item["serverBgImg"..key_Ex], "login_3")
                setSpriteFrameByName(item["status"..key_Ex], "weihu")
            else
                if self.mainlist[1].type and self.mainlist[1].type == "resent" and self.mainidx ==1  then -- 最近登录
                    setSpriteFrameByName(item["serverBgImg"..key_Ex], "login_1")
                else -- 所有服务器
                    setSpriteFrameByName(item["serverBgImg"..key_Ex], "login_2")
                end
            end


            if data.tag and data.tag == "hot" then
                setSpriteFrameByName(item["status"..key_Ex], "baoman")
            elseif data.tag and data.tag == "new" then
                setSpriteFrameByName(item["status"..key_Ex], "tuijian")
            else
                setSpriteFrameByName(item["status"..key_Ex], "xinfu")
            end


--            item["cellBtn"..key_Ex]:setTouchPriority(-103)
--            item["cellBtn"..key_Ex]:addHandleOfControlEvent(function()
--                if gameTouch.isScrollling then return end
--                if data.status ~= "maintain" or self.isldfs then
--                    self.SelectedServer = data -- 点击返回修改
--                    self:showEnter()
--                end
--            end, CCControlEventTouchUpInside)

            r = a2

        elseif fn == "numberOfCells" then
            r = #self.sublist[self.mainidx]
        elseif fn == "cellTouched" then
            local data = self.sublist[self.mainidx][a1:getIdx()+1]
            if data.status ~= "maintain" or self.isldfs then
                self.SelectedServer = data -- 点击返回修改
                self:showEnter()
            else
                runGamePrompt({msg = "该区正在维护，请选择其他区游戏"})
            end
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.enterLayerItem["sublistScroll"]:removeAllChildrenWithCleanup(true)

    self["sublistTableView"] = ui.createLuaTableView({
        handle = serverListHandle,
        viewwidth = self.enterLayerItem["sublistScroll"]:getContentSize().width,
        viewheight = self.enterLayerItem["sublistScroll"]:getContentSize().height,
        dire = 1
    })
    self["sublistTableView"]:setTouchPriority(-101)
    self.enterLayerItem["sublistScroll"]:addChild(self["sublistTableView"])
    self["sublistTableView"]:reloadData()
end

function loginScene.initrequest(self,order)

    --    UIRequest({type = 1001}) --玩家信息
    --    UIRequest({type = 300}) --VIP状态信息
    --    UIRequest({type = 117}) --VIP信息
    --    UIRequest({type = 1002}) --基础信息
    --    UIRequest({type = 1012}) --武将魂魄
    --    UIRequest({type = 1200}) --道具信息
    --    UIRequest({type = 1107}) --装备碎片信息
    --    UIRequest({type = 2300}) --好友信息
    --    UIRequest({type = 1310}) --奇遇信息
    --    UIRequest({type = 1300}) --副本信息
    --    UIRequest({type = 1032}) --提示信息


    --UIRequest({type=999900, order = order,reqs= {1001,1300,1032}})
    local request =  {1001,300,117,3730,1200,1002,1012,1107,2300,1300,3610,1032,1054,1044,1040,3200,2000,1031,2230,1310,2090,1070,2144,1350,3780,3671}

    UIRequest({type=999900, order = order,reqs= request})

    if order == "datainit" then
        self:showConfigProcess({type = "datainit", index = 0,total = #request})
    end
end

function loginScene.checkGuide(self)
    UIRequest({type =200,param = "first"})
end

function loginScene.enterToGame(self)
--    loading:stopLoginloading()
    self:showConfigProcess({type = "datainit", index = 1,total = 1})

    self:clear()
    CCDirector:sharedDirector():replaceScene(mainScene)

    --GameScene:init(mainScene)
    --guide:palyOpenStory(1,8,function() guide:palyFirstBattle(function() guide:playStory9(function() guide:palyFirst(function() GameScene:init(mainScene) end) end) end ) end)

    --guide:palyFirst()

    UIRequest({type =200})
end

function loginScene.clear(self)
    self.rootLayer:removeFromParentAndCleanup(true)
    self.rootLayer = nil
    self.enterLayer = nil
    self.processLayer = nil

    self.serverlist = {}
    self.serverlistTableView = nil
    self.recentlist = {}
    self.recentlistTableView = nil
    self.SelectedServer = {}

    self.processLayer = nil
    self.processLayerItem =nil

    self.waitLayer = nil
    self.waitLayerItem =nil

    self.enterLayer = nil
    self.enterLayerItem = {}

    self.userCreateLayer = nil
    self.userCreateLayerItem = {}

    self.accountInputBox = nil
    self.passwordInputBox = nil

    texture.removeSpriteFramesWithFile("Login/login")

    CCTextureCache:sharedTextureCache():removeTextureForKey("Login/login.png")
    CCTextureCache:sharedTextureCache():removeTextureForKey("Login/login.pvr.ccz")
    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
    CCTextureCache:sharedTextureCache():removeUnusedTextures()
    --texture.removeSpriteFramesWithFile("Login/login.plist")

    self.egameaboutnode = nil
    self.egameaboutItem = {}

    self.status = false
end

function loginScene.UserInputResult(self,t)
    if (t.result == 0) then
        if tonumber(t.error) == 1 then
            -- runGamePrompt({msg = "用户名不存在"})
            runGamePrompt({msg = gameConfig.strings:string_common("loginScene",6)})
        elseif tonumber(t.error) == 2 then
            -- runGamePrompt({msg = "密码错误"})
            runGamePrompt({msg = gameConfig.strings:string_common("loginScene",7)})
        else
            -- runGamePrompt({msg = "用户名已存在"})
            runGamePrompt({msg = gameConfig.strings:string_common("loginScene",8)})
        end
        self:showUserInput(self.requestType)
    else
        self:hideUserInput()
    end
end

function loginScene.hideUserInput(self)
    self:showNode(self.enterLayerItem.accountNode,false)

    ui.removeInputEditBox(self.accountInputBox)
    ui.removeInputEditBox(self.passwordInputBox)
    self.accountInputBox = nil
    self.passwordInputBox = nil
end

function loginScene.showUserInput(self,requestType)
    self.requestType = requestType
    -- self.enterLayerItem.inputTitle:setString(self.requestType == 10 and "注册新账号" or "旧账号登录")
    -- self.enterLayerItem.inputTitle:setString(self.requestType == 10 and gameConfig.strings:string_common("loginScene",9) or gameConfig.strings:string_common("loginScene",10))
    if self.requestType == 10 then
        self.enterLayerItem.inputTitleSpr1:setVisible(true)
        self.enterLayerItem.inputTitleSpr2:setVisible(false)
    else
        self.enterLayerItem.inputTitleSpr2:setVisible(true)
        self.enterLayerItem.inputTitleSpr1:setVisible(false)
    end
    self:showNode(self.enterLayerItem.accountNode,true)

    self.enterLayerItem.userinputName:setString("")
    self.enterLayerItem.userpassword:setString("")
    ui.setLabelString(self.enterLayerItem.quitLab, nil, 19)
    ui.setLabelString(self.enterLayerItem.determineLab, nil, 19)
    
    local beginfunc = function(label)
        label:setString("")
    end

    local endfunc = function(label,text,box)
        label:setString(text)
        box:setText("")
    end
    if not self.accountInputBox then
        self.accountInputBox = ui.creatInputEditBoxBylable(self.enterLayerItem.userinputName,kEditBoxInputModeSingleLine,beginfunc,endfunc,
            {
                fontSize = 40,
                fontColor = ccc3(255, 255, 255),
                nochecksensitive = true
            })
        self.accountInputBox:setTouchPriority(-10)
    end
    if not self.passwordInputBox then
        self.passwordInputBox = ui.creatInputEditBoxBylable(self.enterLayerItem.userpassword,kEditBoxInputModeSingleLine,beginfunc,endfunc,
            {
                fontSize = 40,
                fontColor = ccc3(255, 255, 255),
                nochecksensitive = true
            })
        self.passwordInputBox:setTouchPriority(-10)
    end

    self.enterLayerItem.userconfirm:addHandleOfControlEvent(function()
        print("userconfirm")
        if self.enterLayerItem.userinputName:getString() == "" then
            -- runGamePrompt({msg = "邮箱格式错误"})
            runGamePrompt({msg = gameConfig.strings:string_common("loginScene",11)})
            self:showUserInput(self.requestType)
        elseif self.enterLayerItem.userpassword:getString() == ""  then
            -- runGamePrompt({msg = "密码不能为空"})
            runGamePrompt({msg = gameConfig.strings:string_common("loginScene",12)})
        else
            self.userdata =  {user = self.enterLayerItem.userinputName:getString()}
            
            local acctest = require"accbyhttp/http_acctest"
            if self.requestType == 10 then
                acctest:userrigist()
            elseif self.requestType == 11 then
                acctest:userlogin()
            end
        end

    end, CCControlEventTouchUpInside)

    self.enterLayerItem.userconcel:addHandleOfControlEvent(function()
        print("userconcel")
        self:hideUserInput()
    end, CCControlEventTouchUpInside)
end

function loginScene.egameabout(self)
    if self.egameaboutnode ~= nil then 
       self.egameaboutnode:removeFromParentAndCleanup(true)
       self.egameaboutnode = nil
    else
       self.egameaboutnode,self.egameaboutItem = CCBReaderLoad("Login/egame_about.ccbi", nil, true, "egame_about")
       self.egameaboutnode:setPosition(self.d_viewSize.width/2,self.d_viewSize.height/2)
       self.rootLayer:addChild(self.egameaboutnode,3)
       self.egameaboutnode:setScale(gameConfig.scaleNum)
       self.egameaboutItem.closeButton:addHandleOfControlEvent(function()
       self.egameaboutnode:removeFromParentAndCleanup(true)
       self.egameaboutnode = nil
       end, CCControlEventTouchUpInside)
    end    
end

function loginScene.init(self,loginscene,isrelog)

    self.isrelog = isrelog

    self.rootLayer = CCLayerColor:create(ccc4(0,0,0,255))
    self.rootLayer:setColor(ccc3(0, 0, 0))
    self.rootLayer:setContentSize(CCSizeMake(self.d_viewSize.width, self.d_viewSize.height))
    self.rootLayer:setAnchorPoint(ccp(0,0))
    self.rootLayer:setPosition(ccp(0,0))
    loginscene:addChild(self.rootLayer)

    self.enterLayer,self.enterLayerItem = CCBReaderLoad("Login/login2.ccbi", nil, true, "login")
    self.enterLayer:setPosition(self.d_viewSize.width/2,gameConfig.fixH)
    self.rootLayer:addChild(self.enterLayer,1)
    self.enterLayer:setScale(gameConfig.scaleNum)

    if self.enterLayerItem.topnode then
        self.enterLayerItem.topnode:setPositionY(gameConfig.topposY)
    end
    self.enterLayerItem.logonode:setPositionY(gameConfig.topposY-1920)
    self.enterLayerItem.loadingNode:setPositionY(gameConfig.topposY*0.5)


    if self.enterLayerItem.ageTips then
        self.enterLayerItem.ageTips:addHandleOfControlEvent(function()
            print("ageTips")
            gameWindowslogin:openWindow("ageTips")
        end, CCControlEventTouchUpInside)
    end
    

    self.enterLayerItem.logbutton:addHandleOfControlEvent(function()
        self.logtag=self.logtag+1
        if self.logtag >=5 then 
            gamedata.isshowlog = true
            runGamePrompt({msg = "调试模式开启"})
        end
    end, CCControlEventTouchUpInside)

    if MYGameSendData and MYGameSendData.InitSuccess then
        MYGameSendData:InitSuccess()
    end

    --进入游戏按钮点击
    self.enterLayerItem.EnterButton:addHandleOfControlEvent(function()
        if not next(self.SelectedServer) then return end
        self:loginGame()

    end, CCControlEventTouchUpInside)



    if string.find(gamedata.device.channel,"qq")~=nil or string.find(gamedata.device.channel,"weixin")~=nil  or string.find(gamedata.device.channel,"tencent")~=nil  then
        gamedata.sdk.channel.loginId = 1;
    end

    self.enterLayerItem.weixin_login:addHandleOfControlEvent(function()
       -- self:showNode(self.enterLayerItem.loadingNode,true)
       if gamedata.sdk.channel.loginId and (gamedata.sdk.channel.loginId == 1) then
             if string.find(gamedata.device.channel,"qq1") then
                 sdk:LoginTencent("weixin1")
             elseif string.find(gamedata.device.channel,"17") then 
                  sdk:LoginTencent("17weixin")
             else
                sdk:LoginTencent("weixin")
             end   
            
        else
            runGamePrompt({ msg = "正在登陆中请稍后" })
        end
        --sdk:LoginTencent("weixin");
    end, CCControlEventTouchUpInside)

    self.enterLayerItem.qq_login:addHandleOfControlEvent(function()
      --  self:showNode(self.enterLayerItem.loadingNode,true)
       if gamedata.sdk.channel.loginId and (gamedata.sdk.channel.loginId == 1) then
             if string.find(gamedata.device.channel,"qq1") then
                 sdk:LoginTencent("qq1")
            elseif string.find(gamedata.device.channel,"17") then 
                  sdk:LoginTencent("17qq")
             else
                sdk:LoginTencent("qq")
             end            
        else
            runGamePrompt({ msg = "正在登陆中请稍后" })
        end
        --sdk:LoginTencent("qq");
    end, CCControlEventTouchUpInside)


    self.enterLayerItem.leshi_changeuser:addHandleOfControlEvent(function()
        sdk:changeUser();
    end,CCControlEventTouchUpInside)


    local isBtnClick = false
    self.enterLayerItem.channel_login:addHandleOfControlEvent(function()
        if isBtnClick then
           return
        else                      
            isBtnClick = true
            self.rootLayer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5), CCCallFunc:create(function()
                isBtnClick = false
            end)))
        end
        sdk:BtnChannelLogin();

    end,CCControlEventTouchUpInside)


    --关于按钮
    self.enterLayerItem.egame_about:addHandleOfControlEvent(function()
          self:egameabout()
    end,CCControlEventTouchUpInside)
    --更多游戏按钮
    self.enterLayerItem.egame_moregame:addHandleOfControlEvent(function()
        sdk:EgameMoreGame();
    end,CCControlEventTouchUpInside)
  

    self.enterLayerItem.newuser:addHandleOfControlEvent(function()
        if sdk:isValid() then
            sdk:changeUser()
            --sdk:Recharge("0000000001", 0.01, "test", "test desc")
        else
            self:showUserInput(10)
        end
    end, CCControlEventTouchUpInside)
    self.enterLayerItem.userlogin:addHandleOfControlEvent(function()
        if sdk:isValid() then
            sdk:changeUser()
            --sdk:Recharge("0000000001", 0.01, "test", "test desc")
        else
            self:showUserInput(11)
        end
    end, CCControlEventTouchUpInside)
    self:showNode(self.enterLayerItem.accountNode,false)


    self.status = true
    self.configrate = 0
    self.loadconfigrate = 0
    self.resourcerate = 0
    self.loadresourcerate = 0


    if bRunWithScene then
         if haveVideo then
            CCDirector:sharedDirector():replaceScene(loginscene)
        else
            CCDirector:sharedDirector():runWithScene(loginscene)
        end   
        -- CCDirector:sharedDirector():runWithScene(loginscene)
    else
        if CCDirector:sharedDirector():getRunningScene() ~= loginscene then
            CCDirector:sharedDirector():replaceScene(loginscene)
        end
    end

    local gameversion = require"config_version"
    if gameversion.showversion then 
        gameversion:showversion(loginscene)
    end

    self:reloadUserAgreement()

    print("loginScene init============")

    if self.isdebug then
        if self.enterLayerItem.oldbuttonNode then
            self.enterLayerItem.oldbuttonNode:setVisible(true)
        end
    else
        if self.enterLayerItem.oldbuttonNode then
            self.enterLayerItem.oldbuttonNode:setVisible(false)
        end
    end

    if self.showGameNotice then self:showGameNotice() end
end


function loginScene.reloadUserAgreement(self)
    if not gameWindowslogin then
        gameWindowslogin = require"GameWindowsLogin"
        gameWindowslogin:init()
    end
    --用户协议勾选
    if self.enterLayerItem.userAgreement then

        self.enterLayerItem.userAgreementBtn:setSwallowsTouch(true)
        self.enterLayerItem.userAgreementBtn:setTouchPriority(-103)

        self.enterLayerItem.privacyAgreementBtn:setSwallowsTouch(true)
        self.enterLayerItem.privacyAgreementBtn:setTouchPriority(-103)

        self.enterLayerItem.userAgreementBtn:addHandleOfControlEvent(function()
            gameWindowslogin:openWindow("userAndPrivacyAgreement",{type = 0},function()end)
        end, CCControlEventTouchUpInside)
        self.enterLayerItem.privacyAgreementBtn:addHandleOfControlEvent(function()
            gameWindowslogin:openWindow("userAndPrivacyAgreement",{type = 1},function()end)
        end, CCControlEventTouchUpInside)
        

        local _str = CCUserDefault:sharedUserDefault():getStringForKey("isfirstAgreementUnselect")
        if CCUserDefault:sharedUserDefault():getStringForKey("userAgreement") ~= "true" then
            self.enterLayerItem.yessprite:setVisible(false)
        else
            if _str ~= "true" then
                print("没有勾选之前，都不可见")
                self.enterLayerItem.yessprite:setVisible(false)
            else
                self.enterLayerItem.yessprite:setVisible(true)
            end    
        end
        self.enterLayerItem.yesBtn:addHandleOfControlEvent(function()
            if _str ~= "true" then
                print("没有勾选之前，直接选择勾选")
                CCUserDefault:sharedUserDefault():setStringForKey("isfirstAgreementUnselect","true")
                self.enterLayerItem.yessprite:setVisible(true)
                self:reloadUserAgreement()
            else
                print("勾选之后，直接取消勾选")
                CCUserDefault:sharedUserDefault():setStringForKey("isfirstAgreementUnselect","false")
                self.enterLayerItem.yessprite:setVisible(false)
                self:reloadUserAgreement()
            end    

        end, CCControlEventTouchUpInside)



    end
end

function loginScene.showOpt(self)
    if string.find(gamedata.device.channel,"qq")~=nil or string.find(gamedata.device.channel,"weixin")~=nil  or string.find(gamedata.device.channel,"tencent")~=nil then
        print("tencent show  ---------------")
        self:showNode(self.enterLayerItem.tencentNode,true)
        self:showNode(self.enterLayerItem.userAgreement,false)  
        self:showNode(self.enterLayerItem.loadingNode,false)
    else
        self:showNode(self.enterLayerItem.tencentNode,false)
        self:showNode(self.enterLayerItem.userAgreement,false)  
    end

    --切换账号按钮
    if gamedata.device.channel == "leshi"  or gamedata.device.channel == "yuewen" or gamedata.device.channel == "yuxiang" 
        or gamedata.device.channel == "cxsm" or gamedata.device.channel == "cxyx" or string.find(gamedata.device.channel,"17") then

        self:showNode(self.enterLayerItem.leshiChangeCountNode,false)
    end

    --登录游戏按钮
    if  gamedata.device.channel == "anqu" or gamedata.device.channel == "zy" or gamedata.device.channel == "sogou" or gamedata.device.channel == "pyw" or gamedata.device.channel == "lenovo" or gamedata.device.channel == "chujiana" or gamedata.device.channel == "baiducmcj"
            or gamedata.device.channel == "xmgame"  or gamedata.device.channel == "linnyou"  or gamedata.device.channel == "51iyx" or gamedata.device.channel == "yuwan" or gamedata.device.channel == "jrtt" or gamedata.device.channel == "nhdz"
            or gamedata.device.channel == "changba" or gamedata.device.channel == "wanke" or gamedata.device.channel == "lb" or gamedata.device.channel == "aphy"  or gamedata.device.channel == "sw" or gamedata.device.channel == "yuewen" or gamedata.device.channel == "anzhi" or (gamedata.device.platform == "android" and gamedata.device.channel == "x7sy")
            or (gamedata.device.platform == "android" and gamedata.device.channel == "lhh") or gamedata.device.channel == "styj" or gamedata.device.channel == "huawein"  or (gamedata.device.platform == "android" and string.find(gamedata.device.channel,"qiyu")) then

        -- if self.isaddLoginBtnPlat then
        --self:showNode(self.enterLayerItem.channel_loginnode,true)
        self:showNode(self.enterLayerItem.loadingNode,false)
    end

    if gamedata.device.channel == "egame" then
        self:showNode(self.enterLayerItem.egameMoreGamenode,true)
    end
end

function loginScene.reset(self)
    self:showNode(self.enterLayerItem.loadingNode,false)
    self:showNode(self.enterLayerItem.serverlistNode,false)
    self:showNode(self.enterLayerItem.enterNode,false)

    --切换账号按钮
    if gamedata.device.channel == "leshi"  or gamedata.device.channel == "yuewen" or gamedata.device.channel == "yuxiang" 
        or gamedata.device.channel == "cxsm" or gamedata.device.channel == "cxyx" or string.find(gamedata.device.channel,"17") then

        self:showNode(self.enterLayerItem.leshiChangeCountNode,false)
    end

    --登录游戏按钮
    if  gamedata.device.channel == "anqu" or gamedata.device.channel == "zy" or gamedata.device.channel == "sogou" or gamedata.device.channel == "pyw" or gamedata.device.channel == "lenovo" or gamedata.device.channel == "chujiana" or gamedata.device.channel == "baiducmcj"
            or gamedata.device.channel == "xmgame"  or gamedata.device.channel == "linnyou"  or gamedata.device.channel == "51iyx" or gamedata.device.channel == "yuwan" or gamedata.device.channel == "jrtt" or gamedata.device.channel == "nhdz"
            or gamedata.device.channel == "changba" or gamedata.device.channel == "wanke" or gamedata.device.channel == "lb" or gamedata.device.channel == "7k7k" or gamedata.device.channel == "tiantian" or gamedata.device.channel == "aphy" 
             or gamedata.device.channel == "sw" or gamedata.device.channel == "yuewen" or gamedata.device.channel == "anzhi" or (gamedata.device.platform == "android" and gamedata.device.channel == "x7sy") 
             or (gamedata.device.platform == "android" and gamedata.device.channel == "lhh") or gamedata.device.channel == "huawein"  or (gamedata.device.platform == "android" and string.find(gamedata.device.channel,"qiyu"))  then

        -- if self.isaddLoginBtnPlat then
        self:showNode(self.enterLayerItem.channel_loginnode,true)
        self:showNode(self.enterLayerItem.loadingNode,false)
    end

    if gamedata.device.channel == "egame" then
        self:showNode(self.enterLayerItem.egameMoreGamenode,true)
    end
end

function loginScene.showGameNotice(self)
    local needgamenotice = {
        papa = true,
        xy = true,
    }
    
    print("showGameNotice",gamedata.device.channel)
    if gamedata.device.channel and needgamenotice[gamedata.device.channel] then
        local sp1 = CCSprite:create("Login/notice1.jpg")
        if sp1 then
            pauseUIUpdate()
            self.enterLayerItem.EnterButton:setEnabled(false)
            sp1:setAnchorPoint(ccp(0.5,0.5))
            sp1:setScale(self.d_viewSize.width/sp1:getContentSize().width)
            sp1:setPosition(ccp(self.d_viewSize.width/2,self.d_viewSize.height/2))
            self.rootLayer:addChild(sp1,100)

            sp1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(3), CCCallFunc:create(function()
                local sp2 = CCSprite:create("Login/notice2.jpg")
                if sp2 then
                    sp1:setDisplayFrame(sp2:displayFrame())
                    sp1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2), CCCallFunc:create(function()
                        sp1:removeFromParentAndCleanup(true)
                        self.enterLayerItem.EnterButton:setEnabled(true)
                        startUIUpdate()
                    end)))
                else
                    sp1:removeFromParentAndCleanup(true)
                    self.enterLayerItem.EnterButton:setEnabled(true)
                    startUIUpdate()
                end
            end)))
        end
    end
end

function loginScene.loginGame(self)

    if self:checkOnlineTime() then
        --在线时间超限
        return
    end

   if gamedata.gameconfig.haveVideo and gamedata.gameconfig.haveVideo == "true" then
         if loginsceneVideo then
             print("LoginScene 视频没播完，别想进游戏")
             return
        end 
    end 

    if self.isdebug and (not self.userdata or not self.userdata.user or self.userdata.user == "") then
            runGamePrompt({msg = "请注册新账号或用旧账号登陆"})
        else
            if self.SelectedServer.status ~= "maintain" or self.isldfs then
                self.isrelog = nil
                gameWindows.windows["roleinfo"].module.SelectedServer = self.SelectedServer
                self:showConfigProcess({type = "config", index = 5, total = 10,time = 0.5})
                
                local entergame = require"accbyhttp/http_entergame"
                entergame:entergame({
                    sid = tonumber(self.SelectedServer.id),
                    session = gamedata.session
                    })

                local gameversion = require"config_version"
                if gameversion.showServerandUser then 
                    gameversion:showServerandUser(loginscene)
                end

                if gamedata.gameconfig and gamedata.gameconfig.isshengduTG then
                    if gamedata.sdk and gamedata.sdk.sdkShengDu then
                        gamedata.sdk:sdkShengDu("login")
                    end    
                end 

            else
                runGamePrompt({msg = "当前区正在维护，请选择其他区游戏"})
            end
    end
    if self.egameaboutnode then
          self.egameaboutnode:removeFromParentAndCleanup(true)
          self.egameaboutnode = nil
    end 

end

function loginScene.videoPlay(self)
     print("LoginScene videoPlay")
     loginsceneVideo = true
     if isNewEngine then
       videoscene = require"adpat_code/VideoScene.lua"
     else
       videoscene = require"VideoScene.lua"
     end   

      videoscene:createVideoScene() 
end


return loginScene