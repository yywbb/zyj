--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/12
-- Time: 下午6:08
-- To change this template use File | Settings | File Templates.
--

local function reloadGang(gangstatus)
    if gangstatus.id and gangstatus.id > 0 then

        if GameScene.layers["gang_main"].show then
            GameScene.layers["gang_main"].module:reloaddata(gangstatus)
        else
            GameScene:shiftLayer("gang_main","up")
            GameScene.layers["gang_main"].module:reloaddata(gangstatus)
        end
    else
        GameScene:shiftLayer("gang_list","up")
    end
end


function UIGangStatus(t)
    print("公会2200，接受客户端数据")
    --printT(t)
    if t.param and t.param+0 == 200 then return end

    if GameScene:checkopenlevelbyId(28) then
        reloadGang(t.gangstatus,t.param)
    end

end

function UIGangCreate(t)
    print("公会2201，接受客户端数据")
    --printT(t)

    reloadGang(t.gangstatus)
    UIRequest({type = 1001})
end

function UIGangs(t)
    print("公会2202，接受客户端数据")
    --printT(t)
    if GameScene.layers["gang_list"].show then
        GameScene.layers["gang_list"].module:reloaddata(t.gangs)
    end
end

function UIGangReq(t)
    print("公会2203，接受客户端数据")

    if GameScene.layers["gang_list"].show then
        GameScene.layers["gang_list"].module:reqResult(t)
    end
end

function UIGangReqQuery(t)
    print("公会2204，接受客户端数据")
    --printT(t)

    if GameScene.layers["gang_manager"].show then
        GameScene.layers["gang_manager"].module:reloadreqlist(t.players)
    end

end

function UIGangReqRep(t)
    print("公会2205，接受客户端数据")

    if t.result == 1 then
        if t.opt == 1 then
            UIRequest({type = 2204})
            UIRequest({type = 2206})
        else
            UIRequest({type = 2204})
        end
    else
        runGamePrompt({msg = "操作失败，请重试"})
    end

end

function UIGangMember(t)
    print("公会2206，接受客户端数据")
    --printT(t)

    if GameScene.layers["gang_manager"].show then
        GameScene.layers["gang_manager"].module:reloadmemberlist(t.gangmembers)
    end

end

function UIGangKickMember(t)
    print("公会2207，接受客户端数据")

    if t.result == 1 then
        if GameScene.layers["gang_manager"].show then
            GameScene.layers["gang_manager"].module:reloadmemberlist(t.gangmembers)
        end
    else
        runGamePrompt({msg = "操作失败，请重试"})
    end
end

function UIGangQuit(t)
    print("公会2208，接受客户端数据")

    reloadGang(t.gangstatus)
end

function UIGangPassPower(t)
    print("公会2209，接受客户端数据")
    if t.result == 1 then
        if GameScene.layers["gang_manager"].show then
            GameScene.layers["gang_manager"].module:reloadmemberlist(t.gangmembers)
        end
    else
        runGamePrompt({msg = "操作失败，请重试"})
    end
end

function UIGangSetAssistant(t)
    print("公会2210，接受客户端数据")
    if t.result == 1 then
        if GameScene.layers["gang_manager"].show then
            GameScene.layers["gang_manager"].module:reloadmemberlist(t.gangmembers)
        end
    else
        runGamePrompt({msg = "操作失败，请重试"})
    end
end

function UIGangRemoveAssistant(t)
    print("公会2219，接受客户端数据")
    if t.result == 1 then
        if GameScene.layers["gang_manager"].show then
            GameScene.layers["gang_manager"].module:reloadmemberlist(t.gangmembers)
        end
    else
        runGamePrompt({msg = "操作失败，请重试"})
    end
end


function UIGangSetAnnouncement(t)
    print("公会2211，接受客户端数据")
    --printT(t)
    if t.result == 1 then
        reloadGang(t.gangstatus)
    else
        runGamePrompt({msg = "操作失败，请重试"})
    end
end


function UIGangsearch(t)
    print("公会2218，接受客户端数据")
    --printT(t)

    if GameScene.layers["gang_list"].show then
        GameScene.layers["gang_list"].module:searchResult(t)
    end
end

------------------------------------------------------------------------------------------------------------


