--
-- Created by IntelliJ IDEA.
-- User: lipurpose
-- Date: 18/6/5
-- Time: 下午3:32
-- To change this template use File | Settings | File Templates.
--

function UIArtifactCastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5501, "ArtifactCast")

    local specialData = ids_pb.Ids()
    table.insert(specialData.ids,uireq.isUse)
    
    gamedata.ext.ArtifactCastProps = uireq.props

    return 1, 5501, specialData:SerializeToString()
end

function NetArtifactCastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5501, "ArtifactCast")
    local artifactData = params_pb.ParamS()
    artifactData:ParseFromString(fd.rbuf)

    local artifactDatas = gamedata:Newartifact({artifactData})
    for k,v in pairs(gamedata.ext.ArtifactCastProps) do
        gamedata:updateStaff({cid = v.cid,num = -v.num})
    end
    return {type = 5501,rewardArtifact = artifactDatas,data = getAllArtifacts()}
end


function UIArtifactCommpondCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5502, "ArtifactCommpond")
    local useArtifacts = ids_pb.Ids()
    for k,v in pairs(uireq.uses) do
        table.insert(useArtifacts.ids,v.iid)
    end
    gamedata.ext.ArtifactCommpondUse = uireq.uses
    return 1,5502,useArtifacts:SerializeToString()
end

function NetArtifactCommpondCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5502, "ArtifactCommpond")
    local artifactData = params_pb.ParamS()
    artifactData:ParseFromString(fd.rbuf)

    local artifacts = gamedata:Newartifact({artifactData})
    gamedata:DeleteArtifact(gamedata.ext.ArtifactCommpondUse)
    for k,v in pairs(gamedata.ext.ArtifactCommpondUse) do
        for i = 1,4 do
            if v["jewel"..i] > 0 then
                if not gamedata.cache.jewels[v["jewel"..i]] then
                    gamedata.cache.jewels[v["jewel"..i]] = {cid = v["jewel"..i],num = 0}
                end
                gamedata.cache.jewels[v["jewel"..i]].num = gamedata.cache.jewels[v["jewel"..i]].num + 1
            end
        end
    end

    return {type = 5502,rewardArtifact = artifacts,data = getAllArtifacts()}
end


function UIArtifactChangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5503, "ArtifactChange")
    local changeData = ids_pb.Ids()

    table.insert(changeData.ids,uireq.sid)
    table.insert( changeData.ids,uireq.iid)
    table.insert( changeData.ids,uireq.disboard)

    gamedata.ext.artifactChangeSid = uireq.sid
    gamedata.ext.artifactChangeIid = uireq.iid or 0

    gamedata.ext.artifactChangePIid = gamedata.cache.slots[uireq.sid].newartifact
    return 1,5503,changeData:SerializeToString()
end

function NetArtifactChangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5503, "NetArtifactChangeCallBack")

    local reward = nil;
    local slotData = nil;
    local artifacts =nil;
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    if gamedata.cache.slots[gamedata.ext.artifactChangeSid] then
        local iid = gamedata.cache.slots[gamedata.ext.artifactChangeSid].newartifact
        if iid and iid ~= 0 then
            if gamedata.cache.artifacts[iid] then
                gamedata.cache.artifacts[iid].sid = nil
                gamedata.cache.artifacts[iid].generalcid = nil

                for i = 1, 4 do
                    if gamedata.cache.artifacts[iid]["jewel"..i] > 0 then
                        gamedata.cache.artifacts[iid]["jewel"..i] = 0
                    end
                end
            end
        end
    end
    

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local artifactData = params_pb.ParamS()
            artifactData:ParseFromString(v.data)
            artifacts = gamedata:Newartifact({artifactData})
        elseif v.id == 1 then
            local info = slots_pb.SlotS()
            info:ParseFromString(v.data)

            gamedata:SlotInfoProcess(info)
            if gamedata.ext.artifactChangePIid > 0 then
                gamedata.cache.artifacts[gamedata.ext.artifactChangePIid].sid = nil

            end
            local slotData =  table.copy(gamedata.cache.slots[gamedata.ext.artifactChangeSid])
            if gamedata.ext.artifactChangeIid > 0 then
                slotData.newartifact = gamedata.cache.artifacts[gamedata.ext.artifactChangeIid]
                gamedata.cache.artifacts[gamedata.ext.artifactChangeIid].sid = gamedata.ext.artifactChangeSid

            end
        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end
    
    return {type = 5503,
            artifacts = artifacts,
            data = getAllArtifacts(),
            slot = slotData,
            reward = reward}
