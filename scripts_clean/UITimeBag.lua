--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/1/12
-- Time: 16:25
-- To change this template use File | Settings | File Templates.
--

function UITimeBag(t)
    print("限时礼包查询2880，接受客户端数据")
    printT(t)

    if t.param and t.param == "main" then
        if not next(t.timebag) then
            GameScene:runMainTip()
        else

            if gameWindows.windows["timebag"].show then
                gameWindows.windows["timebag"].module:reloadData(t,function()
                    GameScene:runMainTip()
                end)
            else
                gameWindows:openWindow("timebag",t,function()
                    GameScene:runMainTip()
                end)
            end
        end
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadtimebag(t)
    end    
end

function UITimeBagTimeOver( t )
    print("限时礼包到期28801，接受客户端数据")

    if gameWindows.windows["timebag"].show then
        gameWindows.windows["timebag"].module:reloadData(t)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadtimebag(t)
    end
end

function UITimeBagGet(t)
    print("限时礼包领取2881，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        if gameWindows.windows["timebag"].show then
            gameWindows.windows["timebag"].module:reloadData(t)
        end
    end)

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadtimebag(t)
    end  

end

function UITimeBagTrig( t )
    print("限时礼包触发2882，接受客户端数据")
    printT(t)

    if t.param and t.param=="main" then
        UIRequest({type = 2880,param="main"})
    end

    if not t.timebag then 
        print("触发条件不满足")
        return 
    end

    if gameWindows.windows["timebag"].show then
        gameWindows.windows["timebag"].module:reloadData(t)
    else
        gameWindows:openWindow("timebag",t)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadtimebag(t)
    end  
end
