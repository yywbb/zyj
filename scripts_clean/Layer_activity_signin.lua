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
    restresign = 0,
    vip = 0,
    date = {},
    daynum = 0,
    --firstweek = 1,
    dateconfig = {31,28,31,30,31,30,31,31,30,31,30,31,},
}

function signin.findDayNum(self)
    self.date = os.date("*t", os.time())
    --self.firstweek = os.date("*t", os.time{year = self.date.year, month = self.date.month, day = 1})["wday"]
    if  self.date.month == 2 and math.mod( self.date.year,4) == 0 then
        self.daynum = 29
    else
        self.daynum = self.dateconfig[self.date.month]
    end
end

function signin.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitysignin/signin_new",nil, true, "signin_new")

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
       -- ui.setLabelString(item["in_day"..key_Ex], (id+1).."号", 11)
       ui.setLabelString(item["in_day"..key_Ex], gameConfig.strings:idNum(id+1), 11)

       if data.status == 0 then
           item["in_statusnode"..key_Ex]:setVisible(false)
           item["in_usenode"..key_Ex]:setVisible(false)
       elseif data.status == 1 then
           item["in_statusnode"..key_Ex]:setVisible(true)
           item["in_usenode"..key_Ex]:setVisible(false)
           -- item["in_status"..key_Ex]:setString(self.date.day == (id+1) and "领取" or "补签")
           item["in_status"..key_Ex]:setString(self.date.day == (id+1) and gameConfig.strings:string_common("moreCommon",6) or gameConfig.strings:string_common("moreCommon",16))
           if  self.date.day == (id+1) then
               local eccb,eitem = CCBReaderLoad("UIEffect/lizi/qiandao", nil, true, "qiandao")
               item["in_geteffect"..key_Ex]:addChild(eccb)
               eitem.partical:setPositionType(kCCPositionTypeGrouped)
           end
       elseif data.status == 2 then
           item["in_statusnode"..key_Ex]:setVisible(false)
           item["in_usenode"..key_Ex]:setVisible(true)
       end
       item["in_button"..key_Ex]:addHandleOfControlEvent(function()
           printT(self.touchPos,"self.touchPos")
           if self.touchPos and not ui.isTouched(self.coveritems.scrollnode,self.touchPos.x,self.touchPos.y) then
           else
               if data.status ==1 then
                   if self.date.day == (id+1) then
                        UIRequest({type = 2061})
                   else
                       if self.restresign > 0 then
                           gameWindows:openWindow("resignconfirm",{icondata = data,day = id+1},nil)
                       else
                           shortVip()
                       end
                   end
               else
                   ui.setPopwindowByCid(data.cid)
               end
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

    self.vip = data.vip or 0
    local vipsign = gamedata.config.vip[tostring(data.vip)].b_signin or 0
    self.restresign = vipsign - data.status.resign
    self.data = data.status.days
    self:findDayNum()

    -- self.coveritems.month:setString(self.date.month.."月签到奖励")
    self.coveritems.month:setString(gameConfig.strings:monthSign(self.date.month))
    setSpriteFrameByName(self.coveritems.vip,"b_n_vip_"..data.vip)
    ui.setLabelString(self.coveritems["resigntime"], self.restresign.."/"..vipsign, 13)

    if math.ceil(self.date.day/5) > 4 then
        self.coveritems.container:setPositionY(-188*(7-math.ceil(self.date.day/5)))
    end

    local config
    if self.date.month <10 then
        config = gamedata.config["signin_"..self.date.year.."0"..self.date.month]
    else
        config = gamedata.config["signin_"..self.date.year..self.date.month]
    end

    for i=1,35 do
        if i<=self.daynum and config[tostring(i)] then
            local id,num = ui.getIDandNUM(config[tostring(i)].reward)
            local onedata = {
                has = true,
                cid = id,
                num = num,
                status = self.data[tostring(i)]
            }

            self:setOneDay(self.coveritems,onedata,i-1)
        else
            self:setOneDay(self.coveritems,{has = false},i-1)
        end
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