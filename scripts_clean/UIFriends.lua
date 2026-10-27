--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-15
-- Time: 上午9:55
-- To change this template use File | Settings | File Templates.
--

function UIFriendQuery(t)
    print("好友查询2300，接受客户端数据")
    --printT(t)

    if GameScene.layers["friends"].show then
        GameScene.layers["friends"].module:reloadFriendList(t)
    end

end

function UIFriendRecommend(t)
    print("好友推荐2301，接受客户端数据")
    -- printT(t)
    if GameScene.layers["friends"].show then
        GameScene.layers["friends"].module:reloadRecomendList(t)
    end

end

function UIFriendReq(t)
    print("好友申请2302，接受客户端数据")
    --printT(t)

    -- if t.Result == 1 then
    --     runGamePrompt({msg = "申请成功"})
    -- else
    --     runGamePrompt({msg = "申请失败"})
    -- end
    print("t.Result----------",t.Result)
    if t.Result == 0 then
        runGamePrompt({msg = "申请成功"})
    elseif t.Result == 1001 then
        runGamePrompt({msg = "自己好友已满"})
    elseif t.Result == 1002 then
        runGamePrompt({msg = "对方好友已满"})
    else
        runGamePrompt({msg = "申请失败"})
    end

    UIRequest({type = 2301})
end

function UIFriendReqQuery(t)
    print("好友申请查询2303，接受客户端数据")
    --printT(t)
    if GameScene.layers["friends"].show then
        GameScene.layers["friends"].module:reloadReqList(t)
    end

end

function UIFriendRep(t)
    print("好友确认2304，接受客户端数据")
    --printT(t)

    UIRequest({type = 2300,param = 1})
    UIRequest({type = 2303})

end

function UIFriendChatQuery(t)
    print("好友聊天查询2305，接受客户端数据")
    --printT(t)

    if t.req.new ==0 then
        if gameWindows.windows["friend"].show then
            gameWindows.windows["friend"].module:reloadChatView({data = t})
        else
            gameWindows:openWindow("friend",{type = "chat", data = t},nil)
        end
    else
        if gameWindows.windows["friend"].show then
            gameWindows.windows["friend"].module:addNewChat(t)
        end
    end

end

function UIFriendChat(t)
    print("好友聊天2306，接受客户端数据")
    --printT(t)
    if gameWindows.windows["friend"].show then
        gameWindows.windows["friend"].module:addNewChat(t)
    end
end

function UIFriendSearch(t)
    print("好友查找2307，接受客户端数据")
    --printT(t)
    if gameWindows.windows["friend"].show then
        gameWindows.windows["friend"].module:reloadResult(t)
    end
end

function UIFriendSendGift(t)
    print("好友送礼2308，接受客户端数据")
    --printT(t)

    UIRequest({type = 2300})
end

function UIFriendRecvGift(t)
    print("好友收礼2309，接受客户端数据")
    -- printT(t)

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,function()
            UIRequest({type = 1001})
            if t.receiveids and next(t.receiveids) then
                UIRequest({type = 2300})
            else
                UIRequest({type = 2300,param = "update"})
            end

        end)
    else
        UIRequest({type = 1001})
        if t.receiveids and next(t.receiveids) then
            UIRequest({type = 2300})
        else
            UIRequest({type = 2300,param = "update"})
        end
    end

end

function UIFriendDelete(t)
    print("好友删除2310，接受客户端数据")
    --printT(t)
    UIRequest({type = 2300})
    UIRequest({type = 1032})
end

function UIFriendAllReq(t)
    print("好友确认2311，接受客户端数据")
    --printT(t)

    UIRequest({type = 2300,param = 1})
    UIRequest({type = 2303})

end

function UIFriendAllShield(t)
    print("屏蔽列表申请查询3002，接受客户端数据")
    -- printT(t)
    if GameScene.layers["friends"].show then
        GameScene.layers["friends"].module:reloadShieldList(t)
    end

end

function UIFriendAddShield(t)
    print("屏蔽列表申请添加3003，接受客户端数据")
    if t.result == 0 then
        runGamePrompt({msg=gameConfig.strings:string_common("friends",28)})
    else
        runGamePrompt({msg=gameConfig.strings:string_common("friends",29)})
    end
end

function UIFriendDeleteShield(t)
    print("屏蔽列表申请删除3004，接受客户端数据")
    if t.result == 0 then
        runGamePrompt({msg=gameConfig.strings:string_common("friends",30)})
    else
        runGamePrompt({msg=gameConfig.strings:string_common("friends",31)})
    end

    UIRequest({type = 3002})
end

function UIFriendChatList(t)
    print("聊天列表2312，接受客户端数据")
    if gameWindows.windows["friend"].show then
        gameWindows.windows["friend"].module:reloadChat(t.players,false)
    end
end


function UIFriendHasChat(t)
    print("是否有飞鸽2313，接受客户端数据")
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadchat(t)
    end
    if t.result == 1 then
        UIRequest({type = 2300,param = 1})
    end
end

function UIFriendAllAdd(t)
    print("一键添加好友6038，接受客户端数据")

    printT(t)
    if t.stutus == 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("friends",22)})
        UIRequest({type = 2301, fresh = 1})
    elseif t.stutus == 1 then
        runGamePrompt({msg = gameConfig.strings:string_common("friends",23)})
    elseif t.stutus == 2 then
        runGamePrompt({msg = gameConfig.strings:string_common("friends",24)})
        UIRequest({type = 2301, fresh = 1})
    end
end
