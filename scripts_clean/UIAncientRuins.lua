--
-- Author: songyibo
-- Date: 2019-09-23 13:42:10
--
function UIAncientRuinsQuery(t)
	printT(t,"7080 上古遗迹查询")

	if t.param and t.param == "checkOpen" then
		if GameScene.layers["main"].show then
	        GameScene.layers["main"].module:setAncientRuins(t.AncientRuinsData)
	    end
	else
		if GameScene.layers["ancientRuins"].show then
	        GameScene.layers["ancientRuins"].module:reloadData(t.AncientRuinsData)
	    else
	    	GameScene:shiftLayer("ancientRuins","up",t.AncientRuinsData)
	    end
	end
    
end


function UIAncientRuinsAttack(t)
	printT(t,"7081 上古遗迹战斗")
	
	t.attackInfo.result = t.result or 0
	local cb = function ()
		UIRequest({type = 1001})
		if GameScene.layers["ancientRuins"].show then
	        GameScene.layers["ancientRuins"].module:attackCallback(t.attackInfo,t.AncientRuinsData)
	    end
	end

	RunbattleCallBack("ancientRuins", {reward = t.reward, battlereport = t.battlereport,result = t.result or 0}, cb)

end

function UIAncientRuinsReward(t)
	printT(t,"7082 上古遗迹领奖")


	local cb = function ()
	    if GameScene.layers["ancientRuins"].show then
	        GameScene.layers["ancientRuins"].module:awardCallback(t.AncientRuinsData)
	    end
	end

	if t.reward then
		showRewardPopupWindow(t.reward, nil,cb)
	else
		cb()
	end
	UIRequest({type = 1001})
end
