--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/28
-- Time: 16:45
-- To change this template use File | Settings | File Templates.
--

function UIRecall(t)
    print("3770,接受客户端数据")
    printT(t)
    if t.recall then
        if GameScene.layers["activity"].module.pageTable[58] then
            GameScene.layers["activity"].module.pageTable[58].module:reloaddata(t.recall)
        end
    else
    end
end

function UIRecallReward(t)
    print("3771,接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward)
    UIRequest({type = 1001})
    UIRequest({type = 3770})

end

function UIRecallChange(t)
    print("3776,接受客户端数据")
    printT(t)

    UIRequest({type = 3770, update = true})
end