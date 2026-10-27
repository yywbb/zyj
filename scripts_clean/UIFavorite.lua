--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/8
-- Time: 上午10:06
-- To change this template use File | Settings | File Templates.
--


function UIGeneralLove(t)
    print("好感系统3670,接受客户端数据")
    -- printT(t)
    -- showRewardPopupWindow(t.reward,nil,nil)

    -- GameScene:addUpdate(1012)
    -- updateDataLife(t.cid)

    if GameScene.layers["favoritegeneral"].show then
        GameScene.layers["favoritegeneral"].module:reloadData(t)
    end
end

function UIGeneralsLoveQuery(t)
    print("好感系统3671,接受客户端数据")
    -- printT(t)
    -- showRewardPopupWindow(t.reward,nil,nil)
    GameScene.layers["generals"].module.generalslovedata = t.allgeneral

    if gameWindows.windows["favoriteList"].show then
        gameWindows.windows["favoriteList"].module:listdataReload(t.allgeneral)
    end
    if GameScene.layers["favoritegeneral"].show then
        GameScene.layers["favoritegeneral"].module:listdataReload(t.allgeneral)
    end
end

function UIGeneralLoveUseProp(t)
    print("好感系统3672,接受客户端数据")
    -- printT(t)
    
    if GameScene.layers["favoritegeneral"].show then
        GameScene.layers["favoritegeneral"].module:reloadData(t,true)
    end

    if GameScene.layers["favoritegeneral"].show then
        GameScene.layers["favoritegeneral"].module:favoriteSetLevelup(t.useprops)
    end
    
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
end

function UIGeneralLoveExchange(t)
    print("好感系统3675,接受客户端数据")
    -- printT(t)
    
    UIRequest({type = 3671})

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    UIRequest({type = 1001})
end

function UIGeneralLoveTask(t)
    print("好感系统3673,接受客户端数据")
    -- printT(t)

    if gameWindows.windows["favoriteList"].show then
        print("favoriteList..reloadData")
        gameWindows.windows["favoriteList"].module:achievementReload(t.data)
    end

    if GameScene.layers["favoritegeneral"].show then
        print("favoritegeneral..reloadData")
        GameScene.layers["favoritegeneral"].module:achievementReload(t.data)
    end
end


function UIGeneralLoveTaskReward(t)
    print("好感系统3674,接受客户端数据")
    -- printT(t)

    runGamePrompt({msg = t.reward})
    
    if gameWindows.windows["favoriteList"].show then
        gameWindows.windows["favoriteList"].module:achievementReload(t.data)
    end
    if GameScene.layers["favoritegeneral"].show then
        print("favoritegeneral..reloadData")
        GameScene.layers["favoritegeneral"].module:achievementReload(t.data)
    end
    UIRequest({type = 1001, param = "resume"})
end
