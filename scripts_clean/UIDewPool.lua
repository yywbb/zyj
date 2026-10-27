--
-- Author: songyibo
-- Date: 2020-06-15 16:46:26
--

function UIDewPoolQuery(t)
    printT(t,"8055 露水池查询")

    if GameScene.layers["activity"].module.pageTable[166].module.show then
        GameScene.layers["activity"].module.pageTable[166].module:reloaddata(t.data)
    end
end

function UIDewPoolAward(t)
    printT(t,"8056 露水池领奖")
    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if t.unLockTask and t.unLockTask == 1 then
        runGamePrompt({msg = "露水收集任务已解锁"})
    end
    UIRequest({type = 8055})
end

function UIDewPoolExchange(t)
    printT(t,"8057 露水池商店购买")
    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    UIRequest({type = 8055})
end

