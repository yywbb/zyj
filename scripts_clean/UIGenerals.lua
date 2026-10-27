--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-13
-- Time: 上午10:59
-- To change this template use File | Settings | File Templates.
--

function UIAllGeneral(t)
    print("10023 接受客户端数据")
    -- printT(t)

    GameScene.layers["generals"].module:ReloadGenerals(t.generals)
    if GameScene.layers["generals"].show then
        GameScene.layers["generals"].module:showGenerals()
    end

    GameScene.layers["generalup"].module:ReloadGenerals(t.generals)
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:ReloadData()
    end

    if GameScene.layers["exclusiveArtifact"].show then
        GameScene.layers["exclusiveArtifact"].module:reload()
    end

end

function UIOffGeneral(t)
    print("10024 接受客户端数据")

    GameScene.layers["qiankunlu"].module:setGeneralData(t.offgenerals)
    
    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData()
    end

    if GameScene.layers["change"].show then
        GameScene.layers["change"].module:setOffGeneralData(t.offgenerals)
    end
end


function UIGeneralFragmentsList(t)
    print("1012 接受客户端数据")
    --printT(t)
    GameScene.layers["qiankunlu"].module:setGeneralFragmentData(t.generalfragments)
    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData()
    end
    GameScene.layers["generals"].module:ReloadFragments(t)
    if GameScene.layers["generals"].show then
        GameScene.layers["generals"].module:showFragments()
    end
end

function UIGeneralFragmentById(t)
    print("10121 接受客户端数据")
    --printT(t)
    if t.order == 1 then
        setFragmentData(t.fragment)
    elseif t.order == 2 then
        gameWindows.windows["generalInfo"].module:setFragmentData(t.fragment)
    end

end


function UIGeneralRecruitQuery(t)
    print("招募查询1402 接受客户端数据")
    printT(t)

    for i=1,3 do
        if gamedata.config.recruit_basic[tostring(i)].openfreerecruit == 1 then
        else
            if t["generalrecruit"][tostring(i)].timer > 0 then
                gameTimer:rigistTime("recruitTimer"..i,t["generalrecruit"][tostring(i)].timer)
            end
        end
    end

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:reloadrecruit(t.generalrecruit)
    end

    if gameWindows.windows["recruit"].show then
        gameWindows.windows["recruit"].module:requestPropNum()
    end

end


function UIGeneralRecruit(t)
    print("招募1403 接受客户端数据")
    printT(t)

    local callback = function()
        --UIRequest({type = 1400})
        --UIRequest({type = 1001})
    end

    if t.method == 1 then

        gameWindows:openWindow("recruit",{type = "one", data = t },callback)
    elseif t.method == 2 then
        if t.pos == 1 then
            gameWindows:openWindow("recruit",{type = "ten", data = t },callback)
            GameScene:addUpdate(1200)
        else
            gameWindows:openWindow("recruit",{type = "ten", data = t },callback)
        end
    elseif t.method == 3 then
        if t.reward and next(t.reward) then
            -- gameWindows:closeAllWindowDirect()
            showRewardPopupWindow(t.reward,callback)
        end
    end
    
    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:recruitshopquery()
    end

    UIRequest({type = 1402})
    UIRequest({type = 1001})
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10211)
    GameScene:addUpdate(1200)
    GameScene:addUpdate(11112)
    UIRequest({type = 7110})
end

function UIRecruitNewTempQuery(t)
    print("7110， 新招募查询")
    printT(t)

    if gameWindows.windows["recruit"].show then
        gameWindows.windows["recruit"].module:setFengshenRefresh(t.data)
    end

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:setFengshenHint(t.data)
    end

end

function UIRecruitNew(t)
    print("7111， 新招募")
    printT(t)

    local _data = {
        method = 2,
        pos = 4,
        gets = t.data.gets,
    }

    gameWindows:openWindow("recruit",{type = "ten", data = _data },nil)
    UIRequest({type = 1402})
    UIRequest({type = 7110})
