--
-- Author: songyibo
-- Date: 2019-03-21 11:16:04
--

function UIXianBuyTimes(t)
    printT(t,"7010 仙元购买挑战次数")
    if t.sysId == 450 then
        if GameScene.layers["babelTower"].show then
             GameScene.layers["babelTower"].module:freshChallengeTimes(t.BabelTowerMapData.buyTime)
        end

        if gameWindows.windows["babelTowerEnter"].show then
            gameWindows.windows["babelTowerEnter"].module:freshChallengeTimes(t.BabelTowerMapData.buyTime)
        end
        runGamePrompt({msg = gameConfig.strings:string_common("babelTower", 20)})
    elseif t.sysId == 463 then

        GameScene.vipstatus.xianku_cishu = GameScene.vipstatus.xianku_cishu   +  t.buyTime
        if GameScene.layers["blessingCave"].show then
          GameScene.layers["blessingCave"].module:reloadTimes(t)
        end
    elseif t.sysId == 614 then
        GameScene.vipstatus.device_soul = GameScene.vipstatus.device_soul   +  t.buyTime
        if GameScene.layers["exclusiveArtifactCopy"].show then
          GameScene.layers["exclusiveArtifactCopy"].module:reloadTimes(t)
        end
    end

    UIRequest({type = 1001})
    
end


function UIBabelTowerQuery(t)
    printT(t,"7011 通天塔查询")
    if t.data.curPoint > 0 then
        --直接进入关卡
        UIRequest({type = 7012,mapId = t.data.curPoint})
    else
        if not GameScene.layers["babelTower"].show then
            GameScene:shiftLayer("babelTower","up",t.data)
        else
            GameScene.layers["babelTower"].module:reload(t.data)
        end
    end
end


function UIBabelTowerLevelQuery(t)
    printT(t,"7012 通天塔关卡信息查询")
    if not GameScene.layers["babelTowerLevel"].show then
        GameScene:shiftLayer("babelTowerLevel","up",t)
    else
        GameScene.layers["babelTowerLevel"].module:reload(t)
    end
end


function UIBabelTowerBattle(t)
    printT(t,"7013 通天塔战斗回调")
    local function cb()
        
        if t.reward and next(t.reward) then
            updateDataLife(t.reward)

            local freshLayer = function (  )
                print("freshLayer")
                if GameScene.layers["babelTowerLevel"].show then
                    GameScene.layers["babelTowerLevel"].module:battleCallback({data = t.totalLevelData,mapData = t.mapData})
                end
            end
            if t.firstKill and t.firstKill == 1 then
                gameWindows:openWindow("getStaff",{data = t.reward,type = "首通奖励"},freshLayer)
            else
                gameWindows:openWindow("getStaff",{data = t.reward,type = "恭喜获得"},freshLayer)
            end
        else
            if GameScene.layers["babelTowerLevel"].show then
                GameScene.layers["babelTowerLevel"].module:battleCallback({data = t.totalLevelData,mapData = t.mapData})
            end
        end
    end


    --第一层最后一关播剧情
    -- t.palybackstory = true
    RunbattleCallBack("babelTower", t, cb)
end


function UIBabelTowerQuit(t)
    printT(t,"7014 通天塔退出地图")
    GameScene:shiftLayer("babelTower","up",t.data)
end


function UIBabelTowerAward(t)
    printT(t,"7015 通天塔三星全通奖励领取")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end
    if gameWindows.windows["babelTowerAward"].show then
        gameWindows.windows["babelTowerAward"].module:reload(t.mapData)
    end

    if GameScene.layers["babelTower"].show then
        GameScene.layers["babelTower"].module:reload(t.mapData)
    end

    if GameScene.layers["babelTowerLevel"].show then
        GameScene.layers["babelTowerLevel"].module:reload({mapData = t.mapData})
    end
end

function UIBabelTowerAutoBattle(t)
    printT(t,"7016 通天塔扫荡")
    gameWindows:openWindow("babelTowerAutoBattle",t.rewards)
    if GameScene.layers["babelTowerLevel"].show then
        --定位到停止关卡

        local level = 1
        if t.rewards then
            for k,v in pairs(t.rewards) do
                if v.level > level then
                    level = v.level
                end
            end
            level = math.min(20,level + 1)
            GameScene.layers["babelTowerLevel"].module.levelIndex = level
        end

        
        GameScene.layers["babelTowerLevel"].module:reload({data = t.totalLevelData})
    end
end

function UIBabelTowerShopQuery(t)
    printT(t,"7017 通天塔商店查询")
    if  GameScene.layers["activity"].module.pageTable[161] then
        GameScene.layers["activity"].module.pageTable[161].module:reloadData(t)
    end
end

function UIBabelTowerShopBuy(t)
    printT(t,"7018 通天塔商店购买")
    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if  GameScene.layers["activity"].module.pageTable[161] then
        t.maxMap = nil
        GameScene.layers["activity"].module.pageTable[161].module:reloadData(t)
    end

    UIRequest({type = 1001})
end


function UIBabelTowerRankQuery(t)
    printT(t,"7019 排行查询")
    if gameWindows.windows["babelTowerRank"].show then
        gameWindows.windows["babelTowerRank"].module:reload(t)
    end
end