function UIGangUserGang2(t)
    print("公会2230，接受客户端数据")
    printT(t)

    GameScene.layers["gang_main"].module.gang = t.gang2status


    if GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        UIRequest({type = 2252})
    end


    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadGuildTip()
    end

    if not t.param then return end
    if t.param == "main" then
        if GameScene:checkopenlevelbyId(28) then
            reloadGang(t.gang2status,t.param)
        end
    elseif t.param == "xianchi" then
        if GameScene:checkopenlevelbyId(122) then
            if t.gang2status.id and t.gang2status.id > 0 then
                GameScene:shiftLayer("gang_xianchi","up",{gang = t.gang2status})
            else
                runGamePrompt({msg = "您还没有加入公会"})
            end
        end
    elseif t.param == "shangxiang" then
        if GameScene:checkopenlevelbyId(124) then
            if t.gang2status.id and t.gang2status.id > 0 then
                GameScene:shiftLayer("gang_shangxiang","up")
            else
                runGamePrompt({msg = "您还没有加入公会"})
            end
        end
    elseif t.param == "gangwar" then
        if GameScene:checkopenlevelbyId(171) then
            if t.gang2status.id and t.gang2status.id > 0 then
                local globalconfig = gamedata.config.global_kv
                if tonumber(t.gang2status.level) >= tonumber(globalconfig.gang2_signup_minlevel.value) then
                    --GameScene:shiftLayer("gangwar_main","up")
                    UIRequest({type = 2130, param = "main"})
                else
                    runGamePrompt({msg = gameConfig.strings:guildOpenLv(globalconfig.gang2_signup_minlevel.value)})
                end
            else
                runGamePrompt({msg = "您还没有加入公会"})
            end
        end
    elseif t.param == "skill" then
        if GameScene:checkopenlevelbyId(172) then
            if t.gang2status.id and t.gang2status.id > 0 then
                GameScene:shiftLayer("gang_skill","up")
            else
                runGamePrompt({msg = "您还没有加入公会"})
            end
        end
    elseif t.param == "activity" then
        if t.gang2status.id and t.gang2status.id > 0 then
            if GameScene.layers["guildActivity"].show then
                GameScene.layers["guildActivity"].module:reload(t.gang2status)
            else
                GameScene:shiftLayer("guildActivity",nil,{gang = t.gang2status})
            end
        else
            runGamePrompt({msg = "您还没有加入公会"})
        end
    end

end

function UIGangUserGang2Create(t)
    print("公会2231，接受客户端数据")
    -- printT(t)

    if t.result and t.result == 0 then
        runGamePrompt({msg = "公会创建成功"})
        UIRequest({type = 2230,param = "main"})
        UIRequest({type = 1001})
    elseif t.result and t.result == 2001 then
        runGamePrompt({msg = "公会名重复，创建失败"})
    else
        runGamePrompt({msg = "公会创建失败"})
    end
end

function UIGangUserGang2List(t)
    print("公会2232，接受客户端数据")
    -- printT(t)
    if GameScene.layers["gang_list"].show then
        GameScene.layers["gang_list"].module:reloaddata(t)
    end
end

function UIGangUserGang2Req(t)
    print("公会2233，接受客户端数据")
    -- printT(t)
    if t.result == 2002 then
        runGamePrompt({msg = "请不要重复申请"})
    elseif t.result == 2003 then
        runGamePrompt({msg = "公会人员已满"})
    elseif t.result == 2004 then
        runGamePrompt({msg = "已加入其他的公会"})
    elseif t.result == 2005 then
        runGamePrompt({msg = "会长已拒绝你加入该公会"})
    elseif t.result == 2006 then
        runGamePrompt({msg = "您的等级不足"})
    elseif t.result == 1 then
        UIRequest({type = 2230,param = "main"})
    else
        if GameScene.layers["gang_list"].show then
            GameScene.layers["gang_list"].module:reqResult(t)
        end
    end

end

function UIGangUserGang2ReqQuery(t)
    print("公会2234，接受客户端数据")
    -- printT(t)

    if GameScene.layers["gang_manager"].show then
        GameScene.layers["gang_manager"].module:reloadreqlist(t.players)
    end
end

