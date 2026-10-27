--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-5-7
-- Time: 下午1:34
-- To change this template use File | Settings | File Templates.
--
local socket = require("socket")
local t0 = socket.gettime()
require("UIRequest")

require("GameErrorMessage")

--账户服务器
require("log")
require("gameloop")
require("gameloop2")
require("gamedata")
require("GameUserValid")

require"GameDownloadProxy"

require"GameRole"
require"GameSlots"
require"GameSlotChangeEquip"
require"GameSlotChangeSoul"
require"GameQuickEquip"
require"GameUpgradeSkill"


require"GameCopy"
require"GameCopyBrave"


require"GamePropList"
require"GameGeneralFragmentList"

require"GameRecruitQuery"
require"GameRecruit"

require"GameAthletics"

require"GameActivityQuery"

require"GameBloodBattle"


require"GameCheckOtherSlotsInfo"

require"GameEquipStrengthen"
require"GameEquipRefine"
require"GameTreasureUp"
require"GameTreasureRefine"
require"GameEquipFragment"
require"GameEquipFragmentCompound"

require"GameGeneralInheritPreview"
require"GameGeneralInheritConfirm"
require"GameGeneralFoster"
require"GameGeneralCompound"
require"GameGeneralBreak"

require"GameQiankunlu"

require"GameFriendQuery"
require"GameFriendChat"
require"GameFriendManager"

require"GameShop"
require"GameFriendCopy"

require"GameRob"

require"GameEncounter"

require"GameSoul"
require"GameGeneralExchange"
require"GameTech"
require"GameHappinessplace"

require"GameCup"
require"GameGang"
require"GameDevilFotress"

require"GameMails"
require"GameBattleOther"

require"GameEatChicken"
require"GameActivityMammon"
require"GameSignIn"

require"GameBroadcast"
require"GameTask"

require"GamePenglai"
require"GameIsland"
require"GameLiveness"

require"GameWorldBoss"

require"battletest"
require"GameChat"
require"GameActivityHole"

require"GameRecharge"
require"GameCacheReset"
require"GameInvent"

require"GameHint"
require"GameGuide"
require"GameCollect"
require"GameGetLastResponse"

require"GameCDK"
require"GameSystemMail"
require"GameCombMessages"

require"GameRank"
require"GameActivityReward"
require"GameUserDataCollect"

require"GameZhuxiantai"

require"GameActivity_tigerchicken"
require"GameStartActivity"
require"GameActivityShop"
require"GameGlobalParam"
require"GameActivityExchange"

require"GameActivityBlackShop"

require"GameActivitySecretShop"

require"GameGetStaffNum"

require"GameGeneralUp"

require"GameFavorite"

require"GameActivityRobShop"

require"GameGuildWar"

require"GameSlotArrange"
require"GameSingleBoss"

require"GameCopyActivity"
require"GameActivityMultipleRebate"

require"GameMofu"
require"GameMagic"
require"GameCopyStar"

require"GameEquipStage"
require"GameEquipStarUp"

require"GameMaze"
require"GameActivityCornucopia"
require"GameGeneralAwanken"
require"GameChampion"
require"GameDragonBoat"
require"GamePassKill"

require"GameActivity_duanwulunpan"
require"GameActivityOldDriver"

require"GameWuDaoHui"

require"GameFashion"
require"GameActivityFashion"
require"GameNightclub"

require"GameActivity_sdk_hare"
require"GameActivityGoddown"
require"GameLimitExchange"
require"GameGameStar"

require"GameActivitySafeMaskShop"

require"GameActivityJinghuaShop"

require"GameWing"
require"GameServiceWar"
require"GameHonorWar"

require"GameRecall"

require"GameTriggerGift"

require"GameAuction"

require"GameCangjingge"

require"GameDragonWishing"

require"GameActivityZhounian"

require"GameActivityTree"

require"GameDaoGuan"
require"GameTimeBag"

require"GameActivityPeentoGift"

require"GameActivityAuction"

require"GameArtifact"
require"GameActivityWeekCard"

require"GameGeneralXiuLian"
require"GamePoolingServer"
require"GameCopyHell"
require"GameTitle"

require"GameActivityChristmas"
require"GameGeneralFeiSheng"

require"GameBabelTower"

require"GameBlessingCave"
require"GameChange"
require"GameGodSoulTemple"
require"GameXuanyueTreasures"
require"GameExamination"
require"GameAncientRuins"
require"GameSpeedGift"
require"GameHelper"
require"GameDewPool"

require"GameActivityAD"

require"GameIllusion"
require"GameSculptureActivity"

require"GameExclusiveArtifact"

require"GameToken"


require"GameGodCompetition_main"
require"GameGodCompetition"
require"GameMiniGames"

require"GameAscensionSendai"

