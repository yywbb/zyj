--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/30
-- Time: 下午4:37
-- To change this template use File | Settings | File Templates.
--


local wudaomain = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    PojunListTableView = nil,
    TanlanghListTableView = nil,

    data= {},

    pagesname = {"破军","贪狼"},
    pages = {"pojun","tanlang"},
    choosepage = "pojun",

    -- 活动时间
    begintimenum = {week=3,hour=20,min=30,sec=0},
    endtimenum = {week=3,hour=21,min=0,sec=0},
    finaltimenum = {week=3,hour=21,min=10,sec=0},


    isout = false, --不在活动时间 被强制弹出
    reportdata = nil,
    normalCellSize = {x = 900, y = 200},
    ListTableView = nil,
    sizeT = {},

    ispipei = false,

    xiandouchangeNum = 0,--匹配成功后仙豆变化数
}



function wudaomain.init(self,parent,toppos)
    print("wudaomain===")
    self.rootNode,self.rootItems = CCBReaderLoad("wudaohui/wudaohui.ccbi", nil, true, "wudaohui")
    print("test01")
    self.rootNode:setPosition(-540,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.middlenode:setPositionY(toppos-150)

    self.rootItems.aboutBtn:setTouchPriority(-103)
    self.rootItems.aboutBtn:addHandleOfControlEvent(function()
        print("说明")
        gameWindows:openWindow("wudaohuipipei",{index = "rule"},nil)
    end, CCControlEventTouchUpInside)

    self.rootItems.shopBtn:setTouchPriority(-103)
    self.rootItems.shopBtn:addHandleOfControlEvent(function()
        print("商店抽奖")
        GameScene:shiftLayerById(193)
    end, CCControlEventTouchUpInside)


    -- 武道会基础信息查询
    UIRequest({type = 4100})
    -- -- 武道会战报查询
    UIRequest({type = 4104})
end



function wudaomain.reloaddata(self,data,part_point)
    printT(data,"reloaddata＝＝＝")
    if not data then return end  
    print("data.mynowscorenum==",data.mynowscorenum)
    if self.oldxiandounum then
        self.xiandouchangeNum = data.mynowscorenum - self.oldxiandounum
        -- print("changelevel22222==",self.levelchangeNum)
    end
    print("self.oldxiandounum",self.oldxiandounum,self.xiandouchangeNum)

    self.oldxiandounum = data.mynowscorenum
    self.data = data or {}
    self.part_point = part_point or 0

    if self.data.teamnum == 1  then
        
        self.rootItems.pojuneffect:setVisible(true)
        self.rootItems.tanlangeffect:setVisible(false)
        self.rootItems.pojunnode:setContentSize(CCSizeMake(934,425))
        self.rootItems.tanlangnode:setContentSize(CCSizeMake(934,525))
    else
        self.rootItems.pojuneffect:setVisible(false)
        self.rootItems.tanlangeffect:setVisible(true)
        self.rootItems.pojunnode:setContentSize(CCSizeMake(934,525))
        self.rootItems.tanlangnode:setContentSize(CCSizeMake(934,425))
    end

    self.rootItems.rankStageBtn:setTouchPriority(-103)
    self.rootItems.rankStageBtn:addHandleOfControlEvent(function()
        print("段位")
        -- self:shiftNode("firstNode")
        gameWindows:openWindow("wudaohuiduanwei",{myallscorenum=self.data.myallscorenum})
        -- GameScene:shiftLayer("devilcollect",nil,{petsData = self.petdata, petFragmentData = self.petFragmentData})

    end, CCControlEventTouchUpInside)
    

    self.rootItems.pojunPageBtn:setTouchPriority(-103)
    self.rootItems.pojunPageBtn:addHandleOfControlEvent(function()
        print("破军阵营")
        self:shiftPage("pojun")
    end, CCControlEventTouchUpInside)

    self.rootItems.tanlangPageBtn:setTouchPriority(-103)
    self.rootItems.tanlangPageBtn:addHandleOfControlEvent(function()
        print("贪狼阵营")
        self:shiftPage("tanlang")
    end, CCControlEventTouchUpInside)



    -- 设置攻打次数
    local globalconfig = gamedata.config.global_kv
    ui.setLabelString(self.rootItems.fightnumText,nil,13)
    local fightnum = (globalconfig.wudao_challenge_times and globalconfig.wudao_challenge_times.value or 0) - self.data.fightnum
    ui.setLabelString(self.rootItems.fightnumLabel, fightnum, 21)
    
    if fightnum <= 0 then
        ui.addGray("CCControlButton",self.rootItems.doButton)
    else
        ui.removeGray("CCControlButton",self.rootItems.doButton)
    end
    
    ui.setLabelString(self.rootItems.doLab,"开始匹配",19)
    self.rootItems.doButton:setTouchPriority(-103)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        print("战斗匹配")
        if fightnum <= 0 then
            runGamePrompt({msg = "没有匹配次数，不可挑战"})
            return
        end
        if self.isout == true then
            runGamePrompt({msg = "不在活动时间内，不可匹配"})
            return
        end
        if self.ispipei == false then
            ui.setLabelString(self.rootItems.doLab,"匹配中...",19)

            -- local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(5), CCCallFunc:create(function() 
                UIRequest({type = 4101,id = 0})
            -- end))
            -- self.rootItems.doButton:runAction(sequence)

            self:pipeiupdatetime()
            self.ispipei = true
        else
            -- gameTimer:UnrigistTimeFunc("wudaohui_main_pipeisuccess_delay")
            self.rootItems.doButton:stopAllActions()
            ui.setLabelString(self.rootItems.doLab,"开始匹配",19)

            gameTimer:UnrigistTimeFunc("wudaohui_pipei")
            UIRequest({type = 4101,id = 1})
            self.ispipei = false
        end

        -- self:shiftPage("tanlang")
        -- gameWindows:openWindow("wudaohuipipei",{index = "pipei"},nil)

    end, CCControlEventTouchUpInside)


    

    self.rootItems.pojunAllSoreLabel:setString(self.data.teamscore1 or 0)
    self.rootItems.tanlangAllSoreLabel:setString(self.data.teamscore2 or 0)
    
    -- 设置宝箱信息状态
    for i =1, 3 do
        self:setRewardStatus(i)
    end
    self:setmydata()
    self.choosepage = self.pages[tonumber((self.data.teamnum) or 1)]
    self:shiftPage(self.choosepage)
    -- 战报预览
    self:setWarDataShow()
    -- 设置排行榜刷新
    self:ranklistUpdateSet()
    -- 武道会倒计时设置
    self:setTimeData()

    self:sethit()
