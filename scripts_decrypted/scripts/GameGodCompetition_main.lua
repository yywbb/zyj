--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/1
-- Time: 11:00
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")
local battleresult_pb = require("battleresult_pb")
local players_pb = require("players_pb")
local result_pb = require("result_pb")
local tasks_pb = require"tasks_pb"

require"PickBattleResultReport"

local function GodChampionData( data )
    local tempdata = {}
    local arrnum = #data/7

    for i=1,arrnum do
        local idx = 7*(i-1)
        local temp = {}
        temp.rank = i

        temp.list           = data[idx+1] and data[idx+1].i or 0
        temp.rid            = data[idx+2] and data[idx+2].i or 0
        temp.name           = data[idx+2] and data[idx+2].s or ""
        temp.level          = data[idx+3] and data[idx+3].i or 0
        temp.profile        = data[idx+4] and data[idx+4].i or 0
        temp.w_l            = data[idx+5] and data[idx+5].i or 0
        temp.w_c            = data[idx+6] and data[idx+6].i or 0
        temp.serviceid      = data[idx+7] and data[idx+7].i or 0
        temp.servicename    = data[idx+7] and data[idx+7].s or ""
        tempdata[temp.list] = temp
    end

    return tempdata
end

local function GodCompetitionRoleBattle( data,id )
    if data and id and id+0 > 0 then
        local point = {}
        point.id =        data[1] and data[1].s or ""
        point.phase =     data[2] and data[2].i or 0
        point.round =     data[3] and data[3].i or 0
        point.result =    data[4] and data[4].i or 0
        point.resultnum = data[5] and data[5].i or 0
        point.star =      data[6] and data[6].i or 0
        point.reward =    data[7] and data[7].i or 0
        
        point.rid_a =     data[8] and data[8].i or 0
        point.name_a =    data[8] and data[8].s or ""
        point.profile_a = data[9] and data[9].i or 0
        point.power_a =   data[10] and data[10].i or 0
        point.rid_b =     data[11] and data[11].i or 0
        point.name_b =    data[11] and data[11].s or ""
        point.profile_b = data[12] and data[12].i or 0
        point.power_b =   data[13] and data[13].i or 0
        point.time =      data[14] and data[14].i or 0

        point.title_a   =  data[15] and data[15].i or 0
        point.iconBox_a =  data[16] and data[16].i or 0
        point.title_b   =  data[17] and data[17].i or 0
        point.iconBox_b =  data[18] and data[18].i or 0

        gamedata.cache.godComRoleBattles[tostring(id)] = point
    end
end

local function GodCompetitionPlayers( data,id )
    if data and id and id+0 > 0 then
        local point = {}
        point.rid = data[1] and data[1].i or 0
        point.name = data[1] and data[1].s or ""
        point.level = data[2] and data[2].i or 0
        point.profile = data[3] and data[3].i or 0
        point.server_id = data[4] and data[4].i or 0
        point.server_name = data[4] and data[4].s or ""

        gamedata.cache.godplayers[tostring(point.rid)] = point
    end
end

--封神赛报名
function UIUserApesSignUpCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 8250, "UserApesSignUp")

    return 1, 8250, nil
end

function NetUserApesSignUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8250, "UserApesSignUp")
   
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local result = ids.ids[1] or 0

    return { type = 8250, result = result}
end

--封神赛主页查询
function UIUserApexQueryCallBack( uireq )
    print("from UI 8251")

    return 1, 8251, nil
end