--客户端向服务器发送请求
game_ui_callback = {

    --通天塔
    [70110] = UIPureSlotsCallBack,
    [7010] = UIXianBuyTimesCallBack,
    [7011] = UIBabelTowerQueryCallBack,
    [7012] = UIBabelTowerLevelQueryCallBack,
    [7013] = UIBabelTowerBattleCallback,
    [7014] = UIBabelTowerQuitCallback,
    [7015] = UIBabelTowerAwardCallback,
    [7016] = UIBabelTowerAutoBattleCallback,
    [7017] = UIBabelTowerShopQueryCallback,
    [7018] = UIBabelTowerShopBuyCallback,
    [7019] = UIBabelTowerRankQueryCallback,
    --商会
    [61200] = UICanSellQuery,
    [6120] = UIGoodsSellCallBack,
    [6121] = UIGoodsRevokeCallBack,
    [6122] = UIGoodsBuyCallBack,
    [6123] = UIGoodsProtectQueryCallBack,
    [6124] = UIGoodsResetSellCallBack,

    
    --称号、头像框
    [6301] = UITitleQueryCallBack,
    [6302] = UITitleUseCallBack,
    [6201] = UIIconBoxQueryCallBack,
    [6202] = UIIconBoxUseCallBack,

    -- 天庭银座 began
    [4500] = UIUserPatrolQuery,
    [4501] = UIUserPatrolStatus,
    [4502] = UIUserPatrolAttack,
    [4503] = UIUserPatrolDo,
    [4504] = UIUserPatrolReward,
    [4505] = UIUserPatrolEventDo,
    [4509] = UIUserPatrolOneAdd,
    [4510] = UIUserPatrolOneAddReward,
    [4511] = UIUserPatrolOneAddQuery,
    -- 魔符自动合成和查询
    [6405] = UIAutoMoFuQueryCallBack,
    [6406] = UIAutoMoFuComposeCallBack,

    -- 天庭银座 ends
    -- 限时兑换 began
    [3710] = UILimitExchangeQuery,
    [3711] = UIUserLimitExchange,
    [3712] = UIUserLimitExchangeRefresh,
    -- 限时兑换 ends
    [999990] = UIbattletestCallBack,
    [999989] = UIGetLastResponseCallBack,
    [999988] = LuaExceptionReportCallBack,
    [999900] = UICombMessagesCallback,
    [979797] = UImerorytestCallBack,

    [999901] = UIUserDataCollectCallBack,
    [999902] = UIRoleInfoBasicCallBack,
    [999904] = UIHearCheckCallBack,

    [999905] = UIServerTimeCallBack,
    [999906] = UIdeviceinfoCallBack,

    [999907] = UIconfigUpdateCallBack,

    [777777] = UInetLuaReloadCallBack,
    [6666666] = NetunzipFileCallBack,

    [1]    = UIReloginCallBack,
    [997]  = UIDisconnect,
    [996]  = UIReconnect,
    [995]  = UIDisconnect2,
    [9951]  = UIDisconnect3,
    --[20] = GameDownloadProxy,
    [1000] = UINetSessionValidateCallback,

    [5340] = UIOnlinetimeQueryCallBack,
    [5341] = UIRealnameRewardQueryCallBack,
    [5342] = UIRealnameRewardCallBack,

    [998]  = AndroidNetLoad,

    [100] = UIRandomNameCallBack,
    [101] = UISetNameCallBack,
    [102] = UIRoleSetProfileCallBack,
    [200] = UIGuideQueryCallBack,
    [201] = UIGuideExcuteCallBack,
    [202] = UIInitGeneralCallBack,

    [203] = UIChangeGenderCallBack,
    [204] = UIGenderQueryCallBack,

    [110] = UICacheReset,

    [212] = UIContinue7QueryCallBack,
    [213] = UIContinue7RewardCallBack,
    [214] = UIContinue7QueryCallBack1,
    [215] = UIContinue7RewardCallBack1,

    [115] = UIRechargePreCallBack,
    [117] = UIVipCallBack,
    [2090] = UIMonthCardCallBack,
    [2091] = UIMonthCardGetCallBack,
    [2092] = UIMonthCardRewardCallBack,
    [2093] = UIMonthCardRewardGetCallBack,
    [2094] = UIGrowPlanCallBack,
    [2095] = UIGrowPlanBuyCallBack,
    [2096] = UIGrowPlanRewardCallBack,
    [2097] = UIRechargeDoubleCallBack,
    [2098] = UIFirstRechargeRewardCallBack,
    [2099] = UIFirstRechargeStatusCallBack,
    [300] = UIVipStatusCallBack,
    [301] = UIUserBuyCallBack,

    [2080] = UIInviteCodeCallback,
    [2081] = UIInviteCodeSetCallBack,
    [2082] = UIInviteCodeRewardCallBack,

    [1032] = UIHintCallBack,
    [10321] = UIHintResetCallBack,
    [10322] = UIHintSlotCallBack,
    [10323] = UIHintArtifactCallBack,

    [1030] = UIUserSystemMailCallBack,

    [1015] = UIGeneralCollectCallBack,
    [1103] = UIEquipCollectCallBack,
    [3910] = UITeamRecomQueryCallBack,
    [3911] = UITeamRecomRewardCallBack,

    [1001] = UIRoleInfoCallBack,
    [10011] = UIRoleQueryCallBack,
    [10012] = UIRoleLevelUpCallBack,

    [1002] = UISlotsAllInfoCallBack,
    [10021] = UISlotsCallBack,
    [10022] = UISlotGemsCallBack,
    [10023] = UIAllGeneralCallBack,
    [10024] = UIOffGeneralCallBack,
    [10025] = UIEquipsCallBack,
    [10026] = UISoulsCallBack,
    [10027] = UIOffSoulsCallBack,
    [10028] = UIGemsCallBack,
    [10029] = UISelectListCallBack,
    [1003] = UIChangeSlotCallBack,
    [1004] = UIChangeCheerCallBack,
    [1005] = UISlotChangeEquipCallBack,
    [1006] = UISlotChangeSoulCallBack,
    [1007] = UIQuickEquipCallBack,
    [1008] = UIUpgradeSkillCallBack,
    [1009] = UISlotArrangeCallBack,

    [1130] = UIMagicstoneUpCallBack,

    [1050] = UIProtagonistQueryCallBack,
    [1051] = UIProtagonistAddAttrCallBack,
    [1052] = UIProtagonistGrowUpCallBack,
    [1053] = UIProtagonistRecoverTrainCallBack,
    [1054] = UIUserProtagonist2CallBack,
    [1055] = UIUserProtagonist2AddAttrCallBack,
    [1056] = UIUserProtagonist2GrowupPreveiwCallBack,
    [1057] = UIUserProtagonist2GrowupCallBack,


    [1020] = UICheckOtherSlotsInfoCallBack,
    [1022] = UIBattleOtherCallback,
    [1031] = UISomeIdsCallBack,

    [1010] = UIGeneralInheritPreviewCallBack,
    [1011] = UIGeneralInheritConfirmCallBack,
    [1012] = UIGeneralFragmentListCallback,
    [10121] = UIGeneralFragmentByIdCallback,
    [1013] = UIGeneralFosterPreviewCallBack,
    [1014] = UIGeneralFosterConfirmCallBack,
    [1016] = UIGeneralCompoundCallBack,
    [1017] = UIGeneralBreakCallBack,
    [1023] = UIGeneralBreakPreviewCallBack,
    [1018] = UIGameGeneralFragmentRobQueryCallBack,
    [1019] = UIGameGeneralFragmentRobCallBack,
    [1021] = UIGeneralExchangeCallBack,

    [10211] = UIGeneralExchangeQueryCallBack,
    [1025] = UIGeneralAwakenCallBack,
    [1058] = UIProtagonistAwakenCallBack,
    [1038] = UIUseExpDanCallBack,

    [1026] = UIGeneralArtifactLevelupCallBack,
    [1029] = UIGeneralUpStarCallBack,

    [1800] = UITechListCallback,
    [18001] = UITechGeneralListCallback,
    [1801] = UITechUpgradeCallBack,

    [1805] = UIDevilStatusCallback,
    [1806] = UIDevilExchangeFragmentCallback,
    [1807] = UIDevilUpCallback,
    [1808] = UIDevilStatus2Callback,
    [1809] = UIDevilLevel1ExpCallback,
    [1810] = UIDevilLevel2UpCallback,

    [1040] = UIPetQueryCallback,
    [1041] = UIPetLevel1UpCallback,
    [1042] = UIPetLevel2UpCallback,
    [1043] = UIPetSetCallback,
    [1044] = UIPetFragmentCallback,
    [1045] = UIPetCompoundCallback,

    [1046] = UIPetStageUpCallback,
    [1047] = UIPetPassiveSkillCallback,
    [1048] = UIPetPassiveSkillStudyCallback,
    [1049] = UIPetBagCompoundCallback,

    [1060] = UIPetPassiveSkillLockCallback,
    [1061] = UIPetPassiveSkillResetCallback,

    [1062] = UIPetLevel1Up2Callback,

    [1064] = UIPetPassiveSkillRedCallback,

    [1065] = UIPetResetCallBack,

    [1066] = UIPetDevourCallback,

    [1110] = UIGameTreasureFragmentRobQueryCallBack,
    [1111] = UIGameTreasureFragmentRobCallBack,
    [11111] = UIGameRobEquipQueryCallback,
    [11112] = UIGameRobGeneralQueryCallback,
    [1112] = UIRobProfCDqueryCallBack,
    [1113] = UIRobProfCDAddCallBack,
    [1114] = UIGameTreasureFragmentRobTenCallBack,
    [1125] = UIRobOneKeyTreasureCallback,

    [1101] = UIEquipStrengthenCallBack,
    [1102] = UIEquipRefineCallBack,

    [1105] = UITreasureUpCallBack,
    [1106] = UITreasureRefineCallBack,
    [1107] = UIEquipFragmentAllCallback,
    [11071] = UIEquipFragmentListCallback,
    [1108] = UIEquipFragmentCompoundCallBack,
    [1109] = UIQuickEquipStrengthenCallBack,

    [1115] = UIEquipRefineExCallBack,
    [1116] = UITreasureRefineExCallBack,

    [1118] = UITreasureStrengthenCallBack,
    [1119] = UITreasureRefine2CallBack,

    [1210] = UITreasureStrengthenByPropCallBack,

    [1104] = UIEquipResolveCallBack,
    [1036] = UIGeneralFragmentResolveCallBack,
    [1117] = UIEquipResetCallBack,
    [1035] = UIGeneralResetCallBack,
    [1037] = UIGeneralResolveCallBack,
    [1077] = UIFashionDressResetCallBack,
    [1039] = UIGeneralResolveCallBack2,

    [3850] = UIResolveQualityCallBack,

    [1120] = UIEquipBaptizePreviewCallBack,
    [1121] = UIEquipBaptizeConfirmCallBack,

    [1122] = UIEquipStageUpCallBack,

    [1123] = UIEquipStarUpCallBack,

    [1124] = UIEquipBaptizeAutomaticCallBack,
    [1126] = UIGeneralAutoTrainCallBack,  --武将培养加上
    [1127] = UITreasureStarUpCallBack,  --宝物升星

    [2501] = UISoulHuntQueryCallBack,
    [2502] = UISoulHuntCallBack,
    [2503] = UISoulExchangeCallBack,
    [2504] = UISoulUpgradeCallBack,
    [2505] = UISoulHunt41CallBack,
    [2506] = UISoulResolveCallBack,
    [2507] = UISoulCompoundCallBack,

    [1400] = UIGeneralRecruitStatusCallback,
    [1401] = UIGeneralRecruitCallback,

    [1402] = UIGeneralRecruitQueryCallback,
    [1403] = UIGeneralRecruit2Callback,
    [5321] = UIGeneralRecruitShopQueryCallback,
    [5322] = UIGeneralRecruitRewardCallback,

    [1404] = UIOldDriverQueryCallBack,
    [1405] = UIOldDriverOptCallBack,

    [1406] = UITigerchickenQueryCallBack,
    [1407] = UITigerchickenDoCallBack,
    [1408] = UITigerchickenshopQueryCallBack,
    [1409] = UITigerchickenshopExchangeCallBack,

    --作妖2048
    [1600] = UIMiniGameQueryCallback,
    [1601] = UIMiniGameSynchronizationCallback,
    [1602] = UIMiniGameOverCallback,
    [1603] = UIMiniGameStartCallback,
    [1604] = UIMiniGameExchangeCallback,
    [1605] = UIMiniGameAchievementCallback,
    [1606] = UIMiniGameAchievementRewardCallback,
    [1607] = UIMiniGameRankCallback,
    [1608] = UIMiniGameExchangeQueryCallback,

    [1610] = UIAthleticsList2Callback,
    [1611] = UIAthleticsAtta2ckCallback,
    [1613] = UIAthleticsRewardsQuery3Callback,
    [1614] = UIAthleticsRewardExchange3Callback,
    [1615] = UIAthleticsRankRewardsStatusCallback,
    [1616] = UIAthleticsBoss2Callback,


    [1300] = UICopyQueryCallback,
    [1301] = UICopyAttackCallback,
    [1302] = UICopyWipeCallback,
    [1306] = UICopyAttack2Callback,
    [1307] = UICopyWipe2Callback,
    [1303] = UICopyAll3StarRewardCallback,
    [1304] = UICopyPrestigeRewardCallback,
    [1305] = UICopyResetKillCallback,

    [1330] = UIBraveCopyQueryCallback,
    [1331] = UIBraveCopyAttackCallback,
    [1332] = UIBraveCopyWipeCallback,
    [1337] = UIBraveCopyAttack2Callback,
    [1338] = UIBraveCopyWipe2Callback,
    [1333] = UIBraveCopyAll3StarRewardCallback,
    [1334] = UIBraveCopyPrestigeRewardCallback,
    [1335] = UIBraveCopyResetKillCallback,

    [1336] = UICopyClearTimerCallback,

    [1310] = UIEncounterQueryCallback,
    [13101] = UIEncounterQueryExtCallback,
    [1311] = UIEncounterUseCallback,
    [13111] = UIEncounterTimeUpCallback,

    --[1320] = UIFriendCopyQueryCallback,
    [13201] = UIFriendCopyFriendSelectCallBack,
    --[1321] = UIFriendCopyAttackCallback,
    [1323] = UIFriendCopyQueryCallback,
    [1324] = UIFriendCopyAttackCallback,
    [1325] = UIFriendCopyOneFinishCallback,

    [1322] = UIFriendCopyRankCallback,

    [1200] = UIPropListCallback,
    [1201] = UIPropUseCallback,
    [1203] = UIPropNumQueryCallback,
    [12001] = UIPropQueryByIdCallback,


    [20001] = UIActivityIsOpenCallBack,
    [2000] = UIActivityQueryCallBack,
    [2070] = UIBloodQueryCallBack,
    [2071] = UIBloodBattleCallBack,
    [2072] = UIBlood3AttrBufQueryCallBack,
    [2073] = UIBlood3AttrBufCallBack,
    [2074] = UIBlood5AwardQueryCallBack,
    [2075] = UIBlood5AwardCallBack,
    [2076] = UIBloodRankQueryCallBack,
    [2077] = UIBloodWipeCallBack,
    [2078] = UIBloodWipeRewardCallBack,
    [2079] = UIBloodWipeContinueCallBack,
    -- [2085] = UIBloodExchangeCallBack,

    [2085] = UIActivitySDKShareQueryCallBack,
    [2086] = UIActivitySDKShareDoCallBack,
    [2087] = UIActivitySDKShareRewardCallBack,


    --[2030] = UIHappinessPlaceQueryCallBack,
    --[2031] = UIHappinessPlaceUseCallBack,
    --[2032] = UIHappinessPlaceRankCallback,
    --[2033] = UIHappinessPlaceExchangeCallBack,
    --[2034] = UIHappinessPlaceServerRewardCallBack,

    [2031] = UICornucopiaQueryCallBack,
    [2032] = UICornucopiaCallBack,
    [2033] = UICornucopiaRewardCallBack,

    [2035] = UIActivityStartGiftQueryCallBack,
    [2036] = UIActivityStartGiftCallBack,
    [2022] = UIDayDayGiftCallBack,
    [2023] = UIDayDayGiftRewardCallBack,

    [3310] = UIDayDayGiftX1CallBack,
    [3311] = UIDayDayGiftX1RewardCallBack,

    [2024] = UIRechargeGiftCallBack,
    [2025] = UIRechargeGiftRewardCallBack,

    [2020] = UIConsumeGiftCallBack,
    [2021] = UIConsumeGiftRewardCallBack,

    [2010] = UIActivityEatChickenQueryCallBack,
    [2011] = UIEatChickenCallBack,
    [2015] = UIActivityMammonQueryCallBack,
    [2016] = UIActivityMammonCallBack,
    [2017] = UIActivityMammonBroadCastCallBack,
    [2060] = UISignInStatusCallBack,
    [2061] = UISignInCallBack,
    [2062] = UIMysticalStargazingCallBack,
    [2063] = UIMysticalSwacthStarCallBack,
    [2064] = UIMysticalChangeSwacthStarCallBack,
    [2065] = UIGetWatchStartCallBack,
    [2066] = UIWatchStarRewardCallBack,
    [2067] = UIWatchStarWatchExCallBack,
    [2068] = UIWatchStarUpLevelCallBack,

    --[2040] = UIPenglaiCallBack,
    [2041] = UIPenglaiSelectDifficultyCallBack,
    [2042] = UIPenglaiSearchCallBack,
    [2043] = UIPenglaiBattleCallBack,
    [2044] = UIPenglaiRankCallBack,
    [2045] = UIPenglaiTodayRewardCallBack,
    [2046] = UIPenglaiTotalCallBack,
    [2047] = UIPenglaiTotalRewardCallBack,
    [2048] = UIPenglaiTaskCallBack,
    [2049] = UIPenglaiTaskRewardCallBack,

    [2110] = UIIslandCallBack,
    [2111] = UIIslandGotoCallBack,
    [2112] = UIIslandNextCallBack,
    [2113] = UIIslandGetTodayRewardCallBack,
    [2114] = UIIslandTaskCallBack,
    [2115] = UIIslandTaskRewardCallBack,
    [2116] = UIIslandRankCallBack,
    [2117] = UIIslandGlobalCallBack,
    [2118] = UIIslandGlobalRewardCallBack,

    [2120] = UIPenglai3CallBack,
    [2121] = UIPenglai3DiceCallBack,
    [2122] = UIPenglai3RewardCallBack,
    [2123] = UIPenglai3ResetCallBack,
    [2124] = UIPenglai3CardCallBack,
    [2125] = UIPenglai3CardOpenCallBack,
    [2126] = UIPenglai3CardCloseCallBack,
    [2127] = UIPenglaiAutoRewardCallBack,
    [2128] = UIPenglaiAutoReward2CallBack,

    [2050] = UIMysticalCaveCallBack,
    [2051] = UIMysticalCaveForecastCallBack,
    [2052] = UIMysticalCaveReversionCallBack,
    [2053] = UIMysticalCaveConfirmCallBack,
    [2054] = UIMysticalRewardCallBack,
    [2055] = UIActivityExchangeCallBack,
    [2056] = UIActivityExchangeEXCallBack,
    [2057] = UIActivityExchangeRefreshCallBack,

    [2089] = UIUserCDKeyExchangeCallBack,

    [2300] = UIFriendQueryCallback,
    [2301] = UIFriendRecommendCallback,
    [2302] = UIFriendReqCallBack,
    [2303] = UIFriendReqQueryCallback,
    [2304] = UIFriendRepCallBack,
    [2305] = UIFriendChatQueryCallback,
    [2306] = UIFriendChatCallback,
    [2307] = UIFriendSearchCallBack,
    [2308] = UIFriendSendGiftCallBack,
    [2309] = UIFriendRecvGiftCallBack,
    [2310] = UIFriendDeleteCallBack,
    [2311] = UIFriendAllReqCallBack,
    [6038] = UIFriendAllAddCallback,

    [2400] = UITaskQueryCallBack,
    [2401] = UITaskCompleteCallBack,

    [2410] = UILivenessCallBack,
    [2411] = UILivenessRewardCallBack,

    [2100] = UICupStatusCallBack,
    [2101] = UICupJoinTomorrowCallBack,
    [2102] = UICupTopCallBack,
    [21021] = UICupTopSeeCallBack,
    [2103] = UICupBattlePlayCallBack,
    [2104] = UICupBattleRewardCallBack,
    [2105] = UICupBattleBetCallBack,
    [2106] = UICupBattleRewardallCallBack,

    [2107] = UICupRankCallBack,

    [2200] = UIGangStatusCallBack,
    [2201] = UIGangCreateCallBack,
    [2202] = UIGangsCallBack,
    [2203] = UIGangReqCallBack,
    [2204] = UIGangReqQueryCallBack,
    [2205] = UIGangReqRepCallBack,
    [2206] = UIGangMemberCallBack,
    [2207] = UIGangKickMemberCallBack,
    [2208] = UIGangQuitCallBack,
    [2209] = UIGangPassPowerCallBack,
    [2210] = UIGangSetAssistantCallBack,
    [2211] = UIGangSetAnnouncementCallBack,
    [2219] = UIGangRemoveAssistantCallBack,
    [2220] = UIGangsearchCallBack,

    [2230] = UIUserGang2CallBack,
    [2231] = UIUserGang2CreateCallBack,
    [2232] = UIUserGang2ListCallBack,
    [2233] = UIUserGang2ReqCallBack,
    [2234] = UIUserGang2ReqQueryCallBack,
    [2235] = UIUserGang2RepCallBack,
    [2236] = UIUserGang2MemberCallBack,
    [2237] = UIUserGang2MSetContent1CallBack,
    [2238] = UIUserGang2MSetContent2CallBack,
    [2239] = UIUserGang2MSetViceCallBack,
    [2240] = UIUserGang2MKickCallBack,
    [2241] = UIUserGang2MPassCallBack,
    [2242] = UIUserGang2QuitCallBack,
    [2243] = UIUserGang2SearchCallBack,

    [2250] = UIUserGang2PrayQueryCallBack,
    [2251] = UIUserGang2PrayCallBack,
    [2252] = UIGuideShopViewCallBack,
    [2253] = UIGuideShopBuyGoodsCallBack,
    [2254] = UIUserGang2OptsCallBack,
    [2255] = UIUserGang2ImpeachCallBack,
    [2256] = UIUserGang2FishpondCallBack,
    [2257] = UIUserGang2FishpondFeedCallBack,
    [2258] = UIUserGang2FishpondRewardCallBack,
    [2259] = UIUserGang2MSetNameCallBack,
    [2260] = UIUserGang2DailyRewardCallBack,
    [2261] = UIUserGang2FishpondPointRankCallBack,
    [2262] = UIGangSkillQuery,
    [2263] = UIGangSkillStudy,

    [2265] = UIGangApplyLimitCallBack,
    [2266] = UIUserGang2DisbandCallBack,

    [2267] = UIUserGang2ReqCancelCallBack,
    
    [2312] = UIFriendChatListCallback,
    [2313] = UIFriendHasChatCallback,



    [2610] = UIDevilFotressStatusCallBack,
    [2611] = UIDevilFotressGangDefCallBack,
    [2612] = UIDevilFotressGangDefSetCallBack,
    [2613] = UIDevilFotressGangDefsCallBack,
    [2614] = UIDevilFotressGangProciamCallBack,
    [2616] = UIDevilFtoressTargetCallBack,
    [2617] = UIDevilFotressAutoBattleCallBack,
    [2618] = UIDevilFotressTargetBattleCallBack,
    
    [28801] = UITimeBagTimeOverCallBack,
    [2880] = UITimeBagCallback,
    [2881] = UITimeBagGetCallBack,
    [2882] = UITimeBagTrigCallBack,


    [3000] = UIUserChatQueryCallBack,
    [3001] = UIUserChatCallBack,
    [3002] = UIFriendAllShieldCallBack,
    [3003] = UIFriendAddShieldCallBack,
    [3004] = UIFriendDeleteShieldCallBack,
    [3010] = UIUserGangChatQueryCallBack,
    [3011] = UIUserGangChatCallBack,
    [3012] = UIUserChatNumResetCallBack,
    [3015] = UIBroadcastQueryCallBack,
    [30001] = UIUserCrossChatCallBack,

    [3100] = UIMailListCallBack,
    [3101] = UIMailReadCallBack,
    [3102] = UIMailDeleteCallBack,
    [3103] = UIMailSendCallBack,

    [3400]  = UIWorldBoss1QueryCallBack,
    [3401]  = UIWorldBoss1AttackCallBack,
    [3402]  = UIWorldBoss1RankCallBack,
    [3403]  = UIWorldBoss1RealNotifyCallBack,
    [3404]  = UIWorldBoss1PreRankCallBack,

    [3410]  = UIWorldBoss2QueryCallBack,
    [3411]  = UIWorldBoss2AttackCallBack,
    [3412]  = UIWorldBoss2RankCallBack,
    [3413]  = UIWorldBoss2RealNotifyCallBack,
    [3414]  = UIWorldBoss2PreRankCallBack,
    [3415]  = UIWorldBoss2OfflineBattleCallBack,
    [3416]  = UIWorldBoss2OfflineBattleResultCallBack,

    [3200] = UIshopQueryCallback,
    [3210] = UIGiftBagQueryCallback,
    [3201] = UIShopBuyCallback,
    [3211] = UIGiftBagBuyCallback,


    [2037] = UIOnlineRewardQueryCallBack,
    [2038] = UIOnlineRewardCallBack,

    [2039] = UIOnlineRewardByTimeQueryCallBack,
    [2040] = UIOnlineRewardByTimeCallBack,

    [3500] = UIRankQueryCallBack,
    [35001] = UIRankMydataCallBack,

    [3503] = UIOldRankQueryCallBack,

    [3600] = UIZhuxiantaiQueryCallBack,
    [3601] = UIZhuxiantaiBattleCallBack,
    [3602] = UIZhuxiantaiWipeCallBack,
    [3603] = UIZhuxiantaiAttrQueryCallBack,
    [3604] = UIZhuxiantaiAttrSelectCallBack,
    [3605] = UIZhuxiantaiRankCallBack,
    [3606] = UIZhuxiantaiExchangeCallBack,
    [3607] = UIZhuxiantaiResetCallBack,


    [3610] = UIBegin7DaysCallBack,
    [36101] = UIBegin7DaysExtCallBack,
    [3611] = UIBegin7DaysRewardCallBack,

    [3615] =UIActivityShopQueryCallBack,
    [3616] =UIActivityShopCallBack,
    [3617] =UIActivityShopResetCallBack,

    [3630] =UIActivityBlackShopQueryCallBack,
    [3631] =UIActivityBlackShopCallBack,
    [3632] =UIActivityBlackShopResetCallBack,

    [3650] =UIActivitySecretShopQueryCallBack,
    [3651] =UIActivitySecretShopCallBack,
    [3652] =UIActivitySecretShopResetCallBack,


    [3660] =UIRobShopCallBack,
    [3661] =UIRobShopBuyCallBack,

    [1340] = UIActivityCopyCallback,
    [1341] = UIActivityCoinCopyCallback,
    [1342] = UIActivityExpDanCopyCallback,
    [1343] = UIActivityForgeStoneCopyCallback,
    [1344] = UIActivityEquipStarCopyCallback,
    [1345] = UIActivityZhenfuCopyCallback,
    [1347] = UIActivityForgingCopyCallback,
    [1348] = UIActivityOneFinshCopyCallback,

    [1350] = UIGeneralCopyQueryCallback,
    [1351] = UIGeneralCopyAttackCallback,
    [1352] = UIGeneralCopyGetBoxCallback,

    [1370] = UIHadesCopyQueryCallback,
    [1371] = UIHadesCopyAttackCallback,
    [1372] = UIHadesCopyGetBoxCallback,

    [3620] = UIMieshendianQueryCallBack,
    [36201] = UIMieshendianBossQueryCallBack,
    [3621] = UIMieshendianBattle1CallBack,
    [3622] = UIMieshendianBattle2CallBack,
    [3623] = UIMieshendianModupCallBack,
    [3624] = UIMieshendianModupCDClearCallBack,
    [3625] = UIMieshendianRankCallBack,
    [3626] = UIMieshendianResetCallBack,
    [3627] = UIMieshendianShopCallBack,
    [3628] = UIMieshendianShopBuyCallBack,

    [3641] = UISignIn2StatusCallBack,
    [3642] = UISignIn2CallBack,
    [3643] = UILuxurySignInStatusCallBack,
    [3644] = UILuxurySignInCallBack,
    [3680] = UIMonthGrowQueryCallBack,
    [3681] = UIMonthGrowGetRewardCallBack,
    [3682] = UIMonthGrowWelfareQueryCallBack,
    [3683] = UIMonthGrowWelfareGetRewardCallBack,

    [3684] = UIMonthGrowQueryX1CallBack,
    [3685] = UIMonthGrowGetRewardX1CallBack,
    [3686] = UIMonthGrowWelfareQueryX1CallBack,
    [3687] = UIMonthGrowWelfareGetRewardX1CallBack,

    --神奇基金
    [3688] = UIMagicFundQueryCallBack,
    [3689] = UIMagicFundRewardCallBack,

    [3690] = UIShareActivityQueryCallBack,
    [3691] = UIShareActivityCallBack,
    [4010] = UITitbitDiscountQuryCallBack,
    [4011] = UITitbitDiscountBuyCallBack,
    [4012] = UITitbitDiscountX1QuryCallBack,
    [4013] = UITitbitDiscountX1BuyCallBack,
    [4014] = UITitbitDiscountX2QuryCallBack,
    [4015] = UITitbitDiscountX2BuyCallBack,
    [4016] = UITitbitDiscountX3QuryCallBack,
    [4017] = UITitbitDiscountX3BuyCallBack,


    [4018] = UICPTitbitDiscountX1QuryCallBack,
    [4019] = UICPTitbitDiscountX1BuyCallBack,
    [4020] = UICPTitbitDiscountX2QuryCallBack,
    [4021] = UICPTitbitDiscountX2BuyCallBack,
    [4022] = UICPTitbitDiscountX3QuryCallBack,
    [4023] = UICPTitbitDiscountX3BuyCallBack,
    [4024] = UICPTitbitDiscountX4QuryCallBack,
    [4025] = UICPTitbitDiscountX4BuyCallBack,

    [8034] = UICPTitbitDiscountX5QuryCallBack,
    [8035] = UICPTitbitDiscountX5BuyCallBack,

    [4000] = UIGrowPlanGlobalCallBack,
    [4001] = UIGrowPlanGlobalRewardCallBack,

    [4100] = UIWuDaoHuiQueryCallBack,
    [4101] = UIWuDaoHuiPiPeiCallBack,
    [4103] = UIWuDaoHuiBoxRewardCallBack,
    [4104] = UIWuDaoHuiReportCallBack,
    [4105] = UIWuDaoHuiLotteryQueryCallBack,
    [4106] = UIWuDaoHuiLotteryRewardCallBack,
    [4107] = UIWuDaoHuiDuanWeiQueryCallBack,
    [4108] = UIWuDaoHuiDuanWeiRewardCallBack,

    [3670] = UIGeneralLoveCallBack,
    [3671] = UIGeneralsLoveQueryCallback,
    [3672] = UIGeneralLoveUsePropCallBack,
    [3673] = UIGeneralLoveTaskCallBack,
    [3674] = UIGeneralLoveTaskRewardCallBack,
    [3675] = UIGeneralLoveExchangeCallBack,


    [3790] = UIActivityMammonQueryCallBack2,
    [3791] = UIActivityMammonCallBack2,
    [3792] = UIActivityMammonBroadCastCallBack2,


    --获取武将，装备，物品，个数
    [12002] = UIGetStaffNumCallback,


    [2130] = UIGuildWarPointCatalogueCallBack,
    [2131] = UIGuildWarPointQueryCallBack,
    [2132] = UIGangPointJoinConfirmCallBack,
    [2133] = UIGangPointJoinQueryCallBack,
    [2134] = UIGangPointEnterBattlefieldCallBack,
    [2135] = UIGangPointJoinBattleCallBack,
    [2136] = UIGangPointInspireCoinCallBack,
    [2137] = UIGangPointInspireGoldCallBack,
    [2142] = UIGuildWarPointAwardCallBack,
    [2144] = UIGuildWarProfitCallBack,
    [2146] = UIGuildWarOneInspireCallBack,
    [2147] = UIGuildWarOneBattleCallBack,

    [2138] = UIGangPointBattleStatusQueryCallBack,
    [2140] = UIGangPointSumBattleListCallBack,
    [2139] = UIGangPointSumBattlePlayCallBack,
    [2141] = UIGangPointBraBattlePlayCallBack,

    -- 主界面公会数据获取
    [2149] = UIMainGetGangDataCallBack,


    [3700] = UISingleBossQuaryCallback,
    [3701] = UISingleBossBattleCallback,

    [3702] = UISlotsArrangeQuaryCallback,
    [3703] = UISlotsArrangeCallback,
    [3704] = UISlotsExceptCallback,

    [3705] = UIKingManOnekeyChallengeCallback,


    [3740] = UIWingQuaryCallback,
    [3741] = UIWingSatrUpCallback,
    [3742] = UIWingStageUpCallback,
    [3743] = UIWingDyeingCallback,
    [3744] = UIWingColorQueryCallback,

    [1140] = UISigilLevelUpCallBack,
    [1141] = UISigilChangePosCallBack,
    [1142] = UISigilCanLevelUpCallBack,

    [1360] = UIInstrumentQueryCallback,
    [1361] = UIInstrumentUnlockCallback,
    [1362] = UIInstrumentForgePreview,
    [1363] = UIInstrumentForgeConfirm,
    [1364] = UIInstrumentForgeAutomaticCallback,
    [1365] = UIBreakForgePreview,


    [3800] = UIMazeQueryCallBack,

    [3801] = UIMazeMoveCallBack,
    [3802] = UIMazeRandomEventCallBack,
    [3803] = UIMazeBattleCallBack,
    [3812] = UIMazeResetCallBack,
    [3806] = UIMazeShopQueryCallBack,
    [3810] = UIMazeShopRefreshCallBack,
    [3807] = UIMazeShopBuyCallBack,
    [3808] = UIMazeTaskQueryCallBack,
    [3809] = UIMazeTaskGetRewardCallBack,    

    [20000] = UIAppStorePay,
    [10000] = UITencentLogin,
    [10002] = UITencentLogin2,
    [10001] = TencentPayCheck,
    [10003] = TencentPayCheck2,

    
    [3811] = UIEnemySlotsQuaryCallback,
    [3804] = UISlotsWithHpQuaryCallback,
    [3805] = UISlotsChangeWithHpCallback,

    [116] = UIRechageSuccessCallback,

    [11501] = UIrechargeONCallBack,
    [11601] = UIrechargeOFFCallBack,

    [2700] = UIChampionStatusCallBack,
    [2701] = UIChampionBattleCallBack,
    [2702] = UIChampionNextCallBack,
    [2703] = UIChampionResetCallBack,
    [2704] = UIChampionBoxOpenCallBack,
    [2705] = UIChampionCompleteCallBack,

    [2710] = UIChampionShopQueryCallBack,
    [2711] = UIChampionShopCallBack,
    [2712] = UIChampionShopResetCallBack,

    [3820] = UIOverPassQueryCallBack,
    [3821] = UIOverPassRankCallBack,
    [3822] = UIOverPassShopCallBack,
    [3823] = UIOverPassShopBuyCallBack,
    [3824] = UIOverPassBattleCallBack,
    [3826] = UIOverPassChangeBossCallBack,
    [3827] = UIOverPassGetRewardCallBack,
    [3828] = UIOverPassRefreshCallBack,
    [3829] = UIOverPassRecordQueryCallBack,
    [3830] = UIOverPassRecordPlayCallBack,

    [3306] = UIDumplingSearchCallBack,
    [3307] = UIDumplingUsedCallBack,

    [3300] = UIDuanWuQueryCallBack,
    [3301] = UIDuanWuLotteryQueryCallBack,
    [3302] = UIDuanWuDuihuanCallBack,

    [4630] = UITurntableQueryCallBack,
    [4631] = UITurntableLotteryCallBack,

    [4650] = UIDivideStallCarnivalQueryCallBack,
    [4651] = UIDivideStallCarnivalDrawCallBack,

    [4660] = UIIntegralTurntableQueryCallBack,
    [4661] = UIIntegralTurntableLuckDrawCallBack,

    [3720] = UIUserProtagonistGameQuery,
    [3721] = UIUserProtagonistGameEatBeans,
    [3722] = UIUserProtagonistGamePopcorn,


    [3733] = UISafeMaskShopQueryCallBack,
    [3734] = UISafeMaskShopRewardCallBack,

    [6451] = UIJinghuaShopQueryCallBack,
    [6452] = UIJinghuaShopRewardCallBack,

    [3730] = UISlotCoverQueryCallBack,
    [3731] = UISlotCoverupCallBack,
    [3732] = UISlotCoverMasterQueryCallBack,
    [3735] = UISlotCoverLevel2UpCallBack,
    [3736] = UISlotCoverFeiShengCallBack,

    [3901] = UIDragonBoatSearchCallBack,
    [3902] = UIDragonBoatUsedCallBack,

    [1070] = UIFashionDressQueryCallBack,
    [1071] = UIFashionDressHideCallBack,
    [1072] = UIFashionDressStrangeCallBack,
    [1073] = UIFashionDressChangeCallBack,

    [1074] = UIFashionDressGetCallBack,
    [1075] = UIFashionDressActQueryCallBack,
    [1076] = UIFashionDressShopQueryCallBack,

    [4200] = UISlotSpiritQueryCallBack,
    [4201] = UISlotSpiritUseCallBack,
    [4202] = UISlotSpiritLevelupCallBack,
    [4204] = UISlotSpiritAdditionQueryCallBack,

    [4310] = UIGodDownShopQueryCallBack,
    [4311] = UIGodDownShopRewardCallBack,
    [4320] = UIGodDownRankQueryCallBack,

    
    [4300] = UIGodDownQueryCallBack,
    [4301] = UIGodDownTributeCallBack,
    [4302] = UIGodDownTributeRewardCallBack,
    [4303] = UIGodDownTributeImmediateCallBack,
    [4304] = UIGodDownGiftCallBack,

    [4400] = UIActivityQShopQueryCallBack,
    [4401] = UIActivityQShopRewardCallBack,

    [4405] = UIChristmasShopQueryCallBack,
    [4406] = UIChristmasShopRewardCallBack,

    [20051] = UIActivityEverydayCallBack,

    [4600] = UIMidAutumnShopQueryCallBack,
    [4601] = UIMidAutumnShopRewardCallBack,

    [4602] = UIMidAutumnShopQuery_x1CallBack,
    [4603] = UIMidAutumnShopReward_x1CallBack,

    [3750] = UISingleRechargeGiftCallBack,
    [3751] = UISingleRechargeGiftRewardCallBack,

    [3758] = UISingleRechargeGiftX2CallBack,
    [3759] = UISingleRechargeGiftRewardX2CallBack,

    [3755] = UISingleRechargeGiftX1CallBack,
    [3756] = UISingleRechargeGiftRewardX1CallBack,

    [5062] = UISingleRechargeGift_X2CallBack,
    [5063] = UISingleRechargeGiftReward_X2CallBack,

    [4700] = UIWorldWarPrepareQueryCallBack,
    [4701] = UIWorldWarGetItemCallBack,
    [4702] = UIWorldWarQueryCallBack,
    [4704] = UIWorldWarPrepareUpdateSlotCallBack,
    [4703] = UIWorldWarRoleBattlesCallBack,
    [4711] = UIWorldWarBattlePlayCallBack,
    [4708] = UIWorldWarTopCallBack,
    [4712] = UIWorldWarTopUserInfoCallBack,
    [4714] = UIWorldWarRoleBattlesRewardCallBack,

    [4705] = UIWorldWarSignInfoQuerCallBack,
    [4706] = UIWorldWarChampionQuerCallBack,
    [4707] = UIWorldWarGroupInfoQueryCallBack,

    [4710] = UIWorldWarTopInfoCallBack,
    [4713] = UIWorldWarTopBetInfoCallBack,

    [4715] = UIWorldWarRankQueryCallBack,
    [4716] = UIWorldWarWeedBetCallBack,

    [4717] = UIWorldWarCurrentChampionQueryCallBack,
    [4718] = UIWorldWarWorshipCallBack,

    [4720] = UIWorldWarRoleBattlesShenbangCallBack,
    [4721] = UIWorldWarTopShenbangCallBack,
    [4722] = UIWorldWarWeedBetShenbangCallBack,
    [4723] = UIWorldWarRoleBattlesRewardShenbangCallBack,
    [4724] = UIWorldWarTopUserInfoShenbangCallBack,
    [4725] = UIWorldWarTopInfoShenbangCallBack,
    [4726] = UIWorldWarTopBetInfoShenbangCallBack,
    [4727] = UIWorldWarBattlePlayShenbangCallBack,
    [4728] = UIWorldWarRankQueryShenbangCallBack,

    [6701] = UIHonorWarSlotQueryCallBack,
    [6702] = UIHonorWarSlotArrangeCallBack,
    [6503] = UIHonorWarStatusQueryCallBack,
    [6504] = UIHonorWarRoleBattlesCallBack,
    [6505] = UIHonorWarRoleBattlesRewardCallBack,
    [6506] = UIHonorWarRoleBattlesInfoCallBack,
    [6507] = UIHonorWarBattlePlayCallBack,
    [6508] = UIHonorWarTopCallBack,
    [6509] = UIHonorWarWeedBetCallBack,
    [6510] = UIHonorWarChampionQueryCallBack,
    [6511] = UIHonorWarGroupInfoQueryCallBack,
    [6512] = UIHonorWarTopUserInfoCallBack,
    [6513] = UIHonorWarLastChampionQueryCallBack,
    [6514] = UIHonorWarStarRankQueryCallBack,
    [6515] = UIHonorWarSignupCallBack,
    [6516] = UIWeekLivenessCallBack,
    [6517] = UITotalLivenessCallBack,
    [6530] = UIWeekLivenessCallBack2,

    [6518] = UIAchievementQueryCallBack,
    [6519] = UIAchievementRewardCallBack,

    [3760] = UIAchievementLimitTimeCallBack,
    [3761] = UIAchievementLimitTimeRewardCallBack,

    [3765] = UIOctober1stCallBack,
    [3766] = UIOctober1stRewardCallBack,
    [37651] = UIOctober1stExtCallBack,

    [4880] = UISevenDayActivityCallBack,
    [4881] = UISevenDayActivityRewardCallBack,
    [48801] = UISevenDayActivityExtCallBack,

    [4611] = UIVipWelfareExchangeCallBack,
    [46111] = UIVipWelfareExtCallBack,

    [3770] = UIRecallCallBack,
    [3771] = UIRecallRewardCallBack,

    [3772] = UIReturnCallBack,
    [3773] = UIReturnRewardCallBack,
    [37721] = UIReturnExtCallBack,
    [3774] = UIReturnCDKCallBack,

    [1346] = UIActivityCopyModUpCallBack,

    [3780] = UIGeneralBestQueryCallBack,
    [10030] = UIRedFragmentsCallBack,

    [4615] = UITimeGiftCallBack,
    [4616] = UITimeGiftRewardCallBack,

    [4719] = UIWorldWarChampionSlotInfoCallBack,

    [4800] = UITriggerGiftQueryCallBack,
    [4801] = UITriggerGiftRewardCallBack,

    [4620] = UIPropRecoveryCallBack,

    [4635] = UITurntableWorldQueryCallBack,
    [4636] = UITurntableWorldDrawCallBack,

    [4810] = UIAuctionHouseQueryCallBack,
    [4811] = UIAuctionHouseAuctionCallBack,
    [4812] = UIAuctionHouseGetCallBack,
    [4813] = UIAuctionHouseLogCallBack,
    [4814] = UIAuctionHouseOptsCallBack,

    [4820] = UIManorQueryCallBack,
    [4821] = UIManorFriendListQueryCallBack,
    [4822] = UIManorLevelUpCallBack,
    [4823] = UIManorGetWoodCallBack,
    [4824] = UIManorNoticeQueryCallBack,
    [4826] = UIManorNoticeGetTaskCallBack,
    [4827] = UIManorNoticeDoneTaskCallBack,
    [4828] = UIManorYaoBattleCallBack,
    [4829] = UIManorShopCallBack,
    [4830] = UIManorShopExchangeCallBack,
    [4831] = UIManorConcentCallBack,

    [4860] = UITotalRechargeQueryCallBack,
    [4861] = UITotalRechargeGetRewardCallBack,

    [4840] = UIGang2BossCallBack,
    [4841] = UIGang2BossRankCallBack,
    [4842] = UIGang2RoleRankCallBack,
    [4843] = UIGang2BossInspireCallBack,
    [4844] = UIGang2BossBattleCallBack,

    [4850] = UIRechargeRebateCallBack,
    [4851] = UIRechargeRebateGetCallBack,

    [4875] = UIKGodDownShopQueryCallBack,
    [4876] = UIKGodDownShopRewardCallBack,
    [4877] = UIKGodDownRankQueryCallBack,

    [4870] = UIKGodDownQueryCallBack,
    [4871] = UIKGodDownTributeCallBack,
    [4872] = UIKGodDownTributeRewardCallBack,
    [4873] = UIKGodDownTributeImmediateCallBack,
    [4874] = UIKGodDownGiftCallBack,

    [4885] = UITurntableRecordCallBack,

    [4890] = UIVipWeekGiftCallback,
    [4891] = UIVipWeekGiftRewardCallback,

    [3860] = UIGamblingCallback,
    [3861] = UIGamblingRewardCallback,
    [3862] = UIGamblingShopCallback,
    [3863] = UIGamblingShopRewardCallback,

    [4006] = UIRechargeDouble2CallBack,

    [4901] = UIDragonWishingQueryCallBack,
    [4902] = UIDragonWishingGetCallBack,
    [4903] = UIDragonWishingRewardCallBack,
    [4904] = UIDragonWishingEventCallBack,
    [4905] = UIDragonWishingEventCloseCallBack,
    [4906] = UIDragonWishingShopCallBack,
    [4907] = UIDragonWishingQueryMapCallBack,
    --
    [5002] = UICPDayDayGiftCallBack,
    [5003] = UICPDayDayGiftRewardCallBack,
    [5000] = UICPRechargeGiftCallBack,
    [5001] = UICPRechargeGiftRewardCallBack,
    [5010] = UICPGodDownQueryCallBack,
    [5011] = UICPGodDownTributeCallBack,
    [5012] = UICPGodDownTributeRewardCallBack,
    [5013] = UICPGodDownTributeImmediateCallBack,
    [5014] = UICPGodDownGiftCallBack,
    [5015] = UICPGodDownShopQueryCallBack,
    [5016] = UICPGodDownShopRewardCallBack,
    [5017] = UICPGodDownRankQueryCallBack,
    [5020] = UICPTigerchickenQueryCallBack,
    [5021] = UICPTigerchickenDoCallBack,
    [5022] = UICPTigerchickenshopQueryCallBack,
    [5023] = UICPTigerchickenshopExchangeCallBack,
    [5025] = UICPAchievementLimitTimeCallBack,
    [5026] = UICPAchievementLimitTimeRewardCallBack,
    [5030] = UICPTitbitDiscountQuryCallBack,
    [5031] = UICPTitbitDiscountBuyCallBack,
    [5032] = UICPOldDriverQueryCallBack,
    [5033] = UICPOldDriverOptCallBack,
    [5034] = UICPRechargeDoubleCallBack,
    [5035] = UICPActivityQShopQueryCallBack,
    [5036] = UICPActivityQShopRewardCallBack,
    [5037] = UICPTurntableQueryCallBack,
    [5038] = UICPTurntableLotteryCallBack,
    [5039] = UICPConsumeGiftCallBack,
    [5040] = UICPConsumeGiftRewardCallBack,
    [5041] = UICPRechargeRebateCallBack,
    [5042] = UICPRechargeRebateGetCallBack,
    [5043] = UICPActivityShopQueryCallBack,
    [5044] = UICPActivityShopCallBack,
    [5045] = UICPActivityShopResetCallBack,
    [5046] = UICPContinue7QueryCallBack,
    [5047] = UICPContinue7RewardCallBack,

    [5048] = UICPSevenDayActivityCallBack,
    [5049] = UICPSevenDayActivityRewardCallBack,

    [4886] = UICPDiZaoShenHuaActivityCallBack,
    [4887] = UICPDiZaoShenHuaActivityRewardCallBack,
    [48861] = UICPDiZaoShenHuaActivityExtCallBack,

    [4888] = UICPTianXiaWuShuangActivityCallBack,
    [4889] = UICPTianXiaWuShuangActivityRewardCallBack,
    [48881] = UICPTianXiaWuShuangActivityExtCallBack,

    [5150] = UIGang2GroundQueryCallBack,
    [5151] = UIGang2GroundStartCallBack,
    [5152] = UIGang2GroundGetHogsCallBack,
    [5153] = UIGang2GroundCatchHogCallBack,
    [5154] = UIGang2GroundBoxRewardsCallBack,
    [5155] = UIGang2GroundRankCallBack,
    [5156] = UIGang2GroundGameOverCallBack,

    [50481] = UICPSevenDayActivityExtCallBack,

    [5050] = UICPSingleRechargeGiftCallBack,
    [5051] = UICPSingleRechargeGiftRewardCallBack,
    [5052] = UICPLimitExchangeQuery,
    [5053] = UICPUserLimitExchange,
    [5054] = UICPUserLimitExchangeRefresh,
    [5055] = UICPTotalRechargeQueryCallBack,
    [5056] = UICPTotalRechargeGetRewardCallBack,
    [5057] = UICPIntegralTurntableQueryCallBack,
    [5058] = UICPIntegralTurntableLuckDrawCallBack,

    [5060] = UICPSingleRechargeGiftX1CallBack,
    [5061] = UICPSingleRechargeGiftRewardX1CallBack,

    [5323] = UIActivityTreeQueryCallBack,
    [5324] = UIActivityTreeWaterCallBack,
    [5325] = UIActivityTreetaskCallBack,
    [5326] = UIActivityTreetaskGetCallBack,
    [5327] = UIActivityTreetaskcancelCallBack,
    [5328] = UIActivityWaterBuyCallBack,
    [5329] = UIActivityTreetaskFreshCallBack,
    [5330] = UIActivityBoxrewardCallBack,

    -- 道馆UI协议
    [5301] = UIDaoGuanMainCallBack,
    [5302] = UIDaoGuanGetRewardCallBack,
    [5303] = UIDaoGuanGoToCallBack,
    [5304] = UIDaoGuanDareCallBack,
    [5305] = UIDaoGuanFightNoteCallBack,
    [5306] = UIDaoGuanArrangeQuaryCallback,
    [5307] = UIDaoGuanArrangeCallback,

    [5309] = UIActivityZhounianRandomCallBack,
    [5310] = UIActivityZhounianQueryCallBack,
    [5311] = UIActivityZhounianPrayCallBack,
    [5312] = UIActivityZhounianTaskCallBack,
    [5313] = UIActivityZhounianTaskGetCallBack,
    [5314] = UIActivityZhounianTaskFreshCallBack,
    [5318] = UIActivityZhounianTaskCancelCallBack,

    [5315] = UIActivityChaozhiQueryCallBack,
    [5316] = UIActivityChaozhiBuyCallBack,
    [5317] = UIActivityChaozhiGetCallBack,

    [5319] = UIForeverRechargeQueryCallBack,
    [5320] = UIForeverRechargeRewardCallBack,

    [5201] = UIHeroBossQueryCallBack,
    [5202] = UIHeroBossFollowCallBack,
    [5203] = UIHeroBossEnterCallBack,
    [5204] = UIHeroBossAttackCallBack,
    [5205] = UIHeroBossCheerCallBack,
    [5206] = UIHeroBossRankCallBack,
    [5207] = UIHeroBossRealNotifyCallBack,
    [5208] = UIHeroBossAwardRecordCallBack,
    [5209] = UIHeroBossReviveCallBack,
    [5210] = UIHeroBossDeadCallBack,
    [5211] = UIHeroBossDoubleCallBack,
    [5212] = UIHeroBossChangeNumCallBack,

    [5331] = UIActivityZhongshuRankCallBack,
    [5345] = UIActivityBuyItemCallBack,
    [5346] = UITurntableRecordCommonCallBack,

    [5401] = UIActivityPeentoGiftQueryCallBack,
    [5402] = UIActivityPeentoGiftRewardCallBack,
    [5403] = UIActivityPeentoGiftResetCallBack,

    [5601] = UIActivityNewRankQueryCallBack,

    [5602] = UIActivityNewRankGetCallBack,
    [5603] = UIActivityPowerGrowthX2CallBack,

    [5501] = UIArtifactCastCallBack,
    [5502] = UIArtifactCommpondCallBack,
    [5503] = UIArtifactChangeCallBack,
    [5504] = UIArtifactOpenPosCallBack,
    [5505] = UIArtifactMountJewelCallBack,
    [5506] = UIJewelUpgradeCallBack,
    [5507] = UIJewelCommpondCallBack,
    [5508] = UIArtifactCheckCallBack,
    [5509] = UIArtifactCheckTimeCallBack,

        -- 一键打造
    [5515] = UIUserArtifactOnceMakeCallBack,
    -- 一键鉴定
    [5516] = UIUserArtifactOnceCheckupCallBack,
    -- 一键重铸
    [5517] = UIUserArtifactRecastCallBack,
     -- 神器锁定
    [5518] = UIUserArtifactLockCallBack,
    -- 神器强化
    [5519] = UIUserArtifactStrengthenCallBack,
    -- 神器重生
    [5520] = UIUserArtifactRenascenceCallBack,

    -- 开孔
    [5540] = UIUserArtifactOpeningCallBack,
    [5541] = UIUserArtifactBaptizeCallBack,
    [5542] = UIUserArtifactBaptizeReplaceCallBack,
    [5543] = UIUserArtifactSkillUpCallBack,

    --洗炼技能取消
    [5544] = UIUserArtifactSkillWashCancelCallBack,
    [5545] = UIUserArtifactSkillExchangeCallBack,
    [5546] = UIUserArtifactStrenExchangeCallBack,

    [5511] = UIGeneralXiuLianLevelInfoCallBack,
    [5512] = UIGeneralXiuLianInfoCallBack,
    [5513] = UIGeneralXiuLianCallBack,

    [5521] = UIEquipCastCallBack,

    [5525] = UIWeekGiftCallBack,
    [5526] = UIWeekGiftRewardCallBack,

    [10031] = UIJewelListDataCallBack,
    [10032] = UIArtifactDataCallBack,

    [5801] = UIActivityWeekCardQueryCallBack,
    [5802] = UIActivityWeekCardActiveCallBack,
    [5803] = UIActivityWeekCardRewardCallBack,
    [5804] = UIActivityWeekCardTipsCallBack,

    [5701] = UITotalRechargeQueryX1CallBack,
    [5702] = UITotalRechargeGetRewardX1CallBack,


    [5410] = UIActivityAuctionQueryCallBack,
    [5411] = UIActivityAuctionClinchCallBack,
    [5412] = UIActivityAuctionRecordingCallBack,
    [5413] = UIActivityAuctionEndCallBack,
    [5414] = UIActivityAuctionIsEndCallBack,
    [5415] = UIActivityAuctionOneKeyCallBack,

    
    [5901] = UILimitPropListQueryCallback,
    [5902] = UILimitPropUseCallback,

    [6001] = UIKingBattleQueryCallBack,
    [6002] = UIKingBattleMatchCallBack,
    [6003] = UIKingBattleMatchSuccessCallBack,
    [6004] = UIKingBattleGlorySelectCallBack,
    [6005] = UIKingBattleDailyRewardQueryCallBack,
    [6006] = UIKingBattleDailyRewardReceiveCallBack,
    [6007] = UIKingBattleSegmentQueryCallBack,
    [6008] = UIKingBattleSegmentReceiveCallBack,
    [6009] = UIKingBattleGloryQueryCallBack,
    [6010] = UIKingBattleLogsQueryCallBack,
    [6011] = UIKingBattleReplayCallBack,
    [6012] = UIKingBattleRevengeCallBack,

    [6015] = UIKingBattleShopQueryCallBack,
    [6016] = UIKingBattleShopRewardCallBack,

    [5531] = UIMonthGrowQueryX2CallBack,
    [5532] = UIMonthGrowGetRewardX2CallBack,
    [5533] = UIMonthGrowWelfareQueryX2CallBack,
    [5534] = UIMonthGrowWelfareGetRewardX2CallBack,

    [6101] = UIPoolingServerSignQueryCallBack,
    [6102] = UIPoolingServerSignGetRewardCallBack,
    [6103] = UIPoolingServerTaskQueryCallBack,
    [6104] = UIPoolingServerTaskGetRewardCallBack,
    [6105] = UIPoolingServerOnlineQueryCallBack,
    [6106] = UIPoolingServerOnlineGetRewardCallBack,
    -- 地狱副本
    [6111] = UIHellCopyQueryCallBack,
    [6112] = UIHellCopyChallengeCallBack,
    [6113] = UIHellCopyRefreshPlayerBuffCallBack,
    [6114] = UIHellCopyGetRewardCallBack,
    [6115] = UIHellCopyChoosePlayerBuffCallBack,
    [6117] = UINewRankQueryCallBack,

    -- 中秋
    [6401] = UIZhongQiuActivityCallBack,
    [6402] = UIZhongQiuActivityRewardCallBack,
    [64011] = UIZhongQiuActivityExtCallBack,

    [6601] = UIActivityChristmasQueryCallBack,
    [6602] = UIActivityChristmasDoCallBack,
    [6603] = UIActivityChristmasRewardCallBack,
    [6604] = UIActivityChristmasReward2CallBack,

    [6501] = UIActivityHolidayQueryCallBack,
    [6502] = UIActivityHolidayDoCallBack,

    [6801] = UIActivityTimebuyQueryCallBack,
    [6802] = UIActivityTimebuyListCallBack,
    [6803] = UIActivityTimebuyRewardCallBack,

    [6901] = UIRedfragmentResolveCallBack,

    [6910] = UIPartnerFashionBuyCallBack,
    [6911] = UIPartnerFashionQueryCallBack,
    [6912] = UIPartnerFashionUseCallBack,
    [6913] = UIPartnerFashionRecoveryCallBack,
    [7001] = UIPartnerFeiShengCallBack,
    [6810] = UIPlayerBackTipsCallBack,
    [6811] = UIPlayerBackQueryCallBack,
    [6812] = UIPlayerBackRewardCallBack,

    [7021] = UIGeneralChangeBreakSkillCallBack,

    [6520] = UIBlessingCaveStatusCallBack,
    [6521] = UIBlessingCaveAttackCallBack,
    [6522] = UIBlessingCaveSweepCallBack,

    --转换
    [7025] = UIGeneralChangeCallback,
    --互换
    [8095] = UISwapChangeCallback,
    --武将觉醒重生
    [8096] = UIGeneralAwakenRebirthCallback,
    --查询单个武将信息
    [8097] = UIQueryGeneralByIdCallback,
    --武将升星重生
    [8301] = UIGeneralUpStarRebirthCallback,

    --神魂殿
    [7030] = UIGodSoulTempleQueryCallback,
    [7031] = UIGodSoulTempleLevelUpCallback,
    [7032] = UIGodSoulTempleRefineSoulQueryCallback,
    [7033] = UIGodSoulTempleRefineSoulCallback,
    [7034] = UIGodSoulTempleCuishenQueryCallback,
    [7035] = UIGodSoulTempleCuishenCallback,

    --玄月秘宝
    [7060] = UIXuanyueQueryCallback,
    [7061] = UIXuanyueAwardCallback,

    --玄月秘宝复制
    [7063] = UIXuanyueQuery2Callback,
    [7064] = UIXuanyueAward2Callback,

    --玄月秘宝3
    [7072] = UIXuanyueQuery3Callback,
    [7073] = UIXuanyueAward3Callback,

    [7002] = UIExaminationStatusCallBack,
    [7003] = UIExaminationStartCallBack,
    [7004] = UIExaminationEndCallBack,
    [7005] = UIExaminationPaihangbangCallBack,
    --上古遗迹
    [7080] = UIAncientRuinsQueryCallback,
    [7081] = UIAncientRuinsAttackCallback,
    [7082] = UIAncientRuinsRewardCallback,
    --成长计划复制
    [7091] = UIGrowPlan2CallBack,
    [7092] = UIGrowPlan2BuyCallBack,
    [7093] = UIGrowPlan2RewardCallBack,
    [7094] = UIGrowPlan2GlobalCallBack,
    [7095] = UIGrowPlan2GlobalRewardCallBack,
    --新10连招募
    [7110] = UIRecruitNewTempQueryCallBack,
    [7111] = UIRecruitNewCallBack,
    [7112] = UIRecruitNewRefreshCallBack,
    [7113] = UIRecruitNewTempSaveCallBack,

    [8020] = UIDisscountGiftQueryCallBack,
    [8021] = UIDisscountGiftRewardCallBack,
    [8022] = UIDisscountGiftQueryCallBack2,
    [8023] = UIDisscountGiftRewardCallBack2,
    [8024] = UIDisscountGiftQueryCallBack3,
    [8025] = UIDisscountGiftRewardCallBack3,
    [8026] = UISpeedGiftQueryCallBack,
    [8027] = UISpeedGiftRewardCallBack,
    [8028] = UISpeedGiftQueryCallBack2,
    [8029] = UISpeedGiftRewardCallBack2,
    [8032] = UISpeedGiftQueryCallBack3,
    [8033] = UISpeedGiftRewardCallBack3,
    [8045] = UIHefuGiftQuryCallBack,
    [8046] = UIHefuGiftBuyCallBack,
    [8047] = UIHefuShopQuryCallBack,
    [8048] = UIHefuShopBuyCallBack,
    
    --游戏助手
    [6211] = UIGameHelperQueryCallback,
    [6212] = UIGameHelperExeCallback,


    --盛宴查询
    [2271] = UIGangFeastCheckCallBack,
    --盛宴加入
    [2272] = UIGangCreateJoinFeastCallBack,
    --盛宴领奖
    [2273] = UIGangGetFeastRewardCallBack,
    --盛宴刷新
    [2274] = UIGangRefreshFeastCallBack,
    --盛宴开启
    [2275] = UIGangHandOpenFeastCallBack,
    --盛宴接龙
    [2276] = UIGangFeastAgainCallBack,
    --盛宴退出
    [2277] = UIGangBackFeastCallBack,
    --盛宴转换经验丹
    [2278] = UIGangExpChangeFeastCallBack,

    --澡堂查询
    [2281] = UIGangBathCheckCallBack,
    --澡堂加入
    [2282] = UIGangCreateJoinBathCallBack,
    --澡堂领奖
    [2283] = UIGangGetBathRewardCallBack,
    --澡堂刷新
    [2284] = UIGangRefreshBathCallBack,
    --开启澡堂
    [2285] = UIGangHandOpenBathCallBack,
    --澡堂接龙
    [2286] = UIGangBathAgainCallBack,
    --澡堂退出
    [2287] = UIGangBackBathCallBack,

    --道具通用购买
    [7501] = UIPropBuyQueryCallback,

    --通用弹幕
    [2290] = UISendBarrageCallBack,
    --露水池
    [8055] = UIDewPoolQueryCallback,
    [8056] = UIDewPoolAwardCallback,
    [8057] = UIDewPoolExchangeCallback,

    --周基金
    [8071] = UIWeekFundQueryX1CallBack,
    [8072] = UIWeekFundAwardX1CallBack,
    [8073] = UIWeekFundQueryX2CallBack,
    [8074] = UIWeekFundAwardX2CallBack,
    [8075] = UICPWeekFundQueryX1CallBack,
    [8076] = UICPWeekFundAwardX1CallBack,
    [8077] = UICPWeekFundQueryX2CallBack,
    [8078] = UICPWeekFundAwardX2CallBack,
    [8079] = UIRCWeekFundQueryX1CallBack,
    [8080] = UIRCWeekFundAwardX1CallBack,
    [8081] = UIRCWeekFundQueryX2CallBack,
    [8082] = UIRCWeekFundAwardX2CallBack,

    --自动炼化
    [8060] = UIShopAutoRefinQueryCallBack,
    [8061] = UIShopAutoRefinSetCallBack,
    --免费好礼
    [8091] = UIUserADQueryCallBack,
    [8092] = UIUserADRewardCallBack,
    [8093] = UIUserADChangsStatusCallBack,

    --幻化
    [8110] = UIIllusionQueryCallBack,
    [8111] = UIIllusionExeCallBack,
    [8112] = UIIllusionCancelCallBack,
    [8113] = UIIllusionActivityQueryCallBack,
    [8114] = UIIllusionActivityRewardCallBack,
    [8115] = UIIllusionActivityQueryX1CallBack,
    [8116] = UIIllusionActivityRewardX1CallBack,
    [8117] = UIIllusionActivityTaskQueryCallBack,
    [8118] = UIIllusionActivityTaskRewardCallBack,

    --复制成长计划 机缘计划
    [8120] = UIGrowPlan4CallBack,
    [8121] = UIGrowPlan4RewardCallBack,

    --复制成长计划 仙缘计划
    [8122] = UIGrowPlan5CallBack,
    [8123] = UIGrowPlan5RewardCallBack,

    --雕塑红利
    [8130] = UISculptureActivityQueryCallBack,
    [8131] = UISculptureActivityAwardCallBack,
    [8132] = UISculptureActivityShopBuyCallBack,
    [8133] = UISculptureActivityRankQueryCallBack,

    --专属神器
    [8101]  = UIExclusiveArtifactQueryCallBack,                  --查询
    [8102]  = UIExclusiveArtifactStrengthenCallBack,             --强化
    [8103]  = UIExclusiveArtifactActiveCallBack,                 --洗礼        
    [8104]  = UIExclusiveArtifactInlayCallBack,                  --镶嵌
    [8105]  = UIExclusiveArtifactQiLingQueryCallBack,            --器灵查询
    [81051] = UIExclusiveArtifactQiLingUpdateCallback,
    [8106]  = UIExclusiveArtifactQiLingStrengthenCallBack,       --器灵强化
    [8107]  = UIExclusiveArtifactQiLingLockCallBack,             --器灵锁定
    [8108]  = UIExclusiveArtifactQiLingRefiningCallBack,         --器灵熔炼
    [8109]  = UIExclusiveArtifacActiveChallengeQueryCallBack,    --神器激活挑战次数查询
    --专属神器副本
    [8201] = UIExclusiveArtifactCopyCallBack,                   
    [8202] = UIExclusiveArtifactCopyFightCallBack,
    [8203] = UIExclusiveArtifactCopySweepCallBack,
    [8204] = UIExclusiveArtifactResetCallBack,

    --天机令
    [8241] = UITokenActiveCallBack,                              --天机令激活
    [8242] = UITokenfragmentComposeCallBack,                     --碎片合成
    [8243] = UITokenRecoveryCallBack,                            --回收


    --封神赛
    [8250] = UIUserApesSignUpCallBack, --报名
    [8251] = UIUserApexQueryCallBack, --主页查询
    [8252] = UIGodCompetitionSlotsQueryCallBack,
    [825200] = UICompetitionSlotsIndexSave, --主阵容的 主角index本地存储
    [8253] = UIGodCompetitionChangeSlotsCallBack,
    [8254] = UIGodCompetitionChangePetCallBack,
    [8255] = UIGodCompetitionSlotSpiritQueryCallBack,
    [8256] = UIGodCompetitionChangeSpiritCallBack,
    [8257] = UIGodCompetitionChangeSpiritPositionCallBack,
    [8258] = UIUserApexBossAttackCallBack, --boss挑战
    [8259] = UIUserApexBossDamageRankCallBack, --boss伤害排行榜查询
    [8260] = UIUserApexBossBattleRecordCallBack, --boss挑战记录
    [8261] = UIUserApexBossRewardsQueryCallBack, --boss伤害奖励查询
    [8262] = UIUserApexBossRewardsCollectCallBack, --boss伤害奖励领取

    [8263] = UIUserApexUpLoadSlotsCallBack, --上传阵容(pvp阶段)
    [8264] = UIUserCheckLoadSlotsCallBack, --上传阵容(检查阵容)

    [8271] = UIUserWarOfApexChampionOldCallBack, --上届冠军信息
    [8272] = UIUserWarOfApexRewardCallBack, --领奖
    [8273] = UIUserWarOfApexRoleBattlesInfoCallBack, --战斗详情
    [8274] = UIUserWarOfApexBattlePlayCallBack, --战斗播放
    [8275] = UIUserWarOfApexBetCallBack, --押注
    [8276] = UIUserWarOfApexChampoionQueryCallBack, --历届冠军排行榜
    [8277] = UIUserWarOfApexGroupInfoCallBack, --赛区信息
    [8278] = UIUserWarOfApexSrarRankCallBack, --星级排行榜

    [8279] = UIUserWarOfApexRoleBattlesCallBack, --预选赛查询
    [8280] = UIUserWarOfApexTopInfoCallBack, --冠军赛查询
    [8281] = UIUserWarOfApexRolesInfoCallBack, --淘汰赛玩家信息

    --耐力密码
    [8245] = UINaiLiCodeRankCallBack,

    --升仙台
    [8851] = UIAscensionSendaiMapQueryCallBack, --地图查询
    [8852] = UIAscensionSendaiMapSelectCallBack, --选择挑战难度
    [8853] = UIAscensionSendaiRunPointCallBack, --走格子
    [8854] = UIAscensionSendaiEventSetCallBack, --事件二次处理
    [8855] = UIAscensionSendaiBufferQueryCallBack, --buff查询

    [8856] = UIAscensionSendaiShopCallBack, --系统商店查询
    [8857] = UIAscensionSendaiShopBuyCallBack, --系统商店购买

    [8858] = UIAscensionSendaiSlotGeneralsUpCallBack, --阵容镜像上传
    [8859] = UIAscensionSendaiSlotGeneralsQueryCallBack, --武将镜像查询
    [88591] = UIAscensionSendaiSlotGeneralsChangeCallBack, --武将布阵
    [8860] = UIAscensionSendaiSlotMonsterQueryCallBack, --怪物阵容查询

}

