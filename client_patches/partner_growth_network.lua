-- 费用由同版配置计算；一次在途、显示进度确认，未知结果不重试。
require("GameGeneralAwanken")
require("GameGeneralXiuLian")
require("GameGeneralFeiSheng")
require("GamePropList")
require("GameErrorMessage")
local ids_pb=require("ids_pb")
local generals_pb=require("generals_pb")
local comb_pb=require("combmessages_pb")
local progress={}
local levels={}
local serial=0
local updateGenerals=gamedata.Generals
function gamedata.Generals(self,rows,...)
    for _,raw in ipairs(rows) do
        local hero=self.cache.generals[raw.iid]
        if hero and ((raw.level1 or 1)<hero.level1 or (raw.level2 or 0)<hero.level2
            or (raw.skilllevel or 0)<hero.skilllevel or (raw.fei_sheng_level or 0)<hero.level8) then
            progress[raw.iid]=nil;levels[raw.iid]=nil
            hero.level6,hero.level7=0,0
        end
    end
    local result=updateGenerals(self,rows,...)
    for _,raw in ipairs(rows) do
        local hero,data=self.cache.generals[raw.iid],levels[raw.iid]
        if hero and data then hero.level6,hero.level7=data[1],data[2] end
    end
    return result
end

local function fail(message) return 0,503,{type=503,msg=message} end
local function ids(values)
    local body=ids_pb.Ids()
    for _,v in ipairs(values) do table.insert(body.ids,v) end
    return body:SerializeToString()
end
local function parse(raw)
    local body=ids_pb.Ids();body:ParseFromString(raw);return body.ids
end
local function add(cost,cid,num)
    if num and num>0 then table.insert(cost,{cid=cid,num=num}) end
end
local function fragment(origin)
    for _,row in pairs(gamedata.config.general_fragment) do if row.general==origin then return row.id end end
end
local function research(iid,data)
    progress[iid]=data
    levels[iid]={data[1],data[6]}
    local hero=gamedata.cache.generals[iid]
    hero.level6,hero.level7=data[1],data[6]
    local result={iid=iid,heart1=data[5],heart2=data[10]}
    for kind=1,2 do
        local offset=(kind-1)*5
        for i=1,3 do
            local _,scale=string.match(gamedata.config.Immortal_type[tostring(kind)]["attr"..i],"([^,]+),([^,]+)")
            local index=(kind-1)*4+i
            local extra=0
            for level=0,data[offset+1]-1 do
                local _,amount=string.match(gamedata.config.Immortal_level[tostring(kind)][tostring(level)]["stageAttr"..i],"([^,]+),([^,]+)")
                extra=extra+tonumber(amount)
            end
            result["attrA"..index]=extra
            result["attr"..index]=data[offset+i+1]*tonumber(scale)+extra
        end
    end
    gamedata.cache.xiuLianData=gamedata.cache.xiuLianData or {}
    gamedata.cache.xiuLianData[iid]=result
    return result
end
function UIGeneralXiuLianLevelInfoCallBack(req) return 1,5511,nil end
function NetGeneralXiuLianLevelInfoCallBack(fd)
    local data=parse(fd.rbuf)
    levels={}
    for i=1,#data,3 do
        levels[data[i]]={data[i+1],data[i+2]}
        local hero=gamedata.cache.generals[data[i]]
        if hero then hero.level6,hero.level7=data[i+1],data[i+2] end
    end
    return {type=5511,isUpdate=1}
end
for _,entry in ipairs({{1023,"UIGeneralBreakPreviewCallBack","NetGeneralBreakPreviewCallBack"},
    {5512,"UIGeneralXiuLianInfoCallBack","NetGeneralXiuLianInfoCallBack"}}) do
    local opcode=entry[1]
    local queue={}
    _G[entry[2]]=function(req)
        local iid=req.general or req.iid
        if req.partnerView and req.partnerView.iid~=iid then return fail("伙伴查询目标已变化") end
        table.insert(queue,{iid=iid,view=req.partnerView})
        return 1,opcode,ids({iid})
    end
    _G[entry[3]]=function(fd)
        if fd.ser==0 or #queue==0 then return {type=opcode,partnerIgnored=true} end
        local pending=table.remove(queue,1)
        if opcode==5512 then
            local data=parse(fd.rbuf);serial=data[11]
            return {type=opcode,general=research(pending.iid,data),partnerView=pending.view}
        end
        local data=generals_pb.Generals();data:ParseFromString(fd.rbuf)
        return {type=opcode,nextGeneral=gamedata:generalData(data.generals[1]),partnerView=pending.view,
            generalslove=gamedata.cache.generalslove.alldata or {}}
    end
    gamedata.ext["partnerQuery"..opcode]=queue
end

