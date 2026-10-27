--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/3
-- Time: 下午1:26
-- To change this template use File | Settings | File Templates.
--

function UIActivityTreeQuery(t)
    print("种树活动5323，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[102] 
        and GameScene.layers["activity"].module.pageTable[102].module.show then
        GameScene.layers["activity"].module.pageTable[102].module:animation(t,"require")
    end

end

function UIActivityTreeWater(t)
    print("种树活动5324，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[102] 
        and GameScene.layers["activity"].module.pageTable[102].module.show then
        GameScene.layers["activity"].module.pageTable[102].module:animation(t,"water")
    end

end

function UIActivityTreetask(t)
    print("种树活动5325，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[102] 
        and GameScene.layers["activity"].module.pageTable[102].module.show then
        GameScene.layers["activity"].module.pageTable[102].module:reloaddata(t)
    end
end

function UIActivityTreetaskGet(t)
    print("种树活动5326，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[102] 
        and GameScene.layers["activity"].module.pageTable[102].module.show then
        GameScene.layers["activity"].module.pageTable[102].module:reloaddata(t)
    end
end

function UIActivityTreetaskcancel(t)
    print("种树活动5327，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[102] 
        and GameScene.layers["activity"].module.pageTable[102].module.show then
        GameScene.layers["activity"].module.pageTable[102].module:reloaddata(t)
    end
end

function UIActivityWaterBuy(t)
    print("种树活动5328，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[102] 
        and GameScene.layers["activity"].module.pageTable[102].module.show then
        GameScene.layers["activity"].module.pageTable[102].module:reloaddata(t)
    end
end

function UIActivityTreetaskFresh(t)
    print("种树活动5329，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[102] 
        and GameScene.layers["activity"].module.pageTable[102].module.show then
        GameScene.layers["activity"].module.pageTable[102].module:reloaddata(t)
    end
    UIRequest({type=1001})
    UIRequest({type=5323,param="main"})
end

function UIActivityBoxreward(t)
    print("种树活动5330，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[102] 
        and GameScene.layers["activity"].module.pageTable[102].module.show then
        GameScene.layers["activity"].module.pageTable[102].module:reloaddata(t)
    end
end


function UIActivityZhongshuRank(t)
    print("种树排行榜5331，接受客户端数据")
    printT(t)
    
    if gameWindows.windows["zhongshuRank"].show then
        gameWindows.windows["zhongshuRank"].module:reload(2,t)
    end
end

