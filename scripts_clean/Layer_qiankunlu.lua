--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local Layer_qiankunlu = {

    rootNode = nil,
    rootItems = nil,

    generalFragmentData = nil,

    equipsFragmentData = nil,

    equipsData = nil,

    treasuresData =nil,

    treasuresFragmentData = nil,

    generalData = nil,

    fashionData = nil,

    petData = nil,

    artifactData = nil,

    chooseData = nil,

    redFragmentData = nil,

    showredFragmentData = nil,

    showgeneralFragmentData = nil,

    showequipsFragmentData = nil,

    showequipsData = nil,

    showtreasuresData =nil,

    showtreasuresFragmentData = nil,

    showgeneralData = nil,

    showfashionData = nil,

    showpetData = nil,

    showartifactData = nil,

    allspendgold = 0,

    allspendcoin = 0,

    exceptdata = {},

    pageconfig = {"lianhua","chongsheng","fenjie"} ,
    pagename = {"炼化","重生","分解"},
    selectpage = "lianhua",

    hintconfig = {
        {
            name = "rootItems",
            config = {
                title1 = {161},
            },
        },
    },

    resolvequality = 4,

    petiid = 0,

}



function Layer_qiankunlu.shiftPage(self,type,state)

    -- print("shiftPage===type,selectpage==",type,self.selectpage,state)
    if state then

    elseif type and self.selectpage == type then
        -- print("nothing..change")
        return
    end
    -- print("isopen==")

    if type then
        self.selectpage = type
    end


    self.chooseData = nil

    self.showredFragmentData = nil
    self.showgeneralFragmentData = nil
    self.showequipsData = nil
    self.showtreasuresData = nil
    self.showgeneralData = nil
    self.showequipsFragmentData = nil
    self.showtreasuresFragmentData = nil

    -- print("i...am..shiftPage",type)

    for k,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            --self.rootItems[v.."Node"]:setPosition(ccp(540.0,960.0))
            self.rootItems[v.."Node"]:setVisible(true)
        else
            --self.rootItems[v.."Node"]:setPosition(ccp(9999,-460))
            self.rootItems[v.."Node"]:setVisible(false)
        end
    end

    --
    if self.rootItems.secretBtn then
        self.rootItems.secretBtn:setVisible(false)
    end    
    if self.rootItems.jinghuaBtn then
        self.rootItems.jinghuaBtn:setVisible(false)
    end   
    --

    if self.selectpage == "lianhua" then 

        if self.rootItems.secretBtn then
            self.rootItems.secretBtn:setVisible(true)
        end  

        self.rootItems.showItemsNode:setVisible(true)        
        UIRequest({type = 3704})

        self:setHint()
        -- self:lianhuaSortData()
        -- self:setShowItems()

    elseif self.selectpage == "chongsheng" then
        UIRequest({type = 7030})
        --self.rootItems.showItemsNode:setPosition(ccp(9999.0,-460))
        self.rootItems.showItemsNode:setVisible(false)
        -- print("setchongsheng===")
        self:chongshengSortData()
        self:setOneShowItem()

    elseif self.selectpage == "huahun" then

        if self.rootItems.secretBtn then
            self.rootItems.secretBtn:setVisible(true)
        end

        --self.rootItems.showItemsNode:setPosition(ccp(540.0,960.0))
        self.rootItems.showItemsNode:setVisible(true)
        -- print("sethuahun===")


        UIRequest({type = 3704})


        -- self:huahunSortData()
        -- self:setShowItems()

    elseif self.selectpage == "fenjie" then 

        if self.rootItems.jinghuaBtn then
            self.rootItems.jinghuaBtn:setVisible(true)
        end   

        self.rootItems.showItemsNode:setVisible(true)          
        --
        self:fenjieSortData()
        self:setShowItems()
    end
end

function Layer_qiankunlu.setHint( self )
    local lianhuahint = GameScene.hintdata["161"] or 0

    ui.sethint(self.rootItems.hint_general,lianhuahint==1 or lianhuahint==3)
    ui.sethint(self.rootItems.hint_equip,lianhuahint==2 or lianhuahint==3)
end


function Layer_qiankunlu.fenjieSortData(self)
    if self.redFragmentData and next(self.redFragmentData)then
        self.showredFragmentData = self:fenjieRedFragmentSortfun(self.redFragmentData)
    else
        self.showredFragmentData = nil
    end

end

function Layer_qiankunlu.lianhuaSortData(self)
    if (self.generalFragmentData and next(self.generalFragmentData)) or (self.showgeneralData and next(self.showgeneralData))  then
        self.showgeneralFragmentData = self:lianhuaGeneralFragmentSortfun(self.generalFragmentData)
    else
        self.showgeneralFragmentData = nil
    end

    if self.equipsData and next(self.equipsData) then
        self.showequipsData = self:sortfun(self.equipsData)
    end
    
    if (self.equipsFragmentData and next(self.equipsFragmentData)) or (self.showequipsData and next(self.showequipsData)) then
        self.showequipsFragmentData = self:lianhuaEquipsFragmentSortfun(self.equipsFragmentData)
    else
        self.showequipsFragmentData = nil
    end

    if self.treasuresData and next(self.treasuresData) then
        self.showtreasuresData = self:sortfunTreasure(self.treasuresData)
    end
    
    if (self.treasuresFragmentData and next(self.treasuresFragmentData)) or (self.showtreasuresData and next(self.showtreasuresData)) then
        self.showtreasuresFragmentData = self:lianhuaTreasuresFragmentSortfun(self.treasuresFragmentData)
    else
        self.showtreasuresFragmentData = nil
    end
end

function Layer_qiankunlu.chongshengSortData(self)
    if self.generalData and next(self.generalData) then
        self.showgeneralData = self:chongshengSortfun(self.generalData)
    else
        self.showgeneralData = nil
    end

    if self.equipsData and next(self.equipsData) then
        self.showequipsData = self:chongshengSortfun(self.equipsData)
    else
        self.showequipsData = nil
    end
    self.showequipsFragmentData = self.showequipsData

    if self.treasuresData and next(self.treasuresData) then
        self.showtreasuresData = self:chongshengSortfun(self.treasuresData)
    else
        self.showtreasuresData = nil
    end
    self.showtreasuresFragmentData = self.showtreasuresData

    if self.fashionData and next(self.fashionData) then
        self.showfashionData = self:chongshengFashionSortfun(self.fashionData)
    else
        self.showfashionData = nil
    end

    if self.petData and next(self.petData) then
        self.showpetData = self:chongshengPetSortfun(self.petData)
    else
        self.showpetData = nil
    end


    if self.artifactData and next(self.artifactData) then
        self.showartifactData = self:chongshengartifactSortfun(self.artifactData)
    else
        self.showartifactData = nil
        UIRequest({type = 10032})
    end

    self.showExclusiveArtifactData = self:chongshengExclusiveArtifactSortfun()


    -- self.showgeneralData = self:chongshengSortfun(self.generalData)
    -- self.showequipsData = self:chongshengSortfun(self.equipsData)
    -- self.showtreasuresData = self:chongshengSortfun(self.treasuresData)
end

function Layer_qiankunlu.huahunSortData(self,exceptdata)
    self.exceptdata = exceptdata
    if self.generalData and next(self.generalData) then
        self.showgeneralData = self:huahunSortfun(self.generalData,exceptdata)
    else
        self.showgeneralData = nil
    end

    self:lianhuaSortData()
    self:setShowItems()
    -- self.showgeneralData = self:huahunSortfun(self.generalData)
end

function Layer_qiankunlu.reloadResolveQuality( self )
    self:resetquicknode("close")
    self:lianhuaSortData()
    self:setShowItems()
end

function Layer_qiankunlu.huahunSortfun(self,data,exceptdata)
    -- print("sortfun000====")
    -- printT(exceptdata)

    local arrdata = {}
    for k,v in pairs(data) do
        
        -- if v.level1 == 1 and exceptdata[tostring(v.iid)]==nil then
            -- print("quality==",v.quality)
            -- print("interquality===")
            table.insert(arrdata,v)
        -- end
    end

    -- print("sortfun====")
    -- printT(arrdata)

    local sortfun = function( a,b )
        if exceptdata[tostring(a.iid)] and not exceptdata[tostring(b.iid)] then
            print("returnfalse")
            return false
        elseif exceptdata[tostring(b.iid)] and not exceptdata[tostring(a.iid)] then
            print("returntrue")
            return true
        else
            if (a.level1 > 1) and not (b.level1 > 1) then
                return false
            elseif (b.level1 > 1) and not (a.level1 > 1) then
                return true
            else
                return  a.quality < b.quality
            end    
        end
    end
    table.sort(arrdata, sortfun)
    -- printT(arrdata,"arrdata===")
    return arrdata
end

function Layer_qiankunlu.chongshengSortfun(self,data)
    local arrdata = {}

    for k,v in pairs(data) do
        -- print("staffType===",ui.IDconfig(v.cid)["staffType"])
        -- printT(v,"chongshengSortfun")
        if ui.IDconfig(v.cid)["staffType"] and ui.IDconfig(v.cid)["staffType"] == "equip" and ui.IDconfig(v.cid).quality and ui.IDconfig(v.cid).quality >= 6 and ui.IDconfig(v.cid).relative and ui.IDconfig(v.cid).relative > 0 then
            table.insert(arrdata,v)
        elseif v.level1 > 1 or (v.xcount and v.xcount > 0) or (v.level2 and v.level2 > 0) or (v.level3 and v.level3 > 0) or (v.level4 and v.level4 > 0) or (v.level8 and v.level8 > 0) then
            -- print("quality==",v.quality)
            -- print("interquality===")
            table.insert(arrdata,v)
        end
    end

    -- print("sortfun====")
    -- printT(arrdata)

    local sortfun = function( a,b )
        return a.quality < b.quality
    end
    table.sort(arrdata, sortfun)

    return arrdata
