--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UIActivityBlackShopQuery(t)
    print("限时商店3630，接受客户端数据")

    -- printT(t)


    if  GameScene.layers["activity"].module.pageTable[18] then
        GameScene.layers["activity"].module.pageTable[18].module:reloaddata(t)
    end

end

function UIActivityBlackShop(t)
    print("限时商店3631，接受客户端数据")
    -- printT(t)
    showRewardPopupWindow(t.reward, nil,function()
        UIRequest({type=3630,update = true})
        UIRequest({type = 1001})
    end)
end

function UIActivityBlackShopReset(t)
    print("限时商店3632，接受客户端数据")

    if  GameScene.layers["activity"].module.pageTable[18] then
        GameScene.layers["activity"].module.pageTable[18].module:reloaddata(t)
    end
    UIRequest({type = 1001})
end
