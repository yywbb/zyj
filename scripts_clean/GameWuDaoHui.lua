--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/12/21
-- Time: 下午2:06
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")
local battleresult_pb = require("battleresult_pb")
local players_pb = require("players_pb")


local function getDuanweiNum( self )
    -- body
    print("getDuanweiNum====")
    local duanweiConfig = gamedata.config.wudao_part
    -- myallscorenum.allscore
    local duanweidata = {}
    for k,v in pairs(duanweiConfig) do
        print(k,v)
        table.insert(duanweidata,v)
    end

    local sortfunc = function( a,b )
        return a.id < b.id
    end

    table.sort( duanweidata, sortfunc )

    local myallscorenum = gamedata.cache.wudaohui.main.myallscorenum or 0
    local posnum= 0
    for i,v in ipairs(duanweidata) do
        local scoredata1 = gamedata.getIDandNUMs(v.num)

        if  table.getTableLength(duanweidata) == i and myallscorenum >= scoredata1[1].num then
            posnum = i
            break
        end

        if myallscorenum < scoredata1[1].num then
            
            if i == 1 then
                posnum = 0
                break
            end
            posnum = i-1
            print("iiii-==",i,myallscorenum)
            -- printT(v)
            break
        end
    end
    print("posnum===",posnum)

    gamedata.cache.role.part_point = posnum
end
-- 查询
function UIWuDaoHuiQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4100, "OverPass")
    print("UIWuDaoHuiQueryCallBack===")
    printT(uireq)
    gamedata.ext.wudaohuiupdate = uireq.update

    -- local generalstempdata = {{i=202},{i=10110,s="莫言修杰"},{i=1222200},{i=0},{i=203},{i=10115,s="独木桥上的饕"},{i=1122200},{i=0},{i=204},{i=10114,s="图门修杰"},{i=1522200},{i=0}}
    -- local basicdata = {0,1,2,2,2,2,8889,12000}
    

    -- gamedata:passKillGeneralsDate(generalstempdata)
    -- gamedata:passKillBasicDate(basicdata)
    
    -- return 0, 4100, { type = 4100, passkill = gamedata.cache.passkill}

    return 1, 4100, nil
end

function NetWuDaoHuiQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4100, "OverPass")
    print("NetWuDaoHuiQueryCallBack===")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:wudaohuiData(ids.ids)

        end


        if v.id == 1 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            gamedata.cache.wudaohui.main.rank1 = gamedata:players(playersData.players) or {}

            print("messages==ni==",v.id)
        end

        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            gamedata.cache.wudaohui.main.rank2 = gamedata:players(playersData.players) or {}

            print("messages==ni==",v.id)
        end
    end

    if gamedata.ext.wudaohuiupdate == nil and gamedata.cache.wudaohui.main then

        getDuanweiNum()
    end


    return { type = 4100, wudaohui = gamedata.cache.wudaohui.main,update = gamedata.ext.wudaohuiupdate,part_point = gamedata.cache.role.part_point}
end


-- 战斗匹配请求
function UIWuDaoHuiPiPeiCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4101, "GeneralsLove")
    printT(uireq,"UIWuDaoHuiPiPeiCallBack==")
    local idsData = ids_pb.Ids()
    -- id=0 表示匹配；id＝1 表示取消匹配
    table.insert(idsData.ids, uireq.id) 


    return 1, 4101, idsData:SerializeToString()
end

function NetWuDaoHuiPiPeiCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4101, "GeneralsLove")
    print("NetWuDaoHuiPiPeiCallBack")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    gamedata:wudaohuiData(ids.ids)
    if ids.ids[1] == 0 then
        print("战斗匹配请求")
    else
        print("战斗匹配取消请求")
    end 


    -- gamedata.cache.vipstatus.athletics_boss = gamedata.cache.vipstatus.athletics_boss +1

    return {
        type = 4101,result = ids.ids[1],
    }
end


-- 战斗匹配成功
function NetWuDaoHuiPiPeiSuceccsCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4102, "GeneralsLove")
    print("NetWuDaoHuiPiPeiSuceccsCallBack")
    
    local NetOverPassResultPb = battleresult_pb.BattleResult()
    NetOverPassResultPb:ParseFromString(fd.rbuf)


    -- gamedata.cache.vipstatus.athletics_boss = gamedata.cache.vipstatus.athletics_boss +1

    return {
        type = 4102,
        result = NetOverPassResultPb.result,
        reward = gamedata:SomethingProcess(NetOverPassResultPb.reward),
        battlereport = PickBattleResultReport(NetOverPassResultPb),

    }
end

