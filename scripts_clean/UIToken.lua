function UITokenActive(t)
    print("天机令激活8241，接受客户端数据")
    printT(t)

    if t.result then
        GameScene:addUpdate(1200)
        UIRequest({type = 10021})
    end
end

function UITokenfragmentCompose(t)
    print("天机令合成8242，接受客户端数据")
    printT(t)
    showRewardPopupWindow(t.reward,nil,nil)
    if GameScene.layers["tokenBag"].show then
        GameScene.layers["tokenBag"].module:UIUpdateData()
    end 
end


function UITokenRecoveryQuery(t)
    print("天机令回收8243，接受客户端数据")
    printT(t)
    showRewardPopupWindow(t.reward,nil,nil)
    if GameScene.layers["tokenBag"].show then
        GameScene.layers["tokenBag"].module:UIUpdateData()
    end 
end