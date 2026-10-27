--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/4
-- Time: 下午2:16
-- To change this template use File | Settings | File Templates.
--

function UIPenglai(t)
    print("蓬莱仙道2040，接受客户端数据")
    --printT(t)

    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reloaddata(t)
    end

end

function UIPenglaiSelectDifficulty(t)
    print("蓬莱仙道2041，接受客户端数据")
    --printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reloaddata(t)
    end
end

function UIPenglaiSearch(t)
    print("蓬莱仙道2042，接受客户端数据")
    --printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:palystep(t)
    end
end

function UIPenglaiBattle(t)
    print("蓬莱仙道2043，接受客户端数据")
    --printT(t)

    local cb = function()
        if GameScene.layers["penglai"].show then
            GameScene.layers["penglai"].module:battlereloaddata(t)
        end
    end


    if t.result ~= -1 then
        RunbattleCallBack("penglai", t, cb)
    else
        cb()
    end

end

function UIPenglaiRank(t)
    print("蓬莱仙道2044，接受客户端数据")
    --printT(t)
    if gameWindows.windows["penglaiReward"].show then
        gameWindows.windows["penglaiReward"].module:relaodRank(t)
    end
end

function UIPenglaiTodayReward(t)
    print("蓬莱仙道2045，接受客户端数据")
    --printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
end

function UIPenglaiTotal(t)
    print("蓬莱仙道2046，接受客户端数据")
    --printT(t)

    if gameWindows.windows["penglaiReward"].show then
        gameWindows.windows["penglaiReward"].module:relaodTotal(t)
    end

end

function UIPenglaiTotalReward(t)
    print("蓬莱仙道2047，接受客户端数据")
    --printT(t)

    if gameWindows.windows["penglaiReward"].show then
        gameWindows.windows["penglaiReward"].module:resetpenglaitotal(t.id)
    end
    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
end

function UIPenglaiTask(t)
    print("蓬莱仙道2048，接受客户端数据")
    --printT(t)

    if gameWindows.windows["penglaiReward"].show then
        gameWindows.windows["penglaiReward"].module:relaodTask(t)
    end
end

function UIPenglaiTaskReward(t)
    print("蓬莱仙道2049，接受客户端数据")
    --printT(t)
    if gameWindows.windows["penglaiReward"].show then
        gameWindows.windows["penglaiReward"].module:resetpenglaitask(t.id)
    end
    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
end
