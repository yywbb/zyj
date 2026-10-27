require"sqlite3init"

local version = {
	gameversion = "2.23",

	originSize = {width=1080, height = 1920},
    maxRadio_size = {width=640, height = 960},
}

function version.showversion(self,nowScene)

    if LoginScene and LoginScene.status and LoginScene.enterLayerItem and LoginScene.enterLayerItem.gameversion then
        LoginScene.enterLayerItem.gameversion:setVisible(false)
    end

	local version = (GAME_VERSION_NUM and GAME_VERSION_NUM ~= "") and GAME_VERSION_NUM or self.gameversion
	
	local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end
    local ret = 0
    local SQL = "SELECT VersionNum FROM ResourcesVersion" 
    for row in mydb:nrows(SQL) do
        ---print("VersionNUm:"..row["VersionNum"])
        ret=row["VersionNum"]
    end
    if ret == 0 then
        SQL = "INSERT INTO ResourcesVersion VALUES (0)"
        mydb:exec(SQL)
        ---log(string.format("sqlite err in syncresource: %s",mydb:errmsg()));
    end
    mydb:close()
    local resourceversion = ret

    print("version.showversion",version,resourceversion)

    nowScene = nowScene or CCDirector:sharedDirector():getRunningScene()

    if not self[nowScene] then self[nowScene] = {} end
    
    if not self[nowScene].versionlabel then
        local openGLView = CCDirector:sharedDirector():getOpenGLView()
        self.d_viewSize = openGLView:getFrameSize()
        local label = CCLabelTTF:create(version.."."..resourceversion, "Helvetica", 24)
        label:setFontName("Helvetica-Bold")   
        label:setFontSize(24)
        label:setAnchorPoint(ccp(1,0))

        if not self.scaleNum then
            self.scaleNum = gameConfig.scaleNum
        end
        label:setScale(self.scaleNum)
        label:setPositionX(self.d_viewSize.width/2+540*self.scaleNum)
        label:setPositionY(gameConfig.fixH*self.scaleNum)
        nowScene:addChild(label,10000)
        self[nowScene].versionlabel = label
    else
        self[nowScene].versionlabel:setString(version.."."..resourceversion)
    end
end

function version.showServerandUser(self,nowScene)

    local server = gameWindows.windows["roleinfo"].module.SelectedServer 
    server = server and server.id or 0
    local user = LoginScene.roleuid or 0    
    local userid = (GameScene and GameScene.roleinfo) and GameScene.roleinfo.id or 0
    print("version.showServerandUser",user,server,userid)
    nowScene = nowScene or CCDirector:sharedDirector():getRunningScene()

    if not self[nowScene] then self[nowScene] = {} end

    if not self[nowScene].userlabel then
        local openGLView = CCDirector:sharedDirector():getOpenGLView()
        self.d_viewSize = openGLView:getFrameSize()
        local label = CCLabelTTF:create(user.."-"..server.."-"..userid, "Helvetica", 24)
        label:setFontName("Helvetica-Bold")   
        label:setFontSize(24)
        label:setAnchorPoint(ccp(0,0))
        if not self.scaleNum then
            self.scaleNum = gameConfig.scaleNum
        end
        label:setScale(self.scaleNum)
        label:setPositionX(self.d_viewSize.width/2-540*self.scaleNum)
        label:setPositionY(gameConfig.fixH*self.scaleNum)

        nowScene:addChild(label,10000)
        self[nowScene].userlabel = label
    else
        self[nowScene].userlabel:setString(server.."-"..user)
    end
end

return version