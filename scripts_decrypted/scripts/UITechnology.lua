--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/3
-- Time: 下午6:22
-- To change this template use File | Settings | File Templates.
--

function UITechGeneralList(t)
    print("科技升级武将列表18001 接受客户端数据")
    --printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reloadData",t.data)
        -- GameScene.layers["devil"].module:reloadData(t.data)
    end

end

function UITechList(t)
    print("科技请求1800 接受客户端数据")

end

function UITechUpgrade(t)
    print("科技升级1801 接受客户端数据")

end

--  mowang

function UIDevilStatus(t)
    print("1805 接受客户端数据")

end

function UIDevilExchangeFragment(t)
    print("1806 接受客户端数据")

end

function UIDevilUp(t)
    print("1807 接受客户端数据")

end


--
function UIDevilStatus2(t)
    print("1808 接受客户端数据")
    --printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reloadData",t.data)
        -- GameScene.layers["devil"].module:reload(t)
    end

end

function UIDevilLevel1Exp(t)
    print("1809 接受客户端数据")
    --printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","checkuplv1",t.status)
        -- GameScene.layers["devil"].module:checkuplv1(t.status)
    end

    UIRequest({type = 1808})
    UIRequest({type = 18001})

    GameScene:addUpdate(1002,"devil")
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10211)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)

end

function UIDevilLevel2Up(t)
    print("1810 接受客户端数据")
    --printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reload",t)
        GameScene.layers["devil"].module:pageDataCallback("mochong","checkuplv2",t)
        -- GameScene.layers["devil"].module:reload(t)
        -- GameScene.layers["devil"].module:checkuplv2(t)
    end

    GameScene:addUpdate(1002,"devil")
end


-----------------------
-----------------------
-- function UIPetQuery(t)
--     print("1040 接受客户端数据")
--     --printT(t)

--     if GameScene.layers["devil"].show then
--         GameScene.layers["devil"].module:reload(t)
--     end

-- end

-- function UIPetFragment(t)
--     print("1044 接受客户端数据")
--     --printT(t)

--     if GameScene.layers["devil"].show then
--         GameScene.layers["devil"].module:setGetPetNode(t)
--     end

--     if gameWindows.windows["devourinfo"].show then
--         gameWindows.windows["devourinfo"].module:setfragment(t)
--     end

-- end

function UIPetCompound(t)
    print("1045 接受客户端数据")
    --printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reload",t)
        -- GameScene.layers["devil"].module:reload(t)
    end


end

-- function UIPetSet(t)
--     print("1043 接受客户端数据")
--     --printT(t)

--     if GameScene.layers["devil"].show then
--         GameScene.layers["devil"].module:reload(t)
--     end


-- end

function UIPetLevel1Up(t)
    print("1041 接受客户端数据")
    --printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reload",t)
        -- GameScene.layers["devil"].module:reload(t)
    end

    GameScene:addUpdate(1002,"devil")
    -- GameScene:addUpdate(1012)
    -- GameScene:addUpdate(10211)
    -- GameScene:addUpdate(10023)
    -- GameScene:addUpdate(10024)

end

function UIPetLevel2Up(t)
    print("1042 接受客户端数据")
    --printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reload",t)
    end

    GameScene:addUpdate(1002,"devil")
end


---------------------------------------新版接口---------------------------------------
---------------------------------------新版接口---------------------------------------
---------------------------------------新版接口---------------------------------------

function UIPetQuery(t)
    print("魔宠查询1040，接受客户端数据")
    printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reload",t.petsdata)
        -- GameScene.layers["devil"].module:reload(t.petsdata)
    end

    if gameWindows.windows["godCompetitionPetList"].show then
        gameWindows.windows["godCompetitionPetList"].module:reload(t.petsdata)
    end

    GameScene.layers["qiankunlu"].module:setPetData(t.petsdata)
end

function UIPetSet(t)
    print("魔宠上阵1043，接受客户端数据")
    -- printT(t)
    -- GameScene:shiftLayer("devil","up")
    UIRequest({type = 1044})
    
    UIRequest({type = 1040})

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","passiveSkillReload",t.skilldata,true)
        -- GameScene.layers["devil"].module:passiveSkillReload(t.skilldata,true)
    end
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
end

function UIPetFragment(t)
    print("魔宠碎片查询1044，接受客户端数据")
    -- printT(t)
    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","getMochongFragmentData",t.fragment)

    end
    

end

function UIPetStageUp( t )
    print("魔宠进阶1046，接受客户端数据")
    printT(t)
    
    if GameScene.layers["devil"].show then

        GameScene.layers["devil"].module:pageDataCallback("mochong","getSpendPropsData",t.spendprops,true)
        GameScene.layers["devil"].module:pageDataCallback("mochong","getMochongFragmentData",t.fragment)
        GameScene.layers["devil"].module:pageDataCallback("mochong","passiveSkillReload",t.skilldata)
        GameScene.layers["devil"].module:pageDataCallback("mochong","effectAction")
        GameScene.layers["devil"].module:pageDataCallback("mochong","reload",t.petsdata)

        GameScene.layers["devil"].module:pageDataCallback("shenji","getMochongFragmentData",t.fragment)

        GameScene.layers["devil"].module:pageDataCallback("jinjie","getSpendPropsData",t.spendprops,true)
        GameScene.layers["devil"].module:pageDataCallback("jinjie","getMochongFragmentData",t.fragment)
        GameScene.layers["devil"].module:pageDataCallback("jinjie","effectAction")
        GameScene.layers["devil"].module:pageDataCallback("jinjie","reload",t) 

        GameScene.layers["devil"].module:pageDataSend("mochongdata",{petsData = t.petsdata })

    end

    GameScene.layers["qiankunlu"].module:setPetData(t.petsdata)
    
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    
    UIRequest({type = 1001})
    -- print("测试进阶=-=-=-=-=-=-")
    -- checkFindDragonPush()
