--[[
-- UI
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-5-6
-- Time: 上午11:02
-- To change this template use File | Settings | File Templates.
]] --

UPDATECACHE = false
DelayUpdateFuncs = {}

--gamedata = {
--    config = {},
--    ext = {},
--    device = require"device"
--}
--
--require("gamedata")

--local hintChange = {
--    [116] = true,
--    [2091] = true,
--    [2093] = true,
--    [2096] = true,
--    [2098] = true,
--    [2082] = true,
--    [213] = true,
--    [1003] = true,
--    [1004] = true,
--    [1005] = true,
--    [1006] = true,
--    [1007] = true,
--    [1017] = true,
--    [1019] = true,
--    [1111] = true,
--    [1108] = true,
--    [2502] = true,
--    [1401] = true,
--    [1303] = true,
--    [1304] = true,
--    [1333] = true,
--    [1334] = true,
--    [1311] = true,
--    [13111] = true,
--    [1321] = true,
--    [1601] = true,
--    [2011] = true,
--    [2016] = true,
--    [2061] = true,
--    [2041] = true,
--    [2051] = true,
--    [2304] = true,
--    [2309] = true,
--    [2401] = true,
--    [2411] = true,
--    [2101] = true,
--    [2105] = true,
--    [2089] = true,
--    [3211] = true,
--    [3101] = true,
--    [2038] = true,
--    [3607] = true,
--    [3611] = true,
--    [2036] = true,
--    [213] = true,
--    [2023] = true,
--}

