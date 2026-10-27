--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-13
-- Time: 上午11:01
-- To change this template use File | Settings | File Templates.
--

function UISouls(t)
    print("10026 接受客户端数据")
    --printT(t)
    GameScene.layers["soul"].module:relaodList(t.param,t.souls)
    if GameScene.layers["soul"].show then
        GameScene.layers["soul"].module:shiftListPage()
    end

    if t.param == "all" then
        if GameScene.layers["soulResolveList"].show then
            GameScene.layers["soulResolveList"].module:ReloadData(t.souls)
        end
    end
end

function UIOffSouls(t)
    print("10027 接受客户端数据")
    --printT(t)

end

function UISoulHuntQuery(t)
    print("2501 接受客户端数据")
    --printT(t)

--    for i = 1,5 do
--        if not gameTimer.times["soulTimer"..i] and t.soulhunt.time[tostring(i)] > 0 then
--            gameTimer:rigistTime("soulTimer"..i,t.soulhunt.time[tostring(i)])
--        end
--    end

    if GameScene.layers["soul"].show then
        GameScene.layers["soul"].module:relaodHunt(t)
    end
end

function UISoulHunt(t)
    print("2502 接受客户端数据")
    --printT(t)

--    for i = 1,5 do
--        if t.soulhunt.time[tostring(i)] and t.soulhunt.time[tostring(i)] > 0 then
--            gameTimer:rigistTime("soulTimer"..i,t.soulhunt.time[tostring(i)])
--        end
--    end

    if t.getsouls and table.getTableLength(t.getsouls) >=1 then
        GameScene.layers["soul"].module:playget(t.getsouls)
        GameScene:addUpdate(10026,"all")
        for k,v in pairs(t.getsouls) do
            if v.quality then
                GameScene:addUpdate(10026,"star"..v.quality)
            end
        end
    end

    if t.reward and next(t.reward) then
        runGamePrompt({msg = "获得"..ui.IDconfig(t.reward["1"].cid).name..t.reward["1"].num})
    end
    if GameScene.layers["soul"].show then
        GameScene.layers["soul"].module:requestItemNum()
    end
    setroleupdatacallback(function()
        if GameScene.layers["soul"].show then
            GameScene.layers["soul"].module:relaodHunt(t)
        end
    end)
    GameScene:addUpdate(10021)
    --UIRequest({type = 10026})
    GameScene:addUpdate(1200)
    GameScene:UpdatePresentLayer()
    UIRequest({type = 1001})

end

function UISoulExchange(t)
    print("2503 接受客户端数据")
    printT(t)
    if GameScene.layers["soul"].show then
        GameScene.layers["soul"].module:relaodHunt(t)
    end

    showRewardPopupWindow(t.getsouls,nil,nil)
    UIRequest({type = 1001})
    --UIRequest({type = 10026})
end

function UISoulUpgrade(t)
    print("2504 接受客户端数据")
    --printT(t)

    --resetSoulStrengthen(t.newsoul,function() GameScene:UpdatePresentLayer() end)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10026,"all")
    GameScene:addUpdate(10026,"star"..t.newsoul.quality)
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()
    if gameWindows.windows["soulInfo"].show then
        gameWindows.windows["soulInfo"].module:reloaddata(t.newsoul)
    end
end

function UISoulHunt41(t)
    print("2505 接受客户端数据")
    --printT(t)

    if GameScene.layers["soul"].show then
        GameScene.layers["soul"].module:relaodHunt(t)
    end
end

function UISoulResolve(t)
    print("2506 接受客户端数据")
    --printT(t)

    if t.reward and next(t.reward) then
        runGamePrompt({msg = "获得"..gamedata.config.props[tostring(t.reward["1"].cid)].name..t.reward["1"].num})
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10026,"all")
    for k,v in pairs(t.changes) do
        GameScene:addUpdate(10026,k)
    end
    GameScene:addUpdate(1200)
    GameScene:UpdatePresentLayer()
end

--
function UISoulCompound(t)
    print("2507 接受客户端数据")
    --printT(t)

    if gameWindows.windows["soulintegrate"].show then
        gameWindows.windows["soulintegrate"].module:compound()
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10026,"all")
    GameScene:addUpdate(10026,"star2")
    GameScene:addUpdate(10026,"star3")
    GameScene:addUpdate(10026,"star4")
    GameScene:addUpdate(10026,"star5")
    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

end
