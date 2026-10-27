
roleupdatacallback = nil

function setroleupdatacallback(cb)
    roleupdatacallback = cb
end


--无法更新UIlogin 在此处保存
function selectServerIDResultForSaveSession(t)
    printT(t,"selectServerIDResultForSaveSession")
    gamedata.session = t.sid
end


--player info
function UIRoleShow(t)
	print("请求角色信息1001 接收客户端返回数据")
    --printT(t)

    if t.param == "first" then
        local device = require"device"

        return
    end

    if t.info then
        GameScene:setRoleInfo(t.info)

        --uc专用的信息
        local params = {}
        local serverInfo = gameWindows.windows["roleinfo"].module.SelectedServer  --获取服务器的基本数据
        print("t.info------------------------")
        printT(t.info)
        params.roleId = t.info.id   --玩家ID
        params.roleName = t.info.name  --玩家名字
        params.roleLv = t.info.level   --玩家等级
        params.serverId = serverInfo.id   --服务器ID
        params.severName = serverInfo.name  --服务器名字
        params.vip = t.info.vip  --等级
        params.gold = t.info.gold   --玩家元宝
        params.roleuid = LoginScene.roleuid  --玩家uid
        params.servertimes = gamedata:time()

        if GameScene.guid then
         params.paltformGuid = GameScene.guid --平台id
        end
        
        local sdk = require"SDKfunction"
        if sdk:isValid() then
            local device = require"device"
            
            if device.channel == "360" or device.channel == "coolpad" then
                params.platformId = GameScene.guid  --平台的id
                params.platforName = GameScene.guidname  --平台的名字
                printT(params)
                sdk:UserInformation(params)
            elseif device.channel == "qq" or device.channel == "weixin" or device.channel == "qq1" or device.channel == "weixin1" then
                -- local luaj = require "luaj"
                -- local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
                -- local javaMethodName = "UserInformation"
                -- local javaParams = { string.format("%d", params.roleuid), params.roleName, string.format("%d", params.roleLv), params.serverId <= 2 and 1 or params.serverId, params.severName }
                -- local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;)V"
                -- luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
                 local tencentserverid = params.serverId <= 2 and 1 or params.serverId
               params.serverId = tencentserverid
               sdk:UserInformation(params)
               
            else
                printT(params)
                sdk:UserInformation(params)
            end
        end
    end

    if t.param == "role_info" then
        gameTimer:rigistTime("staminanext",t.info["staminanext"])
        gameTimer:rigistTime("staminaall",t.info["staminaall"])
        gameTimer:rigistTime("energynext",t.info["energynext"])
        gameTimer:rigistTime("energyall",t.info["energyall"])
        gameWindows:openWindow("roleinfo",t.info,nil)
    end

    if t.param == "resume" then
        if t.info then
            if gameWindows.windows["roleinfo"].show then
                gameTimer:rigistTime("staminanext",t.info["staminanext"])
                gameTimer:rigistTime("staminaall",t.info["staminaall"])
                gameTimer:rigistTime("energynext",t.info["energynext"])
                gameTimer:rigistTime("energyall",t.info["energyall"])
                gameWindows:openWindow("roleinfo",t.info,nil)
            end
        else
            UIRequest({type = 1001,param = "resume"})
        end

    end

    if roleupdatacallback then
        roleupdatacallback()
        roleupdatacallback = nil
    end

    if t.info and (t.info.coin<0 or t.info.gold<0 or t.info.stamina<0 or t.info.energy<0) then
        UIRequest({type = 1001,param = "error"})
    end
    if gameWindows.windows["robselect"].show then
        gameWindows.windows["robselect"].module:reloadEnergy()
    end
    return 0, nil
end

function UIRoleInfoBasic(t)
    print("请求角色信息999902 接收客户端返回数据")
    if t.msg ~= "" then
        UIRequest({type=999988, msg=t.err, from="net",noneedfix = true})
        UIRequest({type = 1001})
        if gamedata.isdebug then
            runGamePrompt({msg = t.msg})
        end
    end
end

function UIRoleQuery(t)
    print("请求角色信息10011 接收客户端返回数据")

    if t.order == 11001 then
        setEquipStrengthenRole(t.info)
    end

    return 0, nil
end

function UIFirstEnterGame(t)
    print("进入游戏100010 接收客户端返回数据")
    printT(t)
    local serverInfo = gameWindows.windows["roleinfo"].module.SelectedServer  --获取服务器的基本数据
    local ptRoleId = t.roleId
    local ptseverid = serverInfo.id   --服务器ID
    if MYGameSendData then
        MYGameSendData:SendEnterGame(ptseverid,ptRoleId)
    end
end

