--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/9
-- Time: 下午7:34
-- To change this template use File | Settings | File Templates.
--
require"myque"

local deviceApi = require"device"

local main = {

    rootNode = nil,
    rootItems = nil,
    data = {},

    holiday_Node = nil,
    holiday_Items = nil,
    holiday_animationManager = nil,

    buttonshow = false,
    buttonshow2 = false,

    buttontouch = -13,
    buttontouch2 = -14,
    touchPriority = -15,
    istouchmove = false,

    isBossOver = false,

    hintconfig = {
        {
            name = "rootItems",
            config = {
                daliyreward = {40},
                activity6 = {},
                activity5 = {},
                activity4 = {},
                activity3 = {},
                activity2 = {},
                activity1 = {},
                huoban = {6,110},
                
                startactivity = {},
                october1st = {},
                mogong = {115},
                mochong = {49},
                gonghui = {122,124,125,163,268,570,571,575,576},
                -- chat = {39,266,267,442},
                qiyu = {18},
                firstcharge = {162},
                playerreturn = {247,248,249,250},
                --servicewarAfter = {212},
                servicewar = {212},
                --manor = {262,265},
                sevendayactivity = {},
                cp_dizaoshenhua = {},
                cp_tianxiawushuang = {},

                zhounian = {358},
                chaozhi = {359},
                daoguan = {355},
                -- artifact = {366,396,398},
                fabao = {149},
                -- lieming = {9},
                kezhan = {138},
                -- kingBattle = {380,404,425},
                zhongqiuactivity = {400,401,402,403},
                honorwar = {381,452},
                playerback = {448},
                vipgift = {},
                sanjieliankao = {468},
                bet = {27},
                -- finddragon = {540},
                limitedset = {212, 355, 381,452, 468}, --跨服战 daoguan honorwar sanjieliankao
                minigame = {661},
            },
        },
        {
            name = "buttonitem",
            config = {
                friend = {37,127},
                mail = {38,80,81},
                mainext = {37,127,38,80,81,44},
                achieve = {44},
            },
        },
        {
            name = "buttonitem2",
            config = {
                lieming = {9},
                artifact = {366,396,398},
                manor = {262,265},
                auction = {377},
                mainext2 = {9,366,396,398,262,265,377,599,612,632},
                change = {465},
                godSoulTemple = {526,527,528,602},
                illusion = {599},
                qiling = {612},
                tokenBag = {632},
            },
        },
    },

    newconfig = {
        mainext = {parent = "buttonitem",condition = {37}},
        friend = {parent = "buttonitem",condition = {37}},
        rank = {parent = "buttonitem",condition = {155}},

        lieming = {parent = "buttonitem2",condition = {9}},
        gonghui = {parent = "rootItems",condition = {28}},
        mochong = {parent = "rootItems",condition = {49}},
        qiankunlu = {parent = "rootItems",condition = {161}},
        kezhan = {parent = "rootItems",condition = {138}},
        -- mofu = {parent = "rootItems",condition = {146}},
        -- equipup = {parent = "rootItems",condition = {150}},
        fabao = {parent = "rootItems",condition = {149}},

        -- manor = {parent = "rootItems",condition = {262}},
        huodong6 = {parent = "rootItems",condition = {} },
        huodong5 = {parent = "rootItems",condition = {} },
        huodong4 = {parent = "rootItems",condition = {} },
        huodong3 = {parent = "rootItems",condition = {} },
        huodong2 = {parent = "rootItems",condition = {} },
        huodong1 = {parent = "rootItems",condition = {}},

        -- artifact = {parent = "rootItems",condition = {396}},
    },

    suoconfig = {
    mogong = {sysid = 115,suo = false},
    --huoban = {sysid = 6,suo = false},
    mochong = {sysid = 49,suo = false},
    -- lieming = {sysid = 9,suo = false},
    gonghui = {sysid = 28,suo = false},
    qiankunlu = {sysid = 161,suo = false},
    kezhan = {sysid = 138,suo = false},
    achieve = {sysid = 75,suo = false},
    -- mofu = {sysid = 146,suo = false},
    -- equipup = {sysid = 150,suo = false},
    fabao = {sysid = 149,suo = false},
} ,

    --
    broadcastsDefaultIndex = 1,
    -- broadcastsDefault = {
    --     "欢迎进入神将道",
    --     "这里有最逗比的伙伴",
    --     "这里有最酷炫的技能",
    --     "这里有最欢乐的剧情",
    -- },
    broadcastsDefault = {
        gameConfig.strings:string_common("main",0),
        gameConfig.strings:string_common("main",1),
        gameConfig.strings:string_common("main",2),
        gameConfig.strings:string_common("main",3),
    },
    serveBroadcast = myque.new(),

    -- iconconfig = {
    --     firstchargenode = {status = false,pos = nil},
    --     startactivitynode = {status = false,pos = nil},
    --     onlinerewardnode = {status = false,pos = nil},
    --     onlinerewardbytimenode = {status = false,pos = nil},
    --     qiyunode = {status = false,pos = nil},
    --     october1stnode = {status = false,pos = nil},
    --     servicewarAfternode = {status = false,pos = nil},
    --     playerreturnnode = {status = false,pos = nil},
    --     sevendayactivitynode = {status = false,pos = nil},
    -- },

    -- bossnodePosY = nil,

    bosstime = {
        [1] = {beginT = 12*3600,endT = 12.5*3600,openTipText = "12点开启挑战"},
        [2] = {beginT = 21*3600,endT = 21.5*3600,openTipText = "21点开启挑战"},
    },

    pi = math.pi,
    ScaleY = math.sin(math.pi/5.5),
    R = 400,
    Scale = 0.45,
    angle = 2*math.pi/7,

    --angles = {0, 2*math.pi/6, 4*math.pi/6, 7*math.pi/8, 9*math.pi/8, 8*math.pi/6, 10*math.pi/6},

    slotpos = {},

    rotaAngle =0,
    frontid = 1,

    prompttimenum = {week=3,hour=20,min=20,sec=0},
    begintimenum = {week=3,hour=20,min=30,sec=0},
    endtimenum = {week=3,hour=21,min=0,sec=0},
    finaltimenum = {week=3,hour=21,min=10,sec=0},

    promptTimeNum = {week=3,hour=20,min=20,sec=0},
    beginTimeNum = {week=3,hour=20,min=30,sec=0},
    endTimeNum = {week=3,hour=21,min=0,sec=0},
    finalTimeNum = {week=3,hour=21,min=10,sec=0},
    examinationData = {},
}

function main.findZorder(self,angle)
    local pi = self.pi
    if math.abs(angle) > 2*pi then
        angle = math.mod(angle,2*pi)
    end

    if angle<0 then
        angle = angle + 2*self.pi
    end
    if angle> pi/7 and angle<= 3*pi/7 then
        return 4
    elseif angle> 3*pi/7 and angle<= 5*pi/7 then
        return 3
    elseif angle> 5*pi/7 and angle<= 7*pi/7 then
        return 2
    elseif angle> 7*pi/7 and angle<= 9*pi/7 then
        return 2
    elseif angle> 9*pi/7 and angle<= 11*pi/7 then
        return 3
    elseif angle> 11*pi/7 and angle<= 13*pi/7 then
        return 4
    else
        return 5
    end
end

function main.setOneSlot(self,i)
    self.slotpos[i].x = self.R*math.sin(self.slotpos[i].angle)
    self.slotpos[i].y = -self.R*math.cos(self.slotpos[i].angle)
    self.slotpos[i].sx = 1-(1-self.Scale)*(self.slotpos[i].y+self.R)/(2*self.R)
    self.slotpos[i].sy = self.slotpos[i].sx/self.ScaleY

    self.rootItems["slot"..i]:setPosition(self.slotpos[i].x, self.slotpos[i].y)
    self.rootItems["slot"..i]:setScaleX(self.slotpos[i].sx)
    self.rootItems["slot"..i]:setScaleY(self.slotpos[i].sy)

    local Zorder   =  self:findZorder(self.slotpos[i].angle)
    self.rootItems["slot"..i]:setZOrder(Zorder)
    self.slotpos[i].item.button_slot:setSwallowsTouch(true)
    self.slotpos[i].item.button_slot:setTouchPriority(-Zorder)
    if self.slotpos[i].item.namenode then
        self.slotpos[i].item.namenode:setVisible(i==self.frontid)
    end
end