function UIGangUserGang2Rep(t)
    print("公会2235，接受客户端数据")
    -- printT(t)

    if t.result == 0 then
        runGamePrompt({msg = "操作成功，同意该玩家的申请"})
        UIRequest({type = 2230})
        UIRequest({type = 2234})
        UIRequest({type = 2236})
    elseif t.result == 2003 then
        runGamePrompt({msg = "本公会人数已满，无法通过该申请"})
        UIRequest({type = 2234})
    elseif t.result == 2004 then
        runGamePrompt({msg = "对方已有公会，无法通过该申请"})
        UIRequest({type = 2234})
    elseif t.result == 2005 then
        runGamePrompt({msg = "操作成功，拒绝该玩家的申请"})
        UIRequest({type = 2234})
    elseif t.result == 2006 then
        runGamePrompt({msg = "该玩家已取消申请"})
        UIRequest({type = 2234})
    end

end

function UIGangUserGang2Member(t)
    print("公会2236，接受客户端数据")
    -- printT(t)

    if GameScene.layers["gang_manager"].show then
        GameScene.layers["gang_manager"].module:reloadmemberlist(t)
    end

    if GameScene.layers["gangwar_main"].show then
        GameScene.layers["gangwar_main"].module:reloadmembers(t)
    end

    GameScene.layers["gang_main"].module.gang = t.gang2status
    if GameScene.layers["gang_main"].show then
        GameScene.layers["gang_main"].module:reloaddata()
    end

    UIRequest({type = 2265})
end

function UIGangUserGang2MSetContent1(t)
    print("公会2237，接受客户端数据")
    if t.result and t.result == 1 then
        runGamePrompt({msg = "修改成功"})
        UIRequest({type = 2236})
    else
        runGamePrompt({msg = "修改失败"})
    end
end

function UIGangUserGang2MSetContent2(t)
    print("公会2238，接受客户端数据")
    if t.result and t.result == 1 then
        runGamePrompt({msg = "修改成功"})
        UIRequest({type = 2236})
    else
        runGamePrompt({msg = "修改失败"})
    end
end

function UIGangUserGang2MSetVice(t)
    print("公会2239，接受客户端数据")
    -- printT(t)

    UIRequest({type = 2236})
end

function UIGangUserGang2MKick(t)
    print("公会2240，接受客户端数据")
    -- printT(t)
    UIRequest({type = 2230})
    UIRequest({type = 2236})
end

function UIGangUserGang2MPass(t)
    print("公会2241，接受客户端数据")
    -- printT(t)
    UIRequest({type = 2230})
    UIRequest({type = 2236})
end

function UIGangUserGang2Quit(t)
    print("公会2242，接受客户端数据")
    -- printT(t)

    UIRequest({type = 2230,param = "main"})
end

function UIGangUserGang2Search(t)
    print("公会2243，接受客户端数据")
    -- printT(t)

    if GameScene.layers["gang_list"].show then
        GameScene.layers["gang_list"].module:searchResult(t.gangs)
    end
end

function UIGangUserGang2PrayQuery(t)
    print("公会2250，接受客户端数据")
    -- printT(t)
    if GameScene.layers["gang_shangxiang"].show then
        GameScene.layers["gang_shangxiang"].module:reloaddata(t)
    end
end

function UIGangUserGang2Pray(t)
    print("公会2251，接受客户端数据")
    -- printT(t)
    
    if GameScene.layers["gang_shangxiang"].show then
        GameScene.layers["gang_shangxiang"].module:reloaddata(t)
        -- 播放献贡品动画
        GameScene.layers["gang_shangxiang"].module:reateEffect()
    end

    
    runGamePrompt({msg = "公会经验增加"..t.totalcontribution.."点"..",".."个人贡献增加"..t.contribution.."点"})
    UIRequest({type =1001})
end

-----------------------------------------------------------------------------------------
--工会商店

function UIGangShopGoodsView(t)
    print("公会商店2252，接受客户端数据")
    -- if GameScene.layers["guild_shop"].show then
    --     GameScene.layers["guild_shop"].module:reloaddata(t)
    -- end

    if  GameScene.layers["activity"].module.pageTable[162] and GameScene.layers["activity"].module.pageTable[162].module.show then
        print("gangshop==")
        GameScene.layers["activity"].module.pageTable[162].module:reloadData(t)
    end
end

function UIGangShopBuyGoods(t)
    print("公会商店2253，接受客户端数据")
    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 2252})
        UIRequest({type =1001})
    end)
end

-------------------------------------------------------------------------------------------
--公会动态
function UIGangUserGang2Opts(t)
    print("公会2254，接受客户端数据")
    gameWindows:openWindow("guildlegion",t)

end

