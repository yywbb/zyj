require("UIGenerals")
local revision=-1
function LocalIllusionPage(view)
    local entry=GameScene.layers.illusion
    local page=entry and entry.show and entry.module
    if not page or not page.rootNode then return end
    if view and page.localIllusionGeneration~=view.generation then return end
    return page
end
local request=UIRequest
function UIRequest(req,...)
    if req.type==8110 or req.type==8111 or req.type==8112 then
        local page=LocalIllusionPage()
        if page then
            req.illusionView=req.illusionView or {generation=page.localIllusionGeneration}
            for _,row in pairs(page.data or {}) do
                if row.cid==req.illusionIid then
                    req.illusionExpected={cid=row.cid,serial=page.localIllusionSerial,
                        endtime=row.endtime,generalIid=row.generalIid or 0}
                end
            end
        elseif req.type==8110 then
            local entry=gameWindows.windows.changebreakskill
            local m=entry and entry.show and entry.module
            if m and m.rootNode and m.selectIllusion then
                req.illusionView={window=m.localIllusionGeneration,iid=m.data.general.iid}
            end
        end
    elseif req.type==7021 and req.selectIllusion==1 then
        local window=gameWindows.windows.changebreakskill
        local m=window and window.show and window.module
        if m and m.rootNode and m.data and m.data.general then
            local hero=m.data.general
            req.generalIid=hero.iid
            req.illusionExpected=m.localIllusionExpected
            req.illusionView={window=m.localIllusionGeneration,iid=hero.iid}
        end
    end
    return request(req,...)
end
local function sync(t)
    if t.illusionIgnored or (t.illusionSerial or -1)<revision then return end
    revision=t.illusionSerial
    local entry=gameWindows.windows.changebreakskill
    local window=entry and entry.show and entry.module
    if window and window.rootNode and t.illusionView and window.localIllusionGeneration==t.illusionView.window
        and window.data.general.iid==t.illusionView.iid then
        for _,row in pairs(t.data or {}) do
            if row.generalIid==window.data.general.iid then
                window.localIllusionExpected={cid=row.cid,serial=t.illusionSerial,endtime=row.endtime,generalIid=row.generalIid}
            end
        end
    end
    local page=LocalIllusionPage(t.illusionView)
    if page and (t.illusionPush or t.illusionView) then
        page.localIllusionSerial=t.illusionSerial
        page:reloaddata(t.data)
    end
end
function UIIllusionQuery(t) sync(t) end
function UIIllusionExe(t)
    if t.illusionIgnored then return end
    sync(t)
    for _,id in ipairs({10021,10023}) do GameScene:addUpdate(id) end
end
function UIIllusionCancel(t) UIIllusionExe(t) end
local changed=UIGeneralChangeBreakSkill
function UIGeneralChangeBreakSkill(t)
    if t.illusionIgnored then return end
    if not t.illusionView then return changed(t) end
    local entry=gameWindows.windows.changebreakskill
    local m=entry and entry.show and entry.module
    if m and m.rootNode and m.localIllusionGeneration==t.illusionView.window and m.data.general.iid==t.illusionView.iid then
        gameWindows:closeWindowDirect("changebreakskill")
        runGamePrompt({msg="成功更换幻影突破技"})
    end
    for _,id in ipairs({10021,10023}) do GameScene:addUpdate(id) end
end
