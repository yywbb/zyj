--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-8-21
-- Time: 上午11:43
-- To change this template use File | Settings | File Templates.
--


local gameConfig = {

    originSize = {width=1080, height = 1920},
    maxRadio_size = {width=640, height = 960},
    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },

    maiscenebottomheight = 160,
    labelnodeheight = 200,
    navigationheight = 247,


    defautTitleId = 35501,
    defautIconBoxId = 35001,

    strings = require"language_CN",

    battlePos = {
        [1] = {x = 363, y=1920-921, s = 1.06},
        [2] = {x = 363, y=1920-918, s = 1.13},
        [3] = {x = 358, y=1920-1175, s = 1.22},
        [4] = {x = 362, y=1920-1232, s = 1.24},
        [5] = {x = 342, y=1920-1463, s = 1.3},
        [6] = {x = 343, y=1920-1565, s = 1.4},
        [7] = {x = 343, y=1920-1752, s = 1.45},
        [8] = {x = 182, y=1920-781, s = 1.06},
        [9] = {x = 179, y=1920-1034, s = 1.13},
        [10] = {x = 163, y=1920-1066, s = 1.22},
        [11] = {x = 158, y=1920-1282, s = 1.24},
        [12] = {x = 152, y=1920-1368, s = 1.3},
        [13] = {x = 152, y=1920-1590, s = 1.4},
        [14] = {x = 152, y=1920-1742, s = 1.45},
    },

    touchPriority = {
        prompt = -1500,
        loading = -1000,
        touchPosLyer = -900,
        guide_story = -850,
        guide = -800,

        topwindow = -500,

        battleScene  = -450,

        menu = -400,
        templayer2 = -300,
        popwindow = -200,
        templayer1 = -130,
        gameScene = 0,

        barrage = -450,
    },

    Zorder = {
        prompt = 1500,
        loading = 1000,
        touchPosLyer = 900,
        guide_story = 850,
        guide = 800,

        popwindow = 500,
        battleScene = 450,

        gameScene = 0,
    },

    images = {
        alpha = "alpha.png",

        copystepOn = "_0009_jdxz_tongguodian",
        copystepOff = "_0009_jdxz_tongguodian2",

        s_icon_1000 = "obj_s_coin",
        s_icon_1001 = "obj_s_gold",
        s_icon_1002 = "b_n_MainScene_ti",
        s_icon_1003 = "b_n_MainScene_sha",
        s_icon_1025 = "0yuan",

        -------------------------------------------
        pageon = "page_on",
        pageoff = "page_off",

        weapon = "icon_wuqi",
        accessory = "icon_baowu",
        armor = "icon_fangju",
        treasure = "icon_shuji",
        horse = "icon_zuoqi",
        head = "icon_toukui",

        --button
        pageButtonOn = "titlebuttonon",
        pageButtonOff = "titlebuttonoff",

        --copyfriend
        atk_add = "zi_attack_add",
        def_add = "zi_defense_add",
        dead = "dead_sprite",

        betsprite = "_0012-6",
        checksprite = "_0008_1",
        betright = "_0009_1",
        betwrong = "_0009_1_2",
        hasbet = "_0015_2",

        l_g_q_back_default = "obj_icon_pz_quality0",
        l_g_q_back_1 = "obj_icon_pz_quality0",
        l_g_q_back_2 = "obj_icon_pz_quality2",
        l_g_q_back_3 = "obj_icon_pz_quality3",
        l_g_q_back_4 = "obj_icon_pz_quality4",
        l_g_q_back_5 = "obj_icon_pz_quality5",
        l_g_q_back_6 = "obj_icon_pz_quality6",
        l_g_q_back_7 = "obj_icon_pz_quality7",

        o_q_back_default = "icon_z_quality0",
        o_q_back_1 = "icon_z_quality0",
        o_q_back_2 = "b_icon_z_quality2",
        o_q_back_3 = "b_icon_z_quality3",
        o_q_back_4 = "b_icon_z_quality4",
        o_q_back_5 = "b_icon_z_quality5",
        o_q_back_6 = "b_icon_z_quality5",
        o_q_back_7 = "b_icon_z_quality5",

        s_q_back_2 = "leveltextbg2",
        s_q_back_3 = "leveltextbg3",
        s_q_back_4 = "leveltextbg4",
        s_q_back_5 = "leveltextbg5",
        s_q_back_6 = "leveltextbg5",
        s_q_back_7 = "leveltextbg5",


        n_back_default = "levelsprite_hui",
        n_back_1 = "levelsprite_hui",
        n_back_2 = "levelsprite2",
        n_back_3 = "levelsprite3",
        n_back_4 = "levelsprite4",
        n_back_5 = "levelsprite5",
        n_back_6 = "levelsprite5",
        n_back_7 = "levelsprite5",

        starON= "obj_xing",
        starOFF = "xingbg",

        tank = "obj_qian",
        dps = "obj_hou",
        lead = "alpha",--"obj_zhu",
        support = "support",

        winsprite = "obj_battle_lose",
        losesprite = "obj_battle_win",

        pageButtonON = "b_n_button_tab2",
        pageButtonOFF= "b_n_button_tab1",

        icon_ni_qualitydefault = "icon_ni_quality0",
        icon_ni_quality1 = "icon_ni_quality0",
        icon_ni_quality2 = "icon_ni_quality2",
        icon_ni_quality3 = "icon_ni_quality3",
        icon_ni_quality4 = "icon_ni_quality4",
        icon_ni_quality5 = "icon_ni_quality5",
        icon_ni_quality6 = "icon_ni_quality5",
        icon_ni_quality7 = "icon_ni_quality5",

        icon_ni_kuangdefault = "icon_ni_kuang0",
        icon_ni_kuang1 = "icon_ni_kuang0",
        icon_ni_kuang2 = "icon_ni_kuang2",
        icon_ni_kuang3 = "icon_ni_kuang3",
        icon_ni_kuang4 = "icon_ni_kuang4",
        icon_ni_kuang5 = "icon_ni_kuang5",
        icon_ni_kuang6 = "icon_ni_kuang5",
        icon_ni_kuang7 = "icon_ni_kuang5",

        something = "somthing",

        cell_quality2 = "b_icon_n_quality2",
        cell_quality3 = "b_icon_n_quality3",
        cell_quality4 = "b_icon_n_quality4",
        cell_quality5 = "b_icon_n_quality5",
        cell_quality6 = "b_icon_n_quality5",
        cell_quality7 = "b_icon_n_quality5",

        --activity
        activityicon_peace = "activity_peace",
        activityicon_mammon = "activity_mammon",
        activityicon_happinessplace = "activity_hole",
        activityicon_signin = "activity_signin",
        activityicon_fairycave = "activity_fairycave",
        activityicon_card = "activity_card",
        activityicon_cardgift = "activity_cardgift",
        activityicon_double = "activity_double",
        activityicon_growplan = "activity_growplan",
        activityicon_invent = "activity_invent",
        activityicon_consumereward = "activity_consumereward",
        activityicon_continuous = "activity_continuous",
        activityicon_cumulative = "activity_cumulative",
        activityicon_dailyreward = "activity_dailyreward",
        activityicon_newrank = "activity_newrank",
        activityicon_exchange = "encountericon3",
        activityicon_blackshop = "activity_heishishangdian",
        activityicon_secretshop = "activity_shenmishangdian",
        activityicon_shop = "activity_xianshishangdian",
        activityicon_robshop = "activity_xianshishangdian",
        activityicon_mazeshop = "activity_shenmishangdian",
        activityicon_passkillshop = "shop_guoguanzhanjiang",
        activityicon_duanwulunpan = "activity_jianianhua",
        activityicon_wudaolunpan = "activity_xiandou",
        activityicon_tigerchicken = "activity_laohuji",
        activityicon_tigerchickenshop = "shop_laohuji",

        
        activityicon_sportsshop = "shop_jingjichang",
        activityicon_gangshop = "shop_gonghui",
        activityicon_destroytempleshop = "shop_mieshendian",
        
        activityicon_welfareMonth = "activity_yuejijin",
        activityicon_multipleRebate = "activity_yuejijinfuli",
        activityicon_share = "activity_fenxiangyouli",
        activityicon_treasuresDiscount = "activity_zhenpinzhekou",
        activityicon_cornucopia = "activity_money",
        activityicon_dumpling = "activity_jixian",
        activityicon_dragonboat = "activity_longzhou",
        activityicon_doubleoutput = "activity_51",
        activityicon_championshop = "shop_guanjundeshilian",
        activityicon_treasuresDiscountX1 = "activity_zhenpinzhekou",
        activityicon_treasuresDiscountX2 = "activity_zhenpinzhekou",
        activityicon_treasuresDiscountX3 = "activity_zhenpinzhekou",
        activityicon_dailyrewardX1 = "activity_chongzhiyouli",
        activityicon_olddriver = "activity_invent",
        activityicon_sdkshare = "activity_fenxiang",
        
        activityicon_passkillshop = "shop_guoguanzhanjiang",

        activityicon_fashion = "activity_shizhuang",
        activityicon_goddown = "activity_pigmeimeng",

        activityicon_goddown_shop = "activity_pigjiangli",
        activityicon_goddown_rank = "activity_pigrank",

        activityicon_limitexchange = "activity_xianshiduihuan",
        activityicon_everyday = "activity_everyday",

        activityicon_fashionshop = "pentakill",
        activityicon_safemaskshop = "mozhaoshop2",

        activityicon_zhongqiujianianhua = "activity_zhongqiujianianhua",
        activityicon_danchongfuli = "activity_danchongfuli",
        activityicon_zhongqiuduihuan = "activity_zhongqiuduihuan",

        activityicon_achievements = "activity_xianshi",
        activityicon_vipwelfare = "activity_vip",
        activityicon_playerrecall = "activity_playerreturn",
        activityicon_fulilibao = "activity_fulilibao",

        activityicon_christmasshop = "activity_shengdan",

        activityicon_paimaihang = "activity_paimaihang",

        activityicon_cangjinggeshop = "cangjinggevip",

        activityicon_rebate = "activity_fanli",
        activityicon_pantaoxianli = "activity_pantaoxianli",

        suo = "suo",
        battle = "twoblade",
        penglaisprite1 = "alpha",
        penglaisprite2 = "conersprite2",
        penglaisprite3 = "conersprite",

        player = "player",
        boss = "boss",
        monster = "monster",
        box = "box",

        encounter_icon_exp = "encountericon4",
        encounter_icon_search = "encountericon3",
        encounter_icon_battle = "encountericon2",
        encounter_icon_general = "encountericon5",
        encounter_icon_shop = "encountericon1",
    },

    equipconfig = {
        [1] = "horse",
        [2] = "weapon",
        [3] = "treasure",
        [4] = "head",
        [5] = "armor",
        [6] = "accessory",
    },

    activityRankConfig = {
        [11] =  {rankId = 1,name = "等级",     reward = "toplevel",achievement = "openlevel_rank_achievement"},
        [104] = {rankId = 2,name = "战力",     reward = "combat_rank",achievement = "artifact_rank_achievement"},
        [126] = {rankId = 5,name = "翅膀",     reward = "wing_rank",achievement = "wing_rank_achievement"},
        [124] = {rankId = 6,name = "副本",     reward = "copy_rank",achievement = "copy_rank_achievement"},
        [125] = {rankId = 7,name = "魔罩",     reward = "mozhao_rank",achievement = "mozhao_rank_achievement"},
        [128] = {rankId = 18,name = "伙伴战力",  reward = "friend_rank",achievement = "friend_rank_achievement"},
        [106] = {rankId = 11,name = "战力成长", reward = "combat_grow",achievement = "combat_grow_achievement"},
        [105] = {rankId = 12,name = "魔符",    reward = "sigil_rank",achievement = "sigil_rank_achievement"},
        [114] = {rankId = 13,name = "战力成长1",reward = "combat_grow_x1",achievement = "combat_grow_achievement1"},
        [115] = {rankId = 14,name = "战力成长2",reward = "combat_grow_x2",achievement = "combat_grow_achievement2"},
        [127] = {rankId = 15,name = "命格",    reward = "soul_rank",achievement = "soul_rank_achievement"},
        [123] = {rankId = 16,name = "法宝",    reward = "artifact_rank",achievement = "artifact_rank_achievement"},
        [129] = {rankId = 17,name = "神器",    reward = "localTrump_rank",achievement = "trump_rank_achievement"},
    },

    soulcolorConfig = {
        [2] = ccc3(255,255,255),
        [3] = ccc3(0,0,255),
        [4] = ccc3(255,0,255),
        [5] = ccc3(255,0,0),
    },

    bagLimit_equip = 100,
    bagLimit_treasure = 100,
    bagLimit_soul = 100,

    npcRidlimit = 2146483648,

    colors= {

    },

    serverWarStage = {
        Upload_Array            = 1,    --上传阵容
        Began_Audition          = 2,    --海选开始倒计时
        End_Audition            = 3,    --海选结束倒计时
        Show_Audition           = 63,   --海选展示倒计时
        Guess_64To32            = 64,   --64进32下注倒计时
        Guess_32To16            = 68,   --32进16下注倒计时
        Guess_16To8             = 73,   --16进8下注倒计时
        Battle_64To8_3          = 76,   --小组赛8强第3轮
        Guess_8To4              = 77,   --8进4下注倒计时
        Show_result_4           = 81,   --4强展示期
        Guess_4To2              = 82,   --半决赛下注倒计时
        Battle_4To2_3           = 85,   --半决赛第3轮
        Guess_2To1              = 86,   --决赛下注倒计时
        Battle_2To1_3           = 89,   --决赛第3轮
        Show_Champion           = 90,   --决赛展示
    },

    --是否开启充值按钮
    ischargeOpen = true,

    sensitiveWord = require"shield_cn",

    AD_packageName = gamedata.device.getPackageName(),
    
    fixH = 0,
}

