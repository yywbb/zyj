function LocalHadesContext()
    for _,name in ipairs({'hadescopy_map','copy_chapter'}) do
        local page=GameScene.layers[name]
        if page and page.show and page.module.rootNode then
            return {name=name,generation=page.module.localHadesGeneration,tab=page.module.selectpage}
        end
    end
end
function LocalHadesActive(view)
    local page=view and GameScene.layers[view.name]
    return page and page.show and page.module.rootNode and page.module.localHadesGeneration==view.generation
        and (view.name~='copy_chapter' or page.module.selectpage==view.tab)
end
local send=UIRequest
function UIRequest(req,...)
    if req.type==1370 or req.type==1371 or req.type==1372 then req.hadesView=LocalHadesContext() end
    return send(req,...)
end
