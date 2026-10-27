--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 上午10:04
-- To change this template use File | Settings | File Templates.
--

local popWindows = {

    maxRadio_size = gameConfig.maxRadio_size,
    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },
    viewSize = gameConfig.originSize,

    existTopWindows = 0,
    existNormalWindows = 0,

    topZorder = gameConfig.Zorder.popwindow,
    topPriority = gameConfig.touchPriority.topwindow,

    normalZorder =  1,
    normalPriority =  gameConfig.touchPriority.popwindow,

    touchPos = {},

    windows = {
        confirm = {type = "top", postype = "center", module = require"window_confirm" },
        starRule = {type = "top", postype = "center", module = require"window_StarRule" },
        starGetReward = {type = "top", postype = "center", module = require"window_starGetReward" },
        
        baglimittip = {type = "top", postype = "center", module = require"window_bagLimitTip" },

        --skillinfo = {type = "normal", postype = "touchpos", module = require"window_skillinfo" },

        soulIntroduction = {type = "top", postype = "center", module = require"window_soulIntroduction" },
        equipInfo = {type = "normal", postype = "center", module = require"window_equipInfo" },
        generalInfo = {type = "normal", postype = "center", module = require"window_generalInfo" },
        generalInfoRole = {type = "normal", postype = "center", module = require"window_generalInfo_role" },
        generalInfoSkill = {type = "normal", postype = "center", module = require"window_generalInfo_skill" },

        generalUp = {type = "normal", postype = "center", module = require"window_generalup" },

        slotarrange = {type = "normal", postype = "center", module = require"window_slotArrange" },
        selectlist = {type = "normal", postype = "center", module = require"window_select" },
        shopbuy = {type = "normal", postype = "center", module = require"window_buy" },
        recruit = {type = "top", postype = "center", module = require"window_recruit" },

        soulInfo = {type = "normal", postype = "center", module = require"window_soulInfo" },
        propInfo = {type = "normal", postype = "center", module = require"window_propInfo" },
        recharge = gameConfig.ischargeOpen and {type = "normal", postype = "center", module = require"window_recharge" } or {},
        vipwelfare ={type = "normal", postype = "center", module = require"window_vipwelfare" },
        robselect = {type = "normal", postype = "center", module = require"window_robselect" },
        robaddCD = {type = "normal", postype = "center", module = require"window_robaddCD" },
        robresult = {type = "normal", postype = "center", hold = true, module = require"window_robresult" },
        robresultreward = {type = "normal", postype = "center", module = require"window_robresultReward" },
        
        roleinfo = {type = "top", postype = "center", hold = true, module = require"window_roleinfo" },

        userLevelup = {type = "top", postype = "center", hold = true, module = require"window_userLvUp" },

        zhuxiantai = {type = "normal", postype = "center", module = require"window_zhuxiantai" },


        startactivityhelp = {type = "normal", postype = "center", module = require"window_startactivity_help" },
        cdkey = {type = "normal", postype = "center", module = require"window_cdk" },
        kefu = {type = "normal", postype = "center", module = require"window_kefu" },
        friend = {type = "normal", postype = "center", module = require"window_friend" },
        sportshelp = {type = "normal", postype = "center", module = require"window_sportshelp" },

        -- post = {type = "top", postype = "center", module = require"window_post" },
        post = {type = "top", postype = "center", module = require"window_post2" },
        getStaff = {type = "top", postype = "center", module = require"window_getStaff" },

        useropt = {type = "normal", postype = "center", module = require"window_userOpt" },

        cup = {type = "top", postype = "touchPos", module = require"window_cup" },
        -- penglai = {type = "normal", postype = "touchPos", module = require"window_penglai" },
        -- penglaiReward = {type = "normal", postype = "touchPos", module = require"window_penglaiReward" },
        penglaiReward = {type = "normal", postype = "touchPos", module = require"window_islandAchievement" },
        -- penglaiResult = {type = "normal", postype = "touchPos", module = require"window_islandresult" },
        penglaiResult = {type = "normal", postype = "touchPos", hold = true, module = require"window_islandresult" },

        -- 蓬莱仙岛
        isLand = {type = "normal", postype = "touchPos", hold = true, module = require"window_isLand" },
        
        generalexp = {type = "normal", postype = "center", hold = true, module = require"window_generalExp" },

        levelReward = {type= "normal", postype = "center", module = require"window_levelReward"},

        friendcopy = {type= "normal", postype = "center", module = require"window_friendCopy"},
        -- worldbossrank = {type= "normal", postype = "center", module = require"window_worldBossRank"},
        worldbossrank = {type= "normal", postype = "center", module = require"window_worldBoss"},
        mammon_pop = {type= "normal", postype = "enter", module = require"window_mammonReward"},

        invent = {type= "normal", postype = "center", module = require"window_invent"},
        online = {type= "normal", postype = "center", module = require"window_online"},
        onlinebytime = {type= "normal", postype = "center", module = require"window_onlinebytime"},

        buytrain = {type= "normal", postype = "center", module = require"window_buytrain"},
        devilup = {type= "normal", postype = "center", module = require"window_devilup"},
        tips = {type= "normal", postype = "center", module = require"window_tips"},

        activityshopPreview = {type= "normal", postype = "center", module = require"window_activityshopPreview"},

        firstrecharge = {type= "normal", postype = "center", module = require"window_firstRecharge"},
        accRecharge = {type= "normal", postype = "center", module = require"window_accRecharge"},
        chatpop = {type= "normal", postype = "touchPosTo", module = require"window_chatpop"},
        chatemoji = {type= "normal", postype = "touchPosTo", module = require"window_chatemoji"},

        guildnew = {type= "normal", postype = "center", module = require"window_guild2new"},
        guildsetnotice = {type= "normal", postype = "center", module = require"window_guild2setnotice"},
        guildquit = {type= "normal", postype = "center", module = require"window_guild2quit"},
        guildmsg = {type= "normal", postype = "center", module = require"window_guild2msg"},

        guildlegion = {type = "normal", postype = "center", module = require"window_guild2legion"},

        guildsetname = {type= "normal", postype = "center", module = require"window_guild2setname"},
        guildrewardview = {type= "normal", postype = "center", module = require"window_guild2rewardview"},
        guildtreasureinfo = { type = "normal" , postype = "center", module = require"window_guild2treasureInfo" },
        guildtreasuretips = { type = "normal" , postype = "center", module = require"window_guild2treasureTips" },
        guildtreasurechecklist = { type = "normal" , postype = "center", module = require"window_guild2treasurechecklist" },
        guildxianchirank = {type= "normal", postype = "center", module = require"window_guild2_xianchi"},
        guildwarabout = {type= "top", postype = "center", module = require"window_guildWar_about"},


        buypropById = {type= "normal", postype = "center", module = require"window_buypropById" },

        -- dropTips = {type= "normal", postype = "center", module = require"window_dropTips"},
        dropTips = {type= "normal", postype = "center", module = require"window_dropTips2"},

        devilpreview = {type= "top", postype = "center", module = require"window_devilpreview"},
        devilsuccessUp = {type= "top", postype = "center", module = require"window_devilsuccessUp"},
        
        devilSkill = { type = "normal",postype = "center",module = require"window_devilSkill"},
        devilSkillDetail = {type = "normal",postype = "center",module = require"window_devilSkillDetail"},
        -- 魔宠图鉴说明
        devilTuJian = { type = "normal",postype = "center",module = require"window_devilTuJian"},

        zhuxiantaiboss = {type = "normal", postype = "center", module = require"window_zhuxiantaiBoss" },
        zhuxiantaireward = {type = "normal", postype = "center", module = require"window_zhuxiantaiReward" },
        zhuxiantairank = {type = "normal", postype = "center", module = require"window_zhuxiantaiRank" },
        zhuxiantaibosstips = {type = "normal", postype = "center", module = require"window_zhuxiantaiBossTips" },

        devourDetails = {type = "normal", postype = "center", module = require"window_devourDetails" },
        devourSelect = {type = "normal", postype = "center", module = require"window_devourSelect" },
        
        versionUpdate = {type = "top", postype = "center", module = require"window_versionUpdate" },
        downloadUpdate = {type = "top", postype = "center", module = require"window_downloadUpdate" },

        friendcopyrank = {type = "normal", postype = "center", module = require"window_friendcopyrank" },

        propusebynum = {type = "normal", postype = "center", module = require"window_propusebynum" },
        buyProperty = {type = "normal", postype = "center", module = require"window_buyProperty" },
        generalupfinish = {type = "top", postype = "center", module = require"window_generalupFinish" },
        generalawakenfinish = {type = "top", postype = "center", module = require"window_generalawakenfinish" },
        protagonistawakenfinish = {type = "top", postype = "center", module = require"window_protagonistawakenfinish" },

        qiankunluselect = {type = "normal", postype = "center", module = require"window_qiankunluSelect" },
        qiankunluPopup = {type = "normal", postype = "center", module = require"window_qiankunluPopup" },

        favoriteList = {type = "normal", postype = "center", module = require"window_favoriteList" },
        favoritetransfer = {type = "normal", postype = "center", module = require"window_favoritetransfer" },
        favoritetransferselect = {type = "normal", postype = "center", module = require"window_favoritetransferselect" },

        treasureupSelect = {type = "normal", postype = "center", module = require"window_treasureupSelect" },

        penglaiRule = {type = "top", postype = "center", module = require"window_penglaiRule" },


        standings = {type = "normal", postype = "center", module = require"window_standings"},
        standingsScroll = {type = "normal", postype = "center", module = require"window_standingsScroll" },

        inspireRule = {type = "top", postype = "center", module = require"window_inspireRule" },

        copyacivity = {type = "top", postype = "center", module = require"window_copy_activity" },
        copyacivityitem = {type = "top", postype = "center", module = require"window_copy_activityItem" },

        bossDetail = {type = "normal", postype = "center", hold = true, module = require"window_bossDetail"},
        kingfoot =  {type = "top", postype = "center", module = require"window_daily_kingfoot" },
        bossDropDetail = {type = "normal", postype = "center", hold = true, module = require"window_bossDropDetail"},

        encounter = {type = "top", postype = "center", hold = true, module = require"window_encounter" },
        battleVs = {type = "top", postype = "center", hold = true, module = require"window_battleVS" },

        bossSkillInfo = {type = "normal", postype = "center", module = require"window_bossSkillInfo"},
        
        multipleRebateHelp = {type = "normal", postype = "center", module = require"window_multipleRebateHelp"},
        singlebosschongwuselect = {type = "normal", postype = "center", module = require"window_singleboss_chongwuselect"},
        

        mofulevelup = {type = "normal", postype = "center", module = require"window_MofuLevelUp"},
        mofuselect = {type = "normal", postype = "center", module = require"window_mofuSelect"},
        mofuproperty = {type = "normal", postype = "center", module = require"window_mofuProperty"},

        share = {type = "normal", postype = "center", module = require"window_share"},

        copystarInfo = {type = "normal", postype = "center", module = require"window_copy_starInfo"},
        copyhadesInfo = {type = "normal", postype = "center", module = require"window_copy_hadesInfo"},
        vipUpgrade = {type = "normal", postype = "center", module = require"window_vipUpgrade"},
        mazereward = {type = "normal", postype = "center", module = require"window_mazeReward"},
        
        blackreset = {type = "normal", postype = "center", module = require"window_blackresetPop"},

        godStoneInfo = {type = "normal", postype = "center", module = require"window_godStoneInfo"},

        firstwin = {type = "normal", postype = "center", module = require"window_firstwin"},

        buypower = {type = "normal", postype = "center", module = require"window_buyPowerPop"},

        cornucopiaRule = {type = "normal", postype = "center", module = require"window_cornucopiaRule"},

        
        passkillselect = {type = "normal", postype = "center", module = require"window_passkill_select"},

        championbox = {type = "normal", postype = "center", module = require"window_championBox"},
        championRule = {type = "normal", postype = "center", module = require"window_championRule"},


        lunpanchange = {type = "normal", postype = "center", module = require"window_lunpanChange"},
        dragonboatrule = {type = "normal", postype = "center", module = require"window_dragonboatrule"},
        clubselet = {type = "normal", postype = "center", module = require"window_nightclubselet"},
        clubchoose = {type = "normal", postype = "center", module = require"window_nightclubchoose"},
        clubchance = {type = "top", postype = "center", module = require"window_nightclubchance"},
        clubevent = {type = "normal", postype = "center", module = require"window_nightclubevent"},
        oneAddclubchoose = {type = "normal", postype = "center", module = require"window_nightoneAddclubchoose"},


        wudaohuipipei = {type = "normal", postype = "center", module = require"window_wudaohui_pipei"},
        wudaohuiduanwei = {type = "normal", postype = "center", module = require"window_wudaohui_duanwei"},

        fashionPreview = {type = "normal", postype = "center", module = require"window_fashionPreview"},
        fashionGet = {type = "normal", postype = "center", module = require"window_fashionGet"},
        fashionPost = {type = "normal", postype = "center", module = require"window_fashionPost"},
        tigerchickenRule = {type = "normal", postype = "center", module = require"window_tigerchickenrule"},

        deploymentUp = {type = "normal", postype = "center", module = require"window_deploymentUp"},
        deploymentLevelUp = {type = "normal", postype = "center", module = require"window_deploymentLevelUp"},

        goddownSelect = {type = "normal", postype = "center", module = require"window_goddownSelect"},
        goddownRule = {type = "normal", postype = "center", module = require"window_goddownRule"},

        battleSlot = {type = "top", postype = "center", hold = true, module = require"window_battleslot" },
        safemaskmaster = {type = "normal", postype = "center", module = require"window_safemaskmaster"},
        safemaskup = {type = "normal", postype = "center", module = require"window_safemaskup"},
        safemaskRule = {type = "normal", postype = "center", module = require"window_safemaskRule"},

        fashionPost2 = {type = "normal", postype = "center", module = require"window_fashionPost2"},

        
        wingstagesuccess = {type = "normal", postype = "center", module = require"window_wingstagesuccess"},
        wingcolorset = {type = "normal", postype = "center", module = require"window_wingColor"},
        wingPreview = {type = "normal", postype = "center", module = require"window_wingPreview"},


        servicewarchampionlist = {type = "normal", postype = "center", module = require"window_servicewar_championlist"},
        servicewarbet = {type = "top", postype = "center", module = require"window_servicewar_bet"},
        servicewarbetchoose = {type = "normal", postype = "center", module = require"window_servicewar_betchoose"},

        servicewarrule = {type = "normal", postype = "center", module = require"window_servicewar_rule"},

        playerreturncdk = {type = "normal", postype = "center", module = require"window_playerreturncdk" },
        playerreturnPost = {type = "normal", postype = "center", module = require"window_playerreturnPost"},

        userexpup = {type = "normal", postype = "center", module = require"window_userExpup"},

        starGetRewardPreview = {type = "top", postype = "center", module = require"window_starGetRewardPreview" },

        triggerGift = {type = "normal", postype = "center", module = require"window_trigger_gift"},

        exchangeMore = {type = "normal", postype = "center", module = require"window_exchangeMore"},

        soulintegrate = {type = "normal", postype = "center", module = require"window_soulintegrate" },

        goddownReward = {type = "normal", postype = "center", module = require"window_goddownReward" },

        propsRecovery = {type = "normal", postype = "center", module = require"window_props_recovery" },

        boxselect = {type = "normal", postype = "center", module = require"window_boxopenbyselect" },
        boxselect6 = {type = "normal", postype = "center", module = require"window_boxopenbyselect6" },

        auctionRule = {type = "normal", postype = "center", module = require"window_auctionRule" },
        auctionGet = {type = "normal", postype = "center", module = require"window_auctionGet" },
        auctionNum = {type = "normal", postype = "center", module = require"window_auctionNum" },
        auctionLog = {type = "normal", postype = "center", module = require"window_auctionLog" },

        soulfast = {type = "normal", postype = "center", module = require"window_soul_fast" },

        cangjingge_allbuild = {type = "normal", postype = "center", module = require"window_cangjingge_allbuild" },
        cangjingge_buildup = {type = "top", postype = "center", module = require"window_cangjingge_buildup" },
        cangjingge_guai = {type = "normal", postype = "center", module = require"window_cangjingge_guai" },
        cangjingge_qualityup = {type = "normal", postype = "center", module = require"window_cangjingge_qualityup" },
        cangjingge_task = {type = "top", postype = "center", module = require"window_cangjingge_task" },
        cangjingge_rule = {type = "normal", postype = "center", module = require"window_cangjingge_rule" },

        setnotice = {type= "normal", postype = "center", module = require"window_setnotice"},

        gangrank2 = {type= "normal", postype = "center", module = require"window_guild2_boss_rank2"},
        gangbossRule = {type= "normal", postype = "center", module = require"window_gangbossRule"},

        equipbaptize = {type= "normal", postype = "center", module = require"window_equipBaptizeAutomatic"},
        instrumentForgeAutomatic = {type= "normal", postype = "center", module = require"window_instrumentForgeAutomatic"},
        zidong_rule = {type= "normal", postype = "center", module = require"window_zidong_rule"},

        k_goddownSelect = {type = "normal", postype = "center", module = require"window_k_goddownSelect"},
        k_goddownReward = {type = "normal", postype = "center", module = require"window_k_goddownReward" },

        signin_tip = {type = "normal", postype = "center", module = require"window_signin_tip" },

        changegender = {type = "normal", postype = "center", module = require"window_changegender" },

        turntablerecord = {type = "normal", postype = "center", module = require"window_turntablerecord" },

        mailmoretext = {type = "normal", postype = "center", module = require"window_mailmoretext" },

        gamblingRule = {type = "normal", postype = "center", module = require"window_gamblingRule" },

        shenlongxuyuan_event = {type = "normal", postype = "center", hold = true, module = require"window_shenlongxuyuan_event" },
        shenlongxuyuan_shop = {type = "normal", postype = "center", hold = true, module = require"window_shenlongxuyuan_shop" },
        shenlongxuyuan_reward = {type = "normal", postype = "center", hold = true, module = require"window_shenlongxuyuan_reward" },
        shenlongxuyuan_rule = {type = "normal", postype = "center", module = require"window_shenlongxuyuan_rule" },
        shenlongxuyuan_jiangli = {type = "normal", postype = "center", module = require"window_shenlongxuyuan_jiangli" },
        guardReward = {type = "normal", postype = "center", module = require"window_guardReward" },
        guard_rule = {type = "normal", postype = "center", module = require"window_guild2_guard_rule" },
        guardrewardview = {type= "normal", postype = "center", module = require"window_guardrewardview"},
        
        -- 道馆守卫战奖励预览
        daoGuanRewardview = {type= "normal", postype = "center", module = require"window_daoGuanRewardview"},
        -- 道馆守卫战奖励预览
        daoGuanRewardview2 = {type= "normal", postype = "center", module = require"window_daoGuanRewardview2"},

        -- 说明
        daoGuanExplain = {type= "normal", postype = "center", module = require"window_daoGuanExplain"},
        -- 战报记录
        daoGuanFightNote = {type= "normal", postype = "center", module = require"window_daoGuanFightNote"},
        -- 购买次数
        daoGuanBuyCount = {type= "normal", postype = "center", module = require"window_daoGuanBuyCount"},
        -- 挑战馆长弹窗
        daoGuanTiaoZhan = {type= "normal", postype = "center", module = require"window_daoGuanTiaoZhan"},
        -- 道馆挑战布阵
        daoGuanAttack = {type= "normal", postype = "center", module = require"window_daoGuanAttack"},
        
        vipkefu = {type= "normal", postype = "center", module = require"window_vipkefu"},

        shiming = {type= "top", postype = "center", hold = true,module = require"window_shiming"},

        timebag = {type= "normal", postype = "center", module = require"window_timebag"},

        zhounianbuff = {type= "normal", postype = "center", module = require"window_zhounianbuff"},
        zhounianSelect = {type= "normal", postype = "center", module = require"window_zhounianSelect"},

        bosschallenge_cheer = {type = "normal", postype = "center", module = require"window_bosschallenge_cheer" },
        bosschallenge_rewardlist = {type = "normal", postype = "center", module = require"window_bosschallenge_rewardlist" },
        bosschallenge_ranklist = {type = "normal", postype = "center", module = require"window_bosschallenge_ranklist" },
        bosschallenge_rule = {type = "normal", postype = "center", module = require"window_bosschallenge_rule" },
        bosschallenge_double = {type = "normal", postype = "center", module = require"window_bosschallenge_double" },
        zhongshuRank = {type= "normal", postype = "center", module = require"window_zhongshuRank"},
        zhongshuRule = {type= "normal", postype = "center", module = require"window_zhongshuRule"},
        equipbynum = {type = "normal", postype = "center", module = require"window_equipbynum" },
        recruitshop = {type = "normal", postype = "center", module = require"window_recruitshop" },

        buyprop = {type = "normal", postype = "center", module = require"window_buyProp" },
        buyItem = {type = "normal",postype = "center", module = require"window_buyItem"},    --通用购买道具 1,10,100
        water = {type = "normal", postype = "center", module = require"window_water" },
        exclusiveArtifact = {type = "normal", postype = "center", module = require"window_exclusive_artifact_info" },
        exclusiveArtifactAdvanced = {type = "normal", postype = "center", module = require"window_exclusive_artifact_advanced" },
        peentoGiftRule = {type = "normal", postype = "center",module = require"window_peentoGiftRule"},
        peentoGiftPreShow = {type = "normal", postype = "center",module = require"window_peentoGiftPreShow"},
        peentoSurePanel = {type = "normal",postype = "center",module = require"window_peentoSurePanel"},
        jewelInfo = {type = "normal",postype = "center",module = require"window_jewelInfo"},
        openServerRank = {type = "normal",postype = "center",module = require"window_openServerRank"},
        openServerPost = {type = "normal",postype = "center",module = require"window_openServerPost"},
        threeGeneralPost = {type = "normal",postype = "center",module = require"window_threeGeneralPost"},

        activityAuctionRule = {type = "normal",postype = "center",module = require"window_activity_auction_rule"},
        activityAuctionRecording = {type = "normal",postype = "center",module = require"window_activity_auction_recording"},
        activityAuctionChooseAntique = {type = "normal",postype = "center",module = require"window_activity_auction_choose_antique"},
        activityAuctionSpecialReward = {type = "normal",postype = "center",module = require"window_activity_auction_special_reward"},
        activityantiqueOnekey = {type = "normal",postype = "center",module = require"window_antiqueOnekey"},

     
        castArtifactRule = {type = "normal",postype = "center",module = require"window_castArtifactRule"},
        artifactEffectList = {type = "normal",postype = "center",module = require"window_artifactEffectList"},
        artifactSelect = {type = "normal",postype = "center",module = require"window_artifactSelect"},
        jewelSelect = {type = "normal",postype = "center",module = require"window_jewelSelect"},
        artifactMount = {type = "normal",postype = "center",module = require"window_artifactMount"},
        artifactInfo = {type = "normal",postype = "center",module = require"window_artifactInfo"},
        artifactInfoOther = {type = "top",postype = "center",module = require"window_artifactInfoOther"},
        artifactOpenPos = {type = "normal",postype = "center",module = require"window_artifactOpenPos"},
        weekCardDouble = {type = "normal",postype = "center",module = require"window_weekCardDouble"},
        propSelect = {type = "normal",postype = "center",module = require"window_propSelect"},
        artifactSInfo = {type = "normal",postype = "center",module = require"window_artifactSInfo"},
        jewelUp = {type = "normal",postype = "center",module = require"window_jewelUp"},
        jewelEffect = {type = "normal",postype = "center",module = require"window_jewelEffect"},
        artifactCreateTip = {type = "normal",postype = "center",module = require"window_artifactCreateTip"},
        checkTimeList = {type = "normal",postype = "center",module = require"window_checkTimeList"},

        activityCopySelect = {type = "normal", postype = "center", module = require"window_activityCopy_select"},
        shopExchange = {type = "top", postype = "center", module = require"window_shopExchange"},
        guildWarSure = {type = "normal", postype = "center", module = require"window_guildWarSure" },

        honorBattleCheer = {type = "normal", postype = "center", module = require"window_honor_battle_cheer"},     
        honorBattleStarRank = {type = "normal", postype = "center", module = require"window_honor_battle_StarRank"},
        honorBattleOdds = {type = "normal", postype = "center", module = require"window_honor_battle_odds"},
        honorBattleProperty = {type = "normal", postype = "center", module = require"window_honor_battle_property"},
        honorBattleChampion = {type = "normal", postype = "center", module = require"window_honor_battle_champion"},
        honorBattleDivisionInfo = {type = "normal", postype = "center", module = require"window_honor_battle_division_info"},
        honorBattleReward = {type = "normal", postype = "center", module = require"window_honor_battle_reward"},
        honorBattleRule = {type = "normal", postype = "center", module = require"window_honor_battle_rule"},
        honorTime = {type = "normal", postype = "center", module = require"window_honor_time"},
    
        --add bet Window
        honorBet = {type = "normal", postype = "center", module = require"window_honor_bet"},
        honorBuff = {type = "normal", postype = "center", module = require"window_honor_buff"},
        poolingServersSignReward = {type = "normal",postype = "center",module = require"window_pooling_servers_sign_reward"},
        
        hellBuyBuff = {type = "normal", postype = "center", module = require"window_hell_buy_buff"},
        hellRewardPreview = {type = "normal", postype = "center", module = require"window_hell_reward_preview"},
        hellAllReward = {type = "normal", postype = "center", module = require"window_hell_all_reward"},
        hellRefresh = {type = "normal", postype = "center", module = require"window_hell_refresh"},
        hellBossInfo = {type = "normal", postype = "center", module = require"window_hell_boss_info"},

        magicViewAttr = {type = "normal", postype = "center", module = require"window_magicViewAttr"},

        goddownShop = {type = "normal", postype = "center", module = require"window_goddownShop"},
        goddownRank = {type = "normal", postype = "center", module = require"window_goddownRank"},

        kgoddownShop = {type = "normal", postype = "center", module = require"window_k_goddownShop"},
        kgoddownRank = {type = "normal", postype = "center", module = require"window_k_goddownRank"},

        cp_goddownShop = {type = "normal", postype = "center", module = require"window_cp_goddownShop"},
        cp_goddownRank = {type = "normal", postype = "center", module = require"window_cp_goddownRank"},

        tigerchickenshop = {type = "normal", postype = "center", module = require"window_tigerchickenshop"},
        cp_tigerchickenshop = {type = "normal", postype = "center", module = require"window_cp_tigerchickenshop"},
        activityNewRank = {type = "normal", postype = "center", module = require"window_activityNewRank"},
        newRankRule = {type = "normal", postype = "center", module = require"window_newRankRule"},
        mobileShop = {type = "normal", postype = "center", module = require"window_mobileShop"},
        friendcopy_onefinish = {type = "normal", postype = "center", module = require"window_friendcopy_onefinish"},

        -- tradingShopBuy = {type = "normal", postype = "center", module = require"window_tradingShopGoodsBuy"},
        -- tradingShopSell = {type = "normal", postype = "center", module = require"window_tradingShopGoodsSell"},
        -- tradingShopCancel = {type = "normal", postype = "center", module = require"window_tradingShopGoodsCancel"},

        artifactRule = {type = "normal",postype = "center",module = require"window_artifact_rule"},
        -- 一键打造弹窗
        onceCreateArtifact = {type = "top", postype = "center", module = require"window_onceCreateArtifact"},
        -- 一键鉴定
        onceCheckup = {type = "top", postype = "center", module = require"window_onceCheckup"},
        -- 强化一键添加
        onceAddStrengthen = {type = "top", postype = "center", module = require"window_onceAddStrengthen"},
        -- 一键重铸
        onceRecoin = {type = "top", postype = "center", module = require"window_onceRecoin"},
        -- 技能升级
        artifactSkillUp = {type = "top", postype = "center", module = require"window_artifactSkillUp"},
         -- 一键鉴定
        onceCheckedPanel = {type = "top", postype = "center", module = require"window_onceCheckedPanel"},

        hadesAllReward = {type = "normal", postype = "center", module = require"window_hades_all_reward"},

        newJieriRule = {type = "normal", postype = "center", module = require"window_newJieriRule"},
        --newJieri = {type = "normal", postype = "center", module = require"window_newJieri"},

        redbag = {type = "normal", postype = "center", module = require"window_redbag"},
        timebuy_list = {type = "normal", postype = "center", module = require"window_timebuy_list"},

        partner_fashion = {type = "normal", postype = "center", module = require"window_partner_fashion"},
        confirmWithShield = {type = "normal", postype = "center", module = require"window_confirmWithShield"},

        artifactGongming = {type = "normal", postype = "center", module = require"window_artifactGongming" },

        robautoresult = {type = "normal", postype = "center", module = require"window_robautoresult" },

        playerback_tip = {type = "normal", postype = "center", module = require"window_playerback_tip" },
        playerback = {type = "normal", postype = "center", module = require"window_playerback" },

        generalFeiSheng = {type = "normal", postype = "center", module = require"window_generalFeiSheng" },
        generalAttributeInfo = {type = "normal", postype = "center", module = require"window_generalAttributeInfo" },
        babelTowerAward = {type = "normal", postype = "center", module = require"window_babelTowerAward" },
        babelTowerBuy = {type = "normal", postype = "center", module = require"window_babelTowerBuy" },
        babelTowerEnter = {type = "normal", postype = "center", module = require"window_babelTowerEnter" },
        babelTowerLevelDetails = {type = "normal", postype = "center", module = require"window_babelTowerLevelDetails" },
        babelTowerAutoBattle = {type = "normal", postype = "center", module = require"window_babelTowerAutoBattle" },
        babelTowerRule = {type = "normal", postype = "center", module = require"window_babelTowerRule" },

        changebreakskill = {type = "normal", postype = "center", module = require"window_changebreakskill" },
        scope_rule = {type = "normal", postype = "center", module = require"window_scope_rule" },

        glory_battle_achievement = {type = "normal", postype = "center", module = require"window_glory_battle_achievement" },
        power_rule = {type = "normal", postype = "center", module = require"window_rolePowerRule" },
        goldBreakConfirm = {type = "normal", postype = "center", module = require"window_goldBreakConfirm" },
        feisheng_rule = {type = "normal", postype = "center", module = require"window_feisheng_rule" },

        blessingCaveBuy = {type = "normal", postype = "center", module = require"window_blessingCaveBuy" },
        
        generalChangeSelect = {type = "normal", postype = "center", module = require"window_general_change_selelct" },
        generalChangedResult = {type = "normal", postype = "center", module = require"window_general_changed_result" },
        generalChangedRule = {type = "normal", postype = "center", module = require"window_general_change_rule"},

        swapChangeSelect = {type = "normal", postype = "center", module = require"window_swap_change_selelct"},

        kingmanOnekeyChallenge = {type = "normal", postype = "center", module = require"window_kingmanOnekeyChallenge" },
        
        magicAttribute = {type = "normal", postype = "center", module = require"window_magicAttribute" },
        
        wudaohuiRewardPreview = {type = "normal", postype = "center", module = require"window_wudaohui_reward_preview" },

        babelTowerRank = {type = "normal", postype = "center", module = require"window_babelTowerRank" },

        examinationrank = {type = "normal", postype = "center", module = require"window_examinnationRank" },
        statusOverview = {type = "normal", postype = "center", module = require"window_status_overview" },
        robonekeyresult =  {type = "normal", postype = "center", module = require"window_robonekeyresult" },

        examinationRule = {type = "normal",postype = "center",module = require"window_examinnation_rule"},
        godSoulTempleRule = {type = "normal",postype = "center",module = require"window_godSoulTemple_rule"},
        championSetting         = {type = "normal", postype = "center", module = require"window_championSetting" },
        championResult          = {type = "normal", postype = "center", module = require"window_championResult" },
        vipExchangeBuy = {type = "normal", postype = "center", module = require"window_vipExchangeBuy" },
        generalcultivate        = {type= "normal", postype = "center", module = require"window_generalcultivateAuto"},
        -- 玄月密保
        xuanyueTreasuresBuy     = {type = "normal", postype = "center", module = require"window_xuanyueTreasuresBuy" },
        xuanyueTreasuresActivate = {type = "normal", postype = "center", module = require"window_xuanyueTreasuresActivate" },
        xuanyueTreasureTip      = {type = "normal", postype = "center", module = require"window_xuanyueTreasures_tip" },
        xuanyueTreasuresRule    = {type = "normal", postype = "center", module = require"window_xuanyueTreasuresRule" },

        xuanyueTreasuresBuy2     = {type = "normal", postype = "center", module = require"window_xuanyueTreasuresBuy2" },
        xuanyueTreasuresActivate2 = {type = "normal", postype = "center", module = require"window_xuanyueTreasuresActivate2" },
        xuanyueTreasureTip2      = {type = "normal", postype = "center", module = require"window_xuanyueTreasures_tip2" },
        -- 玄月密保3
        xuanyueTreasuresBuy3     = {type = "normal", postype = "center", module = require"window_xuanyueTreasuresBuy3" },
        xuanyueTreasuresActivate3 = {type = "normal", postype = "center", module = require"window_xuanyueTreasuresActivate3" },
        xuanyueTreasureTip3      = {type = "normal", postype = "center", module = require"window_xuanyueTreasures_tip3" },
	
        disCountGiftPost = {type = "normal", postype = "center", module = require"window_disCountGiftPost"},
        speedGiftPost = {type = "normal", postype = "center", module = require"window_speedGiftPost"},
        ancientRuinsMonster = {type = "normal", postype = "center", module = require"window_ancientRuins_monster"},
        ancientRuinsRule = {type = "normal", postype = "center", module = require"window_ancientRuinsRule"},
    	-- 缘分详情
        fateInfoPop = {type = "normal", postype = "touchPosTo", module = require"window_fateInfoPop"},
        fengshenRule = {type = "normal", postype = "center", module = require"window_fengshenRule"},
        copyexchange = {type = "normal", postype = "center", module = require"window_copyexchange"},
        gameHelperLog = {type = "normal", postype = "center", module = require"window_gameHelperLog"},
        gameHelperRule = {type = "normal", postype = "center", module = require"window_gameHelperRule"},
        gameHelperTip = {type = "normal", postype = "center", module = require"window_gameHelperTip"},
        gameHelperConfirm = {type = "normal", postype = "center", module = require"window_gameHelperConfirm"},
        artifactWashEffectList = {type = "normal",postype = "center",module = require"window_artifactWashEffectList"},
        island2Confirm = {type = "top", postype = "center", module = require"window_island2Confirm" },
        hadesCopyRule = {type = "normal", postype = "center", module = require"window_hadesCopyRule"},
        --帮会澡堂
        openzaotanginfo = {type= "normal", postype = "center", module = require"window_openzaotanginfo"},
        --澡堂结算
        zaotangjiesuan = {type= "normal", postype = "center", module = require"window_zaotangfinish"},

        openfeastinfo = {type= "normal", postype = "center", module = require"window_openfeastinfo"},
        --盛宴结算
        feastjiesuan = {type= "normal", postype = "center", module = require"window_feastfinish"},
        --盛宴召集
        feastzhaoji = {type= "normal", postype = "center", module = require"window_feastinvite"},
        --帮会澡堂，宴会继续
        gangProduceAgain = {type= "normal", postype = "center", module = require"window_gangProduceAgain"},

        --通用 道具不足直接使用元宝的弹窗
        price_props = {type = "normal", postype = "center", module = require"window_price_props"},
        commonRule = {type= "normal", postype = "center", module = require"window_commonRule"},

        upStarSkill = {type= "normal", postype = "center", module = require"window_upStarSkill"},

        overpassRecord = {type= "normal", postype = "center", module = require"window_overpassRecord"},
        -- 道具详情和获取途径整合弹唱
        infoAndAccess = {type = "normal", postype = "center", module = require"window_infoAndAccess" },

        chengzhangjihuaUp = {type = "normal", postype = "center", module = require"window_chengzhangjihuaUp" },
    
        artifactWashConfirm = {type = "normal", postype = "center", module = require"window_artifactWashConfirm" },
        hefuActivity = {type = "normal", postype = "center", module = require"window_hefuActivity_tip" },

        feastExpChange = {type = "normal", postype = "center", module = require"window_feastExpChange"},

        autorefining = {type = "normal", postype = "center", module = require"window_autorefining"},
        
        --广告提示
        adCueboard = {type = "top", postype = "center", module = require"window_adCueboard" },

        greatGiftByAD = {type = "top", postype = "center", module = require"window_greatGiftByAD" },


        changeSkillIllusion = {type = "normal", postype = "center", module = require"window_changeSkillIllusion" },

        sculpturePost = {type = "normal", postype = "center", module = require"window_sculpturePost" },
        qilingInfo = {type = "normal", postype = "center", module = require"window_qilingInfo" },
        qilingIntensify = {type = "normal", postype = "center", module = require"window_qilingIntensify" },
        exclusiveArtifactAttr = {type = "normal", postype = "center", module = require"window_exclusiveArtifactAttr" },
        exclusiveArtifact = {type = "top", postype = "center", module = require"window_exclusiveArtifact" },
        qilingSelect = {type = "normal", postype = "center", module = require"window_qilingSelect" },
        qilingRefiningSelect = {type = "normal", postype = "center", module = require"window_qilingRefiningSelect" },
        exclusiveTipPop = {type = "normal", postype = "touchPosTo", module = require"window_exclusiveTipPop",bgColor = ccc4(0,0,0,0)},
        exclusiveActive = {type = "normal", postype = "normal", module = require"window_exclusiveActive"},
    
        exclusiveArtifactQiLingCopy = {type = "top", postype = "center", module = require"window_ExclusiveArtifactQiLingCopy"},
        exclusiveArtifactBuyNum = {type = "normal", postype = "center", module = require"window_ExclusiveArtifactBuyNum"},
        exclusiveArtifact_rewardlist = {type = "normal", postype = "center", module = require"window_ExclusiveArtifact_rewardlist"},

        userAndPrivacyAgreement = {type= "top", postype = "center", hold = true,module = require"window_userAndPrivacyAgreement"},
        tokenRecovery = {type = "normal",postype = "center", module = require"window_token_recovery"},
        tokenOverview = {type = "normal",postype = "center", module = require"window_token_overview"},

        generalJXRebirth = {type = "normal",postype = "center", module = require"window_generaljuexingchongsheng"},
        generalUpStarRebirth = {type = "normal",postype = "center", module = require"window_generalupstarchongsheng"},

        --封神赛
        godCompetitionPetList = {type = "normal",postype = "center", module = require"window_godCompetitionPetSelect"},
        godCompetitionBattleOdds = {type = "normal",postype = "center", module = require"window_godCompetition_battle_odds"},
        godCompetition_hurtlist = {type = "normal",postype = "center", module = require"window_godcompetition_hurtlist"},
        godcompetition_battleRecord = {type = "normal",postype = "center", module = require"window_godcompetition_battleRecord"},
        godCompetitionBattleDivisionInfo = {type = "normal", postype = "center", module = require"window_godCompetition_battle_division_info"},
        godCompetition_reward = {type = "normal", postype = "center", module = require"window_godcompetition_reward"},
        godcompetition_bossinfos = {type = "normal", postype = "center", module = require"window_godcompetition_bossinfo"},
        godcompetitionRule = {type = "normal", postype = "center", module = require"window_godcompetition_rule"},
        godCompetitionBet = {type = "normal",postype = "center", module = require"window_godCompetition_bet"},
        godcompetition_bossskillinfo = {type = "normal",postype = "center", module = require"window_godcompetition_bossskillinfo"},
        godCompetitionBattleStarRank = {type = "normal",postype = "center", module = require"window_godcompetition_battle_StarRank"},
        godCompetitionTime = {type = "normal", postype = "center", module = require"window_godcompetition_time"},
        
        --3、7日、许愿活动一键领取
        onekeyall = {type = "normal",postype = "center", module = require"window_onekeyallreward"},

        setgmspeed = {type = "normal",postype = "center", module = require"window_setgmspeed"},
        --大元宵排行榜
        dayuanxiaorank = {type = "normal",postype = "center", module = require"window_dayuanxiao_rank"},
        dayuanxiao_rankreward = {type = "normal",postype = "center", module = require"window_dayuanxiao_rankreward"},
        nailicode = {type = "normal",postype = "center", module = require"window_naili_code"},
        nailicode_rule = {type = "normal",postype = "center", module = require"window_naili_code_rule"},
        game2048rank = {type = "normal",postype = "center", module = require"window_minigame2048_rank"},
        game2048shop = {type = "normal",postype = "center", module = require"window_minigame2048_shop"},
        game2048achievement = {type = "normal",postype = "center", module = require"window_minigame2048_achievement"},

        --升仙台
        ascension_xianshu = {type = "normal",postype = "center", module = require"window_ascensionSendai_xianshu"},
        sendai_allType = {type = "normal",postype = "center", module = require"window_ascensionSendai_allType"},
        sendai_battle = {type = "normal",postype = "center", module = require"window_ascensionSendai_battle"},
        shengxiantai_rule = {type = "normal", postype = "center", module = require"window_shengxiantai_rule" },
        --宝物升星
        treasureUpStarSill = {type = "normal",postype = "center", module = require"window_treasureUpStarSkill"},
    },

    profColor = ccc4(0,0,0,190),

    inited = false,
}