function gameConfig.makeServerWarTimeForStage(self,s_open)

   if s_open and s_open == 1 then

        gamedata.config.cross_battle_time = table.copy(gamedata.config.cross_battle_champion_time)
        --神榜冠军赛
        self.serverWarStage = {
            Upload_Array            = 1,    --上传阵容
            Began_Audition          = 2,    --海选开始倒计时
            End_Audition            = 3,    --海选结束倒计时
            Show_Audition           = 63,   --海选展示倒计时
            Guess_64To32            = 64,   --64进32下注倒计时
            Guess_32To16            = 68,   --32进16下注倒计时
            Guess_16To8             = 72,   --16进8下注倒计时
            Battle_64To8_3          = 75,   --小组赛8强第3轮
            Show_64To8              = 76,   --8强展示倒计时
            Guess_8To4              = 77,   --8进4下注倒计时
            Battle_8To4_3           = 80,   --冠军赛4强第3轮
            Guess_4To2              = 81,   --半决赛下注倒计时
            Battle_4To2_3           = 84,   --半决赛第3轮
            Guess_2To1              = 85,   --决赛下注倒计时
            Battle_2To1_3           = 88,   --决赛第3轮
            Show_Champion           = 89,   --决赛展示
            Began_S_Audition        = 90,   --突围赛开始倒计时
            End_S_Audition          = 91,   --突围赛结束倒计时
            Show_S_Audition         = 111,  --突围展示倒计时
            Guess_S_8To4            = 112,  --8进4下注倒计时
            Battle_S_8To4_3         = 115,  --冠军赛4强第3轮
            Guess_S_4To2            = 116,  --半决赛下注倒计时
            Battle_S_4To2_3         = 119,  --半决赛第3轮
            Guess_S_2To1            = 120,  --决赛下注倒计时
            Battle_S_2To1_3         = 123,  --决赛第3轮
            Show_S_Champion         = 124,  --决赛展示倒计时
        }
    end 
