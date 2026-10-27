--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/25
-- Time: 上午10:43
-- To change this template use File | Settings | File Templates.
--

require"BattleReportAbbToKey"

local copy = {}

function getBraveCopyProcess()
    if next(copy) then
        local sectionMax = table.getTableLength(copy)
        local mapMax = (sectionMax-1)*5 + table.getTableLength(copy[tostring(sectionMax)].maps)
        local pointMax = table.getTableLength(copy[tostring(sectionMax)].maps[tostring(table.getTableLength(copy[tostring(sectionMax)].maps))].points)
        return mapMax+42100,pointMax
    else
        return 0,0
    end
end

function isBraveCopy3star(mapid,pointid)
    if next(copy) then
        local sectionMax = table.getTableLength(copy)
        local mapMax = (sectionMax-1)*5 + table.getTableLength(copy[tostring(sectionMax)].maps)
        if mapMax + 42100 >= mapid then
            local section = math.ceil((mapid-42100)/5)
            local map = math.mod((mapid-42100),5)
            if map ==0 then map = 5 end
            local pointdata =  copy[tostring(section)].maps[tostring(map)].points[tostring(pointid)] or {star = 0}
            return pointdata.star >=3
        else
            return false
        end
    else
        return false
    end
end

local function copyDataReload(t)
    copy = t.bravecopy
    GameScene.layers["copy_chapter"].module.bravedata = t.bravecopy
    GameScene.layers["copy_map"].module.bravedata = t.bravecopy
end

function UIBraveCopyQuery(t)
    print("副本1330 接受客户端数据")
    --printT(t)

    if not gameTimer.times["copywipe"] and t.copywipetimer ~= 0 then
        gameTimer:rigistTime("copywipe",t.copywipetimer)
    end

    copyDataReload(t)

    if GameScene.layers["copy_chapter"].show then
        GameScene.layers["copy_chapter"].module:reloadbraveData()
    end
    if GameScene.layers["copy_map"].show then
        GameScene.layers["copy_map"].module:reloadbraveData()
    end

end

function UIBraveCopyAttack(t)
    print("副本1331 接受客户端数据")

end

function UIBraveCopyAttack2(t)
    print("副本1338 接受客户端数据")
    --printT(t)

    copyDataReload(t)

    if t.encounters and next(t.encounters) then
        GameScene:addUpdate(1310)
        UIRequest({type = 1032})
    end

    if t.result == 0  or t.result == 1 then

        local cb = function()
            if t.layerTag == "map" then
                if  GameScene.layers["copy_map"].show then
                    GameScene.layers["copy_map"].module:reloadbraveData(nil,t.update and {} or nil)
                end

            elseif t.layerTag == "chapter" then
                GameScene:shiftLayer("copy_chapter","down",{
                    --bravedata = t.bravecopy,
                    isnewmap = true,
                    datatype= "brave",
                })
            end
        end
        RunbattleCallBack("copy", t, cb)
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})
end

function UIBraveCopyAll3StarReward(t)
    print("副本全三星奖励1333 接受客户端数据")


    copyDataReload(t)
    if t.result then
        runGamePrompt({msg = "增加"..t.stamina.."点体力"})
        if  GameScene.layers["copy_chapter"].show then
            GameScene.layers["copy_chapter"].module:reloadbraveData(t.bravecopy)
        end

    else
        runGamePrompt({msg = "领取失败"})

    end
    UIRequest({type = 1001})

end

function UIBraveCopyWipe(t)
    print("副本扫荡1332 接受客户端数据")

end

function UIBraveCopyWipe2(t)
    print("副本扫荡1338 接受客户端数据")

    --runGamePrompt({msg = "扫荡完成"} )
    copyDataReload(t)

    if t.encounters and next(t.encounters) then
        GameScene:addUpdate(1310)
        UIRequest({type = 1032})
    end

    RunbattleCallBack("copywipe", t)

    if  GameScene.layers["copy_map"].show then
        GameScene.layers["copy_map"].module:reloadbraveData(t.bravecopy)
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})
end

function UIBraveCopyPrestigeReward(t)
    print("副本声望奖励1334 接受客户端数据")

    --printT(t)
    copyDataReload(t)

    if GameScene.layers["copy_map"].show then
        GameScene.layers["copy_map"].module:reloadbraveData(t.bravecopy)
    end

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
end

function UIBraveCopyResetKill(t)
    print("副本重置次数1335 接受客户端数据")
    copyDataReload(t)

    if GameScene.layers["copy_map"].show then
        GameScene.layers["copy_map"].module:reloadbraveData(t.bravecopy)
    end
    UIRequest({type = 1001})
end