function popWindows.init(self)
    if self.inited then return end

    self.scaleNum = gameConfig.scaleNum

    local function gettouchpos(pos)
        self.touchPos = pos
    end

    gameTouch:rigistFunc("begin","gameWindows",gettouchpos)

    self.inited = true
end

function popWindows.openWindow(self,name,data,callback)
    print("openWindow",name)
    if not self.windows[name] or not next(self.windows[name]) then runGamePrompt({msg = "功能未开启"}) return end
    -- if not GameScene:checkopenlevelbykey(name) then return end

    if self.windows[name].show then
        if name == "getStaff" then
            local _callback = function ()
                self.windows["getStaff"].show = false
                gameWindows:openWindow("getStaff",data,callback)
            end
            self.windows["getStaff"].module.callback = _callback
        elseif name == "infoAndAccess" then
            printT(data,"jkp-windows")
            local _callback = function ()
                self.windows["infoAndAccess"].show = false
                gameWindows:openWindow("infoAndAccess",data,callback)
            end
            self.windows["infoAndAccess"].module.callback = _callback
            self:closeWindowDirect(name)
        else
            if self.windows[name].module.reload then
                self.windows[name].module:reload(data,callback)
            else
                self:closeWindowDirect(name)
            end
        end
        return
    end

    local cb = function(x,y)

        if self.windows[name].hold then return end
        if guide.controller and guide.controller.isOnGuide then return end
        local touchNode = self.windows[name].module.rootNode
        if touchNode and not ui.isTouched(touchNode,x,y) and self.windows[name].ready then
            if not self.windows[name].module.needcallback then
                self.windows[name].module.callback = nil
            end
            self:closeWindowDirect(name)
        end
    end


    local touchPriority = 0
    local istop = false
    if self.existTopWindows ~= 0 or self.windows[name].type == "top" then
        local index = self.existTopWindows+1
        touchPriority = self.topPriority - (index-1)*5 -1

        local noAnimation = nil
        self.windows[name].animationNode, noAnimation = self.windows[name].module:open(touchPriority,data,callback)
        self.windows[name].profLayer = ui.addProflayer(mainScene,touchPriority+1, self.topZorder+2*(index-1)-1,self.windows[name].bgColor or self.profColor,nil,nil,nil,cb,"gameWindowsprof")

        self.windows[name].animationNode:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
        self.windows[name].animationNode:setScale(self.scaleNum)
        local runingScene = battleScene.show and bScene or mainScene
        runingScene:addChild(self.windows[name].animationNode,self.topZorder+2*(index-1))

        self.windows[name].fromX,self.windows[name].fromY,self.windows[name].realtype = self:openWindowAnimation(self.windows[name].animationNode,self.windows[name].postype,"top",noAnimation,name)

        self.existTopWindows = self.existTopWindows+1
        istop = true
    else
        local index = self.existNormalWindows+1
        touchPriority = self.normalPriority - (index-1)*5 -1
        self.normalPriority = math.max(self.normalPriority - 1,-500)
        self.normalZorder = self.normalZorder + 1
        print("existNormalWindows",self.existNormalWindows)

        local noAnimation = nil
        self.windows[name].animationNode, noAnimation = self.windows[name].module:open(touchPriority,data,callback)
        self.windows[name].profLayer = ui.addProflayer(GameScene.rootItems.windownode,touchPriority+1,self.normalZorder+2*index-1,self.windows[name].bgColor or self.profColor,CCSizeMake(1080,2160),nil,nil,cb,"gameWindowsprof")


        self.windows[name].animationNode:setPosition(1080/2,GameScene.topposY/2 + 80)
        self.windows[name].animationNode:setScale(1)
        GameScene.rootItems.windownode:addChild(self.windows[name].animationNode,self.normalZorder+2*index)

        self.windows[name].fromX,self.windows[name].fromY,self.windows[name].realtype = self:openWindowAnimation(self.windows[name].animationNode,self.windows[name].postype,"normal",noAnimation,name)

        self.existNormalWindows = self.existNormalWindows+1

    end

    self.windows[name].show = true

    if self.windows[name].module.cancelTip then
        ui.initSkipPopup(self.windows[name].profLayer,istop,self.windows[name].module.cancelTip)
    end
