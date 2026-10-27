--
-- Author: songyibo
-- Date: 2021-03-16 13:44:13
--

local function ExclusiveArtifactDatas(data,reset)
	GameScene.layers["slotsInfo"].module:setExclusiveArtifactData(data,reset)
end

local function ExclusiveArtifactQilingDatas(data,reset)
	GameScene.layers["qiLingBag"].module:reloadData(data,reset)
end

function UIExclusiveArtifactQuery(t)
	-- printT(t,"8101 专属神器查询")
	ExclusiveArtifactDatas(t.exclusiveArtifacts,true)
end

function UIExclusiveArtifactStrengthen(t)
	printT(t,"8102 专属神器强化")
	ExclusiveArtifactDatas({t.exclusiveArtifact})

	if GameScene.layers["exclusiveArtifact"].show then
		GameScene.layers["exclusiveArtifact"].module:intensifyCallback(t.props)
    end

    GameScene:addUpdate(1200)
	GameScene:addUpdate(10021)
	GameScene:addUpdate(10023)
end

function UIExclusiveArtifactActive(t)
	printT(t,"8103 专属神器激活")

	local cb = function ()
	    if t.result and t.result == 1 then
	    	ExclusiveArtifactDatas({t.exclusiveArtifact})
	    	if gameWindows.windows["generalInfoRole"].show then
		        gameWindows:closeWindowDirect("generalInfoRole")
		    end
	    	gameWindows:openWindow("exclusiveActive",{generalCid = t.generalCid,exclusiveCid = t.exclusiveCid})
	    else
	    	GameScene:addUpdate(10021)
	    	GameScene:UpdatePresentLayer()
	    end
	    if gameWindows.windows["exclusiveArtifact"].show then
	        gameWindows.windows["exclusiveArtifact"].module:reload()
	    end
    end
    
    RunbattleCallBack("exclusiveActive", t, cb)
end

function UIExclusiveArtifactInlay(t)
	printT(t,"8104 专属神器镶嵌")
	ExclusiveArtifactQilingDatas(t.changeQilingDatas)
	ExclusiveArtifactDatas(t.changeArtifactDatas)

	if GameScene.layers["exclusiveArtifact"].show then
		GameScene.layers["exclusiveArtifact"].module:inlayCallback(t.activeSuitId)
    end

    if GameScene.layers["qiLingBag"].show then
		GameScene.layers["qiLingBag"].module:reload(true)
    end

    GameScene:addUpdate(10021)
    GameScene:UpdatePresentLayer()

    UIRequest({type = 10322, param = {"qiling"}})
end

function UIExclusiveArtifactQiLingQuery(t)
	-- printT(t,"8105 器灵查询")
	ExclusiveArtifactQilingDatas(t.qiLingDatas,true)
end

function UIExclusiveArtifactQiLingUpdate(t)
	printT(t,"81051 器灵数据更新")
	ExclusiveArtifactQilingDatas(t.qiLingDatas,true)
end


function UIExclusiveArtifactQiLingStrengthen(t)
	printT(t,"8106 器灵强化")
	ExclusiveArtifactQilingDatas({t.data})

	if gameWindows.windows["qilingIntensify"].show then
        gameWindows.windows["qilingIntensify"].module:intensifyCallback(t)
    end

	if GameScene.layers["qiLingBag"].show then
		GameScene.layers["qiLingBag"].module:reload(true)
    end

    GameScene:addUpdate(1200)
    UIRequest({type = 10322, param = {"qiling"}})
    -- GameScene:addUpdate(10021)
    -- GameScene:UpdatePresentLayer()
end

function UIExclusiveArtifactQiLingLock(t)
	printT(t,"8107 器灵锁定")
	ExclusiveArtifactQilingDatas({t.data})
	if gameWindows.windows["qilingInfo"].show then
        gameWindows.windows["qilingInfo"].module:reload()
    end

    if GameScene.layers["qiLingBag"].show then
		GameScene.layers["qiLingBag"].module:reload(true)
    end
end

function UIExclusiveArtifactQiLingRefining(t)
	printT(t,"8108 器灵熔炼")
	ExclusiveArtifactQilingDatas(t.data,true)

    if GameScene.layers["qiLingRefining"].show then
		GameScene.layers["qiLingRefining"].module:refiningCallback(t)
    end
	
	GameScene:addUpdate(10021)
	UIRequest({type = 10322, param = {"qiling"}})
