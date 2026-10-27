--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/18
-- Time: 10:22
-- To change this template use File | Settings | File Templates.
--

function UIProtagonistGameQuery(t)
    print("3720,接受客户端数据")
    -- if GameScene.layers["gamestar"].show then
    --     GameScene.layers["gamestar"].module:reloadData(t)
    -- end


    if GameScene.layers["lead"].show then
        -- GameScene.layers["lead"].module:setgamestar(t)
        GameScene.layers["lead"].module:pageDataCallback("mogong","setgamestar",t)
        GameScene.layers["lead"].module:pageDataCallback("gamestar","reloadData",t)
    end
end

function UIProtagonistGameEatBeans(t)
    print("3721,接受客户端数据")

    UIRequest({type = 1001})
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    UIRequest({type = 3720})

end

function UIProtagonistGamePopcorn(t)
    print("3722,接受客户端数据")

    UIRequest({type = 1001})
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    -- if GameScene.layers["gamestar"].show then
    --     GameScene.layers["gamestar"].module:boom(t)
    -- end

    if GameScene.layers["lead"].show then
        GameScene.layers["lead"].module:pageDataCallback("gamestar","boom",t)
    end
end