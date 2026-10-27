--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UIActivitySDKShareQuery(t)
    print("sdk分享2085，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[46] then
        GameScene.layers["activity"].module.pageTable[46].module:reloaddata(t)
    end

end

function UIActivitySDKShareDo(t)
    print("sdk分享2086，接受客户端数据")
    printT(t)

    UIRequest({type = 2085})

end

function UIActivitySDKShareOk(t)
    print("sdk分享20861成功，接受客户端数据")
    printT(t)
    UIRequest({type = 2086})

end

function UIActivitySDKShareReward(t)
    print("sdk分享2087，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    UIRequest({type = 2085})

end