end

-- 设置红点提示
function wudaomain.sethit( self )
    local hitstatus = false
    if tonumber(self.data.hintstatus) ~= 0 then
        hitstatus = true
    end
    ui.sethint(self.rootItems.hint,hitstatus)
end

-- 匹配倒计时
function wudaomain.pipeiupdatetime(self)
    
    local pipeidelaynum = self.data.pipeiupdatetimenum or 10
    gameTimer:rigistTime("wudaohui_pipei", pipeidelaynum)
    gameTimer:rigistTimeFunc("wudaohui_pipei",function()
        
        if gameTimer.times["wudaohui_pipei"] >= 0 then
            -- ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeText(gameTimer.times["wudaohui_pipei"],"hour"),21)
            print("1111111====",ui.makeTimeText(gameTimer.times["wudaohui_pipei"],"hour"))
            -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
        end
        if gameTimer.times["wudaohui_pipei"] == 0 then
            print("wudaohui_pipei====")
            gameTimer:UnrigistTimeFunc("wudaohui_pipei")

            self:pipeiupdatetime()
            UIRequest({type = 4101,id = 0})
        end
    end)
end


function wudaomain.setFirstStatus( self )
    -- 领取奖励 取消自动匹配
    ui.setLabelString(self.rootItems.doLab,"开始匹配",19)

    
    gameTimer:UnrigistTimeFunc("wudaohui_pipei")
    if self.ispipei == true then
        local runstrings = "领取奖励，请重新匹配战斗"
        runGamePrompt({msg = runstrings})

        UIRequest({type = 4101,id = 1})
    end
    self.ispipei = false
end

-- 战斗结束后 胜利放自动匹配，失败放结束匹配
function wudaomain.setFightEndData( self, result )
    print("setFightEndData===",result,self.xiandouchangeNum)
    -- 设置攻打次数
    local globalconfig = gamedata.config.global_kv
    local fightnum = (globalconfig.wudao_challenge_times and globalconfig.wudao_challenge_times.value or 0) - self.data.fightnum
    
    
    if fightnum <= 0 then
        self.ispipei = false
        runGamePrompt({msg = "已经没有匹配次数，不可挑战"})
        return
    end

    if tonumber(result) == 1 then
        print("战斗胜利＝＝＝")
        -- 胜利
        if self.isout == false then
            ui.setLabelString(self.rootItems.doLab,"匹配中...",19)

            local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(5), CCCallFunc:create(function() 
                print("战斗胜利，sequence＝＝＝")
                UIRequest({type = 4101,id = 0})
            end))
            self.rootItems.doButton:runAction(sequence)

            self:pipeiupdatetime()
            self.ispipei = true
        end
        

        gameTimer:rigistTime("wudaohui_main_pipeisuccess_delay", 1)
        gameTimer:rigistTimeFunc("wudaohui_main_pipeisuccess_delay",function()
            print("wudaohui_main_pipeisuccess_delay====",gameTimer.times["wudaohui_main_pipeisuccess_delay"])
          
            if gameTimer.times["wudaohui_main_pipeisuccess_delay"] == 0 then
                print("wudaohui_main_pipeisuccess_delay====")
                gameTimer:UnrigistTimeFunc("wudaohui_main_pipeisuccess_delay")
                
                local runstrings = "战斗胜利,获得仙豆数："..(self.xiandouchangeNum or 0)
                print("runstrings-==",runstrings)
                runGamePrompt({msg = runstrings})
            end
        end)

    else
        print("战斗失败＝＝＝")
        -- 失败
        ui.setLabelString(self.rootItems.doLab,"开始匹配",19)
        

        gameTimer:UnrigistTimeFunc("wudaohui_pipei")
        if self.ispipei == true then
            UIRequest({type = 4101,id = 1})
        end
        self.ispipei = false

        gameTimer:rigistTime("wudaohui_main_pipeisuccess_delay", 1)
        gameTimer:rigistTimeFunc("wudaohui_main_pipeisuccess_delay",function()
            print("wudaohui_main_pipeisuccess_delay====",gameTimer.times["wudaohui_main_pipeisuccess_delay"])
          
            if gameTimer.times["wudaohui_main_pipeisuccess_delay"] == 0 then
                print("wudaohui_main_pipeisuccess_delay====")
                gameTimer:UnrigistTimeFunc("wudaohui_main_pipeisuccess_delay")
                
                local runstrings = "战斗失败,获得仙豆数："..(self.xiandouchangeNum or 0).."，取消继续匹配"
                print("runstrings-==",runstrings)
                runGamePrompt({msg = runstrings})
            end
        end)

    end