function NetUserApexQueryCallBack(fd)
    print("from Net 8251")

    local idsdata = ids_pb.Ids()
    idsdata:ParseFromString(fd.rbuf)

    local godStatus = {
        period = idsdata.ids[1] or 0, --第几届
        group = idsdata.ids[2] or 0, --赛区
        status = idsdata.ids[3] or 0, --封神赛阶段
        num = (idsdata.ids[4] + idsdata.ids[5] + idsdata.ids[6]) or 0, --每日boss挑战次数
        damage1 = idsdata.ids[7] or 0, --boss1总伤害
        damage2 = idsdata.ids[8] or 0, --boss2总伤害
        damage3 = idsdata.ids[9] or 0, --boss3总伤害
        buff1 = { --boss1的buff
            b1 = idsdata.ids[10] or 0,
            b2 = idsdata.ids[11] or 0,
            b3 = idsdata.ids[12] or 0,
        },
        buff2 = { --boss2的buff
            b1 = idsdata.ids[13] or 0,
            b2 = idsdata.ids[14] or 0,
            b3 = idsdata.ids[15] or 0,
        },
        buff3 = { --boss3的buff
            b1 = idsdata.ids[16] or 0,
            b2 = idsdata.ids[17] or 0,
            b3 = idsdata.ids[18] or 0,
        },
        newDamage1 = idsdata.ids[19] or 0, --玩家对boss1总伤害
        newDamage2 = idsdata.ids[20] or 0, --玩家对boss2总伤害
        newDamage3 = idsdata.ids[21] or 0, --玩家对boss3总伤害
        bossid = idsdata.ids[22] or 0, --当前最高伤害的bossid
        iscanArray = idsdata.ids[23] or 0, --是否可以布阵
        competition = idsdata.ids[24] or 0, --是否参加pvp
    }
    print("competition = ",godStatus.competition)
    gamedata.cache.godCompetitionData.competition = godStatus.competition

    return { type = 8251, godStatus = godStatus }
end

--BOSS挑战
function UIUserApexBossAttackCallBack( uireq )
    print("from UI 8258")

    local bossid = uireq.bossid
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,bossid)

    return 1, 8258, idsData:SerializeToString()
end

function NetUserApexBossAttackCallBack(fd)
    print("from Net 8258")

    local bossAttackResultPb = battleresult_pb.BattleResult()
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local t = {
        type = 8258,
        result = 0,
    }

    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            bossAttackResultPb:ParseFromString(v.data)
            t.reward = gamedata:SomethingProcess(bossAttackResultPb.reward)
            t.battlereport1 = bossAttackResultPb.battlereport
        elseif v.id == 2 then
            bossAttackResultPb:ParseFromString(v.data)
            t.battlereport2 = bossAttackResultPb.battlereport
        elseif v.id == 3 then
            bossAttackResultPb:ParseFromString(v.data)
            t.battlereport3 = bossAttackResultPb.battlereport
        end
    end

    return t
end

function UIUserApexBossDamageRankCallBack( uireq )
    print("from UI 8259")

    return 1, 8259, nil
end

function NetUserApexBossDamageRankCallBack( fd )
    print("from Net 8259")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    --跨服排行
    local serverdata = {
        alldata = {},
        mydata={},
    }

    --本服排行
    local newdata = {
        alldata = {},
        mydata={},
    }

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)   
        if v.id == 1 then --跨服
            local sData = params.params
            for i=1, #sData/5 do
                local temp = {}
                local idx = 5*(i-1)
                
                temp.damage = sData[idx+1] and sData[idx+1].i or 0
                temp.rid = sData[idx+2] and sData[idx+2].i or 0
                temp.serviceid = sData[idx+3] and sData[idx+3].s or ""
                temp.name = sData[idx+4] and sData[idx+4].s or ""
                temp.rank = sData[idx+5] and sData[idx+5].i or 0
                table.insert(serverdata.alldata,temp)
            end
        elseif v.id == 2 then --本服
            local nData = params.params
            for i=1, #nData/5 do
                local temp = {}
                local idx = 5*(i-1)
                
                temp.damage = nData[idx+1] and nData[idx+1].i or 0
                temp.rid = nData[idx+2] and nData[idx+2].i or 0
                temp.serviceid = nData[idx+3] and nData[idx+3].s or ""
                temp.name = nData[idx+4] and nData[idx+4].s or ""
                temp.rank = nData[idx+5] and nData[idx+5].i or 0
                table.insert(newdata.alldata,temp)
            end
        elseif v.id == 3 then --跨服自己
            local psData = params.params
            local temp = {}
            temp.damage = psData[1] and psData[1].i or 0
            temp.rid = psData[2] and psData[2].i or 0
            temp.serviceid = psData[3] and psData[3].s or ""
            temp.name = psData[4] and psData[4].s or ""
            temp.rank = psData[5] and psData[5].i or 0
            serverdata.mydata = temp
        elseif v.id == 4 then --本服自己
            local pnData = params.params
            local temp = {}
            temp.damage = pnData[1] and pnData[1].i or 0
            temp.rid = pnData[2] and pnData[2].i or 0
            temp.serviceid = pnData[3] and pnData[3].s or ""
            temp.name = pnData[4] and pnData[4].s or ""
            temp.rank = pnData[5] and pnData[5].i or 0
            newdata.mydata = temp
        end
    end

    return { type = 8259, serverdata = serverdata, newdata = newdata}
