--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-10
-- Time: 上午10:48
-- To change this template use File | Settings | File Templates.
--
require"BattleReportAbbToKey"

local copy = {}

function getNormalCopyProcess()
   if next(copy) then
       local sectionMax = table.getTableLength(copy)
       local mapMax = (sectionMax-1)*5 + table.getTableLength(copy[tostring(sectionMax)].maps)
       local pointMax = table.getTableLength(copy[tostring(sectionMax)].maps[tostring(table.getTableLength(copy[tostring(sectionMax)].maps))].points)
       return mapMax+42100,pointMax
   else
       return 0,0
   end
end

function isNormalCopy3star(mapid,pointid)
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

function hasNormalCopyChallenge(mapid,pointid)
    if next(copy) then
        if mapid and pointid and mapid > 0 and pointid > 0 then
            local maxchallenge = gamedata.config.copy[tostring(mapid)][tostring(pointid)] and gamedata.config.copy[tostring(mapid)][tostring(pointid)].challenge or 0
            local sectionMax = table.getTableLength(copy)
            local mapMax = (sectionMax-1)*5 + table.getTableLength(copy[tostring(sectionMax)].maps)
            if mapMax + 42100 >= mapid then
                local section = math.ceil((mapid-42100)/5)
                local map = math.mod((mapid-42100),5)
                if map ==0 then map = 5 end
                local kill = copy[tostring(section)].maps[tostring(map)].points[tostring(pointid)] and copy[tostring(section)].maps[tostring(map)].points[tostring(pointid)].kill or 0
                return kill < maxchallenge
            else
                return true
            end 
         else
            return true
         end   
    else
        return true
    end
end

local function copyDataReload(t)
    copy = t.copy
    GameScene.layers["copy_chapter"].module.normaldata = t.copy
    GameScene.layers["copy_map"].module.normaldata = t.copy
end

function UICopyQuery(t)
    print("副本1300 接受客户端数据")
    --printT(t)

    copyDataReload(t)

    if GameScene.layers["copy_chapter"].show then
        GameScene.layers["copy_chapter"].module:reloadnormalData()
    end

    if GameScene.layers["copy_map"].show then
        GameScene.layers["copy_map"].module:reloadnormalData()
    end
end

function UICopyAttack(t)
    print("副本1301 接受客户端数据")

end

function UICopyAttack2(t)
    print("副本1306 接受客户端数据")
    printT(t)
    copyDataReload(t)

    if t.encounters and next(t.encounters) then
        GameScene:addUpdate(1310)
        UIRequest({type = 1032})
    end

    if t.result == 0  or t.result == 1 then

        local cb= function()
            if t.layerTag == "map" then
                if GameScene.layers["copy_map"].show then
                    GameScene.layers["copy_map"].module:reloadnormalData(nil,t.update and {} or nil)
                end
            elseif t.layerTag == "chapter" then
                GameScene:shiftLayer("copy_chapter","down",{
                    --normaldata = t.copy,
                    isnewmap = true,
                    datatype= "normal",
                })
            end
        end
        RunbattleCallBack("copy", t, cb)
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})

    if GameScene:checkopenlevelbyId(148,true) then
        UIRequest({type = 1350})
    end

    if GameScene:checkopenlevelbyId(430,true) then
        UIRequest({type = 1370})
    end
end

function UICopyAll3StarReward(t)
    print("副本全三星奖励1303 接受客户端数据")
    copyDataReload(t)

    if t.result then
        runGamePrompt({msg = "增加"..t.stamina.."点体力"})
        if GameScene.layers["copy_chapter"].show then
            GameScene.layers["copy_chapter"].module:reloadnormalData(t.copy)
        end
    else
        runGamePrompt({msg = "领取失败"})
    end
    UIRequest({type = 1001})

end

function UICopyWipe(t)
    print("副本扫荡1302 接受客户端数据")

end

function UICopyWipe2(t)
    print("副本扫荡1307 接受客户端数据")
    printT(t)
    copyDataReload(t)

    if t.encounters and next(t.encounters) then
        GameScene:addUpdate(1310)
        UIRequest({type = 1032})
    end

    RunbattleCallBack("copywipe", t)

    if GameScene.layers["copy_map"].show then
        GameScene.layers["copy_map"].module:reloadnormalData(t.copy)
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})
end

function UICopyPrestigeReward(t)

    copyDataReload(t)

    if GameScene.layers["copy_map"].show then
        GameScene.layers["copy_map"].module:reloadnormalData(t.copy)
    end

    if guide.controller then
        guide.controller:setGuideLayerVisible(false)
    end
    showRewardPopupWindow(t.reward,nil,function()
        if guide.controller then
            guide.controller:UIComplete(80141)
        end
    end)
    UIRequest({type = 1001})
end

function UICopyResetKill(t)
    print("副本重置次数1305 接受客户端数据")

    copyDataReload(t)

    if GameScene.layers["copy_map"].show then
        GameScene.layers["copy_map"].module:reloadnormalData(t.copy)
    end
    UIRequest({type = 1001})
end


function UICopyClearTimer(t)
    print("副本重置CD1336 接受客户端数据")

end