--客户端接收服务器返回的数据
game_net_callback = {

    --通天塔
    [7010] = NetXianBuyTimesCallBack,
    [7011] = NetBabelTowerQueryCallBack,
    [7012] = NetBabelTowerLevelQueryCallBack,
    [7013] = NetBabelTowerBattleCallback,
    [7014] = NetBabelTowerQuitCallback,
    [7015] = NetBabelTowerAwardCallback,
    [7016] = NetBabelTowerAutoBattleCallback,
    [7017] = NetBabelTowerShopQueryCallback,
    [7018] = NetBabelTowerShopBuyCallback,
    [7019] = NetBabelTowerRankQueryCallback,
    --商会
    [6120] = NetGoodsSellCallBack,
    [6121] = NetGoodsRevokeCallBack,
    [6122] = NetGoodsBuyCallBack,
    [6123] = NetGoodsProtectQueryCallBack,
    [6124] = NetGoodsResetSellCallBack,

    --称号、头像框
    [6301] = NetTitleQueryCallBack,
    [6302] = NetTitleUseCallBack,
    [6303] = NetTitleLoseCallBack,
    [6304] = NetTitleGetCallBack,

    [6201] = NetIconBoxQueryCallBack,
    [6202] = NetIconBoxUseCallBack,
    [6203] = NetIconBoxLoseCallBack,
    [6204] = NetIconBoxGetCallBack,
    -- 魔符自动合成
    [6405] = NetAutoMoFuQueryCallBack,
    [6406] = NetAutoMoFuComposeCallBack,

    -- 天庭银座 began
    [4500] = NetUserPatrolQuery,
    [4501] = NetUserPatrolStatus,
    [4502] = NetUserPatrolAttack,
    [4503] = NetUserPatrolDo,
    [4504] = NetUserPatrolReward,
    [4505] = NetUserPatrolEventDo,
    [4509] = NetUserPatrolOneAdd,
    [4510] = NetUserPatrolOneAddReward,
    [4511] = NetUserPatrolOneAddQuery,
    -- 天庭银座 ends
    -- 限时兑换 began
    [3710] = NetLimitExchangeQuery,
    [3711] = NetUserLimitExchange,
    [3712] = NetUserLimitExchangeRefresh,
    -- 限时兑换 ends
    [999990] = NetbattletestCallBack,
    [999988] = LuaExceptionResponseCallBack,
    [999900] = NetCombMessagesCallback,
    [999]  = NetGlobalParamCallBack,
    [1000] = NetSessionValidateCallback,
    [991000] = NetSessionValidateCallback,

    [999902] = NetRoleInfoBasic,
    [999903] = NetRequestLocking,

    [999904] = NetHearCheckCallBack,
    [999905] = NetServerTimeCallBack,

    [999907] = NetconfigUpdateCallBack,
    [999908] = NetOfflineCallBack,

    [5555] = NetbagLimitTipCallBack,

    [5340] = NetOnlinetimeQueryCallBack,
    [5341] = NetRealnameRewardQueryCallBack,
    [5342] = NetRealnameRewardCallBack,
    [5347] = NetUserKickCallBack,

    [110] = NetCacheReset,
    [111] = NetStaminaUp,
    [112] = NetEnergyUp,

    [100] = NetRandomNameCallBack,
    [101] = NetSetNameCallBack,
    [102] = NetRoleSetProfileCallBack,
    [200] = NetGuideQueryCallBack,
    [201] = NetGuideExcuteCallBack,
    [202] = NetInitGeneralCallBack,

    [203] = NetChangeGenderCallBack,
    [204] = NetGenderQueryCallBack,

    [205] = NetPowerchangeCallBack,


    [212] = NetContinue7QueryCallBack,
    [213] = NetContinue7RewardCallBack,
    [214] = NetContinue7QueryCallBack1,
    [215] = NetContinue7RewardCallBack1,

    [115] = NetRechargePreCallBack,
    [116] = NetRechargeResultCallBack,
    [117] = NetVipCallBack,
    [118] = NetRechargeScoreCallBack,
    [2090] = NetMonthCardCallBack,
    [2091] = NetMonthCardGetCallBack,
    [2092] = NetMonthCardRewardCallBack,
    [2093] = NetMonthCardRewardGetCallBack,
    [2094] = NetGrowPlanCallBack,
    [2095] = NetGrowPlanBuyCallBack,
    [2096] = NetGrowPlanRewardCallBack,
    [2097] = NetRechargeDoubleCallBack,
    [2098] = NetFirstRechargeRewardCallBack,
    [2099] = NetFirstRechargeStatusCallBack,
    [300] = NetVipStatusCallBack,
    [301] = NetUserBuyCallBack,

    [2080] = NetInviteCodeCallback,
    [2081] = NetInviteCodeSetCallBack,
    [2082] = NetInviteCodeRewardCallBack,

    [1030] = NetUserSystemMailCallBack,

    [1032] = NetHintCallBack,
    [1034] = NetHintChangeCallBack,

    [1015] = NetGeneralCollectCallBack,
    [1103] = NetEquipCollectCallBack,
    [3910] = NetTeamRecomQueryCallBack,
    [3911] = NetTeamRecomRewardCallBack,

    [1001] = NetRoleInfoCallBack,
    [1002] = NetSlotsAllInfoCallBack,
    [1003] = NetChangeSlotCallBack,
    [1004] = NetChangecheerCallBack,
    [1005] = NetSlotChangeEquipCallBack,
    [1006] = NetSlotChangeSoulCallBack,
    [1007] = NetQuickEquipCallBack,
    [1008] = NetUpgradeSkillCallBack,
    [1009] = NetSlotArrangeCallBack,

    [1024] = NetGeneralOnSlotCallBack,
    [1025] = NetGeneralAwakenCallBack,
    [1058] = NetProtagonistAwakenCallBack,
    [1027] = NetGeneralSlotCallBack,

    [1029] = NetGeneralUpStarCallBack,

    [1130] = NetMagicstoneUpCallBack,

    [1050] = NetProtagonistQueryCallBack,
    [1051] = NetProtagonistAddAttrCallBack,
    [1052] = NetProtagonistGrowUpCallBack,
    [1053] = NetProtagonistRecoverTrainCallBack,
    [1054] = NetUserProtagonist2CallBack,
    [1055] = NetUserProtagonist2AddAttrCallBack,
    [1056] = NetUserProtagonist2GrowupPreveiwCallBack,
    [1057] = NetUserProtagonist2GrowupCallBack,


    [1020] = NetCheckOtherSlotsInfoCallBack,
    [1022] = NetBattleOtherCallback,

    [1010] = NetGeneralInheritPreviewCallBack,
    [1011] = NetGeneralInheritConfirmCallBack,
    [1012] = NetGeneralFragmentListCallback,
    [1013] = NetGeneralFosterPreviewCallBack,
    [1014] = NetGeneralFosterConfirmCallBack,
    [1016] = NetGeneralCompoundCallBack,
    [1017] = NetGeneralBreakCallBack,
    [1023] = NetGeneralBreakPreviewCallBack,
    [1018] = NetGameGeneralFragmentRobQueryCallback,
    [1019] = NetGameGeneralFragmentRobCallBack,

    [1021] = NetGeneralExchangeCallBack,


    [1031] = NetSomeIdsCallBack,

    [1038] = NetUseExpDanCallBack,

    [1026] = NetGeneralArtifactLevelupCallBack,

    [1800] = NetTechListCallback,
    [1801] = NetTechUpgradeCallBack,

    [1805] = NetDevilStatusCallback,
    [1806] = NetDevilExchangeFragmentCallback,
    [1807] = NetDevilUpCallback,
    [1808] = NetDevilStatus2Callback,
    [1809] = NetDevilLevel1ExpCallback,
    [1810] = NetDevilLevel2UpCallback,

    [1040] = NetPetQueryCallback,
    [1041] = NetPetLevel1UpCallback,
    [1042] = NetPetLevel2UpCallback,
    [1043] = NetPetSetCallback,
    [1044] = NetPetFragmentCallback,
    [1045] = NetPetCompoundCallback,

    [1046] = NetPetStageUpCallback,
    [1047] = NetPetPassiveSkillCallback,
    [1048] = NetPetPassiveSkillStudyCallback,
    [1049] = NetPetBagCompoundCallback,

    [1060] = NetPetPassiveSkillLockCallback,
    [1061] = NetPetPassiveSkillResetCallback,

    [1062] = NetPetLevel1Up2Callback,

    [1064] = NetPetPassiveSkillRedCallback,

    [1065] = NetPetResetCallBack,

    [1066] = NetPetDevourCallback,

    [1110] = NetGameTreasureFragmentRobQueryCallback,
    [1111] = NetGameTreasureFragmentRobCallBack,
    [1112] = NetRobProfCDqueryCallBack,
    [1113] = NetRobProfCDAddCallBack,
    [1114] = NetGameTreasureFragmentRobTenCallBack,
    [1125] = NetRobOneKeyTreasureCallback,

    [1101] = NetEquipStrengthenCallBack,
    [1102] = NetEquipRefineCallBack,

    [1105] = NetTreasureUpCallBack,
    [1106] = NetTreasureRefineCallBack,
    [1107] = NetEquipFragmentAllCallback,
    [1108] = NetEquipFragmentCompoundCallBack,
    [1109] = NetQuickEquipStrengthenCallBack,

    [1115] = NetEquipRefineExCallBack,
    [1116] = NetTreasureRefineExCallBack,

    [1118] = NetTreasureStrengthenCallBack,
    [1119] = NetTreasureRefine2CallBack,

    [1210] = NetTreasureStrengthenByPropCallBack,

    [1104] = NetEquipResolveCallBack,
    [1036] = NetGeneralFragmentResolveCallBack,
    [1117] = NetEquipResetCallBack,
    [1035] = NetGeneralResetCallBack,
    [1037] = NetGeneralResolveCallBack,
    [1077] = NetFashionDressResetCallBack,
    [1039] = NetGeneralResolveCallBack2,

    [3850] = NetResolveQualityCallBack,

    [1120] = NetEquipBaptizePreviewCallBack,
    [1121] = NetEquipBaptizeConfirmCallBack,

    [1122] = NetEquipStageUpCallBack,

    [1123] = NetEquipStarUpCallBack,

    [1124] = NetEquipBaptizeAutomaticCallBack,
    [1126] = NetGeneralAutoTrainCallBack,  --武将培养加上
    [1127] = NetTreasureStarUpCallBack,  --宝物升星

    [2501] = NetSoulHuntQueryCallBack,
    [2502] = NetSoulHuntCallBack,
    [2503] = NetSoulExchangeCallBack,
    [2504] = NetSoulUpgradeCallBack,
    [2505] = NetSoulHunt41CallBack,
    [2506] = NetSoulResolveCallBack,
    [2507] = NetSoulCompoundCallBack,

    [1400] = NetGeneralRecruitStatusCallback,
    [1401] = NetGeneralRecruitCallback,

    [1402] = NetGeneralRecruitQueryCallback,
    [1403] = NetGeneralRecruit2Callback,
    [5321] = NetGeneralRecruitShopQueryCallback,
    [5322] = NetGeneralRecruitRewardCallback,

    [1404] = NetOldDriverQueryCallBack,
    [1405] = NetOldDriverOptCallBack,

    [1406] = NetTigerchickenQueryCallBack,
    [1407] = NetTigerchickenDoCallBack,
    [1408] = NetTigerchickenshopQueryCallBack,
    [1409] = NetTigerchickenshopExchangeCallBack,

    --作妖2048
    [1600] = NetMiniGameQueryCallback,
    [1601] = NetMiniGameSynchronizationCallback,
    [1602] = NetMiniGameOverCallback,
    [1603] = NetMiniGameStartCallback,
    [1604] = NetMiniGameExchangeCallback,
    [1605] = NetMiniGameAchievementCallback,
    [1606] = NetMiniGameAchievementRewardCallback,
    [1607] = NetMiniGameRankCallback,
    [1608] = NetMiniGameExchangeQueryCallback,

    [1610] = NetAthleticsList2Callback,
    [1611] = NetAthleticsAtta2ckCallback,
    [1613] = NetAthleticsRewardsQuery3Callback,
    [1614] = NetAthleticsRewardExchange3Callback,
    [1615] = NetAthleticsRankRewardsStatusCallback,
    [1616] = NetAthleticsBoss2Callback,

    [1300] = NetCopyQueryCallback,
    [1301] = NetCopyAttackCallback,
    [1302] = NetCopyWipeCallback,
    [1306] = NetCopyAttack2Callback,
    [1307] = NetCopyWipe2Callback,
    [1303] = NetCopyAll3StarRewardCallback,
    [1304] = NetCopyPrestigeRewardCallback,
    [1305] = NetCopyResetKillCallback,

    [1330] = NetBraveCopyQueryCallback,
    [1331] = NetBraveCopyAttackCallback,
    [1332] = NetBraveCopyWipeCallback,
    [1337] = NetBraveCopyAttack2Callback,
    [1338] = NetBraveCopyWipe2Callback,
    [1333] = NetBraveCopyAll3StarRewardCallback,
    [1334] = NetBraveCopyPrestigeRewardCallback,
    [1335] = NetBraveCopyResetKillCallback,

    [1336] = NetCopyClearTimerCallback,

    [1310] = NetEncounterQueryCallback,
    [1311] = NetEncounterUseCallback,

--    [1320] = NetFriendCopyQueryCallback,
--    [1321] = NetFriendCopyAttackCallback,

    [1323] = NetFriendCopyQueryCallback,
    [1324] = NetFriendCopyAttackCallback,
    [1325] = NetFriendCopyOneFinishCallback,

    [1322] = NetFriendCopyRankCallback,

    [1200] = NetPropListCallback,
    [1201] = NetPropUseCallback,
    [1203] = NetPropNumQueryCallback,

    [2000] = NetActivityQueryCallBack,
    [2070] = NetBloodQueryCallBack,
    [2071] = NetBloodBattleCallBack,
    [2072] = NetBlood3AttrBufQueryCallBack,
    [2073] = NetBlood3AttrBufCallBack,
    [2074] = NetBlood5AwardQueryCallBack,
    [2075] = NetBlood5AwardCallBack,
    [2076] = NetBloodRankQueryCallBack,
    [2077] = NetBloodWipeCallBack,
    [2078] = NetBloodWipeRewardCallBack,
    [2079] = NetBloodWipeContinueCallBack,
    -- [2085] = NetBloodExchangeCallBack,
    [2085] = NetActivitySDKShareQueryCallBack,
    [2086] = NetActivitySDKShareDoCallBack,
    [2087] = NetActivitySDKShareRewardCallBack,

    --[2030] = NetHappinessPlaceQueryCallBack,
    --[2031] = NetHappinessPlaceUseCallBack,
    --[2032] = NetHappinessPlaceRankCallback,
    --[2033] = NetHappinessPlaceExchangeCallBack,
    --[2034] = NetHappinessPlaceServerRewardCallBack,

    [2031] = NetCornucopiaQueryCallBack,
    [2032] = NetCornucopiaCallBack,
    [2033] = NetCornucopiaRewardCallBack,

    [2035] = NetActivityStartGiftQueryCallBack,
    [2036] = NetActivityStartGiftCallBack,
    [2022] = NetDayDayGiftCallBack,
    [2023] = NetDayDayGiftRewardCallBack,

    [3310] = NetDayDayGiftX1CallBack,
    [3311] = NetDayDayGiftX1RewardCallBack,

    [2024] = NetRechargeGiftCallBack,
    [2025] = NetRechargeGiftRewardCallBack,

    [2020] = NetConsumeGiftCallBack,
    [2021] = NetConsumeGiftRewardCallBack,

    [2010] = NetActivityEatChickenQueryCallBack,
    [2011] = NetEatChickenCallBack,
    [2015] = NetActivityMammonQueryCallBack,
    [2016] = NetActivityMammonCallBack,
    [2017] = NetActivityMammonBroadCastCallBack,
    [2060] = NetSignInStatusCallBack,
    [2061] = NetSignInCallBack,
    [2062] = NetMysticalStargazingCallBack,
    [2063] = NetMysticalSwacthStarCallBack,
    [2064] = NetMysticalChangeSwacthStarCallBack,
    [2065] = NetGetWatchStartCallBack, 
    [2066] = NetWatchStarRewardCallBack,
    [2067] = NetWatchStarWatchExCallBack,
    [2068] = NetWatchStarUpLevelCallBack,

    --[2040] = NetPenglaiCallBack,
    [2041] = NetPenglaiSelectDifficultyCallBack,
    [2042] = NetPenglaiSearchCallBack,
    [2043] = NetPenglaiBattleCallBack,
    [2044] = NetPenglaiRankCallBack,
    [2045] = NetPenglaiTodayRewardCallBack,
    [2046] = NetPenglaiTotalCallBack,
    [2047] = NetPenglaiTotalRewardCallBack,
    [2048] = NetPenglaiTaskCallBack,
    [2049] = NetPenglaiTaskRewardCallBack,

    [2110] = NetIslandCallBack,
    [2111] = NetIslandGotoCallBack,
    [2112] = NetIslandNextCallBack,
    [2113] = NetIslandGetTodayRewardCallBack,
    [2114] = NetIslandTaskCallBack,
    [2115] = NetIslandTaskRewardCallBack,
    [2116] = NetIslandRankCallBack,
    [2117] = NetIslandGlobalCallBack,
    [2118] = NetIslandGlobalRewardCallBack,

    [2120] = NetPenglai3CallBack,
    [2121] = NetPenglai3DiceCallBack,
    [2122] = NetPenglai3RewardCallBack,
    [2123] = NetPenglai3ResetCallBack,
    [2124] = NetPenglai3CardCallBack,
    [2125] = NetPenglai3CardOpenCallBack,
    [2126] = NetPenglai3CardCloseCallBack,
    [2127] = NetPenglaiAitoRewardCallBack,
    [2128] = NetPenglaiAutoReward2CallBack,




    [2050] = NetMysticalCaveCallBack,
    [2051] = NetMysticalCaveForecastCallBack,
    [2052] = NetMysticalCaveReversionCallBack,
    [2053] = NetMysticalCaveConfirmCallBack,
    [2054] = NetMysticalRewardCallBack,
    [2055] = NetActivityExchangeCallBack,
    [2056] = NetActivityExchangeEXCallBack,
    [2057] = NetActivityExchangeRefreshCallBack,

    [2089] = NetUserCDKeyExchangeCallBack,

    [2300] = NetFriendQueryCallback,
    [2301] = NetFriendRecommendCallback,
    [2302] = NetFriendReqCallBack,
    [2303] = NetFriendReqQueryCallback,
    [2304] = NetFriendRepCallBack,
    [2305] = NetFriendChatQueryCallback,
    [2306] = NetFriendChatCallback,
    [2307] = NetFriendSearchCallBack,
    [2308] = NetFriendSendGiftCallBack,
    [2309] = NetFriendRecvGiftCallBack,
    [2310] = NetFriendDeleteCallBack,
    [2311] = NetFriendAllReqCallBack,
    [6038] = NetFriendAllAddCallback,

    [2400] = NetTaskQueryCallBack,
    [2401] = NetTaskCompleteCallBack,

    [2410] = NetLivenessCallBack,
    [2411] = NetLivenessRewardCallBack,

    [2100] = NetCupStatusCallBack,
    [2101] = NetCupJoinTomorrowCallBack,
    [2102] = NetCupTopCallBack,
    [2103] = NetCupBattlePlayCallBack,
    [2104] = NetCupBattleRewardCallBack,
    [2105] = NetCupBattleBetCallBack,
    [2106] = NetCupBattleRewardallCallBack,

    [2107] = NetCupRankCallBack,

    [2200] = NetGangStatusCallBack,
    [2201] = NetGangCreateCallBack,
    [2202] = NetGangsCallBack,
    [2203] = NetGangReqCallBack,
    [2204] = NetGangReqQueryCallBack,
    [2205] = NetGangReqRepCallBack,
    [2206] = NetGangMemberCallBack,
    [2207] = NetGangKickMemberCallBack,
    [2208] = NetGangQuitCallBack,
    [2209] = NetGangPassPowerCallBack,
    [2210] = NetGangSetAssistantCallBack,
    [2211] = NetGangSetAnnouncementCallBack,
    [2219] = NetGangRemoveAssistantCallBack,
    [2220] = NetGangsearchCallBack,



    [2230] = NetUserGang2CallBack,
    [2231] = NetUserGang2CreateCallBack,
    [2232] = NetUserGang2ListCallBack,
    [2233] = NetUserGang2ReqCallBack,
    [2234] = NetUserGang2ReqQueryCallBack,
    [2235] = NetUserGang2RepCallBack,
    [2236] = NetUserGang2MemberCallBack,
    [2237] = NetUserGang2MSetContent1CallBack,
    [2238] = NetUserGang2MSetContent2CallBack,
    [2239] = NetUserGang2MSetViceCallBack,
    [2240] = NetUserGang2MKickCallBack,
    [2241] = NetUserGang2MPassCallBack,
    [2242] = NetUserGang2QuitCallBack,
    [2243] = NetUserGang2SearchCallBack,

    [2250] = NetUserGang2PrayQueryCallBack,
    [2251] = NetUserGang2PrayCallBack,
    [2252] = NetGuideShopViewCallBack,
    [2253] = NetGuideShopBuyGoodsCallBack,
    [2254] = NetUserGang2OptsCallBack,
    [2255] = NetUserGang2ImpeachCallBack,
    [2256] = NetUserGang2FishpondCallBack,
    [2257] = NetUserGang2FishpondFeedCallBack,
    [2258] = NetUserGang2FishpondRewardCallBack,
    [2259] = NetUserGang2MSetNameCallBack,
    [2260] = NetUserGang2DailyRewardCallBack,
    [2261] = NetUserGang2FishpondPointRankCallBack,
    [2262] = NetGangSkillQuery,
    [2263] = NetGangSkillStudy,    

    [2265] = NetGangApplyLimitCallBack,
    [2266] = NetUserGang2DisbandCallBack,

    [2267] = NetUserGang2ReqCancelCallBack,
    
    [2312] = NetFriendChatListCallback,
    [2313] = NetFriendHasChatCallback,

    [2610] = NetDevilFotressStatusCallBack,
    [2611] = NetDevilFotressGangDefCallBack,
    [2612] = NetDevilFotressGangDefSetCallBack,
    [2613] = NetDevilFotressGangDefsCallBack,
    [2614] = NetDevilFotressGangProciamCallBack,
    [2616] = NetDevilFtoressTargetCallBack,
    [2617] = NetDevilFotressAutoBattleCallBack,
    [2618] = NetDevilFotressTargetBattleCallBack,
    [2600] = NetDevilFotressBattleNotifyCallBack,

    [2880] = NetTimeBagCallback,
    [2881] = NetTimeBagGetCallBack,
    [2882] = NetTimeBagTrigCallBack,

    [3000] = NetUserChatQueryCallBack,
    [3001] = NetUserChatCallBack,
    [3002] = NetFriendAllShieldCallBack,
    [3003] = NetFriendAddShieldCallBack,
    [3004] = NetFriendDeleteShieldCallBack,
    [3010] = NetUserGangChatQueryCallBack,
    [3011] = NetUserGangChatCallBack,
    [3012] = NetUserChatNumResetCallBack,
    [3015] = NetBroadcastQueryCallBack,

    [3200] = NetshopQueryCallback,
    [3210] = NetGiftBagQueryCallback,
    [3201] = NetShopBuyCallback,
    [3211] = NetGiftBagBuyCallback,

    [3100] = NetMailListCallBack,
    [3101] = NetMailReadCallBack,
    [3102] = NetMailDeleteCallBack,
    [3103] = NetMailSendCallBack,

    [3400]  = NetWorldBoss1QueryCallBack,
    [3401]  = NetWorldBoss1AttackCallBack,
    [3402]  = NetWorldBoss1RankCallBack,
    [3403]  = NetWorldBoss1RealNotifyCallBack,
    [3404]  = NetWorldBoss1PreRankCallBack,

    [3410]  = NetWorldBoss2QueryCallBack,
    [3411]  = NetWorldBoss2AttackCallBack,
    [3412]  = NetWorldBoss2RankCallBack,
    [3413]  = NetWorldBoss2RealNotifyCallBack,
    [3414]  = NetWorldBoss2PreRankCallBack,
    [3415]  = NetWorldBoss2OfflineBattleCallBack,
    [3416]  = NetWorldBoss2OfflineBattleResultCallBack,


    [2037] = NetOnlineRewardQueryCallBack,
    [2038] = NetOnlineRewardCallBack,
    [2039] = NetOnlineRewardByTimeQueryCallBack,
    [2040] = NetOnlineRewardByTimeCallBack,

    [3500] = NetRankQueryCallBack,
    [3501] = NetRankChangeCallBack,
    [3503] = NetOldRankQueryCallBack,

    [3600] = NetZhuxiantaiQueryCallBack,
    [3601] = NetZhuxiantaiBattleCallBack,
    [3602] = NetZhuxiantaiWipeCallBack,
    [3603] = NetZhuxiantaiAttrQueryCallBack,
    [3604] = NetZhuxiantaiAttrSelectCallBack,
    [3605] = NetZhuxiantaiRankCallBack,
    [3606] = NetZhuxiantaiExchangeCallBack,
    [3607] = NetZhuxiantaiResetCallBack,



    [3610] = NetBegin7DaysCallBack,
    [3611] = NetBegin7DaysRewardCallBack,

    [3615] =NetActivityShopQueryCallBack,
    [3616] =NetActivityShopCallBack,
    [3617] =NetActivityShopResetCallBack,

    [3630] =NetActivityBlackShopQueryCallBack,
    [3631] =NetActivityBlackShopCallBack,
    [3632] =NetActivityBlackShopResetCallBack,

    [3650] =NetActivitySecretShopQueryCallBack,
    [3651] =NetActivitySecretShopCallBack,
    [3652] =NetActivitySecretShopResetCallBack,


    [3660] =NetRobShopCallBack,
    [3661] =NetRobShopBuyCallBack,

    [3620] = NetMieshendianQueryCallBack,
    [3621] = NetMieshendianBattle1CallBack,
    [3622] = NetMieshendianBattle2CallBack,
    [3623] = NetMieshendianModupCallBack,
    [3624] = NetMieshendianModupCDClearCallBack,
    [3625] = NetMieshendianRankCallBack,
    [3626] = NetMieshendianResetCallBack,
    [3627] = NetMieshendianShopCallBack,
    [3628] = NetMieshendianShopBuyCallBack,


    [3641] = NetSignIn2StatusCallBack,
    [3642] = NetSignIn2CallBack,
    [3643] = NetLuxurySignInStatusCallBack,
    [3644] = NetLuxurySignInCallBack,
    [3680] = NetMonthGrowQueryCallBack,
    [3681] = NetMonthGrowGetRewardCallBack,
    [3682] = NetMonthGrowWelfareQueryCallBack,
    [3683] = NetMonthGrowWelfareGetRewardCallBack,

    [3684] = NetMonthGrowQueryX1CallBack,
    [3685] = NetMonthGrowGetRewardX1CallBack,
    [3686] = NetMonthGrowWelfareQueryX1CallBack,
    [3687] = NetMonthGrowWelfareGetRewardX1CallBack,

    --神奇基金
    [3688] = NetMagicFundQueryCallBack,
    [3689] = NetMagicFundRewardCallBack,

    [3690] = NetShareActivityQueryCallBack,
    [3691] = NetShareActivityCallBack,

    [3790] = NetActivityMammonQueryCallBack2,
    [3791] = NetActivityMammonCallBack2,
    [3792] = NetActivityMammonBroadCastCallBack2,

    [4010] = NetTitbitDiscountQuryCallBack,
    [4011] = NetTitbitDiscountBuyCallBack,
    [4012] = NetTitbitDiscountX1QuryCallBack,
    [4013] = NetTitbitDiscountX1BuyCallBack,
    [4014] = NetTitbitDiscountX2QuryCallBack,
    [4015] = NetTitbitDiscountX2BuyCallBack,
    [4016] = NetTitbitDiscountX3QuryCallBack,
    [4017] = NetTitbitDiscountX3BuyCallBack,


    [4018] = NetCPTitbitDiscountX1QuryCallBack,
    [4019] = NetCPTitbitDiscountX1BuyCallBack,
    [4020] = NetCPTitbitDiscountX2QuryCallBack,
    [4021] = NetCPTitbitDiscountX2BuyCallBack,
    [4022] = NetCPTitbitDiscountX3QuryCallBack,
    [4023] = NetCPTitbitDiscountX3BuyCallBack,
    [4024] = NetCPTitbitDiscountX4QuryCallBack,
    [4025] = NetCPTitbitDiscountX4BuyCallBack,
    
    [8034] = NetCPTitbitDiscountX5QuryCallBack,
    [8035] = NetCPTitbitDiscountX5BuyCallBack,

    [4000] = NetGrowPlanGlobalCallBack,
    [4001] = NetGrowPlanGlobalRewardCallBack,

    [4100] = NetWuDaoHuiQueryCallBack,
    [4101] = NetWuDaoHuiPiPeiCallBack,

    [4102] = NetWuDaoHuiPiPeiSuceccsCallBack,
    [4103] = NetWuDaoHuiBoxRewardCallBack,
    [4104] = NetWuDaoHuiReportCallBack,
    [4105] = NetWuDaoHuiLotteryQueryCallBack,
    [4106] = NetWuDaoHuiLotteryRewardCallBack,
    [4107] = NetWuDaoHuiDuanWeiQueryCallBack,
    [4108] = NetWuDaoHuiDuanWeiRewardCallBack,




    [1999] = NetBroadcastCallBack,


    [3670] = NetGeneralLoveCallBack,
    [3671] = NetGeneralsLoveQueryCallback,
    [3672] = NetGeneralLoveUsePropCallBack,
    [3673] = NetGeneralLoveTaskCallBack,
    [3674] = NetGeneralLoveTaskRewardCallBack,
    [3675] = NetGeneralLoveExchangeCallBack,

    
    [2130] = NetGuildWarPointCatalogueCallBack,
    [2131] = NetGuildWarPointQueryCallBack,
    [2132] = NetGangPointJoinConfirmCallBack,
    [2133] = NetGangPointJoinQueryCallBack,
    [2134] = NetGangPointEnterBattlefieldCallBack,
    [2135] = NetGangPointJoinBattleCallBack,
    [2136] = NetGangPointInspireCoinCallBack,
    [2137] = NetGangPointInspireGoldCallBack,
    [2143] = NetGangPointMembersCallBack,
    [2142] = NetGuildWarPointAwardCallBack,

    [2144] = NetGuildWarProfitCallBack,
    [2145] = NetGuildWarProfitChangeCallBack,

    [2146] = NetGuildWarOneInspireCallBack,
    [2147] = NetGuildWarOneBattleCallBack,
    
    [2138] = NetGangPointBattleStatusQueryCallBack,
    [2140] = NetGangPointSumBattleListCallBack,
    [2139] = NetGangPointSumBattlePlayCallBack,
    [2141] = NetGangPointBraBattlePlayCallBack,

    [3700] = NetSingleBossQuaryCallback,
    [3701] = NetSingleBossBattleCallback,

    [3702] = NetSlotsArrangeQuaryCallback,
    [3703] = NetSlotsArrangeCallback,
    [3704] = NetSlotsExceptCallback,

    [3705] = NetKingManOnekeyChallengeCallback,


    [3740] = NetWingQuaryCallback,
    [3741] = NetWingSatrUpCallback,
    [3742] = NetWingStageUpCallback,
    [3743] = NetWingDyeingCallback,
    [3744] = NetWingColorQueryCallback,

    [1140] = NetSigilLevelUpCallBack,
    [1141] = NetSigilChangePosCallBack,


    [1340] = NetActivityCopyCallback,
    [1341] = NetyActivityCoinCopyCallback,
    [1342] = NetActivityExpDanCopyCallback,
    [1343] = NetActivityForgeStoneCopyCallback,
    [1344] = NetActivityEquipStarCopyCallback,
    [1345] = NetActivityZhenfuCopyCallback,
    [1347] = NetActivityForgingCopyCallback,
    [1348] = NetActivityOneFinshCopyCallback,
    
    [1350] = NetGeneralCopyQueryCallback,
    [1351] = NetGeneralCopyAttackCallback,
    [1352] = NetGeneralCopyGetBoxCallback,

    [1370] = NetHadesCopyQueryCallback,
    [1371] = NetHadesCopyAttackCallback,
    [1372] = NetHadesCopyGetBoxCallback,

    [1360] = NetInstrumentQueryCallback,
    [1361] = NetInstrumentUnlockCallback,
    [1362] = NetInstrumentForgePreview,
    [1363] = NetInstrumentForgeConfirm,
    [1364] = NetInstrumentForgeAutomaticCallback,
    [1365] = NetBreakForgePreview,


    [3800] = NetMazeQueryCallBack,
    [3801] = NetMazeMoveCallBack,
    [3802] = NetMazeRandomEventCallBack,
    [3803] = NetMazeBattleCallBack,
    [3812] = NetMazeResetCallBack,


    
    [3811] = NetEnemySlotsQuaryCallback,
    [3804] = NetSlotsWithHpQuaryCallback,
    [3805] = NetSlotsChangeWithHpCallback,

    [3806] = NetMazeShopQueryCallBack,
    [3810] = NetMazeShopRefreshCallBack,
    [3807] = NetMazeShopBuyCallBack,
    [3808] = NetMazeTaskQueryCallBack,
    [3809] = NetMazeTaskGetRewardCallBack,

    [2700] = NetChampionStatusCallBack,
    [2701] = NetChampionBattleCallBack,
    [2702] = NetChampionNextCallBack,
    [2703] = NetChampionResetCallBack,
    [2704] = NetChampionBoxOpenCallBack,
    [2705] = NetChampionCompleteCallBack,

    [2710] = NetChampionShopQueryCallBack,
    [2711] = NetChampionShopCallBack,
    [2712] = NetChampionShopResetCallBack,

    [3820] = NetOverPassQueryCallBack,
    [3821] = NetOverPassRankCallBack,
    [3822] = NetOverPassShopCallBack,
    [3823] = NetOverPassShopBuyCallBack,
    [3824] = NetOverPassBattleCallBack,
    [3825] = NetOverPassRankRefreshCallBack,
    [3826] = NetOverPassChangeBossCallBack,
    [3827] = NetOverPassGetRewardCallBack,
    [3828] = NetOverPassRefreshCallBack,
    [3829] = NetOverPassRecordQueryCallBack,
    [3830] = NetOverPassRecordPlayCallBack,
    [3831] = NetOverPassRecordUpdateCallBack,

    [3306] = NetDumplingSearchCallBack,
    [3307] = NetDumplingUsedCallBack,

    [3300] = NetDuanWuQueryCallBack,
    [3301] = NetDuanWuLotteryQueryCallBack,
    [3302] = NetDuanWuDuihuanCallBack,

    [4630] = NetTurntableQueryCallBack,
    [4631] = NetTurntableLotteryCallBack,

    [4650] = NetDivideStallCarnivalQueryCallBack,
    [4651] = NetDivideStallCarnivalDrawCallBack,

    [4660] = NetIntegralTurntableQueryCallBack,
    [4661] = NetIntegralTurntableLuckDrawCallBack,

    [3720] = NetUserProtagonistGameQuery,
    [3721] = NetUserProtagonistGameEatBeans,
    [3722] = NetUserProtagonistGamePopcorn,


    [3733] = NetSafeMaskShopQueryCallBack,
    [3734] = NetSafeMaskShopRewardCallBack,

    [6451] = NetJinghuaShopQueryCallBack,
    [6452] = NetJinghuaShopRewardCallBack,

    [3730] = NetSlotCoverQueryCallBack,
    [3731] = NetSlotCoverupCallBack,
    [3732] = NetSlotCoverMasterQueryCallBack,
    [3735] = NetSlotCoverLevel2UpCallBack,
    [3736] = NetSlotCoverFeiShengCallBack,
    [3901] = NetDragonBoatSearchCallBack,
    [3902] = NetDragonBoatUsedCallBack,

    [1070] = NetFashionDressQueryCallBack,
    [1071] = NetFashionDressHideCallBack,
    [1072] = NetFashionDressStrangeCallBack,
    [1073] = NetFashionDressChangeCallBack,

    [1074] = NetFashionDressGetCallBack,
    [1075] = NetFashionDressActQueryCallBack,
    [1076] = NetFashionDressShopQueryCallBack,

    [4310] = NetGodDownShopQueryCallBack,
    [4311] = NetGodDownShopRewardCallBack,
    [4320] = NetGodDownRankQueryCallBack,

    [4200] = NetSlotSpiritQueryCallBack,
    [4201] = NetSlotSpiritUseCallBack,
    [4202] = NetSlotSpiritLevelupCallBack,
    [4203] = NetSlotSpiritChangeCallBack,
    [4204] = NetSlotSpiritAdditionQueryCallBack,

    [4300] = NetGodDownQueryCallBack,
    [4301] = NetGodDownTributeCallBack,
    [4302] = NetGodDownTributeRewardCallBack,
    [4303] = NetGodDownTributeImmediateCallBack,
    [4304] = NetGodDownGiftCallBack,


    [4400] = NetActivityQShopQueryCallBack,
    [4401] = NetActivityQShopRewardCallBack,

    [4405] = NetChristmasShopQueryCallBack,
    [4406] = NetChristmasShopRewardCallBack,

    [4600] = NetMidAutumnShopQueryCallBack,
    [4601] = NetMidAutumnShopRewardCallBack,

    [4602] = NetMidAutumnShopQuery_x1CallBack,
    [4603] = NetMidAutumnShopReward_x1CallBack,

    [3750] = NetSingleRechargeGiftCallBack,
    [3751] = NetSingleRechargeGiftRewardCallBack,


    [3758] = NetSingleRechargeGiftX2CallBack,
    [3759] = NetSingleRechargeGiftRewardX2CallBack,

    [3755] = NetSingleRechargeGiftX1CallBack,
    [3756] = NetSingleRechargeGiftRewardX1CallBack,

    [5062] = NetSingleRechargeGift_X2CallBack,
    [5063] = NetSingleRechargeGiftReward_X2CallBack,

    [4700] = NetWorldWarPrepareQueryCallBack,
    [4701] = NetWorldWarGetItemCallBack,
    [4702] = NetWorldWarQueryCallBack,
    [4704] = NetWorldWarPrepareUpdateSlotCallBack,
    [4703] = NetWorldWarRoleBattlesCallBack,
    [4711] = NetWorldWarBattlePlayCallBack,
    [4708] = NetWorldWarTopCallBack,
    [4712] = NetWorldWarTopUserInfoCallBack,
    [4714] = NetWorldWarRoleBattlesRewardCallBack,
    [4709] = NetWorldWarPreparePushCallBack,

    [4705] = NetWorldWarSignInfoQuerCallBack,
    [4706] = NetWorldWarChampionQuerCallBack,
    [4707] = NetWorldWarGroupInfoQueryCallBack,

    [4710] = NetWorldWarTopInfoCallBack,
    [4713] = NetWorldWarTopBetInfoCallBack,

    [4715] = NetWorldWarRankQueryCallBack,
    [4716] = NetWorldWarWeedBetCallBack,

    [4717] = NetWorldWarCurrentChampionQueryCallBack,
    [4718] = NetWorldWarWorshipCallBack,

    [4720] = NetWorldWarRoleBattlesShenbangCallBack,
    [4721] = NetWorldWarTopShenbangCallBack,
    [4722] = NetWorldWarWeedBetShenbangCallBack,
    [4723] = NetWorldWarRoleBattlesRewardShenbangCallBack,
    [4724] = NetWorldWarTopUserInfoShenbangCallBack,
    [4725] = NetWorldWarTopInfoShenbangCallBack,
    [4726] = NetWorldWarTopBetInfoShenbangCallBack,
    [4727] = NetWorldWarBattlePlayShenbangCallBack,
    [4728] = NetWorldWarRankQueryShenbangCallBack,

    [6701] = NetHonorWarSlotQueryCallBack,
    [6702] = NetHonorWarSlotArrangeCallBack,
    [6503] = NetHonorWarStatusQueryCallBack,
    [6504] = NetHonorWarRoleBattlesCallBack,
    [6505] = NetHonorWarRoleBattlesRewardCallBack,
    [6506] = NetHonorWarRoleBattlesInfoCallBack,
    [6507] = NetHonorWarBattlePlayCallBack,
    [6508] = NetHonorWarTopCallBack,
    [6509] = NetHonorWarWeedBetCallBack,
    [6510] = NetHonorWarChampionQueryCallBack,
    [6511] = NetHonorWarGroupInfoQueryCallBack,
    [6512] = NetHonorWarTopUserInfoCallBack,
    [6513] = NetHonorWarLastChampionQueryCallBack,
    [6514] = NetHonorWarStarRankQueryCallBack,
    [6515] = NetHonorWarSignupCallBack,
    [6516] = NetWeekLivenessCallBack,
    [6517] = NetTotalLivenessCallBack,
    [6530] = NetWeekLivenessCallBack2,


    [6518] = NetAchievementQueryCallBack,
    [6519] = NetAchievementRewardCallBack,

    [3760] = NetAchievementLimitTimeCallBack,
    [3761] = NetAchievementLimitTimeRewardCallBack,

    [3765] = NetOctober1stCallBack,
    [3766] = NetOctober1stRewardCallBack,

    [4880] = NetSevenDayActivityCallBack,
    [4881] = NetSevenDayActivityRewardCallBack,

    [4611] = NetVipWelfareExchangeCallBack,

    [3770] = NetRecallCallBack,
    [3771] = NetRecallRewardCallBack,

    [3772] = NetReturnCallBack,
    [3773] = NetReturnRewardCallBack,
    [3774] = NetReturnCDKCallBack,
    [3776] = NetRecallChangeCallBack,

    [1346] = NetActivityCopyModUpCallBack,

    [3780] = NetGeneralBestQueryCallBack,

    [4615] = NetTimeGiftCallBack,
    [4616] = NetTimeGiftRewardCallBack,

    [4719] = NetWorldWarChampionSlotInfoCallBack,

    [4800] = NetTriggerGiftQueryCallBack,
    [4801] = NetTriggerGiftRewardCallBack,
    [4802] = NetTriggerGiftPushCallBack,

    [4620] = NetPropRecoveryCallBack,

    [4635] = NetTurntableWorldQueryCallBack,
    [4636] = NetTurntableWorldDrawCallBack,

    [4810] = NetAuctionHouseQueryCallBack,
    [4811] = NetAuctionHouseAuctionCallBack,
    [4812] = NetAuctionHouseGetCallBack,
    [4813] = NetAuctionHouseLogCallBack,
    [4814] = NetAuctionHouseOptsCallBack,
    [4815] = NetAuctionHouseChangeCallBack,

    [4820] = NetManorQueryCallBack,
    [4821] = NetManorFriendListQueryCallBack,
    [4822] = NetManorLevelUpCallBack,
    [4823] = NetManorGetWoodCallBack,
    [4824] = NetManorNoticeQueryCallBack,
    [4825] = NetManorChangeCallBack,
    [4826] = NetManorNoticeGetTaskCallBack,
    [4827] = NetManorNoticeDoneTaskCallBack,
    [4828] = NetManorYaoBattleCallBack,
    [4829] = NetManorShopCallBack,
    [4830] = NetManorShopExchangeCallBack,
    [4831] = NetManorConcentCallBack,

    [4860] = NetTotalRechargeQueryCallBack,
    [4861] = NetTotalRechargeGetRewardCallBack,

    [4840] = NetGang2BossCallBack,
    [4841] = NetGang2BossRankCallBack,
    [4842] = NetGang2RoleRankCallBack,
    [4843] = NetGang2BossInspireCallBack,
    [4844] = NetGang2BossBattleCallBack,
    [4845] = NetGang2BossNotifyCallBack,
    [4846] = NetGang2BossChangeCallBack,

    [4850] = NetRechargeRebateCallBack,
    [4851] = NetRechargeRebateGetCallBack,

    [4875] = NetKGodDownShopQueryCallBack,
    [4876] = NetKGodDownShopRewardCallBack,
    [4877] = NetKGodDownRankQueryCallBack,

    [4870] = NetKGodDownQueryCallBack,
    [4871] = NetKGodDownTributeCallBack,
    [4872] = NetKGodDownTributeRewardCallBack,
    [4873] = NetKGodDownTributeImmediateCallBack,
    [4874] = NetKGodDownGiftCallBack,

    [4885] = NetTurntableRecordCallBack,

    [4890] = NetVipWeekGiftCallback,
    [4891] = NetVipWeekGiftRewardCallback,

    [3860] = NetGamblingCallback,
    [3861] = NetGamblingRewardCallback,
    [3862] = NetGamblingShopCallback,
    [3863] = NetGamblingShopRewardCallback,

    [4006] = NetRechargeDouble2CallBack,

    [4901] = NetDragonWishingQueryCallBack,
    [4902] = NetDragonWishingGetCallBack,
    [4903] = NetDragonWishingRewardCallBack,
    [4904] = NetDragonWishingEventCallBack,
    [4905] = NetDragonWishingEventCloseCallBack,
    [4906] = NetDragonWishingShopCallBack,
    [4907] = NetDragonWishingQueryMapCallBack,

    --
    [5002] = NetCPDayDayGiftCallBack,
    [5003] = NetCPDayDayGiftRewardCallBack,
    [5000] = NetCPRechargeGiftCallBack,
    [5001] = NetCPRechargeGiftRewardCallBack,
    [5010] = NetCPGodDownQueryCallBack,
    [5011] = NetCPGodDownTributeCallBack,
    [5012] = NetCPGodDownTributeRewardCallBack,
    [5013] = NetCPGodDownTributeImmediateCallBack,
    [5014] = NetCPGodDownGiftCallBack,
    [5015] = NetCPGodDownShopQueryCallBack,
    [5016] = NetCPGodDownShopRewardCallBack,
    [5017] = NetCPGodDownRankQueryCallBack,
    [5020] = NetCPTigerchickenQueryCallBack,
    [5021] = NetCPTigerchickenDoCallBack,
    [5022] = NetCPTigerchickenshopQueryCallBack,
    [5023] = NetCPTigerchickenshopExchangeCallBack,
    [5025] = NetCPAchievementLimitTimeCallBack,
    [5026] = NetCPAchievementLimitTimeRewardCallBack,
    [5030] = NetCPTitbitDiscountQuryCallBack,
    [5031] = NetCPTitbitDiscountBuyCallBack,
    [5032] = NetCPOldDriverQueryCallBack,
    [5033] = NetCPOldDriverOptCallBack,
    [5034] = NetCPRechargeDoubleCallBack,
    [5035] = NetCPActivityQShopQueryCallBack,
    [5036] = NetCPActivityQShopRewardCallBack,
    [5037] = NetCPTurntableQueryCallBack,
    [5038] = NetCPTurntableLotteryCallBack,
    [5039] = NetCPConsumeGiftCallBack,
    [5040] = NetCPConsumeGiftRewardCallBack,
    [5041] = NetCPRechargeRebateCallBack,
    [5042] = NetCPRechargeRebateGetCallBack,
    [5043] = NetCPActivityShopQueryCallBack,
    [5044] = NetCPActivityShopCallBack,
    [5045] = NetCPActivityShopResetCallBack,
    [5046] = NetCPContinue7QueryCallBack,
    [5047] = NetCPContinue7RewardCallBack,

    [5048] = NetCPSevenDayActivityCallBack,
    [5049] = NetCPSevenDayActivityRewardCallBack,

    [4886] = NetCPDiZaoShenHuaActivityCallBack,
    [4887] = NetCPDiZaoShenHuaActivityRewardCallBack,

    [4888] = NetCPTianXiaWuShuangActivityCallBack,
    [4889] = NetCPTianXiaWuShuangActivityRewardCallBack,

    [5050] = NetCPSingleRechargeGiftCallBack,
    [5051] = NetCPSingleRechargeGiftRewardCallBack,
    [5052] = NetCPLimitExchangeQuery,
    [5053] = NetCPUserLimitExchange,
    [5054] = NetCPUserLimitExchangeRefresh,
    [5055] = NetCPTotalRechargeQueryCallBack,
    [5056] = NetCPTotalRechargeGetRewardCallBack,
    [5057] = NetCPIntegralTurntableQueryCallBack,
    [5058] = NetCPIntegralTurntableLuckDrawCallBack,

    [5060] = NetCPSingleRechargeGiftX1CallBack,
    [5061] = NetCPSingleRechargeGiftRewardX1CallBack,

    [5323] = NetActivityTreeQueryCallBack,
    [5324] = NetActivityTreeWaterCallBack,
    [5325] = NetActivityTreetaskCallBack,
    [5326] = NetActivityTreetaskGetCallBack,
    [5327] = NetActivityTreetaskcancelCallBack,
    [5328] = NetActivityWaterBuyCallBack,
    [5329] = NetActivityTreetaskFreshCallBack,
    [5330] = NetActivityBoxrewardCallBack,


    [5150] = NetGang2GroundQueryCallBack,
    [5151] = NetGang2GroundStartCallBack,
    [5154] = NetGang2GroundBoxRewardsCallBack,
    [5155] = NetGang2GroundRankCallBack,
    [5156] = NetGang2GroundGameOverCallBack,

    -- 道馆Net协议
    [5301] = NetDaoGuanMainCallBack,
    [5302] = NetDaoGuanGetRewardCallBack,
    [5303] = NetDaoGuanGoToCallBack,
    [5304] = NetDaoGuanDareCallBack,
    [5305] = NetDaoGuanFightNoteCallBack,
    [5306] = NetDaoGuanArrangeQuaryCallback,
    --周年许愿
    [5309] = NetActivityZhounianRandomCallBack,
    [5310] = NetActivityZhounianQueryCallBack,
    [5311] = NetActivityZhounianPrayCallBack,
    [5312] = NetActivityZhounianTaskCallBack,
    [5313] = NetActivityZhounianTaskGetCallBack,
    [5314] = NetActivityZhounianTaskFreshCallBack,
    [5318] = NetActivityZhounianTaskCancelCallBack,

    [5315] = NetActivityChaozhiQueryCallBack,
    [5316] = NetActivityChaozhiBuyCallBack,
    [5317] = NetActivityChaozhiGetCallBack,

    [5319] = NetForeverRechargeQueryCallBack,
    [5320] = NetForeverRechargeRewardCallBack,

    [5201] = NetHeroBossQueryCallBack,
    [5202] = NetHeroBossFollowCallBack,
    [5203] = NetHeroBossEnterCallBack,
    [5204] = NetHeroBossAttackCallBack,
    [5205] = NetHeroBossCheerCallBack,
    [5206] = NetHeroBossRankCallBack,
    [5207] = NetHeroBossRealNotifyCallBack,
    [5208] = NetHeroBossAwardRecordCallBack,
    [5209] = NetHeroBossReviveCallBack,
    [5210] = NetHeroBossDeadCallBack,
    [5211] = NetHeroBossDoubleCallBack,
    [5212] = NetHeroBossChangeNumCallBack,

    [5331] = NetActivityZhongshuRankCallBack,

    [5345] = NetActivityBuyItemCallBack,
    [5346] = NetTurntableRecordCommonCallBack,

    [5401] = NetActivityPeentoGiftQueryCallBack,
    [5402] = NetActivityPeentoGiftRewardCallBack,
    [5403] = NetActivityPeentoGiftResetCallBack,

    [5501] = NetArtifactCastCallBack,
    [5502] = NetArtifactCommpondCallBack,
    [5503] = NetArtifactChangeCallBack,
    [5504] = NetArtifactOpenPosCallBack,
    [5505] = NetArtifactMountJewelCallBack,
    [5506] = NetJewelUpgradeCallBack,
    [5507] = NetJewelCommpondCallBack,
    [5508] = NetArtifactCheckCallBack,
    [5509] = NetArtifactCheckTimeCallBack,

    -- 一键打造
    [5515] = NetUserArtifactOnceMakeCallBack,
    -- 一键鉴定
    [5516] = NetUserArtifactOnceCheckupCallBack,
    -- 一键重铸
    [5517] = NetUserArtifactRecastCallBack,
     -- 神器锁定
    [5518] = NetUserArtifactLockCallBack,
    -- 神器强化
    [5519] = NetUserArtifactStrengthenCallBack,
    -- 神器重生
    [5520] = NetUserArtifactRenascenceCallBack,

    [5540] = NetUserArtifactOpeningCallBack,
    [5541] = NetUserArtifactBaptizeCallBack,
    [5542] = NetUserArtifactBaptizeReplaceCallBack,
    [5543] = NetUserArtifactSkillUpCallBack,
    --洗炼技能取消
    [5544] = NetUserArtifactSkillWashCancelCallBack,
    [5545] = NetUserArtifactSkillExchangeCallBack,
    [5546] = NetUserArtifactStrenExchangeCallBack,
    
    [10000] = NetTencentLogin,
    [10002] = NetTencentLogin2,

    [999997] = NetErrorMessageCallback7,
    [999998] = NetErrorMessageCallback8,
    [999999] = NetErrorMessageCallback9,
    [5601] = NetActivityNewRankQueryCallBack,

    [5602] = NetActivityNewRankGetCallBack,
    [5603] = NetActivityPowerGrowthX2CallBack,

    [5801] = NetActivityWeekCardQueryCallBack,
    [5802] = NetActivityWeekCardActiveCallBack,
    [5803] = NetActivityWeekCardRewardCallBack,
    [5804] = NetActivityWeekCardTipsCallBack,

    [5701] = NetTotalRechargeQueryX1CallBack,
    [5702] = NetTotalRechargeGetRewardX1CallBack,

    [5511] = NetGeneralXiuLianLevelInfoCallBack,
    [5512] = NetGeneralXiuLianInfoCallBack,
    [5513] = NetGeneralXiuLianCallBack,

    [5521] = NetEquipCastCallBack,

    [5525] = NetWeekGiftCallBack,
    [5526] = NetWeekGiftRewardCallBack,

    [5410] = NetActivityAuctionQueryCallBack,
    [5411] = NetActivityAuctionClinchCallBack,
    [5412] = NetActivityAuctionRecordingCallBack,
    [5413] = NetActivityAuctionEndCallBack,
    [5414] = NetActivityAuctionIsEndCallBack,
    [5415] = NetActivityAuctionOneKeyCallBack,
    
    [5901] = NetLimitPropListQueryCallback,
    [5902] = NetLimitPropUseCallback,

    [6001] = NetKingBattleQueryCallBack,
    [6002] = NetKingBattleMatchCallBack,
    [6003] = NetKingBattleMatchSuccessCallBack,
    [6004] = NetKingBattleGlorySelectCallBack,
    [6005] = NetKingBattleDailyRewardQueryCallBack,
    [6006] = NetKingBattleDailyRewardReceiveCallBack,
    [6007] = NetKingBattleSegmentQueryCallBack,
    [6008] = NetKingBattleSegmentReceiveCallBack,
    [6009] = NetKingBattleGloryQueryCallBack,
    [6010] = NetKingBattleLogsQueryCallBack,
    [6011] = NetKingBattleReplayCallBack,
    [6012] = NetKingBattleRevengeCallBack,

    [6015] = NetKingBattleShopQueryCallBack,
    [6016] = NetKingBattleShopRewardCallBack,

    [5531] = NetMonthGrowQueryX2CallBack,
    [5532] = NetMonthGrowGetRewardX2CallBack,
    [5533] = NetMonthGrowWelfareQueryX2CallBack,
    [5534] = NetMonthGrowWelfareGetRewardX2CallBack,

    [6101] = NetPoolingServerSignQueryCallBack,
    [6102] = NetPoolingServerSignGetRewardCallBack,
    [6103] = NetPoolingServerTaskQueryCallBack,
    [6104] = NetPoolingServerTaskGetRewardCallBack,
    [6105] = NetPoolingServerOnlineQueryCallBack,
    [6106] = NetPoolingServerOnlineGetRewardCallBack,
    -- 地狱副本
    [6111] = NetHellCopyQueryCallBack,
    [6112] = NetHellCopyChallengeCallBack,
    [6113] = NetHellCopyRefreshPlayerBuffCallBack,
    [6114] = NetHellCopyGetRewardCallBack,
    [6115] = NetHellCopyChoosePlayerBuffCallBack,
    [6116] = NetHellCopyRefreshBossBuffCallBack,
    [6117] = NetNewRankQueryCallBack,
    -- 中秋
    [6401] = NetZhongQiuActivityCallBack,
    [6402] = NetZhongQiuActivityRewardCallBack,

    [6601] = NetActivityChristmasQueryCallBack,
    [6602] = NetActivityChristmasDoCallBack,
    [6603] = NetActivityChristmasRewardCallBack,
    [6604] = NetActivityChristmasReward2CallBack,

    [6501] = NetActivityHolidayQueryCallBack,
    [6502] = NetActivityHolidayDoCallBack,

    [6801] = NetActivityTimebuyQueryCallBack,
    [6802] = NetActivityTimebuyListCallBack,
    [6803] = NetActivityTimebuyRewardCallBack,

    [6901] = NetRedfragmentResolveCallBack,

    [6910] = NetPartnerFashionBuyCallBack,
    [6911] = NetPartnerFashionQueryCallBack,
    [6912] = NetPartnerFashionUseCallBack,
    [6913] = NetPartnerFashionRecoveryCallBack,
    [6914] = NetPartnerFashionHasRecoveryCallBack,
    [7001] = NetPartnerFeiShengCallBack,
    [6810] = NetPlayerBackTipsCallBack,
    [6811] = NetPlayerBackQueryCallBack,
    [6812] = NetPlayerBackRewardCallBack,

    [7021] = NetGeneralChangeBreakSkillCallBack,

    [6520] = NetBlessingCaveStatusCallBack,
    [6521] = NetBlessingCaveAttackCallBack,
    [6522] = NetBlessingCaveSweepCallBack,

    --转换
    [7025] = NetGeneralChangeCallback,
    --互换
    [8095] = NetSwapChangeCallback,
    --武将觉醒重生
    [8096] = NetGeneralAwakenRebirthCallback,
    --查询单个武将信息
    [8097] = NetQueryGeneralByIdCallback,
    --武将升星重生
    [8301] = NetGeneralUpStarRebirthCallback,
        
    --神魂殿
    [7030] = NetGodSoulTempleQueryCallback,
    [7031] = NetGodSoulTempleLevelUpCallback,
    [7032] = NetGodSoulTempleRefineSoulQueryCallback,
    [7033] = NetGodSoulTempleRefineSoulCallback,
    [7034] = NetGodSoulTempleCuishenQueryCallback,
    [7035] = NetGodSoulTempleCuishenCallback,
    --玄月秘宝
    [7060] = NetXuanyueQueryCallback,
    [7061] = NetXuanyueAwardCallback,
    [7062] = NetXuanyueActivateCallback,

    --玄月复制
    [7063] = NetXuanyueQuery2Callback,
    [7064] = NetXuanyueAward2Callback,
    [7067] = NetXuanyueActivate2Callback,

    --玄月密保3
    [7072] = NetXuanyueQuery3Callback,
    [7073] = NetXuanyueAward3Callback,
    [7074] = NetXuanyueActivate3Callback,
    
    [7002] = NetExaminationStatusCallBack,
    [7003] = NetExaminationStartCallBack,
    [7004] = NetExaminationEndCallBack,
    [7005] = NetExaminationPaihangbangCallBack,
    --上古遗迹
    [7080] = NetAncientRuinsQueryCallback,
    [7081] = NetAncientRuinsAttackCallback,
    [7082] = NetAncientRuinsRewardCallback,
    --成长计划复制
    [7091] = NetGrowPlan2CallBack,
    [7092] = NetGrowPlan2BuyCallBack,
    [7093] = NetGrowPlan2RewardCallBack,
    [7094] = NetGrowPlan2GlobalCallBack,
    [7095] = NetGrowPlan2GlobalRewardCallBack,
    --新10连招募
    [7110] = NetRecruitNewTempQueryCallBack,
    [7111] = NetRecruitNewCallBack,
    [7112] = NetRecruitNewRefreshCallBack,
    [7113] = NetRecruitNewTempSaveCallBack,

    [8020] = NetDisscountGiftQueryCallBack,
    [8021] = NetDisscountGiftRewardCallBack,
    [8022] = NetDisscountGiftQueryCallBack2,
    [8023] = NetDisscountGiftRewardCallBack2,
    [8024] = NetDisscountGiftQueryCallBack3,
    [8025] = NetDisscountGiftRewardCallBack3,
    [8026] = NetSpeedGiftQueryCallBack,
    [8027] = NetSpeedGiftRewardCallBack,
    [8028] = NetSpeedGiftQueryCallBack2,
    [8029] = NetSpeedGiftRewardCallBack2,
    [8032] = NetSpeedGiftQueryCallBack3,
    [8033] = NetSpeedGiftRewardCallBack3,
    [8045] = NetHefuGiftQuryCallBack,
    [8046] = NetHefuGiftBuyCallBack,
    [8047] = NetHefuShopQuryCallBack,
    [8048] = NetHefuShopBuyCallBack,

    --游戏助手
    [6211] = NetGameHelperQueryCallback,
    [6212] = NetGameHelperExeCallback,


    --公会盛宴
    [2271] = NetGangFeastCheckCallBack,
    --盛宴加入
    [2272] = NetGangCreateJoinFeastCallBack,
    --盛宴领奖
    [2273] = NetGangGetFeastRewardCallBack,
    --盛宴刷新
    [2274] = NetGangRefreshFeastCallBack,
    --盛宴开启
    [2275] = NetGangHandOpenFeastCallBack,
    --盛宴接龙
    [2276] = NetGangFeastAgainCallBack,
    --盛宴退出
    [2277] = NetGangBackFeastCallBack,
    --盛宴转换经验丹
    [2278] = NetGangExpChangeFeastCallBack,

    --公会篝火
    [2281] = NetGangBathCheckCallBack,
    --澡堂加入
    [2282] = NetGangCreateJoinBathCallBack,
    --澡堂领奖
    [2283] = NetGangGetBathRewardCallBack,
    --澡堂刷新
    [2284] = NetGangRefreshBathCallBack,
    --开启澡堂
    [2285] = NetGangHandOpenBathCallBack,
    --澡堂接龙
    [2286] = NetGangBathAgainCallBack,
    --澡堂退出
    [2287] = NetGangBackBathCallBack,

    --道具通用购买
    [7501] = NetPropBuyQueryCallback,

    --通用弹幕
    [2290] = NetSendBarrageCallBack,
    [2291] = NetBarrageCallBack,
    --露水池
    [8055] = NetDewPoolQueryCallback,
    [8056] = NetDewPoolAwardCallback,
    [8057] = NetDewPoolExchangeCallback,

    --周基金
    [8071] = NetWeekFundQueryX1CallBack,
    [8072] = NetWeekFundAwardX1CallBack,
    [8073] = NetWeekFundQueryX2CallBack,
    [8074] = NetWeekFundAwardX2CallBack,
    [8075] = NetCPWeekFundQueryX1CallBack,
    [8076] = NetCPWeekFundAwardX1CallBack,
    [8077] = NetCPWeekFundQueryX2CallBack,
    [8078] = NetCPWeekFundAwardX2CallBack,
    [8079] = NetRCWeekFundQueryX1CallBack,
    [8080] = NetRCWeekFundAwardX1CallBack,
    [8081] = NetRCWeekFundQueryX2CallBack,
    [8082] = NetRCWeekFundAwardX2CallBack,

    --自动炼化
    [8060] = NetShopAutoRefinQueryCallBack,
    [8061] = NetShopAutoRefinSetCallBack,
    --免费好礼
    [8091] = NetUserADQueryCallBack,
    [8092] = NetUserADRewardCallBack,
    [8093] = NetUserADChangsStatusCallBack,

    --幻化
    [8110] = NetIllusionQueryCallBack,
    [8111] = NetIllusionExeCallBack,
    [8112] = NetIllusionCancelCallBack,
    [8113] = NetIllusionActivityQueryCallBack,
    [8114] = NetIllusionActivityRewardCallBack,
    [8115] = NetIllusionActivityQueryX1CallBack,
    [8116] = NetIllusionActivityRewardX1CallBack,
    [8117] = NetIllusionActivityTaskQueryCallBack,
    [8118] = NetIllusionActivityTaskRewardCallBack,

    --复制成长计划 机缘计划
    [8120] = NetGrowPlan4CallBack,
    [8121] = NetGrowPlan4RewardCallBack,

    --复制成长计划 仙缘计划
    [8122] = NetGrowPlan5CallBack,
    [8123] = NetGrowPlan5RewardCallBack,

    --雕塑红利
    [8130] = NetSculptureActivityQueryCallBack,
    [8131] = NetSculptureActivityAwardCallBack,
    [8132] = NetSculptureActivityShopBuyCallBack,
    [8133] = NetSculptureActivityRankQueryCallBack,


    --专属神器
    [8101] = NetExclusiveArtifactQueryCallBack,                  --查询
    [8102] = NetExclusiveArtifactStrengthenCallBack,             --强化
    [8103] = NetExclusiveArtifactActiveCallBack,                 --激活       
    [8104] = NetExclusiveArtifactInlayCallBack,                  --镶嵌
    [8105] = NetExclusiveArtifactQiLingQueryCallBack,            --器灵查询   
    [8106] = NetExclusiveArtifactQiLingStrengthenCallBack,       --器灵强化
    [8107] = NetExclusiveArtifactQiLingLockCallBack,             --器灵锁定
    [8108] = NetExclusiveArtifactQiLingRefiningCallBack,         --器灵熔炼
    [8109] = NetExclusiveArtifacActiveChallengeQueryCallBack,    --神器激活挑战次数查询
    --专属神器副本
    [8201] = NetExclusiveArtifactCopyCallBack,
    [8202] = NetExclusiveArtifactCopyFightCallBack,
    [8203] = NetExclusiveArtifactCopySweepCallBack,
    [8204] = NetExclusiveArtifactResetCallBack,

    --天机令
    [8241] = NetTokenActiveCallBack,                              --天机令激活
    [8242] = NetTokenfragmentComposeCallBack,                     --碎片合成
    [8243] = NetTokenRecoveryCallBack,                            --回收


    --封神赛
    [8250] = NetUserApesSignUpCallBack, --报名
    [8251] = NetUserApexQueryCallBack, --主页查询
    [8252] = NetGodCompetitionSlotsQueryCallBack,
    [8253] = NetGodCompetitionChangeSlotsCallBack,
    [8254] = NetGodCompetitionChangePetCallBack,
    [8255] = NetGodCompetitionSlotSpiritQueryCallBack,
    [8256] = NetGodCompetitionChangeSpiritCallBack,
    [8257] = NetGodCompetitionChangeSpiritPositionCallBack,
    [8258] = NetUserApexBossAttackCallBack, --boss挑战
    [8259] = NetUserApexBossDamageRankCallBack, --boss伤害排行榜查询
    [8260] = NetUserApexBossBattleRecordCallBack, --boss挑战记录
    [8261] = NetUserApexBossRewardsQueryCallBack, --boss伤害奖励查询
    [8262] = NetUserApexBossRewardsCollectCallBack, --boss伤害奖励领取

    [8263] = NetUserApexUpLoadSlotsCallBack, --上传阵容(pvp阶段)
    [8264] = NetUserCheckLoadSlotsCallBack, --上传阵容(检查阵容)

    [8271] = NetUserWarOfApexChampionOldCallBack, --上届冠军信息
    [8272] = NetUserWarOfApexRewardCallBack, --领奖
    [8273] = NetUserWarOfApexRoleBattlesInfoCallBack, --战斗详情
    [8274] = NetUserWarOfApexBattlePlayCallBack, --战斗播放
    [8275] = NetUserWarOfApexBetCallBack, --押注
    [8276] = NetUserWarOfApexChampoionQueryCallBack, --历届冠军排行榜
    [8277] = NetUserWarOfApexGroupInfoCallBack, --赛区信息
    [8278] = NetUserWarOfApexSrarRankCallBack, --星级排行榜

    [8279] = NetUserWarOfApexRoleBattlesCallBack, --预选赛查询
    [8280] = NetUserWarOfApexTopInfoCallBack, --冠军赛查询
    [8281] = NetUserWarOfApexRolesInfoCallBack, --淘汰赛玩家信息

    [8245] = NetNaiLiCodeRankCallBack,

    --升仙台
    [8851] = NetAscensionSendaiMapQueryCallBack, --地图查询
    [8852] = NetAscensionSendaiMapSelectCallBack, --选择挑战难度
    [8853] = NetAscensionSendaiRunPointCallBack, --走格子
    [8854] = NetAscensionSendaiEventSetCallBack, --事件二次处理
    [8855] = NetAscensionSendaiBufferQueryCallBack, --buff查询

    [8856] = NetAscensionSendaiShopCallBack, --系统商店查询
    [8857] = NetAscensionSendaiShopBuyCallBack, --系统商店购买

    [8858] = NetAscensionSendaiSlotGeneralsUpCallBack, --阵容镜像上传
    [8859] = NetAscensionSendaiSlotGeneralsQueryCallBack, --武将镜像查询
    [8860] = NetAscensionSendaiSlotMonsterQueryCallBack, --怪物阵容查询

}

