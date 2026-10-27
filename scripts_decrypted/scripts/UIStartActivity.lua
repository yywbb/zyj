--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/12
-- Time: 14:22
-- To change this template use File | Settings | File Templates.
--

-- 海外版未开功能：十一活动，老玩家回归

function UIBegin7DaysExt(t)
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has ==1,"startactivitynode")
    end
end

function UIBegin7Days(t)
    print("3610，接受客户端数据")
    printT(t)

    if GameScene.layers["startactivity"].show then
        GameScene.layers["startactivity"].module:ReloadData(t.data)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.data["0"]["1"] <11,"startactivitynode")
    end
    if t.data["0"]["1"] >= 11 then
        if not GameScene.openactivityinpost then
            GameScene.openactivityinpost = {}
            GameScene.openactivityinpost[tostring(82)] = 0
        else
            GameScene.openactivityinpost[tostring(82)] = 0
        end
        
    end 
end

function UIBegin7DaysReward(t)
    print("3611，接受客户端数据")
    printT(t)

    local cb = function()
        if GameScene.layers["startactivity"].show then
            GameScene.layers["startactivity"].module:request()
        end
    end

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    elseif t.xgold > 0 then
        runGamePrompt({msg = "当前折扣已变更，请重新购买"})
        cb()
    end

    UIRequest({type =1001})

end

--
function UIOctober1stExt(t)
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has == 1,"october1stnode")
    end
end

function UIOctober1st(t)
    print("3765，接受客户端数据")
    printT(t)

    if t.data["0"]["2"] and t.data["0"]["2"] == 1 then
        GameScene.layers["october1st"].module:setShowType(7)
    else
        GameScene.layers["october1st"].module:setShowType(4)
    end

    if GameScene.layers["october1st"].show then
        GameScene.layers["october1st"].module:ReloadData(t.data)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.data["0"]["1"] > 0,"october1stnode")
    end

    if t.data["0"]["1"] < 1 then
        if not GameScene.openactivityinpost then
            GameScene.openactivityinpost = {}
            GameScene.openactivityinpost[tostring(217)] = 0
        else
            GameScene.openactivityinpost[tostring(217)] = 0
        end

    end
end

function UIOctober1stReward(t)
    print("3766，接受客户端数据")
    printT(t)

    local cb = function()
        if GameScene.layers["october1st"].show then
            GameScene.layers["october1st"].module:request()
        end
    end

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    end

    UIRequest({type =1001})

end

--
function UIReturnExt(t)
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has == 1,"playerreturnnode")
    end
end

function UIReturn(t)
    print("3772，接受客户端数据")
    printT(t)

    local timelimit = 0
    if gamedata.config.global_kv.player_comeback_timelimit then
        timelimit = tonumber(gamedata.config.global_kv.player_comeback_timelimit.value)
    end

    if GameScene.layers["playerreturn"].show then
        GameScene.layers["playerreturn"].module:ReloadData(t.playerreturn)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode((t.playerreturn.playertype > 0) and (t.playerreturn.loginday <= timelimit),"playerreturnnode")
    end

    if (t.playerreturn.playertype < 1) or (t.playerreturn.loginday > 15) then
        if not GameScene.openactivityinpost then
            GameScene.openactivityinpost = {}
            GameScene.openactivityinpost[tostring(247)] = 0
        else
            GameScene.openactivityinpost[tostring(247)] = 0
        end

    end
end

function UIReturnReward(t)
    print("3773，接受客户端数据")
    printT(t)

    local cb = function()
        if GameScene.layers["playerreturn"].show then
            GameScene.layers["playerreturn"].module:request()
        end
    end

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    end

    UIRequest({type =1001})

end

function UIReturnCDK(t)
    print("3774,接受客户端数据")
    printT(t)

    if t.result == 0 then
        runGamePrompt({msg = "操作失败，请重新输入"})
    else
        if gameWindows.windows["playerreturncdk"].show then
            gameWindows:closeWindowDirect("playerreturncdk")
        end
        runGamePrompt({msg = "成功接受召回"})
        UIRequest({type = 3772, update = true})
    end

end


--
--
--
function UISevenDayActivityExt(t)
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has == 1,"sevendayactivitynode")
    end
end

function UISevenDayActivity(t)
    print("4880，接受客户端数据")
    printT(t)

    if GameScene.layers["sevendayactivity"].show then
        GameScene.layers["sevendayactivity"].module:ReloadData(t.data)
    end

    if t.data["0"]["1"] < 1 then
        if not GameScene.openactivityinpost then
            GameScene.openactivityinpost = {}
            GameScene.openactivityinpost[tostring(275)] = 0
        else
            GameScene.openactivityinpost[tostring(275)] = 0
        end
    else
        GameScene.SevenDayType = 1
        if t.data["0"]["2"] and t.data["0"]["2"] >= 3 then
            GameScene.SevenDayType2 = 2
        end    
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.data["0"]["1"] > 0,"sevendayactivitynode")
    end
end

