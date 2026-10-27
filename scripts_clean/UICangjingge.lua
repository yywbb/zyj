--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/2/15
-- Time: 14:52
-- To change this template use File | Settings | File Templates.
--

function UIManorQuery(t)
    print("4820，接受客户端数据")
    printT(t)

    --
    if t.manorReqRid and t.manorReqRid == 0 and t.cangjingge then
        GameScene.cangjingge = t.cangjingge
        if t.cangjingge.time and t.cangjingge.time > 0 then
            gameTimer:rigistTime("manorqualitytime",t.cangjingge.time+1)
        end
        if t.cangjingge.materialtime and t.cangjingge.materialtime > 0 then
            gameTimer:rigistTime("manormaterialtime",t.cangjingge.materialtime+1)
        end
        if gameWindows.windows["cangjingge_task"].show then
            gameWindows.windows["cangjingge_task"].module:setquality({buildtype = 2, buildlevel = t.cangjingge.building[tostring(2)].level, buildquality = t.cangjingge.building[tostring(2)].quality, building = t.cangjingge.building})
        end
    end

    if GameScene.layers["manor"].show then
        GameScene.layers["manor"].module:reloaddata(t)
    end


end

function UIManorFriendListQuery(t)
    print("4821，接受客户端数据")
    printT(t)

    if t.show and t.show == 1 and GameScene.layers["manor"].show then
        GameScene.layers["manor"].module:showfriend(t)
    else
        GameScene.layers["manor"].module.manorfriends = t.manorfriends
    end
end


function UIManorGetWood(t)
    print("4823 接收客户端返回数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1001})
    end

    UIRequest({type = 4820})
end

function UIManorLevelUp(t)
    print("4822 接收客户端返回数据")
    printT(t)

    if gameWindows.windows["cangjingge_buildup"].show then
        gameWindows.windows["cangjingge_buildup"].module:reload(t)
    end

    GameScene:addUpdate(1200)
    UIRequest({type = 4820})
end

function UIManorNoticeQuery(t)
    print("4824 接收客户端返回数据")
    printT(t)

    if gameWindows.windows["cangjingge_task"].show then
        gameWindows.windows["cangjingge_task"].module:reload(t)
    end

    UIRequest({type = 1001})
end

function UIManorNoticeGetTask(t)
    print("4826 接收客户端返回数据")
    printT(t)

    UIRequest({type = 4824})
end

function UIManorNoticeDoneTask(t)
    print("4827 接收客户端返回数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
    end

    UIRequest({type = 1001})
    UIRequest({type = 4824})
    UIRequest({type = 4820})
end

function UIManorChange(t)
    print("4825 接收客户端返回数据")
    printT(t)
    if t.data then
        GameScene:reloadhint(t.data)
    end
    if GameScene.layers["manor"].show then
        GameScene.layers["manor"].module:manorchange()
    end

end

function UIManorYaoBattle(t)
    print("4828 接受客户端数据")
    printT(t)
    --
    if t.isauto and t.isauto == 1 then
        showRewardPopupWindow(t.reward,nil)
    else    
        RunbattleCallBack("copystar", t,nil)
    end
    UIRequest({type = 4821})
    UIRequest({type = 4820,rid = t.rid or 0})
    UIRequest({type = 1001})
end

function UIManorShop(t)
    print("4829，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[67] and GameScene.layers["activity"].module.pageTable[67].module.show then
        GameScene.layers["activity"].module.pageTable[67].module:reloaddata(t)
    end

end

function UIManorShopExchange(t)
    print("4830 接收客户端返回数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
    end

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
    UIRequest({type = 4829})
end

function UIManorConcent(t)
    print("4831，接受客户端数据")
    printT(t)

    UIRequest({type = 4820})

end