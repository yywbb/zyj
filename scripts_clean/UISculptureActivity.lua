--
-- Author: songyibo
-- Date: 2021-03-01 16:22:07
--

function UISculptureActivityQuery(t)
    printT(t,"8130 雕塑红利查询")
    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[180] and GameScene.layers["activity"].module.pageTable[180].module and GameScene.layers["activity"].module.pageTable[180].module.show then
        GameScene.layers["activity"].module.pageTable[180].module:reloaddata(t.data)
    end
end

function UISculptureActivityAward(t)
    printT(t,"8131 雕塑红利领奖")

    local cb = function (  )
        if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[180] and GameScene.layers["activity"].module.pageTable[180].module and GameScene.layers["activity"].module.pageTable[180].module.show then
            if t.rewardstatus then
                GameScene.layers["activity"].module.pageTable[180].module:reloaddata({reward = t.rewardstatus,props = t.props})
            else
                UIRequest({type = 8130})
            end
        end
    end

    if t.reward then
        showRewardPopupWindow(t.reward,nil,cb)
    else
        cb()
    end
end


function UISculptureActivityShopBuy(t)
    printT(t,"8132 雕塑红利商店购买")
    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[180] and GameScene.layers["activity"].module.pageTable[180].module and GameScene.layers["activity"].module.pageTable[180].module.show then
    	GameScene.layers["activity"].module.pageTable[180].module:reloaddata({shop = t.shop,props = t.props})
    end
end


function UISculptureActivityRankQuery(t)
    printT(t,"8133 雕塑红利排行")
    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[180] and GameScene.layers["activity"].module.pageTable[180].module and GameScene.layers["activity"].module.pageTable[180].module.show then
        GameScene.layers["activity"].module.pageTable[180].module:reloadRank(t.ranklist)
    end
end
