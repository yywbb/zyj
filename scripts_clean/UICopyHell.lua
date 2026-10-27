-- 地狱副本
-- 地狱副本主界面
function HellCopyQuery(t)
	print("地狱副本查询 6111，接受客户端数据")
	printT(t)
	if GameScene.layers["hellcopy"].show then
        GameScene.layers["hellcopy"].module:reloadData(t,false)
    end 
end

-- 地狱副本挑战boss
function HellCopyChallenge(t)
    print("地狱副本查询 6112，接受客户端数据")
    printT(t)
    local cb = function ()
	    UIRequest({type = 6111})
	    if t.result and t.result == 1 then
	    	--todo
	    end

	    if GameScene.layers["hellcopy"].show and t.result and t.result == 1 then
	        GameScene.layers["hellcopy"].module:detailBossDead(t.challengeId)
	    end 
    end

    RunbattleCallBack("copyhell", t, cb)

    UIRequest({type = 1001})
    
    
    if gameWindows.windows["hellBossInfo"].show then
		gameWindows:closeWindow("hellBossInfo")
	end
end

-- 地狱副本查询刷新玩家buff
function HellCopyRefreshPlayerBuff(t)
	print("地狱副本查询 6113，接受客户端数据")
	printT(t)

	if GameScene.layers["hellcopy"].show then
		GameScene.layers["hellcopy"].module:refreshPlayerBuff(t.playerBuff)
	end

	if gameWindows.windows["hellBuyBuff"].show then
		gameWindows.windows["hellBuyBuff"].module:reloadData(t)
	end

	UIRequest({type = 1001})
end

-- 地狱副本领取奖励
function HellCopyGetReward(t)
	print("地狱副本查询 6114，接受客户端数据")
	-- printT(t)

	local _cb = function()
		if GameScene.layers["hellcopy"].show then
	        GameScene.layers["hellcopy"].module:reloadIsAllClear(2)
	    end
	end

	if gameWindows.windows["hellAllReward"].show then
		gameWindows:closeWindow("hellAllReward")
	end
	
	showRewardPopupWindow(t.reward, nil, _cb)
	UIRequest({type = 1001})
end

-- 地狱副本选择玩家buff
function HellCopyChoosePlayerBuff(t)
	print("地狱副本查询 6115，接受客户端数据")
	-- printT(t)

	if GameScene.layers["hellcopy"].show then
		GameScene.layers["hellcopy"].module:refreshPlayerBuff(t.playerBuff)
	end

	if gameWindows.windows["hellBuyBuff"].show then
		gameWindows.windows["hellBuyBuff"].module:reloadData(t)
	end
end

-- 地狱副本刷新bossBuff
function HellCopyRefreshBossBuff(t)
	print("地狱副本查询 6116，接受客户端数据")

	if gameWindows.windows["hellBossInfo"].show then
		gameWindows:closeWindow("hellBossInfo")
	end

	-- printT(t)
	if GameScene.layers["hellcopy"].show then
        GameScene.layers["hellcopy"].module:reloadData(t, true)
    end
end