end


function Layer_qiankunlu.chongshengFashionSortfun(self,data)
    local arrdata = {}

    for k,v in pairs(data.fashions) do
        -- print("staffType===",ui.IDconfig(v.cid)["staffType"])
        -- printT(v,"chongshengSortfun")
        if v.level > 1 then
            -- print("quality==",v.quality)
            -- print("interquality===")
            table.insert(arrdata,v)
        end
    end

    print("sortfun====")
    -- printT(arrdata)

    local sortfun = function( a,b )
        return a.id < b.id
    end
    table.sort(arrdata, sortfun)

    return arrdata
end

function Layer_qiankunlu.lianhuaGeneralFragmentSortfun(self,data)
    local arrdata = {}
    for k,v in pairs(data) do
        local config = ui.IDconfig(v.cid)
        if (not config.whether_refining) or (config.whether_refining and config.whether_refining == 1) then
            if v.quality ~= 1 then
                table.insert(arrdata,v)
            end
        end
    end

    -- print("sortfun====")
    -- printT(arrdata)

    local sortfun = function( a,b )
        return a.quality < b.quality
    end
    table.sort(arrdata, sortfun)

    if self.showgeneralData and next(self.showgeneralData)then
        for k,v in pairs(self.showgeneralData) do
            table.insert(arrdata,v)
        end
    end

    printT(self.showgeneralData,"self.showgeneralData   ----     ")

    printT(arrdata,"arrdata   ----     ")

    return arrdata
end

function Layer_qiankunlu.lianhuaEquipsFragmentSortfun(self,data)
    local arrdata = {}
    for k,v in pairs(data) do
        local config = ui.IDconfig(v.cid)
        if (not config.whether_refining) or (config.whether_refining and config.whether_refining == 1) then
            if v.quality ~= 1 then
                table.insert(arrdata,v)
            end
        end
    end
    -- print("sortfun====")
    -- printT(arrdata)

    local sortfun = function( a,b )
        return a.quality < b.quality
    end
    table.sort(arrdata, sortfun)

    if self.showequipsData and next(self.showequipsData)then
        for k,v in pairs(self.showequipsData) do
            table.insert(arrdata,v)
        end
    end

    printT(self.showequipsData,"self.showequipsData   ----     ")

    printT(arrdata,"arrdata   ----     ")

    return arrdata
end

function Layer_qiankunlu.lianhuaTreasuresFragmentSortfun(self,data)
    local arrdata = {}
    for k,v in pairs(data) do
        local config = ui.IDconfig(v.cid)
        if (not config.whether_refining) or (config.whether_refining and config.whether_refining == 1) then
            if v.quality ~= 1 then
                table.insert(arrdata,v)
            end
        end
    end

    local sortfun = function( a,b )
        return a.quality < b.quality
    end
    table.sort(arrdata, sortfun)

    if self.showtreasuresData and next(self.showtreasuresData)then
        for k,v in pairs(self.showtreasuresData) do
            table.insert(arrdata,v)
        end
    end

    printT(self.showtreasuresData,"self.showtreasuresData   ----     ")

    printT(arrdata,"arrdata   ----     ")

    return arrdata
end


function Layer_qiankunlu.chongshengPetSortfun(self,data)
    local arrdata = {}

    for k,v in pairs(data) do
        if self.petiid and (self.petiid == v.iid) then

        elseif (v.level > 0) or (v.collectlevel > 1) then   
            table.insert(arrdata,v)
        end
    end

    local sortfun = function( a,b )
        return a.cid < b.cid
    end
    table.sort(arrdata, sortfun)

    return arrdata
end

function Layer_qiankunlu.chongshengartifactSortfun(self,data)

    local sortFunc = function (a,b)
        return a.score < b.score
    end


    local arrdata = {}

    for k,v in pairs(data) do

        local condition = false
        if v.isChecked > 0 and v.isLockState == 0 and ((not v.sid) or (v.sid <= 0)) then

            --强化过
            if v.level1 > 0 then
                condition = true
            end

            --开孔数量>1
            local kaikongNum = 0
            for i=1,4 do
                if v["jewel"..i] == 0 then
                    kaikongNum = kaikongNum + 1
                end
            end
            if kaikongNum > 1 then
                condition = true
            end
            
            -- --有宝石
            -- for i=1,4 do
            --     if v["jewel"..i] > 0 then
            --         condition = true
            --         break
            --     end
            -- end
        end

        if condition then
            table.insert(arrdata,v)
        end
    end
    table.sort(arrdata, sortFunc)

    return arrdata
end


--专属神器可重生
function Layer_qiankunlu.chongshengExclusiveArtifactSortfun(self)
    local exclusiveArtifactDatas = {}
    for k,v in pairs(GameScene.layers["slotsInfo"].module.exclusiveArtifactData) do
        local general = GameScene.layers["slotsInfo"].module:getGeneralIson(v.generalIid)
        if v.level > 0 and (not general) then
            table.insert(exclusiveArtifactDatas,v)
        end
    end
    printT(exclusiveArtifactDatas,"chongshengExclusiveArtifactSortfun")
    return exclusiveArtifactDatas
end

function Layer_qiankunlu.sortfun(self,data)
    local arrdata = {}
    for k,v in pairs(data) do
        -- print("quality==",v.quality)
        -- print("interquality===")
        local config = ui.IDconfig(v.cid)
        if (not config.whether_refining) or (config.whether_refining and config.whether_refining == 1) then
            if v.level2 == 0 and v.level3 == 0 and v.level4 == 0 then
                table.insert(arrdata,v)
            end
        end
    end


    local sortfun = function( a,b )
        return a.quality < b.quality
    end
    table.sort(arrdata, sortfun)

    return arrdata
end

function Layer_qiankunlu.sortfunTreasure(self,data)
    local arrdata = {}
    for k,v in pairs(data) do
        local config = ui.IDconfig(v.cid)
        if (not config.whether_refining) or (config.whether_refining and config.whether_refining == 1) then
            if v.level1 == 1 and v.level2 == 0 and v.level3 == 0 and v.level4 == 0 then
                table.insert(arrdata,v)
            end
        end
        
    end

    local sortfun = function( a,b )
        return a.quality < b.quality
    end
    table.sort(arrdata, sortfun)

    return arrdata
end

function Layer_qiankunlu.fenjieRedFragmentSortfun(self,data)

    local arrdata = {}
    for k,v in pairs(data) do
        if v.num and v.num > 0 then
            v.decompose = gamedata.config.redl_awake_item[tostring(v.cid)].decompose or 0
            v.priority = gamedata.config.redl_awake_item[tostring(v.cid)].priority or 0
            table.insert(arrdata,v)
        end
    end

    local sortfun = function( a,b )
        if a.decompose == b.decompose then    
            return a.priority < b.priority
        else
            return a.decompose > b.decompose
        end    
    end
    table.sort(arrdata, sortfun)

    return arrdata
end


function Layer_qiankunlu.setHuahunData(self)
    self.allspendcoin = 0
    ui.setLabelString(self.rootItems.huahunSpendText,nil,14)
    if self.chooseData and next(self.chooseData) then
        for i,v in ipairs(self.chooseData) do

            self.allspendcoin = self.allspendcoin + gamedata.config.global_kv[v["quality"].."_soul_cost"].value

            -- if v["quality"] == 3 then
            --     self.allspendcoin = self.allspendcoin + gamedata.config.global_kv["3_soul_cost"].value
            -- elseif v["quality"] == 4 then
            --     self.allspendcoin = self.allspendcoin + gamedata.config.global_kv["4_soul_cost"].value
            -- elseif v["quality"] == 5 then
            --     self.allspendcoin = self.allspendcoin + gamedata.config.global_kv["5_soul_cost"].value
            -- end
        end
        if GameScene.roleinfo.coin >= self.allspendcoin then
            ui.setLabelString(self.rootItems.huahunSpend_Label,self.allspendcoin,14)
        else
            ui.setLabelString(self.rootItems.huahunSpend_Label,self.allspendcoin,24)
        end
        
    else
        ui.setLabelString(self.rootItems.huahunSpend_Label,0,14)
    end
end