function main.initSlot(self)
    self.rootItems.slotNode:setScaleY(self.ScaleY)

    local slotData = GameScene.layers["slotsInfo"].module.slotdata

    GameScene.ext_hint_slotfashion = 0
    for i=1,7 do
        if not self.slotpos[i] then
            self.slotpos[i]={}
            self.slotpos[i].angle = (i-1)*self.angle

            if slotData[tostring(i)] then
                if slotData[tostring(i)].general then
                    self.slotpos[i].ccb,self.slotpos[i].item = CCBReaderLoad("MainScene/main_slot", nil, true, "main_slot")
                    local config = gamedata.config.general[tostring(slotData[tostring(i)].general.illusionGeneralCid or slotData[tostring(i)].general.cid)]
                    self.slotpos[i].config = config
                    -- 设置形象
                    local generalName = gamedata.config.generalanimation[tostring(config.animationid)].name
                    if config.fashion_id == 0 then --非时装
                        if slotData[tostring(i)].general.illusionGeneralCid then
                            generalName = ui.getGeneralAnimationidSion(generalName, slotData[tostring(i)].general)
                        else
                            generalName = ui.getGeneralAnimationid(generalName, slotData[tostring(i)].general)
                        end
                    end
                    --
                    local wingData = {level=GameScene.protagonist.w_l,color=GameScene.protagonist.w_c}
                    self.slotpos[i].general = ui.itemcache:attachskeleton(generalName, self.slotpos[i].item.general,wingData)
                    --self.slotpos[i].general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",2)
                    self.slotpos[i].general:setScale(1.8)
                    self.slotpos[i].general:setAnimation("stand",true,0)
                    --self.slotpos[i].item.general:addChild(self.slotpos[i].general)

                    if config.name == "主角" then
                        local growconfig = gamedata.config.protagonist_grow or {}
                        local data = GameScene.protagonist
                        local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(data.level2+1)] and (math.mod(data.level2,5)+1) or 5), nil, true, "jie")
                        self.slotpos[i].item.general:addChild(Node11)
                    else
                        ui.addAwakeEffect(self.slotpos[i].item.general,slotData[tostring(i)].general.skilllevel,1.5)
                    end

                    if config.quality and config.quality >= 7 then
                        ui.setLabelString(self.slotpos[i].item.name,config.name == "主角" and GameScene.roleinfo.name or config.name..(slotData[tostring(i)].general.illusionGeneralCid and gameConfig.strings:string_common("huanhua",10) or  ""),213)
                    else
                        ui.setLabelString(self.slotpos[i].item.name,config.name == "主角" and GameScene.roleinfo.name or config.name..(slotData[tostring(i)].general.illusionGeneralCid and gameConfig.strings:string_common("huanhua",10) or  ""),((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
                    end
                    --
                    local o_cid = slotData[tostring(i)].general.cid
                    if gamedata.config.general[tostring(o_cid)] and gamedata.config.general[tostring(o_cid)].partner_id and gamedata.config.general[tostring(o_cid)].partner_id > 0 then
                        o_cid = gamedata.config.general[tostring(o_cid)].partner_id
                    end    
                    for k,v in pairs(gamedata.config.partner_fashion) do
                        if (v.orange_partner2 == o_cid) or (v.red_partner2 == o_cid) or (v.gold_partner2 == o_cid) then
                            if getPartnerfashionOnceFromSqlite(v.fashion_id) == 1 then
                                GameScene.ext_hint_slotfashion = 1
                                break
                            end 
                        end    
                    end 

                else
                    self.slotpos[i].ccb,self.slotpos[i].item = CCBReaderLoad("UIEffect/main/slotempty_e", nil, true, "slotempty_e")
                end
                self.slotpos[i].item.button_slot:addHandleOfControlEvent(function()
                    if self.istouchmove then return end
                    GameScene:shiftLayer("slotsInfo","up",{sid = i,sidtype = "slot"})
                end, CCControlEventTouchUpInside)
            else
                self.slotpos[i].ccb,self.slotpos[i].item = CCBReaderLoad("MainScene/main_slotlock", nil, true, "main_slotlock")

                self.slotpos[i].item.button_slot:addHandleOfControlEvent(function()
                    if self.istouchmove then return end
                    local slotconfig = gamedata.config.general_slot
                    local nextlevel = slotconfig[tostring(i)]
                    -- runGamePrompt({msg = nextlevel.."级开启"})
                    runGamePrompt({msg = gameConfig.strings:lvOpen(nextlevel)})
                end, CCControlEventTouchUpInside)
            end
            self.rootItems["slot"..i]:addChild(self.slotpos[i].ccb)
        end

        self:setOneSlot(i)
    end

    self:setSlot()
    self:frontshow(frontid)

    gameTimer:rigistTime("mainslot",120)
    gameTimer:rigistTimeFunc("mainslot",function()
        --print(gameTimer.times["mainslot"])
        if gameTimer.times["mainslot"] == 117 then
             self:frontstop()
        elseif gameTimer.times["mainslot"] == 0 then
             self:fronttalk()
             gameTimer:rigistTime("mainslot",120)
        end
    end)
end

function main.setSlot(self)
    self.rootItems.rotanode:setRotation(-math.deg(self.rotaAngle))
    for i=1,7 do
        self.slotpos[i].angle = (i-1)*self.angle + self.rotaAngle

        local x  =  self.R*math.sin(self.slotpos[i].angle)
        local y  =  -self.R*math.cos(self.slotpos[i].angle)
        self.slotpos[i].sx = 1-(1-self.Scale)*(y+self.R)/(2*self.R)
        self.slotpos[i].sy = self.slotpos[i].sx/self.ScaleY

        self.rootItems["slot"..i]:setRotation(math.deg(self.rotaAngle))
        self.rootItems["slot"..i]:setScaleX(self.slotpos[i].sx)
        self.rootItems["slot"..i]:setScaleY(self.slotpos[i].sy)
        self.rootItems["slot"..i]:setZOrder(self:findZorder(self.slotpos[i].angle))
        if self.slotpos[i].item.namenode then
            self.slotpos[i].item.namenode:setVisible(i==self.frontid)
        end
    end
end

-- 更新主角的名字
function main.updatePlayerName(self,newName)
    local slotData = GameScene.layers["slotsInfo"].module.slotdata
    for i=1,7 do
        if self.slotpos[i] then
            local config = self.slotpos[i].config
            if config and config.name == "主角" then
                if config.quality and config.quality >= 7 then
                    ui.setLabelString(self.slotpos[i].item.name,newName,213)
                else
                    ui.setLabelString(self.slotpos[i].item.name,newName,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
                end
                break
            end
        end
    end
end

function main.moveslot(self,dis)
    self.rotaAngle = self.rotaAngle + (dis or 0)*(self.pi/1800)
    self:setSlot()

--    local stepAngle = (dis or 0)*(self.pi/1800)
--    for i=1,7 do
--        local newpos = self.slotpos[i].pos + (dis>=0 and 1 or -1)
--        if newpos>7 then
--            newpos = 1
--        elseif newpos<0 then
--            newpos = 7
--        end
--        self.slotpos[i].angle = self.slotpos[i].angle + stepAngle*math.abs(self.angles[newpos]-self.angles[self.slotpos[i].pos])/self.angle
--        self.slotpos[i].pos = newpos
--        self:setOneSlot(i)
--    end
end

function main.moveSlotAnimation(self,dis,direct)
    if math.abs(self.rotaAngle) > 2*self.pi then
        self.rotaAngle = math.mod(self.rotaAngle,2*self.pi)
    end

    if self.rotaAngle<0 then
        self.rotaAngle = self.rotaAngle + 2*self.pi
    end

    local stepdis = (direct and 1 or -1)*100
    local targetAngle =  self.rotaAngle

    for i=1,7 do
        if self.rotaAngle > (i-1)*self.angle and self.rotaAngle <= i*self.angle then
            if direct then
                targetAngle = i*self.angle
                self.frontid = 8-i
            else
                targetAngle = (i-1)*self.angle
                self.frontid = 9-i
            end

            if self.frontid>7 then
                self.frontid = 1
            elseif self.frontid<0 then
                self.frontid = 7
            end
            break
        end
    end

    self.timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        local newangle = self.rotaAngle + stepdis*(self.pi/1800)
        if direct then
            if newangle >= targetAngle then
                self.rotaAngle = targetAngle
                self:setSlot()
                self:frontshow()
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                return
            end
        else
            if newangle <= targetAngle then
                self.rotaAngle = targetAngle
                self:setSlot()
                self:frontshow()
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                return
            end
        end
        self.rotaAngle = newangle
        self:setSlot()
    end, 0, false)
end

function main.frontshow(self,id)
    self.frontid = id or self.frontid
    --print(self.frontid,"frontshow")
    --printT(self.slotpos[self.frontid].config)
    if self.slotpos[self.frontid].general then
        self:fronttalk()
        gameTimer:rigistTime("mainslot",120)
    end
end

function main.fronttalk(self)
    if self.slotpos[self.frontid].general then
        local ccb,item = CCBReaderLoad("MainScene/tishi", nil, true, "tishi")
        self.slotpos[self.frontid].item.talk:addChild(ccb)
        item.content:setString(self.slotpos[self.frontid].config.dialogue or "策划还没配我说的话呢！！！！！")
        if self.playingSound then
            gamedata.music:StopSound(self.playingSound)
            self.playingSound = nil
        end
        self.playingSound = gamedata.music:PlaySound(self.slotpos[self.frontid].config.specialaudio or "12305.mp3",false)
    end
end

function main.frontstop(self)
    --print(self.frontid,"frontstop")
    if self.slotpos[self.frontid].general then
        self.slotpos[self.frontid].item.talk:removeAllChildrenWithCleanup(true)
        self.slotpos[self.frontid].ccb:stopAllActions()
        --self.slotpos[self.frontid].general:setAnimation("stand",true,0)
    end
end

function main.makehintconfig(self)
    if not next(self.hintconfig[1].config.activity1) then
        for k,v in pairs(gamedata.config.activity_time) do
            if v.systemid and (v.systemid ~= 253) and (v.systemid ~= 373) and (v.systemid ~= 377) then
                table.insert(self.hintconfig[1].config["activity"..v.type], v.systemid)
            end
        end
    end

    if not next(self.hintconfig[1].config.startactivity) then
        for i=82,109 do
            table.insert(self.hintconfig[1].config.startactivity, i)
        end
    end

    if not next(self.hintconfig[1].config.sevendayactivity) then
        for i=275,302 do
            table.insert(self.hintconfig[1].config.sevendayactivity, i)
        end
    end

    if not next(self.hintconfig[1].config.october1st) then
        for i=217,244 do
            table.insert(self.hintconfig[1].config.october1st, i)
        end
    end

    if not next(self.hintconfig[1].config.cp_dizaoshenhua) then
        for i=469,496 do
            table.insert(self.hintconfig[1].config.cp_dizaoshenhua, i)
        end
    end

    if not next(self.hintconfig[1].config.cp_tianxiawushuang) then
        for i=497,524 do
            table.insert(self.hintconfig[1].config.cp_tianxiawushuang, i)
        end
    end

end

function main.palyBroadcast(self)
    --
    self.rootItems.broadcast1:setPositionX(GameScene.viewSize.width)

    if myque.empty(self.serveBroadcast) then
        self.rootItems.broadcast1:setVisible(false)
        self.rootItems.broadcastinfo1:setString(self.broadcastsDefault[self.broadcastsDefaultIndex])
        self.broadcastsDefaultIndex = self.broadcastsDefaultIndex + 1
        if self.broadcastsDefaultIndex >= 5 then
            self.broadcastsDefaultIndex = 1
        end
    else
        self.rootItems.broadcast1:setVisible(true)
        self.rootItems.broadcastinfo1:setString(myque.pop(self.serveBroadcast))
    end

    self.rootItems.broadcast_d:setScaleX((self.rootItems.broadcastinfo1:getContentSize().width+50)/70)
    self.rootItems.broadcast_t:setPositionX(120+self.rootItems.broadcastinfo1:getContentSize().width)

    local moveTo = CCMoveTo:create(16, ccp(-200 - self.rootItems.broadcastinfo1:getContentSize().width, self.rootItems.broadcast1:getPositionY()))

    local seq = CCSequence:createWithTwoActions(moveTo, CCCallFunc:create(function()
        self:palyBroadcast()
    end))
    self.rootItems.broadcast1:runAction(seq)

end

function main.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("MainScene/main2", nil, true, "main")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if self.rootItems.maintimebag then
        self.rootItems.maintimebag:setVisible(false)
    end

    self:makehintconfig()

    if GameScene.layers["slotsInfo"].module.slotdata and next(GameScene.layers["slotsInfo"].module.slotdata) then
        if not GameScene:checkUpdate(10021) then
            self:initSlot()
        end
    end

    -- if not self.bossnodePosY then
    --     self.bossnodePosY = self.rootItems.bossnode:getPositionY()
    -- end

    -- if not self.iconconfig.firstchargenode.pos then
    --     for k,v in pairs(self.iconconfig) do
    --         self.iconconfig[k].pos = self.rootItems[k]:getPositionX()
    --     end
    -- end

    -- for k,v in pairs(self.iconconfig) do
    --     self:setNode(v.status,k,false)
    -- end

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.bgnode:setPositionY((GameScene.topposY-1920)*0.2)
    self.rootItems.slotNode:setPositionY((GameScene.topposY-1920)*0.2+834)

    if self.rootItems.holidayshownode then
        self.rootItems.holidayshownode:setPositionY((GameScene.topposY-1920)*0.2+954)
    end    

    if self.rootItems.holidayshownode2 then
        self.rootItems.holidayshownode2:setPositionY((GameScene.topposY-1920)*0.2+954)
    end    

    local ad = require"adChannel"
    
    if ad:showOrNot() then
        self.buttonccb,self.buttonitem = CCBReaderLoad("MainScene/main_ext2", nil, true, "main_ext")
    else
        self.buttonccb,self.buttonitem = CCBReaderLoad("MainScene/main_ext", nil, true, "main_ext")
    end
    self.animationManager = getAnimationManager(self.buttonitem)
    self.rootItems.mainext:addChild(self.buttonccb)

    self.animationManager:runAnimationsForSequenceNamed(self.buttonshow and "opened" or "closed")

    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-510))

    local function ccTouchBegan(x, y)
        self.istouchmove = false
        self.touchpos = {x=x,y=y }
        self.movex = x
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            if ui.isTouched(self.rootItems.mainchat,x,y) then
                self.chatpos = {x=self.rootItems.mainchat:getPositionX(),y=self.rootItems.mainchat:getPositionY() }
                self.chatTouch = true
                self.chatmove = false
            elseif ui.isTouched(self.rootItems.mainfriend,x,y) and self.rootItems.mainfriend:isVisible() then
                self.friendpos = {x=self.rootItems.mainfriend:getPositionX(),y=self.rootItems.mainfriend:getPositionY()}
                self.friendTouch = true
                self.friendmove = false
            end
        end
        self:frontstop()

        return true
    end

    local function ccTouchMoved(x, y)
        if self.chatTouch then
            local newy = self.chatpos.y + (y - self.touchpos.y)/GameScene.scaleNum
            if math.abs(y - self.touchpos.y) > 5 and newy > 620 and newy < (GameScene.topposY-1620)+1020 then
                self.rootItems.mainchat:setPosition(ccp(self.chatpos.x,self.chatpos.y + (y - self.touchpos.y)/GameScene.scaleNum))
                self.chatmove = true
            end
        elseif self.friendTouch then
            local newy = self.friendpos.y + (y - self.touchpos.y)/GameScene.scaleNum
            if math.abs(y - self.touchpos.y) > 5 and newy > 620 and newy < (GameScene.topposY-1620)+1020 then
                self.rootItems.mainfriend:setPosition(ccp(self.friendpos.x,self.friendpos.y + (y - self.touchpos.y)/GameScene.scaleNum))
                self.friendmove = true
            end
        else
            if math.abs(x - self.touchpos.x) > 20 then
                if self.timer then
                    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                    self.timer = nil
                end
                self.istouchmove = true
                self:moveslot(x - self.movex)
                self.movex = x
                gameTimer:rigistTime("mainslot",9999)
            end
        end
    end

    local function ccTouchEnded(x, y)
        if self.chatTouch then
            if not self.chatmove then
                GameScene:shiftLayer("chat","up")
            end
            self.chatTouch = false
        elseif self.friendTouch then
            if not self.friendmove then
                gameWindows:openWindow("friend",{type = "chat"},nil)
            end
            self.friendTouch = false
        else
            if self.istouchmove then
                self:moveSlotAnimation(x - self.movex,x>self.touchpos.x)
            end
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -12, false)
    self.rootItems.touchLayer:setTouchPriority(-12)
    self.rootItems.touchLayer:setTouchEnabled(true)

    self:setExtButton()
    ----------------------------下拉按钮------------------------------------

    self.buttonitem.m_more:setSwallowsTouch(true)
    self.buttonitem.m_more:setTouchPriority(self.buttontouch2-3)
    self.buttonitem.m_more:addHandleOfControlEvent(function()
        print(self.buttonshow)
        self.buttonshow = not self.buttonshow
        self.animationManager:runAnimationsForSequenceNamed(self.buttonshow and "open" or "close")
        gamedata.music:PlayOptSound("ldcd")
    end, CCControlEventTouchUpInside)

    if gameConfig:checkBuildOpen(155) then
        self.buttonitem.m_rank:setSwallowsTouch(true)
        self.buttonitem.m_rank:setTouchPriority(self.buttontouch2-2)
        self.buttonitem.m_rank:addHandleOfControlEvent(function()
            print("paihang")
            GameScene:shiftLayer("ranklist","up")
        end, CCControlEventTouchUpInside)
    else
        self.buttonitem.m_rank:setVisible(false)
    end

    self.buttonitem.m_friend:setSwallowsTouch(true)
    self.buttonitem.m_friend:setTouchPriority(self.buttontouch2-2)
    self.buttonitem.m_friend:addHandleOfControlEvent(function()
        GameScene:shiftLayer("friends","up")
    end, CCControlEventTouchUpInside)

    self.buttonitem.m_mail:setSwallowsTouch(true)
    self.buttonitem.m_mail:setTouchPriority(self.buttontouch2-2)
    self.buttonitem.m_mail:addHandleOfControlEvent(function()
        GameScene:shiftLayer("mail","up")
    end, CCControlEventTouchUpInside)

    if not next(GameScene.layers["collect"].module.generaldata) then
        GameScene.layers["collect"].module:makeconfig()
    end
    self.buttonitem.tujian:setSwallowsTouch(true)
    self.buttonitem.tujian:setTouchPriority(self.buttontouch2-2)
    self.buttonitem.tujian:addHandleOfControlEvent(function()
    --UIRequest({type = 1015})
        GameScene:shiftLayer("collect","up")
    end, CCControlEventTouchUpInside)

    --vipkefu todo
    if self.buttonitem.vipkefu then
        self.buttonitem.vipkefu:setSwallowsTouch(true)
        self.buttonitem.vipkefu:setTouchPriority(self.buttontouch2-2)
        self.buttonitem.vipkefu:addHandleOfControlEvent(function()
            if gameConfig:checkBuildOpen(353) then
                gameWindows:openWindow("vipkefu",{viptype = self.vipkefutype})
            end
        end, CCControlEventTouchUpInside)
    end

    self.buttonitem.achieve:setSwallowsTouch(true)
    self.buttonitem.achieve:setTouchPriority(self.buttontouch2-2)
    self.buttonitem.achieve:addHandleOfControlEvent(function()
        print("成就")
        GameScene:shiftLayer("achievement","up")
        UIRequest({type = 999901,id=13})

    end, CCControlEventTouchUpInside)

    --
    if self.buttonitem.fashion then
        self.buttonitem.fashion:setSwallowsTouch(true)
        self.buttonitem.fashion:setTouchPriority(self.buttontouch2-2)
        self.buttonitem.fashion:addHandleOfControlEvent(function()
            if gameConfig:checkBuildOpen(444) then
                GameScene:shiftLayer("partnerfashion_collect","up")
            end
        end, CCControlEventTouchUpInside)
    end

    --展示广告
    if self.buttonitem.showad then
        self.buttonitem.showad:setSwallowsTouch(true)
        self.buttonitem.showad:setTouchPriority(self.buttontouch2-2)
        self.buttonitem.showad:addHandleOfControlEvent(function()
            gameWindows:openWindow("greatGiftByAD",{data = ""},nil)
        end, CCControlEventTouchUpInside)
    end
    -----------------------------上排按钮-------------------------------------------

    -- self.rootItems.liveness:setSwallowsTouch(true)
    -- self.rootItems.liveness:setTouchPriority(self.buttontouch)
    -- self.rootItems.liveness:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("task","up")
    --     UIRequest({type = 999901,id=13})
    -- end, CCControlEventTouchUpInside)

    -- self.rootItems.activity:setSwallowsTouch(true)
    -- self.rootItems.activity:setTouchPriority(self.buttontouch)
    -- self.rootItems.activity:addHandleOfControlEvent(function()
    --     UIRequest({type = 2000,page ="2"})
    -- end, CCControlEventTouchUpInside)

    
    self.rootItems.fabao:setSwallowsTouch(true)
    self.rootItems.fabao:setTouchPriority(self.buttontouch )
    self.rootItems.fabao:addHandleOfControlEvent(function()
        print("法宝")
        GameScene:shiftLayer("magic","up")

    end, CCControlEventTouchUpInside)

    self.rootItems.kezhan:setSwallowsTouch(true)
    self.rootItems.kezhan:setTouchPriority(self.buttontouch)
    self.rootItems.kezhan:addHandleOfControlEvent(function()
        print("点击客栈")
        GameScene:shiftLayer("favoritegeneral","up")
    end, CCControlEventTouchUpInside)

    -- 商店集合入口
    self.rootItems.activityshop:setSwallowsTouch(true)
    self.rootItems.activityshop:setTouchPriority(self.buttontouch)
    self.rootItems.activityshop:addHandleOfControlEvent(function()
        print("公会合集")
        UIRequest({type = 2000,page ="3"})
        -- GameScene:shiftLayer("sportsshop","up")

    end, CCControlEventTouchUpInside)


    -- self.rootItems.fuli:setSwallowsTouch(true)
    -- self.rootItems.fuli:setTouchPriority(self.buttontouch)
    -- self.rootItems.fuli:addHandleOfControlEvent(function()
    --     UIRequest({type = 2000,page ="1"})
    -- end, CCControlEventTouchUpInside)

    -- self.rootItems.startactivity:setSwallowsTouch(true)
    -- self.rootItems.startactivity:setTouchPriority(self.buttontouch)
    -- self.rootItems.startactivity:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("startactivity","up")
    -- end, CCControlEventTouchUpInside)
    --充值按钮
    self.rootItems.m_recharge:setSwallowsTouch(true)
    self.rootItems.m_recharge:setTouchPriority(self.buttontouch)
    self.rootItems.m_recharge:addHandleOfControlEvent(function()
        print("recharge")
        --GameScene:shiftLayer("recharge","up")
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)
    --变速器
    self.rootItems.GMSpeednode:setVisible(true)
    self.rootItems.GMSpeed:setSwallowsTouch(true)
    self.rootItems.GMSpeed:setTouchPriority(self.buttontouch)
    self.rootItems.GMSpeed:addHandleOfControlEvent(function()
        print("GMSpeed")
        gameWindows:openWindow("setgmspeed")
    end, CCControlEventTouchUpInside)

    --
    -- self.rootItems.october1st:setSwallowsTouch(true)
    -- self.rootItems.october1st:setTouchPriority(self.buttontouch)
    -- self.rootItems.october1st:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("october1st","up")
    -- end, CCControlEventTouchUpInside)

    -- self.rootItems.sevendayactivity:setSwallowsTouch(true)
    -- self.rootItems.sevendayactivity:setTouchPriority(self.buttontouch)
    -- self.rootItems.sevendayactivity:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("sevendayactivity","up")
    -- end, CCControlEventTouchUpInside)

    -- self.rootItems.servicewarAfter:setSwallowsTouch(true)
    -- self.rootItems.servicewarAfter:setTouchPriority(self.buttontouch)
    -- self.rootItems.servicewarAfter:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("servicewarAfter","up")
    -- end, CCControlEventTouchUpInside)

    -- self.rootItems.servicewar:setSwallowsTouch(true)
    -- self.rootItems.servicewar:setTouchPriority(self.buttontouch)
    -- self.rootItems.servicewar:addHandleOfControlEvent(function()
    --     UIRequest({type = 4702,param =  "goto"})
    -- end, CCControlEventTouchUpInside)

    -- self.rootItems.playerreturn:setSwallowsTouch(true)
    -- self.rootItems.playerreturn:setTouchPriority(self.buttontouch)
    -- self.rootItems.playerreturn:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer("playerreturn","up")
    -- end, CCControlEventTouchUpInside)

    --
    -- if self.rootItems.vipgift then
    --     self.rootItems.vipgift:setSwallowsTouch(true)
    --     self.rootItems.vipgift:setTouchPriority(self.buttontouch)
    --     self.rootItems.vipgift:addHandleOfControlEvent(function()
    --         GameScene:shiftLayer("shopList","up",{selectpage = "gift",giftpage = 2})
    --     end, CCControlEventTouchUpInside)
    -- end

    ------------------------------下排按钮------------------------------------------

    -- self.rootItems.qiyu:setSwallowsTouch(true)
    -- self.rootItems.qiyu:setTouchPriority(self.buttontouch)
    -- self.rootItems.qiyu:addHandleOfControlEvent(function()
    --     UIRequest({type = 1310,param =  "goto"})
    --     --GameScene:shiftLayer("encounter2")
    -- end, CCControlEventTouchUpInside)

    
    self.rootItems.mogong:setSwallowsTouch(true)
    self.rootItems.mogong:setTouchPriority(self.buttontouch)
    self.rootItems.mogong:addHandleOfControlEvent(function()
        print("点击魔宫")
        guide:setGuideProlayer(true)
        GameScene:shiftLayer("lead","up")
    end, CCControlEventTouchUpInside)

    self.rootItems.huoban:setSwallowsTouch(true)
    self.rootItems.huoban:setTouchPriority(self.buttontouch)
    self.rootItems.huoban:addHandleOfControlEvent(function()
        print("点击伙伴")
        GameScene:shiftLayer("generals","up")
    end, CCControlEventTouchUpInside)

    if self.rootItems.mochong then
        self.rootItems.mochong:setSwallowsTouch(true)
        self.rootItems.mochong:setTouchPriority(self.buttontouch)
        self.rootItems.mochong:addHandleOfControlEvent(function()
            print("点击魔宠")
            GameScene:shiftLayer("devil","up")
            -- runGamePrompt({msg = "功能未开启"})
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.gonghui:setSwallowsTouch(true)
    self.rootItems.gonghui:setTouchPriority(self.buttontouch)
    self.rootItems.gonghui:addHandleOfControlEvent(function()
        print("点击公会")
        --runGamePrompt({msg = "功能未开启"})

        --UIRequest({type = 999990})   --战斗测试
        --UIRequest({type = 979797})   --内存测试

        --GameScene:shiftLayerById(158)

        UIRequest({type = 2230, param = "main"})
    end, CCControlEventTouchUpInside)

    self.rootItems.qiankunlu:setSwallowsTouch(true)
    self.rootItems.qiankunlu:setTouchPriority(self.buttontouch)
    self.rootItems.qiankunlu:addHandleOfControlEvent(function()
        print("点击乾坤炉")
        GameScene:shiftLayer("qiankunlu","up")
        
    end, CCControlEventTouchUpInside)

    -- self.rootItems.equipup:setSwallowsTouch(true)
    -- self.rootItems.equipup:setTouchPriority(self.buttontouch)
    -- self.rootItems.equipup:addHandleOfControlEvent(function()
    --     print("装备进阶")
    --     GameScene:shiftLayer("equipstage","up")
    -- end, CCControlEventTouchUpInside)

   

    self.rootItems.timebag:setSwallowsTouch(true)
    self.rootItems.timebag:setTouchPriority(self.buttontouch)
    self.rootItems.timebag:addHandleOfControlEvent(function()
        print("限时礼包")
        GameScene.tipindex = 999 
        UIRequest({type = 2880,param="main"})
    end, CCControlEventTouchUpInside)

    -- 游戏助手
    self.rootItems.zhushou:setSwallowsTouch(true)
    self.rootItems.zhushou:setTouchPriority(self.buttontouch)
    self.rootItems.zhushou:addHandleOfControlEvent(function()
        if not gameConfig:checkBuildOpen(566) then
            runGamePrompt({msg = "敬请期待"})
        else
            GameScene:shiftLayer("gameHelper","up")
        end

    end, CCControlEventTouchUpInside)

    ------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------



    --self.rootItems.broadscroll:setTouchEnabled(false)
    self:palyBroadcast()

    self:setSuo()

    local initrequest = {}

    --UIRequest({type = 117})
    --UIRequest({type = 2037})
    --UIRequest({type = 2313})
    table.insert(initrequest,{type = 2313}) 

    --UIRequest({type = 13101})
    --UIRequest({type = 36101})
    UIRequest({type = 10322, param = {"generals","protagonist","qiling","tokenBag"}})

    if gameConfig:checkBuildOpen(213) and GameScene:checkopenlevelbyId(213,true) then
        --UIRequest({type = 3740})
        table.insert(initrequest,{type = 3740}) 
    end

    if gameConfig:checkBuildOpen(253) then
        --UIRequest({type = 4800})
        table.insert(initrequest,{type = 4800}) 
    end

    --UIRequest({type = 2880})
    table.insert(initrequest,{type = 2880}) 

    if gameConfig:checkBuildOpen(378) then
        --UIRequest({type = 5511})
        table.insert(initrequest,{type = 5511}) 
    end

    if gameConfig:checkBuildOpen(444) then
        table.insert(initrequest,{type = 6911}) 
    end

    if gameConfig:checkBuildOpen(42) then
        table.insert(initrequest,{type = 3210}) 
    end

    if gameConfig:checkBuildOpen(468) then
        print("----7002")
        table.insert(initrequest,{type = 7002}) 
    end

    if gameConfig:checkBuildOpen(599) and GameScene:checkopenlevelbyId(599,true) then
         UIRequest({type = 8110})
    end
    if gameConfig:checkBuildOpen(28) and GameScene:checkopenlevelbyId(28,true) then
        table.insert(initrequest,{type = 2230}) 
    end

    if gameConfig:checkBuildOpen(21) and GameScene:checkopenlevelbyId(21,true) then
        self:requestWorldBossdata()
    end

    if not gameConfig:checkBuildOpen(437) then
        self.rootItems.slotNode:setVisible(true)
    end

    self:setArrange(initrequest)

    --
    if gameConfig:checkBuildOpen(444) then
        self:setFashionHint()
    end

    --审核模式隐藏聊天按钮
    if gamedata.audit_state and gamedata.audit_state == "true" then
        print("-----隐藏聊天按钮-------")
        self.rootItems.mainchat:setVisible(false)
    end
    GameScene:checkUpdate(1012)
    self:reqChatHint()

    -- 广告红点
    if ad:showOrNot() then
        UIRequest({type=8091})
    end
end


--请求聊天数量
function main.reqChatHint(self)
    UIRequest({type =1032,ids = {579}})
end

function main.reloadChatHint(self)
    self.rootItems.chatNumNode:setVisible(true)
    if GameScene.hintdata["579"] then
        if GameScene.hintdata["579"] <= 0 then
            self.rootItems.chatNumNode:setVisible(false)
        elseif GameScene.hintdata["579"] > 99 then
            self.rootItems.chatNum:setString("99+")
        else
            self.rootItems.chatNum:setString(GameScene.hintdata["579"])
        end
    end
end

function main.setFashionHint(self)
    if gamedata.config.partner_fashion and self.buttonitem and self.buttonitem.hint_fashion then
        ui.sethint(self.buttonitem.hint_fashion,false)
        for k,v in pairs(gamedata.config.partner_fashion) do
            if getPartnerfashionOnceFromSqlite(v.fashion_id) == 1 then
                ui.sethint(self.buttonitem.hint_fashion,true)
                break
            end
        end
    end
end

function main.setADHint(self,data,adOnceRed)
    if gamedata.config.free_gift and self.buttonitem and self.buttonitem.hint_showad then
        ui.sethint(self.buttonitem.hint_showad,false)

        local limitedset = self.hintconfig[2].config.mainext
        local hintext_2 = false
        for i,v in ipairs(limitedset) do
            if GameScene.hintdata[tostring(v)] and GameScene.hintdata[tostring(v)] ~= 0 then
                hintext_2 = true
                break
            end
        end

        ui.sethint(self.buttonitem.hint_mainext,hintext_2)

        local allCharge = false
        for i=1,5 do
            if data.adStatus then
                if data.adStatus["status"..i] == 1 then
                    ui.sethint(self.buttonitem.hint_showad,true)
                    ui.sethint(self.buttonitem.hint_mainext,true)
                    return 
                elseif data.adStatus["status"..i] == 0 then
                    allCharge = true
                end
            else
                print("data is nil!")
            end
        end

        if adOnceRed and allCharge then 
            ui.sethint(self.buttonitem.hint_showad,true)
            ui.sethint(self.buttonitem.hint_mainext,true)
        end
    end

    return
end

--神魂殿红点
function main.setgodSoulTempleHint(self,data,isshowHint)
    printT(data,"setgodSoulTempleHint")
    self.templeHint = {}
    local isshow = isshowHint or  0
    if data and data.godSoulTemple then
       local sanshegnshi = gamedata.config.shenhundian_sanshengshi
       for k,v in pairs(data.godSoulTemple) do
           if sanshegnshi then
                local _datasoulBacic = v["genralsLevel2ByBasic"] or 0
                local _datasoulLevel = v["soulLevel"] or 0
                -- print("setgodSoulTempleHint basic:".._datasoulBacic.." level:".._datasoulLevel)
                if sanshegnshi[tostring(k)] and sanshegnshi[tostring(k)][tostring(_datasoulLevel+1)] then
                    local  _soullimit = sanshegnshi[tostring(k)][tostring(_datasoulLevel+1)].breakthrough_limit or 1
                     -- print("setgodSoulTempleHint limit:".._soullimit)
                    if tonumber(_soullimit) <= tonumber(_datasoulBacic) then
                        isshow = 1
                    else
                        table.insert(self.templeHint,{ id = k, isshowHint = 1 })
                    end   
                else     
                   table.insert(self.templeHint,{ id = k, isshowHint = isshow })
                end     
           end
       end
    end     
    printT(self.templeHint,"templeHint")

    if self.buttonitem2 and self.buttonitem2.godSoulTemple then
        self.buttonitem2.hint_godSoulTemple:removeAllChildrenWithCleanup(true)
        if isshow == 1  then
            local ccb,item = CCBReaderLoad("UIEffect/red.ccbi", nil, true, "red")
             self.buttonitem2.hint_godSoulTemple:addChild(ccb)
        end    
    end
end 


function main.setExtButton(self)
    ----------------------------下排按钮------------------------------------
    self.buttonccb2,self.buttonitem2 = CCBReaderLoad("MainScene/main_button2", nil, true, "main_button2")
    self.animationManager2 = getAnimationManager(self.buttonitem2)
    self.rootItems.mainspread:addChild(self.buttonccb2)
    self.animationManager2:runAnimationsForSequenceNamed(self.buttonshow2 and "opened" or "closed")


    self.buttonitem2.m_more:setSwallowsTouch(true)
    self.buttonitem2.m_more:setTouchPriority(self.buttontouch-2)
    self.buttonitem2.m_more:addHandleOfControlEvent(function()
        print(self.buttonshow2)
        self.buttonshow2 = not self.buttonshow2
        self.animationManager2:runAnimationsForSequenceNamed(self.buttonshow2 and "open" or "close")
        gamedata.music:PlayOptSound("ldcd")
    end, CCControlEventTouchUpInside)


    self.buttonitem2.mofu:setSwallowsTouch(true)
    self.buttonitem2.mofu:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.mofu:addHandleOfControlEvent(function()
        print("魔符背包")
        GameScene:shiftLayer("mofulist","up")
    end, CCControlEventTouchUpInside)



    self.buttonitem2.lieming:setSwallowsTouch(true)
    self.buttonitem2.lieming:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.lieming:addHandleOfControlEvent(function()
        print("点击猎命")
        GameScene:shiftLayer("soul","up")
    end, CCControlEventTouchUpInside)

    self.buttonitem2.artifact:setSwallowsTouch(true)
    self.buttonitem2.artifact:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.artifact:addHandleOfControlEvent(function()
        print("神器列表")
        GameScene:shiftLayer("artifact","up")
    end, CCControlEventTouchUpInside)

    self.buttonitem2.manor:setSwallowsTouch(true)
    self.buttonitem2.manor:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.manor:addHandleOfControlEvent(function()
        print("藏经阁")
        GameScene:shiftLayer("manor","up")
    end, CCControlEventTouchUpInside)

    self.buttonitem2.change:setSwallowsTouch(true)
    self.buttonitem2.change:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.change:addHandleOfControlEvent(function()
        print("转换")
        if gameConfig:checkBuildOpen(465) and GameScene:checkopenlevelbyId(465) then
            GameScene:shiftLayer("change","up", {page = "General"})
        end
    end, CCControlEventTouchUpInside)

    self.buttonitem2.godSoulTemple:setSwallowsTouch(true)
    self.buttonitem2.godSoulTemple:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.godSoulTemple:addHandleOfControlEvent(function()
        print("神魂殿")
        if gameConfig:checkBuildOpen(525) and GameScene:checkopenlevelbyId(525) then
            GameScene:shiftLayer("godSoulTemple","up", {page = "gold", hintdata = self.templeHint or {}})
        end
    end, CCControlEventTouchUpInside)

    self.buttonitem2.illusion:setSwallowsTouch(true)
    self.buttonitem2.illusion:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.illusion:addHandleOfControlEvent(function()
        print("幻化")
        GameScene:shiftLayer("illusion")
    end, CCControlEventTouchUpInside)

    self.buttonitem2.qiling:setSwallowsTouch(true)
    self.buttonitem2.qiling:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.qiling:addHandleOfControlEvent(function()
        print("器灵")
        GameScene:shiftLayer("qiLingBag")
        -- GameScene:shiftLayer("exclusiveArtifact")
    end, CCControlEventTouchUpInside)

    self.buttonitem2.tokenBag:setSwallowsTouch(true)
    self.buttonitem2.tokenBag:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.tokenBag:addHandleOfControlEvent(function()
        print("天机令")
        GameScene:shiftLayer("tokenBag")
        -- GameScene:shiftLayer("exclusiveArtifact")
    end, CCControlEventTouchUpInside)
    

    if gameConfig:checkBuildOpen(262) then
        self.buttonitem2.manorBN:setVisible(true)
    else
        self.buttonitem2.manorBN:setVisible(false)
    end

    self.buttonitem2.auction:setSwallowsTouch(true)
    self.buttonitem2.auction:setTouchPriority(self.buttontouch - 1)
    self.buttonitem2.auction:addHandleOfControlEvent(function()
        print("古董拍卖")
        GameScene:shiftLayer("antiqueAuction","up")
    end, CCControlEventTouchUpInside)

    ----------------------------------------------------------------
end

function main.setButtonFunc(self,button,isSwallowsTouch,touchPriority,func)
    button:setSwallowsTouch(isSwallowsTouch)
    button:setTouchPriority(touchPriority)

    local function buttonfunc()
        --if self.istouchmove then return end
        xpcall(func,__G_TRACKBACK__)
    end
    button:addHandleOfControlEvent(buttonfunc, CCControlEventTouchUpInside)
end

main.arrangeconfig = {
    {name = "firstcharge",                  check = function() UIRequest({type = 117}) end, 
                                            func = function() gameWindows:openWindow("firstrecharge",GameScene.layers["main"].module.data,nil) end},
    {name = "foreverrecharge", sysid = 360, check = function() return {type = 5319} end, 
                                            func = function() gameWindows:openWindow("accRecharge",GameScene.layers["main"].module.foreverdata,nil) end},
    {name = "startactivity",                check = function() UIRequest({type = 36101}) end, 
                                            func = function() GameScene:shiftLayer("startactivity","up") end},

    {name = "activity",                     func = function() UIRequest({type = 2000,page ="2"}) end},
    {name = "fuli",                         func = function() UIRequest({type = 2000,page ="1"}) end},
    {name = "activityrank",                 check = function() UIRequest({type = 2000,page ="4",ischeck = 1}) end,
                                            func = function() UIRequest({type = 2000,page ="4"}) end},
    {name = "activityrecharge",             check = function() UIRequest({type = 2000,page ="5",ischeck = 1}) end,
                                            func = function() UIRequest({type = 2000,page ="5"}) end},
    {name = "activityhefu",                 check = function() UIRequest({type = 2000,page ="6",ischeck = 1}) end,
                                            func = function() UIRequest({type = 2000,page ="6"}) end},

    {name = "liveness",                     func = function() GameScene:shiftLayer("task","up") end},
    {name = "limitedset",                   func = function() GameScene:shiftLayer("limitedset","up") end},
    -- {name = "wudaohui",       sysid = 191,  check= function() GameScene.layers["main"].module:setwudaohuiUpdateTime() end,
    --                                         func = function() GameScene.layers["main"].module:enterWudaohui() end},
    {name = "sevendayactivity",             check = function()  
                                                    if gameConfig:checkBuildOpen(326) then
                                                        UIRequest({type = 50481})
                                                    elseif gameConfig:checkBuildOpen(275) then
                                                        UIRequest({type = 48801})            --todo
                                                    end 
                                                end, 
                                            func = function() GameScene:shiftLayer("sevendayactivity","up") end},
                                            
    {name = "cp_dizaoshenhua",             check = function()
                                                    if gameConfig:checkBuildOpen(469) then
                                                        UIRequest({type = 48861})
                                                    end
                                                    
                                                end, 
                                            func = function() GameScene:shiftLayer("cp_dizaoshenhua","up") end},

    {name = "cp_tianxiawushuang",             check = function()  
                                                    if gameConfig:checkBuildOpen(497) then
                                                        UIRequest({type = 48881})
                                                    end
                                                end, 
                                            func = function() GameScene:shiftLayer("cp_tianxiawushuang","up") end},
    
                                                                                    
    {name = "october1st",      sysid = 217, check = function() UIRequest({type = 37651}) end, 
                                            func = function() GameScene:shiftLayer("october1st","up") end},
    -- {name = "servicewarAfter", sysid = 212, check = function() 
    --                                                 UIRequest({type = 4702})
    --                                                 UIRequest({type = 4717, param = "main"}) 
    --                                             end,
    --                                         func = function() GameScene:shiftLayer("servicewarAfter","up") end},
    -- {name = "servicewar",      sysid = 212, func = function() UIRequest({type = 4702,param =  "goto"}) end},
    -- {name = "honorwar",        sysid = 381, func = function() GameScene:shiftLayer("honorBattle","up") end},
    {name = "onlinereward",                 check = function() return {type = 2037} end},
    {name = "onlinerewardbytime",sysid = 251,check= function() return {type = 2039} end},

    {name = "playerreturn",    sysid = 247, check = function() UIRequest({type = 37721}) end, 
                                            func = function() GameScene:shiftLayer("playerreturn","up") end},
    -- {name = "boss",            sysid = 21,  check = function() GameScene.layers["main"].module:requestWorldBossdata() end },
    {name = "qiyu",                         check = function() UIRequest({type = 13101}) end, 
                                            func = function() UIRequest({type = 1310,param =  "goto"}) end},
    -- {name = "bet",             sysid = 27,  check = function() GameScene.layers["main"].module:checkCupbet() end,
    --                                         func = function() GameScene:shiftLayer("cup","up",{page = "tops"}) end},
    -- {name = "guildWar",        sysid = 171, check = function() UIRequest({type = 2149}) end},
    {name = "zhounian",        sysid = 358, check = function() GameScene.layers["main"].module:checkZhounian() end,
                                            func = function() GameScene:shiftLayer("zhounian","up") end},
    {name = "chaozhi",         sysid = 359, check = function() GameScene.layers["main"].module:checkChaozhi() end,
                                            func = function() GameScene:shiftLayerById(359) end},
    
    {name = "h5Recharge",                   check = function () 
                                                        if not not gamedata.sdk.h5RechargeUrl then
                                                            GameScene.layers["main"].module:setNode(true,"h5Rechargenode") 
                                                        else
                                                            GameScene.layers["main"].module:setNode(false,"h5Rechargenode") 
                                                        end
                                                    end,             
                                            func = function () if  sdk:isValid() and  sdk.openHP  then  sdk:openHP() end end},
    -- {name = "daoguan",         sysid = 355, check= function() GameScene.layers["main"].module:setdaoguanshouweiUpdateTime() end,
    --                                         func = function()
    --                                             if GameScene.layers["main"].module and GameScene.layers["main"].module.daoguanIsout then
    --                                                 runGamePrompt({msg = "即将开启"})
    --                                                 return
    --                                             end
    --                                             GameScene:shiftLayer("daoGuanMain","up")
    --                                         end},
    {name = "zhongqiuactivity", sysid = 400, check = function() GameScene.layers["main"].module:checkZhongQiu() end,
                                            func = function() GameScene:shiftLayer("zhongqiuactivity","up") end},
    {name = "holiday", sysid = 437, check = function() return {type = 6501} end, 
                                    func = function()                                       
                                        if GameScene.layers["main"].module and GameScene.layers["main"].module.holidaystatus and GameScene.layers["main"].module.holidaystatus == 3 then
                                            if GameScene.layers["main"].module and GameScene.layers["main"].module.holidaytype and GameScene.layers["main"].module.holidaytype > 0 then
                                                if GameScene.holidaynum and (GameScene.holidaynum < gamedata.config.holiday_time[tostring(GameScene.layers["main"].module.holidaytype)].num) then
                                                    --gameWindows:openWindow("newJieri",{},nil)
                                                    runGamePrompt({msg = "进行中"})
                                                else
                                                    runGamePrompt({msg = "今日领取次数已用完"})
                                                end
                                            end
                                        elseif GameScene.layers["main"].module and GameScene.layers["main"].module.holidaystatus and GameScene.layers["main"].module.holidaystatus == 2 then    
                                            runGamePrompt({msg = "即将开启"})
                                        else
                                            runGamePrompt({msg = "活动未开启"})
                                        end
                                    end},    
    {name = "playerback",       sysid = 448,  check= function() return {type = 6810} end,
        func = function() gameWindows:openWindow("playerback",nil,nil) end},           
    {name = "vipgift", sysid = 304, check = function() GameScene.layers["main"].module:checkVipgift() end,func = function()
        -- GameScene:shiftLayer("shopList","up",{selectpage = "gift",giftpage = 2}) 
        GameScene:shiftLayerById(304)
    end},      

    {name = "sanjieliankao",         sysid = 468, check= function() GameScene.layers["main"].module:setsanjieliankaoUpdateTime() end,
                                            func = function()
                                                if GameScene.layers["main"].module and GameScene.layers["main"].module.sanjieliankaoIsout then
                                                    runGamePrompt({msg = "即将开启"})
                                                    return
                                                end
                                                GameScene:shiftLayer("examination","up")
                                            end},               
    {       
        name = "xuanyue",
        check = function()  
            if gameConfig:checkBuildOpen(539) then
                UIRequest({type = 7060})
            end
        end, 
        func = function() GameScene:shiftLayer("xuanyueTreasures","up") end
    }, 
    {       
        name = "xuanyue2",
        check = function()  
            if gameConfig:checkBuildOpen(559) then
                UIRequest({type = 7063})
            end
        end, 
        func = function() GameScene:shiftLayer("xuanyueTreasures2","up") end
    }, 
    {       
        name = "xuanyue3",
        check = function()  
            if gameConfig:checkBuildOpen(577) then
                UIRequest({type = 7072})
            end
        end, 
        func = function() GameScene:shiftLayer("xuanyueTreasures3","up") end
    }, 
    {
        name = "shangguyiji",             
        check = function (  )
            if gameConfig:checkBuildOpen(544) then
                UIRequest({type = 7080,param = "checkOpen"})
            end
        end ,
        func = function() UIRequest({type = 7080}) end
    },
    {
        name = "zaotang",             
        check = function() end, 
        func = function()
            local bathdoing = GameScene.layers["gang_main"].module.gang.gangbathdoing
            if bathdoing and bathdoing > 0 then
                UIRequest({type = 2282, roomid = bathdoing, controltype = 1})
            else
                runGamePrompt({msg = "篝火已结束"})
            end
        end
    },

    {
        name = "feast",             
        check = function() end, 
        func = function()
            local feastdoing = GameScene.layers["gang_main"].module.gang.gangfeastdoing
            if feastdoing and feastdoing > 0 then
                UIRequest({type = 2272, roomid = feastdoing, controltype = 1})
            else
                runGamePrompt({msg = "盛宴已结束"})
            end
        end
    },

    {       
        name = "naili",
        check = function() GameScene.layers["main"].module:checkNaiLiCode() end, 
        func = function() gameWindows:openWindow("nailicode") end
    }, 
    --小游戏
    {
        name = "minigame",
        check = function() GameScene.layers["main"].module:checkminigame() end,
        func = function() GameScene:shiftLayerById(661) end
    },
}
main.arrangelist = {}

main.arrangeconst = {}

function main.checkminigame(self)
    if GameScene:checkopenlevelbyId(661,true) then
        UIRequest({type = 1600})
    else
        self:setNode(false,"minigamenode")
    end
end

function main.reloadGuildTip(self)
    printT(GameScene.layers["gang_main"].module.gang,"reloadGuildTip")
    local bathdoing = GameScene.layers["gang_main"].module.gang.gangbathdoing
    if bathdoing and bathdoing > 0 then
        self:setNode(true, "zaotangnode")

        gameTimer:rigistTime("main_zaotangTime",10)        
        gameTimer:rigistTimeFunc("main_zaotangTime", function()
            if gameTimer.times["main_zaotangTime"] <= 0 then
                UIRequest({type = 2230})
            end
        end)

    else
        self:setNode(false, "zaotangnode")
    end



    local feastdoing = GameScene.layers["gang_main"].module.gang.gangfeastdoing
    if feastdoing and feastdoing > 0 then
        self:setNode(true, "feastnode")

        gameTimer:rigistTime("main_feastTime",10)        
        gameTimer:rigistTimeFunc("main_feastTime", function()
            if gameTimer.times["main_feastTime"] <= 0 then
                UIRequest({type = 2230})
            end
        end)

    else
        self:setNode(false, "feastnode")
    end

end

function main.checkNaiLiCode( self )
    local open = false
    if gamedata.config.activity_time["54"].param == 192660 then
        if gamedata.config.activity_time["54"]["end"] and gamedata.config.activity_time["54"]["end"] ~= "" then
            local e_year,e_month,e_day,e_hour,e_minute,e_second = ui.getDate(gamedata.config.activity_time["54"]["end"])
            local endt = os.time({year=tonumber(e_year), month=tonumber(e_month),day=tonumber(e_day),hour=tonumber(e_hour),min=tonumber(e_minute),sec=tonumber(e_second)})
            endt = endt + 86400*7
            local endtab = os.date("*t",endt)
            local endString = endtab.year..ui.addZeroFrontNum(2,endtab.month)..ui.addZeroFrontNum(2,endtab.day)..ui.addZeroFrontNum(2,endtab.hour).."000000"

            local status,remintime = ui.checkDateActive(gamedata.config.activity_time["54"]["begin"], endString)
            if status then --活动时间内
                open = true
            else
                open = false
            end
        end
    end
    self:setNode(open, "nailinode")
end


function main.checkVipgift(self)
    if not gameConfig:checkBuildOpen(154) then 
        return
    end
    local isShow = true
    local vipGift_localInfoString = CCUserDefault:sharedUserDefault():getStringForKey("vipGift_localInfoString"..GameScene.roleinfo.id)
    if vipGift_localInfoString and vipGift_localInfoString ~= "" then
        local now = os.date("*t", gamedata:time())
        local _t = string.split(vipGift_localInfoString,"_")
        if tonumber(_t[1]) == now.year and tonumber(_t[2]) == now.month and tonumber(_t[3]) == now.day then
            isShow = false
        end
    end

    GameScene.layers["main"].module:setNode(isShow,"vipgiftnode")
end

function main.setArrange( self, initrequest )
    local checkrequest = initrequest or {}
    for k,v in ipairs(self.arrangeconfig) do
        if self.rootItems[v.name] then
            if v.func then
                self:setButtonFunc(self.rootItems[v.name],true,self.buttontouch2,v.func)
            end
            if gamedata.audit_state and gamedata.audit_state == "true" then
                -- self:setNode(false,v.name.."node")
            else
                if not v.sysid or (gameConfig:checkBuildOpen(v.sysid) and GameScene:checkopenlevelbyId(v.sysid,true)) then
                    if self.arrangeconst[v.name.."node"] == true then
                        self:setNode(self.arrangeconst[v.name.."node"],v.name.."node")
                    elseif v.check then
                        local req = v.check()
                        if req then
                            table.insert(checkrequest,req)
                        end
                    else
                        self:setNode(true,v.name.."node")
                    end
                end
            end
        end
    end
    if next(checkrequest) then
        UIRequest({type=999900, reqs= checkrequest})
    end

    self:arrangeicon()
end

function main.arrangeicon(self)
    local index = 1
    for k,v in ipairs(self.arrangeconfig) do
        if self.rootItems[v.name.."node"] then
            if self.arrangelist[v.name.."node"] then
                self.rootItems[v.name.."node"]:setScale(0.85) --1
                self.rootItems[v.name.."node"]:setVisible(true)
                local x = math.mod(index,6) --5
                if x==0 then x=6 end --5
                local y = math.ceil(index/6) --5
                self.rootItems[v.name.."node"]:setPosition(145*(x-1)-430,-145*(y-1)-100) -- 400, 160,157
                index = index+1
            else
                self.rootItems[v.name.."node"]:setScale(1)
                self.rootItems[v.name.."node"]:setVisible(false)
                self.rootItems[v.name.."node"]:setPosition(999,999)
            end
        end
    end
end

function main.setNode(self,has,node,isconst)

    if not self.rootItems then return end

    local oldstatus = not not self.arrangelist[node]

    if node == "sevendayactivitynode" then
        if GameScene.SevenDayType2 and GameScene.SevenDayType2 == 3 then
            setControlButtonFrame(self.rootItems["sevendayactivity"],"b_n_mainicon_dizaoshenhua","b_n_mainicon_dizaoshenhua","b_n_mainicon_dizaoshenhua")        
        elseif GameScene.SevenDayType2 and GameScene.SevenDayType2 == 2 then
            setControlButtonFrame(self.rootItems["sevendayactivity"],"b_n_mainicon_tianxiawushuang","b_n_mainicon_tianxiawushuang","b_n_mainicon_tianxiawushuang")
        elseif GameScene.SevenDayType and GameScene.SevenDayType == 2 then
            setControlButtonFrame(self.rootItems["sevendayactivity"],"b_n_mainicon_sevenday","b_n_mainicon_sevenday","b_n_mainicon_sevenday")
        else
            setControlButtonFrame(self.rootItems["sevendayactivity"],"b_n_mainicon_dizaoshenhua","b_n_mainicon_dizaoshenhua","b_n_mainicon_dizaoshenhua")
        end
    end

    if node == "firstcharge" or node == "foreverrecharge" then
        has = has and gameConfig.ischargeOpen
    end

    if node == "zhongqiuactivitynode" then
        print("setNode","zhongqiuactivity",GameScene.layers["zhongqiuactivity"].module.mainIcon)
        if GameScene.layers["zhongqiuactivity"].module.mainIcon and GameScene.layers["zhongqiuactivity"].module.mainIcon ~= "" then
            setControlButtonFrame(self.rootItems["zhongqiuactivity"],GameScene.layers["zhongqiuactivity"].module.mainIcon,GameScene.layers["zhongqiuactivity"].module.mainIcon,GameScene.layers["zhongqiuactivity"].module.mainIcon)
        end
    end

    if node == "october1stnode" then
        print("setNode","october1stnode",GameScene.layers["october1st"].module.mainIcon)
        if GameScene.layers["october1st"].module.mainIcon and GameScene.layers["october1st"].module.mainIcon ~= "" then
            setControlButtonFrame(self.rootItems["october1st"],GameScene.layers["october1st"].module.mainIcon,GameScene.layers["october1st"].module.mainIcon,GameScene.layers["october1st"].module.mainIcon)
        end
    end

    if node == "zhouniannode" then
        print("setNode","zhouniannode",GameScene.layers["zhounian"].module.mainIcon)
        if GameScene.layers["zhounian"].module.mainIcon and GameScene.layers["zhounian"].module.mainIcon ~= "" then
            setControlButtonFrame(self.rootItems["zhounian"],GameScene.layers["zhounian"].module.mainIcon,GameScene.layers["zhounian"].module.mainIcon,GameScene.layers["zhounian"].module.mainIcon)
        end
    end

    self.arrangelist[node] = has

    if isconst then
        self.arrangeconst[node] = has
    end

    if oldstatus ~= self.arrangelist[node] then
        self:arrangeicon()
    end
end

-- function main.arrangeicon(self)
--     --printT(self.iconconfig,"self.iconconfig")
--     if self.iconconfig["firstchargenode"].status and not self.iconconfig["startactivitynode"].status then
--         self.rootItems.firstchargenode:setPositionX(self.iconconfig["startactivitynode"].pos)
--     else
--         self.rootItems.firstchargenode:setPositionX(self.iconconfig["firstchargenode"].pos)
--     end

--     --
--     if self.rootItems.vipgiftnode then
--         if gameConfig:checkBuildOpen(154) and gameConfig:checkBuildOpen(304) then
--             if (not self.iconconfig["firstchargenode"].status) or (not self.iconconfig["startactivitynode"].status) then
--                 self.rootItems.vipgiftnode:setVisible(true)
--             else
--                 self.rootItems.vipgiftnode:setVisible(false)
--             end
--         else
--             self.rootItems.vipgiftnode:setVisible(false)
--         end
--     end
-- end


-- function main.setNode(self,has,node,noarrange)
--     --print(node)

--     if node == "firstchargenode" then
--         self.iconconfig[node].status = has and gameConfig.ischargeOpen
--     else
--         self.iconconfig[node].status = has
--     end
--     self.rootItems[node]:setVisible(self.iconconfig[node].status)

--     if node == "october1stnode" then
--         if not has then
--             self.rootItems.bossnode:setPositionY(self.rootItems.october1stnode:getPositionY())
--         else
--             self.rootItems.bossnode:setPositionY(self.bossnodePosY)
--         end
--     end
    
--     if not noarrange and self.iconconfig["firstchargenode"].pos then
--         self:arrangeicon()
--     end

--     if node == "qiyunode" then
--         if gameTimer.times["mainqiyunode"] and gameTimer.times["mainqiyunode"] > 0 then
--             gameTimer:rigistTimeFunc("mainqiyunode",function()
--                 if gameTimer.times["mainqiyunode"] > 0 then
--                 else
--                     UIRequest({type = 13101})
--                 end
--             end)
--         end
--     end
-- end

function main.checkZhounian( self )
    local tiemconfig = gamedata.config.peak_time["6"]

    if not tiemconfig then 
        self:setNode(false,"zhouniannode") 
        return
    end

    if ui.checkDateActive(tiemconfig.begin,tiemconfig.award) then
        self:setNode(true,"zhouniannode")
    else
        self:setNode(false,"zhouniannode")
    end
end

function main.checkZhongQiu( self )
    -- local tiemconfig = gamedata.config.peak_time["10"]

    -- if not tiemconfig then 
    --     self:setNode(false,"zhongqiuactivitynode") 
    --     return
    -- end

    -- if ui.checkDateActive(tiemconfig.begin,tiemconfig.award) then
    --     self:setNode(true,"zhongqiuactivitynode")
    -- else
    --     self:setNode(false,"zhongqiuactivitynode")
    -- end

    if gameConfig:checkBuildOpen(400) then
        UIRequest({type = 64011})
    end 
end

function main.checkChaozhi( self )
    UIRequest({type = 20001,id =100})
end

main.bettime = {
    {begint = {hour= 12,min = 00}, endt = {hour= 18,min = 57}},   
}
function main.checkCupbet( self )
    local now = os.date("*t", gamedata:time())
    
    local v = self.bettime[1]

    if (now.hour == v.begint.hour and now.min >= v.begint.min) or now.hour > v.begint.hour then
        if (now.hour == v.endt.hour and now.min < v.endt.min) or now.hour < v.endt.hour then
            gameTimer:rigistTime("main_bet", (v.endt.hour-now.hour)*3600 + (v.endt.min-now.min)*60 - now.sec)
            gameTimer:rigistTimeFunc("main_bet",function()
                if gameTimer.times["main_bet"] <= 0 then
                    gameTimer:UnrigistTimeFunc("main_bet")
                    self:setNode(false,"betnode")
                end
            end)
            self:setNode(true,"betnode")
        else
            self:setNode(false,"betnode")
        end
    else
        self:setNode(false,"betnode")
    end

end

-- 武道会 判断为哪个活动倒计时
function main.setwudaohuiUpdateTime( self )
    ui.setLabelString(self.rootItems.wudaohuiText,nil,21)

    if gamedata.config.wudao_time and gamedata.config.wudao_time["1"] and gamedata.config.wudao_time["1"].open_week and gamedata.config.wudao_time["1"].open_week > 0 then
    else
        return
    end

    local nowtime = os.date("*t", gamedata:time())
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))

    local updatestatus = false
    for k,v in pairs(gamedata.config.wudao_time) do
        if tonumber(v.open_week) == daynums then
            local hour1,min1,sec1 = ui.getGangBattleTime(v["open_time"])
            local hour2,min2,sec2 = ui.getGangBattleTime(v["over_time"])
            local hour3,min3,sec3 = ui.getGangBattleTime(v["finaly_time"])
            local hour4,min4,sec4 = ui.getGangBattleTime(v["prompt_time"])
            
            self.begintimenum = {week=v["open_week"], hour=hour1, min=min1, sec=sec1}
            self.endtimenum = {week=v["open_week"], hour=hour2, min=min2, sec=sec2}
            self.finaltimenum = {week=v["open_week"], hour=hour3, min=min3, sec=sec3}
            self.prompttimenum = {week=v["open_week"], hour=hour4, min=min4, sec=sec4}
            updatestatus = true
            break
        end
    end
    if updatestatus == false then
        return
    end
    
    gameTimer:rigistTime("main_wudaohui_main_flesh", 2*24*3600)
    gameTimer:rigistTimeFunc("main_wudaohui_main_flesh",function()
        local nowtime = os.date("*t", gamedata:time())
        local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
        local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

        if (self:gettimenum(self.prompttimenum) <= alltimes and alltimes < self:gettimenum(self.begintimenum)) or (self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum)) or (self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.finaltimenum)) then
            self:wudaohuiUpdatetime()
            gameTimer:UnrigistTimeFunc("main_wudaohui_main_flesh")
        end
        if gameTimer.times["main_wudaohui_main_flesh"] == 0 then
            gameTimer:UnrigistTimeFunc("main_wudaohui_main_flesh")
            self:wudaohuiUpdatetime()
        end
    end)

    self:wudaohuiUpdatetime()
