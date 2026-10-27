--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/2/4
-- Time: 上午10:34
-- To change this template use File | Settings | File Templates.
--


function UIGeneralCollect(t)
    print("伙伴收集1015，接受客户端数据")
    --GameScene.layers["collect"].module:getgeneralData(t.generalcollect)
    if GameScene.layers["collect"].show then
        GameScene.layers["collect"].module:reloadgeneralData(t.generalcollect)
    end

    if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodIconData(t.generalcollect)
    end
end


function UIEquipCollect(t)
    print("装备收集1103，接受客户端数据")

    --GameScene.layers["collect"].module:getequipData(t.equipcollect)
    if GameScene.layers["collect"].show then
        GameScene.layers["collect"].module:reloadequipData(t.equipcollect)
    end
end

function UITeamRecomQuery(t)
    print("阵容推荐查询3910，接受客户端数据")
    -- printT(t)
    if GameScene.layers["collect"].show then
        GameScene.layers["collect"].module:getBoxData(t.teamRecomQuery)
    end
end

function UITeamRecomReward(t)
    print("领取宝箱3911，接受客户端数据")
    if GameScene.layers["collect"].show then
        GameScene.layers["collect"].module:getBoxData(t.teamRecomQuery)
    end
    showRewardPopupWindow(t.reward, nil,nil)
end