end

--挑战记录
function UIUserApexBossBattleRecordCallBack( uireq )
    print("from UI 8260")
    return 1, 8260, nil
end

function NetUserApexBossBattleRecordCallBack( fd )
    print("from Net 8260")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local battleInfo = {}
    local index = 1
    for k,v in ipairs(datas.messages) do
        if v.id > 0 then    
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local data = ids.ids
            local _temp = {slotinfo = {}, bossid =  0}
            for kk=1,3 do
                local _battleTemp = {}
                local _index = (kk-1)*17+1
                _battleTemp.slotsid = data[_index] or 0
                _battleTemp.hurtNum = data[_index+1] or 0
                
                local slotIndex= 2
                for kkk=1,7 do
                    _battleTemp["slot"..kkk] = data[_index+slotIndex] or 0
                    slotIndex = slotIndex +1 
                    _battleTemp["llusion"..kkk] = data[_index+slotIndex] or 0
                    slotIndex = slotIndex +1 
                end    

                _battleTemp.petid = data[_index+16] or 0
                _temp.slotinfo[kk] = _battleTemp

            end    
            _temp.bossid = data[52] or 0
            _temp.timetemp = v.id or 0

            -- printT(_temp,"temp")
            table.insert(battleInfo,_temp)
            index = index+1
        end    
    end    

    -- printT(battleInfo,"battleInfo")
    return { type = 8260, battleInfo = battleInfo}

end

--boss伤害奖励查询
function UIUserApexBossRewardsQueryCallBack( uireq )
    print("from UI 8261")
    return 1, 8261, nil
end

function NetUserApexBossRewardsQueryCallBack( fd )
    print("from Net 8261")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local data = ids.ids
    local status = {}
    for i= 1, #data do
        status[i] = data[i] or 0
    end    
    return { type = 8261, status = status}
end

function UIUserApexBossRewardsCollectCallBack( uireq )
    print("from UI 8262")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.server)
    table.insert(idsData.ids,uireq.rewardid)
    
    print(uireq.server,uireq.rewardid," UIUserApexBossRewardsCollectCallBack")

    return 1, 8262, idsData:SerializeToString()

end

function NetUserApexBossRewardsCollectCallBack( fd )
    print("from Net 8262")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    return {type = 8262, reward = reward}
end

function UIUserApexUpLoadSlotsCallBack( uireq )
    print("from UI 8263")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.timeid)

    return 1, 8263, idsData:SerializeToString()
end

function NetUserApexUpLoadSlotsCallBack( fd )
    print("from Net 8263")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local data = ids.ids
    local status = data[1] or 0 --1，代表上传成功
    return { type = 8263, status = status}
end

function UIUserCheckLoadSlotsCallBack( uireq )
    print("from UI 8264")
    return 1, 8264, nil
end

function NetUserCheckLoadSlotsCallBack( fd )
    print("from Net 8264")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local data = ids.ids
    local status = data[1] or 1  --非0，代表该阵容为空
    return { type = 8264, status = status}
end
-----------------------------------------------封神赛小组和冠军区-------------------------------------------------------

function UIUserWarOfApexChampionOldCallBack( uireq )
    print("from UI 8271")

    return 1, 8271, nil
end

function NetUserWarOfApexChampionOldCallBack( fd )
    print("from Net 8271")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local lastChampion = GodChampionData(params.params) 

    return { type = 8271, lastChampion = lastChampion}
end

--封神赛领奖
function UIUserWarOfApexRewardCallBack( uireq )
    print("from UI 8272")

    local params = params_pb.ParamS()
    local data = params.params:add()
    data.i = uireq.phase
    data.s = uireq.id

    return 1, 8272, params:SerializeToString()
end

function NetUserWarOfApexRewardCallBack( fd )
    print("from Net 8272")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    return {type = 8272, reward = reward}
end

