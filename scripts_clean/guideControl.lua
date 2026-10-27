--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/2/2
-- Time: 下午4:36
-- To change this template use File | Settings | File Templates.
--

local _guide = {
    data = nil,
    excute = {
        section = nil,
        step = nil,
    },
    config = {
        section = nil,
        step = nil
    },
    isOnGuide = false,
    isPause = false,
    isLoadData = false

    ,_system_guide = {}
    ,_system_excute = 0
    ,_blackscreen = nil
    ,_first = true
    ,_levelup_t = nil,

}

function _guide.Init(self,guidedata)
    cclog("_guide.Init")
    self.data = guidedata or self.data
    self.config.section = gamedata.config.guide_section
    self.config.step = gamedata.config.guide_step
    if self._first then
        self._first = false
    end
    if next(self.data) == nil then
        --- 第一次
        self.isOnGuide = true
        self.excute.section = 1
        self.excute.step = 1
        self:ExcuteGuide()
    else
        for k,v in pairs(self.data) do
            if v.status == 1 then
                self.excute.section = v.section
                self.excute.step = v.step+1
                self.isOnGuide = true

                local sectionC = self.config.section[tostring(v.section)]
                if sectionC.trigger == "first" and sectionC.condition ~= "" then
                    self._system_excute = tonumber(sectionC.condition)
                    self._system_guide[tonumber(sectionC.condition)] = {
                        system = tonumber(sectionC.condition),
                        status = 1
                    }
                end

                local sectionconfig = self.config.step[tostring(self.excute.section)]
                if not sectionconfig or not sectionconfig[tostring(self.excute.step)] then
                    self.excute.step = v.step
                    self:CompleteStep("Error",999999)
                    break
                end

                local needRecover = false
                while sectionconfig[tostring(self.excute.step)] do
                    if sectionconfig[tostring(self.excute.step)].redo ~=2 then
                        needRecover = true
                        break
                    end
                    self.excute.step = self.excute.step+1
                end

                if needRecover then
                    self:RecoverGuide()
                    break
                else
                    self.excute.step = self.excute.step-1
                    self:CompleteStep("Error",999999)
                    break
                end
            end
        end
    end

    if not self.isOnGuide then
        GameScene:init(mainScene)
    end

end

function _guide.RecoverGuide(self)
    cclog("_guide.RecoverGuide section:%d step:%d",self.excute.section, self.excute.step)
    local sectionStepConfig = self.config.step[tostring(self.excute.section)]
    local excutestep = self.excute.step
    if sectionStepConfig[tostring(excutestep)].redo == 2 then
        repeat
            self.excute.step = self.excute.step + 1
            until(sectionStepConfig[tostring(self.excute.step)].redo ~= 2)
    else
        for i=excutestep-1,1,-1 do
            print(i)
            if  sectionStepConfig[tostring(i)].redo ~= 1 then
                break
            else
                self.excute.step = i
            end
        end
    end

    local pageconfig = sectionStepConfig[tostring(self.excute.step)]

    if pageconfig.page ~= 0 then
        GameScene:init(mainScene)
    end
    self:ExcuteGuide(true)
end

function _guide.RecoverGuideScene(self)
    if self.isOnGuide then
        local sectionStepConfig = self.config.step[tostring(self.excute.section)]
        local pageconfig = sectionStepConfig[tostring(self.excute.step)]
        GameScene:shiftLayerById(pageconfig.page,pageconfig._param1)
    end
end

local function MakeClick(t,callback)

    guide:excuteGuide(t,callback)

--    local msg = t.talkcontent
--    local rect = tonumber(t.clickrect) or 1
--    local x,y = ui.getIDandNUM(t.clickxy1)
--
--    guide:createGuideLayer(x,1920-y,rect,msg,t.locRate or 0,t.audio,callback)
end

local function MakeMove(t)
    guide:excuteGuide(t,callback)

--    local posT = ui.getIDandNUMs(t.clickxy1)
--    posT[1] = {x = posT[1].cid,y = 1920-posT[1].num }
--    posT[2] = {x = posT[2].cid,y = 1920-posT[2].num}
--    guide:createMove(posT,t.talkcontent,t.locRate or 0)
end

