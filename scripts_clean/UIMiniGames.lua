
function UIMiniGameQuery(t)
    print("1600, 接受客户端数据")
    printT(t)

    if t.data.state > 0 then
        GameScene.layers["main"].module:setNode(true, "minigamenode")
    else
        GameScene.layers["main"].module:setNode(false, "minigamenode")
    end

    if GameScene.layers["minigame"].show then
        GameScene.layers["minigame"].module:reloadData(t.data)
    end
end

function UIMiniGameSynchronization(t)
    print("1601, 接受客户端数据")
    printT(t)

    if t.state == 0 then --作弊了
        
    end
end

function UIMiniGameOver(t)
    print("1602, 接受客户端数据")
    printT(t)

    UIRequest({type = 1032})
    UIRequest({type = 1600})
end

function UIMiniGameStart(t)
    print("1603, 接受客户端数据")
    printT(t)

    UIRequest({type = 1600})
end

function UIMiniGameExchange(t)
    print("1604, 接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)

    UIRequest({type = 1001})
    UIRequest({type = 1600})
    UIRequest({type = 1608})
end

function UIMiniGameAchievement(t)
    print("1605, 接受客户端数据")
    printT(t)

    if gameWindows.windows["game2048achievement"].show then
        gameWindows.windows["game2048achievement"].module:reloadData(t)
    end
end

function UIMiniGameAchievementReward(t)
    print("1606, 接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
        UIRequest({type = 1605})
    end)
end

function UIMiniGameRank(t)
    print("1607, 接受客户端数据")
    printT(t)

    if gameWindows.windows["game2048rank"].show then
        gameWindows.windows["game2048rank"].module:reloadData(t)
    end
end

function UIMiniGameExchangeQuery(t)
    print("1608, 接受客户端数据")
    printT(t)

    if gameWindows.windows["game2048shop"].show then
        gameWindows.windows["game2048shop"].module:relaodpoint(t.allpoint)
        gameWindows.windows["game2048shop"].module:reloaddata(t.exchangeData)
    end

end