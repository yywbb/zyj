
VideoScene = {
    isfinished = false,
    videoSchedule = nil,
    isCreateVideoScene = false,
}

local videoBgCtrl = require "videoBgScene"
local uiqueue = require("uiqueue")
function VideoScene.pauseVideoUIUpdate(self)
    if videoBgCtrl then
        videoBgCtrl:clear()
    end    
    if videoSchedule then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(videoSchedule)
        videoSchedule = nil
    end
    isfinished = false
    isCreateVideoScene = false
end


function VideoScene.onVideoCreateLogin(self)
    print("VideoScene onVideoCreateLogin")
    self:pauseVideoUIUpdate()
    
    if loginsceneVideo then
        print("VideoScene loginsceneVideo")
        -- if loginscene then
            print("VideoScene loginscene")
           -- CCDirector:sharedDirector():replaceScene(loginscene)
        -- end   
     loginsceneVideo = false
   else
         require"accbyhttp/main_ui"
   end
   loginsceneVideo = false
  
    -- local login = require "Login"
end

function VideoScene.videoUIUpdate(self)
    print("VideoScene videoUIUpdate")

    if isfinished then
        self:onVideoCreateLogin()
    end

    local tret = uiqueue.popresponsefromclient()
    if tret ~= nil then

        -- print("videoUIUpdate PUSH  tret.type = ", tret["type"])
        local func = nil
        if tonumber(tret["type"]) == 3334 then
            isfinished = true
            videoBgCtrl:clear()
        else
            uiqueue.setresponsetoui({type=tret["type"]})
        end
    end

end

function VideoScene.startVideoUIUpdate(self)
    print("VideoScene startVideoUIUpdate")

    if not videoSchedule then
        videoSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
            print("VideoScene videoUIUpdate")
            if isfinished then
                self:onVideoCreateLogin()
            end

            local tret = uiqueue.popresponsefromclient()
            if tret ~= nil then

                local func = nil
                if tonumber(tret["type"]) == 3334 then
                    isfinished = true
                    videoBgCtrl:clear()
                else
                    uiqueue.setresponsetoui({type=tret["type"]})
                end
            end
        end, 0, false)
    end
end

function VideoScene.createVideoScene(self)
   print("VideoScene createVideoScene")
   if isCreateVideoScene then --当前video没有结束之前不允许再次播放
       print("VideoScene createVideoScene 当前video没有结束之前不允许再次播放")
     return
   end
    videoBgCtrl:init()
    if VideoPlatform then
        VideoPlatform:play("video1.mp4",function()
            print("VideoScene onVideoCreateLogin")
            self:pauseVideoUIUpdate()
            
            if loginsceneVideo then
                print("VideoScene loginsceneVideo")
                -- if loginscene then
                    print("VideoScene loginscene")
                   -- CCDirector:sharedDirector():replaceScene(loginscene)
                -- end   
           else
                 require"accbyhttp/main_ui"
           end
            loginsceneVideo = false
            isCreateVideoScene = false
        end) 
     end
    self:startVideoUIUpdate()
    isCreateVideoScene = true
end



return  VideoScene