local function step2NetUICallBack()
    require"UILogin"
    require"UIFangchenmi"
    require"UILoadConfig"
    require"UIPrompt"
    require"UIErrorMessage"
    require"UIDownloadProxy"
    require"UIRole"
    require"UISlots"
    require"UIGenerals"
    require"UICopy"
    require"UICopyBrave"
    require"UIFriendCopy"
    require"UIProps"
    require"UIAthletics"
    require"UIActivity"
    require"UIBloodbattle"
    require"UIHappinessPlace"
    require"UIEatChicken"
    require"UIMammon"
    require"UIActivityHole"
    require"UIEquips"
    require"UISouls"
    require"UIFriends"
    require"UISelectList"
    require"UIShop"
    require"UIRob"
    require"UIEncounter"
    require"UITechnology"
    require"UICup"
    require"UIGang"
    require"UIMails"
    require"UIBattleOther"
    require"UISignIn"
    require"UIBroadcast"
    require"UITask"
    require"UIPenglai"
    require"UIIsland"
    require"UILiveness"
    require"UIReLogin"
    require"UIDevilFotress"
    require"UIWorldBoss"
    require"battletest"
    require"UIChat"
    require"UIRecharge"
    require"UICacheReset"
    require"UIInvent"
    require"UIGuide"
    require"UICollect"
    require"UICDK"
    require"UISystemMail"
    require"UIRank"
    require"UIActivityReward"
    require"UIActivityExchange"

    require"UIActivitySecretShop"


    require"UIZhuxiantai"

    require"UIStartActivity"

    require"UIActivityShop"
    require"UIActivityBlackShop"
    require"UIGlobalParam"

    require"UIGetStaffNum"

    require"UIQiankunlu"
    
    require"UIFavorite"

    require"UIActivityRobShop"

    require"UIGuildWar"

    require"UIcommonSlot"
    require"UIsingleBoss"

    require"UIGuildWar"

    require"UIActivityMultipleRebate"
    require"UICopyActivity"
    
    require"UIMofu"
    require"UIMagic"

    require"UICopyStar"

    require"UIEquipStage"
    require"UIEquipStarUp"
    
    require"UIMaze"
    require"UIActivityCornucopia"
    
    require"UIPasskill"

    require"UIChampion"
    require"UIActivity_DuanwuLunpan"

    require"UIDragonBoat"
    require"UIActivityOldDriver"
    
    require"UIWuDaoHui"
    require"UIActivity_tigerchicken"

    require"UIFashion"
    require"UIActivityFashion"
    require"UINightclub"
    
    require"UIActivity_sdkshare"
    require"UILimitExchange"
    require"UIGameStar"
    require"UIActivityGoddown"
    
    require"UIActivitySafeMaskShop"

    require"UIActivityJinghuaShop"

    require"UIWing"
    require"UIServiceWar"
    require"UIHonorWar"

    require"UIRecall"

    require"UITriggerGift"

    require"UIAuction"

    require"UICangjingge"

    require"UIDragonWishing"
    require"UIActivityZhounian"

    require"UIActivityTree"

    require"UIDaoGuan"
    require"UITimeBag"
    
    require"UIActivityPeentoGift"

    require"UIActivityAuction"

    require"UIArtifact"
    require"UIActivityWeekCard"

    require"UIPoolingServer"
    require"UICopyHell"
    
    require"UITitle"

    require"UIActivityChristmas"
    require"UIBabelTower"

    require"UIBlessingCave"
    require"UIChange"
    require"UIXuanyueTreasures"
    require"UIGodSoulTemple"

    require"UIExamination"
    require"UIAncientRuins"

    require"UISpeedGift"
    require"UIHelper"
    require"UIDewPool"

    require"UIActivityAD"

    require"UIIllusion"
    require"UISculptureActivity"
    
    require"UIExclusiveArtifact"

    require"UIToken"


    require"UIGodCompetition_main"
    require"UIGodCompetition"
    require"UIMiniGames"

    require"UIAscensionSendai"

    local net_ui_callback2 = {
        [70110] = UIPureSlots,
        [7010] = UIXianBuyTimes,
        [7011] = UIBabelTowerQuery,
        [7012] = UIBabelTowerLevelQuery,
        [7013] = UIBabelTowerBattle,
        [7014] = UIBabelTowerQuit,
        [7015] = UIBabelTowerAward,
        [7016] = UIBabelTowerAutoBattle,
        [7017] = UIBabelTowerShopQuery,
        [7018] = UIBabelTowerShopBuy,
        [7019] = UIBabelTowerRankQuery,
        [999990] = UIbattletest,
        [999988] = UILuaException,
        [888888] = UILoginShow,
        [8888883] = UIResourceUpdateFinish,
        [80] = UIEventPost,
        [8888882] = UIReLoginShow,
        [979797] = UImerorytest,

        [999900] = UICombMessage,
        [999909] = UICombMessageProcess,

        [999902] = UIRoleInfoBasic,
        [999903] = UIRequestLocking,
        [999904] = UIHeartCheck,
        [999905] = UIServerTime,

        [999907] = UIconfigUpdate,
        [999908] = UIOffline,
        --登录相关

        [777777] = UIrestart,
        [6666666] = UIunzip,

        [999911] = UILogout,

        [5555] = UIbagLimitTip,

        [5340] = UIOnlinetimeQuery,
        [5341] = UIRealnameRewardQuery,
        [5342] = UIRealnameReward,
        [5347] = UIUserKick,
        [5343] = UIOnlinetimeUpdate,


        [3] = setLoginServerListTable,
        [5] = selectServerIDResult,
        [55] = selectServerIDResultForSaveSession,

        [9] = setLoginPercentFromServer,
        [10] = judgeLoginNewUserIsValid,
        [11] = judgeLoginUserAccountIsValid,
        [12] = judgeLoginChangePwdIsValid,
        [20] = UIDownloadProxy,
        [90] = UIReLogin,
        [901] = UISetLoginParam,
        [902] = UIIDCardParam,

        [1000] = judgeSelectedServerIDValid,
        [500] = UILoadConfig,

        [100] = UIRandomName,
        [101] = UISetName,
        [102] = UIRoleSetProfile,
        [200] = UIGuideQuery,
        [201] = UIGuideExcute,
        [202] = UIInitGeneral,

        [203] = UIChangeGender,
        [204] = UIGenderQuery,

        [501] = UIPromptTimeOut,
        [502] = UIPromptNoSignal,
        [503] = UIPrompt,
        [504] = UIGameloading,
        [505] = UINetConectSucess,
        --[506] = UIForegroundCallBack,

        [510] = startLoginIntoGameLoading,
        [511] = stopLoginIntoGameLoading,

        [4] = configUpdateFinished,

        [110] = UICacheReset,
        [111] = UIRoleShow,
        [112] = UIRoleShow,

        [10001] = UITencentRecharge,
        [10003] = UITencentRecharge2,

        [11602] = UIRechargefresh,

        [115] = UIRechargePre,
        [116] = UIRechargeResult,
        [117] = UIVip,
        [118] = UIRechargeScore,
        [2090] = UIMonthCard,
        [2091] = UIMonthCardGet,
        [2092] = UIMonthCardReward,
        -- 限时兑换 began
        [3710] = UILimitTimeExchangeQuery,
        [3711] = UILimitTimeExchange,
        [3712] = UILimitTimeExchangeRefresh,
        -- 限时兑换 ends
        -- 天庭银座 began
        [4500] = UIUserPatrolQuery,
        [4501] = UIUserPatrolStatus,
        [4502] = UIUserPatrolAttack,
        [4503] = UIUserPatrolDo,
        [4504] = UIUserPatrolReward,
        [4505] = UIUserPatrolEventDo,
        [4509] = UserPatrolOneAdd,
        [4510] = UserPatrolOneAddReward,
        [4511] = UserPatrolOneAddQuery,
        -- 天庭银座 ends
        [2093] = UIMonthCardRewardGet,
        [2094] = UIGrowPlan,
        [2095] = UIGrowPlanBuy,
        [2096] = UIGrowPlanReward,
        [2097] = UIRechargeDouble,
        [2098] = UIFirstRechargeReward,
        [2099] = UIFirstRechargeStatus,
        [300]  = UIVipStatus,
        [301]  = UIUserBuy,

        [2080] = UIInviteCode,
        [2081] = UIInviteCodeSet,
        [2082] = UIInviteCodeReward,

        [205] = UIPowerChange,
        [98] = UIGetGuid,
        --游戏相关
        [212] = UIContinue7Query,
        [213] = UIContinue7Reward,
        [214] = UIContinue7Query1,
        [215] = UIContinue7Reward1,

        [1030] = UIUserSystemMail,

        [1032] = UIHint,
        [10321] = UIHintReset,

        [1015] = UIGeneralCollect,
        [1103] = UIEquipCollect,
        [3910] = UITeamRecomQuery,
        [3911] = UITeamRecomReward,

        [1024] = UIGeneralOnSlot,
        [1027] = UIGeneralSlot,


        [1001] = UIRoleShow,
        [10011] = UIRoleQuery,
        [10012] = UIRoleLevelUp,
        [1002] = UISlotsAllInfo,
        [10021] = UISlots,
        [10022] = UISlotGems,
        [10023] = UIAllGeneral,
        [10024] = UIOffGeneral,
        [10025] = UIEquips,
        [10026] = UISouls,
        [10027] = UIOffSouls,
        [10028] = UIGems,
        [10029] = UISelectList,
        [1003] = UISlotChange,
        [1004] = UICheerChange,
        [1005] = UISlotChangeEquip,
        [1006] = UISlotChangeSoul,
        [1007] = UIQuickEquip,
        [1008] = UIUpgradeSkill,
        [1009] = UISlotArrange,
        [1130] = UIMagicstoneUp,

        [1050] = UIProtagonistQuery,
        [1051] = UIProtagonistAddAttr,
        [1052] = UIProtagonistGrowUp,
        [1053] = UIProtagonistRecoverTrain,
        [1054] = UIUserProtagonist2,
        [1055] = UIUserProtagonist2AddAttr,
        [1056] = UIUserProtagonist2GrowupPreveiw,
        [1057] = UIUserProtagonist2Growup,

        [1020] = UICheckOtherSlotsInfo,
        [1021] = UIGeneralExchange,
        [10211] = UIGeneralExchangeQuery,
        [1025] = UIGeneralAwaken,
        [1058] = UIProtagonistAwaken,
        [1800] = UITechList,
        [18001] = UITechGeneralList,
        [1801] = UITechUpgrade,

        [1805] = UIDevilStatus,
        [1806] = UIDevilExchangeFragment,
        [1807] = UIDevilUp,
        [1808] = UIDevilStatus2,
        [1809] = UIDevilLevel1Exp,
        [1810] = UIDevilLevel2Up,

        [1040] = UIPetQuery,
        [1041] = UIPetLevel1Up,
        [1042] = UIPetLevel2Up,
        [1043] = UIPetSet,
        [1044] = UIPetFragment,
        [1045] = UIPetCompound,

        [1046] = UIPetStageUp,
        [1047] = UIPetPassiveSkill,
        [1048] = UIPetPassiveSkillStudy,
        [1049] = UIPetFragmentCompound,
        
        [1060] = UIPetPassiveSkillLock,
        [1061] = UIPetPassiveSkillReset,

        [1062] = UIPetLevel1Up2,

        [1064] = UIPetPassiveSkillRed,

        [1065] = UIPetReset,

        [1066] = UIPetDevour,

        [1022] = UIBattleOther,

        [1031] = UISomeIds,

        [1010] = UIGeneralInheritPreview,
        [1011] = UIGeneralInheritConfirm,
        [1012] = UIGeneralFragmentsList,
        [10121] = UIGeneralFragmentById,

        [1013] = UIGeneralFosterPreview,
        [1014] = UIGeneralFosterConfirm,

        [1016] = UIGeneralCompound,
        [1017] = UIGeneralBreak,
        [1023] = UIGeneralBreakPreview,

        [1038] = UIUseExpDan,

        [1026] = UIGeneralArtifactLevelup,
        [1029] = UIGeneralUpStar,

        [1018] = UIGameGeneralFragmentRobQuery,
        [1019] = UIGameGeneralFragmentRob,
        [1110] = UIGameTreasureFragmentRobQuery,
        [1111] = UIGameTreasureFragmentRob,
        [11111] = UIGameRobEquipQuery,
        [11112] = UIGameRobGeneralQuery,
        [1112] = UIRobProfCDquery,
        [1113] = UIRobProfCDAdd,
        [1114] = UIGameTreasureFragmentRobTen,
        [1125] = UIRobOneKeyTreasure,


        [1101] = UIEquipStrengthen,
        [1102] = UIEquipRefine,
        [1104] = UIEquipResolve,
        [1105] = UITreasureUp,
        [1106] = UITreasureRefine,

        [1115] = UIEquipRefineEx,
        [1116] = UITreasureRefineEx,

        [1118] = UITreasureStrengthen,
        [1119] = UITreasureRefine2,

        [1210] = UITreasureStrengthebyprop,

        [1107] = UIEquipFragmentAll,
        [11071] = UIEquipFragmentList,

        [1108] = UIEquipFragmentCompound,
        [1109] = UIQuickEquipStrengthen,

        [1120] = UIEquipBaptizePreview,
        [1121] = UIEquipBaptizeConfirm,

        [1122] = UIEquipStageUp,

        [1123] = UIEquipStarUp,

        [1124] = UIEquipBaptizeAutomatic,
        [1126] = UIGeneralFosterAutomatic,  --武将培养加上
        [1127] = UITreasureStarUp,  --宝物升星

        [2501] = UISoulHuntQuery,
        [2502] = UISoulHunt,
        [2503] = UISoulExchange,
        [2504] = UISoulUpgrade,
        [2505] = UISoulHunt41,
        [2506] = UISoulResolve,
        [2507] = UISoulCompound,

        [1402] = UIGeneralRecruitQuery,
        [1403] = UIGeneralRecruit,

        [1404] = UIOldDriverQuery,
        [1405] = UIOldDriverOpt,

        [1406] = UITigerchickenQuery,
        [1407] = UITigerchickenDo,
        [1408] = UITigerchickenshop,
        [1409] = UITigerchickenshopExchange,

        [1300] = UICopyQuery,
        [1301] = UICopyAttack,
        [1302] = UICopyWipe,
        [1306] = UICopyAttack2,
        [1307] = UICopyWipe2,
        [1303] = UICopyAll3StarReward,
        [1304] = UICopyPrestigeReward,
        [1305] = UICopyResetKill,
        [1340] = UIActivityCopy,
        [1341] = UIActivityCoinCopy,
        [1342] = UIActivityExpDanCopy,
        [1343] = UIActivityForgeStoneCopy,
        [1344] = UIActivityEquipStarCopy,
        [1345] = UIActivityZhenfuCopy,
        [1347] = UIActivityForgingCopy,
        [1348] = UIActivityOneFinshCopy,

        [1350] = UIGeneralCopyQuery,
        [1351] = UIGeneralCopyAttack,
        [1352] = UIGeneralCopyGetBox,

        [1370] = UIHadesCopyQuery,
        [1371] = UIHadesCopyAttack,
        [1372] = UIHadesCopyGetBox,

        [1330] = UIBraveCopyQuery,
        [1331] = UIBraveCopyAttack,
        [1332] = UIBraveCopyWipe,
        [1337] = UIBraveCopyAttack2,
        [1338] = UIBraveCopyWipe2,
        [1333] = UIBraveCopyAll3StarReward,
        [1334] = UIBraveCopyPrestigeReward,
        [1335] = UIBraveCopyResetKill,
        [1336] = UICopyClearTimer,

        [1310] = UIEncounterQuery,
        [13101] = UIEncounterQueryExt,
        [1311] = UIEncounterUse,
        [13111] = UIEncounterTimeUp,

        --[1320] = UIFriendCopyQuery,
        [13201] = UIFriendCopyFriendSelect,
        --[1321] = UIFriendCopyAttack,
        [1323] = UIFriendCopyQuery,
        [1324] = UIFriendCopyAttack,
        [1325] = UIFriendCopyOneFinish,
        [1322] = UIFriendCopyRank,

        --作妖2048
        [1600] = UIMiniGameQuery,
        [1601] = UIMiniGameSynchronization,
        [1602] = UIMiniGameOver,
        [1603] = UIMiniGameStart,
        [1604] = UIMiniGameExchange,
        [1605] = UIMiniGameAchievement,
        [1606] = UIMiniGameAchievementReward,
        [1607] = UIMiniGameRank,
        [1608] = UIMiniGameExchangeQuery,

        [1610] = UIAthleticsList,
        [1611] = UIAthleticsAttack,
        [1613] = UIAthleticsRewardsList2,
        [1614] = UIAthleticsRewardsExchange2,
        [1615] = UIAthleticsRankRewardsStatus,
        [1616] = UIAthleticsBoss,

        [1200] = UIPropsList,
        [1201] = UIPropsUse,
        [1203] = UIPropNumQuery,
        [12001] = UIPropQueryById,

        [20001] = UIActivityIsOpen,
        [2000] = UIActivityQuery,
        [2070] = UIBloodQuery,
        [2071] = UIBloodBattle,
        [2072] = UIBlood3AttrBufQuery,
        [2073] = UIBlood3AttrBuf,
        [2074] = UIBlood5AwardQuery,
        [2075] = UIBlood5Award,
        [2076] = UIBloodRankQuery,
        [2077] = UIBloodWipe,
        [2078] = UIBloodWipeReward,
        [2079] = UIBloodWipeContinue,
        -- [2085] = UIBloodExchange,

        [2085] = UIActivitySDKShareQuery,
        [2086] = UIActivitySDKShareDo,
        [20861] = UIActivitySDKShareOk,
        [2087] = UIActivitySDKShareReward,

        [28801] = UITimeBagTimeOver,
        [2880] = UITimeBag,
        [2881] = UITimeBagGet,
        [2882] = UITimeBagTrig,

        --[2030] = UIHappinessPlaceQuery,
        --[2031] = UIHappinessPlaceUse,
        --[2032] = UIHappinessPlaceRank,
        --[2033] = UIHappinessPlaceExchange,
        --[2034] = UIHappinessPlaceExchange,

        [2031] = UICornucopiaQuery,
        [2032] = UICornucopia,
        [2033] = UICornucopiaReward,

        [2035] = UIActivityStartGiftQuery,
        [2036] = UIActivityStartGift,

        [2022] = UIDayDayGift,
        [2023] = UIDayDayGiftReward,

        [3310] = UIDayDayGiftX1,
        [3311] = UIDayDayGiftX1Reward,

        [2024] = UIRechargeGift,
        [2025] = UIRechargeGiftReward,

        [2020] = UIConsumeGift,
        [2021] = UIConsumeGiftReward,

        [2010] = UIActivityEatChickenQuery,
        [2011] = UIEatChicken,
        [2015] = UIActivityMammonQuery,
        [2016] = UIActivityMammon,
        [2017] = UIActivityMammonBroadcast,
        [2060] = UISignInStatus,
        [2061] = UISignIn,

        --[2040] = UIPenglai,
        [2041] = UIPenglaiSelectDifficulty,
        [2042] = UIPenglaiSearch,
        [2043] = UIPenglaiBattle,
        [2044] = UIPenglaiRank,
        [2045] = UIPenglaiTodayReward,
        [2046] = UIPenglaiTotal,
        [2047] = UIPenglaiTotalReward,
        [2048] = UIPenglaiTask,
        [2049] = UIPenglaiTaskReward,

        [2110] = UIIsland,
        [2111] = UIIslandGoto,
        [2112] = UIIslandNext,
        [2113] = UIIslandGetTodayReward,
        [2114] = UIIslandTask,
        [2115] = UIIslandTaskReward,
        [2116] = UIIslandRank,
        [2117] = UIIslandGlobal,
        [2118] = UIIslandGlobalReward,

        [2120] = UIPenglai3,
        [2121] = UIPenglai3Dice,
        [2122] = UIPenglai3Reward,
        [2123] = UIPenglai3Reset,
        [2124] = UIPenglai3Card,
        [2125] = UIPenglai3CardOpen,
        [2126] = UIPenglai3CardClose,
        [2127] = UIPenglaiAutoReward,
        [2128] = UIPenglaiAutoReward2,

        [2050] = UIMysticalCave,
        [2051] = UIMysticalCaveForecast,
        [2052] = UIMysticalCaveReversion,
        [2053] = UIMysticalCaveConfirm,
        [2054] = UIMysticalReward,
        [2055] = UIExchange,
        [2056] = UIExchangeEX,
        [2057] = UIExchangeRefresh,

        [2062] = UIWatchStarQuery,
        [2063] = UIWatchStarWatch,
        [2064] = UIWatchStarChange,
        [2065] = UIWatchStarGet,
        [2066] = UIWatchStarReward,
        [2067] = UIWatchStarWatchEx,
        [2068] = UIWatchStarUpLevel,


        [2300] = UIFriendQuery,
        [2301] = UIFriendRecommend,
        [2302] = UIFriendReq,
        [2303] = UIFriendReqQuery,
        [2304] = UIFriendRep,
        [2305] = UIFriendChatQuery,
        [2306] = UIFriendChat,
        [2307] = UIFriendSearch,
        [2308] = UIFriendSendGift,
        [2309] = UIFriendRecvGift,
        [2310] = UIFriendDelete,
        [2311] = UIFriendAllReq,
        [6038] = UIFriendAllAdd,

        [2400] = UITaskQuery,
        [2401] = UITaskComplete,

        [2410] = UILiveness,
        [2411] = UILivenessReward,

        [2100] = UICupStatus,
        [2101] = UICupJoinTomorrow,
        [2102] = UICupTop,
        [21021] = UICupTopSee,
        [2103] = UICupBattlePlay,
        [2104] = UICupBattleReward,
        [2105] = UICupBattleBet,
        [2106] = UICupBattleRewardall,

        [2107] = UICupRank,

        [2200] = UIGangStatus,
        [2201] = UIGangCreate,
        [2202] = UIGangs,
        [2203] = UIGangReq,
        [2204] = UIGangReqQuery,
        [2205] = UIGangReqRep,
        [2206] = UIGangMember,
        [2207] = UIGangKickMember,
        [2208] = UIGangQuit,
        [2209] = UIGangPassPower,
        [2210] = UIGangSetAssistant,
        [2211] = UIGangSetAnnouncement,
        [2219] = UIGangRemoveAssistant,
        [2220] = UIGangsearch,

        [2230] = UIGangUserGang2,
        [2231] = UIGangUserGang2Create,
        [2232] = UIGangUserGang2List,
        [2233] = UIGangUserGang2Req,
        [2234] = UIGangUserGang2ReqQuery,
        [2235] = UIGangUserGang2Rep,
        [2236] = UIGangUserGang2Member,
        [2237] = UIGangUserGang2MSetContent1,
        [2238] = UIGangUserGang2MSetContent2,
        [2239] = UIGangUserGang2MSetVice,
        [2240] = UIGangUserGang2MKick,
        [2241] = UIGangUserGang2MPass,
        [2242] = UIGangUserGang2Quit,
        [2243] = UIGangUserGang2Search,

        [2250] = UIGangUserGang2PrayQuery,
        [2251] = UIGangUserGang2Pray,
        [2252] = UIGangShopGoodsView,
        [2253] = UIGangShopBuyGoods,
        [2254] = UIGangUserGang2Opts,
        [2255] = UIGangUserGang2Impeach,
        [2256] = UIGangUserGang2Fishpond,
        [2257] = UIGangUserGang2FishpondFeed,
        [2258] = UIGangUserGang2FishpondReward,
        [2259] = UIGangUserGang2MSetName,
        [2260] = UIGangUserGang2DailyReward,
        [2261] = UIUserGang2FishpondPointRank,
        [2262] = UIGang2Skill,
        [2263] = UIGang2SkillStudy,

        [2265] = UIGangApplyLimit,
        [2266] = UIUserGang2Disband,

        [2267] = UIUserGang2ReqCancel,

        [2312] = UIFriendChatList,
        [2313] = UIFriendHasChat,

        [2610] = UIDevilFotressStatus,
        [2611] = UIDevilFotressGangDef,
        [2612] = UIDevilFotressGangDefSet,
        [2613] = UIDevilFotressGangDefs,
        [2614] = UIDevilFotressGangProciam,
        [2616] = UIDevilFtoressTarget,
        [2617] = UIDevilFotressAutoBattle,
        [2618] = UIDevilFotressTargetBattle,
        [2600] = UIDevilFotressBattleNotify,

        [2089] = UIUserCDKeyExchange,

        [3000] = UIUserChatQuery,
        [3001] = UIUserChat,
        [3002] = UIFriendAllShield,
        [3003] = UIFriendAddShield,
        [3004] = UIFriendDeleteShield,
        [3010] = UIUserGangChatQuery,
        [3011] = UIUserGangChat,
        [3012] = UIUserChatNumReset,
        [3015] = UIBroadcastQuery,
        [30001] = UIUserCrossChat,

        [3200] = UIShopQuery,
        [3210] = UIGiftBagQuery,
        [3201] = UIShopBuy,
        [3211] = UIGiftBagBuy,

        [3100] = UIMailList,
        [3101] = UIMailRead,
        [3102] = UIMailDelete,
        [3103] = UIMailSend,

        [3400]  = UIWorldBoss1Query,
        [3401]  = UIWorldBoss1Attack,
        [3402]  = UIWorldBoss1Rank,
        [3403]  = UIWorldBoss1RealNotify,
        [3404]  = UIWorldBoss1PreRank,

        [3410]  = UIWorldBoss2Query,
        [3411]  = UIWorldBoss2Attack,
        [3412]  = UIWorldBoss2Rank,
        [3413]  = UIWorldBoss2RealNotify,
        [3414]  = UIWorldBoss2PreRank,
        [3415]  = UIWorldBoss2OfflineBattle,
        [3416]  =UIWorldBoss2OfflineBattleResult,

        [2037] = UIOnlineRewardQuery,
        [2038] = UIOnlineReward,
        [2039] = UIOnlineRewardByTimeQuery,
        [2040] = UIOnlineRewardByTime,

        [3500]  = UIRankQuery,
        [3501]  = UIRankChange,
        [35001]  = UIRankMydataQuery,
        [3503]  = UIOldRankQuery,

        [3600] = UIZhuxiantaiQuery,
        [3601] = UIZhuxiantaiBattle,
        [3602] = UIZhuxiantaiWipe,
        [3603] = UIZhuxiantaiAttrQuery,
        [3604] = UIZhuxiantaiAttrSelect,
        [3605] = UIZhuxiantaiRank,
        [3606] = UIZhuxiantaiExchange,
        [36061] = UIZhuxiantaiExchangeQuery,
        [3607] = UIZhuxiantaiReset,

        [3615] =UIActivityShopQuery,
        [3616] =UIActivityShop,
        [3617] =UIActivityShopReset,

        [3630] =UIActivityBlackShopQuery,
        [3631] =UIActivityBlackShop,
        [3632] =UIActivityBlackShopReset,


        [3650] =UIActivitySecretShopQuery,
        [3651] =UIActivitySecretShop,
        [3652] =UIActivitySecretShopReset,

        [3660] =UIRobShop,
        [3661] =UIRobShopBuy,

        

        [1999] = UIBroadcast,

        [3610] = UIBegin7Days,
        [36101] = UIBegin7DaysExt,
        [3611] = UIBegin7DaysReward,

        [3620] = UIMieshendianQuery,
        [36201] = UIMieshendianBossQuery,
        [3621] = UIMieshendianBattle1,
        [3622] = UIMieshendianBattle2,
        [3623] = UIMieshendianModup,
        [3624] = UIMieshendianModupCDClear,
        [3625] = UIMieshendianRank,
        [3626] = UIMieshendianReset,
        [3627] = UIMieshendianShop,
        [3628] = UIMieshendianShopBuy,

        [3641] = UISignIn2Status,
        [3642] = UISignIn2,
        [3643] = UILuxurySignInStatus,
        [3644] = UILuxurySignIn,
        [3680] = UIMonthGrowQuery,
        [3681] = UIMonthGrowGetReward,
        [3682] = UIMonthGrowWelfareQuery,
        [3683] = UIMonthGrowWelfareGetReward,

        [3684] = UIMonthGrowQueryX1,
        [3685] = UIMonthGrowGetRewardX1,
        [3686] = UIMonthGrowWelfareQueryX1,
        [3687] = UIMonthGrowWelfareGetRewardX1,

        --神奇基金
        [3688] = UIMagicFundQuery,
        [3689] = UIMagicFundReward,

        [3690] = UIShareActivityQuery,
        [3691] = UIShareActivity,


        [3790] = UIActivityMammonQuery2,
        [3791] = UIActivityMammon2,
        [3792] = UIActivityMammonBroadcast2,

        [4010] = UITitbitDiscountQury,
        [4011] = UITitbitDiscountBuy,
        [4012] = UITitbitDiscountX1Qury,
        [4013] = UITitbitDiscountX1Buy,
        [4014] = UITitbitDiscountX2Qury,
        [4015] = UITitbitDiscountX2Buy,
        [4016] = UITitbitDiscountX3Qury,
        [4017] = UITitbitDiscountX3Buy,

        [4018] = UICPTitbitDiscountX1Qury,
        [4019] = UICPTitbitDiscountX1Buy,
        [4020] = UICPTitbitDiscountX2Qury,
        [4021] = UICPTitbitDiscountX2Buy,
        [4022] = UICPTitbitDiscountX3Qury,
        [4023] = UICPTitbitDiscountX3Buy,
        [4024] = UICPTitbitDiscountX4Qury,
        [4025] = UICPTitbitDiscountX4Buy,
        [8034] = UICPTitbitDiscountX5Qury,
        [8035] = UICPTitbitDiscountX5Buy,

        [4000] = UIGrowPlanGlobal,
        [4001] = UIGrowPlanGlobalReward,

        [4100] = UIWuDaoHuiQuery,
        [4101] = UIWuDaoHuiPiPei,
        [4102] = UIWuDaoHuiPiPeiSuceccs,
        [4103] = UIWuDaoHuiBoxReward,
        [4104] = UIWuDaoHuiReport,
        [4105] = UIWuDaoHuiLotteryQuery,
        [4106] = UIWuDaoHuiLotteryReward,
        [4107] = UIWuDaoHuiDuanWeiQuery,
        [4108] = UIWuDaoHuiDuanWeiReward,

        [3670] = UIGeneralLove,
        [3671] = UIGeneralsLoveQuery,
        [3672] = UIGeneralLoveUseProp,
        [3673] = UIGeneralLoveTask,
        [3674] = UIGeneralLoveTaskReward,
        [3675] = UIGeneralLoveExchange,

        
        [2130] = UIGuildWarPointCatalogue,
        [2131] = UIGuildWarTreasureInfo,
        [2132] = UIGangPointJoinConfirm,
        [2133] = UIGangPointJoinQuery,
        [2134] = UIGangPointEnterBattlefield,
        [2135] = UIGangPointJoinBattle,
        [2136] = UIGangPointInspireCoin,
        [2137] = UIGangPointInspireGold,
        [2143] = UIGangPointMembers,
        [2142] = UIGuildWarPointAward,

        [2138] = UIGangPointBattleStatusQuery,
        [2140] = UIGangPointSumBattleList,
        [2139] = UIGangPointSumBattlePlay,
        [2141] = UIGangPointBraBattlePlay,

        [2149] = UIMainGetGangData,

        [2144] = UIGuildWarProfit,
        [2145] = UIGuildWarProfitChange,
        [2146] = UIGuildWarOneInspire,
        [2147] = UIGuildWarOneBattle,
        --错误信息相关
        [9999] = UIErrorMessage,
        [9997] = UIErrorMessage7,
        [9998] = UIshowloginlog,

        --设置推送
        [999] = UIGlobalParam,

        --获取武将，装备，物品，个数
        [12002] = UIGetStaffNum,


        -- 乾坤炉
        [1036] = UIGeneralFragmentResolve,

        [1039] = UIGeneralResolve2,
        [3850] = UIResolveQuality,

        -- 腾讯登录
        [10000] = UITCLoginResult,
        [10002] = UITCLoginResult2,
        
        [1104] = UIEquipResolve,
        [1035] = UIGeneralReset,
        [1117] = UIEquipReset,
        [1037] = UIGeneralResolve,
        [1077] = UIFashionDressReset,


        [3700] = UISingleBossQuary,
        [3701] = UISingleBossBattle,


        [3702] = UISlotsArrangeQuary,
        [3703] = UISlotsArrange,

        [3704] = UISlotsExcept,
        [3705] = UIKingmanOnekeyChallengeBack,


        [3740] = UIWingQuary,
        [3741] = UIWingSatrUp,
        [3742] = UIWingStageUp,
        [3743] = UIWingDyeing,
        [3744] = UIWingColorQuery,

        [1140] = UISigilLevelUp,
        [1141] = UISigilChangePos,
        [1142] = UISigilCanLevelUp,

        [1360] = UIInstrumentQuery,
        [1361] = UIInstrumentUnlock,
        [1362] = UIInstrumentForgePreview,
        [1363] = UIInstrumentForgeConfirm,
        [1364] = UIInstrumentForgeAutomatic,
        [1365] = UIBreakForgePreview,


        [3800] = UIMazeQuery,

        [3801] = UIMazeMove,
        [3802] = UIMazeRandomEvent,
        [3803] = UIMazeBattle,
        [3812] = UIMazeReset,
        [3806] = UIMazeShopQuery,
        [3810] = UIMazeShopRefresh,
        [3807] = UIMazeShopBuy,
        [3808] = UIMazeTaskQuery,
        [3809] = UIMazeTaskGetReward,


        [3811] = UIEnemySlotsQuary,
        [3804] = UISlotsWithHpQuary,
        [3805] = UISlotsChangeWithHp,


        [3820] = UIOverPassQuery,
        [3821] = UIOverPassRank,
        [3822] = UIOverPassShop,
        [3823] = UIOverPassShopBuy,
        [3824] = UIOverPassBattle,
        [3825] = UIOverPassRankRefresh,
        [3826] = UIOverPassChangeBoss,
        [3827] = UIOverPassGetReward,
        [3828] = UIOverPassRefresh,
        [3829] = UIOverPassRecordQuery,
        [3830] = UIOverPassRecordPlay,
        [3831] = UIOverPassRecordUpdate,


        [116000] = UIRechargeSucPre,
        [116001] = UIRechargeRsNotFd,

        [2700] = UIChampionStatus,
        [2701] = UIChampionBattle,
        [2702] = UIChampionNext,
        [2703] = UIChampionReset,
        [2704] = UIChampionBoxOpen,
        [2705] = UIChampionComplete,

        [2710] = UIChampionShopQuery,
        [2711] = UIChampionShop,
        [2712] = UIChampionShopReset,


        [3300] = UIDuanWuQuery,
        [3301] = UIDuanWuLotteryQuery,
        [3302] = UIDuanWuDuihuan,

        [4630] = UITurntableQuery,
        [4631] = UITurntableLottery,

        [4650] = UIDivideStallCarnivalQuery,
        [4651] = UIDivideStallCarnivalDraw,

        [4660] = UIIntegralTurntableQuery,
        [4661] = UIIntegralTurntableLuckDraw,

        [3306] = UIDumplingSearch,
        [3307] = UIDumplingUsed,

        [3720] = UIProtagonistGameQuery,
        [3721] = UIProtagonistGameEatBeans,
        [3722] = UIProtagonistGamePopcorn,


        [3733] = UISafeMaskShopQuery,
        [3734] = UISafeMaskShopReward,

        [6451] = UIJinghuaShopQuery,
        [6452] = UIJinghuaShopReward,

        [3730] = UISlotCoverQuery,
        [3731] = UISlotCoverup,
        [3732] = UISlotCoverMasterQuery,
        [3735] = UISlotCoverLevel2Up,
        [3736] = UISlotCoverFeiSheng,


        [3901] = UIDragonBoatSearch,
        [3902] = UIDragonBoatUsed,

        [1070] = UIFashionDressQuery,
        [1071] = UIFashionDressHide,
        [1072] = UIFashionDressStrange,
        [1073] = UIFashionDressChange,

        [1074] = UIFashionDressGet,
        [1075] = UIFashionDressActQuery,
        [1076] = UIFashionDressShopQuery,

        [4310] = UIGodDownShopQuery,
        [4311] = UIGodDownShopReward,
        [4320] = UIGodDownRankQuery,

        [4200] = UISlotSpiritQuery,
        [4201] = UISlotSpiritUse,
        [4202] = UISlotSpiritLevelup,
        [4203] = UISlotSpiritChange,
        [4204] = UISlotSpiritAdditionQuery,

        [4300] = UIGodDownQuery,
        [4301] = UIGodDownTribute,
        [4302] = UIGodDownTributeReward,
        [4303] = UIGodDownTributeImmediate,
        [4304] = UIGodDownGift,


        [4400] = UIActivityQShopQuery,
        [4401] = UIActivityQShopReward,

        [4405] = UIChristmasShopQuery,
        [4406] = UIChristmasShopReward,

        [4600] = UIMidAutumnShopQuery,
        [4601] = UIMidAutumnShopReward,

        [4602] = UIMidAutumnShopQuery_x1,
        [4603] = UIMidAutumnShopReward_x1,

        [3750] = UISingleRechargeGift,
        [3751] = UISingleRechargeGiftReward,

        [3755] = UISingleRechargeGiftX1,
        [3756] = UISingleRechargeGiftRewardX1,

        [5062] = UISingleRechargeGift_X2,
        [5063] = UISingleRechargeGiftReward_X2,

        [3758] = UISingleRechargeGiftX2,
        [3759] = UISingleRechargeGiftRewardX2,

        [4705] = UIWorldWarSignInfoQuer,
        [4706] = UIWorldWarChampionQuer,
        [4707] = UIWorldWarGroupInfoQuery,

        [4710] = UIWorldWarTopInfo,
        [4713] = UIWorldWarTopBetInfo,
        [4715] = UIWorldWarRankQuery,
        [4716] = UIWorldWarWeedBet,
        [4717] = UIWorldWarCurrentChampionQuery,
        [4718] = UIWorldWarWorship,

        [4720] = UIWorldWarRoleBattlesShenbang,
        [4721] = UIWorldWarTopShenbang,
        [4722] = UIWorldWarWeedBetShenbang,
        [4723] = UIWorldWarRoleBattlesRewardShenbang,
        [4724] = UIWorldWarTopUserInfoShenbang,
        [4725] = UIWorldWarTopInfoShenbang,
        [4726] = UIWorldWarTopBetInfoShenbang,
        [4727] = UIWorldWarBattlePlayShenbang,
        [4728] = UIWorldWarRankQueryShenbang,

        [6701] = UIHonorWarSlotQuery,
        [6702] = UIHonorWarSlotArrange,
        [6503] = UIHonorWarStatusQuery,
        [6504] = UIHonorWarRoleBattles,
        [6505] = UIHonorWarRoleBattlesReward,
        [6506] = UIHonorWarRoleBattlesInfo,
        [6507] = UIHonorWarBattlePlay,
        [6508] = UIHonorWarTop,
        [6509] = UIHonorWarWeedBet,
        [6510] = UIHonorWarChampionQuery,
        [6511] = UIHonorWarGroupInfoQuery,
        [6512] = UIHonorWarTopUserInfo,
        [6513] = UIHonorWarLastChampionQuery,
        [6514] = UIHonorWarStarRankQuery,
        [6515] = UIHonorWarSignup,
        [6516] = UIWeekLiveness,
        [6517] = UITotalLiveness,
        [6530] = UIWeekLiveness2,

        [6518] = UIAchievementQuery,
        [6519] = UIAchievementReward,

        [20051] = UIActivityEveryday,

        [4700] = UIWorldWarPrepareQuery,
        [4701] = UIWorldWarGetItem,
        [4702] = UIWorldWarQuery,
        [4704] = UIWorldWarPrepareUpdateSlot,
        [4703] = UIWorldWarRoleBattles,
        [4711] = UIWorldWarBattlePlay,
        [4708] = UIWorldWarTop,
        [4712] = UIWorldWarTopUserInfo,
        [4714] = UIWorldWarRoleBattlesReward,
        [4709] = UIWorldWarPreparePush,

        [3760] = UIAchievementLimitTime,
        [3761] = UIAchievementLimitTimeReward,

        [3765] = UIOctober1st,
        [3766] = UIOctober1stReward,
        [37651] = UIOctober1stExt,

        [4880] = UISevenDayActivity,
        [4881] = UISevenDayActivityReward,
        [48801] = UISevenDayActivityExt,

        [4611] = UIVipWelfareExchange,
        [46111] = UIVipWelfareExt,

        [3770] = UIRecall,
        [3771] = UIRecallReward,

        [3772] = UIReturn,
        [3773] = UIReturnReward,
        [37721] = UIReturnExt,
        [3774] = UIReturnCDK,
        [3776] = UIRecallChange,

        [1346] = UIActivityCopyModUp,

        [3780] = UIGeneralBestQuery,
        [10030] = UIRedFragments,

        [4615] = UITimeGift,
        [4616] = UITimeGiftReward,

        [4719] = UIWorldWarChampionSlotInfo,

        [4800] = UITriggerGiftQuery,
        [4801] = UITriggerGiftReward,
        [4802] = UITriggerGiftPush,

        [4620] = UIPropRecovery,

        [4635] = UITurntableWorldQuery,
        [4636] = UITurntableWorldDraw,

        [4810] = UIAuctionHouseQuery,
        [4811] = UIAuctionHouseAuction,
        [4812] = UIAuctionHouseGet,
        [4813] = UIAuctionHouseLog,
        [4814] = UIAuctionHouseOpts,
        [4815] = UIAuctionHouseChange,

        [4820] = UIManorQuery,
        [4821] = UIManorFriendListQuery,
        [4822] = UIManorLevelUp,
        [4823] = UIManorGetWood,
        [4824] = UIManorNoticeQuery,
        [4825] = UIManorChange,
        [4826] = UIManorNoticeGetTask,
        [4827] = UIManorNoticeDoneTask,
        [4828] = UIManorYaoBattle,
        [4829] = UIManorShop,
        [4830] = UIManorShopExchange,
        [4831] = UIManorConcent,

        [4860] = UITotalRechargeQuery,
        [4861] = UITotalRechargeGetReward,

        [4840] = UIGang2Boss,
        [4841] = UIGang2BossRank,
        [4842] = UIGang2RoleRank,
        [4843] = UIGang2BossInspire,
        [4844] = UIGang2BossBattle,
        [4845] = UIGang2BossNotify,
        [4846] = UIGang2BossChange,

        [4850] = UIRechargeRebate,
        [4851] = UIRechargeRebateGet,

        [4875] = UIKGodDownShopQuery,
        [4876] = UIKGodDownShopReward,
        [4877] = UIKGodDownRankQuery,

        [4870] = UIKGodDownQuery,
        [4871] = UIKGodDownTribute,
        [4872] = UIKGodDownTributeReward,
        [4873] = UIKGodDownTributeImmediate,
        [4874] = UIKGodDownGift,

        [4885] = UITurntableRecord,

        [4890] = UIVipWeekGift,
        [4891] = UIVipWeekGiftReward,

        [3860] = UIGambling,
        [3861] = UIGamblingReward,
        [3862] = UIGamblingShop,
        [3863] = UIGamblingShopReward,

        [4006] = UIRechargeDouble2,

        [4901] = UIDragonWishingQuery,
        [4902] = UIDragonWishingGet,
        [4903] = UIDragonWishingReward,
        [4904] = UIDragonWishingEvent,
        [4905] = UIDragonWishingEventClose,
        [4906] = UIDragonWishingShop,
        [4907] = UIDragonWishingQueryMap,

        [5002] = UICPDayDayGift,
        [5003] = UICPDayDayGiftReward,
        [5000] = UICPRechargeGift,
        [5001] = UICPRechargeGiftReward,
        [5010] = UICPGodDownQuery,
        [5011] = UICPGodDownTribute,
        [5012] = UICPGodDownTributeReward,
        [5013] = UICPGodDownTributeImmediate,
        [5014] = UICPGodDownGift,
        [5015] = UICPGodDownShopQuery,
        [5016] = UICPGodDownShopReward,
        [5017] = UICPGodDownRankQuery,
        [5020] = UICPTigerchickenQuery,
        [5021] = UICPTigerchickenDo,
        [5022] = UICPTigerchickenshop,
        [5023] = UICPTigerchickenshopExchange,
        [5025] = UICPAchievementLimitTime,
        [5026] = UICPAchievementLimitTimeReward,
        [5030] = UICPTitbitDiscountQury,
        [5031] = UICPTitbitDiscountBuy,
        [5032] = UICPOldDriverQuery,
        [5033] = UICPOldDriverOpt,
        [5034] = UICPRechargeDouble,
        [5035] = UICPActivityQShopQuery,
        [5036] = UICPActivityQShopReward,
        [5037] = UICPTurntableQuery,
        [5038] = UICPTurntableLottery,
        [5039] = UICPConsumeGift,
        [5040] = UICPConsumeGiftReward,
        [5041] = UICPRechargeRebate,
        [5042] = UICPRechargeRebateGet,
        [5043] = UICPActivityShopQuery,
        [5044] = UICPActivityShop,
        [5045] = UICPActivityShopReset,
        [5046] = UICPContinue7Query,
        [5047] = UICPContinue7Reward,

        [5321] = UIGeneralRecruitShopQuery,
        [5322] = UIGeneralRecruitReward,        

        [5323] = UIActivityTreeQuery,
        [5324] = UIActivityTreeWater,
        [5325] = UIActivityTreetask,
        [5326] = UIActivityTreetaskGet,
        [5327] = UIActivityTreetaskcancel,
        [5328] = UIActivityWaterBuy,
        [5329] = UIActivityTreetaskFresh,
        [5330] = UIActivityBoxreward,

        [5048] = UICPSevenDayActivity,
        [5049] = UICPSevenDayActivityReward,

        [4886] = UICPDiZaoShenHuaActivity,
        [4887] = UICPDiZaoShenHuaActivityReward,
        [48861] = UICPDiZaoShenHuaActivityExt,

        [4888] = UICPTianXiaWuShuangActivity,
        [4889] = UICPTianXiaWuShuangActivityReward,
        [48881] = UICPTianXiaWuShuangActivityExt,


        [5150] = UIGang2GroundQuery,
        [5151] = UIGang2GroundStart,
        [5152] = UIGang2GroundGetHogs,
        [5153] = UIGang2GroundCatchHog,
        [5154] = UIGang2GroundBoxRewards,
        [5155] = UIGang2GroundRank,
        [5156] = UIGang2GroundGameOver,

        [5309] = UIActivityZhounianRandom,
        [5310] = UIActivityZhounianQuery,
        [5311] = UIActivityZhounianPray,
        [5312] = UIActivityZhounianTask,
        [5313] = UIActivityZhounianTaskGet,
        [5314] = UIActivityZhounianTaskFresh,
        [5318] = UIActivityZhounianTaskCancel,

        [5315] = UIActivityChaozhiQuery,
        [5316] = UIActivityChaozhiBuy,
        [5317] = UIActivityChaozhiGet,
        

        [50481] = UICPSevenDayActivityExt,

        [5050] = UICPSingleRechargeGift,
        [5051] = UICPSingleRechargeGiftReward,
        [5052] = UICPLimitTimeExchangeQuery,
        [5053] = UICPLimitTimeExchange,
        [5054] = UICPLimitTimeExchangeRefresh,
        [5055] = UICPTotalRechargeQuery,
        [5056] = UICPTotalRechargeGetReward,
        [5057] = UICPIntegralTurntableQuery,
        [5058] = UICPIntegralTurntableLuckDraw,

        [5060] = UICPSingleRechargeGiftX1,
        [5061] = UICPSingleRechargeGiftRewardX1,

        [5301] = UIDaoGuanMain,
        [5302] = UIDaoGuanGetReward,
        [5303] = UIDaoGuanGoTo,
        [5304] = UIDaoGuanDare,
        [5305] = UIDaoGuanFightNote,
        [5306] = UIDaoGuanArrangeQuary,

        [100010] = UIFirstEnterGame,
        [100011] = H5CallBack,

        [5201] = UIHeroBossQuery,
        [5202] = UIHeroBossFollow,
        [5203] = UIHeroBossEnter,
        [5204] = UIHeroBossAttack,
        [5205] = UIHeroBossCheer,
        [5206] = UIHeroBossRank,
        [5207] = UIHeroBossRealNotify,
        [5208] = UIHeroBossAwardRecord,
        [5209] = UIHeroBossRevive,
        [5210] = UIHeroBossDead,
        [5211] = UIHeroBossDouble,
        [5212] = UIHeroBossChangeNum,

        [5319] = ForeverRechargeQuery,
        [5320] = ForeverRechargeReward,

        [5331] = UIActivityZhongshuRank,

        [5345] = UIActivityBuyItem,
        [5346] = UITurntableRecordCommon,

        [5401] = UIActivityPeentoGiftQuery,
        [5402] = UIActivityPeentoGiftReward,
        [5403] = UIActivityPeentoGiftReset,
        [5501] = UIArtifactCast,
        [5502] = UIArtifactCommpond,
        [5503] = UIArtifactChange,
        [5504] = UIArtifactOpenPos,
        [5505] = UIArtifactMountJewel,
        [5506] = UIJewelUpgrade,
        [5507] = UIJewelCommpond,
        [5508] = UIArtifactCheck,
        [5509] = UIArtifactCheckTime,

        -- 一键打造
        [5515] = UIUserArtifactOnceMake,
        -- 一键鉴定
        [5516] = UIUserArtifactOnceCheckup,
        -- 一键重铸
        [5517] = UIUserArtifactRecast,
         -- 神器锁定
        [5518] = UIUserArtifactLock,
        -- 神器强化
        [5519] = UIUserArtifactStrengthen,
        -- 神器重生
        [5520] = UIUserArtifactRenascence,

        [5540] = UIUserArtifactOpening,
        [5541] = UIUserArtifactBaptize,
        [5542] = UIUserArtifactBaptizeReplace,
        [5543] = UIUserArtifactSkillUp,
        [5544] = UIUserArtifactSkillWashCancel,
        [5545] = UIUserArtifactSkillExchange,
        [5546] = UIUserArtifactStrenExchange,


        [5511] = UIGeneralXiuLianLevelInfo,
        [5512] = UIGeneralXiuLianInfo,
        [5513] = UIGeneralXiuLian,

        [5521] = UIEquipCast,

        [5525] = UIWeekGift,
        [5526] = UIWeekGiftReward,
        [6405] = UIAutoMoFuQuery,
        [6406] = UIAutoMoFuCompose,

        [10031] = UIJewelListData,
        [10032] = UIArtifactData,

        [5601] = UIActivityNewRankQuery,

        [5602] = UIActivityNewRankGet,
        [5603] = UIActivityPowerGrowthX2,

        [5801] = UIActivityWeekCardQuery,
        [5802] = UIActivityWeekCardActive,
        [5803] = UIActivityWeekCardReward,
        [5804] = UIActivityWeekCardTips,


        [5701] = UITotalRechargeQueryX1,
        [5702] = UITotalRechargeGetRewardX1,

        [5410] = UIActivityAuctionQuery,
        [5411] = UIActivityAuctionClinch,
        [5412] = UIActivityAuctionRecording,
        [5413] = UIActivityAuctionEnd,
        [5414] = UIActivityAuctionIsend,
        [5415] = UIActivityAuctionOnekey,


        [5901] = UILimitPropListQuery,
        [5902] = UILimitPropUse,


        [6001] = UIKingBattleQuery,
        [6002] = UIKingBattleMatch,
        [6003] = UIKingBattleMatchSuccess,
        [6004] = UIKingBattleGlorySelect,
        [6005] = UIKingBattleDailyRewardQuery,
        [6006] = UIKingBattleDailyRewardReceive,
        [6007] = UIKingBattleSegmentQuery,
        [6008] = UIKingBattleSegmentReceive,
        [6009] = UIKingBattleGloryQuery,
        [6010] = UIKingBattleLogsQuery,
        [6011] = UIKingBattleReplay,
        [6012] = UIKingBattleRevenge,
        [6015] = UIKingBattleShopQuery,
        [6016] = UIKingBattleShopReward,

        [5531] = UIMonthGrowQueryX2,
        [5532] = UIMonthGrowGetRewardX2,
        [5533] = UIMonthGrowWelfareQueryX2,
        [5534] = UIMonthGrowWelfareGetRewardX2,

        [6101] = UIPoolingServerSignQuery,
        [6102] = UIPoolingServerSignGetReward,
        [6103] = UIPoolingServerTaskQuery,
        [6104] = UIPoolingServerTaskGetReward,
        [6105] = UIPoolingServerOnlineQuery,
        [6106] = UIPoolingServerOnlineGetReward,
        -- 地狱副本
        [6111] = HellCopyQuery,
        [6112] = HellCopyChallenge,
        [6113] = HellCopyRefreshPlayerBuff,
        [6114] = HellCopyGetReward,
        [6115] = HellCopyChoosePlayerBuff,
        [6116] = HellCopyRefreshBossBuff,
        [6117] = UINewRankQuery,

        --称号、头像框
        [6301] = UITitleQuery,
        [6302] = UITitleUse,
        [6303] = UITitleLose,
        [6304] = UITitleGet,
        [6201] = UIIconBoxQuery,
        [6202] = UIIconBoxUse,
        [6203] = UIIconBoxLose,
        [6204] = UIIconBoxGet,

        --商会
        [61200] = UICanSell,
        [6120] = UIGoodsSell,
        [6121] = UIGoodsRevoke,
        [6122] = UIGoodsBuy,
        [6123] = UIGoodsProtectQuery,
        [6124] = UIGoodsResetSell,
        -- 中秋
        [6401] = UIZhongQiuActivity,
        [6402] = UIZhongQiuActivityReward,
        [64011] = UIZhongQIuActivityExt,

        [6601] = UIActivityChristmasQuery,
        [6602] = UIActivityChristmasDo,
        [6603] = UIActivityChristmasReward,
        [6604] = UIActivityChristmasReward2,

        [6501] = UIActivityHolidayQuery,
        [6502] = UIActivityHolidayDo,

        [6801] = UIActivityTimebuyQuery,
        [6802] = UIActivityTimebuyList,
        [6803] = UIActivityTimebuyReward,

        [6901] = UIRedfragmentResolve,

        [6910] = UIPartnerFashionBuy,
        [6911] = UIPartnerFashionQuery,
        [6912] = UIPartnerFashionUse,
        [6913] = UIPartnerFashionRecovery,
        [6914] = UIPartnerFashionHasRecovery,
        [7001] = UIPartnerFeiSheng,
        [6810] = UIPlayerBackTips,
        [6811] = UIPlayerBackQuery,
        [6812] = UIPlayerBackReward,

        [7021] = UIGeneralChangeBreakSkill,

        [6520] = UIBlessingCaveStatusQuery,
        [6521] = UIBlessingCaveAttack,
        [6522] = UIBlessingCaveSweep,

        --转换
        [7025] = UIGeneralChange,
        --互换
        [8095] = UISwapChange,
        --武将觉醒重生
        [8096] = UIGeneralAwakenRebirth,
        --查询单个武将信息
        [8097] = UIQueryGeneralById,
        --武将升星重生
        [8301] = UIGeneralUpStarRebirth,

        --神魂殿
        [7030] = UIGodSoulTempleQuery,
        [7031] = UIGodSoulTempleLevelUp,
        [7032] = UIGodSoulTempleRefineSoulQuery,
        [7033] = UIGodSoulTempleRefineSoul,
        [7034] = UIGodSoulTempleCuishenQuery,
        [7035] = UIGodSoulTempleCuishen,

    	[7002] = UIExaminationStatusQuery,
        [7003] = UIExaminationStart,
        [7004] = UIExaminationEnd,
        [7005] = UExaminationPaihangbang,
	--玄月秘宝
        [7060] = UIXuanyueQuery,
        [7061] = UIXuanyueAward,
        [7062] = UIXuanyueActivate,

        --玄月秘宝复制
        [7063] = UIXuanyueQuery2,
        [7064] = UIXuanyueAward2,
        [7067] = UIXuanyueActivate2,

        --玄月秘宝复制
        [7072] = UIXuanyueQuery3,
        [7073] = UIXuanyueAward3,
        [7074] = UIXuanyueActivate3,
	

        --上古遗迹
        [7080] = UIAncientRuinsQuery,
        [7081] = UIAncientRuinsAttack,
        [7082] = UIAncientRuinsReward,
	
	[7091] = UIGrowPlan2,
	[7092] = UIGrowPlan2Buy,
        [7093] = UIGrowPlan2Reward,
        [7094] = UIGrowPlan2Global,
        [7095] = UIGrowPlan2GlobalReward,
	
	--新10连招募
        [7110] = UIRecruitNewTempQuery,
        [7111] = UIRecruitNew,
        [7112] = UIRecruitNewRefresh,
        [7113] = UIRecruitNewTempSave,

        [8020] = UIDiscountGiftQuery,
        [8021] = UIDiscountGiftReward,
        [8022] = UIDiscountGiftQuery2,
        [8023] = UIDiscountGiftReward2,
        [8024] = UIDiscountGiftQuery3,
        [8025] = UIDiscountGiftReward3,
        [8026] = UISpeedGiftQuery,
        [8027] = UISpeedGiftReward,
        [8028] = UISpeedGiftQuery2,
        [8029] = UISpeedGiftReward2,
        [8032] = UISpeedGiftQuery3,
        [8033] = UISpeedGiftReward3,
        [8045] = UIhefuGiftQuery,
        [8046] = UIhefuGiftReward,
        [8047] = UIhefuShopQury,
        [8048] = UIhefuShopBuy,

        --游戏助手
        [6211] = UIGameHelperQuery,
        [6212] = UIGameHelperExe,

        --公会盛宴
        [2271] = UIGang2FeastCheck,
        [2272] = UIGang2CreateJoinFeast,
        [2273] = UIGang2GetFeastReward,
        [2274] = UIGang2FeastRefresh,
        [2275] = UIGang2FeastHandOpen,
        [2276] = UIGang2FeastAgainOpen,
        [2277] = UIGang2BackFeast,
        [2278] = UIGangExpChangeFeast,

        --公会篝火
        [2281] = UIGang2BathCheck,
        [2282] = UIGang2CreateJoinBath,
        [2283] = UIGang2GetBathReward,
        [2284] = UIGang2BathRefresh,
        [2285] = UIGang2BathHandOpen,
        [2286] = UIGang2BathAgainOpen,
        [2287] = UIGang2BackBath,

        --道具通用购买
        [7501] = UIPropBuyQuery, 

        --弹幕
        [2290] = UISendBarrageQuery,
        [2291] = UIBarrageQuery,

        --露水池
        [8055] = UIDewPoolQuery,
        [8056] = UIDewPoolAward,
        [8057] = UIDewPoolExchange,

        --周基金
        [8071] = UIWeekFundQueryX1,
        [8072] = UIWeekFundAwardX1,
        [8073] = UIWeekFundQueryX2,
        [8074] = UIWeekFundAwardX2,
        [8075] = UICPWeekFundQueryX1,
        [8076] = UICPWeekFundAwardX1,
        [8077] = UICPWeekFundQueryX2,
        [8078] = UICPWeekFundAwardX2,
        [8079] = UIRCWeekFundQueryX1,
        [8080] = UIRCWeekFundAwardX1,
        [8081] = UIRCWeekFundQueryX2,
        [8082] = UIRCWeekFundAwardX2,

        --自动炼化
        [8060] = UIShopAutoRefinQuery,
        [8061] = UIShopAutoRefinSet,

        --广告接口
        [8091] = UIADQuery,
        [8092] = UIADReward,
        [8093] = UIADChangeStatus,

        --幻化
        [8110] = UIIllusionQuery,
        [8111] = UIIllusionExe,
        [8112] = UIIllusionCancel,
        [8113] = UIIllusionActivityQuery,
        [8114] = UIIllusionActivityReward,
        [8115] = UIIllusionActivityQueryX1,
        [8116] = UIIllusionActivityRewardX1,
        [8117] = UIIllusionActivityTaskQuery,
        [8118] = UIIllusionActivityTaskReward,

        --复制成长计划 机缘计划
        [8120] = UIGrowPlan4,
        [8121] = UIGrowPlan4Reward,

        --复制成长计划 仙缘计划
        [8122] = UIGrowPlan5,
        [8123] = UIGrowPlan5Reward,

        --雕塑红利
        [8130] = UISculptureActivityQuery,
        [8131] = UISculptureActivityAward,
        [8132] = UISculptureActivityShopBuy,
        [8133] = UISculptureActivityRankQuery,

        --专属神器
        [8101]  = UIExclusiveArtifactQuery,                  --查询
        [8102]  = UIExclusiveArtifactStrengthen,             --强化
        [8103]  = UIExclusiveArtifactActive,                 --激活        
        [8104]  = UIExclusiveArtifactInlay,                  --镶嵌
        [8105]  = UIExclusiveArtifactQiLingQuery,            --器灵查询
        [81051] = UIExclusiveArtifactQiLingUpdate,           --器灵查询
        [8106]  = UIExclusiveArtifactQiLingStrengthen,       --器灵强化
        [8107]  = UIExclusiveArtifactQiLingLock,             --器灵锁定
        [8108]  = UIExclusiveArtifactQiLingRefining,         --器灵熔炼
        [8109]  = UIExclusiveArtifacActiveChallengeQuery,    --神器激活挑战次数查询
        --专属神器副本
        [8201] = UIExclusiveArtifactCopy,                   
        [8202] = UIExclusiveArtifactCopyFight,
        [8203] = UIExclusiveArtifactCopySweep,
        [8204] = UIExclusiveArtifactReset,
        --天机令
        [8241] = UITokenActive,                              --天机令激活
        [8242] = UITokenfragmentCompose,                     --碎片合成
        [8243] = UITokenRecoveryQuery,                       --碎片查询


        --封神赛
        [8250] = UIUserApesSignUp, --报名
        [8251] = UIUserApexQuery, --主页查询
        [8252] = UIGodCompetitionSlotsQuery,
        [825200] = UICompetitionSlotsIndexSave,
        [8253] = UIGodCompetitionChangeSlots,
        [8254] = UIGodCompetitionChangePet,
        [8255] = UIGodCompetitionSlotSpiritQuery,
        [8256] = UIGodCompetitionSlotSpiritQuery,
        [8257] = UIGodCompetitionSlotSpiritQuery,
        [8258] = UIUserApexBossAttack, --boss挑战
        [8259] = UIUserApexBossDamageRank, --boss伤害排行榜查询
        [8260] = UIUserApexBossBattleRecord, --boss挑战记录
        [8261] = UIUserApexBossRewardsQuery, --boss伤害奖励查询
        [8262] = UIUserApexBossRewardsCollect, --boss伤害奖励领取

        [8263] = UIUserApexUpLoadSlots, --上传阵容 pvp
        [8264] = UIUserCheckLoadSlots, --上传阵容(检查阵容)

        [8271] = UIUserWarOfApexChampionOld, --上届冠军信息
        [8272] = UIUserWarOfApexReward, --领奖
        [8273] = UIUserWarOfApexRoleBattlesInfo, --战斗详情
        [8274] = UIUserWarOfApexBattlePlay, --战斗播放
        [8275] = UIUserWarOfApexBet, --押注
        [8276] = UIUserWarOfApexChampoionQuery, --历届冠军排行榜
        [8277] = UIUserWarOfApexGroupInfo, --赛区信息
        [8278] = UIUserWarOfApexSrarRank, --星级排行榜

        [8279] = UIUserWarOfApexRoleBattles, --预选赛查询
        [8280] = UIUserWarOfApexTopInfo, --冠军赛查询
        [8281] = UIUserWarOfApexRolesInfo, --淘汰赛玩家信息

        --耐力密码
        [8245] = UINaiLiCodeRank,

        --升仙台
        [8851] = UIAscensionSendaiMapQuery, --地图查询
        [8852] = UIAscensionSendaiMapSelect, --选择挑战难度
        [8853] = UIAscensionSendaiRunPoint, --走格子
        [8854] = UIAscensionSendaiEventSet, --事件二次处理
        [8855] = UIAscensionSendaiBufferQuery, --buff查询

        [8856] = UIAscensionSendaiShop, --系统商店查询
        [8857] = UIAscensionSendaiShopBuy, --系统商店购买

        [8858] = UIAscensionSendaiSlotGeneralsUp, --阵容镜像上传
        [8859] = UIAscensionSendaiSlotGeneralsQuery, --武将镜像查询
        [88591] = UIAscensionSendaiSlotGeneralsChange, --武将布阵
        [8860] = UIAscensionSendaiSlotMonsterQuery, --怪物阵容查询

    }
    return net_ui_callback2
