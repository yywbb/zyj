--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/3
-- Time: 下午3:31
-- To change this template use File | Settings | File Templates.
--

function UISlotsArrangeQuary(t)
    print("布阵3702，接受客户端数据")
    -- printT(t)
    if t.slotarrangeparam and t.slotarrangeparam == "notgoto" then
    else
        GameScene:shiftLayer("slotarrange",nil,t)
    end

end

function UISlotsArrange(t)
    print("布阵3703，接受客户端数据")
    -- printT(t)

    if GameScene.layers["slotarrange"].show then
        GameScene.layers["slotarrange"].module:reloadData(t)
    end

end

-- 乾坤炉化魂 需要排除的数据
function UISlotsExcept(t)
    printT(t,"布阵3704，接受客户端数据")
    -- printT(t)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:huahunSortData(t.iids)
    end

    if GameScene.layers["change"].show then
        GameScene.layers["change"].module:setOffGeneralRemoveData(t.iids)
    end


    if t.GodSoulTemple then
        if GameScene.layers["godSoulTempleRefineSoul"].show then
            GameScene.layers["godSoulTempleRefineSoul"].module:setFragmentsData(t)
        end
    end
end

function UIEnemySlotsQuary(t)
    print("迷宫敌方布阵3811，接受客户端数据")
    -- printT(t)

    GameScene:shiftLayer("slotenemy",nil,t)
    if GameScene.layers["slotenemy"].show then
        GameScene.layers["slotenemy"].module:reloadData(t)
    end
    UIRequest({type = 1001})

end

function UISlotsWithHpQuary(t)
    print("迷宫己方布阵3804，接受客户端数据")
    -- printT(t)


    GameScene:shiftLayer("slotwithhp",nil,t)

end

function UISlotsChangeWithHp(t)
    print("迷宫己方换阵3805，接受客户端数据")
    -- printT(t)

    if GameScene.layers["slotwithhp"].show then
        GameScene.layers["slotwithhp"].module:reloadData(t)
    end

end


