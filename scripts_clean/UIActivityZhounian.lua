--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/3
-- Time: 下午1:26
-- To change this template use File | Settings | File Templates.
--

function UIActivityZhounianRandom(t)
    print("周年活动 5309 接受客户端数据")
    printT(t)

    if GameScene.layers["zhounian"].show then
        GameScene.layers["zhounian"].module:reloadRandomCid(t.data)
    end
    UIRequest({type = 1001})
end

function UIActivityZhounianQuery(t)
    print("周年活动 5310 接受客户端数据")
    printT(t)
    if GameScene.layers["zhounian"].show then
        GameScene.layers["zhounian"].module:reload(t)
    end
end

function UIActivityZhounianPray(t)
    print("周年活动 5311 接受客户端数据")
    printT(t)
    if GameScene.layers["zhounian"].show then
        GameScene.layers["zhounian"].module:reload(t)
    end
end

function UIActivityZhounianTask(t)
    print("周年活动 5312 接受客户端数据")
    printT(t)
    if GameScene.layers["zhounian"].show then
        GameScene.layers["zhounian"].module:reload(t)
    end
end

function UIActivityZhounianTaskCancel(t)
    print("周年活动 5318 接受客户端数据")
    printT(t)
    if GameScene.layers["zhounian"].show then
        GameScene.layers["zhounian"].module:reload(t)
    end
end

function UIActivityZhounianTaskGet(t)
    print("周年活动 5313 接受客户端数据")
    printT(t)
    if GameScene.layers["zhounian"].show then
        GameScene.layers["zhounian"].module:reload(t)
    end
end

function UIActivityZhounianTaskFresh(t)
    print("周年活动 5314 接受客户端数据")
    printT(t)
    if GameScene.layers["zhounian"].show then
        GameScene.layers["zhounian"].module:reload(t)
    end
    UIRequest({type = 1001})
end

--
function UIActivityChaozhiQuery(t)
    print("超值活动 5315 接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[100] 
        and GameScene.layers["activity"].module.pageTable[100].module.show then
        GameScene.layers["activity"].module.pageTable[100].module:reloaddata(t)
    end
end

function UIActivityChaozhiBuy(t)
    print("超值活动 5316 接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[100] 
        and GameScene.layers["activity"].module.pageTable[100].module.show then
        GameScene.layers["activity"].module.pageTable[100].module:reloaddata(t)
    end
end

function UIActivityChaozhiGet(t)
    print("超值活动 5317 接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[100] 
        and GameScene.layers["activity"].module.pageTable[100].module.show then
        GameScene.layers["activity"].module.pageTable[100].module:reloaddata(t)
    end
end