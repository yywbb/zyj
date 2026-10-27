--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/8
-- Time: 上午10:06
-- To change this template use File | Settings | File Templates.
--


-- 装备进阶
function UIEquipStageUp(t)
    print("装备进阶1122,接受客户端数据")
    printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    
    GameScene:addUpdate(10025)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10025,t.equipdata.type)
    GameScene:addUpdate(10025,"offequips")

    updateDataLife(t.props)

    if GameScene.layers["equipstage"].show then
        GameScene.layers["equipstage"].module:reloadStatus(t.equipdata)
    end

    if GameScene.layers["equipsup"].show then
        if not GameScene:checkUpdate(10025,"slotequips") then

        end
        GameScene.layers["equipsup"].module:reload({data = t.equipdata})

    end

    UIRequest({type = 1001})
    UIRequest({type = 10322})

    if t.qualityUp == 1 then
        print("t.qualityUp")
        UIRequest({type = 1002, param = "devil"})
    end

end

