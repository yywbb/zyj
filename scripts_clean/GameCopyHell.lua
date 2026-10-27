--地狱副本
local battleresult_pb = require("battleresult_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
require"PickBattleResultReport"

--地狱副本主界面
function UIHellCopyQueryCallBack(uireq)
	cclog("NET type:%d cmd:%s recv request from UI", 6111, "UIHellCopyQueryCallBack")

	return 1, 6111, nil
end

--地狱副本主界面
function NetHellCopyQueryCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 6111, "NetHellCopyQueryCallBack")

	local _ids = ids_pb.Ids()
	_ids:ParseFromString(fd.rbuf)
    local _boss = {[1] = {}, [2] = {}, [3] = {}}
    local _isAllClear = 0

    _isAllClear = _ids.ids[1]
    _buffRefreshTime = _ids.ids[2]

    for i = 3, #_ids.ids do
    	local _num1 = math.modf((i - 2)/ 6) + 1
    	local _num2 = math.mod((i - 2), 6)
    	if _num2 == 1 then
    		_boss[_num1].iid = _ids.ids[i]
    	elseif _num2 == 2 then
    		_boss[_num1].cid = _ids.ids[i]
    	elseif _num2 == 3 then
    		_boss[_num1].buffCid = _ids.ids[i]
    	elseif _num2 == 4 then
    		_boss[_num1].value = _ids.ids[i]
    	elseif _num2 == 5 then
            _boss[_num1].isClear = _ids.ids[i]
    	elseif _num2 == 0 then
            _num1 = _num1 - 1
    		_boss[_num1].isReward = _ids.ids[i]
    	end
    end

    return {type = 6111, boss = _boss, buffRefreshTime = _buffRefreshTime, isAllClear = _isAllClear}
end

--地狱副本挑战
function UIHellCopyChallengeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6112, "UIHellCopyChallengeCallBack")
    local _data = ids_pb.Ids()

    if uireq.param then
        table.insert(_data.ids, uireq.param)
    end

    gamedata.ext.hellCopyChallenge = uireq.param

    return 1, 6112, _data:SerializeToString()
end

--地狱副本挑战
function NetHellCopyChallengeCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 6112, "NetHellCopyChallengeCallBack")

    local _battleResultPb = battleresult_pb.BattleResult()
    _battleResultPb:ParseFromString(fd.rbuf)

    return {
        type = 6112,
        result = _battleResultPb.result,
        reward = gamedata:SomethingProcess(_battleResultPb.reward),
        battlereport = PickBattleResultReport(_battleResultPb),
        challengeId = gamedata.ext.hellCopyChallenge,
    }
end

--地狱副本查询或刷新玩家buff
function UIHellCopyRefreshPlayerBuffCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6113, "UIHellCopyRefreshPlayerBuffCallBack")
    local _data = ids_pb.Ids()

    if uireq.param then
        table.insert(_data.ids, uireq.param)
    end

    gamedata.ext.hellRefreshGold = uireq.gold

    return 1, 6113, _data:SerializeToString()
end

--地狱副本查询或刷新玩家buff
function NetHellCopyRefreshPlayerBuffCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 6113, "NetHellCopyRefreshPlayerBuffCallBack")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _playerBuff = {}
    _playerBuff.refreshCount = _ids.ids[1] + 1
    _playerBuff.currentBuff = _ids.ids[2]
    _playerBuff.buffCid1 = _ids.ids[3]
    _playerBuff.buffValue1 = _ids.ids[4]
    _playerBuff.buffCid2 = _ids.ids[5]
    _playerBuff.buffValue2 = _ids.ids[6]

    local _gold = gamedata.ext.hellRefreshGold
    
    if _gold > 0 then
        gamedata:updateRoleGold(0 - _gold, "地狱副本刷新物品钱数")
    end

    return {type = 6113, playerBuff = _playerBuff}
end

--地狱副本领取奖励
function UIHellCopyGetRewardCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 6114, "UIHellCopyGetRewardCallBack")

    return 1, 6114, nil
end

--地狱副本领取奖励
function NetHellCopyGetRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 6114, "NetHellCopyGetRewardCallBack")
    local _getData = somethings_pb.SomeThings()
    _getData:ParseFromString(fd.rbuf)

    return { type = 6114, reward = gamedata:SomethingProcess(_getData)}
end

--地狱副本选择玩家buff
function UIHellCopyChoosePlayerBuffCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6115, "UIHellCopyChoosePlayerBuffCallBack")
    local _data = ids_pb.Ids()

    if uireq.param then
        table.insert(_data.ids, uireq.param)
    end

    return 1, 6115, _data:SerializeToString()
end

--地狱副本选择玩家buff
function NetHellCopyChoosePlayerBuffCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 6115, "NetHellCopyChoosePlayerBuffCallBack")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _playerBuff = {}
    _playerBuff.refreshCount = _ids.ids[1] + 1
    _playerBuff.currentBuff = _ids.ids[2]
    _playerBuff.buffCid1 = _ids.ids[3]
    _playerBuff.buffValue1 = _ids.ids[4]
    _playerBuff.buffCid2 = _ids.ids[5]
    _playerBuff.buffValue2 = _ids.ids[6]

    return {type = 6115, playerBuff = _playerBuff}
end

--地狱副本刷新bossBuff(后端推送)
function NetHellCopyRefreshBossBuffCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 6116, "NetHellCopyRefreshBossBuffCallBack")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    local _boss = {[1] = {}, [2] = {}, [3] = {}}

    _buffRefreshTime = _ids.ids[1]

    for i = 2, #_ids.ids do
        local _num1 = math.modf((i - 1)/ 4) + 1
        local _num2 = math.mod((i - 1), 4)
        if _num2 == 1 then
            _boss[_num1].iid = _ids.ids[i]
        elseif _num2 == 2 then
            _boss[_num1].cid = _ids.ids[i]
        elseif _num2 == 3 then
            _boss[_num1].buffCid = _ids.ids[i]
        elseif _num2 == 0 then
            _num1 = _num1 - 1
            _boss[_num1].value = _ids.ids[i]
        end
    end

    return {type = 6116, boss = _boss, buffRefreshTime = _buffRefreshTime}
end