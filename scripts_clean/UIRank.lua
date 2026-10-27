--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/21
-- Time: 15:14
-- To change this template use File | Settings | File Templates.
--

function UIRankQuery(t)
    print("请求排行榜 3500 接收客户端返回数据")
    printT(t)


    if t.activityRankId then
        if GameScene.layers["activity"].module.pageTable[t.activityRankId].module.show then
            GameScene.layers["activity"].module.pageTable[t.activityRankId].module:openRankWindow(t.players)
        end
    elseif GameScene.layers["ranklist"].show then
        GameScene.layers["ranklist"].module:ReloadData(t)
    end

    -- if t.method == 11 or t.method == 12 or t.method == 13 or t.method == 14 then
    --     gameWindows:openWindow("openServerRank",{method = t.method, players =t.players},nil)
    -- elseif GameScene.layers["ranklist"].show then
    --     GameScene.layers["ranklist"].module:ReloadData(t)
    -- end

end

function UIOldRankQuery(t)
    print("请求排行榜 3503 接收客户端返回数据")
    printT(t)
    if t.activityRankId then
        if GameScene.layers["activity"].module.pageTable[t.activityRankId].module.show then
            GameScene.layers["activity"].module.pageTable[t.activityRankId].module:openRankWindow(t.players)
        end
    end
end



function UIRankChange(t)
    print("排行榜 3501 接收客户端返回数据")

    GameScene.layers["ranklist"].module:Rankchange()
end

function UIRankMydataQuery(t)
    print("请求 35001 接收客户端返回数据")
    --printT(t)

    if GameScene.layers["ranklist"].show then
       GameScene.layers["ranklist"].module:setMyRank(t.mydata)
    end

end