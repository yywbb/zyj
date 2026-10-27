

local unziphandler = {}

function unziphandler.checkneedunzip( self,callback )
    self.callback = callback

    if CONFIG.config.mode == "obb" then
        local filepath = self:findwritepath().."config.json"
        if not cc.FileUtils:getInstance():isFileExist(filepath) then
            self:checkInit()
        else
            self.callback()
        end
    else
        self.callback()
    end
end

function unziphandler.findwritepath(self)

    local strindex = string.find(gWPath,"compress")
    if strindex then
        return string.sub(gWPath,1,strindex-1)
    end
    return gWPath
end

function unziphandler.checkInit( self )
    local isinited = false
    self.inittimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        if not isinited then
            local luaj = require"luaj"
            local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
            local javaMethodName = "getIsinit"
            local javaMethodSig = "()Z"
            local result,isinited_ = luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig);
            isinited = isinited_;

            if isinited then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.inittimer)
                self.inittimer = nil
                self:startunzip()
            end
        end
    end, 0.3, false)
end

function unziphandler.startunzip( self )
    UIRequest({
        type = 666666,
        opt = "needunzip",
        zippath = CCDeviceModel:getObbPath(),
        writepath = self:findwritepath(),
    })

    self.totalfilenum = CONFIG.config.zipFileNum or 10000

    self.updatetimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        local tret = uiqueue.popresponsefromclient()
        if tret and tret.type == 666666 then
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.updatetimer)
            self.updatetimer = nil            
            self:unzipcomplete()
            return
        end  
        self:showunzipprocess()
    end, 0, false)
end

function unziphandler.showunzipprocess(self)

    self.numunzip = CCDeviceModel:getunzipfilenums()
    print("self.numunzip",self.numunzip)

    if self.numunzip>self.totalfilenum then
        self.numunzip = self.totalfilenum
    end

    if LoginScene.status then
        if LoginScene.enterLayer then
            LoginScene:showNode(LoginScene.enterLayerItem.processNode,true)
            LoginScene:showNode(LoginScene.enterLayerItem.enterNode,false)
            LoginScene:showNode(LoginScene.enterLayerItem.serverlistNode,false)
            LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,false)
        end
        ui.setLabelString(LoginScene.enterLayerItem.tip,"解压中,此过程不消耗流量...",13)
        ui.setLabelString(LoginScene.enterLayerItem.persentage,"",13)
        ui.setSpriteTextureRect2(LoginScene.enterLayerItem.resourceprocess,0,0,921*(self.numunzip/self.totalfilenum),33)
    end
end

function unziphandler.unzipcomplete( self )
    print("unziphandler.unzipcomplete")
    local path = cc.FileUtils:getInstance():fullPathForFilename("config.json")
    local destpath = self:findwritepath().."config.json"
    if path ~= destpath then
        CCDeviceModel:copyFile(path,destpath)
    end

    SQLite3Init()

    self.callback()
end

return unziphandler
