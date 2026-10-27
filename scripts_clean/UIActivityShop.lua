--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UIActivityShopQuery(t)
    print("限时商店3615，接受客户端数据")

    -- printT(t)

    gameTimer:rigistTime("activityshop",t.data.time)

    if  GameScene.layers["activity"].module.pageTable[3] then
        GameScene.layers["activity"].module.pageTable[3].module:reloaddata(t.data)
    end

end

function UIActivityShop(t)
    print("限时商店3616，接受客户端数据")

    showRewardPopupWindow(t.reward, nil,function()
        UIRequest({type=3615,update = true})
        UIRequest({type = 1001})
    end)
end

function UIActivityShopReset(t)
    print("限时商店3617，接受客户端数据")
    gameTimer:rigistTime("activityshop",t.data.time)

    if  GameScene.layers["activity"].module.pageTable[3] then
        GameScene.layers["activity"].module.pageTable[3].module:reloaddata(t.data)
    end
    UIRequest({type = 1001})
end


--cp
function UICPActivityShopQuery(t)
    print("5043，接受客户端数据")
    printT(t)

    gameTimer:rigistTime("cp_activityshop",t.data.time)

    if  GameScene.layers["activity"].module.pageTable[93] then
        GameScene.layers["activity"].module.pageTable[93].module:reloaddata(t)
    end

end

function UICPActivityShop(t)
    print("5044，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward, nil,function()
        UIRequest({type = 5043,update = true})
        UIRequest({type = 1001})
    end)
end

function UICPActivityShopReset(t)
    print("5045，接受客户端数据")
    printT(t)

    gameTimer:rigistTime("activityshop",t.data.time)

    if  GameScene.layers["activity"].module.pageTable[93] then
        GameScene.layers["activity"].module.pageTable[93].module:reloaddata(t)
    end
    UIRequest({type = 1001})
end