end

function wudaomain.setWarDataShow( self )
    print("setWarDataShow===")

    self.rootItems.closeNode:setVisible(false)
    self.rootItems.openNode:setVisible(true)
    self.rootItems.zhanbaoNode:setPosition(-9999,0)



    self.rootItems.closeBtn:setTouchPriority(-104)
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        print("close战报")
        self.rootItems.closeNode:setVisible(false)
        self.rootItems.openNode:setVisible(true)
        -- self:shiftPage("tanlang")
        -- gameWindows:openWindow("wudaohuipipei",nil,nil)
        self.rootItems.zhanbaoNode:setVisible(false)
        self.rootItems.zhanbaoNode:setPosition(-9999,0)
    end, CCControlEventTouchUpInside)

    self.rootItems.openBtn:setTouchPriority(-104)
    self.rootItems.openBtn:addHandleOfControlEvent(function()
        print("open战报")
        self.rootItems.closeNode:setVisible(true)
        self.rootItems.openNode:setVisible(false)
        -- self:shiftPage("tanlang")
        -- gameWindows:openWindow("wudaohuipipei",nil,nil)
        self.rootItems.zhanbaoNode:setVisible(true)
        self.rootItems.zhanbaoNode:setPosition(0,0)

    end, CCControlEventTouchUpInside)

    
end

function wudaomain.setReportData( self, data )
    -- printT(data,"setReportData===")
    if not data then
        return
    end
    self.reportdata = {}

    --数据排序
    for k, v in pairs(data.report) do
        if v and type(v) == "table" then
            table.insert(self.reportdata,v)
        end
    end 
    -- printT(self.reportdata,"reportdata===")
    local sortfunc = function(a,b)
        return a.fightnum > b.fightnum
    end
    table.sort(self.reportdata,sortfunc)
    --创建richlabel 和创建表
    self:getSizeTable()
    --创建表
    if self.ListTableView then
        self.ListTableView:reloadData()
        if next(self.sizeT) then
            local sizeheightnum = 0
            for k,v in pairs(self.sizeT) do
                sizeheightnum = sizeheightnum + v.height
            end
            print("sizeheightnum===",sizeheightnum)
            self.ListTableView:setLuaContentOffset(0, self.rootItems.listNode:getContentSize().height - sizeheightnum)
        end

    else
        self:createList()
    end
    
end

function wudaomain.getSizeTable(self)
    -- if next(self.sizeT) then return end
    if self.changexiandounum ~= 0 and self.changexiandounum == table.getTableLength(self.reportdata) then
        return
    end
    if next(self.reportdata) then
        self.changexiandounum = table.getTableLength(self.sizeT)
    end  
    self.sizeT = {}


    print("getSizeTable====")
    for i= 1, table.getTableLength(self.reportdata) do
    -- for i= 1, 20 do
        if self.reportdata[i] and self.reportdata[i].opt then
            local str = self:ctRichLabel(self.reportdata[i])
            -- printT(str,"str=====")
            local container = CCNode:create()
            container:setAnchorPoint(ccp(0,1))
            container:setContentSize(CCSizeMake(900,20))
            container:retain()
            self.sizeT[i] = {
                height = ui.createRichLabel(str,container,false)+20,
                container = container
            }
        end
    end
    printT(self.sizeT)
end

