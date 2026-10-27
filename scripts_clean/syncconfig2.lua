--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-4-28
-- Time: 下午6:20
-- To change this template use File | Settings | File Templates.
--

require("pack")
require("sqlite3init")
require("localfile")
require("gamedata")
require("myjson")
require"GameDownloadProxy"
local sectionconfig_pb = require("sectionconfig_pb")
function SQLite3ConfigVersion(section)
    local configs = {}
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "SELECT  SECTION, TYPE, VersionNum FROM ConfigInfo where SECTION = "..section
    for row in mydb:rows(SQL) do
        table.insert(configs, {section = row[1], type = row[2], VersionNum = row[3] })
    end
    mydb:close()
    return configs
end


function SQLite3UpdateConfigVersion(section, mytype, version)
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "UPDATE ConfigInfo set VersionNum=" .. version .. " where SECTION = "..section.." and TYPE='" .. mytype .. "'";
    mydb:exec(SQL)
    if mydb:changes() == 0 then
        --print("Insert start......")
        SQL = string.format("INSERT INTO ConfigInfo (SECTION,TYPE,VersionNum) VALUES (%d,'%s',%d)", section,mytype, version)
        ---log(string.format("SQL:%s", SQL));
        mydb:exec(SQL)
        --print("insert end......")
    end
    --log(string.format("sqlite err in syncconfig: %s", mydb:errmsg()));
    mydb:close()
end

local isSyncConfig = true --判断是否同步
local file = require"FileOperation"

