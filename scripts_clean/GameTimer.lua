--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-17
-- Time: 上午10:36
-- To change this template use File | Settings | File Templates.
--

local gameTimer = {
    timer = nil,

    times = {},
    timeFuncs = {},
    time_os = {},

    oldtime = 0,

    reconnect = false,

    hartrecivetime = 0
}

function gameTimer.startheartCheck(self)
    self.hartrecivetime = gamedata:time()
    self:rigistTime("heartCheck",10001)
    self:rigistTimeFunc("heartCheck",function(now)
         if self.times["heartCheck"]== 0 then
             self:rigistTime("heartCheck",10000)
         end

         if math.mod(self.times["heartCheck"],30) == 0 then
             UIRequest({type = 999904})
         end

        if now - self.hartrecivetime > 60 then
            UIRequest({type = 9951})
            self:UnrigistTimeFunc("heartCheck")
        end
    end)
end

function gameTimer.reciveheartCheck(self)
    self.hartrecivetime = gamedata:time()
end


function gameTimer.init(self)

    self.oldtime = gamedata:time()

    local schedulefunc = function()
        local now =  gamedata:time()
        local old =  self.oldtime
        self.oldtime = now
        --print(old,now,self.reconnect)
        if now - old >10 then
            if LoginScene and LoginScene.status then
                local date1 = os.date("*t", now)
                local date2 = os.date("*t", old)

                if now - old >30*60 or date1.day ~= date2.day then
                    if loading.restart then
                        loading:restart()
                    end
                    return
                end

                return
            end

            if (not LoginScene.status) and GameScene and GameScene.rootLayer then
                UIRequest({type =1001,param = "update"})
                UIRequest({type =1032})
            end
        end

        if self.reconnect and (not LoginScene.status and GameScene and GameScene.rootLayer) then
            UIRequest({type =1001,param = "update"})
            UIRequest({type =1032})
            self.reconnect = false
        end


        if next(self.times) then

            --print(now)
            for k,v in pairs(self.times) do
                if v ~= 0 then
                    local rest =  self.time_os[k].endt - now
                    --print(self.time_os[k].endt)
                    if rest > 0 then
                        self.times[k] = rest
                        if self.timeFuncs[k] then self.timeFuncs[k](now) end
                    else
                        self.times[k] = 0
                        if not self.time_os[k].hasCall and self.timeFuncs[k] then
                            self.time_os[k].hasCall = true
                            self.timeFuncs[k](now)
                        end
                    end
                end
            end

        end        
    end

    self.timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()

        xpcall(schedulefunc,__G_TRACKBACK__)

    end, 1, false)
end

function  gameTimer.rigistTime(self,name,time)
    if not time then return end
    local start = gamedata:time()
    self.times[name] = time
    self.time_os[name] = {
        start = start,
        endt = start+time,
        hasCall = false,
    }
end

function  gameTimer.UnrigistTime(self,name)
    self.times[name] = nil
    self.time_os[name] = nil
end

function  gameTimer.rigistTimeFunc(self,name,timefunc)
    self.timeFuncs[name] = timefunc
end

function  gameTimer.UnrigistTimeFunc(self,name)
    self.timeFuncs[name] = nil
end

function gameTimer.clear(self)
    if self.timer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
    end
    self.times = {}
    self.timeFuncs = {}
    self.time_os = {}
    self.timer = nil
end


function gameTimer.UnrigistAll(self)
    print("jjjjjjjjjj-----")
    printT(self.times)
    printT(self.timeFuncs)
    printT(self.time_os)
    self.times = {}
    self.timeFuncs = {}
    self.time_os = {}
end

return gameTimer