--创建richlabel的模板
function wudaomain.ctRichLabel(self,richdata)
    -- printT(richdata,"richdata===")
    local str = {}
    -- local richtime = os.date("(%Y-%m-%d %H:%M)",richdata.times) 
    if richdata.opt == 1 then
        -- table.insert(str,{fontID = 5, content = richtime})
        table.insert(str,{fontID = 5, content = "您的队伍战胜了"})
        table.insert(str,{fontID = 1, content = richdata.name})
        table.insert(str,{fontID = 5, content = "的队伍，当前场次第"})
        table.insert(str,{fontID = 5, content = tostring(richdata.fightnum)})
        table.insert(str,{fontID = 5, content = "场"})
    elseif richdata.opt == 2 then
        -- table.insert(str,{fontID = 5, content = richtime})
        table.insert(str,{fontID = 3, content = tostring(richdata.mystraightwinnum)})
        table.insert(str,{fontID = 3, content = "连胜！"})
        table.insert(str,{fontID = 5, content = "您的队伍战胜了"})
        table.insert(str,{fontID = 1, content = richdata.name})
        table.insert(str,{fontID = 5, content = "的队伍，获得"})
        table.insert(str,{fontID = 5, content = tostring(richdata.mystraightwinnum)})
        table.insert(str,{fontID = 5, content = "连胜奖"})
        table.insert(str,{fontID = 5, content = "，当前场次第"})
        table.insert(str,{fontID = 5, content = tostring(richdata.fightnum)})
        table.insert(str,{fontID = 5, content = "场"})

    elseif richdata.opt == 3 then
        -- table.insert(str,{fontID = 5, content = richtime})
        table.insert(str,{fontID = 3, content = tostring(richdata.mystraightwinnum)})
        table.insert(str,{fontID = 3, content = "连胜！"})
        table.insert(str,{fontID = 5, content = "您的队伍战胜了"})
        table.insert(str,{fontID = 1, content = richdata.name})
        table.insert(str,{fontID = 5, content = "的队伍，获得"})
        table.insert(str,{fontID = 5, content = tostring(richdata.mystraightwinnum)})
        table.insert(str,{fontID = 5, content = "连胜奖"})
        table.insert(str,{fontID = 5, content = "，并将对方的"})
        table.insert(str,{fontID = 5, content = tostring(richdata.otherstraightwinnum)})
        table.insert(str,{fontID = 5, content = "连胜终结"})
        table.insert(str,{fontID = 5, content = "，当前场次第"})
        table.insert(str,{fontID = 5, content = tostring(richdata.fightnum)})
        table.insert(str,{fontID = 5, content = "场"})
    elseif richdata.opt == 4 then
        table.insert(str,{fontID = 5, content = "您的队伍输给了"})
        table.insert(str,{fontID = 1, content = richdata.name})
        table.insert(str,{fontID = 5, content = "的队伍，当前场次第"})
        table.insert(str,{fontID = 5, content = tostring(richdata.fightnum)})
        table.insert(str,{fontID = 5, content = "场"})
    elseif richdata.opt == 5 then
        table.insert(str,{fontID = 11, content = "连胜终止！"})
        table.insert(str,{fontID = 5, content = "您的连胜被"})
        table.insert(str,{fontID = 1, content = richdata.name})
        table.insert(str,{fontID = 5, content = "的队伍终止了，当前场次第"})
        table.insert(str,{fontID = 5, content = tostring(richdata.fightnum)})
        table.insert(str,{fontID = 5, content = "场"})
    elseif richdata.opt == 6 then
        table.insert(str,{fontID = 5, content = "您的队伍战胜了"})
        table.insert(str,{fontID = 1, content = richdata.name})
        table.insert(str,{fontID = 5, content = "的队伍，并将对方的"})
        table.insert(str,{fontID = 5, content = tostring(richdata.otherstraightwinnum)})
        table.insert(str,{fontID = 5, content = "连胜终结"})
        table.insert(str,{fontID = 5, content = "，当前场次第"})
        table.insert(str,{fontID = 5, content = tostring(richdata.fightnum)})
        table.insert(str,{fontID = 5, content = "场"})
    end
    return str
end

--创建表
function wudaomain.createList(self)
    print("createList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn,myTable,a1,a2)
        local r
        if fn == "cellSize" then
            --r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            r = CCSizeMake(self.normalCellSize.x, self.sizeT[a1+1].height)
        elseif fn == "isRecycle" then
      
            return false
    
        elseif fn == "cellAtIndex" then
            -- a2 = CCTableViewCell:create()
            -- a2:addChild(self.sizeT[a1+1].container)


            local cellCCB = 0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB = self.sizeT[a1+1].container

                celldict[a2] = {cellCCB = cellCCB}
            else
                first =false
                cellCCB = celldict[a2].cellCCB
            end
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            -- printT(self.sizeT,"numberOfCells===")
            r = table.getTableLength(self.sizeT)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)
    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listNode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-103)
end

