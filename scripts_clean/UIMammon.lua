--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/27
-- Time: 下午2:56
-- To change this template use File | Settings | File Templates.
--

function UIActivityMammonQuery(t)
    print("爱神2015 接受客户端数据")
    --printT(t)



    if not gameTimer.times["mammon"] and t.status["2"] > 0 then
        gameTimer:rigistTime("mammon",t.status["2"])
    end

    if GameScene.layers["activity"].module.pageTable[2] then
        GameScene.layers["activity"].module.pageTable[2].module:reloaddata(t)
    end

end

function UIActivityMammon(t)
    print("爱神2016 接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[2] then
        GameScene.layers["activity"].module.pageTable[2].module:palyrandom(t)
    end
    UIRequest({type =1001})
end

function UIActivityMammonBroadcast(t)
    print("爱神2017接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[2] then
        GameScene.layers["activity"].module.pageTable[2].module:reloadbroadcast(t)
    end

end




function UIActivityMammonQuery2(t)
    print("3790 接受客户端数据")
    printT(t)



    if not gameTimer.times["mammon2"] and t.status["2"] > 0 then
        gameTimer:rigistTime("mammon2",t.status["2"])
    end

    if GameScene.layers["activity"].module.pageTable[61] then
        GameScene.layers["activity"].module.pageTable[61].module:reloaddata(t)
    end

end

function UIActivityMammon2(t)
    print("爱神3791 接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[61] then
        GameScene.layers["activity"].module.pageTable[61].module:palyrandom(t)
    end
    UIRequest({type =1001})
end

function UIActivityMammonBroadcast2(t)
    print("爱神3792接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[61] then
        GameScene.layers["activity"].module.pageTable[61].module:reloadbroadcast(t)
    end

end