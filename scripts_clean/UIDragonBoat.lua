--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/18
-- Time: 10:22
-- To change this template use File | Settings | File Templates.
--

function UIDumplingSearch(t)
    print("3306，接受客户端数据")
    if  GameScene.layers["activity"].module.pageTable[39] and GameScene.layers["activity"].module.pageTable[39].module.show then
        GameScene.layers["activity"].module.pageTable[39].module:reloaddata(t)
    end
end
function UIDumplingUsed(t)
    print("3307，接受客户端数据")
    if  GameScene.layers["activity"].module.pageTable[39] and GameScene.layers["activity"].module.pageTable[39].module.show then
        GameScene.layers["activity"].module.pageTable[39].module:play(t)
    end

    UIRequest({type = 1001})
end

function UIDragonBoatSearch(t)
    print("3901，接受客户端数据")
    if  GameScene.layers["activity"].module.pageTable[40] and GameScene.layers["activity"].module.pageTable[40].module.show then
        GameScene.layers["activity"].module.pageTable[40].module:reloaddata(t)
    end
end

function UIDragonBoatUsed(t)
    print("3902，接受客户端数据")
    if  GameScene.layers["activity"].module.pageTable[40] and GameScene.layers["activity"].module.pageTable[40].module.show then
        GameScene.layers["activity"].module.pageTable[40].module:reloaddata(t)
    end
end