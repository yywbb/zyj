--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/2/29
-- Time: 14:38
-- To change this template use File | Settings | File Templates.
--

function UIMazeQuery(t)
    print("MazeQuery 3800，接受客户端数据")
    printT(t)

    if GameScene.layers["maze"].show then
        GameScene.layers["maze"].module:ReloadData(t)
    end
end

function UIMazeMove(t)
    print("Maze 3801，接受客户端数据")
    printT(t)

    if GameScene.layers["maze"].show then
        GameScene.layers["maze"].module:ReloadData(t)
    end

end

function UIMazeRandomEvent(t)
    print("Maze 3802，接受客户端数据")
    printT(t)

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,nil)
        UIRequest({type = 1001})
    end

    UIRequest({type = 3800})
end

function UIMazeBattle(t)
    print("Maze 3803，接受客户端数据")
    printT(t)

    local cb = function()
        --UIRequest({type = 3800})
        GameScene:shiftLayer("maze")
    end

    RunbattleCallBack("maze", t, cb)
end

function UIMazeReset(t)
    print("Maze 3812，接受客户端数据")
    printT(t)

    if GameScene.layers["maze"].show then
        GameScene.layers["maze"].module:ReloadData(t)
    end

    UIRequest({type = 1001})
end

function UIMazeShopQuery(t)
    print("迷宫商店查询3806 接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[25] then
        GameScene.layers["activity"].module.pageTable[25].module:reloaddata(t)
    end

end

function UIMazeShopRefresh(t)
    print("迷宫商店刷新3810 接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[25] then
        GameScene.layers["activity"].module.pageTable[25].module:refresh(t)
    end
    if t.isNeedGold == 1 then
        UIRequest({type = 1001})
    end    
end

function UIMazeShopBuy(t)
    print("迷宫商店购买3807 接受客户端数据")
    printT(t)

    if t.isUpGold == true then
        UIRequest({type = 1001})
    end    
    if GameScene.layers["activity"].module.pageTable[25] then
        GameScene.layers["activity"].module.pageTable[25].module:buyItem(t)
    end
    showRewardPopupWindow(t.reward,nil,nil)
    -- UIRequest({type = 1001})
end

function UIMazeTaskQuery(t)
    print("迷宫成就奖励查询3808 接受客户端数据")
    printT(t)
    
    gameWindows:openWindow("mazereward",t.data)
end

function UIMazeTaskGetReward(t)
    print("迷宫成就奖励领取3809 接受客户端数据")
    printT(t)

    if gameWindows.windows["mazereward"].show then
        gameWindows.windows["mazereward"].module:reload(t.listData)
    end

    showRewardPopupWindow(t.reward,nil,nil)
    UIRequest({type = 1001})
end