--战斗详情
function UIUserWarOfApexRoleBattlesInfoCallBack( uireq )
    print("from UI 8273")

    local params = params_pb.ParamS()
    local data = params.params:add()
    data.i = uireq.phase
    data.s = uireq.id

    return 1, 8273, params:SerializeToString()
end

function NetUserWarOfApexRoleBattlesInfoCallBack( fd )
    print("from Net 8273")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local battleinfo = {}
    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)   
        local data = params.params    
        if v.id == 0 then 
            battleinfo.players = {
                rid_a      = data[1] and data[1].i or 0,
                rid_b      = data[2] and data[2].i or 0,
            }            
        elseif v.id == 1 then
            battleinfo[1] = {
                time       = data[1] and data[1].i or 0,  --战斗倒计时
                id         = data[1] and data[1].s or "", --战斗key
                --左边信息
                power_a    = data[2] and data[2].i or 0,  --左玩战斗力
                pet_a      = data[3] and data[3].i or 0,  --左宠物
                general1_a = data[4] and data[4].i or 0,  --左武将1头像
                oldcid1_a  = data[5] and data[5].i or 0,  --左武将1cid
                general2_a = data[6] and data[6].i or 0,  --左武将2头像
                oldcid2_a  = data[7] and data[7].i or 0,  --左武将2cid
                general3_a = data[8] and data[8].i or 0,  --左武将3头像
                oldcid3_a  = data[9] and data[9].i or 0,  --左武将3cid
                general4_a = data[10] and data[10].i or 0,  --左武将4头像
                oldcid4_a  = data[11] and data[11].i or 0,  --左武将4cid
                general5_a = data[12] and data[12].i or 0,  --左武将5头像
                oldcid5_a  = data[13] and data[13].i or 0,  --左武将5cid
                general6_a = data[14] and data[14].i or 0,  --左武将6头像
                oldcid6_a  = data[15] and data[15].i or 0,  --左武将6cid
                general7_a = data[16] and data[16].i or 0,  --左武将7头像
                oldcid7_a  = data[17] and data[17].i or 0,  --左武将7cid
                --右边信息
                power_b    = data[18] and data[18].i or 0,  --左玩战斗力
                pet_b      = data[19] and data[19].i or 0,  --右宠物
                general1_b = data[20] and data[20].i or 0,  --右武将1头像
                oldcid1_b  = data[21] and data[21].i or 0,  --右武将1cid
                general2_b = data[22] and data[22].i or 0,  --右武将2头像
                oldcid2_b  = data[23] and data[23].i or 0,  --右武将2cid
                general3_b = data[24] and data[24].i or 0,  --右武将3头像
                oldcid3_b  = data[25] and data[25].i or 0,  --右武将3cid
                general4_b = data[26] and data[26].i or 0,  --右武将4头像
                oldcid4_b  = data[27] and data[27].i or 0,  --右武将4cid
                general5_b = data[28] and data[28].i or 0,  --右武将5头像
                oldcid5_b  = data[29] and data[29].i or 0,  --右武将5cid
                general6_b = data[30] and data[30].i or 0,  --右武将6头像
                oldcid6_b  = data[31] and data[31].i or 0,  --右武将6cid
                general7_b = data[32] and data[32].i or 0,  --右武将7头像
                oldcid7_b  = data[33] and data[33].i or 0,  --右武将7cid
                --战斗结果
                result     = data[34] and data[34].i or 0,
                rid_a      = data[35] and data[35].i or 0,  --左玩id
                rid_b      = data[36] and data[36].i or 0,  --右玩id
            }
        elseif v.id == 2 then
            battleinfo[2] = {
                time       = data[1] and data[1].i or 0,  --战斗倒计时
                id         = data[1] and data[1].s or "", --战斗key
                --左边信息
                power_a    = data[2] and data[2].i or 0,  --左玩战斗力
                pet_a      = data[3] and data[3].i or 0,  --左宠物
                general1_a = data[4] and data[4].i or 0,  --左武将1头像
                oldcid1_a  = data[5] and data[5].i or 0,  --左武将1cid
                general2_a = data[6] and data[6].i or 0,  --左武将2头像
                oldcid2_a  = data[7] and data[7].i or 0,  --左武将2cid
                general3_a = data[8] and data[8].i or 0,  --左武将3头像
                oldcid3_a  = data[9] and data[9].i or 0,  --左武将3cid
                general4_a = data[10] and data[10].i or 0,  --左武将4头像
                oldcid4_a  = data[11] and data[11].i or 0,  --左武将4cid
                general5_a = data[12] and data[12].i or 0,  --左武将5头像
                oldcid5_a  = data[13] and data[13].i or 0,  --左武将5cid
                general6_a = data[14] and data[14].i or 0,  --左武将6头像
                oldcid6_a  = data[15] and data[15].i or 0,  --左武将6cid
                general7_a = data[16] and data[16].i or 0,  --左武将7头像
                oldcid7_a  = data[17] and data[17].i or 0,  --左武将7cid
                --右边信息
                power_b    = data[18] and data[18].i or 0,  --左玩战斗力
                pet_b      = data[19] and data[19].i or 0,  --右宠物
                general1_b = data[20] and data[20].i or 0,  --右武将1头像
                oldcid1_b  = data[21] and data[21].i or 0,  --右武将1cid
                general2_b = data[22] and data[22].i or 0,  --右武将2头像
                oldcid2_b  = data[23] and data[23].i or 0,  --右武将2cid
                general3_b = data[24] and data[24].i or 0,  --右武将3头像
                oldcid3_b  = data[25] and data[25].i or 0,  --右武将3cid
                general4_b = data[26] and data[26].i or 0,  --右武将4头像
                oldcid4_b  = data[27] and data[27].i or 0,  --右武将4cid
                general5_b = data[28] and data[28].i or 0,  --右武将5头像
                oldcid5_b  = data[29] and data[29].i or 0,  --右武将5cid
                general6_b = data[30] and data[30].i or 0,  --右武将6头像
                oldcid6_b  = data[31] and data[31].i or 0,  --右武将6cid
                general7_b = data[32] and data[32].i or 0,  --右武将7头像
                oldcid7_b  = data[33] and data[33].i or 0,  --右武将7cid
                --战斗结果
                result     = data[34] and data[34].i or 0,
                rid_a      = data[35] and data[35].i or 0,  --左玩id
                rid_b      = data[36] and data[36].i or 0,  --右玩id
            }            
        elseif v.id == 3 then
            battleinfo[3] = {
                time       = data[1] and data[1].i or 0,  --战斗倒计时
                id         = data[1] and data[1].s or "", --战斗key
                --左边信息
                power_a    = data[2] and data[2].i or 0,  --左玩战斗力
                pet_a      = data[3] and data[3].i or 0,  --左宠物
                general1_a = data[4] and data[4].i or 0,  --左武将1头像
                oldcid1_a  = data[5] and data[5].i or 0,  --左武将1cid
                general2_a = data[6] and data[6].i or 0,  --左武将2头像
                oldcid2_a  = data[7] and data[7].i or 0,  --左武将2cid
                general3_a = data[8] and data[8].i or 0,  --左武将3头像
                oldcid3_a  = data[9] and data[9].i or 0,  --左武将3cid
                general4_a = data[10] and data[10].i or 0,  --左武将4头像
                oldcid4_a  = data[11] and data[11].i or 0,  --左武将4cid
                general5_a = data[12] and data[12].i or 0,  --左武将5头像
                oldcid5_a  = data[13] and data[13].i or 0,  --左武将5cid
                general6_a = data[14] and data[14].i or 0,  --左武将6头像
                oldcid6_a  = data[15] and data[15].i or 0,  --左武将6cid
                general7_a = data[16] and data[16].i or 0,  --左武将7头像
                oldcid7_a  = data[17] and data[17].i or 0,  --左武将7cid
                --右边信息
                power_b    = data[18] and data[18].i or 0,  --左玩战斗力
                pet_b      = data[19] and data[19].i or 0,  --右宠物
                general1_b = data[20] and data[20].i or 0,  --右武将1头像
                oldcid1_b  = data[21] and data[21].i or 0,  --右武将1cid
                general2_b = data[22] and data[22].i or 0,  --右武将2头像
                oldcid2_b  = data[23] and data[23].i or 0,  --右武将2cid
                general3_b = data[24] and data[24].i or 0,  --右武将3头像
                oldcid3_b  = data[25] and data[25].i or 0,  --右武将3cid
                general4_b = data[26] and data[26].i or 0,  --右武将4头像
                oldcid4_b  = data[27] and data[27].i or 0,  --右武将4cid
                general5_b = data[28] and data[28].i or 0,  --右武将5头像
                oldcid5_b  = data[29] and data[29].i or 0,  --右武将5cid
                general6_b = data[30] and data[30].i or 0,  --右武将6头像
                oldcid6_b  = data[31] and data[31].i or 0,  --右武将6cid
                general7_b = data[32] and data[32].i or 0,  --右武将7头像
                oldcid7_b  = data[33] and data[33].i or 0,  --右武将7cid
                --战斗结果
                result     = data[34] and data[34].i or 0,
                rid_a      = data[35] and data[35].i or 0,  --左玩id
                rid_b      = data[36] and data[36].i or 0,  --右玩id
            }            
        end
    end

    return {type = 8273, battleinfo = battleinfo}
