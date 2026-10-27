--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/10
-- Time: 下午3:51
-- To change this template use File | Settings | File Templates.
--

function UILiveness(t)
    print("活跃度2410 接受客户端数据")
    --printT(t)

    if GameScene.layers["task"].show then
        GameScene.layers["task"].module:reloadDaily(t.liveness)
    end
end

function UILivenessReward(t)
    print("活跃度2411 接受客户端数据")
    printT(t)
    local datatmp = ui.CheckHuodongByParam(1)
    -- local datatmp = ui.CheckHuodongByParam(1)
    if datatmp and t.reward and next(t.reward) then
        -- t.isrewarddouble = datatmp
        GameScene.isrewarddouble = datatmp
    end

    
    showRewardPopupWindow(t.reward,nil,function()
        if GameScene.layers["task"].show then
            GameScene.layers["task"].module:reloadDaily(t.liveness)
        end
        UIRequest({type = 2410})
        UIRequest({type = 6517})
    end)
    UIRequest({type = 1001})
end

function UITotalLiveness(t)
    print("本周活跃度6517 接受客户端数据")
    --printT(t)

    if GameScene.layers["task"].show then
        GameScene.layers["task"].module:reloadWeekDaily(t)
    end
end

function UIWeekLiveness2(t)
    print("本周活跃度6530 接受客户端数据")
    printT(t)

   local cb = function()
        if GameScene.layers["task"].show then
               UIRequest({type = 6517})
        end
       
    end

    showRewardPopupWindow(t.reward,nil,cb)

    -- if GameScene.layers["task"].show then
    --     GameScene.layers["task"].module:reloadWeekDaily(t)
    -- end
    UIRequest({type = 1001})
end