-- function wudaomain.setTimeData( self )
--     if gamedata.config.wudao_time and gamedata.config.wudao_time["1"] and gamedata.config.wudao_time["1"].open_week and gamedata.config.wudao_time["1"].open_week > 0 then
--     else
--         return
--     end
--     self:setFightingTimeData()

--     local nowtime = os.date("*t", gamedata:time())

--     local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
--     local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec

--     if alltimes >= self:gettimenum(self.finaltimenum1) and alltimes < self:gettimenum(self.finaltimenum2) then
--         -- 武道会 (第二轮)
--         self.begintimenum = self.begintimenum2
--         self.endtimenum = self.endtimenum2
--         self.finaltimenum = self.finaltimenum2

--     else
--         -- 武道会（第一轮）
--         self.begintimenum = self.begintimenum1
--         self.endtimenum = self.endtimenum1
--         self.finaltimenum = self.finaltimenum1

--     end
-- end

function wudaomain.setTimeData( self )
    if gamedata.config.wudao_time and gamedata.config.wudao_time["1"] and gamedata.config.wudao_time["1"].open_week and gamedata.config.wudao_time["1"].open_week > 0 then
    else
        return
    end
    

    local nowtime = os.date("*t", gamedata:time())

    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    -- local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec
    local updatestatus = false
    -- printT(gamedata.config.wudao_time,"wudao_time====")
    for k,v in pairs(gamedata.config.wudao_time) do
        if tonumber(v.open_week) == daynums then
            local hour1,min1,sec1 = ui.getGangBattleTime(v["open_time"])
            local hour2,min2,sec2 = ui.getGangBattleTime(v["over_time"])
            local hour3,min3,sec3 = ui.getGangBattleTime(v["finaly_time"])
            print("hour1,min1,sec1==",hour1,min1,sec1)
            print("hour2,min2,sec2==",hour2,min2,sec2)

            self.begintimenum = {week=v["open_week"], hour=hour1, min=min1, sec=sec1}
            self.endtimenum = {week=v["open_week"], hour=hour2, min=min2, sec=sec2}
            self.finaltimenum = {week=v["open_week"], hour=hour3, min=min3, sec=sec3}
            updatestatus = true
            break
        end
    end
    if updatestatus == false then
        return
    end
    printT(self.begintimenum,"begintimenum===")
    printT(self.endtimenum,"endtimenum===")
    printT(self.finaltimenum,"finaltimenum===")

    gameTimer:rigistTime("wudaohui_main_flesh", 2*24*3600)
    gameTimer:rigistTimeFunc("wudaohui_main_flesh",function()
        print("wudaohui_main_flesh====")
        -- if self.begintimenum.week == (nowtime.wday-1) and nowtime.hour>=self.begintimenum.hour then
        local nowtime = os.date("*t", gamedata:time())
        local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
        local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

        -- print("55555555555====",self:gettimenum(self.begintimenum),alltimes)
        if (self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum)) or (self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.finaltimenum)) then

            print("wudaohui_main_flesh====")
            self:updatetimeFunc()
            gameTimer:UnrigistTimeFunc("wudaohui_main_flesh")
        end
        if gameTimer.times["wudaohui_main_flesh"] == 0 then
            gameTimer:UnrigistTimeFunc("wudaohui_main_flesh")
            self:updatetimeFunc()
        end
    end)

    self:updatetimeFunc()
end


function wudaomain.updatetimeFunc( self )
    local nowtime = os.date("*t", gamedata:time())
    print("nowtime===")
    -- printT(nowtime)
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

    local remaintime = 0
    print("remaintime====",self:gettimenum(self.begintimenum),alltimes,self:gettimenum(self.endtimenum),self:gettimenum(self.endtimenum) - alltimes)

    if self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum) then
        self.isout = false
        remaintime = self:gettimenum(self.endtimenum) - alltimes

        self.rootItems.noticeDescLabel:setString("活动结束倒计时：")

        gameTimer:rigistTime("wudaohui_start", remaintime)
        gameTimer:rigistTimeFunc("wudaohui_start",function()
            -- print("wudaohui_start==")
            
            if gameTimer.times["wudaohui_start"] >= 0 then
                ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeText(gameTimer.times["wudaohui_start"],"hour"),21)
                -- print("1111111====",ui.makeTimeText(gameTimer.times["wudaohui_start"],"hour"))
            end
            if gameTimer.times["wudaohui_start"] == 0 then
                print("wudaohui_start====")
                gameTimer:UnrigistTimeFunc("wudaohui_start")

                self:updatetimeFunc()
            end
        end)
    elseif self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.finaltimenum) then
        self.isout = true
        remaintime = self:gettimenum(self.finaltimenum) - alltimes
        self.rootItems.noticeDescLabel:setString("活动结束")
        ui.setLabelString(self.rootItems.timerLabel,"",21)
        print("updatetimeFunc===1111")
        -- 活动结束，进入领奖时间，结束匹配倒计时
        ui.setLabelString(self.rootItems.doLab,"开始匹配",19)
        gameTimer:UnrigistTimeFunc("wudaohui_pipei")
        if self.ispipei == true then
            UIRequest({type = 4101,id = 1})
        end
        self.ispipei = false

        ui.addGray("CCControlButton",self.rootItems.doButton)


        gameTimer:rigistTime("wudaohui_rewards", remaintime)
        gameTimer:rigistTimeFunc("wudaohui_rewards",function()
            -- print("wudaohui_rewards==")
            if gameTimer.times["wudaohui_rewards"] >= 0 then
                -- ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeText(gameTimer.times["wudaohui_rewards"],"hour"),21)
                -- print("1111111====",ui.makeTimeText(gameTimer.times["wudaohui_rewards"],"hour"))
            end
            if gameTimer.times["wudaohui_rewards"] == 0 then
                print("wudaohui_rewards====")
                gameTimer:UnrigistTimeFunc("wudaohui_rewards")

                self:updatetimeFunc()
            end
        end)
    else
        self.isout = true

        self.rootItems.noticeDescLabel:setString("活动结束")
        ui.setLabelString(self.rootItems.timerLabel,"",21)

        runGamePrompt({msg = "活动已经结束！"})
        GameScene:shiftLayer("main","up")
    end

    