end



function UIArtifactOpenPosCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5504, "ArtifactOpenPos")
    local artifact = gamedata.cache.artifacts[uireq.iid]
    local config = gamedata.config.trump[tostring(artifact.cid)]

    local openLevel = config["hole_lv"..uireq.pos]
    if gamedata.cache.role.level < openLevel then
        return 0,503,{type = 503, msg = 51 }
    end
    local useTable = gamedata.getIDandNUMs(config["hole_cost"..uireq.pos])
    
    for k,v in pairs(useTable) do
        local isenough, ret = gamedata.checkStaffEnough(v.cid,v.num,{})
        if not isenough then
            return 0,503,ret
        end
    end
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    table.insert(info.ids,uireq.pos)

    gamedata.ext.ArtifactOpen = {iid = uireq.iid,pos = uireq.pos}
    gamedata.ext.ArtifactOpenProps = useTable
    

    return 1,5504,info:SerializeToString()
end

function NetArtifactOpenPosCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5504, "ArtifactOpenPos")

    gamedata.cache.artifacts[gamedata.ext.ArtifactOpen.iid]["jewel"..gamedata.ext.ArtifactOpen.pos] = 0
    for k,v in pairs(gamedata.ext.ArtifactOpenProps) do
        gamedata:updateStaff({cid = v.cid,num = -v.num, name = "神器开启镶嵌"})
    end

    return {type = 5504,artifact = gamedata.cache.artifacts[gamedata.ext.ArtifactOpen.iid],data = getAllArtifacts()}
end

local function getAllJewels()
    local jewels = table.copy(gamedata.cache.jewels)
    return jewels
end

function UIArtifactMountJewelCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5505, "ArtifactMountJewel")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    table.insert(info.ids,uireq.jewelCid)
    table.insert(info.ids,uireq.pos)
    
    gamedata.ext.mountIid = uireq.iid
    gamedata.ext.mountInfo = {cid = uireq.jewelCid,pos = uireq.pos}
    return 1,5505,info:SerializeToString()
end

function NetArtifactMountJewelCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5505, "ArtifactMountJewel")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local cid,num = 0,0 
    if gamedata.ext.mountInfo.cid <= 0 then
        cid = gamedata.cache.artifacts[gamedata.ext.mountIid]["jewel"..gamedata.ext.mountInfo.pos]
        num = 1
    else
        cid = gamedata.ext.mountInfo.cid
        num = -1
    end

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local artifactData = params_pb.ParamS()
            artifactData:ParseFromString(v.data)
            local artifacts = gamedata:Newartifact({artifactData})
        elseif v.id == 1 then
            local info = slots_pb.SlotS()
            info:ParseFromString(v.data)
            gamedata:SlotInfoProcess(info)
        end
    end
    
    if cid > 0 then
        gamedata.cache.jewels[cid] = gamedata.cache.jewels[cid] or {cid = cid,num = 0}
        gamedata.cache.jewels[cid].num = gamedata.cache.jewels[cid].num + num
        if gamedata.cache.jewels[cid].num <= 0 then
            gamedata.cache.jewels[cid] = nil
        end
    end
    
    local artifactData = gamedata.cache.artifacts[gamedata.ext.mountIid]

    local mountType = gamedata.ext.mountInfo.cid > 0 and 1 or 0
    return {type = 5505,
    data = getAllArtifacts(),
    jewelData = getAllJewels(),
    artifact = artifactData,
    mountType = mountType}
end


function UIJewelUpgradeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5506, "JewelUpgrade")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    table.insert(info.ids,uireq.pos)
    
    gamedata.ext.artifactUpgradeIid = uireq.iid
    gamedata.ext.artifactUpgradePos = uireq.pos
    return 1,5506,info:SerializeToString()
end