end


function main.wudaohuiUpdatetime( self )
    self.isout = true

    local nowtime = os.date("*t", gamedata:time())
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

    local remaintime = 0

    if self:gettimenum(self.prompttimenum) <= alltimes and alltimes < self:gettimenum(self.begintimenum) then
        self.isout = true
        self:setNode(true,"wudaohuinode")

        remaintime = self:gettimenum(self.begintimenum) - alltimes

        gameTimer:rigistTime("main_wudaohui_reading", remaintime)
        gameTimer:rigistTimeFunc("main_wudaohui_reading",function()           
            if gameTimer.times["main_wudaohui_reading"] >= 0 then
                ui.setLabelString(self.rootItems.wudaohuitime,"待开启:"..ui.makeTimeText(gameTimer.times["main_wudaohui_reading"],"minute"),26)
            end
            if gameTimer.times["main_wudaohui_reading"] == 0 then
                gameTimer:UnrigistTimeFunc("main_wudaohui_reading")
                self:wudaohuiUpdatetime()
            end
        end)


    elseif self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum) then
        self.isout = false
        self:setNode(true,"wudaohuinode")

        remaintime = self:gettimenum(self.endtimenum) - alltimes

        gameTimer:rigistTime("main_wudaohui_start", remaintime)
        gameTimer:rigistTimeFunc("main_wudaohui_start",function()   
            if gameTimer.times["main_wudaohui_start"] >= 0 then
                ui.setLabelString(self.rootItems.wudaohuitime,"进行中:"..ui.makeTimeText(gameTimer.times["main_wudaohui_start"],"minute"),26)
            end
            if gameTimer.times["main_wudaohui_start"] == 0 then
                gameTimer:UnrigistTimeFunc("main_wudaohui_start")
                self:wudaohuiUpdatetime()
            end
        end)
    elseif self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.finaltimenum) then
        self.isout = false
        self:setNode(true,"wudaohuinode")

        remaintime = self:gettimenum(self.finaltimenum) - alltimes

        gameTimer:rigistTime("main_wudaohui_rewards", remaintime)
        gameTimer:rigistTimeFunc("main_wudaohui_rewards",function()
            if gameTimer.times["main_wudaohui_rewards"] >= 0 then
                ui.setLabelString(self.rootItems.wudaohuitime,"待关闭:"..ui.makeTimeText(gameTimer.times["main_wudaohui_rewards"],"minute"),26)
            end
            if gameTimer.times["main_wudaohui_rewards"] == 0 then
                gameTimer:UnrigistTimeFunc("main_wudaohui_rewards")
                self:wudaohuiUpdatetime()
            end
        end)
    else
        print("活动结束活动结束活动结束活动结束===")
        self.isout = true
        self:setNode(false,"wudaohuinode")
    end
