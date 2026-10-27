local _activityId = 110

function UIActivityAuctionQuery(t)
    print("5410，接受客户端数据")
    printT(t)

    if t.isUpdata and t.isUpdata == 1 then
        GameScene:addUpdate(1200)
    end

    if gameWindows.windows["activityAuctionChooseAntique"].show then
        gameWindows:closeWindow("activityAuctionChooseAntique")
    end

    -- if GameScene.layers["activity"].module.pageTable[_activityId] and GameScene.layers["activity"].module.pageTable[_activityId].module.show then
    --     GameScene.layers["activity"].module.pageTable[_activityId].module:reloadData(t)
    -- end

    if GameScene.layers["antiqueAuction"].show then
        GameScene.layers["antiqueAuction"].module:reloadData(t)
    end

end

function UIActivityAuctionClinch(t)
    print("5411，接受客户端数据")
    printT(t)
    
    UIRequest({type = 1001})

    local _cb2 = function()
        UIRequest({type = 5410})
    end

    local _cb3 = function()
        showRewardPopupWindow(t.reward2, nil, _cb2)
    end

    local _cb = function()
        gameTouch:setClickProf(false)

        if t.isSpecial == 1 then
            if t.npcId ~= 0 then
                gameWindows:openWindow("activityAuctionSpecialReward", {npcId = t.npcId, cid = t.reward1["1"].cid, price = t.reward1["1"].num}, _cb3)
            else
                _cb3()
            end
        else
            UIRequest({type = 5410})
        end
    end

    -- local _isShow = GameScene.layers["activity"].module.pageTable[_activityId] and 
    --                 GameScene.layers["activity"].module.pageTable[_activityId].module.show and
    --                 GameScene.layers["activity"].module.realPageTable[GameScene.layers["activity"].module.presentPage].id == _activityId

    local _isShow = GameScene.layers["antiqueAuction"].show

    if t.npcId ~= 0 then
        if _isShow then
            UIRequest({type = 5414})
            showRewardPopupWindow(t.reward1, nil, _cb)
        else
            
        end
    else
        if not _isShow then
            UIRequest({type = 5414})

            if GameScene.antiqueResultType == 1000 then
                GameScene:coin_effect(1,540,960,0.5)
            elseif GameScene.antiqueResultType == 1001 then
                GameScene:coin_effect(2,540,960,0.5)
            end
        else
        end
    end
end

function UIActivityAuctionRecording(t)
    print("5412，接受客户端数据")
    printT(t)

    if gameWindows.windows["activityAuctionRecording"].show then
        gameWindows.windows["activityAuctionRecording"].module:reloadData(t)
    end
end

function UIActivityAuctionEnd(t)
    print("5413，接受客户端数据")
    printT(t)
    
    -- local _isShow = GameScene.layers["activity"].module.pageTable[_activityId] and 
    --                 GameScene.layers["activity"].module.pageTable[_activityId].module.show and
    --                 GameScene.layers["activity"].module.realPageTable[GameScene.layers["activity"].module.presentPage].id == _activityId
    
    local _isShow = GameScene.layers["antiqueAuction"].show

    if t.result == 1 then
        if not _isShow then
            gameTimer:UnrigistTime("activityAuctionTimer")
            gameTimer:UnrigistTimeFunc("activityAuctionTimer")
            gameTouch:setClickProf(false)
        end
    end
end

function UIActivityAuctionIsend(t)
    print("5414，接受客户端数据")
    printT(t)
    
    UIRequest({type = 1001})
    
    -- local _isShow = GameScene.layers["activity"].module.pageTable[_activityId] and 
    --                 GameScene.layers["activity"].module.pageTable[_activityId].module.show and
    --                 GameScene.layers["activity"].module.realPageTable[GameScene.layers["activity"].module.presentPage].id == _activityId
    
    local _isShow = GameScene.layers["antiqueAuction"].show
    
    if t.result == 1 then
        if not _isShow then
            gameTimer:UnrigistTime("activityAuctionTimer")
            gameTimer:UnrigistTimeFunc("activityAuctionTimer")
            gameTouch:setClickProf(false)

            if t.resultType == 1 then
                if t.priceType == 1000 then
                    GameScene:coin_effect(1,540,960,0.5)
                elseif t.priceType == 1001 then
                    GameScene:coin_effect(2,540,960,0.5)
                end
            end
        end
    end
end

function UIActivityAuctionOnekey(t)
    print("5415，接受客户端数据")
    printT(t)
    
     if t.isUpdata and t.isUpdata == 1 then
        GameScene:addUpdate(1200)
    end
    
    UIRequest({type = 1001})
    local _cb2 = function()
        UIRequest({type = 5410})
    end

    local _cb3 = function()
        showRewardPopupWindow(t.reward2, nil, _cb2)
    end

    local _cb = function()
        gameTouch:setClickProf(false)

        if t.isSpecial == 1 then
            if t.npcId ~= 0 then
                gameWindows:openWindow("activityAuctionSpecialReward", {npcId = t.npcId, cid = t.reward1["1"].cid, price = t.reward1["1"].num}, _cb3)
            else
                _cb3()
            end
        else
            UIRequest({type = 5410})
        end
    end


    UIRequest({type = 5414})

    gameWindows:closeWindow("activityantiqueOnekey")
    --赝品
    if t.reward1 and table.getTableLength(t.reward1) <=0  then 
        -- print("------古董为赝品")
         local callBack = function()
         end
         gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("activityAuction", 14) }, callBack)
    else   
        showRewardPopupWindow(t.reward1, nil, _cb)
    end    

    -- print("antiqueResultType:"..GameScene.antiqueResultType)
    -- if GameScene.antiqueResultType == 1000 then
    --     GameScene:coin_effect(1,540,960,0.5)
    -- elseif GameScene.antiqueResultType == 1001 then
    --     GameScene:coin_effect(2,540,960,0.5)
    -- end

end