function UIGangUserGang2Impeach(t)
    print("公会2255，接受客户端数据")

    if t.result and t.result == 0 then
        runGamePrompt({msg = "弹劾成功"})
        UIRequest({type = 2236})
    elseif t.result and t.result == 2006 then
        runGamePrompt({msg = "会长离线未超过7天，不可弹劾"})
    elseif t.result and t.result == 2007 then
        -- runGamePrompt({msg = "会长已被弹劾"})
        runGamePrompt({msg = "已有人提出弹劾"})
    end

end

function UIGangUserGang2Fishpond(t)
    print("公会2256，接受客户端数据")
    -- printT(t)
    if GameScene.layers["gang_xianchi"].show then
        GameScene.layers["gang_xianchi"].module:reloaddata(t.data)
    end
end

function UIGangUserGang2FishpondFeed(t)
    print("公会2257，接受客户端数据")
    -- printT(t)

    if next(t.changexianchiLevelData) and GameScene.layers["gang_xianchi"].show then
        if t.changexianchiLevelData.status == "xc_level" then
            -- 仙池等级升级
            GameScene.layers["gang_xianchi"].module:xianchilevelup(t.changexianchiLevelData)
        elseif t.changexianchiLevelData.status == "xc_quality" then
            -- 仙池品级升级

            GameScene.layers["gang_xianchi"].module:xianchiqualityup(t.changexianchiLevelData)
        end
        
    end

    -- -- 获取工会经验／贡献值／进度 提示
    -- if GameScene.layers["gang_xianchi"].show and next(t.getChangedata) then
    --     GameScene.layers["gang_xianchi"].module:showGetPoint(t.getChangedata)
    -- end
    
    if GameScene.layers["gang_xianchi"].show then
        GameScene.layers["gang_xianchi"].module:reloaddata(t.xianchidata, t.getChangedata)
    end

    if GameScene.layers["gang_xianchi"].show then
        GameScene.layers["gang_xianchi"].module:delayfunction()
        -- GameScene.layers["gang_xianchi"].module:actionSoap(t.getChangedata,t.reward)
    end

    -- if next(t.getChangedata) then
    --     runGamePrompt({msg = "获得公会经验:"..t.getChangedata.gang_exp..",获得公会贡献值:"..t.getChangedata.contribution})
    -- end
    

    if next(t.changeGangLevelData) and GameScene.layers["gang_xianchi"].show then
        GameScene.layers["gang_xianchi"].module:ganglevelup(t.changeGangLevelData)
    end



    if next(t.reward) and GameScene.layers["gang_xianchi"].show then
        showRewardPopupWindow(t.reward,nil,nil)
        updateDataLife(t.reward)
    end

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
end

function UIGangUserGang2FishpondReward(t)
    print("公会2258，接受客户端数据")
    -- printT(t)
    if next(t.reward) and GameScene.layers["gang_xianchi"].show then
        showRewardPopupWindow(t.reward,nil,function()
            UIRequest({type = 1001})
            UIRequest({type = 2256})
        end)
    end
end

function UIGangUserGang2MSetName(t)
    print("公会2259，接受客户端数据")
    if t.result and t.result == 0 then
        runGamePrompt({msg = "修改成功"})
        UIRequest({type = 2236})
        UIRequest({type = 1001})
    elseif t.result and t.result == 2001 then
        runGamePrompt({msg = "公会名重复，修改失败"})
    else
        runGamePrompt({msg = "修改失败"})
    end
end

function UIGangUserGang2DailyReward(t)
    print("公会2260，接受客户端数据")
    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 2236})
        UIRequest({type =1001})
    end)
end


function UIUserGang2FishpondPointRank( t )
    print("公会2261，接受客户端数据")
    -- printT(t)
    if gameWindows.windows["guildxianchirank"].show then
        gameWindows.windows["guildxianchirank"].module:createRankList(t.players)
    end
end
--工会技能
function UIGang2Skill( t )
    print("公会2262，接受客户端数据")
    printT(t)
    if GameScene.layers["gang_skill"].show then
        GameScene.layers["gang_skill"].module:reloaddata(t)
    end
end
--学习工会技能
function UIGang2SkillStudy( t )
    print("公会2263，接受客户端数据")
    printT(t)

    GameScene:addUpdate(10023)

    if GameScene.layers["gang_skill"].show then
        GameScene.layers["gang_skill"].module:reloaddata(t)
    end
end


--
function UIGang2Boss( t )
    print("4840，接受客户端数据")
    printT(t)
    if GameScene.layers["guildboss"].show then
        GameScene.layers["guildboss"].module:reloaddata(t)
    end
