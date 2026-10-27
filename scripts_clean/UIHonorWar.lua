--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/1
-- Time: 11:05
-- To change this template use File | Settings | File Templates.
--

function UIHonorWarSlotQuery(t)
    print("6701，接受客户端数据")
    printT(t)

    if GameScene.layers["honorBattleArray"].show then
        GameScene.layers["honorBattleArray"].module:ReloadData(t)
    end
end

function UIHonorWarSlotArrange(t)
    print("6702，接受客户端数据")
    printT(t)

    runGamePrompt({msg = "保存成功！"})
    if GameScene.layers["honorBattleArray"].show then
        GameScene.layers["honorBattleArray"].module:ReloadData(t)
    end
end

function UIHonorWarStatusQuery(t)
    print("6503，接受客户端数据")
    printT(t)

    if GameScene.layers["honorBattle"].show then
        GameScene.layers["honorBattle"].module:ReloadData(t)
    end
    if GameScene.layers["limitedset"].show then
        GameScene.layers["limitedset"].module:updateHonorIcon(t)
    end
end

function UIHonorWarRoleBattles(t)
    print("6504，接受客户端数据")
    printT(t)
    
    if GameScene.layers["honorBattle"].show then
        GameScene.layers["honorBattle"].module:reloadPersonal(t)
    end
end

function UIHonorWarRoleBattlesReward(t)
    print("6505，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
    UIRequest({type = 6504})
end

function UIHonorWarRoleBattlesInfo(t)
    print("6506，接受客户端数据")
    printT(t)

    if gameWindows.windows["honorBattleOdds"].show then
        gameWindows.windows["honorBattleOdds"].module:reloadData(t.info)
    end
end

function UIHonorWarBattlePlay(t)
    print("6507，接受客户端数据")
    printT(t)

    RunbattleCallBack("honorwar", t)

end

function UIHonorWarTop(t)
    print("6508，接受客户端数据")
    printT(t)

    if GameScene.layers["honorBattle"].show then
        GameScene.layers["honorBattle"].module:ReloadTop(t)
    end
end

function UIHonorWarWeedBet(t)
    print("6509，接受客户端数据")
    printT(t)
    if t.result == 1 then
        runGamePrompt({msg = "押注成功"})
    else
        runGamePrompt({msg = "押注失败"})
    end
    if gameWindows.windows["honorBattleOdds"].show then
        gameWindows.windows["honorBattleOdds"].module:refreshData()
    end

    UIRequest({type = 1001})
    UIRequest({type = 6508})
end

function UIHonorWarChampionQuery(t)
    print("6510，接受客户端数据")
    printT(t)
    gameWindows:openWindow("honorBattleChampion",t)
end

function UIHonorWarGroupInfoQuery(t)
    print("6511，接受客户端数据")
    printT(t)
    gameWindows:openWindow("honorBattleDivisionInfo",t)
end

function UIHonorWarTopUserInfo(t)
    print("6512，接受客户端数据")
    printT(t)

    if GameScene.layers["honorBattle"].show then
        GameScene.layers["honorBattle"].module:ReloadPlayers(t)
    end
end

function UIHonorWarLastChampionQuery(t)
    print("6513，接受客户端数据")
    printT(t)
    if GameScene.layers["honorBattle"].show then
        GameScene.layers["honorBattle"].module:reloadMain(t)
    end
end

function UIHonorWarStarRankQuery(t)
    print("6514，接受客户端数据")
    printT(t)

    gameWindows:openWindow("honorBattleStarRank",t)
end

function UIHonorWarSignup(t)
    print("6515，接受客户端数据")
    printT(t)

    UIRequest({type = 6503})
end

function UIWeekLiveness(t)
    print("6516，接受客户端数据")
    printT(t)
    if GameScene.layers["honorBattle"].show then
        GameScene.layers["honorBattle"].module:ReloadLiveness(t)
    end
end


function UIAchievementQuery(t)
    print("6518，接受客户端数据")
    printT(t)

    if gameWindows.windows["glory_battle_achievement"].show then
        gameWindows.windows["glory_battle_achievement"].module:reload(t)
    end

end

function UIAchievementReward(t)
    print("6519，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)

    UIRequest({type = 1001})
    UIRequest({type = 6518})
end