end

function UIRecruitNewRefresh(t)
    print("7112， 招募数据刷新")
    printT(t)

    local _data = {
        method = 2,
        pos = 4,
        gets = t.data.gets,
    }

    gameWindows:openWindow("recruit",{type = "ten", data = _data },nil)
    UIRequest({type = 7110})

    UIRequest({type = 1001})
end

function UIRecruitNewTempSave(t)
    print("7113， 招募保存数据")
    printT(t)

    
    if t.reward and next(t.reward) then
        gameWindows:closeAllWindowDirect()
        showRewardPopupWindow(t.reward)
    end

    UIRequest({type = 7110})
    UIRequest({type = 1402})
    UIRequest({type = 1001})
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10211)
    GameScene:addUpdate(1200)
    GameScene:addUpdate(11112)
end

function UIGeneralBreakPreview(t)
    print("武将突破预览1023， 接受客户端数据")
    printT(t)
    if gameWindows.windows["generalUp"].show then
        gameWindows.windows["generalUp"].module:setTupoNext(t)
    end
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:setTupoNext(t)
    end
end

function UIGeneralBreak(t)
    print("武将突破1017， 接受客户端数据")

    --printT(t)
    --resetGeneralUpInfo(t,function() GameScene:UpdatePresentLayer() end)
    GameScene:addUpdate(10030)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(1200)
    if t.ison then
        GameScene:addUpdate(10021)
    else
        GameScene:addUpdate(10024)
    end
    GameScene:addUpdate(10023)
    --GameScene:addUpdate(11112)
    UIRequest({type = 1001})

    GameScene:UpdatePresentLayer()
    if gameWindows.windows["generalUp"].show then
        gameWindows.windows["generalUp"].module:resetPage_tupo(t)
    end
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:resetPage_tupo(t)
    end

    UIRequest({type = 10322, param = {"generals"}})
end


function UIGeneralInheritConfirm(t)
    print("武将传承确认1011， 接受客户端数据")
    --printT(t)

    --setInheritResult(t,function() GameScene:UpdatePresentLayer() end)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)
    --UIRequest({type = 1002})

    GameScene:UpdatePresentLayer()
    if gameWindows.windows["generalInfo"].show then
        gameWindows.windows["generalInfo"].module:reloaddata(t)
    end

end

function UIGeneralInheritPreview(t)
    print("武将传承预览1010， 接受客户端数据")
    --printT(t)
    if gameWindows.windows["generalInfo"].show then
        if t.inheritrequest.method == 1 then
            --setPreview(t.previewData,"normal")
            gameWindows.windows["generalInfo"].module:setInheritPreview(t.previewData,"normal")
            UIRequest({type = 1010, fid = t.inheritrequest.fid, tid = t.inheritrequest.tid,method = 2 })
        elseif t.inheritrequest.method == 2 then
            --setPreview(t.previewData,"special")
            gameWindows.windows["generalInfo"].module:setInheritPreview(t.previewData,"special")
        end
    end

end


function UIGeneralFosterPreview(t)
    print("武将培养1013， 接受客户端数据")
    --printT(t)

    UIRequest({type =1001})
    GameScene:addUpdate(1200)

    --GameScene:UpdatePresentLayer()
    if gameWindows.windows["generalInfo"].show then
        gameWindows.windows["generalInfo"].module:setTrainResuit(t)
    end

    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:setTrainResuit(t)
    end
end

function UIGeneralFosterConfirm(t)
    print("武将培养1014， 接受客户端数据")
    printT(t)
    --resetGeneralTrain(t,function() GameScene:UpdatePresentLayer() end)

    if t.ison then
        GameScene:addUpdate(10021)
    else
        GameScene:addUpdate(10024)
    end
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)
    --UIRequest({type = 1002})

    GameScene:UpdatePresentLayer()
    if gameWindows.windows["generalInfo"].show then
        gameWindows.windows["generalInfo"].module:reloaddata(t)
    end

    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:ReloadData(t)
    end
