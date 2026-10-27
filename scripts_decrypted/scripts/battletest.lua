--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/13
-- Time: 下午5:23
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local battleresult_pb = require("battleresult_pb")

function UImerorytestCallBack()
    cclog("NET type:%d cmd:%s recv request from UI", 979797, "merorytest")
    return 0,979797,{type = 979797, data = gamedata.config.general}
end

function UIbattletestCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 999990, "battletest")
    local battletestData = ids_pb.Ids()
--    table.insert(battletestData.ids, 10406)
--    table.insert(battletestData.ids, 10407)
--    table.insert(battletestData.ids, 10409)
--    table.insert(battletestData.ids, 10410)
--    table.insert(battletestData.ids, 10411)
--    table.insert(battletestData.ids, 10412)
--    table.insert(battletestData.ids, 10413)

    table.insert(battletestData.ids, 10516)
    table.insert(battletestData.ids, 10520)
    table.insert(battletestData.ids, 10508)
    table.insert(battletestData.ids, 10510)
    table.insert(battletestData.ids, 10523)
    table.insert(battletestData.ids, 10549)
    table.insert(battletestData.ids, 10415)

    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)

    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)

    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)

    table.insert(battletestData.ids, 10549)
    table.insert(battletestData.ids, 10415)
    table.insert(battletestData.ids, 10508)
    table.insert(battletestData.ids, 10510)
    table.insert(battletestData.ids, 10523)
    table.insert(battletestData.ids, 10520)
    table.insert(battletestData.ids, 10538)

    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)
    table.insert(battletestData.ids, 150)

    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)
    table.insert(battletestData.ids, 10)

    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)
    table.insert(battletestData.ids, 2)


    return 1, 999990, battletestData:SerializeToString()
end
require"MergeBattleReport"
function NetbattletestCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 999990, "battletest")

    local battletestData = battleresult_pb.BattleResult()
    battletestData:ParseFromString(fd.rbuf)
    --local testStory = '{"battle":{"action":[{"content":"牛哥，咱们演示一下合体技！","type":"talk","direct":true,"general":10508},{"content":"好啊，来一发！","type":"talk","direct":true,"general":10510},{"dest":[{"direct":false,"pos":14,"damage":{"status":"critical;dead","num":2,"damage":3000}},{"direct":false,"pos":12,"damage":{"status":"critical;dead","num":2,"damage":3000}}],"source":{"type":"comb","pos":["14","12"],"direct":true},"type":"battle"}],"init":{"attack":{"12":{"id":2,"boss":true},"14":{"id":1,"boss":true}},"defense":{"12":{"id":102,"boss":false},"14":{"id":101,"boss":false}}}},"meta":{"attack":{"generals":{"1":{"name":"牛魔王","defaultskill":{"id":12510},"level":100,"hp2":10000,"hp":10000,"cid":10510,"pos":14,"id":1},"2":{"name":"齐天大圣","defaultskill":{"id":12508},"level":100,"hp2":10000,"hp":10000,"cid":10508,"pos":12,"id":2}},"name":"1"},"defense":{"generals":{"102":{"name":"弓箭手","defaultskill":{"id":12206},"level":100,"hp2":2000,"hp":2000,"cid":10206,"pos":12,"id":102},"101":{"name":"弓箭手","defaultskill":{"id":12206},"level":100,"hp2":2000,"hp":2000,"cid":10206,"pos":14,"id":101}},"name":"2"}},"type":"battle","result":null}'