end

--战斗播放
function UIUserWarOfApexBattlePlayCallBack( uireq )
    print("from UI 8274")

    local params = params_pb.ParamS()
    local data = params.params:add()
    data.i = uireq.idx
    data.s = uireq.id

    return 1, 8274, params:SerializeToString()
end

function NetUserWarOfApexBattlePlayCallBack( fd )
    print("from Net 8274")

    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    return {
        type = 8274,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),
        star = copyAttackResultPb.star
    }
end

--押注
function UIUserWarOfApexBetCallBack( uireq )
    print("from UI 8275")
    
    local params = params_pb.ParamS()
    local data1 = params.params:add()
    data1.s = uireq.id
    local data2 = params.params:add()
    data2.i = uireq.mark
    local data3 = params.params:add()
    data3.i = uireq.money

    gamedata.ext.GodComWeedBet = uireq

    return 1, 8275, params:SerializeToString()
end

function NetUserWarOfApexBetCallBack( fd )
    print("from Net 8275")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    if gamedata.ext.GodComWeedBet and gamedata.ext.GodComWeedBet.money then
        gamedata:updateRoleCoin(0-gamedata.ext.GodComWeedBet.money)
    end

    return {
        type = 8275,
        result = Result.result,
        id = gamedata.ext.GodComWeedBet and gamedata.ext.GodComWeedBet.id or 1
    }
