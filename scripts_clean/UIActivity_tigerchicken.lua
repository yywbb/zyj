--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/6/17
-- Time: 下午1:40
-- To change this template use File | Settings | File Templates.
--

function UITigerchickenQuery(t)
    print("老虎机1406，接受客户端数据")

    printT(t)

    if  GameScene.layers["activity"].module.pageTable[45] then
        GameScene.layers["activity"].module.pageTable[45].module:reloaddata(t.data)
    end

    -- if  GameScene.layers["activity"].module.pageTable[45] then
    --     GameScene.layers["activity"].module.pageTable[45].module:relaodpoint(t.data)
    -- end

    if gameWindows.windows["tigerchickenshop"].show then
        gameWindows.windows["tigerchickenshop"].module:relaodpoint(t.data)
    end
end

function UITigerchickenDo(t)
    print("老虎机1407，接受客户端数据")

    printT(t)
    if  GameScene.layers["activity"].module.pageTable[45] then
        GameScene.layers["activity"].module.pageTable[45].module:playReward(t)
    end

    updateDataLife(t.reward)

    UIRequest({type = 1001})
end


function UITigerchickenshop(t)
    print("老虎机1408，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[45] then
    --     GameScene.layers["activity"].module.pageTable[45].module:reloaddata(t)
    -- end


    if gameWindows.windows["tigerchickenshop"].show then
        gameWindows.windows["tigerchickenshop"].module:reloaddata(t)
    else
        gameWindows:openWindow("tigerchickenshop",t)
    end

end

function UITigerchickenshopExchange(t)
    print("老虎机1409，接受客户端数据")

    printT(t)

    showRewardPopupWindow(t.reward,nil)

    UIRequest({type = 1001})
    UIRequest({type = 1406})
    UIRequest({type = 1408})
end

--
function UIGambling(t)
    print("3860，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[74] then
        GameScene.layers["activity"].module.pageTable[74].module:reloaddata(t)
    end

end

function UIGamblingReward(t)
    print("3861，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[74] then
        GameScene.layers["activity"].module.pageTable[74].module:playReward(t)
    end

    UIRequest({type = 1001})

end


function UIGamblingShop(t)
    print("3862，接受客户端数据")

    printT(t)

    if  GameScene.layers["activity"].module.pageTable[75] then
        GameScene.layers["activity"].module.pageTable[75].module:reloaddata(t)
    end

end

function UIGamblingShopReward(t)
    print("3863，接受客户端数据")

    printT(t)

    showRewardPopupWindow(t.reward,nil)

    UIRequest({type = 1001})
    GameScene:addUpdate(1200)
    UIRequest({type = 3862})

end


--
--
function UICPTigerchickenQuery(t)
    print("5020，接受客户端数据")

    printT(t)

    if  GameScene.layers["activity"].module.pageTable[80] then
        GameScene.layers["activity"].module.pageTable[80].module:reloaddata(t)
    end

    -- if  GameScene.layers["activity"].module.pageTable[80] then
    --     GameScene.layers["activity"].module.pageTable[80].module:relaodpoint(t)
    -- end

    if gameWindows.windows["cp_tigerchickenshop"].show then
        gameWindows.windows["cp_tigerchickenshop"].module:relaodpoint(t.data)
    end

end

function UICPTigerchickenDo(t)
    print("5021，接受客户端数据")

    printT(t)
    if  GameScene.layers["activity"].module.pageTable[80] then
        GameScene.layers["activity"].module.pageTable[80].module:playReward(t)
    end

    updateDataLife(t.reward)

    UIRequest({type = 1001})
end


function UICPTigerchickenshop(t)
    print("5022，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[80] then
    --     GameScene.layers["activity"].module.pageTable[80].module:reloaddata(t)
    -- end

    if gameWindows.windows["cp_tigerchickenshop"].show then
        gameWindows.windows["cp_tigerchickenshop"].module:reloaddata(t)
    else
        gameWindows:openWindow("cp_tigerchickenshop",t)
    end

end

function UICPTigerchickenshopExchange(t)
    print("5023，接受客户端数据")

    printT(t)

    showRewardPopupWindow(t.reward,nil)

    UIRequest({type = 1001})
    UIRequest({type = 5020})
    UIRequest({type = 5022})
end
