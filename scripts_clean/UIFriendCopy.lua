--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-17
-- Time: 下午3:07
-- To change this template use File | Settings | File Templates.
--

--function UIFriendCopyQuery(t)
--    print("请求好友副本1320 接收客户端返回数据")
--    printT(t)
--
--    if GameScene.layers["friendcopy"].show then
--        GameScene.layers["friendcopy"].module:reloadList(t)
--    end
--
--end
--
--function UIFriendCopyAttack(t)
--    print("攻打好友副本1321 接收客户端返回数据")
--    printT(t)
--
--    RunbattleCallBack("friendcopy", t, nil)
--
--    GameScene:addUpdate(1200)
--    UIRequest({type = 1320})
--    UIRequest({type = 12001, order = 13201, cids ={20048,20049,20050}})
--    UIRequest({type = 1001})
--end

function UIFriendCopyQuery(t)
    print("请求好友副本1323 接收客户端返回数据")
    printT(t)

    if GameScene.layers["friendcopy"].show then
        GameScene.layers["friendcopy"].module:reloadList(t)
    end

end

function UIFriendCopyAttack(t)
    print("攻打好友副本1324 接收客户端返回数据")
    printT(t)
    local datatmp = ui.CheckHuodongByParam(7)
    -- local datatmp = ui.CheckHuodongByParam(1)
    if datatmp and t.reward and next(t.reward) then
        GameScene.isrewarddouble = datatmp
    end

    if t.battlereport2 and t.battlereport2 ~= "" then
        t.battlereport = MergeBattleReportForFriendCopy(t.battlereport1,t.battlereport2)
    else
        t.battlereport = t.battlereport1
    end

    local callBackFunc = function()
        UIRequest({type = 1323})
        UIRequest({type = 1001})        
    end
    RunbattleCallBack("friendcopy", t, callBackFunc)
end


function UIFriendCopyFriendSelect(t)
    print("请求助战选择13201 接收客户端返回数据")
    --printT(t)

    if next(t.data) then
        gameWindows:openWindow("friendcopy",{type = "select",data = t},nil)
    else
        runGamePrompt({msg = "无好友可助阵"})
    end
end


function UIFriendCopyRank(t)
    print("请求好友副本排行1322 接收客户端返回数据")
    --printT(t)

    if t.friendcopyrank then
        gameWindows:openWindow("friendcopyrank",t.friendcopyrank,nil)
    end
end

function UIFriendCopyOneFinish(t)
    print("1325 接收客户端返回数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward)
    end        
    UIRequest({type = 1323})     

end
