-- 本地公会活动使用服务端目标/计时；不再上传客户端总分。
function UIGangSkillQuery(uireq)
    return 1, 2262, nil
end

function UIGang2GroundGetHogsCallBack(uireq)
    return 1, 5152, nil
end

function NetGang2GroundGetHogsCallBack(fd)
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local targets = {}
    for i=1,(ids.ids[2] or 0) do
        targets[i] = {point=ids.ids[3*i], id=ids.ids[3*i+1], token=ids.ids[3*i+2]}
    end
    return {type=5152, status=ids.ids[1] or 0, mouseNum=#targets, mouseTab=targets}
end

function UIGang2GroundCatchHogCallBack(uireq)
    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.point)
    table.insert(ids.ids, uireq.status)
    table.insert(ids.ids, uireq.token or 0)
    return 1, 5153, ids:SerializeToString()
end

function NetGang2GroundCatchHogCallBack(fd)
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    return {type=5153, status=ids.ids[1] or 0,
        mouseData={score=ids.ids[2] or 0, battleNum=ids.ids[3] or 0,
                   powerSatus=ids.ids[4] or 0, hp=ids.ids[5] or 0}}
end

function UIGang2GroundGameOverCallBack(uireq)
    gamedata.ext.gameOverhighScore = uireq.highScore or 0
    return 1, 5156, nil
end

local originalGuardQuery = NetGang2GroundQueryCallBack
function NetGang2GroundQueryCallBack(fd)
    local reply = originalGuardQuery(fd)
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    reply.data.localRunning = ids.ids[10] == 1
    return reply
end

-- 奖励展示只读扩展；经验和贡献由随后的绝对快照同步，不能再次加算。
local function roomReward(fd, opcode, prefix)
    local data = somethings_pb.SomeThings()
    data:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(data)
    for _,extra in ipairs(data.pext1 or {}) do
        local values=extra.ids
        for i=1,#values,2 do table.insert(reward, {cid=values[i], num=values[i+1]}) end
    end
    return {type=opcode, reward=reward, beinum=gamedata.ext[prefix.."bei"],
            roomid=prefix=="feast" and gamedata.ext.roomid or gamedata.ext.bathroomid,
            personNum=prefix=="feast" and gamedata.ext.personNum or gamedata.ext.bathPersonNum}
end

function NetGangGetFeastRewardCallBack(fd) return roomReward(fd, 2273, "feast") end
function NetGangGetBathRewardCallBack(fd) return roomReward(fd, 2283, "bath") end

local originalBossBattle = NetGang2BossBattleCallBack
function NetGang2BossBattleCallBack(fd)
    local reply=originalBossBattle(fd)
    local data=worldboss1_pb.WorldBoss1()
    data:ParseFromString(fd.rbuf)
    for _,extra in ipairs(data.battle.reward.pext1 or {}) do
        for i=1,#extra.ids,2 do table.insert(reply.n_reward,{cid=extra.ids[i],num=extra.ids[i+1]}) end
    end
    return reply
end

for _,name in ipairs({"NetGangCreateJoinFeastCallBack", "NetGangRefreshFeastCallBack", "NetGangHandOpenFeastCallBack", "NetGangFeastAgainCallBack",
                     "NetGangCreateJoinBathCallBack", "NetGangRefreshBathCallBack", "NetGangHandOpenBathCallBack", "NetGangBathAgainCallBack"}) do
    local callback = _G[name]
    _G[name] = function(fd)
        local reply = callback(fd)
        local data = combmessages_pb.CombMessages()
        data:ParseFromString(fd.rbuf)
        for _,message in ipairs(data.messages) do
            if message.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(message.data)
                reply.data.feastRoomid = ids.ids[9] or reply.data.feastRoomid
            end
        end
        return reply
    end
end

-- 只包装新增的变更，沿用首批localGuildBusy；查询不占用变更锁。
for _,entry in ipairs({
    {2263,"UIGangSkillStudy","NetGangSkillStudy"},
    {4843,"UIGang2BossInspireCallBack","NetGang2BossInspireCallBack"},
    {4844,"UIGang2BossBattleCallBack","NetGang2BossBattleCallBack"},
    {5151,"UIGang2GroundStartCallBack","NetGang2GroundStartCallBack"},
    {5154,"UIGang2GroundBoxRewardsCallBack","NetGang2GroundBoxRewardsCallBack"},
    {5156,"UIGang2GroundGameOverCallBack","NetGang2GroundGameOverCallBack"},
    {2272,"UIGangCreateJoinFeastCallBack","NetGangCreateJoinFeastCallBack"},
    {2273,"UIGangGetFeastRewardCallBack","NetGangGetFeastRewardCallBack"},
    {2275,"UIGangHandOpenFeastCallBack","NetGangHandOpenFeastCallBack"},
    {2276,"UIGangFeastAgainCallBack","NetGangFeastAgainCallBack"},
    {2277,"UIGangBackFeastCallBack","NetGangBackFeastCallBack"},
    {2278,"UIGangExpChangeFeastCallBack","NetGangExpChangeFeastCallBack"},
    {2282,"UIGangCreateJoinBathCallBack","NetGangCreateJoinBathCallBack"},
    {2283,"UIGangGetBathRewardCallBack","NetGangGetBathRewardCallBack"},
    {2285,"UIGangHandOpenBathCallBack","NetGangHandOpenBathCallBack"},
    {2286,"UIGangBathAgainCallBack","NetGangBathAgainCallBack"},
    {2287,"UIGangBackBathCallBack","NetGangBackBathCallBack"}
}) do
    local opcode,request,response = entry[1],_G[entry[2]],_G[entry[3]]
    assert(request and response, "missing guild callback "..opcode)
    _G[entry[2]] = function(uireq)
        if gamedata.ext.localGuildBusy then return 0,503,{type=503,msg="正在处理公会操作，请稍候"} end
        local remote,kind,body = request(uireq)
        if remote == 1 then gamedata.ext.localGuildBusy = opcode end
        return remote,kind,body
    end
    _G[entry[3]] = function(fd)
        if gamedata.ext.localGuildBusy == opcode then gamedata.ext.localGuildBusy = nil end
        return response(fd)
    end
end