local function MakeDisplay(t,callback)

    guide:excuteGuide(t,callback)

--    local msg = t.talkcontent
--    local rect = tonumber(t.clickrect) or 1
--    local x,y = ui.getIDandNUM(t.clickxy1)
--
--    guide:createDisplayLayer(x,1920-y,rect,msg,t.locRate or 0,t.audio,cb)
end

local function MakeTalk(t,callback)

    guide:excuteGuide(t,callback)

    --guide:playGuideTalk({content = t.talkcontent},cb,t.audio)
end

local function MakeSelectGeneral()
    guide:palyFirst()
end

local function PlayerAnimation(t,cb)
    if t._param1 == "beforebattle" then
        guide:palyOpenStory(1,8,cb)
    elseif t._param1 == "afterbattle" then
        if cb then cb() end
        --guide:playStory9(cb)
    elseif t._param1 == "afterselect" then
        --guide.first:oneStep(guide.first.step)
    end
end


function _guide.ExcuteGuide(self,isrecover)
    if not self.isOnGuide then
        return
    end
    local stepConfig = self.config.step[tostring(self.excute.section)][tostring(self.excute.step)]
    local stepType = stepConfig.steptype
    cclog("_guide.ExcuteGuide section:%d step:%d type:%s",self.excute.section, self.excute.step, stepType)

    printT(stepConfig)

    if stepType == "click" then
        MakeClick(stepConfig)
    elseif stepType == "click2" then
        MakeClick(stepConfig,function()  end)
    elseif stepType == "talk" then
        MakeTalk(stepConfig,function() self:UIComplete(8020) end)
    elseif stepType == "display" then
        MakeDisplay(stepConfig,function() self:CompleteStep("animation",8060) end)
    elseif stepType == "move" then
        MakeMove(stepConfig)
    elseif stepType == "animation" then
        PlayerAnimation(stepConfig,function() self:CompleteStep("animation") end)
    elseif stepType == "battledemo" then
        guide:palyFirstBattle(function() self:CompleteStep("battledemo") end)
    elseif stepType == "selectprofile" then
        MakeSelectGeneral()
    else
        self.isOnGuide = false

    end
    if not isrecover then
        self:SpecialProcess(stepConfig)
    end
end

function _guide.CompleteStep(self,tag, commitid)
    if not self.isOnGuide then
        return
    end
    cclog("_guide.CompleteStep tag:%s section:%d step:%d", tag or "normal",self.excute.section, self.excute.step)
    commitid = commitid or 0

    if self.config.step[tostring(self.excute.section)] == nil then
        return
    end

    local sectionStepConfig = self.config.step[tostring(self.excute.section)]
    local stepConfig =  sectionStepConfig[tostring(self.excute.step)]
    cclog("%d:%d",stepConfig.commit, commitid)
    if stepConfig.commit ~= commitid and commitid ~= 999999 then ----999999为特权修正编号
        return
    end
    if stepConfig.redo ~= 0 then
        UIRequest({type=201,section=self.excute.section,step=self.excute.step})
    end

    self.excute.step = self.excute.step + 1
    if sectionStepConfig[tostring(self.excute.step)] == nil then
        self.isOnGuide = false
        if self._system_excute ~= 0 then
            self._system_guide[self._system_excute].status = 2
            self._system_excute = 0
        end
        if self.excute.section ~=1 and GameScene.presentLayer then
            GameScene:setNew(GameScene)
            GameScene:setNew(GameScene.layers[GameScene.presentLayer].module)
        end

        guide:removeGuideLayer()

        if self.completeCB then self.completeCB() end
    else
        self:NextStep()
    end
end


function _guide.NextStep(self)
    self:ExcuteGuide()
end

function _guide.CompleteSection(self,section)
    guide:removeGuideLayer()
    guide:removeproflayer()
    if not self.isOnGuide then
        return
    end

    local cursection =  section or self.excute.section
    local stepnum = table.getTableLength(self.config.step[tostring(cursection)])
    UIRequest({type=201,section=cursection,step=stepnum})
    self.isOnGuide = false
    if self._system_excute ~= 0 then
        self._system_guide[self._system_excute].status = 2
        self._system_excute = 0
    end
    if self.excute.section ~=1 and GameScene.presentLayer then
        GameScene:setNew(GameScene)
        GameScene:setNew(GameScene.layers[GameScene.presentLayer].module)
    end

    if self.completeCB then self.completeCB() end