local game_net_ext_callback = {}

function RegsiterNetExtCall(id, func)
    game_net_ext_callback[id] = func
end

function CallOtherEx(id, func, param)
    RegsiterNetExtCall(id, func)
    if param ~= nil then
        UIRequest_(table.merge(param, { type = id }))
    else
        UIRequest_({ type = id })
    end
end

function NullCallBackEx()
    return nil
end

function ProcessFromGameServer()
    local gameserver = {
        host = gamedata.serverlist[tonumber(gamedata.selectserver)].ip,
        port = gamedata.serverlist[tonumber(gamedata.selectserver)].port, 10
    }
    cclog("gameserver.host=%s gameserver.port=%s", gameserver.host, gameserver.port)

    local bFirst = true
    while 1 do
--        fd = ConnectToServer(gameserver)
--        if fd ~= nil then
--            --重新发送
--            if bFirst then
--                bFirst = false
--            else
--                UIReqeustClear()
--                UIRequest_({ type = 1000 })
--            end
--            local loopret = GameLoop(fd, game_ui_callback, game_net_callback, game_net_ext_callback)
--            if loopret == 999 then
--                UIReqeustClear()
--                break
--            elseif loopret == 998 then
--                UIReqeustClear()
--            end
--        else
--            socket.sleep(0.1)
--        end
        local loopret = GameLoop2(gameserver, game_ui_callback, game_net_callback, game_net_ext_callback)
        UIReqeustClear()
        if loopret == 999 then
            break
        elseif loopret == 777777 then
            fd.sock:close()
            return 777777
        end
        socket.sleep(5)
    end
end

local t1 = socket.gettime()
cclog("load gameserver %f ms",t1-t0)