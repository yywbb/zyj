--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 14/10/23
-- Time: 14:18
-- To change this template use File | Settings | File Templates.
--

function UIEncounterQueryExt(t)

    if t.updatetime and t.updatetime >0 then
        gameTimer:rigistTime("mainqiyunode",t.updatetime)
    end
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has ==1 and t.updatetime >0,"qiyunode")
    end
end

function UIEncounterQuery(t)
    print("1310 接受客户端数据")
    printT(t)

    --test
    --t.encounters["1"]["time"] = 8000

    GameScene.layers["encounter2"].module.encounterData = t.encounters

    if GameScene.layers["encounter2"].show then
        GameScene.layers["encounter2"].module:reloadData()
    elseif t.param and t.param =="goto" then
        if next(t.encounters) then
            GameScene:shiftLayer("encounter2")
        else
            runGamePrompt({msg = "还没遇到奇遇"})
        end
    end

end

function UIEncounterUse(t)
    print("1311 接受客户端数据")
    printT(t)
    -- todo

    if gameTimer.times["encounter_"..t.iid] then
        gameTimer:UnrigistTimeFunc("encounter_"..t.iid)
    end

    local cb = function()
        GameScene:UpdatePresentLayer()
        UIRequest({type = 1310})
    end

    if t.encounterType == "exp" then
        if t.reward ~= "" then
            showRewardPopupWindow(t.reward, nil,cb)
        end
    elseif t.encounterType == "search" then
        if t.reward ~= "" then
            showRewardPopupWindow(t.reward, nil,cb)
        end
    elseif t.encounterType == "battle" then
        if t.battlereport ~= "" then
            RunbattleCallBack("encounter", t,cb)
        elseif t.reward ~= "" then
            showRewardPopupWindow(t.reward, nil,cb)
        end
    elseif t.encounterType == "general" then

        if t.gets and table.getTableLength(t.gets) > 0 then --or t.fragments ~= "" then
            t.opt = 2
            gameWindows:openWindow("recruit",{type = "one", data = t },cb)
            GameScene:addUpdate(1012)
            GameScene:addUpdate(10024)
            GameScene:addUpdate(10211)
            GameScene:addUpdate(10023)
        elseif t.reward  and table.getTableLength(t.reward) > 0 then
            showRewardPopupWindow(t.reward, nil,cb)
        end
    elseif t.encounterType == "shop" then
        if t.reward ~= "" then
            showRewardPopupWindow(t.reward, nil,cb)
        end
    end


    UIRequest({type = 1001})
    GameScene:addUpdate(1200)
    GameScene:addUpdate(1310)
    --UIRequest({type = 1310})
end

function UIEncounterTimeUp(t)
--    if gameTimer.times["encounter_"..t.iid] then
--        gameTimer:UnrigistTimeFunc("encounter_"..t.iid)
--    end

    GameScene.layers["encounter2"].encounterData = t.encounters

    if GameScene.layers["encounter2"].show then
        GameScene.layers["encounter2"].module:reloadData(t)
    end

    --UIRequest({type = 1310})
end