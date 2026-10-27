--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/8
-- Time: 上午10:06
-- To change this template use File | Settings | File Templates.
--


function UIWorldBoss1Query(t)
    print("世界boss3400,接受客户端数据")
    -- printT(t)
    gameTimer:rigistTime("worldbossstart",t.startCD)

    if GameScene.layers["worldboss"].show then
        GameScene.layers["worldboss"].module:reloadstatus(t.worldboss)
        gameTimer:rigistTime("worldbossattack1",t.worldboss.cd)
        print("setlivecd ui3400===",t.worldboss.cd)
    end

    GameScene.layers["main"].module:setWorldBossStatus(t.worldboss.status)
end

function UIWorldBoss1Attack(t)
    print("世界boss3401,接受客户端数据")
    printT(t)
    gameTimer:UnrigistTimeFunc("worldbossattack1")
    gameTimer:rigistTime("worldbossattack1",t.worldboss.cd)
    print("setlivecd ui3401===",t.worldboss.cd)

    local cb = function()
        if GameScene.layers["worldboss"].show then
            print("worldboss..is..show")
            if t.worldboss.status == 0 then
                if t.worldboss.kill == 0 then
                    GameScene.layers["worldboss"].module:reloadstatus(t.worldboss)
                else
                    GameScene.layers["worldboss"].module:bosskilled()
                end
            else
                GameScene.layers["worldboss"].module:setBattle(t.worldboss)
                GameScene.layers["worldboss"].module:startnotify()
            end
        else
            print("worldboss..isnot..show")
            if t.worldboss.status == 0 then
            else
                print("fresh..timer==")
                GameScene.layers["worldboss"].module:setattackCD(t.worldboss.cd)
            end
        end
    end


    if t.isauto == 1  then
        if next(t.reward) then
            if GameScene.layers["worldboss"].show then
                showRewardPopupWindow(t.reward,nil,cb)
            else
                updateDataLife(t.reward)
                cb()
            end
        else
            cb()
        end
    else
        if t.battlereport then
            GameScene.layers["worldboss"].module:stoptnotify()
            RunbattleCallBack("worldboss", t, cb)
        end
    end

    UIRequest({type = 1001})

end

function UIWorldBoss1Rank(t)
    print("世界boss3402,接受客户端数据")
    -- printT(t)

    if GameScene.layers["worldboss"].show then
        GameScene.layers["worldboss"].module:setrealrank(t.ranks)
    end
end

function UIWorldBoss1RealNotify(t)
    print("世界boss3403,接受客户端数据")
    -- printT(t)

    if GameScene.layers["worldboss"].show then
        GameScene.layers["worldboss"].module:setbosshp(t.bosshp)
        GameScene.layers["worldboss"].module:reloadnotify(t.infos)
    end

    GameScene.layers["main"].module:setWorldBossStatus(t.bosshp)
end

function UIWorldBoss1PreRank(t)
    print("世界boss3404,接受客户端数据")
    -- printT(t)

    if GameScene.layers["worldboss"].show then
        GameScene.layers["worldboss"].module:reloadprerank(t)
    end
end

-------------------------------------------------------------------------------------
-----------------------------------另外一条龙数据--------------------------------------
-------------------------------------------------------------------------------------
function UIWorldBoss2Query(t)
    print("世界boss3410,接受客户端数据")
    -- printT(t)
    gameTimer:rigistTime("worldbossstart",t.startCD)

    if GameScene.layers["worldboss"].show then
        GameScene.layers["worldboss"].module:reloadstatus(t.worldboss)
        gameTimer:rigistTime("worldbossattack2",t.worldboss.cd)
    end

    GameScene.layers["main"].module:setWorldBossStatus(t.worldboss.status)
end

