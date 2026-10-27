--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/8
-- Time: 上午10:06
-- To change this template use File | Settings | File Templates.
--


-- 装备升星
function UIEquipStarUp(t)
    print("装备升星1123,接受客户端数据")
    printT(t)
    if t.equipdata.ison and t.equipdata.ison == 1 then
        GameScene:addUpdate(10021)
        GameScene:addUpdate(10023)
    end
    
    GameScene:addUpdate(10025)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10025,t.equipdata.type)
    GameScene:addUpdate(10025,"offequips")

    updateDataLife(t.props)

    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:reloaddata(t.equipdata, true)
    end
    UIRequest({type = 1001})
end

--宝物升星
function UITreasureStarUp(t)
    print("宝物升星1127, 接受客户端数据")
    printT(t)

    GameScene:addUpdate(10025,"offtreasures")
    GameScene:addUpdate(10025,"treasures")
    GameScene:addUpdate(10021)

    updateDataLife(t.props)

    if GameScene.layers["treasureup"].show then
        GameScene.layers["treasureup"].module:ReloadData(t.equipdata)
    end
    UIRequest({type = 1001})
end
