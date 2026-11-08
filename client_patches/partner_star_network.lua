-- 伙伴升星 1029：同版配置报价、显示进度确认、共享在途锁、避 seq0 推送、匹配错误解锁。
-- 追加在 GameGeneralUp 末尾，覆盖原生 UIGeneralUpStarCallBack / NetGeneralUpStarCallBack。
local star_ids_pb=require("ids_pb")
local star_generals_pb=require("generals_pb")

local function fail(message) return 0,503,{type=503,msg=message} end
local function ids(values)
    local body=star_ids_pb.Ids()
    for _,v in ipairs(values) do table.insert(body.ids,v) end
    return body:SerializeToString()
end
local function parse(raw)
    local body=star_ids_pb.Ids();body:ParseFromString(raw);return body.ids
end
local function busy()
    local ext=gamedata.ext
    return ext.localPartnerStarBusy or ext.localPartnerGrowthBusy or ext.localLeadGrowthBusy
        or ext.localSoulBusy or ext.localEquipGrowthBusy or ext.localFormationBusy
end

function UIGeneralUpStarCallBack(req)
    if busy() then return fail("伙伴或阵容正在结算，请等待回复；未知超时请重进游戏") end
    -- UIRequest 注入的 partnerView 带完整显示进度（含 level5），旧页面或旧星数一律拒绝。
    local view=req.partnerStarView or req.partnerView
    local hero=view and gamedata.cache.generals[view.iid]
    if not hero or req.iid~=view.iid or hero.cid~=view.cid
        or (hero.level2 or 0)~=(view.advance or 0) or (hero.skilllevel or 0)~=(view.awake or 0)
        or (hero.level8 or 0)~=(view.soar or 0) or (hero.level5 or 0)~=(view.star or 0) then
        return fail("伙伴升星目标已变化，请重新打开页面")
    end
    local row=gamedata.config.general[tostring(hero.cid)]
    if not row or not row.rising_star or row.rising_star<=0 or (hero.level2 or 0)<=13 then
        return fail("伙伴升星尚未开放或该伙伴不能升星")
    end
    local star=hero.level5 or 0
    local nextConfig=gamedata.config.general_star[tostring(star+1)]
    if not nextConfig then return fail("伙伴升星已满级") end
    if (hero.level8 or 0)<nextConfig.limitlv then return fail("飞升等级不足，不能升星") end
    local cost=gamedata.getIDandNUMs(nextConfig.consume)
    if #cost==0 then return fail("伙伴升星消耗配置无效") end
    local pending={opcode=1029,iid=hero.iid,star=star,cost=cost,view=view}
    gamedata.ext.localPartnerStarBusy=pending
    gamedata.ext.localFormationBusy=pending
    return 1,1029,ids({hero.iid,hero.cid,star,hero.level8 or 0,hero.level2 or 0})
end

function NetGeneralUpStarCallBack(fd)
    local pending=gamedata.ext.localPartnerStarBusy
    if fd.ser==0 or not pending or pending.opcode~=1029 then return {type=1029,partnerStarIgnored=true} end
    local body=star_generals_pb.Generals();body:ParseFromString(fd.rbuf)
    gamedata:Generals(body.generals)
    for _,r in ipairs(pending.cost) do gamedata:updateStaff({cid=r.cid,num=-r.num}) end
    gamedata.ext.localPartnerStarBusy=nil
    if gamedata.ext.localFormationBusy==pending then gamedata.ext.localFormationBusy=nil end
    return {type=1029,ison=gamedata:isGeneralOn(pending.iid),general=gamedata.cache.generals[pending.iid],
        partnerStarView=pending.view}
end

-- 匹配 1029 的失败回包才解锁；其他在途操作继续由伙伴成长链处理。
local star_error_receive=NetErrorMessageCallback9
function NetErrorMessageCallback9(fd)
    local pending=gamedata.ext.localPartnerStarBusy
    local error=parse(fd.rbuf)
    local result=star_error_receive(fd)
    if pending and pending.opcode==error[1] then
        gamedata.ext.localPartnerStarBusy=nil
        if gamedata.ext.localFormationBusy==pending then gamedata.ext.localFormationBusy=nil end
        result.partnerStarErrorView=pending.view
    end
    return result
end
