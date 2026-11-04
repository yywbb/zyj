function LocalActivityCopyContext()
    local page=(GameScene.layers.copy_chapter or {}).module or {}
    local window=(gameWindows.windows.copyacivity or {}).module or {}
    return {page=page.localActivityCopyGeneration,tab=page.selectpage,
        window=window.rootNode and window.localActivityCopyGeneration,aid=(window.data or {}).aid}
end
function LocalActivityCopyWindow(view)
    local window=gameWindows.windows.copyacivity
    return view and view.window and window and window.show and window.module.rootNode
        and window.module.localActivityCopyGeneration==view.window and window.module.data.aid==view.aid
end
function LocalActivityCopyActive(view,mutation)
    if not view then return false end
    if mutation and view.window then return LocalActivityCopyWindow(view) end
    local page=GameScene.layers.copy_chapter
    return LocalActivityCopyWindow(view) or page and page.show and page.module.rootNode
        and page.module.localActivityCopyGeneration==view.page and page.module.selectpage==view.tab
end
local send=UIRequest
function UIRequest(req,...)
    if req.type==1340 or req.type==1341 or req.type==1342 or req.type==1343 or req.type==1344 or req.type==1345 or req.type==1347 then
        req.activityCopyView=LocalActivityCopyContext()
    end
    return send(req,...)
end