-- 展示炼化后可获得的物品
function Layer_qiankunlu.showgetSomething(self)
    -- print("showgetSomething==")
    -- printT(self.chooseData)
    if self.selectpage == "fenjie" then
        self.selectItems.showgetNode:setVisible(false)
        local f_getnum1,f_getnum2 = 0,0
        for k,v in pairs(self.chooseData or {}) do
            if gamedata.config.redl_awake_item[tostring(v.cid)] and gamedata.config.redl_awake_item[tostring(v.cid)].decompose_prop then
                local decomposeprop = ui.getIDandNUMs(gamedata.config.redl_awake_item[tostring(v.cid)].decompose_prop)
                for kk,vv in pairs(decomposeprop) do
                    if vv.cid == 20790 then
                        f_getnum1 = f_getnum1+vv.num*v.num
                    elseif vv.cid == 20778 then
                        f_getnum2 = f_getnum2+vv.num*v.num
                    end    
                end    
            end
        end    
        ui.setLabelString(self.rootItems.f_getnum1,f_getnum1,23)
        ui.setLabelString(self.rootItems.f_getnum2,f_getnum2,23)
    elseif self.selectpage == "huahun" or self.chooseData == nil  or  not next(self.chooseData) then
        self.selectItems.showgetNode:setVisible(false)
    else
        self.selectItems.showgetNode:setVisible(true)
        for i=1,5 do
            self.selectItems["getnode"..i]:setVisible(false)
        end

        ui.setLabelString(self.selectItems.showgetText,nil,14)

        if self.rootItems.showgetMore then
            self.rootItems.showgetMore:setVisible(false)
            ui.setLabelString(self.selectItems.showgetMore,nil,14)
        end

        local temconfig = {}
        if self.chooseData[1]["cid"] then
            temconfig = ui.IDconfig(self.chooseData[1]["cid"])
        else
            temconfig = ui.IDconfig(self.chooseData[1]["id"])
        end

        if (self.chooseData[1].type and (self.chooseData[1].type == "horse" or self.chooseData[1].type == "treasure")) or (temconfig.staffType == "treasure_fragment") then
            
            local coinNum = 0
            local coinCid = 1000
            local stoneNum = 0
            local stoneCid = 0
            local showgetdata = {}

            for i,v in ipairs(self.chooseData) do

                local config = ui.IDconfig(v.cid)
                local num = 1
                if config.staffType == "treasure_fragment" then
                    num = v.num or 1
                end

                -- 装备分解获取物品
                if config["sellprice"] then
                    local sellcoinnum =  config["sellprice"]*num
                    coinNum = coinNum + (sellcoinnum or 0)
                end
                
                local destroyData =  ui.getIDandNUMs(config["resolve"])
                for k,v in pairs(destroyData) do
                    if v.cid == 1000 then
                        coinNum = coinNum + (v.num or 0)*num
                    else
                        stoneCid = v.cid
                        stoneNum = stoneNum + (v.num or 0)*num
                    end
                end

                -- 强化后分解获取金币
                -- local equipstrengthenNum = equipstrengthen[tostring(v.level1)][("Trafficking"..v.quality)]
                -- coinNum = coinNum + (equipstrengthenNum or 0)

                -- stoneCid = 20222
                stoneNum = stoneNum + (v.xcount or 0)

                --
                if self.rootItems.showgetMore then
                    if config.lianhua and config.lianhua == 1 then
                        self.rootItems.showgetMore:setVisible(true)
                    end
                end
            end
            if coinNum ~= 0 then
                table.insert(showgetdata,{cid=coinCid,num=coinNum})
            end
            if stoneNum ~= 0 then
                table.insert(showgetdata,{cid=stoneCid,num=stoneNum})
            end
            print("showgetdata==equips")
            for i,v in ipairs(showgetdata) do
                self.selectItems["getnode"..i]:setVisible(true)
                local idconfig = ui.IDconfig(v.cid)
                setSpriteFrameByName(self.selectItems["geticon"..i], idconfig.icon or "alpha")
                self.selectItems["geticon"..i]:setScale(0.5)
                ui.setLabelString(self.selectItems["getLabel"..i],("x"..((v.num>=100000) and (math.floor(v.num/10000).."万") or v.num)),3)
            end    

        elseif (self.chooseData[1].type and (self.chooseData[1].type == "head" or self.chooseData[1].type == "weapon" or self.chooseData[1].type == "accessory" or self.chooseData[1].type == "armor" or self.chooseData[1].type == "shoe" or self.chooseData[1].type == "accessories")) or temconfig.staffType == "equip_fragment" then

            local coinNum = 0
            local coinCid = 1000
            local stoneNum = 0
            local stoneCid = 20222
            local showgetdata = {}

            for i,v in ipairs(self.chooseData) do

                local config = ui.IDconfig(v.cid)
                local num = 1
                if config.staffType == "equip_fragment" then
                    num = v.num or 1
                end

                -- 装备分解获取物品
                if config["sellprice"] then
                    local sellcoinnum =  config["sellprice"]*num
                    coinNum = coinNum + (sellcoinnum or 0)
                end

                local destroyData =  ui.getIDandNUMs(config["resolve"])
                for k,v in pairs(destroyData) do
                    if v.cid == 1000 then
                        coinNum = coinNum + (v.num or 0)*num
                    else
                        stoneCid = v.cid
                        stoneNum = stoneNum + (v.num or 0)*num
                    end
                end

                if config.staffType ~= "equip_fragment" and v.level1 and gamedata.config.equip_strengthen[tostring(v.level1)] then
                    -- 强化后分解获取金币
                    local equipstrengthenNum = gamedata.config.equip_strengthen[tostring(v.level1)][("Trafficking"..v.quality)]
                    coinNum = coinNum + (equipstrengthenNum or 0)
                end
               

                -- stoneCid = 20222
                stoneNum = stoneNum + (v.xcount or 0)

                --
                if self.rootItems.showgetMore then
                    if config.lianhua and config.lianhua == 1 then
                        self.rootItems.showgetMore:setVisible(true)
                    end
                end
            end
            if coinNum ~= 0 then
                table.insert(showgetdata,{cid=coinCid,num=coinNum})
            end
            if stoneNum ~= 0 then
                table.insert(showgetdata,{cid=stoneCid,num=stoneNum})
            end
            print("showgetdata==equips")
            -- printT(showgetdata)
            for i,v in ipairs(showgetdata) do
                self.selectItems["getnode"..i]:setVisible(true)
                local idconfig = ui.IDconfig(v.cid)
                setSpriteFrameByName(self.selectItems["geticon"..i], idconfig.icon or "alpha")
                self.selectItems["geticon"..i]:setScale(0.5)
                ui.setLabelString(self.selectItems["getLabel"..i],("x"..((v.num>=100000) and (math.floor(v.num/10000).."万") or v.num)),3)
            end
        elseif (self.chooseData[1].fragmentCid and self.chooseData[1].fragmentCid > 0) or (self.chooseData[1].cid>= 10101 and self.chooseData[1].cid <= 11000) or (self.chooseData[1].cid >= 160001 and self.chooseData[1].cid <= 161000) or (self.chooseData[1].cid >= 170001 and self.chooseData[1].cid <= 171000) or (self.chooseData[1].cid >= 162001 and self.chooseData[1].cid <= 163000) or (self.chooseData[1].cid >= 164001 and self.chooseData[1].cid <= 165000) or (self.chooseData[1].cid >= 174001 and self.chooseData[1].cid <= 175000) then
            local showgetdata = {}
            local hundannum = 0
            local hundancid = 20200
            local generalfargment = gamedata.config.general_fragment
            for i,v in ipairs(self.chooseData) do
                print(i,v)
                if v.fragmentCid then 
                    hundannum = hundannum + (generalfargment[tostring(v.fragmentCid)] and generalfargment[tostring(v.fragmentCid)]["stovestone"]*(v.num or 1))
                elseif (v.cid>= 10101 and v.cid <= 11000) or (v.cid >= 160001 and v.cid <= 161000) or (v.cid >= 170001 and v.cid <= 171000) or (v.cid >= 162001 and v.cid <= 163000) or (v.cid >= 164001 and v.cid <= 165000) or (v.cid >= 174001 and v.cid <= 175000) then
                    hundannum = hundannum + (generalfargment[tostring(v.cid+1000)] and generalfargment[tostring(v.cid+1000)]["stovestone"]*generalfargment[tostring(v.cid+1000)]["num"]*(v.num or 1))
                end
            end
            table.insert(showgetdata,{cid = hundancid,num = hundannum})

            print("showgetdata==fragments")
            -- printT(showgetdata)

            for i,v in ipairs(showgetdata) do
                self.selectItems["getnode"..i]:setVisible(true)
                local idconfig = ui.IDconfig(v.cid)
                setSpriteFrameByName(self.selectItems["geticon"..i], idconfig.icon or "alpha")
                self.selectItems["geticon"..i]:setScale(0.5)
                ui.setLabelString(self.selectItems["getLabel"..i],("x"..((v.num>=100000) and (math.floor(v.num/10000).."万") or v.num)),3)
            end
        end
    end
end


-- 设置展示物品
function Layer_qiankunlu.setShowItems(self)
    -- self.chooseData
    -- print("setShowItems===")
    -- printT(self.chooseData)
    if self.selectpage == "huahun" then
        self:setHuahunData()
    end
    for i=1,self.maxnum_select do
        if self.chooseData and next(self.chooseData) and i <= #self.chooseData then
            -- print("setHasItems",i)
            self:setHasItems(self.chooseData[tonumber(i)],i,self.selectItems)
        else
            -- print("setNothingItems",i)
            self:setNothingItems(i,self.selectItems)
        end
    end

    self:showgetSomething()
end

