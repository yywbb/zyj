local operations={[1017]=true,[1023]=true,[1025]=true,[5512]=true,[5513]=true,[7001]=true,[1029]=true}
function LocalPartnerGrowthPage(view,shown)
    if not view then return end
    local entry=view.kind=="layer" and GameScene.layers.generalup or gameWindows.windows[view.kind]
    local page=entry and entry.module
    local hero=page and page.data and page.data.general
    if entry and entry.show and hero and page.localPartnerGeneration==view.generation
        and hero.iid==view.iid and (page.selectpage or page.pagetype)==view.tab
        and (not shown or hero.cid==view.cid and hero.level2==view.advance
            and hero.skilllevel==view.awake and (hero.level8 or 0)==view.soar
            and (view.star==nil or (hero.level5 or 0)==view.star)) then return page end
end
local send=UIRequest
function UIRequest(req,...)
    if operations[req.type] or req.type==12001 and (req.order==33020 or req.order==10103 or req.order==33015 or req.order==32004 or req.order==33019) then
        for _,kind in ipairs({"generalUp","generalInfo","layer"}) do
            local entry=kind=="layer" and GameScene.layers.generalup or gameWindows.windows[kind]
            local page=entry and entry.module
            local hero=page and page.data and page.data.general
            if entry and entry.show and hero then
                req.partnerView={kind=kind,generation=page.localPartnerGeneration,tab=page.selectpage or page.pagetype,
                    iid=hero.iid,cid=hero.cid,advance=hero.level2,awake=hero.skilllevel,soar=hero.level8 or 0,star=hero.level5 or 0}
                if req.type==1017 and kind~="layer" and hero.level2>=10 then
                    runGamePrompt({msg="高阶突破请从阵容中的伙伴成长页操作，以确认完整材料"})
                    return
                end
                break
            end
        end
    end
    return send(req,...)
end
function UIGeneralBreakPreview(t)
    local page=not t.partnerIgnored and LocalPartnerGrowthPage(t.partnerView,true)
    if page then page:setTupoNext(t) end
end
for _,entry in ipairs({{"UIGeneralBreak","resetPage_tupo"},{"UIGeneralAwaken","resetPage_Awaken"},
    {"UIGeneralXiuLianInfo","getXiuLianData"},{"UIGeneralXiuLian","xiuLianSuccess"},{"UIPartnerFeiSheng","feiShengCallback"}}) do
    local name,method=entry[1],entry[2]
    _G[name]=function(t)
        if t.partnerIgnored then return end
        for _,id in ipairs({10021,10023,10024,1200,1012}) do GameScene:addUpdate(id) end
        if name=="UIPartnerFeiSheng" and t.isLead==1 then
            -- 主角飞升不走伙伴页：缓存已由 gamedata:Generals 更新，这里把新境界同步到主角页，
            -- 缺了这一步页面会一直停在旧境界名（如白莲境0级），但战力已按新等级显示。
            local lead=GameScene.layers["lead"]
            if lead and lead.show then return lead.module:pageDataCallback("feisheng","feiShengCallback",t.general) end
            return
        end
        local page=LocalPartnerGrowthPage(t.partnerView)
        if page then
            if t.partnerView.kind=="generalInfo" then return page:reloaddata(t) end
            return page[method](page,name=="UIPartnerFeiSheng" and t.general or t)
        end
    end
end