function UIWorldBoss2Attack(t)
    print("世界boss3411,接受客户端数据")
    -- printT(t)
    
    gameTimer:UnrigistTimeFunc("worldbossattack2")
    gameTimer:rigistTime("worldbossattack2",t.worldboss.cd)

    local cb = function()
        if GameScene.layers["worldboss"].show then
            if t.worldboss.status == 0 then
                if t.worldboss.kill == 0 then
                    GameScene.layers["worldboss"].module:reloadstatus(t.worldboss)
                else
                    GameScene.layers["worldboss"].module:bosskilled()
                end
            else
                GameScene.layers["worldboss"].module:setBattle(t.worldboss)
                GameScene.layers["worldboss"].module:startnotify()
            end
        else
            print("worldboss..isnot..show")
            if t.worldboss.status == 0 then
            else
                print("fresh..timer==")
                GameScene.layers["worldboss"].module:setattackCD(t.worldboss.cd)
            end
        end
    end


    if t.isauto == 1 then
        if next(t.reward) then
            if GameScene.layers["worldboss"].show then
                showRewardPopupWindow(t.reward,nil,cb)
            else
                updateDataLife(t.reward)
                cb()
            end
        else
            cb()
        end
    else
        if t.battlereport then
            GameScene.layers["worldboss"].module:stoptnotify()
            RunbattleCallBack("worldboss", t, cb)
        end
    end

    UIRequest({type = 1001})

end

function UIWorldBoss2Rank(t)
    print("世界boss3412,接受客户端数据")
    -- printT(t)

    if GameScene.layers["worldboss"].show then
        GameScene.layers["worldboss"].module:setrealrank(t.ranks)
    end
end

function UIWorldBoss2RealNotify(t)
    print("世界boss3413,接受客户端数据")
    -- printT(t)

    if GameScene.layers["worldboss"].show then
        GameScene.layers["worldboss"].module:setbosshp(t.bosshp)
        GameScene.layers["worldboss"].module:reloadnotify(t.infos)
    end

    GameScene.layers["main"].module:setWorldBossStatus(t.bosshp)
end

function UIWorldBoss2PreRank(t)
    print("世界boss3414,接受客户端数据")
    -- printT(t)

    if GameScene.layers["worldboss"].show then
        GameScene.layers["worldboss"].module:reloadprerank(t)
    end
end



--
function UIHeroBossQuery(t)
    print("5201,接受客户端数据")
    printT(t)

    GameScene.herobosschallengenum = 0
    GameScene.herobossenter = 0
    GameScene.herobossfollow = 0
    GameScene.herobossdouble = 0
    if t.heroboss then
        GameScene.herobossdouble = t.heroboss.double or 0
        GameScene.herobossenter = t.heroboss.enter or 0
        GameScene.herobosschallengenum = t.heroboss.challengenum or 0
       for k,v in pairs(t.heroboss.boss) do
            if v.follow and v.follow == 1 then
                GameScene.herobossfollow = v.id
            end
       end
    end
    --
    if GameScene.layers["bosschallenge"].show then
        GameScene.layers["bosschallenge"].module:ReloadData(t)
    end

end

function UIHeroBossFollow(t)
    print("5202,接受客户端数据")
    printT(t)

    if t.isfollow and t.isfollow == 1 then
        runGamePrompt({msg = "关注成功"})
        UIRequest({type = 5201})
    elseif t.isfollow and t.isfollow == 2 then
        runGamePrompt({msg = "关注取消"})
        UIRequest({type = 5201})
    end

end

function UIHeroBossEnter(t)
    print("5203,接受客户端数据")
    printT(t)

    GameScene.layers["bosschallenge_attack"].module:reloaddata(t)
    if t.heroboss.status == 0 then
        gameTimer:UnrigistTimeFunc("herobossovertime")
        gameTimer:UnrigistTimeFunc("herobossattack")
        if t.heroboss.cd > 0 then
            gameTimer:rigistTime("herobosstime",t.heroboss.cd+1)
        else
            gameTimer:rigistTime("herobosstime",0)
        end
    elseif t.heroboss.status == 1 then
        gameTimer:UnrigistTimeFunc("herobosstime")
        if t.heroboss.cd > 0 then
            gameTimer:rigistTime("herobossattack",t.heroboss.cd)
        else
            gameTimer:rigistTime("herobossattack",0)
        end
        if t.heroboss.kill > 0 then
            gameTimer:rigistTime("herobossovertime",t.heroboss.kill+1)
        else
            gameTimer:rigistTime("herobossovertime",0)
        end
    end

    if GameScene.layers["bosschallenge_attack"].show then
        GameScene.layers["bosschallenge_attack"].module:reloadstatus()
    end

end