end

-- 代入时间计算秒数
function wudaomain.gettimenum(self,times,minnum)
    -- print("minnum===",minnum)
    local min = 0
    if minnum then
        min = minnum
    end
    local alltimes = 0
    alltimes = (times.week and (times.week-1) or 0)*24*3600 + (times.hour or 0)*3600 + times.min*60 + times.sec + min*60
    return alltimes
end

function wudaomain.setmydata(self)
    self.rootItems.myRanknode:setVisible(true)


    -- self.rootItems.noRankText:setString("榜外")
    ui.setLabelString(self.rootItems.noRankText,"榜外",14)
    -- printT(GameScene.roleinfo,"GameScene===")

    -- self.rootItems.name:setString(GameScene.roleinfo.name or "")
    -- self.rootItems.score:setString(self.data.mynowscorenum or 0)

    -- ui.setLabelString(self.rootItems.name,GameScene.roleinfo.name or "",14)
    -- 添加段位icon
    if self.rootItems.duanNode then
        ui.setWudaoPart(self.rootItems,self.part_point)
    end

    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(self.rootItems,GameScene.roleinfo,0.5,34/34,14)


    ui.setLabelString(self.rootItems.score,self.data.mynowscorenum or 0,14)

    local myratestring = (self.data.victorynum or 0).."/"..(self.data.fightnum or 0)
    -- self.rootItems.winrate:setString(myratestring)
    ui.setLabelString(self.rootItems.winrate,myratestring,14)


    if self.data.straightvictorynum < 3 then
        self.rootItems.straightWinNode:setVisible(false)
    else
        self.rootItems.straightWinNode:setVisible(true)
        
        ui.setLabelString(self.rootItems.straightWinNumLabel,(self.data.straightvictorynum or 0),13)
    end


    local myranklistdata = self.data["rank"..self.data.teamnum]
    -- straightWinNumNode:setVisible(true)
    local myranknum = 0
    for k,v in pairs(myranklistdata) do
        if GameScene.roleinfo.id == v.rid then
            myranknum = tonumber(k) or 0
        end
    end


    if myranknum == 0 then
        self.rootItems.noRankText:setVisible(true)
        self.rootItems.rankSpriteLabel:setVisible(false)
        self.rootItems.ranknumLabel:setVisible(false)
    else
        
        self.rootItems.noRankText:setVisible(false)
        self.rootItems.rankSpriteLabel:setVisible(true)
        self.rootItems.ranknumLabel:setVisible(true)

        if myranknum <=3 then
            local spritename = "b_n_zxt_"..myranknum..".png"
            setSpriteFrameByName(self.rootItems.rankSpriteLabel,spritename)
            self.rootItems.ranknumLabel:setVisible(false)
        else
            self.rootItems.rankSpriteLabel:setVisible(false)
            self.rootItems.ranknumLabel:setString(myranknum)
        end
        
    end

end

function wudaomain.setRewardStatus(self,itemNum)
    local paramconfig = gamedata.config.wudao_reward[tostring(itemNum)]
    if self.data["rewardstatue"..itemNum] == 2 then
        self.rootItems["finish"..itemNum]:setVisible(true)
    else
        self.rootItems["finish"..itemNum]:setVisible(false)
    end

    setSpriteFrameByName(self.rootItems["box"..itemNum], "box"..(itemNum+1).."_"..self.data["rewardstatue"..itemNum])

    self.rootItems["r_button"..itemNum]:setSwallowsTouch(true)
    self.rootItems["r_button"..itemNum]:setTouchPriority(-102)
    self.rootItems["r_button"..itemNum]:addHandleOfControlEvent(function()
        print("itemNum",itemNum)

        if self.data["rewardstatue"..itemNum] == 0 then
            gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(paramconfig["reward"]),type = gameConfig.strings:string_common("task",6)},nil)
        elseif self.data["rewardstatue"..itemNum] == 1 then
            print("请求服务器id=",itemNum)
            -- if itemNum > self.xianchidata.xc_level then
            --     -- runGamePrompt({msg = "仙池等级不足，无法领取"})
            --     runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",2)})
            --     return
            -- end

            UIRequest({type = 4103, id = itemNum})
        elseif self.data["rewardstatue"..itemNum] == 2 then
            gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(paramconfig["reward"]),type = gameConfig.strings:string_common("moreCommon",5)},nil)
        end
    end, CCControlEventTouchUpInside)

