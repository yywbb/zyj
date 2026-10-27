--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/6
-- Time: 下午2:34
-- To change this template use File | Settings | File Templates.
--


function UIOverPassQuery(t)
    print("过关斩将3820，接受客户端数据")
    printT(t)

    if GameScene.layers["passkillmain"].show then
        GameScene.layers["passkillmain"].module:reloaddata(t.passkill)
    end
end

function UIOverPassChangeBoss(t)
    print("过关斩将3826，接受客户端数据")
    printT(t)

    if GameScene.layers["passkillmain"].show then
        GameScene.layers["passkillmain"].module:reloaddata(t.passkill)
    end
    UIRequest({type = 1001})
end

function UIOverPassGetReward(t)
    print("过关斩将3827，接受客户端数据")
    printT(t)

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,nil)
    end

    if GameScene.layers["passkillmain"].show then
        GameScene.layers["passkillmain"].module:reloaddata(t.passkill)
    end
    UIRequest({type = 1001})
end

function UIOverPassBattle(t)
    print("过关斩将3824，接受客户端数据")
    printT(t)

    local cb = function()
        UIRequest({type = 3820})
    end

    if t.isauto and t.isauto == 1 then
        if t.result and t.result == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("island",13)})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("island",12)})
        end
        showRewardPopupWindow(t.reward,nil,cb)
    else
        RunbattleCallBack("overpass", t,cb)
    end

    UIRequest({type = 1001})
end

function UIOverPassRank(t)
    print("过关斩将3821，接受客户端数据")
    printT(t)


    if GameScene.layers["passkillrank"].show then
        GameScene.layers["passkillrank"].module:reloadRankData(t.rank,t.myrank)
    end

end

function UIOverPassRankRefresh(t)
    print("过关斩将3825，接受客户端数据")
    printT(t)

    if t.result == 1 then
        if GameScene.layers["passkillrank"].show then
            UIRequest({type = 3821})
        end
        
    else
        runGamePrompt({msg = "操作失败，请重试"})
    end
end

function UIOverPassShop(t)
    print("过关斩将3822，接受客户端数据")
    printT(t)

     if  GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        print("showsecret==")
        GameScene.layers["activity"].module.pageTable[162].module:reloadData(t.passkillshop)
    end

    
end

function UIOverPassShopBuy(t)
    print("过关斩将3823，接受客户端数据")
    printT(t)

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,nil)
    end

    UIRequest({type = 3822})

end

--

function UIOverPassRefresh(t)
    print("过关斩将3828，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        GameScene.layers["activity"].module.pageTable[162].module:reloadData(t.passkillshop)
    end

    UIRequest({type = 1001})

end


function UIOverPassRecordQuery(t)
    print("过关斩将3829，接受客户端数据")
    printT(t)

    if gameWindows.windows["overpassRecord"].show then
        gameWindows.windows["overpassRecord"].module:reloadData(t.players)
    end
end

function UIOverPassRecordPlay(t)
    print("过关斩将3830，接受客户端数据")
    RunbattleCallBack("normal", {battlereport = t.battlereport,result = t.result or 0})
end

function UIOverPassRecordUpdate(t)
    print("过关斩将3831，接受客户端数据")
    UIRequest({type = 3829})
end
