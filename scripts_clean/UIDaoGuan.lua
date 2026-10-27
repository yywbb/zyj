-- 道馆UI消息

-- 道馆主界面
function UIDaoGuanMain(t)
    print("5301，接受客户端数据")
    printT(t)

    if GameScene.layers["daoGuanMain"].show then
        GameScene.layers["daoGuanMain"].module:reloaddata(t)
    end

    if GameScene.layers["limitedset"].show then
        GameScene.layers["limitedset"].module:setDaoguanHint(t)
    end
end

-- 道馆奖励
function UIDaoGuanGetReward(t)
    print("领取奖励5302，接受客户端数据")
    --printT(t)
    if GameScene.layers["daoGuanMain"].show then
        GameScene.layers["daoGuanMain"].module:reloaddata(t)
    end

    if gameWindows.windows["daoGuanRewardview"].show then
        gameWindows.windows["daoGuanRewardview"].module:reload(t.maindata)
    end
    
    showRewardPopupWindow(t.reward, nil)
    UIRequest({type = 1001})
end

-- 进入道馆后的刷新
function UIDaoGuanGoTo(t)
    print("进入道馆5303，接受客户端数据")
    printT(t)
    if GameScene.layers["daoGuanList"].module then
        GameScene.layers["daoGuanList"].module:reloaddata(t)
    end
end

-- 道馆挑战
function UIDaoGuanDare(t)
    print("挑战5304，接受客户端数据")
    printT(t)
    
    RunbattleCallBack("overpass", t, function()
        if GameScene.layers["daoGuanMain"].show then
            UIRequest({type = 5301})
        elseif GameScene.layers["daoGuanList"].show then
            UIRequest({type = 5303, id = t.id})
        end

        local sequence3 = CCSequence:createWithTwoActions(CCDelayTime:create(0.2), CCCallFunc:create(function() 
                if t.result == 1 then
                    if t.tip=="metal" then
                        runGamePrompt({msg=gameConfig.strings:daoguanhuizhangget(t.id)})
                    elseif t.tip=="leader" then
                        runGamePrompt({msg=gameConfig.strings:daoguanleaderget(t.id)})
                    elseif t.tip=="member" then
                        runGamePrompt({msg=gameConfig.strings:daoguanmemberget(t.id)})
                    end
                else
                    runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 33)})
                end                 
            end))
        GameScene.rootLayer:runAction(sequence3)  
    end)

    UIRequest({type = 1001})
end

-- 道馆战报
function UIDaoGuanFightNote(t)
    print("战报查看 5305，接受客户端数据")
    
    gameWindows:openWindow("daoGuanFightNote", t)
end

-- 道馆布阵
function UIDaoGuanArrangeQuary(t)
	print("打开布阵 5306，接受客户端数据")

    if t.needtimes then
        DaoGuanBuyTimes(gameConfig.strings:string_common("daoguanshouwei", 30))
        return
    end

    gameWindows:openWindow("daoGuanAttack", t)        

end