-- 宝箱领奖
function UIWuDaoHuiBoxRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4103, "GeneralLoveUseProp")
    print("UIWuDaoHuiBoxRewardCallBack==")
    printT(uireq)
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    gamedata.ext.WudaohuiGetRewardid = uireq.id


    return 1, 4103, idsData:SerializeToString()
end

function NetWuDaoHuiBoxRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4103, "GeneralLoveUseProp")
    print("NetWuDaoHuiBoxRewardCallBack==")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    -- gamedata.cache.wudaohui.main["rewardstatue"..gamedata.ext.WudaohuiGetRewardid] = 2

    -- return { type = 4103, reward = gamedata:SomethingProcess(getData),wudaohui = gamedata.cache.wudaohui.main}
    return { type = 4103, reward = gamedata:SomethingProcess(getData)}
end


-- 仙豆大轮盘 查询
function UIWuDaoHuiLotteryQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4105, "GeneralLoveTask")
    print("UIWuDaoHuiLotteryQueryCallBack")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id or 1)

    return 1, 4105, idsData:SerializeToString()
end

function NetWuDaoHuiLotteryQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4105, "GeneralLoveTask")
    print("NetWuDaoHuiLotteryQueryCallBack")
    local  ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:wudaohuiShopData(ids.ids)

    return { type = 4105, shop = gamedata.cache.wudaohui.shop}
end



-- 仙豆大轮盘 抽奖
function UIWuDaoHuiLotteryRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4106, "OverPassShopQuery")
    print("UIWuDaoHuiLotteryRewardCallBack===")
    -- printT(uireq)

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.num or 1)

    return 1, 4106, idsData:SerializeToString()
end

function NetWuDaoHuiLotteryRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4106, "OverPassShopQuery")
    print("NetWuDaoHuiLotteryRewardCallBack===")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)
    gamedata.cache.wudaohui.shop.rewardid = 0
    local getData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata.cache.wudaohui.shop.rewardid = ids.ids[1]
        end


        if v.id == 1 then
            getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)
            print("messages==ni==",v.id)
        end

        
    end

    return { type = 4106, reward = gamedata:SomethingProcess(getData), rewardid = gamedata.cache.wudaohui.shop.rewardid}
end


-- 战报查询
function UIWuDaoHuiReportCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4104, "OverPass")
    print("UIWuDaoHuiReportCallBack===")
    -- printT(uireq)

    return 1, 4104, nil
end

function NetWuDaoHuiReportCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4104, "OverPass")
    print("NetWuDaoHuiReportCallBack===")
    gamedata.cache.wudaohui.report = {}
    local wudaohuiData = combmessages_pb.CombMessages()
    wudaohuiData:ParseFromString(fd.rbuf)
    for k,v in ipairs(wudaohuiData.messages) do
        print("wudaoid===",v.id)
        local msgnum = #wudaohuiData.messages-1
        if v.id then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:wudaohuiReport(params.params)
        end
    end

    printT(gamedata.cache.wudaohui.report,"report===")

    return { type = 4104, report = gamedata.cache.wudaohui.report}
end

-- 武道会查询
function UIWuDaoHuiDuanWeiQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4107, "DuanWei")
    print("UIWuDaoHuiDuanWeiQueryCallBack")
    -- local idsData = ids_pb.Ids()
    -- table.insert(idsData.ids, uireq.rid)

    return 1, 4107, nil
end

function NetWuDaoHuiDuanWeiQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4107, "DuanWei")
    print("NetWuDaoHuiDuanWeiQueryCallBack")
    local  ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local duanweidata = {}
    for i,v in ipairs(ids.ids) do
        table.insert(duanweidata,v)
    end

    return { type = 4107, duanweidata = duanweidata}
end

-- 段位宝箱领奖
function UIWuDaoHuiDuanWeiRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4108, "duanweireward")
    print("UIWuDaoHuiDuanWeiRewardCallBack==")
    printT(uireq)
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    -- gamedata.ext.WuDaoHuiDuanWeiRewardid = uireq.id


    return 1, 4108, idsData:SerializeToString()
end

function NetWuDaoHuiDuanWeiRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4108, "duanweireward")
    print("NetWuDaoHuiDuanWeiRewardCallBack===")

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)
    local getData = {}
    local duanweidata = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local ids = ids_pb.Ids();
            ids:ParseFromString(v.data)

            for i,v in ipairs(ids.ids) do
                table.insert(duanweidata,v)
            end
        end

        if v.id == 1 then
            getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)
            print("messages==ni==",v.id)
        end

        
    end

    return { type = 4108, reward = gamedata:SomethingProcess(getData), duanweidata = duanweidata}
end