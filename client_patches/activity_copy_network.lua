-- 六类活动共用查询和在途锁，防止阵符结果读取另一场的难度。
local sendQuery,receiveQuery=UIActivityCopyCallback,NetActivityCopyCallback
function UIActivityCopyCallback(req)
    local mode,mid,raw=sendQuery(req)
    if mode==1 then
        local queue=gamedata.ext.localActivityCopyQueries or {}
        table.insert(queue,{temp=req.temp,view=req.activityCopyView});gamedata.ext.localActivityCopyQueries=queue
    end
    return mode,mid,raw
end
function NetActivityCopyCallback(fd)
    local req=fd.ser~=0 and table.remove(gamedata.ext.localActivityCopyQueries or {},1) or nil
    local result=receiveQuery(fd)
    result.temptype=req and req.temp
    result.activityCopyView=req and req.view
    return result
end
for _,row in ipairs({
    {1341,"UIActivityCoinCopyCallback","NetyActivityCoinCopyCallback"},
    {1342,"UIActivityExpDanCopyCallback","NetActivityExpDanCopyCallback"},
    {1343,"UIActivityForgeStoneCopyCallback","NetActivityForgeStoneCopyCallback"},
    {1344,"UIActivityEquipStarCopyCallback","NetActivityEquipStarCopyCallback"},
    {1345,"UIActivityZhenfuCopyCallback","NetActivityZhenfuCopyCallback"},
    {1347,"UIActivityForgingCopyCallback","NetActivityForgingCopyCallback"},
}) do
    local opcode,send,receive=row[1],_G[row[2]],_G[row[3]]
    _G[row[2]]=function(req)
        if gamedata.ext.localActivityCopyBusy then return 0,503,{type=503,msg="活动副本正在结算，请等待回复；未知超时请重进游戏"} end
        local mode,mid,raw=send(req)
        if mode==1 then
            gamedata.ext.localActivityCopyBusy=opcode
            gamedata.ext.localActivityCopyView=req.activityCopyView
        end
        return mode,mid,raw
    end
    _G[row[3]]=function(fd)
        if fd.ser==0 or gamedata.ext.localActivityCopyBusy~=opcode then return {type=opcode,localActivityCopyIgnored=true} end
        local result=receive(fd)
        result.activityCopyView=gamedata.ext.localActivityCopyView
        gamedata.ext.localActivityCopyBusy=nil
        gamedata.ext.localActivityCopyView=nil
        return result
    end
end
