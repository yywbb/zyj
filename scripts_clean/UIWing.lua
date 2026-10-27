--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/6
-- Time: 下午2:34
-- To change this template use File | Settings | File Templates.
--


function UIWingQuary(t)
    print("主角翅膀3740，接受客户端数据")
    printT(t)

    -- if GameScene.layers["wingmain"].show then
    --     GameScene.layers["wingmain"].module:reloadData(t)
    -- end

    if GameScene.layers["lead"].show then
        GameScene.layers["lead"].module:pageDataCallback("wing","reloadData",t)
    end
end

function UIWingSatrUp(t)
    print("主角翅膀3741，接受客户端数据")
    printT(t)

    -- if GameScene.layers["wingmain"].show then
    --     GameScene.layers["wingmain"].module:effect_shengxing(t)
    -- end

    if GameScene.layers["lead"].show then
        GameScene.layers["lead"].module:pageDataCallback("wing","effect_shengxing",t)
    end

    if t.protagonist then
        GameScene.protagonist = t.protagonist
    end
    -- UIRequest({type = 1054, param = "update"})
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
end

function UIWingStageUp(t)
    print("主角翅膀3742，接受客户端数据")
    printT(t)
    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
    end

    -- if GameScene.layers["wingmain"].show then
    --     if t.first then
    --         GameScene.layers["wingmain"].module:reloadData(t)
    --     else
    --         GameScene.layers["wingmain"].module:stageEndSet(t)
    --     end
        
    -- end

    if GameScene.layers["lead"].show then
        if t.first then
            GameScene.layers["lead"].module:pageDataCallback("wing","reloadData",t)
        else
            GameScene.layers["lead"].module:pageDataCallback("wing","stageEndSet",t)
        end
    end

    if t.protagonist then
        GameScene.protagonist = t.protagonist
    end
    UIRequest({type = 1001})
    -- UIRequest({type = 1054, param = "update"})
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
end

--
function UIWingDyeing(t)
    print("主角翅膀3743，接受客户端数据")
    printT(t)

    if t.protagonist then
        GameScene.protagonist = t.protagonist
    end
    UIRequest({type = 1001})
    UIRequest({type = 3740})
    UIRequest({type = 3744})
    -- UIRequest({type = 1054, param = "update"})
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
end

function UIWingColorQuery(t)
    print("主角翅膀3744，接受客户端数据")
    printT(t)

    if gameWindows.windows["wingcolorset"].show then
        gameWindows.windows["wingcolorset"].module:reloadData(t)
    end

end