end




function _guide.LevelUp3(self,level)

    --if true then return end

    local sectionConfig = self.config.section
    local levelGuideSection = 0
    for k,v in pairs(sectionConfig) do
        if v.trigger == "level" and tonumber(v.condition) == level then
            levelGuideSection = v.section
            break
        end
    end

    if levelGuideSection ~= 0 then
        self.excute.section = levelGuideSection
        self.excute.step = 1
        self.isOnGuide = true
        self:ExcuteGuide()
    end
end

function _guide.isNewSystemByid(self,id)
    if self._system_guide[id] and self._system_guide[id].status == 2 then return false end
     local section = 0
     for k,v in pairs(self.config.section) do
         if v.trigger == "first" and tonumber(v.condition) == id then
             section = v.section
         end
     end
--     print("isNewSystemByid")
--     print(section)
--     printT(self.data)

    if section ==0 then return false end
     for k,v in pairs(self.data) do
         if v.section == section then
             if v.status == 2 then
                 return false
             end
         end
     end

     print("newsystem",section,id)
    return true
end

function _guide.addComplete( self,sysid,cb )
   
    if self:isNewSystemByid(sysid) then
        self.completeCB=cb
    else
        cb()
    end
end


function _guide.NewSystem(self,system)

    --if true then return end

    cclog("_guide.NewSystem %s",system)
    if self.isOnGuide or (self._system_guide[system] ~= nil and self._system_guide[system].status == 2) then
        return
    end

    local buildconfig = gamedata.config.build
    local buildconfig_key = gamedata.config.build_key

    local sectionConfig = self.config.section
    local systemGuideSection = 0

    local systemid = 0
    for k,v in pairs(sectionConfig) do
        if type(system) == "number" then
            if v.trigger == "first" and v.condition ~= "" and tonumber(v.condition) == system then
                systemGuideSection = v.section
                systemid = tonumber(v.condition)
                break
            end
        end
    end

    if systemGuideSection == 0 then
        self._system_guide[systemid] = {
            system = systemid,
            status = 2
        }
        return
    else
        if self._system_guide[systemid] and self._system_guide[systemid].status == 2 then return  end
        for k,v in pairs(self.data) do
            if v.section == systemGuideSection then
                if v.status == 2 then
                    self._system_guide[systemid] = {
                        system = systemid,
                        status = 2
                    }
                    return
                end
            end
        end
        self._system_excute = systemid
        self._system_guide[systemid] = {
            system = systemid,
            status = 1
        }
        self.isOnGuide = true
        self.excute.section = systemGuideSection
        self.excute.step = 1
        self:ExcuteGuide()
    end
end

function _guide.LevelUp(self,exp,callback)

    if exp and next(exp) and exp.oldlevel< exp.newlevel then
        GameScene:levelUprequest()

        gameWindows:openWindow("userLevelup",exp,callback)
    else
        if callback then
            callback()
        end
    end
end

function _guide.UIComplete(self,id)
    if self.isOnGuide then
        UIResponse({type=id})
    end
end

function _guide.SpecialProcess(self,stepConfig)
    if self.excute.section == 1 then
        if stepConfig.special and stepConfig.special == "hide" then
            guide:setGuideLayerVisible(false)
        end
    end
end

function _guide.setGuideLayerVisible(self,isVisible)
    if self.isOnGuide then
        guide:setGuideLayerVisible(isVisible)
    end
end

function _guide.reset(self)
    self.data = nil
    self.excute = {
        section = nil,
        step = nil,
    }
    self.config = {
        section = nil,
        step = nil
    }
    self.isOnGuide = false
    self.isPause = false
    self.isLoadData = false
    self._system_guide = {}
    self._system_excute = 0
    self._blackscreen = nil
    self._first = true
    self._levelup_t = nil
end

return _guide