
function UIAscensionSendaiMapQuery(t)
    print("8851, 接受客户端数据")
    printT(t)

    if GameScene.layers["ascensionSendai"].show then
        GameScene.layers["ascensionSendai"].module:reloadData(t)
    end
end

function UIAscensionSendaiMapSelect(t)
    print("8852, 接受客户端数据")
    printT(t)

    if GameScene.layers["ascensionSendai"].show then
        GameScene.layers["ascensionSendai"].module:clearSelect()
        GameScene.layers["ascensionSendai"].module:gotoSendaiSlot()
    end
end

function UIAscensionSendaiRunPoint(t)
    print("8853, 接受客户端数据")
    printT(t)

    if GameScene.layers["ascensionSendai"].show then
        GameScene.layers["ascensionSendai"].module:updataPointState(t.eventdata)
    end

    if t.event.type == "adventure" then       --随机事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_secondary(t)
        end
    elseif t.event.type == "buy" then         --购买事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_openShop(t)
        end
    elseif t.event.type == "buff" then        --仙术事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_selectBuff(t)
        end
    elseif t.event.type == "cheer" then       --协助事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_selectCheer(t)
        end
    elseif t.event.type == "encounter" then   --仙遇事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_encounter(t)
        end
    elseif t.event.type == "recover" then     --恢复事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_recover(t)
        end
    elseif t.event.type == "revive" then      --复活事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_revive(t)
        end
    elseif t.event.type == "battle" or t.event.type == "battle1" then      --战斗事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_battle(t)
        end
    elseif t.event.type == "boss" then        --BOSS战斗事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:adventure_event_boss(t)
        end
    elseif t.event.type == "reward" then      --奖励事件
        if t.eventdata.rewards and next(t.eventdata.rewards) then
            showRewardPopupWindow(t.eventdata.rewards,nil,nil)
            UIRequest({type = 8851})
        else
            runGamePrompt({msg = "当前事件已完成"})
        end
    end
end

function UIAscensionSendaiEventSet(t)
    print("8854, 接受客户端数据")
    printT(t)

    if t.event.type == "buy" then             --购买事件
        runGamePrompt({msg = "恭喜获得仙术加持"})
        UIRequest({type = 8851})
    elseif t.event.type == "buff" then        --仙术事件
        runGamePrompt({msg = "恭喜获得仙术加持"})
        UIRequest({type = 8851})
    elseif t.event.type == "cheer" then       --协助事件
        runGamePrompt({msg = "恭喜获得仙人助阵"})
        UIRequest({type = 8851})
    elseif t.event.type == "encounter" then   --仙遇事件
        showRewardPopupWindow(t.eventdata.rewards,nil,nil)
        UIRequest({type = 8851})
    elseif t.event.type == "recover" then     --恢复事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:secondary_event_recover(t)
            UIRequest({type = 8851})
        end
    elseif t.event.type == "revive" then      --复活事件
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module:secondary_event_revive(t)
            UIRequest({type = 8851})
        end
    elseif t.event.type == "battle" or t.event.type == "battle1" then      --战斗事件
        local battleCallBack = function()
            GameScene:shiftLayer("ascensionSendai", nil, {eventId = t.eventdata.eventId})
        end
        RunbattleCallBack("sendaiBattle", t.eventdata, battleCallBack)
    elseif t.event.type == "boss" then        --BOSS战斗事件
        local battleCallBack = function()
            GameScene:shiftLayer("ascensionSendai", nil, {bossResult = t.eventdata.result})
        end
        RunbattleCallBack("sendaiBattle", t.eventdata, battleCallBack)
    end

end

function UIAscensionSendaiBufferQuery(t)
    print("8855, 接受客户端数据")
    printT(t)

    if gameWindows.windows["ascension_xianshu"].show then
        gameWindows.windows["ascension_xianshu"].module:reloadData(t)
    end
    
end

function UIAscensionSendaiShop(t)
    print("8856, 接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        GameScene.layers["activity"].module.pageTable[162].module:reloadData(t)
    end
end

function UIAscensionSendaiShopBuy(t)
    print("8857, 接受客户端数据")
    printT(t)
    
    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,nil)
    end
    UIRequest({type = 8856})
    UIRequest({type = 1001})
end

function UIAscensionSendaiSlotGeneralsUp(t)
    print("8858, 接受客户端数据")
    printT(t.sendaiGenerals)
    
    gameTouch:clickprofbytime(0.5)
    runGamePrompt({msg = "阵容上传成功"})
    if GameScene.layers["ascensionSendaiSlot"].show then
        GameScene.layers["ascensionSendaiSlot"].module:reloadData(t)
    end
end

function UIAscensionSendaiSlotGeneralsQuery(t)
    print("8859, 接受客户端数据")
    printT(t.sendaiGenerals)
    printT(t.enemyData)

    if GameScene.layers["ascensionSendaiSlot"].show then
        GameScene.layers["ascensionSendaiSlot"].module:reloadData(t)
    end
    
    if GameScene.layers["ascensionSendaiSlot2"].show then
        GameScene.layers["ascensionSendaiSlot2"].module:reloadData(t)
    end

    if gameWindows.windows["sendai_allType"].show then
        gameWindows.windows["sendai_allType"].module:reloadData(t.sendaiGenerals)
    end
end

function UIAscensionSendaiSlotGeneralsChange(t)
    print("88591, 接受客户端数据")
    printT(t.sendaiGenerals)

    if GameScene.layers["ascensionSendaiSlot"].show then
        GameScene.layers["ascensionSendaiSlot"].module:reloadData(t)
    end

    if GameScene.layers["ascensionSendaiSlot2"].show then
        GameScene.layers["ascensionSendaiSlot2"].module:reloadData(t)
    end
end

function UIAscensionSendaiSlotMonsterQuery(t)
    print("8860, 接受客户端数据")
    printT(t)

    if gameWindows.windows["sendai_battle"].show then
        gameWindows.windows["sendai_battle"].module:reloadData(t)
    end
end