
--与海外版有差异，国内版名将副本没有通关宝箱

local starcopy = {}

function getStarCopyProcess()
    if next(starcopy) then
        local sectionMax, mapMax, pointMax = 0,0,0
        for i = 1,table.getTableLength(starcopy.sections) do
            if i >= sectionMax and starcopy.sections[tostring(i)] then
                for ii = 1,table.getTableLength(starcopy.sections[tostring(i)]) do
                    if starcopy.sections[tostring(i)][tostring(ii)] and starcopy.sections[tostring(i)][tostring(ii)].status and starcopy.sections[tostring(i)][tostring(ii)].status > -1 then
                        sectionMax = i
                        mapMax = starcopy.sections[tostring(i)][tostring(ii)].mapid
                        pointMax = table.getTableLength(starcopy.sections[tostring(i)][tostring(ii)].points)
                    end
                end
            end
        end
        return mapMax,pointMax
    else
        return 0,0
    end
end

function UIGeneralCopyQuery(t)
    print("名将副本查询 1350 接受客户端数据")
    printT(t)
    if GameScene:checkopenlevelbyId(148,true) then
        starcopy = table.copy(t.starcopy)

        GameScene.layers["copy_chapter"].module.stardata = t.starcopy
        if  GameScene.layers["copy_chapter"].show then
            GameScene.layers["copy_chapter"].module:reloadStarCopyData(t)
        end

        if  GameScene.layers["starcopy_map"].show then
            GameScene.layers["starcopy_map"].module:reloaddata(t.starcopy,true)
        end
    end
end

function UIGeneralCopyAttack(t)
    print("名将副本挑战 1351 接受客户端数据")
    printT(t)

    local cb = function()
        local cb1 = function() UIRequest({type = 1350}) end
        if next(t.firstreward) then
            gameWindows:openWindow("firstwin",{reward = t.firstreward},cb1)
        else
            cb1()
        end
    end

    RunbattleCallBack("copystar", t, cb)

    UIRequest({type = 1001})
end

function UIGeneralCopyGetBox(t)
    print("名将副本领取 1352 接受客户端数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1001})
    end

    GameScene.layers["copy_chapter"].module.stardata = t.starcopy
    if  GameScene.layers["starcopy_map"].show then
        GameScene.layers["starcopy_map"].module:reloaddata(t.starcopy,true)
    end

end



--hades
local hadescopy = {}

function getHadesCopyProcess()
    if next(hadescopy) then
        local sectionMax, mapMax, pointMax = 0,0,0
        for i = 1,table.getTableLength(hadescopy.sections) do
            if i >= sectionMax and hadescopy.sections[tostring(i)] then
                for ii = 1,table.getTableLength(hadescopy.sections[tostring(i)]) do
                    if hadescopy.sections[tostring(i)][tostring(ii)] and hadescopy.sections[tostring(i)][tostring(ii)].status and hadescopy.sections[tostring(i)][tostring(ii)].status > -1 then
                        sectionMax = i
                        mapMax = hadescopy.sections[tostring(i)][tostring(ii)].mapid
                        pointMax = table.getTableLength(hadescopy.sections[tostring(i)][tostring(ii)].points)
                    end
                end
            end
        end
        return mapMax,pointMax
    else
        return 0,0
    end
end

function UIHadesCopyQuery(t)
    print("副本查询 1370 接受客户端数据")
    printT(t)
    if GameScene:checkopenlevelbyId(430,true) then
        hadescopy = table.copy(t.hadescopy)

        -- GameScene.layers["copy_chapter"].module.hadesdata = t.hadescopy
        if  GameScene.layers["copy_chapter"].show then
            GameScene.layers["copy_chapter"].module:reloadHadesCopyData(t)
        end

        if  GameScene.layers["hadescopy_map"].show then
            GameScene.layers["hadescopy_map"].module:reloaddata(t.hadescopy,true)
        end
    end
end

function UIHadesCopyAttack(t)
    print("副本挑战 1371 接受客户端数据")
    printT(t)

    local cb = function()
        if  GameScene.layers["copy_chapter"].show then
            GameScene.layers["copy_chapter"].module:hadesCopyBattleCallback(t)
        end
    end
    if t.skip == 1 and t.result == 1 then
        runGamePrompt({msg = "实力压榨,秒杀敌人!",change_type = "red"})
        if t.reward and next(t.reward) then
            showRewardPopupWindow(t.reward,nil,cb)
        end

    else
        RunbattleCallBack("copyhades", t, cb)
    end

    UIRequest({type = 1001})
end

function UIHadesCopyGetBox(t)
    print("副本领取 1372 接受客户端数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1001})
        UIRequest({type = 1370})
    end

end