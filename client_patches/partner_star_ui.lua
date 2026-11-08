-- 升星成功回包：绑定伙伴成长页世代，忽略 seq0 推送与已切换的页面。
-- 原生 UIGeneralUpStar 的冗余 1001 查询已由打包脚本移除，服务端会推绝对 1001/1200/1012。
local star_native_up=UIGeneralUpStar
function UIGeneralUpStar(t)
    if t.partnerStarIgnored then return end
    if t.partnerStarView and not LocalPartnerGrowthPage(t.partnerStarView) then return end
    return star_native_up(t)
end
