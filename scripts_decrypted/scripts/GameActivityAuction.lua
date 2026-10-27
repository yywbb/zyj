local _ids_pb = require("ids_pb")
local _somethings_pb = require("somethings_pb")
local _combmessages_pb = require("combmessages_pb")

function UIActivityAuctionQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5410, "UIActivityAuctionQueryCallBack")
    if uireq.cid then
        local idsData = _ids_pb.Ids()
        table.insert(idsData.ids, uireq.cid)
        gamedata.ext.antiqueId = uireq.cid

        return 1, 5410, idsData:SerializeToString()
    else
        return 1, 5410, nil
    end
end

function NetActivityAuctionQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5410, "NetActivityAuctionQueryCallBack")

    local _ids = _ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    local _auctionStatus = _ids.ids[1] or 0
    local _auctionId = _ids.ids[2]
    -- local _currentAuction = _ids.ids[3]
    local _queueId = 0
    local _auctionQueue = {}

    for i = 3, #_ids.ids do
        if math.mod(i, 5) == 3 then
            _queueId = _ids.ids[i]
            _auctionQueue[_ids.ids[i]] = {}
        else
            if math.mod(i, 5) == 4 then
                _auctionQueue[_queueId].npcId = _ids.ids[i]
            elseif math.mod(i, 5) == 0 then
                _auctionQueue[_queueId].price = _ids.ids[i]
            elseif math.mod(i, 5) == 1 then
                _auctionQueue[_queueId].trueOrFalse = _ids.ids[i]
            elseif math.mod(i, 5) == 2 then
                _auctionQueue[_queueId].time = _ids.ids[i]
            end
        end
    end

    local _isUpdata = 0
    if gamedata.ext.antiqueId then
        gamedata:updateStaff({cid = gamedata.ext.antiqueId, num = -1})
        gamedata.ext.antiqueId = nil
        _isUpdata = 1
    end

    return {type = 5410, 
            auctionStatus = _auctionStatus,
            auctionId = _auctionId,
            currentAuction = _currentAuction,
            auctionQueue = _auctionQueue,
            isUpdata = _isUpdata}
end

function UIActivityAuctionClinchCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5411, "UIActivityAuctionClinchCallBack")

    return 1, 5411, nil
end

function NetActivityAuctionClinchCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5411, "NetActivityAuctionClinchCallBack")

    local _combmessage = _combmessages_pb.CombMessages()
    local _ids = _ids_pb.Ids()
    local _someThings1 = _somethings_pb.SomeThings()
    local _someThings2 = _somethings_pb.SomeThings()

    _combmessage:ParseFromString(fd.rbuf)

    for k,v in ipairs(_combmessage.messages) do
        if v.id == 0 then
            _ids:ParseFromString(v.data)
        elseif v.id == 1 then
            _someThings1:ParseFromString(v.data)
        elseif v.id == 2 and _ids.ids[2] == 1 then
            _someThings2:ParseFromString(v.data)
        end
    end

    local _reward1 = gamedata:SomethingProcess(_someThings1)
    local _reward2 = nil

    if _ids.ids[2] == 1 then
        _reward2 = gamedata:SomethingProcess(_someThings2)
    end

    return {type = 5411, npcId = _ids.ids[1], isSpecial = _ids.ids[2], reward1 = _reward1, reward2 = _reward2}
end

function UIActivityAuctionRecordingCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5412, "UIActivityAuctionRecordingCallBack")
    
    return 1, 5412, nil
end

function NetActivityAuctionRecordingCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5412, "NetActivityAuctionRecordingCallBack")

    local _ids = _ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    local _recordingTable = {}

    if #_ids.ids > 0 then
        local _recordingNum = 0
        local _tempNum1 = 0
        local _tempNum2 = 0
        local _recordingDetailedNum = 0
        local _continue = true

        local isonekey = false
        for i = 1, #_ids.ids do
            _continue = true
            if _ids.ids[i] == -1 or _ids.ids[i] == -2 then
                _recordingNum = _recordingNum + 1
                _recordingTable[_recordingNum] = {}
                _recordingTable[_recordingNum].recording = {}
                _tempNum1 = 1
                _tempNum2 = 1
                _recordingDetailedNum = 1
                _continue = false
                if _ids.ids[i] == -1  then
                    isonekey = false
                else
                    isonekey = true
                end    
            end

            print("i :".._ids.ids[i])

            if _continue then

                if isonekey == true then
                    if _tempNum1 == 1 then
                        _tempNum1 = _tempNum1 + 1
                        _recordingTable[_recordingNum].startTime = _ids.ids[i]
                    elseif _tempNum1 == 2 then
                        _tempNum1 = _tempNum1 + 1
                        _recordingTable[_recordingNum].auctionId = _ids.ids[i]
                    elseif _tempNum1 == 3 then
                        _tempNum1 = _tempNum1 + 1
                        _recordingTable[_recordingNum].trueOrFalse = _ids.ids[i]
                        -- _recordingTable[_recordingNum].recording[_recordingDetailedNum] = {}
                    else
                        if _tempNum2 == 1 then
                            _tempNum2 = _tempNum2 + 1
                            _recordingTable[_recordingNum].num = _ids.ids[i]
                        elseif _tempNum2 == 2 then
                            _tempNum2 = _tempNum2 + 1
                            _recordingTable[_recordingNum].right = _ids.ids[i]
                        elseif _tempNum2 == 3 then
                            _tempNum2 = _tempNum2 + 1
                            _recordingTable[_recordingNum].wrong = _ids.ids[i]
                        elseif _tempNum2 ==  4 then
                             _tempNum2 = _tempNum2 + 1
                            _recordingTable[_recordingNum].chengjiao = _ids.ids[i]
                        elseif _tempNum2 ==  5 then
                             _tempNum2 = 1
                            _recordingTable[_recordingNum].getgold = _ids.ids[i]
                            _recordingDetailedNum = _recordingDetailedNum + 1
                            -- if i + 1 <= #_ids.ids and _ids.ids[i + 1] ~= -2 then
                            --     _recordingTable[_recordingNum].recording[_recordingDetailedNum] = {}
                            -- end
                        end    
                    end    

                else
                    if _tempNum1 == 1 then
                        _tempNum1 = _tempNum1 + 1
                        _recordingTable[_recordingNum].startTime = _ids.ids[i]
                    elseif _tempNum1 == 2 then
                        _tempNum1 = _tempNum1 + 1
                        _recordingTable[_recordingNum].auctionId = _ids.ids[i]
                    elseif _tempNum1 == 3 then
                        _tempNum1 = _tempNum1 + 1
                        _recordingTable[_recordingNum].trueOrFalse = _ids.ids[i]
                        _recordingTable[_recordingNum].recording[_recordingDetailedNum] = {}
                    else
                        if _tempNum2 == 1 then
                            _tempNum2 = _tempNum2 + 1
                            _recordingTable[_recordingNum].recording[_recordingDetailedNum].ruond = _ids.ids[i]
                        elseif _tempNum2 == 2 then
                            _tempNum2 = _tempNum2 + 1
                            _recordingTable[_recordingNum].recording[_recordingDetailedNum].npcId = _ids.ids[i]
                        elseif _tempNum2 == 3 then
                            _tempNum2 = 1
                            _recordingTable[_recordingNum].recording[_recordingDetailedNum].price = _ids.ids[i]
                            _recordingDetailedNum = _recordingDetailedNum + 1
                            if i + 1 <= #_ids.ids and _ids.ids[i + 1] ~= -1 and _ids.ids[i + 1] ~= -2 then
                                _recordingTable[_recordingNum].recording[_recordingDetailedNum] = {}
                            end
                        end
                    end
                end
            end
        end
    end

    return {type = 5412, recordingTable = _recordingTable}
