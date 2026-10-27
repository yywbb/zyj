--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UIActivitySecretShopQuery(t)
    print("神秘商店3650，接受客户端数据")

    -- printT(t)

    if  GameScene.layers["activity"].module.pageTable[161] and GameScene.layers["activity"].module.pageTable[161].module.show then
        print("showsecret==")
        GameScene.layers["activity"].module.pageTable[161].module:reloadData(t)
    end

end

function UIActivitySecretShop(t)
    print("神秘商店3651，接受客户端数据")
    -- printT(t)
    showRewardPopupWindow(t.reward, nil,function()
        UIRequest({type=3650,update = true})
        GameScene:addUpdate(1200)
        UIRequest({type = 1001})
    end)
end

function UIActivitySecretShopReset(t)
    print("神秘商店3652，接受客户端数据")

    if  GameScene.layers["activity"].module.pageTable[161] and GameScene.layers["activity"].module.pageTable[161].module.show then
        GameScene.layers["activity"].module.pageTable[161].module:reloadData(t)
    end
    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
end