end

function UIGang2BossInspire(t)
    print("4843，接受客户端数据")
    printT(t)
    if t.result and t.result > 0 then
        runGamePrompt({msg = gameConfig.strings:inspireTip(t.result)})
    end
    UIRequest({type = 1001})
end

function UIGang2BossRank( t )
    print("4841，接受客户端数据")
    printT(t)

    if GameScene.layers["gangbossrank"].show then
        GameScene.layers["gangbossrank"].module:ReloadData(t)
    end

end

function UIGang2RoleRank( t )
    print("4842，接受客户端数据")
    printT(t)

    if gameWindows.windows["gangrank2"].show then
        gameWindows.windows["gangrank2"].module:reload(t.rolerank)
    end

end

function UIGang2BossBattle(t)
    print("4844,接受客户端数据")
    --printT(t)

    if GameScene.layers["guildboss"].show then
        GameScene.layers["guildboss"].module:battleCallback(t)
    end

    UIRequest({type = 1001})
    UIRequest({type = 4840})

end

function UIGang2BossNotify(t)
    print("4845,接受客户端数据")
    printT(t)

    if GameScene.layers["guildboss"].show then
        GameScene.layers["guildboss"].module:setNotify(t.notify)
    end

end

function UIGang2BossChange(t)
    print("4846,接受客户端数据")
    printT(t)

    if GameScene.layers["guildboss"].show then
        UIRequest({type = 4840})
    end

end

function UIGang2GroundQuery(t)
    print("5150,接受客户端数据")
    printT(t)
    if GameScene.layers["gang_guard"].show then
        GameScene.layers["gang_guard"].module:reloaddata(t.data)
    end

    if gameWindows.windows["guardrewardview"].show then
        gameWindows.windows["guardrewardview"].module:reload(t.data)
    end

end

function UIGang2GroundStart(t)
    print("5151,接受客户端数据")
    printT(t)
    if t.status == 0 then
        if GameScene.layers["gang_guard"].show then
            GameScene.layers["gang_guard"].module:readyStart(t)
        end
    elseif t.status == 1 then
        runGamePrompt({msg = "次数不足"})
    elseif t.status == 2 then
        runGamePrompt({msg = "上局游戏未结束"})
    elseif t.status == 3 then
        runGamePrompt({msg = "消耗不足"})
    end
    
    UIRequest({type = 1001})

end

function UIGang2GroundGetHogs(t)
    print("5152,接受客户端数据")
    printT(t)

    if t.status == 0 then 
        if GameScene.layers["gang_guard"].show then
            GameScene.layers["gang_guard"].module:getMouseData(t)
        end
    --elseif t.status == 1 then
        --runGamePrompt({msg = "还没有开始游戏"})
    --elseif t.status == 2 then
        --runGamePrompt({msg = "游戏超时"})
    --elseif t.status == 3 then
        --runGamePrompt({msg = "怪物还没有杀完"})
    else
        
    end


end

function UIGang2GroundCatchHog(t)
    print("5153,接受客户端数据")
    printT(t)
    if t.status == 0 then 
        if GameScene.layers["gang_guard"].show then
            GameScene.layers["gang_guard"].module:catchMouseData(t)
        end
    -- elseif t.status == 1 then
    --     runGamePrompt({msg = "还没有开始游戏"})
    -- elseif t.status == 2 then
    --     runGamePrompt({msg = "该格子中没有怪物"})
    -- elseif t.status == 3 then
    --     runGamePrompt({msg = "生命值已为0"})
    end

end

function UIGang2GroundBoxRewards(t)
    print("5154,接受客户端数据")
    printT(t)
    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 5150})
        UIRequest({type = 2230})
    end)
    UIRequest({type = 1001})

end

function UIGang2GroundRank(t)
    print("5155,接受客户端数据")
    printT(t)

    if t.guardRankId == 0 then
        if GameScene.layers["guardRank"].show then
            GameScene.layers["guardRank"].module:ReloadGuildData(t)
        end
    else
        if GameScene.layers["guardRank"].show then
            GameScene.layers["guardRank"].module:ReloadZoneData(t)
        end
    end

end

function UIGang2GroundGameOver(t)
    print("5156,接受客户端数据")
    printT(t)

    gameWindows:openWindow("guardReward",t,function()
        showRewardPopupWindow(t.reward,nil,function()
            
        end)
        UIRequest({type = 1001})
    end)
    UIRequest({type = 5150})
    
    -- showRewardPopupWindow(t.reward,nil,function()
    -- end)
    -- UIRequest({type = 1001})

