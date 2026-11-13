-- 同版配置报价；神器与阵容/装备共用在途锁，未知结果不重试。
local ids_pb=require("ids_pb")
local params_pb=require("params_pb")
local slots_pb=require("slots_pb")
local combmessages_pb=require("combmessages_pb")
local somethings_pb=require("somethings_pb")
require("GameSlots")
require("GamePropList")
local received={}

local function reject(msg) return 0,503,{type=503,msg=msg} end
local growth={[5502]=true,[5504]=true,[5505]=true,[5506]=true,[5507]=true,[5517]=true,[5518]=true,[5519]=true,
    [5520]=true,[5540]=true,[5541]=true,[5542]=true,[5543]=true,[5544]=true,[5545]=true,[5546]=true}
local function ordered(list,byScore)
    local result={}
    for _,v in pairs(list or {}) do result[#result+1]=v.iid end
    table.sort(result,function(a,b)
        if byScore then
            local x,y=gamedata.cache.artifacts[a],gamedata.cache.artifacts[b]
            if x and y and x.score~=y.score then return x.score<y.score end
        end
        return a<b
    end)
    return result
end
local function growthRequest(req,opcode)
    local values,keys,costs={},{},{}
    local function cost(text,count,exclude)
        if not text or text=="" then return end
        for _,v in ipairs(gamedata.getIDandNUMs(text or "")) do
            local n=v.num*(count or 1)-(v.cid==exclude and 1 or 0)
            if n>0 then costs[#costs+1]={cid=v.cid,num=n} end
        end
    end
    local item=gamedata.cache.artifacts[req.iid or req.cid]
    local row=item and gamedata.config.trump[tostring(item.cid)]
    if opcode==5502 or opcode==5517 then
        keys=ordered(opcode==5502 and req.uses or req.curList,opcode==5517)
        if opcode==5517 then while #keys%3~=0 do table.remove(keys) end end
        for _,key in ipairs(keys) do values[#values+1]=key end
        if opcode==5517 then values[#values+1]=req.curState or 0 end
    elseif opcode==5507 then
        values={req.cid-1,req.num}
        local gem=gamedata.config.trump_gem[tostring(values[1])]
        if not gem then return nil end
        cost(gem.gem_lv,req.num)
    elseif opcode==5545 or opcode==5546 then
        keys={req.iid1,req.iid2};values={req.iid1,req.iid2}
        local a,b=gamedata.cache.artifacts[req.iid1],gamedata.cache.artifacts[req.iid2]
        if not a or not b then return nil end
        local price=0
        if opcode==5545 then
            local count=0
            for _,v in ipairs({a,b}) do
                for i=1,3 do
                    if v["skill"..i]>0 then
                        local skill=gamedata.config.breakskill[tostring(v["skill"..i])]
                        price=price+tonumber(gamedata.config.trump_config["quality_swap_price_"..skill.quality].value)
                        count=count+1
                    end
                end
            end
            if count>0 then price=price+tonumber(gamedata.config.trump_config["number_swap_price_"..count].value) end
        else
            price=tonumber(gamedata.config.trump_transfer[tostring(math.max(a.level1,b.level1))].price)
        end
        if price>0 then costs={{cid=1001,num=price}} end
    else
        if not item or not row then return nil end
        keys={item.iid}
        if opcode==5518 then values={item.iid,req.isLock}
        elseif opcode==5519 then
            values={item.iid}
            for _,key in ipairs(ordered(req.expendList)) do keys[#keys+1]=key;values[#values+1]=key end
        elseif opcode==5504 then values={item.iid,req.pos};cost(row["hole_cost"..req.pos])
        elseif opcode==5505 then values={item.iid,req.jewelCid,req.pos};if req.jewelCid>0 then costs={{cid=req.jewelCid,num=1}} end
        elseif opcode==5506 then
            values={item.iid,req.pos}
            local cid=item["jewel"..req.pos]
            local gem=gamedata.config.trump_gem[tostring(cid)]
            if not gem then return nil end
            cost(gem.gem_lv,1,cid)
        elseif opcode==5540 then
            values={item.iid,req.pos,req.curType}
            if req.curType==1 then cost(gamedata.config.trump_config["skill_position_"..req.pos].value) end
        elseif opcode==5541 then
            values={item.iid,req.curType}
            local locked=0
            for i=1,3 do if item["skillHole"..i]==2 then locked=locked+1 end end
            local config=gamedata.config.trump_config["washing_"..req.curType.."_"..math.min(2,locked)]
            if not config then return nil end
            cost(config.value)
        elseif opcode==5543 then values={item.iid,req.pos};cost(gamedata.config.trump_config.skill_cost_5.value)
        elseif opcode==5520 then
            values={item.iid}
            local price=0
            if item.level1>0 then price=gamedata.config.trump_rebirth[tostring(item.level1)].strengthen end
            local count=0
            for i=1,4 do if item["jewel"..i]>=0 then count=count+1 end end
            price=price+gamedata.config.trump_rebirth[tostring(count)].gem
            if price>0 then costs={{cid=1001,num=price}} end
        else values={item.iid} end
    end
    local result={0,#keys}
    table.sort(keys)
    local seen={}
    for _,key in ipairs(keys) do
        local current=gamedata.cache.artifacts[key]
        if not current or seen[key] then return nil end
        seen[key]=true
        result[#result+1]=key
        result[#result+1]=req.artifactVersions and (req.artifactVersions[key] or req.artifactVersions[tostring(key)]) or current.localRevision or 0
    end
    for _,v in ipairs(values) do
        if type(v)~="number" or v%1~=0 or v<0 then return nil end
        result[#result+1]=v
    end
    return result,costs,values
end
local function send(req,opcode)
    local mutation=opcode~=5509
    if mutation and (gamedata.ext.localArtifactBusy or gamedata.ext.localFormationBusy or gamedata.ext.localSoulBusy or gamedata.ext.localEquipGrowthBusy) then
        return reject("神器或阵容正在结算，请等待回复；超时请重进游戏")
    end
    local values,costs,native={},{},nil
    if growth[opcode] then
        values,costs,native=growthRequest(req,opcode)
        if not values then return reject("神器选择已变化，请重新打开页面") end
    elseif opcode==5501 or opcode==5515 then
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
    table.insert(pending[opcode],{view=req.artifactView,costs=costs,values=native or values,
        returnJewel=opcode==5505 and req.jewelCid==0 and gamedata.cache.artifacts[req.iid]["jewel"..req.pos] or nil})
    gamedata.ext.localArtifactPending=pending
    if mutation then
        gamedata.ext.localArtifactBusy={opcode=opcode}
        gamedata.ext.localFormationBusy=gamedata.ext.localArtifactBusy
    end
    return 1,opcode,info:SerializeToString()
end

local function receive(fd,opcode)
    local queue=(gamedata.ext.localArtifactPending or {})[opcode] or {}
    if fd.ser==0 or #queue==0 or fd.ser and received[opcode] and fd.ser<=received[opcode] then
        return {type=opcode,localArtifactIgnored=true}
    end
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
    elseif growth[opcode] then
        local outputs={}
        local function read(raw)
            local info=params_pb.ParamS();info:ParseFromString(raw)
            local item=gamedata:Newartifact({info})[1]
            outputs[#outputs+1]=item
        end
        if opcode==5502 or opcode==5540 or opcode==5542 or opcode==5543 or opcode==5544 then read(fd.rbuf)
        elseif opcode==5518 or opcode==5541 then
            local info=ids_pb.Ids();info:ParseFromString(fd.rbuf)
            local current=gamedata.cache.artifacts[pending.values[1]]
            if opcode==5518 then current.isLockState=info.ids[2]
            else
                for i=1,3 do current["skill"..i.."_cid_bk"]=info.ids[i] end
            end
            current.localRevision=(current.localRevision or 0)+1
            outputs[1]=current
        elseif opcode==5507 then
            local info=somethings_pb.SomeThings();info:ParseFromString(fd.rbuf)
            result.reward=gamedata:SomethingProcess(info)
        else
            local info=combmessages_pb.CombMessages();info:ParseFromString(fd.rbuf)
            for _,v in ipairs(info.messages) do
                if opcode==5520 and v.id==0 then
                    local reward=somethings_pb.SomeThings();reward:ParseFromString(v.data)
                    result.reward=gamedata:SomethingProcess(reward)
                else read(v.data) end
            end
        end
        local removed={}
        if opcode==5502 or opcode==5517 or opcode==5519 then
            local first=opcode==5519 and 2 or 1
            local last=#pending.values-(opcode==5517 and 1 or 0)
            for i=first,last do removed[#removed+1]=pending.values[i] end
        end
        for _,key in ipairs(removed) do
            local item=gamedata.cache.artifacts[key]
            for i=1,4 do
                local cid=item["jewel"..i]
                if cid>0 then gamedata:updateJewelData({{cid=cid,num=1}}) end
            end
            gamedata.cache.artifacts[key]=nil
        end
        if opcode==5505 and pending.values[2]==0 then
            -- 原孔宝石已由回包覆盖，发送前保存的 CID 用于一次性归还。
            local cid=pending.returnJewel
            if cid and cid>0 then gamedata:updateJewelData({{cid=cid,num=1}}) end
        end
        result.artifactData=gamedata.cache.artifacts[pending.values[1]]
        result.artifact=result.artifactData
        result.artifacts={}
        result.swapData={}
        result.artifactList={}
        for i,v in ipairs(outputs) do
            result.artifacts[i]=v;result.artifacts[tostring(i)]=v
            result.swapData[tostring(i)]=v
            result.artifactList[i]={v}
        end
        if opcode==5502 then result.rewardArtifact=outputs end
        if opcode==5520 then
            for _,item in ipairs(outputs) do
                if item.iid~=pending.values[1] then
                    result.reward[#result.reward+1]={cid=item.cid,iid=item.iid,num=1,double=0,order=100}
                end
            end
        end
        if opcode==5517 then result.showType="3" end
        if opcode==5518 then result.artifactSid=pending.values[1];result.isLock=pending.values[2] end
        if opcode==5505 then result.mountType=pending.values[2]>0 and 1 or 0 end
        if opcode==5506 then result.isOk=result.artifactData["jewel"..pending.values[2]] end
        if opcode==5540 then result.pos=pending.values[2];result.curType=pending.values[3] end
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
        result.jewelData=table.copy(gamedata.cache.jewels or {})
        local busy=gamedata.ext.localFormationBusy
        if busy==gamedata.ext.localArtifactBusy and busy and busy.opcode==opcode then gamedata.ext.localFormationBusy=nil end
        if gamedata.ext.localArtifactBusy and gamedata.ext.localArtifactBusy.opcode==opcode then gamedata.ext.localArtifactBusy=nil end
    end
    result.artifactRevision=gamedata.ext.localArtifactRevision or 0
    if fd.ser then received[opcode]=fd.ser end
    return result
end

for _,entry in ipairs({
    {5501,"UIArtifactCastCallBack","NetArtifactCastCallBack"},
    {5503,"UIArtifactChangeCallBack","NetArtifactChangeCallBack"},
    {5508,"UIArtifactCheckCallBack","NetArtifactCheckCallBack"},
    {5509,"UIArtifactCheckTimeCallBack","NetArtifactCheckTimeCallBack"},
    {5515,"UIUserArtifactOnceMakeCallBack","NetUserArtifactOnceMakeCallBack"},
    {5516,"UIUserArtifactOnceCheckupCallBack","NetUserArtifactOnceCheckupCallBack"},
    {5502,"UIArtifactCommpondCallBack","NetArtifactCommpondCallBack"},
    {5504,"UIArtifactOpenPosCallBack","NetArtifactOpenPosCallBack"},
    {5505,"UIArtifactMountJewelCallBack","NetArtifactMountJewelCallBack"},
    {5506,"UIJewelUpgradeCallBack","NetJewelUpgradeCallBack"},
    {5507,"UIJewelCommpondCallBack","NetJewelCommpondCallBack"},
    {5517,"UIUserArtifactRecastCallBack","NetUserArtifactRecastCallBack"},
    {5518,"UIUserArtifactLockCallBack","NetUserArtifactLockCallBack"},
    {5519,"UIUserArtifactStrengthenCallBack","NetUserArtifactStrengthenCallBack"},
    {5520,"UIUserArtifactRenascenceCallBack","NetUserArtifactRenascenceCallBack"},
    {5540,"UIUserArtifactOpeningCallBack","NetUserArtifactOpeningCallBack"},
    {5541,"UIUserArtifactBaptizeCallBack","NetUserArtifactBaptizeCallBack"},
    {5542,"UIUserArtifactBaptizeReplaceCallBack","NetUserArtifactBaptizeReplaceCallBack"},
    {5543,"UIUserArtifactSkillUpCallBack","NetUserArtifactSkillUpCallBack"},
    {5544,"UIUserArtifactSkillWashCancelCallBack","NetUserArtifactSkillWashCancelCallBack"},
    {5545,"UIUserArtifactSkillExchangeCallBack","NetUserArtifactSkillExchangeCallBack"},
    {5546,"UIUserArtifactStrenExchangeCallBack","NetUserArtifactStrenExchangeCallBack"},
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
local jewels=UIJewelListDataCallBack
function UIJewelListDataCallBack(req)
    local mode,opcode,result=jewels(req)
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
function LocalArtifactError(opcode,ser)
    if ser and received[opcode] and ser<=received[opcode] then return end
    local pending=table.remove((gamedata.ext.localArtifactPending or {})[opcode] or {},1)
    if pending and ser then received[opcode]=ser end
    local busy=gamedata.ext.localArtifactBusy
    if pending and busy and busy.opcode==opcode then
        if gamedata.ext.localFormationBusy==busy then gamedata.ext.localFormationBusy=nil end
        gamedata.ext.localArtifactBusy=nil
    end
    return pending
end