function  UIRoleLevelUp(t)
    GameScene:setRoleInfo(t.info)
    GameScene:coin_effect(1,540,600,0.5)
    GameScene:coin_effect(2,540,600,0.5)
end


function UIHint(t)
    print("系统提示1032，接受客户端数据")
    printT(t)

    if t.hintChanges and next(t.hintChanges) then
        for k,v in pairs(t.hintChanges) do
            if tonumber(k) == 39 or tonumber(k) == 266 then
                if GameScene.layers["main"].show then
                    GameScene.layers["main"].module:reqChatHint()
                end
            end
        end
    end

    if t.data then
        GameScene:reloadhint(t.data)
        GameScene:reloadNew()
    end

    if t.updatelist and next(t.updatelist) then
        for k,v in pairs(t.updatelist) do
            if v.type == 3000 or v.type == 3010 or v.type == 3015 then
                if GameScene.presentLayer == "chat" then
                    UIRequest(v)
                end

                if v.type == 3010 and (GameScene.presentLayer == "gang_xianchi2" or GameScene.presentLayer == "guildfeast") then
                    UIRequest(v)
                end

            elseif v.type == 2274 or v.type == 2284 then

                if GameScene.presentLayer == "gang_xianchi2" and v.type == 2284 then
                    if t.data and t.data["576"] and (t.data["576"] == 1 or t.data["576"] == 3) then
                        if t.data["576"] == 1 then
                            print("篝火开始",gamedata:time())
                        else
                            print("篝火状态改变",gamedata:time())
                        end

                        UIRequest(v)
                    elseif t.data and t.data["576"] and t.data["576"] == 2 then
                        print("篝火结束",gamedata:time())
                        if GameScene.layers["gang_xianchi2"].show then
                            GameScene.layers["gang_xianchi2"].module:award()
                        end
                    end
                elseif GameScene.presentLayer == "guildfeast" and v.type == 2274 then
                    if t.data and t.data["575"] and (t.data["575"] == 1 or t.data["575"] == 3) then

                        if t.data["575"] == 1 then
                            print("盛宴开始",gamedata:time())
                        else
                            print("盛宴状态改变",gamedata:time())
                        end
                        
                        UIRequest(v)
                    elseif t.data and t.data["575"] and t.data["575"] == 2 then
                        print("盛宴结束",gamedata:time())
                        if GameScene.layers["guildfeast"].show then
                            GameScene.layers["guildfeast"].module:award()
                        end
                    end
                end

            else
                UIRequest(v)
            end
        end
    end


end

function UIHintReset(t)

end

function UIPowerChange(t)
    printT(t,"战斗力变化提示205，接受客户端数据")

    --local powermsg =  "战斗力"..(t.power >= 0 and "增加" or "减少")..math.abs(t.powerChange)
    local powermsg = {}
    powermsg.change_type = (t.powerChange >= 0) and "add" or "sub"
    powermsg.change_num = math.abs(t.powerChange)

    --print(getbattlecallbackactive())

    if getbattlecallbackactive() then
        setPowerChange(powermsg)
    else
        runGamePrompt({msg = powermsg})
    end

    if GameScene.rootItems then
        GameScene.roleinfo.power = t.power_all
        GameScene.roleinfo.g_power = t.g_power
        GameScene.roleinfo.f_power = t.f_power

        GameScene.rootItems.userpower:setString(GameScene.roleinfo.power)
        --
        if GameScene.layers["deployment"].show then
            GameScene.layers["deployment"].module:reloadPower(GameScene.roleinfo.power)
        end
        UIRequest({type = 1001})
    end

end


function UIProtagonistQuery(t)
    print("1050，接受客户端数据")
    --printT(t)

    GameScene.protagonist = t.protagonist

    if t.protagonist.nexttime and t.protagonist.nexttime > 0 then
        gameTimer:rigistTime("leadTrainTimer",t.protagonist.nexttime)
    end

    if GameScene.layers["lead"].show then
        -- GameScene.layers["lead"].module:reload(t.protagonist)
        GameScene.layers["lead"].module:pageDataCallback("mogong","reload",t.protagonist)
    end
end

function UIProtagonistAddAttr(t)
    print("1051，接受客户端数据")
    --printT(t)

    GameScene:addUpdate(10021)

    GameScene.protagonist = t.protagonist

    if t.protagonist.nexttime and t.protagonist.nexttime > 0 then
        gameTimer:rigistTime("leadTrainTimer",t.protagonist.nexttime)
    end

    if GameScene.layers["lead"].show then
        -- GameScene.layers["lead"].module:reload(t.protagonist)
        GameScene.layers["lead"].module:pageDataCallback("mogong","reload",t.protagonist)
    end
end