end

function main.enterWudaohui(self)
    if self.isout == true then
        runGamePrompt({msg = "即将开启"})
        return
    end

    GameScene:shiftLayerById(191)
end


function main.setAncientRuins(self,data)
    self:setNode(data.isopen == 1,"shangguyijinode")
    if data.isopen == 1 then
        self:ancientRuinsUpdateTime(data)
        ui.sethint(self.rootItems.hint_shangguyiji,tonumber(gamedata.config.global_kv.shanggu_num.value) - tonumber(data.challengeTime) > 0)
    end
    
end

function main.ancientRuinsUpdateTime(self,data)

    local timediff = 0
    local config = gamedata.config.peak_time[tostring(15)]
    if config.param == 3 and config["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(config["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    end
    print("ancientRuinsUpdateTime",timediff)

    if timediff < 86400 then
        gameTimer:rigistTime("main_ancientRuinsTime",timediff)        
        gameTimer:rigistTimeFunc("main_ancientRuinsTime", function()
            if gameTimer.times["main_ancientRuinsTime"] <= 0 then
                self.rootItems.shangguyijitime:setString(gameConfig.strings:string_common("main",10))
                gameTimer:UnrigistTimeFunc("main_ancientRuinsTime")
            else
                ui.setLabelString(self.rootItems.shangguyijitime,gameConfig.strings:string_common("main",9)..ui.makeTimeDayText(gameTimer.times["main_ancientRuinsTime"],"hour"),26)
            end
        end)
    else
        self.rootItems.shangguyijitime:setString("")
    end
end

function main.setXuanyueTreasures(self,data)
    self:setNode(data.day.isopen == 1,"xuanyuenode")
    if data.day.isopen == 1 then
        self:xuanyueTreasuresUpdateTime(data.day)

        local ishint = false
        for k,v in pairs(data.data.status) do
            if v == 1 then
                ishint = true
                break
            end
        end
        ui.sethint(self.rootItems.hint_xuanyue,ishint)
    end
    
end


function main.xuanyueTreasuresUpdateTime(self,data)

    local timediff = 0
    local config = gamedata.config.peak_time[tostring(13)]
    if config.param == 3 and config["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(config["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    elseif config.param == 1 then
        local cpnum = data.cpnum
        local cpday = data.cpday

        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(config["continued_time"]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    end
    print("xuanyueTreasuresUpdateTime",timediff)

    if timediff < 86400 then
        gameTimer:rigistTime("main_xuanyueTreasuresTime",timediff)        
        gameTimer:rigistTimeFunc("main_xuanyueTreasuresTime", function()
            if gameTimer.times["main_xuanyueTreasuresTime"] <= 0 then
                self.rootItems.xuanyuetime:setString(gameConfig.strings:string_common("xuanyueTreasures",15))
                gameTimer:UnrigistTimeFunc("main_xuanyueTreasuresTime")
            else

                ui.setLabelString(self.rootItems.xuanyuetime,ui.makeTimeDayText(gameTimer.times["main_xuanyueTreasuresTime"],"hour"),26)
            end
        end)
    else
        self.rootItems.xuanyuetime:setString("")
    end
end

function main.setXuanyueTreasures2(self,data)
    self:setNode(data.day.isopen == 1,"xuanyue2node")
    if data.day.isopen == 1 then
        self:xuanyueTreasuresUpdateTime2(data.day)

        local ishint = false
        for k,v in pairs(data.data.status) do
            if v == 1 then
                ishint = true
                break
            end
        end
        ui.sethint(self.rootItems.hint_xuanyue2,ishint)
    end
    
end

function main.xuanyueTreasuresUpdateTime2(self,data)

    local timediff = 0
    local config = gamedata.config:getConfigByName("peak_time")[tostring(16)]
    if config.param == 3 and config["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(config["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    elseif config.param == 1 then
        local cpnum = data.cpnum
        local cpday = data.cpday

        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(config["continued_time"]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    end
    print("xuanyueTreasuresUpdateTime2",timediff)

    if timediff < 86400 then
        gameTimer:rigistTime("main_xuanyueTreasuresTime2",timediff)        
        gameTimer:rigistTimeFunc("main_xuanyueTreasuresTime2", function()
            if gameTimer.times["main_xuanyueTreasuresTime2"] <= 0 then
                self.rootItems.xuanyuetime2:setString(gameConfig.strings:string_common("xuanyueTreasures",15))
                gameTimer:UnrigistTimeFunc("main_xuanyueTreasuresTime2")
            else

                ui.setLabelString(self.rootItems.xuanyuetime2,ui.makeTimeDayText(gameTimer.times["main_xuanyueTreasuresTime2"],"hour"),26)
            end
        end)
    else
        self.rootItems.xuanyuetime2:setString("")
    end
end

function main.setXuanyueTreasures3(self,data)
    self:setNode(data.day.isopen == 1,"xuanyue3node")
    if data.day.isopen == 1 then
        self:xuanyueTreasuresUpdateTime3(data.day)

        local ishint = false
        for k,v in pairs(data.data.status) do
            if v == 1 then
                ishint = true
                break
            end
        end
        ui.sethint(self.rootItems.hint_xuanyue3,ishint)
    end
    
end

function main.xuanyueTreasuresUpdateTime3(self,data)

    local timediff = 0
    local config = gamedata.config:getConfigByName("peak_time")[tostring(17)]
    if config.param == 3 and config["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(config["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    elseif config.param == 1 then
        local cpnum = data.cpnum
        local cpday = data.cpday

        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(config["continued_time"]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    end
    print("xuanyueTreasuresUpdateTime3",timediff)

    if timediff < 86400 then
        gameTimer:rigistTime("main_xuanyueTreasuresTime3",timediff)        
        gameTimer:rigistTimeFunc("main_xuanyueTreasuresTime3", function()
            if gameTimer.times["main_xuanyueTreasuresTime3"] <= 0 then
                self.rootItems.xuanyuetime3:setString(gameConfig.strings:string_common("xuanyueTreasures",15))
                gameTimer:UnrigistTimeFunc("main_xuanyueTreasuresTime3")
            else

                ui.setLabelString(self.rootItems.xuanyuetime3,ui.makeTimeDayText(gameTimer.times["main_xuanyueTreasuresTime3"],"hour"),26)
            end
        end)
    else
        self.rootItems.xuanyuetime3:setString("")
    end
end

function main.setsanjieliankaoUpdateTime(self)
    print("setsanjieliankaoUpdateTime")
    self:sanjieliankaoUpdateTime()
end

function main.sanjieliankaoUpdateTime(self,data)
    --  local datas = {
    --   { kstype =1, status = 1,currentnum = 0, rightnum = 0, currentTimuid = 0, useAlltime = 0,jifen = 0},
    --   { kstype =2,status = 2, currentnum = 5, rightnum = 2, currentTimuid = 3, useAlltime = 0,jifen = 0},
    --   { kstype =3,status = 3, currentnum = 5, rightnum = 1, currentTimuid = 5, useAlltime = 0,jifen = 0},
    -- }
    
    if data and next(data) ~= nil  then
        printT(data,"self.examinationData data")

       self.examinationData = data.data
    end

    printT(self.examinationData,"self.examinationData")
    print("sanjieliankaoUpdateTime")
    self.sanjieliankaoIsout =  false

    ui.setLabelString(self.rootItems.sanjieliankaoText, nil, 21)

    self:setNode(false,"sanjieliankaonode")
    
    if next(self.examinationData) == nil  then
        return
    end     
    
    local opentype = 0
    for i,v in pairs(self.examinationData) do
       if v.kstype == 2 and ( v.status == 1 or v.status ==2 or v.status ==4 )   then
           opentype = 1
       elseif v.kstype == 3 and ( v.status == 1 or v.status ==2 or v.status ==4  )   then
           opentype = 2
       end 
    end

    print(opentype,"sanjieliankaoUpdateTime opentype")

    if opentype == 0 then return end

    -- gamedata.cache.examination

    local times = GameScene.layers["examination"].module:gettimes(opentype)
    -- local _nowTime = self:getNowTime()
    -- local _allTimes = _nowTime.hour*3600 + _nowTime.min*60 + _nowTime.sec

    -- printT(_nowTime)
    printT(times,"sanjieliankaoUpdateTime times")
    local _remainTime = 0
    if not times then
            print("sanjieliankaoUpdateTime 1")

        gameTimer:rigistTime("main_examination_main_flesh", 7 * 24 * 3600)
        gameTimer:rigistTimeFunc("main_examination_main_flesh", function()
            if GameScene.layers["examination"].module:gettimes(opentype) then
                gameTimer:UnrigistTimeFunc("main_examination_main_flesh")
                self:sanjieliankaoUpdateTime()
            end

            if gameTimer.times["main_examination_main_flesh"] == 0 then
                gameTimer:rigistTime("main_examination_main_flesh", 7 * 24 * 3600)
            end
        end)
    
    elseif times.prompt <= times.now and times.now < times.open then
                    print("sanjieliankaoUpdateTime 2")

        self.sanjieliankaoIsout = true
        self:setNode(true,"sanjieliankaonode")

        _remainTime = times.open - times.now
        
        gameTimer:rigistTime("main_examination_reading", _remainTime)
        gameTimer:rigistTimeFunc("main_examination_reading", function()
            if gameTimer.times["main_examination_reading"] >= 0 then
                ui.setLabelString(self.rootItems.sanjieliankaotime, gameConfig.strings:string_common("examination", 6)..ui.makeTimeText(gameTimer.times["main_examination_reading"], "hour"), 26)
            end

            if gameTimer.times["main_examination_reading"] == 0 then
                print("main_examination_reading====0000")
                gameTimer:UnrigistTimeFunc("main_examination_reading")

                self:sanjieliankaoUpdateTime()
            end
        end)
    elseif times.open <= times.now and times.now < times.over then
                    print("sanjieliankaoUpdateTime 3")

        self.sanjieliankaoIsout = false
        self:setNode(true,"sanjieliankaonode")

        _remainTime = times.over - times.now
        gameTimer:rigistTime("main_examination_start", _remainTime)
        gameTimer:rigistTimeFunc("main_examination_start", function()
            if gameTimer.times["main_examination_start"] >= 0 then
                ui.setLabelString(self.rootItems.sanjieliankaotime, gameConfig.strings:string_common("examination", 7)..ui.makeTimeText(gameTimer.times["main_examination_start"], "hour"), 26)
            end

            if gameTimer.times["main_examination_start"] == 0 then
                print("main_examination_start====0000")
                gameTimer:UnrigistTimeFunc("main_examination_start")

                self:sanjieliankaoUpdateTime()
            end
        end)
    elseif times.over <= times.now and times.now < times.finaly then
                    print("sanjieliankaoUpdateTime 4")

        self.sanjieliankaoIsout = false
        self:setNode(true,"sanjieliankaonode")

        _remainTime = times.finaly - times.now

        gameTimer:rigistTime("main_examination_rewards", _remainTime)
        gameTimer:rigistTimeFunc("main_examination_rewards",function()
            if gameTimer.times["main_examination_rewards"] >= 0 then
                ui.setLabelString(self.rootItems.sanjieliankaotime, gameConfig.strings:string_common("examination", 8)..ui.makeTimeText(gameTimer.times["main_examination_rewards"], "hour"), 26)
            end
            
            if gameTimer.times["main_examination_rewards"] == 0 then
                print("main_examination_rewards====0000")  
                gameTimer:UnrigistTimeFunc("main_examination_rewards")

                self:sanjieliankaoUpdateTime()
            end
        end)
    else
        print("活动结束活动结束活动结束活动结束===")
        -- 这是武道会的变量还没有更改
        self.sanjieliankaoIsout = true
        self:setNode(false,"sanjieliankaonode")
        ui.setLabelString(self.rootItems.sanjieliankaotime, gameConfig.strings:string_common("examination", 26), 21)
    end

end


function main.setdaoguanshouweiUpdateTime(self)
    self:daoguanUpdateTime()
end

function main.daoguanUpdateTime(self)
    print("daoguanUpdateTime")
    self.daoguanIsout = false

    ui.setLabelString(self.rootItems.daoguanText, nil, 21)

    self:setNode(false,"daoguannode")

    local times = GameScene.layers["daoGuanMain"].module:gettimes()
    -- local _nowTime = self:getNowTime()
    -- local _allTimes = _nowTime.hour*3600 + _nowTime.min*60 + _nowTime.sec

    -- printT(_nowTime)
    printT(times)
    local _remainTime = 0

    if not times then
        gameTimer:rigistTime("main_daoguan_main_flesh", 7 * 24 * 3600)
        gameTimer:rigistTimeFunc("main_daoguan_main_flesh", function()
            if GameScene.layers["daoGuanMain"].module:gettimes() then
                gameTimer:UnrigistTimeFunc("main_daoguan_main_flesh")
                self:daoguanUpdateTime()
            end

            if gameTimer.times["main_daoguan_main_flesh"] == 0 then
                gameTimer:rigistTime("main_daoguan_main_flesh", 7 * 24 * 3600)
            end
        end)
    
    elseif times.prompt <= times.now and times.now < times.open then
        self.daoguanIsout = true
        self:setNode(true,"daoguannode")

        _remainTime = times.open - times.now
        
        gameTimer:rigistTime("main_daoguan_reading", _remainTime)
        gameTimer:rigistTimeFunc("main_daoguan_reading", function()
            if gameTimer.times["main_daoguan_reading"] >= 0 then
                ui.setLabelString(self.rootItems.daoguantime, gameConfig.strings:string_common("daoguanshouwei", 23)..ui.makeTimeText(gameTimer.times["main_daoguan_reading"], "hour"), 26)
            end

            if gameTimer.times["main_daoguan_reading"] == 0 then
                print("main_daoguan_reading====0000")
                gameTimer:UnrigistTimeFunc("main_daoguan_reading")

                self:daoguanUpdateTime()
            end
        end)
    elseif times.open <= times.now and times.now < times.over then
        self.daoguanIsout = false
        self:setNode(true,"daoguannode")

        _remainTime = times.over - times.now
        gameTimer:rigistTime("main_daoguan_start", _remainTime)
        gameTimer:rigistTimeFunc("main_daoguan_start", function()
            if gameTimer.times["main_daoguan_start"] >= 0 then
                ui.setLabelString(self.rootItems.daoguantime, gameConfig.strings:string_common("daoguanshouwei", 24)..ui.makeTimeText(gameTimer.times["main_daoguan_start"], "hour"), 26)
            end

            if gameTimer.times["main_daoguan_start"] == 0 then
                print("main_daoguan_start====0000")
                gameTimer:UnrigistTimeFunc("main_daoguan_start")

                self:daoguanUpdateTime()
            end
        end)
    elseif times.over <= times.now and times.now < times.finaly then
        self.daoguanIsout = false
        self:setNode(true,"daoguannode")

        _remainTime = times.finaly - times.now

        gameTimer:rigistTime("main_daoguan_rewards", _remainTime)
        gameTimer:rigistTimeFunc("main_daoguan_rewards",function()
            if gameTimer.times["main_daoguan_rewards"] >= 0 then
                ui.setLabelString(self.rootItems.daoguantime, gameConfig.strings:string_common("daoguanshouwei", 25)..ui.makeTimeText(gameTimer.times["main_daoguan_rewards"], "hour"), 26)
            end
            
            if gameTimer.times["main_daoguan_rewards"] == 0 then
                print("main_daoguan_rewards====0000")  
                gameTimer:UnrigistTimeFunc("main_daoguan_rewards")

                self:daoguanUpdateTime()
            end
        end)
    else
        print("活动结束活动结束活动结束活动结束===")
        -- 这是武道会的变量还没有更改
        self.daoguanIsout = true
        self:setNode(false,"daoguannode")

        ui.setLabelString(self.rootItems.daoguantime, gameConfig.strings:string_common("daoguanshouwei", 26), 21)
    end
end

function main.getNowTime(self)
    return os.date("*t", gamedata:time())
end

function main.getDayNum(self, nowTime)
    return nowTime.wday == 1 and 7 or (nowTime.wday - 1)
end

function main.getAllTimes(self, nowTime, dayNums)
    return (dayNums - 1) * 24 * 3600 + nowTime.hour * 3600 + nowTime.min * 60 + nowTime.sec - 1
end

function main.getTimeNum(self, times, minnum)
    local _min = minnum or 0
    local _allTimes = (times.week and (times.week - 1) or 0) * 24 * 3600 + (times.hour or 0) * 3600 + times.min * 60 + times.sec + _min * 60
    return _allTimes
end


function main.gonghuizhanUpdateTime(self,gangdata)
    printT(gangdata,"gangdata===")
    if not gangdata or ( not next(gangdata)) then 
        return 
    else
        self.gangdata = gangdata
    end

    if gamedata.config.gang2_battleTime and gamedata.config.gang2_battleTime["1"] and gamedata.config.gang2_battleTime["1"]["1"] and gamedata.config.gang2_battleTime["1"]["1"].weektime_open and gamedata.config.gang2_battleTime["1"]["1"].weektime_open > 0 then
        
    else
        return
    end


    local battletimeconfig = gamedata.config.gang2_battleTime
    local beginreadingnum = {}
    local endreadingnum = {}

    -- 夺宝战 第一场宝物领奖
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["5"]["overtime"])
    self.endrewardgnum1 = {week=battletimeconfig["1"]["5"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["5"]["overtime"])
    self.endrewardgnum2 = {week=battletimeconfig["2"]["5"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 第二场入场时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["2"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["2"]["overtime"])
    self.beginreadingnum2 = {week=battletimeconfig["2"]["2"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endreadingnum2 = {week=battletimeconfig["2"]["2"]["weektime_over"], hour=hour2, min=min2, sec=sec2}
    -- self.beginreadingnum2 = {week=2, hour=21, min=11, sec=30}
    -- self.endreadingnum2 = {week=2, hour=21, min=15, sec=1}

    -- 夺宝战 第一场入场时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["2"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["2"]["overtime"])
    self.beginreadingnum1 = {week=battletimeconfig["1"]["2"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endreadingnum1 = {week=battletimeconfig["1"]["2"]["weektime_over"], hour=hour2, min=min2, sec=sec2}
    --self.beginreadingnum1 = {week=2, hour=21, min=11, sec=20}
    --self.endreadingnum1 = {week=2, hour=21, min=15, sec=1}


    local nowtime = os.date("*t", gamedata:time())
    -- print("nowtime===")
    -- printT(nowtime)
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1



    if alltimes >= self:gettimenum(self.endrewardgnum1) and alltimes < self:gettimenum(self.endrewardgnum2) then
        beginreadingnum = self.beginreadingnum2
        endreadingnum = self.endreadingnum2
    else
        beginreadingnum = self.beginreadingnum1
        endreadingnum = self.endreadingnum1
    end
    
    ui.setLabelString(self.rootItems.guildWarText,nil,21)

    -- self.isBossOver = false
    -- print("gangdata===",GameScene:checkopenlevelbyId(171,true))
    printT(self.gangdata)
    if GameScene:checkopenlevelbyId(171,true) and next(self.gangdata) and self.gangdata.id > 0 then
        gameTimer:rigistTime("guildwarbegintimer",99999)
        gameTimer:rigistTimeFunc("guildwarbegintimer",function()

            local nowtime = os.date("*t", gamedata:time())
            -- print("nowtime===")
            -- printT(nowtime)
            local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
            local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

            -- print("timenums===",self:gettimenum(beginreadingnum),alltimes,self:gettimenum(endreadingnum))

            if self:gettimenum(beginreadingnum) <= alltimes and alltimes < self:gettimenum(endreadingnum) then
                self:setNode(true,"guildWarnode")
                local remindtime = self:gettimenum(endreadingnum) - alltimes
                ui.setLabelString(self.rootItems.guildWartime,ui.makeTimeText(remindtime),26)
                
                self:setButtonFunc(self.rootItems.guildWar,true,self.buttontouch,function()
                    -- GameScene:shiftLayerById(21)

                    local globalconfig = gamedata.config.global_kv
                    if tonumber(self.gangdata.level) >= tonumber(globalconfig.gang2_signup_minlevel.value) then
                        --GameScene:shiftLayer("gangwar_main","up")
                        UIRequest({type = 2130, param = "main"})
                    else
                        runGamePrompt({msg = gameConfig.strings:guildOpenLv(globalconfig.gang2_signup_minlevel.value)})
                    end

                    -- UIRequest({type = 2130, param = "main"})
                end)

            else
                self:setNode(false,"guildWarnode")
            end


            if gameTimer.times["guildwarbegintimer"] <= 0 then
                gameTimer:rigistTime("guildwarbegintimer",99999)
            end
        end)
    else
        self:setNode(false,"guildWarnode")
    end
end

-- 公会战倒数时间计算（秒
function main.gettimenum(self,times,minnum)
    -- print("minnum===",minnum)
    local min = 0
    if minnum then
        min = minnum
    end
    local alltimes = 0
    alltimes = (times.week and (times.week-1) or 0)*24*3600 + (times.hour or 0)*3600 + times.min*60 + times.sec + min*60
    return alltimes
end


-- 世界boss数据请求
function main.requestWorldBossdata(self)
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    if nowtimesec <= self.bosstime[1].beginT then             
    elseif nowtimesec < self.bosstime[1].endT then
        UIRequest({type = 3400,mainRequest = 1}) -- 龙
    elseif nowtimesec <= self.bosstime[2].beginT then
    elseif nowtimesec < self.bosstime[2].endT then
        UIRequest({type = 3410,mainRequest = 1}) -- 凤
    end

    self.isBossOver = false

    gameTimer:rigistTime("bossbegintimer",99999)
    gameTimer:rigistTimeFunc("bossbegintimer",function()
        local nowtime = os.date("*t", gamedata:time())
        local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec
        -- print("bossbegintimer===",ui.makeTimeText(self.bosstime[1].beginT-nowtimesec))

        if nowtimesec < self.bosstime[1].beginT-600 or (nowtimesec > self.bosstime[1].endT and nowtimesec < self.bosstime[2].beginT-600) or nowtimesec > self.bosstime[2].endT then
            self:setNode(false,"bossnode")
        else
            self:setNode(false,"bossnode")
            self:reloadLimitedestHint()
            -- local bossid = 30001

            -- self.rootItems.boss:setSwallowsTouch(true)
            -- self.rootItems.boss:setTouchPriority(self.buttontouch)
            -- if nowtimesec <= self.bosstime[1].beginT then
            --     if self.rootItems.bosstype1 and self.rootItems.bosstype2 then
            --         self.rootItems.bosstype1:setVisible(true)
            --         self.rootItems.bosstype2:setVisible(false)
            --     end
            --     ui.setLabelString(self.rootItems.bosstime,ui.makeTimeText(self.bosstime[1].beginT-nowtimesec),26)
            --     self.rootItems.boss:addHandleOfControlEvent(function()
            --         runGamePrompt({msg = self.bosstime[1].openTipText})
            --         -- GameScene:shiftLayerById(21,{page = "onepage"})
            --         GameScene.boosPanlParam = {page = "onepage"};
            --         UIRequest({type = 3416})
            --     end, CCControlEventTouchUpInside)                
            -- elseif nowtimesec < self.bosstime[1].endT then
            --     if self.rootItems.bosstype1 and self.rootItems.bosstype2 then
            --         self.rootItems.bosstype1:setVisible(true)
            --         self.rootItems.bosstype2:setVisible(false)
            --     end
            --     if self.isBossOver then
            --         ui.setLabelString(self.rootItems.bosstime,"已被击杀！",12)
            --     else
            --         ui.setLabelString(self.rootItems.bosstime,"已经开始啦！",26)
            --     end
            --     -- ui.setLabelString(self.rootItems.bosstime,"已经开始啦！",26)
            --     self.rootItems.boss:addHandleOfControlEvent(function()
            --         -- GameScene:shiftLayerById(21,{page = "onepage"})
            --         GameScene.boosPanlParam = {page = "onepage"};
            --         UIRequest({type = 3416})
            --     end, CCControlEventTouchUpInside)
            -- elseif nowtimesec <= self.bosstime[2].beginT then
            --     if self.rootItems.bosstype1 and self.rootItems.bosstype2 then
            --         self.rootItems.bosstype1:setVisible(false)
            --         self.rootItems.bosstype2:setVisible(true)
            --     end
            --     ui.setLabelString(self.rootItems.bosstime,ui.makeTimeText(self.bosstime[2].beginT-nowtimesec),26)
            --     self.rootItems.boss:addHandleOfControlEvent(function()
            --         runGamePrompt({msg = self.bosstime[2].openTipText})
            --         -- GameScene:shiftLayerById(21,{page = "twopage"})
            --         GameScene.boosPanlParam = {page = "twopage"};
            --         UIRequest({type = 3416})
            --     end, CCControlEventTouchUpInside)
            --     bossid = 31001
            -- elseif nowtimesec < self.bosstime[2].endT then
            --     if self.rootItems.bosstype1 and self.rootItems.bosstype2 then
            --         self.rootItems.bosstype1:setVisible(false)
            --         self.rootItems.bosstype2:setVisible(true)
            --     end
            --     if self.isBossOver then
            --         ui.setLabelString(self.rootItems.bosstime,"已被击杀！",12)
            --     else
            --         ui.setLabelString(self.rootItems.bosstime,"已经开始啦！",26)
            --     end
            --     -- ui.setLabelString(self.rootItems.bosstime,"已经开始啦！！",12)
            --     self.rootItems.boss:addHandleOfControlEvent(function()
            --         GameScene.boosPanlParam = {page = "twopage"};
            --         UIRequest({type = 3416})
            --         -- GameScene:shiftLayerById(21,{page = "twopage"})
            --     end, CCControlEventTouchUpInside)
            --     bossid = 31001
            -- end
            -- local bossconfig = gamedata.config.boss2[tostring(bossid)]
            -- local bossName = gamedata.config.generalanimation[tostring(bossconfig.animationid)].name

            -- if bossName == "nianshou" and self.rootItems.bosstype1 and self.rootItems.bosstype2 then
            --     setSpriteFrameByName(self.rootItems.bosstype1,"b_n_main_worldboss3","public/language")
            --     setSpriteFrameByName(self.rootItems.bosstype2,"b_n_main_worldboss3","public/language")
            -- end

        end

        if gameTimer.times["bossbegintimer"] <= 0 then
            gameTimer:rigistTime("bossbegintimer",99999)
        end
    end)
end

-- 世界boss是否死亡
function main.setWorldBossStatus(self,data)
    if data and tonumber(data) == 0 then
        self.isBossOver = true
    else
        self.isBossOver = false
    end
end

function main.clear(self)
    if self.timer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
    end

    self.buttonshow = false
    self.buttonshow2 = false

    self.timer = nil
    self.playingSound = nil
    gameTimer:UnrigistTimeFunc("online_reward")
    gameTimer:UnrigistTimeFunc("online_rewardbytime")
    gameTimer:UnrigistTimeFunc("mainslot")
    gameTimer:UnrigistTimeFunc("mainqiyunode")
    gameTimer:UnrigistTimeFunc("maintimebagnode")
    gameTimer:UnrigistTimeFunc("bossbegintimer")
    gameTimer:UnrigistTimeFunc("guildwarbegintimer")
    
    gameTimer:UnrigistTimeFunc("main_wudaohui_main_flesh")
    gameTimer:UnrigistTimeFunc("main_wudaohui_reading")
    gameTimer:UnrigistTimeFunc("main_wudaohui_start")
    gameTimer:UnrigistTimeFunc("main_wudaohui_rewards")


    gameTimer:UnrigistTimeFunc("main_examination_main_flesh")
    gameTimer:UnrigistTimeFunc("main_examination_reading")
    gameTimer:UnrigistTimeFunc("main_examination_start")
    gameTimer:UnrigistTimeFunc("main_examination_rewards")
    gameTimer:UnrigistTimeFunc("main_bet")

    gameTimer:UnrigistTimeFunc("main_daoguan_main_flesh")
    gameTimer:UnrigistTimeFunc("main_daoguan_reading")
    gameTimer:UnrigistTimeFunc("main_daoguan_start")
    gameTimer:UnrigistTimeFunc("main_daoguan_rewards")

    gameTimer:UnrigistTimeFunc("main_holidaytime")

    gameTimer:UnrigistTimeFunc("main_xuanyueTreasuresTime")
    gameTimer:UnrigistTimeFunc("main_xuanyueTreasuresTime2")
    gameTimer:UnrigistTimeFunc("main_xuanyueTreasuresTime3")
    
    gameTimer:UnrigistTimeFunc("main_ancientRuinsTime")
    gameTimer:UnrigistTimeFunc("main_zaotangTime")
    gameTimer:UnrigistTimeFunc("main_feastTime")
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.slotpos = {}
    --self.rotaAngle = 0
    --self.bossnodePosY = nil
    self.holiday_Node = nil
    self.holiday_Items = nil
    self.holiday_animationManager = nil

    self.arrangelist = {}

    self.examinationData = {}

end

function main.setSuo(self)
    self.suoconfig = {
        mogong = {sysid = 115,suo = false},
        --huoban = {sysid = 6,suo = false},
        mochong = {sysid = 49,suo = false},
        -- lieming = {sysid = 9,suo = false},
        gonghui = {sysid = 28,suo = false},
        qiankunlu = {sysid = 161,suo = false},
        kezhan = {sysid = 138,suo = false},
        --achieve = {sysid = 75,suo = false},
        -- mofu = {sysid = 146,suo = false},
        -- equipup = {sysid = 150,suo = false},
        fabao = {sysid = 149,suo = false},
        -- manor = {sysid = 262,suo = false},
        -- artifact = {sysid = 396,suo = false},
        zhushou = {sysid = 566,suo = false},
    }


    for k,v in pairs(self.suoconfig) do
        if not gameConfig:checkBuildOpen(v.sysid) then

            if v.sysid == 566 then
                v.suo = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("m_suo.png"))
                self.rootItems[k.."BN"]:addChild(v.suo)
                ui.addGray("CCControlButton",self.rootItems[k])
            else
                self.rootItems[k.."BN"]:setVisible(false)
            end
            
        else
            if not GameScene:checkopenlevelbyId(v.sysid,true) then
                if not v.suo then
                    v.suo = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("m_suo.png"))
                    self.rootItems[k.."BN"]:addChild(v.suo)
                else
                    v.suo:setVisible(true)
                end
                ui.addGray("CCControlButton",self.rootItems[k])
            else
                if v.suo then
                    v.suo:setVisible(false)
                end
                ui.removeGray("CCControlButton",self.rootItems[k])
            end
        end
    end
    self.buttonitemsuoconfig = {
        m_rank = {sysid = 155,suo = false},
        achieve = {sysid = 75,suo = false},
    }
    for k,v in pairs(self.buttonitemsuoconfig) do
        if not gameConfig:checkBuildOpen(v.sysid) then
            self.buttonitem[k.."BN"]:setVisible(false)
        else
            if not GameScene:checkopenlevelbyId(v.sysid,true) then
                if not v.suo then
                    v.suo = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("m_suo.png"))
                    self.buttonitem[k.."BN"]:addChild(v.suo)
                else
                    v.suo:setVisible(true)
                end
                ui.addGray("CCControlButton",self.buttonitem[k])
            else
                if v.suo then
                    v.suo:setVisible(false)
                end
                ui.removeGray("CCControlButton",self.buttonitem[k])
            end
        end
    end

    self.buttonitem2suoconfig = {
        mofu = {sysid = 146,suo = false},
        manor = {sysid = 262,suo = false},
        artifact = {sysid = 396,suo = false},
        lieming = {sysid = 9,suo = false},
        auction = {sysid = 377,suo = false},
        change = {sysid = 465,suo = false},
        godSoulTemple = {sysid = 525,suo = false},
        illusion = {sysid = 599,suo = false},
        qiling = {sysid = 612,suo = false},
        tokenBag = {sysid = 632,suo = false},
    }

    for k,v in pairs(self.buttonitem2suoconfig) do
        if not gameConfig:checkBuildOpen(v.sysid) then
            self.buttonitem2[k.."BN"]:setVisible(false)
        else
            if not GameScene:checkopenlevelbyId(v.sysid,true) then
                if not v.suo then
                    v.suo = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("m_suo.png"))
                    self.buttonitem2[k.."BN"]:addChild(v.suo)
                else
                    v.suo:setVisible(true)
                end
                ui.addGray("CCControlButton",self.buttonitem2[k])
            else
                if v.suo then
                    v.suo:setVisible(false)
                end
                ui.removeGray("CCControlButton",self.buttonitem2[k])
            end
        end
    end
end

function main.reloaddata(self,data)
    self.data = data

    if self.data.firststatus == 2 then
        self:setNode(false,"firstchargenode",true)
        -- self.rootItems.firstchargenode:setPosition(9999,9999)
    else
        self:setNode(true,"firstchargenode",true)
        -- self.rootItems.firstcharge:addHandleOfControlEvent(function()
        --     gameWindows:openWindow("firstrecharge",self.data,nil)
        --     UIRequest({type = 999901,id=11})
        -- end, CCControlEventTouchUpInside)
    end

    -- todo
    if gameConfig:checkBuildOpen(353) then
        self:checkvipkefu()
    end

end

function main.reloadforeverddata(self,data)
    self.foreverdata = data
    
    printT(self.foreverdata,"reloadforeverddata")
    if self.data.firststatus == 2 and self.foreverdata then
        self:setNode(true,"foreverrechargenode")
        if self.foreverdata.status == 1 then
            ui.sethint(self.rootItems.hint_foreverrecharge,true)
        else
            ui.sethint(self.rootItems.hint_foreverrecharge,false)
        end
    else
        self:setNode(false,"foreverrechargenode")
    end
end

function main.reloadOnlinereward(self,data)

    if not next(data) then
        self:setNode(false,"onlinerewardnode",true)
    else
        self:setNode(true,"onlinerewardnode")
        self.onlinedata = data
        self.onlinedata.active = not (gameTimer.times["online_reward"] and gameTimer.times["online_reward"] > 0)

        self:setButtonFunc(self.rootItems.onlinereward,true,self.buttontouch,function()
            gameWindows:openWindow("online",self.onlinedata,nil)
        end)
        self.rootItems.hint_onlinereward:setVisible(false)
        self.rootItems.online_reward_time:setVisible(true)

        if gameTimer.times["online_reward"] and gameTimer.times["online_reward"] > 0 then
            ui.setLabelString(self.rootItems.online_reward_time,ui.makeTimeText(gameTimer.times["online_reward"]),26)
            gameTimer:rigistTimeFunc("online_reward",function()
            --print(gameTimer.times["online_reward"])

                if gameTimer.times["online_reward"] > 0 then
                    self.rootItems.hint_onlinereward:setVisible(false)
                    ui.setLabelString(self.rootItems.online_reward_time,ui.makeTimeText(gameTimer.times["online_reward"]),26)
                    gameWindows.windows.online.module:reset({time = ui.makeTimeText(gameTimer.times["online_reward"])})
                else
                    self.rootItems.online_reward_time:setVisible(false)
                    self.rootItems.hint_onlinereward:setVisible(true)
                    self.onlinedata.active = true
                    gameWindows.windows.online.module:reset({active = true})
                end
            end)
        else
            self.rootItems.online_reward_time:setVisible(false)
            self.rootItems.hint_onlinereward:setVisible(true)
            self.onlinedata.active = true
            gameWindows.windows.online.module:reset({active = true})
        end
    end
end

function main.reloadOnlinerewardByTime(self,data)

    if not next(data) then
        self:setNode(false,"onlinerewardbytimenode",true)
    else
        self:setNode(true,"onlinerewardbytimenode")
        self.onlinebytimedata = data
        self.onlinebytimedata.active = not (gameTimer.times["online_rewardbytime"] and gameTimer.times["online_rewardbytime"] > 0)

        self:setButtonFunc(self.rootItems.onlinerewardbytime,true,self.buttontouch,function()
            gameWindows:openWindow("onlinebytime",self.onlinebytimedata,nil)
        end)
        self.rootItems.hint_onlinerewardbytime:setVisible(false)
        self.rootItems.online_rewardbytime_time:setVisible(true)

        if gameTimer.times["online_rewardbytime"] and gameTimer.times["online_rewardbytime"] > 0 then
            ui.setLabelString(self.rootItems.online_rewardbytime_time,ui.makeTimeText(gameTimer.times["online_rewardbytime"]),26)
            gameTimer:rigistTimeFunc("online_rewardbytime",function()
            --print(gameTimer.times["online_reward"])

                if gameTimer.times["online_rewardbytime"] > 0 then
                    self.rootItems.hint_onlinerewardbytime:setVisible(false)
                    ui.setLabelString(self.rootItems.online_rewardbytime_time,ui.makeTimeText(gameTimer.times["online_rewardbytime"]),26)
                    gameWindows.windows.onlinebytime.module:reset({time = ui.makeTimeText(gameTimer.times["online_rewardbytime"])})
                else
                    self.rootItems.online_rewardbytime_time:setVisible(false)
                    self.rootItems.hint_onlinerewardbytime:setVisible(true)
                    self.onlinebytimedata.active = true
                    gameWindows.windows.onlinebytime.module:reset({active = true})
                end
            end)
        else
            self.rootItems.online_rewardbytime_time:setVisible(false)
            self.rootItems.hint_onlinerewardbytime:setVisible(true)
            self.onlinebytimedata.active = true
            gameWindows.windows.onlinebytime.module:reset({active = true})
        end
    end
end

function main.reloadchat(self,data)
    if data.result == 0 then -- 没有消息
        self.rootItems.mainfriend:setVisible(false)
    else -- 有消息
        self.rootItems.mainfriend:setVisible(true)
    end
end

function main.reloadtimebag( self,data )
    if next(data.timebag) then
        self.rootItems.maintimebag:setVisible(true)

        local updatetime = 0
        for k,v in pairs(data.timebag) do
            if v.status == 0 and v.time>updatetime then
                updatetime = v.time
            end
        end

        if updatetime and updatetime >0 then
            gameTimer:rigistTime("maintimebagnode",updatetime)
            if gameTimer.times["maintimebagnode"] and gameTimer.times["maintimebagnode"] > 0 then
                gameTimer:rigistTimeFunc("maintimebagnode",function()
                    if gameTimer.times["maintimebagnode"] > 0 then
                        print("maintimebagnode",gameTimer.times["maintimebagnode"])
                    else
                        UIRequest({type = 2880})
                    end
                end)
            end
        end
    else
        self.rootItems.maintimebag:setVisible(false)
    end
end

function main.checkvipkefu(self)
    print("checkvipkefu")

    local channel = deviceApi.channel or ""

    if string.find(channel, "muyou") or string.find(channel, "zuoyaoji") or string.find(channel, "17weixin") or string.find(channel, "17qq") or ((deviceApi.platform == "ios") and ((channel == "fzYSJ") or (channel == "fzSSNYJ") or (channel == "fzZXXMJ")))then

        local config = gamedata.config.vip_kefu or {}
        self.vipkefutype = 0
        for i = 1,10 do
            if config[tostring(i)] then
                if self.data.rmb >= config[tostring(i)].rmb then
                    self.vipkefutype = i
                end
            end
        end
        if self.oldvipkefutype and self.oldvipkefutype < self.vipkefutype then
            gameWindows:openWindow("vipkefu",{viptype = self.vipkefutype})
        end
        self.oldvipkefutype = self.vipkefutype
        --
        if self.buttonitem.vipkefu then
            if self.vipkefutype > 0 then
                self.buttonitem.vipkefuNode:setVisible(true)
                self.buttonitem.mainextbg:setVisible(false)
                self.buttonitem.mainextbg2:setVisible(true)
            else
                self.buttonitem.vipkefuNode:setVisible(false)
                self.buttonitem.mainextbg:setVisible(true)
                self.buttonitem.mainextbg2:setVisible(false)
            end
        end

    end
end

function main.checkholiday(self,data)

    print("checkholiday")
    --
    if gamedata.config.holiday_time then

        self.holidaytype = 0
        local now =  gamedata:time()
        local v1 = gamedata.config.holiday_time["1"] 
        local isactive1,resttime1 = ui.checkDateActive(v1.time_open,v1.time_close,now)
        if isactive1 then
            self.holidaytype = 1  --todo
        else
            local v2 = gamedata.config.holiday_time["2"]
            local isactive2,resttime2 = ui.checkDateActive(v2.time_open,v2.time_close,now)
            if isactive2 then
                self.holidaytype = 2
            end
        end 

        if data and data.status then

            self.holidaystatus = 0
            local holidaytime = {}

            gameTimer:UnrigistTimeFunc("main_holidaytime")
            --
            if (self.holidaytype > 0) and data and data.status and (data.status == 1) then
                print("后端判断时间1")
                self.holidaystatus = 3
                GameScene.holidayindex = GameScene.holidayindex or 1
                gameTimer:rigistTime("main_holidaytime", data.time+1)
                gameTimer:rigistTimeFunc("main_holidaytime",function()           
                    if gameTimer.times["main_holidaytime"] > 0 then
                        ui.setLabelString(self.rootItems.main_holidaytime,"结束倒计时:"..ui.makeTimeText(gameTimer.times["main_holidaytime"],"minute"),26)
                        if self.holiday_Items and self.holiday_Items.g_holidaytime then
                            self.holiday_Items.g_holidaytime:setString(ui.makeTimeText(gameTimer.times["main_holidaytime"],"minute"))
                        end
                    end
                    if gameTimer.times["main_holidaytime"] <= 0 then
                        ui.setLabelString(self.rootItems.main_holidaytime,"",26)
                        gameTimer:UnrigistTimeFunc("main_holidaytime")
                        UIRequest({type = 6501})
                    end
                    --print("holidaytime1 "..gameTimer.times["main_holidaytime"])
                end)
            elseif (self.holidaytype > 0) and data and data.status and (data.status == 2) then
                print("后端判断时间2")
                self.holidaystatus = 1
                GameScene.holidayindex = (GameScene.holidayindex or 1) + 1
                ui.setLabelString(self.rootItems.main_holidaytime,"",26)
                gameTimer:rigistTime("main_holidaytime", data.time+1)
                gameTimer:rigistTimeFunc("main_holidaytime",function()           
                    if gameTimer.times["main_holidaytime"] <= 0 then
                        gameTimer:UnrigistTimeFunc("main_holidaytime")
                        UIRequest({type = 6501})
                    end
                    --print("holidaytime2 "..gameTimer.times["main_holidaytime"])
                end)
            -- elseif self.holidaytype > 0 then
            --     print("前端判断时间")
            --     --
            --     local daynow = 0
            --     local temp = os.date("*t", now)
            --     local daynow = os.time({year=temp.year, month=temp.month, day=temp.day, hour=0, min=0, sec=0})
            --     local timetemp = ui.getIDSFromStr(gamedata.config.holiday_time[tostring(self.holidaytype)].time)
            --     local timemin = gamedata.config.holiday_time[tostring(self.holidaytype)].time_min
            --     for i = 1,#timetemp do
            --         table.insert(holidaytime,{tip = daynow+timetemp[i]*3600-5*60, show = daynow+timetemp[i]*3600, showend = daynow+timetemp[i]*3600+timemin*60})
            --     end
            --     --
            --     self.holidaystatus = 0
            --     for i = 1,#holidaytime do
            --         if now < holidaytime[i].showend then
            --             if now >= holidaytime[i].show then
            --                 self.holidaystatus = 3
            --                 GameScene.holidayindex = i
            --                 --
            --                 gameTimer:rigistTime("main_holidaytime", holidaytime[i].showend-now+1)
            --                 gameTimer:rigistTimeFunc("main_holidaytime",function()           
            --                     if gameTimer.times["main_holidaytime"] > 0 then
            --                         ui.setLabelString(self.rootItems.main_holidaytime,"结束倒计时:"..ui.makeTimeText(gameTimer.times["main_holidaytime"],"minute"),26)
            --                         if self.holiday_Items and self.holiday_Items.g_holidaytime then
            --                             self.holiday_Items.g_holidaytime:setString(ui.makeTimeText(gameTimer.times["main_holidaytime"],"minute"))
            --                         end
            --                     end
            --                     if gameTimer.times["main_holidaytime"] <= 0 then
            --                         ui.setLabelString(self.rootItems.main_holidaytime,"",26)
            --                         gameTimer:UnrigistTimeFunc("main_holidaytime")
            --                         UIRequest({type = 6501})
            --                     end
            --                 end)
            --             elseif now >= holidaytime[i].tip then 
            --                 self.holidaystatus = 2
            --                 --
            --                 gameTimer:rigistTime("main_holidaytime", holidaytime[i].show-now+1)
            --                 gameTimer:rigistTimeFunc("main_holidaytime",function()           
            --                     if gameTimer.times["main_holidaytime"] > 0 then
            --                         ui.setLabelString(self.rootItems.main_holidaytime,"开启倒计时:"..ui.makeTimeText(gameTimer.times["main_holidaytime"],"minute"),26)
            --                     end
            --                     if gameTimer.times["main_holidaytime"] <= 0 then
            --                         ui.setLabelString(self.rootItems.main_holidaytime,"",26)
            --                         gameTimer:UnrigistTimeFunc("main_holidaytime")
            --                         UIRequest({type = 6501})
            --                     end
            --                 end)
            --             else 
            --                 self.holidaystatus = 1
            --                 ui.setLabelString(self.rootItems.main_holidaytime,"",26)
            --                 gameTimer:rigistTime("main_holidaytime", holidaytime[i].tip-now+1)
            --                 gameTimer:rigistTimeFunc("main_holidaytime",function()           
            --                     if gameTimer.times["main_holidaytime"] <= 0 then
            --                         gameTimer:UnrigistTimeFunc("main_holidaytime")
            --                         UIRequest({type = 6501})
            --                     end
            --                 end)
            --             end    
            --             break
            --         end
            --     end    
            end    
        end

        if (self.holidaytype > 0) and GameScene.holidaynum and (GameScene.holidaynum < gamedata.config.holiday_time[tostring(GameScene.layers["main"].module.holidaytype)].num) then
            --GameScene.layers["main"].module:setNode((self.holidaytype > 0) and (self.holidaystatus > 1),"holidaynode")
            GameScene.layers["main"].module:setNode(false,"holidaynode")
            if (self.holidaytype > 0) and (self.holidaystatus == 3) then  -- todo
                self:setholiday(true)
            else
                self:setholiday(false)
            end   
        else
            GameScene.layers["main"].module:setNode(false,"holidaynode")
            self:setholiday(false)
        end    
    else
        GameScene.layers["main"].module:setNode(false,"holidaynode")
        self:setholiday(false)
    end    
end

function main.setholiday(self,isshow)

    if isshow then
        self.rootItems.holidayshownode:setVisible(true)
        self.rootItems.holidayshownode2:setVisible(true)
        if self.holidaytype == 1 then
            self.rootItems.slotNode:setVisible(false)
        else
            self.rootItems.slotNode:setVisible(false)
        end    
        
        if self.holiday_Node and self.holiday_Items and self.holiday_animationManager then

        else
            self.rootItems.holidayshownode:removeAllChildrenWithCleanup(true)
            self.rootItems.holidayshownode2:removeAllChildrenWithCleanup(true)
            if self.holidaytype == 1 then
                self.holiday_Node,self.holiday_Items = CCBReaderLoad("activityjieri/activityshengdanliwu", nil, true, "activityshengdanliwu")
                self.holiday_Node:setPosition(0,0)
                self.rootItems.holidayshownode:addChild(self.holiday_Node)
            else
                -- self.holiday_Node,self.holiday_Items = CCBReaderLoad("activityjieri/activityhongbaoyu", nil, true, "activityhongbaoyu")
                self.holiday_Node,self.holiday_Items = CCBReaderLoad("7zhounian/7zhounian_tangguoyu", nil, true, "7zhounian_tangguoyu")
                self.holiday_Node:setPosition(0,0)
                self.rootItems.holidayshownode2:addChild(self.holiday_Node)
            end    
            self.holiday_animationManager = getAnimationManager(self.holiday_Items)
            if (self.holidaytype == 2) or not (GameScene.showholidayfirst and GameScene.showholidayfirst >= (GameScene.holidayindex or 0)) then
                self.holiday_animationManager:runAnimationsForSequenceNamed("1")
                GameScene.showholidayfirst = GameScene.holidayindex or 0
            else
                self.holiday_animationManager:runAnimationsForSequenceNamed("2")
            end
        end
        --
        if self.holiday_Items.g_holidaynum then
            if GameScene.holidaynum and (GameScene.holidaynum < gamedata.config.holiday_time[tostring(GameScene.layers["main"].module.holidaytype)].num) then
                self.holiday_Items.g_holidaynum:setString("剩余"..(gamedata.config.holiday_time[tostring(GameScene.layers["main"].module.holidaytype)].num-GameScene.holidaynum).."次")
            else
                self.holiday_Items.g_holidaynum:setString("剩余0次")
            end    
        end
        --
        -- local pictype = {
        --     [1] = "hongbao_wujiang",
        --     [2] = "hongbao_daoju",
        --     [3] = "hongbao_yinbi",
        --     [4] = "hongbao_yuanbao",
        -- } 
        local pictype = {
            [1] = "hongbaoicon_wujiang",
            [2] = "hongbaoicon_daoju",
            [3] = "hongbaoicon_yinbi",
            [4] = "hongbaoicon_yuanbao",
        } 
        for i = 1,10 do
            local buttonname = "dobutton"..i
            local buttonid = (math.mod(i,4) == 0) and 4 or math.mod(i,4)
            if self.holidaytype == 2 then
                buttonname = "h_button"..((i > 1) and ("_"..(i-1)) or "")
                buttonid = (math.mod(i,4) == 0) and 4 or math.mod(i,4)
                --
                -- setSpriteFrameByName(self.holiday_Items["h_sprite"..((i > 1) and ("_"..(i-1)) or "")],pictype[(math.mod(i,4) == 0) and 4 or math.mod(i,4)],"public/publicsprite")
                setSpriteFrameByName(self.holiday_Items["h_sprite"..((i > 1) and ("_"..(i-1)) or "")],pictype[(math.mod(i,4) == 0) and 4 or math.mod(i,4)],"public/language")
            end
            if self.holiday_Items[buttonname] then   
                self.holiday_Items[buttonname]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    --
                    if GameScene.layers["main"].module and GameScene.layers["main"].module.holidaystatus and GameScene.layers["main"].module.holidaystatus == 3 then
                        if GameScene.layers["main"].module and GameScene.layers["main"].module.holidaytype and GameScene.layers["main"].module.holidaytype > 0 then
                            if GameScene.holidaynum and (GameScene.holidaynum < gamedata.config.holiday_time[tostring(GameScene.layers["main"].module.holidaytype)].num) then
                                if self.holidaytype == 2 then
                                    gameWindows:openWindow("redbag",{id = buttonid },nil)
                                else
                                    gameTouch:clickprofbytime(1.5)    
                                    UIRequest({type = 6502, id = buttonid })
                                end
                            else
                                runGamePrompt({msg = "今日领取次数已用完"})
                            end
                        end
                    elseif GameScene.layers["main"].module and GameScene.layers["main"].module.holidaystatus and GameScene.layers["main"].module.holidaystatus == 2 then    
                        runGamePrompt({msg = "即将开启"})
                    else
                        runGamePrompt({msg = "活动未开启"})
                    end
                end, CCControlEventTouchUpInside)
                self.holiday_Items[buttonname]:setSwallowsTouch(true)
                self.holiday_Items[buttonname]:setTouchPriority(self.buttontouch)
            end
        end
    else
        if self.holiday_Node and self.holiday_Items and self.holiday_animationManager then
            self.holiday_animationManager:setAnimationCompletedCallback(function()
                self.rootItems.holidayshownode:setVisible(false)
                self.rootItems.holidayshownode2:setVisible(false)
                self.rootItems.slotNode:setVisible(true)
                --
                self.rootItems.holidayshownode:removeAllChildrenWithCleanup(true)
                self.rootItems.holidayshownode2:removeAllChildrenWithCleanup(true)
                self.holiday_Node = nil
                self.holiday_Items = nil
                self.holiday_animationManager = nil
            end)
            self.holiday_animationManager:runAnimationsForSequenceNamed("3")
            gameTouch:clickprofbytime(2)
        else    
            self.rootItems.holidayshownode:setVisible(false)
            self.rootItems.holidayshownode2:setVisible(false)
            self.rootItems.slotNode:setVisible(true)
        end
    end    
end    

function main.UIUpdateData(self,isreset)
    if gameWindows.windows["onlinebytime"].show then
        gameWindows:closeWindowDirect("onlinebytime")
    end
    if gameConfig:checkBuildOpen(251) then
        UIRequest({type = 2039})
    end

    self.arrangeconst = {}
    self:setArrange()
end

function main.reloadLimitedestHint(self)
    
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    local hintBoss = false
    if (nowtimesec > self.bosstime[1].beginT and nowtimesec < self.bosstime[1].endT) or (nowtimesec > self.bosstime[2].beginT and nowtimesec < self.bosstime[2].endT) then
        if not self.isBossOver then
            hintBoss = true
        end
    end
    
    local hintdaoguan = false
    local hint = GameScene.hintdata["355"] and GameScene.hintdata["355"] or 0
    if hint ~= 0 then
        --有可领奖
        if hint == 1 then
            hintdaoguan = true
        --有可攻打 也有可领奖
        elseif hint == 11 then
            hintdaoguan = true
        --有可攻打 并且没提示过
        elseif hint == 10 and (not GameScene.layers["daoGuanMain"].module.daoguanOnceHint) then
            hintdaoguan = true
        end
    end

    local times = GameScene.layers["daoGuanMain"].module:gettimes()
    if times then
        if times.now < times.open then
            -- runGamePrompt({msg="即将开启！"})
            hintdaoguan = false
        end
    else
        -- runGamePrompt({msg="不在活动时间内"})
        hintdaoguan = false
    end


    local hintext = false
    local limitedset = {212, 381,452,27,144,191,468}
    for i,v in ipairs(limitedset) do
        if GameScene.hintdata[tostring(v)] and GameScene.hintdata[tostring(v)] ~= 0 then
            hintext = true
            break
        end
    end

    if hintext or hintdaoguan or hintBoss then
        ui.sethint(self.rootItems.hint_limitedset,true)
    else
        ui.sethint(self.rootItems.hint_limitedset,false)
    end
end

return main
