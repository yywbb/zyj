--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-26
-- Time: 上午10:17
-- To change this template use File | Settings | File Templates.
--
function UIActivityPeentoGiftQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5401, "PeentoGiftQuery")

    -- if gamedata.cache.peentoGift and next(gamedata.cache.peentoGift) then
    --     return 0,5401,{type = 5401,data=gamedata.cache.peentoGift}
    -- end

    return 1,5401,nil
end

function NetActivityPeentoGiftQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5401, "PeentoGiftQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local reData = {}
    reData.currentDay = ids.ids[1] or 1
    reData.cpTime = ids.ids[2] or 1
    reData.getPosition = {}
    reData.getPosition[1] = ids.ids[3] or 0
    reData.getPosition[2] = ids.ids[4] or 0
    reData.getPosition[3] = ids.ids[5] or 0
    reData.getPosition[4] = ids.ids[6] or 0
    reData.getPosition[5] = ids.ids[7] or 0
    reData.getPosition[6] = ids.ids[8] or 0
    reData.getPosition[7] = ids.ids[9] or 0
    reData.getPosition[8] = ids.ids[10] or 0
    reData.silverNum = ids.ids[11] or 0

    gamedata.cache.peentoGift = reData
    return {
        type=5401,
        data=reData,
    }
end

function UIActivityPeentoGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5402, "PeentoGiftReward")
    if not gamedata.cache.peentoGift or not next(gamedata.cache.peentoGift) then
        return
    end
    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.pos)

    local cost = {cid=uireq.useId,num = -uireq.useNum,name = "蟠桃献礼抽奖"}
    gamedata.ext.peentoGiftCost = cost
    gamedata.ext.peentoGiftPos = uireq.pos

    return 1,5402,ids:SerializeToString()
end

local function getIDandNums(str)
    local i = string.find(str,",") or string.find(str,"，")
    local j = string.find(str,";") or string.find(str,"；")
    if not j then j = string.len(str)+1 end

    return tonumber(string.sub(str,1,i-1)),tonumber(string.sub(str,i+1,j-1))
end

local function getRewardIdNums(pos)
    local config = gamedata.config.peentogiftawards[tostring(gamedata.cache.peentoGift.currentDay)]
    local id,num = getIDandNums(config["reward"..pos])
    if id == 1000 then
        local silverConfig = gamedata.config.peentogift_silver
        local cuP
        local maxSilver = 0
        for k,v in pairs(silverConfig) do
            local level = tonumber(k)
            if gamedata.cache.role.level <= level then
                if not cuP then
                    cuP = k
                else
                    if tonumber(cuP) > level then
                        cuP = k
                    end
                end
            end
            if maxSilver < v.silver then
                maxSilver = v.silver
            end
        end
        num = cuP and silverConfig[cuP].silver or maxSilver
    end
    return id,num
end

function NetActivityPeentoGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5402, "PeentoGiftReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings)
    printT(reward)

    if gamedata.ext.peentoGiftPos == 0 then
        local k = 1
        for i = 1,8 do
            if not gamedata.cache.peentoGift.getPosition[i] or gamedata.cache.peentoGift.getPosition[i] < 1 then
                for j = 1,8 do
                    local id,num = getRewardIdNums(j)
                    if reward[k].cid == id and reward[k].num == num then
                        gamedata.cache.peentoGift.getPosition[i] = j
                        k = k + 1
                        break
                    end
                end
            end
        end
    else
        for j = 1,8 do
            local id,num = getRewardIdNums(j)
            if reward[1].cid == id and reward[1].num == num then
                gamedata.cache.peentoGift.getPosition[gamedata.ext.peentoGiftPos] = j
            end
            if reward[1].cid == 1000 then
                gamedata.cache.peentoGift.silverNum = reward[1].num
            end
        end
    end
    --print("消耗道具...",gamedata.ext.peentoGiftCost.cid,gamedata.ext.peentoGiftCost.num)
    gamedata:updateStaff(gamedata.ext.peentoGiftCost)
    return {
        type=5402,
        reward = reward,
        data= gamedata.cache.peentoGift,
        propNum = gamedata.cache.props[gamedata.ext.peentoGiftCost.cid] and gamedata.cache.props[gamedata.ext.peentoGiftCost.cid].num or 0
    }
end

function UIActivityPeentoGiftResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5403, "PeentoGiftReward")
    return 1,5403,nil
end

function NetActivityPeentoGiftResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5403, "PeentoGiftReward")
    gamedata.cache.peentoGift.cpTime = gamedata.cache.peentoGift.cpTime + 1
    for i = 1,8 do 
        gamedata.cache.peentoGift.getPosition[i] = 0
        gamedata.cache.peentoGift.silverNum = 0
    end
    return {
        type=5403,
        data= gamedata.cache.peentoGift,
    }
end
