require("UIShop")

local names = {"soul","soulResolveList","soulInfo","soulintegrate","buyItem"}
local function owner(name)
    if name == "soul" or name == "soulResolveList" then return GameScene.layers[name] end
    return gameWindows.windows[name]
end
function LocalSoulContext()
    local view = {}
    for _,name in ipairs(names) do
        local item = owner(name)
        if item and item.module then view[name] = item.module.localSoulGeneration end
    end
    local page = owner("soul")
    view.page = page and page.module and page.module.selectpage
    local info,buy = owner("soulInfo"),owner("buyItem")
    view.iid = info and info.module and info.module.data and info.module.data.iid
    view.item = buy and buy.module and buy.module.data and buy.module.data.id
    return view
end
function LocalSoulMatch(view,name)
    local item = owner(name)
    if not view or not item or not item.show or not item.module or not view[name]
        or view[name] ~= item.module.localSoulGeneration then return end
    if name == "soul" and view.page ~= item.module.selectpage then return end
    if name == "soulInfo" and view.iid ~= item.module.data.iid then return end
    if name == "buyItem" and view.item ~= item.module.data.id then return end
    return item.module
end

local send = UIRequest
function UIRequest(req,...)
    if req.type >= 2501 and req.type <= 2507 or req.type == 1006 or req.type == 1007 or req.type == 5345
        or req.type == 10026 or req.type == 12001 and (req.order == 25061 or req.order == 33007 or req.order == 32021) then
        req.soulView = LocalSoulContext()
    end
    return send(req,...)
end

function LocalSoulResolve(ids,name)
    local view,total = LocalSoulContext(),0
    local page = LocalSoulMatch(view,name)
    if not page then return end
    local source = name == "soulInfo" and {page.data} or page.souls
    for _,iid in ipairs(ids) do
        for _,item in pairs(source or {}) do
            if item.iid == iid then
                if item.generalcid and item.generalcid > 0 then return runGamePrompt({msg="请先卸下已穿戴命格"}) end
                total = total + gamedata.config.soul[tostring(item.cid)].eatexp
            end
        end
    end
    gameWindows:openWindow("confirm",{msg="分解"..#ids.."个闲置命格，返还"..total.."灵元；强化消耗不返还。是否继续？"},function()
        if LocalSoulMatch(view,name) then UIRequest({type=2506,ids=ids}) end
    end)
end

local function refresh()
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    for _,kind in ipairs({"all","star2","star3","star4","star5"}) do GameScene:addUpdate(10026,kind) end
    GameScene:addUpdate(1200)
    GameScene:UpdatePresentLayer()
end
local function hunt(t)
    local page = LocalSoulMatch(t.soulView,"soul")
    if page then page:relaodHunt(t);page:requestItemNum() end
end
function UISouls(t)
    local page = LocalSoulMatch(t.soulView,"soul")
    if page then page:relaodList(t.param,t.souls);page:shiftListPage() end
    local resolve = LocalSoulMatch(t.soulView,"soulResolveList")
    if resolve and t.param == "all" then resolve:ReloadData(t.souls) end
end
UISoulHuntQuery = hunt
UISoulHunt41 = hunt
function UISoulHunt(t)
    refresh()
    local page = LocalSoulMatch(t.soulView,"soul")
    if page and t.getsouls and next(t.getsouls) then page:playget(t.getsouls) end
    if page and t.reward and next(t.reward) then showRewardPopupWindow(t.reward) end
    hunt(t)
end
function UISoulExchange(t)
    refresh()
    hunt(t)
    if LocalSoulMatch(t.soulView,"soul") then showRewardPopupWindow(t.getsouls) end
end
function UISoulUpgrade(t)
    refresh()
    local info = LocalSoulMatch(t.soulView,"soulInfo")
    if info and t.newsoul and t.newsoul.iid == info.data.iid then info:reloaddata(table.merge(info.data,t.newsoul)) end
end
function UISoulResolve(t)
    refresh()
    local info = LocalSoulMatch(t.soulView,"soulInfo")
    if info then
        for _,iid in pairs(t.soulIds or {}) do
            if iid == info.data.iid then info.callback=nil;gameWindows:closeWindowDirect("soulInfo");break end
        end
    end
    if info or LocalSoulMatch(t.soulView,"soulResolveList") then showRewardPopupWindow(t.reward) end
end
function UISoulCompound(t)
    refresh()
    local window = LocalSoulMatch(t.soulView,"soulintegrate")
    if window then window:compound() end
end
local buySuccess = UIActivityBuyItem
function UIActivityBuyItem(t)
    if t.soulItem ~= 20617 then return buySuccess(t) end
    GameScene:addUpdate(1200)
    local buy = LocalSoulMatch(t.soulView,"buyItem")
    if buy then buy:buySuccess(t.reward) end
end
