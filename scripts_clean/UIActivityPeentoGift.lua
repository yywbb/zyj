--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/3
-- Time: 下午1:26
-- To change this template use File | Settings | File Templates.
--

function UIActivityPeentoGiftQuery(t)
    print("蟠桃献礼5401，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[103] 
        and GameScene.layers["activity"].module.pageTable[103].module.show then
        GameScene.layers["activity"].module.pageTable[103].module:reloadData(t)
    end
end

function UIActivityPeentoGiftReward(t)
    print("蟠桃献礼5402，接受客户端数据")
    printT(t)
    local changeCoin,changeGold = updateDataLife(t.reward)
    if changeCoin then
        GameScene:coin_effect(1,540,960,0.5)
    end
    if changeGold then
        GameScene:coin_effect(2,540,960,0.5)
    end
    UIRequest({type = 1001})
    if GameScene.layers["activity"].module.pageTable[103] 
        and GameScene.layers["activity"].module.pageTable[103].module.show then
        GameScene.layers["activity"].module.pageTable[103].module:getReward(t)
    end
end

function UIActivityPeentoGiftReset(t)
    print("蟠桃献礼5403，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[103] 
        and GameScene.layers["activity"].module.pageTable[103].module.show then
        GameScene.layers["activity"].module.pageTable[103].module:reSet(t)
    end
end
    