end

function gameConfig.makeScreenParam(self)
    if not self.scaleNum then
        if self.d_viewSize.width/self.d_viewSize.height <= self.maxRadio_size.width/self.maxRadio_size.height then
            self.scaleNum =  self.d_viewSize.width/self.originSize.width
            self.topposY =  self.d_viewSize.height*self.originSize.width/self.d_viewSize.width
            if self.topposY>2160 then
                self.fixH = (self.topposY-2160)*0.5*self.scaleNum
                self.topposY = 2160
            end
        else
            self.scaleNum = (self.maxRadio_size.width/self.originSize.width)*(self.d_viewSize.height/self.maxRadio_size.height)
            self.topposY =  self.maxRadio_size.height*self.originSize.width/self.maxRadio_size.width
        end
    end
end

function gameConfig.addScreenSide(self,scene)
    if not self.scaleNum then self:makeScreenParam() end

    local ccb, item = CCBReaderLoad("loading/screen_side", nil, true, "screen_side")
    ccb:setPosition(self.d_viewSize.width/2,self.fixH)
    ccb:setScale(self.scaleNum)
    scene:addChild(ccb,20000)
end

function gameConfig.checkBuildOpen(self,id)
    return gamedata.config.build[tostring(id)] and gamedata.config.build[tostring(id)].switch == 1
end

print("gameConfig.AD_packageName",gameConfig.AD_packageName)

return  gameConfig