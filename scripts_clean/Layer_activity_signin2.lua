--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/2
-- Time: 上午10:00
-- To change this template use File | Settings | File Templates.
--

local signin = {

    buttontouch = -103,

    data = {},
    date = {},

}


function signin.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitysignin/signin_new_n",nil, true, "signin_new")

    -- self.coveritems.topnode:setPositionY(self.contentsize.y)
    self.coveritems.adaptnode:setPositionY((GameScene.topposY-1620)*0.5+160)

    local function gettouchpos(pos)
        self.touchPos = pos
    end
    gameTouch:rigistFunc("begin","signin",gettouchpos)

    return self.coverccb
end

function signin.setOneDay(self,item,data,id)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end
    item["in_geteffect"..key_Ex]:removeAllChildrenWithCleanup(true)

    if not data.has then
        item["in_root"..key_Ex]:setVisible(false)
    else
        item["in_root"..key_Ex]:setVisible(true)
        ui.setNewIconName(item,data,id)
        item["in_day"..key_Ex]:setString(ui.IDconfig(data.cid).name or "")
        --ui.setLabelString(item["in_day"..key_Ex], ui.IDconfig(data.cid).name or "", 11)

        if data.day <= self.data.daynum then
            item["in_usenode"..key_Ex]:setVisible(true)
        else
            item["in_usenode"..key_Ex]:setVisible(false)
        end

        if data.vip > 0 then
            item["in_statusnode"..key_Ex]:setVisible(true)
            item["in_status"..key_Ex]:setString("贵宾"..data.vip.."双倍")
        else
            item["in_statusnode"..key_Ex]:setVisible(false)
        end

        item["in_button"..key_Ex]:addHandleOfControlEvent(function()
            if self.touchPos and not ui.isTouched(self.coveritems.scrollnode,self.touchPos.x,self.touchPos.y) then
            else
                ui.setPopwindowByCid(data.cid)
            end
        end, CCControlEventTouchUpInside)
        item["in_button"..key_Ex]:setTouchPriority(-101)
    end
end

function signin.reloaddata(self,data)
    if not self.show then return end
    self.coveritems.scroll = tolua.cast(self.coveritems.scroll, "CCScrollView")
    self.coveritems.scroll:setTouchPriority(-103)
    self.coveritems.scroll:setContentOffset(ccp(0, -551))
    --
    self.data = data or {}
    self.date = os.date("*t", os.time())

    self.coveritems.month:setString(self.date.month.."月签到奖励")
    self.coveritems.day:setString(self.data.daynum)
    ui.setLabelString(self.coveritems.day, nil, 23)

    if math.ceil((self.data.daynum+1)/5) > 4 then
        self.coveritems.container:setPositionY(-188*(7-math.ceil((self.data.daynum+1)/5)))
    end

    local config
    if self.date.month <10 then
        config = gamedata.config["sign2_"..self.date.year.."0"..self.date.month]
    else
        config = gamedata.config["sign2_"..self.date.year..self.date.month]
    end

    for i=1,35 do
        if config[tostring(i)] then
            local id,num = ui.getIDandNUM(config[tostring(i)].award)
            local onedata = {
                has = true,
                cid = id,
                num = num,
                day = i,
                vip = 0,
            }
            if config[tostring(i)].double and config[tostring(i)].double == 1 then
                onedata.vip = config[tostring(i)].vip or 0
            end
            self:setOneDay(self.coveritems,onedata,i-1)
        else
            self:setOneDay(self.coveritems,{has = false},i-1)
        end
    end

    ui.setLabelString(self.coveritems.getLab, nil, 19)
    self.coveritems["getButton"]:addHandleOfControlEvent(function()
        print("signin")
        gameTouch:clickprofbytime(1)
        if self.data.status == 1 then
            runGamePrompt({msg = "今日已签到"})
        elseif not config[tostring(self.data.daynum+1)] then
            runGamePrompt({msg = "本月签到已完成"})
        else
            gameTouch:clickprofbytime(0.3)
            UIRequest({type = 3642})
        end
    end, CCControlEventTouchUpInside)
    self.coveritems["getButton"]:setSwallowsTouch(true)
    self.coveritems["getButton"]:setTouchPriority(-102)

    self.coveritems.buttoneffect:removeAllChildrenWithCleanup(true)
    if self.data.status == 1 then
        ui.addGray("CCControlButton",self.coveritems["getButton"])
        ui.addGray("CCLabelTTF",self.coveritems["getLab"])
    elseif not config[tostring(self.data.daynum+1)] then
        ui.addGray("CCControlButton",self.coveritems["getButton"])
        ui.addGray("CCLabelTTF",self.coveritems["getLab"])
    else
        ui.removeGray("CCControlButton",self.coveritems["getButton"])
        ui.removeGray("CCLabelTTF",self.coveritems["getLab"])
        local eccb,eitem = CCBReaderLoad("UIEffect/anniu/anniu_big", nil, true, "anniu_big")
        self.coveritems.buttoneffect:addChild(eccb)
    end


end

function signin.clear(self)
    self.show = false
    self.touchPos = nil
    gameTouch:UnrigistFunc("begin","signin")
    self.data = {}
    self.coverccb = nil
    self.coveritems = nil
end


return signin