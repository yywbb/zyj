--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/1/12
-- Time: 16:25
-- To change this template use File | Settings | File Templates.
--

function UIUserChatQuery(t)
    print("聊天查询3000，接受客户端数据")
    printT(t)

    if GameScene.layers["chat"].show then
        GameScene.layers["chat"].module:addNewChat(t)
    end

end

function UIUserChat(t)
    print("聊天3001，接受客户端数据")
    --printT(t)

    if GameScene.layers["chat"].show then
        GameScene.layers["chat"].module:addNewChat(t)
    end

end

function UIUserGangChatQuery(t)
    print("公会聊天查询3010，接受客户端数据")
    printT(t)

    if GameScene.layers["chat"].show then
        GameScene.layers["chat"].module:addNewChatguild(t)
    end

    if GameScene.layers["guildfeast"].show then
        GameScene.layers["guildfeast"].module.guildchat.module_guild:addNewChat(t)
    end

    if GameScene.layers["gang_xianchi2"].show then
        GameScene.layers["gang_xianchi2"].module.guildchat.module_guild:addNewChat(t)
    end
end

function UIUserGangChat(t)
    print("公会聊天3011，接受客户端数据")
    printT(t)

    if GameScene.layers["chat"].show then
        GameScene.layers["chat"].module:addNewChatguild(t)
    end

    if GameScene.layers["guildfeast"].show then
        GameScene.layers["guildfeast"].module.guildchat.module_guild:addNewChat(t)
    end

    if GameScene.layers["gang_xianchi2"].show then
        GameScene.layers["gang_xianchi2"].module.guildchat.module_guild:addNewChat(t)
    end
end


function UIUserChatNumReset(t)
    print("聊天3012重置，接受客户端数据")
end

--
function UIBroadcastQuery(t)
    print("广播查询3015，接受客户端数据")
    --printT(t)

    if GameScene.layers["chat"].show then
        GameScene.layers["chat"].module:addNewChatbroadcast(t)
    end

end


function UIUserCrossChat(t)
    print("30001，接受客户端数据")
    --printT(t)

    GameScene:addUpdate(1200)
    
end

function UISendBarrageQuery(t)
    print("发送弹幕2290，接受客户端数据")
    printT(t)
    if t.chats and next(t.chats) then
        gameTimer:rigistTime("BarrageSendTime", 5)
        if t.chats["1"].rid == -1 then

        else
            if t.barrageType ~= 9 then
                runGamePrompt({msg = "已发出邀请"})
            end
            if GameScene.barrageScene then
                GameScene.barrageScene:setBarrage(t)
            end
        end
    end
end

function UIBarrageQuery(t)
    print("弹幕2291，接受客户端数据")
    printT(t)

    if GameScene.barrageScene then
        GameScene.barrageScene:setBarrage(t)
    end
end

