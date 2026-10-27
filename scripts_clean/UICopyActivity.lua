--zhangzhixin
--选关活动界面UI请求

-- 活动副本一键完成功能，海外版未开

function UIActivityCopy(t)
    print("活动副本查询1340 接受客户端数据")
    printT(t)

    GameScene.layers["copy_chapter"].module.activitydata =  t.data
    if  GameScene.layers["copy_chapter"].show then
        GameScene.layers["copy_chapter"].module:reloadactivityData(t.data)
    end

    if gameWindows.windows["activityCopySelect"].show then
        gameWindows.windows["activityCopySelect"].module:reload(t.data)
    end
    
    if t.temptype and t.temptype == "coin" then
        if gameWindows.windows["copyacivity"].show then
            for k,v in pairs(t.data) do
                if v.aid == 2 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end
    elseif t.temptype and t.temptype == "exp" then
        if gameWindows.windows["copyacivity"].show then
            for k,v in pairs(t.data) do
                if v.aid == 1 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end
    elseif t.temptype and t.temptype == "stone" then
        if gameWindows.windows["copyacivity"].show then
            for k,v in pairs(t.data) do
                if v.aid == 3 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end
    elseif t.temptype and t.temptype == "equipstar" then
        if gameWindows.windows["copyacivity"].show then
            for k,v in pairs(t.data) do
                if v.aid == 4 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end
    elseif t.temptype and t.temptype == "zhenfu" then
        if gameWindows.windows["copyacivity"].show then
            for k,v in pairs(t.data) do
                if v.aid == 5 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end
    elseif t.temptype and t.temptype == "forging" then
        if gameWindows.windows["copyacivity"].show then
            for k,v in pairs(t.data) do
                if v.aid == 6 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end
    end
    
end

function UIActivityCoinCopy(t)
    print("银币副本挑战1341 接受客户端数据")
    -- printT(t)
    local datatmp = ui.CheckHuodongByParam(6)
    -- local datatmp = ui.CheckHuodongByParam(1)

    if datatmp and t.reward and next(t.reward) then
        GameScene.isrewarddouble = datatmp
    end

    local callBackFunc = function()
        if  GameScene.layers["copy_chapter"].show  then
            GameScene.layers["copy_chapter"].module:battleCoinData(t.data)
        end

        if gameWindows.windows["copyacivity"].show   then
            for k,v in pairs(t.data) do
                if v.aid == 2 then
                    gameWindows.windows["copyacivity"].module:activityReload(v,t.pass)
                    break
                end
            end
        end     
         UIRequest({type = 1001})
    end
    RunbattleCallBack("activitycopyboss", t,callBackFunc)
    
end

function UIActivityExpDanCopy(t)
    print("经验丹副本挑战1342 接受客户端数据")
    -- printT(t)
    local datatmp = ui.CheckHuodongByParam(6)
    -- local datatmp = ui.CheckHuodongByParam(1)
    if datatmp and t.reward and next(t.reward) then
        GameScene.isrewarddouble = datatmp
    end

    local callBackFunc = function()
        if  GameScene.layers["copy_chapter"].show  then
            GameScene.layers["copy_chapter"].module:battleExpData(t.data)
        end    
        if gameWindows.windows["copyacivity"].show then
            for k,v in pairs(t.data) do
                if v.aid == 1 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end      
    end
    RunbattleCallBack("activitycopy", t,callBackFunc)
end

function UIActivityForgeStoneCopy(t)
    print("银币副本挑战1343 接受客户端数据")
    printT(t)
    local callBackFunc = function()
        if  GameScene.layers["copy_chapter"].show  then
            GameScene.layers["copy_chapter"].module:battleStoneData(t.data)
        end

        if gameWindows.windows["copyacivity"].show   then
            for k,v in pairs(t.data) do
                if v.aid == 3 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end     
    end
    RunbattleCallBack("activitycopy", t,callBackFunc)

end

function UIActivityEquipStarCopy(t)
    print("挑战1344 接受客户端数据")
    printT(t)
    local callBackFunc = function()
        if  GameScene.layers["copy_chapter"].show  then
            GameScene.layers["copy_chapter"].module:battleEquipStarData(t.data)
        end

        if gameWindows.windows["copyacivity"].show   then
            for k,v in pairs(t.data) do
                if v.aid == 4 then
                    gameWindows.windows["copyacivity"].module:activityReload(v,t.pass)
                    break
                end
            end
        end
    end
    RunbattleCallBack("activitycopyboss", t,callBackFunc)

end

function UIActivityZhenfuCopy(t)
    print("挑战1345 接受客户端数据")
    printT(t)
    local callBackFunc = function()
        if  GameScene.layers["copy_chapter"].show  then
            GameScene.layers["copy_chapter"].module:battleZhenfuData(t.data)
        end

        if gameWindows.windows["copyacivity"].show   then
            for k,v in pairs(t.data) do
                if v.aid == 5 then
                    gameWindows.windows["copyacivity"].module:activityReload(v,t.pass)
                    break
                end
            end
        end
    end
    RunbattleCallBack("activitycopyboss", t,callBackFunc)

end

function UIActivityForgingCopy(t)
    print("挑战1347 接受客户端数据")
    printT(t)
    local callBackFunc = function()
        if  GameScene.layers["copy_chapter"].show  then
            GameScene.layers["copy_chapter"].module:battleForgingData(t.data)
        end

        if gameWindows.windows["copyacivity"].show   then
            for k,v in pairs(t.data) do
                if v.aid == 6 then
                    gameWindows.windows["copyacivity"].module:activityReload(v)
                    break
                end
            end
        end
    end
    RunbattleCallBack("activitycopy", t,callBackFunc)

end

function UIActivityCopyModUp(t)
    print("1346 接收客户端返回数据")

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    local temp = nil

    if t.aid and t.aid == 1 then
        temp = "exp"
    elseif t.aid and t.aid == 2 then
        temp = "coin"
    elseif t.aid and t.aid == 3 then
        temp = "stone"
    elseif t.aid and t.aid == 4 then
        temp = "equipstar"
    elseif t.aid and t.aid == 5 then
        temp = "zhenfu"
    elseif t.aid and t.aid == 6 then
        temp = "forging"
    end

    UIRequest({type = 1340, temp = temp})

end




function UIActivityOneFinshCopy(t)
    print("1348 接收客户端返回数据")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1340})
        UIRequest({type = 1001})
    else
        runGamePrompt({msg = "当前不能一键完成"})
    end

end