end

function popWindows.isExitWindow(self)
    return not ((self.existTopWindows == 0) and (self.existNormalWindows == 0))
end

function popWindows.closeWindow(self,name)
    if self.windows[name].show then
        self:closeWindowAnimation(name, function()
            self:closeWindowDirect(name)
        end)
    end
end

function popWindows.closeAllWindowDirect(self)

    for k,v in pairs(self.windows) do
        if v.show then
            self:closeWindowDirect(k)
        end
    end

    self.existTopWindows = 0
    self.existNormalWindows = 0
end

function popWindows.closeWindowDirect(self,name)
    if self.windows[name].show then

        self.windows[name].profLayer:removeFromParentAndCleanup(true)
        self.windows[name].profLayer = nil
        self.windows[name].animationNode = nil

        if self.windows[name].realtype=="top" then
            self.existTopWindows = self.existTopWindows-1
        else
            self.existNormalWindows = self.existNormalWindows-1
        end
        self.windows[name].show = false
        self.windows[name].ready = false
        self.windows[name].module:close()

    end

    print("window name = ",name)
    if name == "infoAndAccess" then
        print("jkp-112233")
    else
        if guide.controller then
            guide.controller:UIComplete(8014)
        end
    end

end

function popWindows.openWindowAnimation(self,node,postype,windowtype,noAnimation,name)
    gameTouch:clickprofbytime(0.4)
    local toX
    local toY
    if windowtype == "top" then
        toX = gamedata.device.SCREEN_WIDTH/2
        toY = gamedata.device.SCREEN_HEIGHT/2
    else
        toX = 1080/2
        toY = GameScene.topposY/2 + 80
    end

    if postype ~= nil and postype == "touchPosTo" then
        toX = self.touchPos.x*(gameConfig.originSize.width/gamedata.device.SCREEN_WIDTH)
        toY = self.touchPos.y*(gameConfig.originSize.width/gamedata.device.SCREEN_WIDTH)
    end

    local fromX = toX
    local fromY = toY

    if postype ~= nil and postype == "touchPos" then
        if windowtype == "top" then
            fromX = self.touchPos.x
            fromY = self.touchPos.y
        else
            fromX = self.touchPos.x*(gameConfig.originSize.width/gamedata.device.SCREEN_WIDTH)
            fromY = self.touchPos.y*(gameConfig.originSize.width/gamedata.device.SCREEN_WIDTH)
        end
    end

    local cb = function()
        if guide.controller then
            guide.controller:UIComplete(8013)
            --guide.controller:NewSystem(name)
        end
        self.windows[name].ready = true
    end


    if noAnimation then
        node:setPosition(ccp(toX,toY))
        cb()
    else
        node:setPosition(ccp(fromX,fromY))
        node:setScale(0)
        local moveto = CCMoveTo:create(noAnimation and 0 or 0.3,ccp(toX,toY))
        local backOut1 = CCEaseBackOut:create(moveto)

        local scaleTo = CCScaleTo:create(noAnimation and 0 or 0.3, windowtype == "top" and self.scaleNum or 1)
        local backOut = CCEaseBackOut:create(scaleTo)

        local spw = CCSpawn:createWithTwoActions(backOut1,backOut)
        local sequence = CCSequence:createWithTwoActions(spw, CCCallFunc:create(cb))
        node:runAction(sequence)
    end

    return fromX,fromY,windowtype
end

function popWindows.closeWindowAnimation(self,name,callBack)
    gameTouch:clickprofbytime(0.4)
    local data = self.windows[name]
    local moveto = CCMoveTo:create(0.3,ccp(data.fromX,data.fromY))
    local backIn1 = CCEaseBackIn:create(moveto)

    data.animationNode:setScale(data.realtype == "top" and self.scaleNum or 1)
    local scaleTo = CCScaleTo:create(0.3, 0)
    local backIn = CCEaseBackIn:create(scaleTo)

    local spw = CCSpawn:createWithTwoActions(backIn1,backIn)
    data.animationNode:runAction(spw)

    --after animation to clear
    local delay = CCDelayTime:create(0.4)
    local sequence = CCSequence:createWithTwoActions(delay, CCCallFunc:create(callBack))
    data.animationNode:runAction(sequence)
end

return popWindows
   I�  