--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/3
-- Time: 下午1:26
-- To change this template use File | Settings | File Templates.
--

function UITaskQuery(t)
    print("任务奖励2400，接受客户端数据")
    -- printT(t)
    if GameScene.layers["achievement"].show then
        GameScene.layers["achievement"].module:reloaddata(t)
    end
end

function UITaskComplete(t)
    print("任务奖励2401，接受客户端数据")
    --printT(t)

--    if GameScene.layers["task"].show then
--        GameScene.layers["task"].module:reloaddata(t)
--    end
    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
        UIRequest({type = 2400})
    end)


end

function UIOnlineRewardQuery(t)
    print("在线奖励2037，接受客户端数据")

    if t.param then
        if not next(t.reward) then
            runGamePrompt({msg = "今日奖励已领完"})
        else
            gameWindows:openWindow("online",t.reward,nil)
        end
        return
    end

    if next(t.reward) then
        gameTimer:rigistTime("online_reward",t.reward.time)
    end
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadOnlinereward(t.reward)
    end
end

function UIOnlineReward(t)
    print("在线奖励2038，接受客户端数据")


    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 2037})
        UIRequest({type = 1001})
    end)

end


function UIOnlineRewardByTimeQuery(t)
    print("在线奖励2039，接受客户端数据")
    printT(t)

    if t.param then
        if not next(t.reward) then
            runGamePrompt({msg = "今日奖励已领完"})
        else
            gameWindows:openWindow("onlinebytime",t.reward,nil)
        end
        return
    end

    if next(t.reward) then
        gameTimer:rigistTime("online_rewardbytime",t.reward.time)
    end
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadOnlinerewardByTime(t.reward)
    end
end

function UIOnlineRewardByTime(t)
    print("在线奖励2040，接受客户端数据")


    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 2039})
        UIRequest({type = 1001})
    end)

end