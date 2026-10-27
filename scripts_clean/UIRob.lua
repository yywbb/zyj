--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-17
-- Time: 下午4:30
-- To change this template use File | Settings | File Templates.
--

function setcd(cd,energy1,energy2)

    gameTimer:rigistTime("robprofCD",cd or 0)

    if GameScene.layers["rob"].show then
        GameScene.layers["rob"].module:setCD()
        GameScene.layers["rob"].module:robTreasureEnergy(energy1,energy2)
    end
end


function UIRobProfCDquery(t)
    print("抢夺保护CD1112，接受客户端数据")
    setcd(t.cd,t.energy1,t.energy2)
end

function UIRobProfCDAdd(t)
    print("抢夺保护CD1113，接受客户端数据")
    --printT(t)
    setcd(t.cd)
    UIRequest({type = 12001, order = 11121, cids = {20128}})
end

function UIGameRobEquipQuery(t)
    print("抢夺11111，接受客户端数据")
    --printT(t)

    GameScene.layers["rob"].module.treasureData = t.treasures
    GameScene.layers["rob"].module.horseData = t.horses
    GameScene.layers["rob"].module.meterialData = t.meterials
    if GameScene.layers["rob"].show then
        GameScene.layers["rob"].module:setshiftPage()
        GameScene.layers["rob"].module:robTreasureEnergy(t.energy1,t.energy2)
    end
end

function UIGameRobGeneralQuery(t)
    print("抢夺11112，接受客户端数据")
    --printT(t)

--    GameScene.layers["rob"].module.generalshowData = t.generals
--    if GameScene.layers["rob"].show then
--        GameScene.layers["rob"].module:setshiftPage()
--    end
end

function UIGameGeneralFragmentRobQuery(t)
    print("魂魄抢夺查询1018,接受客户端数据")
    --printT(t)
    if next(t.players) then
        -- gameWindows:openWindow("robselect",t,nil)
        if gameWindows.windows["robselect"].show then
            gameWindows.windows["robselect"].module:onReload(t)
        else
            gameWindows:openWindow("robselect",t,nil)
        end        
    else
        runGamePrompt({msg = "无可挑战的玩家"})
    end
end

function UIGameGeneralFragmentRob(t)
    print("魂魄抢夺1019,接受客户端数据")
    --printT(t)
--    setcd(0)
--    local cb = function()
--        if t.result == 0 then
--            gameWindows:openWindow("robresult",{index= "fail",data = t},nil)
--        else
--            if next(t.reward) then
--                if GameScene.layers["rob"].show then
--                    GameScene.layers["rob"].module:robGeneralSucess()
--                end
--                GameScene:addUpdate(1012)
--            else
--                gameWindows:openWindow("robresult",{index= "lost",data = t},nil)
--            end
--        end
--    end
--
--    RunbattleCallBack("rob", t, cb)
--    UIRequest({type = 1001})

end

function UIGameTreasureFragmentRobQuery(t)
    print("宝物抢夺查询1110,接受客户端数据")
    -- printT(t)
    if next(t.players) then
        -- gameWindows:openWindow("robselect",t,nil)
        if gameWindows.windows["robselect"].show then
            gameWindows.windows["robselect"].module:onReload(t)
        else
            gameWindows:openWindow("robselect",t,nil)
        end
        
    else
        runGamePrompt({msg = "无可挑战的玩家"})
    end
end


function UIGameTreasureFragmentRob(t)
    print("宝物抢夺查询1111,接受客户端数据")
    -- printT(t)

    setcd(0,t.energy1,t.energy2)

    local cb = function()
        if t.result == 0 then
            gameWindows:openWindow("robresult",{index= "fail",data = t},nil)
        else
            local changeCoin,changeGold = updateDataLife(t.otherreward)

            local callback = function()
                if changeGold then
                    GameScene:coin_effect(2,540,960,0.5)
                end
            end
            gameWindows:openWindow("robresult",{index= "seccess",data = t},callback)
            if GameScene.layers["rob"].show then
                GameScene.layers["rob"].module:robTreasureSucess(t.get)
                GameScene.layers["rob"].module:robTreasureEnergy(t.energy1,t.energy2)
            end

            GameScene:UpdatePresentLayer()
            UIRequest({type = 10322,param = {"rob"}})
        end
    end

    GameScene:addUpdate(11071,"treasure")
    GameScene:addUpdate(1200)
    RunbattleCallBack("rob", t, cb)
    UIRequest({type = 1001})
end

function UIGameTreasureFragmentRobTen(t)
    print("宝物抢夺十次1114,接受客户端数据")
    -- printT(t)
    local changeCoin,changeGold = updateDataLife(t.otherreward)

    local callback = function()
        if changeGold then
            GameScene:coin_effect(2,540,960,0.5)
        end
    end

    GameScene:addUpdate(11071,"treasure")
    GameScene:addUpdate(1200)
    gameWindows:openWindow("robresult",{index= "robTen",data = t},callback)
    if GameScene.layers["rob"].show then
        GameScene.layers["rob"].module:robTreasureSucess(t.get)
        GameScene.layers["rob"].module:robTreasureEnergy(t.energy1,t.energy2)
    end

    GameScene:UpdatePresentLayer()
    UIRequest({type = 10322,param = {"rob"}})
    UIRequest({type = 1001})
end

function UIRobOneKeyTreasure(t)
   print("宝物碎片抢夺1125,接受客户端数据")
    -- printT(t)
    local changeCoin,changeGold = updateDataLife(t.otherreward)

    GameScene:addUpdate(11071,"treasure")
    GameScene:addUpdate(1200)
    --gameWindows:openWindow("robresult",{index= "robTen",data = t},callback)
    if GameScene.layers["rob"].show then
        GameScene.layers["rob"].module:robOneKeyTreasureSucess(t.get)
        GameScene.layers["rob"].module:robTreasureEnergy(t.energy1,t.energy2)

    end

    GameScene:UpdatePresentLayer()
    UIRequest({type = 10322,param = {"rob"}})
    UIRequest({type = 1001})

    --
    if gameWindows.windows["robonekeyresult"].show then
        setcd(0,t.energy1,t.energy2)

        gameWindows.windows["robonekeyresult"].module:Reload(t)
    end 

end