function Layer_qiankunlu.setHasItems(self,data,num,Items)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end

    if self.selectpage == "lianhua" or self.selectpage == "fenjie" then
        ui.removeGray("CCSprite",Items["i_icon"..key_Ex])
        Items["i_icon"..key_Ex]:stopAllActions()
        local back = CCFadeTo:create(0,255)
        Items["i_icon"..key_Ex]:runAction(back)
    end

    Items["i_soulsprite"..key_Ex]:setVisible(true)
    if data.fragmentCid and data.fragmentCid > 0 then
        data.staffType = "general_fragment"
    end
    
    if tonumber(num) == 6 then
        -- printT(data,"fashiondata===")
        if data.cid then
            ui.setNewIcon(Items,data,num-1,data)
        else
            ui.setNewIcon(Items,{cid=data.id},num-1)
        end
        
    else
        ui.setNewIcon(Items,data,num-1)
    end

    --
    if ui.IDconfig(data.cid).staffType and ui.IDconfig(data.cid).staffType == "pet" then
        local configdata = gamedata.config.pet3_attr[tostring(data.cid)][tostring(data.level)]
        setSpriteFrameByName(Items["i_icon"..key_Ex], configdata.icon and configdata.icon or "alpha")
        ui.setSpriteTextureRect(Items["i_icon"..key_Ex],0,0,150,150)
        setSpriteFrameByName(Items["i_k_quality"..key_Ex], "b_iconk"..(configdata.quality and configdata.quality>1 and configdata.quality or 1))
        setSpriteFrameByName(Items["i_quality"..key_Ex], "b_iconbg"..(configdata.quality and configdata.quality>1 and configdata.quality or 1))
    end    
    --

    Items["i_button"..key_Ex]:addHandleOfControlEvent(function()
        -- ui.setPopwindowByCid(data.cid)
        local cb = function( temdata )
            -- print("callback==")
            -- printT(temdata)
            self.chooseData = temdata
            -- self:setShowItems()
            if self.selectpage == "lianhua" or self.selectpage == "fenjie" then 
                -- print("setlianhua===")
                self:setShowItems()
            elseif self.selectpage == "chongsheng" then
                -- print("setchongsheng===")
                self:setOneShowItem()
            elseif self.selectpage == "huahun" then
                -- print("sethuahun===")
                self:setShowItems()
            end
        end

        gameWindows:openWindow("qiankunluselect",{  general = self.showgeneralData, 
                                                    equip = self.showequipsFragmentData, 
                                                    treasure = self.showtreasuresFragmentData, 
                                                    generalfragment = self.showgeneralFragmentData,
                                                    redfragment = self.showredFragmentData,
                                                    choose = self.chooseData,
                                                    page = self.selectpage,
                                                    exceptdata = self.exceptdata,
                                                    fashion = self.showfashionData,
                                                    pet = self.showpetData,
                                                    artifact = self.showartifactData,
                                                    exclusiveArtifact = self.showExclusiveArtifactData,
                                                    maxNum = self.maxnum_select,
                                                    },cb)
        -- print("i..am..1",num)
    end, CCControlEventTouchUpInside)
    Items["i_button"..key_Ex]:setTouchPriority(-101)
end

function Layer_qiankunlu.setNothingItems(self,num,Items)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end
    Items["i_button"..key_Ex]:addHandleOfControlEvent(function()
        local cb = function( temdata )
            -- print("callback2==")
            -- printT(temdata)
            self.chooseData = temdata
            -- self:setShowItems()
            if self.selectpage == "lianhua" or self.selectpage == "fenjie" then 
                -- print("setlianhua===")
                self:setShowItems()
            elseif self.selectpage == "chongsheng" then
                -- print("setchongsheng===")
                self:setOneShowItem()
            elseif self.selectpage == "huahun" then
                -- print("sethuahun===")
                self:setShowItems()
            end
        end

        gameWindows:openWindow("qiankunluselect",{  general = self.showgeneralData, 
                                                    equip = self.showequipsFragmentData, 
                                                    treasure = self.showtreasuresFragmentData, 
                                                    generalfragment = self.showgeneralFragmentData,
                                                    redfragment = self.showredFragmentData,
                                                    choose = self.chooseData,
                                                    page = self.selectpage,
                                                    exceptdata = self.exceptdata,
                                                    fashion = self.showfashionData,
                                                    pet = self.showpetData,
                                                    artifact = self.showartifactData,
                                                    exclusiveArtifact = self.showExclusiveArtifactData,
                                                    maxNum = self.maxnum_select,
                                                    },cb)
        -- print("i..am..2",num)
    end, CCControlEventTouchUpInside)

    setSpriteFrameByName(Items["i_icon"..key_Ex], "obj_add2")

    setSpriteFrameByName(Items["i_k_quality"..key_Ex], "b_iconk1")
    setSpriteFrameByName(Items["i_quality"..key_Ex], "b_iconbg1")
    Items["i_soulsprite"..key_Ex]:setVisible(false)
    Items["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
    Items["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    ui.setLabelString(Items["i_num"..key_Ex],"",13)
    if Items["star_starnode"..key_Ex] then
        Items["star_starnode"..key_Ex]:setVisible(false)
    end


    if self.selectpage == "chongsheng" then

    elseif self.selectpage == "lianhua" then
        if (self.showgeneralFragmentData and next(self.showgeneralFragmentData) ) or (self.showequipsData and next(self.showequipsData)) then
            if table.getTableLength(self.showgeneralFragmentData) >= self.maxnum_select or table.getTableLength(self.showequipsData) >= self.maxnum_select then
                ui.removeGray("CCSprite",Items["i_icon"..key_Ex])
                ui.blink(Items["i_icon"..key_Ex],1)
            else
                if table.getTableLength(self.showgeneralFragmentData) >= num then
                    ui.removeGray("CCSprite",Items["i_icon"..key_Ex])
                    ui.blink(Items["i_icon"..key_Ex],1)
                else
                    ui.addGray("CCSprite",Items["i_icon"..key_Ex])
                end
            end
        else
            ui.addGray("CCSprite",Items["i_icon"..key_Ex])
        end
    elseif self.selectpage == "fenjie" then
        if self.showredFragmentData and next(self.showredFragmentData) then
            if table.getTableLength(self.showredFragmentData) >= self.maxnum_select then
                ui.removeGray("CCSprite",Items["i_icon"..key_Ex])
                ui.blink(Items["i_icon"..key_Ex],1)
            else
                if table.getTableLength(self.showredFragmentData) >= num then
                    ui.removeGray("CCSprite",Items["i_icon"..key_Ex])
                    ui.blink(Items["i_icon"..key_Ex],1)
                else
                    ui.addGray("CCSprite",Items["i_icon"..key_Ex])
                end
            end
        else
            ui.addGray("CCSprite",Items["i_icon"..key_Ex])
        end
    end
    
end

function Layer_qiankunlu.setChongshengSpendLabel(self)
    if self.chooseData and next(self.chooseData) then
        local tempdata = self.chooseData[tonumber(1)]
        -- printT(tempdata,"tempdata===")
        local temconfig = {}
        if tempdata.cid then
            temconfig = ui.IDconfig(tempdata.cid)
        else
            temconfig = ui.IDconfig(tempdata.id)
        end

        self.allspendgold = 0
        if tempdata.type and (tempdata.type == "horse" or tempdata.type == "treasure") then
            -- "treasure"
            -- print("treasure")
            local renascenceconfig = gamedata.config.renascence
            local levelspend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level1)]["treasurerecost"]
            local jinglianspend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level2)]["treasurerefinecost"]
            local treasurestarcost = renascenceconfig[tostring(self.chooseData[tonumber(1)].level3)]["treasurestarcost"]
            self.allspendgold = levelspend + jinglianspend + treasurestarcost
            print("chongsheng,treasure==",levelspend,jinglianspend)

            -- print("levelspend1111===",levelspend)
        elseif tempdata.type and (tempdata.type == "head" or tempdata.type == "weapon" or tempdata.type == "accessory" or tempdata.type == "armor" or tempdata.type == "shoe" or tempdata.type == "accessories") then
            -- print("equip")
            -- "equip"
            local renascenceconfig = gamedata.config.renascence
            local levelspend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level1)]["strengthencost"]
            local xilianspend = 0
            if self.chooseData[tonumber(1)].xcount > 0 then
                xilianspend = gamedata.config.global_kv["equip_baptize_cost"]["value"]
            end

            print("chooseData = ", self.chooseData[tonumber(1)].level2)
            local jinjiespend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level2)]["equipevolvecost"] or 0
            if temconfig.quality == 6 and temconfig.relative and temconfig.relative > 0 then
                jinjiespend = jinjiespend + renascenceconfig["30"]["equipevolvecost"]
            elseif temconfig.quality == 7 and temconfig.relative and temconfig.relative > 0 then
                if temconfig.init_eid and temconfig.init_eid == 1 then --初始红装
                    jinjiespend = jinjiespend + renascenceconfig["50"]["equipevolvecost"]
                else
                    jinjiespend = jinjiespend + renascenceconfig["30"]["equipevolvecost"] + renascenceconfig["50"]["equipevolvecost"]
                end
            end

            local starspend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level3)]["star_cost"] or 0

            local castspend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level4)]["injection"] or 0
            self.allspendgold = levelspend + xilianspend + jinjiespend + starspend + castspend
            print("chongsheng,equip==",levelspend,xilianspend,jinjiespend,castspend)
            -- print("levelspend2222===",levelspend)
            -- print("jinglianspend2222===",jinglianspend)

        elseif temconfig.staffType == "general" then
            print("general==")
            -- printT(self.chooseData[tonumber(1)])
            local generalconfig = gamedata.config.general[tostring(self.chooseData[tonumber(1)].cid)]
            local maxqianlinum = generalconfig["potential"] + (tonumber(self.chooseData[tonumber(1)].level1) - 1)*generalconfig["potential-grow"]
            local useqianlinum = maxqianlinum - (tonumber(self.chooseData[tonumber(1)].potential))
            -- print("maxqianlinum===",maxqianlinum)
            -- printT(self.chooseData[tonumber(1)])
            -- print("useqianlinum===",useqianlinum)
            local globalconfig = gamedata.config.global_kv
            local spendglodnum = (useqianlinum/tonumber(globalconfig.general_rebirth_potential.value))*tonumber(globalconfig.general_rebirth_potentialcost.value)
            -- print("spendglodnum===1111",spendglodnum)
            local d_value = spendglodnum - math.floor(spendglodnum)
            if  d_value * 10 >= 5 then
                -- print("test0000=",spendglodnum)
                spendglodnum = math.ceil(spendglodnum)
            else
                -- print("test1111=",spendglodnum)
                spendglodnum = math.floor(spendglodnum)
            end
            -- print("spendglodnum===2222",spendglodnum)
            if spendglodnum < 0 then
                spendglodnum = 0
            end

            local renascenceconfig = gamedata.config.renascence
            -- print("renascenceconfig")
            -- printT(renascenceconfig)
            local levelspend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level1)]["generallvcost"]
            local tupospend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level2)]["breakcost"]

            -- 觉醒花费
            local juexingnum = renascenceconfig[tostring(self.chooseData[tonumber(1)].skilllevel)]["return"]
            -- print("levelspend===",levelspend)
            -- print("tupospend===",tupospend)
            local feishengnum = renascenceconfig[tostring(self.chooseData[tonumber(1)].level8)]["feishengchongshengxiaohao"] or 0

            --武将升星
            local shengxingnum = renascenceconfig[tostring(self.chooseData[tonumber(1)].level5)]["goldgeneralstar"] or 0

            self.allspendgold = levelspend + tupospend + spendglodnum + juexingnum + feishengnum + shengxingnum
            print("chongsheng,general==",levelspend,tupospend,spendglodnum)
        elseif temconfig.staffType == "fashion" then
            local renascenceconfig = gamedata.config.renascence
            -- print("renascenceconfig")
            -- printT(renascenceconfig)
            local levelspend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level)]["fashion_reborn"]
            self.allspendgold = levelspend 
        elseif temconfig.staffType == "pet" then
            local renascenceconfig = gamedata.config.renascence
            local levelspend = renascenceconfig[tostring(self.chooseData[tonumber(1)].level)]["pet_reborn"]
            self.allspendgold = levelspend 
        elseif temconfig.staffType == "artifact" then
            local renascenceconfig = gamedata.config.trump_rebirth

            self.allspendgold = 0
            local artifactData = self.chooseData[tonumber(1)]
            if artifactData.level1 > 0 then
                self.allspendgold = self.allspendgold + renascenceconfig[tostring(artifactData.level1)].strengthen
            end

            local kongNum = 0
            for i=1,4 do
                if artifactData["jewel"..i] >= 0 then
                    kongNum = kongNum + 1
                end
            end
            if kongNum > 0 then
                self.allspendgold = self.allspendgold + renascenceconfig[tostring(kongNum)].gem
            end
        elseif temconfig.staffType == "exclusive" then
            local renascenceconfig = gamedata.config.renascence

            self.allspendgold = 0
            local exclusiveArtifactData = self.chooseData[tonumber(1)]
            if renascenceconfig[tostring(exclusiveArtifactData.intensify_level)] then
                self.allspendgold = self.allspendgold + renascenceconfig[tostring(exclusiveArtifactData.intensify_level)].exclusive_intensify
            end
            
            if renascenceconfig[tostring(exclusiveArtifactData.baptism_level)] then
                self.allspendgold = self.allspendgold + renascenceconfig[tostring(exclusiveArtifactData.baptism_level)].exclusive_baptism
            end

        end

        if temconfig.staffType == "exclusive" then
            if GameScene.roleinfo.g_gold >= self.allspendgold then
                ui.setLabelString(self.rootItems.chongshengSpend_Label,self.allspendgold,14)
            else
                ui.setLabelString(self.rootItems.chongshengSpend_Label,self.allspendgold,24)
            end

            ui.setLabelString(self.rootItems.chongshengSpendText,"消耗仙元",14)
            setSpriteFrameByName(self.rootItems.chongshengSpendIcon, "0yuan")
            self.rootItems.chongshengSpendIcon:setScale(0.5)
        else
            if GameScene.roleinfo.gold >= self.allspendgold then
                ui.setLabelString(self.rootItems.chongshengSpend_Label,self.allspendgold,14)
            else
                ui.setLabelString(self.rootItems.chongshengSpend_Label,self.allspendgold,24)
            end

            ui.setLabelString(self.rootItems.chongshengSpendText,"消耗元宝",14)
            setSpriteFrameByName(self.rootItems.chongshengSpendIcon, "obj_s_gold")
            self.rootItems.chongshengSpendIcon:setScale(1)
        end
        
    else
        ui.setLabelString(self.rootItems.chongshengSpend_Label,"0",14)
    end
