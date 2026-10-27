--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-23
-- Time: 下午4:16
-- To change this template use File | Settings | File Templates.
--

function UIAthleticsList(t)
    print("竞技1610，接受客户端数据")
    printT(t)

    if GameScene.layers["sports2"].show then
        GameScene.layers["sports2"].module:relaodRank(t.ranklist,t.top10,t.my,t.athletics_boss)
    end

    -- if GameScene.layers["sportsshop"].show then

    --     GameScene.layers["sportsshop"].module:relaodRank(t.ranklist,t.top10,t.my,t.athletics_boss)
    -- end
    if  GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        print("showsportsshop==")
        GameScene.layers["activity"].module.pageTable[162].module:reloadData(t)
    end

end

function UIAthleticsAttack(t)
    print("竞技攻打1611，接受客户端数据")
    -- printT(t)
    
    if t.isFight == 1 then
        local cb = function()
            UIRequest({type = 999900,reqs = {1610,1613}})
            GameScene.layers["sports2"].module.firstRewardData = nil
        end
        RunbattleCallBack("sports", t,cb)
        UIRequest({type = 1001})
    else
        showRewardPopupWindow(t.reward,nil,function()
            UIRequest({type = 1610})
            UIRequest({type = 1001})
        end)
    end

end

function UIAthleticsBoss(t)
    print("竞技攻打BOSS 1616 接受客户端数据")

    RunbattleCallBack("sports", t)
    UIRequest({type = 1001})
    UIRequest({type = 1610})
end

--
--
function UIAthleticsRewardsList2(t)
    print("竞技领奖查询1613，接受客户端数据")
    -- printT(t)
    -- if GameScene.layers["sports2"].show then
    --     GameScene.layers["sports2"].module:relaodRewards(t.rewards)
    -- end

    -- if GameScene.layers["sportsshop"].show then
    --     GameScene.layers["sportsshop"].module:relaodRewards(t.rewards)
    -- end
    if  GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        print("showsportsshopReward==")
        GameScene.layers["activity"].module.pageTable[162].module:reloadRewards(t.rewards)
    end

end

function UIAthleticsRewardsExchange2(t)
    print("竞技领奖1614，接受客户端数据")
    --printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 999900,reqs = {1610,1613}})
        UIRequest({type = 1001})
    end)

end

function UIAthleticsRankRewardsStatus(t)
    print("竞技领奖查询1615，接受客户端数据")
    printT(t)
    if GameScene.layers["sports2"].show then
        GameScene.layers["sports2"].module:relaodRankStatus(t.rankstatus)
    end
end
