--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/11/18
-- Time: 11:14
-- To change this template use File | Settings | File Templates.
--

function UITriggerGiftQuery(t)
    print("4800 接收客户端返回数据")
    printT(t)

    if t.triggergift and next(t.triggergift) then
        for k, v in pairs(t.triggergift) do
            if v.time and v.time > 0 then
                gameTimer:rigistTime("triggergift"..v.iid,v.time+1)
            end
        end
    end

    GameScene.layers["shopList"].module:ReloadTriggerGiftData(t.triggergift)
    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:ReloadGiftData()
    end

    if t.pushiid and t.pushiid > 0 and t.triggergift and t.triggergift[tostring(t.pushiid)] then
        if guide.controller == nil or next(guide.controller) ==nil or not guide.controller.isOnGuide then

            if GameScene.layers["shopList"].show and gameWindows.windows["getStaff"].show then
                gameWindows.windows["getStaff"].module.callback = function ()
                    gameWindows:openWindow("triggerGift",table.copy(t.triggergift[tostring(t.pushiid)]),nil)
                end
            else
                gameWindows:openWindow("triggerGift",table.copy(t.triggergift[tostring(t.pushiid)]),nil)
            end
        end
    end

end

function UITriggerGiftReward(t)
    print("4801 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)

    if t.iid and t.iid > 0 and gameTimer.times["triggergift"..t.iid] then
        gameTimer:UnrigistTimeFunc("triggergift"..t.iid)
    end

    UIRequest({type = 1001})
    UIRequest({type = 4800})

    if GameScene.layers["soul"].show then
        UIRequest({type = 2501})
    end


end

function UITriggerGiftPush(t)
    print("4802 接收客户端返回数据")
    printT(t)

    addTriggerGift(t)

--    if t.triggergiftpush and t.triggergiftpush.iid and t.triggergiftpush.iid > 0 then
--        UIRequest({type = 4800, pushiid = t.triggergiftpush.iid})
--    end

end