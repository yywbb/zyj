--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/12
-- Time: 下午6:08
-- To change this template use File | Settings | File Templates.
--

local function reloadGang(gangstatus)
    if gangstatus.id and gangstatus.id > 0 then

        if GameScene.layers["gang_main"].show then
            GameScene.layers["gang_main"].module:reloaddata(gangstatus)
        else
            GameScene:shiftLayer("gang_main","up")
            GameScene.layers["gang_main"].module:reloaddata(gangstatus)
        end
    else
        GameScene:shiftLayer("gang_list","up")
    end
end


function UIGuildWarPointCatalogue(t)
    print("公会2130，接受客户端数据")
    -- printT(t)

    if GameScene.layers["gangwar_main"].show then
        GameScene.layers["gangwar_main"].module:reloaddata(t.guildwarmain)
    elseif t.param and t.param == "main" then
        GameScene:shiftLayer("gangwar_main","up",t.guildwarmain)
    end

end

function UIGuildWarTreasureInfo( t )
    print("公会2131，据点详细信息")
    -- printT(t)
    if t.treasureInfo and gameWindows.windows["guildtreasureinfo"].show  then
        gameWindows.windows["guildtreasureinfo"].module:reload(t)
    else
        print("UIGuildWarTreasureInfo")
        -- showRewardPopupWindow(t.treasureInfo,nil)        
    end    
end

function UIGangPointJoinConfirm( t )
    print("公会2132，据点报名")
    -- printT(t)
    if gameWindows.windows["guildtreasureinfo"].show then
        gameWindows.windows["guildtreasureinfo"].module:changeState(t.state)
    end
    if gameWindows.windows["guildtreasuretips"].show then
        gameWindows:closeWindow("guildtreasuretips")
    end
    
    UIRequest({type = 2130})
end

function UIGangPointJoinQuery( t )
    print("公会2133， 查看据点报名")
    printT(t)
    if t.treasureChechList then
        gameWindows:openWindow("guildtreasurechecklist",{id =  t.id , guildid = t.guildid,treasureChechList = t.treasureChechList})
    end
end

function UIGangPointEnterBattlefield(t)
    print("公会2134，接受客户端数据")
    -- printT(t)
    if t.GuildWarPrepare.time and t.GuildWarPrepare.time > 0 then
        gameTimer:rigistTime("guildprepare",t.GuildWarPrepare.time+2 or 0)
    else
        gameTimer:rigistTime("guildprepare",0)
    end

    if GameScene.layers["guildprepare"].show then
        GameScene.layers["guildprepare"].module:ReloadData(t)
    elseif t.pointId then
        GameScene:shiftLayer("guildprepare","up",t)
    end

end

function UIGangPointInspireCoin(t)
    print("公会2136，接受客户端数据")
    -- printT(t)

    if GameScene.layers["guildprepare"].show then
        GameScene.layers["guildprepare"].module:ReloadInspire(t)

    end

    UIRequest({type = 1001})

end

function UIGangPointInspireGold(t)
    print("公会2137，接受客户端数据")
    -- printT(t)

    if GameScene.layers["guildprepare"].show then
        GameScene.layers["guildprepare"].module:ReloadInspire(t)

    end

    UIRequest({type = 1001})

end

function UIGangPointJoinBattle(t)
    print("公会2135，接受客户端数据")
    -- printT(t)

    if GameScene.layers["guildprepare"].show then
        GameScene.layers["guildprepare"].module:ReloadInspire(t)
    end

end

function UIGangPointMembers(t)
    print("公会2143，接受客户端数据")
    printT(t)

    if GameScene.layers["guildprepare"].show then
        GameScene.layers["guildprepare"].module:ReloadMembers(t)
    end

end

function UIGangPointBattleStatusQuery(t)
    print("公会2138，接受客户端数据")
    -- printT(t)
    if next(t.GuildStandingsShow) then
        gameWindows:openWindow("standings", t, nil)
    else
        print("没有战报")
        runGamePrompt({msg = "没有战报"})
    end
end

function UIGangPointSumBattleList(t)
    print("公会2140，接受客户端数据")
    -- printT(t)
    if gameWindows.windows["standings"].show then
        gameWindows.windows["standings"].module:onUpdataInfo(t)
    end
end

function UIGangPointSumBattlePlay(t)
    print("公会2139，接受客户端数据")
    if t.battlereport then
        RunbattleCallBack("guildwar", t)
    end
end

function UIGangPointBraBattlePlay(t)
    print("公会2141，接受客户端数据")

    if t.battlereport then
        RunbattleCallBack("guildwar", t)
    end
end

function UIGuildWarPointAward(t)
    print("公会2142，接受客户端数据")
    -- printT(t)
    if GameScene.layers["gangwar_main"].show then
        GameScene.layers["gangwar_main"].module:reloaddata(t.guildwarmain)
    end

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1001})
    end

end

function UIMainGetGangData(t)
    print("公会2149，接受客户端数据")
    printT(t)

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:gonghuizhanUpdateTime(t.gangstatus)
    end
    if GameScene.layers["limitedset"].show then
        GameScene.layers["limitedset"].module:gonghuizhanUpdateTime(t.gangstatus)
    end
end

--
function UIGuildWarProfit(t)
    print("公会2144，接受客户端数据")
    printT(t)

    GameScene.guildWarProfit = t.guildWarProfit


end

function UIGuildWarProfitChange(t)
    print("公会2145，接受客户端数据")
    printT(t)

    GameScene.guildWarProfit = t.guildWarProfit

    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:shiftPage()
    end

end

function UIGuildWarOneInspire(t)
    print("公会2146，接受客户端数据")
    printT(t)
    UIRequest({type = 2130})
    UIRequest({type = 1001})

end

function UIGuildWarOneBattle(t)
    print("公会2147，接受客户端数据")
    printT(t)
    UIRequest({type = 2130})
    UIRequest({type = 1001})

end