end

--历届冠军排行榜
function UIUserWarOfApexChampoionQueryCallBack( uireq )
    print("from UI 8276")
   
    return 1, 8276, nil
end

function NetUserWarOfApexChampoionQueryCallBack( fd )
    print("from Net 8276")
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local data = params.params
    local tempdata = {alldata = {},mydata={
        rank = 0,
        name = gamedata.cache.role.name,
        championNum = 0,
    }}
    local arrnum = #data/3

    for i=1,arrnum do
        local temp = {}
        local idx = 3*(i-1)
        temp.rank = i
        temp.rid            = data[idx+2] and data[idx+2].i or 0
        temp.name           = data[idx+2] and data[idx+2].s or ""
        temp.serviceid      = data[idx+1] and data[idx+1].i or 0
        temp.servicename    = data[idx+1] and data[idx+1].s or ""
        temp.championNum    = data[idx+3] and data[idx+3].i or 0

        if temp.rid == gamedata.cache.role.rid then
            tempdata.mydata = temp
        end
        table.insert(tempdata.alldata,temp)
    end

    return { type = 8276, infodata = tempdata}
end

--赛区信息
function UIUserWarOfApexGroupInfoCallBack( uireq )
    print("from UI 8277")

    if gamedata.cache.GodCompetitionGroupInfo then
        return 0, 8277, {type = 8277, infodata = gamedata.cache.GodCompetitionGroupInfo}
    else
        return 1, 8277, nil
    end
end

function NetUserWarOfApexGroupInfoCallBack( fd )
    print("from Net 8277")
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local data = params.params
    local tempdata = {mydata={}}

    local myServerId = data[1] and data[1].i or 0
    local teamnum = (table.getTableLength(data) - 1)/2

    for i=1,teamnum do
        local idx = 2*i
        local oneserver = {
            groupid = data[idx] and data[idx].i or 0,
            serverid = data[idx+1] and data[idx+1].i or 0,
            servername = data[idx+1] and data[idx+1].s or "",
        }

        if not tempdata["group"..oneserver.groupid] then
            tempdata["group"..oneserver.groupid] = {}
        end
        table.insert(tempdata["group"..oneserver.groupid],oneserver)

        if myServerId == oneserver.serverid then
            tempdata.mydata = oneserver
        end
    end

    gamedata.cache.GodCompetitionGroupInfo = tempdata

    return { type = 8277, infodata = tempdata}
