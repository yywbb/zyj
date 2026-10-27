
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-8-20
-- Time: 下午4:19
-- To change this template use File | Settings | File Templates.
--

local gamedata = {
    serverlist = {},
    role = {},
    config = {},
    configVersion = nil,

    device = require"device",


    isshowlog = false,
    isdebug = false,
    -- istencentPlat = false,
    -- isleshiPlat = false,
    -- isaddLoginBtnPlat = false,

    timeDis = 0,
    timeDis2= 0,
    oncehintData = {},
    _config = {},
}

local metatable = {}
metatable.__index = function (table,key)
    return gamedata:getConfig(key)
end

metatable.__newindex = function (table,key,value)
    print("key__newindex",key)
    gamedata._config[key] = value
end

setmetatable(gamedata.config, metatable)


function gamedata.getConfig(self, fileName)
    if gamedata._config[fileName] == nil then
        if gamedata.section then
            local filePath = "config/" .. gamedata.section .. "/" .. fileName .. ".json"
            local path = CCFileUtils:sharedFileUtils():fullPathForFilename(filePath)

            if path ~= filePath then
                gamedata._config[fileName] = LoadJsonFileToTable(filePath)
            end

            return gamedata._config[fileName]
        else
            return gamedata._config[fileName]
        end
    else
        return gamedata._config[fileName]
    end
end

function gamedata.config.getConfigByName(self, fileName)
    if gamedata._config[fileName] == nil then
        if gamedata.section then
            local filePath = "config/" .. gamedata.section .. "/" .. fileName .. ".json"

            -- if LoadJsonFileToTableforNet then
            --     gamedata.config[fileName] = LoadJsonFileToTableforNet(filePath)
            -- else
                gamedata._config[fileName] = LoadJsonFileToTable(filePath)
            -- end

            return gamedata._config[fileName]
        else
            return gamedata._config[fileName]
        end
    else
        return gamedata._config[fileName]
    end
end

--当月天数
function gamedata.currentMonthDays(self)

    local nowtime = os.date("*t", gamedata:time())
    local year = nowtime.year
    local mon = nowtime.month

    if mon == 2 then
        if(year%4==0 and year%100~=0) or (year%100==0 and year%400==0) then
            return 29
        else
            return 28
        end
    elseif mon == 1 or mon == 3 or mon == 5 or mon == 7 or mon == 8 or mon == 10 or mon == 12 then
        return 31
    elseif mon == 4 or mon == 6 or mon == 9 or mon == 11 then
        return 30
    end
end

--星期几
function gamedata.getWeekNum(strDate)
    local weekNum = os.date("*t",gamedata:time()).wday  -1
    if weekNum == 0 then
        weekNum = 7
    end
    return weekNum
end

function gamedata.time(self)
    return os.time()+self.timeDis
end

function gamedata.cachereset(self)

    self.cache.hint = {}

    self.cache.vipstatus = {}

    self.cache.copy = {}
    self.cache.bravecopy = {}
    self.cache.generalrecruitshop = {}

    self.cache.friendcopy = {}
    self.cache.friendcopyrank = {}

    self.cache.athletics = {
        ranklist = {},
        rewardlist = {},
        my = {},
        rewards = {},
        rankRewardStatus = {},
    }

    self.cache.tree = {}
    self.cache.zhounian2 = {}
    self.cache.activitychaozhi = {}

    self.cache.activitystatus = {}
    self.cache.dailyCpActivityTimeStatus = {}

    self.cache.monthcard = {}
    self.cache.activitySecretShop = {}
    self.cache.activityBlackShop = {}
    self.cache.activityRobShop = {}
    self.cache.chicken = {}
    -- self.cache.mammon = {}
    self.cache.signin = {}
    self.cache.signin2 = {}
    self.cache.cave = {}
    self.cache.startgift = {}
    self.cache.activityWatchStar = {}
    self.cache.activityMonthGrowQuery = {}
    self.cache.activityMonthGrowGetReward = {}
    -- self.cache.activityShare = {}
    self.cache.activityMonthGrowMagicQuery = {}

    self.cache.friends = {
        max = 0,
        friends = {},
    }

    self.cache.shield = {
        max = 0,
        index_now = 0,
        friends = {},
    }

    self.cache.shop = {
        props = {},
        giftbags = {},
        autoOff = 0,
    }

    self.cache.cup = {
        status = {},
        topbattles = {}
    }

    self.cache.gang_shopgoods = {}
    self.cache.gang2xianchi = {}
    self.cache.gang2pray = nil

    self.cache.liveness = {}
    self.cache.island = {}
    self.cache.mieshendian = {}
    self.cache.mieshendianshop = {}

    self.cache.stasrtactivityDay = nil

    self.cache.someids = {
        chat_freenum = 0,
    }

    self.cache.penglai3 = {}

    self.cache.singleBoss = {}

    self.cache.starcopy = {
        attacknum = 0,
        sections = {},
    }

    self.cache.hadescopy = {
        attacknum = 0,
        sections = {},
    }

    self.cache.slotsEnemy = {}
    self.cache.commonSlotsWithHp = {}
    self.cache.mazeShop = {}

    self.cache.maze = {}
    self.cache.mazeShop = {}
    self.cache.luxurySignInStatus = {}

    self.cache.cornucopia = {}

    self.cache.passkill = {}
    self.cache.passkillshop = {}

    self.cache.duanwunlunpan = {}

    self.cache.wudaohui = {}

    self.cache.kingBattle = {}

    self.cache.goddownshop = {}
    self.cache.goddownrank = {}

    self.cache.k_goddownshop = {}
    self.cache.k_goddownrank = {}

    self.cache.October1stDay = nil
    self.cache.playerreturn = {}
    --self.cache.peentoGift = {}

    self.cache.SevenDayActivityDay = nil

    self.cache.ZhongQiuActivityDay = nil

    self.cache.CPDiZaoShenHuaActivityDay = nil

    self.cache.CPTianXiaWuShuangActivityDay = nil
    
    self.cache.HeadIconData = {title = {},iconBox = {}}


    self.cache.HonorWarChampion = nil
    self.cache.HonorWarGroupInfo = nil
    self.cache.WeekLiveness = nil

    --商会商品购买保护期数据
    self.cache.GoodsProtectData = {}

    --通天塔数据
    self.cache.BabelTower = {
        mapData = {},
        levelData = {},
    }
    self.cache.BabelTowerShop = {}

    self.cache.activityShop = {}

    self.cache.xuanyueTreasures = {}
    self.cache.xuanyueTreasures2 = {}
    self.cache.xuanyueTreasures3 = {}

    self.cache.AncientRuinsData = {}

    self.cache.adStatus = {}

    self.cache.illusion = {}

    self.cache.exclusiveArtifactChallengeTimes = {}
end

function gamedata.init(self)
    self.ext = {}


    --请求参数扩展队列
    require"myque"
    self.extQueue = myque.new()


    self.cache = {
        -- guid = "",
        -- guidname = "",

        guide = {},

        hint = {},

        role = {},
        vip = {},
        vipstatus = {},
        monthcard = {},
        monthcardreward = {},
        growplan = {},
        growplanx1 = {},
        rechargedouble = {},
        invent = {},

        activityShop = {},
        activityExchange = {},
        activityBlackShop = {},
        activitySecretShop = {},
        activityRobShop = {},

        tree = {},
        zhounian2 = {},
        activitychaozhi = {},

        generals = {},
        equips = {},
        souls = {},
        slots = {},
        godCompetionData = {},
        godCompetionPower = {},
        cheers = {},
        countdownGift = {},
        gems = {},
        slotgems = {},
        generalfragments = {},
        equipfragments = {},

        generalslove = {},
        generalslovetask = {},

        soulhunt = {},

        copy = {},
        bravecopy = {},
        friendcopy = {},
        friendcopyrank = {},

        props = {},

        generalrecruit = {},
        generalrecruitshop = {},

        growplanGlobal = {},
        growplanGlobalx1 = {},
        
        athletics = {
            ranklist = {},
            rewardlist = {},
            my = {},
            rewards = {},
            rankRewardStatus = {},
        },

        activitystatus = {},
        dailyCpActivityTimeStatus = {},

        bloodbattle = {},
        bloodrank = {},

        zhuxiantai = {},
        zhuxianrank = {},

        chicken = {},
        mammon = {},

        mammon2= {},
        signin = {},
        signin2 = {},
        luxurySignInStatus = {},
        cave = {},

        friends = {
            max = 0,
            friends = {},
        },

        shield = {
            max = 0,
            index_now = 0,
            friends = {},
        },

        shop = {
            props = {},
            giftbags = {},
        },

        encounters = {},

        technology = {},

        happinessplace = {},

        cup = {
            status = {},
            topbattles = {}
        },

        gangstatus = {},
        gangmembers = {},
        gangs_level= {},
        gangs_point= {},
        gang_shopgoods = {},


        gang2status = {},
        gangs2 = {},
        gang2members = {},
        gang2post = {},
        gang2Legion = {},
        gang2CDstatus = {},
        gang2xianchi = {},
        gang2skill = {},

        guildwarmain = {},
        guildwarpointquery = {},--据点信息信息查询
        guildwarjionconfirm = {},
        guildchecklist = {},

        devilfotressftatus = {},

        mails = {},
        mailplayers = {},

        task = {},

        penglai ={},
        island = {},

        liveness = {},

        worldboss = {},
        worldbossrank = {},
        worldboss2 = {},
        worldbossrank2 = {},

        someids = {
            chat_freenum = 0,
        },

        generalcollect = {},
        equipcollect = {},

        devil = {},

        protagonist = {},

        startgift = {},
        continue7 = {},
        continueX1 = {},

        activityWatchStar = {},
        activityMonthGrowQuery = {},
        activityMonthGrowGetReward = {},
        activityMonthGrowMagicQuery = {},
        activityShare = {},
        activityTreasure = {},
        activityTreasureX1 = {},
        activityTreasureX2 = {},
        activityTreasureX3 = {},
        activityTreasureCp = {},
        activityTreasureCpX1 = {},
        activityTreasureCpX2 = {},
        activityTreasureCpX3 = {},
        activityTreasureCpX4 = {},
        activityTreasureCpX5 = {},

        protagonistPreveiw = {},

        mieshendian = {},
        mieshendianshop = {},

        petsdata = {},
        petsfragment = {},
        petpassiveskill = {},
        petBagCompound = {},

        favoritegeneral = {},

        penglai3 ={},

        GuildWarInspire = {},
        GuildWarPrepare = {},
        GuildWarMembers = {},

        GuildStandingsSHow = {},
        GuildStandingsRoleShow = {},

        singleBoss = {},

        commonSlots = {},

        copyActivity = {},
        starcopy = {
            attacknum = 0,
            sections = {},
        },

        hadescopy = {
            attacknum = 0,
            sections = {},
        },

        slotsEnemy = {},
        commonSlotsWithHp = {},

        maze = {},
        mazeShop = {},
        magicdata = {
            lock = {},
            unlock = {}
        },
        magicPreview = {},
        mazeReward = {},

        cornucopia = {},
        teamRecomQuery = {},

        passkill = {},
        passkillshop = {},

        duanwunlunpan = {},

        turntable = {},

        k_turntable = {},

        carnival = {},

        integralturntable = {},

        champion = {
            status = {},
            points = {},
        },

        championShop = {},

        activityOldDriver = {
            buystatus = 0,
            itemsdata = {},
        },

        wudaohui = {},
        kingBattle = {},

        goddownshop = {},
        goddownrank = {},

        k_goddownshop = {},
        k_goddownrank = {},
        
        slotSpirit = {
            use = 0,
            add = 0,
            power = 0,
            level = {},
            activation = {},
        },

        goddownstatus = {},

        k_goddownstatus = {},

        guildWarProfit = {
            id = 0,
            effect = 0,
        },


        safemaskshop = {},

        safemask = {},
        safemaskmaster = {},

        wing = {},
        wingcolor = {},

        worldwarprepare = {},
        worldwarstatus = {},
        worldwarrolebattles = {},
        worldwarplayers = {},
        worldwartop = {},

        playerreturn = {},

        redfragment = {},

        timegift = {},

        triggergift = {},

        auction = {},

        cangjingge = {},
        manorfriends = {},

        gangboss = {},
        artifacts = {},
        jewels = {},

        HeadIconData = {title = {},iconBox = {}},
        
        GoodsProtectData = {},

        hint_notupdate = {},

        BabelTower = {
            mapData = {},
            levelData = {},
        },
        BabelTowerShop = {},
        xuanyueTreasures = {},
        xuanyueTreasures2 = {},
        xuanyueTreasures3 = {},
        AncientRuinsData = {},
        RecruitTempData = {},
        
        hefuShopData = {},

        firstRecharge = {},

        adStatus = {},
        illusion = {},

        exclusiveArtifact = {},
        exclusiveArtifactQiLing = {},
        exclusiveArtifactChallengeTimes = {},

        godCompetitionData = {},

        sendaiGenerals = {}, --升仙台武将镜像
        d_sendaiGenerals = {}, --升仙台怪物数据
    }
end

function gamedata.calculateEndTimeForHeadIcon(self,_type,id,getTime)
    local endtime = 0
    local config = nil
    print("id = ",id)
    if _type == "IconBox" then
        config = gamedata.config.headframe[tostring(id)]
    elseif _type == "Title" then
        config = gamedata.config.title[tostring(id)]
    end

    if config == nil then
      return endtime
    end

    if config.time_type == 1 then
        local t = string.split(config.open_time,",")
        -- 条件1 day 表示每月的几号 
        -- 条件2 week 表示每周几 
        -- 如果day >0 用条件1判断 反之用条件2判断

        local day = tonumber(t[1])  
        local week = tonumber(t[2])

        local nowtime = os.date("*t", gamedata:time())
        local nowWeek = gamedata:getWeekNum()

        if day > 0 then
            day = math.min(gamedata:currentMonthDays(),day)
            if day > nowtime.day then
                endtime = 60*60*24*(day - nowtime.day - 1) + (60*60*24 - nowtime.hour*60*60 - nowtime.min*60 - nowtime.sec)
            elseif day == nowtime.day then
                endtime = 0 --不存在的
            else
                endtime = 60*60*24*(gamedata:currentMonthDays() - nowtime.day - 1 + day) + (60*60*24 - nowtime.hour*60*60 - nowtime.min*60 - nowtime.sec)
            end

        elseif week > 0 then
            if week > nowWeek then
                endtime = 60*60*24*(week - nowWeek - 1) + (60*60*24 - nowtime.hour*60*60 - nowtime.min*60 - nowtime.sec)
            elseif week == nowWeek then
                endtime = 0 --不存在的
            else
                endtime = 60*60*24*(7 - nowWeek - 1 + week) + (60*60*24 - nowtime.hour*60*60 - nowtime.min*60 - nowtime.sec)
            end

        end
    elseif config.time_type == 2 then

        local gettime = os.date("*t", getTime)
        local nowtime = gamedata:time()

        endtime = 60*60*24*(tonumber(config.open_time) - 1) + (60*60*24 - gettime.hour*60*60 - gettime.min*60 -gettime.sec) - (nowtime - getTime)
    elseif config.time_type == 3 then
        endtime = -1
    end
    return endtime
end

function gamedata.HeadIconData(self,data,_type)
    print("HeadIconData",_type)
    -- for i,v in ipairs(data) do
    --     print(i,v)
    -- end

    if _type == "IconBox" then

        if not self.cache.HeadIconData.iconBox then
            self.cache.HeadIconData.iconBox = {}
        end

        for i=1,#data/2 do

            local id = data[i*2-1]
            local endtime = data[i*2]

            self.cache.HeadIconData.iconBox[id] = gamedata:calculateEndTimeForHeadIcon(_type,id,endtime)
        end
    elseif _type == "Title" then
        if not self.cache.HeadIconData.title then
            self.cache.HeadIconData.title = {}
        end

        for i=1,#data/2 do

            local id = data[i*2-1]
            local endtime = data[i*2]
            
            self.cache.HeadIconData.title[data[i*2-1]] = gamedata:calculateEndTimeForHeadIcon(_type,id,endtime)
        end
    end
end

function gamedata.GangBoss(self,data)
    self.cache.gangboss = {}
    self.cache.gangboss.id = data[1] and data[1].i or 1
    self.cache.gangboss.hp = data[2] and tonumber(data[2].s or 0) or 0
    self.cache.gangboss.revive = data[3] and data[3].i or 0
    self.cache.gangboss.inspire = data[4] and data[4].i or 0
    self.cache.gangboss.plus = data[5] and data[5].i or 0
    self.cache.gangboss.challenge = data[6] and data[6].i or 0
end


function gamedata.CangjinggeData(self,data)
    local cangjingge = {}
    cangjingge.name = data[1] and data[1].s or ""
    cangjingge.content = data[2] and data[2].s or ""
    cangjingge.material1 = data[3] and data[3].i or 0
    cangjingge.material2 = data[4] and data[4].i or 0
    cangjingge.monster1 = data[5] and data[5].i or 0
    cangjingge.monster2 = data[6] and data[6].i or 0
    cangjingge.time = data[7] and data[7].i or 0
    cangjingge.materialtime = data[8] and data[8].i or 0
    cangjingge.building = {}
    for i = 1,5 do
        cangjingge.building[tostring(i)] = {}
        cangjingge.building[tostring(i)].level = data[3*i+6] and data[3*i+6].i or 0
        cangjingge.building[tostring(i)].quality = data[3*i+7] and data[3*i+7].i or 0
        cangjingge.building[tostring(i)].status = data[3*i+8] and data[3*i+8].i or 0
    end
    return cangjingge
end

function gamedata.getPropNum(self,id)
    if self.cache.props[id] and self.cache.props[id].num > 0 then
        return self.cache.props[id].num
    else
        return 0
    end
end

function gamedata.CangjinggeFriendsData(self,data)
    local manorfriends = {}
    manorfriends.count = data[1] and data[1].i or 0
    manorfriends.friends = {}
    for i = 2,#data,4 do
        if data[i] and data[i].i then
            manorfriends.friends[tostring(data[i].i)] = {}
            manorfriends.friends[tostring(data[i].i)].rid = data[i] and data[i].i or 0
            manorfriends.friends[tostring(data[i].i)].profile = data[i+1] and data[i+1].i or 0
            manorfriends.friends[tostring(data[i].i)].name = data[i+1] and data[i+1].s or ""
            manorfriends.friends[tostring(data[i].i)].monster1 = data[i+2] and data[i+2].i or 0
            manorfriends.friends[tostring(data[i].i)].monster2 = data[i+3] and data[i+3].i or 0
        end
    end
    return manorfriends
end

function gamedata.AuctionData(self,data)
    self.cache.auction = {}
    self.cache.auction.items = {}
    self.cache.auction.cpnum = data[1] or 1
    self.cache.auction.time = data[2] or 0
    for i = 3,#data,4 do
        self.cache.auction.items[tostring(data[i])] = {}
        self.cache.auction.items[tostring(data[i])].id = data[i] or 0
        self.cache.auction.items[tostring(data[i])].status = data[i+1] or 0
        self.cache.auction.items[tostring(data[i])].num = data[i+2] or 0
        self.cache.auction.items[tostring(data[i])].my = data[i+3] or 0
    end
end

function gamedata.TriggerGift(self,data)
    self.cache.triggergift = {}
    for i = 1,#data,3 do
        self.cache.triggergift[tostring(data[i])] = {}
        self.cache.triggergift[tostring(data[i])].iid = data[i] or 0
        self.cache.triggergift[tostring(data[i])].cid = data[i+1] or 0
        self.cache.triggergift[tostring(data[i])].time = data[i+2] or 0
    end
end

function gamedata.SetTriggerGift(self,data)
    if data[1] and data[1] > 0 then
        if not self.cache.triggergift[tostring(data[1])] then
            self.cache.triggergift[tostring(data[1])] = {}
        end
        --
        self.cache.triggergift[tostring(data[1])].iid = data[1] or 0
        self.cache.triggergift[tostring(data[1])].cid = data[2] or 0
        self.cache.triggergift[tostring(data[1])].time = data[3] or 0
        --
        return table.copy(self.cache.triggergift[tostring(data[1])])
    end

    return {}
end

function gamedata.SetRedFragment(self,data)
    self.cache.redfragment = {}
    for i = 1,#data,2 do
        self.cache.redfragment[data[i]] = {}
        self.cache.redfragment[data[i]].cid = data[i] or 0
        self.cache.redfragment[data[i]].num = data[i+1] or 0
    end
end

function gamedata.UpdateRedFragment(self,data)
    if self.cache.redfragment[data.cid] then
        self.cache.redfragment[data.cid].num = self.cache.redfragment[data.cid].num + data.num
    else
        self.cache.redfragment[data.cid] = {}
        self.cache.redfragment[data.cid].cid = data.cid or 0
        self.cache.redfragment[data.cid].num = data.num or 0
    end
end

function gamedata.WorldWarCurrentChampion(self,data)
    local info = {}
    info.champion = {}
    info.worship = data[1] and data[1].i or 0
    info.number = data[2] and data[2].i or 0
    if #data > 2 then
        for i = 1,((#data-2)/10) do
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)] = {}
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].group = data[10*(i-1)+3] and data[10*(i-1)+3].i or 0
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].name = data[10*(i-1)+4] and data[10*(i-1)+4].s or ""
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].level = data[10*(i-1)+5] and data[10*(i-1)+5].i or 0
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].profile = data[10*(i-1)+6] and data[10*(i-1)+6].i or 0
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].server_id = data[10*(i-1)+7] and data[10*(i-1)+7].i or 0
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].server_name = data[10*(i-1)+8] and data[10*(i-1)+8].s or ""
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].champion_num = data[10*(i-1)+9] and data[10*(i-1)+9].i or 0
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].worship_num = data[10*(i-1)+10] and data[10*(i-1)+10].i or 0
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].wing_l = data[10*(i-1)+11] and data[10*(i-1)+11].i or 0
            info.champion[tostring(data[10*(i-1)+3] and data[10*(i-1)+3].i or 0)].wing_c = data[10*(i-1)+12] and data[10*(i-1)+12].i or 0
        end
    end
    return info
end

