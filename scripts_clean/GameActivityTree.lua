--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-26
-- Time: 上午10:17
-- To change this template use File | Settings | File Templates.
--

function UIActivityTreeReponse(fd)

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local alldata = gamedata.cache.tree
    alldata.reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            alldata.main = {}
            alldata.main.point = ids.ids[1] or 0
            alldata.main.box1 = ids.ids[2] or 0
            alldata.main.box2 = ids.ids[3] or 0
            alldata.main.box3 = ids.ids[4] or 0
            alldata.main.waterbuy = ids.ids[5] or 0
            alldata.main.freshtimes = ids.ids[6] or 0
            alldata.main.tasktimes = ids.ids[7] or 0
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            alldata.tasks = {}
            for i=1,#ids.ids,5 do
                print(i)
                if ids.ids[i] > 0 then
                    table.insert(alldata.tasks,{
                            iid = ids.ids[i],
                            cid = ids.ids[i+1],
                            process = ids.ids[i+2],
                            kind = ids.ids[i+3],
                            status = ids.ids[i+4],
                        })
                end
            end

        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            alldata.reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    alldata.pronum = gamedata.cache.props[20604] and gamedata.cache.props[20604].num or 0
    
    return alldata
end

function UIActivityTreeQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5323, "TreeQuery")

    if next(gamedata.cache.tree) and uireq.param and uireq.param == "main" then
        return 0,5323,{type = 5323,data={main = gamedata.cache.tree.main}}
    end

    return 1,5323,nil
end

function NetActivityTreeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5323, "TreeQuery")
    
    return {
        type=5323,
        data=UIActivityTreeReponse(fd),
    }
end

function UIActivityTreeWaterCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5324, "TreeWater")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.num)

    gamedata.ext.TreeWaternum = uireq.num

    return 1,5324,ids:SerializeToString()
end

function NetActivityTreeWaterCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5324, "TreeWater")
    
    gamedata:updateStaff({cid = 20604,num=0-gamedata.ext.TreeWaternum})
    return {
        type=5324,
        data=UIActivityTreeReponse(fd),
    }
end


function UIActivityTreetaskCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5325, "Treetask")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.id)

    return 1,5325,ids:SerializeToString()
end

function NetActivityTreetaskCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5325, "Treetask")
    
    return {
        type=5325,
        data=UIActivityTreeReponse(fd),
    }
end


function UIActivityTreetaskcancelCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5327, "Treetaskcancel")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.id)

    return 1,5327,ids:SerializeToString()
end

function NetActivityTreetaskcancelCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5327, "Treetaskcancel")
    
    return {
        type=5327,
        data=UIActivityTreeReponse(fd),
    }
end


function UIActivityTreetaskGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5326, "TreetaskGet")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.id)

    return 1,5326,ids:SerializeToString()
end

function NetActivityTreetaskGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5326, "TreetaskGet")
    
    return {
        type=5326,
        data=UIActivityTreeReponse(fd),
    }
end


function UIActivityTreetaskFreshCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5329, "TreetaskFresh")

    return 1,5329,nil
end

function NetActivityTreetaskFreshCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5329, "TreetaskFresh")
    local config = gamedata.config.buycount_price
    local key = "zhongshu_tasks"
    local count = gamedata.cache.tree.main.freshtimes+1
    local cost = config[tostring(count)] and config[tostring(count)][key] or config[tostring(table.getTableLength(config))][key]

    gamedata:updateStaff({cid = 1001,num = 0-cost})

    return {
        type=5329,
        data=UIActivityTreeReponse(fd),
    }
end

function UIActivityWaterBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5328, "WaterBuy")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.num)

    gamedata.ext.WaterBuycost = uireq.gold

    return 1,5328,ids:SerializeToString()
end

function NetActivityWaterBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5328, "WaterBuy")

    gamedata:updateStaff({cid = 1001,num = 0-gamedata.ext.WaterBuycost})

    return {
        type=5328,
        data=UIActivityTreeReponse(fd),
    }
end

function UIActivityBoxrewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5330, "Boxreward")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.id)

    return 1,5330,ids:SerializeToString()
end

function NetActivityBoxrewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5330, "Boxreward")

    return {
        type=5330,
        data=UIActivityTreeReponse(fd),
    }
end

function UIActivityZhongshuRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5331, "ZhongshuRank")

    return 1,5331,nil
end

function NetActivityZhongshuRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5331, "ZhongshuRank")


    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local players = {}
    local myrank = 0
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            players = gamedata:players(playersData.players)
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            myrank = ids.ids[1] or 0
        end
    end

    return { type = 5331,players = players,myrank=myrank}
end


-----------------------------------------------------------



