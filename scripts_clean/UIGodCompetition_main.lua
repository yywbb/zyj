--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 22/3/3
-- Time: 10:33
-- To change this template use File | Settings | File Templates.
--

--封神赛报名
function UIUserApesSignUp(t)
    print("8250, 接受客户端数据")
    printT(t)

    UIRequest({type = 8251})
end

function UIUserApexQuery(t)
    print("8251, 接受客户端数据")
    printT(t)

    if GameScene.layers["godCompetitionMain"].show then
        GameScene.layers["godCompetitionMain"].module:ReloadBossData(t)
    end

    if GameScene.layers["godCompetitionSlotsDetail"].show then
        UIRequest({type = 8263, timeid = t.godStatus.status})
    end

    if GameScene.layers["limitedset"].show then
        GameScene.layers["limitedset"].module:updateGodCompettionIcon(t)
    end
    
end

function UIUserApexBossAttack(t)
    print("8258, 接受客户端数据")
    printT(t)

    t.battlereport = MergeBattleReportForGodCompetition(t.battlereport1,t.battlereport2,t.battlereport3)
    
    printT(t.battlereport,"jkp-battlereport")
    --godCompetitionBattle

    local callBackFunc = function()
        UIRequest({type = 8251})
        UIRequest({type = 1001})        
    end
    RunbattleCallBack("godCompetitionBattle", t, callBackFunc)
end

function UIUserApexBossDamageRank(t)
    print("8259, 接受客户端数据")
    printT(t)

    if gameWindows.windows["godCompetition_hurtlist"].show then
        gameWindows.windows["godCompetition_hurtlist"].module:serviceScoreReload(t)
    end

end

function UIUserApexBossBattleRecord(t)
    print("8260, 接受客户端数据")
    printT(t)
    if gameWindows.windows["godcompetition_battleRecord"].show then
        gameWindows.windows["godcompetition_battleRecord"].module:reloadData(t)
    end
end

function UIUserApexBossRewardsQuery(t)
    print("8261, 接受客户端数据")
    printT(t)
    if gameWindows.windows["godCompetition_reward"].show then
        gameWindows.windows["godCompetition_reward"].module:reloadData(t)
    end
end

function UIUserApexBossRewardsCollect(t)
    print("8262, 接受客户端数据")
    printT(t)
    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
    UIRequest({type = 8261})
end


function UIUserApexUpLoadSlots(t)
    print("8263, 接受客户端数据")
    printT(t)
    if GameScene.layers["godCompetitionSlotsDetail"].show then
        GameScene.layers["godCompetitionSlotsDetail"].module:ReloadPVP(t)
    end
end

function UIUserCheckLoadSlots(t)
    print("8264, 接受客户端数据")
    printT(t)
    if GameScene.layers["godCompetitionSlotsDetail"].show then
        GameScene.layers["godCompetitionSlotsDetail"].module:ReloadBoss(t)
    end
end

function UIUserWarOfApexChampionOld(t)
    print("8271, 接受客户端数据")
    printT(t)

end

function UIUserWarOfApexReward(t)
    print("8272, 接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
    UIRequest({type = 8279})
end

function UIUserWarOfApexRoleBattlesInfo(t)
    print("8273, 接受客户端数据")
    printT(t)

    if gameWindows.windows["godCompetitionBattleOdds"].show then
        gameWindows.windows["godCompetitionBattleOdds"].module:reloadData(t.battleinfo)
    end

end

function UIUserWarOfApexBattlePlay(t)
    print("8274, 接受客户端数据")
    printT(t)

    RunbattleCallBack("godCompetition", t)
end

function UIUserWarOfApexBet(t)
    print("8275, 接受客户端数据")
    printT(t)

    if t.result == 1 then
        runGamePrompt({msg = "押注成功"})
    else
        runGamePrompt({msg = "押注失败"})
    end
    if gameWindows.windows["godCompetitionBattleOdds"].show then
        gameWindows.windows["godCompetitionBattleOdds"].module:refreshData()
    end

    UIRequest({type = 1001})
    UIRequest({type = 8280})
end

function UIUserWarOfApexChampoionQuery(t)
    print("8276, 接受客户端数据")
    printT(t)
    gameWindows:openWindow("honorBattleChampion",t)
end

function UIUserWarOfApexGroupInfo(t)
    print("8277, 接受客户端数据")
    printT(t)
    gameWindows:openWindow("godCompetitionBattleDivisionInfo",t)
end

function UIUserWarOfApexSrarRank(t)
    print("8278, 接受客户端数据")
    printT(t)

    gameWindows:openWindow("godCompetitionBattleStarRank",t)
end

function UIUserWarOfApexRoleBattles(t)
    print("8279, 接受客户端数据")
    printT(t)

    if GameScene.layers["godCompetitionMain"].show then
        GameScene.layers["godCompetitionMain"].module:reloadPersonal(t)
    end
end

function UIUserWarOfApexTopInfo(t)
    print("8280, 接受客户端数据")
    printT(t)

    if GameScene.layers["godCompetitionMain"].show then
        GameScene.layers["godCompetitionMain"].module:ReloadTop(t)
    end
end

function UIUserWarOfApexRolesInfo(t)
    print("8281, 接受客户端数据")
    printT(t)

    if GameScene.layers["godCompetitionMain"].show then
        GameScene.layers["godCompetitionMain"].module:ReloadPlayers(t)
    end
end