end

function Layer_qiankunlu.setOneShowItem(self)
    
    self:setChongshengSpendLabel()
    -- printT(self.chooseData,"setOneShowItem===")

    if self.chooseData and next(self.chooseData) then
        -- print("setHasItems",i)
        local temconfig = {}
        if self.chooseData[1]["cid"] then
            temconfig = ui.IDconfig(self.chooseData[1]["cid"])
        else
            temconfig = ui.IDconfig(self.chooseData[1]["id"])
        end
        -- printT(temconfig,"temconfig===")
        self:setHasItems(self.chooseData[tonumber(1)],1,self.rootItems)
        self.rootItems.chongshengSpendDesc_Label:setVisible(true)
        local descString = ""
        if self.chooseData[tonumber(1)].type and (self.chooseData[tonumber(1)].type == "horse" or self.chooseData[tonumber(1)].type == "treasure") then
            descString = "重生返还初始宝物及养成消耗的大量资源"
        elseif self.chooseData[tonumber(1)].type and (self.chooseData[tonumber(1)].type == "head" or self.chooseData[tonumber(1)].type == "weapon" or self.chooseData[tonumber(1)].type == "accessory" or self.chooseData[tonumber(1)].type == "armor" or self.chooseData[tonumber(1)].type == "shoe" or self.chooseData[tonumber(1)].type == "accessories") then
            descString = "重生返还初始装备及养成消耗的大量资源"
        elseif temconfig.staffType == "general" then  
            descString = "重生返还初始伙伴及养成消耗的大量资源"
        elseif temconfig.staffType == "pet" then  
            descString = "重生返还初始魔宠，并重置该魔宠对应的图鉴等级\n重生后返还养成魔宠及图鉴的全部资源"
        elseif temconfig.staffType == "fashion" then  
            print("type==",temconfig.staffType)
            -- descString = "重生返还初始时装及养成消耗的大量资源"
            descString = gameConfig.strings:string_common("qiankunlu",15)
        elseif temconfig.staffType == "artifact" then
            descString = "             神器重生会重置神器\n返还培养消耗的资源，仅保留技能"
        elseif temconfig.staffType == "exclusive" then
            descString = "专属神器重生返还全部养成资源并卸下所有器灵\n              重生后无需再次激活专属神器"
        end
        print("descstring===",descstring)
        ui.setLabelString(self.rootItems.chongshengSpendDesc_Label,descString,3)
    else
        -- print("setNothingItems",i)
        self:setNothingItems(1,self.rootItems)
        self.rootItems.chongshengSpendDesc_Label:setVisible(false)
    end

end

function Layer_qiankunlu.setRedFragmentData(self,data)
   self.redFragmentData = data
end

function Layer_qiankunlu.setGeneralFragmentData(self,data)
   self.generalFragmentData = data
end

function Layer_qiankunlu.setEquipsData(self,data)
   self.equipsData = data
end

function Layer_qiankunlu.setEquipsFragmentData(self,data)
   self.equipsFragmentData = data
end

function Layer_qiankunlu.setTreasuresData(self,data)
   self.treasuresData = data
end

function Layer_qiankunlu.setTreasuresFragmentData(self,data)
   self.treasuresFragmentData = data
end

function Layer_qiankunlu.setGeneralData(self,data)
   self.generalData = data
end

function Layer_qiankunlu.setFashionData(self,data)
    -- printT(data,"fashionData===")
   self.fashionData = data
end

function Layer_qiankunlu.setPetData(self,data)
    -- printT(data,"petData===")
    self.petiid = data and data.iid or 0
    self.petData = data and data.pets or {}
end

function Layer_qiankunlu.setArtifactData(self,data)
    printT(data,"setArtifactData===")
   self.artifactData = data
   if not self.showartifactData then
       self.showartifactData = self:chongshengartifactSortfun(self.artifactData)
   end
end

function Layer_qiankunlu.reloadPageData(self,data)
    -- print("reloadPageData")
    if  data then
        gameTouch:clickprofbytime(1)
        local sq1 = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
            showRewardPopupWindow(data.reward,nil,nil,true)
            UIRequest({type = 1001})
        end))
        self.rootNode:runAction(sq1)
    end
    
    if not GameScene:checkUpdate(10024) and not GameScene:checkUpdate(1012) and not GameScene:checkUpdate(10025,"offequips") and not GameScene:checkUpdate(10025,"offtreasures") and not GameScene:checkUpdate(10030) and not GameScene:checkUpdate(11071,"equip") and not GameScene:checkUpdate(11071,"treasure") then
        -- self:shiftPage(self.selectpage,true)
        self:playEffectController()
    end
    UIRequest({type = 12001, order = 32001, cids = {20200}})
end