function CheckJewelCanUp(cid,hasNum)
    hasNum = hasNum or 0
    local config = gamedata.config.trump_gem[tostring(cid)]
    if not config then
        return false
    end
    local jewelData = gamedata.cache.jewels[cid]
    if config.per_cid <= 0 then
        return false
    end
    if hasNum > 0 then
        local configN = gamedata.config.trump_gem[tostring(config.per_cid)]
        if gamedata.cache.role.level < configN.gem_lvbet then
            return false
        end
    end
    
    local useTable = gamedata.getIDandNUMs(config.gem_lv)
    local isenough,ret = true,nil
    for k,v in pairs(useTable) do
        if v.cid == cid then
            v.num = v.num - 1
        end
        isenough, ret = gamedata.checkStaffEnough(v.cid,v.num,{})
        if not isenough then
            return false
        end
    end
    return true
end

function NetJewelUpgradeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5506, "JewelUpgrade")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local cid = gamedata.cache.artifacts[gamedata.ext.artifactUpgradeIid]["jewel"..gamedata.ext.artifactUpgradePos]
    local config = gamedata.config.trump_gem[tostring(cid)]

    local useTable = gamedata.getIDandNUMs(config.gem_lv)
    
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local artifactData = params_pb.ParamS()
            artifactData:ParseFromString(v.data)
            local artifacts = gamedata:Newartifact({artifactData})
        elseif v.id == 1 then
            local info = slots_pb.SlotS()
            info:ParseFromString(v.data)
            gamedata:SlotInfoProcess(info)
        end
    end

    for k,v in pairs(useTable) do
        if v.cid == cid then
            v.num = v.num - 1
        end
        gamedata:updateStaff({cid = v.cid,num = -v.num})
    end
    
    local artifactData = gamedata.cache.artifacts[gamedata.ext.artifactUpgradeIid]
    local isOk = artifactData["jewel"..gamedata.ext.artifactUpgradePos]
    
    return {type = 5506,data = getAllArtifacts(),jewelData = getAllJewels(),artifact = artifactData,isOk = isOk}
end


function UIJewelCommpondCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5507, "JewelCommpond")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.cid - 1)
    table.insert(info.ids,uireq.num)
    gamedata.ext.jewelCommpondUse = {}
    gamedata.ext.jewelCommpondUse.cid = uireq.cid - 1
    gamedata.ext.jewelCommpondUse.num = uireq.num
   
    return 1,5507,info:SerializeToString()
end

function NetJewelCommpondCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5507, "JewelCommpond")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings)
        
    local config = gamedata.config.trump_gem[tostring(gamedata.ext.jewelCommpondUse.cid)]
    local useTable = gamedata.getIDandNUMs(config.gem_lv)
    for k,v in ipairs(useTable) do
        gamedata:updateStaff({cid = v.cid,num = -(v.num * gamedata.ext.jewelCommpondUse.num)})
    end
    
    return {type = 5507,
    data = getAllJewels(),
    reward = reward,
    }
end

function UIArtifactCheckCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5508, "ArtifactCheck")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    table.insert(info.ids,uireq.useId)
    gamedata.ext.artifactCheckId = uireq.useId
    return 1,5508,info:SerializeToString()
end

function NetArtifactCheckCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5508, "ArtifactCheck")
    local artifactData = params_pb.ParamS()
    artifactData:ParseFromString(fd.rbuf)

    local artifactDatas = gamedata:Newartifact({artifactData})
    local id = tonumber(gamedata.ext.artifactCheckId)
    local num = gamedata.config.trump_autweight[tostring(id)].itemNum
    
    gamedata:updateStaff({cid = id,num = -num})
    
    return {type = 5508,rewardArtifact = artifactDatas,data = getAllArtifacts()}
end

function UIArtifactCheckTimeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5509, "ArtifactCheckTime")
   
    return 1,5509,nil
end

function NetArtifactCheckTimeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5509, "ArtifactCheckTime")
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)

    return {type = 5509,time = info.ids[1],sec = info.ids[2]}
end

-- 一键打造
function UIUserArtifactOnceMakeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5515, "UIUserArtifactOnceMakeCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.curType)
    table.insert(info.ids,uireq.count)
    gamedata.ext.ArtifactCastType = uireq.curType
    gamedata.ext.ArtifactCastCount = uireq.count
    gamedata.ext.ArtifactCastProps = uireq.props
    return 1,5515,info:SerializeToString()
end

function NetUserArtifactOnceMakeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5515, "NetUserArtifactOnceMakeCallBack")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local artifactList ={};
    for k,v in ipairs(datas.messages) do
        local artifactData = params_pb.ParamS()
        artifactData:ParseFromString(v.data)
        local artifacts = gamedata:Newartifact({artifactData})
        table.insert(artifactList,artifacts)
    end

    for k,v in pairs(gamedata.ext.ArtifactCastProps) do
        if v.cid == 20630 then
            if gamedata.ext.ArtifactCastType == 1 then
                gamedata:updateStaff({cid = v.cid,num = -(v.num*gamedata.ext.ArtifactCastCount)})
            end
        else
            gamedata:updateStaff({cid = v.cid,num = -(v.num*gamedata.ext.ArtifactCastCount)})
        end
    end

    return {type = 5515,artifactList = artifactList,data = getAllArtifacts(),showType = "1"}
end

-- 一键鉴定
function UIUserArtifactOnceCheckupCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5516, "UIUserArtifactOnceCheckupCallBack")
    local info = ids_pb.Ids()
    for k,v in pairs(uireq.curList) do
         -- cclog("打印================  %d recv request from UI",uireq.curList[k].iid)
        table.insert(info.ids,uireq.curList[k].iid)
    end

    gamedata.ext.checkupArtifac = uireq.curList
    table.insert(info.ids,uireq.itemID)
    gamedata.ext.ArtifactCheckupItemID = uireq.itemID
    gamedata.ext.ArtifactCheckupNum = table.getTableLength(uireq.curList)
    return 1,5516,info:SerializeToString()
end

function NetUserArtifactOnceCheckupCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5516, "NetUserArtifactOnceCheckupCallBack")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    --删除消耗的神器
    -- for k,v in pairs(gamedata.ext.checkupArtifac) do
    --     gamedata.cache.artifacts[v.iid] = nil
    -- end

    local artifactList ={};
    for k,v in ipairs(datas.messages) do
        local artifactData = params_pb.ParamS()
        artifactData:ParseFromString(v.data)
        local artifacts = gamedata:Newartifact({artifactData})
        table.insert(artifactList,artifacts)
    end

    gamedata:updateStaff({cid = gamedata.ext.ArtifactCheckupItemID,num = -gamedata.ext.ArtifactCheckupNum})

    return {type = 5516,artifactList = artifactList,data = getAllArtifacts(),showType = "2"}
end

-- 一键重铸
function UIUserArtifactRecastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5517, "UIUserArtifactRecastCallBack")
    local info = ids_pb.Ids()

    local outNum = 0


    local list = {}
    for k,v in pairs(uireq.curList) do
        table.insert(list,v)
    end

    table.sort(list,function ( a,b)
        return a.score < b.score
    end)

    if table.getTableLength(list) >= 3 then
        outNum = table.getTableLength(list)%3
    end

    print("删除多余之前",table.getTableLength(list))
    for i=1,outNum do
        list[#list] = nil
    end

    print("删除多余之后",table.getTableLength(list))

    for i,v in ipairs(list) do
        table.insert(info.ids,v.iid)
    end

    --重铸消耗的神器
    gamedata.ext.recastCostArtifac = list

    table.insert(info.ids,uireq.curState)
    return 1,5517,info:SerializeToString()
end

function NetUserArtifactRecastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5517, "NetUserArtifactRecastCallBack")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    local artifactList ={};
    for k,v in ipairs(datas.messages) do
        local artifactData = params_pb.ParamS()
        artifactData:ParseFromString(v.data)
        local artifacts = gamedata:Newartifact({artifactData})
        table.insert(artifactList,artifacts)
    end
    --删除消耗的神器
    for k,v in pairs(gamedata.ext.recastCostArtifac) do
        gamedata.cache.artifacts[v.iid] = nil
    end

    return {type = 5517,artifactList = artifactList,data = getAllArtifacts(),showType = "3"}
end

-- 神器锁定
function UIUserArtifactLockCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5518, "UIUserArtifactLockCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.cid)
    table.insert(info.ids,uireq.isLock)
    return 1,5518,info:SerializeToString()
end

function NetUserArtifactLockCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5518, "NetUserArtifactLockCallBack")
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)
    local iid = info.ids[1]
    local artifactData = gamedata.cache.artifacts[iid];
    artifactData.isLockState = info.ids[2]
    gamedata.cache.artifacts[iid] = artifactData
    return {type = 5518,artifactSid = iid,isLock = info.ids[2],data = getAllArtifacts()}
