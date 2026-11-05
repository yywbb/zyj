local shift=GameScene.shiftLayer
function GameScene.shiftLayer(self,...)
    self.localChampionEntry=(self.localChampionEntry or 0)+1
    return shift(self,...)
end
local send=UIRequest
local function page(shop)
    if shop then
        local activity=GameScene.layers.activity
        local row=activity and activity.module and activity.module.pageTable and activity.module.pageTable[162]
        return row and row.module
    end
    local row=GameScene.layers.champion
    return row and row.module
end
local function current(view)
    if not view or GameScene.presentLayer~=view.page or view.entry~=(GameScene.localChampionEntry or 0) then return false end
    local module=page(view.shop)
    return module and (module.rootNode or module.coverccb) and (not view.shop or module.show)
        and module.localChampionGeneration==view.generation
end
function UIRequest(req,...)
    local opcode=tonumber(req.type)
    if not opcode or not ((opcode>=2700 and opcode<=2705) or (opcode>=2710 and opcode<=2712)) then return send(req,...) end
    local shop=opcode>=2710
    local module=page(shop)
    req.championView={page=GameScene.presentLayer,entry=GameScene.localChampionEntry or 0,shop=shop,generation=module and module.localChampionGeneration}
    local data=module and module.data
    if not shop then
        req.championSerial=req.championSerial or (data and data.localSerial)
        if opcode==2703 then req.championGold=req.xgold or 0 end
        if opcode==2704 then
            local window=package.loaded.window_championBox
            local saved=window and window.data
            req.championSerial=req.championSerial or (saved and saved.localSerial)
            req.championView.window=window and window.localChampionGeneration
            req.championGold=req.xgold or 0
        end
    end
    if opcode==2705 then
        local status=data and data.status
        local count=tonumber(req.times)
        if not status or not count or count<1 or count>5 or not req.championSerial then return end
        local ceiling=0
        for i=(status.boxopen or 0)+1,count do ceiling=ceiling+gamedata.config.buycount_price[tostring(i)].championbox_cost end
        if status.pass==1 then for i=1,count do ceiling=ceiling+gamedata.config.buycount_price[tostring(i)].championbox_cost end end
        req.championCeiling=ceiling
        local view,serial,used=req.championView,req.championSerial,false
        gameWindows:openWindow('guildmsg',{msg=string.format('配置NPC真实战斗，遇败停止。每关最多开%d箱，最多消耗%d元宝；不重置、不续购。确认？',count,ceiling)},function()
            if used then return end;used=true
            local module=page(false)
            if not current(view) or not module.data or module.data.localSerial~=serial then
                runGamePrompt({msg='试炼页面或状态已变化，请重新确认'});return
            end
            req.championConfirmed=true
            send(req)
        end)
        return
    end
    return send(req,...)
end
function LocalChampionCurrent(t)
    if t.localChampionIgnored or not current(t.championView) then return false end
    if t.type==2704 then
        local window=package.loaded.window_championBox
        return window and window.rootNode and window.localChampionGeneration==t.championView.window
    end
    return true
end
for _,name in ipairs({'UIChampionStatus','UIChampionBattle','UIChampionNext','UIChampionReset','UIChampionBoxOpen',
    'UIChampionComplete','UIChampionShopQuery','UIChampionShop','UIChampionShopReset'}) do
    local receive=_G[name]
    _G[name]=function(t)
        if t.type==2700 and not t.localChampionIgnored and not t.championSync and t.param=='main' then
            local view=t.championView
            if not view or GameScene.presentLayer~=view.page or view.entry~=(GameScene.localChampionEntry or 0) then return end
            return receive(t)
        end
        if LocalChampionCurrent(t) then
            local result=receive(t)
            if t.type==2700 and t.championSync then
                local window=package.loaded.window_championBox
                if window and window.rootNode and window.data and window.data.status.pass==t.champion.status.pass then
                    window:reload(t.champion)
                end
            end
            return result
        end
    end
end