local UINeedLoadConfig = {
    general=true,
    skill=true,
    equip=true,
    suit=true,
    girl=true,
    skill=true,
    combskill = true,
    skill_qualityexp=true,
    skill_level=true,

    godstone = true,
    godstonestrengthening = true,

    general_awake=true,
    props=true,
    props2=true,
    equip_refine_expend=true,
    equip_refine=true,
    equip_strengthen=true,
    guide_section=true,
    guide_step=true,

    notice_2=true,
    notice_3=true,
    login_rewards=true,
    treasure=true,
    wish=true,
    startgift=true,
    general_fragment=true,
    equip_fragment=true,
    task=true,
    build=true,
    copy_talk=true,
    vip=true,


    soul=true,
    soul_exchange=true,
    soul_hunt=true,
    soul_slot_open=true,
    soulslot = true,
    map = true,
    copy = true,
    copy_dialog = true,
    brave_map = true,
    brave_copy = true,
    vip = true,
    recharge = true,
    growplan = true,
    first_recharge = true,
    monthcardgift = true,
    toplevel = true,
    generalanimation = true,
    copy_monster = true,
    skillanimation = true,
    invite = true,

    section = true,
    general_exp = true,

    athletics_rewards = true,
    athletics_rewards2 = true,
    athletics_rewards3 = true,

    gift_bag = true,
    shop = true,

    treasure_fragment = true,
    treasure_refine = true,
    treasure_strengthen = true,

    encounter = true,
    role_exp = true,
    expedition_map = true,
    expedition = true,
    expedition2 = true,

    general_exchange = true,

    zongzi_reward = true, -- 扔粽子

    limit_time_exchange = true, -- 限时兑换表
    limit_time_exchangetime = true, -- 限时兑换自动刷新时间

    dragonBoatRace_guessReward = true, -- 赛龙舟
    hoshimiya_break = true, -- 星宫冲破表
    hoshimiya_jihuo = true, -- 星宫激活

    tiantingyz_guanqia = true, -- 天庭银座关卡表
    tiantingyz_diaoluo = true, -- 天庭银座掉落表
    tiantingyz_duihua = true, -- 天庭银座对话表
    tiantingyz_sjoutput = true, -- 天庭银座事件产出表
    tiantingyz_sjtype = true, -- 天庭银座事件类型表
    tiantingyz_time = true, -- 天庭银座消费时间表
    tiantingyz_zhanbao = true, -- 天庭银座战报表

    activity_time = true,
    cup_reward = true,


    gang2_incense = true,
    gang2_fishpond = true,
    gang2_fishpondexp = true,
    gang2_bait = true,
    gang2_skill_open = true,
    gang2_skill_level = true,
    
    mammon = true,
    mammon1 = true,


    sign2_202401 = true,
    sign2_202402 = true,
    sign2_202403 = true,
    sign2_202404 = true,
    sign2_202405 = true,
    sign2_202406 = true,
    sign2_202407 = true,
    sign2_202408 = true,
    sign2_202409 = true,
    sign2_202410 = true,
    sign2_202411 = true,
    sign2_202412 = true,
    sign2_202501 = true,
    sign2_202502 = true,
    sign2_202503 = true,
    sign2_202504 = true,
    sign2_202505 = true,
    sign2_202506 = true,
    sign2_202507 = true,
    sign2_202508 = true,
    sign2_202509 = true,
    sign2_202510 = true,
    sign2_202511 = true,
    sign2_202512 = true,

    sign2_202201 = true,
    sign2_202202 = true,
    sign2_202203 = true,
    sign2_202204 = true,
    sign2_202205 = true,
    sign2_202206 = true,
    sign2_202207 = true,
    sign2_202208 = true,
    sign2_202209 = true,
    sign2_202210 = true,
    sign2_202211 = true,
    sign2_202212 = true,
    sign2_202301 = true,
    sign2_202302 = true,
    sign2_202303 = true,
    sign2_202304 = true,
    sign2_202305 = true,
    sign2_202306 = true,
    sign2_202307 = true,
    sign2_202308 = true,
    sign2_202309 = true,
    sign2_202310 = true,
    sign2_202311 = true,
    sign2_202312 = true,

    task = true,

    penglai2_type = true,
    penglai2_monster = true,
    penglai2_next = true,
    penglai2_task = true,
    penglai2_rankrewards = true,
    penglai2_dailyrewards = true,
    penglai2_map = true,
    penglai2_globalpoint = true,
    penglai2_map0 = true,
    penglai2_map1 = true,
    penglai2_map2 = true,

    liveness = true,
    liveness_reward = true,

    -- boss2_rewards = true,
    boss2_rewards1 = true,
    boss2_rewards2 = true,
    boss2 = true,

    storyconfig = true,
    daily = true,

    online_reward = true,
    continue7 = true,

    daydaygift_item = true,

    protagonist_grow = true,
    passive_skill = true,

    consumegift_item = true,
    consumegift_reward = true,
    recruit = true,
    loot = true,

    begin7day_task = true,
    begin7day = true,

    pet2_attr = true,

    limittime_shop = true,
    blackmarket_items = true,
    blackmarket_refresh = true,
    battle_result = true,
    mystery_shop = true,

    customer_service = true,
    buycount_price = true,
    drop = true,
    recharge_gift = true,
    exchange_sys = true,

    watchstar_starextra = true,
    watchstar_reward = true,
    watchstar_change = true,
    watchstar_position = true,

    mieshendian_monster_param = true,
    mieshendian_attr = true,
    mieshendian_reward = true,

    breakskill = true,

    pet2_attr = true,
    pet2_fragment = true,
    pet2_expup = true,
    pet2_exp = true,

    recruit_basic = true,

    global_kv = true,

    gang2_shop = true,
    gang2_level = true,

    expedition_rank_reward = true,

    cup_bet_consume = true,
    growplan_global = true,

    renascence = true,
    
    favorable = true,
    
    favorable_level = true,
    favorable_task = true,

    rob_shop = true,

    treasure2_fragment = true,
    treasure2_refine = true,
    treasure2_strengthen = true,

    pet3_attr = true,
    pet3_fragment = true,
    pet3_passiveskill = true,
    pet3_talentskill = true,
    pet3_skillpoints = true,

    penglai3_map = true,
    penglai3_type = true,
    penglai3_card = true,

    mieshendian_condition = true,
    mieshendian_type = true,
    gang2_cityaward = true,

    personalboss_att = true,
    personalboss_date = true,


    daily_function = true,
    exp_copy = true,
    coin_copy = true,
    stone_copy = true,
    month_growup = true,
    month_welfare = true,
    loading = true,

    sigil = true,
    sigilposition = true,
    kingofmofu_lv = true,

    equip_evolvesuffix = true,
    equip_evolve = true,
    equip_evolveconsume = true,
    equip_evolvelv = true,

    equip_star = true,
    

    cheer = true,
    star_map = true,
    artifact = true,
    star_copy = true,
    maze_shop = true,
    treasure_discount = true,
    maze_type = true,
    maze_task = true,

    firstpay = true,
    mieshendian_shop = true,
    mieshendian_award = true,
    shop_price = true,
    team_recommend = true,
    shake_param = true,
    double_output = true,
    general_awaken = true,
    champion_produce = true,
    champion_goods = true,
    champion_refresh = true,

    through_param = true,
    through_rewards = true,
    through_shop = true,

    dragonBoatCarnival_lottery = true,
    dragonBoatCarnival_exchange = true,
    
    daydaygift_item_x1 = true,
    treasure_discount_x1 = true,
    treasure_discount_x2 = true,
    treasure_discount_x3 = true,

    gang2_battleTime = true,

    enlist = true,
    laosiji = true,

    wudao_reward = true,
    wudao_time = true,
    wudao_lottery = true,
    wudao_part = true,

    fashioncoat = true,
    fashionintentify = true,
    fashion_gift_bag = true,

    new_generals_lottery = true,
    new_generals_exchange = true,
    
    goddown_exchange = true,
    goddown_rank = true,

    lingzhentu_cond = true,
    lingzhentu_lv = true,
    lingzhentu_add = true,
    lingzhentu_jihuo = true,
    lingzhentu_zhenfa = true,

    goddown_contribution_reward = true,
    goddown_shangxiang = true,

    activity_huodong = true,

    drop_special = true,

    gang2battle_youhua_type = true,

    mozhao_break = true,
    mozhao_liandan = true,

    mozhao_shoptype = true,
    mozhao_shop = true,

    activity_q_exchange = true,

    upstar_huodong = true,
    zhenfu_huodong = true,

    huodong_monster = true,

    wing_coler = true,
    wing_stage = true,
    wing_uplv = true,

    
    mid_autumn_exchange = true,
    single_gift = true,

    cross_battle_interval = true,
    cross_battle_rankreward = true,
    cross_battle_lvbet = true,
    cross_battle_time = true,

    recruit_tenlottery = true,
    time_achievement = true,

    national_task = true,
    national_7day = true,

    vip_welfare = true,

    player_back_call = true,
    player_back_task = true,

    redl_awake_item = true,
    online_gift = true,

    week_month_gift = true,

    watchstar_lv_reward = true,

    trigger_gift = true,

    pet3_illustrated = true,

    soul_integrate = true,
    soul_integrate_lv = true,

    goddown_event = true,

    turntable = true,

    carnival_lottery = true,
    carnival_price = true,

    auction_items = true,
    auction_pos = true,

    points_canival_item = true,

    home_building = true,
    home_building_attr = true,
    home_monster = true,
    home_store = true,
    home_task = true,

    continuous_recharge = true,
    prize = true,

    gang2_boss = true,
    gang2_boss_reward = true,

    worlddrop = true,

    rebate = true,

    span_goddown_exchange = true,
    span_goddown_rank = true,
    span_goddown_contribution_reward = true,
    span_goddown_shangxiang = true,
    span_goddown_event = true,

    span_turntable = true,

    new_accelerate_task = true,
    new_accelerate = true,
    new_accelerate_task_2 = true,
    new_accelerate_2 = true,

    watchstar_fix = true,

    vip_weekgift = true,

    copy_time = true,

    game_consoles_reward = true,
    game_consoles_shop = true,

    shenlong_map = true,
    shenlong_map2 = true,
    shenlong_praram = true,
    shenlong_random = true,
    shenlong_random2 = true,
    shenlong_type = true,
    shenlong_discount = true,
    shenlong_reward = true,
    zodiac_new = true,

    mozhao_evolve = true,

    vip_kefu = true,
    gambling = true,

    heroboss = true,

    --cp
    daydaygift_item_1 = true,
    daydaygift_item_2 = true,
    daydaygift_item_3 = true,
    daydaygift_item_4 = true,
    daydaygift_item_5 = true,
    daydaygift_item_6 = true,
    daydaygift_item_7 = true,
    daydaygift_item_8 = true,
    daydaygift_item_9 = true,
    daydaygift_item_10 = true,
    daydaygift_item_11 = true,
    daydaygift_item_12 = true,
    goddown_contribution_reward_1 = true,
    goddown_contribution_reward_2 = true,
    goddown_contribution_reward_3 = true,
    goddown_contribution_reward_4 = true,
    goddown_contribution_reward_5 = true,
    goddown_contribution_reward_6 = true,
    goddown_contribution_reward_7 = true,
    goddown_contribution_reward_8 = true,
    goddown_contribution_reward_9 = true,
    goddown_contribution_reward_10 = true,
    goddown_contribution_reward_11 = true,
    goddown_contribution_reward_12 = true,
    goddown_exchange_1 = true,
    goddown_exchange_2 = true,
    goddown_exchange_3 = true,
    goddown_exchange_4 = true,
    goddown_exchange_5 = true,
    goddown_exchange_6 = true,
    goddown_exchange_7 = true,
    goddown_exchange_8 = true,
    goddown_exchange_9 = true,
    goddown_exchange_10 = true,
    goddown_exchange_11 = true,
    goddown_exchange_12 = true,
    goddown_rank_1 = true,
    goddown_rank_2 = true,
    goddown_rank_3 = true,
    goddown_rank_4 = true,
    goddown_rank_5 = true,
    goddown_rank_6 = true,
    goddown_rank_7 = true,
    goddown_rank_8 = true,
    goddown_rank_9 = true,
    goddown_rank_10 = true,
    goddown_rank_11 = true,
    goddown_rank_12 = true,
    laosiji_1 = true,
    laosiji_2 = true,
    laosiji_3 = true,
    laosiji_4 = true,
    laosiji_5 = true,
    laosiji_6 = true,
    laosiji_7 = true,
    laosiji_8 = true,
    laosiji_9 = true,
    laosiji_10 = true,
    laosiji_11 = true,
    laosiji_12 = true,
    new_generals_exchange_1 = true,
    new_generals_exchange_2 = true,
    new_generals_exchange_3 = true,
    new_generals_exchange_4 = true,
    new_generals_exchange_5 = true,
    new_generals_exchange_6 = true,
    new_generals_exchange_7 = true,
    new_generals_exchange_8 = true,
    new_generals_exchange_9 = true,
    new_generals_exchange_10 = true,
    new_generals_exchange_11 = true,
    new_generals_exchange_12 = true,
    new_generals_lottery_1 = true,
    new_generals_lottery_2 = true,
    new_generals_lottery_3 = true,
    new_generals_lottery_4 = true,
    new_generals_lottery_5 = true,
    new_generals_lottery_6 = true,
    new_generals_lottery_7 = true,
    new_generals_lottery_8 = true,
    new_generals_lottery_9 = true,
    new_generals_lottery_10 = true,
    new_generals_lottery_11 = true,
    new_generals_lottery_12 = true,
    new_generals_weights_1 = true,
    new_generals_weights_2 = true,
    new_generals_weights_3 = true,
    new_generals_weights_4 = true,
    new_generals_weights_5 = true,
    new_generals_weights_6 = true,
    new_generals_weights_7 = true,
    new_generals_weights_8 = true,
    new_generals_weights_9 = true,
    new_generals_weights_10 = true,
    new_generals_weights_11 = true,
    new_generals_weights_12 = true,
    recharge_gift_1 = true,
    recharge_gift_2 = true,
    recharge_gift_3 = true,
    recharge_gift_4 = true,
    recharge_gift_5 = true,
    recharge_gift_6 = true,
    recharge_gift_7 = true,
    recharge_gift_8 = true,
    recharge_gift_9 = true,
    recharge_gift_10 = true,
    recharge_gift_11 = true,
    recharge_gift_12 = true,
    time_achievement_1 = true,
    time_achievement_2 = true,
    time_achievement_3 = true,
    time_achievement_4 = true,
    time_achievement_5 = true,
    time_achievement_6 = true,
    time_achievement_7 = true,
    time_achievement_8 = true,
    time_achievement_9 = true,
    time_achievement_10 = true,
    time_achievement_11 = true,
    time_achievement_12 = true,
    treasure_discount_1 = true,
    treasure_discount_2 = true,
    treasure_discount_3 = true,
    treasure_discount_4 = true,
    treasure_discount_5 = true,
    treasure_discount_6 = true,
    treasure_discount_7 = true,
    treasure_discount_8 = true,
    treasure_discount_9 = true,
    treasure_discount_10 = true,
    treasure_discount_11 = true,
    treasure_discount_12 = true,
    consumegift_reward_1 = true,
    consumegift_reward_2 = true,
    consumegift_reward_3 = true,
    consumegift_reward_4 = true,
    consumegift_reward_5 = true,
    consumegift_reward_6 = true,
    consumegift_reward_7 = true,
    consumegift_reward_8 = true,
    consumegift_reward_9 = true,
    consumegift_reward_10 = true,
    consumegift_reward_11 = true,
    consumegift_reward_12 = true,
    continue7_1 = true,
    continue7_2 = true,
    continue7_3 = true,
    continue7_4 = true,
    continue7_5 = true,
    continue7_6 = true,
    continue7_7 = true,
    continue7_8 = true,
    continue7_9 = true,
    continue7_10 = true,
    continue7_11 = true,
    continue7_12 = true,
    continue7_X1 = true,
    limittime_shop_1 = true,
    limittime_shop_2 = true,
    limittime_shop_3 = true,
    limittime_shop_4 = true,
    limittime_shop_5 = true,
    limittime_shop_6 = true,
    limittime_shop_7 = true,
    limittime_shop_8 = true,
    limittime_shop_9 = true,
    limittime_shop_10 = true,
    limittime_shop_11 = true,
    limittime_shop_12 = true,
    rebate_1 = true,
    rebate_2 = true,
    rebate_3 = true,
    rebate_4 = true,
    rebate_5 = true,
    rebate_6 = true,
    rebate_7 = true,
    rebate_8 = true,
    rebate_9 = true,
    rebate_10 = true,
    rebate_11 = true,
    rebate_12 = true,
    turntable_1 = true,
    turntable_2 = true,
    turntable_3 = true,
    turntable_4 = true,
    turntable_5 = true,
    turntable_6 = true,
    turntable_7 = true,
    turntable_8 = true,
    turntable_9 = true,
    turntable_10 = true,
    turntable_11 = true,
    turntable_12 = true,
    guild_play = true,
    system_intro = true,
    guild_integral = true,
    guild_box_total = true,
    guild_box = true,

    new_accelerate_rota_1 = true,
    new_accelerate_rota_2 = true,
    new_accelerate_rota_3 = true,
    new_accelerate_rota_4 = true,
    new_accelerate_rota_5 = true,
    new_accelerate_rota_6 = true,
    new_accelerate_rota_7 = true,
    new_accelerate_rota_8 = true,
    new_accelerate_rota_9 = true,
    new_accelerate_rota_10 = true,
    new_accelerate_rota_11 = true,
    new_accelerate_rota_12 = true,
    new_accelerate_rota_101 = true,
    new_accelerate_rota_102 = true,
    new_accelerate_rota_103 = true,
    new_accelerate_rota_104 = true,
    new_accelerate_rota_105 = true,
    new_accelerate_task_rota_1 = true,
    new_accelerate_task_rota_2 = true,
    new_accelerate_task_rota_3 = true,
    new_accelerate_task_rota_4 = true,
    new_accelerate_task_rota_5 = true,
    new_accelerate_task_rota_6 = true,
    new_accelerate_task_rota_7 = true,
    new_accelerate_task_rota_8 = true,
    new_accelerate_task_rota_9 = true,
    new_accelerate_task_rota_10 = true,
    new_accelerate_task_rota_11 = true,
    new_accelerate_task_rota_12 = true,
    new_accelerate_task_rota_101 = true,
    new_accelerate_task_rota_102 = true,
    new_accelerate_task_rota_103 = true,
    new_accelerate_task_rota_104 = true,
    new_accelerate_task_rota_105 = true,
    single_gift_1 = true,
    single_gift_2 = true,
    single_gift_3 = true,
    single_gift_4 = true,
    single_gift_5 = true,
    single_gift_6 = true,
    single_gift_7 = true,
    single_gift_8 = true,
    single_gift_9 = true,
    single_gift_10 = true,
    single_gift_11 = true,
    single_gift_12 = true,
    limit_time_exchange_1 = true,
    limit_time_exchange_2 = true,
    limit_time_exchange_3 = true,
    limit_time_exchange_4 = true,
    limit_time_exchange_5 = true,
    limit_time_exchange_6 = true,
    limit_time_exchange_7 = true,
    limit_time_exchange_8 = true,
    limit_time_exchange_9 = true,
    limit_time_exchange_10 = true,
    limit_time_exchange_11 = true,
    limit_time_exchange_12 = true,
    continuous_recharge_1 = true,
    continuous_recharge_2 = true,
    continuous_recharge_3 = true,
    continuous_recharge_4 = true,
    continuous_recharge_5 = true,
    continuous_recharge_6 = true,
    continuous_recharge_7 = true,
    continuous_recharge_8 = true,
    continuous_recharge_9 = true,
    continuous_recharge_10 = true,
    continuous_recharge_11 = true,
    continuous_recharge_12 = true,
    prize_1 = true,
    prize_2 = true,
    prize_3 = true,
    prize_4 = true,
    prize_5 = true,
    prize_6 = true,
    prize_7 = true,
    prize_8 = true,
    prize_9 = true,
    prize_10 = true,
    prize_11 = true,
    prize_12 = true,
    points_canival_item_1 = true,
    points_canival_item_2 = true,
    points_canival_item_3 = true,
    points_canival_item_4 = true,
    points_canival_item_5 = true,
    points_canival_item_6 = true,
    points_canival_item_7 = true,
    points_canival_item_8 = true,
    points_canival_item_9 = true,
    points_canival_item_10 = true,
    points_canival_item_11 = true,
    points_canival_item_12 = true,

    Anniversary_task = true,
    Anniversary_weights = true,
    Anniversary_reward = true,
    Anniversary_double = true,
    peak_time = true,
    -- 道馆配置
    daoguan_param = true,
    daoguan_monster = true,
    daoguan_time = true,

    value_feedback = true,
    value_feedback_package = true,
    lifelong_recharge = true,

    enlist_shop = true,

    zhongshu_awards = true,
    zhongshu_list = true,
    zhongshu_reward = true,
    zhongshu_task = true,
    zhongshu_weights = true,
    gambling_gold = true,
    gambling_items = true,
    peentogiftawards = true,
    peentogift_silver = true,
    
    shenqi = true,
    shenqi_evolve = true,
    combat_rank = true,
    sigil_rank = true,
    combat_grow = true,
    trump_gem = true,
    trump = true,
    trump_autweight = true,
    trump_skillRnd = true,

    national_task_x1 = true,
    national_7day_x1 = true,

    trigger_gift2 = true,
    week_double = true,
    weekcardgift = true,

    antique_item = true,
    antique_appraisal = true,
    antique_npc_animation = true,
    antique_npc = true,
    
    continuous_recharge_x1 = true,
    prize_x1 = true,
    
    guild_time = true,
    guild_rank = true,
    
    explain = true,

    king_config = true,
    king_time = true,
    king_paragraph = true,
    Immortal_level = true,
    Immortal_type = true,
    equip_forgingConsume = true,
    king_reward = true,
    king_rewards2 = true,
    king_buff = true,
    glory_battle_odds = true,
    glory_battle_lvbet = true,
    glory_battle_interval = true,
    glory_battle_rankreward = true,
    glory_battle_exchange = true,
    glory_battle_time = true,

    month_welfare_x1 = true,
    month_growup_x1 = true,
    combat_grow_x1 = true,
    combat_grow_x2 = true,
    forging_copy = true,

    new_accelerate_task_3 = true,
    new_accelerate_3 = true,
    new_accelerate_task_4 = true,
    new_accelerate_4 = true,

    month_welfare_x2 = true,
    month_growup_x2 = true,

    suit_gift = true,
    suit_line = true,
    suit_line_files = true,
    suit_sign = true,

    week_gift = true,

    hell_difficulty = true,
    hell_monsterBuff = true,
    hell_playerBuff = true,
    monster = true,

    cross_trump_rank = true,
    trump_rank = true,
    trump_numskill = true,

    Title = true,
    Headframe = true,

    title = true,
    headframe = true,


    transaction_search = true,
    transaction_sell = true,
    transaction_itemType = true,
    transaction_method = true,
    
    festival_day_task = true,
    festival_day = true,

    

    wing_rank = true,

    copy_rank = true, 
    mozhao_rank = true,
    friend_rank = true,
    soul_rank = true,
    artifact_rank = true,
    localTrump_rank = true,

    openlevel_rank_achievement = true,
    artifact_rank_achievement = true,
    wing_rank_achievement = true,
    copy_rank_achievement = true,
    mozhao_rank_achievement = true,
    friend_rank_achievement = true,
    combat_grow_achievement = true,
    sigil_rank_achievement = true,
    combat_grow_achievement1 = true,
    combat_grow_achievement2 = true,
    soul_rank_achievement = true,
    artifact_rank_achievement = true,
    trump_rank_achievement = true,
    portable_store = true,
    -- 注灵道具表
    equip_foringlv = true,

    single_gift_X1 = true,
    single_gift_X1_1 = true,
    single_gift_X1_2 = true,
    single_gift_X1_3 = true,
    single_gift_X1_4 = true,
    single_gift_X1_5 = true,
    single_gift_X1_6 = true,
    single_gift_X1_7 = true,
    single_gift_X1_8 = true,
    single_gift_X1_9 = true,
    single_gift_X1_10 = true,
    single_gift_X1_11 = true,
    single_gift_X1_12 = true,
    -- 神器强化
    trump_strengthen = true,
    -- 金光神器强化
    trump_Godstrengthen = true,
    -- 神器重铸
    trump_compose_cost = true,
    -- 神器开孔
    trump_washing_skill = true,
    -- 神器全局表
    trump_config = true,
    pet3_devour = true,
    pet3_integral = true,
    pet3_numexp = true,

    hades_map = true,
    hades_copy = true,
    -- 家园商店材料
    home_store_material = true,

    essence_shop = true,

    Christmas_awards = true,
    Christmas_reward = true,
    Christmasgift_reward = true,
    holiday_time = true,
    time_buy = true,

    essence_shop_config = true,
    --工会鼓舞
    gang2_boss_encouraging = true,

    cross_chat_config = true,

    partner_fashion = true,
    partner_fashion_shop = true,

    guessing_riddles = true,

    soul_thousand = true,
    --共鸣属性
    resonance_attribute = true,
    --神器重生消耗
    trump_rebirth = true,

    --飞升
    passive_soaring = true,
    partner_soaring = true,

    lord_again = true,

    jinjiangkezhiguanxi = true,

    tongtianta_dazhangjie = true,
    tongtianta_guaiwu = true,
    tongtianta_shangdian = true,
    tongtianta_tongguantiaojian = true,

    glory_battle_achievement = true,
    single_gift_X2 = true,
    mozhao_soaring = true,

    xianku_guaiwu = true,
    transformation_config = true,

    --法宝锻造 仙
    artifact_xian_config = true,
    artifact_baptize_xian = true,

    exchange_shop = true,

    --日常轮换 单充送礼
    single_gift_X2_rc_1 = true,
    single_gift_X2_rc_2 = true,
    single_gift_X2_rc_3 = true,
    single_gift_X2_rc_4 = true,
    single_gift_X2_rc_5 = true,
    single_gift_X2_rc_6 = true,
    single_gift_X2_rc_7 = true,
    single_gift_X2_rc_8 = true,

    --日常轮换 限时商店
    limittime_shop_rc_1 = true,
    limittime_shop_rc_2 = true,
    limittime_shop_rc_3 = true,
    limittime_shop_rc_4 = true,
    limittime_shop_rc_5 = true,
    limittime_shop_rc_6 = true,
    limittime_shop_rc_7 = true,
    limittime_shop_rc_8 = true,


    --日常轮换 火影时装
    activity_q_exchange_rc_1 = true,
    activity_q_exchange_rc_2 = true,
    activity_q_exchange_rc_3 = true,
    activity_q_exchange_rc_4 = true,
    activity_q_exchange_rc_5 = true,
    activity_q_exchange_rc_6 = true,
    activity_q_exchange_rc_7 = true,
    activity_q_exchange_rc_8 = true,
    
    --日常轮换 单充送礼
    single_gift_rc_1 = true,
    single_gift_rc_2 = true,
    single_gift_rc_3 = true,
    single_gift_rc_4 = true,
    single_gift_rc_5 = true,
    single_gift_rc_6 = true,
    single_gift_rc_7 = true,
    single_gift_rc_8 = true,

    --日常轮换 极品武将
    continuous_recharge_x1_rc_1 = true,
    continuous_recharge_x1_rc_2 = true,
    continuous_recharge_x1_rc_3 = true,
    continuous_recharge_x1_rc_4 = true,
    continuous_recharge_x1_rc_5 = true,
    continuous_recharge_x1_rc_6 = true,
    continuous_recharge_x1_rc_7 = true,
    continuous_recharge_x1_rc_8 = true,

    prize_x1_rc_1 = true,
    prize_x1_rc_2 = true,
    prize_x1_rc_3 = true,
    prize_x1_rc_4 = true,
    prize_x1_rc_5 = true,
    prize_x1_rc_6 = true,
    prize_x1_rc_7 = true,
    prize_x1_rc_8 = true,

    --日常轮换 连续充值
    continuous_recharge_rc_1 = true,
    continuous_recharge_rc_2 = true,
    continuous_recharge_rc_3 = true,
    continuous_recharge_rc_4 = true,
    continuous_recharge_rc_5 = true,
    continuous_recharge_rc_6 = true,
    continuous_recharge_rc_7 = true,
    continuous_recharge_rc_8 = true,

    prize_rc_1 = true,
    prize_rc_2 = true,
    prize_rc_3 = true,
    prize_rc_4 = true,
    prize_rc_5 = true,
    prize_rc_6 = true,
    prize_rc_7 = true,
    prize_rc_8 = true,

    --日常轮换 限时成就
    time_achievement_rc_1 = true,
    time_achievement_rc_2 = true,
    time_achievement_rc_3 = true,
    time_achievement_rc_4 = true,
    time_achievement_rc_5 = true,
    time_achievement_rc_6 = true,
    time_achievement_rc_7 = true,
    time_achievement_rc_8 = true,
    
    --日常轮换 跨服转盘
    span_turntable_rc_1 = true,
    span_turntable_rc_2 = true,
    span_turntable_rc_3 = true,
    span_turntable_rc_4 = true,
    span_turntable_rc_5 = true,
    span_turntable_rc_6 = true,
    span_turntable_rc_7 = true,
    span_turntable_rc_8 = true,

    --日常轮换 嘉年华
    turntable_rc_1 = true,
    turntable_rc_2 = true,
    turntable_rc_3 = true,
    turntable_rc_4 = true,
    turntable_rc_5 = true,
    turntable_rc_6 = true,
    turntable_rc_7 = true,
    turntable_rc_8 = true,


    --日常轮换 宫心计
    laosiji_rc_1 = true,
    laosiji_rc_2 = true,
    laosiji_rc_3 = true,
    laosiji_rc_4 = true,
    laosiji_rc_5 = true,
    laosiji_rc_6 = true,
    laosiji_rc_7 = true,
    laosiji_rc_8 = true,

    --日常轮换 消费有礼
    consumegift_reward_rc_1 = true,
    consumegift_reward_rc_2 = true,
    consumegift_reward_rc_3 = true,
    consumegift_reward_rc_4 = true,
    consumegift_reward_rc_5 = true,
    consumegift_reward_rc_6 = true,
    consumegift_reward_rc_7 = true,
    consumegift_reward_rc_8 = true,


    --日常轮换 天天好礼
    daydaygift_item_rc_1 = true,
    daydaygift_item_rc_2 = true,
    daydaygift_item_rc_3 = true,
    daydaygift_item_rc_4 = true,
    daydaygift_item_rc_5 = true,
    daydaygift_item_rc_6 = true,
    daydaygift_item_rc_7 = true,
    daydaygift_item_rc_8 = true,

    --日常轮换 累计充值
    recharge_gift_rc_1 = true,
    recharge_gift_rc_2 = true,
    recharge_gift_rc_3 = true,
    recharge_gift_rc_4 = true,
    recharge_gift_rc_5 = true,
    recharge_gift_rc_6 = true,
    recharge_gift_rc_7 = true,
    recharge_gift_rc_8 = true,
    
    --日常轮换 积分嘉年华
    points_canival_item_rc_1 = true,
    points_canival_item_rc_2 = true,
    points_canival_item_rc_3 = true,
    points_canival_item_rc_4 = true,
    points_canival_item_rc_5 = true,
    points_canival_item_rc_6 = true,
    points_canival_item_rc_7 = true,
    points_canival_item_rc_8 = true,


    --日常轮换 珍品折扣
    treasure_discount_rc_1 = true,
    treasure_discount_rc_2 = true,
    treasure_discount_rc_3 = true,
    treasure_discount_rc_4 = true,
    treasure_discount_rc_5 = true,
    treasure_discount_rc_6 = true,
    treasure_discount_rc_7 = true,
    treasure_discount_rc_8 = true,
    

    --日常轮换 关公
    new_generals_exchange_rc_1 = true,
    new_generals_exchange_rc_2 = true,
    new_generals_exchange_rc_3 = true,
    new_generals_exchange_rc_4 = true,
    new_generals_exchange_rc_5 = true,
    new_generals_exchange_rc_6 = true,
    new_generals_exchange_rc_7 = true,
    new_generals_exchange_rc_8 = true,


    new_generals_lottery_rc_1 = true,
    new_generals_lottery_rc_2 = true,
    new_generals_lottery_rc_3 = true,
    new_generals_lottery_rc_4 = true,
    new_generals_lottery_rc_5 = true,
    new_generals_lottery_rc_6 = true,
    new_generals_lottery_rc_7 = true,
    new_generals_lottery_rc_8 = true,


    goddown_contribution_reward_rc_1 = true,
    goddown_contribution_reward_rc_2 = true,
    goddown_contribution_reward_rc_3 = true,
    goddown_contribution_reward_rc_4 = true,
    goddown_contribution_reward_rc_5 = true,
    goddown_contribution_reward_rc_6 = true,
    goddown_contribution_reward_rc_7 = true,
    goddown_contribution_reward_rc_8 = true,

    goddown_exchange_rc_1 = true,
    goddown_exchange_rc_2 = true,
    goddown_exchange_rc_3 = true,
    goddown_exchange_rc_4 = true,
    goddown_exchange_rc_5 = true,
    goddown_exchange_rc_6 = true,
    goddown_exchange_rc_7 = true,
    goddown_exchange_rc_8 = true,

    goddown_rank_rc_1 = true,
    goddown_rank_rc_2 = true,
    goddown_rank_rc_3 = true,
    goddown_rank_rc_4 = true,
    goddown_rank_rc_5 = true,
    goddown_rank_rc_6 = true,
    goddown_rank_rc_7 = true,
    goddown_rank_rc_8 = true,

    span_goddown_contribution_reward_rc_1 = true,
    span_goddown_contribution_reward_rc_2 = true,
    span_goddown_contribution_reward_rc_3 = true,
    span_goddown_contribution_reward_rc_4 = true,
    span_goddown_contribution_reward_rc_5 = true,
    span_goddown_contribution_reward_rc_6 = true,
    span_goddown_contribution_reward_rc_7 = true,
    span_goddown_contribution_reward_rc_8 = true,

    span_goddown_exchange_rc_1 = true,
    span_goddown_exchange_rc_2 = true,
    span_goddown_exchange_rc_3 = true,
    span_goddown_exchange_rc_4 = true,
    span_goddown_exchange_rc_5 = true,
    span_goddown_exchange_rc_6 = true,
    span_goddown_exchange_rc_7 = true,
    span_goddown_exchange_rc_8 = true,

    span_goddown_rank_rc_1 = true,
    span_goddown_rank_rc_2 = true,
    span_goddown_rank_rc_3 = true,
    span_goddown_rank_rc_4 = true,
    span_goddown_rank_rc_5 = true,
    span_goddown_rank_rc_6 = true,
    span_goddown_rank_rc_7 = true,
    span_goddown_rank_rc_8 = true,

    --拍卖行

    auction_pos_rc_1 = true,
    auction_pos_rc_2 = true,
    auction_pos_rc_3 = true,
    auction_pos_rc_4 = true,
    auction_pos_rc_5 = true,
    auction_pos_rc_6 = true,
    auction_pos_rc_7 = true,
    auction_pos_rc_8 = true,


    xiandou_shop = true,


    sanjie_answer = true,
    sanjie_reward = true,
    span_sanjie_reward = true,
    sanjie_subject_text = true,
    sanjie_subject_config = true,
    sanjie_answer_reward = true,


    --日常轮换缔造神话
    new_accelerate_1_rc_1 = true,
    new_accelerate_1_rc_2 = true,
    new_accelerate_1_rc_3 = true,
    new_accelerate_1_rc_4 = true,
    new_accelerate_task_1_rc_1 = true,
    new_accelerate_task_1_rc_2 = true,
    new_accelerate_task_1_rc_3 = true,
    new_accelerate_task_1_rc_4 = true,

    --日常轮换天下无双
    new_accelerate_2_rc_1 = true,
    new_accelerate_2_rc_2 = true,
    new_accelerate_2_rc_3 = true,
    new_accelerate_2_rc_4 = true,
    new_accelerate_task_2_rc_1 = true,
    new_accelerate_task_2_rc_2 = true,
    new_accelerate_task_2_rc_3 = true,
    new_accelerate_task_2_rc_4 = true,

    -- 神魂殿
    shenhundian_cuishen = true,
    shenhundian_cuishenxiaohao = true,
    shenhundian_lianhun = true,
    shenhundian_lianhunxiaohao = true,
    shenhundian_sanshengshi = true,

    hurt_icon = true,
    week_liveness_reward = true,
    --上古遗迹
    shanggu_stance = true,
    shanggu_reward = true,
    shanggu_monster = true,

    protagonist_awaken = true,
    
    growplan_global_x1 = true,
    growplan_x1 = true,
    xuanyue_reward = true,
    xuanyue2_reward = true,
    xuanyue3_reward = true,
    speedup_gift = true,
    speedup_gift_time_x1 = true,
    speedup_gift_time_x2 = true,
    speedup_gift_time_x3 = true,
    headframe = true,
    title = true,
    trump_transfer = true,
    rank_shop_1 = true,
    rank_shop_2 = true,
    rank_shop_3 = true,
    rank_shop_4 = true,
    rank_shop_5 = true,
    special_gift = true,
    special_gift_time_x1 = true,
    special_gift_time_x2 = true,
    special_gift_time_x3 = true,

    game_helper = true,
    watchstar_helper = true,

    gang2_feast_award = true,
    gang2_feast_bubble = true,
    gang2_feast_gain = true,
    gang2_feast_profit = true,
    gang2_feast_type = true,
    gang2_bath_award = true,
    gang2_bath_buff = true,
    gang2_bath_profit = true,
    gang2_bath_type = true,
    gang2_feast_npc = true,

    price_props = true,
    general_star = true,

    chengzhangplan_money = true,

    suit_shop = true,
    suit_present = true,
    suit_present_time = true,
    dew_pool_achievement = true,
    dew_pool_shop = true,
    dew_pool_task = true,

    week_growup = true,
    week_growup2 = true,
    week_growup_1 = true,
    week_growup_2 = true,
    week_growup_3 = true,
    week_growup_4 = true,
    week_growup_5 = true,

    week_growup_2_1 = true,
    week_growup_2_2 = true,
    week_growup_2_3 = true,
    week_growup_2_4 = true,
    week_growup_2_5 = true,

    week_growup_money = true,
    week_growup_money2 = true,
    week_growup_money_1 = true,
    week_growup_money_2_1 = true,

    week_growup_rc_1 = true,
    week_growup_rc_2 = true,
    week_growup_rc_3 = true,
    week_growup_rc_4 = true,
    
    week_growup_2_rc_1 = true,
    week_growup_2_rc_2 = true,
    week_growup_2_rc_3 = true,
    week_growup_2_rc_4 = true,

    week_growup_money_rc_1 = true,
    week_growup_money_2_rc_1 = true,

    general_awakenattr = true,
    --武将互换
    exchange_break_value = true,
    exchange_awaken_param = true,
    exchange_soaring_param = true,
    illusion = true,
    illusion_present = true,
    illusion_present_time_x1 = true,
    illusion_present_time_x2 = true,
    cross_battle_champion_time = true,
    cross_battle_champion_play = true,
    
    growplan_x2 = true,
    growplan_x3 = true,

    chengzhangplan_money_x2 = true,
    chengzhangplan_money_x3 = true,

    sculpture_dividend_challenge_task_1 = true,
    sculpture_dividend_daily_task_1 = true,
    sculpture_dividend_reward_1 = true,
    sculpture_dividend_shop_1 = true,

    sculpture_dividend_challenge_task_2 = true,
    sculpture_dividend_daily_task_2 = true,
    sculpture_dividend_reward_2 = true,
    sculpture_dividend_shop_2 = true,
    sculpture_dividend_recharge = true,
    
    hell_helper = true,--游戏助手通缉一键buff
    exclusive = true,--   专属神器
    exclusive_intensify = true,-- 专属神器强化
    exclusive_device_spirit = true,-- 专属神器器灵
    exclusive_device_spirit_intensify = true,--   专属神器器灵强化
    exclusive_device_spirit_suit = true,--    专属神器器灵套装
    exclusive_device_spirit_random_properties = true,--   专属神器器灵随机属性
    exclusive_device_spirit_random_pool = true,-- 专属神器器灵随机属性池
    exclusive_copy = true,--  专属副本
    exclusive_device_soul_copy = true,--  专属器魂副本
    exclusive_device_spirit_copy = true,--    专属器灵副本
    activity_probability = true,

    --跨服战boss
    apex_battle_interval = true, --战区划分
    apex_battle_lvbet = true, --等级押注
    apex_battle_npc = true, --预选赛NPC表
    apex_battle_odds = true, --押注系数
    apex_battle_rankreward = true, --排行奖励
    apex_battle_time = true, --PVP时间
    apex_boss_geren_rewards = true, --boss伤害阶段个人奖励
    apex_boss_benfu_rewards = true, --boss伤害阶段本服奖励
    apex_boss_kuafu_rewards = true, --boss伤害阶段跨服奖励
    apex_boss = true, --boss表
    apex_buff = true, --对决BUFF表

    channel_identification = true, --渠道标识

    mystery_rank = true, --大元宵排行奖励

    mid_autumn_exchange_1 = true,
    single_gift_x3 = true,
    
    exchange_2048 = true,
    task_2048 = true,

    --升仙台
    shengxian_interval = true, --进入等级
    shengxian_type = true,
    shengxian_map1 = true,
    shengxian_map2 = true,
    shengxian_map3 = true,
    shengxian_map4 = true,
    shengxian_map5 = true,
    shengxian_map6 = true,
    shengxian_map7 = true,
    shengxian_map8 = true,
    shengxian_map9 = true,
    shengxian_map10 = true,

    shengxian_shop = true,     --升仙商店
    shengxian_battle = true,   --战斗事件
    shengxian_buy = true,      --购买事件
    shengxian_buff = true,     --仙术事件
    shengxian_praram = true,   --仙遇事件
    shengxian_recover = true,  --回血复活事件
    shengxian_monster = true,  --升仙台怪物表

    treasure2_star = true,

}