end


-- 神器强化
function UIUserArtifactStrengthenCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5519, "UIUserArtifactStrengthenCallBack")
    
    printT(uireq,"UIUserArtifactStrengthenCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    gamedata.ext.artifactChangeSid = uireq.sid
    gamedata.ext.artifactChangeIid = uireq.iid
    

    gamedata.ext.artifactExpendList = uireq.expendList

    for k,v in pairs(uireq.expendList) do
        -- cclog("打印================ recv request from UI")
        table.insert(info.ids,uireq.expendList[k].iid)
    end
    return 1,5519,info:SerializeToString()
end

function NetUserArtifactStrengthenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5519, "NetUserArtifactStrengthenCallBack")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    --删除消耗神器
    if gamedata.ext.artifactExpendList then
        for k,v in pairs(gamedata.ext.artifactExpendList) do
            gamedata.cache.artifacts[v.iid] = nil
        end
        
    end

    local slotData = nil;
    local artifacts =nil;
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local artifactData = params_pb.ParamS()
            artifactData:ParseFromString(v.data)
            artifacts = gamedata:Newartifact({artifactData})
        elseif v.id == 1 then
            local info = slots_pb.SlotS()
            info:ParseFromString(v.data)

            gamedata:SlotInfoProcess(info)
            
            if gamedata.ext.artifactChangeSid then
                local slotData =  table.copy(gamedata.cache.slots[gamedata.ext.artifactChangeSid])
                if gamedata.ext.artifactChangeIid > 0 then
                    slotData.newartifact = gamedata.cache.artifacts[gamedata.ext.artifactChangeIid]
                    gamedata.cache.artifacts[gamedata.ext.artifactChangeIid].sid = gamedata.ext.artifactChangeSid
                end
            end
            
        end
    end

    return {type = 5519,artifacts = artifacts,data = getAllArtifacts()}
end

-- 神器重生
function UIUserArtifactRenascenceCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5520, "ArtifactCheckTime")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)

    gamedata.ext.spendgold = uireq.gold or 0
    return 1,5520,info:SerializeToString()
end

function NetUserArtifactRenascenceCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5520, "ArtifactCheckTime")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local slotData = nil;
    local artifacts =nil;
    local reward = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then

            print("coin",gamedata.cache.role.coin)
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
            print("coin",gamedata.cache.role.coin)
            printT(reward,"reward")
        else
            local artifactData = params_pb.ParamS()
            artifactData:ParseFromString(v.data)
            artifacts = gamedata:Newartifact({artifactData})
            -- printT(artifacts,"artifacts")

            for _i,_v in ipairs(artifacts) do
                table.insert(reward,{cid = _v.cid,iid = _v.iid,num = 1,double = 0,order = 100})
            end
        end
    end

    gamedata:updateRoleGold(0-tonumber(gamedata.ext.spendgold),"神器重生消耗元宝",1)

    return {type = 5520,artifacts = artifacts,reward = reward,data = getAllArtifacts()}
end



function UIUserArtifactOpeningCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 5540, "UIUserArtifactOpeningCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    table.insert(info.ids,uireq.pos)
    table.insert(info.ids,uireq.curType)
    gamedata.ext.ArtifactKaiKongiid = uireq.iid
    gamedata.ext.ArtifactKaiKongpos = uireq.pos
    gamedata.ext.ArtifactKaiKongType = uireq.curType
    
    return 1,5540,info:SerializeToString()
end

function NetUserArtifactOpeningCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5540, "NetUserArtifactOpeningCallBack")
    
    local artifactData = params_pb.ParamS()
    artifactData:ParseFromString(fd.rbuf)
    local artifacts = gamedata:Newartifact({artifactData})

    if gamedata.ext.ArtifactKaiKongType and gamedata.ext.ArtifactKaiKongType == 1 then
        --消耗道具
        local cost = gamedata.getIDandNUMs(gamedata.config.trump_config["skill_position_"..gamedata.ext.ArtifactKaiKongpos].value)

        for k,v in pairs(cost) do
            gamedata:updateStaff({cid = v.cid,num = -v.num})
        end
    end

    -- 传出 ids [对应孔位的开孔成功率，孔位状态(-1 未开启，1开启，2 锁定)]
    return {type = 5540,artifactData = artifacts[1],data = getAllArtifacts()}