function UISevenDayActivityReward(t)
    print("4881，接受客户端数据")
    printT(t)

    local cb = function()
        if GameScene.layers["sevendayactivity"].show then
            GameScene.layers["sevendayactivity"].module:request()
        end
    end

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    end

    UIRequest({type =1001})

end


--
--cp
--
--
function UICPSevenDayActivityExt(t)
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has == 1,"sevendayactivitynode")
    end
end

function UICPSevenDayActivity(t)
    print("5048，接受客户端数据")
    printT(t)

    if GameScene.layers["sevendayactivity"].show then
        GameScene.layers["sevendayactivity"].module:ReloadData(t.data)
    end

    if t.data["0"]["1"] < 1 then
        if not GameScene.openactivityinpost then
            GameScene.openactivityinpost = {}
            GameScene.openactivityinpost[tostring(326)] = 0
        else
            GameScene.openactivityinpost[tostring(326)] = 0
        end
        --
        if gameConfig:checkBuildOpen(275) then
            UIRequest({type = 4880})            --todo
        end
    else
        GameScene.SevenDayType = 2
        if t.data["0"]["2"] and t.data["0"]["2"] >= 5 then
            GameScene.SevenDayType2 = 3
        end    
    end

    --
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.data["0"]["1"] > 0,"sevendayactivitynode")
    end

end

function UICPSevenDayActivityReward(t)
    print("5049，接受客户端数据")
    printT(t)

    local cb = function()
        if GameScene.layers["sevendayactivity"].show then
            GameScene.layers["sevendayactivity"].module:request()
        end
    end

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    end

    UIRequest({type =1001})

end


-- cp 缔造神话
function UICPDiZaoShenHuaActivityExt(t)
    printT(t,"48861 接受客户端数据")
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has == 1,"cp_dizaoshenhuanode")
    end
end

function UICPDiZaoShenHuaActivity(t)
    print("4886，接受客户端数据")
    printT(t)

    if GameScene.layers["cp_dizaoshenhua"].show then
        GameScene.layers["cp_dizaoshenhua"].module:ReloadData(t.data)
    end
    --
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.data["0"]["1"] > 0,"cp_dizaoshenhuanode")
    end

end

function UICPDiZaoShenHuaActivityReward(t)
    print("4887，接受客户端数据")
    printT(t)

    local cb = function()
        if GameScene.layers["cp_dizaoshenhua"].show then
            GameScene.layers["cp_dizaoshenhua"].module:request()
        end
    end

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    end

    UIRequest({type =1001})

end



-- cp 天下无双
function UICPTianXiaWuShuangActivityExt(t)
    printT(t,"48881 接受客户端数据")
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has == 1,"cp_tianxiawushuangnode")
    end
end

function UICPTianXiaWuShuangActivity(t)
    print("4888，接受客户端数据")
    printT(t)

    if GameScene.layers["cp_tianxiawushuang"].show then
        GameScene.layers["cp_tianxiawushuang"].module:ReloadData(t.data)
    end
    --
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.data["0"]["1"] > 0,"cp_tianxiawushuangnode")
    end

end

function UICPTianXiaWuShuangActivityReward(t)
    print("4889，接受客户端数据")
    printT(t)

    local cb = function()
        if GameScene.layers["cp_tianxiawushuang"].show then
            GameScene.layers["cp_tianxiawushuang"].module:request()
        end
    end

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    end

    UIRequest({type =1001})

end

 -- 中秋
function UIZhongQiuActivity(t)
    print("6401，接受客户端数据")

    if GameScene.layers["zhongqiuactivity"].show then
        GameScene.layers["zhongqiuactivity"].module:ReloadData(t.data)
    end

    --
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.data["0"]["1"] > 0,"zhongqiuactivitynode")
    end

end

function UIZhongQiuActivityReward(t)
    print("6402，接受客户端数据")
    printT(t)

    local cb = function()
        if GameScene.layers["zhongqiuactivity"].show then
            GameScene.layers["zhongqiuactivity"].module:request()
        end
    end

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,cb)
    end

    UIRequest({type =1001})
end

function UIZhongQIuActivityExt(t)
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.has == 1,"zhongqiuactivitynode")
    end
end


function UIPlayerBackTips(t)
    print("6810，接受客户端数据")
    printT(t)

    if t.param and t.param == "main" then
        if t.status and t.status > 0 then
            gameWindows:openWindow("playerback_tip",t,function()
                GameScene:runMainTip()
            end)
        else
            GameScene:runMainTip()        
        end
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setNode(t.activity == 1,"playerbacknode")
    end

end


function UIPlayerBackQuery(t)
    print("6811，接受客户端数据")
    printT(t)

    if t.playerback and t.playerback.time and t.playerback.time > 0 then
        gameTimer:rigistTime("playerbackend",t.playerback.time+1)
    end    

    if gameWindows.windows["playerback"].show then
        gameWindows.windows["playerback"].module:reload(t)
    end

end

function UIPlayerBackReward(t)
    print("6812，接受客户端数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward,nil,nil)
    end

    UIRequest({type = 1001})
    UIRequest({type = 6811})
end

  �-  