--    local testStory = '{"battle":{"action":[{"content":"又遇到BOSS了吗?让你见识一下无所不能的我以前属下的实力！","type":"talk","direct":false,"general":10601},{"content":"那就让我见识一下吧！","type":"talk","direct":true,"general":0},{"changes":[{"opt":"appear","general":1000000000,"direct":true,"boss":false,"pos":12}],"type":"pos"},{"content":"我来助你！","type":"talk","direct":true,"general":10507},{"content":"这么NB，让你见识一下人多势众。","type":"talk","direct":false,"general":10302},{"changes":[{"opt":"appear","general":1100000005,"direct":false,"boss":false,"pos":6},{"opt":"appear","general":1100000006,"direct":false,"boss":false,"pos":12},{"opt":"appear","general":1100000007,"direct":false,"boss":false,"pos":14}],"type":"pos"},{"content":"看我的","type":"talk","direct":true,"general":10507},{"dest":[{"direct":false,"pos":8,"damage":{"status":"normal","num":0,"damage":11519}},{"direct":false,"pos":10,"damage":{"status":"normal","num":0,"damage":11519}},{"direct":false,"pos":12,"damage":{"status":"normal;dead","num":0,"damage":11519}},{"direct":false,"pos":14,"damage":{"status":"normal;dead","num":0,"damage":11519}}],"source":{"type":"skill","pos":[12],"direct":true},"type":"battle"},{"changes":[{"opt":"appear","general":1000000001,"direct":true,"boss":false,"pos":6}],"type":"pos"},{"content":"魔王大人岂是你能惹得！","type":"talk","direct":true,"general":10502},{"dest":[{"direct":false,"pos":2,"damage":{"status":"normal","num":0,"damage":5119}},{"direct":false,"pos":4,"damage":{"status":"normal","num":0,"damage":5119}},{"direct":false,"pos":6,"damage":{"status":"normal;dead","num":0,"damage":5119}}],"source":{"type":"skill","pos":[6],"direct":true},"type":"battle"},{"content":"剩下的就交给你了，下次再见！","type":"talk","direct":true,"general":10507},{"content":"我们没完！","type":"talk","direct":false,"general":10302}],"init":{"attack":{},"defense":{"8":{"id":1100000002,"boss":false},"2":{"id":1100000000,"boss":false},"4":{"id":1100000001,"boss":false},"10":{"id":1100000003,"boss":false}}}},"meta":{"attack":{"generals":{"1000000001":{"name":"关羽","defaultskill":{"id":12502},"level":100,"hp2":500000,"hp":500000,"cid":10502,"pos":6,"id":1000000001},"0":{"name":"主角","defaultskill":null,"level":0,"hp2":0,"hp":0,"cid":0,"id":0},"1000000000":{"name":"二郎神","defaultskill":{"id":12507},"level":100,"hp2":50000,"hp":50000,"cid":10507,"pos":12,"id":1000000000}},"name":""},"defense":{"generals":{"1100000000":{"name":"孟婆","defaultskill":{"id":12302},"level":1,"hp2":5120,"hp":5120,"cid":10302,"pos":2,"id":1100000000},"1100000001":{"name":"马面","defaultskill":{"id":12204},"level":1,"hp2":5120,"hp":5120,"cid":10204,"pos":4,"id":1100000001},"1100000002":{"name":"孤魂","defaultskill":{"id":12202},"level":1,"hp2":11520,"hp":11520,"cid":10202,"pos":8,"id":1100000002},"1100000003":{"name":"牛头","defaultskill":{"id":12203},"level":1,"hp2":11520,"hp":11520,"cid":10203,"pos":10,"id":1100000003},"1100000004":{"name":"魔王","defaultskill":null,"level":1,"hp2":1,"hp":1,"cid":10601,"id":1100000004},"1100000005":{"name":"野鬼","defaultskill":{"id":12201},"level":1,"hp2":5119,"hp":5119,"cid":10201,"pos":6,"id":1100000005},"1100000006":{"name":"牛头","defaultskill":{"id":12203},"level":1,"hp2":11519,"hp":11519,"cid":10203,"pos":12,"id":1100000006},"1100000007":{"name":"骷髅","defaultskill":{"id":12205},"level":1,"hp2":11519,"hp":11519,"cid":10205,"pos":14,"id":1100000007}},"name":""}},"type":"battle","result":true}'
--    local report = MergeBattleReport(battletestData.battlereport,testStory)
--    cclog(report)
    local t = {
        type = 999990,
        result = battletestData.result,
        battlereport = PickBattleResultReport(battletestData)
    }
    return t
end

function UIbattletest(t)
    print("战斗测试")
    printT(t)
    RunbattleCallBack("test", t)
end

function UImerorytest(t)
    print("内存测试")
    --printT(t)
end ?"  