function UIHeroBossAttack(t)
    print("5204,接受客户端数据")
    printT(t)

    GameScene.layers["bosschallenge_attack"].module:reloaddata(t)
    if t.heroboss.status == 0 then
        gameTimer:UnrigistTimeFunc("herobossovertime")
        gameTimer:UnrigistTimeFunc("herobossattack")
        if t.heroboss.cd > 0 then
            gameTimer:rigistTime("herobosstime",t.heroboss.cd+1)
        else
            gameTimer:rigistTime("herobosstime",0)
        end
    elseif t.heroboss.status == 1 then
        gameTimer:UnrigistTimeFunc("herobosstime")
        if t.heroboss.cd > 0 then
            gameTimer:rigistTime("herobossattack",t.heroboss.cd)
        else
            gameTimer:rigistTime("herobossattack",0)
        end
    end

    local cb = function()
        if GameScene.layers["bosschallenge_attack"].show then
            GameScene.layers["bosschallenge_attack"].module:reloadstatus()
        end
    end

    if t.isauto == 1  then
        if next(t.reward) then
            if GameScene.layers["bosschallenge_attack"].show then
                showRewardPopupWindow(t.reward,nil,cb)
            else
                updateDataLife(t.reward)
                cb()
            end
        else
            cb()
        end
    else
        if t.battlereport then
            GameScene.layers["bosschallenge_attack"].module:stoptnotify()
            RunbattleCallBack("heroboss", t, cb)
        end
    end

    if t.reward and next(t.reward) then
        UIRequest({type = 1001})
    end

end


function UIHeroBossRank(t)
    print("5206,接受客户端数据")
    printT(t)

    if GameScene.layers["bosschallenge_attack"].show then
        GameScene.layers["bosschallenge_attack"].module:setrealrank(t.ranks)
    end
end

function UIHeroBossRealNotify(t)
    print("5207,接受客户端数据")
    printT(t)
    if t.infos and t.infos["1"] and t.infos["1"].method and GameScene.layers["bosschallenge_attack"].module.bossid and (GameScene.layers["bosschallenge_attack"].module.bossid == t.infos["1"].method)  then

        if GameScene.layers["bosschallenge_attack"].show then
            GameScene.layers["bosschallenge_attack"].module:setbosshp(t.bosshp)
            GameScene.layers["bosschallenge_attack"].module:reloadnotify(t.infos)
            --
            if gameTimer.times["herobossovertime"] and gameTimer.times["herobossovertime"] > 0 then
            else
                GameScene.layers["bosschallenge_attack"].module:changedata()
            end
        end

    end
end

function UIHeroBossCheer(t)
    print("5205,接受客户端数据")
    printT(t)

    if gameWindows.windows["bosschallenge_cheer"].show then
         gameWindows.windows["bosschallenge_cheer"].module:reload(t)
    end

    if GameScene.layers["bosschallenge_attack"].show then
        GameScene.layers["bosschallenge_attack"].module:changedata()
    end

    UIRequest({type = 1001})

end

function UIHeroBossAwardRecord(t)
    print("5208,接受客户端数据")
    printT(t)

    gameWindows:openWindow("bosschallenge_ranklist",t,nil)

end

function UIHeroBossRevive(t)
    print("5209,接受客户端数据")
    printT(t)

    UIRequest({type = 5201})

    for k,v in pairs(t.bosslist) do
        if  GameScene.layers["bosschallenge_attack"].module.bossid == v then
            if GameScene.layers["bosschallenge_attack"].show then
                GameScene.layers["bosschallenge_attack"].module:changedata()
            end
        end
        if GameScene.layers["bosschallenge_attack"].show or (battleScene and battleScene.show) then

        elseif GameScene.herobossfollow and GameScene.herobossfollow == v then
            runGamePrompt({msg = "您关注的英雄挑战BOSS已复活，快去挑战吧！"})
        end
    end
end


function UIHeroBossDead(t)
    print("5210,接受客户端数据")
    printT(t)

    UIRequest({type = 5201})

    for k,v in pairs(t.bosslist) do
        if  GameScene.layers["bosschallenge_attack"].module.bossid == v then
            gameTimer:UnrigistTimeFunc("herobossattack")
            if GameScene.layers["bosschallenge_attack"].show then
                GameScene.layers["bosschallenge_attack"].module:changedata()
            end
        end
    end

end

function UIHeroBossDouble(t)
    print("5211,接受客户端数据")
    printT(t)

    if t.result and t.result == 1 then
        UIRequest({type = 5201})
    else
        runGamePrompt({msg = "操作失败"})
    end
end


function UIHeroBossChangeNum(t)
    print("5212,接受客户端数据")
    printT(t)

    if GameScene.layers["bosschallenge"].show then
        UIRequest({type = 5201})       
    end

end
  b2  