end

--星级排行榜
function UIUserWarOfApexSrarRankCallBack( uireq )
    print("from UI 8278")

    return 1, 8278, nil
end

local function GodCompetitionStarRank( data,i )
    local data = {
        rank = (i-1)/3 + 1,
        serverid   = data[i].i or 0,
        servername = data[i].s or "",
        rid        = data[i+1].i or 0,
        name       = data[i+1].s or "",
        star       = data[i+2].i or 0,
    }

    if not string.find(data.name,"S"..data.serverid.."-") and data.serverid > 0 then
        data.name = "S"..data.serverid.."-"..data.name
    end

    return data
end

function NetUserWarOfApexSrarRankCallBack( fd )
    print("from Net 8278")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local rankdata = {}
    local mydata = {rank = 0, name = gamedata.cache.role.name, star = 0}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        local data = params.params
        if v.id == 1 then
            if mydata.rank == 0 then
                mydata = GodCompetitionStarRank(data,1)
                mydata.rank = 0
            end
        else
            for i=1,#data,3 do
                local onedata = GodCompetitionStarRank(data,i)
                table.insert( rankdata, onedata)
                if onedata.rid == gamedata.cache.role.id 
                    or onedata.rid == gamedata.cache.role.id + gamedata.selectserver*1000000 then
                    mydata = onedata
                end
            end
        end
    end

    mydata.competition = gamedata.cache.godCompetitionData.competition

    return { type = 8278, rankdata = rankdata, mydata = mydata}
end

--封神赛预选赛查询
function UIUserWarOfApexRoleBattlesCallBack( uireq )
    print("from UI 8279")

    return 1, 8279, nil
end

function NetUserWarOfApexRoleBattlesCallBack( fd )
    print("from Net 8279")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.godComRoleBattles = {}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        GodCompetitionRoleBattle(params.params,v.id)
    end

    return { type = 8279, godComRoleBattles = gamedata.cache.godComRoleBattles }
end

--冠军赛查询
function UIUserWarOfApexTopInfoCallBack( uireq )
    print("from UI 8280")

    return 1, 8280, nil
end

function NetUserWarOfApexTopInfoCallBack( fd )
    print("from Net 8280")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local topinfo = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then    
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local data = ids.ids
            topinfo.selfdata = {}
            topinfo.selfdata.list = data[1] or 0
            topinfo.selfdata.rank = data[2] or 0
            topinfo.selfdata.time = data[3] or 0
        else
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            local data = params.params
            topinfo[tostring(v.id)] = {}
            local totalbetcount = 0
            
            for i = 1, (#data)/7 do
                local onebattle = {}
                local idx = 7*(i-1)
                onebattle.id     = data[idx+1].s or "0" --战斗组
                onebattle.phase  = data[idx+1].i or 0   --战斗阶段
                onebattle.p_id1  = data[idx+2].i or 0   --左玩id
                onebattle.p_id2  = data[idx+3].i or 0   --右玩id
                onebattle.result = data[idx+4].i or 0   --战斗结果
                onebattle.resultnum = data[idx+5].i or 0--战斗比分
                onebattle.bet    = data[idx+6].i or 0   --押注信息
                onebattle.betnum = data[idx+7].i or 0   --押注类型
                onebattle.betcount = tonumber(data[idx+7].s or "0") or 0 --押注次数
                totalbetcount = totalbetcount + onebattle.betcount
                topinfo[tostring(v.id)][tostring(i)] = onebattle
            end

            topinfo[tostring(v.id)].totalbetcount = totalbetcount
        end
    end

    return { type = 8280, godtop = topinfo or {} }

end

--参赛玩家信息
function UIUserWarOfApexRolesInfoCallBack( uireq )
    print("from UI 8281")

    return 1, 8281, nil
end

function NetUserWarOfApexRolesInfoCallBack( fd )
    print("from Net 8281")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.godplayers = {}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        GodCompetitionPlayers(params.params,v.id)
    end

    return { type = 8281, godplayers = gamedata.cache.godplayers or {}}

end
 �~  