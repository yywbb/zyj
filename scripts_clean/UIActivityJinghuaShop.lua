--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UIJinghuaShopQuery(t)
    print("商店6451，接受客户端数据")

    printT(t)

    if  GameScene.layers["activity"].module.pageTable[161] and GameScene.layers["activity"].module.pageTable[161].module.show then
        GameScene.layers["activity"].module.pageTable[161].module:reloadData(t)
    end

end

function UIJinghuaShopReward(t)
    print("商店6452，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward, nil,nil)

    GameScene:addUpdate(1200)
    UIRequest({type = 6451})
    UIRequest({type = 1001})

end
