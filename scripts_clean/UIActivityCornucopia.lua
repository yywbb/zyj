--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/4/21
-- Time: 14:47
-- To change this template use File | Settings | File Templates.
--

function UICornucopiaQuery(t)
    print("2031，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[29] then
        GameScene.layers["activity"].module.pageTable[29].module:reloaddata(t)
    end
end

function UICornucopia(t)
    print("2032，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[29] then
        GameScene.layers["activity"].module.pageTable[29].module:play(t)
    end

    updateDataLife(t.reward)
    --showRewardPopupWindow(t.reward,nil,nil)
    UIRequest({type = 1001})

end

function UICornucopiaReward(t)
    print("2033，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[29] then
        GameScene.layers["activity"].module.pageTable[29].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward,nil,nil)
    UIRequest({type =1001})
end