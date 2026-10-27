--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 14/12/27
-- Time: 上午10:12
-- To change this template use File | Settings | File Templates.
--

local BATTLEREPORT_ABB_TO_KEY = {
    ['"i"']='"id"',
    ['"c"']='"cid"',
    ['"n"']='"name"',
    ['"l"']='"level"',
    ['"h"']='"hp"',
    ['"j"']='"hp2"',
    ['"d"']='"defaultskill"',
    ['"g"']='"generals"',
    ['"o"']='"boss"',
    ['"b"']='"battle"',
    ['"a"']='"action"',
    ['"e"']='"dest"',
    ['"t"']='"type"',
    ['"s"']='"source"',
    ['"r"']='"direct"',
    ['"p"']='"pos"',
    ['"m"']='"damage"',
    ['"i"']='"id"',
    ['"u"']='"status"',
    ['"k"']='"skill"',
    ['"w"']='"switch"',
    ['"x"']='"comb"',

    ['"N"']='"normal"',
    ['"C"']='"critical"',
    ['"S"']='"skillid"',
    ['"M"']='"damage2"',
    ['"E"']='"effect"',
    ['"W"']='"weaken"',
    ['"U"']='"num"',

    ['"R"']='"attr"',
    ['"B"']='"buffer"',
    ['"A"']='"atk"',
    ['"D"']='"def"',

    ['"f"']='"forbear"',
}

function ReplaceAbbToKey(report)
    for k,v in pairs(BATTLEREPORT_ABB_TO_KEY) do
        report = string.gsub(report, k, v)
    end
    return report
end