local pages={artifactCreate=true,artifactCheck=true,artifactList=true,slotsInfo=true}
local names={"artifactCreate","artifactCheck","artifactList","slotsInfo","onceCreateArtifact","onceCheckup","artifactInfo","artifactSelect","onceCheckedPanel","checkTimeList"}
local function owner(name) return pages[name] and GameScene.layers[name] or gameWindows.windows[name] end
function LocalArtifactContext()
    local view={}
    for _,name in ipairs(names) do
        local entry=owner(name)
        if entry and entry.module then
            local m=entry.module
            local slot=m.slotdata and m.slotdata[tostring(m.sid)]
            view[name]={generation=m.localArtifactGeneration,page=m.selectpage,sid=m.sid,
                general=slot and slot.general and slot.general.iid,
                iid=(m.artifactSelect or m.data or {}).iid}
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
    if expected.page~=m.selectpage or expected.sid~=m.sid or expected.general~=(slot and slot.general and slot.general.iid)
        or expected.iid~=(m.artifactSelect or m.data or {}).iid then return end
    return m
end

local send=UIRequest
function UIRequest(req,...)
    if req.type==5501 or req.type==5503 or req.type==5508 or req.type==5509 or req.type==5515 or req.type==5516
        or req.type==10032 or req.type==12001 and (req.order==33009 or req.order==33013) then
        req.artifactView=req.artifactView or LocalArtifactContext()
        if req.type==12001 and req.order==33013 then
            local window=gameWindows.windows.onceCheckup
            req.artifactView.property=window and window.module and window.module.rootNode and "onceCheckup" or "artifactCheck"
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
    for _,name in ipairs({"artifactCreate","artifactCheck","artifactSelect"}) do
        local page=LocalArtifactMatch(t.artifactView,name)
        if page then
            if name=="artifactCheck" then page:setArtifactData(t) else page:reloadData(t) end
        end
    end
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
