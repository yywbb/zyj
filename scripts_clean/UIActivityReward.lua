--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/26
-- Time: 18:39
-- To change this template use File | Settings | File Templates.
--

function UIActivityStartGiftQuery(t)
    print(" 2035 接收客户端返回数据")
    --printT(t)
    if not next(t.showTable) then
        UIRequest({type = 2000, page = 1})
    else
        if GameScene.layers["activity"].module.pageTable[12] then
            -- GameScene.layers["activity"].module.pageTable[12].module:reloaddata(t.status)
            GameScene.layers["activity"].module.pageTable[12].module:reloaddata(t)
        end
    end

end

function UIActivityStartGift(t)
    print(" 2036 接收客户端返回数据")
    --printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 2035, param = "update"})
        UIRequest({type =1001})
    end)

end

--
function UIContinue7Query(t)
    print(" 212 接收客户端返回数据")
    --printT(t)

    if  GameScene.layers["activity"].module.pageTable[13] then
        GameScene.layers["activity"].module.pageTable[13].module:reloaddata(t.status)
    end


end

function UIContinue7Reward(t)
    print(" 213 接收客户端返回数据")
    --printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 212, param = "update"})
        UIRequest({type =1001})
    end)

end

--
function UIContinue7Query1(t)
    print(" 214 接收客户端返回数据")
    if  GameScene.layers["activity"].module.pageTable[132] then
        GameScene.layers["activity"].module.pageTable[132].module:reloaddata(t.status)
    end


end

function UIContinue7Reward1(t)
    print(" 215 接收客户端返回数据")
    --printT(t)
    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 214, param = "update"})
        UIRequest({type =1001})
    end)

end



--
function UIDayDayGift(t)
    print(" 2022 接收客户端返回数据")
    --printT(t)


    if t.time and t.time >0 then
        gameTimer:rigistTime("ActivityDailyreward",t.time)
    end

    if  GameScene.layers["activity"].module.pageTable[14] and GameScene.layers["activity"].module.pageTable[14].module.show then
        GameScene.layers["activity"].module.pageTable[14].module:reloaddata(t)
    end


end

function UIDayDayGiftReward(t)
    print(" 2023 接收客户端返回数据")
    --printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 2022})
        UIRequest({type =1001})
    end)

end

function UIConsumeGift(t)
    print(" 2020 接收客户端返回数据")
    printT(t)
    if t.time and t.time > 0 then
        gameTimer:rigistTime("Activityconsumerreward",t.time)
    end
    if  GameScene.layers["activity"].module.pageTable[15] then
        GameScene.layers["activity"].module.pageTable[15].module:reloaddata(t)
    end


end

function UIConsumeGiftReward(t)
    print(" 2021 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 2020})
        UIRequest({type =1001})
    end)

end

--
function UIRechargeGift(t)
    print(" 2024 接收客户端返回数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[16] and GameScene.layers["activity"].module.pageTable[16].module.show then
        GameScene.layers["activity"].module.pageTable[16].module:reloaddata(t)
    end


end

function UIRechargeGiftReward(t)
    print(" 2025 接收客户端返回数据")
    --printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 2024})
        UIRequest({type = 1001})
    end)

end

--
--
function UIDayDayGiftX1(t)
    print(" 3310 接收客户端返回数据")
    printT(t)


    if t.time and t.time >0 then
        gameTimer:rigistTime("Activitydailyreward_x1",t.time)
    end

    if  GameScene.layers["activity"].module.pageTable[35] and GameScene.layers["activity"].module.pageTable[35].module.show then
        GameScene.layers["activity"].module.pageTable[35].module:reloaddata(t)
    end


end

function UIDayDayGiftX1Reward(t)
    print(" 3311 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 3310})
        UIRequest({type = 1001})
    end)

end

