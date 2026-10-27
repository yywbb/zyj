--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UISafeMaskShopQuery(t)
    print("魔罩商店3733，接受客户端数据")

    printT(t)

    if  GameScene.layers["activity"].module.pageTable[53] then
        print("showsecret==")
        GameScene.layers["activity"].module.pageTable[53].module:reloaddata(t.data,t.gold)
    end

end

function UISafeMaskShopReward(t)
    print("魔罩商店3734，接受客户端数据")
    -- printT(t)
    showRewardPopupWindow(t.reward, nil,function()
        UIRequest({type = 3733})
        UIRequest({type = 1001})
    end)
end
