--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/28
-- Time: 下午6:40
-- To change this template use File | Settings | File Templates.
--

function UISignInStatus(t)
    print("签到状态2060，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[4] then
        GameScene.layers["activity"].module.pageTable[4].module:reloaddata(t)
    end


end

function UISignIn(t)
    print("签到2061，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[4] then
        GameScene.layers["activity"].module.pageTable[4].module:reloaddata(t)
    end

    showRewardPopupWindow(t.reward, nil,nil)

    UIRequest({type =1001})
end

------------
function UISignIn2Status(t)
    print("签到状态3641，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[19] and GameScene.layers["activity"].module.pageTable[19].module.show  then
        GameScene.layers["activity"].module.pageTable[19].module:reloaddata(t.data)
    end

    if t.param and t.param == "main" and GameScene.layers["main"].show then
        local config = {}
        local date = os.date("*t", gamedata:time())
        if date.month <10 then
            config = gamedata.config["sign2_"..date.year.."0"..date.month]
        else
            config = gamedata.config["sign2_"..date.year..date.month]
        end
        if t.data.status == 1 then
        elseif not config[tostring(t.data.daynum+1)] then
        else
            local cb = function()

            end
            gameWindows:openWindow("signin_tip",{},cb)
        end
    end

end

function UISignIn2(t)
    print("签到3642，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[19] and GameScene.layers["activity"].module.pageTable[19].module.show  then
        GameScene.layers["activity"].module.pageTable[19].module:reloaddata(t.data)
    end

    showRewardPopupWindow(t.reward, nil,nil)

    UIRequest({type =1001})
end

function UILuxurySignInStatus(t)
    print("签到3643，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[19] and GameScene.layers["activity"].module.pageTable[19].module.show  then
        GameScene.layers["activity"].module.pageTable[19].module:onLuxurySigninInterface(t)
    end  
end

function UILuxurySignIn(t)
    print("签到3644，接受客户端数据")
    printT(t)
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[19] and GameScene.layers["activity"].module.pageTable[19].module.show  then
        GameScene.layers["activity"].module.pageTable[19].module:onLuxurySigninInterface(t)
    end  
end