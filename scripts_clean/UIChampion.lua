--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/18
-- Time: 10:22
-- To change this template use File | Settings | File Templates.
--

function UIChampionStatus(t)
    print("2700，接受客户端数据")
    printT(t)

    if GameScene.layers["champion"].show then
        GameScene.layers["champion"].module:reload(t.champion)
    elseif t.param and t.param == "main" then
        GameScene:shiftLayer("champion","up",t.champion)
    end

end

function UIChampionBattle(t)
    print("2701，接受客户端数据")
    printT(t)

--    local callBackFunc = function()
--        UIRequest({type = 2700})
--    end

    if t.isauto and t.isauto == 1 then
        if t.result and t.result == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("island",13)})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("island",12)})
        end
        if t.reward and next(t.reward) then
            showRewardPopupWindow(t.reward,nil,nil)
            if GameScene.layers["champion"].show then
                GameScene.layers["champion"].module:battlechangeData()
            end
        else
            UIRequest({type = 2700})
        end
    else
        RunbattleCallBack("champion", t,nil)
        if GameScene.layers["champion"].show then
            GameScene.layers["champion"].module:battlechangeData()
        end
    end
    --

    UIRequest({type = 1001})
end

function UIChampionNext(t)
    print("2702，接受客户端数据")
    printT(t)

    if GameScene.layers["champion"].show then
        GameScene.layers["champion"].module:reload(t.champion)
    end

end

function UIChampionReset(t)
    print("2703，接受客户端数据")
    printT(t)

    if GameScene.layers["champion"].show then
        GameScene.layers["champion"].module:reload(t.champion)
    end
    UIRequest({type = 1001})
end

function UIChampionBoxOpen(t)
    print("2704，接受客户端数据")
    printT(t)

    if GameScene.layers["champion"].show then
        GameScene.layers["champion"].module:reload(t.champion)
    end

    if gameWindows.windows["championbox"].show then
        gameWindows.windows["championbox"].module:reload(t.champion)
    end

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
end


--商店
function UIChampionShopQuery(t)
    print("2710，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        GameScene.layers["activity"].module.pageTable[162].module:reloadData(t)
    end

end

function UIChampionShop(t)
    print("2711，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward, nil,function()
        UIRequest({type = 2710,update = true})
        UIRequest({type = 1001})
    end)
end

function UIChampionShopReset(t)
    print("2712，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        GameScene.layers["activity"].module.pageTable[162].module:reloadData(t)
    end
    UIRequest({type = 1001})
end

function UIChampionComplete(t)
    print("2705，接受客户端数据")
    printT(t)

    gameWindows:openWindow("championResult", t, nil)
    UIRequest({type = 2700})
    UIRequest({type = 1001})
end