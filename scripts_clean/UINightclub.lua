--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/12
-- Time: 下午6:08
-- To change this template use File | Settings | File Templates.
--

-----------------------------------------------------------------------------------------
function UIUserPatrolQuery(t)
    print("天庭银座=4500,接受客户端数据")
    -- printT(t)
    if GameScene.layers["nightclub"].show then
        GameScene.layers["nightclub"].module:reloaddata(t._message)
    end
end
-----------------------------------------------------------------------------------------
function UIUserPatrolStatus(t)
    print("天庭银座=4501,接受客户端数据")
    -- printT(t)
    if GameScene.layers["clubclubcell"].show then
        GameScene.layers["clubclubcell"].module:reloaddata(t.status)
    end
end
-----------------------------------------------------------------------------------------
function UIUserPatrolAttack(t)
    print("天庭银座=4502,接受客户端数据")
    UIRequest({type = 1001})
    -- printT(t)
    local function tmpDone()
        if GameScene.layers["clubclubcell"].show then
            GameScene.layers["clubclubcell"].module:play(t.datas)
        end
    end
    if t.result and t.result ~= -1 then
        RunbattleCallBack("nightclub1", t,tmpDone)
    else
        tmpDone()
    end
end
-----------------------------------------------------------------------------------------
function UIUserPatrolDo(t)
    print("天庭银座=4503,接受客户端数据")
    UIRequest({type = 1001})
    -- printT(t)
    if GameScene.layers["clubclubcell"].show then
        GameScene.layers["clubclubcell"].module.m_iSelet = nil
        GameScene.layers["clubclubcell"].module:reloaddata(t.status)
    end
end
-----------------------------------------------------------------------------------------
function UIUserPatrolReward(t)
    print("天庭银座=4504,接受客户端数据")
    UIRequest({type = 1001})
    -- printT(t)
    if GameScene.layers["clubclubcell"].show then
        GameScene.layers["clubclubcell"].module:refresh(t)
    end
end
-----------------------------------------------------------------------------------------
function UIUserPatrolEventDo(t)
    print("天庭银座=4505,接受客户端数据")
    -- printT(t)
    local changeCoin,changeGold = updateDataLife(t.reward)
    if changeCoin then
        GameScene:coin_effect(1,540,960,0.5)
    end
    if changeGold then
        GameScene:coin_effect(2,540,960,0.5)
    end
    UIRequest({type = 1001})

    local function tmpDone()
        if gameWindows.windows["clubchance"].show then
            gameWindows.windows["clubchance"].module:reload(t)
        end
    end
    if t.result and t.result ~= -1 then
        RunbattleCallBack("nightclub2", t,tmpDone)
    else
        tmpDone()
    end
end
-----------------------------------------------------------------------------------------

function UserPatrolOneAdd(t)
    print("天庭银座4509,接受客户端数据")
    printT(t)

    GameScene.layers["oneAddclub"].module.selectType = nil
    GameScene.layers["oneAddclub"].module.selectData = nil
    if GameScene.layers["oneAddclub"].show then
        GameScene.layers["oneAddclub"].module:SpecialEventData(t)
    end

    --UIRequest({type = 4511})
    UIRequest({type =1001})

end

function UserPatrolOneAddReward(t)
    print("天庭银座4510,接受客户端数据")
    printT(t)
    GameScene.layers["oneAddclub"].module.rewardData = nil
    GameScene.layers["oneAddclub"].module.rewardStage = nil
    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 4511})
        UIRequest({type =1001})
    end)
 
end

function UserPatrolOneAddQuery(t)
    print("天庭银座4511,接受客户端数据")
    printT(t)
    if GameScene.layers["oneAddclub"].show then
        GameScene.layers["oneAddclub"].module:reloadData(t)
    end
    
end