end

function UIGeneralCompound(t)
    print("武将合成1016， 接受客户端数据")
    --printT(t)
    t.opt = 2
    gameWindows:openWindow("recruit",{type = "one", data = t },function() GameScene:UpdatePresentLayer() end)

    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10211)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(11112)

    --GameScene:UpdatePresentLayer()
end

function UIGeneralExchangeQuery(t)
    print("武将兑换查询10211， 接受客户端数据")
    --printT(t)

    if GameScene.layers["generals"].show then
        GameScene.layers["generals"].module:ReloadData(t)
    end
end

function UIGeneralExchange(t)
    print("武将兑换1021， 接受客户端数据")
    --printT(t)

--    if ui.IDconfig(t.get["1"].cid).staffType == "general" then
--        gameWindows:openWindow("recruit",{type = "one", data = {generals = t.get,fragments = {},opt = 2} },nil)
--    else
--        gameWindows:openWindow("recruit",{type = "one", data = {generals = {},fragments = t.get, opt = 2} },nil)
--    end
--    t.opt = 2
--    gameWindows:openWindow("recruit",{type = "one", data = t },function() GameScene:UpdatePresentLayer() end)

    showRewardPopupWindow(t.gets,nil,function()
        UIRequest({type = 1001})
    end)

    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10211)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(11112)

    UIRequest({type = 1001})

end

function UIUseExpDan(t)
    print("武将吃经验丹 1038， 接受客户端数据")
    --printT(t)
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10021)

    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:ReloadData_up()
    end
end

function UIGeneralAwaken(t)
    print("武将觉醒1025， 接受客户端数据")
    printT(t)

    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:resetPage_Awaken(t)
    end
    UIRequest({type = 1001})    
end


function UIGeneralBestQuery(t)
    print("3780， 接受客户端数据")
    printT(t)

    GameScene.layers["qiankunlu"].module:setRedFragmentData(t.redfragment)
    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData()
    end

    GameScene.layers["generals"].module:ReloadRedFragments(t.redfragment)
    if GameScene.layers["generals"].show then
        GameScene.layers["generals"].module:showRedFragments()
    end

end

function UIRedFragments(t)
    print("10030， 接受客户端数据")
    printT(t)

    GameScene.layers["qiankunlu"].module:setRedFragmentData(t.redfragment)
    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData()
    end

    GameScene.layers["generals"].module:ReloadRedFragments(t.redfragment)
    if GameScene.layers["generals"].show then
        GameScene.layers["generals"].module:showRedFragments()
    end

end

function UIGeneralRecruitShopQuery( t )
    print("招募商店查询5321 接受客户端数据")
    printT(t)

    if gameWindows.windows["recruitshop"].show then
        gameWindows.windows["recruitshop"].module:reload(t.shop)
    end

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:reloadrecruitshop(t.shop)
    end
end


function UIGeneralRecruitReward( t )
    print("招募商店兑换5322 接受客户端数据")
    printT(t)

    if gameWindows.windows["recruitshop"].show then
        gameWindows.windows["recruitshop"].module:reload(t.shop)
    end

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:reloadrecruitshop(t.shop)
    end

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)
end

function UIGeneralArtifactLevelup( t )
    print("神器升级1026 接受客户端数据")
    printT(t)
    if GameScene.layers["exclusiveArtifactUp"].show then
        GameScene.layers["exclusiveArtifactUp"].module:reloadGeneralData(t.nextGeneral)
    end
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    UIRequest({type = 1001})  
end

