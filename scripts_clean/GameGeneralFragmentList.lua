--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-18
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local function makeGeneralFragment()

    for k ,v in pairs(gamedata.cache.generalfragments) do
        gamedata:updategeneralfragmentbynum({cid = v.cid,num=0})
    end


    local GeneralFragments = table.copy(gamedata.cache.generalfragments)
    local sortGeneralFragments = {}

    for k,v in pairs(GeneralFragments) do
        local generalcid = v.cid --gamedata.config.general_fragment[tostring(v.cid)].general
        local quality = gamedata.config.general[tostring(generalcid)].quality
        GeneralFragments[k].quality =  quality
        table.insert(sortGeneralFragments, GeneralFragments[k])
    end
    gamedata.sortData(sortGeneralFragments, "quality","cid")
    return  sortGeneralFragments

    --添加字段
    -- local  lenFragments = table.getn(sortGeneralFragments)
    -- for i =1,lenFragments do
    --     if sortGeneralFragments[i].neednum <= 0 and sortGeneralFragments[i].quality > 2 then
    --         sortGeneralFragments[i].sotisfy = 1
    --     else
    --         sortGeneralFragments[i].sotisfy = 0
    --     end
    --     if sortGeneralFragments[i].status == 1 and sortGeneralFragments[i].sotisfy == 1 then
    --         sortGeneralFragments[i].stt = 2
    --     else
    --         sortGeneralFragments[i].stt = 1
    --     end
    -- end
    -- gamedata.sortData(sortGeneralFragments, "sotisfy","stt","quality","num","cid")
    -- return  sortGeneralFragments

end


function UIGeneralFragmentListCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1012, "generalfragments")
    if next(gamedata.cache.generalfragments) then
        return 0, 1012, { type = uireq.type, generalfragments = makeGeneralFragment()}--, robgenerals = makeGeneralRob()}
    else
        return 1, 1012, nil
    end
end

local generalfragments_pb = require("generalfragments_pb")
function NetGeneralFragmentListCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1012, "generalfragments")
    local generalfragmentsData = generalfragments_pb.GeneralFragments()
    generalfragmentsData:ParseFromString(fd.rbuf)

    gamedata.cache.generalfragments = {}
    gamedata:GeneralFragments(generalfragmentsData.fragments)


    return { type = 1012, generalfragments = makeGeneralFragment()}--, robgenerals = makeGeneralRob()}
end

function UIGeneralFragmentByIdCallback(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 10121, "generalfragments")

    printT(uireq)
    return 0, 10121, { type = 10121, order = uireq.order, fragment = gamedata.cache.generalfragments[uireq.generalCid] }
end
