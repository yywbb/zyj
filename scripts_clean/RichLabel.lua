--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/8/21
-- Time: 上午10:56
-- To change this template use File | Settings | File Templates.
--

-- strTable  example:
--[[
   strTable = {
        {fontID = 1,content = "恭喜"},
        {fontID = 2,content = "东方香之"},
        {},              --空表实现换行
        {fontID = 3,content = "获得ggdfgdfhdghsdghdghfghdfghdfghdfghdfg竞技场第"},
        {fontID = 4,content = "1"},
        {fontID = 5,content = "名！！"},
        {fontID = 0,content = "obj_s_gold.png"},  --id为0是图片
     }
]]--


local BMfontId = {
    [32] = "font/fangzheng.fnt",
    [34] = "font/fangzheng2.fnt",
    [35] = "font/fangzheng3.fnt",
    [36] = "font/fangzheng4.fnt",
    [37] = "font/fangzheng_lan.fnt",
    [38] = "font/fangzheng_huang.fnt",
    [39] = "font/mini_lan1.fnt",
    [40] = "font/mini_lan2.fnt",
    [43] = "font/mini_zhandouli.fnt",
    [44] = "font/fangzheng_cusong.fnt",
    [45] = "font/mini_main.fnt",

    [50] = "font/fangzheng_rub.fnt",
    [51] = "font/fangzheng_up.fnt",
    [52] = "font/fangzheng_down.fnt",
    [53] = "font/mibi_shu.fnt",
    [54] = "font/mini_huang.fnt",
    [55] = "font/fangzheng_chengzhang.fnt",
    [56] = "font/mini_hong.fnt",
    [57] = "font/fangzheng_paiming.fnt",
    [58] = "font/loseblood_critical_0.fnt",
    [59] = "font/loseblood_normal_0.fnt",
    [60] = "font/shu11.fnt",

}

local richlabel = {

}

function richlabel.init(self,str,container)
    self.offsetX = 0
    self.offsetY = 0
    self.linenodes = {}
    self.str = {}
    self.container = container
    self.size = container:getContentSize()

    for k,v in ipairs(str) do
        if v.content and string.find(v.content,"\n") then
            local str_ = v.content
            local b,e = string.find(str_,"\n")
            while b do
                table.insert(self.str,{fontID=v.fontID,content = (b==1 and " " or string.sub(str_,1,b-1)),fontSize = v.fontSize})
                table.insert(self.str,{})

                str_ = (e==string.len(str_) and "" or string.sub(str_,e+1,string.len(str_)))
                b,e = string.find(str_,"\n")
            end
            if str_ ~= "" then
                table.insert(self.str,{fontID=v.fontID,content = str_,fontSize = v.fontSize})
            end
        else
            table.insert(self.str,v)
        end
    end
end