end

local function step1NetUICallBack()
    require"UILogin"
    require"UIFangchenmi"
    require"UIErrorMessage"
    require"UIDownloadProxy"
    require"UIReLogin"
    local syncresource_ui_callback = {
        [9] = setLoginPercentFromServer,
        [20] = UIDownloadProxy,
        --错误信息相关
        [9999] = UIErrorMessage,
        [9997] = UIErrorMessage7,
        [9998] = UIshowloginlog,
        [888888] = UILoginShow,
        [8888883] = UIResourceUpdateFinish,
        [80] = UIEventPost,
        [777777] = UIrestart,
        [6666666] = UIunzip,
    }
    return syncresource_ui_callback
end

local uiqueue = require("uiqueue")
local net_ui_callback = step1NetUICallBack()

local socket = require("socket")


require"myque"

local triggerGiftlist = myque.new()
local isTriggerGiftEnable = true
local triggerGiftDelaylist={
    [1306] = true,
    [1307] = true,
    [3742] = true,
    [1403] = true,
    [1351] = true,
}
function addTriggerGift( data )
    myque.push(triggerGiftlist,data)
end

function setTriggerGiftEnable( isenable )
    isTriggerGiftEnable = isenable
end

function setTriggerGiftEnableByType( isenable,request )
    if request and triggerGiftDelaylist[request] then
        isTriggerGiftEnable = isenable
    end