end

function UIUserArtifactBaptizeCallBack(uireq)
    printT(uireq,"UIUserArtifactBaptizeCallBack")
    cclog("UI type:%d cmd:%s recv request from UI", 5541, "UIUserArtifactBaptizeCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    table.insert(info.ids,uireq.curType)
    gamedata.ext.ArtifactXiLianiid = uireq.iid
    gamedata.ext.ArtifactXiLianXprops = uireq.xprops

    return 1,5541,info:SerializeToString()
end

function NetUserArtifactBaptizeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5541, "NetUserArtifactBaptizeCallBack")
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)
    local artifactData = gamedata.cache.artifacts[gamedata.ext.ArtifactXiLianiid]
    artifactData.skill1_cid_bk = info.ids[1]
    artifactData.skill2_cid_bk = info.ids[2]
    artifactData.skill3_cid_bk = info.ids[3]
    gamedata.cache.artifacts[gamedata.ext.ArtifactXiLianiid] = artifactData
    
    --减去消耗道具
    for k,v in pairs(gamedata.ext.ArtifactXiLianXprops) do
        gamedata:updateStaff({cid = v.cid,num = -v.num})
    end

    return {type = 5541,artifactData = artifactData,data = getAllArtifacts()}
end

function UIUserArtifactBaptizeReplaceCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 5542, "UIUserArtifactBaptizeReplaceCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    gamedata.ext.ArtifactXiLianiid = uireq.iid
    return 1,5542,info:SerializeToString()
end

function NetUserArtifactBaptizeReplaceCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5542, "NetUserArtifactBaptizeReplaceCallBack")

    local artifactData = params_pb.ParamS()
    artifactData:ParseFromString(fd.rbuf)
    local artifacts = gamedata:Newartifact({artifactData})

    return {type = 5542,artifactData = artifacts[1],data = getAllArtifacts()}
end

function UIUserArtifactSkillWashCancelCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 5544, "UIUserArtifactSkillWashCancelCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    gamedata.ext.ArtifactXiLianCanceliid = uireq.iid
    return 1,5544,info:SerializeToString()
end

function NetUserArtifactSkillWashCancelCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5544, "UIUserArtifactSkillWashCancelCallBack")

    -- local info = ids_pb.Ids()
    -- info:ParseFromString(fd.rbuf)
    local artifactData = gamedata.cache.artifacts[gamedata.ext.ArtifactXiLianCanceliid]
    artifactData.skill1_cid_bk = -1
    artifactData.skill2_cid_bk = -1
    artifactData.skill3_cid_bk = -1
    gamedata.cache.artifacts[gamedata.ext.ArtifactXiLianCanceliid] = artifactData

    return {type = 5544,artifactData = artifactData,data = getAllArtifacts()}
end

function UIUserArtifactSkillExchangeCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 5545, "UIUserArtifactSkillExchangeCallBack")
    printT(uireq,"UIUserArtifactSkillExchangeCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid1)
    table.insert(info.ids,uireq.iid2)

    gamedata.ext.ArtifactSkillExchangeIid1 = uireq.iid1
    gamedata.ext.ArtifactSkillExchangeIid2 = uireq.iid2

    gamedata.ext.ArtifactSkillExchangeConsumeGold = uireq.consumeGold or 0

    return 1,5545,info:SerializeToString()
end

function NetUserArtifactSkillExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5545, "NetUserArtifactSkillExchangeCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local artifactDatas = {}
    for k,v in ipairs(datas.messages) do
        local artifactData = params_pb.ParamS()
        artifactData:ParseFromString(v.data)
        local artifacts = gamedata:Newartifact({artifactData})
        table.insert(artifactDatas,artifacts[1])
    end

    gamedata:updateStaff({cid = 1001,num = -gamedata.ext.ArtifactSkillExchangeConsumeGold})

    return {type = 5545,data = artifactDatas}
end

function UIUserArtifactSkillUpCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 5543, "UIUserArtifactSkillUpCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.cid)
    table.insert(info.ids,uireq.pos)
    gamedata.ext.ArtifactDianHuaCid = uireq.cid
    return 1,5543,info:SerializeToString()
end

function NetUserArtifactSkillUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5543, "NetUserArtifactSkillUpCallBack")
    local artifactData = params_pb.ParamS()
    artifactData:ParseFromString(fd.rbuf)
    local artifacts = gamedata:Newartifact({artifactData})

    -- skillObj.cid = gamedata.ext.ArtifactDianHuaCid
    -- skillObj.skill1 = info.ids[1]
    return {type = 5543}