function Layer_qiankunlu.resetquicknode( self,status)

    if status == "open" then
        local index = 1
        for i=2,5 do
            self.quickItems["q_node"..i]:stopAllActions()
            if i==self.resolvequality then
                self.quickItems["q_node"..i]:setZOrder(1)
                self.quickItems["q_node"..i]:setPosition(60,0)
            else
                local moveto = CCMoveTo:create(0.5,ccp(60,index*68))
                local backout = CCEaseBackOut:create(moveto)
                self.quickItems["q_node"..i]:setZOrder(0)
                self.quickItems["q_node"..i]:runAction(backout)
                index = index +1
            end
        end
        self.quickstatus = true
    else
        for i=2,5 do
            self.quickItems["q_node"..i]:stopAllActions()
            if i==self.resolvequality then
                self.quickItems["q_node"..i]:setZOrder(1)
                self.quickItems["q_button"..i]:setTouchPriority(-107)
            else
                self.quickItems["q_node"..i]:setZOrder(0)
                self.quickItems["q_button"..i]:setTouchPriority(-106)
            end
            local moveto = CCMoveTo:create(0.3,ccp(60,0))
            local backout = CCEaseBackIn:create(moveto)
            self.quickItems["q_node"..i]:runAction(backout)
        end
        self.quickstatus = false
    end

end

function Layer_qiankunlu.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("qiankunlu/qiankunlu", nil, true, "qiankunlu")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    local recycle_10_level = gamedata.config.global_kv.recycle_10_level or {value=50}
    local level10 = tonumber(recycle_10_level.value)
    self.maxnum_select = GameScene.roleinfo.level>=level10 and 10 or 5
    self.selectNode,self.selectItems = CCBReaderLoad("qiankunlu/qiankunlu"..self.maxnum_select, nil, true, "qiankunlu")
    self.rootItems.showItemsNode:addChild(self.selectNode)
    self.rootItems.topnode:setPositionY(toppos)

    self.quickNode,self.quickItems = CCBReaderLoad("qiankunlu/qiankunlu_fast", nil, true, "qiankunlu_fast")
    self.rootItems.quicknode:addChild(self.quickNode) 
    self.quickani = getAnimationManager(self.quickItems)

    self.quickItems["q_node"..self.resolvequality]:setZOrder(1)
    ui.setLabelString(self.quickItems["quickdesc"],nil,14)

    for i=2,5 do
        self.quickItems["q_button"..i]:setSwallowsTouch(true)
        self.quickItems["q_button"..i]:setTouchPriority(self.resolvequality == i and -107 or -106)
        self.quickItems["q_button"..i]:addHandleOfControlEvent(function()
            print("q_button ----",i)
            if self.resolvequality == i then
                self.quickstatus = not self.quickstatus
                self:resetquicknode(self.quickstatus and "open" or "close")
            else
                gameTouch:clickprofbytime(1)
                UIRequest({type=3850,quality = i})
            end
        end, CCControlEventTouchUpInside)
    end
    
    --
    if self.rootItems.buttonnode3 then
        self.rootItems.buttonnode3:setVisible(gameConfig:checkBuildOpen(441))
    end    
    --
    -- self:shiftPage()
    self:reloadPageData()
    -- 规则说明
    self.rootItems.ruleBtn:setSwallowsTouch(true)
    self.rootItems.ruleBtn:setTouchPriority(-105)
    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
        -- print("ruleBtn===")
        -- gameWindows:openWindow("qiankunluPopup",{index = self.selectpage},nil)
        if self.selectpage == "lianhua" then
            ui.popCommonRule(588)
        elseif self.selectpage == "chongsheng" then
            gameWindows:openWindow("qiankunluPopup",{index = "chongsheng"},nil)
        elseif self.selectpage == "fenjie" then
            ui.popCommonRule(441)
        end
        
    end, CCControlEventTouchUpInside)

    -- 神秘商店
    self.rootItems.secretBtn:setSwallowsTouch(true)
    self.rootItems.secretBtn:setTouchPriority(-105)
    self.rootItems.secretBtn:addHandleOfControlEvent(function()
        -- print("secretBtn===")
        --runGamePrompt({msg = "功能暂未开启"})
        GameScene:shiftLayerById(134)
        if guide.controller then
            guide.controller:UIComplete(10080)
        end
    end, CCControlEventTouchUpInside)

    if self.rootItems.jinghuaBtn then
        self.rootItems.jinghuaBtn:setSwallowsTouch(true)
        self.rootItems.jinghuaBtn:setTouchPriority(-105)
        self.rootItems.jinghuaBtn:addHandleOfControlEvent(function()
            GameScene:shiftLayerById(434)
        end, CCControlEventTouchUpInside)
    end
    
    -- 炼化按钮
    ui.setLabelString(self.rootItems.lianhuaText,nil,19)
    self.rootItems.lianhuaBtn:setSwallowsTouch(true)
    self.rootItems.lianhuaBtn:setTouchPriority(-105)
    self.rootItems.lianhuaBtn:addHandleOfControlEvent(function()
        print("lianhuaBtn===")
        if self.chooseData and next(self.chooseData) then
            local tempdata = self.chooseData[tonumber(1)]

            local config = ui.IDconfig(tempdata.cid)


            if (config.staffType ==  "treasure_fragment") or (tempdata.type and (tempdata.type == "horse" or tempdata.type == "treasure")) then
                -- "treasure"
                -- print("treasure")
                local ids = {}
                local cid = {}
                local fragments = {}
                local fivestype = {}
                for i,v in ipairs(self.chooseData) do
                    local config = ui.IDconfig(v.cid)

                    if config.quality >= 5 then
                        table.insert(fivestype,v)
                    end

                    if config.staffType == "treasure_fragment" then
                        table.insert(fragments,{cid = v.cid,num = v.num})
                    else
                        table.insert(ids,v.iid)
                    end
                    table.insert(cid,{cid = v.cid})
                end

                if next(fivestype) then
                    local callback = function()
                        -- print("callbackfive....")
                        gameTouch:clickprofbytime(1)
                        UIRequest({type=1104,ids = ids,cid = cid,fragments = fragments})
                    end
                    gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "lianhua",labeltype = "treasure"},callback)
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type=1104,ids = ids,cid = cid,fragments = fragments})
                    -- print("nofive....")
                end

                

            elseif (config.staffType ==  "equip_fragment") or (tempdata.type and (tempdata.type == "head" or tempdata.type == "weapon" or tempdata.type == "accessory" or tempdata.type == "armor" or tempdata.type == "shoe" or tempdata.type == "accessories")) then
                -- print("equip")
                -- "equip"
                local ids = {}
                local cid = {}
                local fragments = {}
                local fivestype = {}
                for i,v in ipairs(self.chooseData) do

                    local config = ui.IDconfig(v.cid)

                    if config.quality >= 5 then
                        table.insert(fivestype,v)
                    end
                        
                    if config.staffType == "equip_fragment" then
                        table.insert(fragments,{cid = v.cid,num = v.num})
                    else
                        
                        table.insert(ids,v.iid)
                    end
                    table.insert(cid,{cid = v.cid})
                end


                if next(fivestype) then
                    local callback = function()
                        -- print("callbackfive....")
                        gameTouch:clickprofbytime(1)
                        UIRequest({type=1104,ids = ids,cid = cid,fragments = fragments})
                    end
                    gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "lianhua",labeltype = "equip"},callback)
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type=1104,ids = ids,cid = cid,fragments = fragments})
                    -- print("nofive....")
                end
            elseif (tempdata.fragmentCid and tempdata.fragmentCid > 0) or (tempdata.cid >= 10101 and tempdata.cid <= 11000) or (tempdata.cid >= 160001 and tempdata.cid <= 161000) or (tempdata.cid >= 170001 and tempdata.cid <= 171000) or (tempdata.cid >= 162001 and tempdata.cid <= 163000) or (tempdata.cid >= 164001 and tempdata.cid <= 165000) or (tempdata.cid >= 174001 and tempdata.cid <= 175000) then
                -- print("generalFragment")
                -- "generalFragment"
                local fragments = {}
                local cid = {}
                local fivestype = {}
                local ids = {}
                for i,v in ipairs(self.chooseData) do
                    if v.quality >= 5 then
                        table.insert(fivestype,v)
                    end

                    if v.fragmentCid then
                        table.insert(fragments,{cid=v.fragmentCid, num=v.num})
                        table.insert(cid,{cid = v.fragmentCid})
                    elseif (v.cid >= 10101 and v.cid <= 11000) or (v.cid >= 160001 and v.cid <= 161000) or (v.cid >= 170001 and v.cid <= 171000) or (v.cid >= 162001 and v.cid <= 163000) or (v.cid >= 164001 and v.cid <= 165000) or (v.cid >= 174001 and v.cid <= 175000) then
                        table.insert(ids,v.iid)
                        table.insert(cid,{cid = v.cid})
                        table.insert(fragments,{cid=v.cid, num=1})
                    else
                    end
                end

                -- printT(fragments)

                if next(fivestype) then
                    local callback = function()
                        --UIRequest({type=1036, fragments = fragments, cid = cid})
                        gameTouch:clickprofbytime(1)
                        UIRequest({type=1039, fragments = fragments, cid = cid,ids = ids})
                    end
                    gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "lianhua",labeltype = "generalFragment"},callback)
                else
                    --UIRequest({type=1036, fragments = fragments, cid = cid})
                    gameTouch:clickprofbytime(1)
                    UIRequest({type=1039, fragments = fragments, cid = cid,ids = ids})
                end

            else
                -- print("general")
                -- "general"
            end
        else
            runGamePrompt({msg = "请放入需要炼化的伙伴或装备"})
        end


    end, CCControlEventTouchUpInside)

    -- 一键魂魄按钮
    ui.setLabelString(self.rootItems.onekeyGeneralFragmentText,nil,19)
    self.rootItems.onekeyGeneralFragmentBtn:setSwallowsTouch(true)
    self.rootItems.onekeyGeneralFragmentBtn:setTouchPriority(-105)
    self.rootItems.onekeyGeneralFragmentBtn:addHandleOfControlEvent(function()
        -- print("onekeyGeneralFragmentBtn===")
        
        self:onekeyAddFunc(self.showgeneralFragmentData,"没有符合条件的魂魄")
        -- self:setShowItems()

    end, CCControlEventTouchUpInside)
    
    -- 一键装备按钮
    ui.setLabelString(self.rootItems.onekeyEquipText,nil,19)
    self.rootItems.onekeyEquipBtn:setSwallowsTouch(true)
    self.rootItems.onekeyEquipBtn:setTouchPriority(-105)
    self.rootItems.onekeyEquipBtn:addHandleOfControlEvent(function()
        -- print("onekeyEquipBtn===")

        self:onekeyAddFunc(self.showequipsFragmentData,"没有符合条件的装备")
        -- self:setShowItems()
    end, CCControlEventTouchUpInside)

    -- 一键宝物按钮
    ui.setLabelString(self.rootItems.onekeyTreasureText,nil,19)
    self.rootItems.onekeyTreasureBtn:setSwallowsTouch(true)
    self.rootItems.onekeyTreasureBtn:setTouchPriority(-105)
    self.rootItems.onekeyTreasureBtn:addHandleOfControlEvent(function()
        self:onekeyAddFunc(self.showtreasuresFragmentData,"没有符合条件的宝物")
        -- self:setShowItems()

        -- print("onekeyTreasureBtn===")
    end, CCControlEventTouchUpInside)

    --
    ui.setLabelString(self.rootItems.f_txt,nil,14)
    ui.setLabelString(self.rootItems.fenjieText,nil,19)
    self.rootItems.fenjieBtn:setSwallowsTouch(true)
    self.rootItems.fenjieBtn:setTouchPriority(-105)
    self.rootItems.fenjieBtn:addHandleOfControlEvent(function()
        if self.chooseData and next(self.chooseData) then
            local fragments = {}
            for i,v in ipairs(self.chooseData) do
                table.insert(fragments,{cid = v.cid, num = v.num})
            end

            local callback = function()
                gameTouch:clickprofbytime(1)
                UIRequest({type = 6901, fragments = fragments,})
            end
            gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fragments,page = "fenjie",labeltype = "redfragment"},callback)

        else
            runGamePrompt({msg = "请放入需要分解的伙伴精华"})
        end

    end, CCControlEventTouchUpInside)
    --
    ui.setLabelString(self.rootItems.onekeyText20,nil,18)
    ui.setLabelString(self.rootItems.onekeyText23,nil,18)
    --
    self.rootItems.onekeyBtn20:setSwallowsTouch(true)
    self.rootItems.onekeyBtn20:setTouchPriority(-105)
    self.rootItems.onekeyBtn20:addHandleOfControlEvent(function()
        
        self:onekeyAddRedFunc(self.showredFragmentData,20790)

    end, CCControlEventTouchUpInside)
    --
    self.rootItems.onekeyBtn23:setSwallowsTouch(true)
    self.rootItems.onekeyBtn23:setTouchPriority(-105)
    self.rootItems.onekeyBtn23:addHandleOfControlEvent(function()
        
        self:onekeyAddRedFunc(self.showredFragmentData,20778)

    end, CCControlEventTouchUpInside)
    --
    self.rootItems.iconBtn20:setSwallowsTouch(true)
    self.rootItems.iconBtn20:setTouchPriority(-105)
    self.rootItems.iconBtn20:addHandleOfControlEvent(function()
        
        ui.setPopwindowByCid(20790)

    end, CCControlEventTouchUpInside)
    --
    self.rootItems.iconBtn23:setSwallowsTouch(true)
    self.rootItems.iconBtn23:setTouchPriority(-105)
    self.rootItems.iconBtn23:addHandleOfControlEvent(function()
        
        ui.setPopwindowByCid(20778)

    end, CCControlEventTouchUpInside)
    --

    self:chongshenginit()

    self:huahuninit()
    UIRequest({type = 12001, order = 32001, cids = {20200}})
