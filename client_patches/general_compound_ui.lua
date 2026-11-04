local compoundSend, compoundReceive = UIRequest, UIGeneralCompound
function UIRequest(req,...)
    if tonumber(req.type) == 1016 then
        local page, window = package.loaded.Layer_general, package.loaded.window_infoAndAccess
        req.compoundView = {page=page and page.localCompoundGeneration,tab=page and page.selectpage,
            window=window and window.localCompoundGeneration,cid=(req.ids or {})[1] or (req.ids or {})["1"]}
    end
    return compoundSend(req,...)
end

function UIGeneralCompound(t)
    if t.localCompoundIgnored then return end
    local view = t.compoundView or {}
    local page, window = package.loaded.Layer_general, package.loaded.window_infoAndAccess
    local activePage = page and page.rootNode and GameScene.layers.generals.show
        and view.page == page.localCompoundGeneration and view.tab == page.selectpage
    local activeWindow = window and window.root and view.window == window.localCompoundGeneration
        and window.paramData and tonumber(window.paramData.cid) == tonumber(view.cid)
    if activePage or activeWindow then return compoundReceive(t) end
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
end
