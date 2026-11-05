-- 同版配置报价；神器与阵容/装备共用在途锁，未知结果不重试。
local ids_pb=require("ids_pb")
local params_pb=require("params_pb")
local slots_pb=require("slots_pb")
local combmessages_pb=require("combmessages_pb")
require("GameSlots")
require("GamePropList")

local function reject(msg) return 0,503,{type=503,msg=msg} end
local function send(req,opcode)
    local mutation=opcode~=5509
    if mutation and (gamedata.ext.localFormationBusy or gamedata.ext.localSoulBusy or gamedata.ext.localEquipGrowthBusy) then
        return reject("神器或阵容正在结算，请等待回复；超时请重进游戏")
    end
    local values,costs={},{}
    if opcode==5501 or opcode==5515 then
        local mode,count=req.curType,req.count
        if opcode==5501 then
            mode=req.isUse;if mode==true then mode=1 elseif mode==false then mode=0 end
            count=1
        end
        if (mode~=0 and mode~=1) or type(count)~="number" or count%1~=0 or count<1 or count>tonumber(gamedata.config.trump_config.make_max.value) then
            return reject("神器打造数量或方式无效")
        end
        values={mode};if opcode==5515 then values[2]=count end
        for _,key in ipairs(mode==1 and {"trump_forging_cost","godtrump_forging_cost"} or {"trump_forging_cost"}) do
            for _,v in ipairs(gamedata.getIDandNUMs(gamedata.config.global_kv[key].value)) do
                costs[#costs+1]={cid=v.cid,num=v.num*count}
            end
        end
    elseif opcode==5508 or opcode==5516 then
        local list=opcode==5508 and {{iid=req.iid}} or req.curList or {}
        local ordered={}
        for _,v in pairs(list) do ordered[#ordered+1]=v.iid end
        table.sort(ordered)
        local prop=opcode==5508 and req.useId or req.itemID
        local weight=gamedata.config.trump_autweight[tostring(prop)]
        if not weight or #ordered<1 or #ordered>tonumber(gamedata.config.trump_config.clear_max.value) then return reject("请选择神器和鉴定符") end
        for _,iid in ipairs(ordered) do
            local item=gamedata.cache.artifacts[iid]
            if not item or item.isChecked~=0 or values[#values]==iid then return reject("神器已变化，请重新选择") end
            local row=gamedata.config.trump[tostring(item.cid)]
            if row.goldTrump>0 and tonumber(row.appraiseMethod)~=prop then return reject("金光神器需要高级鉴定符") end
            values[#values+1]=iid
        end
        values[#values+1]=prop
        costs={{cid=prop,num=weight.itemNum*#ordered}}
    elseif opcode==5503 then
        local slot=gamedata.cache.slots[req.sid]
        if not slot or not slot.general or slot.general==0 then return reject("阵位已变化，请重新打开") end
        values={req.sid,req.iid or 0,1}
    end
    for _,v in ipairs(costs) do
        local enough,reason=gamedata.checkStaffEnough(v.cid,v.num,{})
        if not enough then return 0,503,reason end
    end
    local info=ids_pb.Ids()
    for _,v in ipairs(values) do table.insert(info.ids,v) end
    local pending=gamedata.ext.localArtifactPending or {}
    pending[opcode]=pending[opcode] or {}
    table.insert(pending[opcode],{view=req.artifactView,costs=costs,values=values})
    gamedata.ext.localArtifactPending=pending
    if mutation then gamedata.ext.localFormationBusy={opcode=opcode} end
    return 1,opcode,info:SerializeToString()
end

local function receive(fd,opcode)
    local queue=(gamedata.ext.localArtifactPending or {})[opcode] or {}
    if fd.ser==0 or #queue==0 then return {type=opcode,localArtifactIgnored=true} end
    local pending=table.remove(queue,1)
    local result={type=opcode,artifactView=pending.view}
    if opcode==5509 then
        local info=ids_pb.Ids();info:ParseFromString(fd.rbuf)
        result.time,result.sec=info.ids[1],info.ids[2]
        result.receivedAt=os.time()
    elseif opcode==5503 then
        local info=combmessages_pb.CombMessages();info:ParseFromString(fd.rbuf)
        for _,v in ipairs(info.messages) do
            if v.id==1 then
                local slots=slots_pb.SlotS();slots:ParseFromString(v.data)
                for _,a in pairs(gamedata.cache.artifacts) do a.sid=nil;a.generalcid=nil end
                gamedata:SlotInfoProcess(slots)
            end
        end
    elseif opcode==5501 or opcode==5508 then
        local info=params_pb.ParamS();info:ParseFromString(fd.rbuf)
        result.rewardArtifact=gamedata:Newartifact({info})
    else
        local info=combmessages_pb.CombMessages();info:ParseFromString(fd.rbuf)
        result.artifactList={}
        for _,v in ipairs(info.messages) do
            local item=params_pb.ParamS();item:ParseFromString(v.data)
            table.insert(result.artifactList,gamedata:Newartifact({item}))
        end
        result.showType=opcode==5515 and "1" or "2"
    end
    if opcode~=5509 then
        for _,v in ipairs(pending.costs) do gamedata:updateStaff({cid=v.cid,num=-v.num}) end
        gamedata.ext.localArtifactRevision=(gamedata.ext.localArtifactRevision or 0)+1
        result.data=getAllArtifacts()
        local busy=gamedata.ext.localFormationBusy
        if busy and busy.opcode==opcode then gamedata.ext.localFormationBusy=nil end
    end
    result.artifactRevision=gamedata.ext.localArtifactRevision or 0
    return result
end

for _,entry in ipairs({
    {5501,"UIArtifactCastCallBack","NetArtifactCastCallBack"},
    {5503,"UIArtifactChangeCallBack","NetArtifactChangeCallBack"},
    {5508,"UIArtifactCheckCallBack","NetArtifactCheckCallBack"},
    {5509,"UIArtifactCheckTimeCallBack","NetArtifactCheckTimeCallBack"},
    {5515,"UIUserArtifactOnceMakeCallBack","NetUserArtifactOnceMakeCallBack"},
    {5516,"UIUserArtifactOnceCheckupCallBack","NetUserArtifactOnceCheckupCallBack"},
}) do
    local opcode=entry[1]
    assert(_G[entry[2]] and _G[entry[3]],"missing artifact callback "..opcode)
    _G[entry[2]]=function(req) return send(req,opcode) end
    _G[entry[3]]=function(fd) return receive(fd,opcode) end
end

local query=UIArtifactDataCallBack
function UIArtifactDataCallBack(req)
    local mode,opcode,result=query(req)
    result.artifactView=req.artifactView
    result.artifactRevision=gamedata.ext.localArtifactRevision or 0
    return mode,opcode,result
end
local props=UIPropQueryByIdCallback
function UIPropQueryByIdCallback(req)
    local mode,opcode,result=props(req)
    if mode==0 and result then result.artifactView=req.artifactView;result.artifactRevision=gamedata.ext.localArtifactRevision or 0 end
    return mode,opcode,result
end
function LocalArtifactError(opcode)
    table.remove((gamedata.ext.localArtifactPending or {})[opcode] or {},1)
end
