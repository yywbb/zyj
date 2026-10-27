--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/18
-- Time: 10:22
-- To change this template use File | Settings | File Templates.
--

function UILimitTimeExchangeQuery(t)
    print("3710,接受客户端数据")
    if  GameScene.layers["activity"].module.pageTable[50] and GameScene.layers["activity"].module.pageTable[50].module.show then
        GameScene.layers["activity"].module.pageTable[50].module:reloaddata(t)
    end
end
function UILimitTimeExchange(t)
    print("3711,接受客户端数据")

    if t.xprop and next(t.xprop) then
        updateDataLife(t.xprop)
    end

    if  GameScene.layers["activity"].module.pageTable[50] and GameScene.layers["activity"].module.pageTable[50].module.show then
        GameScene.layers["activity"].module.pageTable[50].module:play(t)
    end
    UIRequest({type = 1001})

end
function UILimitTimeExchangeRefresh(t)
    print("3712,接受客户端数据")
    if  GameScene.layers["activity"].module.pageTable[50] and GameScene.layers["activity"].module.pageTable[50].module.show then
        GameScene.layers["activity"].module.pageTable[50].module:reloaddata(t)
    end
    UIRequest({type = 1001})
end

--
function UICPLimitTimeExchangeQuery(t)
    print("5052,接受客户端数据")
    if  GameScene.layers["activity"].module.pageTable[95] and GameScene.layers["activity"].module.pageTable[95].module.show then
        GameScene.layers["activity"].module.pageTable[95].module:reloaddata(t)
    end
end
function UICPLimitTimeExchange(t)
    print("5053,接受客户端数据")

    if t.xprop and next(t.xprop) then
        updateDataLife(t.xprop)
    end

    if  GameScene.layers["activity"].module.pageTable[95] and GameScene.layers["activity"].module.pageTable[95].module.show then
        GameScene.layers["activity"].module.pageTable[95].module:play(t)
    end
    UIRequest({type = 1001})

end
function UICPLimitTimeExchangeRefresh(t)
    print("5054,接受客户端数据")
    if  GameScene.layers["activity"].module.pageTable[95] and GameScene.layers["activity"].module.pageTable[95].module.show then
        GameScene.layers["activity"].module.pageTable[95].module:reloaddata(t)
    end
    UIRequest({type = 1001})
end