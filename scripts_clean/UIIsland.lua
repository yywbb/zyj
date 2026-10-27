--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/8/28
-- Time: 下午6:01
-- To change this template use File | Settings | File Templates.
--

function UIIsland(t)
    print("蓬莱仙岛2110，接受客户端数据")
    -- printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reload(t)
    end
end

function UIIslandGoto(t)
    print("蓬莱仙岛2111，接受客户端数据")
    -- printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reload(t)
    end
    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    elseif t.getPoint ~= 0 then
        runGamePrompt({msg = "获取"..t.getPoint.."积分"})
    end

    
    UIRequest({type = 1001})
end

function UIIslandNext(t)
    print("蓬莱仙岛2112，接受客户端数据")
    -- printT(t)
    print("result=",t.result)

    if t.battlereport then
        local cb = function()
            -- if t.result == 0 then
            --     print("result:0")
            --     gameWindows:openWindow("penglaiResult",{index= "fail",data = t},nil)
            -- elseif t.result == 1 then
            --     print("result:1")
            --     gameWindows:openWindow("penglaiResult",{index= "seccess",data = t},nil)
            -- else
                -- print("result:else")
                if GameScene.layers["penglai"].show then
                    GameScene.layers["penglai"].module:reload(t)
                end
            -- end
        end
        RunbattleCallBack("penglai", t, cb)
    elseif GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reload(t)
    end

    if t.getbuffer == 1 then
        print("i..am..in..getbuffer")
        if GameScene.layers["penglai"].show then
            GameScene.layers["penglai"].module:setbufferaction()
        end
    end
    
    UIRequest({type = 1001})
end



function UIIslandGetTodayReward(t)
    print("蓬莱仙岛2113，接受客户端数据")
    -- printT(t)
    if t.reward then
        -- local callback = function()
        --     print("callback===")
        --     -- GameScene:shiftLayer("daily","up")
        -- end
        print("getreward")
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1001})
    else
        gameWindows:openWindow("penglaiResult",{index= "complete",data = t},nil)
    end 
end

function UIIslandTask(t)
    print("蓬莱仙岛2114，接受客户端数据")
    -- printT(t)

    if gameWindows.windows["penglaiReward"].show then
        gameWindows.windows["penglaiReward"].module:relaodTask(t)
    end
end

function UIIslandTaskReward(t)
    print("蓬莱仙岛2115，接受客户端数据")
    -- printT(t)

    UIRequest({type = 2114,update = true})
    -- if gameWindows.windows["penglaiReward"].show then
    --     gameWindows.windows["penglaiReward"].module:resetpenglaitask(t)
    -- end
    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
end

function UIIslandRank(t)
    print("蓬莱仙岛2116，接受客户端数据")
    -- printT(t)
    if gameWindows.windows["penglaiReward"].show then
        gameWindows.windows["penglaiReward"].module:relaodRank(t)
    end
end

function UIIslandGlobal(t)
    print("蓬莱仙岛2117，接受客户端数据")
    -- printT(t)

    if gameWindows.windows["penglaiReward"].show then
        gameWindows.windows["penglaiReward"].module:relaodTotal(t)
    end
end

function UIIslandGlobalReward(t)
    print("蓬莱仙岛2118，接受客户端数据")
    -- printT(t)
    UIRequest({type = 2117})
    -- if gameWindows.windows["penglaiReward"].show then
    --     gameWindows.windows["penglaiReward"].module:resetpenglaitotal(t.id)
    -- end
    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
end

-------------
-------------penglai3

function UIPenglai3(t)
    print("蓬莱仙岛2120，接受客户端数据")
    printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reload(t)
    end
end

--
function UIPenglai3Dice(t)
    print("蓬莱仙岛2121，接受客户端数据")
    printT(t)

    updateDataLife(t.reward)
    GameScene:addUpdate(1200)
    UIRequest({type = 1001})


    local datatmp = ui.CheckHuodongByParam(5)
    -- local datatmp = ui.CheckHuodongByParam(1)
    if datatmp and t.reward and next(t.reward) then
        GameScene.isrewarddouble = datatmp
    end
    
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:setDice(t)
    end
end

--
function UIPenglai3Card(t)
    print("蓬莱仙岛2124，接受客户端数据")
    printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:setCard(t)
    end
end

function UIPenglai3CardOpen(t)
    print("蓬莱仙岛2125，接受客户端数据")
    printT(t)

    --showRewardPopupWindow(t.reward,nil)
    local changeCoin,changeGold = updateDataLife(t.reward)
    if changeCoin then
        GameScene:coin_effect(1,540,960,0.5)
    end
    if changeGold then
        GameScene:coin_effect(2,540,960,0.5)
    end

    UIRequest({type = 2124})
    UIRequest({type = 1001})
end

function UIPenglai3CardClose(t)
    print("蓬莱仙岛2126，接受客户端数据")
    printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reload(t)
    end
end

function UIPenglaiAutoReward2(t)
    print("蓬莱仙岛2128，接受客户端数据")
    printT(t)

    if t.goldcost == -1 then
        shortGold()
        return
    end


    UIRequest({type = 1001})

    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:autoComplete(t)
    end
end

function UIPenglaiAutoReward(t)
    print("蓬莱仙岛2127，接受客户端数据")
    printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:autoReload(t)
    end
end


function UIPenglai3Reward(t)
    print("蓬莱仙岛2122，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
    UIRequest({type = 2120})
end

function UIPenglai3Reset(t)
    print("蓬莱仙岛2123，接受客户端数据")
    printT(t)
    if GameScene.layers["penglai"].show then
        GameScene.layers["penglai"].module:reload(t)
    end
    UIRequest({type = 1001})
end