--
-- Author: yxf
-- Date: 2019-03-21 11:16:04
--

---------------------------特惠礼包1--------------------------
function UIDiscountGiftQuery(t)
    printT(t,"8020 特惠礼包1查询")

    if GameScene.layers["activity"].module.pageTable[150] then
         GameScene.layers["activity"].module.pageTable[150].module:reloaddata(t)
    end
end


function UIDiscountGiftReward(t)
    printT(t,"8021 特惠礼1包领取")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 8020})
        UIRequest({type = 1001})
    end)
end

---------------------------特惠礼包2--------------------------


function UIDiscountGiftQuery2(t)
    printT(t,"8022 特惠礼包2查询")

    if GameScene.layers["activity"].module.pageTable[151] then
         GameScene.layers["activity"].module.pageTable[151].module:reloaddata(t)
    end
end


function UIDiscountGiftReward2(t)
    printT(t,"8023 特惠礼2包领取")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 8022})
        UIRequest({type = 1001})
    end)
end


---------------------------特惠礼包3--------------------------


function UIDiscountGiftQuery3(t)
    printT(t,"8024 特惠礼包3查询")

    if GameScene.layers["activity"].module.pageTable[152] then
         GameScene.layers["activity"].module.pageTable[152].module:reloaddata(t)
    end
end


function UIDiscountGiftReward3(t)
    printT(t,"8025 特惠礼3包领取")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 8024})
        UIRequest({type = 1001})
    end)
end


---------------------------加速礼包1--------------------------
function UISpeedGiftQuery(t)
    printT(t,"8026 加速礼包1查询")

    t.activityId = 153
    if t.requireType and t.requireType == "main" then
        gameWindows:openWindow("speedGiftPost",t,function ( )
            GameScene:runMainTip()
        end)
    else
        if GameScene.layers["activity"].module.pageTable[153] then
             GameScene.layers["activity"].module.pageTable[153].module:reloaddata(t)
        end
    end


    
end


function UISpeedGiftReward(t)
    printT(t,"8027 加速礼1包领取")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 8026})
        UIRequest({type = 1001})
    end)
end


---------------------------加速礼包2--------------------------
function UISpeedGiftQuery2(t)
    printT(t,"8028 加速礼包2查询")

    t.activityId = 154
    if t.requireType and t.requireType == "main" then
        gameWindows:openWindow("speedGiftPost",t,function ( )
            GameScene:runMainTip()
        end)
    else
        if GameScene.layers["activity"].module.pageTable[154] then
             GameScene.layers["activity"].module.pageTable[154].module:reloaddata(t)
        end
    end
end


function UISpeedGiftReward2(t)
    printT(t,"8029 加速礼2包领取")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 8028})
        UIRequest({type = 1001})
    end)
end


---------------------------加速礼包3--------------------------
function UISpeedGiftQuery3(t)
    printT(t,"8032 加速礼包3查询")

    t.activityId = 155
    if t.requireType and t.requireType == "main" then
        gameWindows:openWindow("speedGiftPost",t,function ( )
            GameScene:runMainTip()
        end)
    else
        if GameScene.layers["activity"].module.pageTable[155] then
             GameScene.layers["activity"].module.pageTable[155].module:reloaddata(t)
        end
    end
end


function UISpeedGiftReward3(t)
    printT(t,"8033 加速礼3包领取")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 8032})
        UIRequest({type = 1001})
    end)
end

---------------------------合服礼包--------------------------
function UIhefuGiftQuery(t)
    printT(t,"8045 合服礼包查询")

    if GameScene.layers["activity"].module.pageTable[165] then
         GameScene.layers["activity"].module.pageTable[165].module:reloaddata(t)
    end
end


function UIhefuGiftReward(t)
    printT(t,"8046 合服礼包领取")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 8045})
        UIRequest({type = 1001})
    end)
end