end

function checkFindDragonPush()
    print("function checkFindDragonPush()")
    if tonumber(gamedata.config.build["540"].switch) ~= 1 then
        return
    end
    if gamedata.config.xunlong_config.xunlong_push_1 ~= 1 then
        return
    end

    if not GameScene:checkopenlevelbyId(540,true) then
        return
    end

    local curTime = tonumber(os.date("%Y%m%d%H%M%S", gamedata:time()))
    local beginTime = tonumber(gamedata.config.activity_time["150"]["begin"]) 
    local endTime = tonumber(gamedata.config.activity_time["150"]["end"])
    if curTime < beginTime or curTime > endTime then
        return
    end
    
    if CCUserDefault:sharedUserDefault():getBoolForKey("findDragon"..GameScene.roleinfo.id..os.date("%Y-%m-%d")) then 
        return
    end
    UIRequest({type = 7070})
end

function UIPetPassiveSkill( t )
    print("被动技能查询1047，接受客户端数据")
    -- printT(t)
    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","passiveSkillReload",t.skilldata)
        -- GameScene.layers["devil"].module:passiveSkillReload(t.skilldata)
    end
    
end

function UIPetPassiveSkillStudy( t )
    print("被动技能学习1048，接受客户端数据")
    -- printT(t)
    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","passiveSkillReload",t.skilldata,true)
        -- GameScene.layers["devil"].module:passiveSkillReload(t.skilldata,true)
    end
    
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
end

function UIPetPassiveSkillLock( t )
    print("被动技能锁定1060，接受客户端数据")
    -- printT(t)
    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","passiveSkillReload",t.skilldata)
        -- GameScene.layers["devil"].module:passiveSkillReload(t.skilldata)
    end
    if gameWindows.windows["devilSkill"].show then
        gameWindows.windows["devilSkill"].module:changelockData(t.skilldata)
    end
    if gameWindows.windows["devilSkillDetail"].show then
        gameWindows.windows["devilSkillDetail"].module:changelockData(t.skilldata)
    end
end

function UIPetPassiveSkillReset( t )
    print("被动技能重置1061，接受客户端数据")
    -- printT(t)
    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","passiveSkillReload",t.skilldata,true)
        -- GameScene.layers["devil"].module:passiveSkillReload(t.skilldata,true)
    end
    UIRequest({type = 1001})

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
end


function UIPetFragmentCompound( t )
    print("被动技能锁定1049，接受客户端数据")
    -- printT(t)
    if GameScene.layers["devilBag"].show then
        GameScene.layers["devilBag"].module:devilBagCompound(t.compoundData.data)
    end

    UIRequest({type = 1040})

    if tonumber(t.update) == 1 then
        UIRequest({type = 1047,updata = 1})
    end 

    -- print("测试合成=-=-=-=-=-=-")
    -- checkFindDragonPush()
end


function UIPetLevel1Up2(t)
    print("1062，接受客户端数据")
    printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reload",t.petsdata)
        -- GameScene.layers["devil"].module:reload(t.petsdata)
    end

    UIRequest({type = 1001})

    if t.iid and t.iid > 0 then
        if t.petsdata.pets[tostring(t.iid)] then
            if GameScene.layers["devil"].show then
                GameScene.layers["devil"].module:pageDataCallback("shengji","reload",t.petsdata.pets[tostring(t.iid)])
            end
            -- if GameScene.layers["devourcollectup"].show then
            --     GameScene.layers["devourcollectup"].module:reload(t.petsdata.pets[tostring(t.iid)])
            -- end
        end
        runGamePrompt({msg = "升级成功"})
    end

    GameScene.layers["qiankunlu"].module:setPetData(t.petsdata)

    -- print("测试升级=-=-=-=-=-=-")
    -- checkFindDragonPush()
end

function UIPetPassiveSkillRed( t )
    print("被动技能升红 1064，接受客户端数据")
    -- printT(t)
    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","passiveSkillReload",t.skilldata,true)
        -- GameScene.layers["devil"].module:passiveSkillReload(t.skilldata,true)
    end
    UIRequest({type = 1001})

    runGamePrompt({msg = "技能品质提升成功"})

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
end

function UIPetDevour(t)
    print("魔宠 1066，接受客户端数据")
    printT(t)

    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:pageDataCallback("mochong","reload",t.petsdata)
        GameScene.layers["devil"].module:pageDataCallback("mochong","shiftNode","devourNode")

        -- GameScene.layers["devil"].module:reload(t.petsdata)
        -- GameScene.layers["devil"].module:shiftNode("devourNode")
    end

    GameScene.layers["qiankunlu"].module:setPetData(t.petsdata)
end
�/  