local function page(t,target)
    local entry = GameScene.layers.magic
    local value = entry and entry.module
    if entry and entry.show and value and value.rootItems and value.localMagicView == t.view
        and (not target or value.selectID == t.id) then return value end
end

local function refresh(t)
    local value = page(t,true)
    if value then UIRequest({type=1360,id=t.id,view=t.view}) end
end

function UIInstrumentQuery(t)
    local value = page(t,false)
    if not value then return end
    if t.id > 0 and value.selectID ~= t.id then return end
    value.previeState = false
    value.localMagicToken = nil
    value:load(t)
end

function UIInstrumentUnlock(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    refresh(t)
end

function UIInstrumentForgePreview(t)
    local value = page(t,true)
    if not value then return end
    value.localMagicToken = t.token
    if t.token > 0 then
        value:preview(t.data)
    else
        value.previeState = false
        value:setButtonShowType(0)
    end
end

function UIInstrumentForgeConfirm(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    local value = page(t,true)
    if value then
        value.localMagicToken = nil
        value.previeState = false
        refresh(t)
    end
end

function UIInstrumentForgeAutomatic(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    local window = gameWindows.windows.instrumentForgeAutomatic
    if window and window.show and window.module.rootItems and window.module.iid == t.id and window.module.localMagicView == t.view
        and window.module.localMagicWindow == t.window then
        window.module:reloadData(t)
    end
    refresh(t)
end

function UIBreakForgePreview(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    refresh(t)
end
