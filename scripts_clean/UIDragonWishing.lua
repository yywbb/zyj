--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/12/5
-- Time: 11:39
-- To change this template use File | Settings | File Templates.
--[[
[4901] = UIDragonWishingQuery,
[4902] = UIDragonWishingGet,
[4903] = UIDragonWishingReward,
[4904] = UIDragonWishingEvent,
]]


function UIDragonWishingQuery(t)
    print("4901，接受客户端数据")
    printT(t)

    if t.dragonwishing.time and t.dragonwishing.time > 0 then
        gameTimer:rigistTime("shenlongxuyuandice",t.dragonwishing.time+1)
    end

    if GameScene.layers["shenlongxuyuan"].show then
        GameScene.layers["shenlongxuyuan"].module:reloaddata(t)
    end
end


function UIDragonWishingGet(t)
    print("4902，接受客户端数据")
    printT(t)

    updateDataLife(t.reward)
    updateDataLife(t.battlereward)
    UIRequest({type = 1001})


    if GameScene.layers["shenlongxuyuan"].show then
        GameScene.layers["shenlongxuyuan"].module:setDice(t)
    end
end

function UIDragonWishingReward(t)
    print("4903，接受客户端数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1001})
    end
    UIRequest({type = 4901})
end

function UIDragonWishingEvent(t)
    print("4904，接受客户端数据")
    printT(t)

    local cb = function()
        --UIRequest({type = 4901})
        if GameScene.layers["shenlongxuyuan"].show then
            GameScene.layers["shenlongxuyuan"].module:specialEvent()
        end
    end

    if t.battlereport then
        RunbattleCallBack("penglai", {reward = t.battlereward or {}, battlereport = t.battlereport,result = t.result or 0}, cb)
    elseif t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    elseif t.adddice and t.adddice ~= 0 then
        cb()
    else
        cb()
    end

    UIRequest({type = 1001})
end

function UIDragonWishingEventClose(t)
    print("4905，接受客户端数据")
    printT(t)
    if GameScene.layers["shenlongxuyuan"].show then
        GameScene.layers["shenlongxuyuan"].module:specialEvent()
    end
    --UIRequest({type = 4901})
end

function UIDragonWishingShop(t)
    print("4906，接受客户端数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
    end
    UIRequest({type = 1001})
    if gameWindows.windows["shenlongxuyuan_shop"].show then
        gameWindows.windows["shenlongxuyuan_shop"].module:reload(t)
    end

end

function UIDragonWishingQueryMap(t)
    print("4907，接受客户端数据")
    printT(t)
    
    if t.map then
        if GameScene.layers["shenlongxuyuan"].show then
            GameScene:shiftLayer("daily","down")
        end
        GameScene:shiftLayer("shenlongxuyuan","up", t.map)
    end
end