end

function Layer_qiankunlu.playEffectController( self )
    -- print("playEffectController")
    -- printT(self.chooseData)
    if self.chooseData and next(self.chooseData) then

    else
        self:shiftPage(self.selectpage,true)
        return
    end

    if self.selectpage == "lianhua" or self.selectpage == "fenjie" then
        for i,v in ipairs(self.chooseData) do
            self:playEffect(i,self.selectItems)
        end
    elseif self.selectpage =="chongsheng" then
        self:playEffect(6,self.rootItems)
    elseif self.selectpage =="huahun" then
        for i,v in ipairs(self.chooseData) do
            self:playEffect(i,self.selectItems)
        end
    end

    local sq2 = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        self:shiftPage(self.selectpage,true)
    end))
    self.rootNode:runAction(sq2)
    
end

function Layer_qiankunlu.playEffect( self, num ,Ttems)
    -- print("playEffect",num)
    local rootNode, rootItems = CCBReaderLoad("UIEffect/qiankunlu/qiankunlu.ccbi", nil, true, "qiankunlu")
   Ttems["effect"..num.."node"]:addChild(rootNode)

    self.animationManager = getAnimationManager(rootItems)
    self.animationManager:setAnimationCompletedCallback(function()
        -- print("complete..effect")
        Ttems["effect"..num.."node"]:removeAllChildrenWithCleanup(true)
    end)
    self.animationManager:runAnimationsForSequenceNamed("qiankunlu_texiao")
end

function Layer_qiankunlu.setGodSoulTempleData(self, data)
    self.godSoulTemple = data.godSoulTemple
end

function Layer_qiankunlu.checkGodSoulTempleLevelDown(self, data)
    local _cid = ui.getOriginCid(data[1].cid)
    local _basic = gamedata.config.general[tostring(_cid)].basic
    local _level2 = self.chooseData[1].level2
    local _soulLevel = self.godSoulTemple[tostring(_basic)] and self.godSoulTemple[tostring(_basic)].soulLevel or 0
    local _genralsLevel2ByBasic = self.godSoulTemple[tostring(_basic)] and self.godSoulTemple[tostring(_basic)].genralsLevel2ByBasic or 0

    if (_basic == 18 or _basic == 20 or _basic == 23) and _soulLevel > 0 then
        if _genralsLevel2ByBasic - _level2 < gamedata.config.shenhundian_sanshengshi[tostring(_basic)][tostring(_soulLevel)].breakthrough_limit then
            return false, _basic
        else
            return true
        end
    else
        return true
    end
end