end

local function updateTriggerGift()
    if isTriggerGiftEnable then
        local data = myque.pop(triggerGiftlist)
        if not data then return end
        if data.triggergiftpush and data.triggergiftpush.iid and data.triggergiftpush.iid > 0 then
            UIRequest({type = 4800, pushiid = data.triggergiftpush.iid})
        end
    end
end

local delayUpdateQue = myque.new()

function UIUpdate()
    --local t1 = socket.gettime()
    for i=1,10,1 do
        local tret = uiqueue.popresponsefromclient()
        if tret ~= nil then

            --海外版这里有额外处理

            --print(socket.gettime() - t1, "popresponsefromclient",tret["type"])
            cclog("UIUpdate PUSH  tret.type = %s ", tret["type"])
            if tonumber(tret["type"]) == 888888 then
                net_ui_callback = step2NetUICallBack()
            end
            local func = net_ui_callback[tonumber(tret["type"], 10)]
            ---assert(func, string.format("UI callback not exist in UIUpdate.lua", tret.type))

            if nil ~= func then
                local func1,func2 = func,__G_TRACKBACK__
                if type(func) == "table" then
                    func1 = func[1]
                    if #func > 1 then
                        func2 = func[2]
                    end
                end
                --printT(tret)

                local bcall, ret, body = xpcall(function() return func1(tret) end,func2)
                if bcall then
                    if ret ~= 0 then
                        if body ~= nil then
                            cclog("UIUpdate PUSH func =%s ret =%s body=%s", func1, ret, body)
                            uiqueue.pushrequesttoclient(body)
                        end
                    end
                else
                    cclog("[Error]UIUpdate Process Error");
                end
            else
                cclog("UIUpdate type:%s invalid content:%s", tret["type"], tret)
            end

            if tret.type == 777777 or tret.type == 999911 then
                break
            end

            if loading then
                loading:stopGameloading(tret["type"])
            end
            if guide and guide.controller ~= nil and next(guide.controller) ~=nil then
                guide.controller:CompleteStep("uiupdate",tret["type"])
            end
            --print(socket.gettime() - t1, "UIUpdate",tret["type"])

