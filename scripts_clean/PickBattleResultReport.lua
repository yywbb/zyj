--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/9/25
-- Time: 上午10:26
-- To change this template use File | Settings | File Templates.
--

require"BattleReportConvertPbToTab.lua"
require"myjson"

function PickBattleResultReport(battleresult)
--    if battleresult.battlereport2 then
--
--        report2 =MakeJsonStringFromTable(BattleReportConvertPbToTab(battleresult.battlereport2))
--        if #report2 < 200 then
--            cclog("pick battlereport")
--            cclog(battleresult.battlereport)
--            return battleresult.battlereport
--        end
--        cclog("pick battlereport2")
--        cclog(report2)
--        cclog(battleresult.battlereport)
--        return report2
--    else
--        cclog("pick battlereport")
--        cclog(battleresult.battlereport)
--        return battleresult.battlereport
--    end

    if battleresult.battlereport and battleresult.battlereport~="" then
        ---cclog("pick battlereport")
        ---cclog(battleresult.battlereport)
        return battleresult.battlereport
    else
        report2 =MakeJsonStringFromTable(BattleReportConvertPbToTab(battleresult.battlereport2))
        ---cclog("pick battlereport2")
        ---cclog(report2)
        ---cclog(battleresult.battlereport)
        return report2
    end
end

function PickBattleResultReportByKey(battleresult,key)

    if battleresult[key] and battleresult[key] ~= "" then
        return MakeJsonStringFromTable(BattleReportConvertPbToTab(battleresult[key]))
    else
        return nil
    end
end