local function send(req,opcode)
    if gamedata.ext.localFormationBusy or gamedata.ext.localSoulBusy or gamedata.ext.localEquipGrowthBusy then
        return fail("伙伴或阵容正在结算，请等待回复；未知超时请重进游戏")
    end
    local view=req.partnerView
    local hero=view and gamedata.cache.generals[view.iid]
    if not hero or hero.cid~=view.cid or hero.level2~=view.advance or hero.skilllevel~=view.awake or hero.level8~=view.soar then
        return fail("伙伴或显示进度已变化，请重新打开页面")
    end
    if req.iid and req.iid~=hero.iid or opcode==1017 and (req.ids[1] or req.ids["1"])~=hero.cid then
        return fail("伙伴请求目标已变化，请重新打开页面")
    end
    local row=gamedata.config.general[tostring(hero.cid)]
    local origin=gamedata.config.general[tostring(row.init_cid)]
    local cost,values={},{}
    if opcode==1017 then
        local target=hero.level2+1
        local step=gamedata.config.general_awake[tostring(target)]
        if not step then return fail("此伙伴已达突破上限") end
        local quality=target>13 and 7 or target>10 and 6 or row.quality
        add(cost,1000,step["coin"..quality]);add(cost,20017,step[quality.."prop"])
        add(cost,fragment(row.init_cid),step[quality.."piece"])
        add(cost,20354,step.red_cost);add(cost,20551,step.red_cost2)
        if step.red_item>0 then
            local red=row.quality==6 and hero.cid or row.red_id~=0 and row.red_id or row.break_id
            for _,r in pairs(gamedata.config.redl_awake_item) do if r.red_id==red then add(cost,r.id,step.red_item) end end
        end
        for _,r in ipairs(gamedata.getIDandNUMs(step.gold_cost or "")) do add(cost,r.cid,r.num) end
        values={hero.cid,req.scope or 0}
        if target>10 then table.insert(values,hero.level2) end
    elseif opcode==1025 then
        local base=tonumber((gamedata.config.global_kv["general_awaken"..origin.basic] or {}).value) or 0
        local step=gamedata.config.general_awaken[tostring(math.max(hero.skilllevel,base)+1)]
        if not step then return fail("伙伴觉醒已满级") end
        cost=gamedata.getIDandNUMs(step.consume1)
        for _,r in ipairs(gamedata.getIDandNUMs(step["consume_"..origin.basic] or "")) do add(cost,r.cid,r.num) end
        add(cost,fragment(row.init_cid),step.number)
        values={hero.iid,hero.skilllevel}
    elseif opcode==7001 then
        local step=gamedata.config.partner_soaring[tostring(hero.level8+1)]
        if not step then return fail("伙伴飞升已满级") end
        cost=gamedata.getIDandNUMs(step[origin.basic.."consume"])
        values={hero.iid,hero.level8}
    else
        local data=progress[hero.iid]
        if not data then return fail("请先查询当前伙伴进修进度") end
        local offset=(req.xiuLian-1)*5
        local step=gamedata.config.Immortal_level[tostring(req.xiuLian)][tostring(data[offset+1])]
        cost=gamedata.getIDandNUMs(req.isBreak==1 and step.extraConsume or step.consumeEveryTimes)
        values={hero.iid,req.xiuLian,req.isBreak,data[offset+1],data[offset+5],serial}
    end
    local pending={opcode=opcode,iid=hero.iid,cost=cost,view=view}
    gamedata.ext.localPartnerGrowthBusy=pending
    gamedata.ext.localFormationBusy=pending
    return 1,opcode,ids(values)
end
local function receive(fd,opcode)
    local pending=gamedata.ext.localPartnerGrowthBusy
    if fd.ser==0 or not pending or pending.opcode~=opcode then return {type=opcode,partnerIgnored=true} end
    local raw,data=fd.rbuf
    if opcode==5513 then
        local body=comb_pb.CombMessages();body:ParseFromString(raw)
        for _,message in ipairs(body.messages) do
            if message.id==0 then raw=message.data elseif message.id==1 then data=parse(message.data) end
        end
    end
    local body=generals_pb.Generals();body:ParseFromString(raw)
    gamedata:Generals(body.generals)
    for _,r in ipairs(pending.cost) do gamedata:updateStaff({cid=r.cid,num=-r.num}) end
    local detail
    if data then serial=data[11];detail=research(pending.iid,data)
    elseif progress[pending.iid] then detail=research(pending.iid,progress[pending.iid]) end
    gamedata.ext.localPartnerGrowthBusy=nil
    if gamedata.ext.localFormationBusy==pending then gamedata.ext.localFormationBusy=nil end
    return {type=opcode,general=gamedata.cache.generals[pending.iid],ison=gamedata:isGeneralOn(pending.iid),
        generalXiuLian=detail,partnerView=pending.view}
end
for _,entry in ipairs({{1017,"UIGeneralBreakCallBack","NetGeneralBreakCallBack"},
    {1025,"UIGeneralAwakenCallBack","NetGeneralAwakenCallBack"},
    {5513,"UIGeneralXiuLianCallBack","NetGeneralXiuLianCallBack"},
    {7001,"UIPartnerFeiShengCallBack","NetPartnerFeiShengCallBack"}}) do
    local opcode=entry[1]
    _G[entry[2]]=function(req) return send(req,opcode) end
    _G[entry[3]]=function(fd) return receive(fd,opcode) end
end
local query=UIPropQueryByIdCallback
function UIPropQueryByIdCallback(req)
    local mode,mid,result=query(req)
    if mode==0 and result then result.partnerView=req.partnerView end
    return mode,mid,result
end
local errorReceive=NetErrorMessageCallback9
function NetErrorMessageCallback9(fd)
    local pending=gamedata.ext.localPartnerGrowthBusy
    local error=parse(fd.rbuf)
    local result=errorReceive(fd)
    if pending and pending.opcode==error[1] then result.partnerErrorView=pending.view end
    return result
end
