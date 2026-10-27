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
local generals_pb = require("generals_pb")

function UIGeneralLoveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3670, "GeneralLove")
    print("UIGeneralLoveCallBack===")
    -- printT(uireq)

    -- if gamedata.cache.generalslove[uireq.cid] and gamedata.cache.generalslove[uireq.cid].exp then
    --     return 0,3670,{type = 3760, data = gamedata.cache.generalslove[uireq.cid] }
    -- end

    local idsData = ids_pb.Ids()
    if uireq.cid then
        print("uireq has cid")
        table.insert(idsData.ids, uireq.cid)
        gamedata.ext.generalsloveid =  uireq.cid
    end

    return 1, 3670, idsData:SerializeToString()
end

function NetGeneralLoveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3670, "GeneralLove")
    local  Result = ids_pb.Ids();
    Result:ParseFromString(fd.rbuf)

    gamedata:generalLoveData(Result.ids)
    local props = {20201,20208,20211,20220}
    local arr = {}
    for i,v in ipairs(props) do
        print(i,v)
        if gamedata.cache.props[tonumber(v)] then
            print("propsid==222",v)
            table.insert(arr,gamedata.cache.props[tonumber(v)])
        else
            print("propsid=is=not=",v)
            table.insert(arr,{cid = v,num = 0})
        end
    end

    -- for i=20201,20220 do
    --     if gamedata.cache.props[tonumber(i)] then
    --         print("propsid==222",i)
    --         table.insert(arr,gamedata.cache.props[tonumber(i)])
    --     else
    --         print("propsid=is=not=",i)
    --         table.insert(arr,{cid = i,num = 0})
    --     end 
    -- end

    return { type = 3670, favorite = gamedata.cache.generalslove.showdata, gifts = arr}
end

function UIGeneralLoveExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3675, "GeneralLoveExchange")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.cid1)
    table.insert(idsData.ids, uireq.cid2)

    gamedata.ext.generalsloveExchangeid = {cid1=uireq.cid1,cid2=uireq.cid2}

    return 1, 3675, idsData:SerializeToString()
end

function NetGeneralLoveExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3675, "GeneralLoveExchange")
    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)

    local getGenerals = gamedata:Generals(GeneralsData.generals)

    local cid1 = gamedata.ext.generalsloveExchangeid.cid1
    local cid2 = gamedata.ext.generalsloveExchangeid.cid2
    local level1 = gamedata.cache.generalslove.alldata[cid1]
    local level2 = gamedata.cache.generalslove.alldata[cid2]

    gamedata.cache.generalslove.alldata[cid1] = level2
    gamedata.cache.generalslove.alldata[cid2] = level1

    local sourcelevel = gamedata.cache.generalslove.alldata[cid1].level
    local destlevel = gamedata.cache.generalslove.alldata[cid2].level
    local maxlevel = math.max(sourcelevel,destlevel)
    local levelconfig = gamedata.config.favorable_level[tostring(maxlevel)]
    local golddes = levelconfig and levelconfig.favor_exchange_price or "1001,0;"
    local consume = gamedata.getIDandNUMs(golddes)
    printT(consume)
    gamedata:updateStaff({cid = consume[1].cid,num=0-consume[1].num})

    return { type = 3675, allgeneral = gamedata.cache.generalslove.alldata}
end

function UIGeneralsLoveQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3671, "GeneralsLove")
    print("UIGeneralsLoveQueryCallback")
    return 1, 3671, nil
end

function NetGeneralsLoveQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3671, "GeneralsLove")
    -- print("NetGeneralsLoveQueryCallback")
    -- printT(makeAllGeneralsTemp())
    local  Result = ids_pb.Ids();
    Result:ParseFromString(fd.rbuf)

    gamedata:generalsLove(Result)
    for k,v in pairs(gamedata.cache.generalslove.alldata) do
        local has = false
        for k1,v1 in pairs(makeAllGeneralsTemp()) do
            if gamedata.config.general[tostring(v1.cid)].init_cid and gamedata.config.general[tostring(v1.cid)].init_cid == v.cid then
                v.ison = v1.ison or 0
                has = true
                v.hascid = v1.cid
            elseif gamedata.config.general[tostring(v1.cid)].orange_id and gamedata.config.general[tostring(v1.cid)].orange_id == v.cid then
                v.ison = v1.ison or 0
                has = true
                v.hascid = v1.cid
            elseif gamedata.config.general[tostring(v1.cid)].generalid2 and gamedata.config.general[tostring(v1.cid)].generalid2 == v.cid then
                v.ison = v1.ison or 0
                has = true
                v.hascid = v1.cid
            elseif v.cid == v1.cid then
                v.ison = v1.ison or 0
                has = true
                v.hascid = v1.cid
            elseif gamedata.config.general[tostring(v1.cid)].partner_id and gamedata.config.general[tostring(v1.cid)].partner_id == v.cid then
                v.ison = v1.ison or 0
                has = true
                v.hascid = v1.cid
            end
        end
        if has == false then
            v.ison = -1
            v.hascid = 0
        end
        
    end

    return { type = 3671, allgeneral = gamedata.cache.generalslove.alldata }
