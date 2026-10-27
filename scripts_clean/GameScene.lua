--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-7-28
-- Time: 下午1:43
-- To change this template use File | Settings | File Templates.
--

require"myque"
local gameScene = {

    maxRadio_size = gameConfig.maxRadio_size,
    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },
    viewSize = gameConfig.originSize,
    topposY = gameConfig.originSize.height,

    updateTable = {
        ["10023"] = true,
    },
    updateRelation = {
--        ["1200"] = {"1310"},
--        ["10023"] = {"1310"},
    },

    scaleNum  = 1,
    bottomHeight = 0,

    rootLayer = nil,
    rootNode = nil,
    rootItems = nil,

    priorLayer = nil,
    presentLayer = nil,
    roletimer = nil,

    topconfig = {
        {name = "userinfo_b",height= 173,},
        {name = "userinfo_s",height= 81,},
    },

    effect_pos1 = ccp(180,-40),
    effect_pos2 = ccp(400,-40),
    effect_pos3 = ccp(20,-40),
    effect_pos4 = ccp(300,-40),

    layers = {
        main = {name = "主界面", top = {1,0,0,0},  resource = {"MainScene/main"}, shiftDirect = true, module = require"Layer_main", },
        mail = {name = "邮件", top =  {0,1,0,0},  resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_mail", },
        activity = {name = "activity",  top = {0,1,0,0},  resource = {"activity/activity"}, shiftDirect = true, module = require"Layer_activity"},
        task = {name = "奖励",  top = {0,1,0,0},  resource = {}, delayupdate = true,shiftDirect = true,module = require"Layer_task"},
        penglai = {name = "蓬莱仙岛",  top = {0,1,0,0},  resource = {"island3/island3"}, delayupdate = true,module = require"Layer_island2"},
        worldboss = {name = "群仙屠龙",  top = {0,0,0,0},  resource = {"worldboss/boss"}, delayupdate = true,module = require"Layer_worldboss2"},
        equips   = {name = "装备",  top = {0,1,0,0},  resource = {}, delayupdate = true,shiftDirect = true,module = require"Layer_equips"},
        equips_resolve   = {name = "批量分解", top = {0,1,0,0},   resource = {}, shiftDirect = true,module = require"Layer_equipResolve"},
        treasure_resolve   = {name = "批量分解", top = {0,1,0,0},   resource = {}, shiftDirect = true,module = require"Layer_treasureResolve"},
        slotsInfo   = {name = "阵容",  top = {0,1,0,0},  resource = {}, delayupdate = true,shiftDirect = true,module = require"Layer_slotsInfo"},
        generals   = {name = "伙伴列表", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_general"},
        soul = {name = "soul", top = {0,1,0,0},   resource = {"soul/soul"}, delayupdate = true, module = require"Layer_soul" },
        soulResolveList = {name = "soulResolveList",  top = {0,1,0,0},  resource = {}, shiftDirect = true,module = require"Layer_soulResolveList" },
        copy_map   = {name = "copy_map", top = {0,1,0,0},   resource = {}, shiftDirect = true, module = require"Layer_copy_list"},
        copy_chapter   = {name = "copy_chapter", top = {0,1,0,0},   resource = {}, module = require"Layer_copy_chapter"},
        friends   = {name = "friends", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_friends"},
        encounter2 = {name = "奇遇",  top = {0,0,0,0},  resource = {"encounter2_new/encounter2"}, delayupdate = true, shiftDirect = true, module = require"Layer_encounter2" },
        friendcopy = {name = "好友副本", top = {0,1,0,0},   resource = {"copyFriend/copyfriend"}, shiftDirect = true,delayupdate = true,module = require"Layer_friendcopy2" },
        sports2 = {name = "竞技场", top = {0,1,0,0},   resource = {"n_sports2/n_sports2"}, delayupdate = true, shiftDirect = true,module = require"Layer_sports"},
        rob = {name = "rob", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_rob" },
        cup = {name = "cup",  top = {0,1,0,0},  resource = {"cup/cup"}, delayupdate = true, shiftDirect = true,module = require"Layer_cup" },

        gang_list = {name = "公会",  top = {0,1,0,0},  resource = {"gonghui2/gonghui"}, delayupdate = true,module = require"Layer_guild2_list" },
        gang_main = {name = "公会",  top = {0,1,0,0},  resource = {"gonghui2/gonghui_zhuye"}, module = require"Layer_guild2_main" },
        gang_manager = {name = "公会",  top = {0,1,0,0},  resource = {"gonghui2/gonghui_zhuye"}, module = require"Layer_guild2_manager" },
        gang_shangxiang = {name = "公会",  top = {0,1,0,0},  resource = {"gonghui2/gang_shangxiang"}, module = require"Layer_guild2_shangxiang" },
        gang_xianchi = {name = "公会",  top = {0,0,0,0},  resource = {"gonghui2/gang_shanchi"}, module = require"Layer_guild2_xianchi" },
        gang_xianchi2 = {name = "公会篝火", firstremove = true, top = {0,1,0,0}, nobottom = true, delayupdate = false, resource = {"gonghui2/gang_shanchi"}, module = require"Layer_guild_zaotang" },

        gang_skill = {name = "公会技能",  top = {0,0,0,0},  resource = {}, delayupdate = true,module = require"Layer_guild_skill" },
        gangwar_main = {name = "公会战",  top = {0,1,0,0},  resource = {"gonghui2/gangwar_main"}, module = require"Layer_guildWar_main" },
        gang_guard = {name = "公会防守",  top = {0,1,0,0},  resource = {"gonghui2/gonghui_shouwei"}, module = require"Layer_guild2_guard" },
        guardRank = {name = "公会防守排行",  top = {0,1,0,0},  resource = {"gonghui2/gonghui_shouweirank"}, module = require"Layer_guild2_guardRank" },       


        -- guild_shop = {name = "工会商店", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_guild_shop"},
        -- guild_shop = {name = "工会商店", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_guild_shop2"},

        bloodbattle = {name = "灭神殿", top = {0,1,0,0},   resource = {}, delayupdate = true, module = require"Layer_zhuxiantai2"},

        chat = {name = "聊天", top = {0,0,0,0},   resource = {}, module = require"Layer_chat"},
        shopList = {name = "商城", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_shopList"},

        daily = {name = "日常", top = {0,0,0,0},   resource = {"daily/daily"}, shiftDirect = true, module = require"Layer_daily" },
        collect = {name = "图鉴", top = {0,0,0,0},   resource = {}, delayupdate = true,module = require"Layer_collect" },
        gonglve = {name = "攻略", top = {0,1,0,0},   resource = {}, module = require"Layer_gonglve"},

        devil = {name = "魔宠", top = {0,1,0,0},   resource = {}, delayupdate = true,module = require"Layer_mochonglead"},
        -- devourList = {name = "魔宠列表",  top = {0,1,0,0},  resource = {"love/love"}, delayupdate = true,module = require"Layer_devourList"},
        devilBag = { name = "魔宠背包",top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_devilBag"},
        devilcollect = { name = "魔宠图鉴",top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_devourcollect"},

        ranklist = {name = "排行榜", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_rank2"},

        lead = {name = "魔宫", top = {0,1,0,0},   resource = {}, delayupdate = true,module = require"Layer_lead3"},
        startactivity = {name = "开服活动", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_startactivity"},

        watchstar = {name = "观星台", top = {0,1,0,0},   resource = {}, delayupdate = true,module = require"Layer_watchstar2"},

        qiankunlu = {name = "乾坤炉",  top = {0,1,0,0},  resource = {"qiankunlu/qiankunlu"}, delayupdate = true,module = require"Layer_qiankunlu"},

        generalup = {name = "伙伴升级",  top = {0,1,0,0},  resource = {"general_new/general_n_up"}, delayupdate = true,module = require"Layer_generalup"},

        favoritegeneral = {name = "好感系统",  top = {0,1,0,0},  resource = {"love/love"}, delayupdate = true,module = require"Layer_favoritegeneral"},

        treasureup = {name = "宝物强化",  top = {0,1,0,0},  resource = {"equip_new/baowu_qianghua"}, delayupdate = true,module = require"Layer_treasureup"},
        equipsup = {name = "武器洗练",  top = {0,1,0,0},  resource = {"equip_new/equips_up_n"}, delayupdate = true,module = require"Layer_equip_up"},
        
        guildprepare = {name = "公会备战",  top = {0,0,0,0}, nobottom = true, resource = {"gonghuizhan/gonghuizhan_zhunbei"}, delayupdate = true,module = require"Layer_guild2_prepare"},
        
        achievement = {name = "奖励",  top = {0,1,0,0},  resource = {}, delayupdate = true,shiftDirect = true,module = require"Layer_achievement"},

        singleboss = {name = "个人boss",  top = {0,0,0,0},  resource = {}, delayupdate = false,shiftDirect = false, module = require"Layer_singleBoss"},
        slotarrange = {name = "布阵",  top = {0,0,0,0},  resource = {}, delayupdate = false,shiftDirect = false, module = require"Layer_slotArrange"},

        mofulist = {name = "魔符背包",  top = {0,1,0,0},  resource = {}, delayupdate = true,shiftDirect = true, module = require"Layer_mofuList"},
        starcopy_map   = {name = "名将副本", top = {0,1,0,0},   resource = {}, shiftDirect = true, module = require"Layer_copy_star_map"},
        
        hadescopy_map   = {name = "地狱副本", top = {0,1,0,0},   resource = {}, shiftDirect = true, module = require"Layer_copy_hades_map"},


        magic =  {name = "法宝",  top = {0,1,0,0},  resource = {}, delayupdate = true,shiftDirect = false, module = require"Layer_magic"},
        
        equipstage = {name = "装备进阶",  top = {0,1,0,0},  resource = {}, delayupdate = true,shiftDirect = false, module = require"Layer_equipstage"},

        maze = {name = "迷宫", top = {0,1,0,0},   resource = {}, delayupdate = false, module = require"Layer_maze"},


        slotenemy = {name = "迷宫敌方阵容", top = {0,1,0,0},   resource = {}, delayupdate = false, module = require"Layer_slotEnemy"},
        slotwithhp = {name = "迷宫己方阵容", top = {0,0,0,0},   resource = {}, delayupdate = false, module = require"Layer_slotArrangeWithHp"},
        
        -- destroyTempleShop = {name = "灭神殿商店", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_destroyTempleShop"},
        -- destroyTempleShop = {name = "灭神殿商店", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_destroyTempleShop2"},


        -- sportsshop = {name = "竞技场商店", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_sports_shop"},

        champion = {name = "冠军试炼", top = {0,1,0,0}, resource = {}, delayupdate = false, module = require"Layer_champion"},
    
        passkillmain = {name = "过关斩将主页面", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_passkill_main"},
        passkillrank = {name = "过关斩将排行榜", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_passkill_rank"},

        wudaohui = {name = "武道会主界面", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_wudaohui_main"},

        -- fashion = {name = "时装",  top = {0,1,0,0},  resource = {"shizhuang/shizhuang"}, delayupdate = false,module = require"Layer_fashion"},
        -- gamestar = {name = "黄道十二宫",  top = {0,1,0,0},  resource = {"game/game"}, delayupdate = false,module = require"Layer_gamestar"},
        deployment = {name = "灵阵图",  top = {0,1,0,0},  resource = {"soulzhen/soulzhen"}, delayupdate = false,module = require"Layer_deployment"},        
        nightclub = {name = "夜总会主页",  top = {0,1,0,0},  resource = {"nightclub/nightclub_main"}, module = require"Layer_nightclub_main" },
        clubclubcell = {name = "夜总会店铺",  top = {0,1,0,0},  resource = {"nightclub/nightclub"}, module = require"Layer_nightclub_cell" },
        oneAddclub = {name = "一键夜总会",  top = {0,1,0,0},  resource = {"nightclub/nightclub_oneAdd"}, module = require"Layer_nightclub_oneAdd" },
        safemask = {name = "魔罩",  top = {0,1,0,0},  resource = {"safemask/safemask"}, delayupdate = false,module = require"Layer_safemask"},
        
        -- wingmain = {name = "主角翅膀",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_wing_main"},

        servicewarBefore = {name = "跨服战捐献",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_servicewar_before"},
        servicewarNow = {name = "跨服战",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_servicewar_now"},
        servicewarAfter = {name = "跨服战膜拜",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_servicewar_after"},

        october1st = {name = "十一活动", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_october1st"},
        playerreturn = {name = "魔王回归", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_playerreturn"},

        devourcollectup = { name = "魔宠图鉴升级",top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_devourcollect_up"},

        manor = {name = "藏经阁",  top = {0,1,0,0},  resource = {"cangjingge/cangjingge_zhuye"}, module = require"Layer_cangjingge_main" },

        guildboss = {name = "公会boss",  top = {0,1,0,0},  resource = {"gonghui2/gonghui_boss"}, module = require"Layer_guild2_boss" },
        gangbossrank = {name = "公会boss排行榜",  top = {0,1,0,0},  resource = {"gonghui2/gonghui_bossrank"}, module = require"Layer_guild2_boss_rank" },

        sevendayactivity = {name = "走向巅峰", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_sevendayactivity"},

        cp_dizaoshenhua = {name = "日常轮换缔造神话", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_cp_dizaoshenhua"},
        cp_tianxiawushuang = {name = "日常轮换天下无双", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_cp_tianxiawushuang"},

        shenlongxuyuan = {name = "神龙许愿", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_shenlongxuyuan"},
    
        -- zhounian = {name = "周年庆", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_activity_zhounian"},
        zhounian = {name = "7周年庆", top = {0,1,0,0},   delayupdate = true,resource = {}, module = require"Layer_activity_7zhounian"},
    
        bosschallenge = {name = "英雄挑战",  top = {0,1,0,0},  resource = {"bosschallenge/bosschallenge"}, module = require"Layer_bosschallenge" },
        bosschallenge_attack = {name = "英雄挑战攻打",  top = {0,1,0,0},  resource = {"bosschallenge/bosschallenge_attack"}, module = require"Layer_bosschallenge_attack" },

        -- 道馆守卫列表
        daoGuanMain = {name = "道馆守卫战", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_daoGuanMain"},
        -- 道馆守卫
        daoGuanList = {name = "道馆守卫列表", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_daoGuanList"},
        

        exclusiveArtifactUp = {name = "神器升级", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_exclusive_artifact_up"},
        jewel = {name = "宝石列表",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_jewelList"},
        artifactList = {name = "新神器列表",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactList"},
        artifactCreate = {name = "新神器锻造",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactCreate"},

        -- kingBattle_main = {name = "王者之战",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_KingBattle_main"},
        -- kingBattle_glory = {name = "王者荣耀",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_kingBattle_glory"},
        honorBattle = {name = "荣耀之战",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_honorBattle_main"},
        honorBattleArray = {name = "荣耀之战布阵",  top = {0,0,0,0},  resource = {}, delayupdate = true, module = require"Layer_honorBattle_Array"},
        
        artifact = {name = "新神器界面",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifact"},
        artifactBook = {name = "新神器图鉴",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactBook"},
        artifactCheck = {name = "新神器鉴定",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactCheck"},
        artifactMount = {name = "新神器镶嵌",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactMount"},
        -- 神器强化
        artifactStrengthen = {name = "神器强化",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactStrengthen"},
        artifactWash = {name = "神器洗练",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactWash"},
       
        hellcopy = {name = "地狱副本", top = {0,1,0,0},   resource = {}, shiftDirect = true, module = require"Layer_copy_hell"},
    
        zhongqiuactivity = {name = "中秋活动", top = {0,1,0,0}, delayupdate = true, resource = {}, module = require"Layer_activity_zhongqiu"},

        antiqueAuction = {name = "古董拍卖", top = {0,1,0,0},   resource = {}, shiftDirect = true, module = require"Layer_antiqueAuction"},

        partnerfashion_collect = {name = "时装图鉴", top = {0,1,0,0}, resource = {}, module = require"Layer_partnerfashion_collect"},
        artifactSkillSwop = {name = "新神器技能互换",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactSkillSwop"},
        babelTower = {name = "通天塔",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_babelTower"},
        babelTowerLevel = {name = "通天塔关卡",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_babelTowerLevel"},
        -- generalFeiSheng = {name = "主角飞升",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_generalFeiSheng"},
       
        blessingCave = {name = "福祉仙洞",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_blessingCave"},
        change = {name = "转换", top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_change"},
        godSoulTemple = {name = "神魂殿", top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_godSoulTemple"},
        godSoulTempleRefineSoul = {name = "神魂殿", top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_godSoulTempleRefineSoul"},
        godSoulTempleCuishen = {name = "神魂殿粹神", top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_godSoulTempleCuishen"},
        examination = {name = "三届联考",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_examination"},
        xuanyueTreasures = {name = "玄月秘宝",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_xuanyueTreasures"},
        xuanyueTreasures2 = {name = "玄月秘宝复制",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_xuanyueTreasures2"},
        xuanyueTreasures3 = {name = "玄月秘宝3",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_xuanyueTreasures3"},

        ancientRuins = {name = "上古遗迹",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_ancientRuins"},
        artifactSkillStrengthen = {name = "新神器强化转移",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_artifactSkillStrengthen"},
        gameHelper = {name = "游戏助手",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_gameHelper"},
	
    	limitedset = {name = "限时玩法",top = {0,0,0,0},resource = {},delayupdate = true, module = require"Layer_limitedset"},
        guildActivity = {name = "公会活动",top = {0,0,0,0},resource = {},delayupdate = true, module = require"Layer_guildActivity"},
        
        --先删除 后创建
        guildfeast = {name = "公会盛宴",firstremove = true,top = {0,1,0,0}, nobottom = true,delayupdate = false, resource = {"gonghui3/gonghui_shengyan"}, module = require"Layer_guild_feast" },

        illusion   = {name = "幻化", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_illusion"},

        qiLingBag   = {name = "器灵背包", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_qiLingBag"},
        qiLingRefining   = {name = "器灵熔炼", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_qiLingRefining"},
        exclusiveArtifact = {name = "专属神器", top = {0,1,0,0},   resource = {}, delayupdate = true, shiftDirect = true,module = require"Layer_exclusiveArtifact"},
	
	    exclusiveArtifactCopy = {name = "专属神器副本",top = {0,1,0,0},resource = {},delayupdate = true,module = require"Layer_ExclusiveArtifactCopy"},
    
        tokenMain = {name = "天机令主页", top = {0,1,0,0}, resource = {}, delayupdate = true, shiftDirect = true, module = require"Layer_token_main"},

        tokenBag = {name = "天机令背包", top = {0,1,0,0}, resource = {}, delayupdate = true, module = require"Layer_tokenBag"},

    
        --封神赛
        godCompetitionMain = {name = "封神赛",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_godCompetition_main"},
        godCompetitionSlotsInfo = {name = "封神赛布阵",top = {0,0,0,0},resource = {},delayupdate = false,module = require"Layer_GodCompetition_slotsInfo"},
        godCompetitiondeployment = {name = "灵阵图",  top = {0,1,0,0},  resource = {"soulzhen/soulzhen"}, delayupdate = false,module = require"Layer_godCompetitionDeployment"},        
        godCompetitionSlotsDetail = {name = "封神赛阵容预览",  top = {0,0,0,0},  resource = {}, delayupdate = false,module = require"Layer_GodCompetition_slotsDetail"},        
        --小游戏
        minigame = {name = "小游戏",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_minigame_main"},

        --升仙台
        ascensionSendai = {name = "升仙台",  top = {0,1,0,0},  resource = {}, delayupdate = true, module = require"Layer_ascensionSendai_main"},
        ascensionSendaiSlot = {name = "升仙台点仙",  top = {0,0,0,0},  resource = {}, delayupdate = true, module = require"Layer_ascensionSendai_slotArrange"},
        ascensionSendaiSlot2 = {name = "升仙台布阵",  top = {0,0,0,0},  resource = {}, delayupdate = true, module = require"Layer_ascensionSendai_specialSlot"},

    },


    templayers = {
        other_slotinfo = require"Layer_slotsinfo_other",

    },
    presenttemplayer = {},


    broadcastsDefaultIndex = 1,
    broadcastsDefault = {
        "欢迎进入神将道",
        "这里有最逗比的武将",
        "这里有最酷炫的技能",
        "这里有最欢乐的剧情",
    },
    serveBroadcast = myque.new(),


    hintconfig = {
        {
            name = "rootItems",
            config = {
                richang = {},
                shop = {11,41,42,253},
                slotinfo = {2,3,4,5,158,462},
                -- copy = {12,148,157,397,430},
                copy = {12,148,157,430},
                bag = {111,8},
            },
        },
    },

    newconfig = {
        richang = {parent = "rootItems",condition = {}},
        zhenrong = {parent = "rootItems",condition = {462}},
    },
}

function gameScene.makenewconfig(self)
    for k ,v in pairs(gamedata.config.daily) do
        table.insert(self.newconfig.richang.condition,v.systemid)
        table.insert(self.hintconfig[1].config.richang,v.systemid)
    end

    for k,v in pairs(gamedata.config.activity_time) do
        if v.systemid and v.systemid ~= 0 and v.systemid ~= 377 then
            table.insert(self.layers["main"].module.newconfig["huodong"..v.type].condition,v.systemid)
        end
    end
end

function gameScene.reloadNew(self)
    self:setNew(self)
    if self.presentLayer then
        self:setNew(self.layers[self.presentLayer].module)
    end
end

function gameScene.setNew(self,module)
    if not self.roleinfo then return end
    if not module.rootItems then return end
    if module.newconfig then
        print("gameScene.setNew")
        --printT(module.newconfig)
        for k,v in pairs(module.newconfig) do
            module[v.parent]["new_"..k]:removeAllChildrenWithCleanup(true)
            for kk,vv in ipairs(v.condition) do
                if guide.controller then
                    if guide.controller:isNewSystemByid(vv) and self:checkopenlevelbyId(vv,true) then
                        local ccb,Items = CCBReaderLoad("talk/new", nil, true, "new")
                        module[v.parent]["new_"..k]:addChild(ccb)
                    end
                end
            end
        end
    end

    if self.presentLayer == "main" then
        if self.roleinfo and next(self.roleinfo) and self.roleinfo.id then
            local _wudaohuiRewardPreview = CCUserDefault:sharedUserDefault():getBoolForKey("wudaohuiRewardPreview"..self.roleinfo.id)

            if _wudaohuiRewardPreview then
                self.layers["main"].module["rootItems"]["new_huodong3"]:removeAllChildrenWithCleanup(true)
                local ccb,Items = CCBReaderLoad("talk/new", nil, true, "new")
                self.layers["main"].module["rootItems"]["new_huodong3"]:addChild(ccb)
            end
        end
    end

    if self.presentLayer then
        if self.presentLayer == "activity" then
            if self.layers[self.presentLayer].module.NavigationTableView then
                self.layers[self.presentLayer].module.NavigationTableView:reloadData()
            end
        end
    end
end

function gameScene.UICacheReset(self)
    GameScene.layers["copy_chapter"].module.activitydata = nil
    GameScene.layers["copy_chapter"].module.stardata = nil
    GameScene.layers["copy_chapter"].module.hadesdata = nil
    GameScene.layers["copy_chapter"].module.normaldata = nil
    GameScene.layers["copy_map"].module.normaldata = nil

    GameScene.layers["shopList"].module.propsData = nil
    GameScene.layers["shopList"].module.giftData = nil

    GameScene.layers["sports2"].module.rankData ={}
    GameScene.layers["sports2"].module.top10Data ={}
    GameScene.layers["sports2"].module.rewardData ={}

    GameScene.layers["friends"].module.frinedData ={}
    GameScene.layers["friends"].module.recomendData ={}
    GameScene.layers["friends"].module.reqData ={}
    GameScene.layers["friends"].module.shieldData ={}

    GameScene.layers["task"].module.itemdata ={}
    GameScene.layers["task"].module.normaldata ={}

    GameScene.layers["cup"].module.statusdata ={}
    GameScene.layers["cup"].module.topsdata ={}
    GameScene.layers["cup"].module.rankdata ={}

    GameScene.layers["babelTowerLevel"].module.levelIndex = 1

    GameScene.layers["activity"].module.dailyCpActivityTimeStatus = {}

    CCUserDefault:sharedUserDefault():setStringForKey("vipGift_localInfoString"..GameScene.roleinfo.id, "") 



    CCUserDefault:sharedUserDefault():setStringForKey("lianhun_FirstString"..GameScene.roleinfo.id.."_18", "") 
    CCUserDefault:sharedUserDefault():setStringForKey("lianhun_FirstString"..GameScene.roleinfo.id.."_20", "") 
    CCUserDefault:sharedUserDefault():setStringForKey("lianhun_FirstString"..GameScene.roleinfo.id.."_23", "")

    CCUserDefault:sharedUserDefault():setStringForKey("cuishen_FirstString"..GameScene.roleinfo.id.."_20", "") 
    CCUserDefault:sharedUserDefault():setStringForKey("cuishen_FirstString"..GameScene.roleinfo.id.."_23", "") 
end

function gameScene.UpdatePresentLayer(self,isreset)

    print("界面 = ",self.presentLayer, isreset)
    if self.presentLayer and GameScene.layers[self.presentLayer] and GameScene.layers[self.presentLayer].show and GameScene.layers[self.presentLayer].module.UIUpdateData then
        GameScene.layers[self.presentLayer].module:UIUpdateData(isreset)
    elseif self.presentLayer == "rob" then
        GameScene:checkUpdate(11112)
        GameScene:checkUpdate(11111)
    elseif self.presentLayer == "encounter2" then
        GameScene:checkUpdate(1310)
    elseif self.presentLayer == "main" and isreset then
        UIRequest({type = 117})
        UIRequest({type = 2037})
        UIRequest({type = 13101})
        UIRequest({type = 36101})
    elseif self.presentLayer == "mail" and isreset then
        UIRequest({type =3100})
    elseif self.presentLayer == "activity" and isreset then
        print("activity.isreset===")
        UIRequest({type = 2000,page =GameScene.layers["activity"].module.type})
        for k,v in ipairs(GameScene.layers["activity"].module.realPageTable) do
            if v.request then
                UIRequest({ type = v.request })
            end
        end
    elseif self.presentLayer == "cup" and isreset then

        if GameScene.layers["cup"].show then
            GameScene.layers["cup"].module:shiftPage(GameScene.layers["cup"].module.selectpage)
        end
    elseif self.presentLayer == "babelTowerLevel" and isreset then
        if GameScene.layers["babelTowerLevel"].show then
            GameScene.layers["babelTowerLevel"].module:forcedExitLevel()
        end
    elseif self.presentLayer == "babelTower" and isreset then
        if GameScene.layers["babelTower"].show then
            UIRequest({type = 7011})
        end
    elseif self.presentLayer == "blessingCave" and isreset then
        if GameScene.layers["blessingCave"].show then
            UIRequest({type = 6520})
        end
    elseif self.presentLayer == "examination" and isreset then
        if GameScene.layers["examination"].show then
            UIRequest({type = 7002})
        end
    elseif self.presentLayer == "ancientRuins" and isreset then
        UIRequest({type=7080})
    elseif self.presentLayer == "xuanyueTreasures" and isreset then
        UIRequest({type=7060})
    elseif self.presentLayer == "xuanyueTreasures2" and isreset then
        UIRequest({type=7063})
    elseif self.presentLayer == "xuanyueTreasures3" and isreset then
        UIRequest({type=7072})
    elseif self.presentLayer == "gameHelper" and isreset then
        if GameScene.layers["gameHelper"].show then
            GameScene.layers["gameHelper"].module:UIReset()
        end
    elseif self.presentLayer == "guildActivity" and isreset then
        if gameWindows.windows["openzaotanginfo"].show then
            UIRequest({type = 2281})
        end

        if gameWindows.windows["openfeastinfo"].show then
            UIRequest({type = 2271})
        end
    elseif self.presentLayer == "exclusiveArtifactCopy" and isreset then
        if GameScene.layers["exclusiveArtifactCopy"].show then
            UIRequest({type = 8201})
        end
    elseif self.presentLayer == "godCompetitionMain" and isreset then
        if GameScene.layers["godCompetitionMain"].show then
            UIRequest({type = 8250})
        end
    elseif self.presentLayer == "ascensionSendai" and isreset then
        if GameScene.layers["ascensionSendai"].show then
            GameScene.layers["ascensionSendai"].module.cellItems = nil
            UIRequest({type = 8851})
        end
    elseif self.presentLayer == "ascensionSendaiSlot" and isreset then
        GameScene:shiftLayer("ascensionSendai")
    elseif self.presentLayer == "ascensionSendaiSlot2" and isreset then
        GameScene:shiftLayer("ascensionSendai")
    end
end


function gameScene.addUpdate(self,type,param)
    self.updateTable[type..(param or "")] = true
    if type == 1002 then
        self.updateTable[5901] = true
    end
    if self.updateRelation[type..(param or "")] then
        for k,v in pairs(self.updateRelation[type..(param or "")]) do
            self:addUpdate(v)
        end
    end
end

function gameScene.checkUpdate(self,type,param,norequest)

    print("checkUpdate",type..(param or ""))
    if self.updateTable[type..(param or "")] then
        if not norequest then
            UIRequest({type = tonumber(type), param = param})
        end
        self.updateTable[type..(param or "")] = nil
        print(true)
        return true
    end
    print(false)
    return false
end

function gameScene.addtempLayers(self,name,param,toppos,index)

    local ext = ""
    if index and index == 2 then
        ext = "2"
    end

    self.rootItems["tempnode"..ext]:setPosition(ccp(540,-1920))

    self.templayers[name]:init(self.rootItems["templayernode"..ext],toppos or self.topposY,param,index)
    if self.templayers[name].pageconfig and self.templayers[name].pagename then
        self.templayers[name].rootItems.bgsprite:setZOrder(2)
        self:setLayerpageshift(self.templayers[name],self.templayers[name],-139)
        self:shiftlayerpage(self.templayers[name],self.templayers[name],self.templayers[name].selectpage)
    end
    local moveTo = CCMoveTo:create(0.3, ccp(540, 0))
    local backOut = CCEaseExponentialOut:create(moveTo)
    local seq = CCSequence:createWithTwoActions(backOut, CCCallFunc:create(function()

    end))
    self.rootItems["tempnode"..ext]:runAction(backOut)
    self.presenttemplayer[name] = index and tostring(index) or ""
end

function gameScene.removetempLayers(self,name)
    if not name then return end
    local moveTo = CCMoveTo:create(0.3, ccp(540, -1920))
    local backOut = CCEaseExponentialOut:create(moveTo)
    local seq = CCSequence:createWithTwoActions(backOut, CCCallFunc:create(function()
        self.templayers[name]:clear()
        self.rootItems["templayernode"..self.presenttemplayer[name]]:removeAllChildrenWithCleanup(true)
        self.presenttemplayer[name] = nil
    end))
    self.rootItems["tempnode"..self.presenttemplayer[name]]:runAction(seq)
end

function gameScene.removealltempLayers(self)
    for k,v in pairs(self.presenttemplayer) do
        self:removetempLayers(k)
    end
end


function gameScene.palyBroadcast(self)
    self.rootItems.broadcastinfo:setPositionX(self.viewSize.width)

    if myque.empty(self.serveBroadcast) then
        self.rootItems.broadcastinfo:setString(self.broadcastsDefault[self.broadcastsDefaultIndex])
        self.broadcastsDefaultIndex = self.broadcastsDefaultIndex + 1
        if self.broadcastsDefaultIndex == 5 then
            self.broadcastsDefaultIndex = 1
        end
    else
        self.rootItems.broadcastinfo:setString(myque.pop(self.serveBroadcast))
    end

    local moveTo = CCMoveTo:create(16, ccp(0 - self.rootItems.broadcastinfo:getContentSize().width, self.rootItems.broadcastinfo:getPositionY()))

    local seq = CCSequence:createWithTwoActions(moveTo, CCCallFunc:create(function()
        self:palyBroadcast()
    end))
    self.rootItems.broadcastinfo:runAction(seq)
end

function gameScene.arrangeTop(self,topdata,nobottom)
    local height = 0
    for k,v in ipairs(self.topconfig) do

        if topdata[k] and topdata[k] == 1  then
            if k ~= 4 then
                height = height - v.height
            end
            self.rootItems[v.name]:setPosition(ccp(0, height))
            self.rootItems[v.name]:setVisible(true)
--            local moveTo = CCMoveTo:create(0.3, ccp(0, height))
--            local backOut = CCEaseExponentialOut:create(moveTo)
--            self.rootItems[v.name]:stopAllActions()
--            self.rootItems[v.name]:runAction(backOut)
        else
            self.rootItems[v.name]:setPosition(ccp(0, 0))
            self.rootItems[v.name]:setVisible(false)
--            local moveTo = CCMoveTo:create(0.3, ccp(0, 0))
--            local backOut = CCEaseExponentialOut:create(moveTo)
--            self.rootItems[v.name]:stopAllActions()
--            self.rootItems[v.name]:runAction(backOut)
        end
    end

    self.rootItems.MainSceneBottomNode:setPositionY(nobottom and -300 or 0)


    return height
end

function  gameScene.shiftlayerpage(self,configmodule,itemmodule,page)

    for km,vm in ipairs(configmodule.pageconfig) do
        if vm == page then
            setSpriteFrameByName(itemmodule.rootItems["buttonsprite"..km], gameConfig.images.pageButtonON)
            --itemmodule.rootItems["buttontext"..km]:setOpacity(255)
            itemmodule.rootItems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(itemmodule.rootItems["buttonsprite"..km], gameConfig.images.pageButtonOFF)
            --itemmodule.rootItems["buttontext"..km]:setOpacity(125)

            itemmodule.rootItems["buttonnode"..km]:setZOrder(0)


            --未开启置灰 点亮效果置灰
            if configmodule.pagebuild and configmodule.pagebuild[km] then
                local buildId = configmodule.pagebuild[km]
                if  self:checkopenlevelbyId(buildId,true) then
                    setSpriteFrameByName(itemmodule.rootItems["buttonsprite"..km], gameConfig.images.pageButtonOFF)
                else
                    setSpriteFrameByName(itemmodule.rootItems["buttonsprite"..km], gameConfig.images.pageButtonON)
                end
            end

        end
    end


    if guide.controller and page ~= nil and page ~= "" then
        guide.controller:NewSystem(ui.getSystemIdbykey(self.presentLayer..page))
    end

end

function gameScene.setLayerpageshift(self,configmodule,itemmodule,TouchPriority)
    for k=1,7 do
        if configmodule.pageconfig[k] then
            itemmodule.rootItems["buttontext"..k]:setVisible(true)
            itemmodule.rootItems["buttonsprite"..k]:setVisible(true)
            itemmodule.rootItems["buttontext"..k]:setString(configmodule.pagename[k])
            if not configmodule.pageScroll then
                itemmodule.rootItems["button"..k]:setSwallowsTouch(true)
            end
            itemmodule.rootItems["button"..k]:setTouchPriority(TouchPriority)
            itemmodule.rootItems["button"..k]:addHandleOfControlEvent(function()
                -- if gameTouch.ismove then return end
                if configmodule.pagebuild and configmodule.pagebuild[k] and not self:checkopenlevelbyId(configmodule.pagebuild[k]) then return end
                if not self:checkopenlevelbykey(self.presentLayer..configmodule.pageconfig[k]) then return end

                guide:setGuideProlayer(true)
                self:shiftlayerpage(configmodule,itemmodule,configmodule.pageconfig[k])
                configmodule:shiftPage(configmodule.pageconfig[k])
                if guide.controller then
                    guide.controller:UIComplete(8016)
                end

            end, CCControlEventTouchUpInside)
        else
            if not itemmodule.rootItems["buttontext"..k] then
            else
                itemmodule.rootItems["buttontext"..k]:setVisible(false)
                itemmodule.rootItems["buttonsprite"..k]:setVisible(false)
                itemmodule.rootItems["button"..k]:setTouchEnabled(false)
                --itemmodule.rootItems["button"..k]:addHandleOfControlEvent(function() end, CCControlEventTouchUpInside)
            end
        end

        --置灰
        if configmodule.pageconfig[k] and configmodule.pagebuild and configmodule.pagebuild[k] then
            local buildId = configmodule.pagebuild[k]
            if itemmodule.rootItems["buttonsprite"..k] then
                if  self:checkopenlevelbyId(buildId,true) then
                    ui.removeGray("CCSprite",itemmodule.rootItems["buttonsprite"..k])
                    ui.removeGray("CCLabelBMFont",itemmodule.rootItems["buttontext"..k])
                else
                    ui.addGray("CCSprite",itemmodule.rootItems["buttonsprite"..k])
                    ui.addGray("CCLabelBMFont",itemmodule.rootItems["buttontext"..k])
                end
            end
        end
    end
end

function gameScene.createLayer(self,layername,parent,param)
    if layername and layername ~= "" then
        if  self.layers[layername] then
            gamedata.music:ChangeLayer(layername)
            -- if MobClickCpp then
            --     MobClickCpp:beginLogPageView(layername)
            -- end
            if self.layers[layername].delayupdate then
                pauseUIUpdate()
            end

            if self.layers[layername].module.pageconfig and self.layers[layername].module.pagename and self.layers[layername].module.pagebuild then
                local pageconfig = {}
                local pagename = {}
                local pagebuild = {}

                for i,v in ipairs(self.layers[layername].module.pagebuild) do
                    if gameConfig:checkBuildOpen(v) then
                        table.insert(pageconfig,self.layers[layername].module.pageconfig[i])
                        table.insert(pagename,self.layers[layername].module.pagename[i])
                        table.insert(pagebuild,self.layers[layername].module.pagebuild[i])
                    end
                end

                self.layers[layername].module.pageconfig = pageconfig
                self.layers[layername].module.pagename = pagename
                self.layers[layername].module.pagebuild = pagebuild
            end
            
            local bcall,uirep = xpcall(function()
                self.layers[layername].module:init(parent,self.topposY+self:arrangeTop(self.layers[layername].top,self.layers[layername].nobottom),param)
            end,__G_TRACKBACK__)

            if self.layers[layername].module.pageconfig and self.layers[layername].module.pagename then
                if self.layers[layername].top[6] == 1 then
                    self:setLayerpageshift(self.layers[layername].module,self,-120)
                    self:shiftlayerpage(self.layers[layername].module,self,self.layers[layername].module.selectpage)
                else
                    self:setLayerpageshift(self.layers[layername].module,self.layers[layername].module,-120)
                    self:shiftlayerpage(self.layers[layername].module,self.layers[layername].module,self.layers[layername].module.selectpage)
                end
            end

            self.layers[layername].show = true

            self:setHint(self.layers[layername].module,layername)
            self:setNew(self.layers[layername].module)
        end
    end
end

function gameScene.removeLayer(self,layername)
    if layername and layername ~= "" then
        print("removeLayer==============",self.priorLayer,self.presentLayer)

        startUIUpdate()

        if  self.layers[layername] and  self.layers[layername].show then
            -- if MobClickCpp then
            --     MobClickCpp:endLogPageView(layername)
            -- end

            self.layers[layername].show = false
            self.layers[layername].module:clear()

            UPDATECACHE = 1
--            CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
--            CCTextureCache:sharedTextureCache():removeUnusedTextures()
        end
    end
end

function gameScene.shiftoutext(self)
--    if self.presentLayer == "chat" then
--        UIRequest({type = 10321,ids = {39,266,267}})
--    end
end

function gameScene.shiftLayer(self,layername,type,param)
    print("shiftLayer",layername)
    if not self.layers[layername] then runGamePrompt({msg = "功能未开启"}) return end
    if layername == self.presentLayer then return end

    if not self:checkopenlevelbykey(layername) then return end

    self:shiftoutext()

    gameTouch:clickprofbytime(0.3)

    if  self.priorLayer and self.layers[self.priorLayer].show then  self:removeLayer(self.priorLayer) end

    gameWindows:closeAllWindowDirect()
    self:removealltempLayers()

    ui.itemcache:detachAllSkeletons()

    if self.presentLayer == "chat" then
        UIRequest({type = 3012,method = 1})
        UIRequest({type = 3012,method = 2})
    end
    --print(self.priorLayer,self.presentLayer)
    self.priorLayer = self.presentLayer
    self.presentLayer = layername
    --print(self.priorLayer,self.presentLayer)

    if  self.layers[layername] then
        self.priorNode = self.presentNode
        self.presentNode = ui.createNode()
        self.rootItems.layernode:addChild(self.presentNode)


--        self.presentNode:setPosition(ccp(0,0))
--        self:removeLayer(self.priorLayer)
--        if self.priorNode then
--            self.priorNode:removeFromParentAndCleanup(true)
--            self.priorNode = nil
--        end
--        self:createLayer(self.presentLayer,self.presentNode,param)
    
    

        if not type or self.layers[layername].shiftDirect then
            self.presentNode:setPosition(ccp(0,0))

            --篝火盛宴先删除后创建 共用layer_guildchat 导致
            if self.layers[layername].firstremove then
                self:removeLayer(self.priorLayer)
                self:createLayer(self.presentLayer,self.presentNode,param)
            else
                self:createLayer(self.presentLayer,self.presentNode,param)
                self:removeLayer(self.priorLayer)
            end

            
            
            if self.priorNode then
                self.priorNode:removeFromParentAndCleanup(true)
                self.priorNode = nil
            end
            self:guideUIComplete(self.presentLayer)
        elseif type == "up" then
            self.presentNode:setZOrder(1)
            if self.priorNode then
                self.priorNode:setZOrder(0)
            end

            self.presentNode:setPosition(ccp(0,0))
            self:createLayer(self.presentLayer,self.presentNode,param)
            self.presentNode:setPosition(ccp(0,-self.viewSize.height))

            print(self.priorLayer)


            local moveTo = CCMoveTo:create(0.2, ccp(0, 0))
            local backOut = CCEaseExponentialOut:create(moveTo)
            local seq = CCSequence:createWithTwoActions(backOut, CCCallFunc:create(function()
                self:removeLayer(self.priorLayer)

                if self.priorNode then
                      self.priorNode:removeFromParentAndCleanup(true)
                      self.priorNode = nil
                end

                self:guideUIComplete(self.presentLayer)

            end))
            self.presentNode:runAction(seq)

        elseif type == "down" then
            self.presentNode:setZOrder(0)
            if self.priorNode then
                self.priorNode:setZOrder(1)
            end
            self.presentNode:setPosition(ccp(0,0))

            self:createLayer(self.presentLayer,self.presentNode,param)
            local moveTo = CCMoveTo:create(0.2, ccp(0,-self.viewSize.height))
            local backOut = CCEaseExponentialOut:create(moveTo)
            local seq = CCSequence:createWithTwoActions(backOut, CCCallFunc:create(function()
                self:removeLayer(self.priorLayer)
                if self.priorNode then
                    self.priorNode:removeFromParentAndCleanup(true)
                    self.priorNode = nil
                end
                self:guideUIComplete(self.presentLayer)
            end))
            self.priorNode:runAction(seq)
        end
    end

    if guide.controller and layername ~= "lead" then
        guide.controller:NewSystem(ui.getSystemIdbykey(layername))
    end

    self:move_xdi(layername)
    
    -- 材质显示
    print("dumpCachedTextureInfo==01")
    --CCTextureCache:sharedTextureCache():dumpCachedTextureInfo()
    print("dumpCachedTextureInfo==02")
end

function gameScene.guideUIComplete(self,layername)
    if not guide.controller then return end
    if layername == "copy_map" then
        guide.controller:UIComplete(8011)
    elseif layername == "task" then
        guide.controller:UIComplete(8012)
    elseif layername == "main" then
        guide.controller:UIComplete(8001)
    elseif layername == "copy_chapter" then
        guide.controller:UIComplete(8010)
    elseif layername == "generals" then
        guide.controller:UIComplete(8111)
    elseif layername == "slotsInfo" then
        guide.controller:UIComplete(8018)
    elseif layername == "activity" then
        guide.controller:UIComplete(8002)
    elseif layername == "equips" then
        guide.controller:UIComplete(8019)
--    elseif layername == "encounter2" then
--        guide.controller:UIComplete(8022)
    elseif layername == "lead" then
        guide.controller:UIComplete(8041)
    elseif layername == "mail" then
        guide.controller:UIComplete(8020)
    elseif layername == "generalup" then
        guide.controller:UIComplete(8015)
    elseif layername == "bloodbattle" then
        guide.controller:UIComplete(8070)
    elseif layername == "treasureup" then
        guide.controller:UIComplete(8071)
    elseif layername == "penglai" then
        guide.controller:UIComplete(8072)
    elseif layername == "starcopy_map" then
        guide.controller:UIComplete(8074)
    elseif layername == "devilBag" then
        guide.controller:UIComplete(8075)
    elseif layername == "slotarrange" then
        guide.controller:UIComplete(8076)
    elseif layername == "singleboss" then
        guide.controller:UIComplete(8077)
    elseif layername == "devil" then
        guide.controller:UIComplete(8078)
    elseif layername == "equipsup" then
        guide.controller:UIComplete(8079)
    elseif layername == "hadescopy_map" then
        guide.controller:UIComplete(8081)
    end
end

function gameScene.checkopenlevelbykey(self,key,nopromt)
     if not (self.roleinfo and self.roleinfo.level) then
         return false
     end
     local config = gamedata.config.build_key[tostring(key)]
     if config and self.roleinfo.level < config.level then
         if nopromt then return false end
         runGamePrompt({msg = "等级不足，"..config.level.."级开启，努力升级吧！！"})
         return false
     end
     return true
end

function gameScene.checkopenlevelbyId(self,id,nopromt)
    if not (self.roleinfo and self.roleinfo.level) then
        return false
    end
    local config = gamedata.config.build[tostring(id)]

    if config and config.switch ~= 1 then
        if nopromt then return false end
        runGamePrompt({msg = "功能未开启"})
        return false
    end

    if config and self.roleinfo.level < config.level then
        if nopromt then return false end
        runGamePrompt({msg = "等级不足，"..config.level.."级开启，努力升级吧！！"})
        return false
    end
    return true
end

function gameScene.shiftLayerById(self,id,param)
    print("shiftid==",id)
    if not self:checkopenlevelbyId(id) then return end
    local config = gamedata.config.build[tostring(id)]
    printT(config)

    gameWindows:closeAllWindowDirect()

    if tonumber(id) == 170 then
        self:shiftLayer("collect","up","recommend")
    elseif tonumber(id) == 450 then
        UIRequest({type = 7011})
    elseif tonumber(id) == 463 then
        self:shiftLayer("blessingCave","up","recommend")
    elseif tonumber(id) == 613 then
        self:shiftLayer("exclusiveArtifactCopy","up","recommend")
    elseif tonumber(id) == 308 then
        UIRequest({type = 4907})
    elseif tonumber(id) == 634 then
        self:shiftLayer("godCompetitionMain","up")
    elseif config.type == "layer" then
        self:shiftLayer(config.key,"up",param)
    elseif config.type == "request" then
        if config.param1 and config.param1 ~= "" then
            UIRequest({type = tonumber(config.key), param=config.param1})
        else
            UIRequest({type = tonumber(config.key)})
        end
    elseif config.type == "activity" then
        if config.param1 and config.param1 ~= "" then
            local type = tostring(gamedata.config.activity_time[tostring(config.param1)].type)
            if self.presentLayer == "activity" and type == self.layers.activity.module.type then
                self.layers.activity.module:setPageByid(config.param1)
            else
                UIRequest({type = config.key, param=config.param1,page = type})
            end
        else
            UIRequest({type = config.key,page = tonumber(config.param2)})
        end
    elseif config.type == "activitysub" then
        if config.param2 and config.param2 ~= "" then
            local activityId = gamedata.config.build[tostring(config.param2)].param1
            local type = tostring(gamedata.config.activity_time[tostring(activityId)].type)
            if self.presentLayer == "activity" and type == self.layers.activity.module.type then
                self.layers.activity.module:setPageByid(tonumber(activityId),tonumber(config.param1))
            else
                UIRequest({type = config.key, param=activityId,page = type,pageId = tonumber(config.param1)})
            end
        else
            runGamePrompt({mag = "配置表异常"..config.id})
        end
    elseif config.type == "layersub" then
        if self.presentLayer == config.param1 then
            self.layers[config.param1].module:shiftPage(config.key)
        else
            self.layers[config.param1].module[config.param2] = config.key
            self:shiftLayer(config.param1,"up",param)
        end
    elseif config.type == "copy_chapter" then
        if config.key == "activity" then
            if self.presentLayer == "copy_chapter" then
                self.layers.copy_chapter.module:shiftPage(config.key)
            else
                self.layers.copy_chapter.module[config.param2] = config.key
                self:shiftLayer("copy_chapter","up")
            end
        elseif param and param ~= "" then
            local i = string.find(param,",")
            local map,point
            if i then
                map,point = ui.getIDandNUM(param)
            else
                map = tonumber(param)
            end

            local mapmax, pointmax = ui.getCopyProcess(config.key)
            if ui.isCopyOpen(map,point,mapmax, pointmax) then
                local section = math.ceil((map-42100)/5)
                if self.presentLayer == "copy_chapter" then
                    self.layers.copy_chapter.module:setParam({
                        datatype= config.key,
                        section = section,
                    })
                    self.layers.copy_chapter.module:reloaddata()
                else
                    self:shiftLayer("copy_chapter","up",{
                        datatype= config.key,
                        section = section,
                    })
                end

            else
                runGamePrompt({mag = "关卡未开启"})
            end
        else
            if self.presentLayer == "copy_chapter" then
                self.layers.copy_chapter.module:setParam({
                    datatype= config.key,
                })
                self.layers.copy_chapter.module:reloaddata()
            else
                self:shiftLayer("copy_chapter","up",{
                    datatype= config.key,
                })
            end
        end

    elseif config.type == "copy_map" then
        local i = string.find(param,",")
        local map,point
        if i then
            map,point = ui.getIDandNUM(param)
        else
            map = tonumber(param)
        end

        local mapmax, pointmax = ui.getCopyProcess(string.sub(config.key,5,string.len(config.key)))
        print(mapmax, pointmax)
        if ui.isCopyOpen(map,point,mapmax, pointmax) then
            local section = math.ceil((map-42100)/5)
            local mapid = math.mod((map-42100),5)
            if mapid ==0 then mapid = 5 end

            if self.presentLayer == "copy_map" then
                self.layers.copy_map.module:setParam({
                    datatype = string.sub(config.key,5,string.len(config.key)),
                    section=section,
                    map = mapid,
                    point = point
                })
                self.layers.copy_map.module:reloaddata()
            else
                self:shiftLayer("copy_map","up",{
                    datatype = string.sub(config.key,5,string.len(config.key)),
                    section=section,
                    map = mapid,
                    point = point
                })
            end
        else
            runGamePrompt({mag = "关卡未开启"})
        end


    elseif config.type == "window" then
        if config.param1 and config.param1 ~= "" then
            gameWindows:openWindow(config.key,{}, nil)
        else
            gameWindows:openWindow(config.key,{},nil)
        end
    elseif config.type == "function" then
        if config.param1 == "generals" or config.param1 == "equips" then
            if config.key and config.key ~= "" then
                self.layers[config.param1].module[config.param2] = config.key
            end

            GameScene:shiftLayer(config.param1,"up")
        elseif config.param1 == "slotsInfo" then
            if config.key == "slot" then
                GameScene:shiftLayer("slotsInfo","up",{sid = tonumber(config.param2)})
            elseif config.key == "cheer" or config.key == "mofu" then
                GameScene:shiftLayer("slotsInfo","up",{sid = config.key})
            elseif config.key == "soul" then
                GameScene:shiftLayer("slotsInfo","up",{status = "soul"})
            end
        end
    elseif config.type == "startactivity" then
        GameScene:shiftLayer("startactivity","up")
    elseif config.type == "october1st" then
        GameScene:shiftLayer("october1st","up")
    end
end

function gameScene.setOptProfEnabled(self,bool)
    self.rootItems.optprof:setTouchEnabled(bool)
end

function gameScene.levelUprequest(self)
    --UIRequest({type=999900, reqs= {1002,10211}})
    UIRequest({type = 1002})
    --UIRequest({type = 10211})
    UIRequest({type = 2094,update = true})
    UIRequest({type = 7091,update = true})

    if self:checkopenlevelbyId(49,true) then
        UIRequest({type = 1047,updata = true})
    end



    GameScene:addUpdate(10021)
    GameScene:addUpdate(10211)

    UIRequest({type = 10322})

    UIRequest({type = 1001,param = "resume"})
    UIRequest({type = 2000,param2 = true})
    self:checkWudaohuiRewardNew()
    self:setNew(self)
    self:setNew(self.layers[self.presentLayer].module)
end

function gameScene.checkWudaohuiRewardNew(self)
    if self.roleinfo and next(self.roleinfo) and self.roleinfo.id then
        local _xiandouShopConfig = table.copy(gamedata.config.xiandou_shop)

        for i = 1, table.getTableLength(_xiandouShopConfig) do
            for ii = 1, table.getTableLength(_xiandouShopConfig[tostring(i)]) do
                if _xiandouShopConfig[tostring(i)][tostring(ii)].level_min == self.roleinfo.level then
                    CCUserDefault:sharedUserDefault():setBoolForKey("wudaohuiRewardPreview"..self.roleinfo.id, true)
                    return
                end
            end
        end
    end
end



function gameScene.initrequest(self,order)

    --    UIRequest({type = 1001}) --玩家信息
    --    UIRequest({type = 300}) --VIP状态信息
    --    UIRequest({type = 117}) --VIP信息
    --    UIRequest({type = 1002}) --基础信息
    --    UIRequest({type = 1012}) --武将魂魄
    --    UIRequest({type = 1200}) --道具信息
    --    UIRequest({type = 1107}) --装备碎片信息
    --    UIRequest({type = 2300}) --好友信息
    --    UIRequest({type = 1310}) --奇遇信息
    --    UIRequest({type = 1300}) --副本信息
    --    UIRequest({type = 1032}) --提示信息


    --UIRequest({type=999900, order = order,reqs= {1001,300,117,1200,1002,1012,1107,2300,1300,1330,3610,1032,1054,3200}})
end

function gameScene.cacheresetrequest(self,order)
    UIRequest({type=999900, order = order,reqs= {1001,300,2300,1300,3610,1032,3200,1031,{type=2000,param2=true},{type=8110,update=true}}})
end


function gameScene.toNormalScale(self)
    local scaleTo = CCScaleTo:create(0.5, self.scaleNum)
    local backOut = CCEaseExponentialOut:create(scaleTo)
    self.rootNode:runAction(backOut)
end

function gameScene.move_xdi(self,name)
    if not name then
        self.rootItems.sprite_xdi:setPositionX(0)
    elseif name == "slotsInfo" then
        self.rootItems.sprite_xdi:setPositionX(180)
    elseif name == "copy_chapter" then
        self.rootItems.sprite_xdi:setPositionX(360)
    elseif name == "daily" then
        self.rootItems.sprite_xdi:setPositionX(540)
    elseif name == "shopList" then
        self.rootItems.sprite_xdi:setPositionX(900)
    elseif name == "equips" then
        self.rootItems.sprite_xdi:setPositionX(720)
    elseif name == "main" then
        self.rootItems.sprite_xdi:setPositionX(0)
    end
end

function gameScene.clear(self)

    if self.presentLayer then
        self.layers[self.presentLayer].show = false
        self.layers[self.presentLayer].module:clear()
    end

    gameWindows:closeAllWindowDirect()
    self:removealltempLayers()

    if self.rootLayer then
        self.rootLayer:removeAllChildrenWithCleanup(true)
        self.rootLayer:removeFromParentAndCleanup(true)
        self.rootLayer = nil
    end
    self.rootNode = nil
    self.rootItems = nil

    self.presentNode = nil
    self.priorNode = nil
    self.roleinfo = nil

    self.updateTable = {}
    self.hintdata = nil
    self.titleHintData = nil
    self.vipeffect = nil
    self.vip = nil

    self.scaleNum  = 1
    self.bottomHeight = 0

    self.priorLayer = nil
    self.presentLayer = nil
    self.roletimer = nil

    self.presenttemplayer = {}

    self.broadcastsDefaultIndex = 1

    self.newconfig = {
        richang = {parent = "rootItems",condition = {}},
    }

end

function gameScene.makeLayerSubSwitch(self)
    for k,v in pairs(self.layers) do
        print("makeLayerSubSwitch",k)
        if v and  v.module and v.module.pageconfig then
            local newpageconfig = {}
            print(k)
            for kk,vv in ipairs(v.module.pageconfig) do
                if type(vv) =="string" and gamedata.config.build_key[k..vv] and gamedata.config.build_key[k..vv].switch ==0 then
                else
                    table.insert(newpageconfig,vv)
                end
            end
            v.module.pageconfig = newpageconfig
        end
    end
end

function gameScene.init(self,mainscene,callback,scale)

    print("gameScene.init--------------")

    --gamedata.music:GameStart()
    self:makenewconfig()
    self:makeLayerSubSwitch()

    self.rootLayer = CCLayerColor:create(ccc4(0,0,0,255))
    self.rootLayer:setColor(ccc3(0, 0, 0))
    self.rootLayer:setContentSize(CCSizeMake(self.d_viewSize.width, self.d_viewSize.height))
    self.rootLayer:setAnchorPoint(ccp(0,0))
    self.rootLayer:setPosition(ccp(0,0))
    mainscene:addChild(self.rootLayer,gameConfig.Zorder.gameScene)

    self.rootNode,self.rootItems = CCBReaderLoad("MainScene/MainSceneInfo", nil, true, "MainSceneInfo")
    self.rootNode:setPosition(self.d_viewSize.width/2,gameConfig.fixH or 0)
    self.rootLayer:addChild(self.rootNode)

    self.animationManager = getAnimationManager(self.rootItems)

    self.scaleNum = gameConfig.scaleNum
    self.topposY =  gameConfig.topposY
    self.rootNode:setScale(self.scaleNum*(scale or 1))

    if self.rootItems.bgsprite then self.rootItems.bgsprite:setPositionY(self.topposY/2) end

    self.rootItems.MainSceneTopNode:setPosition(ccp(self.viewSize.width/2,self.topposY))

    self.bottomHeight = self.rootItems.MainSceneBottomNode:getContentSize().height

    self.rootItems.mainbg:setPositionY((self.topposY-1620)*0.5-210)

    self.rootItems.MainCityButton:setSwallowsTouch(true)
    self.rootItems.MainCityButton:setTouchPriority(-450)
    self.rootItems.MainCityButton:addHandleOfControlEvent(function()
        print("点击主页")
        guide:setGuideProlayer(true)
        gameWindows:closeAllWindowDirect()
        self:shiftLayer("main","down")

        print("lua memory",collectgarbage("count"))
--        if self.priorLayer ~= "main" then
--            UIRequest({type = 1032}) --提示信息
--        end
    end, CCControlEventTouchUpInside)

    self.rootItems.mainslot:setSwallowsTouch(true)
    self.rootItems.mainslot:setTouchPriority(-450)
    self.rootItems.mainslot:addHandleOfControlEvent(function()
        print("点击阵容")
        guide:setGuideProlayer(true)
        GameScene:shiftLayer("slotsInfo","up")

    --UIRequest({type = 999990})
    end, CCControlEventTouchUpInside)

    self.rootItems.maincopy:setSwallowsTouch(true)
    self.rootItems.maincopy:setTouchPriority(-450)
    self.rootItems.maincopy:addHandleOfControlEvent(function()
 
        guide:setGuideProlayer(true)
        GameScene:shiftLayer("copy_chapter","up",{datatype = "normal"})
        UIRequest({type = 999901,id=14})
    end, CCControlEventTouchUpInside)

    self.rootItems.mainday:setSwallowsTouch(true)
    self.rootItems.mainday:setTouchPriority(-450)
    self.rootItems.mainday:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily","up")
    end, CCControlEventTouchUpInside)

    self.rootItems.mainshop:setSwallowsTouch(true)
    self.rootItems.mainshop:setTouchPriority(-450)
    self.rootItems.mainshop:addHandleOfControlEvent(function()
        print("点击商城")
        guide:setGuideProlayer(true)
        GameScene:shiftLayer("shopList","up")
        UIRequest({type = 999901,id=12})
    end, CCControlEventTouchUpInside)
    self.rootItems.mianbag:setSwallowsTouch(true)
    self.rootItems.mianbag:setTouchPriority(-450)
    self.rootItems.mianbag:addHandleOfControlEvent(function()
        guide:setGuideProlayer(true)
        GameScene:shiftLayer("equips","up")
    end, CCControlEventTouchUpInside)

    self.rootItems.optprof:setSwallowsTouch(true)
    self.rootItems.optprof:setTouchEnabled(false)
    self.rootItems.optprof:setTouchPriority(-599)

    self.rootItems.tempprof:setSwallowsTouch(true)
    self.rootItems.tempprof:setTouchEnabled(true)
    self.rootItems.tempprof:setTouchPriority(-130)

    self.rootItems.tempprof2:setSwallowsTouch(true)
    self.rootItems.tempprof2:setTouchEnabled(true)
    self.rootItems.tempprof2:setTouchPriority(-300)

    self.rootItems.role_button:setSwallowsTouch(true)
    self.rootItems.role_button:setTouchPriority(-100)
    self.rootItems.role_button:addHandleOfControlEvent(function()

        UIRequest({type = 1001, param = "role_info"})
    end, CCControlEventTouchUpInside)

    self.rootItems.power_button:setSwallowsTouch(true)
    self.rootItems.power_button:setTouchPriority(-100)
    self.rootItems.power_button:addHandleOfControlEvent(function()
        gameWindows:openWindow("power_rule")
        
    end, CCControlEventTouchUpInside)

    --todo
    if self.rootItems.add_t and self.rootItems.add_t_s and self.rootItems.add_s and self.rootItems.add_s_s then
        self.rootItems.add_t:setSwallowsTouch(true)
        self.rootItems.add_t:setTouchPriority(-100)
        self.rootItems.add_t:addHandleOfControlEvent(function()
            local props = {}
            for k,v in pairs(GameScene.props or {}) do
                props[tostring(v.cid)] = v
            end
            gameWindows:openWindow("buypower",{props = props or {},id = 2})
        end, CCControlEventTouchUpInside)
        --
        self.rootItems.add_t_s:setSwallowsTouch(true)
        self.rootItems.add_t_s:setTouchPriority(-100)
        self.rootItems.add_t_s:addHandleOfControlEvent(function()
            local props = {}
            for k,v in pairs(GameScene.props or {}) do
                props[tostring(v.cid)] = v
            end
            gameWindows:openWindow("buypower",{props = props or {},id = 2})
        end, CCControlEventTouchUpInside)
        --
        self.rootItems.add_s:setSwallowsTouch(true)
        self.rootItems.add_s:setTouchPriority(-100)
        self.rootItems.add_s:addHandleOfControlEvent(function()
            local props = {}
            for k,v in pairs(GameScene.props or {}) do
                props[tostring(v.cid)] = v
            end
            gameWindows:openWindow("buypower",{props = props or {},id = 3})
        end, CCControlEventTouchUpInside)


        --
        self.rootItems.add_s_s:setSwallowsTouch(true)
        self.rootItems.add_s_s:setTouchPriority(-100)
        self.rootItems.add_s_s:addHandleOfControlEvent(function()
            local props = {}
            for k,v in pairs(GameScene.props or {}) do
                props[tostring(v.cid)] = v
            end
            gameWindows:openWindow("buypower",{props = props or {},id = 3})
        end, CCControlEventTouchUpInside)
    end
    --

    self.rootItems.vipbutton:setSwallowsTouch(true)
    self.rootItems.vipbutton:setTouchPriority(-100)
    self.rootItems.vipbutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("recharge",{pagetype = "vip"})
    end, CCControlEventTouchUpInside)
    --
    if self.roleinfo then
        self:setRoleInfo(self.roleinfo)
    else
        UIRequest({type = 1001})
    end
    --self:palyBroadcast()
    self:shiftLayer("main")
    self:reloadhint()
    self:reloadNew()
    --self:initrequest("gamescene")

    if not gameConfig:checkBuildOpen(154) then
        self.rootItems.vipnode:setVisible(false)
    else
        self.rootItems.vipnode:setVisible(true)
    end

    if guide.controller then
        guide.controller:RecoverGuideScene()
    end

    defaultIdCardStatus()

    --弹出公告
    self:initMainTip()
    self:runMainTip()

    if gameTimer then
        gameTimer:startheartCheck()
    end

    self:updateRenzheng()
    OnlinetimeRequest()
	
    self:setTitleHint()

    self:init_barrageScene()

end

function gameScene.init_barrageScene(self)
    if not self.barrageScene then
        self.barrageScene = require"Layer_guild_barrage"
        self.barrageScene:init(self.rootItems,self.topposY)
    end
end

function gameScene.runMainTip(self)
    if not (guide.controller == nil or next(guide.controller) ==nil or not guide.controller.isOnGuide) then
        return
    end

    self.tipindex = self.tipindex +1
    local tiptype = self.tips_order[self.tipindex]
    if not tiptype then
        return
    end

    local isShow = true
    local tipStr = CCUserDefault:sharedUserDefault():getStringForKey("tip_"..tiptype)
    if tipStr and tipStr ~= "" then
        local now = os.date("*t", gamedata:time())
        local _t = string.split(tipStr,"_")
        if tonumber(_t[1]) == 0 and tonumber(_t[2]) == now.year and tonumber(_t[3]) == now.month and tonumber(_t[4]) == now.day then
            isShow = false
        end
    end
    print("runMainTip",tiptype,isShow)
    if isShow then
        self.maintips[tiptype]()
    else
        self:runMainTip()
    end
end

function gameScene.isEndActivity(self,panelID)
    print("  isEndActivity  =",panelID)
    printT(gamedata.config.activity_time)
   local timediff = 0

   if gamedata.config.activity_time[tostring(panelID)]["open_type"] and gamedata.config.activity_time[tostring(panelID)]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time[tostring(panelID)]["continued_time"]+(gamedata.config.activity_time[tostring(panelID)]["days_later"] or 0)) - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < 0 then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time[tostring(panelID)]["continued_time"]+(gamedata.config.activity_time[tostring(panelID)]["days_later2"] or 0))- nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        end
    elseif gamedata.config.activity_time[tostring(panelID)]["end"] and gamedata.config.activity_time[tostring(panelID)]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time[tostring(panelID)]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    end

    self.isEnd = (timediff < 0)
    local isEnd = (timediff < 0)
    return isEnd
end 

function gameScene.initMainTip( self )
    self.tipindex = 0

    local callback = function()
        self:runMainTip()
    end

    local function tip_post()
        print("checkpost")
        if guide.controller == nil or next(guide.controller) ==nil or not guide.controller.isOnGuide then
            if gamedata.audit_state and gamedata.audit_state == "true" then
                callback()
            else
                userAccountCheck(function()
                    gameWindows:openWindow("post",nil,callback)
                end)
            end
        end
    end

    local function tip_god3()
        print("checkgod3")
        -- 三神推送
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timeEnd = GameScene.roleinfo.servertime + 86400*7 - temp.hour*3600 - temp.min*60 - temp.sec
        if timeEnd - nowtime > 10 then
            gameWindows:openWindow("threeGeneralPost",timeEnd,callback)
        else
            callback()
        end
    end



    local function tip_chongbang()
        print("checkchongbang-----")
        
        if GameScene.chongbangActivity and next(GameScene.chongbangActivity) then
            -- table.sort(GameScene.chongbangActivity)
            local curActivity = {}
            local obj = {};
            local curActivityID = 0
            -- activityRankConfig
            --  对活动弹窗重新定义打开顺序
            for i,v in ipairs(GameScene.chongbangActivity) do
                obj = {}
                curActivityID = 0
                if v == 406 then
                    obj.index = 1;
                    curActivityID = 124
                elseif v == 113 then
                    obj.index = 2;
                    curActivityID = 11
                elseif v == 370 then
                    obj.index = 3;
                    curActivityID = 104
                elseif v == 407 then
                    obj.index = 4;
                    curActivityID = 125
                elseif v == 405 then
                    obj.index = 5;
                    curActivityID = 123
                elseif v == 371 then
                    obj.index = 6;
                    curActivityID = 105
                elseif v == 408 then
                    obj.index = 7;
                    curActivityID = 126
                elseif v == 410 then
                    obj.index = 8;
                    curActivityID = 128
                elseif v == 409 then
                    obj.index = 9;
                    curActivityID = 127
                elseif v == 411 then
                    obj.index = 10;
                elseif v == 372 then
                    obj.index = 11;
                elseif v == 387 then
                    obj.index = 12;
                elseif v == 388 then
                    obj.index = 13;
                end
                obj.build_key = v;
                if curActivityID > 0 then
                    local isEnd = self:isEndActivity(curActivityID)
                    print("  isEnd  ",isEnd);
                    if isEnd == false then
                        table.insert(curActivity,obj)
                    end
                else
                    table.insert(curActivity,obj)
                end
            end
            if curActivity and next(curActivity) then
                ui.sortData(curActivity,"index")
                gameWindows:openWindow("openServerPost",{activityId = curActivity[#curActivity].build_key},callback)
            else
                callback()
            end    
        else
            callback()
        end
    end

    local function tip_timebag()
        print("checktimebag")
        -- 限时礼包
        UIRequest({type = 2882,opt=2,param="main"})
    end

    local function tip_fashion()
        print("checkfasion")
        if GameScene.fashionactivity3 and GameScene.fashionactivity3 == 1 then
            gameWindows:openWindow("fashionPost2",{opt = 3},callback)
        elseif GameScene.fashionactivity2 and GameScene.fashionactivity2 == 1 then
            gameWindows:openWindow("fashionPost2",nil,callback)
        elseif GameScene.fashionactivity and GameScene.fashionactivity == 1 then
            gameWindows:openWindow("fashionPost",nil,callback)
        else
            callback()
        end
    end

    local function tip_playerreturn()
        print("playerreturn")
        if GameScene.playerreturnactivity and GameScene.playerreturnactivity == 1 then
            gameWindows:openWindow("playerreturnPost",nil,callback)
        else
            callback()
        end
    end

    local function tip_vipUpgrade()
        print("checkvipup")
        if GameScene.vipup and gameConfig:checkBuildOpen(154) then
            gameWindows:openWindow("vipUpgrade", {vip = GameScene.vipup.vip}, callback)
            GameScene.vipup = nil
        else
            callback()
        end
    end

    local function tip_signin()
        print("checksignin")
        if gameConfig:checkBuildOpen(132) and GameScene:checkopenlevelbyId(132,true) then
            UIRequest({type = 3641, param = "main"})
        end
    end

    local function tip_playerback()
        print("checkplayerback")
        if gameConfig:checkBuildOpen(448) and GameScene:checkopenlevelbyId(448,true) then
            UIRequest({type = 6810, param = "main"})
        else
            callback()
        end
    end

    local function tip_discountGift()
        print("discountGift")
        if GameScene.discountgiftctivity and GameScene.discountgiftctivity > 0 then
            gameWindows:openWindow("disCountGiftPost",GameScene.discountgiftctivity,callback)
            GameScene.discountgiftctivity = 0
        else
            callback()
        end
    end

     local function tip_speedGift()
        print("speedGift")
        if GameScene.speedgiftctivity and GameScene.speedgiftctivity > 0 then

            if GameScene.speedgiftctivity == 153 then
                UIRequest({type = 8026, param = "main"})
            elseif GameScene.speedgiftctivity == 154 then
                UIRequest({type = 8028, param = "main"})
            elseif GameScene.speedgiftctivity == 155 then
                UIRequest({type = 8032, param = "main"})
            else
                callback()
            end
            GameScene.speedgiftctivity = 0
        else
            callback()
        end
    end


    local function tip_xueyuemibao()
        print("xueyuemibao")
        if gameConfig:checkBuildOpen(539) and GameScene:checkopenlevelbyId(539,true) then
            UIRequest({type = 7060, param = "main"})
        else
            callback()
        end

    end

    local function tip_xueyuemibao2()
        print("xueyuemibao2")
        if gameConfig:checkBuildOpen(559) and GameScene:checkopenlevelbyId(559,true) then
            UIRequest({type = 7063, param = "main"})
        else
            callback()
        end

    end

    local function tip_xueyuemibao3()
        print("xueyuemibao3")
        if gameConfig:checkBuildOpen(577) and GameScene:checkopenlevelbyId(577,true) then
            UIRequest({type = 7072, param = "main"})
        else
            callback()
        end

    end

    local function tip_hefuActivity()
        print("tip_hefuActivity")
        if gameConfig:checkBuildOpen(393) and GameScene:checkopenlevelbyId(393,true) then
            if GameScene.hefuactivityopen and GameScene.hefuactivityopen > 0 then
                UIRequest({type = 6105, param = "main"})
                GameScene.hefuactivityopen = 0
            else
                callback()
            end
        else
            callback()
        end

    end


    local function tip_sculpture()
        print("tip_sculpture")
        if GameScene.sculptureactivityopen and GameScene.sculptureactivityopen > 0 then
            gameWindows:openWindow("sculpturePost",nil,callback)
        else
            callback()
        end
    end

    self.maintips = {
        post            = tip_post,
        playerback      = tip_playerback,
        god3            = tip_god3,
        chongbang       = tip_chongbang,
        timebag         = tip_timebag,
        fashion         = tip_fashion,
        playerreturn    = tip_playerreturn,
        vipUpgrade      = tip_vipUpgrade,
        xueyuemibao     = tip_xueyuemibao,
        xueyuemibao2    = tip_xueyuemibao2,
        xueyuemibao3    = tip_xueyuemibao3,
        discountGift    = tip_discountGift,
        speedGift       = tip_speedGift,
        hefuActivity    = tip_hefuActivity,
        sculpture       = tip_sculpture,
        signin          = tip_signin,
    }

     self.tips_order = {
        "post",
        "playerback",
        "god3",
        "chongbang",
        "timebag",
        "fashion",
        "playerreturn",
        "vipUpgrade",
        "xueyuemibao",
        "xueyuemibao2",
	"xueyuemibao3",
        "discountGift",
        "speedGift",
        "hefuActivity",
        "sculpture",
        "signin",
    }

end

function gameScene.coin_effect(self,opt,positionX,positionY,time)
    -- opt==1 银币特效
    -- opt==2 元宝特效

    local time = time or 1
    local positionX = positionX and positionX-540 or 0
    local positionY = positionY and positionY-1920 or 0
    local pos1 = self.effect_pos1
    local pos2 = self.effect_pos2

    if self.rootItems.userinfo_s:isVisible() or self.rootItems.userinfo_b:isVisible() then
        if self.rootItems.userinfo_s:isVisible() then
            pos1 = self.effect_pos3
            pos2 = self.effect_pos4
        end
    end

    if opt and (opt == 1 or opt == 3) then
        self.rootItems.jinqianNode:setPosition(positionX or 0,positionY or 9999)
        self.rootItems.jinqianNode:setVisible(true)
        local moveto1 = CCMoveTo:create(time, pos1)
        self.rootItems.jinqianNode:runAction(CCSequence:createWithTwoActions(moveto1,CCCallFunc:create(function()
            self.rootItems.jinqianNode:setVisible(false)
            self.rootItems.jinqianNode:setPosition(0,9999)
            self:up_effect(1)
            self.rootItems.coin:setString(ui.makeshortnum(self.roleinfo.coin))
            self.rootItems.coin2:setString(ui.makeshortnum(self.roleinfo.coin))

            ui.setStringWithStroke(self.rootItems.coin,nil,10)
            ui.setStringWithStroke(self.rootItems.coin2,nil,10)
        end)))
    end

    if opt and (opt == 2 or opt == 3) then
        self.rootItems.yuanbaoNode:setPosition(positionX or 0,positionY or 9999)
        self.rootItems.yuanbaoNode:setVisible(true)
        local moveto2 = CCMoveTo:create(time, pos2)
        self.rootItems.yuanbaoNode:runAction(CCSequence:createWithTwoActions(moveto2,CCCallFunc:create(function()
            self.rootItems.yuanbaoNode:setVisible(false)
            self.rootItems.yuanbaoNode:setPosition(0,9999)
            self:up_effect(2)
            self.rootItems.gold:setString(self.roleinfo.gold)
            self.rootItems.gold2:setString(self.roleinfo.gold)

            ui.setStringWithStroke(self.rootItems.gold,nil,10)
            ui.setStringWithStroke(self.rootItems.gold2,nil,10)

        end)))
    end
    --
end

function gameScene.up_effect(self,opt)
    -- opt==1 银币特效up
    -- opt==2 元宝特效up
    -- opt==3 银币特效down
    -- opt==4 元宝特效down

    --
    local scaleTo1 = CCScaleTo:create(0.3, 1.5,1.5)
    local scaleTo2 = CCScaleTo:create(0.3, 1,1)
    local spw1 = CCSequence:createWithTwoActions(scaleTo1,scaleTo2)
    local scaleTo11 = CCScaleTo:create(0.3, 1.5,1.5)
    local scaleTo22 = CCScaleTo:create(0.3, 1,1)
    local spw2 = CCSequence:createWithTwoActions(scaleTo11,scaleTo22)


    local opt = opt or 0
    local pos = {}
    pos.pos1 = self.effect_pos1
    pos.pos2 = self.effect_pos2

    if self.rootItems.userinfo_s:isVisible() or self.rootItems.userinfo_b:isVisible() then
        if self.rootItems.userinfo_s:isVisible() then
            pos.pos1 = self.effect_pos3
            pos.pos2 = self.effect_pos4
        end
    else

        return
    end

    if opt == 1 or opt == 3 then
        if self.rootItems.upNode1 then
            self.rootItems.upNode1:removeAllChildrenWithCleanup(true)
            self.rootItems.upNode1:setPosition(pos.pos1)
            local Node,Items = CCBReaderLoad(opt == 1 and "UIEffect/up_down/up" or "UIEffect/up_down/down", nil, true, "do")
            Node:setPosition(0,0)
            self.rootItems.upNode1:addChild(Node)
            local animationManager = getAnimationManager(Items)
            animationManager:setAnimationCompletedCallback(function()
                self.rootItems.upNode1:removeAllChildrenWithCleanup(true)
                self.rootItems.upNode1:setPosition(0,9999)
            end)
            animationManager:runAnimationsForSequenceNamed(opt == 1 and "up" or "down")
        end

        --
        if self.rootItems.userinfo_s:isVisible() then
            self.rootItems.coin2:runAction(spw1)
        else
            self.rootItems.coin:runAction(spw1)
        end
        --
    elseif opt == 2 or opt == 4 then
        if self.rootItems.upNode2 then
            self.rootItems.upNode2:removeAllChildrenWithCleanup(true)
            self.rootItems.upNode2:setPosition(pos.pos2)
            local Node,Items = CCBReaderLoad(opt == 2 and "UIEffect/up_down/up" or "UIEffect/up_down/down", nil, true, "do")
            Node:setPosition(0,0)
            self.rootItems.upNode2:addChild(Node)
            local animationManager = getAnimationManager(Items)
            animationManager:setAnimationCompletedCallback(function()
                self.rootItems.upNode2:removeAllChildrenWithCleanup(true)
                self.rootItems.upNode2:setPosition(0,9999)
            end)
            animationManager:runAnimationsForSequenceNamed(opt == 2 and "up" or "down")
        end

        if self.rootItems.userinfo_s:isVisible() then
            self.rootItems.gold2:runAction(spw2)
        else
            self.rootItems.gold:runAction(spw2)
        end
        --
    end
    --
end

function gameScene.qiyuEffect(self)
    local Node,Items = CCBReaderLoad(opt == 2 and "UIEffect/lizi/tuowei" or "UIEffect/lizi/tuowei", nil, true, "tuowei")
    Node:setPosition(540,self.topposY/2)
    self.rootItems.MainSceneBottomNode:addChild(Node)
    local moveto2 = CCMoveTo:create(0.5, ccp(460,80))
    Node:runAction(CCSequence:createWithTwoActions(moveto2,CCCallFunc:create(function()
        Node:removeFromParentAndCleanup(true)
    end)))
end

function gameScene.hintDataExt(self)
    --道馆不在时间内不显示红点
    if self.hintdata["355"] and self.hintdata["355"] > 0 then
        print("hintDataExt",self.hintdata["355"])
        local times = GameScene.layers["daoGuanMain"].module:gettimes()
        if not times then
            self.hintdata["355"] = 0
        end

        if self.hintdata["355"] ~= 0 then
            --有可领奖
            if self.hintdata["355"] == 1 then
            --有可攻打 也有可领奖
            elseif self.hintdata["355"] == 11 then
            --有可攻打 并且没提示过
            elseif self.hintdata["355"] == 10 and GameScene.layers["daoGuanMain"].module.daoguanOnceHint then
                self.hintdata["355"] = 0
            end
        end

    end


    if self.hintdata["168"] and self.hintdata["168"] > 0 then
        local ad = require"adChannel"
        if self.hintdata["168"] == 10 and (not ad:showOrNot()) then
            self.hintdata["168"] = 0
        end
    end


    --幻化红点处理
    self.hintdata["599"] = 0
    local illusionHints = getIllsionFromSqlite()
    printT(illusionHints,"illusionHints")
    for k,v in pairs(illusionHints) do
        if v.endtime > gamedata:time() then
            self.hintdata["599"] = 1
            break
        end
    end

    --幻化馆 [1 可领取 2可购买] 可购买本次登陆只显示一次
    if self.hintdata["605"] and self.hintdata["605"] > 0 then
        if GameScene.layers["activity"].module.activityPageconfig[177].module.onceHint and self.hintdata["605"] == 2 then
            self.hintdata["605"] = 0
        end
    end
end

function gameScene.reloadhint(self,data)
    if data then
        self.hintdata = data
        self:hintDataExt()
    end
    self:setHint(self)
    if self.presentLayer then
        self:setHint(self.layers[self.presentLayer].module,self.presentLayer)
    end
end

function gameScene.checkhint(self,id)
    if self.hintdata then
        if self.hintdata[tostring(id)] and self.hintdata[tostring(id)] ~=0 then
            return true
        end
    end
    return false
end

function gameScene.setHint(self,module,layername)
    if not module.rootItems then return end
    if module.hintconfig then
        if self.hintdata then
            for k,v in ipairs(module.hintconfig) do
                for k_, v_ in pairs(v.config) do
                    if module[v.name]["hint_"..k_] then
                        local show = false
                        for kk,vv in ipairs(v_) do
                            if self:checkopenlevelbyId(vv,true) and self.hintdata[tostring(vv)] and self.hintdata[tostring(vv)] ~=0 then
                                show = true
                            end
                        end
                        if (k_ == "slotinfo") and GameScene.ext_hint_slotfashion and (GameScene.ext_hint_slotfashion == 1) then
                            show = true
                        end    
                        ui.sethint(module[v.name]["hint_"..k_],show)
                    end
                end
            end
        else
            for k,v in ipairs(module.hintconfig) do
                for k_, v_ in pairs(v.config) do
                    if module[v.name]["hint_"..k_] then
                        ui.sethint(module[v.name]["hint_"..k_],false)
                    end
                end
            end
        end
    end

    if layername and self.layers[layername].show then
        if layername == "activity" then
            self.layers[layername].module:reloadHint()
        elseif layername == "startactivity" then
            self.layers[layername].module:reloadHint()
        elseif layername == "october1st" then
            self.layers[layername].module:reloadHint()
        elseif layername == "zhongqiuactivity" then
            self.layers[layername].module:reloadHint()
        elseif layername == "rob" then
            if self.layers[layername].module.listView:reloadData() then
                self.layers[layername].module.listView:reloadData()
            end
        elseif layername == "slotsInfo" then
            if self.layers[layername].module.generalListTableView then
                self.layers[layername].module.generalListTableView:reloadData()
            end
        elseif layername == "safemask" then
            self.layers[layername].module:reloadHint()
        elseif layername == "passkillmain" then
            self.layers[layername].module:reloadHint()
        elseif layername == "main" then
            self.layers[layername].module:reloadLimitedestHint()
            self.layers[layername].module:reloadChatHint()
        end
    end
end

function gameScene.setTitleHint(self)
    local hints = getTitleOnceFromSqlite()
    printT(hints,"hints")
    self.titleHintData = {title = {},iconBox = {}}

    local isHint = false
    for i,v in ipairs(hints) do
        local config = ui.IDconfig(v.cid)
        if config.staffType == "title" and v.status == 1 and gameConfig:checkBuildOpen(560) then
            isHint = true
            table.insert(self.titleHintData.title,v)
        elseif config.staffType == "iconBox" and v.status == 1 and gameConfig:checkBuildOpen(561) then
            isHint = true
            table.insert(self.titleHintData.iconBox,v)
        end
    end

    if self.rootItems and self.rootItems.title_hint then
        ui.sethint(self.rootItems.title_hint,isHint)
    end
end

function gameScene.setIconBox(self,cid)
end

function gameScene.setProfile(self,cid)

    if gamedata.config.general[tostring(cid)] then
        setSpriteFrameByName(self.rootItems.usericon, gamedata.config.general[tostring(cid)].icon)
        ui.setSpriteTextureRect(self.rootItems.usericon,0,0,150,150)
    end


--    if not self.cliper then
--        self.cliper = CCClippingNode:create()
--        local stencil = CCSprite:createWithSpriteFrameName("copymap_iconmask.png")
--        self.cliper:setStencil(stencil)
--        self.cliper:setAlphaThreshold(0)
--        local icon = CCSprite:create()
--        setSpriteFrameByName(icon,"huangyueying.png")
--        self.cliper:addChild(icon)
--        self.cliper:setPosition(-999,0)
--        self.rootNode:addChild(self.cliper)
--    end
end


function gameScene.setRoleInfo(self,dataTable)


    if not self.rootItems then
        self.roleinfo = dataTable
        return
    end

    if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:reload(dataTable)
    end
    
    printT(dataTable,"roleinfo  reset")
    --[[   --test
    local function change_end()
       print("change_end")
    end
    local scaleTo1 = CCScaleTo:create(0.3, 1.5,1.5)
    local scaleTo2 = CCScaleTo:create(0.3, 1,1)
    local spw1 = CCSequence:createWithTwoActions(scaleTo2,CCCallFunc:create(change_end))
    local spw2 = CCSequence:createWithTwoActions(scaleTo1,spw1)
    --self.rootItems.coin:runAction(spw2)
    --
    ]]

    local vipLevel = tonumber(dataTable.vip or 0)
    local levelNum = tostring(dataTable.level or 1)
    local expCurrent = tonumber(dataTable.exp or 0)
    local expTotal = tonumber(dataTable.nextexp or 0)
    local energyCurrent = tostring(dataTable.energy or 0)
    local energyTotal = tostring(dataTable.maxenergy or 0)
    local staminaCurrent = tostring(dataTable.stamina or 0)
    local staminaTotal = tostring(dataTable.maxstamina or 0)
    local coinNum = tostring(dataTable.coin or 0)
    local goldNum = tostring(dataTable.gold or 0)
    local name = tostring(dataTable.name or "")
    local power = tostring(dataTable.power or 0)
    local staminanext = tostring(dataTable.staminanext or 0)
    local staminaall = tostring(dataTable.staminaall or 0)
    local energynext = tostring(dataTable.energynext or 0)
    local energyall = tostring(dataTable.energyall or 0)

    --todo
    --part
    if self.rootItems.duanNode then
        ui.setWudaoPart(self.rootItems,dataTable.part_point or 0)
    end

    if self.roleinfo then
       if self.roleinfo.coin < dataTable.coin and  not (self.rootItems.userinfo_s:isVisible() or self.rootItems.userinfo_b:isVisible()) then
           self.rootItems.coin:setString(ui.makeshortnum(coinNum))
           self.rootItems.coin2:setString(ui.makeshortnum(coinNum))
           --self:up_effect(1)
       elseif self.roleinfo.coin > dataTable.coin then
           self.rootItems.coin:setString(ui.makeshortnum(coinNum))
           self.rootItems.coin2:setString(ui.makeshortnum(coinNum))
           self:up_effect(3)
       elseif self.roleinfo.coin == dataTable.coin then
           self.rootItems.coin:setString(ui.makeshortnum(coinNum))
           self.rootItems.coin2:setString(ui.makeshortnum(coinNum))
       end
       if self.roleinfo.gold < dataTable.gold and not (self.rootItems.userinfo_s:isVisible() or self.rootItems.userinfo_b:isVisible() ) then
           self.rootItems.gold:setString(goldNum)
           self.rootItems.gold2:setString(goldNum)
           --self:up_effect(2)
       elseif self.roleinfo.gold > dataTable.gold then
           self.rootItems.gold:setString(goldNum)
           self.rootItems.gold2:setString(goldNum)
           self:up_effect(4)
       elseif self.roleinfo.gold == dataTable.gold then
           self.rootItems.gold:setString(goldNum)
           self.rootItems.gold2:setString(goldNum)
       end
    else
        self.rootItems.coin:setString(ui.makeshortnum(coinNum))
        self.rootItems.coin2:setString(ui.makeshortnum(coinNum))
        self.rootItems.gold:setString(goldNum)
        self.rootItems.gold2:setString(goldNum)
    end

    self:setProfile(dataTable.profile)
    self.roleinfo = dataTable

    --人物等级

    ui.setLabelString(self.rootItems.userlevel,"等级:"..levelNum,46)

    --人物名字
    -- self.rootItems.username:setString(name)
    --描边
    -- ui.setLabelString(self.rootItems.username,nil,46)
    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(self.rootItems,self.roleinfo,0,40/34,46,self.rootItems.username)

    --VIP等级
    --self.rootItems.VIP:setString("VIP"..vipLevel)
    setSpriteFrameByName(self.rootItems.VIP,"b_n_vip_"..vipLevel)

    if gameConfig:checkBuildOpen(154) and not self.vipeffect then
        local ccb,item = CCBReaderLoad("UIEffect/vip/vip", nil, true, "vip")
        self.rootItems.vipeffect:addChild(ccb)
        self.vipeffect = true
    end

    --战斗力
    self.rootItems.userpower:setString(power)

    --体力条
    self.rootItems.userenergy:setString(staminaCurrent)
    self.rootItems.userenergy2:setString(staminaCurrent)
    self.rootItems.userenergy_all:setString("/" .. staminaTotal)
    self.rootItems.userenergy2_all:setString("/" .. staminaTotal)

    if staminaCurrent+0 == 0 then
        self.rootItems.userenergy:setColor(ccc3(189,30,14))
        self.rootItems.userenergy2:setColor(ccc3(189,30,14))
        self.rootItems.userenergy:setFontSize(36)
        self.rootItems.userenergy2:setFontSize(36)
    elseif staminaCurrent+0 > staminaTotal+0 then
        self.rootItems.userenergy:setColor(ccc3(55,209,121))
        self.rootItems.userenergy2:setColor(ccc3(55,209,121))
        self.rootItems.userenergy:setFontSize(36)
        self.rootItems.userenergy2:setFontSize(36)
    else
        self.rootItems.userenergy:setColor(ccc3(255,255,255))
        self.rootItems.userenergy2:setColor(ccc3(255,255,255))
        self.rootItems.userenergy:setFontSize(34)
        self.rootItems.userenergy2:setFontSize(34)
    end
    --杀气条
    self.rootItems.userstamina:setString(energyCurrent)
    self.rootItems.userstamina2:setString(energyCurrent)
    self.rootItems.userstamina_all:setString("/" .. energyTotal)
    self.rootItems.userstamina2_all:setString("/" .. energyTotal)

    if energyCurrent+0 == 0 then
        self.rootItems.userstamina:setColor(ccc3(189,30,14))
        self.rootItems.userstamina2:setColor(ccc3(189,30,14))
    elseif energyCurrent+0 > energyTotal+0 then
        self.rootItems.userstamina:setColor(ccc3(55,209,121))
        self.rootItems.userstamina2:setColor(ccc3(55,209,121))
    else
        self.rootItems.userstamina:setColor(ccc3(255,255,255))
        self.rootItems.userstamina2:setColor(ccc3(255,255,255))
    end

    ui.setSpriteTextureRect2(self.rootItems.userexpbar,0,0,466 * ((expCurrent > expTotal) and 1 or (expCurrent/expTotal)),17)


    ui.setStringWithStroke(self.rootItems.userenergy,nil,10)
    ui.setStringWithStroke(self.rootItems.userenergy2,nil,10)
    ui.setStringWithStroke(self.rootItems.userenergy_all,nil,10)
    ui.setStringWithStroke(self.rootItems.userenergy2_all,nil,10)

    ui.setStringWithStroke(self.rootItems.userstamina,nil,10)
    ui.setStringWithStroke(self.rootItems.userstamina2,nil,10)
    ui.setStringWithStroke(self.rootItems.userstamina_all,nil,10)
    ui.setStringWithStroke(self.rootItems.userstamina2_all,nil,10)

    ui.setStringWithStroke(self.rootItems.coin,nil,10)
    ui.setStringWithStroke(self.rootItems.coin2,nil,10)

    ui.setStringWithStroke(self.rootItems.gold,nil,10)
    ui.setStringWithStroke(self.rootItems.gold2,nil,10)
    --

    --设置游戏速度
    local speednum = 1
    local stopOff = 0
    if guide.controller and guide.controller.isOnGuide and guide.controller.excute.section == 1 then
    else
        local numstr = CCUserDefault:sharedUserDefault():getStringForKey("gmspeednum"..self.roleinfo.id)
        if numstr and numstr ~= "" then
            speednum = tonumber(numstr)
        end
        stopOff = CCUserDefault:sharedUserDefault():getIntegerForKey("gmspeedstate"..self.roleinfo.id)
    end
    if stopOff == 0 then
        CCDirector:sharedDirector():getScheduler():setTimeScale(speednum)
    else
        CCDirector:sharedDirector():getScheduler():setTimeScale(1)
    end
    -- CCDirector:sharedDirector():getScheduler():setTimeScale(1)
end

function gameScene.updateRenzheng( self )
    print("gameScene.updateRenzheng",gamedata.sdk.idCardStatus)

    if not gameConfig:checkBuildOpen(364) then return end 

    if gamedata.sdk.idCardStatus then
        self.rootItems.renzhengsprite:setVisible(true)
        if gamedata.sdk.idCardStatus >= 1 then
            setSpriteFrameByName(self.rootItems.renzhengsprite,"yirenzheng")
        elseif gamedata.sdk.idCardStatus == 0 then
            setSpriteFrameByName(self.rootItems.renzhengsprite,"weirenzheng")
        else
            self.rootItems.renzhengsprite:setVisible(false)
        end
    else
        self.rootItems.renzhengsprite:setVisible(false)
    end

    if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:updateRenzheng()
    end
end

return gameScene