function gamedata.WorldWarTop(self,data,id)
    if tostring(id) == "0" then
        self.cache.worldwartop.betplayers = {}
        for k,v in ipairs(data) do
            table.insert(self.cache.worldwartop.betplayers,v)
        end
    else
        self.cache.worldwartop[tostring(id)] = {}
        for i = 1, (#data)/5 do
            self.cache.worldwartop[tostring(id)][tostring(i)] = {}
            self.cache.worldwartop[tostring(id)][tostring(i)].id = data[5*(i-1)+1] or 0
            self.cache.worldwartop[tostring(id)][tostring(i)].bet = data[5*(i-1)+2] or 0
            self.cache.worldwartop[tostring(id)][tostring(i)].p_id1 = data[5*(i-1)+3] or 0
            self.cache.worldwartop[tostring(id)][tostring(i)].p_id2 = data[5*(i-1)+4] or 0
            self.cache.worldwartop[tostring(id)][tostring(i)].result = data[5*(i-1)+5] or 0
        end
    end
end

function gamedata.WorldWarTopShenbang(self,data,id)
    if tostring(id) == "0" then
        self.cache.worldwartopShenbang.betplayers = {}
        for k,v in ipairs(data) do
            table.insert(self.cache.worldwartopShenbang.betplayers,v)
        end
    else
        self.cache.worldwartopShenbang[tostring(id)] = {}
        for i = 1, (#data)/5 do
            self.cache.worldwartopShenbang[tostring(id)][tostring(i)] = {}
            self.cache.worldwartopShenbang[tostring(id)][tostring(i)].id = data[5*(i-1)+1] or 0
            self.cache.worldwartopShenbang[tostring(id)][tostring(i)].bet = data[5*(i-1)+2] or 0
            self.cache.worldwartopShenbang[tostring(id)][tostring(i)].p_id1 = data[5*(i-1)+3] or 0
            self.cache.worldwartopShenbang[tostring(id)][tostring(i)].p_id2 = data[5*(i-1)+4] or 0
            self.cache.worldwartopShenbang[tostring(id)][tostring(i)].result = data[5*(i-1)+5] or 0
        end
    end
end

function gamedata.WorldWarPlayers(data)
    if data then
        local point = {}
        point.id = data[1] and data[1].i or 0
        point.rid = data[2] and data[2].i or 0
        point.name = data[3] and data[3].s or ""
        point.level = data[4] and data[4].i or 0
        point.profile = data[5] and data[5].i or 0
        point.server_id = data[6] and data[6].i or 0
        point.server_name = data[7] and data[7].s or ""
        point.isself = data[8] and data[8].i or 0

        return point
    end
end

function gamedata.WorldWarRoleBattles(data)
    if data  then
        local point = {}
        point.id = data[1] and data[1].i or 0
        point.phase = data[2] and data[2].i or 0
        point.round = data[3] and data[3].i or 0
        point.result = data[4] and data[4].i or 0
        point.star = data[5] and data[5].i or 0
        point.reward = data[6] and data[6].i or 0
        point.point = data[7] and data[7].i or 0
        point.win_count = data[8] and data[8].i or 0
        point.lose_count = data[9] and data[9].i or 0
        point.rid = data[10] and data[10].i or 0
        point.name = data[11] and data[11].s or ""
        point.level = data[12] and data[12].i or 0
        point.profile = data[13] and data[13].i or 0
        point.server_id = data[14] and data[14].i or 0
        point.server_name = data[15] and data[15].s or ""

        point.title = data[16] and data[16].i or 0
        point.iconBox = data[17] and data[17].i or 0
        return point
    end
end

function gamedata.WorldWarPrepare(self,data)
    self.cache.worldwarprepare = {}
    self.cache.worldwarprepare.propnum = data[1] or 0
    self.cache.worldwarprepare.propnumall = data[2] or 0
    self.cache.worldwarprepare.attr_atk = data[3] or 0
    self.cache.worldwarprepare.attr_def = data[4] or 0
    self.cache.worldwarprepare.attr_hp = data[5] or 0
    self.cache.worldwarprepare.attr_all = data[6] or 0
end

function gamedata.WorldWarStatus(self,data)
    self.cache.worldwarstatus = {}
    self.cache.worldwarstatus.number = data[1] or 0
    self.cache.worldwarstatus.list = data[2] or 0
    self.cache.worldwarstatus.status = data[3] or 0
    self.cache.worldwarstatus.competition = data[4] or 0
    self.cache.worldwarstatus.server_id = data[5] or 0
    --神榜冠军赛开启
    self.cache.worldwarstatus.s_open = data[6] or 0
    --神榜赛区数量
    self.cache.worldwarstatus.divisionNum = data[7] or 0
    --当前所在赛区
    self.cache.worldwarstatus.curDivision = data[8] or 0
    --是否晋级冠军赛
    self.cache.worldwarstatus.promotion = data[9] or 0
end

function gamedata.SafeMask(self,data)
    if data then
        self.cache.safemask = {}
        for i = 1,7 do
            self.cache.safemask[tostring(i)] = {sid = i, level = data[i] or 0, level2 = data[i+7] or 0,level3 = data[i+14] or 0}
        end
    end
end

function gamedata.SafeMaskMaster(self,data)
    if data then
        self.cache.safemaskmaster = {}
        for i = 1,7 do
            self.cache.safemaskmaster[tostring(i)] = {mastertype = i, masterid = data[i] or 0}
        end
    end
end

function gamedata.GoddownStatus(self,data)
    if data then
        self.cache.goddownstatus.point = data[1] or 0
        self.cache.goddownstatus.allpoint = data[2] or 0
        self.cache.goddownstatus.selected = data[3] or 0
        self.cache.goddownstatus.status = data[4] or 0
        self.cache.goddownstatus.cdtime = data[5] or 0
        self.cache.goddownstatus.boxstatus = {}
        for i = 6,#data do
            self.cache.goddownstatus.boxstatus[tostring(i-5)] = data[i] or 0
        end
    end
end

function gamedata.k_GoddownStatus(self,data)
    if data then
        self.cache.k_goddownstatus.point = data[1] or 0
        self.cache.k_goddownstatus.allpoint = data[2] or 0
        self.cache.k_goddownstatus.selected = data[3] or 0
        self.cache.k_goddownstatus.status = data[4] or 0
        self.cache.k_goddownstatus.cdtime = data[5] or 0
        self.cache.k_goddownstatus.boxstatus = {}
        for i = 6,#data do
            self.cache.k_goddownstatus.boxstatus[tostring(i-5)] = data[i] or 0
        end
    end
end

function gamedata.SlotSpiritData(self,data)
    if data then
        self.cache.slotSpirit.use = data[1] or 0
        self.cache.slotSpirit.add = data[2] or 0
        self.cache.slotSpirit.power = data[3] or 0
    end
end

function gamedata.SlotSpiritLevel(self,data)
    if data then
        self.cache.slotSpirit.level = {}
        for k,v in ipairs(data) do
            table.insert(self.cache.slotSpirit.level,v)
        end
    end
end

function gamedata.SlotSpiritActivation(self,data)
    if data then
        self.cache.slotSpirit.activation = {}
        for k,v in ipairs(data) do
            table.insert(self.cache.slotSpirit.activation,v)
        end
    end
end

function gamedata.ActivityOldDriver(self,data)

    self.cache.activityOldDriver.itemsdata = {}
    self.cache.activityOldDriver.buystatus = data.ids[1] or 0
    for i=2,11,1 do
        local order = data.ids[i] or 0
        if order == 1 then order = -1 end
        table.insert(self.cache.activityOldDriver.itemsdata,{id = i-1, status = data.ids[i] or 0, num = data.ids[i+10] or 0, order = order})
    end
    self.sortData(self.cache.activityOldDriver.itemsdata, "order","id",nil,nil,nil,nil,true,true)
end

function gamedata.ChampionShop(self,data)

    local nowtime = os.date("*t", gamedata:time())
    self.cache.championShop.freshtime = nowtime
    self.cache.championShop.itemsdata = {}
    self.cache.championShop.championpoint = data.ids[1] or 0
    self.cache.championShop.resetnum = data.ids[2] or 0
    for i=3,13,2 do
        table.insert(self.cache.championShop.itemsdata,{id = data.ids[i] or 0, num = data.ids[i+1] or 0})
    end
end

function gamedata.ChampionStatus(self,data)
    if data then
        self.cache.champion.status.pass = data[1] or 1
        self.cache.champion.status.dekaron = data[2] or 0
        self.cache.champion.status.reset = data[3] or 0
        self.cache.champion.status.boxstatus = data[4] or 0
        self.cache.champion.status.boxopen = data[5] or 0
    end
end

function gamedata.ChampionPoint(self,data,id)
    if data and id and id+0 > 0 then
        local point = {}
        point.status = data[1] and data[1].i or 0
        point.hp = data[2] and data[2].i or 0
        point.profile = data[3] and data[3].i or 10101
        point.power = data[4] and data[4].i or 0
        point.name = data[5] and data[5].s or ""
        point.w_l = data[6] and data[6].i or 0
        point.w_c = data[7] and data[7].i or 0

        self.cache.champion.points[tostring(id)] = point
    end
end

function gamedata.ChampionBox(self,data)
    if data then
        self.cache.champion.status.boxstatus = data[1] or 0
        self.cache.champion.status.boxopen = data[2] or 0
    end
end


function gamedata.PetsData(self,data)
    self.cache.petsdata["iid"] = data[1] or 0
    self.cache.petsdata["pets"] = {}
    -- for k,v in ipairs(data) do
    --     print("PetsData==",k,v)
    -- end
    local petsnum = (#(data)-1)/4
    print("petsnum==",petsnum,#(data))
    for i = 1,petsnum do
        local pet = {}
        pet.iid = data[(i-1)*4+2] or 0
        pet.cid = data[(i-1)*4+3] or 0
        pet.level = data[(i-1)*4+4] or 0
        pet.collectlevel = data[(i-1)*4+5] or 0
        self.cache.petsdata["pets"][pet.iid] = pet
        -- table.insert(self.cache.petsdata["pets"],pet)
    end
    -- local sortById = function(a,b) return a.cid < b.cid end
    -- table.sort(self.cache.petsdata["pets"], sortById)
end

function gamedata.updatePetsFragment(self,v)
    print("updatePetsFragment===")
    if not self.cache.petsfragment[v.cid] then
        self.cache.petsfragment[v.cid] = {}
        self.cache.petsfragment[v.cid].cid = v.cid
        self.cache.petsfragment[v.cid].num = v.num
    else
        self.cache.petsfragment[v.cid].num = self.cache.petsfragment[v.cid].num + v.num
    end
end

function gamedata.PetsFragments(self,data)
    
    print("PetsFragments===")
    for k,v in ipairs(data.idnums) do
        self.cache.petsfragment[v.id] = { cid = v.id , num = v.num }
    end
end

function gamedata.PetPassiveSkillData(self,data)
    self.cache.petpassiveskill["nowskillpoint"] = data[1] or 0  --普通技能点
    self.cache.petpassiveskill["nowskillpoint2"] = data[2] or 0 --红色技能点
    self.cache.petpassiveskill["nowskillpoint3"] = data[3] or 0 --金色技能点
    self.cache.petpassiveskill["skill"] = {}
    -- for k,v in ipairs(data) do
    --     print("petpassiveskill",k,v)
    -- end

    local skillnum = 5
    -- print("tablelength===",table.getTableLength(data))
    -- print("skillnum===",skillnum)
    for i = 1,skillnum do
        -- print("skill.i==",i)
        local skill = {}
        skill.cid = data[(i-1)*4+4] or 0
        skill.status = data[(i-1)*4+5] or 0
        skill.level = data[(i-1)*4+6] or 0
        skill.lock = data[(i-1)*4+7] or 0

        -- self.cache.petpassiveskill["skill"][skill.cid] = skill
        table.insert(self.cache.petpassiveskill["skill"],skill)
    end
end


function gamedata.setPetData(self,data)

        local pet = {}
        pet.iid = data[1] or 0
        pet.cid = data[2] or 0
        pet.exp = data[3] or 0
        pet.level1 = data[4] or 0
        pet.level2 = data[5] or 0
        local has = false
        for k,v in pairs(self.cache.petsdata["pets"]) do
            if v.cid == pet.cid then
                v.iid = pet.iid
                v.exp = pet.exp
                v.level1 = pet.level1
                v.level2 = pet.level2
                has = true
            end
        end
        if not has then
            table.insert(self.cache.petsdata["pets"],pet)
        end
        local sortById = function(a,b) return a.cid < b.cid end
        table.sort(self.cache.petsdata["pets"], sortById)
end
--魔宠碎片合成
function gamedata.PetBagCompoundData(self,data)
    print("gamedata.PetBagCompoundData")
    -- for k,v in ipairs(data) do
    --     print("PetBagCompoundData",k,v)
    -- end
    self.cache.petBagCompound.data = {}
    self.cache.petBagCompound.data["iid"] = data[1] or 0 
    self.cache.petBagCompound.data["cid"] = data[2] or 0 
    self.cache.petBagCompound.data["level"] = data[3] or 0 
    self.cache.petBagCompound.update = data[4] or 0
    self.cache.petBagCompound.data["collectlevel"] = data[5] or 1
end

function gamedata.setPetSet(self,data)

    for k,v in pairs(self.cache.petsdata["pets"]) do
        if v.cid == data then
            self.cache.petsdata.iid = v.iid
        end
    end

end

function gamedata.DevilStatus(self,data)

    self.cache.devil["exp"] = data[1] or 0
    self.cache.devil["devil_lv"] = data[2] or 0
    self.cache.devil["atk_lv"] = data[3] or 0
    self.cache.devil["def_lv"] = data[4] or 0
    self.cache.devil["hp_lv"] = data[5] or 0
    self.cache.devil["dnum"] = data[6] or 0
    self.cache.devil["atk"] = data[7] or 0
    self.cache.devil["def"] = data[8] or 0
    self.cache.devil["hp"] = data[9] or 0
    self.cache.devil["speed"] = data[10] or 0
    self.cache.devil["critical"] = data[11] or 0
    self.cache.devil["dodge"] = data[12] or 0
    self.cache.devil["parry"] = data[13] or 0
end

function gamedata.UpdateDevilNum(self,data)

    if self.cache.devil.dnum then
        self.cache.devil.dnum = self.cache.devil.dnum + (data[1] or 0)
    else
        self.cache.devil.dnum = data[1] or 0
    end
end

function gamedata.Guide(self,data)

    for k,v in ipairs(data.sections) do
        self.cache.guide[v.section] = {
            section = v.section,
            status = v.status,
            step = v.step,
        }
    end
end

function gamedata.updateChatfreenum(self,num)
    local oldnum = 0
    if self.cache.someids then
        oldnum = self.cache.someids["chat_freenum"] or 0
        self.cache.someids["chat_freenum"] = oldnum + num
    end
end


function gamedata.SomeIds(self,ids)
    if ids.ids and ids.ids[1] then
        self.cache.someids["chat_freenum"] = ids.ids[1] or 0
    end
end

function gamedata.ProtagonistData(self,data)
    return {
        iid = data.iid,
        level1 = data.level1,
        level2 = data.level2,
        atk_a = data.atk_a,
        def_a = data.def_a,
        hp_a = data.hp_a,
        train = data.train,
        w_l = data.train_max,
        w_c = data.nexttime
    }
end

function gamedata.Protagonist(self,data)
    local general = self.cache.protagonist and self.cache.protagonist.general or {}
    local relation = self.cache.protagonist and self.cache.protagonist.relation or {}

    if data and data.iid and data.iid ~=0 then
        self.cache.protagonist = self:ProtagonistData(data)
        for k,v in pairs(self.cache.slots) do
            if v.general and v.general+0 == data.iid+0 then
                relation = v.relation
            end
        end
    end

    if data.general and data.general.iid > 0 then
        self.cache.protagonist.general = self:generalData(data.general,true)
        self.cache.protagonist.general.level6 = general.level6 or 0
        self.cache.protagonist.general.level7 = general.level7 or 0
    else
        self.cache.protagonist.general = general
    end

    self.cache.protagonist.relation = relation

end

function gamedata.RoleData(self,roledata, uuid)
    --
    local part_point = self.cache.role.part_point or 0
    local part_rank = self.cache.role.part_rank or 0

    self.cache.role = {
        id = roledata.id,
        gender =  roledata.gender,
        name = roledata.name,
        vip = roledata.vip,
        level = roledata.level,
        exp = roledata.exp,
        nextexp = roledata.nextexp,
        coin = roledata.coin,
        gold = roledata.gold,
        stamina = roledata.stamina, --体力
        maxstamina = roledata.maxstamina,
        energy = roledata.energy, --精力
        maxenergy = roledata.maxenergy,
        createtime = roledata.createtime,
        servertime = roledata.servertime,
        logintime = roledata.logintime,
        staminanext = roledata.staminanext,
        staminaall = roledata.staminaall,
        energynext = roledata.energynext,
        energyall = roledata.energyall,
        profile = roledata.profile,
        uuid = uuid,
        showid = roledata.id,
        part_point = part_point,
        part_rank = part_rank,
        title = roledata.title,
        iconBox = roledata.avatar,
        g_gold = roledata.g_gold or 0,

        power = roledata.power_all or 0,
        f_power_WithOutTransform = roledata.power or 0,
        g_power_WithOutTransform = roledata.g_power or 0,

        f_power = 0,
        g_power = 0,
    }

    self:updateRolePower(self.cache.role.f_power_WithOutTransform,self.cache.role.g_power_WithOutTransform)

    self.cache.role.createtime = self.cache.role.createtime + gamedata.timeDis2
    self.cache.role.servertime = self.cache.role.servertime + gamedata.timeDis2
    self.cache.role.logintime = self.cache.role.logintime + gamedata.timeDis2

    if self.cache.role.id> 1000000 then
        local serverid = math.floor(self.cache.role.id/1000000)
        self.cache.role.showid = serverid.."_"..(self.cache.role.id-serverid*1000000)
    end

end

function gamedata.Vip(self,data)
    self.cache.vip.vip = data[1]
    self.cache.role.vip = data[1]
    self.cache.vip.rmb = data[2]
    if self.cache.vip.vip < table.getTableLength(self.config.vip)-1 then
        self.cache.vip.nextrmb = self.config.vip[tostring(self.cache.vip.vip+1)].needgold
    else
        self.cache.vip.nextrmb = self.config.vip[tostring(self.cache.vip.vip)].needgold
    end

    self.cache.vip.firststatus = data[3]
end

function gamedata.Vipstatus(self,data)
    self.cache.vipstatus.b_athletics = data[1]
    self.cache.vipstatus.b_physical = data[2]
    self.cache.vipstatus.b_energy = data[3]
    self.cache.vipstatus.b_elitecopy = data[4]
    self.cache.vipstatus.friendcopy_times = data[5]
    self.cache.vipstatus.b_signin = data[6]
    self.cache.vipstatus.bzxtrst = data[7]
    self.cache.vipstatus.athletics_boss = data[20]

    self.cache.vipstatus.coin_copy_times = data[10]
    self.cache.vipstatus.exp_copy_times = data[11]
    self.cache.vipstatus.personalboss_times = data[12]
    self.cache.vipstatus.otherAndNotUsed = data[13] --服务器已经使用 但客户端不知道干什么用
    self.cache.vipstatus.stone_copy_attacktimes = data[14]--锻造石攻打次数
    self.cache.vipstatus.stone_copy_times = data[15]--锻造石购买次数
    self.cache.vipstatus.through_times = data[16]--过关斩将购买次数

    self.cache.vipstatus.upstar_times = data[23] or 0
    self.cache.vipstatus.zhenfu_times = data[24] or 0

    self.cache.vipstatus.vipexchange_free = data[25] or 0
    self.cache.vipstatus.vipexchange_buy = data[26] or 0

    self.cache.vipstatus.home_challenge_times = data[27] or 0
    self.cache.vipstatus.sociaty_boss_order = data[28] or 0
    self.cache.vipstatus.b_hall = data[29] or 0

    self.cache.vipstatus.b_hero_boss = data[30] or 0

    self.cache.vipstatus.forging_copy_times = data[32] or 0

    self.cache.vipstatus.xianku_cishu = data[33] or 0

    self.cache.vipstatus.m_cumulative_recharge = data[35] or 0
    self.cache.vipstatus.device_soul = data[36] or 0
    self.cache.vipstatus.game_2048_times = data[38] or 0
end


function gamedata.MonthCard(self,data)
    self.cache.monthcard = {
        [1] = {
            restday = data[1],
            status = data[2],
        },
        [2] = {
            restday = data[3],
            status = data[4],
        },
    }
end

function gamedata.MonthCardReward(self,data)

    self.cache.monthcardreward = {}
    for k,v in ipairs(data) do
        table.insert(self.cache.monthcardreward,v)
    end
end

function gamedata.GrowPlanx1(self,data)
    self.cache.growplanx1 = {
        status = {},
        stage = 1,
    }

    for k,v in ipairs(data) do
        if k==1 then
            self.cache.growplanx1.stage = v
        else
            table.insert(self.cache.growplanx1.status,v)
        end
    end

end

function gamedata.GrowPlanGlobalx1(self,data)
    self.cache.growplanGlobalx1 = {
        totalnum = 0,
        rewards={},
    }
    for k,v in ipairs(data) do
        if k==1 then
            self.cache.growplanGlobalx1.totalnum = v
        else
            table.insert(self.cache.growplanGlobalx1.rewards,v)
        end
    end
end

function gamedata.GrowPlan(self,data)
    self.cache.growplan = {}
    for k,v in ipairs(data) do
        --print(v)
        table.insert(self.cache.growplan,v)
    end
end

function gamedata.GrowPlanGlobal(self,data)
    self.cache.growplanGlobal = {
        totalnum = 0,
        rewards={},
    }
    for k,v in ipairs(data) do
        if k==1 then
            self.cache.growplanGlobal.totalnum = v
        else
            table.insert(self.cache.growplanGlobal.rewards,v)
        end
    end
end

function gamedata.RechargeDouble(self,data)
    self.cache.rechargedouble = {}
    for k,v in ipairs(data) do
        table.insert(self.cache.rechargedouble,v)
    end
end

function gamedata.Invent(self,data)
    self.cache.invent = {
        code = data.code,
        status = {}
    }

    for k,v in ipairs(data.param) do
        if k==1 then
            self.cache.invent.selfstatus = v
        elseif k==2 then
            self.cache.invent.inventnum = v
        else
            table.insert(self.cache.invent.status,v)
        end
    end
end

function gamedata.updateRolePower(self,f_power,g_power,allPower)

    if self.cache.role then
        if f_power and f_power >= 0 then
            self.cache.role.f_power_WithOutTransform = f_power
        end

        if g_power and g_power >= 0 then
            self.cache.role.g_power_WithOutTransform = g_power
        end

        if allPower and allPower >= 0 then
            self.cache.role.power = allPower
        end

        --转换战力
        self.cache.role.f_power = math.floor(self.cache.role.f_power_WithOutTransform + self.cache.role.g_power_WithOutTransform * gamedata.config.global_kv.fairy_turn_every.value)

        self.cache.role.g_power = math.floor(self.cache.role.g_power_WithOutTransform + self.cache.role.f_power_WithOutTransform * gamedata.config.global_kv.every_fairy_turn.value)
    end
end

function gamedata.updateStaff(self,data)
    if not data then
        return
    end
    local config = gamedata.IDconfig(data.cid)
    if config.staffType == "gold" then
        gamedata:updateRoleGold(data.num, data.name, data.amount)
    elseif config.staffType == "g_gold" then
        gamedata:updateRoleG_gold(data.num, data.name, data.amount)
    elseif config.staffType == "coin" then
        gamedata:updateRoleCoin(data.num)
    elseif config.staffType == "props" then
        gamedata:updateprops(data)
    elseif config.staffType == "general_fragment" then
        gamedata:updategeneralfragmentbynum(data)
    elseif config.staffType == "equip_fragment" or config.staffType == "meterial_fragment" or config.staffType == "treasure_fragment" then
        gamedata:updateequipfragment(data)
    elseif config.staffType == "general" then
        local iid = 0
        for k,v in pairs(makeAllGeneralsTemp()) do
            if v.cid == data.cid and (not v.ison or v.ison == 0) then
                iid = v.iid
                break
            end
        end
        if gamedata.cache.generals[iid] then gamedata.cache.generals[iid] = nil end
    elseif config.staffType == "equip" then

    elseif config.staffType == "pet_fragment" then
        gamedata:updatePetsFragment(data)
    elseif config.staffType == "red_fragment" then
        if gamedata.cache.redfragment[data.cid] then
            gamedata.cache.redfragment[data.cid].num = (gamedata.cache.redfragment[data.cid].num or 0) + data.num
        else
            gamedata.cache.redfragment[data.cid] = {}
            gamedata.cache.redfragment[data.cid].num = data.num
        end
    elseif config.staffType == "jewel" then
        gamedata.cache.jewels[data.cid].num = gamedata.cache.jewels[data.cid].num + data.num
        if gamedata.cache.jewels[data.cid].num <= 0 then
            gamedata.cache.jewels[data.cid] = nil
        end
    elseif config.staffType == "token_fragment" then
        gamedata:updateprops(data)
    elseif config.staffType == "token" then
        gamedata:updateprops(data)

    elseif config.staffType == "countdownGift" then
        gamedata:updateCountdownGift(data)
    end
end


function gamedata.updateCountdownGift(self,v)
    if self.cache.countdownGift[v.iid] then
        self.cache.countdownGift[v.iid] = nil
    end
end




function gamedata.updateRoleCoin(self,num)
    if self.cache.role.coin then
        self.cache.role.coin = self.cache.role.coin + num
    end

end

function gamedata.updateRoleGold(self,num,name,amount)
    print("updateRoleGold")
    if self.cache.role.gold then
        print("updateRoleGold",self.cache.role.gold,num)
        self.cache.role.gold = self.cache.role.gold + num
        if num < 0 and name then
            UIResponse({type = 503, msgtype = "umeng", datatype = "buy", name = name, amount = amount, gold = -num })
        end
        print("updateRoleGold",self.cache.role.gold)
    end

end


function gamedata.updateRoleG_gold(self,num,name,amount)
    print("updateRoleG_gold")
    if self.cache.role.g_gold then
        print("updateRoleG_gold",self.cache.role.g_gold,num)
        self.cache.role.g_gold = self.cache.role.g_gold + num
        -- if num < 0 and name then
        --     UIResponse({type = 503, msgtype = "umeng", datatype = "buy", name = name, amount = amount, gold = -num })
        -- end
        print("updateRoleG_gold",self.cache.role.g_gold)
    end
end

function gamedata.updateRoleExp(self,exp)

    local t = {
        rolegetexp = exp.rolegetexp,
        oldexp = self.cache.role.exp,
        newexp =  exp.roleexp,
        oldlevel = self.cache.role.level,
        newlevel = exp.rolelevel
    }

    self.cache.role.exp = exp.roleexp
    self.cache.role.level = exp.rolelevel
    if self.cache.role.level > t.oldlevel then
        UIResponse({type = 503, msgtype = "umeng", datatype = "setUserLevel", level = self.cache.role.level })
    end


    return t
end

function gamedata.updateRoleStamina(self,Stamina)
    if self.cache.role.stamina then
        self.cache.role.stamina = self.cache.role.stamina + Stamina
    end

end

function gamedata.updateRoleEnergy(self,energy)
    if self.cache.role.stamina then
        self.cache.role.energy = self.cache.role.energy + energy
    end

end

function gamedata.shortenergy(self)
    if self.cache.props[20015] and self.cache.props[20015].num > 0 then
        UIResponse({type = 503, msgtype = "useenergy_s", num  = self.cache.props[20015].num})
    elseif self.cache.props[20020] and self.cache.props[20020].num > 0 then
        UIResponse({type = 503, msgtype = "useenergy_b", num  = self.cache.props[20020].num})
    else
        UIResponse({type = 503, msgtype = "shortenergy"})
    end
end

function gamedata.shortstamina(self)
    if self.cache.props[20014] and self.cache.props[20014].num > 0 then
        UIResponse({type = 503, msgtype = "usestamina_s", num  = self.cache.props[20014].num})
    elseif self.cache.props[20019] and self.cache.props[20019].num > 0 then
        UIResponse({type = 503, msgtype = "usestamina_b", num  = self.cache.props[20019].num})
    else
        UIResponse({type = 503, msgtype = "shortphysical"})
    end
end

function gamedata.generalLoveData(self,data)
    self.cache.generalslove.showdata = {
         cid = data[1],
         exp = data[2],
         level = data[3],
         hp = data[4],
         atk = data[5],
         def = data[6],
         speed = data[7],
         critical = data[8],
         dodge = data[9],
         parry = data[10],
         resilience = data[11],
         hit = data[12],
         arp = data[13],
         criticaldmg = data[14],
         aadddmg = data[15],
         asubdmg = data[16],
         radddmg = data[17],
         rsubdmg = data[18],
         generallevel = 1,
     }

     for k,v in pairs(self.cache.generals) do
        if v.cid == self.cache.generalslove.showdata.cid then
            self.cache.generalslove.showdata.generallevel = v.level1
        elseif gamedata.config.general[tostring(v.cid)].init_cid and gamedata.config.general[tostring(v.cid)].init_cid == self.cache.generalslove.showdata.cid then
            self.cache.generalslove.showdata.generallevel = v.level1
        elseif gamedata.config.general[tostring(v.cid)].orange_id and gamedata.config.general[tostring(v.cid)].orange_id == self.cache.generalslove.showdata.cid then 
            self.cache.generalslove.showdata.generallevel = v.level1
        elseif gamedata.config.general[tostring(v.cid)].generalid2 and gamedata.config.general[tostring(v.cid)].generalid2 == self.cache.generalslove.showdata.cid then 
            self.cache.generalslove.showdata.generallevel = v.level1
        elseif gamedata.config.general[tostring(v.cid)].partner_id and gamedata.config.general[tostring(v.cid)].partner_id == self.cache.generalslove.showdata.cid then 
            self.cache.generalslove.showdata.generallevel = v.level1
        end   
     end
     
end

function  gamedata.generalsLove(self,data)
    self.cache.generalslove.alldata = {}
    local nowcid
    if not next(data.ids) then
        return
    end
    for k,v in ipairs(data.ids) do
        if math.mod(k,2) == 1 then
            if not self.cache.generalslove.alldata[v] then
                self.cache.generalslove.alldata[v] = {}
            end
            self.cache.generalslove.alldata[v].cid = v
            nowcid = v
        elseif math.mod(k,2) == 0 then
            self.cache.generalslove.alldata[nowcid].level = v
        end
    end
end

function gamedata.generalLoveUseProps(self,data)
    self.cache.generalslove.useprops = {}
    self.cache.generalslove.useprops.data = {}
    self.cache.generalslove.useprops.baojinum = 0

    print("generalLoveUseProps")
    local nowcid
    -- printT(data)

    for k,v in ipairs(data) do
        print(k,v)
        if tonumber(k) == 1 then
            print("baojinum=====",v)
            self.cache.generalslove.useprops.baojinum = v
        else
            if math.mod(tonumber(k),2) == 1 then
                self.cache.generalslove.useprops.data[nowcid].num = v
            elseif math.mod(tonumber(k),2) == 0 then
                if not self.cache.generalslove.useprops.data[v] then
                    print("createbycid===")
                    printT(self.cache.generalslove.useprops.data)

                    self.cache.generalslove.useprops.data[v] = {}
                end
                printT(self.cache.generalslove.useprops.data)
                print("generalLoveUseProps.cid==",v)
                self.cache.generalslove.useprops.data[v].cid = v
                nowcid = v
            end
        end
    end
end

function gamedata.generalLoveTask(self,data)
    print("generalLoveTask..gamedata")

    local nowcid
    if not next(data) then
        return
    end
    for k,v in ipairs(data) do
        if math.mod(k,2) == 1 then
            if not self.cache.generalslovetask[v] then
                self.cache.generalslovetask[v] = {}
            end
            self.cache.generalslovetask[v].cid = v
            nowcid = v
        elseif math.mod(k,2) == 0 then
            self.cache.generalslovetask[nowcid].status = v
        end
    end
end

function gamedata.generalLoveTaskSet(self,data,cid)
    print("generalLoveTaskSet..gamedata",data[1],cid)
    printT(self.cache.generalslovetask)

    self.cache.generalslovetask[tonumber(cid)].status = 2
end


--返回一个仙凡属性转换后的
function gamedata.generalAttrChange(data)
    local general = table.copy(data)

    --凡属性转换仙属性折算比例
    local every_fairy_turn = gamedata.config.global_kv.every_fairy_turn.value

    --仙属性转换凡属性折算比例
    local fairy_turn_every = gamedata.config.global_kv.fairy_turn_every.value

    general.atk         =   math.floor(data.atk + data.g_atk * fairy_turn_every)
    general.defense     =   math.floor(data.defense + data.g_defense * fairy_turn_every)
    general.hp          =   math.floor(data.hp + data.g_hp * fairy_turn_every)
    general.critical    =   math.floor(data.critical + data.g_critical * fairy_turn_every)
    general.dodge       =   math.floor(data.dodge + data.g_dodge * fairy_turn_every)
    general.parry       =   math.floor(data.parry + data.g_parry * fairy_turn_every)
    general.resilience  =   math.floor(data.resilience + data.g_resilience * fairy_turn_every)
    general.hit         =   math.floor(data.hit + data.g_hit * fairy_turn_every)
    general.arp         =   math.floor(data.arp + data.g_arp * fairy_turn_every)
    general.criticaldmg =   math.floor(data.criticaldmg + data.g_criticaldmg * fairy_turn_every)


    general.g_atk         =   math.floor(data.g_atk + data.atk * every_fairy_turn)
    general.g_defense     =   math.floor(data.g_defense + data.defense * every_fairy_turn)
    general.g_hp          =   math.floor(data.g_hp + data.hp * every_fairy_turn)
    general.g_critical    =   math.floor(data.g_critical + data.critical * every_fairy_turn)
    general.g_dodge       =   math.floor(data.g_dodge + data.dodge * every_fairy_turn)
    general.g_parry       =   math.floor(data.g_parry + data.parry * every_fairy_turn)
    general.g_resilience  =   math.floor(data.g_resilience + data.resilience * every_fairy_turn)
    general.g_hit         =   math.floor(data.g_hit + data.hit * every_fairy_turn)
    general.g_arp         =   math.floor(data.g_arp + data.arp * every_fairy_turn)
    general.g_criticaldmg =   math.floor(data.g_criticaldmg + data.criticaldmg * every_fairy_turn)

    return general
end


function gamedata.generalData(self,data,isprotagonist)
    local generalconfig = gamedata.config.general[tostring(data.cid)]

    local general
    if data.attrWithOutTransform then
        general = table.copy(data)
    else
        general =  {
            cid = data.cid,
            iid = data.iid,
            level1 = data.level1,
            level2 = data.level2 or 0, --突破
            level4 = data.level4 or 0,
            level5 = data.level5 or 0, --升星
            level6 = 0, --文科
            level7 = 0, --理科
            level8 = data.fei_sheng_level or data.level8 or 0, --飞升等级
            exp = data.exp,
            skilllevel = data.skilllevel, --觉醒
            skillexp = data.skillexp,
            quality = generalconfig.quality,
            basic = generalconfig.basic,
            skill = {},
            combskill = {},

            power = data.power_withOutTransform or data.power or 0, -- 配合1014培养接口修改
            g_power = data.g_power_withOutTransform or data.g_power or 0,
            scope = data.scope or 0,
            g_score1 = data.g_score1 or 0,
            g_score2 = data.g_score2 or 0,
            g_score3 = data.g_score3 or 0,
            g_score4 = data.g_score4 or 0,
            g_score5 = data.g_score5 or 0,

            speed = data.speed,
            potential = data.potential,

            atk = data.atk or 0,
            defense = data.defense or 0,
            hp = data.hp or 0,
            critical = data.critical or 0,
            dodge = data.dodge or 0,
            parry = data.parry or 0,
            resilience = data.resilience or 0,
            hit = data.hit or 0,
            arp = data.arp or 0,
            criticaldmg = data.criticaldmg or 0,

            g_atk = data.g_atk or 0,
            g_defense = data.g_def or 0,
            g_hp = data.g_hp or 0,
            g_critical = data.g_critical or 0,
            g_dodge = data.g_dodge or 0,
            g_parry = data.g_parry or 0,
            g_resilience = data.g_resilience or 0,
            g_hit = data.g_hit or 0,
            g_arp = data.g_arp or 0,
            g_criticaldmg = data.g_criticaldmg or 0,

            illusion = {},
            exclusiveArtifactCid = 0,
            godCompetitionArrayId = 0,
        }

        if data.ids and data.ids.ids[1] and data.ids.ids[1] > 0 then
            general.illusion = {
                cid                 = data.ids.ids[1] or 0,
                g_score1            = data.ids.ids[2] or 0,
                g_score2            = data.ids.ids[3] or 0,
                g_score3            = data.ids.ids[4] or 0,
                g_score4            = data.ids.ids[5] or 0,
                g_score5            = data.ids.ids[6] or 0,
                score               = data.ids.ids[7] or 0,
                attrWeaken          = data.ids.ids[8] or 0,
                illusionGeneralCid  = data.ids.ids[9] or 0,
            }

            local general_id = gamedata.config.illusion[tostring(general.illusion.cid)].general_id
            local originCid = gamedata.getOriginCid(general_id)
            local originGeneralConfig = gamedata.config.general[tostring(originCid)]

            local orange_id     = general_id
            local red_id        = general_id
            local gold_id       = general_id
            --初始红将
            if originGeneralConfig.quality == 6 then
                orange_id = originCid
                red_id = originCid
                gold_id = originGeneralConfig.gold_id > 0 and originGeneralConfig.gold_id or originCid
            else

                local illusionGeneralConfig = gamedata.config.general[tostring(originCid)]
                red_id = illusionGeneralConfig.break_id
                if red_id > 0 and gamedata.config.general[tostring(red_id)] then
                    gold_id = gamedata.config.general[tostring(red_id)].gold_id
                end
            end

            general.illusion.orange_id  = orange_id
            general.illusion.red_id     = red_id
            general.illusion.gold_id    = gold_id
            general.illusionGeneralCid = general.illusion.illusionGeneralCid

            printT(general.illusion,"illusion")

        end
        -- 换肤标识
        if data.ids and data.ids.ids[10] then
            general.g_fashion = data.ids.ids[10] or 0
        end

        --专属神器cid
        if data.ids and data.ids.ids[11] then
            general.exclusiveArtifactCid = data.ids.ids[11]
        end

         --封神赛 武将曹位
         if data.ids and data.ids.ids[12] then
            general.godCompetitionArrayId = data.ids.ids[12]
        end

        --保留原属性，有地方用到
        general.attrWithOutTransform = {
            atk           = general.atk,
            defense       = general.defense,
            hp            = general.hp,
            critical      = general.critical,
            dodge         = general.dodge,
            parry         = general.parry,
            resilience    = general.resilience,
            hit           = general.hit,
            arp           = general.arp,
            criticaldmg   = general.criticaldmg,

            g_atk         = general.g_atk,
            g_defense     = general.g_defense,
            g_hp          = general.g_hp,
            g_critical    = general.g_critical,
            g_dodge       = general.g_dodge,
            g_parry       = general.g_parry,
            g_resilience  = general.g_resilience,
            g_hit         = general.g_hit,
            g_arp         = general.g_arp,
            g_criticaldmg = general.g_criticaldmg,
        }

        --凡属性转换仙属性折算比例
        local every_fairy_turn = gamedata.config.global_kv.every_fairy_turn.value
        --仙属性转换凡属性折算比例
        local fairy_turn_every = gamedata.config.global_kv.fairy_turn_every.value
        
        general.atk           =   math.floor(general.atk + general.attrWithOutTransform.g_atk * fairy_turn_every)
        general.defense       =   math.floor(general.defense + general.attrWithOutTransform.g_defense * fairy_turn_every)
        general.hp            =   math.floor(general.hp + general.attrWithOutTransform.g_hp * fairy_turn_every)
        general.critical      =   math.floor(general.critical + general.attrWithOutTransform.g_critical * fairy_turn_every)
        general.dodge         =   math.floor(general.dodge + general.attrWithOutTransform.g_dodge * fairy_turn_every)
        general.parry         =   math.floor(general.parry + general.attrWithOutTransform.g_parry * fairy_turn_every)
        general.resilience    =   math.floor(general.resilience + general.attrWithOutTransform.g_resilience * fairy_turn_every)
        general.hit           =   math.floor(general.hit + general.attrWithOutTransform.g_hit * fairy_turn_every)
        general.arp           =   math.floor(general.arp + general.attrWithOutTransform.g_arp * fairy_turn_every)
        general.criticaldmg   =   math.floor(general.criticaldmg + general.attrWithOutTransform.g_criticaldmg * fairy_turn_every)

        general.g_atk         =   math.floor(general.g_atk + general.attrWithOutTransform.atk * every_fairy_turn)
        general.g_defense     =   math.floor(general.g_defense + general.attrWithOutTransform.defense * every_fairy_turn)
        general.g_hp          =   math.floor(general.g_hp + general.attrWithOutTransform.hp * every_fairy_turn)
        general.g_critical    =   math.floor(general.g_critical + general.attrWithOutTransform.critical * every_fairy_turn)
        general.g_dodge       =   math.floor(general.g_dodge + general.attrWithOutTransform.dodge * every_fairy_turn)
        general.g_parry       =   math.floor(general.g_parry + general.attrWithOutTransform.parry * every_fairy_turn)
        general.g_resilience  =   math.floor(general.g_resilience + general.attrWithOutTransform.resilience * every_fairy_turn)
        general.g_hit         =   math.floor(general.g_hit + general.attrWithOutTransform.hit * every_fairy_turn)
        general.g_arp         =   math.floor(general.g_arp + general.attrWithOutTransform.arp * every_fairy_turn)
        general.g_criticaldmg =   math.floor(general.g_criticaldmg + general.attrWithOutTransform.criticaldmg * every_fairy_turn)

        --未转换之前的战力
        general.power_withOutTransform   = general.power
        general.g_power_withOutTransform = general.g_power
        --转换之后的战力
        general.power           =   general.power_withOutTransform + general.g_power_withOutTransform
        general.f_power         =   math.floor(general.power_withOutTransform + general.g_power_withOutTransform * fairy_turn_every)
        general.g_power         =   math.floor(general.g_power_withOutTransform + general.power_withOutTransform * every_fairy_turn)
    end
    
    if not isprotagonist then

        local final_generalConfig = general.illusionGeneralCid and gamedata.config.general[tostring(general.illusionGeneralCid)] or generalconfig

        if final_generalConfig.skillid and final_generalConfig.skillid >0 then
            general.skill = {
                cid = final_generalConfig.skillid,
                generalcid = data.cid,
                level = data.skilllevel,
                exp = data.skillexp,
                status = 2,
            }
        elseif final_generalConfig.special_skill_reveal and final_generalConfig.special_skill_reveal >0 then
            general.skill = {
                cid = final_generalConfig.special_skill_reveal,
                generalcid = data.cid,
                level = data.skilllevel or 0,
                exp = data.skillexp or 0,
                status = 2,
            }
        end
        if final_generalConfig.combskillid and final_generalConfig.combskillid >0 then
            general.combskill = {
                    cid = final_generalConfig.combskillid,
                    generalcid = data.cid,
                    status = 0,
            }
        end
    else
        general.skill = {
            cid = generalconfig.skillid,
            generalcid = data.cid,
            status = 2,
            islead = true,
        }
        general.combskill = {
            cid = (generalconfig.combskillid and generalconfig.combskillid > 0) and generalconfig.combskillid or generalconfig.combskillid2,
            generalcid = data.cid,
            status = (generalconfig.combskillid and generalconfig.combskillid > 0) and 2 or -1,
            islead = true,
        }
    end

    return general
end

function gamedata.equipData(self,data)

    local config = gamedata.config.equip[tostring(data.ids[2])]
    local data = {
        iid = data.ids[1],
        cid = data.ids[2],
        level1 = data.ids[3] or 1,
        level2 = data.ids[4] or 0,
        exp = data.ids[5] or 0,
        xatk = data.ids[6] or 0,
        xdef = data.ids[7] or 0,
        xhp = data.ids[8] or 0,
        xadddmg = data.ids[9] or 0,
        xsubdmg = data.ids[10] or 0,
        xcount = data.ids[11] or 0,
        level3 = data.ids[12] or 0, --星级
        level4 = data.ids[13] or 0,
        quality = config.quality,
        type = config.type,
    }

    if config.type == "horse" or config.type == "treasure" then 
        data.evaluate = config.adorn*(data.quality*10^9 + data.level1*10^6 + data.level2*10^3 + data.level3)
    else
        data.evaluate = config.adorn*(config.quality2*10^14
                                    + data.quality*10^13 
                                    + math.min(config.suit,1)*10^12
                                    + data.level1*10^9 
                                    + data.level3*10^6 
                                    + data.level2*10^3
                                    + data.level4)
    end

    return data
end

function gamedata.artifactData(self,data)
    local result = {
        iid = data[1].i,
        cid = data[2].i,
        name = data[3].s,
        attr1 =  data[4] and data[4].i or 0,
        attr2 = data[5] and data[5].i or 0,
        isChecked = data[6] and data[6].i or 0,
        skill1 = data[7] and data[7].i or 0,
        skill2 = data[8] and data[8].i or 0,
        skill3 = data[9] and data[9].i or 0,
        jewel1 = data[10] and data[10].i or -1,
        jewel2 = data[11] and data[11].i or -1,
        jewel3 = data[12] and data[12].i or -1,
        jewel4 = data[13] and data[13].i or -1,
        -- 强化等级
        level1 = data[14] and data[14].i or 0,
        --强化成功率
        levelProbs = data[15] and data[15].i or 0,
        -- 基础属性

        levelHP = data[16] and (tonumber(data[16].s) and math.floor(tonumber(data[16].s)) or 0)  or 0,
        levelAttack = data[17] and (tonumber(data[17].s) and math.floor(tonumber(data[17].s)) or 0) or 0,
        levelDef = data[18] and (tonumber(data[18].s) and math.floor(tonumber(data[18].s)) or 0) or 0,

        -- levelHP = data[16] and tonumber(data[16].s)  or 0,
        -- levelAttack = data[17] and tonumber(data[17].s) or 0,
        -- levelDef = data[18] and tonumber(data[18].s) or 0,
        
        skill1_cid_bk = data[19] and data[19].i or 0,-- 洗练技能1cid 0没有技能
        skill2_cid_bk = data[20] and data[20].i or 0,-- 洗练技能1cid 0没有技能
        skill3_cid_bk = data[21] and data[21].i or 0,-- 洗练技能1cid 0没有技能
        -- 技能孔1，2，3
        skillHole1 = data[22] and data[22].i or -1,
        skillHole2 = data[23] and data[23].i or -1,
        skillHole3 = data[24] and data[24].i or -1,
        -- 技能孔的开孔概率
        skillHoleProbs1 = data[25] and data[25].i or 0,
        skillHoleProbs2 = data[26] and data[26].i or 0,
        skillHoleProbs3 = data[27] and data[27].i or 0,
        -- 锁定状态
        isLockState = data[28] and data[28].i or 0,
        score = data[29] and data[29].i or 0,
        resonanceActiveId1 = data[30] and data[30].i or 0,
        resonanceActiveId2 = data[31] and data[31].i or 0,
        resonanceActiveId3 = data[32] and data[32].i or 0,
        resonanceSkillNum = data[33] and data[33].i or 0,
    }

    return result
end

function gamedata.jewelData(self,data)
    return {
        cid = data.ids[1],
        num = data.ids[2],
    }
end

function gamedata.soulData(self,data)

    local config = gamedata.config.soul[tostring(data.cid)]
    local data = {
        cid = data.cid,
        iid = data.iid,
        level = data.level,
        quality = config.quality
    }
    data.evaluate = (config.quality2 or 1)*data.level
    return data
end

function gamedata.SoulHuntQuery(self,data)
    self.cache.soulhunt.soul = data.soul
    self.cache.soulhunt.hunt = data.hunt
    self.cache.soulhunt.coin = data.coin
end

function gamedata.SoulHunt(self,data,param)

    local getnum = data.soul- (self.cache.soulhunt.soul or 0)

    self:SoulHuntQuery(data)

    local getsouls = {}
    if next(data.souls) and #data.souls ~=0 then
        getsouls = self:Souls(data.souls)
    end


    if param ==1 or param ==6 then
         if #getsouls == 0 and getnum >0 then
             getsouls = {{cid=70000,num =1} }
             getnum = getnum -1
         end
    elseif param ==10 then
        if #getsouls <10 and getnum > 0 then
            for i= 1,getnum do
                table.insert(getsouls,{cid=70000,num =1})
                getnum = getnum -1
            end
        end
    elseif param ==60 then
        if #getsouls <10 and getnum >10 then
            for i= 1,getnum-10 do
                table.insert(getsouls,{cid=70000,num =1})
                getnum = getnum -1
            end
        end
    elseif param ==100 then
        if #getsouls <100 and getnum > 0 then
            for i= 1,getnum do
                table.insert(getsouls,{cid=70000,num =1})
                getnum = getnum -1
            end
        end
    elseif param ==600 then
        if #getsouls <100 and getnum >100 then
            for i= 1,getnum-100 do
                table.insert(getsouls,{cid=70000,num =1})
                getnum = getnum -1
            end
        end
    end

    return getsouls,getnum
end

function gamedata.findcombskilllevel(self,generals,slots,cheers,protagonistiid)

    local combskills = {}
    for k,v in pairs(generals) do
        if protagonistiid and v.iid == protagonistiid then
        else
            local generalcid = gamedata.getOriginCid(v.illusionGeneralCid or v.cid)
            local config = gamedata.config.general[tostring(generalcid)]
            if config.combskillid and config.combskillid ~= 0 then
                if not combskills[config.combskillid] then
                    combskills[config.combskillid] = {level = v.level2, status = 0, cids = {},ison= {}}
                end
                if v.level2 < combskills[config.combskillid].level then
                    combskills[config.combskillid].level = v.level2
                end
                

                if not combskills[config.combskillid].cids[generalcid] then
                    combskills[config.combskillid].cids[generalcid] = {ison = false,iids = {}}
                end
                table.insert(combskills[config.combskillid].cids[generalcid].iids,v.iid)

                local skillconfig = self.config.combskill[tostring(config.combskillid)]
                if not skillconfig["cid"..(table.getTableLength(combskills[config.combskillid].cids)+1)] or skillconfig["cid"..(table.getTableLength(combskills[config.combskillid].cids)+1)] == 0 then
                    combskills[config.combskillid].status = 1
                end
            end
        end
    end

    for k,v in pairs(slots) do
        if generals[v.general] then
            if protagonistiid and v.general == protagonistiid then
            else
                local generalcid = gamedata.getOriginCid(generals[v.general].illusionGeneralCid or generals[v.general].cid)
                local config = gamedata.config.general[tostring(generalcid)]
                if config.combskillid and config.combskillid ~= 0 then
                    if combskills[config.combskillid].status == 1 then
                        table.insert(combskills[config.combskillid].ison,v.general)
                    end
                    combskills[config.combskillid].cids[generalcid].ison = true
                    combskills[config.combskillid].cids[generalcid].level2 = generals[v.general].level2
                end
            end
        end
    end

    for k,v in pairs(cheers) do
        if protagonistiid and v.general == protagonistiid then
        else
            local generalcid = gamedata.getOriginCid(generals[v.general].illusionGeneralCid or generals[v.general].cid)
            local config = gamedata.config.general[tostring(generalcid)]
            if config.combskillid and config.combskillid ~= 0 then
                if combskills[config.combskillid].status == 1 then
                    table.insert(combskills[config.combskillid].ison,v.general)
                end
                combskills[config.combskillid].cids[generalcid].ison = true
                combskills[config.combskillid].cids[generalcid].level2 = generals[v.general].level2
            end
        end
    end

    for k,v in pairs(combskills) do
        if table.getTableLength(v.cids) == #v.ison then
            for k_,v_ in pairs(v.cids) do
                for k__,v__ in pairs(v_.iids) do
                    generals[v__].combskillstatus = 2
                    generals[v__].combskilllevel = v.level
                    generals[v__].combskill.status = 2
                    generals[v__].combskill.level2 = v.level
                    generals[v__].combskill.cids = v.cids
                end
            end
        else
            for k_,v_ in pairs(v.cids) do
                for k__,v__ in pairs(v_.iids) do
                    generals[v__].combskillstatus = v.status
                    generals[v__].combskilllevel = v.level
                    generals[v__].combskill.status = v.status
                    generals[v__].combskill.cids = v.cids
                end
            end
        end
    end
end

function gamedata.Generals(self,generalsdata,needreturn)

    -- local generals = {}
    for k,v in ipairs(generalsdata) do
        if self:checkIsMainChacter(v.iid,v.cid) then
            -- 主角
            local level6,level7 = 0,0
            if self.cache.protagonist.general then
                level6 = self.cache.protagonist.general.level6 or 0
                level7 = self.cache.protagonist.general.level7 or 0
            end
            self.cache.protagonist.general = self:generalData(v,true)
            self.cache.protagonist.general.level6 = level6
            self.cache.protagonist.general.level7 = level7
            --
            self.cache.protagonist.level1 = self.cache.protagonist.general.level1
            self.cache.protagonist.level2 = self.cache.protagonist.general.level2           
        else
            local level6,level7 = 0,0
            if self.cache.generals[v.iid] then
                level6 = self.cache.generals[v.iid].level6 or 0
                level7 = self.cache.generals[v.iid].level7 or 0
            end
            self.cache.generals[v.iid] = self:generalData(v)
            self.cache.generals[v.iid].level6 = level6
            self.cache.generals[v.iid].level7 = level7
        end
    end

    self:findcombskilllevel(self.cache.generals,self.cache.slots,self.cache.cheers,self.cache.protagonist.iid)

    if needreturn then
        local generals = {}
        for k,v in ipairs(generalsdata) do
            table.insert(generals,self.cache.generals[v.iid])
        end
        return generals
    end

end


function gamedata.checkIsMainChacter(self,iid,cid)
    if not iid or not cid  then return false end
    if iid == self.cache.protagonist.iid or (cid >=10101 and cid<=10199) or
    (cid >=10901 and cid <=10999) or (cid >=162001 and cid <=162099) then
        return true
    else
        return false    
    end    
end

function gamedata.SlotGenerals(self,generalsdata,needreturn)

    local generals =  table.copy(self.cache.generals)
    local protagonist =  table.copy(self.cache.protagonist)

    for k,v in ipairs(generalsdata) do
        print("SlotGenerals k v",v.iid)
        print (protagonist.iid ,"protagonist")
        if self:checkIsMainChacter(v.iid,v.cid) then
            -- 主角
            local level6,level7 = 0,0
            if protagonist.general then
                level6 = protagonist.general.level6 or 0
                level7 = protagonist.general.level7 or 0
            end
            protagonist.general = self:generalData(v,true)
            protagonist.general.level6 = level6
            protagonist.general.level7 = level7
            --
            protagonist.level1 = protagonist.general.level1
            protagonist.level2 = protagonist.general.level2      
     
        else
            local level6,level7 = 0,0
            if generals[v.iid] then
                level6 = generals[v.iid].level6 or 0
                level7 = generals[v.iid].level7 or 0
            end
            generals[v.iid] = self:generalData(v)
            generals[v.iid].level6 = level6
            generals[v.iid].level7 = level7
        end
    end
    
    self:findcombskilllevel(generals,self.cache.slots,self.cache.cheers,protagonist.iid)
    
    printT(protagonist)
    if needreturn then
        local returngeneral = {}
        for k,v in ipairs(generalsdata) do
            if self:checkIsMainChacter(v.iid,v.cid) then
                table.insert(returngeneral,protagonist)
            else    
                table.insert(returngeneral,generals[v.iid])
            end    
        end
        printT(returngeneral,"SlotGenerals return")
        return returngeneral
    end

end


function gamedata.SlotGodCompetitionGenerals(self,generalsdata,needreturn)
    local generals =  table.copy(self.cache.generals)
    local protagonist =  table.copy(self.cache.protagonist)
    local ismainChapter = false
    for k,v in ipairs(generalsdata) do
        -- print("SlotGenerals k v",v.iid)
        -- print (protagonist.iid ,"protagonist")
        if self:checkIsMainChacter(v.iid,v.cid) then
            ismainChapter= true
            -- 主角
            local level6,level7 = 0,0
            if protagonist.general then
                level6 = protagonist.general.level6 or 0
                level7 = protagonist.general.level7 or 0
            end
            protagonist.general = self:generalData(v,true)
            protagonist.general.level6 = level6
            protagonist.general.level7 = level7
            --
            protagonist.level1 = protagonist.general.level1
            protagonist.level2 = protagonist.general.level2      
     
        else
            local level6,level7 = 0,0
            if generals[v.iid] then
                level6 = generals[v.iid].level6 or 0
                level7 = generals[v.iid].level7 or 0
            end
            generals[v.iid] = self:generalData(v)
            generals[v.iid].level6 = level6
            generals[v.iid].level7 = level7
        end
    end
    
    if ismainChapter then
        self:findcombskilllevel(generals,self.cache.slots,self.cache.cheers,protagonist.iid)
    end    
    
    -- printT(protagonist)
    if needreturn then
        local returngeneral = {}
        for k,v in ipairs(generalsdata) do
            if self:checkIsMainChacter(v.iid,v.cid) then
                table.insert(returngeneral,protagonist)
            else    
                table.insert(returngeneral,generals[v.iid])
            end    
        end
        -- printT(returngeneral,"SlotGenerals return")
        return returngeneral
    end

end

--重置武将的 合体技能
function gamedata.finGodCompetitionCombskilllevel(self)
    local cachegenerals =  table.copy(self.cache.generals)
    for i=1,3 do
        if gamedata.cache.godCompetionData[tonumber(i)] and  gamedata.cache.godCompetionData[tonumber(i)].slot_General then
            local generals  =   gamedata.cache.godCompetionData[tonumber(i)].slot_General.general
            local cheers  =   gamedata.cache.godCompetionData[tonumber(i)].cheer_General
            local combskills = {}
            for k,v in pairs(cachegenerals) do
                if  v.iid and v.cid and self:checkIsMainChacter(v.iid,v.cid) then
                else
                    local generalcid = gamedata.getOriginCid(v.illusionGeneralCid or v.cid)
                    local config = gamedata.config.general[tostring(generalcid)]
                    if config.combskillid and config.combskillid ~= 0 then
                        if not combskills[config.combskillid] then
                            combskills[config.combskillid] = {level = v.level2, status = 0, cids = {},ison= {}}
                        end
                        if v.level2 < combskills[config.combskillid].level then
                            combskills[config.combskillid].level = v.level2
                        end
                        if not combskills[config.combskillid].cids[generalcid] then
                            combskills[config.combskillid].cids[generalcid] = {ison = false,iids = {}}
                        end
                        table.insert(combskills[config.combskillid].cids[generalcid].iids,v.iid)
        
                        local skillconfig = self.config.combskill[tostring(config.combskillid)]
                        if not skillconfig["cid"..(table.getTableLength(combskills[config.combskillid].cids)+1)] or skillconfig["cid"..(table.getTableLength(combskills[config.combskillid].cids)+1)] == 0 then
                            combskills[config.combskillid].status = 1
                        end
                    end
                end
            end
        
    
            for i=1,3 do
                local _generals  =   gamedata.cache.godCompetionData[tonumber(i)].slot_General.general
                for k,v in pairs(_generals) do
                    if v.general then
                        if  v.general.iid and v.general.cid and self:checkIsMainChacter(v.general.iid,v.general.cid) then
                        else
                            local generalcid = gamedata.getOriginCid(v.general.illusionGeneralCid or v.general.cid)
                            local config = gamedata.config.general[tostring(generalcid)]
                            if config.combskillid and config.combskillid ~= 0 then
                                if combskills[config.combskillid].status == 1 then
                                    table.insert(combskills[config.combskillid].ison,v.general.iid)
                                end
                                printT(combskills[config.combskillid],k,"cids")
                                combskills[config.combskillid].cids[generalcid].ison = true
                                combskills[config.combskillid].cids[generalcid].level2 = v.general.level2
                            end
                        end
                    end     
                end
            end    
    
    
            for k,v in pairs(cheers) do
                if v.general then
                    if v.general.iid and v.general.cid and self:checkIsMainChacter(v.general.iid,v.general.cid) then
                    else
                        local generalcid = gamedata.getOriginCid(cachegenerals[v.general.iid].illusionGeneralCid or cachegenerals[v.general.iid].cid)
                        local config = gamedata.config.general[tostring(generalcid)]
                        if config and config.combskillid and config.combskillid ~= 0 then
                            if combskills[config.combskillid].status == 1 then
                                table.insert(combskills[config.combskillid].ison,v.general.iid)
                            end
                            combskills[config.combskillid].cids[generalcid].ison = true
                            combskills[config.combskillid].cids[generalcid].level2 = cachegenerals[v.general.iid].level2
                        end
                    end
                end    
            end

            for kk,vv in pairs(generals) do
                if vv.general then
                    if  vv.general.iid and vv.general.cid and self:checkIsMainChacter(vv.general.iid,vv.general.cid) then
                    else
                        local isset = false
                        for k,v in pairs(combskills) do
                            if table.getTableLength(v.cids) == #v.ison then --已经激活
                                for k_,v_ in pairs(v.cids) do
                                    for k__,v__ in pairs(v_.iids) do
                                        if generals[kk].general.iid ==  v__ then
                                            generals[kk].general.combskillstatus = 2
                                            generals[kk].general.combskilllevel = v.level
                                            generals[kk].general.combskill.status = 2
                                            generals[kk].general.combskill.cids = v.cids
                                            isset = true
                                        end    
                                    end
                                end                                
                            else    
                                for k_,v_ in pairs(v.cids) do
                                    for k__,v__ in pairs(v_.iids) do
                                        if generals[kk].general.iid ==  v__ then
                                            generals[kk].general.combskillstatus = v.status
                                            generals[kk].general.combskilllevel = v.level
                                            generals[kk].general.combskill.status = v.status
                                            generals[kk].general.combskill.cids = v.cids
                                            isset= true
                                        end     
                                    end
                                end
                            end
                        end      
                    end
                end     
            end
            gamedata.cache.godCompetionData[tonumber(i)].slot_General.general = generals
        end    
    end    
end



function gamedata.ProtagonistPreveiw(self,generalsdata)

    local generals = {}
    for k,v in ipairs(generalsdata) do
        self.cache.protagonistPreveiw[v.level2] = self:generalData(v,true)
    end

    return self.cache.protagonistPreveiw
end

function gamedata.removeEquips(self,ids)
    for k,v in pairs(ids) do
        self.cache.equips[v] = nil
    end
end

--移除宝物
function gamedata.removeEquipsNumBycid(self,cid,number)   
    local removetable = {}
    local num =  math.abs(number)
    local tresureOrhorse = {}
    for k,v in pairs(self.cache.slots) do
        if v.treasure then
            table.insert(tresureOrhorse,v.treasure)
        end    
        if v.horse  then
            table.insert(tresureOrhorse,v.horse)
        end    
    end
    -- printT(tresureOrhorse,"removeEquipsNumBycid 在阵容")
    local iscontain = function (iid)
        for i,w in pairs(tresureOrhorse) do
            if iid == w then
                return false
            end  
        end
        return true
    end

    for k,v in pairs(self.cache.equips) do
       if tostring(v.cid) == tostring(cid) then
            local hwe = v.generalcid or ""
            -- print("removeEquipsNumBycid generalid",hwe)
            -- printT(v)
            if (v.level1 <= 1) and (v.level2 <= 0) and (v.level3 <= 0) and (v.xcount <= 0) then
                if iscontain(v.iid) then
                     table.insert(removetable,{iid =  v.iid})
                end    
                -- for i,w in pairs(tresureOrhorse) do
                --    if v.iid ~= w then
                --       table.insert(removetable,{iid =  v.iid})
                --    end  
                -- end
            end
       end 
    end
    local sortfunc = function (a,b)
        return  a.iid < b.iid 
    end
    table.sort(removetable,sortfunc)
    if num <= table.getTableLength(removetable) then
        for i=1,num do
            print("removeEquipsNumBycid remove:",removetable[i].iid)
            -- printT(self.cache.equips[removetable[i].iid],"removedata")
            self.cache.equips[removetable[i].iid] = nil
        end
    end   
    -- makeEquipsTemp()
end


function gamedata.Equips(self,equipsdata)
    local equips = {}
    for k,v in ipairs(equipsdata) do
        self.cache.equips[v.ids[1]] = self:equipData(v)
        table.insert(equips,self.cache.equips[v.ids[1]])
    end
    return equips
end

function gamedata.Newartifact(self,artifactData,isSetGeneral)
    local artifacts = {}
    for k,v in ipairs(artifactData) do
        self.cache.artifacts[v.params[1].i] = self:artifactData(v.params)
        table.insert(artifacts,self.cache.artifacts[v.params[1].i])
    end
    if isSetGeneral then
        for k,v in pairs(self.cache.slots) do
            if v.newartifact > 0 then
                self.cache.artifacts[v.newartifact].sid = k
            end
        end
    end
    return artifacts
end

function gamedata.DeleteArtifact(self,artifacts)
    for k,v in pairs(artifacts) do
        self.cache.artifacts[v.iid] = nil
    end
end

function gamedata.Jewel(self,jewelData)
    local jewels = {}
    for k,v in ipairs(jewelData) do
        self.cache.jewels[v.ids[1]] = self:jewelData(v)
        table.insert(jewels,self.cache.jewels[v.ids[1]])
    end
    return jewels
end

function gamedata.Souls(self,soulsdata)
    local souls = {}
    for k,v in ipairs(soulsdata) do
        if v.iid ~= 0 then
            self.cache.souls[v.iid] = self:soulData(v)
            table.insert(souls,self.cache.souls[v.iid])
        end
    end
    return souls
end

function gamedata.relationData(self,data)
    local relation = {}
    print(data,"relationData data")
    if data then
        for k,v in ipairs(data) do
            local ids = {}
            for kk,vv in ipairs(v.ids) do
                ids[kk] = vv
            end
            relation[k] = {activate = v.activate,ids = ids}
        end
    end    
    printT(relation,"relationData data return")

    return relation
end

function gamedata.slotData(self,data)
    local _token = {}

    if data.token then
        local _count = 1
        local _len1 = table.getTableLength(gamedata.config.token_suit)
        local _len2 = table.getTableLength(gamedata.config.token_suit["1"])
        local _config = gamedata.config.token_suit

        for i = 1, _len1 do
            _token[i] = {}
            for _i = 1, _len2 do
                _token[i][_i] = data.token[_count]
                _count = _count + 1
            end
        end
    end

    return {
        sid = data.sid,
        general = data.general,

        weapon = data.weapon,
        armor = data.armor ,
        accessory = data.accessories ,
        head = data.shoe ,
        treasure = data.treasure,
        horse = data.horse ,
        newartifact = data.newartifact or 0,
        token = _token,

        s1 = data.s1,
        s2 = data.s2,
        s3 = data.s3,
        s4 = data.s4,
        s5 = data.s5,
        s6 = data.s6,
        s7 = data.s7,
        s8 = data.s8,

        g1 = data.g1,
        g2 = data.g2,
        g3 = data.g3,
        g4 = data.g4,
        g5 = data.g5,
        g6 = data.g6,
        g7 = data.g7,
        g8 = data.g8,

        relation = self:relationData(data.relation),
    }

end

function gamedata.Slots(self,slotsdata)
    for k,v in ipairs(slotsdata) do
        -- print("v.sid",v.sid,v.general)
        if v.general and v.general ~= 0 then
            self.cache.slots[v.sid] = self:slotData(v)
        else
            self.cache.slots[v.sid] = nil
        end
    end
end

function gamedata.isGeneralOn(self,iid)
    for k,v in pairs(self.cache.slots) do
        if iid == v.general then
            return 2
        end
    end

    for k,v in pairs(self.cache.cheers) do
        if iid == v.general then
            return 1
        end
    end
    return nil
end

function gamedata.isEquipOn(self,iid)
    for k,v in pairs(self.cache.slots) do
        if iid == v.weapon or
            iid == v.armor or
            iid == v.accessory or
            iid == v.head or
            iid == v.treasure or
            iid == v.horse then

           return 1
        end
    end
    return nil
end

function gamedata.cheerData(self,data)
    return {
        sid = data.sid,
        general = data.general,
        relation = self:relationData(data.relation),
    }
end

function gamedata.Cheers(self,cheersdata)
    for k,v in ipairs(cheersdata) do
        self.cache.cheers[v.sid] = self:cheerData(v)
    end
end

function gamedata.slotgemData(self,data)
    if data then
        local gendata = {}
        for k,v in ipairs(data) do
            table.insert(gendata,v)
        end
        return gendata
    else
        return {}
    end
end

function gamedata.slotGems(self,data)
    for i=1,8 do
        if data["f"..i] and data["f"..i].ids and data["f"..i].ids[1] then
            self.cache.slotgems[i] = self:slotgemData(data["f"..i].ids)
        end
    end
end


function gamedata.gemData(self,data)
    return {
        iid = data.ids[1] or 0,
        cid = data.ids[2] or 0,
        level = data.ids[3] or 1,
        exp = data.ids[4] or 0,
        order = gamedata.config.sigil[tostring(data.ids[2])].order,
        type = gamedata.config.sigil[tostring(data.ids[2])].type,
    }
end


function gamedata.Gems(self,data)
    local gems = {}
    for k,v in ipairs(data) do
        self.cache.gems[v.ids[1]] = self:gemData(v)
        table.insert(gems,self.cache.gems[v.ids[1]])
    end
    return gems
end

function gamedata.SlotInfoProcess(self,info)
    self:Slots(info.slots)
    self:Protagonist(info.protagonist)
    self:Cheers(info.cheers)
    self:Generals(info.generals)
    self:Equips(info.equips)
    self:Souls(info.souls)
    self:Gems(info.gems)
    self:Newartifact(info.newartifacts or {},true)
    self:Jewel(info.jewels or {})
    self:slotGems(info)
end

function gamedata.pointData(self,data)

    return {
        id = data.id,
        move = data.move,
        star = data.star,
        kill = data.kill,
    }

end

function gamedata.copyData(self,data)

    local map = {
        id = data.id,
        status = data.status,
        prestige = data.prestige,
        pa1 = data.pa1,
        pa2 = data.pa2,
        pa3 = data.pa3,
        points = {},
    }

    for k,v in ipairs(data.points) do
        map.points[v.id] = self:pointData(v)
    end

    return map
end

function gamedata.Copies(self,copies)
    for k,v in ipairs(copies.maps) do
        self.cache.copy[v.id] = self:copyData(v)
    end
    self.cache.copywipetimer = copies.timer
end

function gamedata.BraveCopies(self,copies)
    for k,v in ipairs(copies.maps) do
        self.cache.bravecopy[v.id] = self:copyData(v)
    end
    self.cache.copywipetimer = copies.timer
end

function gamedata.activityCopy( self,aiData )
    self.cache.copyActivity = {}
    local count, tempTable= 0,{}
    print("activityCopy ==")
    for k,v in ipairs(aiData.ids) do
        if k%5 == 1 then
            count = count + 1
            table.insert(tempTable ,{}) 
            tempTable[count].aid = v 
        elseif k%5 == 2 then
            tempTable[count].usedTimes = v 
        elseif k%5 == 3 then
            tempTable[count].openLevel = v
        elseif k%5 == 4 then
            tempTable[count].isFirst = v
        else
            tempTable[count].passLevel = v
        end
    end


    local vip = self.config.vip
    for k,v in pairs(self.config.daily_function) do
        local t = {}
        if v["function"] == 1 then
            t.times = vip[tostring(0)].exp_copy_times or 0
        elseif  v["function"] == 2 then
            t.times = vip[tostring(0)].coin_copy_times or 0
        elseif  v["function"] == 3 then
            t.times = vip[tostring(0)].stone_copy_times or 0
        elseif  v["function"] == 4 then
            t.times = vip[tostring(0)].upstar_times or 0
        elseif  v["function"] == 5 then
            t.times = vip[tostring(0)].zhenfu_times or 0
        elseif  v["function"] == 6 then
            t.times = vip[tostring(0)].forging_copy_times or 0
        end
        for m,n in pairs(v) do
            t[m] = n
        end
        table.insert(self.cache.copyActivity,t)
    end
    for k,v in ipairs(self.cache.copyActivity) do
        for m,n in pairs(tempTable) do
            if tonumber(v.id) == tonumber(n.aid) then
                for i,j in pairs(n) do
                    v[i] = j
                end
                v.isOpen = true
                break
            end
        end
    end
    for k,v in ipairs(self.cache.copyActivity) do
        if v.isOpen == nil then
            v.isOpen = false
            v.aid = v.id
            v.usedTimes = -1
            v.openLevel = 0
            v.isFirst = 0
            v.passLevel = 0
        end
    end
    table.sort(self.cache.copyActivity,function(a,b)
        if a.isOpen == true and b.isOpen == false then
            return true
        elseif  a.isOpen == false and b.isOpen == true then
            return false
        else
            if a.order and b.order then
                return (a.order < b.order)
            else
                return (a.id < b.id)
            end
        end
    end)

end
     
function gamedata.friendcopyData(self,data)
    local map =  {
        map = data.map,
        kill = data.kill,
        point = data.point,
        friend = data.friend,
        generals = {},
        hps = {},
    }
    if data.friend and data.friend ~= 0 then
        if self.config.expedition_map[tostring(data.map)].friend == 1 then
            map.friendgeneral = self.cache.friends.friends[data.friend].first
        else
            map.friendgeneral = self.cache.friends.friends[data.friend].second
        end
    end


    for k,v in ipairs(data.hps) do
        if k<=7 then
            table.insert(map.hps,v)
        else
            table.insert(map.generals,v)
        end
    end

    return map
end

function  gamedata.FriendCopies(self,copies)
--    for k,v in ipairs(copies.expeditions) do
--        self.cache.friendcopy[v.map] = self:friendcopyData(v)
--    end
    self.cache.friendcopy.kill = copies.ids[1] or 0
    self.cache.friendcopy.maps = {}
    for k,v in ipairs(copies.ids) do
        if math.mod(k,2) == 0 and k > 1 then
            table.insert(self.cache.friendcopy.maps,{})
            self.cache.friendcopy.maps[math.floor(k/2)].id =  copies.ids[k] or 0
        elseif k > 1 then
            self.cache.friendcopy.maps[math.floor(k/2)].kill =  copies.ids[k] or 0
        end
    end
end


function gamedata.propData(self,data)
    return {
        cid = data.id,
        num = data.num,
    }
end

function gamedata.updateprops(self,v)
    if not self.cache.props[v.cid] then
        self.cache.props[v.cid] = {}
        self.cache.props[v.cid].cid = v.cid
        self.cache.props[v.cid].num = v.num
    else
        self.cache.props[v.cid].num = self.cache.props[v.cid].num + v.num
    end
    if v.update then
    elseif self.cache.props[v.cid].num == 0 then
        self.cache.props[v.cid] = nil
    end
    -- if self.cache.props[v.cid].num == 0 then
    --     self.cache.props[v.cid] = nil
    -- end
    if v.num < 0 then
        local _name = ""

        if v.cid >= 202101 and v.cid <= 202300 then
            _name = self.config.token_fragment[tostring(v.cid)].name 
        elseif v.cid >= 201901 and v.cid <= 202100 then
            _name = self.config.token[tostring(v.cid)].name
        else
            _name = self.config.props[tostring(v.cid)].name
        end

        UIResponse({type = 503, msgtype = "umeng", datatype = "use", name = _name, amount = -v.num, gold = 0 })
    end
end



function gamedata.Props(self,propsdata)

    local props = {}
    self.cache.props = {}
    for k,v in ipairs(propsdata) do
        if not self.cache.props[v.id] then
            self.cache.props[v.id] = self:propData(v)
        else
            self:updateprops(self:propData(v))
        end

        table.insert(props,self:propData(v))
    end
    return props
end



function gamedata.generalfragmentData(self,data)
    return {
        cid = data.cid,
        num = data.num,
        status = data.status,
        neednum = data.neednum,
    }
end

function gamedata.ishasgeneral(self,cid)
    for k,v in pairs(self.cache.generals) do
        if (gamedata.config.general[tostring(v.cid)].init_cid and gamedata.config.general[tostring(v.cid)].init_cid == cid) or (gamedata.config.general[tostring(v.cid)].gold_id and gamedata.config.general[tostring(v.cid)].gold_id == cid) or (gamedata.config.general[tostring(v.cid)].orange_id and gamedata.config.general[tostring(v.cid)].orange_id == cid) or (gamedata.config.general[tostring(v.cid)].break_id and gamedata.config.general[tostring(v.cid)].break_id == cid) or (gamedata.config.general[tostring(v.cid)].generalid2 and gamedata.config.general[tostring(v.cid)].generalid2 == cid) or (v.cid == cid) then
            return v
        elseif (gamedata.config.general[tostring(v.cid)].partner_id and gamedata.config.general[tostring(v.cid)].partner_id == cid) then           
            return v
        end
    end

    return nil
end

function gamedata.findFragmentCid(self,generalcid)
    --printT(self.config.general_fragment)
    --print(generalcid)
    for k,v in pairs(self.config.general_fragment) do
        --print(generalcid, v.general)
        if generalcid == v.general then
            --printT(v)
            return v.id
        end
    end
end

function gamedata.updategeneralfragmentbynum(self,v)
    local generalCid
    local fragmentCid
    local fragmentConfig
    if (v.cid >= 10101 and v.cid <= 11000) or (v.cid >= 160001 and v.cid <= 161000) or (v.cid >= 170001 and v.cid <= 171000) or (v.cid >= 162001 and v.cid <= 163000) or (v.cid >= 164001 and v.cid <= 165000) or (v.cid >= 174001 and v.cid <= 175000) then
        generalCid = v.cid
        fragmentCid= self:findFragmentCid(generalCid)
        fragmentConfig = self.config.general_fragment[tostring(fragmentCid)]
    else
        fragmentCid = v.cid
        fragmentConfig = self.config.general_fragment[tostring(fragmentCid)]
        generalCid = fragmentConfig.general
    end

    if not self.cache.generalfragments[generalCid] then
        self.cache.generalfragments[generalCid] = {}
        self.cache.generalfragments[generalCid].cid = generalCid
        self.cache.generalfragments[generalCid].fragmentCid = fragmentCid
        self.cache.generalfragments[generalCid].num = v.num
    else
        self.cache.generalfragments[generalCid].num = self.cache.generalfragments[generalCid].num + v.num
    end

    if self.cache.generalfragments[generalCid].num == 0 then
        self.cache.generalfragments[generalCid] = nil
    else

        local generalInCache = self:ishasgeneral(generalCid)

        if not  generalInCache then
            self.cache.generalfragments[generalCid].status = 1
            self.cache.generalfragments[generalCid].neednum =  fragmentConfig.num
        else
            self.cache.generalfragments[generalCid].status = 2

            local quality = self.config.general[tostring(generalCid)].quality
            local nextnum
            local nextlevel
            local needprop,needcoin
            if generalInCache.level2+1 <= table.getTableLength(self.config.general_awake) then
                nextnum = self.config.general_awake[tostring(generalInCache.level2+1)][quality.."piece"]
                nextlevel = self.config.general_awake[tostring(generalInCache.level2+1)].level
                needprop = self.config.general_awake[tostring(generalInCache.level2+1)][tostring(quality).."prop"]
                needcoin = self.config.general_awake[tostring(generalInCache.level2+1)]["coin"..tostring(quality)]
            else
                needprop=0
                needcoin = 0
                nextnum = -1
                nextlevel = self.config.general_awake[tostring(generalInCache.level2)].level
            end
            if quality > 2 then
                self.cache.generalfragments[generalCid].neednum =  nextnum
            else
                self.cache.generalfragments[generalCid].neednum = 0
            end

        end
    end
end


function gamedata.GeneralFragments(self,GeneralFragments)

    local generalfragments = {}

    for k,v in ipairs(GeneralFragments) do
        self:updategeneralfragmentbynum({cid = v.cid, num =v.num})
--        if not self.cache.generalfragments[v.cid] then
--            self.cache.generalfragments[v.cid] = self:generalfragmentData(v)
--        else
--            self:updategeneralfragmentbynum({cid = v.cid, num =v.num})
--        end

        table.insert(generalfragments,self:generalfragmentData(v))
    end

    return  generalfragments
end

function gamedata.recruitsData(self,i,k,recruitData)
    self.cache.generalrecruit[i] = {
        consum = recruitData[k] or 0,
        freetimes = recruitData[k+1] or 0,
        consumtimes = recruitData[k+2] or 0,
        tentimes = recruitData[k+3] or 0,
        timer = recruitData[k+4] or 0,
        updatetime = gamedata:time()
    }
end

function gamedata.Recruits(self,recruitData)
    for i=1,4 do
        self:recruitsData(i,(i-1)*5+1,recruitData)
    end
end

function gamedata.GeneralsEXP(self,exps)

    local exptable = {}
    for k,v in pairs(self.cache.slots) do
        if v.general and v.general ~= 0 then
            for kk,vv in ipairs(exps) do
                if v.general == vv.id then
                    if not self.cache.generals[vv.id] or vv.id == self.cache.protagonist.iid then
                        exptable[k] = {
                            id = vv.id,
                            cid = self.cache.protagonist.general.cid,
                            exp = vv.exp,
                            level = self.cache.protagonist.general.level1,
                            level2 = 0,
                            levelup = vv.levelup,
                            skilllevel = self.cache.protagonist.general.skilllevel or 0,
                        }
                    else
                        exptable[k] = {
                            id = vv.id,
                            cid = self.cache.generals[vv.id].illusionGeneralCid or self.cache.generals[vv.id].cid,
                            exp = vv.exp,
                            level = self.cache.generals[vv.id].level1,
                            level2 = self.cache.generals[vv.id].level2,
                            levelup = vv.levelup,
                            skilllevel = self.cache.generals[vv.id].skilllevel or 0,
                            g_fashion = self.cache.generals[vv.id].g_fashion or 0,
                        }
                    end
                    break
                end
            end
        end
    end
    return exptable
end

function gamedata.equipfragmentData(self,v)
    return {
        cid = v.id,
        num = v.num,
    }
end

function gamedata.updateequipfragment(self,v)
    if not self.cache.equipfragments[v.cid] then
        self.cache.equipfragments[v.cid] = v
    else
        self.cache.equipfragments[v.cid].num = self.cache.equipfragments[v.cid].num + v.num
    end
    if self.cache.equipfragments[v.cid].num == 0 then
        self.cache.equipfragments[v.cid] = nil
    end

end

function gamedata.updateJewelData(self,data)
    for k,v in ipairs(data) do
        if not self.cache.jewels[v.cid] then
            self.cache.jewels[v.cid] = {cid = v.cid,num = v.num}
        else
            self.cache.jewels[v.cid].num = self.cache.jewels[v.cid].num + v.num
        end
    end
   
end

function gamedata.EquipFragments(self,data)
    local equipfragments = {}
    for k,v in ipairs(data) do
        if not self.cache.equipfragments[v.id] then
            self.cache.equipfragments[v.id] = self:equipfragmentData(v)
        else
            self:updateequipfragment(self:equipfragmentData(v))
        end

        table.insert(equipfragments,self:equipfragmentData(v))
    end
    return equipfragments
end


function gamedata.checkEquipNum( self,needchecktreasure,needcheckequip)
    local treasurenum = 0
    local equipnum = 0 
    for k,v in pairs(self.cache.equips) do
        if v.type == "horse" or v.type == "treasure" then
            treasurenum = treasurenum + 1
        else
            equipnum = equipnum + 1
        end
    end

    print("checkEquipNum: treasurenum",treasurenum,"equipnum",equipnum)

    if needchecktreasure and treasurenum>500 and treasurenum<1000 then
        UIResponse({type=5555,kind=1,opt = 0})
    elseif needcheckequip and equipnum>500 and equipnum<1000 then
        UIResponse({type=5555,kind=2,opt = 0})
    end
end

function gamedata.checkSoulNum( self )
    local soulnum = table.getTableLength(self.cache.souls)
    print("checkSoulNum: soulnum",soulnum)
    if soulnum>500 then
        UIResponse({type=5555,kind=3,opt = 0})
    end
end

function gamedata.checkQilingNum( self )
    local qilingnum = table.getTableLength(self.cache.exclusiveArtifactQiLing)
    print("checkQilingNum: qilingnum",qilingnum)
    if qilingnum>500 and qilingnum<=1000 then
        UIResponse({type=5555,kind=4,opt = 0})
    end
end

function gamedata.SomethingProcess(self,data,exttype)
    print("SomethingProcess==")

    local reward = {}
    local used = {}

    local ext = {}
    local double = 0

    local titles = {}
    local iconBoxs = {}

    if data.pext5 and data.pext5[1] and data.pext5[1].ids then      --双倍掉落标示
        double = data.pext5[1].ids[1] or 0
    end

    if exttype and exttype== "generalrecruit" then
        if data.pext5 and data.pext5[2] and data.pext5[2].ids then    --招募额外掉落
            local extdata = data.pext5[2].ids
            for k,v in ipairs(extdata) do
                if math.mod(k,2)== 0 then
                    local onedata = {cid = extdata[k-1],num = v}
                    table.insert(ext,onedata)
                    gamedata:updateStaff(onedata)
                end
            end
        end
    end


    if data.gold and data.gold ~= 0 then
        print("SomethingProcess==    gold")
        self:updateRoleGold(data.gold)
        if data.gold > 0 then
            table.insert(reward,{cid = 1001, num = data.gold, order = 1, double = double})
        end
    end

    if data.coin and data.coin ~= 0 then
        self:updateRoleCoin(data.coin)
        if data.coin > 0 then
            table.insert(reward,{cid = 1000, num = data.coin, order = 2, double = double})
        end
    end

    if data.stamina and data.stamina ~= 0 then
        self:updateRoleStamina(data.stamina)
        UIResponse({type = 503, msg = "获得体力"..data.stamina})
        --table.insert(reward,{cid = 1002, num = data.stamina})
    end

    if data.energy and data.energy ~= 0 then
        self:updateRoleEnergy(data.energy)
        UIResponse({type = 503, msg = "获得精力"..data.energy})
        --table.insert(reward,{cid = 1003, num = data.energy})
    end

    if exttype and exttype== "cornucopia" then
        if data.pext1 and data.pext1[1] and data.pext1[1].ids then
            self:Cornucopia(data.pext1[1].ids)
            ext = {}
            for i=5,9 do
                ext[i-4] = data.pext1[1].ids[i] or 1
            end
        end
    end

    if exttype and exttype== "dumpling" then
        if data.pext1 and data.pext1[1] and data.pext1[1].ids then
            ext._type = data.pext1[1].ids[1]
        end
    end

    if next(data.generals) then
        for k,v in ipairs(data.generals) do
            -- if v.iid == self.cache.protagonist.iid or (v.cid >=10101 and v.cid<=10199) or 
            --     (v.cid >=10901 and v.cid <=10999) then
            --     self:generalData(v,true)
            -- else
            --     self.cache.generals[v.iid] = self:generalData(v)
            -- end
            table.insert(reward,{cid = v.cid, num =1,iid = v.iid, order = 3, quality = self.config.general[tostring(v.cid)].quality, double = double})
        end
        self:Generals(data.generals)
        --self:findcombskilllevel(self.cache.generals,self.cache.slots,self.cache.cheers,self.cache.protagonist.iid)
    end

    if next(data.equips) then
        local needchecklimitTruesure = false
        local needchecklimitEquip = false
        for k,v in ipairs(data.equips) do
            local equipdata = self:equipData(v)
            needchecklimitTruesure = needchecklimitTruesure 
                or ((equipdata.type == "horse" or equipdata.type == "treasure") and self.cache.equips[v.ids[1]]==nil)
            needchecklimitEquip = needchecklimitEquip
                or (equipdata.type ~= "horse" and equipdata.type ~= "treasure" and self.cache.equips[v.ids[1]]==nil)

            self.cache.equips[v.ids[1]] = equipdata
            local config = self.config.equip[tostring(v.ids[2])]
            if config.type == "horse" or config.type == "treasure" then
                table.insert(reward,{cid = v.ids[2], iid=v.ids[1], num =1, order = 7, quality = config.quality, double = double})
            else
                table.insert(reward,{cid =v.ids[2], iid=v.ids[1], num =1, order = 5, quality = config.quality, double = double})
            end

            if exttype and exttype== "equipstrengthen" then
                if data.pext1 and data.pext1[1] and data.pext1[1].ids then
                    ext[v.ids[1]] = data.pext1[1].ids[k] or 0
                end
            end
        end
        if needchecklimitTruesure or needchecklimitEquip then
            self:checkEquipNum(needchecklimitTruesure,needchecklimitEquip)
        end
    end


    if data.countdownGifts and next(data.countdownGifts) then
        for k,v in ipairs(data.countdownGifts) do
            self.cache.countdownGift[v.iid] = self:countdownGiftData(v)
            table.insert(reward,{cid =v.cid, iid=v.iid, num =1, order = 3, double = double})
        end
    end


    if next(data.gems) then
        for k,v in ipairs(data.gems) do
            self.cache.gems[v.ids[1]] = self:gemData(v)
            table.insert(reward,{cid = v.ids[2], iid = v.ids[1], num =1, order = 11, double = double})
        end
    end

    if data.souls then
        local needchecklimit = false
        for k,v in ipairs(data.souls.idcidlevels) do
            needchecklimit = needchecklimit or (self.cache.souls[v.iid]==nil)
            self.cache.souls[v.iid] = self:soulData(v)
            table.insert(reward,{cid = v.cid, iid=v.iid, num =1, order = 9, quality = self.config.soul[tostring(v.cid)].quality, double = double})
        end
        if needchecklimit then
            self:checkSoulNum()
        end
    end

    if data.illusion  then
        local ids = {}
        local nums = {}
        for i=1,math.floor(#data.illusion.ids/4) do
            table.insert(ids,data.illusion.ids[(i - 1) * 4 + 1])
            table.insert(ids,data.illusion.ids[(i - 1) * 4 + 2])
            table.insert(ids,data.illusion.ids[(i - 1) * 4 + 3])
            table.insert(nums,data.illusion.ids[(i - 1) * 4 + 4])
        end

        local illusions = self:illusions(ids)
        for i,v in ipairs(illusions) do
            table.insert(reward,{cid = v.cid, num =nums[i],endtime = v.endtime})
        end
    end

    if data.qiling and next(data.qiling) then
        print("exclusiveQiling",#data.qiling.ids)
        local qiLingDatas = gamedata:ExclusiveArtifactQiLingDatas(data.qiling.ids)
        for i,v in ipairs(qiLingDatas) do
            table.insert(reward,v)
        end

        if #qiLingDatas > 0 then
            self:checkQilingNum()
        end
    end

    if data.props  and data.props.idnums then
        for k,v in ipairs(data.props.idnums) do

            if v.id == 1004 then
                if self.cache.mieshendian.points then
                    self.cache.mieshendian.points = self.cache.mieshendian.points + v.num
                else
                    self.cache.mieshendian.points = v.num
                end
                if self.cache.mieshendianshop.points then
                    self.cache.mieshendianshop.points = self.cache.mieshendianshop.points + v.num
                else
                    self.cache.mieshendianshop.points = v.num
                end
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1005 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1006 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1007 then
                if self.cache.passkill.basic and self.cache.passkill.basic.killcoinnum then
                    self.cache.passkill.basic.killcoinnum  = self.cache.passkill.basic.killcoinnum + v.num
                elseif self.cache.passkill.basic then
                    self.cache.passkill.basic.killcoinnum  = v.num
                end

                if self.cache.passkillshop.killcoinnum then
                    self.cache.passkillshop.killcoinnum  = self.cache.passkillshop.killcoinnum + v.num
                elseif self.cache.passkillshop then
                    self.cache.passkillshop.killcoinnum  = v.num
                end
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1008 then
                UIResponse({type = 11602})
                
                UIRequest({type = 117,update = true})
                UIResponse({type = 503, msg = "获得VIP经验"..v.num})
            elseif v.id == 1009 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1010 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1012 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1013 then
                UIResponse({type = 503, msg = "获得仙豆："..v.num})
            elseif v.id == 1015 then
                UIResponse({type = 503, msg = "获得好感度："..v.num})
            elseif v.id == 1017 then
                print("exp:"..v.num)
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1019 then
                --UIRequest({type = 4660,update = true})
                UIResponse({type = 503, msg = "获得"..v.num.."充值积分"})
            elseif v.id == 1020 then
                UIResponse({type = 503, msg = "获得好感度："..v.num})
            elseif v.id == 1021 then
                --UIResponse({type = 503, msg = "获得"..v.num.."游戏机积分"})
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1023 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1024 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1025 then
                self:updateRoleG_gold(v.num)
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1026 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1027 then
                if gamedata.cache.xuanyueTreasures.data then
                    gamedata.cache.xuanyueTreasures.data.score  = gamedata.cache.xuanyueTreasures.data.score + v.num
                end

                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1029 then
                if gamedata.cache.xuanyueTreasures2.data then
                    gamedata.cache.xuanyueTreasures2.data.score  = gamedata.cache.xuanyueTreasures2.data.score + v.num
                end

                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1028 then
                if gamedata.cache.AncientRuinsData then
                    gamedata.cache.AncientRuinsData.yinghun  = gamedata.cache.AncientRuinsData.yinghun + v.num
                end
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1030 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1031 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1032 then
                if gamedata.cache.xuanyueTreasures3.data then
                    gamedata.cache.xuanyueTreasures3.data.score  = gamedata.cache.xuanyueTreasures3.data.score + v.num
                end

                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1033 then
                UIResponse({type = 503, msg = "获得雕塑经验："..v.num})
            elseif v.id == 1044 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 1045 then
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif v.id == 70000 then
                if self.cache.soulhunt.soul then
                    self.cache.soulhunt.soul = self.cache.soulhunt.soul +v.num
                else
                    self.cache.soulhunt.soul = v.num
                end
                table.insert(reward,{cid = v.id, num =v.num, order = 10, double = double})
            elseif (v.id >= 10101 and v.id <= 11000) or (v.id >= 160001 and v.id <= 161000) or (v.id >= 170001 and v.id <= 171000) or (v.id >= 162001 and v.id <= 163000) or (v.id >= 164001 and v.id <= 165000) or (v.id >= 174001 and v.id <= 175000) then
                self:updategeneralfragmentbynum({cid = v.id, num =v.num} )
                table.insert(reward,{cid = v.id, num =v.num, order = 4, quality = self.config.general[tostring(v.id)].quality, double = double})
            elseif (v.id >= 11101 and v.id <= 12000) or (v.id >= 161001 and v.id <= 162000) or (v.id >= 171001 and v.id <= 172000) or (v.id >= 163001 and v.id <= 164000) or (v.id >= 165001 and v.id <= 166000) or (v.id >= 175001 and v.id <= 176000) then
                self:updategeneralfragmentbynum({cid = v.id, num =v.num})
                table.insert(reward,{cid = v.id, num =v.num, order = 4, quality = self.config.general[tostring(self.config.general_fragment[tostring(v.id)].general)].quality, double = double})
            elseif v.id >= 18001 and v.id <= 19000 then
                self:UpdateRedFragment({cid = v.id, num =v.num})
                table.insert(reward,{cid = v.id, num =v.num, order = 4, quality = gamedata.IDconfig(v.id).quality, double = double})
            elseif (v.id >= 20001 and v.id <= 21000) or (v.id >= 26407 and v.id <= 26414) or (v.id >= 191001 and v.id <= 200000) then
                if v.id == 21000 then
                    if self.cache.happinessplace.stone then
                        self.cache.happinessplace.stone = self.cache.happinessplace.stone + v.num
                    else
                        self.cache.happinessplace.stone = v.num
                    end
                    UIResponse({type = 503,msg = "获得补天石"..v.num})
                else
                    self:updateprops({cid = v.id, num =v.num})
                    table.insert(reward,{cid = v.id, num =v.num, order = 10, quality = self.config.props[tostring(v.id)].quality, double = double})
                end

            elseif v.id >= 27001 and v.id <= 28000 then
                self:updateequipfragment({cid = v.id, num =v.num})
                table.insert(reward,{cid = v.id, num =v.num, order = 6, quality = self.config.equip[tostring(self.config.equip_fragment[tostring(v.id)].equip)].quality, double = double})
            elseif v.id >= 28001 and v.id <= 29000 then
                self:updateequipfragment({cid = v.id, num =v.num})
                local selfconfig = gamedata.config.treasure2_fragment[tostring(v.id)]
                local fatherconfig
                if selfconfig.page == "meterial" then
                    fatherconfig = gamedata.config.props[tostring(selfconfig.equip)]
                else
                    fatherconfig = gamedata.config.equip[tostring(selfconfig.equip)]
                end

                table.insert(reward,{cid = v.id, num =v.num, order = 8, quality = fatherconfig.quality, double = double})
            elseif v.id >= 91001 and v.id <= 92000 then
                self:updatePetsFragment({cid = v.id, num =v.num})
                table.insert(reward,{cid = v.id, num =v.num, order = 3, quality = gamedata.config.pet3_attr[tostring(gamedata.config.pet3_fragment[tostring(v.id)].petid)]["0"].quality, double = double})
            elseif v.id >= 80001 and v.id <= 81000 then
                table.insert(reward,{cid = v.id, num =v.num, order = 1, quality = 5, double = double})
            elseif v.id >= 82001 and v.id <= 83000 then
                table.insert(reward,{cid = v.id, num =v.num, order = 1, double = double})
            elseif v.id >= 120000 and v.id <= 121000 then
                self:updateJewelData({{cid = v.id,num = v.num}})
                table.insert(reward,{cid = v.id,num = v.num,order = 10,quality = gamedata.config.trump_gem[tostring(v.id)].quality or 1,double = double})
            elseif v.id > 35501 and v.id <= 36000 then --称号
                local title = {v.id,gamedata:time()}
                gamedata:HeadIconData(title,"Title")
                table.insert(reward,{cid = v.id, num =v.num, order = 10, quality = 5, double = double ,time = gamedata.cache.HeadIconData.title[v.id]})
            elseif v.id > 35001 and v.id <= 35500 then --头像框
                local iconBox = {v.id,gamedata:time()}
                gamedata:HeadIconData(iconBox,"IconBox")
                table.insert(reward,{cid = v.id, num =v.num, order = 10, quality = 5, double = double ,time = gamedata.cache.HeadIconData.iconBox[v.id]})
            elseif v.id >= 202101 and v.id <= 202300 then
                self:updateprops({cid = v.id, num =v.num})
                table.insert(reward,{cid = v.id, num =v.num, order = 3, quality = gamedata.config.token_fragment[tostring(v.id)].quality, double = double})
            elseif v.id >= 201901 and v.id <= 202100 then
                self:updateprops({cid = v.id, num =v.num})
                table.insert(reward,{cid = v.id, num =v.num, order = 3, quality = gamedata.config.token[tostring(v.id)].quality, double = double})
            end
        end
    end

    if data.usediids then
        for k,v in ipairs(data.usediids.ids) do
            --print("usediids",v)
            if self.cache.generals[v] then
                table.insert(used, {cid = self.cache.generals[v].cid, iid = self.cache.generals[v].iid} )
                self.cache.generals[v] = nil
            elseif self.cache.equips[v] then
                table.insert(used, {cid = self.cache.equips[v].cid, iid = self.cache.equips[v].iid} )
                self.cache.equips[v] = nil
            elseif self.cache.souls[v] then
                table.insert(used, {cid = self.cache.souls[v].cid, iid = self.cache.souls[v].iid} )
                self.cache.souls[v] = nil
            elseif self.cache.countdownGift[v] then
                table.insert(used, {cid = self.cache.countdownGift[v].cid, iid = self.cache.countdownGift[v].iid} )
                self.cache.countdownGift[v] = nil
            end
        end
    end

    if data.usedcidnums  and data.usedcidnums.idnums then
        for k,v in ipairs(data.usedcidnums.idnums) do
            if v.id == 1000 then
                self:updateRoleCoin(0-v.num)
            elseif v.id == 1001 then
                self:updateRoleGold(0-v.num)
            elseif v.id == 1003 then
                self:updateRoleEnergy(0-v.num)
            elseif (v.id >= 10101 and v.id <= 11000) or (v.id >= 160001 and v.id <= 161000) or (v.id >= 170001 and v.id <= 171000) or (v.id >= 162001 and v.id <= 163000) or (v.id >= 164001 and v.id <= 165000) or (v.id >= 174001 and v.id <= 175000) then
                self:updategeneralfragmentbynum({cid = v.id, num =0-v.num})
            elseif (v.id >= 11101 and v.id <= 12000) or (v.id >= 161001 and v.id <= 162000) or (v.id >= 171001 and v.id <= 172000) or (v.id >= 163001 and v.id <= 164000) or (v.id >= 165001 and v.id <= 166000) or (v.id >= 175001 and v.id <= 176000) then
                self:updategeneralfragmentbynum({cid = v.id, num =0-v.num})
            elseif v.id >= 20001 and v.id <= 21000 then
                self:updateprops({cid = v.id, num =0-v.num})
            elseif v.id >= 27001 and v.id <= 28000 then
                self:updateequipfragment({cid = v.id, num =0-v.num})
            elseif v.id >= 28001 and v.id <= 29000 then
                self:updateequipfragment({cid = v.id, num =0-v.num})
            end
            table.insert(used,{cid = v.id, num =v.num})
        end
    end

    --printT(reward,"something reward")

    self.sortData(reward, "order","quality","cid",nil,nil,nil,true,false,true)
    --printT(reward)

    return reward, used, ext

end


function gamedata.countdownGiftData(self,data)

    local data = {
        iid = data.iid,
        cid = data.cid,
        limitTime = data.time,
        num = 1,
    }

    return data
end


function gamedata.CountdownGift(self,countdownGiftdata)
    local countdownGift = {}
    for k,v in ipairs(countdownGiftdata) do
        self.cache.countdownGift[v.iid] = self:countdownGiftData(v)
        table.insert(countdownGift,self.cache.countdownGift[v.iid])
    end
    return countdownGift
end

function gamedata.rankData(self,data)
    return {
        rank = data.rank,
        name = data.name,
        level = data.level,
        status = data.status,
        rid = data.rid,
        icon = data.heads[1].icon
    }
end

function gamedata.Athletics(self,data)

    self.athletics.my = {
        prestige = data.my.prestige,
        rank = data.my.rank,
        level = data.my.level,
        athletics = data.my.athletics,
    }

    for k,v in ipairs(data.ranks) do
        self.cacahe.athletics.ranklist[v.rank] = self:rankData(v)
    end

end

function gamedata.athleticsRewardData(self,data)
    return {
        id= data.id,
        status =data.status,
    }
end

function gamedata.AthleticsRewards(self,data)

    for k,v in ipairs(data.items) do
        if v.status ~= 0 then
            self.cache.athletics.rewardlist[v.id] = self:athleticsRewardData(v)
        end
    end
end

function gamedata.ActivityStatusData(self,v)
    return {
        id = v.id,
        status = v.status,
    }
end

function gamedata.ActivityStatus(self,data)
    for k,v in ipairs(data.activities) do
         self.cache.activitystatus[v.id] = self:ActivityStatusData(v)
    end
end

function gamedata.DailyCpActivityTimeStatus(self,data)
    
    for i=1,math.floor(#data/3) do
        local sysid = data[(i-1)*3 + 1]
        local cpnum = data[(i-1)*3 + 2]
        local cpday = data[(i-1)*3 + 3]
        self.cache.dailyCpActivityTimeStatus[sysid] = {
            sysid = sysid,
            cpnum = cpnum,
            cpday = cpday,
        }
    end
end

function gamedata.Mieshendian(self,data)
    self.cache.mieshendian = {
        maxfloor = data[1] or 0,
        todaymaxfloor = data[2] or 0,
        todaycount = data[3] or 0,
        failcount = data[4] or 0,
        floor = data[5] or 0,
        star = data[6] or 0,
        cdtime = data[7] or 0,
        resetbuy = data[8] or 0,
        points = data[9] or 0,
        maxstar = data[10] or 0,
        maxwipe = data[11] or 0,
    }
end

function gamedata.MieshendianShop(self,data)

    self.cache.mieshendianshop = {
        points = data[1] or 0,
        maxstar = data[2] or 0,
        items = {},
    }
    for k,v in ipairs(data) do
        if k > 2 and math.mod(k,2) == 1 then
            local item = {}
            item.id = data[k] or 0
            item.count = data[k+1] or 0
            self.cache.mieshendianshop.items[tostring(item.id)] = item
        end
    end
end

function gamedata.Zhuxiantai(self,data)
    self.cache.zhuxiantai = {
        prestige = data[1],
        maxstar = data[2],
        todaymaxstar = data[3],
        star = data[4],
        leftstar = data[5],
        count = data[6],
        reset = data[7],
        floor = data[8],
        atk = data[9],
        def = data[10],
        hp = data[11],
        speed = data[12],
        critical = data[13],
        dodge = data[14],
        parry = data[15],
        status = data[16],
        monster1 = data[17],
        power1 = data[18],
        monster2 = data[19],
        power2 = data[20],
        monster3 = data[21],
        power3 = data[22],
        shop = {},
    }

    for i=23,72 do
        table.insert(self.cache.zhuxiantai.shop,data[i])
    end
end


function gamedata.BloodData(self,blood)
    self.cache.bloodbattle = {
        status = blood.status,
        count = blood.count,
        yesterday = blood.yesterday,
        person = blood.person,
        maxlevel = blood.maxlevel,
        maxpoint = blood.maxpoint,
        getpoint = blood.getpoint,
        leftpoint = blood.leftpoint,
        level = blood.level,
        hpadd = blood.hpadd,
        atkadd = blood.atkadd,
        defadd = blood.defadd,
        max3starlevel = blood.max3starlevel or 0,
        modupcd = blood.modupcd,
        point = blood.point,
        enemies = {}
    }

    for k,v in ipairs(blood.enemies) do
        table.insert(self.cache.bloodbattle.enemies,{
            quality = v.quality,
            num1 = v.num1,
            num2 = v.num2,
            monster = v.monster,
            star = v.star,
            award = v.award,
        })
    end
end

function gamedata.BloodRankData(self,bloodrank)

    for k,v in ipairs(bloodrank.ranks) do
        table.insert(self.cache.bloodrank,{
            rank = v.rank,
            rid = v.rid,
            name = v.name,
            level = v.level,
            maxpoint = v.maxpoint,
            maxlevel = v.maxlevel,
            coninutes = v.coninutes,
            profile = v.profile,
        })
    end
end

function gamedata.othereneralData(self,data,othername)
    return {
        iid = data.iid,
        cid = data.cid,
        level1 = data.level1,
        level2 = data.level2,
        level3 = data.level3 or 0,
        skilllevel = data.level3 or 0,
        power = data.power,
        oldcid = data.ext1 or 0,
        friendname = othername
    }
end

function gamedata.friendData(self,v)
    local friend =  {
        rid = v.rid,
        name = v.name,
        level = v.level,
        profile = v.profile,
        sendgift = v.sendgift,
        recvgift = v.recvgift,
        use = v.use,
--        first = self:othereneralData(v.first,v.name),
--        second = self:othereneralData(v.second,v.name)
        part_rank = 0,
        part_point = 0,
    }

    if v.params and v.params.params and next(v.params.params) then
        friend.params = {}
        for k,v in ipairs(v.params.params) do
            if tonumber(k) == 1 then
                friend.part_rank = v.i or 0
            elseif tonumber(k) == 2 then
                friend.part_point = v.i or 0
            elseif tonumber(k) == 3 then
                friend.iconBox = v.i or gameConfig.defautTitleId
            elseif tonumber(k) == 4 then
                friend.title = v.i or gameConfig.defautIconBoxId
            else
                table.insert(friend.params,{
                    i = v.i,
                    s = v.s
                })
            end
        end
    end

    return friend
end

function gamedata.Friends(self,data)
    self.cache.friends.max = data.max
    self.cache.friends.friends = {}
    for k,v in ipairs(data.friends) do
        self.cache.friends.friends[v.rid] = self:friendData(v)
    end
end

function gamedata.Shield(self,data)
    self.cache.shield.max = data.ids[1] -- 屏蔽总数
    self.cache.shield.index_now = data.ids[2] + data.ids[3]
end

function gamedata.playerdata(self,v)
    local player =  {
        rid = v.rid,
        name = v.name,
        level = v.level,
        vip = v.vip,
        profile = v.profile,
        param = v.param,    --0:未申请； 1：已申请； 2：已同意好友； 3：自己好友已满； 4： 对方好友已满
        part_rank = 0,
        part_point = 0,
        f_power = 0,
        g_power = 0,
    }

    if v.params and v.params.params and next(v.params.params) then
        player.params = {}
        for k,v in ipairs(v.params.params) do
             if tonumber(k) == 1 then
                 player.part_rank = v.i or 0
             elseif tonumber(k) == 2 then
                 player.part_point = v.i or 0
            elseif tonumber(k) == 3 then
                player.iconBox = v.i or gameConfig.defautTitleId
            elseif tonumber(k) == 4 then
                player.title = v.i or gameConfig.defautIconBoxId
             else
                 table.insert(player.params,{
                     i = v.i,
                     s = v.s
                 })
             end
        end
    end

    return player
end

function gamedata.players(self,data)
    local players = {}
    for k, v in ipairs(data) do
        -- print("player.data===",v.rid,v.name,v.level,v.vip,v.profile,v.param)
        table.insert(players,self:playerdata(v))
    end
    return players
end

function gamedata.chatData(self,v)
    return {
        rid = v.rid,
        content = v.content,
        second = v.second,
    }
end

function gamedata.chats(self,data)
    local chats = {}
    for k, v in ipairs(data) do
        table.insert(chats,self:chatData(v))
    end
    return chats
end

function gamedata.shopData(self,v)
    return {
        cid = v.cid,
        num = v.num,
        gold = v.gold,
        discount = v.discount,
    }
end

function gamedata.ShopProps(self,data)
    for k, v in ipairs(data) do
        self.cache.shop.props[k] = v
    end
end

function gamedata.GiftBags(self,data)
    for k, v in ipairs(data) do
        self.cache.shop.giftbags[v.cid] = self:shopData(v)
    end
end

function gamedata.encountData(self,v)
    local now = gamedata:time()
    return {
        iid = v.iid or 0,
        cid = v.cid or 0,
        time = v.time or 0,
        zhe = v.dis or 0,
        beginT = now,
    }
end

function gamedata.Encounters(self,data)
    local encounters = {}
    for k, v in ipairs(data) do
        self.cache.encounters[v.iid] = self:encountData(v)
        table.insert(encounters,self:encountData(v))
    end
    return encounters
end

function gamedata.techData(self,v)
    return {
        cid = v.cid,
        exp = v.exp,
        level = v.level,
    }
end

function gamedata.Technology(self,data)
    for k, v in ipairs(data) do
        self.cache.technology[v.cid] = self:techData(v)
    end
end

function gamedata.HappinessPlace(self,data)
    self.cache.happinessplace.stone = data.stone
    self.cache.happinessplace.free = data.free
    self.cache.happinessplace.freetime = data.freetime
    self.cache.happinessplace.total = data.total
    self.cache.happinessplace.time = data.time
    self.cache.happinessplace.servertotal = data.servertotal
    self.cache.happinessplace.rewards = {}

    for k,v in ipairs(data.rewards) do
        table.insert(self.cache.happinessplace.rewards,v)
    end

end

function gamedata.playerwithgeneralsdata(self,data)
    if not data then return nil end
    local player = self:playerdata(data)
    player.generals = {}
    for k,v in ipairs(data.generals) do
        table.insert(player.generals,self:othereneralData(v))
    end

    return player
end


function gamedata.cupbattleData(self,v)
   return {
       id = v.id,
       round = v.round,
       result = v.result,
       reward = v.reward,
       enemy = self:playerwithgeneralsdata(v.enemy)
   }
end

function gamedata.CupStatus(self,data)

    self.cache.cup.status.round = data.round
    self.cache.cup.status.tomorrow = data.tomorrow

    if not self.cache.cup.status.battles then
        self.cache.cup.status.battles = {}
    end

    for k,v in ipairs(data.battles) do
        self.cache.cup.status.battles[v.round] = self:cupbattleData(v)
    end
end

function gamedata.cuptopbattleData(self,v)
     local battle = {
         id = v.id,
         round = v.round,
         status = v.status,
         bet = v.bet,
         see =false,
         support = v.support,
         a = self:playerwithgeneralsdata(v.a),
         b = self:playerwithgeneralsdata(v.b)
     }

     --print("cuptopbattleData",v.id,v.round,v.bet,v.status)

    if v.status >=0 then
        battle.see = true
--       local nowtime = os.date("*t", gamedata:time())
--       if v.round == 10 then
--           if nowtime.hour >= 15 or (nowtime.hour == 14 and nowtime.min>30) then
--               battle.see = true
--           else
--               battle.see = false
--           end
--       elseif v.round == 11 then
--           if nowtime.hour >= 17 or (nowtime.hour == 17 and nowtime.min>30) then
--               battle.see = true
--           else
--               battle.see = false
--           end
--       elseif v.round == 12 then
--           if nowtime.hour >= 20 or (nowtime.hour == 19 and nowtime.min>30) then
--               battle.see = true
--           else
--               battle.see = false
--           end
--       end
    end

    return battle
end

function gamedata.CupTops(self,data)
    for k,v in ipairs(data.cuptops) do
        self.cache.cup.topbattles[v.id] = self:cuptopbattleData(v)
    end
end

function gamedata.gangbroadcastsData(self,data)
    local broadcastsData = {
        content = data.content,
        template = data.template,
        param = {},
    }
    for k,v in ipairs(data.param) do
        table.insert(broadcastsData.param,v)
    end
    return broadcastsData
end

function gamedata.GangStatus(self,data)

    self.cache.gangstatus = {
        id = data.id,
        name = data.name,
        exp = data.exp,
        level = data.level,
        exp1 = data.exp1,
        level1 = data.level1,
        count1 = data.count1,
        exp2 = data.exp2,
        level2 = data.level2,
        count2 = data.count2,
        announcement = (data.announcement and data.announcement ~= "") and data.announcement or "",
        memberexp = data.memberexp,
        memberlevel = data.memberlevel,
        clean = data.clean,
        ask = data.ask,
        post = data.post,
        gangmoney = data.gangmoney,
        broadcasts = {},
        shopitems = {},
        shopitemstatus = {},
        shopupdatetimes = 0,

        leadername =  data.leadername,
    }

    for k,v in ipairs(data.broadcasts) do
        table.insert(self.cache.gangstatus.broadcasts,self:gangbroadcastsData(v))
    end

    for k,v in ipairs(data.shopitems) do
        if k == 1 then
            self.cache.gangstatus.shopupdatetimes = v
        else
            table.insert(self.cache.gangstatus.shopitems,v)
        end

    end

    for k,v in ipairs(data.shopitemstatus) do
        table.insert(self.cache.gangstatus.shopitemstatus,v)
    end

end

function gamedata.Gang2Status(self,data)

    if not self.cache.gang2status then  self.cache.gang2status = {} end
    self.cache.gang2status.id = data[1] and data[1].i or 0
    self.cache.gang2status.name = data[2] and data[2].s or ""
    self.cache.gang2status.level = data[3] and data[3].i or 0
    self.cache.gang2status.exp = data[4] and data[4].i or 0
    self.cache.gang2status.content = data[5] and data[5].s or ""
    self.cache.gang2status.status = data[6] and data[6].i or 0
    self.cache.gang2status.param = data[7] and data[7].i or 0
    self.cache.gang2status.statustime = data[8] and data[8].i or 0
    self.cache.gang2status.declaration = data[9] and data[9].s or ""
    self.cache.gang2status.num = data[10] and data[10].i or 0
    self.cache.gang2status.power = data[11] and data[11].i or 0

end

function gamedata.Gang2Status2(self,data)

    if not self.cache.gang2status then  self.cache.gang2status = {} end
    self.cache.gang2status.contribution = data[1] and data[1] or 0
    self.cache.gang2status.totalcontribution = data[2] and data[2] or 0
    self.cache.gang2status.initiationtime = data[3] and data[3] or 0
    self.cache.gang2status.rewardstatus = data[4] and data[4] or 0

    self.cache.gang2status.gangfeastreward = data[5] and data[5] or 0
    self.cache.gang2status.gangfeastdoing = data[6] and data[6] or 0
    self.cache.gang2status.gangfeastplace = data[7] and data[7] or 0
    self.cache.gang2status.gangbathreward = data[8] and data[8] or 0
    self.cache.gang2status.gangbathdoing = data[9] and data[9] or 0
    self.cache.gang2status.gangbathplace = data[10] and data[10] or 0
    
end

--公会军团动态的数据
function gamedata.Gang2Legion(self,data,msgnum)
    if not self.cache.gang2Legion then self.cache.gang2Legion ={} end
    self.cache.gang2Legion.startLocation = data[1] and data[1] or 0
    self.cache.gang2Legion.startLocation = self.cache.gang2Legion.startLocation + (msgnum or 0)
end

--公会军团动态的数据
function gamedata.Gang2Legion2(self,data)
    if not self.cache.gang2Legion then self.cache.gang2Legion = {} end
    self.cache.gang2Legion[#self.cache.gang2Legion +1] = {}
    local tt = self.cache.gang2Legion[#self.cache.gang2Legion] 
    tt.opt = data[1] and data[1].i or 0
    tt.times = data[2] and data[2].i or ""
    tt.name1 = data[3] and data[3].s or 0
    tt.name2 = data[4] and data[4].s or 0
    tt.content = data[5] and data[5].s or ""
    tt.status = data[6] and data[6].s or 0
    tt.param = data[7] and data[7].s or 0
end


function gamedata.Gang2Data(self,data)

    local gang2 = {}

    if data then
        gang2.id = data[1] and data[1].i or 0
        gang2.name = data[2] and data[2].s or ""
        gang2.level = data[3] and data[3].i or 0
        gang2.num = data[4] and data[4].i or 0
        gang2.leadername = data[5] and data[5].s or ""
        gang2.declaration = data[6] and data[6].s or ""
        gang2.power = data[7] and data[7].i or 0
        gang2.param = data[8] and data[8].i or 0
        gang2.autoStatus = data[9] and data[9].i or 0
        gang2.autoLv = data[10] and data[10].i or 0
    end

    return gang2

end

function gamedata.Gang2MemberData(self,data)
    local member = {}
    if data then
        member.rid = data[1] and data[1].i or 0
        member.name = data[2] and data[2].s or ""
        member.level = data[3] and data[3].i or 0
        member.power = data[4] and data[4].i or 0
        member.pointtotal = data[5] and data[5].i or 0
        member.pointtoday = data[6] and data[6].i or 0
        member.secs = data[7] and data[7].i or 0
        member.profile = data[8] and data[8].i or 0
        member.vip = data[9] and data[9].i or 0
        member.part_rank = data[10] and data[10].i or 0
        member.part_point = data[11] and data[11].i or 0
        member.iconBox = data[12] and data[12].i or 0
        member.title = data[13] and data[13].i or 0
    end
    return member
end

function gamedata.Gang2Post(self,data)
    if data then
        self.cache.gang2post = {}
        self.cache.gang2post.post1 = data[1] and data[1] or 0
        self.cache.gang2post.post2_1 = data[2] and data[2] or 0
        self.cache.gang2post.post2_2 = data[3] and data[3] or 0
        self.cache.gang2post.post2_3 = data[4] and data[4] or 0
    end
    return self.cache.gang2post
end



function gamedata.gangData(self,data)
    return {
        id = data.id,
        name = data.name,
        level = data.level,
        exp = data.exp,
        num = data.num,
        power = data.power,
        point = data.point,
        param = data.param,
        leadername =  data.leadername,
    }
end

function gamedata.GangsLevel(self,data)
    for k,v in ipairs(data.gangs) do
        self.cache.gangs_level[#self.cache.gangs_level+1] = self:gangData(v)
    end
end


function gamedata.GangsPoint(self,data)
    for k,v in ipairs(data.gangs) do
        self.cache.gangs_point[#self.cache.gangs_point+1] = self:gangData(v)
    end
end

function gamedata.gangmemberData(self,data)
    return {
        rid = data.rid,
        name = data.name,
        level = data.level,
        power = data.power,
        ganglevel = data.ganglevel,
        contribution = data.contribution,
        post = data.post or 0,
        lastlogin = data.lastlogin or 0,
        devilfotress = data.devilfotress,

        profile = data.profile,
    }
end

function gamedata.GangMembers(self,data)
    local members = {}
    self.cache.gangmembers = {}
    for k,v in ipairs(data.members) do
        self.cache.gangmembers[v.rid] = self:gangmemberData(v)
        table.insert(members,self:gangmemberData(v))
    end
    return members
end

function gamedata.gangsimpleData(self,data)
    return {
        id = data.id,
        name = data.name,
        level = data.level,
        exp = data.exp,
        num = data.num,
        power = data.power,
        point = data.point,
        param = data.param,
    }
end

function gamedata.GangShopGoods(self,data)
    -- body
    print("GangShopGoods")
    self.cache.gang_shopgoods = {}

    for k,v in ipairs(data.ids) do
        table.insert(self.cache.gang_shopgoods,{})
        self.cache.gang_shopgoods[k].index = k
        self.cache.gang_shopgoods[k].num = data.ids[k]
    end
end

function gamedata.GangXianChiData(self,data)
    -- body
    print("GangXianChiData")
    
    self.cache.gang2xianchi.xc_quality = data[1]
    self.cache.gang2xianchi.xc_exp = data[2]
    self.cache.gang2xianchi.xc_level = data[3]
    self.cache.gang2xianchi.xc_dayprogress = data[4]

    self.cache.gang2xianchi.rewardstatus1 = data[5]
    self.cache.gang2xianchi.rewardstatus2 = data[6]
    self.cache.gang2xianchi.rewardstatus3 = data[7]
    self.cache.gang2xianchi.rewardstatus4 = data[8]
    self.cache.gang2xianchi.eattimesnum = data[9]
end


-- 公会战
-- 参战据点
function gamedata.GuildWarTakeWarPointData(self,data)
    print("GuildWarTakeWarPointData===")
    self.cache.guildwarmain.inspirestatus = data[1]
    self.cache.guildwarmain.battleSignstatus = data[2]

    self.cache.guildwarmain.takewardata = {}
    self.cache.guildwarmain.takewardata.contributionNum = data[3]
    self.cache.guildwarmain.takewardata.onepoint = data[4]
    self.cache.guildwarmain.takewardata.twopoint = data[5]
    self.cache.guildwarmain.takewardata.rewardpoint = data[6]
    self.cache.guildwarmain.takewardata.rewardstatus = data[7]

    -- printT(self.cache.guildwarmain.takewardata)
end

function gamedata.GuildWarAllPointData(self,data)
    print("GuildWarAllPointData===")
    -- printT(data)
    if not  data  then return end
    self.cache.guildwarmain.allpointsdata = {}
    
    for k,v in ipairs(data) do
        print(k,v.i,v.s)
        local pointdata = {}
        pointdata.id = v and v.i or 0
        pointdata.name = v and v.s or ""

        table.insert(self.cache.guildwarmain.allpointsdata,pointdata)
    end
    -- if not self.cache.guildwarmain.allpointsdata[id] then
    --     self.cache.guildwarmain.allpointsdata[id] = {}
    -- end
    
    printT(self.cache.guildwarmain.allpointsdata)

end

function gamedata.GuildWarPointQuery( self,data )
    print("GuildWarPointQuery===")
    self.cache.guildwarpointquery.guildid = data[1] and  data[1].i  or 0       --占领公会id
    self.cache.guildwarpointquery.guildname = data[1] and data[1].s or ""      --占领据点的公会名称 （""为无工会占领）
    self.cache.guildwarpointquery.guildlevel = data[2] and  data[2].i  or 0    --占领公会等级
    self.cache.guildwarpointquery.guildatk = data[3] and data[3].i or 0        --战斗力
    self.cache.guildwarpointquery.guilddefense = data[4] and data[4].i or 0    --城防
    self.cache.guildwarpointquery.guildatkpercent = data[5] and data[5].i or 0 --战力百分比
    self.cache.guildwarpointquery.guildnum = data[6] and data[6].i or 0        --可报名次数
    self.cache.guildwarpointquery.guildstate = data[7] and data[7].i or 0      --按钮状态（0报名未开启，1报名攻打，2已   报名，3报名截止，4进入战场，5战前准备，6查看战斗, 7没有公会参战）
    self.cache.guildwarpointquery.guildtime = data[8] and data[8].i or 0       --倒计时时间（距离开始时间 秒）
    self.cache.guildwarpointquery.guildwarid = data[9] and data[9].i or 0      --战斗id（0表示没有）
end
function gamedata.GangPointJoinConfirmData(  self,data )
     print("GangPointJoinConfirmData===")
     self.cache.guildwarjionconfirm.isok = data[1]
 end 

function gamedata.GangPointJoinQuery( self,data)
    print("GangPointJoinQuery === ")
    self.cache.guildchecklist.isSignUp = data[1] and data[1].i or 0
    self.cache.guildchecklist.cellData = {}
    local count = 0
    for k,v in ipairs(data) do
        if k> 1 then
            if (k-1)%4 == 1 then
                table.insert(self.cache.guildchecklist.cellData,{})  
                count = count + 1 
                self.cache.guildchecklist.cellData[count].gid = v and v.i or 0  
                self.cache.guildchecklist.cellData[count].name = v and v.s or 0  
            end
            if (k - 1)%4 == 2 then
                self.cache.guildchecklist.cellData[count].level = v and v.i  or 0
            end    
            if (k - 1)%4 == 3 then
                self.cache.guildchecklist.cellData[count].atk = v and v.i  or 0 
            end 
            if (k - 1)%4 == 0 then
                self.cache.guildchecklist.cellData[count].contribution = v and v.i  or 0 
            end                                 
        end
    end
end
--工会技能
function gamedata.gangSkill(self,data)
    self.cache.gang2skill = {}
    local t = {}
    local count = 0
    for k,v in pairs(gamedata.config.gang2_skill_open) do
        table.insert(t,v.id)
        count = count + 1
    end
    table.sort(t,function(a,b)
        if a > b then
            return false
        else
            return true
        end
    end)
    for i = 1,count do
        print("ttttt"..i.." = "..tostring(t[i]))
        print(data[i])
        self.cache.gang2skill[tostring(t[i])] =  {[1] = data[i] or 0 ,[2] = i}
    end
end

function gamedata.DevilFotressStatus(self,data)

    self.cache.devilfotressftatus.setdef = data.setdef
    self.cache.devilfotressftatus.gang1 = self:gangsimpleData(data.gang1 or {})
    self.cache.devilfotressftatus.gang2 = self:gangsimpleData(data.gang2 or {})
    self.cache.devilfotressftatus.gang3 = self:gangsimpleData(data.gang3 or {})
    self.cache.devilfotressftatus.vaild = data.vaild
end

function gamedata.DevilFotressGangDef(self,data)

    local GangDefdata = {
        gang = data.gang,
        points = {},
    }

    for k, v in ipairs(data.position) do
        if v ~= 0 then
            for i,j in ipairs(data.players) do
                if j.rid == v then
                    GangDefdata.points[k]= {pos = k, player = self:playerwithgeneralsdata(j) }
                end
            end
        else
            GangDefdata.points[k]= {pos = k, player = {}}
        end
    end

    return GangDefdata
end

function gamedata.DevilFtoressTargetPointData(self,v)
    return {
        pos = v.pos,
        hp = v.hp,
        kill = v.kill,
        count = v.count,
        player = self:playerwithgeneralsdata(v.player),
    }
end


function gamedata.DevilFtoressTarget(self,data)

    local Targetdata = {
        gang = data.gang,
        battlecount = data.battlecount or 0,
        points = {},
    }

    for k, v in ipairs(data.points) do
        Targetdata.points[v.pos] = self:DevilFtoressTargetPointData(v)
    end

    return Targetdata
end

function  gamedata.mailData(self,v)
   local mail = {
       id = v.id,
       type = v.type,
       status = v.status,
       source = v.source,
       title = v.title,
       content = v.content,
       attachment = (v.attachment and string.find(v.attachment,"{")) and LoadJsonStringToTable(v.attachment) or {},
       second = v.second,
   }

    if mail.type == 1 or mail.type == 2 then
        if v.source and v.source ~= 0 then
            mail.source =  self.cache.mailplayers[v.source]
        end
    end

    return mail
end

function gamedata.Mails(self,data)
    for k, v in ipairs(data.players) do
        self.cache.mailplayers[v.rid] = self:playerwithgeneralsdata(v)
    end

    for k, v in ipairs(data.mails) do
        self.cache.mails[v.id] = self:mailData(v)
    end
end

function gamedata.Chicken(self,data)
    for k,v in ipairs(data.ids) do
        table.insert(self.cache.chicken,v)
    end
end

function gamedata.ActivityShop(self,data)

    local now = gamedata:time()
    self.cache.activityShop.reciveTime = now
    self.cache.activityShop.lucky = data.ids[1]
    self.cache.activityShop.reset = data.ids[2]
    self.cache.activityShop.time = data.ids[3]
    self.cache.activityShop.status = {}

    for i=4, 14 ,2  do
        table.insert(self.cache.activityShop.status,{id = data.ids[i], status = data.ids[i+1]})
    end
end

function gamedata.ActivityBlackShop(self,data)
    for k,v in pairs(data.ids) do
        print(k,v)
    end
    local nowtime = os.date("*t", gamedata:time())
    self.cache.activityBlackShop.freshtime = nowtime
    self.cache.activityBlackShop.itemsdata = {}
    self.cache.activityBlackShop.resetnum = data.ids[1]
    for i=2,18 ,2 do
        print(i)
        if data.ids[i] then
            table.insert(self.cache.activityBlackShop.itemsdata,{id = data.ids[i], num = data.ids[i+1]})
        end
    end
end

function gamedata.ActivitySecretShop(self,data)
    for k,v in pairs(data.ids) do
        print(k,v)
    end
    local nowtime = os.date("*t", gamedata:time())
    self.cache.activitySecretShop.freshtime = nowtime

    self.cache.activitySecretShop.itemsdata = {}
    self.cache.activitySecretShop.freshnum = data.ids[1]

    for i=2,12 ,2 do
        print(i)
        table.insert(self.cache.activitySecretShop.itemsdata,{id = data.ids[i], num = data.ids[i+1]})
    end
end

function gamedata.ActivitySafeMaskShop(self,data)
    local onerankdata = {}
    local tworankdata = {}
    local threerankdata = {}
    local fourrankdata = {}
    local fiverankdata = {}

    -- local mozhaoLvdata = {1,1,0,2,1,2,3}
    local mozhaoLvdata = self.cache.safemask
    -- printT(mozhaoLvdata,"mozhaoLvdata===")
    -- printT(gamedata.config.mozhao_break,"mozhao_break===")

    local allspenddata = {}
    for i,v in pairs(mozhaoLvdata) do
        local breakconfig = gamedata.config.mozhao_break[tostring(v.level)]
        -- print("level===",v.level)
        -- print("tablelength---",(table.getTableLength(gamedata.config.mozhao_break)-1))

        if v.level < (table.getTableLength(gamedata.config.mozhao_break)-1) then
            local spenddata = gamedata.getIDandNUMs(breakconfig.lv_cost)
            for ai,av in ipairs(spenddata) do
                -- table.insert(allspenddata,v)
                allspenddata[tostring(av.cid)] = i
            end
        end
    end

    -- printT(allspenddata,"allspenddata===")

    for i,v in ipairs(data) do
        if i > table.getTableLength(gamedata.config.mozhao_shop) then
            break
        end
        -- print("safemask===id===",i,v)
        local tempconfig = gamedata.config.mozhao_shop
        local rewarddata = gamedata.getIDandNUMs(tempconfig[tostring(i)].reward)
        local temp = {}
        temp.num = v
        temp.id = i
        if allspenddata[tostring(rewarddata[1]["cid"])]  then
            -- 该材料被需要
            temp.status = 1
        else
            temp.status = 0
        end
        if tempconfig[tostring(i)].type == 1 then
            table.insert(onerankdata,temp)
        elseif tempconfig[tostring(i)].type == 2 then
            table.insert(tworankdata,temp)
        elseif tempconfig[tostring(i)].type == 3 then
            table.insert(threerankdata,temp)
        elseif tempconfig[tostring(i)].type == 4 then
            table.insert(fourrankdata,temp)
        elseif tempconfig[tostring(i)].type == 5 then
            table.insert(fiverankdata,temp)
        end
        self.cache.safemaskshop.onerankdata = onerankdata
        self.cache.safemaskshop.tworankdata = tworankdata
        self.cache.safemaskshop.threerankdata = threerankdata
        self.cache.safemaskshop.fourrankdata = fourrankdata
        self.cache.safemaskshop.fiverankdata = fiverankdata
    end

end



function gamedata.ActivityRobShop(self,data)
    for k,v in pairs(data.ids) do
        print(k,v)
    end
    self.cache.activityRobShop.itemsdata = {}
    print("activityRobShop==")
    for i=1,16 ,3 do
        print(i)
        table.insert(self.cache.activityRobShop.itemsdata,{cid = data.ids[i], num = data.ids[i+1], buynum = data.ids[i+2]})
    end
end


function gamedata.ActivityExchange(self,data)
    self.cache.activityExchange.resetTime = data.ids[1] or 0
    print(data.ids[1])
    self.cache.activityExchange.items = {}
    for k,v in ipairs(data.ids) do
        if math.mod(k,2) == 0 and k > 1 then 
            table.insert(self.cache.activityExchange.items,{})
            self.cache.activityExchange.items[math.floor(k/2)].index =  math.floor(k/2) or 0
            self.cache.activityExchange.items[math.floor(k/2)].id =  data.ids[k] or 0
        elseif k > 1 then  
            self.cache.activityExchange.items[math.floor(k/2)].num =  data.ids[k] or 0
        end        
    end

end


function gamedata.ActivityWatchStar(self,data)

    self.cache.activityWatchStar = {}
    self.cache.activityWatchStar.starstatus = {}
    self.cache.activityWatchStar.rewardstatus = {}
    self.cache.activityWatchStar.rewardlevel = 1
    self.cache.activityWatchStar.starnum = 0
    self.cache.activityWatchStar.forecastnum = 0
    self.cache.activityWatchStar.changenum = 0

    for k,v in ipairs(data.ids) do
        if k == 1 then -- 星辰数量
            self.cache.activityWatchStar.starnum = v or 0
        elseif k == 2 then -- 已观星次数
            self.cache.activityWatchStar.forecastnum = v or 0
        elseif k == 3 then -- 换星的次数
            self.cache.activityWatchStar.changenum = v or 0
        elseif k == 22 then -- 奖励档位
            self.cache.activityWatchStar.rewardlevel = v or 1
        elseif k < 12 then -- 每颗星的状态
            table.insert(self.cache.activityWatchStar.starstatus,v)
        else -- 奖励的状态
            table.insert(self.cache.activityWatchStar.rewardstatus,v)
        end
    end

end

function gamedata.ActivityMonthGrowQuery(self, data)
    self.cache.activityMonthGrowQuery = {}
    self.cache.activityMonthGrowQuery.activationBtnStatus1 = data.ids[1] or 0
    self.cache.activityMonthGrowQuery.receiveDay1 = data.ids[2] or 0
    self.cache.activityMonthGrowQuery.activationBtnStatus2 = data.ids[3] or 0
    self.cache.activityMonthGrowQuery.receiveDay2 = data.ids[4] or 0
end

function gamedata.ActivityMonthGrowWelfareQuery(self, data)
    self.cache.activityMonthGrowGetReward = {}
    self.cache.activityMonthGrowGetReward.btnStatus1 = data.ids[1] or 0
    -- self.cache.activityMonthGrowGetReward.receiveNum1 = data.ids[2] or 0
    self.cache.activityMonthGrowGetReward.btnStatus2 = data.ids[2] or 0
    -- self.cache.activityMonthGrowGetReward.receiveNum2 = data.ids[4] or 0
end

--神奇基金
function gamedata.ActivityMonthGrowMagicQuery(self, data)
    self.cache.activityMonthGrowMagicQuery = {}
    self.cache.activityMonthGrowMagicQuery.status = data.ids[1] or 0  --活动状态
    self.cache.activityMonthGrowMagicQuery.activationBtnStatus1 = data.ids[2] or 0 --30元基金状态
    self.cache.activityMonthGrowMagicQuery.activationBtnStatus2 = data.ids[3] or 0 --198元基金状态
    self.cache.activityMonthGrowMagicQuery.btnStatus1 = data.ids[4] or 0 --30元基金当天领取状态
    self.cache.activityMonthGrowMagicQuery.btnStatus2 = data.ids[5] or 0 --198元基金当天领取状态
    self.cache.activityMonthGrowMagicQuery.receiveDay1 = data.ids[6] and (data.ids[6]-1) or 0 --30元基金领取天数
    self.cache.activityMonthGrowMagicQuery.receiveDay2 = data.ids[7] and (data.ids[7]-1) or 0 --198元基金领取天数
end

function gamedata.GangGuardData(self,data)

    if not self.cache.gangGuard then  self.cache.gangGuard = {} end
    self.cache.gangGuard.highScore = data[1] and data[1] or 0   --最高分
    self.cache.gangGuard.totalScore = data[2] and data[2] or 0  --今日总积分
    self.cache.gangGuard.gametime = data[3] and data[3] or 0    --今日游戏次数
    self.cache.gangGuard.guildLv = data[4] and data[4] or 0    --公会等级

    self.cache.gangGuard.boxstatus = {}      --宝箱状态
    for i=1,5 do
        self.cache.gangGuard.boxstatus[tostring(i)] =  data[4+i] and data[4+i] or 0 
    end

end

function gamedata.ActivityShare(self, data)
    self.cache.activityShare = {}
    for i = 1, #data, 2 do --cid = data.ids[i], num = data.ids[i+1]
        table.insert(self.cache.activityShare, {task = data[i], status = data[i+1]})
    end
end

function gamedata.ActivityTreasure(self, data)
    self.cache.activityTreasure = {}
    for i = 1, #data, 2 do --cid = data.ids[i], num = data.ids[i+1]
        table.insert(self.cache.activityTreasure, {num = data[i], status = data[i+1]})
    end

end

function gamedata.ActivityTreasureX1(self, data)
    self.cache.activityTreasureX1 = {}
    for i = 1, #data, 2 do --cid = data.ids[i], num = data.ids[i+1]
        table.insert(self.cache.activityTreasureX1, {num = data[i], status = data[i+1]})
    end

end

function gamedata.ActivityTreasureX2(self, data)
    self.cache.activityTreasureX2 = {}
    for i = 1, #data, 2 do --cid = data.ids[i], num = data.ids[i+1]
        table.insert(self.cache.activityTreasureX2, {num = data[i], status = data[i+1]})
    end

end

function gamedata.ActivityTreasureX3(self, data)
    self.cache.activityTreasureX3 = {{},{},{},{},{}}
    for i=1,5 do
        if data and data[i] then
            -- printT(data[i],"data[i]")
            for k,v in ipairs(data[i]) do
                -- print("i",i,"k:",k," v:",v)
                self.cache.activityTreasureX3[i][k] = {num = data[i][k], isshow = 0,order = 0,ids = 0}
            end
        end    
    end
    -- printT(self.cache.activityTreasureX3,"gamedata.activityTreasureX3")
end

function gamedata.Mammon(self,data)
    for k,v in ipairs(data.ids) do
        table.insert(self.cache.mammon,v)
    end
end

function gamedata.Mammon2(self,data)
    for k,v in ipairs(data.ids) do
        table.insert(self.cache.mammon2,v)
    end
end

function gamedata.SignIn(self,data)

    self.cache.signin.days = {}
    for k,v in ipairs(data.ids) do
        --print("signinstatus",k,v)
        if k == 1 then
            self.cache.signin.resign = v
        else
            table.insert(self.cache.signin.days,v)
        end
    end
end

function gamedata.SignIn2(self,data)
    self.cache.signin2 = {}
    self.cache.signin2.daynum = data.ids[1] or 0
    self.cache.signin2.status = data.ids[2] or 0

end

function gamedata.LuxurySignInStatus(self, data)
    self.cache.luxurySignInStatus = {}
    self.cache.luxurySignInStatus.status = data.ids[1] or 0
    self.cache.luxurySignInStatus.itemId1 = data.ids[2] or 0
    self.cache.luxurySignInStatus.itemNum1 = data.ids[3] or 0
    self.cache.luxurySignInStatus.itemId2 = data.ids[4] or 0
    self.cache.luxurySignInStatus.itemNum2 = data.ids[5] or 0
    self.cache.luxurySignInStatus.itemId3 = data.ids[6] or 0
    self.cache.luxurySignInStatus.itemNum3 = data.ids[7] or 0
    self.cache.luxurySignInStatus.itemId4 = data.ids[8] or 0
    self.cache.luxurySignInStatus.itemNum4 = data.ids[9] or 0
end

function gamedata.taskData(self,data)
    return {
        cid= data.cid,
        status= (data.status == 2 and -1 or data.status),
        now= data.now,
    }
end

function gamedata.Task(self,data)

    for k,v in ipairs(data.tasks) do
         self.cache.task[v.cid] = self:taskData(v)
    end
end

function gamedata.Penglai3(self,data)

    self.cache.penglai3.count = data[1] or 0
    self.cache.penglai3.map = data[2] or 1
    self.cache.penglai3.dice = data[3] or 0
    self.cache.penglai3.battle = data[4] or 0
    self.cache.penglai3.reward = data[5] or 0
    self.cache.penglai3.location = data[6] or 1
    self.cache.penglai3.status = {}
    for i = 1,31 do
        table.insert(self.cache.penglai3.status,data[i+6] or 0)
    end

end

function gamedata.Penglai(self,data)

    self.cache.penglai.difficulty = data.difficulty
    self.cache.penglai.presection = data.presection
    self.cache.penglai.nowsection = data.nowsection
    self.cache.penglai.nextsection = data.nextsection
    self.cache.penglai.pos = data.pos
    self.cache.penglai.point = data.point
    self.cache.penglai.pointtotal = data.pointtotal
    self.cache.penglai.status = data.status

end

function gamedata.IslandCommom(self,data)
    self.cache.island.Dayfreenum = data[1]
    self.cache.island.PointWeek = data[2]
    self.cache.island.PointDay = data[3]
    self.cache.island.buffer = data[4]
    self.cache.island.prelocation = data[5]
    self.cache.island.location = data[6]
    self.cache.island.status = data[7]
    self.cache.island.restPoints = data[8]
    self.cache.island.rewardStatus = data[9]
end

function gamedata.Island(self,data)

    self:IslandCommom(data)

    self.cache.island.mapStatus = {}
    for i=1,50 do
        self.cache.island.mapStatus[i] = {}
        self.cache.island.mapStatus[i].type = data[9+(i-1)*3+1]
        self.cache.island.mapStatus[i].param = data[9+(i-1)*3+2]
        self.cache.island.mapStatus[i].status = data[9+(i-1)*3+3]
    end

    self.cache.island.totalRewardStatus = {}
    for i=310,319 do
        table.insert(self.cache.island.totalRewardStatus,data[i])
    end
end

function gamedata.IslandTask(self,data)
    self.cache.island.task = {}
    for k,v in ipairs(data.tasks) do
        table.insert(self.cache.island.task,self:taskData(v))
    end
end

function gamedata.IslandGlobal(self,data)
    self.cache.island.global = {}
    for k,v in ipairs(data) do
        if k==1 then
            self.cache.island.globalpoint = v
        else
            table.insert(self.cache.island.global,v)
        end
    end
end

function gamedata.rankreward(self,data)
    self.cache.athletics.rankRewardStatus = {}
    for k,v in ipairs(data) do
        table.insert(self.cache.athletics.rankRewardStatus,v)
    end
end

function gamedata.IslandRank(self,data)
    self.cache.island.rank  = gamedata:players(data)
end

function gamedata.Liveness(self,data)
    self.cache.liveness.items = {}

    local totalnum = #data.items/2

    for k,v in ipairs(data.items) do
        --print("liveness",k,v)
        if k <= totalnum then
            table.insert(self.cache.liveness.items,{status = v})
        else
            self.cache.liveness.items[k-totalnum].num = v
        end
    end

    self.cache.liveness.reward = {}
    for k,v in ipairs(data.rewards) do
        table.insert(self.cache.liveness.reward,v)
    end
end

function gamedata.WorldBossData(self,data)
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec
    local worldbossdata =  {
        status =  data.status,
        damage =  data.damage or 0,
        kill =  data.kill or 0,
        cd =  data.cd or 0,
        damagesum =  data.damagesum or 0,
        bosshp =  data.bosshp or 0,
        bosslevel =  data.bosslevel or 0,
        attackcount = data.attackcount,
        ranks = {},
        timestatusnum = nowtimesec
    }

    for k,v in ipairs(data.ranks) do
        table.insert(worldbossdata.ranks,self:playerwithgeneralsdata(v))
    end

    return worldbossdata
end

function gamedata.WorldBossRankData(self,worldbossrankData)
    self.cache.worldbossrank.ranks = {}
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    for k,v in ipairs(worldbossrankData.ranks) do
        table.insert(self.cache.worldbossrank.ranks,gamedata:playerwithgeneralsdata(v))
    end

    self.cache.worldbossrank.kill = gamedata:playerwithgeneralsdata(worldbossrankData.kill)
    self.cache.worldbossrank.time = worldbossrankData.time
    self.cache.worldbossrank.timestatusnum = nowtimesec
end

function gamedata.WorldBossRankData2(self,worldbossrankData)
    self.cache.worldbossrank2.ranks = {}
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    for k,v in ipairs(worldbossrankData.ranks) do
        table.insert(self.cache.worldbossrank2.ranks,gamedata:playerwithgeneralsdata(v))
    end

    self.cache.worldbossrank2.kill = gamedata:playerwithgeneralsdata(worldbossrankData.kill)
    self.cache.worldbossrank2.time = worldbossrankData.time
    self.cache.worldbossrank2.timestatusnum = nowtimesec
    
end


function gamedata.GuildWarInspire(self,data)

    self.cache.GuildWarInspire = {}

    self.cache.GuildWarInspire.status = data[1] or 0
    self.cache.GuildWarInspire.coinInspireTimes = data[2] or 0
    self.cache.GuildWarInspire.goldInspireTimes = data[3] or 0
    self.cache.GuildWarInspire.atkBuff = data[4] or 0
    self.cache.GuildWarInspire.defBuff = data[5] or 0
    self.cache.GuildWarInspire.winMax = data[6] or 0

end

function gamedata.GuildWarPrepare(self,data)

    self.cache.GuildWarPrepare = {}

    self.cache.GuildWarPrepare.status = data[1] and data[1].i or 0
    self.cache.GuildWarPrepare.time = data[2] and data[2].i or 0
    self.cache.GuildWarPrepare.keepGid = data[3] and data[3].i or 0
    self.cache.GuildWarPrepare.keepName = data[3] and data[3].s or ""
    self.cache.GuildWarPrepare.attackGid = data[4] and data[4].i or 0
    self.cache.GuildWarPrepare.attackName = data[4] and data[4].s or ""

end

function gamedata.GuildStandingsShow(self, data, index)

    self.cache.GuildStandingsShow[tostring(index)] = {}

    self.cache.GuildStandingsShow[tostring(index)].fightId = data[1] and data[1].i or 0
    self.cache.GuildStandingsShow[tostring(index)].guildId1 = data[2] and data[2].i or 0
    self.cache.GuildStandingsShow[tostring(index)].guildName1 = data[2] and data[2].s or ""
    self.cache.GuildStandingsShow[tostring(index)].status1 = data[3] and data[3].i or 0
    self.cache.GuildStandingsShow[tostring(index)].guildId2 = data[4] and data[4].i or 0
    self.cache.GuildStandingsShow[tostring(index)].guildName2 = data[4] and data[4].s or ""  
    self.cache.GuildStandingsShow[tostring(index)].status2 = data[5] and data[5].i or 0
end

function gamedata.GuildStandingsRoleShow(self, data, index)
    self.cache.GuildStandingsRoleShow[tostring(index)] = {}

    self.cache.GuildStandingsRoleShow[tostring(index)].id = index
    self.cache.GuildStandingsRoleShow[tostring(index)].fightId = data[1] and data[1].i or 0
    self.cache.GuildStandingsRoleShow[tostring(index)].battleId1 = data[2] and data[2].i or 0
    self.cache.GuildStandingsRoleShow[tostring(index)].battleName1 = data[2] and data[2].s or 0
    self.cache.GuildStandingsRoleShow[tostring(index)].battleId2 = data[3] and data[3].i or 0
    self.cache.GuildStandingsRoleShow[tostring(index)].battleName2 = data[3] and data[3].s or 0    
end

function gamedata.GuildWarMembers(self,data)

    if data[1] and data[1].i then

        self.cache.GuildWarMembers[data[1].i] = {}
        self.cache.GuildWarMembers[data[1].i].attackMembers = {}
        self.cache.GuildWarMembers[data[1].i].keepMembers = {}

        for k,v in ipairs(data) do
            if k > 1 and math.mod(k,3) == 1 then
                local member = {}
                member.rid = data[k-2].i or 0
                member.name = data[k-2].s or ""
                member.profile = data[k-1].i or 0
                member.pos = data[k].i or 0
                if member.pos > 1 then
                    table.insert(self.cache.GuildWarMembers[data[1].i].attackMembers,member)
                else
                    table.insert(self.cache.GuildWarMembers[data[1].i].keepMembers,member)
                end
            end
        end

    end
end


function gamedata.FavoriteCheck(self,data)

    self.cache.favoritegeneral = {}
    print("FavoriteCheck==")

    self.cache.favoritegeneral.cid = data[1]
    self.cache.favoritegeneral.favoriteExp = data[2]
    self.cache.favoritegeneral.favoriteLevel = data[3]
    self.cache.favoritegeneral.hp = data[4]
    self.cache.favoritegeneral.atk = data[5]
    self.cache.favoritegeneral.def = data[6]
    self.cache.favoritegeneral.speed = data[7]
    self.cache.favoritegeneral.critical = data[8]
    self.cache.favoritegeneral.dodge = data[9]
    self.cache.favoritegeneral.parry = data[10]
    self.cache.favoritegeneral.resilience = data[11]
    self.cache.favoritegeneral.hit = data[12]
    self.cache.favoritegeneral.arp = data[13]
    self.cache.favoritegeneral.criticaldmg = data[14]
    self.cache.favoritegeneral.aadddmg = data[15]
    self.cache.favoritegeneral.asubdmg = data[16]
    self.cache.favoritegeneral.radddmg = data[17]
    self.cache.favoritegeneral.rsubdmg = data[18]
end

function gamedata.Cave(self,data)

    self.cache.cave = {
        forecast = data.forecast,
        reward = data.reward,
        reversion = data.reversion,
        position = {},
        position2 = {},
    }

    for k,v in ipairs(data.position) do
        table.insert(self.cache.cave.position,v)
    end

    for k,v in ipairs(data.position2) do
        table.insert(self.cache.cave.position2,v)
    end
end

function gamedata.GeneralCollect(self,data)
    for k,v in ipairs(data.idnums) do
        self.cache.generalcollect[v.id] = v.num
    end
end

function gamedata.EquipCollect(self,data)
    for k,v in ipairs(data.idnums) do
        self.cache.equipcollect[v.id] = v.num
    end
end

function gamedata.TeamRecomQuery(self, data)
    self.cache.teamRecomQuery = {}
    for k,v in ipairs(data.ids) do
        table.insert(self.cache.teamRecomQuery, v)
    end    
end

function gamedata.SingleBoss(self,data)
    self.cache.singleBoss.battlenum = data.ids[1] or 0
    self.cache.singleBoss.bosstype = data.ids[2] or 1
    self.cache.singleBoss.isFirst = data.ids[3] or 0
    self.cache.singleBoss.openlevel = data.ids[4] or 0  
    self.cache.singleBoss.curblood = data.ids[5] or 100
end

function gamedata.Cornucopia(self,ids)
    self.cache.cornucopia.ad = ids[1] or 0
    self.cache.cornucopia.count = ids[2] or 0
    self.cache.cornucopia.box1 = ids[3] or 0
    self.cache.cornucopia.box2 = ids[4] or 0
    self.cache.cornucopia.box3 = ids[5] or 0
end

function gamedata.magic(self,data)
    local length = #data
    print(length.." magic")
    self.cache.magicdata.lock = {}
    self.cache.magicdata.unlock = {}
    self.cache.magicdata.lock.id =  data[length - 10] or 0 --如果id == 0表示全部解锁 后面数据无效
    self.cache.magicdata.lock.task1Num =   data[length - 9] or 0
    self.cache.magicdata.lock.task1Complete =   data[length - 8] or 0
    self.cache.magicdata.lock.task2Num =   data[length - 7] or 0
    self.cache.magicdata.lock.task2Complete =   data[length - 6] or 0
    self.cache.magicdata.lock.task3Num =   data[length - 5] or 0
    self.cache.magicdata.lock.task3Complete =   data[length - 4] or 0
    self.cache.magicdata.lock.task4Num =   data[length - 3] or 0
    self.cache.magicdata.lock.task4Complete =   data[length - 2] or 0
    self.cache.magicdata.lock.task5Num =   data[length - 1] or 0
    self.cache.magicdata.lock.task5Complete =   data[length] or 0   
    local index = 1
    while true do
        if not data[index + 11]  then return end
        if index % 10 == 1 then
            local t = {}
            t.id = data[index] or 0
            t.attr1 = data[index + 1] or 0
            t.attr2 = data[index + 2] or 0
            t.attr3 = data[index + 3] or 0
            t.attr4 = data[index + 4] or 0
            t.istupo = data[index + 5] or 0
            t.attr5 = data[index + 6] or 0
            t.attr6 = data[index + 7] or 0
            t.attr7 = data[index + 8] or 0
            t.attr8 = data[index + 9] or 0
            -- if t.id == 1 then
            --      t.istupo = 0
            -- else
            --      t.istupo = -1
            -- end  
            -- t.istupo = 0

            -- t.attr5 = 0
            -- t.attr6 = 0
            -- t.attr7 = 0
            -- t.attr8 = 0

            table.insert(self.cache.magicdata.unlock,t)
        end
        index = index + 1 
    end
     --10个yi zu

end
function gamedata.MagicPreview(self,data)
    self.cache.magicPreview = {
        data[1] or 0,
        data[2] or 0,
        data[3] or 0,
        data[4] or 0,
    }
end


function gamedata.mazeShop(self,data)
    self.cache.mazeShop.refeshTimes = data[1] or 0
    self.cache.mazeShop.items = {}
    local index = 1
    while true do
        index = index + 1
        if data[index] == nil then break end
        if index%2 == 0 then
            local t = {}
            t.id = data[index] or 1
            t.buyTimes = data[index + 1] or 0
            table.insert(self.cache.mazeShop.items,t)
        end
    end
end

function gamedata.mazeReward(self,data)
    print("gamedata.mazeReward =============")
    local tReward = {}
    for k,v in pairs( gamedata.config.maze_task ) do
        tReward[k] = {}
        for m,n in pairs(v) do 
            local t = {}
            t.state = 0
            for i,j in pairs(n) do 
                t[i] = j
            end
            t.state = 0
            tReward[k][m] = t
        end  
    end
    -- printT(tReward)
    local i = 1
    while true do
        if data[i] == nil then break end
        if i%3 == 1 then
            tReward[tostring(data[i ] or 1)][tostring(data[i + 1] or 1)].state = data[i + 2] or 0
        end
        i = i + 1
    end  
    self.cache.mazeReward = {}
    for k,v in pairs(tReward) do
        for m,n in pairs(v) do
            table.insert(self.cache.mazeReward,n)
        end
    end
    -- printT(self.cache.mazeReward)
    table.sort(self.cache.mazeReward,function(a,b)
        if a.state == 1 and b.state ~= 1 then
            return true
        elseif  a.state ~= 1 and b.state == 1  then
            return false
        elseif a.state == 0 and b.state == 2 then
            return true
        elseif a.state == 2 and b.state == 0 then
            return false
        elseif a.type > b.type then
            return false
        elseif a.type < b.type then
            return true
        elseif a.id >b.id then
            return false
        else
            return true
        end
    end)    
end

function gamedata.CommonSlots(self,data)
    local slots = {generals={}}

    for k,v in ipairs(data.ids) do
        if k==8 then
            slots.pet = v
        elseif k==9 then
            slots.power = v
        elseif k<=7 then
            slots.generals[k] = v
        end
    end
    self.cache.commonSlots[data.ids[10]..data.ids[11]] = slots

    return data.ids[10],data.ids[11]
end

function gamedata.SetSlotsEnemy(self,data)

    -- if data then
    --     gang2.id = data[1] and data[1].i or 0
    --     gang2.name = data[2] and data[2].s or ""
    --     gang2.level = data[3] and data[3].i or 0
    --     gang2.num = data[4] and data[4].i or 0
    --     gang2.leadername = data[5] and data[5].s or ""
    --     gang2.declaration = data[6] and data[6].s or ""
    --     gang2.power = data[7] and data[7].i or 0
    --     gang2.param = data[8] and data[8].i or 0
    -- end


    -- slotsEnemy = {}
    self.ext.slotArrangeId = data[1] and data[1].i or 0
    self.cache.slotsEnemy.id = data[1] and data[1].i or 0
    self.cache.slotsEnemy.resetNum = data[2] and data[2].i or 0
    self.cache.slotsEnemy.power = data[3] and data[3].i or 0
    self.cache.slotsEnemy.petcid = data[4] and data[4].i or 0
    self.cache.slotsEnemy.petlevel = data[5] and data[5].i or 0

    local slot = {}

    for k,v in ipairs(data) do
        print("kkkkk===",k,v)
        if data[k*4+2] then
            print("k*4===",data[k*4+2])
        end
        if data[k*4+2] then
            local temp = {}
            temp.cid = data[k*4+2] and data[k*4+2].i or 0
            if temp.cid >=10101 and temp.cid <= 10199 then
                temp.name = data[k*4+2] and data[k*4+2].s or ""
            end
            temp.level = data[k*4+3] and data[k*4+3].i or 0
            temp.hppercent = data[k*4+4] and data[k*4+4].i or 0
            temp.stage = data[k*4+5] and data[k*4+5].i or 0
            table.insert(slot,temp)
        end
    end
    self.cache.slotsEnemy.slot = slot
end

function gamedata.CommonSlotsWithHp(self,data)
    self.cache.commonSlotsWithHp.slots = {}
    self.cache.commonSlotsWithHp.generalsdata = {}
    local generals = {}
    local hpArr = {}
    local generalsdata = {}

    for k,v in ipairs(data) do
        print("kkkk=k==",k,v)
        if k==1 then
            self.cache.commonSlotsWithHp.slots.power = v
        elseif k==2 then
            self.cache.commonSlotsWithHp.slots.pet = v
        elseif math.mod(k,2) == 1 then
            if k < 17 then
                table.insert(generals,v)
                if hpArr[v] == nil then
                    hpArr[v] = {}
                end
                hpArr[v] = data[k+1]
            end
            

            if v ~= 0 and self.cache.generals[v] then
                generalsdata[v] = self.cache.generals[v]
                print("vvvvv=",v)
                -- printT(self.cache.generals[v])
                -- printT(data[k+1])
                generalsdata[v].hppercent = data[k+1]
            elseif v ~= 0 and v == self.cache.protagonist.general.iid then
                print("vvvvv=22222",v)
                -- printT(self.cache.protagonist.general.iid)
                -- printT(data[k+1])
                generalsdata[v] = self.cache.protagonist.general
                generalsdata[v].hppercent = data[k+1]
            end
        end
    end
    self.cache.commonSlotsWithHp.slots.generals = generals
    self.cache.commonSlotsWithHp.slots.hpArr = hpArr
    self.cache.commonSlotsWithHp.generalsdata = generalsdata
end

function gamedata.StarCopyMapData(self,data)
    if data[1] and data[1]>0 then
        local mapdata = {}
        mapdata.mapid = data[1]
        mapdata.status = data[2] or 0
        mapdata.section = gamedata.config.star_map[tostring(mapdata.mapid)].section-40000
        mapdata.points = {}
        for k,v in ipairs(data) do
            if k > 2 and math.mod(k,3) == 0 then
                local point = {}
                point.pointid = data[k] or 0
                point.pointstatus = data[k+1] or -1
                point.boxstatus = data[k+2] or 0
                mapdata.points[tostring(point.pointid)] = point
            end
        end
        if self.cache.starcopy.sections[tostring(mapdata.section)] then
            local has = false
            for k,v in pairs(self.cache.starcopy.sections[tostring(mapdata.section)]) do
                if v.mapid == mapdata.mapid then
                    self.cache.starcopy.sections[tostring(mapdata.section)][k] = mapdata
                    has = true
                end
            end
            if not has then
                self.cache.starcopy.sections[tostring(mapdata.section)][tostring(table.getTableLength(self.cache.starcopy.sections[tostring(mapdata.section)])+1)] = mapdata
            end
        else
            self.cache.starcopy.sections[tostring(mapdata.section)] = {}
            self.cache.starcopy.sections[tostring(mapdata.section)]["1"] = mapdata
        end
    end
end

function gamedata.HadesCopyMapData(self,data)
    if data[1] and data[1]>0 then
        local mapdata = {}
        mapdata.mapid = data[1]
        mapdata.status = data[2] or 0
        mapdata.mapbox = data[3] or 0
        mapdata.section = gamedata.config.hades_map[tostring(mapdata.mapid)].section-40000
        mapdata.points = {}
        for k,v in ipairs(data) do
            if k > 3 and math.mod(k,3) == 1 then
                local point = {}
                point.pointid = data[k] or 0
                point.pointstatus = data[k+1] or -1
                point.boxstatus = data[k+2] or 0
                mapdata.points[tostring(point.pointid)] = point
            end
        end
        if self.cache.hadescopy.sections[tostring(mapdata.section)] then
            local has = false
            for k,v in pairs(self.cache.hadescopy.sections[tostring(mapdata.section)]) do
                if v.mapid == mapdata.mapid then
                    self.cache.hadescopy.sections[tostring(mapdata.section)][k] = mapdata
                    has = true
                end
            end
            if not has then
                self.cache.hadescopy.sections[tostring(mapdata.section)][tostring(table.getTableLength(self.cache.hadescopy.sections[tostring(mapdata.section)])+1)] = mapdata
            end
        else
            self.cache.hadescopy.sections[tostring(mapdata.section)] = {}
            self.cache.hadescopy.sections[tostring(mapdata.section)]["1"] = mapdata
        end
    end
end

function gamedata.MazeStatus(self,data)
    self.cache.maze = {}
    self.cache.maze.reset = data[1] or 0
    self.cache.maze.event_type = data[2] or 0
    self.cache.maze.position = data[3] or 0
    self.cache.maze.event_id = data[4] or 0
    self.cache.maze.event_param1 = data[5] or 0
    self.cache.maze.event_param2 = data[6] or 0
    self.cache.maze.event_param3 = data[7] or 0
    self.cache.maze.event_param4 = data[8] or 0
    self.cache.maze.buff_global = data[9] or 0
    self.cache.maze.buff_temp = data[10] or 0
end
--

function gamedata.passKillGeneralsDate( self,data )
    for i,v in ipairs(data) do
        print("data====data",i,v.i,v.s)
    end
    self.cache.passkill.generals = {}
    local generalsdata = {}
    if data then
        for i=1,3 do
            generalsdata["generalrid"..i] = data[(i-1)*6+1] and data[(i-1)*6+1].i or 0
            generalsdata["generalcid"..i] = data[(i-1)*6+2] and data[(i-1)*6+2].i or 0
            generalsdata["generalname"..i] = data[(i-1)*6+2] and data[(i-1)*6+2].s or ""
            generalsdata["generalpower"..i] = data[(i-1)*6+3] and data[(i-1)*6+3].i or 0
            generalsdata["generalstatus"..i] = data[(i-1)*6+4] and data[(i-1)*6+4].i or 0
            generalsdata["generalwing_level"..i] = data[(i-1)*6+5] and data[(i-1)*6+5].i or 0
            generalsdata["generalwing_color"..i] = data[(i-1)*6+6] and data[(i-1)*6+6].i or 0
        end
    end

    self.cache.passkill.generals = generalsdata
end

function gamedata.passKillBasicDate( self,data )
    self.cache.passkill.basic = {}
    local basicdata = {}
    if data then
        basicdata.boxstatus1 = data[1] or 0
        basicdata.boxstatus2 = data[2] or 0
        basicdata.boxstatus3 = data[3] or 0

        basicdata.victorynum = data[4] or 0
        basicdata.resetnum = data[5] or 0
        basicdata.fightnum = data[6] or 0
        basicdata.killcoinnum = data[7] or 0
        basicdata.killscorenum = data[8] or 0
    end
    self.cache.passkill.basic = basicdata
end

function gamedata.passKillShopDate( self,data )
    self.cache.passkillshop.exchanged = {}
    if data then
        self.cache.passkillshop.killcoinnum = data[1] or 0
        self.cache.passkillshop.changenum = data[2] or 0
        --
        for i,v in ipairs(data) do
            if i > 2 then
                if math.mod(i,2) == 1 then
                    local tempconfig = gamedata.config.through_shop[tostring(data[i])]
                    local tempdata  = {}
                    tempdata.id = tempconfig.id
                    tempdata.num = tempconfig.limit - (data[i+1] or 0)
                    table.insert(self.cache.passkillshop.exchanged,tempdata)
                end
            end
        end
    end
end


function gamedata.TurntableData( self,data )
    self.cache.turntable = {}
    self.cache.turntable.lotteryNums = data[1] or 0
    self.cache.turntable.goldNums = data[2] or 0
    self.cache.turntable.lotteryFreeUsed = data[3] or 0
end

function gamedata.k_TurntableData( self,data )
    self.cache.k_turntable = {}
    self.cache.k_turntable.lotteryNums = data[1] or 0
    self.cache.k_turntable.goldNums = data[2] or 0
    self.cache.k_turntable.lotteryFreeUsed = data[3] or 0
end

function gamedata.CarnivalData( self,data )
    self.cache.carnival = {}
    self.cache.carnival.lotteryStatus = data[1] or 1
    self.cache.carnival.lotteryNums = data[2] or 0
end

function gamedata.IntegralTurntableData( self,data )
    self.cache.integralturntable = {}
    self.cache.integralturntable.lotteryScore = data[1] or 1
    self.cache.integralturntable.lotteryNums = data[2] or 0
end

function gamedata.duanwunlunpanData( self,data )
    self.cache.duanwunlunpan.main = {}
    self.cache.duanwunlunpan.main.pointScore = data[1] or 0
    self.cache.duanwunlunpan.main.lotteryNums = data[2] or 0
    self.cache.duanwunlunpan.main.lotteryFreeUsed = data[3] or 0
end

function gamedata.wudaohuiData( self,data )
    self.cache.wudaohui.main = {}
    self.cache.wudaohui.main.teamnum = data[1] or 0
    self.cache.wudaohui.main.fightnum = data[2] or 0
    self.cache.wudaohui.main.victorynum = data[3] or 0
    self.cache.wudaohui.main.teamscore1 = data[4] or 0
    self.cache.wudaohui.main.teamscore2 = data[5] or 0
    self.cache.wudaohui.main.rewardstatue1 = data[6] or 0
    self.cache.wudaohui.main.rewardstatue2 = data[7] or 0
    self.cache.wudaohui.main.rewardstatue3 = data[8] or 0
    self.cache.wudaohui.main.myallscorenum = data[9] or 0
    self.cache.wudaohui.main.nextranknum = data[10] or 0
    self.cache.wudaohui.main.mynowscorenum = data[11] or 0
    self.cache.wudaohui.main.straightvictorynum = data[12] or 0
    self.cache.wudaohui.main.updatetimenum = data[13] or 0
    self.cache.wudaohui.main.pipeiupdatetimenum = data[14] or 0
    self.cache.wudaohui.main.hintstatus = data[15] or 0

end


function gamedata.kingBattleData( self,data )
    self.cache.kingBattle.main = {}
    self.cache.kingBattle.main.score = data[1] or 0
    self.cache.kingBattle.main.myserverRank = data[2] or 0
    self.cache.kingBattle.main.crossServerRank = data[3] or 0
    self.cache.kingBattle.main.challengeNum = data[4] or 0
end


function gamedata.wudaohuiShopData( self,data )
    self.cache.wudaohui.shop = {}
    self.cache.wudaohui.shop.mynowscorenum = data[1] or 0
    self.cache.wudaohui.shop.myallscorenum = data[2] or 0
    self.cache.wudaohui.shop.hintstatus = data[3] or 0
    self.cache.wudaohui.shop.reward = {}

    for i = 1, 8 do
        table.insert(self.cache.wudaohui.shop.reward, data[i + 3])
    end
end
--武道会自己战报动态的数据
function gamedata.wudaohuiReport(self,data)
    if not self.cache.wudaohui.report then self.cache.wudaohui.report = {} end
    self.cache.wudaohui.report[#self.cache.wudaohui.report +1] = {}
    local tt = self.cache.wudaohui.report[#self.cache.wudaohui.report] 
    tt.opt = data[1] and data[1].i or 0
    tt.name = data[2] and data[2].s or ""
    tt.fightnum = data[3] and data[3].i or 0
    tt.mystraightwinnum = data[4] and data[4].i or 0
    tt.otherstraightwinnum = data[5] and data[5].i or 0
end

-- 主角翅膀查询
function gamedata.WingData( self,data )
    self.cache.wing = {}
    self.cache.wing.stagenum = data[1] or 0
    self.cache.wing.starnum = data[2] or 0
    self.cache.wing.exp = data[3] or 0
    self.cache.wing.colortype = data[4] or 0
    self.cache.wing.successpercent = data[5] or 0
    self.cache.wing.expnumtable = nil
    self.cache.wing.expnumtable = {}

    for i,v in ipairs(data) do
        if i > 5 and data[i] then
            table.insert(self.cache.wing.expnumtable,(data[i] or 0))
            -- self.cache.wing["expnum"..i] = data[i] or 0
        end
    end
end
-- 主角翅膀进阶数据
function gamedata.WingStageData( self,data )
    self.cache.wing = {}
    self.cache.wing.stagenum = data[1] or 0
    self.cache.wing.starnum = data[2] or 0
    self.cache.wing.exp = data[3] or 0
    self.cache.wing.colortype = data[4] or 0
    self.cache.wing.successpercent = data[5] or 0
    self.cache.wing.issuccess = data[6] or 0
end


-- 跨服战赛区信息（人 地 天 仙 神)
function gamedata.ServiceWarGroupInfoData( self,data )
    local tempdata = {}
    local ranktypeMy = data[1] and data[1].i or 0

    local teamnum = (table.getTableLength(data) - 1)/3

    local rank1 = {}
    local rank2 = {}
    local rank3 = {}
    local rank4 = {}
    local rank5 = {}
    local mydata = {}
    for i=1,teamnum do
        if data[3*(i)-1] and data[3*(i)-1].i == 1 then
            local temp = {}
            temp.ranktype   = data[3*(i)-1] and data[3*(i)-1].i or 0
            temp.serverid   = data[3*(i)] and data[3*(i)].i or 0
            temp.name       = data[3*(i)+1] and data[3*(i)+1].s or ""

            table.insert(rank1,temp)
        elseif data[3*(i)-1] and data[3*(i)-1].i == 2 then
            local temp = {}
            temp.ranktype   = data[3*(i)-1] and data[3*(i)-1].i or 0
            temp.serverid   = data[3*(i)] and data[3*(i)].i or 0
            temp.name       = data[3*(i)+1] and data[3*(i)+1].s or ""

            table.insert(rank2,temp)
        elseif data[3*(i)-1] and data[3*(i)-1].i == 3 then
            local temp = {}
            temp.ranktype   = data[3*(i)-1] and data[3*(i)-1].i or 0
            temp.serverid   = data[3*(i)] and data[3*(i)].i or 0
            temp.name       = data[3*(i)+1] and data[3*(i)+1].s or ""

            table.insert(rank3,temp)
        elseif data[3*(i)-1] and data[3*(i)-1].i == 4 then
            local temp = {}
            temp.ranktype   = data[3*(i)-1] and data[3*(i)-1].i or 0
            temp.serverid   = data[3*(i)] and data[3*(i)].i or 0
            temp.name       = data[3*(i)+1] and data[3*(i)+1].s or ""

            table.insert(rank4,temp)
        elseif data[3*(i)-1] and data[3*(i)-1].i == 5 then
            local temp = {}
            temp.ranktype   = data[3*(i)-1] and data[3*(i)-1].i or 0
            temp.serverid   = data[3*(i)] and data[3*(i)].i or 0
            temp.name       = data[3*(i)+1] and data[3*(i)+1].s or ""
            temp.division   = data[3*(i)+1] and data[3*(i)+1].i or 0

            table.insert(rank5,temp)
        end

        if data[3*(i)] and ranktypeMy == data[3*(i)].i then
            mydata.ranktype = data[3*(i)-1] and data[3*(i)-1].i or 0
            mydata.serverid = data[3*(i)] and data[3*(i)].i or 0
            mydata.name     = data[3*(i)+1] and data[3*(i)+1].s or ""
            mydata.division = data[3*(i)+1] and data[3*(i)+1].i or 0
        end
    end
    tempdata.rank1 = rank1
    tempdata.rank2 = rank2
    tempdata.rank3 = rank3
    tempdata.rank4 = rank4
    tempdata.rank5 = rank5
    tempdata.mydata = mydata

    return tempdata
end


-- 跨服战历届冠军查询
function gamedata.ServiceWarChampionData( self,data )
    local tempdata = {}
    local arrnum = (table.getTableLength(data))/8

    for i=1,arrnum do
        local temp = {}
        temp.rank = i

        temp.rid            = data[8*(i-1)+1] and data[8*(i-1)+1].i or 0
        temp.name           = data[8*(i-1)+2] and data[8*(i-1)+2].s or ""
        temp.level          = data[8*(i-1)+3] and data[8*(i-1)+3].i or 0
        temp.profile        = data[8*(i-1)+4] and data[8*(i-1)+4].i or 0
        temp.serviceid      = data[8*(i-1)+5] and data[8*(i-1)+5].i or 0
        temp.servicename    = data[8*(i-1)+6] and data[8*(i-1)+6].s or ""
        temp.championnum    = data[8*(i-1)+7] and data[8*(i-1)+7].i or 0
        temp.mobainum       = data[8*(i-1)+8] and data[8*(i-1)+8].i or 0
        table.insert(tempdata,temp)
    end

    return tempdata
end

-- 跨服战下注 基本信息
function gamedata.ServiceWarBetBasicData( self,data )
    local temp = {}
    temp.id = data[1] or 0
    temp.maxbetmoneynum = data[2] or 0
    temp.nowbetmoneynum = data[3] or 0
    temp.petchance1 = data[4] and (data[4]/10) or 0
    temp.petchance2 = data[5] and (data[5]/10) or 0
    temp.petnum1 = data[6] or 0
    temp.petnum2 = data[7] or 0
    temp.petstatus = data[8] or 0

    -- temp.battleid1 = data[8] or 0
    -- temp.battleresult1 = data[9] or 0

    -- temp.battleid2 = data[10] or 0
    -- temp.battleresult2 = data[11] or 0

    -- temp.battleid3 = data[12] or 0
    -- temp.battleresult3 = data[13] or 0

    return temp
end

-- 跨服战下注 玩家信息
function gamedata.ServiceWarBetPlayerData( self,data )

    local temp = {}
    temp.id = data[1] and data[1].i or 0
    temp.rid = data[2] and data[2].i or 0
    temp.name = data[3] and data[3].s or ""
    temp.level = data[4] and data[4].i or 0
    temp.profile = data[5] and data[5].i or 0
    temp.power = data[6] and data[6].i or 0
    temp.server_id = data[7] and data[7].i or 0
    temp.server_name = data[8] and data[8].s or ""
    temp.generals = {}
    local tempnum = math.floor((table.getTableLength(data)-8)/4)
    for i=1,tempnum do
        local tempda = {}
        tempda.cid = data[9+(i-1)*5] and data[9+(i-1)*5].i or 0
        tempda.oldcid = data[10+(i-1)*5] and data[10+(i-1)*5].i or 0
        tempda.level1 = data[11+(i-1)*5] and data[11+(i-1)*5].i or 0
        tempda.level2 = data[12+(i-1)*5] and data[12+(i-1)*5].i or 0
        tempda.level3 = data[13+(i-1)*5] and data[13+(i-1)*5].i or 0
        table.insert(temp.generals,tempda)
    end

    return temp
end

-- 跨服战(观战) 基本信息
function gamedata.ServiceWarWatchBasicData( self,data )
    local temp = {}
    temp.id = data[1] or 0
    -- temp.maxbetmoneynum = data[2] or 0
    -- temp.nowbetmoneynum = data[3] or 0
    -- temp.petchance1 = data[4] and (data[4]/10) or 0
    -- temp.petchance2 = data[5] and (data[5]/10) or 0
    -- temp.petnum1 = data[6] or 0
    -- temp.petnum2 = data[7] or 0

    temp.battleid1 = data[2] or 0
    temp.battleresult1 = data[3] or 0
    temp.position1 = data[4] or 0

    temp.battleid2 = data[5] or 0
    temp.battleresult2 = data[6] or 0
    temp.position2 = data[7] or 0

    temp.battleid3 = data[8] or 0
    temp.battleresult3 = data[9] or 0
    temp.position3 = data[10] or 0

    return temp
end
-- 跨服战(观战) 玩家信息
function gamedata.ServiceWarWatchPlayerData( self,data )

    local temp = {}
    temp.id = data[1] and data[1].i or 0
    temp.rid = data[2] and data[2].i or 0
    temp.name = data[3] and data[3].s or ""
    temp.level = data[4] and data[4].i or 0
    temp.profile = data[5] and data[5].i or 0
    temp.power = data[6] and data[6].i or 0
    temp.server_id = data[7] and data[7].i or 0
    temp.server_name = data[8] and data[8].s or ""

    return temp
end


--天神下凡商店
function gamedata.godDownShopData(self,data)
    -- body
    print("goddownshop")
    self.cache.goddownshop.props = {}
    self.cache.goddownshop.goddownnum = data[1] or 0

    for k,v in ipairs(data) do
        if tonumber(k) > 1 then
            table.insert(self.cache.goddownshop.props,{})
            self.cache.goddownshop.props[k-1].index = k-1
            self.cache.goddownshop.props[k-1].num = data[k]
        end
    end
end

function gamedata.k_godDownShopData(self,data)
    -- body
    print("k_goddownshop")
    self.cache.k_goddownshop.props = {}
    self.cache.k_goddownshop.goddownnum = data[1] or 0

    for k,v in ipairs(data) do
        if tonumber(k) > 1 then
            table.insert(self.cache.k_goddownshop.props,{})
            self.cache.k_goddownshop.props[k-1].index = k-1
            self.cache.k_goddownshop.props[k-1].num = data[k]
        end
    end
end


function gamedata.sortData(data, parm1, parm2, parm3, parm4, parm5, parm6, parm1type, parm2type, parm3type, parm4type, parm5type, parm6type)
    local sortfunc = function (a,b)
        if parm1 == nil then return false end
        if (a[parm1] or 0) > (b[parm1] or 0) then
            return not parm1type
        elseif (a[parm1] or 0) < (b[parm1] or 0) then
            return not not parm1type
        elseif (a[parm1] or 0) == (b[parm1] or 0) then
            if parm2 == nil then return false end
            if (a[parm2] or 0) > (b[parm2] or 0) then
                return not parm2type
            elseif (a[parm2] or 0) < (b[parm2] or 0) then
                return not not parm2type
            elseif (a[parm2] or 0) == (b[parm2] or 0) then
                if parm3 == nil then return false end
                if (a[parm3] or 0) > (b[parm3] or 0) then
                    return not parm3type
                elseif (a[parm3] or 0) < (b[parm3] or 0) then
                    return not not parm3type
                elseif (a[parm3] or 0) == (b[parm3] or 0) then
                    if parm4 == nil then return false end
                    if (a[parm4] or 0) > (b[parm4] or 0) then
                        return not parm4type
                    elseif (a[parm4] or 0) < (b[parm4] or 0) then
                        return not not parm4type
                    elseif (a[parm4] or 0) == (b[parm4] or 0) then
                        if parm5 == nil then return false end
                        if (a[parm5] or 0) > (b[parm5] or 0) then
                            return not parm5type
                        elseif (a[parm5] or 0) < (b[parm5] or 0) then
                            return not not parm5type
                        elseif (a[parm5] or 0) == (b[parm5] or 0) then
                            if parm6 == nil then return false end
                            if (a[parm6] or 0) > (b[parm6] or 0) then
                                return not parm6type
                            elseif (a[parm6] or 0) < (b[parm6] or 0) then
                                return not not parm6type
                            else
                                return false
                            end
                        end
                    end

                end
            end
        end
    end

    table.sort(data,sortfunc)
end

function gamedata.sortDataByOrder(data, parm1, parm2, parm3, parm4)
    local sortfunc = function (a,b)
        if parm1 == nil then return false end
        if a[parm1] < b[parm1] then
            return true
        elseif a[parm1] > b[parm1] then
            return false
        elseif a[parm1] == b[parm1] then
            if parm2 == nil then return false end
            if a[parm2] < b[parm2] then
                return true
            elseif a[parm2] > b[parm2] then
                return false
            elseif a[parm2] == b[parm2] then
                if parm3 == nil then return false end
                if a[parm3] < b[parm3] then
                    return true
                elseif a[parm3] > b[parm3] then
                    return false
                elseif a[parm3] == b[parm3] then
                    if parm4 == nil then return false end
                    return a[parm4] < b[parm4]
                end
            end
        end
    end

    table.sort(data,sortfunc)
end

function gamedata.getIDandNUM(str)
    local i = string.find(str,",") or string.find(str,"，")
    local j = string.find(str,";") or string.find(str,"；")

    print(i,j,"gamedata.getIDandNUM")

    return tonumber(string.sub(str,1,i-1)),tonumber(string.sub(str,i+1,j-1))
end

function gamedata.getIDandData(str)
    local i = string.find(str,",") or string.find(str,"，")
    local j = string.find(str,";") or string.find(str,"；")

    print(i,j,"ui.getIDandData")

    return tostring(string.sub(str,1,i-1)),tonumber(string.sub(str,i+1,j-1))
end

function gamedata.getAttrData(str)
    local i = string.find(str,";") or string.find(str,"；")
    -- local j = string.find(str,";") or string.find(str,"；")

    print(i,"ui.getAttrData")

    return tostring(string.sub(str,1,i-1)),tonumber(string.sub(str,i+1))
end

function gamedata.getAttr2Data(str)
    local i = string.find(str,",") or string.find(str,"，")

    return tostring(string.sub(str,1,i-1)),tonumber(string.sub(str,i+1))
end

function gamedata.getIDandNUMs(datastring)
    if not datastring then return {} end
    local data = {}
    local i = 0
    local j = 0
    while true do
        local b = j + 1
        i = string.find(datastring, ",", i + 1)
        if i == nil then break end
        local a = i + 1
        j = string.find(datastring, ";", j + 1)
        if not j then j = string.len(datastring)+1 end
        table.insert(data, { cid = tonumber(string.sub(datastring, b, i - 1)), num = tonumber(string.sub(datastring, a, j - 1)) })
    end
    return data
end

function gamedata.getIds(datastring)
    if not datastring then return {} end
    local data = {}
    local i = 0
    while true do
        local a = i + 1
        i = string.find(datastring, ",", i + 1)
        if i == nil then break end
        table.insert(data, {string.sub(datastring, a, i - 1)})
    end
    return data
end

function gamedata.groupdata(data,NUM)
    local temp = {}
    local newnum = math.ceil(table.getTableLength(data)/NUM)

    for i=1,newnum do
        temp[i] = {}
        for j=1, NUM do
            if data[NUM*(i-1)+j] then
                temp[i][j] = data[NUM*(i-1)+j]
            end
        end
    end
    return temp
end

function gamedata.getEquipForExchangeNum(cid)
    local config = gamedata.IDconfig(cid)
    local num = {cid = cid }
    if config.staffType == "equip" then
        local equipdata = makeEquipsTemp()
        local equipnum = 0
        for k,v in pairs(equipdata) do
            if (cid == v.cid) and (not v.ison or v.ison == 0) and (v.level1 <= 1) and (v.level2 <= 0) and (v.level3 <= 0) and (v.xcount <= 0) then
                equipnum = equipnum + 1
            end
        end
        num.num = equipnum
    end
    return num
end

function gamedata.getStaffNum(cid,forExchange)
    local config = gamedata.IDconfig(cid)

    local num = {cid = cid}
    if config.staffType == "coin" then
        num.num = gamedata.cache.role.coin
    elseif config.staffType == "gold" then
        num.num = gamedata.cache.role.gold
    elseif config.staffType == "g_gold" then
        num.num = gamedata.cache.role.g_gold
    elseif config.staffType == "red_fragment" then
        if gamedata.cache.redfragment[cid] then
            num.num = gamedata.cache.redfragment[cid].num or 0
        else
            num.num = 0
        end
    elseif config.staffType == "general_fragment" then
         if gamedata.cache.generalfragments[config.generalid] then
             num = table.copy(gamedata.cache.generalfragments[config.generalid])
             num.neednum = num.neednum
         else

             num = {cid = cid,num = 0}
             local generalInCache = gamedata:ishasgeneral(config.generalid)
             if not  generalInCache then
                 num.neednum = gamedata.config.general_fragment[tostring(cid)].num
             else
                 local quality = config.quality
                 local nextnum
                 if generalInCache.level2+1 <= table.getTableLength(gamedata.config.general_awake) then
                     num.neednum = gamedata.config.general_awake[tostring(generalInCache.level2+1)][quality.."piece"]
                 else
                     num.neednum = 0
                 end
             end
         end

    elseif config.staffType == "equip_fragment" or config.staffType == "meterial_fragment" or config.staffType == "treasure_fragment" then
         num = table.copy(gamedata.cache.equipfragments[cid] or  {cid = cid,num=0 })
         num.neednum = config.num
    elseif config.staffType == "general" then
        num.num = 0
        for k,v in pairs(makeAllGeneralsTemp()) do
            if v.cid == cid and (not v.ison or v.ison == 0)then
                num.num = 1
                break
            end
        end
    elseif config.staffType == "equip" then
        if forExchange then
            local equipdata = makeEquipsTemp()
            local equipnum = 0
            for k,v in pairs(equipdata) do
                if (cid == v.cid) and (not v.ison or v.ison == 0) and (v.level1 <= 1) and (v.level2 <= 0) and (v.level3 <= 0) and (v.level4 <= 0) and (v.xcount <= 0) then
                    equipnum = equipnum + 1
                end
            end
            num.num = equipnum
        else
            local equipdata = gamedata.cache.equips
            local equipnum = 0
            for k,v in pairs(equipdata) do
                if cid == v.cid then
                    equipnum = equipnum + 1
                end
            end
            num.num = equipnum
        end
    elseif config.staffType == "props" then
        local propsdata = gamedata.cache.props[tonumber(cid)]
        num.num = propsdata and propsdata.num or 0
    elseif config.staffType == "pet_fragment" then
        --
        num.num = gamedata.cache.petsfragment[cid] and gamedata.cache.petsfragment[cid].num or 0
    elseif config.staffType == "countdownGift" then
        local countdownGiftdata = gamedata.cache.countdownGift
        local countdownGiftnum = 0
        for k,v in pairs(countdownGiftdata) do
            if cid == v.cid then
                countdownGiftnum = countdownGiftnum + 1
            end
        end
        num.num = countdownGiftnum
    elseif config.staffType == "jewel" then
        num.num = gamedata.cache.jewels[cid] and gamedata.cache.jewels[cid].num or 0
    elseif config.staffType == "g_gold" then
        num.num = gamedata.cache.role.g_gold or 0
    elseif config.staffType == "token" or  config.staffType == "token_fragment" then
        local propsdata = gamedata.cache.props[tonumber(cid)]
        num.num = propsdata and propsdata.num or 0
    else
        num.num = 0
    end

    return num
end

function gamedata.checkStaffEnough(cid,neednum,updatetable)
    local numnow =  gamedata.getStaffNum(cid,true).num
    if numnow < neednum then
        local ret = {}
        local config = gamedata.IDconfig(cid)
        if config.staffType == "coin" then
            ret = {type = 503,msg = config.name.."不足！！"}
        elseif config.staffType == "gold" then
            ret = {type = 503, msgtype = "shortgold" }
        elseif config.staffType == "props" then
            ret = {type = 503,msgtype = "shortprop",id= cid,num= numnow,updatetable = updatetable}
        elseif config.staffType == "stamina" then
            ret = {type = 503, msgtype = "shortphysical", param = gamedata.cache.props }
        elseif config.staffType == "energy" then
            ret = {type = 503, msgtype = "shortenergy", param = gamedata.cache.props }
        else
            if config.staffType == "red_fragment" then
                ret = {type = 503,msg = config.name.."精华不足！！"}
            else
                ret = {type = 503,msg = config.name.."不足！！"}
            end
        end

        return false,ret
    end
    return true
end

function gamedata.coinConfig(num)

    local t = {
        cid = 1000,
        num = num,
        name = "银币",
        icon = "propcoin"
    }
    return t
end

function gamedata.g_goldConfig(num)

    local t = {
        cid = 1025,
        num = num,
        -- name = "仙元",
        name = "仙元",
        icon = "0yuan"
    }
   return t
end

function gamedata.goldConfig(num)

    local t = {
        cid = 1001,
        num = num,
        name = "元宝",
        icon = "propgold"
    }
    return t
end

function gamedata.wishpointConfig(num)

    local t = {
        cid = 1027,
        num = num,
        name = "祝福值",
        icon = "xuanyuejifen"
    }
   return t
end

function gamedata.wishpointConfig2(num)

    local t = {
        cid = 1029,
        num = num,
        name = "祝福值",
        icon = "xuanyuejifen"
    }
   return t
end

function gamedata.wishpointConfig3(num)

    local t = {
        cid = 1032,
        num = num,
        name = "祝福值",
        icon = "xuanyuejifen"
    }
   return t
end

function gamedata.yinghunConfig(num)

    local t = {
        cid = 1028,
        num = num,
        name = "英魂",
        icon = "yinghun"
    }
    return t
end

function gamedata.staminaConfig(num)

    local t = {
        cid = 1002,
        num = num,
        name = "体力",
        icon = ""
    }
    return t
end

function gamedata.energyConfig(num)

    local t = {
        cid = 1003,
        num = num,
        name = "精力",
        icon = ""
    }
    return t
end

function gamedata.stoneConfig(num)

    local t = {
        cid = 21000,
        num = num,
        name = "补天石",
        icon = "fudi_stone"
    }
    return t
end

function gamedata.prestigeConfig(num)    --灭神殿积分

    local t = {
        cid = 1004,
        num = num,
        name = "积分",
        icon = "b_sprite16"
    }
    return t
end

function gamedata.pointConfig(num)   --竞技场积分

    local t = {
        cid = 1005,
        num = num,
        name = "竞技场积分",
        -- name = gameConfig.strings:string_common("ui",11),
        icon = "jingjichangjifen",
        desc = "在竞技场商店中兑换稀有道具",
        quality = 5,
    }
    return t
end

function gamedata.gangpointConfig(num)    --公会贡献

    local t = {
        cid = 1006,
        num = num,
        name = "公会贡献",
        icon = "gonghuigongxian",
        desc = "在公会商店中兑换稀有道具",
        quality = 5
    }
    return t
end

function gamedata.gangexpConfig(num)    --公会经验
    --队伍经验
    local t = {
        cid = 1030,
        num = num,
        name = "公会经验",
        icon = "icon_gonghuijifen",
        quality = 5,
    }
    return t
end

function gamedata.sculptureExpConfig(num)
    local t = {
        cid = 1033,
        num = num,
        name = "雕塑经验",
        icon = "diaosujingyan",
        quality = 5,
    }
    return t
end

function gamedata.generalexpConfig(num)    --上阵伙伴经验
    --上阵伙伴经验
    local t = {
        cid = 1031,
        num = num,
        name = "上阵伙伴经验",
        icon = "icon_gonghuijifen",
        quality = 5,
    }
    return t
end

function gamedata.yuanmingConfig(num)   --元命

    local t = {
        cid = 70000,
        num = num,
        name = "元命",
        icon = "yuanming"
    }
    return t
end

function gamedata.vipexpConfig(num)

    local t = {
        cid = 1008,
        num = num,
        name = "VIP经验",
        icon = "ach_vip"

    }
    return t
end

function gamedata.championpointConfig(num)    --冠军试炼积分

    local t = {
        cid = 1009,
        num = num,
        name = "试炼点",
        icon = "shiliandian",
        desc = "在试炼商店中兑换装备进阶和升星相关道具",
        quality = 5,
    }
    return t
end

function gamedata.passkillcoinConfig(num)    --过关斩将币

    local t = {
        cid = 1007,
        num = num,
        name = "斩将币",
        icon = "zhanjiangbi",
        desc = "在斩将商店中兑换武将和主角进阶相关道具",
        quality = 5
    }
    return t
end

function gamedata.xiandouConfig(num)   --仙豆

    local t = {
        cid = 1013,
        num = num,
        name = "仙豆",
        icon = "xiandou",
        desc = "在仙豆大转盘中兑换稀有道具",
        quality = 5,

    }
    return t
end

function gamedata.dragonboatpropConfig(num)    --赛龙舟

    local t = {
        cid = 1010,
        num = num,
        name = "绣球",
        icon = "xiuqiu"
    }
    return t
end



function gamedata.dumplingpropConfig(num)    --粽子

    local t = {
        cid = 1012,
        num = num,
        name = "粽子",
        icon = "zongzi"
    }
    return t
end

function gamedata.tigerchickenpointConfig(num)    --老虎机积分

    local t = {
        cid = 1014,
        num = num,
        name = "积分",
        icon = "hunpojifen"
    }
    return t
end

function gamedata.goddownpointConfig(num)    --天神下凡好感度

    local t = {
        cid = 1015,
        num = num,
        name = "好感度",
        icon = "love_ti"
    }
    return t
end

function gamedata.userexpConfig(num)    --队伍经验

    local t = {
        cid = 1017,
        num = num,
        name = "队伍经验",
        icon = "expicons"
    }
    return t
end

function gamedata.rechargescoreConfig(num)    --充值积分

    local t = {
        cid = 1019,
        num = num,
        name = "充值积分",
        icon = "hunpojifen"
    }
    return t
end

function gamedata.k_goddownpointConfig(num)    --跨服天神下凡好感度

    local t = {
        cid = 1020,
        num = num,
        name = "好感度",
        icon = "love_ti"
    }
    return t
end

function gamedata.gambingpointConfig(num)    --游戏机积分

    local t = {
        cid = 1021,
        num = num,
        name = "游戏机积分",
        icon = "youxijiicon"
    }
    return t
end

function gamedata.kingpointConfig(num)    --冠军试炼积分

    local t = {
        cid = 1023,
        num = num,
        name = "王者积分",
        icon = "wangzhezhizhanpoint"
    }
    return t
end

function gamedata.christmaspropConfig(num)    --圣诞

    local t = {
        cid = 1024,
        num = num,
        name = "圣诞帽",
        icon = "shengdanmao"
    }
    return t
end

function gamedata.platformcurrencyConfig(num)    --平台币

    local t = {
        cid = 1026,
        num = num,
        name = "牧游币",
        icon = "icon_muyoubi"
    }
    return t
end

function gamedata.shengxianbiConfig(num)    --升仙币
    local t = {
        cid = 1044,
        num = num,
        name = "升仙币",
        icon = "shengxianbi",
        quality = 5
    }
    return t
end

function gamedata.xianyuConfig(num)    --仙玉
    local t = {
        cid = 1045,
        num = num,
        name = "升仙玉",
        icon = "xianyu",
        quality = 5
    }
    return t
end

function gamedata.IDconfig(_id,num)
    print("IDconfig",_id)
    local id = tonumber(_id)

    if not id then
        return {}
    elseif id == 1000 then
        return  table.merge(gamedata.coinConfig(num),{staffType = "coin"})
    elseif id == 1001 then
        return  table.merge(gamedata.goldConfig(num),{staffType = "gold"})
    elseif id == 1002 then
        return  table.merge(gamedata.staminaConfig(num),{staffType = "stamina"})
    elseif id == 1003 then
        return  table.merge(gamedata.energyConfig(num),{staffType = "energy"})
    elseif id == 1004 then
        return  table.merge(gamedata.prestigeConfig(num),{staffType = "prestige"})
    elseif id == 1005 then
        return  table.merge(gamedata.pointConfig(num),{staffType = "point"})
    elseif id == 1006 then
        return  table.merge(gamedata.gangpointConfig(num),{staffType = "gangpoint"})
    elseif id == 1007 then
        return  table.merge(gamedata.passkillcoinConfig(num),{staffType = "passkillcoin"})
    elseif id == 1008 then
        return  table.merge(gamedata.vipexpConfig(num),{staffType = "vipexp"})
    elseif id == 1009 then
        return  table.merge(gamedata.championpointConfig(num),{staffType = "championpoint"})
    elseif id == 1010 then
        return  table.merge(gamedata.dragonboatpropConfig(num),{staffType = "dragonboatprop"})
    elseif id == 1012 then
        return  table.merge(gamedata.dumplingpropConfig(num),{staffType = "dumplingprop"})
    elseif id == 1013 then
        return  table.merge(gamedata.xiandouConfig(num),{staffType = "xiandou"})
    elseif id == 1014 then
        return  table.merge(gamedata.tigerchickenpointConfig(num),{staffType = "tigerchickenpoint"})
    elseif id == 1015 then
        return  table.merge(gamedata.goddownpointConfig(num),{staffType = "goddownpoint"})
    elseif id == 1017 then
        return  table.merge(gamedata.userexpConfig(num),{staffType = "userexp"})
    elseif id == 1019 then
        return  table.merge(gamedata.rechargescoreConfig(num),{staffType = "rechargescore"})
    elseif id == 1020 then
        return  table.merge(gamedata.k_goddownpointConfig(num),{staffType = "k_goddownpoint"})
    elseif id == 1021 then
        return  table.merge(gamedata.gambingpointConfig(num),{staffType = "gambingpoint"})
    elseif id == 1023 then
        return  table.merge(gamedata.kingpointConfig(num),{staffType = "kingpoint"})
    elseif id == 1024 then
        return  table.merge(gamedata.christmaspropConfig(num),{staffType = "christmasprop"})
    elseif id == 1025 then
        return  table.merge(gamedata.g_goldConfig(num),{staffType = "g_gold"})
    elseif id == 1026 then
        return  table.merge(gamedata.platformcurrencyConfig(num),{staffType = "platformcurrency"})
    elseif id == 1027 then
        return  table.merge(gamedata.wishpointConfig(num),{staffType = "wishpoint"})
    elseif id == 1029 then
        return  table.merge(gamedata.wishpointConfig2(num),{staffType = "wishpoint2"})
    elseif id == 1032 then
        return  table.merge(gamedata.wishpointConfig3(num),{staffType = "wishpoint3"})
    elseif id == 1028 then
        return  table.merge(gamedata.yinghunConfig(num),{staffType = "yinghun"})
    elseif id == 1030 then
        return  table.merge(gamedata.gangexpConfig(num),{staffType = "gangexp"})
    elseif id == 1033 then
        return  table.merge(gamedata.sculptureExpConfig(num),{staffType = "sculptureexp"})
    elseif id == 1031 then
        return  table.merge(gamedata.generalexpConfig(num),{staffType = "generalexp"})
    elseif id == 1044 then
        return  table.merge(gamedata.shengxianbiConfig(num),{staffType = "shengxianbi"})
    elseif id == 1045 then
        return  table.merge(gamedata.xianyuConfig(num),{staffType = "xianyu"})
    elseif id == 21000 then
        return  table.merge(gamedata.stoneConfig(num),{staffType = "stone"})
    elseif id == 70000 then
        return  table.merge(gamedata.config.soul[tostring(70000)],{staffType = "yuanming"})
    elseif (id >= 10101 and id <= 11000) or (id >= 160001 and id <= 161000) or (id >= 170001 and id <= 171000) or (id >= 162001 and id <= 163000) or (id >= 164001 and id <= 165000) or (id >= 174001 and id <= 175000) then
        return   table.merge(gamedata.config.general[tostring(id)],{staffType = "general"})
    elseif (id >= 11101 and id <= 12000) or (id >= 161001 and id <= 162000) or (id >= 171001 and id <= 172000) or (id >= 163001 and id <= 164000) or (id >= 165001 and id <= 166000) or (id >= 175001 and id <= 176000) then
        return   table.merge(gamedata.config.general[tostring(gamedata.config.general_fragment[tostring(id)].general)],{staffType = "general_fragment"})
    elseif (id >= 12001 and id <= 12600) or (id >= 13501 and id <= 13726) or (id >= 180001 and id <= 183001) then
        return   table.merge(gamedata.config.skill[tostring(id)],{staffType = "skill"})
    elseif id >= 12601 and id <= 14000 then
        if (id >= 12607 and id <= 12621) or (id >= 12821 and id <= 12835) or (id >= 12842 and id <= 12856) then
            return   table.merge(gamedata.config.combskill[tostring(id)],{staffType = "skill"})
        else
            return   table.merge(gamedata.config.combskill[tostring(id)],{staffType = "combskill"})
        end
    elseif id >= 14001 and id <= 15000 then
        return   table.merge(gamedata.config.generalanimation[tostring(id)],{staffType = "generalanimation"})
    elseif id >= 16001 and id <= 17000 then
        return    table.merge(gamedata.config.skillanimation[tostring(id)],{staffType = "skillanimation"})
    elseif id >= 18001 and id <= 19000 then
        return    table.merge(gamedata.config.redl_awake_item[tostring(id)],{staffType = "red_fragment"})
    elseif (id >= 20001 and id <= 21000) or (id >= 26407 and id <= 26414) then
        return    table.merge(gamedata.config.props[tostring(id)],{staffType = "props"})
    elseif id >= 191001 and id <= 200000 then
        return    table.merge(gamedata.config.props[tostring(id)],{staffType = "props"})
    elseif id >= 21001 and id <= 27000 then
        return    table.merge(gamedata.config.equip[tostring(id)],{staffType = "equip"})
    elseif id >= 27001 and id <= 28000 then
        local euqipconfig = gamedata.config.equip[tostring(gamedata.config.equip_fragment[tostring(id)].equip)]
        return    table.merge(gamedata.config.equip_fragment[tostring(id)],{staffType = "equip_fragment", type = euqipconfig.type,quality = euqipconfig.quality,icon = euqipconfig.icon,desc = euqipconfig.desc})
    elseif id >= 28001 and id <= 29000 then

        local selfconfig = gamedata.config.treasure2_fragment[tostring(id)]
        local fatherconfig
        if selfconfig.page == "meterial" then
            fatherconfig = gamedata.config.props[tostring(selfconfig.equip)]
        else
            fatherconfig = gamedata.config.equip[tostring(selfconfig.equip)]
        end
        if selfconfig.page == "meterial" then
            return    table.merge(gamedata.config.treasure2_fragment[tostring(id)],{staffType = "meterial_fragment",quality = fatherconfig.quality})
        else
            return    table.merge(gamedata.config.treasure2_fragment[tostring(id)],{staffType = "treasure_fragment",quality = fatherconfig.quality})
        end
    elseif id >= 29001 and id <= 30000 then
        return     table.merge(gamedata.config.suit[tostring(id)],{staffType = "suit"})
    elseif (id >= 30001 and id <= 33000) or (id >= 42001 and id <= 43000) then
        local config = gamedata.config.general[tostring(gamedata.config.copy_monster[tostring(id)].generalid)]
        return     table.merge(gamedata.config.copy_monster[tostring(id)],{staffType = "monster",icon = config.icon})
    elseif id > 33000 and id <= 33100 then
        return table.merge(gamedata.config.sigil[tostring(id)],{staffType = "sigil"})
    elseif id >= 44001 and id <= 45000 then --升仙台怪物id段
        local config = gamedata.config.general[tostring(gamedata.config.shengxian_monster[tostring(id)].generalid)]
        return table.merge(gamedata.config.shengxian_monster[tostring(id)],{staffType = "monster", icon = config.icon, animationid = config.animationid})
    elseif id >= 70000 and id <= 71000 then
        return    table.merge(gamedata.config.soul[tostring(id)] ,{staffType = "soul"})
    elseif id > 90000 and id < 91000 then
        return    table.merge(gamedata.config.pet3_attr[tostring(id)]["0"] ,{staffType = "pet"})
    elseif id >= 91000 and id < 92000 then
        return    table.merge(gamedata.config.pet3_fragment[tostring(id)] ,{
            staffType = "pet_fragment",
            icon = gamedata.config.pet3_attr[tostring(gamedata.config.pet3_fragment[tostring(id)].petid)]["0"].icon,
            name = gamedata.config.pet3_attr[tostring(gamedata.config.pet3_fragment[tostring(id)].petid)]["0"].name.."碎片" or "",
            quality = gamedata.config.pet3_attr[tostring(gamedata.config.pet3_fragment[tostring(id)].petid)]["0"].quality or ""
        })
    elseif id >= 92000 and id < 93000 then
        return    table.merge(gamedata.config.pet3_passiveskill[tostring(id)] ,{
            icon = gamedata.config.pet3_passiveskill[tostring(id)].icon,
            name = gamedata.config.pet3_passiveskill[tostring(id)].name,
            quality = gamedata.config.pet3_passiveskill[tostring(id)].quality
        })
    elseif id >= 80001 and id <= 81000 then
        local roleid = 0
        local fashionconfig = gamedata.config.fashioncoat or {}

        if (gamedata.cache.protagonist.general.cid >= 10101 and gamedata.cache.protagonist.general.cid <= 10115) or (gamedata.cache.protagonist.general.cid >= 10997 and gamedata.cache.protagonist.general.cid <= 10999) or (gamedata.cache.protagonist.general.cid >= 162001 and gamedata.cache.protagonist.general.cid <= 162003) then
            roleid = gamedata.cache.protagonist.general.cid
        else
            for k,v in pairs(fashionconfig) do
                for k1,v1 in pairs(v) do
                    if v1.coat_id == gamedata.cache.protagonist.general.cid then
                        roleid = v1.role_id
                    end
                end
            end
        end
        local coat_id = 0
        local name = ""
        if fashionconfig[tostring(id)] then
            for k,v in pairs(fashionconfig[tostring(id)]) do
                if v.role_id == roleid then
                    coat_id = v.coat_id
                    name = v.name
                end
            end
        end
            
        local icon = nil
        local quality = 1
        if gamedata.config.general[tostring(coat_id)] then
            icon = gamedata.config.general[tostring(coat_id)]["icon"]
            quality = gamedata.config.general[tostring(coat_id)]["quality"]
        end

        return {
            staffType = "fashion",
            icon = icon,
            name = name,
            quality = quality
        }
    elseif id >= 82001 and id <= 83000 then
        return table.merge(gamedata.config.partner_fashion[tostring(id)],{staffType = "partnerfashion"})
    elseif id >= 120000 and id <= 121000 then
        return table.merge(gamedata.config.trump_gem[tostring(id)],{staffType = "jewel"})
    elseif id >= 110000 and id <= 111000 then
        return table.merge(gamedata.config.trump[tostring(id)],{staffType = "artifact"})
    elseif id >= 150000 and id <= 160000 then
        return table.merge(gamedata.config.props2[tostring(id)],{staffType = "countdownGift"})
    elseif id >= 35001 and id <= 35500 then
        return   table.merge(gamedata.config.headframe[tostring(id)],{staffType = "iconBox"})
    elseif id >= 35501 and id <= 36000 then
        return   table.merge(gamedata.config.title[tostring(id)],{staffType = "title"})
    elseif id >= 200501 and id <= 201000 then
        local general_id = gamedata.config.illusion[tostring(id)].general_id
        local config = {
            staffType = "phantom",
            icon = gamedata.config.general[tostring(general_id)].icon,
            quality = gamedata.config.general[tostring(general_id)].quality
        }
        return table.merge(gamedata.config.illusion[tostring(id)],config)
    elseif id >= 201601 and id <= 201900 then
        return   table.merge(gamedata.config.exclusive_device_spirit[tostring(id)],{staffType = "qiling"})
    elseif (id >= 201901 and id <= 202100) then
        return   table.merge(gamedata.config.token[tostring(id)],{staffType = "token"})
    elseif (id >= 202101 and id <= 202300) then
        return   table.merge(gamedata.config.token_fragment[tostring(id)],{staffType = "token_fragment"})
    end

end

function gamedata.judgeFeiSheng(cid)
    local general = gamedata.IDconfig(cid)
    if general.soaring and general.soaring > 0 then
        return true
    end
    return false
end


function gamedata.dailyCpActivityConfig(name,sysid)
    print("dailyCpActivityConfig",name,sysid)
    local cpData
    if isNetThread then
        cpData = gamedata.cache.dailyCpActivityTimeStatus[sysid]
    else
        cpData = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[sysid]
    end

    printT(cpData,"cpData")

    if cpData and cpData.cpnum and cpData.cpnum > 0 and cpData.cpnum < 9 then
        return gamedata.config[name.."_rc_"..cpData.cpnum] or {}
    end

    return gamedata.config[name] or {}
end

function gamedata.xuanyueTreasuresDay(self,data)
    local day = {}
    day.isopen = data[1]
    day.isCpActivity = data[2]
    day.cpnum = data[3]
    day.cpday = data[4]

    return day
end

function gamedata.xuanyueTreasuresData(self,data)
    local _data = {}
    _data.score = data[1]
    _data.isHight = data[2]

    _data.status = {}
    local num = table.getTableLength(gamedata.config:getConfigByName("xuanyue_reward"))
    for i=1,num do
        _data.status[i] = data[i + 2] or 0
    end
    return _data
end

function gamedata.xuanyueTreasuresData2(self,data)
    local _data = {}
    _data.score = data[1]
    _data.isHight = data[2]

    _data.status = {}
    local num = table.getTableLength(gamedata.config:getConfigByName("xuanyue2_reward"))
    for i=1,num do
        _data.status[i] = data[i + 2] or 0
    end
    return _data
end

function gamedata.xuanyueTreasuresData3(self,data)
    local _data = {}
    _data.score = data[1]
    _data.isHight = data[2]

    _data.status = {}
    local num = table.getTableLength(gamedata.config:getConfigByName("xuanyue3_reward"))
    for i=1,num do
        _data.status[i] = data[i + 2] or 0
    end
    return _data
end

function gamedata.getOriginCid(cid)
    local _cid = cid
    local _generalConfig = gamedata.config.general[tostring(_cid)]
    if _generalConfig and _generalConfig.init_cid and _generalConfig.init_cid > 0 then
        _cid = _generalConfig.init_cid
    end
    print("getOriginCid",cid,_cid)
    return _cid
end

function gamedata.setAdStatus(self,data)
    self.cache.adStatus = {}
    self.cache.adStatus.status1 = data[1] or 0
    self.cache.adStatus.status2 = data[2] or 0
    self.cache.adStatus.status3 = data[3] or 0
    self.cache.adStatus.status4 = data[4] or 0
    self.cache.adStatus.status5 = data[5] or 0
end

function gamedata.illusionData(self,data)
    local illusion = {}
    illusion.cid = data[1] or 0
    illusion.generalIid = data[2] or 0
    illusion.endtime = data[3] or 0

    self.cache.illusion[illusion.cid] = illusion

    return illusion
end

function gamedata.illusions(self,data)
    print("illusions")
    for i,v in ipairs(data) do
        print(i,v)
    end
    local illusions = {}
    local i = 0
    while data[i*3 + 1] do
        local v = {
            data[i*3 + 1],
            data[i*3 + 2],
            data[i*3 + 3],
        }
        i = i + 1
        illusions[i] = self:illusionData(v)
    end
    
    return illusions
end

function gamedata.illusionsLimite(self,type)
    print("illusions")
    
    local limit = 0
    if type == "fan_pve" then
        limit = gamedata.config.global_kv.illusion_pve_1 and tonumber(gamedata.config.global_kv.illusion_pve_1.value) or 0
    elseif type == "xian_pve" then
        limit = gamedata.config.global_kv.illusion_pve_2 and tonumber(gamedata.config.global_kv.illusion_pve_2.value) or 0
    elseif type == "l_pvp" then
        limit = gamedata.config.global_kv.illusion_pvp_1 and tonumber(gamedata.config.global_kv.illusion_pvp_1.value) or 0
    elseif type == "k_pvp" then
        limit = gamedata.config.global_kv.illusion_pvp_2 and tonumber(gamedata.config.global_kv.illusion_pvp_2.value) or 0
    end

    if isNetThread then
        return self.cache.role.vip >= limit
    else
        return GameScene.roleinfo.vip >= limit
    end
end

function gamedata.ExclusiveArtifactData(self,t,refresh)
    local artifactData = {}
    if refresh then
        artifactData = t
    else
        artifactData = {
            generalIid      = t[1] or 0,
            cid             = t[2] or 0,
            level           = t[3] or 0,
            inlayId1        = t[4] or 0,
            inlayId2        = t[5] or 0,
            inlayId3        = t[6] or 0,
            inlayId4        = t[7] or 0,
            inlayId5        = t[8] or 0,
            inlayId6        = t[9] or 0,
            suitId1         = t[10] or 0,
            suitId2         = t[11] or 0,
            suitId3         = t[12] or 0,
        }
    end
    artifactData.intensify_level = 0
    artifactData.baptism_level = 0
    artifactData.maxlevel = 0
    
    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level)]
    if exclusiveIntensifyConfig then
        artifactData.baptism_level = exclusiveIntensifyConfig.baptism_level
        if exclusiveIntensifyConfig.intensify_level == 0 then
            local lastConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level - 1)]
            artifactData.intensify_level = lastConfig.intensify_level
        else
            artifactData.intensify_level = exclusiveIntensifyConfig.intensify_level
        end
    end

    if not gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level + 1)] then
        artifactData.maxlevel = 1
    end

    return artifactData
end

function gamedata.ExclusiveArtifactDatas(self,t,other)
    local Artifacts = {}
    for i=1,#t/12 do
        local ArtifactData = gamedata:ExclusiveArtifactData({
            t[12*i-11],
            t[12*i-10],
            t[12*i-9],
            t[12*i-8],
            t[12*i-7],
            t[12*i-6],
            t[12*i-5],
            t[12*i-4],
            t[12*i-3],
            t[12*i-2],
            t[12*i-1],
            t[12*i]
        })
        Artifacts[i] = ArtifactData

        if not other then
            gamedata.cache.exclusiveArtifact[ArtifactData.generalIid] = ArtifactData
        end
    end
    printT(Artifacts,"ExclusiveArtifactDatas")
    return Artifacts
end

function gamedata.ExclusiveArtifactQiLingData(self,t,refresh)

    local qiLingData = {}
    if refresh then
        qiLingData = t
    else
        qiLingData = {
            iid                 = t[1] or 0,
            cid                 = t[2] or 0,
            level               = t[3] or 0,
            successRate         = t[4] or 0,
            lock                = t[5] or 0,
            qiLingAttrKey1      = t[6] or 0,
            qiLingAttrLevel1    = t[7] or 0,
            qiLingAttrValue1    = t[8] or 0,
            qiLingAttrKey2      = t[9] or 0,
            qiLingAttrLevel2    = t[10] or 0,
            qiLingAttrValue2    = t[11] or 0,
            qiLingAttrKey3      = t[12] or 0,
            qiLingAttrLevel3    = t[13] or 0,
            qiLingAttrValue3    = t[14] or 0,
            qiLingAttrKey4      = t[15] or 0,
            qiLingAttrLevel4    = t[16] or 0,
            qiLingAttrValue4    = t[17] or 0,
            generalIid          = nil,
            exclusiveCid        = nil,
            ison                = 0
        }
    end

    local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(qiLingData.cid)]
    qiLingData.quality = qilingConfig.quality
    qiLingData.location = qilingConfig.location
    qiLingData.suit = qilingConfig.suit

    return qiLingData
end

function gamedata.ExclusiveArtifactQiLingDatas(self,t,other)
    local qilingDatas = {}
    for i=1,#t/17 do
        local QiLingData = gamedata:ExclusiveArtifactQiLingData({
            t[17*i-16],
            t[17*i-15],
            t[17*i-14],
            t[17*i-13],
            t[17*i-12],
            t[17*i-11],
            t[17*i-10],
            t[17*i-9],
            t[17*i-8],
            t[17*i-7],
            t[17*i-6],
            t[17*i-5],
            t[17*i-4],
            t[17*i-3],
            t[17*i-2],
            t[17*i-1],
            t[17*i],
        })
        qilingDatas[i] = QiLingData

        if not other then
            --是否镶嵌
            for i,v in pairs(gamedata.cache.exclusiveArtifact) do
                for k=1,6 do
                    if v["inlayId"..k] == QiLingData.iid then
                        QiLingData.generalIid = v.generalIid
                        QiLingData.exclusiveCid = v.cid
                        QiLingData.ison = 1
                        break
                    end
                end
            end
            gamedata.cache.exclusiveArtifactQiLing[QiLingData.iid] = QiLingData
        end
    end
    -- printT(qilingDatas,"ExclusiveArtifactQiLingDatas")
    return qilingDatas
end

function gamedata.changeGodCompetitionPower(self,_gPower,_index,team_id_now)
    _gPower = _gPower or 0
    _index = _index or 1
    team_id_now = team_id_now or 1

    print(_gPower,_index,"changeGodCompetitionPower")
    if  not self.cache.godCompetionPower[_index] then
        self.cache.godCompetionPower[_index] = _gPower --第一次
    else
        if self.cache.godCompetionPower[_index] then
            local change = _gPower - self.cache.godCompetionPower[_index]
            print("封神赛-战力:",_index,team_id_now,_gPower,change)
            if change ~= 0  and  _index == team_id_now then
                print("封神赛——弹窗:",change)
                local powermsg = {}
                powermsg.change_type = (change >= 0) and "add" or "sub"
                powermsg.change_num = math.abs(change)
                powermsg.topwer_num = _gPower
                UIResponse({type = 503, msgtype = "godCompetition_power", msg = powermsg})                
            end    
            self.cache.godCompetionPower[_index] = _gPower 
        end   
    end    
  
end    

return gamedata