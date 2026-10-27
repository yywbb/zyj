--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/6
-- Time: 下午2:34
-- To change this template use File | Settings | File Templates.
--

local function reloadstatus(t)
    if t.cupstatus.tomorrow == 1 then
        if not gameTimer.times["cuptime"]  then
            local nowtime = os.date("*t", gamedata:time())
            local day = nowtime.hour<9 and 0 or 24
            gameTimer:rigistTime("cuptime",(day +9-nowtime.hour)*3600 - nowtime.min* 60 - nowtime.sec)
        end
    end

    GameScene.layers["cup"].module.statusdata = t.cupstatus

    if GameScene.layers["cup"].show then
        GameScene.layers["cup"].module:changeButton()
        GameScene.layers["cup"].module:reloadStatus(t.cupstatus,t.rewardNum)
    end
end

local function reloadTops(t)
    GameScene.layers["cup"].module.topsdata = t.cuptopbattles
    GameScene.layers["cup"].module.betnum = 3-t.betnum
    if GameScene.layers["cup"].show then
        GameScene.layers["cup"].module:reloadTops(t)
    end
end


function UICupStatus(t)
    print("杯赛2100，接受客户端数据")
    printT(t)

    reloadstatus(t)
end

function UICupJoinTomorrow(t)
    print("杯赛2101，接受客户端数据")
    printT(t)

    reloadstatus(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward, nil,nil)
        UIRequest({type = 1001})
    end

end

function UICupTop(t)
    print("杯赛2102，接受客户端数据")
    --printT(t)

    reloadTops(t)
end

function UICupBattlePlay(t)
    print("杯赛2103，接受客户端数据")
    --printT(t)

    RunbattleCallBack("cup", t)
end

function UICupTopSee(t)
    print("杯赛21021，接受客户端数据")
    --printT(t)

    reloadTops(t)

    if t.onebattle then
        if gameWindows.windows["cup"].show then
            gameWindows.windows["cup"].module:reloadBet(t.onebattle)
        end
    end

end

function UICupBattleReward(t)
    print("杯赛2104，接受客户端数据")
    --printT(t)

    reloadstatus(t)
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end

function UICupBattleRewardall(t)
    print("杯赛2106，接受客户端数据")
    --printT(t)

    reloadstatus(t)
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end

function UICupBattleBet(t)
    print("杯赛2105，接受客户端数据")
    --printT(t)
    reloadTops(t)

    if gameWindows.windows["cup"].show then
        gameWindows.windows["cup"].module:reloadBet(t.onebattle)
    end

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
end

--
function UICupRank(t)
    print("杯赛2107，接受客户端数据")
    printT(t)
    GameScene.layers["cup"].module.rankdata = t.rankdata
    if GameScene.layers["cup"].show then
        GameScene.layers["cup"].module:reloadRank(t.rankdata)
    end

end
