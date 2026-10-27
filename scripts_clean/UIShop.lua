--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 14-10-16
-- Time: 19:47
-- To change this template use File | Settings | File Templates.
--

function UIGiftBagQuery(t)
    print("请求商城礼包3210 接收客户端返回数据")

    GameScene.giftbags = t.giftbags or {}

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:ReloadGiftData(t)
    end
end

function UIShopQuery(t)
    print("道具请求3200 接收客户端返回数据")

    --printT(t)

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:ReloadPropsData(t)
    end
end

function UIShopBuy(t)
    print("道具购买3201 接收客户端返回数据")

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:ReloadPropsData(t)
    end

    if gameWindows.windows["shopbuy"].show then
        gameWindows.windows["shopbuy"].module:reloadData(table.merge(gamedata.config.shop[tostring(t.id)],{usenum = t.props[tostring(t.id)]}))
    end

    showRewardPopupWindow(t.reward,nil)

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
end

function UIGiftBagBuy(t)
    print("请求商城礼包3211 接收客户端返回数据")

    GameScene.giftbags = t.giftbags or {}

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:ReloadGiftData(t)
    end
    showRewardPopupWindow(t.reward,nil)

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
end


--
function UIVipWeekGift(t)
    print("4890 接收客户端返回数据")
    printT(t)

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:ReloadWeekGiftData(t)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[173] and GameScene.layers["activity"].module.pageTable[173].module and GameScene.layers["activity"].module.pageTable[173].module.show then
        GameScene.layers["activity"].module.pageTable[173].module:reloaddata(t)
    end
end

function UIVipWeekGiftReward(t)
    print("4891 接收客户端返回数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil)
    end

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})

    UIRequest({type = 4890})

end

function UIActivityBuyItem(t)
    print("购买道具5345，接受客户端数据")
    if gameWindows.windows["buyItem"].show then
        gameWindows.windows["buyItem"].module:buySuccess(t.reward)
    end
end

function UIShopAutoRefinQuery(t)
    print("自动炼化8060，接受客户端数据")
    printT(t,"jkp-auto")
    if gameWindows.windows["autorefining"].show then
        gameWindows.windows["autorefining"].module:reload(t.data)
    end
end

function UIShopAutoRefinSet(t)
    print("自动炼化8061，接受客户端数据")
    printT(t,"jkp-set")
end