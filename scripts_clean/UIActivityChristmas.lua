--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UIActivityChristmasQuery(t)
    print("6601")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[134] then
        GameScene.layers["activity"].module.pageTable[134].module:reloaddata(t.data)
    end

end

function UIActivityChristmasDo(t)
    print("6602")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[134] then
        GameScene.layers["activity"].module.pageTable[134].module:showquestion()
    end  

    showRewardPopupWindow(t.reward, nil,nil)

    GameScene:addUpdate(1200)
    UIRequest({type = 6601})
    UIRequest({type = 1001})

end

function UIActivityChristmasReward(t)
    print("6603")
    printT(t)

    showRewardPopupWindow(t.reward, nil,nil)

    GameScene:addUpdate(1200)
    UIRequest({type = 6601})
    UIRequest({type = 1001})

end

function UIActivityChristmasReward2(t)
    print("6604")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[134] then
        GameScene.layers["activity"].module.pageTable[134].module:showanswer()
    end  

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward, nil,nil)
    end

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})

end


--
--
function UIActivityHolidayQuery(t)
    print("6501")
    printT(t)

    GameScene.holidaynum = t.donum or 0

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:checkholiday(t)
    end 
    
end

function UIActivityHolidayDo(t)
    print("6502")
    printT(t)

    if GameScene.holidaynum then
        GameScene.holidaynum = GameScene.holidaynum+1
    else
        GameScene.holidaynum = 1
    end

    local _cb = function()
        if GameScene.layers["main"].show then
            GameScene.layers["main"].module:checkholiday()
        end 
    end

    if gameWindows.windows["redbag"].show then
        local changeCoin,changeGold = updateDataLife(t.reward)
        if changeCoin then
            GameScene:coin_effect(1,540,960,0.5)
        end
        if changeGold then
            GameScene:coin_effect(2,540,960,0.5)
        end
        --
        gameWindows.windows["redbag"].module:reload(t,_cb)
        --
        --_cb()
    else 
        showRewardPopupWindow(t.reward, nil, _cb)
    end

    GameScene:addUpdate(1200)
    --UIRequest({type = 6501})
    UIRequest({type = 1001})

end


function UIActivityTimebuyQuery(t)
    print("6801")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[135] then
        GameScene.layers["activity"].module.pageTable[135].module:reloaddata(t)
    end
    
end

function UIActivityTimebuyList(t)
    print("6802")
    printT(t)

    if gameWindows.windows["timebuy_list"].show then
        gameWindows.windows["timebuy_list"].module:reload(t)
    end    
    
end

function UIActivityTimebuyReward(t)
    print("6803")
    printT(t)

    if (t.old_gold-t.gold) > 1 then
        runGamePrompt({msg = "折扣已发生改变，本次购买实际消耗"..t.gold.."元宝"})
    end    

    showRewardPopupWindow(t.reward, nil, nil)

    UIRequest({type = 6801})
    UIRequest({type = 1001})
    
end