end

function UIExclusiveArtifacActiveChallengeQuery( t)
	printT(t,"8109 神器激活挑战次数查询")

	if gameWindows.windows["exclusiveArtifact"].show then
        gameWindows.windows["exclusiveArtifact"].module:reloadChallengeTimes(t.data)
    end
end

function UIExclusiveArtifactCopy(t)
	printT(t,"8201 专属副本查询")

	if GameScene.layers["exclusiveArtifactCopy"].show then
		GameScene.layers["exclusiveArtifactCopy"].module:reload(t)
  	end

	if t.index and t.index > 0 then
		if gameWindows.windows["exclusiveArtifactQiLingCopy"].show then
			for k,v in pairs(t.qlData) do
				if tonumber(k) == t.index then
					gameWindows.windows["exclusiveArtifactQiLingCopy"].module:qiLingReload(v,0)
					break
				end
			end
		end
	end
	
end

function UIExclusiveArtifactCopyFight(t)
	printT(t,"8202 专属副本战斗")

	local cb = function()
        if GameScene.layers["exclusiveArtifactCopy"].show then
			if t.result and t.result == 1 then
				UIRequest({type = 8201, index = t.index or 0})
			else
				UIRequest({type = 8201})
			end
            
        end
    end

    RunbattleCallBack("exclusiveArtifactCopy", t, cb)

	GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})
end

function UIExclusiveArtifactCopySweep(t)
	printT(t,"8203 专属副本扫荡")

	local cb = function()
        if GameScene.layers["exclusiveArtifactCopy"].show then
               UIRequest({type = 8201})
        end
    end

    showRewardPopupWindow(t.reward,nil,cb)
end


function UIExclusiveArtifactReset(t)
    printT(t,"8204 专属神器重生")

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end

    ExclusiveArtifactQilingDatas(t.changeQilingDatas)
    ExclusiveArtifactDatas({t.exclusiveArtifact})

    UIRequest({type = 1001})
end

function saveNewQilingToSqlite(iids)
    printT(iids,"saveNewQilingToSqlite")

    local rid = GameScene.roleinfo.id or 0
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
    if rid < 1000000 then
        rid = serverid*1000000 + rid
    end    
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "CREATE TABLE IF NOT EXISTS NewQiling (rid INTEGER, qiling_iid INTEGER, qiling_new INTEGER)";
    mydb:exec(SQL)

    for i,v in ipairs(iids) do
    	if v.opt == 1 then
    		SQL = string.format("INSERT INTO NewQiling (rid,qiling_iid,qiling_new) VALUES (%d,%d,%d)",rid,v.iid,v.opt)
	        mydb:exec(SQL)
    	else
    		SQL = string.format("DELETE FROM NewQiling WHERE rid=%d AND qiling_iid=%d",rid,v.iid)
    		print(SQL)
	        mydb:exec(SQL)
    	end
    end
    mydb:close()
end

function getNewQilingFromSqlite()
    if not GameScene.roleinfo then
        return {}
    end
    print("getNewQilingSqlite")
    local newQiling = {}
    local rid = GameScene.roleinfo.id or 0
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
    if rid < 1000000 then
        rid = serverid*1000000 + rid
    end    
    local mydb = SQLite3Open()
    if nil == mydb then
        return {}
    end
    local SQL = "SELECT count(*) AS pftexist FROM sqlite_master WHERE type='table' AND name='NewQiling'"
    local ret = 0
    for row in mydb:nrows(SQL) do
        ret = row["pftexist"]
    end
    if ret == 0 then
        local SQL = "CREATE TABLE IF NOT EXISTS NewQiling (rid INTEGER, qiling_iid INTEGER, qiling_new INTEGER)";
        mydb:exec(SQL)
        return {}
    end
    local SQL = "SELECT * FROM NewQiling WHERE rid=" .. rid
    for row in mydb:rows(SQL) do
        local iid = row[2] or 0
        local isnew = row[3] or 0
        newQiling[iid] = {iid = iid,isnew = isnew}
    end
    mydb:close()
    return newQiling
end

