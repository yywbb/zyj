--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UIRobShop(t)
    print("夺宝商店3660，接受客户端数据")

    -- printT(t)

    if  GameScene.layers["activity"].module.pageTable[21] then
        GameScene.layers["activity"].module.pageTable[21].module:reloaddata(t)
    end

end


function UIRobShopBuy(t)
    print("限时商店3661，接受客户端数据")
    -- printT(t)
    showRewardPopupWindow(t.reward, nil,function()
        UIRequest({type=3660,update = true})
        UIRequest({type = 1001})
    end)

end