--
function UISingleRechargeGift(t)
    print(" 3750 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[55] and GameScene.layers["activity"].module.pageTable[55].module.show then
        GameScene.layers["activity"].module.pageTable[55].module:reloaddata(t)
    end


end

function UISingleRechargeGiftReward(t)
    print(" 3751 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 3750})
        UIRequest({type = 1001})
    end)

end

--
function UIAchievementLimitTime(t)
    print(" 3760 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[56] and GameScene.layers["activity"].module.pageTable[56].module.show then
        GameScene.layers["activity"].module.pageTable[56].module:reloaddata(t)
    end


end

function UIAchievementLimitTimeReward(t)
    print(" 3761 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 3760})
        UIRequest({type = 1001})
    end)

end

--
function UIVipWelfareExt(t)
    print(" 46111 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[57] and GameScene.layers["activity"].module.pageTable[57].module.show then
        GameScene.layers["activity"].module.pageTable[57].module:reloaddata(t)
    end


end

function UIVipWelfareExchange(t)
    print(" 4611 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)

    if GameScene.layers["activity"].module.pageTable[57] and GameScene.layers["activity"].module.pageTable[57].module.show then
        GameScene.layers["activity"].module.pageTable[57].module:reloaddata(t)
    end

    if gameWindows.windows["vipExchangeBuy"].show then
        gameWindows.windows["vipExchangeBuy"].module:reload({status = 1})
    end

     UIRequest({type = 300, update = true})
end

--

function UITimeGift(t)
    print(" 4615 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[59] and GameScene.layers["activity"].module.pageTable[59].module.show then
        GameScene.layers["activity"].module.pageTable[59].module:reloaddata(t.timegift)
    end

end

function UITimeGiftReward(t)
    print(" 4616 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)

    if GameScene.layers["activity"].module.pageTable[59] and GameScene.layers["activity"].module.pageTable[59].module.show then
        GameScene.layers["activity"].module.pageTable[59].module:reloaddata(t.timegift)
    end

    UIRequest({type = 4615})
end

--

function UITotalRechargeQuery(t)
    print(" 4860 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[68] and GameScene.layers["activity"].module.pageTable[68].module.show then
        GameScene.layers["activity"].module.pageTable[68].module:reloaddata(t)
    end

end

function UITotalRechargeGetReward(t)
    print(" 4861 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)


    UIRequest({type = 4860})
end

function UITotalRechargeQueryX1(t)
    print(" 5701 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[108] and GameScene.layers["activity"].module.pageTable[108].module.show then
        GameScene.layers["activity"].module.pageTable[108].module:reloaddata(t)
    end

end

function UITotalRechargeGetRewardX1(t)
    print(" 5702 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)


    UIRequest({type = 5701})
end

--
function UIRechargeRebate(t)
    print(" 4850 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[69] and GameScene.layers["activity"].module.pageTable[69].module.show then
        GameScene.layers["activity"].module.pageTable[69].module:reloaddata(t)
    end

end

function UIRechargeRebateGet(t)
    print(" 4851 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)

    UIRequest({type = 4850})
end



-- cp
function UICPRechargeGift(t)
    print(" 5000 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[78] and GameScene.layers["activity"].module.pageTable[78].module.show then
        GameScene.layers["activity"].module.pageTable[78].module:reloaddata(t)
    end


end

function UICPRechargeGiftReward(t)
    print(" 5001 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5000})
        UIRequest({type = 1001})
    end)

end

--
--
function UICPDayDayGift(t)
    print(" 5002 接收客户端返回数据")
    printT(t)

    if t.time and t.time >0 then
        gameTimer:rigistTime("ActivityDailyreward",t.time)
    end

    if  GameScene.layers["activity"].module.pageTable[77] and GameScene.layers["activity"].module.pageTable[77].module.show then
        GameScene.layers["activity"].module.pageTable[77].module:reloaddata(t)
    end


end

function UICPDayDayGiftReward(t)
    print(" 5003 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5002})
        UIRequest({type =1001})
    end)

end


--
--
function UICPAchievementLimitTime(t)
    print(" 5025 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[84] and GameScene.layers["activity"].module.pageTable[84].module.show then
        GameScene.layers["activity"].module.pageTable[84].module:reloaddata(t)
    end


end

function UICPAchievementLimitTimeReward(t)
    print(" 5026 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5025})
        UIRequest({type = 1001})
    end)

end


--cp
function UICPContinue7Query(t)
    print(" 5046 接收客户端返回数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[89] then
        GameScene.layers["activity"].module.pageTable[89].module:reloaddata(t)
    end


end

function UICPContinue7Reward(t)
    print(" 5047 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5046, param = "update"})
        UIRequest({type =1001})
    end)

end


--
function UICPConsumeGift(t)
    print(" 5039 接收客户端返回数据")
    printT(t)
    if t.time and t.time > 0 then
        gameTimer:rigistTime("Activityconsumerreward",t.time)
    end
    if  GameScene.layers["activity"].module.pageTable[91] then
        GameScene.layers["activity"].module.pageTable[91].module:reloaddata(t)
    end


end

function UICPConsumeGiftReward(t)
    print(" 5040 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5039})
        UIRequest({type =1001})
    end)

end

--
--
function UICPRechargeRebate(t)
    print(" 5041 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[92] and GameScene.layers["activity"].module.pageTable[92].module.show then
        GameScene.layers["activity"].module.pageTable[92].module:reloaddata(t)
    end

end

function UICPRechargeRebateGet(t)
    print(" 5042 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)

    UIRequest({type = 5041})
end

--
--
function UICPSingleRechargeGift(t)
    print(" 5050 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[94] and GameScene.layers["activity"].module.pageTable[94].module.show then
        GameScene.layers["activity"].module.pageTable[94].module:reloaddata(t)
    end


end

function UICPSingleRechargeGiftReward(t)
    print(" 5051 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5050})
        UIRequest({type = 1001})
    end)

end

--
function UICPTotalRechargeQuery(t)
    print(" 5055 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[96] and GameScene.layers["activity"].module.pageTable[96].module.show then
        GameScene.layers["activity"].module.pageTable[96].module:reloaddata(t)
    end

end

function UICPTotalRechargeGetReward(t)
    print(" 5056 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)


    UIRequest({type = 5055})
end

--
--
function UIWeekGift(t)
    print(" 5525 接收客户端返回数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[116] and GameScene.layers["activity"].module.pageTable[116].module.show then
        GameScene.layers["activity"].module.pageTable[116].module:reloaddata(t)
    end


end

function UIWeekGiftReward(t)
    print(" 5526 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,nil)

    UIRequest({type = 5525})
    UIRequest({type = 1001})    

end

function UINewRankQuery(t)
    print(" 6117 接收客户端返回数据")
    printT(t)
    UIRequest({type = 1001})
end


--
function UISingleRechargeGiftX1(t)
    print(" 3755 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[130] and GameScene.layers["activity"].module.pageTable[130].module.show then
        GameScene.layers["activity"].module.pageTable[130].module:reloaddata(t)
    end


end

function UISingleRechargeGiftRewardX1(t)
    print(" 3756 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 3755})
        UIRequest({type = 1001})
    end)

end


function UISingleRechargeGiftX2(t)
    print(" 3758 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[141] and GameScene.layers["activity"].module.pageTable[141].module.show then
        GameScene.layers["activity"].module.pageTable[141].module:reloaddata(t)
    end


end

function UISingleRechargeGiftRewardX2(t)
    print(" 3759 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 3758})
        UIRequest({type = 1001})
    end)

end

--
function UICPSingleRechargeGiftX1(t)
    print(" 5060 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[131] and GameScene.layers["activity"].module.pageTable[131].module.show then
        GameScene.layers["activity"].module.pageTable[131].module:reloaddata(t)
    end


end

function UICPSingleRechargeGiftRewardX1(t)
    print(" 5061 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5060})
        UIRequest({type = 1001})
    end)

end

function UISingleRechargeGift_X2(t)
    print(" 5062 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[209] and GameScene.layers["activity"].module.pageTable[209].module.show then
        GameScene.layers["activity"].module.pageTable[209].module:reloaddata(t)
    end


end

function UISingleRechargeGiftReward_X2(t)
    print(" 5063 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5062})
        UIRequest({type = 1001})
    end)

end