end


function UIActivityAuctionEndCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5413, "UIActivityAuctionEndCallBack")
    
    return 1, 5413, nil
end

function NetActivityAuctionEndCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5413, "NetActivityAuctionEndCallBack")

    local _ids = _ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    
    return {type = 5413, result = _ids.ids[1]}
end

function UIActivityAuctionIsEndCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5414, "UIActivityAuctionIsEndCallBack")
    gamedata.ext.auctionRequestType = uireq.requestType
    gamedata.ext.priceType = uireq.priceType
    gamedata.ext.resultPrice = uireq.resultPrice

    return 1, 5414, nil
end

function NetActivityAuctionIsEndCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5414, "NetActivityAuctionIsEndCallBack")

    local _ids = _ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _resultType = gamedata.ext.auctionRequestType
    local _priceType = gamedata.ext.priceType
    local _resultPrice = gamedata.ext.resultPrice

    if _resultType == 1 then
        if _priceType == 1000 then
            gamedata:updateRoleCoin(tonumber(gamedata.ext.advancedCoin), nil, 1)
        elseif _priceType == 1001 then
            gamedata:updateRoleGold(tonumber(gamedata.ext.advancedCoin), nil, 1)
        end
    end

    gamedata.ext.auctionRequestType = nil
    gamedata.ext.priceType = nil
    gamedata.ext.resultPrice = nil
    
    return {type = 5414, result = _ids.ids[1], resultType = _resultType, priceType = _priceType}
end


function UIActivityAuctionOneKeyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5415, "UIActivityAuctionOneKeyCallBack")

    local idsData = _ids_pb.Ids()
    table.insert(idsData.ids, uireq.cid)
    table.insert(idsData.ids, uireq.num)
    table.insert(idsData.ids, uireq.price)

    gamedata.ext.antiqueId = uireq.cid
    gamedata.ext.antiquenum = uireq.num


    return 1, 5415, idsData:SerializeToString()
end


function NetActivityAuctionOneKeyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5415, "NetActivityAuctionOneKeyCallBack")

    local _combmessage = _combmessages_pb.CombMessages()
    local _ids = _ids_pb.Ids()
    local _someThings1 = _somethings_pb.SomeThings()
    local _someThings2 = _somethings_pb.SomeThings()

    _combmessage:ParseFromString(fd.rbuf)

    for k,v in ipairs(_combmessage.messages) do
        if v.id == 0 then
            _ids:ParseFromString(v.data)
        elseif v.id == 1 then
            _someThings1:ParseFromString(v.data)
        elseif v.id == 2 and _ids.ids[2] == 1 then
            _someThings2:ParseFromString(v.data)
        end
    end

    local _reward1 = gamedata:SomethingProcess(_someThings1)
    local _reward2 = nil


    if _ids.ids[1] then
       print("_ids.ids[1]:".._ids.ids[1])
    end
    if _ids.ids[2] then
        print("_ids.ids[2]:".._ids.ids[2])
    end

    if _ids.ids[2] == 1 then
        _reward2 = gamedata:SomethingProcess(_someThings2)
    end

    local _isUpdata = 0
    if gamedata.ext.antiqueId and gamedata.ext.antiquenum then
        gamedata:updateStaff({cid = gamedata.ext.antiqueId, num = - gamedata.ext.antiquenum})
        gamedata.ext.antiqueId = nil
        gamedata.ext.antiquenum = nil
        _isUpdata = 1
    end

    -- print(_reward1.."_reward1")
    -- print(_reward2.."_reward2")
    return {type = 5415, npcId = _ids.ids[1], isSpecial = _ids.ids[2], reward1 = _reward1, reward2 = _reward2, isUpdata = _isUpdata}

end



 #.  