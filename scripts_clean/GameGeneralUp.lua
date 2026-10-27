--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/12/26
-- Time: 15:25
-- To change this template use File | Settings | File Templates.
--

local equiprefine_pb = require("equiprefine_pb")
function UIUseExpDanCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1038, "UseExpDan")
    local upData = equiprefine_pb.EquipRefine()

    upData.iid = uireq.iid
    for i=1,4 do
        table.insert(upData.props,uireq.props[tostring(i)].num)
    end

    gamedata.ext.UseExpDan_props =  uireq.props
    gamedata.ext.UseExpDan_iid = uireq.iid

    return 1, 1038, upData:SerializeToString()
end

local t_somethings_pb = require("somethings_pb")
function NetUseExpDanCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1038, "UseExpDan")

    local upGetData = t_somethings_pb.SomeThings()
    upGetData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(upGetData)

    for i=1,4 do
        gamedata:updateprops({cid = gamedata.ext.UseExpDan_props[tostring(i)].cid, num = 0-gamedata.ext.UseExpDan_props[tostring(i)].num})
    end

    return { type = 1038,}
end


local ids_pb = require("ids_pb")
function UIGeneralArtifactLevelupCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1026, "GeneralArtifactLevelup")
    local upData = ids_pb.Ids()


    local nextlevel = gamedata.cache.generals[uireq.iid].level4+1

    local levelconfig = gamedata.config.shenqi[tostring(nextlevel)]
    local consume = gamedata.getIDandNUMs(levelconfig.lv_cost)


    for k,v in ipairs(consume) do
        local isenough, ret = gamedata.checkStaffEnough(v.cid,v.num)
        if not isenough then
            return 0, 503, ret
        end
    end
    
    table.insert(upData.ids,uireq.iid)
    return 1, 1026, upData:SerializeToString()
end

local generals_pb = require("generals_pb")
function NetGeneralArtifactLevelupCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1026, "GeneralArtifactLevelup")

    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)
    local nextGeneral = {}

    local generals = gamedata:Generals(GeneralsData.generals,true)
    -- for k,v in ipairs(GeneralsData.generals) do
    --     nextGeneral = gamedata:generalData(v)
    -- end

    --gamedata.cache.generals[nextGeneral.iid] = nextGeneral
    nextGeneral = generals[1]

    local levelconfig = gamedata.config.shenqi[tostring(nextGeneral.level4)]
    local consume = gamedata.getIDandNUMs(levelconfig.lv_cost)

    for k,v in ipairs(consume) do
        gamedata:updateStaff({cid = v.cid,num=0-v.num})
    end

    return { type = 1026,nextGeneral=nextGeneral}
end


function UIGeneralSkillLevelUpCostQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 10280, "GeneralSkillLevelUpCostQuery")
    local nums = {}
    for k,v in pairs(uireq.cids) do
        local num = gamedata.getStaffNum(v).num
        nums[v] = num
    end

    local combskills = {}
    for k,v in pairs(gamedata.cache.generals) do
        if v.combskill and v.combskill.cid and v.combskill.cid > 0 then
            if not combskills[v.combskill.cid] then
                combskills[v.combskill.cid] = {}
            end
            table.insert(combskills[v.combskill.cid],v)
        end
    end

    return 0, 10280, { type = 10280,props = nums,combskills = combskills}
end


function UIGeneralSkillLevelUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1028, "GeneralArtifactLevelup")

    printT(uireq,"UIGeneralSkillLevelUpCallBack")

    local upData = ids_pb.Ids()
    table.insert(upData.ids,uireq.method)
    table.insert(upData.ids,uireq.iid)

    if uireq.iids then
        for k,v in pairs(uireq.iids) do
            table.insert(upData.ids,v)
        end
    end

    gamedata.ext.SkillLevelUpInfo = uireq
    return 1, 1028, upData:SerializeToString()
end

function NetGeneralSkillLevelUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1028, "GeneralArtifactLevelup")

    for k,v in pairs(gamedata.ext.SkillLevelUpInfo.cost) do
        gamedata:updateStaff({cid = v.cid,num = -v.num })
    end

    local general = nil

    local islead = false
    local iid = gamedata.ext.SkillLevelUpInfo.iid
    if iid == gamedata.cache.protagonist.general.iid then
        general = gamedata.cache.protagonist.general
        islead = true
    else
        general = gamedata.cache.generals[iid]
    end

    if general then
        print("升级技能")
        if gamedata.ext.SkillLevelUpInfo.method == 0 then
            general.skilllevel1 = general.skilllevel1 + 1
        elseif gamedata.ext.SkillLevelUpInfo.method == 1 then
            general.skilllevel2 = general.skilllevel2 + 1

            if not islead then
                for k,v in pairs(gamedata.ext.SkillLevelUpInfo.iids) do
                    if gamedata.cache.generals[v] then
                        gamedata.cache.generals[v].skilllevel2 = gamedata.cache.generals[v].skilllevel2 + 1
                    end
                end
            end
            
        end
    end

    

    return { type = 1028,ison = gamedata:isGeneralOn(general.iid),general = general}
end

function UIGeneralUpStarCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1029, "GeneralUpStar")
    printT(uireq,"GeneralUpStar")

    local upData = ids_pb.Ids()
    table.insert(upData.ids,uireq.iid)

    gamedata.ext.generalUpStar = uireq
    return 1, 1029, upData:SerializeToString()
end

function NetGeneralUpStarCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1029, "GeneralUpStar")

    for k,v in pairs(gamedata.ext.generalUpStar.cost) do
        gamedata:updateStaff({cid = v.cid,num = -v.num })
    end

    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)
    local general = gamedata:Generals(GeneralsData.generals,true)[1]
    return { type = 1029,ison = gamedata:isGeneralOn(general.iid),general = general}
end


