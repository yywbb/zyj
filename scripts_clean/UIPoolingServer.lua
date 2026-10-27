local _activitOnlineId = 119
local _activitSignId = 120
local _activitGiftId = 121

function UIPoolingServerSignQuery(t)
    print("6101，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[_activitSignId] and GameScene.layers["activity"].module.pageTable[_activitSignId].module.show then
    	GameScene.layers["activity"].module.pageTable[_activitSignId].module:reloadData(t.data)
    end
end

function UIPoolingServerSignGetReward(t)
    print("6102，接受客户端数据")
    printT(t)

    UIRequest({type = 1001})
    
   	if GameScene.layers["activity"].module.pageTable[_activitSignId] and GameScene.layers["activity"].module.pageTable[_activitSignId].module.show then
   		GameScene.layers["activity"].module.pageTable[_activitSignId].module:getReward(t)
	end
end

function UIPoolingServerTaskQuery(t)
    print("6103，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[_activitGiftId] and GameScene.layers["activity"].module.pageTable[_activitGiftId].module.show then
        GameScene.layers["activity"].module.pageTable[_activitGiftId].module:reloadData(t)
    end
end

function UIPoolingServerTaskGetReward(t)
    print("6104，接受客户端数据")
    printT(t)

    UIRequest({type = 1001})
    
    if GameScene.layers["activity"].module.pageTable[_activitGiftId] and GameScene.layers["activity"].module.pageTable[_activitGiftId].module.show then
        local _cb = function()
            UIRequest({type = 6103})
        end
        showRewardPopupWindow(t.reward, nil, _cb)
    end
end

function UIPoolingServerOnlineQuery(t)
    print("6105，接受客户端数据")
    printT(t)

    if t.param and t.param == "main" then
        if t.day then
            gameWindows:openWindow("hefuActivity",t,function()
                GameScene:runMainTip()
            end)
        else
            GameScene:runMainTip()        
        end
    end

    if GameScene.layers["activity"].module.pageTable[_activitOnlineId] and GameScene.layers["activity"].module.pageTable[_activitOnlineId].module.show then
        GameScene.layers["activity"].module.pageTable[_activitOnlineId].module:reloadData(t)
    end
end

function UIPoolingServerOnlineGetReward(t)
    print("6106，接受客户端数据")
    printT(t)

    UIRequest({type = 1001})
    
    if GameScene.layers["activity"].module.pageTable[_activitOnlineId] and GameScene.layers["activity"].module.pageTable[_activitOnlineId].module.show then
        local _cb = function()
            UIRequest({type = 6105})
        end
        showRewardPopupWindow(t.reward, nil, _cb)
    end
end
