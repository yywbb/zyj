--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/20
-- Time: 下午12:16
-- To change this template use File | Settings | File Templates.
--

function UIMysticalCave(t)
    print("仙洞2050，接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:reloaddata(t.status)
    end

end

function UIMysticalCaveForecast(t)
    print("仙洞2051，接受客户端数据")
    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:Run(t.status)
    end
    --printT(t)
end

function UIMysticalCaveReversion(t)
    print("仙洞2052，接受客户端数据")
    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:Run(t.status)
    end
    --printT(t)
    UIRequest({type = 1001})
end

function UIMysticalCaveConfirm(t)
    print("仙洞2053，接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:reloaddata(t.status)
    end
    showRewardPopupWindow(t.reward,nil,nil)
    UIRequest({type = 1001})
end

function UIMysticalReward(t)
    print("仙洞2054，接受客户端数据")

    --printT(t)
    --GameScene.layers["activity"].module.pageTable[10].module:setReward(t.status)

    showRewardPopupWindow(t.reward,nil,function() UIRequest({type = 2050}) end)
    UIRequest({type =1001})
end


function UIWatchStarQuery(t)
    print("仙洞2062，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:reloaddata(t.data)
    end

    if GameScene.layers["watchstar"].show then
        GameScene.layers["watchstar"].module:reloaddata(t.data)
    end

    if gameWindows.windows["starGetReward"].show then
        gameWindows.windows["starGetReward"].module:reload(t.data)
    end
end

function UIWatchStarWatch(t)
    print("仙洞2063，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:playdata(t.data)
    end

    if GameScene.layers["watchstar"].show then
        GameScene.layers["watchstar"].module:playdata(t.data)
    end

end

function UIWatchStarChange(t)
    print("仙洞2064，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:playdata(t.data)
    end

    if GameScene.layers["watchstar"].show then
        GameScene.layers["watchstar"].module:playdata(t.data,t.gold)
    end

    UIRequest({type =1001})
end

function UIWatchStarGet(t)
    print("仙洞2065，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:reloaddata(t.data)
    end

    if GameScene.layers["watchstar"].show then
        GameScene.layers["watchstar"].module:reloaddata(t.data)
    end
end

function UIWatchStarReward(t)
    print("仙洞2066，接受客户端数据")
    --printT(t)

    showRewardPopupWindow(t.reward,nil,nil)
    UIRequest({type =2062})
    UIRequest({type =1001})

end

function UIWatchStarWatchEx(t)
    print("仙洞2067，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:watchex(t.data)
    end

    if GameScene.layers["watchstar"].show then
        GameScene.layers["watchstar"].module:watchex(t.data)
    end
    UIRequest({type =1001})
end


function UIWatchStarUpLevel(t)
    print("2068，接受客户端数据")
    printT(t)

    runGamePrompt({msg = "奖励升级成功"})

    if GameScene.layers["activity"].module.pageTable[10] then
        GameScene.layers["activity"].module.pageTable[10].module:reloaddata(t.data)
    end

    if GameScene.layers["watchstar"].show then
        GameScene.layers["watchstar"].module:reloaddata(t.data)
    end

    if gameWindows.windows["starGetReward"].show then
        gameWindows.windows["starGetReward"].module:reload(t.data)
    end

    UIRequest({type =1001})
end



