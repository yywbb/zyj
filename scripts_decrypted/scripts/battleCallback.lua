--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-24
-- Time: 下午2:00
-- To change this template use File | Settings | File Templates.
--

local battlecallback_active = false
local powerchange = nil
function getbattlecallbackactive()
    return  battlecallback_active
end
function setbattlecallbackactive(isactive)
    battlecallback_active  = isactive
end
function setPowerChange(msg)
    powerchange = msg
end

function runPowerChange()
    if powerchange then
        runGamePrompt({msg = powerchange})
        powerchange = nil
    end
    battlecallback_active = false
end

function updateDataLife(reward)
    local changeCoin = false
    local changeGold = false
    local changeExpNum = 0
    local specials = {}
    local changeQilingDatas = {}

    for k, v in pairs(reward) do
        if v.cid and v.cid == 1000 then
            changeCoin = true
            GameScene:addUpdate(10021)
        elseif v.cid and v.cid == 1001 then
            changeGold = true
            GameScene:addUpdate(10021)
        elseif v.cid and v.cid == 1017 then
            changeExpNum = v.num
            UIRequest({type = 1001,param = "resume"})
        elseif v.cid and v.cid == 1025 then
             UIRequest({type = 1001})
        end

        local config = ui.IDconfig(v.cid)
        if config.staffType == "general" then
            GameScene:addUpdate(1012)
            GameScene:addUpdate(10023)
            GameScene:addUpdate(10024)
            GameScene:addUpdate(10211)
        elseif config.staffType == "general_fragment" then
            GameScene:addUpdate(1012)
            GameScene:addUpdate(10023)
        elseif config.staffType == "red_fragment" then
            GameScene:addUpdate(10030)
        elseif config.staffType == "equip" then
            if config.type == "horse" or config.type == "treasure" then
                GameScene:addUpdate(10025,"offtreasures")
                GameScene:addUpdate(10025,"treasures")
                GameScene:addUpdate(10021)
            else
                GameScene:addUpdate(10025,"offequips")
                GameScene:addUpdate(10025,"equips")
                GameScene:addUpdate(10021)
            end
            GameScene:addUpdate(10025,config.type)
        elseif config.staffType == "equip_fragment" then
            GameScene:addUpdate(11071,"equip")
        elseif config.staffType == "treasure_fragment" then
            GameScene:addUpdate(11071,"treasure")
            GameScene:addUpdate(11111)
        elseif config.staffType == "meterial_fragment" then
            GameScene:addUpdate(11071,"meterial")
            GameScene:addUpdate(11111)
        elseif config.staffType == "soul" then
            GameScene:addUpdate(10026,"all")
            GameScene:addUpdate(10026,"star"..config.quality)
            GameScene:addUpdate(10021)
        elseif config.staffType == "sigil" then
            GameScene:addUpdate(10028)
            GameScene:addUpdate(10022)
        elseif config.staffType == "props" then
            GameScene:addUpdate(1200)
            if config.id==20222 or config.id ==20256 or config.id ==20099 or config.id ==20223 or config.id ==20282 or config.id ==20283 or config.id == 20842 or config.id == 20843 or config.id == 20844 or config.id == 20845 then
                GameScene:addUpdate(10021)
            end
            if config.id >= 20296 and config.id <= 20325 then
                GameScene:addUpdate(10021)
            end

            --专属神器
            if config.id == 192087 or config.id == 192088 or config.id == 192089 or config.id == 192090 or config.id == 192091 then
                GameScene:addUpdate(10021)
            end
        elseif config.staffType == "countdownGift" then
            GameScene:addUpdate(5901)
        elseif config.staffType == "jewel" then
            GameScene:addUpdate(10031)
        elseif config.staffType == "artifact" then
            GameScene:addUpdate(10032)
        elseif config.staffType == "fashion" then
            UIRequest({type = 1070})
        elseif config.staffType == "partnerfashion" then
            savePartnerfashionOnceToSqlite(v.cid,1)
        elseif config.staffType == "phantom" then
            --判断是否是新获得
            local diff = v.endtime - gamedata:time()
            if diff <= gamedata.config.illusion[tostring(v.cid)].time * 86400 * v.num then
                saveIllusionToSqlite(v.cid,v.endtime)
            end
            UIRequest({type = 8110})
        elseif config.staffType == "qiling" then
            table.insert(changeQilingDatas,v.iid)
            GameScene:addUpdate(10021)
        end
        if gamedata.config.drop_special and v.cid and gamedata.config.drop_special[tostring(v.cid)] then
            specials[#specials+1] = v
        end
    end

    if #changeQilingDatas > 0 then
        local iids = {}
        for i,v in ipairs(changeQilingDatas) do
            iids[i] = {iid = v,opt = 1}
        end
        saveNewQilingToSqlite(iids)
        UIRequest({type = 81051})
    end

    return changeCoin,changeGold,specials,changeExpNum
end


function showRewardPopupWindow(Reward,type,CallBack,nospecials)
    if Reward and next(Reward) then
        local Reward1 = {}
        for k,v in pairs(Reward) do
            if v.cid == 1021 then
                runGamePrompt({msg = "获得"..v.num.."游戏机积分"})
            else
                Reward1[tostring(table.getTableLength(Reward1)+1)] = v
            end
        end
        Reward = Reward1
    end

    if Reward == nil or next(Reward) == nil then
        print("nothing reward")
        if CallBack then CallBack() end
        return
    end

    local roleinfo = table.copy(GameScene.roleinfo)
    local changeCoin,changeGold,specials,changeExpNum = updateDataLife(Reward)

     local callback = function()
         if not (GameScene.presentLayer and GameScene.presentLayer == "main") then
            GameScene:UpdatePresentLayer()
         end

         if changeExpNum and (changeExpNum > 0) and (roleinfo.level < table.getTableLength(gamedata.config.role_exp)) then
             gameWindows:openWindow("userexpup",{roleinfo = roleinfo, expup = changeExpNum,},CallBack)
         elseif CallBack then
             CallBack()
         end

         if changeCoin then
            UIRequest({type = 1001})
            GameScene:coin_effect(1,540,960,0.5)
         end

         if changeGold then
            UIRequest({type = 1001})
            GameScene:coin_effect(2,540,960,0.5)
         end


        print("getStaff_close")
        if GameScene.layers["xuanyueTreasures"].module.activeAction ~= -1 then
            gameWindows:openWindow("xuanyueTreasuresActivate",{id = GameScene.layers["xuanyueTreasures"].module.activeAction})
            GameScene.layers["xuanyueTreasures"].module.activeAction = -1
        end

        if GameScene.layers["xuanyueTreasures2"].module.activeAction ~= -1 then
            gameWindows:openWindow("xuanyueTreasuresActivate2",{id = GameScene.layers["xuanyueTreasures2"].module.activeAction})
            GameScene.layers["xuanyueTreasures2"].module.activeAction = -1
        end

        if GameScene.layers["xuanyueTreasures3"].module.activeAction ~= -1 then
            gameWindows:openWindow("xuanyueTreasuresActivate3",{id = GameScene.layers["xuanyueTreasures3"].module.activeAction})
            GameScene.layers["xuanyueTreasures3"].module.activeAction = -1
        end
        
     end

    UIRequest({type = 10322})

    if table.getTableLength(Reward)<= 1 or nospecials then
        gameWindows:openWindow("getStaff",Reward,callback)
        gamedata.music:PlayOptSound("jllq")
    else
        local specialIDX = 0
        local function palyone()
            specialIDX=specialIDX+1
            if specials[specialIDX] then
                gameWindows:openWindow("getStaff",{specials[specialIDX]},function() palyone() end)
                gamedata.music:PlayOptSound("jllq")
            else
                gameWindows:openWindow("getStaff",Reward,callback)
                gamedata.music:PlayOptSound("jllq")
            end
        end
        palyone()
    end

end


require"MergeBattleReport"
function RunbattleCallBack(gstate, t, CallBack)
    battlecallback_active = true

    local callBackChain = {}
    local step = 1
    local tailCallBack =  function()
        runPowerChange()
        setTriggerGiftEnable(true)
        if CallBack then
            CallBack()
        end
    end

    local timebagtrig = function()
        UIRequest({type = 2882,opt=2})
        UIRequest({type = 2882,opt=3})

        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        if callback then
            callback()
        end
    end

    local showOtherInfo = function()
        print("showOtherInfo")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
--        if t.exp and next(t.exp) and t.exp.oldlevel< t.exp.newlevel then
--            GameScene:levelUprequest()
--
--            gameWindows:openWindow("userLevelup",t.exp,callback)
--        else
--            if callback then
--                callback()
--            end
--        end

        if guide.controller then
            guide.controller:LevelUp(t.exp,callback)
        else
            if callback then
                callback()
            end
        end

    end

    local playBackstory = function()
        print("playBackstory")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        if t.type == 1306 and t.palybackstory then
            local backstory = gamedata.config.copy[tostring(t.map)][tostring(t.point)].backstory
            if backstory and backstory ~= 0 then
                guide:palyCopyStory(gamedata.config.copy_dialog[tostring(backstory)],callback)
            else
                if callback then callback() end
            end
        elseif t.type == 7013 and t.palybackstory then
            guide:palyCopyStory(gamedata.config.copy_dialog[tostring(71147)],callback)
        else
            if callback then callback() end
        end
    end

    local playPrestory = function()
        print("playPrestory")

        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        if t.type == 1306 and t.palyprestory then
            local prestory = gamedata.config.copy[tostring(t.map)][tostring(t.point)].prestory
            if prestory and prestory ~= 0 then
                guide:palyCopyStory(gamedata.config.copy_dialog[tostring(prestory)],callback)
            else
                if callback then callback() end
            end
        else
            if callback then callback() end
        end
    end

    local palyExplore = function()
        print("palyExplore")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        if GameScene.layers["copy_map"].show then
            GameScene.layers["copy_map"].module:palyExplore(t.exp,t.coin,t.move,callback)
        else
            if callback then callback() end
        end
    end

    local showEncounter = function()
        print("showEncounter")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        --printT(t.encounters)
        if t.encounters and next(t.encounters) then
            gameWindows:openWindow("encounter",t.encounters,callback)
        else
            if callback then callback() end
        end
    end

    local showDropList = function()
        print("showDrop")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        showRewardPopupWindow(t.reward,nil,callback)
    end

    local palyBattle = function()
        print("palyBattle")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        if t.type == 1306 and t.palybattlestory then
            local story = gamedata.config.copy[tostring(t.map)][tostring(t.point)].story
            if story and story ~= "" then
                print("palyBattlestory",story)
                local filepath = CCFileUtils:sharedFileUtils():fullPathForFilename("story/" .. story .. ".json")
                local json_text = LoadJsonFileToTable(filepath)
                t.battlereport = MergeBattleReport(t.battlereport,json_text)
                t.speedfalse = true
                t.speedresumestep = #json_text.battle.action
            end
        end

        loading:battlePreLoading(mainScene,"heimu",function() battleScene:init(mainScene,gstate,t,callback) end)
        --battleScene:init(mainScene,gstate,t,callback)

    end

    local showExpGet = function()
        print("showExpGet")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        gameWindows:openWindow("generalexp",{type = "wipe",data = t},callback)
    end

    local showpassReward = function()
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        if t.showpassreward and GameScene.layers["copy_map"].show then
            if t.type == 1301 then
                GameScene.layers["copy_map"].module:reloadnormalData(t.copy)
            elseif t.type == 1331 then
                GameScene.layers["copy_map"].module:reloadbraveData(t.bravecopy)
            end
            GameScene.layers["copy_map"].module:showPassReward(callback)
        else
            if callback then callback() end
        end
    end

    local playYudi = function()
        print("showYUdi")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        guide:showYudi(t,callback)
    end

    local playVs = function()
        print("showvs")
        step = step + 1
        local callback = callBackChain[gstate][step] or tailCallBack
        if t.vs_a and t.vs_b then
            guide:showVs(t,callback)
        else
            if callback then callback() end
        end
    end

    callBackChain = {
        --copyencounter = {palyExplore,showEncounter,showOtherInfo},
        copy = {playPrestory,palyBattle,playBackstory,showDropList,showEncounter,showOtherInfo,timebagtrig},
        copywipe = {showExpGet,showDropList,showEncounter,showOtherInfo,timebagtrig},

        sports = {palyBattle,showDropList,},
        blood = {palyBattle, showDropList},
        rob = {palyBattle},

        servicewar = {palyBattle,showDropList,},
        honorwar = {palyBattle,showDropList},
        encounter = {palyBattle,showDropList,},
        friendcopy = {palyBattle,showDropList,},
        story = {palyBattle,showDropList },
        cup = {palyBattle,showDropList},
        penglai = {palyBattle,showDropList},
        test = {palyBattle,showDropList},

        worldboss = {palyBattle,showDropList},
        battleother = {palyBattle, },

        fort = {palyBattle,showDropList},
        guildwar = {palyBattle},
        activitycopy = {palyBattle,showDropList},
        activitycopyboss = {palyBattle,showDropList},

        singleboss = {palyBattle},

        copystar = {palyBattle,showDropList},

        copyhades = {palyBattle,showDropList},

        maze = {palyBattle,showDropList},

        champion = {palyBattle,showDropList},
        
        overpass = {palyBattle,showDropList},
        
        wudaohui = {palyBattle,showDropList},

        nightclub1 = {palyBattle,showDropList},
        nightclub2 = {palyBattle,},

        heroboss = {palyBattle,showDropList},
        kingBattle = {palyBattle, showDropList},
        kingBattle2 = {palyBattle, showDropList},
        copyhell = {palyBattle,showDropList},
        babelTower = {palyBattle,playBackstory},
        blessingCave = {palyBattle, showDropList},
        robbery = {palyBattle, showDropList},

        ancientRuins = {palyBattle, showDropList},

        normal = {palyBattle},
        --专属副本
        exclusiveArtifactCopy = {palyBattle, showDropList},
        exclusiveActive = {palyBattle},
        --封神赛
        godCompetitionBattle = {palyBattle,showDropList,},
        godCompetition = {palyBattle,showDropList},

        --升仙台战斗
        sendaiBattle = {palyBattle,showDropList},
    }

    local start = callBackChain[gstate][step]
    start()

end

--local function rgbtohsb(r,g,b)
--
--    local max = math.max(r,g,b)
--    local min = math.min(r,g,b)
--
--    local v = max / 255
--    local s = max ==0 and 0 or (max - min)/max
--    local h = 0
--    if max == r and g >= b then
--        h = (g-b)*60/(max-min)+0
--    elseif max == r and g < b then
--        h = (g-b)*60/(max-min)+360
--    elseif max == r and g < b then
--        h = (b-r)*60/(max-min)+120
--    elseif max == r and g < b then
--        h = (r-g)*60/(max-min)+240
--    end
--
--    return h,s,v
--end
--
--local function hsbtorgb(h,s,v)
--
--    local r,g,b = 0,0,0
--
--    local i = math.floor(h/60)
--    local f = (h / 60) - i
--    local p = v * (1 - s)
--    local q = v * (1 - f * s)
--    local t = v * (1 - (1 - f) * s)
--
--    if i == 0 then
--        r = v;
--        g = t;
--        b = p;
--    elseif i == 1 then
--        r = q;
--        g = v;
--        b = p;
--    elseif i == 2 then
--        r = p;
--        g = v;
--        b = t;
--    elseif i == 3 then
--        r = p;
--        g = q;
--        b = v;
--    elseif i == 4 then
--        r = t;
--        g = p;
--        b = v;
--    elseif i == 5 then
--        r = v;
--        g = p;
--        b = q;
--    end
--
--    return r*255,g*255,b*255
--end
--
--
--function findRGB(h_,s_,v_)
--    local r1,g1,b1 = 234,134,189
--
--
--    local h1,s1,v1 = rgbtohsb(r1,g1,b1)
--    print(h1,s1,v1)
--
--    local r2,g2,b2 = hsbtorgb(h1+h_,s1+s_,v1+v_)
--    print(r2,g2,b2)
--
--    print("hsb control =======",r2-r1,g2-g1,b2-b1)
--end
--
--findRGB(-180,0,0)


 �G  