end

--
function UIGangApplyLimit(t)
    print("2265，接受客户端数据")
    printT(t)

    if GameScene.layers["gang_manager"].show then
        GameScene.layers["gang_manager"].module:reloadlimitLv(t)
    end

end

function UIUserGang2Disband(t)
    print("公会2266，接受客户端数据")
    -- printT(t)

    UIRequest({type = 2230,param = "main"})
end


function UIUserGang2ReqCancel(t)
    print("公会2267，接受客户端数据")
    -- printT(t)

    if t.result and t.result == 2007 then
        --runGamePrompt({msg = "对方已拒绝该申请"})
    elseif t.result and t.result == 2008 then
        runGamePrompt({msg = "已加入公会"})
        UIRequest({type = 2230,param = "main"})
    end

    UIRequest({type = 2232})

end


--工会盛宴查询
function UIGang2FeastCheck( t )
    print("帮会2271，接受客户端数据")
    printT(t)

    if gameWindows.windows["openfeastinfo"].show then
        gameWindows.windows["openfeastinfo"].module:reload(t.data)
    end
end

--创建或加入工会盛宴
function UIGang2CreateJoinFeast( t )
    print("帮会2272，接受客户端数据")
    printT(t)
    
    -- if GameScene.layers["guildfeast"].show then
    --     GameScene.layers["guildfeast"].module:reloaddata(t.data)
    -- end
    GameScene:shiftLayer("guildfeast",nil,t.data)
    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
end


--领取盛宴奖励
function UIGang2GetFeastReward( t )
    print("帮会2273，接受客户端数据")
    printT(t)

    if GameScene.layers["guildfeast"].show then
        if GameScene.layers["guildfeast"].module.needoutext then
            GameScene.layers["guildfeast"].module.needoutext = false
        end
    end
    if not next(t.reward) then
        return
    end

    local callback = nil  
    local roleinfo = table.copy(GameScene.roleinfo)
    local changeCoin,changeGold,specials,changeExpNum = updateDataLife(t.reward)
    if changeExpNum and (changeExpNum > 0) and (roleinfo.level < table.getTableLength(gamedata.config.role_exp)) then
        callback = function()
            local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function() 
                gameWindows:openWindow("userexpup",{roleinfo = roleinfo, expup = changeExpNum,},nil)
            end))
            GameScene.rootLayer:runAction(sequence)  
        end    
    end
    if changeCoin then
        GameScene:coin_effect(1,540,960,0.5)
    end
    if changeGold then
        GameScene:coin_effect(2,540,960,0.5)
    end

    if t.beinum then
        -- gameWindows:openWindow("feastjiesuan", {data = t}, callback)
        
        -- if GameScene.layers["guildfeast"].show then
        --     GameScene.layers["guildfeast"].module:jiesuanFeastShouyi(t)
        -- end

        if GameScene.layers["guildfeast"].show then
            GameScene.layers["guildfeast"].module:awardCallback(t)
        end
    else
        if next(t.reward) then
            --补发奖励
            gameWindows:openWindow("feastjiesuan", {data = t, jieshutype = "repair"}, callback)
            UIRequest({type = 2230})
        end
    end
    UIRequest({type = 1001})
end

--盛宴刷新
function UIGang2FeastRefresh( t )
    print("帮会2274，接受客户端数据")
    printT(t)
    if GameScene.layers["guildfeast"].show then
        GameScene.layers["guildfeast"].module:reloaddata(t.data)
    else
        if t.isNotOpen == false then
            GameScene:shiftLayer("guildfeast",nil,t.data)
        end
    end
end
--宴会手动开启
function UIGang2FeastHandOpen( t )
    print("帮会宴会2275，接受客户端数据")
    printT(t)
    if GameScene.layers["guildfeast"].show then
        GameScene.layers["guildfeast"].module:reloaddata(t.data)
        -- GameScene.layers["guildfeast"].module:handStartFeast()
    end
end
--宴会接龙
function UIGang2FeastAgainOpen( t )
    print("帮会宴会2276，接受客户端数据")
    printT(t)
    gameWindows:closeWindowDirect("gangProduceAgain")
    if GameScene.layers["guildfeast"].show then
        GameScene.layers["guildfeast"].module:reloaddata(t.data)
        GameScene.layers["guildfeast"].module:createTimeSaoguangAnim()
    end
    -- runGamePrompt({msg = "接龙成功，获得3分钟举办奖励"})
    UIRequest({type = 1001})