end


function UIUserArtifactStrenExchangeCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 5546, "UIUserArtifactStrenExchangeCallBack")
    printT(uireq,"UIUserArtifactStrenExchangeCallBack")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid1)
    table.insert(info.ids,uireq.iid2)

    gamedata.ext.ArtifactStrenExchangeIid1 = uireq.iid1
    gamedata.ext.ArtifactStrenExchangeIid2 = uireq.iid2

    gamedata.ext.ArtifactStrenExchangeConsumeGold = uireq.consumeGold or 0

    return 1,5546,info:SerializeToString()
end

function NetUserArtifactStrenExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5546, "NetUserArtifactStrenExchangeCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local artifactDatas = {}
    for k,v in ipairs(datas.messages) do
        local artifactData = params_pb.ParamS()
        artifactData:ParseFromString(v.data)
        local artifacts = gamedata:Newartifact({artifactData})
        table.insert(artifactDatas,artifacts[1])
    end

    gamedata:updateStaff({cid = 1001,num = -gamedata.ext.ArtifactStrenExchangeConsumeGold})

    return {type = 5546,data = artifactDatas}
end



function UIJewelListDataCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",10031, "JewelListData")
    return 0,10031,{type = 10031,data = getAllJewels()}
end

function getAllArtifacts()
    local artifacts = table.copy(gamedata.cache.artifacts)
    for k,v in pairs(gamedata.cache.slots) do
        local iid = v.newartifact
        if iid and iid ~= 0 and artifacts[iid] then
            if not gamedata.cache.generals[v.general] or v.general == gamedata.cache.protagonist.iid  then
                artifacts[iid].generalcid = gamedata.cache.protagonist.general.cid
            else
                artifacts[iid].generalcid = gamedata.cache.generals[v.general].cid
            end
            artifacts[iid].sid = v.sid
        end 
    end
    return artifacts
end

function UIArtifactDataCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",10032, "ArtifactData")
    return 0,10032,{type = 10032,data = getAllArtifacts()}
end

--1 全部，2 鉴定
function CheckArtifactAllHint(checkType)
    if checkType == 1 then
        local castConfig = gamedata.config.global_kv
        local castTable = gamedata.getIDandNUMs(castConfig.trump_forging_cost.value)
        local isenough,ret = true,nil
        for k,v in pairs(castTable) do
            isenough, ret = gamedata.checkStaffEnough(v.cid,v.num,{})
            if not isenough then
                break
            end
        end
        if isenough then
            mekehintext(366,1)
        else
            mekehintext(366,0)
        end
    end
    mekehintext(398,0)
    for k,v in pairs(gamedata.cache.artifacts) do
        if v.isChecked < 1 then
            local config = gamedata.config.trump[tostring(v.cid)]
            local id =  tonumber(config.appraiseMethod)
            if id and id > 0 then
                local num = gamedata.config.trump_autweight[tostring(id)].itemNum
                local isenough,ret = gamedata.checkStaffEnough(id,num,{})
                if isenough then
                    mekehintext(398,1)
                    break
                end
            end
        end
    end
end



function UIAutoMoFuQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6405, "UIAutoMoFuQueryCallBack")
    return 1,6405,nil
end


function NetAutoMoFuQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6405, "NetAutoMoFuQueryCallBack")
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)

    return {type = 6405,autoState = info.ids[1],autoLevel = info.ids[2], rolelv = gamedata.cache.role.level or 0 }
end

function UIAutoMoFuComposeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6406, "UIAutoMoFuComposeCallBack")
    local changeData = ids_pb.Ids()

    table.insert(changeData.ids,uireq.autoState)
    table.insert( changeData.ids,uireq.autoLevel)
    return 1,6406,changeData:SerializeToString()
end

function NetAutoMoFuComposeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6406, "NetAutoMoFuComposeCallBack")
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)
    return {type = 6406,curState = info.ids[1]}
end




 #�  