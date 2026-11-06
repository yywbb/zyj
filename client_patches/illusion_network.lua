-- 原生PB不能跳过未知字段；100仅承载本功能的权威列表/序号，先分离再解析。
require("GameSlots")
require("GameGeneralBreak")
require("GameErrorMessage")
local ids_pb=require("ids_pb")
local generals_pb=require("generals_pb")
local serial=-1
local queries={}
local pending
local function ids(values)
    local body=ids_pb.Ids()
    for _,v in ipairs(values) do table.insert(body.ids,v) end
    return body:SerializeToString()
end
local function parse(raw)
    local body=ids_pb.Ids();body:ParseFromString(raw);return body.ids
end
local function split(raw)
    local pos,native,extra=1,{},nil
    local function varint()
        local value,factor=0,1
        for i=1,10 do
            local byte=raw:byte(pos)
            assert(byte and (i<10 or byte<=1),"幻化回包整数无效")
            pos=pos+1;value=value+(byte%128)*factor
            if byte<128 then return value end
            factor=factor*128
        end
    end
    while pos<=#raw do
        local start=pos
        local tag=varint();local field,wire=math.floor(tag/8),tag%8
        assert(field>0,"幻化回包字段无效")
        local value
        if wire==0 then varint()
        elseif wire==2 then
            local size=varint();value=raw:sub(pos,pos+size-1);pos=pos+size
        elseif wire==1 then pos=pos+8
        elseif wire==5 then pos=pos+4
        else error("幻化回包类型无效") end
        assert(pos<=#raw+1,"幻化回包已截断")
        if field==100 then assert(wire==2 and not extra,"幻化扩展无效");extra=value
        else table.insert(native,raw:sub(start,pos-1)) end
    end
    assert(extra,"幻化服务端版本不匹配，请更新服务端和客户端")
    return table.concat(native),extra
end
local function update(raw)
    local native,extra=split(raw)
    local version=parse(extra)
    assert(#version==1 and version[1]>=0,"幻化序号无效")
    if version[1]<serial then return false end
    local rows=parse(native)
    assert(#rows%3==0,"幻化列表无效")
    serial=version[1]
    gamedata.cache.illusion={}
    gamedata:illusions(rows)
    return true
end
local function result(opcode,view)
    return {type=opcode,data=makeIllusionDatas(),illusionView=view,illusionSerial=serial}
end
local function reject(message) return 0,503,{type=503,msg=message} end
function UIIllusionQueryCallBack(req)
    table.insert(queries,{view=req.illusionView})
    return 1,8110,ids({1})
end
function NetIllusionQueryCallBack(fd)
    local query
    if fd.ser~=0 and not fd.localIllusionInit then
        if #queries==0 then return {type=8110,illusionIgnored=true} end
        query=table.remove(queries,1)
    end
    if not update(fd.rbuf) then return {type=8110,illusionIgnored=true} end
    local value=result(8110,query and query.view)
    value.illusionPush=fd.ser==0 or fd.localIllusionInit
    return value
end
local function send(req,opcode)
    if pending or gamedata.ext.localFormationBusy or gamedata.ext.localSoulBusy or gamedata.ext.localEquipGrowthBusy then
        return reject("幻化或阵容正在结算，请等待回复；未知超时请重进游戏")
    end
    local expected=req.illusionExpected
    local item=expected and gamedata.cache.illusion[expected.cid]
    if not item or serial~=expected.serial or item.endtime~=expected.endtime or item.generalIid~=expected.generalIid then
        return reject("幻影或绑定已变化，请重新打开幻化页面")
    end
    local hero=gamedata.cache.generals[req.generalIid or expected.generalIid]
    if not hero then return reject("伙伴已变化，请重新选择") end
    local values={item.cid,hero.iid,item.endtime,item.generalIid,serial}
    if opcode==7021 then
        if req.selectIllusion~=1 or hero.cid~=req.cid or hero.iid~=item.generalIid or not hero.illusionGeneralCid then return reject("请选择当前幻影的彩金技能") end
        values={1,hero.cid,item.cid,serial}
        local choices={}
        for _,v in pairs(req.xselect or {}) do choices[#choices+1]=v end
        table.sort(choices,function(a,b) return a.lv<b.lv end)
        for _,v in ipairs(choices) do values[#values+1]=v.lv;values[#values+1]=v.scope end
    end
    pending={opcode=opcode,view=req.illusionView,iid=hero.iid}
    gamedata.ext.localFormationBusy=pending
    return 1,opcode,ids(values)
end
local function receive(fd,opcode)
    if fd.ser==0 or not pending or pending.opcode~=opcode then return {type=opcode,illusionIgnored=true} end
    local native,query=split(fd.rbuf)
    if opcode~=8112 then
        local body=generals_pb.Generals();body:ParseFromString(native);gamedata:Generals(body.generals)
    else
        local hero=gamedata.cache.generals[pending.iid]
        hero.illusion={};hero.illusionGeneralCid=nil
        gamedata:Generals({hero})
    end
    update(query)
    local value=result(opcode,pending.view)
    if gamedata.ext.localFormationBusy==pending then gamedata.ext.localFormationBusy=nil end
    pending=nil
    return value
end
for _,entry in ipairs({{8111,"UIIllusionExeCallBack","NetIllusionExeCallBack"},
    {8112,"UIIllusionCancelCallBack","NetIllusionCancelCallBack"},
    {7021,"UIGeneralChangeBreakSkillCallBack","NetGeneralChangeBreakSkillCallBack"}}) do
    local opcode=entry[1]
    _G[entry[2]]=function(req) return send(req,opcode) end
    _G[entry[3]]=function(fd) return receive(fd,opcode) end
end
local errorReceive=NetErrorMessageCallback9
function NetErrorMessageCallback9(fd)
    local opcode=parse(fd.rbuf)[1]
    local view=pending and pending.opcode==opcode and pending.view
    if fd.ser~=0 and opcode==8110 then table.remove(queries,1) end
    local value=errorReceive(fd)
    if fd.ser~=0 and pending and pending.opcode==opcode then
        if gamedata.ext.localFormationBusy==pending then gamedata.ext.localFormationBusy=nil end
        pending=nil;value.illusionView=view
    end
    return value
end
