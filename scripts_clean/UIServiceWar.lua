--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/1
-- Time: 11:05
-- To change this template use File | Settings | File Templates.
--

function UIWorldWarQuery(t)
    print("4702，接受客户端数据")
    printT(t)

    if t.worldwarstatus then
        gameConfig:makeServerWarTimeForStage(t.worldwarstatus.s_open)
    end

    if t.param and t.param == "goto" then
        if t.worldwarstatus.status < 2 or t.worldwarstatus.list < 1 then
            GameScene:shiftLayer("servicewarBefore","up")
        else
            GameScene:shiftLayer("servicewarNow","up")
        end
    elseif t.param and t.param == "update" then
        if GameScene.layers["servicewarBefore"].show then
            GameScene.layers["servicewarBefore"].module:ReloadData(t)
        end
        if GameScene.layers["servicewarNow"].show then
            GameScene.layers["servicewarNow"].module.worldwarstatus = t.worldwarstatus
            UIRequest({type = 4703})
            UIRequest({type = 4708,division = GameScene.layers["servicewarNow"].module.selectDivision})
        end
    end

    if GameScene.layers["limitedset"].show then
        GameScene.layers["limitedset"].module:updateServiceIcon(t)
    end

end

function UIWorldWarPrepareQuery(t)
    print("4700，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarBefore"].show then
        GameScene.layers["servicewarBefore"].module:ReloadData(t)
    end
end

function UIWorldWarGetItem(t)
    print("4701，接受客户端数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["servicewarBefore"].show then
        GameScene.layers["servicewarBefore"].module:ReloadData(t)
    end

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
end

function UIWorldWarPrepareUpdateSlot(t)
    print("4704，接受客户端数据")
    printT(t)

    if t.result and t.result == 1 then
        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",7)})
    else
        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",8)})
    end
end


function UIWorldWarRoleBattles(t)
    print("4703，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarNow"].show then
        GameScene.layers["servicewarNow"].module:ReloadData(t)
    end

end

--
function UIWorldWarBattlePlay(t)
    print("4711，接受客户端数据")
    printT(t)

    RunbattleCallBack("servicewar", t)

end

--
function UIWorldWarRoleBattlesReward(t)
    print("4714 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
    UIRequest({type = 4703})
end


function UIWorldWarTopUserInfo(t)
    print("4712，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarNow"].show then
        GameScene.layers["servicewarNow"].module:ReloadPlayers(t)
    end

end

function UIWorldWarTop(t)
    print("4708，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarNow"].show then
        GameScene.layers["servicewarNow"].module:ReloadTop(t)
    end

end

--
function UIWorldWarSignInfoQuer(t)
    print("跨服战4705，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarchampionlist"].show then
        gameWindows.windows["servicewarchampionlist"].module:joinedreload(t.playerdata)
    end

end


function UIWorldWarChampionQuer(t)
    print("跨服战4706，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarchampionlist"].show then
        gameWindows.windows["servicewarchampionlist"].module:championreload(t.infodata)
    end

end

function UIWorldWarGroupInfoQuery(t)
    print("跨服战4707，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarchampionlist"].show then
        gameWindows.windows["servicewarchampionlist"].module:matchinforeload(t.infodata)
    end

end

function UIWorldWarTopInfo(t)
    print("跨服战4710，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarbet"].show then
        gameWindows.windows["servicewarbet"].module:reloadWatchData(t.playerdata)
    end

end

function UIWorldWarTopBetInfo(t)
    print("跨服战4713，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarbet"].show then
        gameWindows.windows["servicewarbet"].module:reloadData(t.servicedata)
    end

end

function UIWorldWarRankQuery(t)
    print("跨服战4715，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarchampionlist"].show then
        gameWindows.windows["servicewarchampionlist"].module:serviceScoreReload(t.playersdata)
    end

end

function UIWorldWarWeedBet(t)
    print("跨服战4716，接受客户端数据")
    printT(t)
    if t.result == 1 then
        runGamePrompt({msg = "押注成功"})
    else
        runGamePrompt({msg = "押注失败"})
    end

    UIRequest({type = 1001})
    
    if GameScene.layers["servicewarNow"].show then
        UIRequest({type = 4713, id = t.id,division = GameScene.layers["servicewarNow"].module.selectDivision})
        UIRequest({type = 4708,division = GameScene.layers["servicewarNow"].module.selectDivision})
    end
end

--

function UIWorldWarCurrentChampionQuery(t)
    print("4717，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarAfter"].show then
        GameScene.layers["servicewarAfter"].module:ReloadData(t)
    end

    if GameScene.layers["servicewarBefore"].show then
        GameScene.layers["servicewarBefore"].module:setChampionNode(t.worldwarchampion.number > 0)
    end

    if GameScene.layers["servicewarNow"].show then
        GameScene.layers["servicewarNow"].module:setChampionNode(t.worldwarchampion.number > 0)
    end

end

function UIWorldWarWorship(t)
    print("4718，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    UIRequest({type = 4717})

end


function UIWorldWarPreparePush(t)
    print("4709，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarBefore"].show then
        GameScene.layers["servicewarBefore"].module:ReloadPushData(t)
    end

end

function UIWorldWarRoleBattlesShenbang(t)
    print("4720，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarNow"].show then
        GameScene.layers["servicewarNow"].module:ReloadData(t)
    end

end

function UIWorldWarTopShenbang(t)
    print("4721，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarNow"].show then
        GameScene.layers["servicewarNow"].module:ReloadTop(t)
    end

end

function UIWorldWarWeedBetShenbang(t)
    print("跨服战4721，接受客户端数据")
    printT(t)
    if t.result == 1 then
        runGamePrompt({msg = "押注成功"})
    else
        runGamePrompt({msg = "押注失败"})
    end

    UIRequest({type = 1001})
    UIRequest({type = 4726, id = t.id})

    if GameScene.layers["servicewarNow"].show then
        UIRequest({type = 4708,division = GameScene.layers["servicewarNow"].module.selectDivision})
    end
end

function UIWorldWarRoleBattlesRewardShenbang(t)
    print("4723 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
    UIRequest({type = 4720})
end

function UIWorldWarTopUserInfoShenbang(t)
    print("4724，接受客户端数据")
    printT(t)

    if GameScene.layers["servicewarNow"].show then
        GameScene.layers["servicewarNow"].module:ReloadPlayers(t)
    end

end

function UIWorldWarTopInfoShenbang(t)
    print("跨服战4725，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarbet"].show then
        gameWindows.windows["servicewarbet"].module:reloadWatchData(t.playerdata)
    end

end

function UIWorldWarTopBetInfoShenbang(t)
    print("跨服战4726，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarbet"].show then
        gameWindows.windows["servicewarbet"].module:reloadData(t.servicedata)
    end

end

function UIWorldWarBattlePlayShenbang(t)
    print("4727，接受客户端数据")
    printT(t)

    RunbattleCallBack("servicewar", t)

end


function UIWorldWarRankQueryShenbang(t)
    print("跨服战4728，接受客户端数据")
    printT(t)

    if gameWindows.windows["servicewarchampionlist"].show then
        gameWindows.windows["servicewarchampionlist"].module:serviceScoreReload(t.playersdata)
    end

end