--            if hintChange[tret["type"]] then
--                UIRequest({type =1032})
--            end


        else
            break
        end
    end

    if UPDATECACHE then
        UPDATECACHE = UPDATECACHE - 1
        if UPDATECACHE < 0 then
            CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
            CCTextureCache:sharedTextureCache():removeUnusedTextures()
            UPDATECACHE = nil
        end
    end

    local delayUpdateFunc = myque.pop(delayUpdateQue)
    if delayUpdateFunc then
        local b_time = os.clock()
        
        delayUpdateFunc.func()
        print("exeUpdateFunc",delayUpdateFunc.name,os.clock() - b_time)
    end

    -- if next(DelayUpdateFuncs) then

    --     local key = ""
    --     for k,v in pairs(DelayUpdateFuncs) do
    --         if v.index<=0 then
    --             v.func()
    --             key = k
    --         else
    --             v.index = v.index -1
    --         end
    --     end
    --     if key ~= "" then DelayUpdateFuncs[key] = nil end
    -- end

    xpcall(function() updateTriggerGift() end,__G_TRACKBACK__)

end


function addDelayUpdateFunc(func,name,index)
    print("addDelayUpdateFunc",name)
    myque.push(delayUpdateQue,{name = name,func = func})
    -- DelayUpdateFuncs[name] = {index = index or 0,func = func}
end


function startUIUpdate()
    if not UIUpdateScheduleScriptFunc then
        UIUpdateScheduleScriptFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(UIUpdate, 0, false)
    end
end

function pauseUIUpdate()
    if UIUpdateScheduleScriptFunc then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(UIUpdateScheduleScriptFunc)
        UIUpdateScheduleScriptFunc = nil
    end
end
startUIUpdate()

--if not gamedata.music then
--    gamedata.music = require"music"
--    gamedata.music:Init()
--    ---gamedata.music:GameStart()
--end
 ��  