--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-25
-- Time: 下午6:21
-- To change this template use File | Settings | File Templates.
--
local deviceApi = require"device"

local activity = {

    NavigationTableView = nil,

    retainresource  = {"activity/activity"},

    dailyCpActivityTimeStatus = {},

    activityPageconfig = {
        [3] = { request = 3615, icon = gameConfig.images.activityicon_shop,      module = require"Layer_activity_shop", resource = {} },
        [5] = { request = 2090, icon = gameConfig.images.activityicon_card,     module = require"Layer_activity_card", resource = {} ,needupdate = true},
        [6] = { request = 2097, icon = gameConfig.images.activityicon_double,   module = require"Layer_activity_double_new", resource = {},needupdate = true},
        [7] = { request = 2094, icon = gameConfig.images.activityicon_growplan, module = require"Layer_activity_growplan2", resource = {}},
        [8] = { request = 2092, icon = gameConfig.images.activityicon_cardgift, module = require"Layer_activity_cardgift_new", resource = {},needupdate = true},
        [9] = { request = 2080, icon = gameConfig.images.activityicon_invent, module = require"Layer_activity_invent", resource = {}},
        [10] = { request = 2062, icon = gameConfig.images.activityicon_fairycave,    module = require"Layer_activity_fairycave2",resource = {}},
        [11] = { request = 1001, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_newrank", resource = {}},
        [14] = { request = 2022, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_dailyreward", resource = {},needupdate = true},
        [15] = { request = 2020, icon = gameConfig.images.activityicon_consumereward,    module = require"Layer_activity_consumereward_new", resource = {},needupdate = true},
        [16] = { request = 2024, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_cumulativerecharge", resource = {},needupdate = true},
        [17] = { request = 2055, icon = gameConfig.images.activityicon_exchange,    module = require"Layer_activity_exchange", resource = {},needupdate = true},
        -- [18] = { request = 3630, icon = gameConfig.images.activityicon_blackshop,    module = require"Layer_activity_blackshop", resource = {}},
        [18] = { request = 3630, icon = gameConfig.images.activityicon_blackshop,    module = require"Layer_activity_blackshop_new", resource = {}},
        -- [20] = { request = 3650, icon = gameConfig.images.activityicon_secretshop,    module = require"Layer_activity_secretshop", resource = {}},
        [21] = { request = 3660, icon = gameConfig.images.activityicon_robshop,    module = require"Layer_activity_robshop", resource = {}},


        [22] = { request = 3682, icon = gameConfig.images.activityicon_welfareMonth,    module = require"Layer_activity_welfareMonth", resource = {}},
        [101] = { request = 3680, icon = gameConfig.images.activityicon_multipleRebate,    module = require"Layer_activity_multipleRebate", resource = {}},
        [23] = { request = 3690, icon = gameConfig.images.activityicon_share,    module = require"Layer_activity_share", resource = {}},
        [24] = { request = 4010, icon = gameConfig.images.activityicon_treasuresDiscount,    module = require"Layer_activity_treasuresDiscount", resource = {}},


        [1] = { request = 2010, icon = gameConfig.images.activityicon_peace,    module = require"Layer_activity_peace", resource = {}},
        [2] = { request = 2015, icon = gameConfig.images.activityicon_mammon,     module = require"Layer_activity_mammon", resource = {},needupdate = true},
        [4] = { request = 2060, icon = gameConfig.images.activityicon_signin,    module = require"Layer_activity_signin3", resource = {}},
        [12] = { request = 2035, icon = gameConfig.images.activityicon_cumulative,    module = require"Layer_activity_cumulative", resource = {}},
        [13] = { request = 212, icon = gameConfig.images.activityicon_continuous,    module = require"Layer_activity_continuous", resource = {}},
        [19] = { request = 3641, icon = gameConfig.images.activityicon_signin,    module = require"Layer_activity_signin3", resource = {}},
        
        [25] = { request = 3806, icon = gameConfig.images.activityicon_mazeshop,    module = require"Layer_activity_mazeshop", resource = {}},

        [29] = { request = 2031, icon = gameConfig.images.activityicon_cornucopia,    module = require"Layer_activity_cornucopia", resource = {}},

        -- [26] = { request = 1610, icon = gameConfig.images.activityicon_sportsshop,    module = require"Layer_sports_shop", resource = {}},
        -- [27] = { request = 2252, icon = gameConfig.images.activityicon_gangshop,    module = require"Layer_guild_shop2", resource = {}},
        -- [27] = { request = 1001, icon = gameConfig.images.activityicon_gangshop,    module = require"Layer_guild_shop2", resource = {}},
        [28] = { request = 3627, icon = gameConfig.images.activityicon_destroytempleshop,    module = require"Layer_destroyTempleShop2", resource = {}},

        [30] = { request = 1001, icon = gameConfig.images.activityicon_doubleoutput,    module = require"Layer_activity_double_output", resource = {}},

        [39] = { request = 3306, icon = gameConfig.images.activityicon_dumpling,    module = require"Layer_activity_dumpling", resource = {},needupdate = true},
        [40] = { request = 3901, icon = gameConfig.images.activityicon_dragonboat,    module = require"Layer_activity_dragonboat", resource = {}, zorder = -1,needupdate = true},
        
        -- [36] = { request = 2710, icon = gameConfig.images.activityicon_championshop,    module = require"Layer_activity_championshop", resource = {}},

        -- [37] = { request = 3822, icon = gameConfig.images.activityicon_passkillshop,    module = require"Layer_passkill_shop", resource = {}},
        
        [38] = { request = 3300, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_duanwu_lunpan", resource = {}},

        [35] = { request = 3310, icon = gameConfig.images.activityicon_dailyrewardX1,    module = require"Layer_activity_dailyreward_x1", resource = {},needupdate = true},
        [32] = { request = 4012, icon = gameConfig.images.activityicon_treasuresDiscountX1,    module = require"Layer_activity_treasuresDiscount_x1", resource = {}},
        [33] = { request = 4014, icon = gameConfig.images.activityicon_treasuresDiscountX2,    module = require"Layer_activity_treasuresDiscount_x2", resource = {}},
        [34] = { request = 4016, icon = gameConfig.images.activityicon_treasuresDiscountX3,    module = require"Layer_activity_treasuresDiscount_x3", resource = {}},

        [41] = { request = 1404, icon = gameConfig.images.activityicon_olddriver,    module = require"Layer_activity_oldDriver", resource = {},needupdate = true},
        [42] = { request = 4105, icon = gameConfig.images.activityicon_wudaolunpan,    module = require"Layer_activity_wudaolunpan", resource = {},needupdate = true},
        [43] = { request = 1075, icon = gameConfig.images.activityicon_fashion,    module = require"Layer_activity_fashion", resource = {}},
        [45] = { request = 1406, icon = gameConfig.images.activityicon_tigerchicken,    module = require"Layer_activity_tigerchicken", resource = {},needupdate = true},
        -- [45] = { request = 1408, icon = gameConfig.images.activityicon_tigerchickenshop,    module = require"Layer_activity_tigerchickenshop", resource = {}},
        [46] = { request = 2085, icon = gameConfig.images.activityicon_sdkshare,    module = require"Layer_activity_sdkshare", resource = {}},
        [48] = { request = 4300, icon = gameConfig.images.activityicon_goddown,    module = require"Layer_activity_goddown", resource = {},needupdate = true},
        
        -- [48] = { request = 4310, icon = gameConfig.images.activityicon_goddown_shop,    module = require"Layer_activity_goddownShop", resource = {} ,needupdate = true},
        -- [49] = { request = 4320, icon = gameConfig.images.activityicon_goddown_rank,    module = require"Layer_activity_goddownRank", resource = {} ,needupdate = true},

        [50] = { request = 3710, icon = gameConfig.images.activityicon_limitexchange, module = require"Layer_activity_limitex", resource = {}, needupdate = true},
        [51] = { request = 20051, icon = gameConfig.images.activityicon_everyday, module = require"Layer_activity_everyday", resource = {},needupdate = true},
        
        [52] = { request = 4400, icon = gameConfig.images.activityicon_fashionshop, module = require"Layer_activity_fashionshop", resource = {},needupdate = true},
        [53] = { request = 3733, icon = gameConfig.images.activityicon_safemaskshop, module = require"Layer_activity_safemaskshop", resource = {},needupdate = true},

        [54] = { request = 4600, icon = gameConfig.images.activityicon_zhongqiuduihuan, module = require"Layer_midAutumnShop", resource = {},needupdate = true},
        [55] = { request = 3750, icon = gameConfig.images.activityicon_danchongfuli, module = require"Layer_activity_singlerecharge", resource = {},needupdate = true},

        [56] = { request = 3760, icon = gameConfig.images.activityicon_achievements, module = require"Layer_activity_achievements", resource = {},needupdate = true},

        [57] = { request = 46111, icon = gameConfig.images.activityicon_vipwelfare, module = require"Layer_activity_vipwelfare", resource = {},needupdate = true},

        [58] = { request = 3770, icon = gameConfig.images.activityicon_playerrecall, module = require"Layer_activity_playerRecall", resource = {},needupdate = true},

        [59] = { request = 4615, icon = gameConfig.images.activityicon_fulilibao, module = require"Layer_activity_timegift", resource = {},needupdate = true},

        [61] = { request = 3790, icon = gameConfig.images.activityicon_mammon, module = require"Layer_activity_mammon2", resource = {},needupdate = true},

        [62] = { request = 4405, icon = gameConfig.images.activityicon_christmasshop, module = require"Layer_activity_christmasshop", resource = {},needupdate = true},

        [63] = { request = 4630, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_activity_lunpan", resource = {},needupdate = true},

        [64] = { request = 4650, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_activity_qualitylunpan", resource = {},needupdate = true},

        [65] = { request = 4810, icon = gameConfig.images.activityicon_paimaihang,    module = require"Layer_auction", resource = {},needupdate = true},

        [66] = { request = 4660, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_recharge_lunpan", resource = {},needupdate = true},

        -- [67] = { request = 4829, icon = gameConfig.images.activityicon_cangjinggeshop,    module = require"Layer_qiankunjing_shop", resource = {},needupdate = true},
        [67] = { request = 4829, icon = gameConfig.images.activityicon_cangjinggeshop,    module = require"Layer_cangjingge_shop", resource = {},needupdate = true},

        [68] = { request = 4860, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_totalrecharge", resource = {},needupdate = true},

        [69] = { request = 4850, icon = gameConfig.images.activityicon_rebate,    module = require"Layer_activity_rechargerebate", resource = {},needupdate = true},

        [71] = { request = 4870, icon = gameConfig.images.activityicon_goddown,    module = require"Layer_activity_k_goddown", resource = {},needupdate = true},
        -- [71] = { request = 4875, icon = gameConfig.images.activityicon_goddown_shop,    module = require"Layer_activity_k_goddownShop", resource = {} ,needupdate = true},
        -- [72] = { request = 4877, icon = gameConfig.images.activityicon_goddown_rank,    module = require"Layer_activity_k_goddownRank", resource = {} ,needupdate = true},

        [73] = { request = 4635, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_activity_k_lunpan", resource = {},needupdate = true},

        [74] = { request = 3860, icon = gameConfig.images.activityicon_tigerchicken,    module = require"Layer_activity_gambling", resource = {},needupdate = true},
        [75] = { request = 3862, icon = gameConfig.images.activityicon_tigerchicken,    module = require"Layer_activity_gamblingshop", resource = {},needupdate = true},

        [76] = { request = 4006, icon = gameConfig.images.activityicon_double,   module = require"Layer_activity_double_new2", resource = {},needupdate = true},

        --cp
        [77] = { request = 5002, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_cp_dailyreward", resource = {},needupdate = true},
        [78] = { request = 5000, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_cp_cumulativerecharge", resource = {},needupdate = true},
        [80] = { request = 5020, icon = gameConfig.images.activityicon_tigerchicken,    module = require"Layer_activity_cp_tigerchicken", resource = {},needupdate = true},
        --[80] = { request = 5022, icon = gameConfig.images.activityicon_tigerchickenshop,    module = require"Layer_activity_cp_tigerchickenshop", resource = {}},
        [82] = { request = 5010, icon = gameConfig.images.activityicon_goddown,    module = require"Layer_activity_cp_goddown", resource = {},needupdate = true},
        
        -- [82] = { request = 5015, icon = gameConfig.images.activityicon_goddown_shop,    module = require"Layer_activity_cp_goddownShop", resource = {} ,needupdate = true},
        -- [83] = { request = 5017, icon = gameConfig.images.activityicon_goddown_rank,    module = require"Layer_activity_cp_goddownRank", resource = {} ,needupdate = true},

        [84] = { request = 5025, icon = gameConfig.images.activityicon_achievements, module = require"Layer_activity_cp_achievements", resource = {},needupdate = true},
        [85] = { request = 5030, icon = gameConfig.images.activityicon_treasuresDiscount,    module = require"Layer_activity_cp_treasuresDiscount", resource = {}},
        [86] = { request = 5032, icon = gameConfig.images.activityicon_olddriver,    module = require"Layer_activity_cp_oldDriver", resource = {},needupdate = true},
        [87] = { request = 5034, icon = gameConfig.images.activityicon_double,   module = require"Layer_activity_cp_double_new", resource = {},needupdate = true},
        [88] = { request = 5035, icon = gameConfig.images.activityicon_fashionshop, module = require"Layer_activity_cp_fashionshop", resource = {},needupdate = true},
        [89] = { request = 5046, icon = gameConfig.images.activityicon_continuous,    module = require"Layer_activity_cp_continuous", resource = {}},
        [90] = { request = 5037, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_activity_cp_lunpan", resource = {},needupdate = true},
        [91] = { request = 5039, icon = gameConfig.images.activityicon_consumereward,    module = require"Layer_activity_cp_consumereward_new", resource = {},needupdate = true},
        [92] = { request = 5041, icon = gameConfig.images.activityicon_rebate,    module = require"Layer_activity_cp_rechargerebate", resource = {},needupdate = true},
        [93] = { request = 5043, icon = gameConfig.images.activityicon_shop,      module = require"Layer_activity_cp_shop", resource = {} },

        [94] = { request = 5050, icon = gameConfig.images.activityicon_danchongfuli, module = require"Layer_activity_cp_singlerecharge", resource = {},needupdate = true},
        [95] = { request = 5052, icon = gameConfig.images.activityicon_limitexchange, module = require"Layer_activity_cp_limitex", resource = {}, needupdate = true},
        [96] = { request = 5055, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_cp_totalrecharge", resource = {},needupdate = true},
        [97] = { request = 5057, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_cp_recharge_lunpan", resource = {},needupdate = true},

        [100] = { request = 5315, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_activity_chaozhifankui", resource = {},needupdate = true},
        [102] = { request = 5323, icon = gameConfig.images.activityicon_zhongqiujianianhua,    module = require"Layer_activity_zhongshu", resource = {},needupdate = true},
        [103] = { request = 5401, icon = gameConfig.images.activityicon_pantaoxianli,    module = require"Layer_activity_peentoGift", resource = {},needupdate = true},
        [104] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_powerRank", resource = {}},
        [105] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_sigilPowerRank", resource = {}},
        [106] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_powerGrowthRank", resource = {}},

        [108] = { request = 5701, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_totalrecharge_x1", resource = {},needupdate = true},
        [109] = { request = 5801, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_weekCard", resource = {},needupdate = true},
        
        -- [110] = { request = nil, icon = gameConfig.images.activityicon_auction, module = require"Layer_activity_auction", resource = {},needupdate = true},
        -- [111] = { request = nil, icon = gameConfig.images.activityicon_honor_battle, module = require"Layer_activity_honor_battle_shop", resource = {},needupdate = true},

        [112] = { request = 3684, icon = gameConfig.images.activityicon_multipleRebate,    module = require"Layer_activity_multipleRebate_x1", resource = {}},
        [113] = { request = 3686, icon = gameConfig.images.activityicon_welfareMonth,    module = require"Layer_activity_welfareMonth_x1", resource = {}},
        [114] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_powerGrowthRank_x1", resource = {}},
        [115] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_powerGrowthRank_x2", resource = {}},

        [116] = { request = 5525, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_weekreward", resource = {},needupdate = true},

        [117] = { request = 5531, icon = gameConfig.images.activityicon_multipleRebate,    module = require"Layer_activity_multipleRebate_x2", resource = {}},
        [118] = { request = 5533, icon = gameConfig.images.activityicon_welfareMonth,    module = require"Layer_activity_welfareMonth_x2", resource = {}},

        [119] = { request = nil, icon = gameConfig.images.activityicon_pooling_servers_online,    module = require"Layer_activity_pooling_servers_online", resource = {}, needupdate = true},
        [120] = { request = nil, icon = gameConfig.images.activityicon_pooling_servers_sign,    module = require"Layer_activity_pooling_servers_sign", resource = {}, needupdate = true},
        [121] = { request = nil, icon = gameConfig.images.activityicon_pooling_servers_gift,    module = require"Layer_activity_pooling_servers_gift", resource = {}, needupdate = true},
        -- [122] = { request = 6015, icon = gameConfig.images.activityicon_sportsshop,    module = require"Layer_kingBattle_shop", resource = {}},


        [123] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_magicWeaponRank", resource = {}},
        [124] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_copyRank", resource = {}},
        [125] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_shieldRank", resource = {}},
        [126] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_wingRank", resource = {}},
        [127] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_minggeRank", resource = {}},
        [128] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_partnerPowerRank", resource = {}},
        [129] = { request = nil, icon = gameConfig.images.activityicon_newrank,    module = require"Layer_activity_artifactRank", resource = {}},

        [130] = { request = 3755, icon = gameConfig.images.activityicon_danchongfuli, module = require"Layer_activity_singlerecharge_x1", resource = {},needupdate = true},
        [131] = { request = 5060, icon = gameConfig.images.activityicon_danchongfuli, module = require"Layer_activity_cp_singlerecharge_x1", resource = {},needupdate = true},
        -- 新连续登录
        [132] = { request = 214, icon = gameConfig.images.activityicon_continuous,    module = require"Layer_activity_newcontinuous", resource = {}},
        -- [133] = { request = 6451, icon = gameConfig.images.activityicon_dailyreward, module = require"Layer_activity_jinghuashop", resource = {},needupdate = true},

        [134] = { request = 6601, icon = gameConfig.images.activityicon_dailyreward, module = require"Layer_activity_christmas", resource = {},needupdate = true},

        [135] = { request = 6801, icon = gameConfig.images.activityicon_dailyreward, module = require"Layer_activity_timebuy", resource = {},needupdate = true},

        -- [136] = { request = 6911, icon = gameConfig.images.activityicon_dailyreward, module = require"Layer_activity_shizhuangshop", resource = {},needupdate = true},
        
        -- [137] = { request = 7017, icon = gameConfig.images.activityicon_dailyreward, module = require"Layer_activity_babelTowerShop", resource = {},needupdate = true},

        [141] = { request = 3758, icon = gameConfig.images.activityicon_danchongfuli, module = require"Layer_activity_singlerecharge_x2", resource = {},needupdate = true},
        [149] = { request = 7091, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_growplan3", resource = {}},
        [150] = { request = 8020, icon = gameConfig.images.activity_jinghualibao,   module = require"Layer_activity_discountGift", resource = {}},
        [151] = { request = 8022, icon = gameConfig.images.activity_jinghualibao,   module = require"Layer_activity_discountGift_cp1", resource = {}},
        [152] = { request = 8024, icon = gameConfig.images.activity_jinghualibao,   module = require"Layer_activity_discountGift_cp2", resource = {}},
        [153] = { request = 8026, icon = gameConfig.images.activity_bazhelibao,   module = require"Layer_activity_speedGift", resource = {}},
        [154] = { request = 8028, icon = gameConfig.images.activity_bazhelibao,   module = require"Layer_activity_speedGift_cp1", resource = {}},
        [155] = { request = 8032, icon = gameConfig.images.activity_bazhelibao,   module = require"Layer_activity_speedGift_cp2", resource = {}},
        [157] = { request = 4018, icon = gameConfig.images.activity_kuafuduihuan_di,    module = require"Layer_activity_cp_treasuresDiscount_x1", resource = {}},
        [158] = { request = 4020, icon = gameConfig.images.activity_kuafuduihuan_tian,    module = require"Layer_activity_cp_treasuresDiscount_x2", resource = {}},
        [159] = { request = 4022, icon = gameConfig.images.activity_kuafuduihuan_xian,    module = require"Layer_activity_cp_treasuresDiscount_x3", resource = {}},
        [160] = { request = 4024, icon = gameConfig.images.activity_kuafuduihuan_shen,    module = require"Layer_activity_cp_treasuresDiscount_x4", resource = {}},
	    -- 20 133 136 137
        [161] = { request = nil, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_general_shop", resource = {},needupdate = true},
        -- 26 27 36 37 207
        [162] = { request = nil, icon = gameConfig.images.activityicon_dailyreward,    module = require"Layer_activity_point_shop", resource = {},needupdate = true},
        -- 跨服榜活动
        [163] = { request = 8034, icon = gameConfig.images.activity_kuafuduihuan_shen,    module = require"Layer_activity_cp_treasuresDiscount_x5", resource = {}},
        -- 合服商店
        [164] = { request = 8047, icon = gameConfig.images.activityicon_pooling_servers_gift,    module = require"Layer_activity_hefushop", resource = {}},
        [165] = { request = 8045, icon = gameConfig.images.activity_jinghualibao,   module = require"Layer_activity_hefuGift", resource = {}},
        [166] = { request = 8055, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_dewPool", resource = {}},

	   --周基金
        [167] = { request = 8071, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_weekFund1", resource = {}},
        [168] = { request = 8073, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_weekFund2", resource = {}},
        [169] = { request = 8075, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_cp_weekFund1", resource = {}},
        [170] = { request = 8077, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_cp_weekFund2", resource = {}},
        [171] = { request = 8079, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_rc_weekFund1", resource = {}},
        [172] = { request = 8081, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_rc_weekFund2", resource = {}},

        [173] = { request = 4890, icon = gameConfig.images.activityicon_fulilibao, module = require"Layer_activity_vipweekGift", resource = {}},

        [175] = { request = 8113, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_illusionGift", resource = {}},
        [176] = { request = 8115, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_illusionGift_x1", resource = {}},
        [177] = { request = 8117, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_illusionTask", resource = {}},

        [178] = { request = 8120, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_growplan4", resource = {}},
        [179] = { request = 8122, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_growplan5", resource = {}},
        [180] = { request = 8130, icon = gameConfig.images.activityicon_growplan,   module = require"Layer_activity_sculpture", resource = {}},
    
        [193] = { request = 3688, icon = gameConfig.images.activityicon_multipleRebate,    module = require"Layer_activity_multipleRebate_magic", resource = {}},

        [208] = { request = 4602, icon = gameConfig.images.activityicon_zhongqiuduihuan, module = require"Layer_midAutumnShop_x1", resource = {},needupdate = true},
        [209] = { request = 5062, icon = gameConfig.images.activityicon_danchongfuli, module = require"Layer_activity_singlerecharge_x3", resource = {},needupdate = true},
    },
    pageTable6 = {},

    pageTable5 = {},

    pageTable4 = {},

    pageTable3 = {},

    pageTable2 = {},

    pageTable1 = {},

    type = "",
    pageTable = {},

    realPageTable = {},
    openPageTable = {},
    createsPage = {},

    presentPage = 1,

    titleCellSize = {x=180,y=180},
    contentCellSize = {x= 1080,y=1150},

    touchX = nil,
    contentoffsetx = 0,
    isContentScroll = false,

    hintext = {
        [568] = {443,134,434,451},
        [569] = {167,166,185,184},
    }
}

function activity.makepageconfig(self)
    if not next(self.pageTable1) or not next(self.pageTable2) or not next(self.pageTable3) then
        for k,v in pairs(gamedata.config.activity_time) do
            -- if tonumber(v.systemid) == 131 or tonumber(v.systemid) == 134 or tonumber(v.systemid) == 167 or tonumber(v.systemid) == 166 or tonumber(v.systemid) == 164 then
            --     self.pageTable3[v.id] = self.activityPageconfig[v.id]
            -- else
                self["pageTable"..v.type][v.id] = self.activityPageconfig[v.id]
            -- end
            
        end
        -- printT(self.pageTable3,"pageTable3===")
    end
end

function activity.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("activity/activity", nil, true, "activity")
    parent:addChild(self.rootNode)

    self:makepageconfig()

    self.rootItems.topnode:setPositionY(toppos)

    self.contentCellSize = {x = gameConfig.originSize.width, y= toppos}
    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos))

    self.rootItems.ActivityScroll = tolua.cast(self.rootItems.ActivityScroll, "CCScrollView")

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self:createPagesExt()

            self.isContentScroll = false
            self.touchX = x
            self.touchY = y
            self.pagemoved = false
            self.contentoffsetx = self.rootItems.ActivityScroll:getContentOffset().x
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end

        if math.abs(x - self.touchX) > 30 and math.abs(y - self.touchY)/math.abs(x - self.touchX) <0.3 then
            self.pagemoved = true
            local offsetX = self.contentoffsetx + (x - self.touchX)
            self.rootItems.ActivityScroll:setContentOffset(ccp(offsetX, self.rootItems.ActivityScroll:getContentOffset().y))
        end
    end

    local function ccTouchEnded(x, y)
        local moveX = self.touchX -x
        print(moveX)

        if moveX > 20 and self.pagemoved then
            if self.presentPage+1 <=table.getTableLength(self.realPageTable) then
                self:setPage(self.presentPage+1)
            else
                self:setPage(self.presentPage)
            end
        elseif moveX < -20 and self.pagemoved then
            if self.presentPage-1 >0 then
                self:setPage(self.presentPage-1)
            else
                self:setPage(self.presentPage)
            end
        else
            if self.realPageTable[self.presentPage] and 
                self.realPageTable[self.presentPage].module.finishNow ~= nil then
                self.realPageTable[self.presentPage].module:finishNow()
            end
            --self:setPage(self.presentPage)
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -105, false)
    self.rootItems.touchLayer:setTouchPriority(-105)
    self.rootItems.touchLayer:setTouchEnabled(true)

    --UIRequest({type = 2000})
end

function activity.setActivityData(self,data)
    for k,v in ipairs(self.realPageTable) do
        v.module:clear()
    end
    self.openPageTable = {}
    self.realPageTable = {}
    self.pageTable = self["pageTable"..self.type]
    for k,v in pairs(data.status) do

        if (v.id == 46) and  (deviceApi.channel ~= "chujiani")  and (deviceApi.channel ~= "zuoyaojihdios2") and (deviceApi.channel ~= "zuoyaojiapple2") and (deviceApi.channel ~= "iOSbaozouZYJ") then
            print("no share")
        elseif (v.id == 132) and (deviceApi.channel ~= "muyoughqnxs") and (not string.find(deviceApi.channel,"muyoutg_baidu")) then
            print("no muyou")
        elseif v.status == 1 then
            self.openPageTable[v.id] = { id = v.id }
            print("v.id==",v.id,self.pageTable[v.id])
            if self.pageTable[v.id] then
                print("pageTableenter===")
                table.insert(self.realPageTable,
                    table.merge(self.pageTable[v.id],
                    {
                        id = v.id,
                        name = gamedata.config.activity_time[tostring(v.id)].name,
                        seq = gamedata.config.activity_time[tostring(v.id)].seq
                    }))
            end

        end
    end
    printT(self.realPageTable,"realPageTable===")

    local sortbySeq= function(a,b) return a.seq < b.seq end
    table.sort(self.realPageTable,sortbySeq)

    printT(data,"data===test")
    if data.id then
         for k,v in ipairs(self.realPageTable) do
             if tonumber(data.id) == v.id then
                self.presentPage = k
             end
         end
    end

    if #self.realPageTable < self.presentPage then self.presentPage = #self.realPageTable end
end

function activity.reloadHint(self)
    if self.NavigationTableView then
        self.NavigationTableView:reloadData()
    end

    if self.activityPageconfig[161].module.show and self.activityPageconfig[161].module.reloadHint then
        self.activityPageconfig[161].module:reloadHint()
    end
end

function activity.createNavigation(self)

    local activityTable = {}
    local NavigationHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/activity_icon.ccbi", nil, true, "activity_icon")
                activityTable[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimationH(self.NavigationTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = activityTable[a2].cellCCB
                ccbDocumentControler = activityTable[a2].ccbDocumentControler
            end

            local config = gamedata.config.activity_time[tostring(self.realPageTable[a1+1].id)]

            if config.id == 52 and self.dailyCpActivityTimeStatus[52] then
                local cpnum = self.dailyCpActivityTimeStatus[52].cpnum or 0
                --单数火影 双数pantkill
                if cpnum%2 == 1 then
                    config.icon = "activity_huoying"
                else
                    config.icon = "activity_shizhuang"
                end
            end

            if config.id == 150 and self.dailyCpActivityTimeStatus[150] then
                local cpnum = self.dailyCpActivityTimeStatus[150].cpnum or 0
                local cpday = self.dailyCpActivityTimeStatus[150].cpday or 0

                local icon = "activity_huoying"
                local name = nil
                local status = {}
                for k,v in pairs(gamedata.config.special_gift_time_x1) do
                    if v.day and v.day ~= "" then
                        table.insert(status,v)
                    end
                end
                table.sort(status, function(a,b) return a.day < b.day end)
                for i=1 , table.getTableLength(status) do
                    local currentday = status[i].day
                    local afterday =  (status[i+1] ~=nil)  and (status[i+1].day) or  -1
                    if cpday>=currentday and cpday<afterday then
                          icon = status[i].icon_activity
                          name = status[i].name
                          break
                    end    
                    if afterday == -1 and cpday>=currentday  then
                        icon = status[i].icon_activity
                        name = status[i].name
                        break
                    end    
                 end

                config.icon = icon or "activity_huoying"
                config.name = name
            end

            ui.setNavigationIcon(ccbDocumentControler,{icon = (config.icon and config.icon ~= "") and config.icon or self.realPageTable[a1+1].icon,name = (config.name and config.name ~= "") and config.name or self.realPageTable[a1+1].name,opt = 1})
            ccbDocumentControler.new:removeAllChildrenWithCleanup(true)

            local sysid = gamedata.config.activity_time[tostring(self.realPageTable[a1+1].id)].systemid
            if guide.controller then
                if self.hintext[tonumber(sysid)] then
                    for i,v in ipairs(self.hintext[tonumber(sysid)]) do
                        if guide.controller:isNewSystemByid(sysid) and GameScene:checkopenlevelbyId(sysid,true) then
                            local ccb,Items = CCBReaderLoad("talk/new", nil, true, "new")
                            ccbDocumentControler.new:addChild(ccb)
                            break
                        end
                    end
                else
                    if guide.controller:isNewSystemByid(sysid) and GameScene:checkopenlevelbyId(sysid,true) then
                        local ccb,Items = CCBReaderLoad("talk/new", nil, true, "new")
                        ccbDocumentControler.new:addChild(ccb)
                    end
                end
            end

            if self.realPageTable[a1+1].id == 42 then
                if GameScene.roleinfo and next(GameScene.roleinfo) and GameScene.roleinfo.id then
                    local _wudaohuiRewardPreview = CCUserDefault:sharedUserDefault():getBoolForKey("wudaohuiRewardPreview"..GameScene.roleinfo.id)

                    if _wudaohuiRewardPreview then
                        ccbDocumentControler.new:removeAllChildrenWithCleanup(true)
                        local ccb,Items = CCBReaderLoad("talk/new", nil, true, "new")
                        ccbDocumentControler.new:addChild(ccb)
                    end
                end
            end
            --ccbDocumentControler.i_selected:setVisible(false)
            ccbDocumentControler.i_selectEffect:removeAllChildrenWithCleanup(true)

            if self.hintext[tonumber(sysid)] then
                local hint = false
                for i,v in ipairs(self.hintext[tonumber(sysid)]) do
                    if GameScene.hintdata[tostring(v)] and GameScene.hintdata[tostring(v)] ~= 0 then
                        hint = true
                        break
                    end
                end
                ui.sethint(ccbDocumentControler.hint,hint)
            else
                ui.sethint(ccbDocumentControler.hint,GameScene.hintdata[tostring(sysid)] and GameScene.hintdata[tostring(sysid)] ~= 0)
            end

            cellCCB:setAnchorPoint(ccp(0.5, 0.5))
            cellCCB:setScale(1)
            if a1+1 == self.presentPage then
                --cellCCB:setScale(1.05)
                --ccbDocumentControler.i_selected:setVisible(true)
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                ccbDocumentControler.i_selectEffect:addChild(eccb)
            end
            if self.NavigationTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.realPageTable)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            self:setPage(a1:getIdx() +1, true)
            if guide.controller then
                guide.controller:UIComplete(8003)
            end
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.NavigationTableView = ui.createLuaTableView({
        handle = NavigationHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.listscroll:addChild(self.NavigationTableView)
    self.NavigationTableView:setTouchPriority(-106)
end

function activity.createContentPage(self, pageId)
    for k,v in ipairs(self.realPageTable) do
        v.module:clear()
    end
    self.rootItems.container:removeAllChildrenWithCleanup(true)
    self.createsPage = {}
    self.rootItems.ActivityScroll:setTouchEnabled(false)
    self:setPage(self.presentPage, true, pageId)
end

function activity.createOnePage(self,page,pageId)
    print("createOnePage===", page, pageId)
    if not self.createsPage[page] and self.realPageTable[page] then
--        local items
--        self.createsPage[page], items = CCBReaderLoad("activity/page.ccbi", nil, true, "page")
--        items.page:setTouchEnabled(false)
--
--        local pagenode = self.realPageTable[page].module:init(self.contentCellSize)
--        pagenode:setAnchorPoint(ccp(0, 0))
--        pagenode:setPosition(ccp(0,0))
--        items.container:addChild(pagenode)
 
        self.createsPage[page] = self.realPageTable[page].module:init(self.contentCellSize,self.realPageTable[page].id, pageId)


        self.createsPage[page]:setPosition(ccp(self.contentCellSize.x*(page-1), 0))
        self.rootItems.container:addChild(self.createsPage[page],self.realPageTable[page].zorder or 1)
        print("发送", self.realPageTable[page].request)
        if self.realPageTable[page].request then
            UIRequest({ type = self.realPageTable[page].request })
        end
    elseif self.realPageTable[page] then
        self.createsPage[page]:setVisible(true)
        if self.realPageTable[page].module.refreshFunc then
            self.realPageTable[page].module:refreshFunc(pageId)
        end
    end
end

function activity.createPages(self, pageId)

    for k,v in pairs(self.createsPage) do

        v:setVisible(k == self.presentPage)
    end
    self:createOnePage(self.presentPage, pageId)
end

function activity.createPagesExt(self)
    self:createOnePage(self.presentPage+1)
    self:createOnePage(self.presentPage-1)
end

function activity.setPageByid(self,id, pageId)
    for k,v in ipairs(self.realPageTable) do
        if tonumber(v.id) == tonumber(id) then
            self:setPage(k, nil, pageId)
            return
        end
    end
    --runGamePrompt({msg = "暂未开放"})
    runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",1)})
end

function activity.setPage(self,page,first,pageId)
    self.presentPage = page
    print("self.presentPage",self.presentPage,pageId)

    if self.NavigationTableView then
        self.NavigationTableView:reloadData()
    else
        self:createNavigation()
    end

    if  self.titleCellSize.x * self.presentPage >  self.rootItems.listscroll:getContentSize().width - self.NavigationTableView:getLuaContentOffsetX() then
        self.NavigationTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * self.presentPage,0),0.2)
    elseif self.titleCellSize.x * (self.presentPage-1) < -self.NavigationTableView:getLuaContentOffsetX() then
        self.NavigationTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.presentPage-1) ,0),0.2)
    end
    
    if self.createsPage[page] and self.realPageTable[page].needupdate and self.realPageTable[page].request then  UIRequest({ type = self.realPageTable[page].request }) end

    if first then
        self.rootItems.ActivityScroll:setContentOffset(ccp(-(self.presentPage-1) * self.contentCellSize.x, self.rootItems.ActivityScroll:getContentOffset().y))
        self:createPages(pageId)
    else
        --self.rootItems.ActivityScroll:setContentOffsetInDuration(ccp(-(self.presentPage-1) * self.contentCellSize.x, self.rootItems.ActivityScroll:getContentOffset().y), 0.2)
        local moveto = CCMoveTo:create(0.2, ccp(-self.contentCellSize.x*(self.presentPage-1), 0))
        self.rootItems.container:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            self:createPages(pageId)
        end)))
    end
    
    if guide.controller then
        guide.controller:NewSystem(gamedata.config.activity_time[tostring(self.realPageTable[self.presentPage].id)].systemid)
    end
end

function activity.reload(self,data)
    print("activityreload===")
    printT(data)

    pauseUIUpdate()
    self.rootItems.touchLayer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
        startUIUpdate()
    end)))
    self.type = data.page
    GameScene.activityStatus = data.status
    self.presentPage = self["presentPage"..self.type] or 1
    self:setActivityData(data)
    
--    if self.NavigationTableView then
--        self.NavigationTableView:reloadData()
--    else
--        self:createNavigation()
--    end
    self:createContentPage(data.pageId)
end

function activity.clear(self)

    for k,v in ipairs(self.realPageTable) do
        v.module:clear()
        for kk,vv in ipairs(v.resource) do
            texture.removeSpriteFramesWithFile(vv)
        end
    end

    self.NavigationTableView = nil

    self["presentPage"..self.type] = self.presentPage
    --self.presentPage = 1

    self.realPageTable = {}
    self.createsPage = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function activity.setDailyCpActivityTimeStatus(self,data)
    for k,v in pairs(data) do
        self.dailyCpActivityTimeStatus[v.sysid] = v
    end
    printT(self.dailyCpActivityTimeStatus,"setDailyCpActivityTimeStatus")
end

--活动时间倒计时 计算
function activity.getDailyCpActivityTime(self,activityId)
    local activityConfig = gamedata.config:getConfigByName("activity_time")[tostring(activityId)]
    if not activityConfig then return 0 end

    local timediff = 0
    if self.dailyCpActivityTimeStatus[activityId] then
        local cpnum = self.dailyCpActivityTimeStatus[activityId].cpnum
        local cpday = self.dailyCpActivityTimeStatus[activityId].cpday

        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)

        if activityConfig["open_type"] == 5 then
            timediff = 86400*(activityConfig[ "continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        else
            timediff = 86400*(activityConfig[ "continued_time"]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        end    

        if activityConfig.extra_time and activityConfig.extra_time > 0 then
            timediff = timediff + 86400 * activityConfig.extra_time
        end
    end
    return timediff
end

--活动时间倒计时 返回字符串
function activity.getDailyCpActivityTimeToString(self,activityId)
    local activityConfig = gamedata.config:getConfigByName("activity_time")[tostring(activityId)]
    if not activityConfig then return "" end

    local endString = ""
    if self.dailyCpActivityTimeStatus[activityId] then
        local cpnum = self.dailyCpActivityTimeStatus[activityId].cpnum
        local cpday = self.dailyCpActivityTimeStatus[activityId].cpday

        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        local timediff = ""
        if activityConfig["open_type"] == 5 then

            timediff = nowtime + 86400*(activityConfig["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        else
            timediff = nowtime + 86400*(activityConfig["continued_time"]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        end    

        local endtab = os.date("*t", timediff-2)
        endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
    end
    return endString
end

--查询 当前活动id的轮数和天数
function activity.getDailyCPActivityDataById(self,activityId)
    local activityConfig = gamedata.config:getConfigByName("activity_time")[tostring(activityId)]
    if not activityConfig then return nil end

    local data = nil
    if self.dailyCpActivityTimeStatus[activityId] then
       data = self.dailyCpActivityTimeStatus[activityId]
        local continuedTime = 0
        if activityConfig["open_type"] == 5 then
            continuedTime = activityConfig["continued_time"..((data.cpnum == 1) and ("_1") or "")]
        else
            continuedTime = activityConfig["continued_time"]
        end
        data.continuedTime = continuedTime
        if activityConfig.extra_time and activityConfig.extra_time > 0 and data.cpday > continuedTime then
            data.extra_time = true
        end
    end
    return data
end

--活动剩余时间
function activity.getActivityRemainingTime(self,activityId)
    local timediff = 0
    if gamedata.config.activity_time[tostring(activityId)]["open_type"] and gamedata.config.activity_time[tostring(activityId)]["open_type"] == 2 then

    elseif gamedata.config.activity_time[tostring(activityId)]["open_type"] and gamedata.config.activity_time[tostring(activityId)]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time[tostring(activityId)]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
    elseif gamedata.config.activity_time[tostring(activityId)]["open_type"] and (gamedata.config.activity_time[tostring(activityId)]["open_type"] == 5 or gamedata.config.activity_time[tostring(activityId)]["open_type"] == 7) then
        timediff = self:getDailyCpActivityTime(activityId)
        
    elseif gamedata.config.activity_time[tostring(activityId)]["end"] and gamedata.config.activity_time[tostring(activityId)]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time[tostring(activityId)]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    end
    return timediff
end

return activity
