local shift=GameScene.shiftLayer
function GameScene.shiftLayer(self,...)
    self.localDragonEntry=(self.localDragonEntry or 0)+1
    return shift(self,...)
end

local send=UIRequest
function UIRequest(req,...)
    local opcode=tonumber(req.type)
    if opcode and opcode>=4901 and opcode<=4907 then
        local module=(GameScene.layers.shenlongxuyuan or {}).module
        req.dragonView={page=GameScene.presentLayer,generation=module and module.localDragonGeneration}
        if opcode==4907 then
            GameScene.localDragonEntry=(GameScene.localDragonEntry or 0)+1
            req.dragonView.entry=GameScene.localDragonEntry
        elseif module then
            if opcode==4902 and module.localDragonMoving then return end
            req.dragonSerial=(module.dragonwishing or {}).serial
            if opcode==4902 then req.auto=module.m_bIsAutoGame==0 and 1 or 0 end
            local name=opcode==4903 and "shenlongxuyuan_reward" or opcode==4904 and "shenlongxuyuan_event" or opcode==4906 and "shenlongxuyuan_shop"
            local window=name and package.loaded["window_"..name]
            if window then req.dragonSerial=window.localDragonSerial;req.dragonView.window=name;req.dragonView.windowGeneration=window.localDragonGeneration end
        end
    end
    return send(req,...)
end

local open=gameWindows.openWindow
function gameWindows.openWindow(self,name,data,callback,...)
    if name=="shenlongxuyuan_event" or name=="shenlongxuyuan_shop" or name=="shenlongxuyuan_reward" then
        local page=(GameScene.layers.shenlongxuyuan or {}).module
        if page then
            data=data or {};data.dragonSerial=(page.dragonwishing or {}).serial
            local generation=page.localDragonGeneration
            GameScene.localDragonWindows=GameScene.localDragonWindows or {}
            local ticket=(GameScene.localDragonWindows[name] or 0)+1
            GameScene.localDragonWindows[name]=ticket
            local cb=callback
            if cb then callback=function(...) if page.rootNode and generation==page.localDragonGeneration and GameScene.localDragonWindows[name]==ticket then return cb(...) end end end
        end
    end
    return open(self,name,data,callback,...)
end

local function current(t)
    local view=t.dragonView or {}
    if t.localDragonIgnored then return false end
    if t.type==4907 then return GameScene.presentLayer==view.page and view.entry==GameScene.localDragonEntry end
    local page=GameScene.layers.shenlongxuyuan
    return page and page.show and page.module and page.module.rootNode and view.generation==page.module.localDragonGeneration
end

local function refresh(t)
    if current(t) then UIRequest({type=4901}) end
end

for _,name in ipairs({"Query","Get","Reward","Event","EventClose","Shop","QueryMap"}) do
    local native=_G["UIDragonWishing"..name]
    _G["UIDragonWishing"..name]=function(t)
        if not current(t) then return end
        local page=GameScene.layers.shenlongxuyuan
        if t.dragonstate and page and page.module then page.module.dragonwishing=t.dragonstate end
        if name=="Query" then
            GameScene.localDragonDiceDeadline=gamedata:time()+(t.dragonwishing.time or 0)
            page.module.localDragonRecoverRead=nil
            if t.opt~=2 then page.module.localDragonMoving=nil end
        end
        if name=="Get" then page.module.localDragonMoving=true end
        if name=="Event" then
            local cb=function() refresh(t) end
            if t.battlereport then RunbattleCallBack("penglai",{reward=t.battlereward or {},battlereport=t.battlereport,result=t.result or 0},cb)
            elseif t.reward and next(t.reward) then showRewardPopupWindow(t.reward,nil,cb)
            else cb() end
        elseif name=="EventClose" then refresh(t)
        elseif name=="Shop" then
            if t.reward and next(t.reward) then showRewardPopupWindow(t.reward,nil) end
            local view=t.dragonView
            local window=package.loaded.window_shenlongxuyuan_shop
            if window and window.rootNode and window.localDragonGeneration==view.windowGeneration then
                window.localDragonSerial=t.dragonstate.serial;window:reload(t)
            end
        else return native(t) end
    end
end