end



function wudaomain.ranklistUpdateSet(self,data)
    print("ranklistUpdateSet===")
    -- printT(data)
    local remaintime = (data and data.updatetimenum) or self.data.updatetimenum 
    gameTimer:rigistTime("wudaohui_update", remaintime)
    gameTimer:rigistTimeFunc("wudaohui_update",function()
        -- print("wudaohui_update==")
        if gameTimer.times["wudaohui_update"] >= 0 then
            -- ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeText(gameTimer.times["wudaohui_update"],"hour"),21)
            -- print("1111111====",ui.makeTimeText(gameTimer.times["wudaohui_update"],"hour"))
        end
        if gameTimer.times["wudaohui_update"] == 0 then
            print("wudaohui_update====")
            gameTimer:UnrigistTimeFunc("wudaohui_update")

            UIRequest({type = 4100, update = 1})
            -- self:updatetimeFunc()
        end
    end)
    if not data then
        print("just update===")
        return
    end

    print("updata==refresh")
    self.data = data

    self.rootItems.pojunAllSoreLabel:setString(self.data.teamscore1 or 0)
    self.rootItems.tanlangAllSoreLabel:setString(self.data.teamscore2 or 0)
    
    self:setmydata()

    self:shiftPage(self.choosepage)
end

function wudaomain.shiftPage(self,type)
    print("shiftPage===",type)
    if type then
        self.choosepage = type
    end
    -- if self.choosepage == type then
    --     return
    -- end

    for k,v in ipairs(self.pages) do
        if v == self.choosepage then
            self.rootItems[v.."node"]:setPosition(ccp(-462,-663.0))
            self.rootItems[v.."node"]:setVisible(true)
        else
            self.rootItems[v.."node"]:setPosition(ccp(9999,-663.0))
            self.rootItems[v.."node"]:setVisible(false)
        end
    end


    if self.choosepage == "pojun" then
        if self.data.teamnum == 1 then
            self.rootItems.myrankCell:setVisible(true)
        else
            self.rootItems.myrankCell:setVisible(false)
        end
        if self.PojunListTableView then
            self.PojunListTableView:reloadData()
        else
            self:pojuncreateList()
        end
    elseif  self.choosepage == "tanlang" then
        if self.data.teamnum == 2 then
            self.rootItems.myrankCell:setVisible(true)
        else
            self.rootItems.myrankCell:setVisible(false)
        end
        if self.TanlanghListTableView then
            self.TanlanghListTableView:reloadData()
        else
            self:tanlangcreateList()
        end
    end

end


function wudaomain.pojuncreateList(self)
    print("pojuncreateList")

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(934, 100)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("wudaohui/cell_wudahuirank", nil, true, "cell_wudahuirank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.PojunListTableView,cellCCB,934/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank1[tostring(a1+1)]

            ccbDocumentControler.myRanknode:setVisible(false)

            ccbDocumentControler.noRankText:setVisible(false)
            ccbDocumentControler.rankSpriteLabel:setVisible(true)
            ccbDocumentControler.ranknumLabel:setVisible(true)

            -- 排名
            if (a1+1) <=3 then
                ccbDocumentControler.ranknumLabel:setVisible(false)
                local spritename = "b_n_zxt_"..(a1+1)..".png"
                setSpriteFrameByName(ccbDocumentControler.rankSpriteLabel,spritename)
            else
                ccbDocumentControler.rankSpriteLabel:setVisible(false)
                ccbDocumentControler.ranknumLabel:setString((a1+1))
            end
            
            

            -- 连胜
            if celldata.params[tostring(1)] and celldata.params[tostring(1)].i < 3 then
                ccbDocumentControler.straightWinNode:setVisible(false)
            else
                ccbDocumentControler.straightWinNode:setVisible(true)
                
                ui.setLabelString(ccbDocumentControler.straightWinNumLabel,(celldata.params[tostring(1)] and celldata.params[tostring(1)].i or 0),13)
            end

            -- 添加段位icon
            if ccbDocumentControler.duanNode then
                ui.setWudaoPart(ccbDocumentControler,celldata.part_point or 0)
            end

            -- ccbDocumentControler.name:setString(celldata.name or "")
            -- 添加段位排名闪烁
            ui.setWudaoDuanweiRankEffect(ccbDocumentControler,celldata,0.5,34/34)



            ccbDocumentControler.score:setString(celldata.params[tostring(3)] and celldata.params[tostring(3)].i or 0)
            local winratestring = (celldata.params[tostring(5)] and celldata.params[tostring(5)].i or 0).."/"..(celldata.params[tostring(4)] and celldata.params[tostring(4)].i or 0)
            ccbDocumentControler.winrate:setString(winratestring)

            

            if self.PojunListTableView then
                cellCCB:setPosition(934/2,0)
            end


            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.rank1)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.PojunListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.pojunnode:getContentSize().width,
        viewheight = self.rootItems.pojunnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.pojunnode:addChild(self.PojunListTableView)
    self.PojunListTableView:setTouchPriority(-102)
