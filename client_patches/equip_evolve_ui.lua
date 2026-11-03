require("UIEquipStarUp")

function LocalEquipGrowthNext(item)
    local row = gamedata.config.equip_evolve[tostring(item.cid)]
    if not row then return end
    if item.level2 < row.level then return item.cid,item.level2+1 end
    if row.evolve and row.evolve > 0 then return row.evolve,1 end
end

function LocalEquipGrowthContext()
    local view = {}
    for _,name in ipairs({"equipsup","equipstage"}) do
        local layer = GameScene.layers[name]
        local page = layer and layer.module
        local item = page and (name == "equipsup" and page.data or page.chooseData and page.chooseData[1])
        if page then view[name] = {generation=page.localEquipGrowthGeneration,iid=item and item.iid,page=page.selectpage} end
    end
    return view
end
function LocalEquipGrowthPage(view,name)
    local layer = GameScene.layers[name]
    local page = layer and layer.module
    local request = view and view[name]
    if not layer or not layer.show or not page or not page.rootNode or not request then return end
    local item = name == "equipsup" and page.data or page.chooseData and page.chooseData[1]
    if request.generation == page.localEquipGrowthGeneration and item and request.iid == item.iid and request.page == page.selectpage then return page end
end
local send = UIRequest
function UIRequest(req,...)
    if req.type == 1122 or req.type == 1123 or req.type == 12001 and (req.order == 14002 or req.order == 14003) then
        req.growthView = LocalEquipGrowthContext()
    end
    return send(req,...)
end

local function update(t)
    for _,kind in ipairs({"equips","offequips","slotequips","equipstage",t.equipdata.type}) do GameScene:addUpdate(10025,kind) end
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)
    local page = LocalEquipGrowthPage(t.growthView,"equipsup")
    if page and page.data.iid == t.growthIID then page:reloaddata(table.merge(page.data,t.equipdata),true) end
    local legacy = LocalEquipGrowthPage(t.growthView,"equipstage")
    if legacy and t.type == 1122 then legacy:reloadStatus(t.equipdata) end
    GameScene:UpdatePresentLayer()
end
UIEquipStageUp = update
UIEquipStarUp = update