function Layer_qiankunlu.chongshenginit( self )

    ui.setLabelString(self.rootItems.chongshengSpendText,nil,14)
    ui.setLabelString(self.rootItems.chongshengSpend_Label,nil,14)


    ui.setLabelString(self.rootItems.chongshengText,nil,19)
    self.rootItems.chongshengBtn:setSwallowsTouch(true)
    self.rootItems.chongshengBtn:setTouchPriority(-105)
    self.rootItems.chongshengBtn:addHandleOfControlEvent(function()
        print("chongshengBtn===")
        
        if self.chooseData and next(self.chooseData) then
            local tempdata = self.chooseData[tonumber(1)]
            local temconfig = {}
            if tempdata.cid then
                temconfig = ui.IDconfig(tempdata.cid)
            else
                temconfig = ui.IDconfig(tempdata.id)
            end
            -- printT(temconfig,"temconfig====1")
            if temconfig.staffType == "exclusive" then
                if self.allspendgold > GameScene.roleinfo.g_gold then
                    shortPropById(1025)
                    return
                end
            else
                if self.allspendgold > GameScene.roleinfo.gold then
                    shortGold()
                    return
                end
            end

            if tempdata.type and (tempdata.type == "horse" or tempdata.type == "treasure") then
                -- "treasure"
                -- print("treasure")
                local ids = {}
                local cid = {}
                local fivestype = {}
                for i,v in ipairs(self.chooseData) do
                    if v.quality >= 5 then
                        table.insert(fivestype,v)
                    end
                    table.insert(ids,v.iid)
                    table.insert(cid,{cid = v.cid})
                end

                if next(fivestype) then
                    local callback = function()
                        -- print("callbackfive....")
                        gameTouch:clickprofbytime(1)
                        UIRequest({type=1117,ids = ids, cid = cid, gold = self.allspendgold})
                    end
                    gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "chongsheng",labeltype = "treasure"},callback)
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type=1117,ids = ids, cid = cid, gold = self.allspendgold})
                    -- print("nofive....")
                end
                
                -- UIRequest({type=1117,ids = ids, cid = cid, gold = self.allspendgold})

            elseif tempdata.type and (tempdata.type == "head" or tempdata.type == "weapon" or tempdata.type == "accessory" or tempdata.type == "armor" or tempdata.type == "shoe" or tempdata.type == "accessories") then
                -- print("equip")
                -- "equip"
                local ids = {}
                local cid = {}
                local fivestype = {}

                for i,v in ipairs(self.chooseData) do
                    if v.quality >= 5 then
                        table.insert(fivestype,v)
                    end
                    table.insert(ids,v.iid)
                    table.insert(cid,{cid = v.cid})
                end

                if next(fivestype) then
                    local callback = function()
                        -- print("callbackfive....")
                        gameTouch:clickprofbytime(1)
                        UIRequest({type=1117,ids = ids, cid = cid, gold = self.allspendgold})
                    end
                    gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "chongsheng",labeltype = "equip"},callback)
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type=1117,ids = ids, cid = cid, gold = self.allspendgold})
                    -- print("nofive....")
                end
                
                -- UIRequest({type=1117,ids = ids, cid = cid, gold = self.allspendgold})
            elseif tempdata.fragmentCid and tempdata.fragmentCid > 0 then
                -- print("generalFragment")

            elseif temconfig.staffType == "general" then  
                -- print("general")
                -- "general"
                local ids = {}
                local cid = {}
                local fivestype = {}
                for i,v in ipairs(self.chooseData) do
                    if v.quality >= 5 then
                        table.insert(fivestype,v)
                    end
                    table.insert(ids,v.iid)
                    table.insert(cid,{cid = v.cid})
                end

                local _result, _basic = self:checkGodSoulTempleLevelDown(cid)

                if _result then
                    if next(fivestype) then
                        local callback = function()
                            -- print("callbackfive....")
                            gameTouch:clickprofbytime(1)
                            UIRequest({type=1035,ids = ids, cid = cid, gold = self.allspendgold})
                        end
                        gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "chongsheng",labeltype = "general"},callback)
                    else
                        gameTouch:clickprofbytime(1)
                        UIRequest({type=1035,ids = ids, cid = cid, gold = self.allspendgold})
                        -- print("nofive....")
                    end
                else
                    if next(fivestype) then
                        local callback = function()
                            -- print("callbackfive....")
                            gameTouch:clickprofbytime(1)
                            UIRequest({type=1035,ids = ids, cid = cid, gold = self.allspendgold})
                        end
                        gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "chongsheng",labeltype = "general", basic = _basic},callback)
                    else
                        gameTouch:clickprofbytime(1)
                        UIRequest({type=1035,ids = ids, cid = cid, gold = self.allspendgold})
                        -- print("nofive....")
                    end
                end
                
                
                -- UIRequest({type=1035,ids = ids, cid = cid, gold = self.allspendgold})
            elseif temconfig.staffType == "fashion" then
                local ids = {}
                local cid = {}
                for i,v in ipairs(self.chooseData) do
                    table.insert(ids,v.id)
                    -- table.insert(cid,{cid = v.cid})
                end
                print("glod===",self.allspendgold)
                -- printT(ids)
                gameTouch:clickprofbytime(1)
                UIRequest({type=1077,ids = ids, gold = self.allspendgold})
                -- print("nofive....")

            elseif temconfig.staffType == "pet" then 

                local ids = {}
                local fivestype = {}
                for i,v in ipairs(self.chooseData) do
                    table.insert(ids,v.iid)
                    table.insert(fivestype,v)
                end
                local callback = function()
                    gameTouch:clickprofbytime(1)
                    UIRequest({type=1065,ids = ids, gold = self.allspendgold})
                end
                gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "chongsheng",labeltype = "pet"},callback)
            elseif temconfig.staffType == "artifact" then 

                local ids = {}
                local fivestype = {}
                for i,v in ipairs(self.chooseData) do
                    table.insert(ids,v.iid)
                    table.insert(fivestype,v)
                end
                local callback = function()
                    UIRequest({type=5520,iid = ids[1], gold = self.allspendgold})
                end
                gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "chongsheng",labeltype = "artifact"},callback)

            elseif temconfig.staffType == "exclusive" then
                local ids = {}
                local fivestype = {}
                for i,v in ipairs(self.chooseData) do
                    table.insert(ids,v.generalIid)
                    table.insert(fivestype,v)
                end
                local callback = function()
                    UIRequest({type=8204,generalIid = ids[1], gold = self.allspendgold})
                end
                gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "chongsheng",labeltype = "exclusiveArtifact"},callback)

            end
        else
            runGamePrompt({msg = "请放入需要重生的伙伴、装备、宝物、时装、神器、魔宠、专属神器"})
        end
    end, CCControlEventTouchUpInside)
end

function Layer_qiankunlu.huahuninit( self )


    -- -- 化魂一键添加按钮
    ui.setLabelString(self.rootItems.onekeyGeneralText,nil,19)
    self.rootItems.onekeyGeneralBtn:setSwallowsTouch(true)
    self.rootItems.onekeyGeneralBtn:setTouchPriority(-105)
    self.rootItems.onekeyGeneralBtn:addHandleOfControlEvent(function()
        -- print("onekeyGeneralBtn===")
        self:onekeyAddFunc(self.showgeneralData,"没有符合条件的伙伴")
        -- self:setShowItems()
    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.huahunText,nil,19)
    ui.setLabelString(self.rootItems.txt_1,nil,14)
    self.rootItems.huahunBtn:setSwallowsTouch(true)
    self.rootItems.huahunBtn:setTouchPriority(-105)
    self.rootItems.huahunBtn:addHandleOfControlEvent(function()
        -- print("huahunBtn===")
        if self.chooseData and next(self.chooseData) then
            if self.allspendcoin > GameScene.roleinfo.coin then
                --runGamePrompt({msg = "银币不足"})
                shortCoin()
                return
            end
            local ids = {}
            local cid = {}
            local fivestype = {}
            for i,v in ipairs(self.chooseData) do
                if v.quality >= 5 then
                    table.insert(fivestype,v)
                end
                table.insert(ids,v.iid)
                table.insert(cid,{cid = v.cid})
            end

            if next(fivestype) then
                local callback = function()
                    -- print("callbackfive....")
                    gameTouch:clickprofbytime(1)
                    UIRequest({type=1037,ids = ids, cid = cid, coin = self.allspendcoin})
                end
                gameWindows:openWindow("qiankunluPopup",{index = "queren", data = fivestype,page = "huahun",labeltype = "general"},callback)
            else
                gameTouch:clickprofbytime(1)
                UIRequest({type=1037,ids = ids, cid = cid, coin = self.allspendcoin})
                -- print("nofive....")
            end

            -- UIRequest({type=1037,ids = ids, cid = cid, coin = self.allspendcoin})
        else
            runGamePrompt({msg = "请放入需要化魂的伙伴"})
        end

    end, CCControlEventTouchUpInside)
    
end


-- 一键添加武将／物品／魂魄／宝物 方法
function Layer_qiankunlu.onekeyAddFunc(self,data,descstring)
    self.chooseData = nil
    self.chooseData = {}


    if data  and next(data) then
        -- if self.selectpage == "lianhua" then
        --     for i,v in ipairs(data) do 
        --         if #self.chooseData < self.maxnum_select then
        --             if v.quality < 5 and v.level1 == 1 and self.exceptdata[tostring(v.iid)]==nil then
        --                 table.insert(self.chooseData, v)
        --             end
        --         else
        --             break
        --         end
        --     end
        -- else

            for i,v in ipairs(data) do 
                if #self.chooseData < self.maxnum_select then 
                    if (not v.fragmentCid) and ((v.cid>= 10101 and v.cid <= 11000) or (v.cid >= 160001 and v.cid <= 161000) or (v.cid >= 170001 and v.cid <= 171000) or (v.cid >= 162001 and v.cid <= 163000) or (v.cid >= 164001 and v.cid <= 165000) or (v.cid >= 174001 and v.cid <= 175000)) then    
                        if v.quality <= self.resolvequality and v.level1 == 1 and self.exceptdata[tostring(v.iid)]==nil then
                            table.insert(self.chooseData, v)
                        end
                    else
                        if v.quality <= self.resolvequality then
                            table.insert(self.chooseData, v)
                        end
                    end
                else
                    break
                end
            end
        --end
    end

    if next(self.chooseData) then
    else
        runGamePrompt({msg = descstring})
    end
    -- printT(self.chooseData,"chooseData===")


    self:setShowItems()


    
    -- print("choosedata===")
    -- printT(self.chooseData)
end

function Layer_qiankunlu.onekeyAddRedFunc(self,data,propid)
    self.chooseData = nil
    self.chooseData = {}

    if data and next(data) then
        for i,v in ipairs(data) do 
            if #self.chooseData < self.maxnum_select then 
                if gamedata.config.redl_awake_item[tostring(v.cid)] and gamedata.config.redl_awake_item[tostring(v.cid)].decompose and gamedata.config.redl_awake_item[tostring(v.cid)].decompose == 1 then    
                    local decomposeprop = ui.getIDandNUMs(gamedata.config.redl_awake_item[tostring(v.cid)].decompose_prop) or {}
                    if decomposeprop and decomposeprop[1] and decomposeprop[1].cid and decomposeprop[1].cid == propid then
                        table.insert(self.chooseData, v)
                    end
                end
            else
                break
            end
        end
    end

    if next(self.chooseData) then
    else
        runGamePrompt({msg = "没有符合条件的伙伴精华"})
    end

    self:setShowItems()
end

-- 更新魂蛋的数量
function Layer_qiankunlu.setUpPropNum(self,data)
    ui.setLabelString(self.rootItems.huntext,("x"..data["20200"]),3)
end


function Layer_qiankunlu.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.selectpage = "lianhua"
    self.chooseData = nil
    self.showgeneralFragmentData = nil
    self.showequipsData = nil
    self.showtreasuresData =nil
    self.showgeneralData = nil
    self.showfashionData = nil
    self.showpetData = nil
    self.showartifactData = nil

    self.allspendgold = 0
    self.allspendcoin = 0
    self.exceptdata = {}
    self.quickstatus = false
end

return Layer_qiankunlu