local configs = {}
local configtotal = table.getTableLength(UINeedLoadConfig)
local index =0
function UILoadConfig(configtype,islast)
    if UINeedLoadConfig[configtype]  then
        --cclog("send to ui section:%d type:%s", gamedata.section, configtype)

        configs[#configs+1] = configtype
    end


    if LoadJsonFileToTableforNet then 

        if islast or #configs>=5 then
            --print("UILoadConfig totalnum",#configs)
            index = index + #configs

            local _index,_total = 0,0

            _index = index
            _total = configtotal

            -- if index<= 300 then 
            --     _index = index
            --     _total = 300
            -- else
            --     _index = index-300 
            --     _total = configtotal-300
            -- end
            uiqueue.setresponsetoui({type=500,configtype=configs, section=gamedata.section,rate = {type = "config", index = _index,total = _total}})
            configs = {}
        end  
    else

        if islast then --or #configs>=1 then
            index = index + #configs
            uiqueue.setresponsetoui({type=500,configtype=configs, section=gamedata.section,rate = {type = "config", index = index,total = configtotal}})
            configs = {}
        end
    end
end


local updateconfigtotal = 0
local uodateindex = 0
function UIupdateConfig(configtype)
    if UINeedLoadConfig[configtype]  then
        cclog("update send to ui section:%d type:%s", gamedata.section, configtype)
        uodateindex = uodateindex +1
        uiqueue.setresponsetoui({type=500,configtype={configtype}, section=gamedata.section,rate = {type = "updateconfig", index = uodateindex,total = updateconfigtotal}})
    end
end

function UISyncConfigCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2, "UISyncConfigCallBack")
    local configreq = sectionconfig_pb.SectionConfig()
    local section = gamedata.section
    configreq.section = section
    local configs = SQLite3ConfigVersion(section)
    local isSyncConfig = true
    local totalnum = table.getn(configs)
    index = 0

    print(totalnum,"totalnum")
    if totalnum ~= 0 then
        if totalnum >1200 then
            return 0,503,{type = 503, msgtype = "restartgame",msg = "本地文件损坏，为保证游戏体验请删除游戏并重新下载安装。"}
        end

        for k, v in ipairs(configs) do
            --			print("config version = ", v.VersionNum)
            local config = configreq.configs:add()
            config.ctype = v.type
            config.version = v.VersionNum;
        end
    end

    return 1, 2, configreq:SerializeToString()
end

function Netloadconfig()
    local configs = SQLite3ConfigVersion(gamedata.section)
    local totalnum = table.getn(configs)
    index = 0
    if totalnum ~= 0 then
        local loadconfigsucess = true
        for k, v in ipairs(configs) do
            if UINeedLoadConfig[v.type] then
                local filepath = "config/" .. gamedata.section .. "/"  .. v.type .. ".json"
                local fullpath = CCFileUtils:sharedFileUtils():fullPathForFilename(filepath)
                if LoadJsonFileToTableforNet then
                    gamedata.config[v.type] = LoadJsonFileToTableforNet(filepath)
                else
                    gamedata.config[v.type] = LoadJsonFileToTable(filepath)
                end

                if gamedata.config[v.type] == nil then
                    SQLite3UpdateConfigVersion(gamedata.section, v.type, 0)
                    if loadconfigsucess then
                        loadconfigsucess = false
                    end
                else
                    UILoadConfig(v.type)
                end
            end
        end

        UILoadConfig(" ",true)
        if not loadconfigsucess then
            return false
        end
    end

    return true
end

function UInetloadconfig()
    local loadconfigsucess = true
    for k,v in pairs(UINeedLoadConfig) do

        local filename = "config/" .. gamedata.section .. "/"  .. k .. ".json"
        local filepath = CCFileUtils:sharedFileUtils():fullPathForFilename(filename)

        if filepath == filename then
            print("no such config",k)
        else
            if LoadJsonFileToTableforNet then
                gamedata.config[k] = LoadJsonFileToTableforNet(filepath)
            else
                gamedata.config[k] = LoadJsonFileToTable(filepath)
            end
            if gamedata.config[k] == nil then
                print("UInetloadconfig k ----   ",k)
                if loadconfigsucess then
                    loadconfigsucess = false
                end
            else
                UILoadConfig(k)
            end
        end
    end
    UILoadConfig(" ",true)
    if loadconfigsucess then
        return 0, 4, {type = 4 }
    else
        return 0, 503, {type = 503, msgtype = "restartgame",msg = "配置文件损坏，请重启游戏更新配置文件。如问题仍存在请删除游戏并重新下载安装。"}
    end
end

function NetunzipFileCallBack(uireq)
    if uireq.zippath and uireq.writepath then
        CCDeviceModel:unzipfile(uireq.zippath,uireq.writepath,true) 
        print("NetunzipFileCallBack",uireq.writepath)
        UIReponse({type = 6666666, opt = uireq.opt})              
    end
    return UInetloadconfig()  
end

function NetSyncConfigCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from Net", 2, "NetSyncConfigCallBack")
    local configresponse = sectionconfig_pb.SectionConfig()
    configresponse:ParseFromString(fd.rbuf)
    local section = configresponse.section

    ConfigDownload.need = false
    ConfigDownload.dict = {}
    updateconfigtotal = #configresponse.configs

    print(totalnum,"totalnum2")
    

    for k, v in ipairs(configresponse.configs) do

        if not UINeedLoadConfig[v.ctype] then
        else
            ConfigDownload.need = true
            --            cclog("Step2SyncConfig id:%s type:%s version:%s length:%s", v.id, v.type, v.version, v.length);
            local url = v.url
            local lenofurls = #(v.urls)
            local url2,url3
            if lenofurls >= 1 then
                url2 = v.urls[1]
                if lenofurls >= 2 then
                    url3 = v.urls[2]
                end
            end
            local filepath = gWPath .. "config/" .. section .. "/"  .. v.ctype .. ".json"
            local filedir = getDirOfPath(filepath)
            cclog("mkdir %s", filedir);
            myfile.mkdir(getDirOfPath(filedir));
            myfile.mkdir(filedir);
            ConfigDownload.dict[url] = {section=section, url=url, file=filepath, version=v.version, type=v.ctype}
            UIReponse({ type = 20 , url=url, url2=url2, url3=url3, file=filepath, filename = v.ctype})
        end
    end

    if not ConfigDownload.need then
        if Netloadconfig() then
            return {type = 4 }
        else
            return {type = 503, msgtype = "restartgame",msg = "配置文件损坏，请重启游戏更新配置文件。如问题仍存在请删除游戏并重新下载安装。"}
        end
    end
end
