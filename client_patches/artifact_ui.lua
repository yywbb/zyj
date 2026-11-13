local pages={artifactCreate=true,artifactCheck=true,artifactList=true,slotsInfo=true,artifactStrengthen=true,
    artifactWash=true,artifactMount=true,artifactSkillSwop=true,artifactSkillStrengthen=true,qiankunlu=true}
local names={"artifactCreate","artifactCheck","artifactList","slotsInfo","artifactStrengthen","artifactWash","artifactMount",
    "artifactSkillSwop","artifactSkillStrengthen","qiankunlu","onceCreateArtifact","onceCheckup","artifactInfo","artifactSelect",
    "onceCheckedPanel","checkTimeList","onceRecoin","onceAddStrengthen","artifactOpenPos","jewelSelect","jewelUp","jewelInfo",
    "artifactSkillUp","artifactWashConfirm"}
local function owner(name) return pages[name] and GameScene.layers[name] or gameWindows.windows[name] end
local function selected(m)
    local item=m.artifactSelect or m.data or m.artifact or {}
    if type(item)~="table" then item=m.data or m.artifact or {} end
    return item.artifactData or item.artifact or item
end
local function selection(m)
    local keys={}
    for _,name in ipairs({"artifactSelect","curArtifactData","selectList","chooseData"}) do
        if type(m[name])=="table" then
            for _,item in pairs(m[name]) do
                if type(item)=="table" and item.iid then keys[#keys+1]=name..":"..item.iid..":"..(item.localRevision or 0) end
            end
        end
    end
    table.sort(keys)
    return table.concat(keys,",")
end
function LocalArtifactContext()
    local view={}
    for _,name in ipairs(names) do
        local entry=owner(name)
        if entry and entry.module then
            local m=entry.module
            local slot=m.slotdata and m.slotdata[tostring(m.sid)]
            local item=selected(m)
            view[name]={generation=m.localArtifactGeneration,page=m.selectpage,sid=m.sid,
                general=slot and slot.general and slot.general.iid,
                iid=item.iid,revision=item.localRevision,
                first=m.artifactData1 and m.artifactData1.iid,second=m.artifactData2 and m.artifactData2.iid,
                firstRevision=m.artifactData1 and m.artifactData1.localRevision,
                secondRevision=m.artifactData2 and m.artifactData2.localRevision,
                selection=selection(m),
                pos=m.pos or m.curPos or m.data and m.data.pos}
        end
    end
    return view
end
function LocalArtifactMatch(view,name)
    local entry=owner(name)
    local expected=view and view[name]
    if not entry or not entry.show or not entry.module or not expected then return end
    local m=entry.module
    if not (m.rootNode or m.root) or not expected.generation or expected.generation~=m.localArtifactGeneration then return end
    local slot=m.slotdata and m.slotdata[tostring(m.sid)]
    local item=selected(m)
    if expected.page~=m.selectpage or expected.sid~=m.sid or expected.general~=(slot and slot.general and slot.general.iid)
        or expected.iid~=item.iid or expected.revision~=item.localRevision
        or expected.first~=(m.artifactData1 and m.artifactData1.iid) or expected.second~=(m.artifactData2 and m.artifactData2.iid)
        or expected.firstRevision~=(m.artifactData1 and m.artifactData1.localRevision)
        or expected.secondRevision~=(m.artifactData2 and m.artifactData2.localRevision)
        or expected.selection~=selection(m)
        or expected.pos~=(m.pos or m.curPos or m.data and m.data.pos) then return end
    return m
end

local send=UIRequest
function UIRequest(req,...)
    if req.type>=5501 and req.type<=5509 or req.type>=5515 and req.type<=5520 or req.type>=5540 and req.type<=5546
        or req.type==10032 or req.type==10031 or req.type==12001 and
        (req.order==33009 or req.order==33013 or req.order==33014 or req.order==33016 or req.order==32002 or req.order==32003) then
        req.artifactView=req.artifactView or LocalArtifactContext()
        req.artifactVersions=req.artifactVersions or {}
        local function remember(item)
            if type(item)~="table" then return end
            item=item.artifactData or item.artifact or item
            if item and item.iid then req.artifactVersions[item.iid]=item.localRevision or 0 end
        end
        for _,list in ipairs({req.uses or {},req.curList or {},req.expendList or {}}) do
            for _,item in pairs(list) do remember(item) end
        end
        for _,name in ipairs(names) do
            local entry=owner(name)
            local m=entry and entry.show and entry.module
            if m then
                for _,key in ipairs({"data","artifact","artifactSelect","artifactData1","artifactData2"}) do remember(m[key]) end
                if req.type==5520 then for _,item in pairs(m.chooseData or {}) do remember(item) end end
            end
        end
        if req.type==12001 and req.order==33013 then
            local window=gameWindows.windows.onceCheckup
            req.artifactView.property=window and window.module and window.module.rootNode and "onceCheckup" or "artifactCheck"
        end
        if req.type==12001 and req.order==32003 then
            local window=gameWindows.windows.artifactSkillUp
            req.artifactView.property=window and window.show and window.module and window.module.rootNode and "artifactSkillUp" or "artifactInfo"
        end
    end
    return send(req,...)
end

local revision=0
function LocalArtifactFresh(t)
    if t.localArtifactIgnored or (t.artifactRevision or 0)<revision then return false end
    revision=t.artifactRevision or revision
    return true
end
local function sync(t)
    if not LocalArtifactFresh(t) then return false end
    if t.data then
        local list=GameScene.layers.artifactList
        if list and list.module then
            if LocalArtifactMatch(t.artifactView,"artifactList") then list.module:reloadData(t)
            else list.module:setArtifactData(t.data) end
        end
        local qiankun=GameScene.layers.qiankunlu
        if qiankun and qiankun.module then qiankun.module:setArtifactData(t.data) end
    end
    for _,id in ipairs({10021,10023,1200}) do GameScene:addUpdate(id) end
    if t.jewelData then
        GameScene:addUpdate(10031)
        local list=GameScene.layers.artifactList
        if list and list.module then
            if LocalArtifactMatch(t.artifactView,"artifactList") then list.module:reloadJewelData({data=t.jewelData})
            else list.module:orderJewelData(t.jewelData) end
        end
    end
    return true
end
function UIArtifactCast(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactCreate")
    if page then page:castSuccess(t) end
end
function UIArtifactCheck(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactCheck")
    if page then page:checkSuccess(t) end
end
function UIUserArtifactOnceMake(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactCreate")
    if page then page:updateItem();gameWindows:openWindow("onceCheckedPanel",t) end
end
function UIUserArtifactOnceCheckup(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactCheck")
    if page then page:setArtifactData();page:resetArtifactSelect();gameWindows:openWindow("onceCheckedPanel",t) end
end
function UIArtifactChange(t)
    if not sync(t) then return end
    local info=LocalArtifactMatch(t.artifactView,"artifactInfo")
    if info then gameWindows:closeWindowDirect("artifactInfo") end
    if LocalArtifactMatch(t.artifactView,"slotsInfo") then UIRequest({type=10021}) end
end
function UIArtifactData(t)
    if not LocalArtifactFresh(t) then return end
    local list=GameScene.layers.artifactList
    if list and list.module then
        if LocalArtifactMatch(t.artifactView,"artifactList") then list.module:reloadData(t)
        else list.module:setArtifactData(t.data) end
    end
    for _,name in ipairs({"artifactCreate","artifactCheck","artifactSelect","artifactMount","artifactStrengthen","artifactSkillStrengthen","onceRecoin"}) do
        local page=LocalArtifactMatch(t.artifactView,name)
        if page then
            if name=="artifactCheck" or name=="artifactMount" or name=="artifactStrengthen" or name=="artifactSkillStrengthen" then page:setArtifactData(t)
            else page:reloadData(t) end
        end
    end
end

function UIArtifactCommpond(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactCreate")
    if page then page:commpondSuccess(t) end
end
function UIUserArtifactRecast(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactCreate")
    if page then page.comppondNeedChange=true;page:reloadData(t);gameWindows:openWindow("onceCheckedPanel",t) end
end
function UIUserArtifactLock(t)
    if not sync(t) then return end
    for _,name in ipairs({"artifactList","artifactStrengthen","onceRecoin","onceAddStrengthen","artifactSelect","artifactSkillSwop","artifactSkillStrengthen"}) do
        local page=LocalArtifactMatch(t.artifactView,name)
        if page and page.lockCallback then page:lockCallback(t) end
    end
    local info=LocalArtifactMatch(t.artifactView,"artifactInfo")
    if info then info.data=t.artifactData;info:updateLockState(t) end
end
function UIUserArtifactStrengthen(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactStrengthen")
    if page then page:updateArtifactData(t);page:setArtifactData(t) end
end
local function washUpdate(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactWash")
    if page then page:updateReload(t);page:setShowSkillGongming(1);page:setShowSkillGongming(2) end
    local info=LocalArtifactMatch(t.artifactView,"artifactInfo")
    if info then info:updateArtifactState(t.artifactData) end
end
UIUserArtifactOpening=washUpdate
UIUserArtifactBaptize=washUpdate
UIUserArtifactBaptizeReplace=washUpdate
UIUserArtifactSkillWashCancel=washUpdate
function UIUserArtifactSkillUp(t)
    if not LocalArtifactFresh(t) then return end
    if LocalArtifactMatch(t.artifactView,"artifactSkillUp") then gameWindows:closeWindowDirect("artifactSkillUp") end
    washUpdate(t)
end
function UIUserArtifactSkillExchange(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactSkillSwop")
    if page then page:swopCallback(t.swapData) end
end
function UIUserArtifactStrenExchange(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactSkillStrengthen")
    if page then page:swopCallback(t.swapData) end
end
function UIUserArtifactRenascence(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"qiankunlu")
    if page then page:reloadPageData(t) end
end
local function gemUpdate(t,method)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"artifactMount")
    if page then page[method](page,t) end
end
function UIArtifactOpenPos(t) gemUpdate(t,"reloadData") end
function UIArtifactMountJewel(t) gemUpdate(t,"reloadData") end
function UIJewelUpgrade(t) gemUpdate(t,"upDateJewel") end
function UIJewelCommpond(t)
    if not sync(t) then return end
    local page=LocalArtifactMatch(t.artifactView,"jewelUp")
    if page then page:commpondSuccess({data=t.jewelData,reward=t.reward}) end
    page=LocalArtifactMatch(t.artifactView,"artifactMount")
    if page then page:jewelUpdate({data=t.jewelData}) end
end
function UIJewelListData(t)
    if not LocalArtifactFresh(t) then return end
    local list=GameScene.layers.artifactList
    if list and list.module then
        if LocalArtifactMatch(t.artifactView,"artifactList") then list.module:reloadJewelData(t)
        else list.module:orderJewelData(t.data) end
    end
    for _,name in ipairs({"jewelSelect","jewelUp"}) do
        local page=LocalArtifactMatch(t.artifactView,name)
        if page then page:reloadData(t) end
    end
    local page=LocalArtifactMatch(t.artifactView,"artifactMount")
    if page then page:setArtifactData(t) end
end
function UIArtifactCheckTime(t)
    if t.localArtifactIgnored then return end
    for _,name in ipairs({"artifactCheck","checkTimeList"}) do
        local page=LocalArtifactMatch(t.artifactView,name)
        if page then page:setTime(t) end
    end
end

-- gameTimer受全局加速影响；时辰显示只认真实秒，到期只查询，不自动鉴定。
function LocalArtifactTime(self,t,name)
    if not t then return UIRequest({type=5509}) end
    local generation=self.localArtifactGeneration
    self.timeData={time=t.time,sec=math.max(0,t.sec-math.max(0,os.time()-(t.receivedAt or os.time())))}
    local deadline=os.time()+self.timeData.sec
    if name=="artifactCheck" then
        setSpriteFrameByName(self.rootItems.timeSp,"shenqitime_"..self.timeSp[t.time])
        setSpriteFrameByName(self.rootItems.timeL,"shichen_"..self.timeSp[t.time])
    else
        self.data=self.timeData
        if not self.listTableView then self:createList() else self.listTableView:reloadData() end
    end
    gameTimer:rigistTime(name,self.timeData.sec)
    local queried=false
    gameTimer:rigistTimeFunc(name,function()
        if not self.rootNode or self.localArtifactGeneration~=generation then return end
        local left=math.max(0,deadline-os.time())
        gameTimer.times[name]=left
        self.timeData.sec=left
        if name=="artifactCheck" then self.rootItems.leftTime:setString(ui.makeTimeDayText(left,"minute")) end
        if name=="checkTimeList" then ui.setLabelString(self.rootItems.attribute2,gameConfig.strings:string_format({"artifact",139},{ui.makeTimeDayText(left,"minute")}),26) end
        if left==0 and not queried then queried=true;UIRequest({type=5509}) end
    end)
end