function richlabel.addOneNode(self,node,nodesize)
    local presentLineNode = self.linenodes[#self.linenodes]
    nodesize = nodesize or node:getContentSize()

    node:setAnchorPoint(ccp(0,0))
    node:setPosition(ccp(self.offsetX,0))
    presentLineNode.node:addChild(node)

    if presentLineNode.posY < nodesize.height then
        presentLineNode.posY = nodesize.height
    end

    presentLineNode.posX = presentLineNode.posX + nodesize.width

    self.offsetX = self.offsetX + nodesize.width
end

function richlabel.addLinenode(self,dis_zero)
    local linenode = CCNode:create()
    self.container:addChild(linenode)
    self.linenodes[#self.linenodes+1] = {posY = 0,posX = 0,node = linenode,dis_zero = dis_zero }
    self.offsetX = 0
end

function richlabel.createSprite(self,data)
    local sprite = CCSprite:create()
    setSpriteFrameByName(sprite,data.content)
    if data.scale then
        sprite:setScale(data.scale)
    end

    local orignsize = sprite:getContentSize()
    local spriteSize = {
        width = orignsize.width*(data.scale or 1),
        height = orignsize.height*(data.scale or 1)
    }
    if spriteSize.width + self.offsetX > self.size.width then
        self:addLinenode()
    end

    self:addOneNode(sprite,spriteSize)
end

function richlabel.createlabel(self,data)
    local label = ui.createLabel({
        fontsize = data.fontSize or ui.findlableSize(data.fontID),
        font = "Helvetica-Bold",
    })
    ui.setLabelString(label,data.content,data.fontID,data.fontSize)

    if self.offsetX + label:getContentSize().width > self.size.width then
        local realindexT= ui.getStrRealindexT(data.content)
        local splitidx = math.floor(#realindexT*((self.size.width-self.offsetX)/label:getContentSize().width))
        if splitidx <= 0 then
            self:addLinenode()
            self:createlabel(data)
        elseif splitidx < #realindexT then
            ui.setLabelString(label,string.sub(data.content,1,realindexT[splitidx]),data.fontID,data.fontSize)
            self:addOneNode(label)
            self:addLinenode(true)
            self:createlabel({fontID = data.fontID,fontSize = data.fontSize,content = string.sub(data.content,realindexT[splitidx]+1,realindexT[#realindexT])})
        elseif splitidx >= #realindexT then
            self:addOneNode(label)
            self:addLinenode()
        end
    else
        self:addOneNode(label)
    end
end

function richlabel.createBMlabel(self,data)
    local label = CCLabelBMFont:create()
    label:setFntFile(BMfontId[data.fontID])

    label:setString(data.content)

    if self.offsetX + label:getContentSize().width > self.size.width then
        local realindexT= ui.getStrRealindexT(data.content)
        local splitidx = math.floor(#realindexT*((self.size.width-self.offsetX)/label:getContentSize().width))
        if splitidx <= 0 then
            self:addLinenode()
            self:createBMlabel(data)
        elseif splitidx < #realindexT then
            ui.setLabelString(label,string.sub(data.content,1,realindexT[splitidx]),data.fontID)
            self:addOneNode(label)
            self:addLinenode()
            self:createBMlabel({fontID = data.fontID,content = string.sub(data.content,realindexT[splitidx]+1,realindexT[#realindexT])})
        elseif splitidx >= #realindexT then
            self:addOneNode(label)
            self:addLinenode()
        end
    else
        self:addOneNode(label)
    end
end

function richlabel.creatRichLabel(self,strTable,container,isseparated,alignment)
    printT(strTable,"creatRichLabel")
    alignment = alignment or {}
    alignment.horizontal = alignment.horizontal or "left"   --水平对其,默认左对齐 中：center 右：right
    alignment.vertical = alignment.vertical or "top"   --垂直对其，默认上对其  中：center 下：bottom
    alignment.min_line_dis = alignment.min_line_dis or 0  --最小行间距 默认为0
    
    if container then
         container:removeAllChildrenWithCleanup(true)
    end

    self:init(strTable,container)

    if not isseparated then self:addLinenode()  end
    for k, v in ipairs(self.str) do
        if isseparated then self:addLinenode()  end
        if not next(v) then
            self:addLinenode()
        elseif v.fontID == 0 then
            self:createSprite(v)
        elseif BMfontId[v.fontID] then
            self:createBMlabel(v)
        else
            self:createlabel(v)
        end
    end

    for k,v in ipairs(self.linenodes) do
        self.offsetY = self.offsetY + v.posY + ((k==1 or (isseparated and v.dis_zero)) and 0 or alignment.min_line_dis)
        v.node:setPositionY(self.size.height-self.offsetY)
        if alignment.horizontal == "left" then
        elseif alignment.horizontal == "center" then
            v.node:setPositionX((self.size.width-v.posX)/2)
        elseif alignment.horizontal == "right" then
            v.node:setPositionX(self.size.width-v.posX)
        end
    end

    if self.size.height > self.offsetY then
        local a_w = self.size.height - self.offsetY
        if alignment.vertical == "top" then
        elseif alignment.vertical == "center" then
            for k,v in ipairs(self.linenodes) do
                v.node:setPositionY(v.node:getPositionY()-a_w/2)
            end
        elseif alignment.vertical == "bottom" then
            for k,v in ipairs(self.linenodes) do
                v.node:setPositionY(v.node:getPositionY()-a_w)
            end
        end
    end

    return self.offsetY,self.offsetX
end

return richlabel