end

function wudaomain.tanlangcreateList(self)
    print("tanlangcreateList")

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(934, 100)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("wudaohui/cell_wudahuirank", nil, true, "cell_wudahuirank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.TanlanghListTableView,cellCCB,934/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.rank2[tostring(a1+1)]

            ccbDocumentControler.myRanknode:setVisible(false)

            ccbDocumentControler.noRankText:setVisible(false)
            ccbDocumentControler.rankSpriteLabel:setVisible(true)
            ccbDocumentControler.ranknumLabel:setVisible(true)

            -- 排名
            if (a1+1) <=3 then
                ccbDocumentControler.ranknumLabel:setVisible(false)

                local spritename = "b_n_zxt_"..(a1+1)..".png"
                setSpriteFrameByName(ccbDocumentControler.rankSpriteLabel,spritename)
            else
                ccbDocumentControler.rankSpriteLabel:setVisible(false)
                ccbDocumentControler.ranknumLabel:setString((a1+1))
            end
            
            

            -- 连胜
            if celldata.params[tostring(1)] and celldata.params[tostring(1)].i < 3 then
                ccbDocumentControler.straightWinNode:setVisible(false)
            else
                ccbDocumentControler.straightWinNode:setVisible(true)
                
                ui.setLabelString(ccbDocumentControler.straightWinNumLabel,(celldata.params[tostring(1)] and celldata.params[tostring(1)].i or 0),13)
            end


            -- 添加段位icon
            if ccbDocumentControler.duanNode then
                ui.setWudaoPart(ccbDocumentControler,celldata.part_point or 0)
            end

            -- ccbDocumentControler.name:setString(celldata.name or "")
            -- 添加段位排名闪烁
            ui.setWudaoDuanweiRankEffect(ccbDocumentControler,celldata,0.5,34/34)

            ccbDocumentControler.score:setString(celldata.params[tostring(3)] and celldata.params[tostring(3)].i or 0)
            local winratestring = (celldata.params[tostring(5)] and celldata.params[tostring(5)].i or 0).."/"..(celldata.params[tostring(4)] and celldata.params[tostring(4)].i or 0)
            ccbDocumentControler.winrate:setString(winratestring)


            if self.TanlanghListTableView then
                cellCCB:setPosition(934/2,0)
            end


            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.rank2)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.TanlanghListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.tanlangnode:getContentSize().width,
        viewheight = self.rootItems.tanlangnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.tanlangnode:addChild(self.TanlanghListTableView)
    self.TanlanghListTableView:setTouchPriority(-102)
end

function wudaomain.clear(self)
    if gameTimer.times["wudaohui_start"] then
        gameTimer:UnrigistTimeFunc("wudaohui_start")
    end
    if gameTimer.times["wudaohui_rewards"] then
        gameTimer:UnrigistTimeFunc("wudaohui_rewards")
    end
    if gameTimer.times["wudaohui_main_flesh"] then
        gameTimer:UnrigistTimeFunc("wudaohui_main_flesh")
    end
    if gameTimer.times["wudaohui_update"] then
        gameTimer:UnrigistTimeFunc("wudaohui_update")
    end
    if gameTimer.times["wudaohui_pipei"] then
        gameTimer:UnrigistTimeFunc("wudaohui_pipei")
    end
    if self.ispipei == true then
        runGamePrompt({msg = "武道会匹配，已取消"})
        UIRequest({type = 4101,id = 1})
    end
    if gameTimer.times["wudaohui_main_pipeisuccess_delay"] then
        gameTimer:UnrigistTimeFunc("wudaohui_main_pipeisuccess_delay")
    end
    

    self.PojunListTableView = nil
    self.TanlanghListTableView = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.data = {}

    self.isout = false

    self.reportdata = nil
    self.ListTableView = nil

    self.ispipei = false
    self.xiandouchangeNum = 0
end

function wudaomain.UIUpdateData(self, isreset)
    if isreset then
        -- 武道会基础信息查询
        UIRequest({type = 4100})
        -- 武道会战报查询
        UIRequest({type = 4104})
    end
end

return wudaomain  ��  