end


function UIGeneralLoveUsePropCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3672, "GeneralLoveUseProp")
    print("UIGeneralLoveUsePropCallBack==")
    -- printT(uireq)
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.cid)
    for k,v in pairs(uireq.props) do
        table.insert(idsData.ids, v.cid)
        table.insert(idsData.ids, v.num)
    end


    return 1, 3672, idsData:SerializeToString()
end

function NetGeneralLoveUsePropCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3672, "GeneralLoveUseProp")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    for k,v in ipairs(UsePorp.messages) do
        print("messages==in=",v.id)
        if v.id == 1 then
            print("messages====",v.id)
            if v.data then
                print("messages==v.id=1...in")
                printT(v.data)

                local GeneralsData = generals_pb.Generals()
                GeneralsData:ParseFromString(v.data)

                local getGenerals = gamedata:Generals(GeneralsData.generals)
            end
        end
        if v.id == 2 then
            -- print("messages====",v.id)
            -- printT(v.data)
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:generalLoveUseProps(ids.ids)

            print("messages====22222")
            -- printT(gamedata.cache.generalslove.useprops)

            for k,v in pairs(gamedata.cache.generalslove.useprops.data) do
                printT(v)
                gamedata:updateprops({cid = v.cid, num = -v.num, update = true})
                print("end===props")
            end
        end

        if v.id == 0 then
            -- print("messages===0000")
            -- printT(v.data)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:generalLoveData(ids.ids)
        end
    end

    local props = {20201,20208,20211,20220}
    local arr = {}
    for i,v in ipairs(props) do
        print(i,v)
        if gamedata.cache.props[tonumber(v)] then
            print("propsid==222",v)
            table.insert(arr,gamedata.cache.props[tonumber(v)])
        else
            print("propsid=is=not=",v)
            table.insert(arr,{cid = v,num = 0})
        end
    end

    -- local arr = {}
    -- for i=20201,20220 do
    --     if gamedata.cache.props[tonumber(i)] then
    --         print("propsid==222",i)
    --         table.insert(arr,gamedata.cache.props[tonumber(i)])
    --     else
    --         print("propsid=is=not=",i)
    --         table.insert(arr,{cid = i,num = 0})
    --     end 
    -- end


    return { type = 3672, favorite = gamedata.cache.generalslove.showdata, gifts = arr,
    useprops = gamedata.cache.generalslove.useprops
    }
end



function UIGeneralLoveTaskCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3673, "GeneralLoveTask")
    print("UIGeneralLoveTaskCallBack")
    return 1, 3673, nil
end

function NetGeneralLoveTaskCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3673, "GeneralLoveTask")
    print("NetGeneralLoveTaskCallBack")
    local  Result = ids_pb.Ids();
    Result:ParseFromString(fd.rbuf)

    gamedata:generalLoveTask(Result.ids)

    return { type = 3673, data = gamedata.cache.generalslovetask}
end


function UIGeneralLoveTaskRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3674, "GeneralLoveTaskReward")
    print("UIGeneralLoveTaskRewardCallBack===")
    -- printT(uireq)

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.cid)

    gamedata.ext.GeneralLoveTaskRewardid = uireq

    return 1, 3674, idsData:SerializeToString()
end

function NetGeneralLoveTaskRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3674, "GeneralLoveTaskReward")
    print("NetGeneralLoveTaskRewardCallBack===")
    local  idsData = ids_pb.Ids();
    idsData:ParseFromString(fd.rbuf)

    for k,v in pairs(idsData.ids) do
        print(k,v)
    end
    -- local config = gamedata.config.favorable_task
    -- gamedata.cache.role.maxstamina = gamedata.cache.role.maxstamina + config
    
    gamedata:generalLoveTaskSet(idsData.ids,gamedata.ext.GeneralLoveTaskRewardid.cid)


    return { type = 3674, data = gamedata.cache.generalslovetask, reward = gamedata.ext.GeneralLoveTaskRewardid.text}
end


 �&  