function UIProtagonistGrowUp(t)
    print("1052，接受客户端数据")
    --printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)

    GameScene.protagonist = t.protagonist

    if t.protagonist.nexttime and t.protagonist.nexttime > 0 then
        gameTimer:rigistTime("leadTrainTimer",t.protagonist.nexttime)
    end

    if GameScene.layers["lead"].show then
        -- GameScene.layers["lead"].module:reload(t.protagonist)
        GameScene.layers["lead"].module:pageDataCallback("mogong","reload",t.protagonist)
    end

    --setLeadUpInfo(t.protagonist)
    UIRequest({type = 1001})
end

function UIProtagonistAwaken(t)
    print("主角觉醒1058， 接受客户端数据")
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)

    GameScene.protagonist = t.protagonist


    if GameScene.layers["lead"].show then
        GameScene.layers["lead"].module:pageDataCallback("awaken","awakenCallback",t.protagonist)
    end

    UIRequest({type = 1001})
end

function UIProtagonistRecoverTrain(t)
    print("1053，接受客户端数据")
    GameScene.vipstatus= t.vipstatus

    UIRequest({type = 1050, param = "update"})
    UIRequest({type = 1001})
end

function UICombMessage(t)
    print("999900，接受客户端数据")

    if t.order == "datainit" then
        LoginScene:enterToGame()
    elseif t.order == "gamescene" then
        if guide.controller then
            guide.controller:RecoverGuideScene()
        end
    elseif t.order == "cachereset" then
        runGamePrompt({msg = "零点数据刷新！"})
        GameScene:UICacheReset()
        GameScene:UpdatePresentLayer(true)
    elseif t.order == "afterselect" then
        guide.first:afterselect()
    end
end

function UICombMessageProcess(t)
    print("999909，接受客户端数据")

    LoginScene:showConfigProcess({type = "datainit", index = t.index,total = t.total})
end

function UIServerTime(t)
    print("999905，接受客户端数据")

    local oldtimeDis = gamedata.timeDis or 0

    gamedata.timeDis = t.timeDis or 0
    gamedata.timeDis3 = t.timeDis3 or 0
    
    -- if gamedata.timeDis > 30 then
    --     runGamePrompt({msg = "系统时间不准，可能影响游戏体验，请校正"})
    --     UIRequest({type=999988, msg="client time err: timedis = "..gamedata.timeDis, from="ui",noneedfix = true})
    -- end

    if math.abs(oldtimeDis- gamedata.timeDis) >30 then
        if gameTimer then
            gameTimer.oldtime = gameTimer.oldtime + gamedata.timeDis-oldtimeDis
        end
    end

end


------------------------------------------------

function UIUserProtagonist2(t)
    print("1054，接受客户端数据")
    printT(t)
    if t.protagonist then
        GameScene.protagonist = t.protagonist
    end
    if GameScene.layers["lead"].show then
        -- GameScene.layers["lead"].module:reload(t)
        GameScene.layers["lead"].module:pageDataCallback("mogong","reload",t)
    end
end

function UIUserProtagonist2AddAttr(t)
    print("1055，接受客户端数据")
    --printT(t)
    if t.protagonist then
        GameScene.protagonist = t.protagonist
    end
    if GameScene.layers["lead"].show then
        -- GameScene.layers["lead"].module:reload(t)
        GameScene.layers["lead"].module:pageDataCallback("mogong","reload",t)
    end

    UIRequest({type = 1001})
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)

    UIRequest({type = 10322, param = {"protagonist"}})
end


function UIUserProtagonist2GrowupPreveiw(t)
    print("1056，接受客户端数据")
    --printT(t)
    if t.protagonist then
        GameScene.protagonist = t.protagonist
    end
    gameWindows:openWindow("devilpreview",t)
end


function UIUserProtagonist2Growup(t)
    print("1057，接受客户端数据")
    --printT(t)
    if t.protagonist then
        GameScene.protagonist = t.protagonist
    end
    if GameScene.layers["lead"].show then
        -- GameScene.layers["lead"].module:reload(t)
        GameScene.layers["lead"].module:pageDataCallback("mogong","reload",t)
    end

    UIRequest({type = 1001})
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)

    UIRequest({type = 10322, param = {"protagonist"}})
end



--

function UIChangeGender(t)
    print("203，接受客户端数据")
    --printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    UIRequest({type = 1001})
    UIRequest({type = 1054, param = "update"})

end

function UIGenderQuery(t)
    print("204，接受客户端数据")
    printT(t)

    if gameWindows.windows["changegender"].show then
        gameWindows.windows["changegender"].module:reload(t)
    end
    
    if GameScene.layers["examination"].show then
        GameScene.layers["examination"].module:setGender(t)
    end

end
