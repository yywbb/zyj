--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/3
-- Time: 下午3:30
-- To change this template use File | Settings | File Templates.
--

function UISingleBossQuary(t)
    print("个人boss3700，接受客户端数据")
    printT(t)
    if not GameScene.layers["singleboss"].show then
        GameScene:shiftLayer("singleboss","up",t.boss)
        GameScene.layers["singleboss"].module:reloadlv(t)
    else
        GameScene.layers["singleboss"].module:reloadData(t.boss)
        GameScene.layers["singleboss"].module:reloadlv(t)
    end
        
    if gameWindows.windows["kingfoot"].show then
        gameWindows.windows["kingfoot"].module:reloaddata(t)
    end

    if gameWindows.windows["kingmanOnekeyChallenge"].show then
        gameWindows.windows["kingmanOnekeyChallenge"].module:reloaddata(t)
    end
end

function UISingleBossBattle(t)
    print("个人boss3701，接受客户端数据")
    printT(t)
    local datatmp = ui.CheckHuodongByParam(4)

    -- local datatmp = ui.CheckHuodongByParam(1)
    if datatmp and t.reward and next(t.reward) then
        -- t.reward.isrewarddouble = datatmp
        if t.result == 0 then
            GameScene.isrewarddouble = datatmp
        end
    end

    local callBackFunc = function()
        if GameScene.layers["singleboss"].show then
            GameScene.layers["singleboss"].module:reloadData(t.boss)
        end    
        if gameWindows.windows["kingfoot"].show then
            gameWindows.windows["kingfoot"].module:reloaddata(t)
        end
        UIRequest({type = 3700})

        if t.reward and next(t.reward) then
            updateDataLife(t.reward)
            if t.result == 1 and t.isNextLevelOpen == 1 then
                gameWindows:openWindow("getStaff",{data = t.reward,type = "恭喜获得",tip = "友情提示：首次掉落不叠加任何双倍产出"},nil)
            else
                gameWindows:openWindow("getStaff",t.reward,nil)
            end
        end
        
    end
    RunbattleCallBack("singleboss", t,callBackFunc)
end

function UIKingmanOnekeyChallengeBack(t)
    print("3705，接受客户端数据")
    printT(t)
    local cb = function()
        if GameScene.layers["singleboss"].show then
               print("奖励关闭")
               UIRequest({type = 3700})
        end
    end
    showRewardPopupWindow(t.reward,nil,cb)
end

function UIServerTimes(t)
    print("3706，接受客户端数据")
    printT(t)
     if gameWindows.windows["worldbossrank"].show then
        gameWindows.windows["worldbossrank"].module:rewardReload(t.times)
    end

end