end
--切出盛宴
function UIGang2BackFeast( t )
    print("帮会2277，接受客户端数据")
    printT(t)
    gameTimer:UnrigistTime("feasttime")
    gameTimer:UnrigistTimeFunc("feasttime")
    if GameScene.layers["guildfeast"].show then
        GameScene.layers["guildfeast"].module:stopDaojishiAnim()
    end
    UIRequest({type = 2230,param = "activity"})
    UIRequest({type = 1001})
end


--盛宴设置
function UIGangExpChangeFeast( t )
    print("帮会2278，接受客户端数据")
    runGamePrompt({msg = "设置成功"})
    if gameWindows.windows["openfeastinfo"].show then
        gameWindows.windows["openfeastinfo"].module.data.ischange = t.method
    end
end

---------------公会篝火-------------------------------
--工会澡堂查询
function UIGang2BathCheck( t )
    print("帮会2281，接受客户端数据")
    printT(t)

    if gameWindows.windows["openzaotanginfo"].show then
        gameWindows.windows["openzaotanginfo"].module:reload(t.data)
    end
end

--创建或加入工会澡堂
function UIGang2CreateJoinBath( t )
    print("帮会2282，接受客户端数据")
    printT(t)
    GameScene:shiftLayer("gang_xianchi2",nil,t.data)
    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
end


--领取澡堂奖励
function UIGang2GetBathReward( t )
    print("帮会2283，接受客户端数据")
    printT(t)

    if GameScene.layers["gang_xianchi2"].show then
        if GameScene.layers["gang_xianchi2"].module.needoutext then
            GameScene.layers["gang_xianchi2"].module.needoutext = false
        end
    end
    if not next(t.reward) then
        return
    end

    local callback = nil  
    if t.beinum then
        -- gameWindows:openWindow("zaotangjiesuan", {data = t}, callback)
        -- if GameScene.layers["gang_xianchi2"].show then
        --     GameScene.layers["gang_xianchi2"].module:jiesuanBathShouyi(t)
        -- end

        if GameScene.layers["gang_xianchi2"].show then
            GameScene.layers["gang_xianchi2"].module:awardCallback(t)
        end
    else
        if next(t.reward) then
            --补发奖励
            gameWindows:openWindow("zaotangjiesuan", {data = t, jieshutype = "repair"}, callback)
            UIRequest({type = 2230})
        end
    end
    UIRequest({type = 1001})
end

--澡堂刷新
function UIGang2BathRefresh( t )
    print("帮会2284，接受客户端数据")
    printT(t)
    if GameScene.layers["gang_xianchi2"].show then
        GameScene.layers["gang_xianchi2"].module:reloaddata(t.data)
    else
        if t.isNotOpen == false then
            GameScene:shiftLayer("gang_xianchi2",nil,t.data)
        end
    end
end
--澡堂收到开启
function UIGang2BathHandOpen( t )
    print("公会篝火2285，接受客户端数据")
    printT(t)
    if GameScene.layers["gang_xianchi2"].show then
        GameScene.layers["gang_xianchi2"].module:reloaddata(t.data)
        -- GameScene.layers["gang_xianchi"].module:handStartBath()
    end
end
--澡堂接龙
function UIGang2BathAgainOpen( t )
    print("公会篝火2286，接受客户端数据")
    printT(t)
    gameWindows:closeWindowDirect("gangProduceAgain")
    if GameScene.layers["gang_xianchi2"].show then
        GameScene.layers["gang_xianchi2"].module:reloaddata(t.data)
        GameScene.layers["gang_xianchi2"].module:createTimeSaoguangAnim()
    end
    -- runGamePrompt({msg = "接龙成功，获得3分钟举办奖励"})
    
    UIRequest({type = 1001})
end
--切出澡堂
function UIGang2BackBath( t )
    print("帮会2287，接受客户端数据")
    printT(t)
    gameTimer:UnrigistTime("bathtime")
    gameTimer:UnrigistTimeFunc("bathtime")

    gameTimer:UnrigistTime("updatabathtime")
    gameTimer:UnrigistTimeFunc("updatabathtime")
    UIRequest({type = 2230,param = "activity"})
    UIRequest({type = 1001})
end
  by  