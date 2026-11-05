local helperInitSwitch=helper.initSwitch
function helper.initSwitch(self,items,level,page,id)
    local supported=(self.data.localHelperSupported or {})[page..":"..id]
    local button=items[ui.ccbNameEx("s_bt",id)]
    if not supported then
        items[ui.ccbNameEx("s_lb",id)]:setString("后续批次补齐")
        items[ui.ccbNameEx("s_openNode",id)]:setVisible(false)
        items[ui.ccbNameEx("s_closeNode",id)]:setVisible(true)
        button:setTouchEnabled(false)
        return
    end
    button:setTouchEnabled(true)
    return helperInitSwitch(self,items,level,page,id)
end

function helper.refreshActivity(self)
    local items=self.containers.activity.items
    for i=1,15 do self:initSwitch(items,gamedata.config.game_helper["3"][tostring(i)].level,3,i) end
    self:initSelectBox(items,3,3,1,2)
    self:reloadMieshen(items)
    self:reloadGuanxing(items)
    self:reloadPenglai(items)
    self:reloadChampion(items)
    self:reloadJingjichang(items)
    self:reloadFriendCopy(items)
    self:reloadKingman(items)
end

function helper.refreshGuild(self)
    local items=self.containers.guild.items
    for i=1,4 do self:initSwitch(items,gamedata.config.game_helper["4"][tostring(i)].level,4,i) end
end

function helper.reloadGuanxing(self,items)
    self:initSelectBox(items,3,2,1,2)
    self.params[3][2][1]=0
    self.cost[3][2]={}
    items.p2:setString("0")
end

function helper.reloadChampion(self,items)
    local data=self.data.activity["5"]
    local vip=gamedata.config.vip[tostring(GameScene.vip.vip)]
    local limit=math.max(0,vip.champion_times-(data.reset or 0))
    local function price()
        local boxes,resets=self.params[3][5][1] or 1,self.params[3][5][2] or 0
        local perRound,resetPrice=0,0
        for i=1,boxes do perRound=perRound+gamedata.config.buycount_price[tostring(i)].championbox_cost end
        for i=(data.reset or 0)+1,(data.reset or 0)+resets do resetPrice=resetPrice+gamedata.config.buycount_price[tostring(i)].champion_cost end
        items.p5_1:setString(perRound*2*(resets+1));items.p5_2:setString(resetPrice)
        self.cost[3][5]={[1001]=perRound*2*(resets+1)+resetPrice}
    end
    local function boxes(num) self.params[3][5][1]=num;price() end
    local function resets(num) self.params[3][5][2]=num;price() end
    items.resetlb5_1:setString("每关最多5箱")
    boxes(self:initNumModel(3,"5_1",self.showParams[3][5][1],1,5,boxes,gamedata.config.game_helper["3"]["5"].level,"冠军试炼"))
    resets(self:initNumModel(3,"5_2",self.showParams[3][5][2],0,limit,resets,gamedata.config.game_helper["3"]["5"].level,"冠军试炼重置"))
end

function helper.makeHelperParams(self,page)
    local rows={}
    local function selected(group,id)
        return (self.data.localHelperSupported or {})[group..":"..id] and self.setting[group][id][1]==1
            and self:checkOpenLevel(gamedata.config.game_helper[tostring(group)][tostring(id)].level)
    end
    if page=="challenge" then
        for id=1,6 do
            local state=self.data.challenge[tostring(id)]
            if selected(2,id) and state and state.open==1 and self.params[2][id][1]>0 then
                table.insert(rows,self.helperParams(2,id,self.params[2][id][1]))
            end
        end
    elseif page=="activity" then
        for _,id in ipairs({1,2,3,5,9,10,12}) do
            if selected(3,id) then
                local value=self.params[3][id][1]
                if id==5 then
                    table.insert(rows,self.helperParams(3,id,value,self.params[3][id][2]))
                elseif id==10 or id==12 then
                    if value>0 then table.insert(rows,self.helperParams(3,id,value,self.data.activity[tostring(id)].openlevel)) end
                elseif self.setting[3][id][2]==1 then table.insert(rows,self.helperParams(3,id,value)) end
            end
        end
    end
    return rows,{}
end

function helper.executeHelper(self,all)
    local rows={}
    for _,page in ipairs(all and self.pages or {self.selectPage}) do
        local params=self:makeHelperParams(page)
        for _,row in ipairs(params) do table.insert(rows,row) end
    end
    if not next(rows) then
        runGamePrompt({msg="请先勾选本批已接通的项目；其余项目将分批补齐"})
        return
    end
    UIRequest({type=6212,params=rows,ext={}})
end
