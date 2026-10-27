function UIADQuery(t)
    print("8091，接受客户端数据")
    printT(t)

    if gameWindows.windows["greatGiftByAD"].show then
        gameWindows.windows["greatGiftByAD"].module:reload(t)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setADHint(t,gameWindows.windows["greatGiftByAD"].module.adOnceRed)
    end
end

function UIADReward(t)
    print("8092，接受客户端数据")
    printT(t)
    showRewardPopupWindow(t.reward,nil,nil)
    UIRequest({type =1001})
    UIRequest({type=8091})
end

function UIADChangeStatus(t)
    print("8093，接受客户端数据")
    printT(t)

    if gameWindows.windows["greatGiftByAD"].show then
        gameWindows.windows["greatGiftByAD"].module:reload(t)
    end
    UIRequest({type=8091})
end