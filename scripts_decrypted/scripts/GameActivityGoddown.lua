--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/7/4
-- Time: 14:52
-- To change this template use File | Settings | File Templates.


local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local players_pb = require("players_pb")

function UIGodDownQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4300, "GodDownQuery")

    return 1, 4300, nil
end

function NetGodDownQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4300, "GodDownQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:GoddownStatus(ids.ids)

    return { type = 4300, goddownstatus = gamedata.cache.goddownstatus}

end

function UIGodDownTributeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4301, "GodDownQuery")

    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 0)

    gamedata.ext.GodDownTributeGold = uireq.xgold or 0

    if gamedata.ext.GodDownTributeGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 4301, doData:SerializeToString()

end

function NetGodDownTributeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4301, "GodDownQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil
    local id = 0
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:GoddownStatus(ids.ids)
        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        elseif v.id == 3 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            id = ids.ids[1] or 0
        end
    end


    if gamedata.ext.GodDownTributeGold and gamedata.ext.GodDownTributeGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.GodDownTributeGold,"天神下凡上香",1)
    end

    return { type = 4301, goddownstatus = gamedata.cache.goddownstatus, reward = reward, id = id}

end

function UIGodDownTributeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4302, "GodDownTributeReward")

    return 1, 4302, nil
end

function NetGodDownTributeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4302, "GodDownTributeReward")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:GoddownStatus(ids.ids)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 4302, goddownstatus = gamedata.cache.goddownstatus, reward = reward}
end

function UIGodDownTributeImmediateCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4303, "GodDownTributeImmediate")

    if uireq.xgold and uireq.xgold > 0 then
        if uireq.xgold > gamedata.cache.role.gold then
            return 0,503,{type = 503, msgtype = "shortgold" }
        end
    end

    return 1, 4303, nil
end

function NetGodDownTributeImmediateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4303, "GodDownTributeImmediate")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:GoddownStatus(ids.ids)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 4303, goddownstatus = gamedata.cache.goddownstatus, reward = reward}
end

function UIGodDownGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4304, "GodDownGift")

    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 1)

    return 1, 4304, doData:SerializeToString()
end

function NetGodDownGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4304, "GodDownGift")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:GoddownStatus(ids.ids)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 4304, goddownstatus = gamedata.cache.goddownstatus, reward = reward}
end

-- 天神下凡商店查询
function UIGodDownShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4310, "GowDownShop")
    print("UIGodDownShopQueryCallBack...")
    -- local data = {100,2}
    -- gamedata:duanwunlunpanData(data)
        
    -- return 0, 4310, { type = 4310, maindata = gamedata.cache.duanwunlunpan.main, }

    return 1, 4310, nil
end

function NetGodDownShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4310, "GowDownShop")
    print("NetGodDownShopQueryCallBack==")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:godDownShopData(ids.ids)

    
    return { type = 4310, shopdata = gamedata.cache.goddownshop,}
end
-- 天神下凡兑换
function UIGodDownShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4311, "GowDownShopReward")
    print("UIGodDownShopRewardCallBack...")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id) 
    if uireq.num then
        table.insert(idsData.ids, uireq.num) 
    end


    return 1, 4311, idsData:SerializeToString()
end

function NetGodDownShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4311, "GowDownShopReward")
    print("NetGodDownShopRewardCallBack==")

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    local rewardData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:godDownShopData(ids.ids)
        end


        if v.id == 1 then
            rewardData = somethings_pb.SomeThings()
            rewardData:ParseFromString(v.data)
            print("messages==ni==",v.id)
        end

    end

    return { type = 4311, shopdata = gamedata.cache.goddownshop,reward = gamedata:SomethingProcess(rewardData)}
end

-- 天神下凡排行榜查询
function UIGodDownRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4320, "GowDownShop")
    print("UIGodDownRankQueryCallBack...")
    -- local data = {100,2}
    -- gamedata:duanwunlunpanData(data)
        
    -- return 0, 4320, { type = 4320, maindata = gamedata.cache.duanwunlunpan.main, }

    return 1, 4320, nil
end

function NetGodDownRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4320, "GowDownShop")
    print("NetGodDownRankQueryCallBack==")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata.cache.goddownrank.myallscore = ids.ids[1] or 0
        end


        if v.id == 1 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            gamedata.cache.goddownrank.rank = gamedata:players(playersData.players) or {}
        end

    end

    return { type = 4320, rankdata = gamedata.cache.goddownrank.rank, mydata = gamedata.cache.goddownrank.myallscore}
end


--
--K_
function UIKGodDownQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4870, "KGodDownQuery")

    return 1, 4870, nil
end

function NetKGodDownQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4870, "KGodDownQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:k_GoddownStatus(ids.ids)

    return { type = 4870, goddownstatus = gamedata.cache.k_goddownstatus}

end

function UIKGodDownTributeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4871, "KGodDownQuery")

    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 0)

    gamedata.ext.k_GodDownTributeGold = uireq.xgold or 0

    if gamedata.ext.k_GodDownTributeGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 4871, doData:SerializeToString()

end

function NetKGodDownTributeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4871, "KGodDownQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil
    local id = 0
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:k_GoddownStatus(ids.ids)
        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        elseif v.id == 3 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            id = ids.ids[1] or 0
        end
    end


    if gamedata.ext.k_GodDownTributeGold and gamedata.ext.k_GodDownTributeGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.k_GodDownTributeGold,"跨服天神下凡上香",1)
    end

    return { type = 4871, goddownstatus = gamedata.cache.k_goddownstatus, reward = reward, id = id}

end

function UIKGodDownTributeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4872, "KGodDownTributeReward")

    return 1, 4872, nil
end

function NetKGodDownTributeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4872, "KGodDownTributeReward")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:k_GoddownStatus(ids.ids)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 4872, goddownstatus = gamedata.cache.k_goddownstatus, reward = reward}
end

function UIKGodDownTributeImmediateCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4873, "KGodDownTributeImmediate")

    if uireq.xgold and uireq.xgold > 0 then
        if uireq.xgold > gamedata.cache.role.gold then
            return 0,503,{type = 503, msgtype = "shortgold" }
        end
    end

    return 1, 4873, nil
end

function NetKGodDownTributeImmediateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4873, "KGodDownTributeImmediate")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:k_GoddownStatus(ids.ids)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 4873, goddownstatus = gamedata.cache.k_goddownstatus, reward = reward}
end

function UIKGodDownGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4874, "KGodDownGift")

    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 1)

    return 1, 4874, doData:SerializeToString()
end

function NetKGodDownGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4874, "KGodDownGift")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:k_GoddownStatus(ids.ids)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 4874, goddownstatus = gamedata.cache.k_goddownstatus, reward = reward}
end

-- 天神下凡商店查询
function UIKGodDownShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4875, "KGowDownShop")
    print("UIKGodDownShopQueryCallBack...")


    return 1, 4875, nil
end

function NetKGodDownShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4875, "KGowDownShop")
    print("NetKGodDownShopQueryCallBack==")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:k_godDownShopData(ids.ids)


    return { type = 4875, shopdata = gamedata.cache.k_goddownshop,}
end
-- 天神下凡兑换
function UIKGodDownShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4876, "KGowDownShopReward")
    print("UIKGodDownShopRewardCallBack...")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    if uireq.num then
        table.insert(idsData.ids, uireq.num)
    end


    return 1, 4876, idsData:SerializeToString()
end

function NetKGodDownShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4876, "KGowDownShopReward")
    print("NetKGodDownShopRewardCallBack==")

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    local rewardData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:k_godDownShopData(ids.ids)
        end


        if v.id == 1 then
            rewardData = somethings_pb.SomeThings()
            rewardData:ParseFromString(v.data)
            print("messages==ni==",v.id)
        end

    end

    return { type = 4876, shopdata = gamedata.cache.k_goddownshop,reward = gamedata:SomethingProcess(rewardData)}
end

-- 天神下凡排行榜查询
local params_pb = require("params_pb")
function UIKGodDownRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4877, "KGowDownShop")
    print("UIKGodDownRankQueryCallBack...")


    return 1, 4877, nil
end

function NetKGodDownRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4877, "KGowDownShop")
    print("NetKGodDownRankQueryCallBack==")

    local rankdata = params_pb.ParamS()
    rankdata:ParseFromString(fd.rbuf)

    gamedata.cache.k_goddownrank.rank = {}
    gamedata.cache.k_goddownrank.myallscore = rankdata.params[1] and rankdata.params[1].i or 0
    for i = 1, ((#rankdata.params-1)/3) do
        gamedata.cache.k_goddownrank.rank[tostring(i)] = {}
        gamedata.cache.k_goddownrank.rank[tostring(i)].serviceid = rankdata.params[3*i-1] and rankdata.params[3*i-1].i or 0
        gamedata.cache.k_goddownrank.rank[tostring(i)].rid = rankdata.params[3*i] and rankdata.params[3*i].i or 0
        gamedata.cache.k_goddownrank.rank[tostring(i)].name = rankdata.params[3*i] and rankdata.params[3*i].s or ""
        gamedata.cache.k_goddownrank.rank[tostring(i)].params = {}
        gamedata.cache.k_goddownrank.rank[tostring(i)].params["1"] = {}
        gamedata.cache.k_goddownrank.rank[tostring(i)].params["1"].i = rankdata.params[3*i+1] and rankdata.params[3*i+1].i or 0
    end
    return { type = 4877, rankdata = gamedata.cache.k_goddownrank.rank, mydata = gamedata.cache.k_goddownrank.myallscore}
end



--cp todo
local GodDown_cpnum = 0
local GodDown_cpday = 0
function UICPGodDownQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5010, "GodDownQuery")

    return 1, 5010, nil
end

function NetCPGodDownQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5010, "GodDownQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    if ids.ids then
        GodDown_cpnum = ids.ids[1] or 0
        GodDown_cpday = ids.ids[2] or 0
        gamedata.cache.goddownstatus.point = ids.ids[3] or 0
        gamedata.cache.goddownstatus.allpoint = ids.ids[4] or 0
        gamedata.cache.goddownstatus.selected = ids.ids[5] or 0
        gamedata.cache.goddownstatus.status = ids.ids[6] or 0
        gamedata.cache.goddownstatus.cdtime = ids.ids[7] or 0
        gamedata.cache.goddownstatus.boxstatus = {}
        for i = 8,#ids.ids do
            gamedata.cache.goddownstatus.boxstatus[tostring(i-7)] = ids.ids[i] or 0
        end
    end

    return { type = 5010, goddownstatus = gamedata.cache.goddownstatus,cpnum = GodDown_cpnum,cpday = GodDown_cpday}

end

function UICPGodDownTributeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5011, "GodDownQuery")

    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 0)

    gamedata.ext.GodDownTributeGold = uireq.xgold or 0

    if gamedata.ext.GodDownTributeGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 5011, doData:SerializeToString()

end

function NetCPGodDownTributeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5011, "GodDownQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil
    local id = 0
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            if ids.ids then
                GodDown_cpnum = ids.ids[1] or 0
                GodDown_cpday = ids.ids[2] or 0
                gamedata.cache.goddownstatus.point = ids.ids[3] or 0
                gamedata.cache.goddownstatus.allpoint = ids.ids[4] or 0
                gamedata.cache.goddownstatus.selected = ids.ids[5] or 0
                gamedata.cache.goddownstatus.status = ids.ids[6] or 0
                gamedata.cache.goddownstatus.cdtime = ids.ids[7] or 0
                gamedata.cache.goddownstatus.boxstatus = {}
                for i = 8,#ids.ids do
                    gamedata.cache.goddownstatus.boxstatus[tostring(i-7)] = ids.ids[i] or 0
                end
            end
        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        elseif v.id == 3 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            id = ids.ids[1] or 0
        end
    end


    if gamedata.ext.GodDownTributeGold and gamedata.ext.GodDownTributeGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.GodDownTributeGold,"天神下凡上香",1)
    end

    return { type = 5011, goddownstatus = gamedata.cache.goddownstatus, reward = reward, id = id,cpnum = GodDown_cpnum,cpday = GodDown_cpday}

end

function UICPGodDownTributeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5012, "GodDownTributeReward")

    return 1, 5012, nil
end

function NetCPGodDownTributeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5012, "GodDownTributeReward")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            if ids.ids then
                GodDown_cpnum = ids.ids[1] or 0
                GodDown_cpday = ids.ids[2] or 0
                gamedata.cache.goddownstatus.point = ids.ids[3] or 0
                gamedata.cache.goddownstatus.allpoint = ids.ids[4] or 0
                gamedata.cache.goddownstatus.selected = ids.ids[5] or 0
                gamedata.cache.goddownstatus.status = ids.ids[6] or 0
                gamedata.cache.goddownstatus.cdtime = ids.ids[7] or 0
                gamedata.cache.goddownstatus.boxstatus = {}
                for i = 8,#ids.ids do
                    gamedata.cache.goddownstatus.boxstatus[tostring(i-7)] = ids.ids[i] or 0
                end
            end
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 5012, goddownstatus = gamedata.cache.goddownstatus, reward = reward, cpnum = GodDown_cpnum,cpday = GodDown_cpday}
end

function UICPGodDownTributeImmediateCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5013, "GodDownTributeImmediate")

    if uireq.xgold and uireq.xgold > 0 then
        if uireq.xgold > gamedata.cache.role.gold then
            return 0,503,{type = 503, msgtype = "shortgold" }
        end
    end

    return 1, 5013, nil
end

function NetCPGodDownTributeImmediateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5013, "GodDownTributeImmediate")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            if ids.ids then
                GodDown_cpnum = ids.ids[1] or 0
                GodDown_cpday = ids.ids[2] or 0
                gamedata.cache.goddownstatus.point = ids.ids[3] or 0
                gamedata.cache.goddownstatus.allpoint = ids.ids[4] or 0
                gamedata.cache.goddownstatus.selected = ids.ids[5] or 0
                gamedata.cache.goddownstatus.status = ids.ids[6] or 0
                gamedata.cache.goddownstatus.cdtime = ids.ids[7] or 0
                gamedata.cache.goddownstatus.boxstatus = {}
                for i = 8,#ids.ids do
                    gamedata.cache.goddownstatus.boxstatus[tostring(i-7)] = ids.ids[i] or 0
                end
            end
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 5013, goddownstatus = gamedata.cache.goddownstatus, reward = reward, cpnum = GodDown_cpnum,cpday = GodDown_cpday}
end

function UICPGodDownGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5014, "GodDownGift")

    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 1)

    return 1, 5014, doData:SerializeToString()
end

function NetCPGodDownGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5014, "GodDownGift")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            if ids.ids then
                GodDown_cpnum = ids.ids[1] or 0
                GodDown_cpday = ids.ids[2] or 0
                gamedata.cache.goddownstatus.point = ids.ids[3] or 0
                gamedata.cache.goddownstatus.allpoint = ids.ids[4] or 0
                gamedata.cache.goddownstatus.selected = ids.ids[5] or 0
                gamedata.cache.goddownstatus.status = ids.ids[6] or 0
                gamedata.cache.goddownstatus.cdtime = ids.ids[7] or 0
                gamedata.cache.goddownstatus.boxstatus = {}
                for i = 8,#ids.ids do
                    gamedata.cache.goddownstatus.boxstatus[tostring(i-7)] = ids.ids[i] or 0
                end
            end
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 5014, goddownstatus = gamedata.cache.goddownstatus, reward = reward, cpnum = GodDown_cpnum,cpday = GodDown_cpday}
end
--
-- 天神下凡商店查询
local GodDownShop_cpnum = 0
local GodDownShop_cpday = 0
function UICPGodDownShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5015, "GowDownShop")
    print("UIGodDownShopQueryCallBack...")

    return 1, 5015, nil
end

function NetCPGodDownShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5015, "GowDownShop")
    print("NetGodDownShopQueryCallBack==")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    GodDownShop_cpnum = ids.ids[1] or 0
    GodDownShop_cpday = ids.ids[2] or 0

    gamedata.cache.goddownshop.props = {}
    gamedata.cache.goddownshop.goddownnum = ids.ids[3] or 0

    for k,v in ipairs(ids.ids) do
        if tonumber(k) > 3 then
            table.insert(gamedata.cache.goddownshop.props,{})
            gamedata.cache.goddownshop.props[k-3].index = k-3
            gamedata.cache.goddownshop.props[k-3].num = ids.ids[k]
        end
    end

    return { type = 5015, shopdata = gamedata.cache.goddownshop, cpnum = GodDownShop_cpnum, cpday = GodDownShop_cpday}
end
-- 天神下凡兑换
function UICPGodDownShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5016, "GowDownShopReward")
    print("UIGodDownShopRewardCallBack...")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    if uireq.num then
        table.insert(idsData.ids, uireq.num)
    end


    return 1, 5016, idsData:SerializeToString()
end

function NetCPGodDownShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5016, "GowDownShopReward")
    print("NetGodDownShopRewardCallBack==")

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    local rewardData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:godDownShopData(ids.ids)
        end


        if v.id == 1 then
            rewardData = somethings_pb.SomeThings()
            rewardData:ParseFromString(v.data)
            print("messages==ni==",v.id)
        end

    end

    return { type = 5016, shopdata = gamedata.cache.goddownshop,reward = gamedata:SomethingProcess(rewardData),cpnum = GodDownShop_cpnum, cpday = GodDownShop_cpday}
end

-- 天神下凡排行榜查询
local GodDownRank_cpnum = 0
local GodDownRank_cpday = 0
function UICPGodDownRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5017, "GowDownShop")
    print("UIGodDownRankQueryCallBack...")


    return 1, 5017, nil
end

function NetCPGodDownRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5017, "GowDownShop")
    print("NetGodDownRankQueryCallBack==")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            GodDownRank_cpnum = ids.ids[1] or 0
            GodDownRank_cpday = ids.ids[2] or 0
            gamedata.cache.goddownrank.myallscore = ids.ids[3] or 0
        end


        if v.id == 1 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            gamedata.cache.goddownrank.rank = gamedata:players(playersData.players) or {}
        end

    end

    return { type = 5017, rankdata = gamedata.cache.goddownrank.rank, mydata = gamedata.cache.goddownrank.myallscore,cpnum = GodDownRank_cpnum,cpday = GodDownRank_cpday}
end

 �q  