function UIGeneralSkillLevelUp( t )
    print("技能升级1028 接受客户端数据")
    printT(t)
    
    runGamePrompt({msg = "升级成功"})
    
    GameScene:addUpdate(10030)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(1200)
    if t.ison then
        GameScene:addUpdate(10021)
    else
        GameScene:addUpdate(10024)
    end
    GameScene:addUpdate(10023)
    --GameScene:addUpdate(11112)
    UIRequest({type = 1001})


    -- GameScene:UpdatePresentLayer()

    if gameWindows.windows["skillLevelUp"].show then
        gameWindows.windows["skillLevelUp"].module:levelUpCallback(t)
    end
end

function UIGeneralUpStar(t)
    print("武将升星1029 接受客户端数据")
    printT(t)
    GameScene:addUpdate(10030)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(1200)
    if t.ison then
        GameScene:addUpdate(10021)
    else
        GameScene:addUpdate(10024)
    end
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})

    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:upStarCallback(t)
    end
    
end


function UIGeneralSkillLevelUpCostQuery( t )
    print("技能升级 消耗查询 10280")
    if gameWindows.windows["skillLevelUp"].show then
        gameWindows.windows["skillLevelUp"].module:reloadCost(t)
    end
end


function UIGeneralXiuLianLevelInfo(t)
    printT(t,"武将修炼信息5511 接受客户端数据")
    if t.isUpdate and t.isUpdate == 1 then
        GameScene:addUpdate(10021)
    end
end

function UIGeneralXiuLianInfo(t)
    print("武将修炼信息5512 接受客户端数据")
    printT(t)
   
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:getXiuLianData(t)
    end
end

function UIGeneralXiuLian(t)
    print("武将修炼信息5513 接受客户端数据")
    printT(t)
    if t.ison then
        GameScene:addUpdate(10021)
    else
        GameScene:addUpdate(10024)
    end
    
    GameScene:addUpdate(10023)
    
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:xiuLianSuccess(t)
    end

    UIRequest({type = 1001})
end


function UIPartnerFeiSheng(t)
    print("武将飞升信息7001 接受客户端数据")
    printT(t)
    
    GameScene:addUpdate(10030)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(1200)
    if t.ison then
        GameScene:addUpdate(10021)
    else
        GameScene:addUpdate(10024)
    end
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})

    GameScene:UpdatePresentLayer()
    -- if gameWindows.windows["generalUp"].show then
    --     gameWindows.windows["generalUp"].module:resetPage_tupo(t)
    -- end
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:feiShengCallback(t.general)
    end

    -- if gameWindows.windows["generalFeiSheng"].show then
    --     gameWindows.windows["generalFeiSheng"].module:feiShengCallback(t.general)
    -- end

    -- if GameScene.layers["generalFeiSheng"].show then
    --     GameScene.layers["generalFeiSheng"].module:feiShengCallback(t.general)
    -- end

    if GameScene.layers["lead"].show then
        GameScene.layers["lead"].module:pageDataCallback("feisheng","feiShengCallback",t.general)
    end
        
    UIRequest({type = 10322, param = {"generals"}})
end

function UIGeneralChangeBreakSkill(t)
    print("7021 接受客户端数据")
    printT(t)

    GameScene:addUpdate(10024)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(1200)
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:ReloadData()
    end
    if GameScene.layers["lead"].show then
        UIRequest({type = 1054, param = "update"})
    end

    if gameWindows.windows["changebreakskill"].show then
        gameWindows:closeWindowDirect("changebreakskill")
    end

    runGamePrompt({msg = "成功更换突破技"})

    UIRequest({type = 1001})
end

function UIGeneralFosterAutomatic(t)
    print("1126 接受客户端数据")
    printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1012)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10031)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10211)

    GameScene:addUpdate(1200)
    GameScene:addUpdate(5402)

    --GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    if gameWindows.windows["generalInfo"].show then
        gameWindows.windows["generalInfo"].module:reloaddata(t)
    end

    if gameWindows.windows["generalcultivate"].show then
         gameWindows.windows["generalcultivate"].module:reloadData(t)
    end
    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:ReloadData(t)
    end
    UIRequest({type = 1001})
    --UIRequest({type = 3705,iid = t.general.iid})
end