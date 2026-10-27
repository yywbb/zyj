function UIExchange(t)
	print("请求兑换活动2055 接收客户端返回数据")
    printT(t)

	if t.resetTime and t.resetTime >0 then
		gameTimer:rigistTime("ActivityExchangeTimer",t.resetTime)
	end

	if GameScene.layers["activity"].module.pageTable[17] then
		GameScene.layers["activity"].module.pageTable[17].module:reloaddata(t)
	end
end

function UIExchangeEX(t)
	print("请求兑换活动2056 接收客户端返回数据")
    printT(t)

    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10211)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(1200)
	showRewardPopupWindow(t.reward,nil,function()
        if GameScene.layers["activity"].module.pageTable[17] then
            GameScene.layers["activity"].module.pageTable[17].module:reloaddata(t)
        end
        UIRequest({type =1001})
    end)
end

function UIExchangeRefresh(t)
	print("请求兑换活动2057 接收客户端返回数据")
    gameTimer:rigistTime("ActivityExchangeTimer",t.resetTime)
	UIRequest({type = 1001})
    GameScene:addUpdate(1200)
    GameScene:UpdatePresentLayer()
	if GameScene.layers["activity"].module.pageTable[17] then
		GameScene.layers["activity"].module.pageTable[17].module:reloaddata(t)
	end
end

