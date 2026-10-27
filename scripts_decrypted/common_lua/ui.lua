--[[
-- UI module: ui object creator helper.
-- 创建和管理 UI 界面元素
-- User: liliang
-- Date: 13-7-18
-- Time: 上午11:26
]] --

local ui = {
    itemcache = require"UIItemCache"
}

function ui.createExclusiveSkeleton(name,scale)
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(name.."/"..name..".atlas")
    print("createExclusiveSkeleton",path)

    if path == (name.."/"..name..".atlas") then
        return nil
    end
    
    local skeleton = CCSkeletonAnimation:create(name.."/"..name..".json",name.."/"..name..".atlas",1)
    skeleton:setScale(scale or 1)
    return skeleton
end

function ui.addDelayCallback(time,callback)
    local node = CCNode:create()
    local nowScene = CCDirector:sharedDirector():getRunningScene()
    nowScene:addChild(node)
    node:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(time), CCCallFunc:create(function()
        callback()
        node:removeFromParentAndCleanup(true)
    end)))
end

function ui.addEffectAutoRemove(parent,fileName,actionName,callback)
    local node,items = CCBReaderLoad(fileName, nil, true, "effect")
    parent:addChild(node)
    local animationManager = getAnimationManager(items)
    animationManager:setAnimationCompletedCallback(function()
        if callback then
            callback()
        end
        node:removeFromParentAndCleanup(true)
    end)
    if actionName then
        animationManager:runAnimationsForSequenceNamed(actionName)
    end
    return node,items
end


function ui.setMobileShopShow(button,touchPriority,id,isshow)

    if not button then
        return
    end
    
    if isshow then
        button:setVisible(true)

        button:setSwallowsTouch(true)
        button:setTouchPriority(touchPriority)
        button:addHandleOfControlEvent(function()
            UIRequest({type=3200, mobileShopId=id})

        end, CCControlEventTouchUpInside)

    else
        button:setVisible(false)

    end
end

function ui.labelfollow(label1,label2)
    label1:setPositionX(label2:getPositionX() + label2:getContentSize().width + 3)
end


function ui.commonBtn(parent, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (parent.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

function ui.getKey(index)
    local _key_Ex = ""
            
    if index == 1 then
        _key_Ex = ""
    else
        _key_Ex = "_"..(index - 1)
    end

    return _key_Ex
end

function ui.countDownLabel(label,time,callBack)
    local setLabelStr = nil

    setLabelStr = function()
        local _t = ui.dayForTime(time)
        time = time - 1
        local str = gameConfig.strings:timeStr(_t)
        label:setString(str)

        if time <= 0 then
            if callBack then
                callBack()
            end
        else
            label:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
                setLabelStr()
            end)))
        end
    end

    if time > 0 then
        setLabelStr()
    else
        if callBack then
            callBack()
        end
    end

end

function ui.createDropdownList(data,touchPriority,callback)
    
    local selectCCB,selectItems = CCBReaderLoad("dropdown/cell_button1", nil, true, "cell_button1")
    selectItems.selectname:setString(data[1].name)

    --0 关闭状态 1 展开状态
    selectCCB.selectStatus = 0

    local menus = {

    }

    local childNum = #data
    local cellSize = {x = 200, y = 50}
    local speed = 0.1/childNum

    local function touchSelect()
        if selectCCB.selectStatus == 0 then
            for i,v in ipairs(menus) do
                v.ccb:setVisible(true)
                v.ccb:setPositionY(0)
                local delay = CCDelayTime:create((childNum-i)*speed)
                local move = CCMoveBy:create(speed*i,ccp(0,-cellSize.y * ( i-1) ))
                v.ccb:runAction(CCSequence:createWithTwoActions(delay,move))
            end
            selectCCB.selectStatus = 1
        else
            for i,v in ipairs(menus) do
                v.ccb:setVisible(false)
                v.ccb:setPositionY(0)
            end
            selectCCB.selectStatus = 0
        end
    end

    local function touchMenu(i)
        print("touchMenu",i)
        selectItems.selectname:setString(data[i].name)
        touchSelect()
        callback(i)
    end

    

    selectItems.selectbutton:setTouchPriority(touchPriority)
    selectItems.selectbutton:setSwallowsTouch(true)
    selectItems.selectbutton:addHandleOfControlEvent(function()
        touchSelect()
    end, CCControlEventTouchUpInside)


    for i,v in ipairs(data) do
        menus[i] = {}
        menus[i].ccb,menus[i].items = CCBReaderLoad("dropdown/cell_button2", nil, true, "cell_button2")
        menus[i].ccb:setVisible(false)
        selectItems.childnode:addChild(menus[i].ccb)
        menus[i].items.menuname:setString(v.name)

        menus[i].items.menubutton:setTouchPriority(touchPriority)
        menus[i].items.menubutton:setSwallowsTouch(true)
        menus[i].items.menubutton:addHandleOfControlEvent(function()
            touchMenu(i)
        end, CCControlEventTouchUpInside)
    end

    return selectCCB
    -- local buyMenus[i].ccb,self.buyMenus[i].items = CCBReaderLoad("shanghui/cell_button1", nil, true, "cell_button1")
end

--创建CCScale9Sprite
function ui.createScale9Sprite(args)
	args = args or {
		image = gameConfig.images.alpha,
		x = 0,
		y = 0,
		w = 0,
		h = 0,
		ax = 0.5,
		ay = 0.5,
	}

	if (args["image"] ~= nil) then
		if string.find(args["image"],".png") == nil then
			args["image"] = args["image"]..".png"
		end
	end

	local itemScaleSprite = CCScale9Sprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(args.image or
            gameConfig.images.alpha))
	itemScaleSprite:setPreferredSize(CCSizeMake(args.w or 0, args.h or 0))
	itemScaleSprite:setAnchorPoint(ccp(args.ax or 0.5, args.ay or 0.5))
	itemScaleSprite:setPosition(ccp(args.x or 0, args.y or 0))
	itemScaleSprite:setInsetLeft(1.0)
	itemScaleSprite:setInsetRight(1.0)
	itemScaleSprite:setInsetTop(1.0)
	itemScaleSprite:setInsetBottom(1.0)

	return itemScaleSprite
end

ui.buttonColor1 = ccc3(253, 238, 221) --按钮1对应的按钮颜色
ui.buttonColor2 = ccc3(241, 193, 137) --按钮2对应的按钮颜色
ui.grayColor = ccc3(144, 144, 144)
ui.whiteColor = ccc3(255, 255, 255)
ui.blackColor = ccc3(0, 0, 0)
ui.greenColor = ccc3(121, 254, 20)
ui.redColor = ccc3(255, 0, 0)
ui.textColor1 = ccc3(250, 228, 188)
ui.textColor2 = ccc3(74, 42, 0)
ui.relationskillcolor1 = ccc3(74, 42, 0)
ui.relationskillcolor2 = ccc3(65, 39, 27)

ui.titlecolor_selected = ccc3(103, 60, 39)
ui.titlecolor_unselected = ccc3(155, 98, 56)

ui.buttonStrokeColor = ccc3(60,14,0)
ui.titleStrokeColor = ccc3(50,23,0)

--创建按钮1<b_pt_001.png>
function ui.createControlButton1(args)
    args = args or {
        text = "",
        fontsize = 30,
        color = ui.whiteColor,
        frame = sanguo_images["buttonback001"],
        callback = function() end,
        x = 0,
        y = 0,
        w = 138,
        h = 76,
        ax = 0.5,
        ay = 0.5,
        callback = function() end
    }

    if false ~= args.zoom then
        args.zoom = true
    end

	if (args["frame"] ~= nil) then
		if string.find(args["frame"],".png") == nil then
			args["frame"] = args["frame"]..".png"
		end
	end

    local button = CCControlButton:create(args.text or "", "Helvetica-Bold", args.fontsize or 30)
    button:setPreferredSize(CCSizeMake(args.w or 138 , args.h or 76 ))
    button:setAnchorPoint(ccp(args.ax or 0.5, args.ay or 0.5))
    button:setPosition(ccp(args.x or 0, args.y or 0))
    setControlButtonFrameByName(button, args.frame or sanguo_images["buttonback001"], CCControlStateNormal)

    button:setTitleColorForState(args.color or ui.buttonColor1, CCControlStateNormal)
    --button:setTitleLabelStroke(ui.redColor,2)
    --button:setTitleLabelShadow(CCSizeMake(3,-3),0,0)

    button:addHandleOfControlEvent(args.callback or function() end, CCControlEventTouchUpInside)

    if not args.zoom then
        button:setZoomOnTouchDown(false)
    end

    return button
end

--创建按钮2 <b_pt_002.png>
function ui.createControlButton2(args)

	args = args or {
		text = "",
		fontsize = 30,
		color = ui.whiteColor,
		frame = sanguo_images.buttonback002,
		callback = function() end,
		x = 0,
		y = 0,
		w = 138,
		h = 76,
		ax = 0.5,
		ay = 0.5,
		callback = function() end
	}

	if (args["frame"] ~= nil) then
		if string.find(args["frame"],".png") == nil then
			args["frame"] = args["frame"]..".png"
		end
	end

	local button = CCControlButton:create(args.text or "", "Helvetica-Bold", args.fontsize or 30 )
	button:setPreferredSize(CCSizeMake(args.w or 138 , args.h or 76 ))
	button:setAnchorPoint(ccp(args.ax or 0.5, args.ay or 0.5))
	button:setPosition(ccp(args.x or 0, args.y or 0))
	setControlButtonFrameByName(button, args.frame or sanguo_images.buttonback002, CCControlStateNormal)
	button:setTitleColorForState(args.color or ui.buttonColor2, CCControlStateNormal)
	button:addHandleOfControlEvent(args.callback or function() end, CCControlEventTouchUpInside)

	return button
end

--精灵创建方法
function ui.createSprite(args)
	args = args or {
		frame = gameConfig.images.alpha,
		x = 0,
		y = 0,
		ax = 0.5,
		ay = 0.5,
	}

	if (args["frame"] ~= nil) then
		if string.find(args["frame"],".png") == nil then
			args["frame"] = args["frame"]..".png"
		end
	end

	local sprite = CCSprite:createWithSpriteFrameName(args.frame or gameConfig.images.alpha)
	sprite:setPosition(ccp(args.x or 0, args.y or 0))
	sprite:setAnchorPoint(ccp(args.ax or 0.5, args.ay or 0.5))
	sprite:setScale(args.scale or  1)
    sprite:setScaleX(args.scaleX or  1)
    sprite:setScaleY(args.scaleY or  1)
    sprite:setZOrder(args.ZOrder or  0)


	return sprite
end

function ui.createSpriteWithImage(args)
	args = args or {
		frame = sanguo_images.alphaback,
		x = 0,
		y = 0,
		ax = 0.5,
		ay = 0.5,
	}

	if (args["frame"] ~= nil) then
		if string.find(args["frame"],".png") == nil then
			args["frame"] = args["frame"]..".png"
		end
	end

	local sprite = CCSprite:create(args.frame or sanguo_images.alphaback)
	sprite:setPosition(ccp(args.x or 0, args.y or 0))
	sprite:setAnchorPoint(ccp(args.ax or 0.5, args.ay or 0.5))
	sprite:setScale((args.scale or 1) )
    sprite:setZOrder(args.ZOrder or  0)

	return sprite
end

--文本创建方法
function ui.createLabel(args)
	args = args or {
		text = "",
		color = ui.whiteColor,
		fontsize = 30,
		font = "Helvetica-Bold",
		x = 0,
		y = 0,
		ax = 0.5,
		ay = 0.5,
		dw = 0,
		dh = 0,
		hAlignment = kCCTextAlignmentLeft,
		vAlignment = kCCVerticalTextAlignmentTop
	}
	local label = CCLabelTTF:create(args.text or "", args.font or "Helvetica-Bold", args.fontsize or 30
        , CCSizeMake(args.dw or 0, args.dh or 0), args.hAlignment or kCCTextAlignmentLeft, args.vAlignment or kCCVerticalTextAlignmentTop)
	label:setColor(args.color or ui.whiteColor)
	label:setAnchorPoint(ccp(args.ax or 0.5, args.ay or 0.5))
	label:setPosition(ccp(args.x or 0, args.y or 0))
	label:setScale(1)
	return label
end

--[[
-- tableView创建方法
-- args: {
--  handle: 事件控制器？
--  viewWidth: 宽度
--  viewHeight: 高度
--  dire: direction 方向 0:横向 1:竖向
--	page:是否翻页 0:正常滑动 1:每次滑动一页
--  }
 ]] --
function ui.createLuaTableView(args)
	args = args or {
		viewwidth = 0,
		viewheight = 0,
		dire = 1,
		page = 0
	}

	local tableview = LuaTableView:createWithHandler(args.handle, CCSizeMake(args.viewwidth or 0, args.viewheight or 0), nil,
		CCString:create("" .. (args.dire or 1) .. (args.page or 0)))

	return tableview
end

--节点对象创建方法
function ui.createNode(args)
	args = args or {
		w = 0,
		h = 0,
		ax = 0,
		ay = 0,
		x = 0,
		y = 0,
        scale = 1,
	}

	local node = CCNode:create()
	node:setContentSize(CCSizeMake(args.w or 0, args.h or 0))
	node:setAnchorPoint(ccp(args.ax or 0, args.ay or 0))
	node:setPosition(ccp(args.x or 0, args.y or 0))
	node:setScale(args.scale or 1)

	return node
end


-- todo merge function loadCCBByName()
--- Load ccb by name, return device screen size fitted ccb.
-- @param ccbName CCB Base name
-- @return 1 layer, 2 ccbDocumentControler. layer:New layer contains ccbLayer; ccbDocumentControler
function ui.loadCCB(ccbName)
	local sceneLayer = CCLayer:create()
	local layer, ccbDocumentControler = CCBReaderLoad(getCCBRealNameByBaseName(ccbName))
	sceneLayer:addChild(layer)
	return sceneLayer, ccbDocumentControler
end


function ui.createTableViewCell(sprit, lable)
	assert(sprit or lable, "Both of sprip and lable is nil.")

	local tableViewCell = CCTableViewCell:create()
	if sprit then tableViewCell:addChild(sprit) end
	if lable then tableViewCell:addChild(lable) end
	return tableViewCell
end


--creat input editbox by layer, node and mode

--[[  mode desc:
kEditBoxInputModeAny : The user is allowed to enter any text, including line breaks.
kEditBoxInputModeEmailAddr : The user is allowed to enter an e-mail address.
kEditBoxInputModeNumeric : The user is allowed to enter an integer value.
kEditBoxInputModePhoneNumber : The user is allowed to enter a phone number.
kEditBoxInputModeUrl : The user is allowed to enter a URL.
kEditBoxInputModeDecimal : The user is allowed to enter a real number value. This extends kEditBoxInputModeNumeric by allowing a decimal point.
kEditBoxInputModeSingleLine : The user is allowed to enter any text, except for line breaks. ]] --

local function strFilterByChar( str )

    local step = 1
    local len = #str
    print("len====",len)

    local newstr = ""
    while step <= len do
        local byte = tonumber(string.byte(string.sub(str,step,step)))
        local bytenum = 1
        if byte<=127 then
            bytenum = 1
        elseif byte>=192 and byte<=223 then
            bytenum = 2
        elseif byte>=224 and byte<=239 then
            bytenum = 3
        elseif byte>=240 and byte<=247 then
            bytenum = 4
        elseif byte>=248 and byte<=251 then
            bytenum = 5
        elseif byte>=252 and byte<=253 then
            bytenum = 6
        end

        step = step + bytenum

        local showstr = ""

        if byte==32   --空格
            or byte==42 --*
            or byte==47 --/
            or byte==10 --换行
            or byte==13 --回车
            then
        else
            showstr = string.sub(str,step-bytenum,step-1)
        end
        local temp = newstr
        temp = temp..showstr
        newstr = temp
    end
    return newstr
end

local function checksensitiveWord(str)
    
    local newstr = string.lower(strFilterByChar(str))
    if gameConfig.sensitiveWord and next(gameConfig.sensitiveWord) then
        for k,v in pairs(gameConfig.sensitiveWord)do
            local newv = string.lower(v)
            if ui.contains(newstr,newv) then
                print(newv)
                return true
            end
        end
    end
    return false
end

function checkName(name)
    print("checkname")
    local step = 1
    local len = #name

    while step <= len do
        print(step)
        local n,j = string.find(string.sub(name,step,step),"%w")

        if n then
            step =step +1
        else
            local num = 0
            for i = 0,2 do
                if step >len then return true end
                if i== 0 then
                    num = num + (tonumber(string.byte(string.sub(name,step,step)) -224) * 2^(6 * (2-i)))
                else
                    num = num + (tonumber(string.byte(string.sub(name,step,step)) -128) * 2^(6 * (2-i)))
                end
                step = step+1
            end

            if num >= 0x4e00 and num <= 0x9fa5 then
            else
                return true
            end
        end
    end

    return false
end

local function removeMoreThan3Byte(str)
    local newstr = ""

    local len = #str;
    local left = len;
    local cnt = 0;
    local lualen = 0
    local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
    while left ~= 0 do
        local tmp=string.byte(str,-left);
        local i=#arr;
        while arr[i] do
            if tmp>=arr[i] then left=left-i;break;end
            i=i-1;
        end

        local tempstr = newstr
        if i<=3 then
            newstr = tempstr..string.sub(str,lualen+1,lualen+i)
        else
            newstr = tempstr.."?"
        end

        lualen=lualen+i
    end
    return newstr
end

function ui.getTextLength(str)
    local _, count = string.gsub(str, "[^\128-\193]", "")
    return count
end

function ui.strFilter( str )
    print("strFilter ",str)

    local step = 1
    local len = #str
    print("len====",len)

    local newstr = ""

    local firstbyte = {
        [1] = 0,
        [2] = 192,
        [3] = 224,
        [4] = 240,
        [5] = 248,
        [6] = 252,
    }

    while step <= len do
        local byte = tonumber(string.byte(string.sub(str,step,step)))
        local bytenum = 1
        if byte<=127 then
            bytenum = 1
        elseif byte>=192 and byte<=223 then
            bytenum = 2
        elseif byte>=224 and byte<=239 then
            bytenum = 3
        elseif byte>=240 and byte<=247 then
            bytenum = 4
        elseif byte>=248 and byte<=251 then
            bytenum = 5
        elseif byte>=252 and byte<=253 then
            bytenum = 6
        end

        print("bytenum===",bytenum)

        local unicode = 0
        for i=1,bytenum do

            local bytecode = tonumber(string.byte(string.sub(str,step,step)))

            print("bytecode===",i,bytecode)
            if i==1 then
                unicode = unicode + (bytecode-firstbyte[bytenum])*2^(6*(bytenum-i))
            else
                unicode = unicode + (bytecode-128)*2^(6*(bytenum-i))
            end
            step = step + 1
        end

        local needfilter = false

        if unicode >= 0x0000 and unicode <= 0x007f then  -- 英文，数字，标点符号（含印尼文）
        elseif unicode >= 0x3000 and unicode <= 0x9fa5 then --中文,日文,韩文
        elseif unicode >= 0x0080 and unicode <= 0x024f then --拉丁文扩展
        elseif unicode >= 0x1e00 and unicode <= 0x1eff then --拉丁文扩展（含越南文）
        elseif unicode >= 0x2000 and unicode <= 0x206f then --常用标点
        elseif unicode >= 0x2c60 and unicode <= 0x2c7f then --拉丁文扩展
        elseif unicode >= 0xa720 and unicode <= 0xa7ff then --拉丁文扩展
        elseif unicode >= 0x0e00 and unicode <= 0x0e7f then --泰文
        elseif unicode >= 0xff00 and unicode <= 0xffef then --半型及全型形式
        else
            needfilter = true
        end

        local showstr = needfilter and "?" or string.sub(str,step-bytenum,step-1)
        print("showstr==",showstr,"realstr=",string.sub(str,step-bytenum,step-1),"unicode==",unicode)

        local temp = newstr
        temp = temp..showstr
        newstr = temp
    end

    print("strFilter end",newstr)
    return newstr
end

local function checkLength(str_,length)

    local str = ui.strFilter(str_)

    local len = #str;
    local left = len;
    local cnt = 0;
    local lualen = 0
    local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
    while left ~= 0 do
        local tmp=string.byte(str,-left);
        local i=#arr;
        while arr[i] do
            if tmp>=arr[i] then left=left-i;break;end
            i=i-1;
        end
        if i==3 then
            cnt=cnt+2;
        else
            cnt=cnt+1;
        end

        if cnt<=length then
            lualen=lualen+i
        end

    end

    return cnt>length, string.sub(str,1,lualen);
end

function ui.removeInputEditBox(inputEditBox)
	if (inputEditBox ~= nil) then
		inputEditBox:removeFromParentAndCleanup(true)
		inputEditBox = nil
	end
end

-------------------
----strFmt = string.format("editBox %p DidBegin !", edit)
----strFmt = string.format("editBox %p DidEnd !", edit)
----strFmt = string.format("editBox %p was returned !", edit)
----strFmt = string.format("editBox %p TextChanged, text: %s ", edit, edit:getText())
-------------------

-- 向下取整
function ui.getIntPart(x)
    if x <= 0 then
       return math.ceil(x);
    end

    if math.ceil(x) == x then
       x = math.ceil(x);
    else
       x = math.ceil(x) - 1;
    end

    return x
end

function ui.creatInputEditBoxForNum(node,label,touchPriority,callback)

    local string = 0

    local inputcontent = ""
    local beginFunc = function()
        string = label:getString()
        
        label:setString("")
    end

    local endFunc = function(text,edit)
        
        edit:setText("")

        if tonumber(text) then
            local num = ui.getIntPart(tonumber(text))
            if num <= 0 then
                num = 1
            end
            callback(num)
        else
            runGamePrompt({msg=gameConfig.strings:string_common("ui",73)})
            label:setString(string)
        end
    end

    local input = ui.creatInputEditBoxByNode(node, kEditBoxInputModePhoneNumber, beginFunc, endFunc,
        {
            fontSize = 33,
            fontColor = label:getColor(),
            -- PlaceHolder = "点击输入",
            PlaceHolder = "",
            length = 3,
        })
    input:setTouchPriority(touchPriority)
end

function ui.creatInputEditBoxByNode(node, mode, beginfunc, endfunc, arg)

    local args = arg or {}

    local inputEditBox = nil --聊天输入框
    local function editBoxTextEventHandle(strEventName, pSender)
        local edit = tolua.cast(pSender, "CCEditBox")
        local strFmt
        if strEventName == "began" then
            beginfunc(edit:getText())
        elseif strEventName == "ended" then
            if args.extSensitiveWord then
                for k,v in pairs(args.extSensitiveWord) do
                    if string.find(edit:getText(),v) then
                        runGamePrompt({msg=gameConfig.strings:string_common("ui",0)})
                        edit:setText("")
                        return
                    end
                end
            end
            if not args.nochecksensitive and checksensitiveWord(edit:getText()) then
                print("sensitiveWord ",edit:getText())
                -- runGamePrompt({msg="输入含有敏感词，请重新输入"})
                runGamePrompt({msg=gameConfig.strings:string_common("ui",0)})
                edit:setText("")
            else
                local istoolong, restStr = checkLength(edit:getText(), args.length or 60)
                if istoolong then
                    -- runGamePrompt({msg="输入过多，多余内容已舍去"})
                    runGamePrompt({msg=gameConfig.strings:string_common("ui",1)})
                end
                edit:setText(restStr)
                endfunc(restStr,edit)

            end
        elseif strEventName == "return" then

        elseif strEventName == "changed" then

            if arg.changed then
                arg.changed(edit)
            end

        end
    end

    inputEditBox = CCEditBox:create(CCSizeMake(node:getContentSize().width*guide.scaleNum,node:getContentSize().height*guide.scaleNum), CCScale9Sprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(gameConfig.images.alpha)))
    node:addChild(inputEditBox)

    inputEditBox:setScale(1/guide.scaleNum)
    inputEditBox:setAnchorPoint(ccp(0, 0))
    inputEditBox:setPosition(ccp(0, 0))

    inputEditBox:setFontName(args.fontNmae or "Helvetica-Bold")
    inputEditBox:setFontSize((args.fontSize or 48)*guide.scaleNum)
    inputEditBox:setFontColor(args.fontColor or ccc3(0, 0, 0))

    inputEditBox:setPlaceholderFontSize((args.fontSize or 48)*guide.scaleNum)
    -- inputEditBox:setPlaceHolder(args.PlaceHolder or "点击输入")
    inputEditBox:setPlaceHolder(args.PlaceHolder or gameConfig.strings:string_common("ui",2))
    inputEditBox:setPlaceholderFontColor(args.PlaceholderFontColor or ccc3(100, 100, 100))

    inputEditBox:setMaxLength(args.length or 60)
    inputEditBox:setReturnType(kKeyboardReturnTypeDone)
    --设置输入模式
    inputEditBox:setInputMode(mode)
    --Handler
    inputEditBox:registerScriptEditBoxHandler(editBoxTextEventHandle)

    inputEditBox:setText(args.text or "")

    return inputEditBox
end

function ui.creatInputEditBoxBylable(label, mode, beginfunc, endfunc, arg)
    local args = arg or {}

    local inputEditBox = nil --聊天输入框

    local function editBoxTextEventHandle(strEventName, pSender)
        local edit = tolua.cast(pSender, "CCEditBox")
        local strFmt
        if strEventName == "began" then
            print("editBox %p DidBegin !")
            if beginfunc then
                beginfunc(label,edit)
            end
        elseif strEventName == "ended" then
            print("editBox %p DidEnd !")
            if args.extSensitiveWord then
                for k,v in pairs(args.extSensitiveWord) do
                    if string.find(edit:getText(),v) then
                        runGamePrompt({msg=gameConfig.strings:string_common("ui",0)})
                        edit:setText("")
                        return
                    end
                end
            end

            if not args.nochecksensitive and checksensitiveWord(edit:getText()) then
                print("sensitiveWord ",edit:getText())
                -- runGamePrompt({msg="输入含有敏感词，请重新输入"})
                runGamePrompt({msg=gameConfig.strings:string_common("ui",0)})
                edit:setText("")
            else
                local istoolong, restStr = checkLength(edit:getText(), args.length or 60)
                if istoolong then
                    -- runGamePrompt({msg="输入过多，多余内容已舍去"})
                    runGamePrompt({msg=gameConfig.strings:string_common("ui",1)})
                end
                endfunc(label,restStr,edit)

            end
        elseif strEventName == "return" then

        elseif strEventName == "changed" then

        end
    end

    print("label:getDimensions().width,label:getDimensions().height",label:getDimensions().width,label:getDimensions().height)
    inputEditBox = CCEditBox:create(CCSizeMake(label:getDimensions().width*guide.scaleNum,label:getDimensions().height*guide.scaleNum), CCScale9Sprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(gameConfig.images.alpha)))
    label:addChild(inputEditBox)

    inputEditBox:setScale(1/guide.scaleNum)
    inputEditBox:setAnchorPoint(ccp(0,0))
    inputEditBox:setPosition(ccp(0, 0))

    inputEditBox:setFontName(args.fontName or "Helvetica-Bold")
    inputEditBox:setFontSize((args.fontSize or 48)*guide.scaleNum)
    inputEditBox:setFontColor(args.fontColor or ccc3(0, 0, 0))

    inputEditBox:setPlaceholderFontSize((args.fontSize or 48)*guide.scaleNum)
    inputEditBox:setPlaceHolder(args.PlaceHolder or "")
    inputEditBox:setPlaceholderFontColor(args.PlaceholderFontColor or ccc3(100, 100, 100))

    inputEditBox:setMaxLength(args.length or 60)
    inputEditBox:setReturnType(kKeyboardReturnTypeDone)
    --设置输入模式
    inputEditBox:setInputMode(mode)
    --Handler
    inputEditBox:registerScriptEditBoxHandler(editBoxTextEventHandle)

    return inputEditBox
end

function ui.isValidEmail(str)
    if string.len(str or "") < 6 then
        return false
    end
    local b, e = string.find(str or "", '@')
    local bstr = ""
    local estr = ""
    if b then
        bstr = string.sub(str, 1, b - 1)
        estr = string.sub(str, e + 1, -1)
    else
        return false
    end

    -- check the string before '@'
    local p1, p2 = string.find(bstr, "[%w_]+")
    if (p1 ~= 1) or (p2 ~= string.len(bstr)) then return false end

    -- check the string after '@'
    if string.find(estr, "^[%.]+") then return false end
    if string.find(estr, "%.[%.]+") then return false end
    if string.find(estr, "@") then return false end
    if string.find(estr, "[%.]+$") then return false end

    _, count = string.gsub(estr, "%.", "")
    if (count < 1) or (count > 3) then
        return false
    end

    return true
end


function ui.countnum(label,from,to,time,param,cb)

    local step = time/0.05
    local stepnum = (to-from)/step


    local countfrom = from
    local timer = 0

    timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        countfrom = countfrom+stepnum
        if  math.ceil(countfrom) <=to then
            label:setString(param..math.floor(countfrom))
        else
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(timer)
            if cb then cb() end
        end
    end, 0.05, false)
    return timer
end

function ui.setGeneralIconL(dataTable,itemTable,id,noeffect)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    if  dataTable.quality ~= nil then
        setSpriteFrameByName(itemTable["g_quality"..key_Ex], gameConfig.images["l_g_q_back_"..dataTable.quality])
    end

    if dataTable.icon ~= "" then
        setSpriteFrameByName(itemTable["g_icon"..key_Ex],dataTable["icon"])
    end

    itemTable["g_level"..key_Ex]:setString("等级. "..dataTable.level)
    --ui.setLabelString(itemTable["g_name"..key_Ex],(dataTable.name == "主角" and GameScene.roleinfo.name or dataTable.name)..(dataTable.level2>0 and " +"..dataTable.level2 or ""), dataTable.quality and 2*dataTable.quality or 1)
    if dataTable.quality and dataTable.quality >= 7 then
        ui.setLabelString(itemTable["g_name"..key_Ex],(dataTable.name == gameConfig.strings:string_common("ui",3) and GameScene.roleinfo.name or dataTable.name)..(dataTable.level2>0 and " +"..dataTable.level2 or ""), 214)
    else    
        ui.setLabelString(itemTable["g_name"..key_Ex],(dataTable.name == gameConfig.strings:string_common("ui",3) and GameScene.roleinfo.name or dataTable.name)..(dataTable.level2>0 and " +"..dataTable.level2 or ""), dataTable.quality and 2*dataTable.quality or 1)
    end

    if not dataTable.awakenicon then
        setSpriteFrameByName(itemTable["g_juexing_iocn"..key_Ex],gameConfig.images.alpha)
    else
        setSpriteFrameByName(itemTable["g_juexing_iocn"..key_Ex],dataTable.awakenicon)
    end

    if not dataTable.awakenstage then
        ui.setLabelString(itemTable["g_juexing_stage"..key_Ex],"",18)
    else
        ui.setLabelString(itemTable["g_juexing_stage"..key_Ex],dataTable.awakenstage,18)
    end

    if not noeffect then
        if dataTable.exp >0 then
            local cb = nil
            if dataTable.levelup ==1  then
                cb = function()
                    local ccb,item = CCBReaderLoad("UIEffect/huobanshengji/huobanshengji.ccbi", nil, true, "huobanshengji")
                    itemTable["g_levelupnode"..key_Ex]:addChild(ccb)
                end
            end

            return ui.countnum(itemTable["g_exp"..key_Ex],0,dataTable.exp,0.5,"+",cb)
        elseif dataTable.exp ==0 and dataTable.exchange and dataTable.exchange == 1 then
            itemTable["g_exp"..key_Ex]:setString("+0")
        else
            itemTable["g_exp"..key_Ex]:setString("MAX")
        end
    else
        itemTable["g_exp"..key_Ex]:setString(dataTable.exp>0 and "+0" or "MAX")
    end

end

function ui.generalExpCount(dataTable,itemTable,id)

    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end
    local cb = nil
    if dataTable.levelup ==1  then
        cb = function()
            local ccb,item = CCBReaderLoad("UIEffect/huobanshengji/huobanshengji.ccbi", nil, true, "huobanshengji")
            itemTable["g_levelupnode"..key_Ex]:addChild(ccb)
        end
    end

    return ui.countnum(itemTable["g_exp"..key_Ex],0,dataTable.exp,0.5,"+",cb)
end

function ui.setUserProfile( item,data,id )
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    local config = ui.IDconfig(data.cid) 

    setSpriteFrameByName(item["i_soulsprite"..key_Ex], "alpha")

    if (config.staffType=="general" or config.staffType == "general_fragment") and config.quality ==5 and config.basic >=18 then
        setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk5_"..config.basic )
    else
        setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk"..(config.quality or 0))
    end

    setSpriteFrameByName(item["i_quality"..key_Ex], "b_iconbg"..(config.quality or 0))

    setSpriteFrameByName(item["i_icon"..key_Ex], config.icon and config.icon or "alpha")
    ui.setSpriteTextureRect(item["i_icon"..key_Ex],0,0,150,150)
end


--描边
function ui.createStroke(label, size, color,isGray)

    local x = label:getContentSize().width + size * 2
    local y = label:getContentSize().height + size * 2
    local rt = CCRenderTexture:create(x, y)

    local originalAnchorPoint = label:getAnchorPoint()
    local originalPosX = label:getPositionX()
    local originalPosY = label:getPositionY()
    local originalColor = label:getColor()
    local originalBlend = label:getBlendFunc()

    label:setColor(isGray and ccc3(0,0,0) or color)
    local tBlendFunc = ccBlendFunc:new()
    tBlendFunc.src = 1 --GL_ONE
    tBlendFunc.dst = 0x0303 --GL_ONE_MINUS_SRC_ALPHA
    label:setBlendFunc(originalBlend)
    local center = ccp(x / 2 , y / 2 )
    rt:begin()
    for i = 0, 360, 30 do
        local _x = center.x + math.sin((i) * 0.01745329252) * size
        local _y = center.y + math.cos((i) * 0.01745329252) * size

        label:setAnchorPoint(ccp(0.5,0.5))
        label:setPosition(ccp(_x, _y))
        label:visit()
    end
    label:setPosition(center)
    label:setColor(isGray and ccc3(255,255,255) or originalColor)
    label:setBlendFunc(originalBlend)
    label:visit()
    rt:endToLua()

    label:setPosition(ccp(originalPosX, originalPosY))
    rt:setAnchorPoint(originalAnchorPoint)
    rt:setPosition(ccp(originalPosX, originalPosY))
    label:getParent():addChild(rt)

    return rt
end

----label:label对象
----str: 显示内容， 为空则只对当前显示内容加阴影
----size:{x,y} 阴影偏移量
----opacity 阴影透明度
----blur: 阴影模糊度

local shadowparams = {
    [1] = {x = 0, y = 0, o = 255, blur = 1},
    [2] = {x = 0, y = 0, o = 127, blur = 10},
    [3] = {x = 0, y = 0, o = 160, blur = 3}, --quality
}

local strokeparams = {
    [1] = {color = ccc3(63,34,13), size = 2,},
    [2] = {color = ccc3(63,34,13), size = 4,},
    [3] = {color = ccc3(63,34,13), size = 6,},
    [4] = {color = ccc3(63,34,13), size = 8,},
    [5] = {color = ccc3(95,45,2), size = 2,},    -- quality1
    [6] = {color = ccc3(2,54,22), size = 2,},    -- quality2
    [7] = {color = ccc3(2,50,114), size = 2,},   -- quality3
    [8] = {color = ccc3(71,0,77), size = 2,},    -- quality4
    [9] = {color = ccc3(77,0,0), size = 2,},     -- quality5
    [10] = {color = ccc3(3,35,67), size = 2,},    -- coin
    [11] = {color = ccc3(35,35,35), size = 2,},   -- name
    [12] = {color = ccc3(77,18,18), size = 2,},
    [13] = {color = ccc3(0,0,0), size = 3,},
    [14] = {color = ccc3(16,14,15), size = 3,},
    [15] = {color = ccc3(91,0,0), size = 3,},
    [16] = {color = ccc3(11,66,2), size = 2,},
    [17] = {color = ccc3(43,24,16), size = 2,},
    [18] = {color = ccc3(35,6,0), size = 2,},
    [19] = {color = ccc3(8,51,95), size = 2,},
    [20] = {color = ccc3(47,28,0), size = 2,},
    [21] = {color = ccc3(0,36,91), size = 2,},

    [22] = {color = ccc3(56,20,20), size = 2,},

    [23] = {color = ccc3(56,14,14), size = 6,},
    [24] = {color = ccc3(20,39,16), size = 4,},
    [25] = {color = ccc3(87, 3,17), size = 6,},
    [26] = {color = ccc3(60,15,15), size = 6,},

    [27] = {color = ccc3(73,31,0), size = 1,},
    [28] = {color = ccc3(88,57,7), size = 2,},
    [29] = {color = ccc3(60,15,15), size = 3,},
    [30] = {color = ccc3(11,34,4), size = 3,},

    [31] = {color = ccc3(87,3,17), size = 3,},
    [32] = {color = ccc3(8,56,28), size = 3,},
    [33] = {color = ccc3(87,30,17), size = 3,},
    [34] = {color = ccc3(64,29,4), size = 3,},
    [35] = {color = ccc3(68,36,5),size = 3,},
    [36] = {color = ccc3(45,14,7),size = 3,},
    [37] = {color = ccc3(62,17,5),size = 3,},
    [38] = {color = ccc3(35,77,29),size = 3},
    [39] = {color = ccc3(96,39,11),size = 3},
    [40] = {color = ccc3(112,56,43),size = 4},
    [41] = {color = ccc3(68,36,5),size = 4},
    [42] = {color = ccc3(66,78,100),size = 3},

    [43] = {color = ccc3(113,65,28),size = 3},
    [44] = {color = ccc3(60,15,15),size = 3},
    [45] = {color = ccc3(50,27,10),size = 3},
    [46] = {color = ccc3(72,27,0),size = 3},
    [47] = {color = ccc3(90,50,32),size = 3},

    [48] = {color = ccc3(87,30,17),size = 3},
    [49] = {color = ccc3(18,94,52),size = 3},
    [50] = {color = ccc3(23,61,97),size = 3},
    [51] = {color = ccc3(121,44,150),size = 3},
    [52] = {color = ccc3(167,56,9),size = 3},
    [53] = {color = ccc3(139,15,11),size = 3},

    [54] = {color = ccc3(63,14,15),size = 4},

    --神器一键打造 name
    [55] = {color = ccc3(230,203,209),size = 3},

    [56] = {color = ccc3(78,45,0),size = 4},

    [61] = {color = ccc3(32,15,20), size = 2,},     -- quality7
    [62] = {color = ccc3(105,58,47), size = 4},
    [63] = {color = ccc3(139,68,10), size = 6,},
    [64] = {color = ccc3(75,37,37), size = 3},
    [65] = {color = ccc3(21, 132, 99), size = 3},
    [66] = {color = ccc3(44, 79, 149), size = 3},
    [67] = {color = ccc3(224, 85, 42), size = 3},
    [68] = {color = ccc3(140, 67, 22), size = 3},
    [69] = {color = ccc3(0,72,92), size = 4},
    
    [138] = {color = ccc3(2,25,91), size = 2,},
    [139] = {color = ccc3(2,25,91), size = 2,},

    [1100] = {color = ccc3(55,8,8), size = 4},

       
    [140] = {color = ccc3(0, 0, 0), size = 2},
}

local labelparams = {
    [1] = {color = ccc3(249,202,153), fontsize = 38},  -- quality1
    [2] = {color = ccc3(249,202,153), fontsize = 29},  -- quality1
    [3] = {color = ccc3(93, 227,90 ), fontsize = 38},  -- quality2
    [4] = {color = ccc3(93, 227,90 ), fontsize = 29},  -- quality2
    [5] = {color = ccc3(121,203,255), fontsize = 38},  -- quality3
    [6] = {color = ccc3(121,203,255), fontsize = 29},  -- quality3
    [7] = {color = ccc3(226,111,255), fontsize = 38},  -- quality4
    [8] = {color = ccc3(226,111,255), fontsize = 29},  -- quality4
    [9] = {color = ccc3(255,132,0  ), fontsize = 38},  -- quality5
    [10] = {color = ccc3(255,132,0  ), fontsize = 29},  -- quality5

    [11] = {color = ccc3(255,252,209), fontsize = 29},
    [12] = {color = ccc3(255,252,209), fontsize = 32},

    [13] = {color = ccc3(255,255,255), fontsize = 29},
    [14] = {color = ccc3(255,255,255), fontsize = 34},

    [151] = {color = ccc3(115,66,25), fontsize = 29},
    [152] = {color = ccc3(115,66,25), fontsize = 34},
    [153] = {color = ccc3(115,66,25), fontsize = 39},

    [18] = {color = ccc3(255,255,255), fontsize = 44},
    [19] = {color = ccc3(255,255,255), fontsize = 50},

    [21] = {color = ccc3(247,200,71 ), fontsize = 37},

    [22] = {color = ccc3(127,226,79 ), fontsize = 29},
    [23] = {color = ccc3(127,226,79 ), fontsize = 34},
    [24] = {color = ccc3(255,8,8 ), fontsize = 29},

    [26] = {color = ccc3(84,255,8 ), fontsize = 29},
    [27] = {color = ccc3(255,8,8 ), fontsize = 29},

    [28] = {color = ccc3(211,211,211), fontsize = 39},
    [29] = {color = ccc3(211,211,211), fontsize = 33},
    [30] = {color = ccc3(211,211,211), fontsize = 29},
    [31] = {color = ccc3(57 ,198,81 ), fontsize = 33},
    [32] = {color = ccc3(227,60 ,21 ), fontsize = 38},
    [33] = {color = ccc3(215,242,255 ), fontsize = 40},
    [34] = {color = ccc3(227,205,127 ), fontsize = 35},
    [35] = {color = ccc3(227,205,127 ), fontsize = 29},
    [36] = {color = ccc3(138,192,255 ), fontsize = 35},
    [37] = {color = ccc3(255,255,255), fontsize = 40},

    [42] = {color = ccc3(203,91,0 ), fontsize = 29},
    [333] = {color = ccc3(255,255,0),fontsize = 29},
    [334] = {color = ccc3(255,255,255),fontsize = 29},
    [335] = {color = ccc3(169,169,169),fontsize = 29},

    [43] = {color = ccc3(255,0,0),fontsize = 38},
    [44] = {color = ccc3(255,0,0),fontsize = 29},
    [905] = {color = ccc3(135, 81, 25),fontsize = 36},
    [50] = {color = ccc3(255,255,255), fontsize = 40},
    [51] = {color = ccc3(115,253,255), fontsize = 34},
    [52] = {color = ccc3(255,251,0), fontsize = 34},
    [53] = {color = ccc3(0,0,0), fontsize = 34},

    [54] = {color = ccc3(255,255,255), fontsize = 36},
    [55] = {color = ccc3(255,237,154), fontsize = 36},
    [56] = {color = ccc3(84,182,74), fontsize = 31},
    [57] = {color = ccc3(254,255,189), fontsize = 31},
    [58] = {color = ccc3(255,255,255), fontsize = 38},
    [59] = {color = ccc3(255,255,255), fontsize = 38},
    [60] = {color = ccc3(255,255,255), fontsize = 32},
    [61] = {color = ccc3(129, 70, 31), fontsize = 28},

    [62] = {color = ccc3(255,230,163), fontsize = 30},
    [63] = {color = ccc3(255,230,163), fontsize = 36},
    [64] = {color = ccc3(120,238,84), fontsize = 32},

    [65] = {color = ccc3(57,206,107), fontsize = 32},
    [66] = {color = ccc3(255,255,255), fontsize = 42},
    [67] = {color = ccc3(255,255,132), fontsize = 36},

    [68] = {color = ccc3(84,255,8 ), fontsize = 36},
    [69] = {color = ccc3(255,8,8 ), fontsize = 36},
    [70] = {color = ccc3(255,227,167),fontsize = 32},
    [71] = {color = ccc3(77,255,85),fontsize = 38},
    [72] = {color = ccc3(115,66,25),fontsize = 38},
    [73] = {color = ccc3(24,122,59),fontsize = 38},
    [74] = {color = ccc3(255,237,154), fontsize = 34},
    [75] = {color = ccc3(255,231,174), fontsize = 36},
    [76] = {color = ccc3(255,227,167), fontsize = 32},
    [77] = {color = ccc3(255,240,196), fontsize = 38},
    --[78] = {color = ccc3(77,255,85), fontsize = 34},
    --[79] = {color = ccc3(9,151,93), fontsize = 32},
    --[80] = {color = ccc3(9,151,93), fontsize = 34},
    --[81] = {color = ccc3(255,0,0),fontsize = 44},



    --商会
    [78] = {color = ccc3(255,255,255), fontsize = 30},
    [79] = {color = ccc3(255,216,68), fontsize = 30},
    [80] = {color = ccc3(255,255,255), fontsize = 32},
    [81] = {color = ccc3(255,255,255), fontsize = 35},
    [82] = {color = ccc3(254,238,165), fontsize = 36},
    [83] = {color = ccc3(255,255,255), fontsize = 40},
    [84] = {color = ccc3(253,229,166), fontsize = 34},
    [85] = {color = ccc3(255,217,75), fontsize = 34},

    [111] = {color = ccc3(77,255,85), fontsize = 34},
    [112] = {color = ccc3(9,151,93), fontsize = 32},
    [113] = {color = ccc3(9,151,93), fontsize = 34},
    [114] = {color = ccc3(255,0,0),fontsize = 44},
    [115] = {color = ccc3(255,0,0),fontsize = 34},
    [116] = {color = ccc3(84,255,8),fontsize = 34},

    [127] = {color = ccc3(255,255,255),fontsize = 45},
    [128] = {color = ccc3(255,235,0),fontsize = 34},

    [131] = {color = ccc3(148,88,29),fontsize = 34},
    [132] = {color = ccc3(255,47,22),fontsize = 34},
    [133] = {color = ccc3(178,180,186),fontsize = 34},

    [138] = {color = ccc3(240,250,255),fontsize = 20},
    [139] = {color = ccc3(115,255,41),fontsize = 20},

    [1000] = {color = ccc3(0, 0, 0),fontsize = 29},
    [1001] = {color = ccc3(255,8,8 ), fontsize = 34},
    [1002] = {color = ccc3(121,121,121), fontsize = 29},
    [1003] = {color = ccc3(248,206,115), fontsize = 29},

    [1004] = {color = ccc3(253,250,196), fontsize = 36}, 

    [91] = {color = ccc3(254,141,168), fontsize = 38},  -- quality7
    [92] = {color = ccc3(254,141,168), fontsize = 29},  -- quality7

    [134] = {color = ccc3(255,225,106  ), fontsize = 38},

    [135] = {color = ccc3(249,208,88  ), fontsize = 37},
    [140] = {color = ccc3(197,224,255), fontsize = 31},
    [181] = {color = ccc3(107,69,55), fontsize = 44},
    [211] = {color = ccc3(247,200,71 ), fontsize = 44},
    [150] = {color = ccc3(247,200,71 ), fontsize = 32},
	
    [1008] = {color = ccc3(255, 242, 79), fontsize = 32},
    [1009] = {color = ccc3(255, 255, 255), fontsize = 32},

    [1010] = {color = ccc3(253,154,27), fontsize = 38},

    [1011] = {color = ccc3(32, 105, 29), fontsize = 36},
    [1012] = {color = ccc3(192, 44, 32), fontsize = 36},

    [1013] = {color = ccc3(121, 50, 0), fontsize = 29},
    [1014] = {color = ccc3(32, 105, 29), fontsize = 29},
    [1015] = {color = ccc3(254, 253, 185), fontsize = 29},

     --弹幕
    [1016] = {color = ccc3(0, 77, 111), fontsize = 29},    --蓝色弹幕 蓝色字
    [1017] = {color = ccc3(255,255,255), fontsize = 30},   --红色弹幕 白色字
    [1018] = {color = ccc3(4,58,40), fontsize = 34},     --黄色弹幕 深绿色字
    [1019] = {color = ccc3(236, 113, 102), fontsize = 29},   --蓝色弹幕人名 粉红
    [1020] = {color = ccc3(0, 253, 255), fontsize = 30},    --红色弹幕人名 青色 
    [1021] = {color = ccc3(95, 48, 15), fontsize = 34},    --黄色弹幕名 深棕色 

    [1022] = {color = ccc3(255, 255, 255), fontsize = 32},
    [1024] = {color = ccc3(192, 44, 32), fontsize = 36},
    [1026] = {color = ccc3(32, 105, 29), fontsize = 29},

    [1027] = {color = ccc3(249, 236, 219), fontsize = 34},
    [1028] = {color = ccc3(228, 226, 89), fontsize = 34},

    --倒计时用 白 绿 墨色描边
    [1029] = {color = ccc3(255, 255, 255), fontsize = 29},
    [1030] = {color = ccc3(0, 255, 0), fontsize = 29},

    [1031] = {color = ccc3(179, 102, 34), fontsize = 32},
    [1032] = {color = ccc3(37, 122, 45), fontsize = 32},
    [1033] = {color = ccc3(188, 163, 146), fontsize = 32},
    [1034] = {color = ccc3(255, 183, 0), fontsize = 32},
}   

local labelconfig = {
    [1] = {labelparam = 1, strokeparam = 5, shadowparam = 3},   -- quality1
    [2] = {labelparam = 2, strokeparam = 5, shadowparam = 3},   -- quality1
    [3] = {labelparam = 3, strokeparam = 6, shadowparam = 3},   -- quality2
    [4] = {labelparam = 4, strokeparam = 6, shadowparam = 3},   -- quality2
    [5] = {labelparam = 5, strokeparam = 7, shadowparam = 3},   -- quality3
    [6] = {labelparam = 6, strokeparam = 7, shadowparam = 3},   -- quality3
    [7] = {labelparam = 7, strokeparam = 8, shadowparam = 3},   -- quality4
    [8] = {labelparam = 8, strokeparam = 8, shadowparam = 3},   -- quality4
    [9] = {labelparam = 9, strokeparam = 9, shadowparam = 3},   -- quality5
    [10] = {labelparam = 10, strokeparam = 9, shadowparam = 3},   -- quality5

    [11] = {labelparam = 43, strokeparam = 22, shadowparam = 3},   -- quality6
    [12] = {labelparam = 44, strokeparam = 22, shadowparam = 3},   -- quality6

    [213] = {labelparam = 91, strokeparam = 61, shadowparam = 3},   -- quality7
    [214] = {labelparam = 92, strokeparam = 61, shadowparam = 3},   -- quality7

    [111] = {labelparam = 11, strokeparam = 12, shadowparam = nil},
    [121] = {labelparam = 12, strokeparam = 12, shadowparam = nil},

    [13] = {labelparam = 13, strokeparam = 13, shadowparam = nil},  --lv and num in icon
    [14] = {labelparam = 14, strokeparam = 13, shadowparam = nil},  --lv and num in icon

    [151] = {labelparam = 151, strokeparam = nil, shadowparam = nil},
    [151] = {labelparam = 151, strokeparam = nil, shadowparam = nil},
    [151] = {labelparam = 151, strokeparam = nil, shadowparam = nil},

    [18] = {labelparam = 18, strokeparam = 13, shadowparam = nil},     --button small
    [19] = {labelparam = 19, strokeparam = 14, shadowparam = nil},   --button big

    [21] = {labelparam = 21, strokeparam = 15, shadowparam = 3},      -- vip

    [22] = {labelparam = 22, strokeparam = 16, shadowparam = 3},      --label green small
    [23] = {labelparam = 23, strokeparam = 16, shadowparam = 3},      --label green big
    [24] = {labelparam = 24, strokeparam = 17, shadowparam = 3},      --label red

    [26] = {labelparam = 26, strokeparam = 15, shadowparam = nil},
    [27] = {labelparam = 27, strokeparam = 15, shadowparam = nil},

    [28] = {labelparam = 28, strokeparam = 13, shadowparam = nil},      --equiptype
    [29] = {labelparam = 29, strokeparam = 13, shadowparam = nil},      --yuan
    [30] = {labelparam = 30, strokeparam = 13, shadowparam = nil},
    [31] = {labelparam = 31, strokeparam = 13, shadowparam = nil},      --yuan jihuo

    [42] = {labelparam = 42, strokeparam = nil, shadowparam = nil},

    [46] = {labelparam = 33, strokeparam = 19, shadowparam = nil},
    [47] = {labelparam = 32, strokeparam = 18, shadowparam = 3},

    [48] = {labelparam = 34, strokeparam = 20, shadowparam = 3},
    [482] = {labelparam = 35, strokeparam = 20, shadowparam = 3},
    [49] = {labelparam = 36, strokeparam = 21, shadowparam = 3},
    [333] = {labelparam = 333,strokeparam = nil, shadowparam = nil},
    [334] = {labelparam = 334,strokeparam = nil, shadowparam = nil},
    [335] = {labelparam = 335,strokeparam = nil, shadowparam = nil},
    [905] = {labelparam = 905,strokeparam = nil, shadowparam = nil},
    [50] = {labelparam = 50, strokeparam = 15, shadowparam = 3},
    [51] = {labelparam = 51, strokeparam = 16, shadowparam = 3},
    [52] = {labelparam = 52, strokeparam = 16, shadowparam = 3},
    [53] = {labelparam = 53, strokeparam = 16, shadowparam = 3},

    [54] = {labelparam = 54, strokeparam = 23, shadowparam = nil},
    [55] = {labelparam = 55, strokeparam = 23, shadowparam = nil},
    [56] = {labelparam = 56, strokeparam = 24, shadowparam = nil},
    [57] = {labelparam = 57, strokeparam = 23, shadowparam = nil},
    [58] = {labelparam = 58, strokeparam = 23, shadowparam = nil},
    [59] = {labelparam = 59, strokeparam = 25, shadowparam = nil},
    [60] = {labelparam = 59, strokeparam = 26, shadowparam = nil},
    [61] = {labelparam = 60, strokeparam = 23, shadowparam = nil},
    [62] = {labelparam = 61, strokeparam = nil, shadowparam = nil},

    [63] = {labelparam = 62, strokeparam = 27, shadowparam = nil},
    [64] = {labelparam = 63, strokeparam = 28, shadowparam = nil},
    [65] = {labelparam = 58, strokeparam = 29, shadowparam = nil},
    [66] = {labelparam = 64, strokeparam = 30, shadowparam = nil},
    [67] = {labelparam = 58, strokeparam = 31, shadowparam = nil},

    [67] = {labelparam = 54, strokeparam = 31, shadowparam = nil},
    [68] = {labelparam = 65, strokeparam = 32, shadowparam = nil},
    [69] = {labelparam = 54, strokeparam = 29, shadowparam = nil},
    [70] = {labelparam = 50, strokeparam = 33, shadowParam = nil},
    [71] = {labelparam = 58, strokeparam = 33, shadowParam = nil},
    [72] = {labelparam = 66, strokeparam = 29, shadowParam = nil},
    [73] = {labelparam = 67, strokeparam = 34, shadowParam = nil},
    [74] = {labelparam = 14, strokeparam = 29, shadowParam = nil},
    [75] = {labelparam = 68, strokeparam = 15, shadowParam = nil},
    [76] = {labelparam = 69, strokeparam = 15, shadowParam = nil},
    [77] = {labelparam = 70, strokeparam = 35, shadowParam = nil},
    [78] = {labelparam = 71, strokeparam = 33, shadowParam = nil},
    [79] = {labelparam = 58, strokeparam = 36, shadowParam = nil},
    [80] = {labelparam = 50, strokeparam = 37, shadowParam = nil},
    [81] = {labelparam = 151, strokeparam = nil, shadowparam = nil},
    [82] = {labelparam = 72,strokeparam = nil,shadowparam = nil},
    [83] = {labelparam = 73,strokeparam = nil,shadowparam = nil},
    [84] = {labelparam = 74,strokeparam = 40,shadowparam = nil},
    [85] = {labelparam = 75,strokeparam = 37,shadowparam = nil},
    [86] = {labelparam = 76,strokeparam = 41,shadowparam = nil},
    [87] = {labelparam = 77,strokeparam = 42,shadowparam = nil},
    [88] = {labelparam = 152, strokeparam = nil, shadowparam = nil},
    --[89] = {labelparam = 59, strokeparam = 25, shadowparam = nil},
    --[90] = {labelparam = 78, strokeparam = 33, shadowParam = nil},
    --[91] = {labelparam = 79, strokeparam = 33, shadowParam = nil},
    --[92] = {labelparam = 80, strokeparam = 33, shadowParam = nil},
    --[93] = {labelparam = 81, strokeparam = 22, shadowParam = 3},

    --商会
    [89] = {labelparam = 78, strokeparam = 43, shadowparam = nil},
    [90] = {labelparam = 79, strokeparam = 43, shadowparam = nil},
    [91] = {labelparam = 54, strokeparam = 44, shadowparam = nil},
    [92] = {labelparam = 81, strokeparam = 45, shadowparam = nil},
    [93] = {labelparam = 82, strokeparam = 46, shadowparam = nil},
    [94] = {labelparam = 83, strokeparam = 33, shadowparam = nil},
    [95] = {labelparam = 84, strokeparam = 33, shadowparam = nil},
    [96] = {labelparam = 85, strokeparam = 47, shadowparam = nil},

    [97] = {labelparam = 81, strokeparam = 48, shadowparam = nil},
    [98] = {labelparam = 81, strokeparam = 49, shadowparam = nil},
    [99] = {labelparam = 81, strokeparam = 50, shadowparam = nil},
    [100] = {labelparam = 81, strokeparam = 51, shadowparam = nil},
    [101] = {labelparam = 81, strokeparam = 52, shadowparam = nil},
    [102] = {labelparam = 81, strokeparam = 53, shadowparam = nil},

    [122] = {labelparam = 59, strokeparam = 25, shadowparam = nil},
    [123] = {labelparam = 111, strokeparam = 33, shadowParam = nil},
    [124] = {labelparam = 112, strokeparam = 33, shadowParam = nil},
    [125] = {labelparam = 113, strokeparam = 33, shadowParam = nil},
    [126] = {labelparam = 114, strokeparam = 22, shadowParam = 3},

    [127] = {labelparam = 127, strokeparam = 54, shadowParam = nil},
    [128] = {labelparam = 128, strokeparam = 13, shadowParam = nil},

    [129] = {labelparam = 50, strokeparam = 13, shadowParam = nil},

    --神器一键打造name
    [130] = {labelparam = 54, strokeparam = 55, shadowParam = nil},


    [131] = {labelparam = 131, strokeparam = nil, shadowParam = nil},
    [132] = {labelparam = 132, strokeparam = nil, shadowParam = nil},
    [133] = {labelparam = 133, strokeparam = nil, shadowParam = nil},

    [134] = {labelparam = 134, strokeparam = 56, shadowParam = nil},
    [135] = {labelparam = 115, strokeparam = 22, shadowParam = 3},
    [136] = {labelparam = 116, strokeparam = 22, shadowparam = 3},
    [137] = {labelparam = 135, strokeparam = 62, shadowparam = nil},

    --白 绿 20
    [138] = {labelparam = 138, strokeparam = 138, shadowparam = nil}, 
    [139] = {labelparam = 139, strokeparam = 139, shadowparam = nil}, 

    [140] = {labelparam = 140, strokeparam = 140, shadowparam = nil},
    [181] = {labelparam = 181, strokeparam = nil, shadowparam = nil},
    [211] = {labelparam = 211, strokeparam = 15, shadowparam = 3},
    [150] = {labelparam = 150, strokeparam = 15, shadowparam = 3}, 

    [1000] = {labelparam = 1000,strokeparam = nil, shadowparam = nil},
    [1001] = {labelparam = 1001, strokeparam = 16, shadowparam = nil},
    [1002] = {labelparam = 1002, strokeparam = nil, shadowparam = nil},
    [1003] = {labelparam = 1003, strokeparam = nil, shadowparam = nil},
    -- 未统计
    [1004] = {labelparam = 1004, strokeparam = 63, shadowparam = nil}, --橙色褐色描边 澡堂

    [1100] = {labelparam = 1100, strokeparam = 1100, shadowparam = nil},
    [1008] = {labelparam = 1008, strokeparam = 64, shadowparam = nil},   --黄字褐色描边
    [1009] = {labelparam = 1009, strokeparam = 64, shadowparam = nil},   --白字褐色描边
    [1010] = {labelparam = 1010, strokeparam = 64, shadowparam = nil},   --橙色字褐色描边

    [1011] = {labelparam = 1011, strokeparam = nil, shadowparam = nil},   --墨绿
    [1012] = {labelparam = 1012, strokeparam = nil, shadowparam = nil},   --暗红

    [1013] = {labelparam = 1013, strokeparam = nil, shadowparam = nil},   --褐色
    [1014] = {labelparam = 1014, strokeparam = nil, shadowparam = nil},   --绿
    [1015] = {labelparam = 1015, strokeparam = 64, shadowparam = nil},   --浅黄字褐色描边

    [1016] = {labelparam = 1016, strokeparam = nil, shadowparam = nil},    --蓝色弹幕 蓝色字
    [1017] = {labelparam = 1017, strokeparam = nil, shadowparam = nil},    --红色弹幕 白色字
    [1018] = {labelparam = 1018, strokeparam = nil, shadowparam = nil},    --黄色弹幕 深绿色字
    [1019] = {labelparam = 1019, strokeparam = nil, shadowparam = nil},    --蓝色弹幕人名 粉红
    [1020] = {labelparam = 1020, strokeparam = nil, shadowparam = nil},    --红色弹幕人名 青色 
    [1021] = {labelparam = 1021, strokeparam = nil, shadowparam = nil},    --黄色弹幕名 深棕色 

    [1022] = {labelparam = 1022, strokeparam = 65, shadowparam = nil},   --白字绿描边
    [1023] = {labelparam = 1022, strokeparam = 66, shadowparam = nil},   --白字蓝描边
    [1024] = {labelparam = 1024, strokeparam = 68, shadowparam = nil}, --黄字棕描边
    [1025] = {labelparam = 1024, strokeparam = 67, shadowparam = nil}, --黄字橙描边
    [1026] = {labelparam = 1026, strokeparam = 68, shadowparam = nil}, --黄字棕描边

    [1027] = {labelparam = 1027, strokeparam = 68, shadowparam = nil}, --浅白棕描边
    [1028] = {labelparam = 1028,strokeparam = 13,shadowparam = nil},  --橙字黑描边

    --倒计时用 白 绿 墨色描边
    [1029] = {labelparam = 1029, strokeparam = 69, shadowparam = nil},
    [1030] = {labelparam = 1030, strokeparam = 69, shadowparam = nil},

    --专属神器随机属性描述 棕色 绿色 未激活 器灵名称橙色
    [1031] = {labelparam = 1031, strokeparam = nil, shadowparam = nil},
    [1032] = {labelparam = 1032, strokeparam = nil, shadowparam = nil},
    [1033] = {labelparam = 1033, strokeparam = nil, shadowparam = nil},
    [1034] = {labelparam = 1034, strokeparam = nil, shadowparam = nil},

}

function ui.findlableSize(index)
    return labelparams[labelconfig[index].labelparam].fontsize
end

function ui.setStringWithShadow(label,str,paramindex)

    label = tolua.cast(label, "CCLabelTTF")

    if str then
        label:setString(str)
    end
    paramindex = paramindex or 1

    label:enableShadow(CCSizeMake(shadowparams[paramindex].x,shadowparams[paramindex].y), shadowparams[paramindex].o, shadowparams[paramindex].blur, true)
end

function ui.setStringWithStroke(label,str,paramindex,shadowparam)
    paramindex = paramindex or 1

    if paramindex > table.getTableLength(strokeparams) then
        paramindex = 1
    end

    local string = str or label:getString()
    label:setString(string)

    local stroke = label:getChildByTag(100)
    if not stroke  then
        stroke = ui.createLabel({
            text = string,
            color = strokeparams[paramindex].color,
            fontsize = label:getFontSize(),
            font = label:getFontName(),
            x = shadowparam and shadowparams[shadowparam].x or 0,--strokeparams[paramindex].size,
            y = gamedata.device.platform == "android" and (shadowparam and shadowparams[shadowparam].y or 0) or -strokeparams[paramindex].size*1.3,--strokeparams[paramindex].size,
            ax = 0,
            ay = 0,
            dw = label:getDimensions().width,
            dh = label:getDimensions().height,
            hAlignment = label:getHorizontalAlignment(),
            vAlignment = label:getVerticalAlignment()
        })

        label:addChild(stroke,-1,100)
        print("new Stroke")
    end
    --print("old Stroke")
    stroke = tolua.cast(stroke, "CCLabelTTF")
    stroke:setColor(strokeparams[paramindex].color)
    stroke:setFontSize(label:getFontSize())
    stroke:enableStroke(ccc3(0,0,0),strokeparams[paramindex].size,true)

    if string ~= stroke:getString() then
        stroke:setString(string)
    end
end

function ui.setStringWithStrokeAndShadow(label,str,strockparam,shadowparam)

    ui.setStringWithStroke(label,str,strockparam,shadowparam)
    local stroke = label:getChildByTag(100)
    ui.setStringWithShadow(stroke,str,shadowparam)
end

function ui.removeLabelStroke(label)
    local stroke = label:getChildByTag(100)
    if stroke then
        stroke:removeFromParentAndCleanup(true)
    end
end

function ui.setLabelString(label,str,typeindex,size)
    if not label then
        return
    end
    
    if not typeindex or not labelconfig[typeindex] then
        if str then
            label:setString(str)
        end
        return
    end

    if labelconfig[typeindex].labelparam then
        label:setColor(labelparams[labelconfig[typeindex].labelparam].color)
        label:setFontSize(size or labelparams[labelconfig[typeindex].labelparam].fontsize)
    end

    if labelconfig[typeindex].strokeparam and labelconfig[typeindex].shadowparam then
        ui.setStringWithStrokeAndShadow(label,str,labelconfig[typeindex].strokeparam,labelconfig[typeindex].shadowparam)
    elseif labelconfig[typeindex].strokeparam then
        ui.setStringWithStroke(label,str,labelconfig[typeindex].strokeparam,nil)
    elseif labelconfig[typeindex].shadowparam then
        ui.setStringWithShadow(label,str,labelconfig[typeindex].shadowparam)
    elseif str then
        label:setString(str)
    end

end

--function ui.setStringWithStroke(label,str,paramindex)
--    paramindex = paramindex or 1
--
--
--    local stroke = label:getChildByTag(1)
--    if not stroke or (str and tostring(str) ~= label:getString()) then
--        if str then label:setString(str) end
--        if stroke then label:removeChildByTag(1,true) end
--
--        local size = strokeparams[paramindex].size
--
--        local x = label:getContentSize().width + size * 2
--        local y = label:getContentSize().height + size * 2
--        local rt = CCRenderTexture:create(x, y)
--
--        print(x,y)
--
--        local originalAnchorPoint = label:getAnchorPoint()
--        local originalPosX = label:getPositionX()
--        local originalPosY = label:getPositionY()
--        local originalColor = label:getColor()
--        local center = ccp(x / 2 , y / 2 )
--
--        rt:begin()
--        label:setColor(strokeparams[paramindex].color)
--        label:enableStroke(ccc3(0,0,0),strokeparams[paramindex].size,true)
--        label:setAnchorPoint(ccp(0.5,0.5))
--        label:setPosition(ccp(center.x+size,center.y-size))
--        label:visit()
--
--
--        label:setColor(originalColor)
--        label:disableStroke(true)
--        label:setPosition(ccp(center.x,center.y))
--
--        label:visit()
--        rt:endToLua()
--
--        rt:setAnchorPoint(ccp(0.5,0.5))
--        rt:setPosition(ccp(center.x-size,center.y-size))
--
--        label:setAnchorPoint(originalAnchorPoint)
--        label:setPosition(originalPosX,originalPosY)
--
--        label:addChild(rt,1,1)
--    end
--end




function ui.makeSpriteDark(sprite)
    local dark = CCTintTo:create(0,120,120,120)
    sprite:runAction(dark)
end

function ui.addGray(type,item)
    if type == "CCSprite" then
        BYGraySprite:addGray(item)
    elseif type == "CCControlButton" then
        item:addGray()
    elseif type == "CCLabelTTF" then
        BYGraySprite:addGrayLabel(item)
    elseif type == "CCLabelBMFont" then
        BYGraySprite:addGrayLabelBM(item)
    elseif type == "CCNode" then
        if item.root then
            if item.g1 then
                local item_ = tolua.cast(item.g1, "CCNode")
                BYGraySprite:addGrayNode(item_)
            end
            if item.cl then
                local item_ = tolua.cast(item.cl, "CCNode")
                BYGraySprite:addGrayNode(item_)
            end
        else
            local item_ = tolua.cast(item, "CCNode")
            BYGraySprite:addGrayNode(item_)
        end
    end
end

function ui.removeGray(type,item)
    if type == "CCSprite" then
        BYGraySprite:removeGray(item)
    elseif type == "CCControlButton" then
        item:removeGray()
    elseif type == "CCLabelTTF" then
        BYGraySprite:removeGrayLabel(item)
    elseif type == "CCLabelBMFont" then
        BYGraySprite:removeGrayLabelBM(item)
    elseif type == "CCNode" then
        if item.root then
            if item.g1 then
                local item_ = tolua.cast(item.g1, "CCNode")
                BYGraySprite:removeGrayNode(item_)
            end
            if item.cl then
                local item_ = tolua.cast(item.cl, "CCNode")
                BYGraySprite:removeGrayNode(item_)
            end
        else
            local item_ = tolua.cast(item, "CCNode")
            BYGraySprite:removeGrayNode(item_)
        end
    end
end

function ui.setNodeRed(node,bool)
    if bool then
        BYGraySprite:makeNodeRed(node)
    else
        BYGraySprite:removeNodeRed(node)
    end
end


function ui.addProcessBar(parent,position,AnchorPoint,frame,persentage)

    local sprite = CCSprite:createWithSpriteFrameName(frame)
    local ProcessBar = CCProgressTimer:create(sprite)
    ProcessBar:setAnchorPoint(AnchorPoint or ccp(0.5, 0.5))
    ProcessBar:setType(kCCProgressTimerTypeBar)
    ProcessBar:setMidpoint(ccp(0, 0.5))
    ProcessBar:setBarChangeRate(ccp(1, 0))
    ProcessBar:setPosition(position or ccp(184, 107))
    ProcessBar:setPercentage(persentage)
    parent:addChild(ProcessBar)
    return ProcessBar

end

function ui.addProflayer(parent,touchPriority,Zorder,color,size,AnchorPoint,Position,callback,log,NoSwallows)
    local Proflayer = CCLayerColor:create(color)
    Proflayer:setContentSize(size or CCSizeMake(gamedata.device.SCREEN_WIDTH,gamedata.device.SCREEN_HEIGHT))
    Proflayer:setAnchorPoint(AnchorPoint or ccp(0,0))
    Proflayer:setPosition(position or ccp(0,0))
    parent:addChild(Proflayer,Zorder or 0)

    local tx,ty = 0,0
    local function ccTouchBegan(x, y)
        print((log or "ui prof").." clicked uiprof")
        tx,ty = x,y
        return true
    end

    local function ccTouchMoved(x, y) end

    local function ccTouchEnded(x, y)
        --closePopupWindow(indx)
        if math.abs(tx-x) < 30 and math.abs(ty-y) < 30 then
            if callback then callback(x, y) end
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

    Proflayer:registerScriptTouchHandler(onTouch, false, touchPriority,not NoSwallows)
    Proflayer:setTouchPriority(touchPriority)
    Proflayer:setTouchEnabled(true)
    return Proflayer
end


function ui.PushNotification(notifications,gamename)

    print("ui.PushNotification")
    CCNotificationManager:removeNotification()

    for k,v in pairs(notifications) do
        cclog("%s %s %d", v.message, v.time, v.repeats)
        CCNotificationManager:notification(v.message,v.time,v.repeats,gamename)
    end

end

function ui.makeTimeText(time,type)
    local hournum = (time ) / 3600
    local minutenum = (time % 3600) / 60
    local second=  time % 60
    local hour = hournum - hournum % 1
    local minute = minutenum - minutenum % 1
    if (tonumber(hour) <= 9) then if (string.len(tostring(hour)) == 1) then if (tonumber(hour) < 1) then hour = "00" else hour = 0 .. hour end end end
    if (tonumber(minute) <= 9) then if (string.len(tostring(minute)) == 1) then if (tonumber(minute) < 1) then minute = "00" else minute = 0 .. minute end end end
    if (tonumber(second) <= 9) then if (string.len(tostring(second)) == 1) then if (tonumber(second) < 1) then second = "00" else second = 0 .. second end end end

    if not type or type == "hour" then
        return  hour .. ":" .. minute .. ":" .. second
    elseif  type == "minute" then
        return   minute .. ":" .. second
    end

end

--天，时，分，秒
function ui.makeTimeDayText(time,type)
    local daynum = (time) / 86400
    local hournum = (time % 86400 ) / 3600
    local minutenum = (time % 3600) / 60
    local second=  time % 60
    local day = daynum - daynum % 1
    local hour = hournum - hournum % 1
    local minute = minutenum - minutenum % 1
    if (tonumber(day) <= 9) then if (string.len(tostring(day)) == 1) then if (tonumber(day) < 1) then day = "00" else day = 0 .. day end end end
    if (tonumber(hour) <= 9) then if (string.len(tostring(hour)) == 1) then if (tonumber(hour) < 1) then hour = "00" else hour = 0 .. hour end end end
    if (tonumber(minute) <= 9) then if (string.len(tostring(minute)) == 1) then if (tonumber(minute) < 1) then minute = "00" else minute = 0 .. minute end end end
    if (tonumber(second) <= 9) then if (string.len(tostring(second)) == 1) then if (tonumber(second) < 1) then second = "00" else second = 0 .. second end end end

    if not type or type == "day" then
        -- return  day .. "天" ..  hour .. "时" .. minute .. "分" .. second .. "秒"
        return gameConfig.strings:dayhourmSecond(day,hour,minute,second)
    elseif  type == "hour" then
        return   hour .. ":" .. minute .. ":" .. second
    elseif  type == "minute" then
        return   minute .. ":" .. second
    elseif type == "day2" then
        return   gameConfig.strings:dayhourmSecond2(day,hour,minute,second)
    elseif type == "day3" then
        return gameConfig.strings:xuanyueTreasuresDayhour(day,hour,minute,second)
    end
end

function ui.makeTimeDes(time,type)
    local daynum =  (time ) / (24*3600)
    local hournum = (time % (24*3600)) / 3600
    local minutenum = (time % 3600) / 60
    local second=  time % 60
    local day =  daynum - daynum % 1
    local hour = hournum - hournum % 1
    local minute = minutenum - minutenum % 1

    -- return (day~=0 and day.."天" or "")..((day~=0 or hour~=0) and hour.."小时" or "")..((day~=0 or hour~=0 or minute~=0) and minute.."分" or "")..second.."秒"
    return gameConfig.strings:dayHourSecond(day,hour,minute,second)
end

--返回时间不带秒数（天，小时，分钟）
function ui.makeTimeDes1(time,type)
    if time < 60 then
        -- return (1 .. "分钟"); 
        return gameConfig.strings:string_common("ui",4); 
    end
    local daynum =  math.floor((time ) / (24*3600))
    if daynum >= 1 then
        if daynum >= 30 then
            return "1个月前"
        else
            return daynum.."天前"
        end
    end
    local hournum = (time % (24*3600)) / 3600
    local minutenum = (time % 3600) / 60
    local day =  daynum - daynum % 1
    local hour = hournum - hournum % 1
    local minute = minutenum - minutenum % 1

    -- return (day~=0 and day.."天" or "")..((day~=0 or hour~=0) and hour.."小时" or "")..((day~=0 or hour~=0 or minute~=0) and minute.."分钟" or "")
    return gameConfig.strings:dayMinute(day,hour,minute)
end

function ui.makeTimeTable(time,type)
    local daynum =  (time ) / (24*3600)
    local hournum = (time % (24*3600)) / 3600
    local minutenum = (time % 3600) / 60
    local second=  time % 60
    local day =  daynum - daynum % 1
    local hour = hournum - hournum % 1
    local minute = minutenum - minutenum % 1
   return {day = day,hour = hour,minute = minute, second = second}
end

function ui.makeTimeText2(time,type)
    local daynum =  (time ) / (3600*24)
    local hournum = (time % (3600*24) ) / 3600
    local minutenum = (time % 3600) / 60
    local second=  time % 60
    local day =  daynum - daynum % 1
    local hour = hournum - hournum % 1
    local minute = minutenum - minutenum % 1

    if day > 0 then
        -- return day.."天"
        return gameConfig.strings:Day(day)
    elseif hour > 0 then
        -- return hour.."小时"
        return gameConfig.strings:hourNum(hour)
    elseif minute > 0 then
        -- return minute.."分钟"
        return gameConfig.strings:minuteNum(minute)
    else
        -- return time.."秒"
        return gameConfig.strings:secondNum(time)
    end
end

function ui.makeTimebefore(time)
    local hournum = (time % (3600*24) ) / 3600
    local minutenum = (time % 3600) / 60
    if time> 3600*24 then
        -- return "1天以上"
        return gameConfig.strings:string_common("ui",37)
    elseif time> 3600 then
        -- return (hournum - hournum % 1).."小时前"
        return gameConfig.strings:hourbf(hournum)
    elseif time> 60 then
        -- return (minutenum - minutenum % 1).."分钟前"
        return gameConfig.strings:minutebf(minutenum)
    else
        -- return "刚刚"
        return gameConfig.strings:string_common("ui",38)
    end

end

function ui.setSpriteTextureRect(sprite,originX,originY,width,height)
    local isrotated = sprite:isTextureRectRotated()

    local originx = sprite:getTextureRect().origin.x + originX
    local originy = sprite:getTextureRect().origin.y + originY

    local w = math.min(width,sprite:getTextureRect().size.width)
    local h = math.min(height,sprite:getTextureRect().size.height)
--    print(w,h)
--    print("sprite:getContentSize().width=",sprite:getContentSize().width,"sprite:getContentSize().height=",sprite:getContentSize().height)
    sprite:setTextureRect(CCRectMake(originx,originy,w,h),isrotated,CCSizeMake(w,h))

end

function ui.setSpriteTextureRect2(sprite,originX,originY,width,height)
    local isrotated = sprite:isTextureRectRotated()

    local originx = sprite:getTextureRect().origin.x + originX
    local originy = sprite:getTextureRect().origin.y + originY

--    local w = math.min(width,sprite:getContentSize().width)
--    local h = math.min(height,sprite:getContentSize().height)
    --    print(w,h)
    --    print("sprite:getContentSize().width=",sprite:getContentSize().width,"sprite:getContentSize().height=",sprite:getContentSize().height)

    print("setSpriteTextureRect2",originx,originy,width,height)
    sprite:setTextureRect(CCRectMake(originx,originy,width,height),isrotated,CCSizeMake(width,height))

end

function ui.isTouched(node,x,y)
    local point= node:convertToNodeSpace(ccp(x,y))
    local rect = CCRectMake(0,0,node:getContentSize().width,node:getContentSize().height)

    return rect:containsPoint(point)
end

function ui.iscontendbynode(node,x,y)
    if x >= node:getPositionX() - node:getContentSize().width*0.5 and
            x <= node:getPositionX() + node:getContentSize().width*0.5
        and y >= node:getPositionY() - node:getContentSize().height*0.5 and
            y <= node:getPositionY() + node:getContentSize().height*0.5 then

        return true
    end

    return false
end


function ui.g_goldConfig(num)

    local t = {
        cid = 1025,
        num = num,
        -- name = "仙元",
        name = gameConfig.strings:string_common("ui",74),
        icon = "0yuan",
        desc = "仙界特有的货币，可以购买仙界稀有资源。",
        quality = 5,
    }
   return t
end

function ui.coinConfig(num)

    local t = {
        cid = 1000,
        num = num,
        -- name = "银币",
        name = gameConfig.strings:string_common("ui",5),
        icon = "propcoin"
    }
    return t
end

function ui.goldConfig(num)

    local t = {
        cid = 1001,
        num = num,
        -- name = "元宝",
        name = gameConfig.strings:string_common("ui",6),
        icon = "propgold"
    }
   return t
end

function ui.wishpointConfig(num)

    local t = {
        cid = 1027,
        num = num,
        name = "祝福值",
        icon = "xuanyuejifen"
    }
   return t
end

function ui.wishpointConfig2(num)

    local t = {
        cid = 1029,
        num = num,
        name = "祝福值",
        icon = "xuanyuejifen"
    }
   return t
end

function ui.wishpointConfig3(num)

    local t = {
        cid = 1032,
        num = num,
        name = "祝福值",
        icon = "xuanyuejifen"
    }
   return t
end

function ui.yinghunConfig(num)

    local t = {
        cid = 1028,
        num = num,
        name = "英魂",
        icon = "yinghun"
    }
   return t
end

function ui.staminaConfig(num)

    local t = {
        cid = 1002,
        num = num,
        -- name = "体力",
        name = gameConfig.strings:string_common("ui",7),
        icon = ""
    }
    return t
end

function ui.energyConfig(num)

    local t = {
        cid = 1003,
        num = num,
        -- name = "精力",
        name = gameConfig.strings:string_common("ui",8),
        icon = ""
    }
    return t
end

function ui.stoneConfig(num)

    local t = {
        cid = 21000,
        num = num,
        -- name = "补天石",
        name = gameConfig.strings:string_common("ui",9),
        icon = "fudi_stone"
    }
    return t
end

function ui.prestigeConfig(num)    --诛仙台积分

    local t = {
        cid = 1004,
        num = num,
        -- name = "积分",
        name = gameConfig.strings:string_common("ui",11),
        icon = "b_sprite16"
    }
    return t
end

function ui.pointConfig(num)   --竞技场积分

    local t = {
        cid = 1005,
        num = num,
        name = "竞技场积分",
        -- name = gameConfig.strings:string_common("ui",11),
        icon = "jingjichangjifen",
        desc = "在竞技场商店中兑换稀有道具",
        quality = 5,
    }
    return t
end

function ui.gangpointConfig(num)    --个人贡献

    local t = {
        cid = 1006,
        num = num,
        name = "个人贡献",
        icon = "icon_gonghuijifen",
        desc = "在公会商店中兑换稀有道具",
        quality = 5
    }
    return t
end


function ui.gangexpConfig(num)    --公会经验
    --队伍经验
    local t = {
        cid = 1030,
        num = num,
        name = "公会经验",
        icon = "gonghui_jingyan",
        quality = 5,
    }
    return t
end

function ui.sculptureExpConfig(num)
    local t = {
        cid = 1033,
        num = num,
        name = "雕塑经验",
        icon = "diaosujingyan",
        quality = 5,
    }
    return t
end

function ui.generalexpConfig(num)    --上阵伙伴经验
    --上阵伙伴经验
    local t = {
        cid = 1031,
        num = num,
        name = "伙伴经验",
        icon = "zaizhenhuobanjingyan",
        quality = 5,
    }
    return t
end

function ui.yuanmingConfig(num)   --元命

    local t = {
        cid = 70000,
        num = num,
        -- name = "元命",
        name = gameConfig.strings:string_common("ui",12),
        icon = "yuanming"

    }
    return t
end

function ui.vipexpConfig(num)   --元命

    local t = {
        cid = 1008,
        num = num,
        name = "贵族经验",
        icon = "ach_vip"

    }
    return t
end

function ui.xiandouConfig(num)   --仙豆

    local t = {
        cid = 1013,
        num = num,
        name = "仙豆",
        icon = "xiandou",
        desc = "在仙豆大转盘中兑换稀有道具",
        quality = 5,

    }
    return t
end

function ui.championpointConfig(num)    --冠军试炼积分

    local t = {
        cid = 1009,
        num = num,
        name = "试炼点",
        icon = "shiliandian",
        desc = "在试炼商店中兑换装备进阶和升星相关道具",
        quality = 5,
    }
    return t
end

function ui.passkillcoinConfig(num)    --过关斩将币

    local t = {
        cid = 1007,
        num = num,
        name = "斩将币",
        icon = "zhanjiangbi",
        desc = "在斩将商店中兑换武将和主角进阶相关道具",
        quality = 5
    }
    return t
end

function ui.dragonboatpropConfig(num)    --赛龙舟

    local t = {
        cid = 1010,
        num = num,
        name = "绣球",
        icon = "xiuqiu"
    }
    return t
end

function ui.dumplingpropConfig(num)    --粽子

    local t = {
        cid = 1012,
        num = num,
        name = "粽子",
        icon = "zongzi"
    }
    return t
end

function ui.tigerchickenpointConfig(num)    --老虎机积分

    local t = {
        cid = 1014,
        num = num,
        name = "积分",
        icon = "hunpojifen"
    }
    return t
end

function ui.goddownpointConfig(num)    --天神下凡好感度

    local t = {
        cid = 1015,
        num = num,
        name = "好感度",
        icon = "love_ti"
    }
    return t
end

function ui.userexpConfig(num)    --队伍经验

    local t = {
        cid = 1017,
        num = num,
        name = "队伍经验",
        icon = "expicons"
    }
    return t
end

function ui.rechargescoreConfig(num)    --充值积分

    local t = {
        cid = 1019,
        num = num,
        name = "充值积分",
        icon = "hunpojifen"
    }
    return t
end

function ui.k_goddownpointConfig(num)    --跨服天神下凡好感度

    local t = {
        cid = 1020,
        num = num,
        name = "好感度",
        icon = "love_ti"
    }
    return t
end

function ui.gambingpointConfig(num)    --游戏机积分

    local t = {
        cid = 1021,
        num = num,
        name = "游戏机积分",
        icon = "youxijiicon"
    }
    return t
end

function ui.kingpointConfig(num)    --王者积分

    local t = {
        cid = 1023,
        num = num,
        name = "王者积分",
        icon = "wangzhezhizhanpoint"
    }
    return t
end

function ui.christmaspropConfig(num)    --圣诞

    local t = {
        cid = 1024,
        num = num,
        name = "灯会门票",
        icon = "denghuimenpaio"
        -- name = "圣诞帽",
        -- icon = "shengdanmao"
    }
    return t
end

function ui.platformcurrencyConfig(num)    --平台币
     

    local t = {
        cid = 1026,
        num = num,
        name = "牧游币",
        icon = "icon_muyoubi",
        desc = "牧游平台专属虚拟货币，在牧游旗下产品充值时使用。牧游币的剩余数量可在个人中心中查看。",
        quality = 5
    }
    return t
end

function ui.shengxianbiConfig(num)    --升仙币
    local t = {
        cid = 1044,
        num = num,
        name = "升仙币",
        icon = "shengxianbi",
        quality = 5
    }
    return t
end

function ui.xianyuConfig(num)    --仙玉
    local t = {
        cid = 1045,
        num = num,
        name = "升仙玉",
        icon = "xianyu",
        quality = 5
    }
    return t
end

function ui.IDconfig(_id,num)
    print("IDconfig",_id)
    local id = tonumber(_id)

    if not id then
        return {}
    elseif id == 1000 then
        return  table.merge(ui.coinConfig(num),{staffType = "coin"})
    elseif id == 1001 then
        return  table.merge(ui.goldConfig(num),{staffType = "gold"})
    elseif id == 1002 then
        return  table.merge(ui.staminaConfig(num),{staffType = "stamina"})
    elseif id == 1003 then
        return  table.merge(ui.energyConfig(num),{staffType = "energy"})
    elseif id == 1004 then
        return  table.merge(ui.prestigeConfig(num),{staffType = "prestige"})
    elseif id == 1005 then
        return  table.merge(ui.pointConfig(num),{staffType = "point"})
    elseif id == 1006 then
        return  table.merge(ui.gangpointConfig(num),{staffType = "gangpoint"})
    elseif id == 1007 then
        return  table.merge(ui.passkillcoinConfig(num),{staffType = "passkillcoin"})
    elseif id == 1008 then
        return  table.merge(ui.vipexpConfig(num),{staffType = "vipexp"})
    elseif id == 1009 then
        return  table.merge(ui.championpointConfig(num),{staffType = "championpoint"})
    elseif id == 1010 then
        return  table.merge(ui.dragonboatpropConfig(num),{staffType = "dragonboatprop"})
    elseif id == 1012 then
        return  table.merge(ui.dumplingpropConfig(num),{staffType = "dumplingprop"})
    elseif id == 1013 then
        return  table.merge(ui.xiandouConfig(num),{staffType = "xiandou"})
    elseif id == 1014 then
        return  table.merge(ui.tigerchickenpointConfig(num),{staffType = "tigerchickenpoint"})
    elseif id == 1015 then
        return  table.merge(ui.goddownpointConfig(num),{staffType = "goddownpoint"})
    elseif id == 1017 then
        return  table.merge(ui.userexpConfig(num),{staffType = "userexp"})
    elseif id == 1019 then
        return  table.merge(ui.rechargescoreConfig(num),{staffType = "rechargescore"})
    elseif id == 1020 then
        return  table.merge(ui.k_goddownpointConfig(num),{staffType = "k_goddownpoint"})
    elseif id == 1021 then
        return  table.merge(ui.gambingpointConfig(num),{staffType = "gambingpoint"})
    elseif id == 1023 then
        return  table.merge(ui.kingpointConfig(num),{staffType = "kingpoint"})
    elseif id == 1024 then
        return  table.merge(ui.christmaspropConfig(num),{staffType = "christmasprop"})
    elseif id == 1025 then
        return  table.merge(ui.g_goldConfig(num),{staffType = "g_gold"})
    elseif id == 1027 then
        return  table.merge(ui.wishpointConfig(num),{staffType = "wishpoint"})
    elseif id == 1028 then
        return  table.merge(ui.yinghunConfig(num),{staffType = "yinghun"})
    elseif id == 1029 then
        return  table.merge(ui.wishpointConfig2(num),{staffType = "wishpoint2"})
    elseif id == 1032 then
        return  table.merge(ui.wishpointConfig3(num),{staffType = "wishpoint3"})
    elseif id == 1026 then
        return  table.merge(ui.platformcurrencyConfig(num),{staffType = "platformcurrency"})
    elseif id == 1030 then
        return  table.merge(ui.gangexpConfig(num),{staffType = "gangexp"})
    elseif id == 1033 then
        return  table.merge(ui.sculptureExpConfig(num),{staffType = "sculptureexp"})
    elseif id == 1031 then
        return  table.merge(ui.generalexpConfig(num),{staffType = "generalexp"})
    elseif id == 1044 then
        return  table.merge(ui.shengxianbiConfig(num),{staffType = "shengxianbi"})
    elseif id == 1045 then
        return  table.merge(ui.xianyuConfig(num),{staffType = "xianyu"})
    elseif id == 21000 then
        return  table.merge(ui.stoneConfig(num),{staffType = "stone"})
    elseif id == 70000 then
        return  table.merge(gamedata.config.soul[tostring(70000)],{staffType = "yuanming"})
    elseif (id >= 10101 and id <= 11000) or (id >= 160001 and id <= 161000) or (id >= 170001 and id <= 171000) or (id >= 162001 and id <= 163000) or (id >= 164001 and id <= 165000) or (id >= 174001 and id <= 175000) then
        return   table.merge(gamedata.config.general[tostring(id)],{staffType = "general"})
    elseif (id >= 11101 and id <= 12000) or (id >= 161001 and id <= 162000) or (id >= 171001 and id <= 172000) or (id >= 163001 and id <= 164000) or (id >= 165001 and id <= 166000) or (id >= 175001 and id <= 176000) then
        return   table.merge(gamedata.config.general[tostring(gamedata.config.general_fragment[tostring(id)].general)],{staffType = "general_fragment"})
    elseif (id >= 12001 and id <= 12600) or (id >= 13501 and id <= 13726) or (id >= 180001 and id <= 183001) then
        return   table.merge(gamedata.config.skill[tostring(id)],{staffType = "skill"})
    elseif id >= 12601 and id <= 14000 then
        if (id >= 12607 and id <= 12621) or (id >= 12821 and id <= 12835) or (id >= 12842 and id <= 12856)  then
            return   table.merge(gamedata.config.combskill[tostring(id)],{staffType = "skill"})
        else
            return   table.merge(gamedata.config.combskill[tostring(id)],{staffType = "combskill"})
        end
    elseif id >= 14001 and id <= 15000 then
        return   table.merge(gamedata.config.generalanimation[tostring(id)],{staffType = "generalanimation"})
    elseif id >= 16001 and id <= 17000 then
        return    table.merge(gamedata.config.skillanimation[tostring(id)],{staffType = "skillanimation"})
    elseif id >= 18001 and id <= 19000 then
        return    table.merge(gamedata.config.redl_awake_item[tostring(id)],{staffType = "red_fragment"})
    elseif (id >= 20001 and id <= 21000) or (id >= 26407 and id <= 26414) then
        return    table.merge(gamedata.config.props[tostring(id)],{staffType = "props"})
    elseif id >= 191001 and id <= 200000 then
        return    table.merge(gamedata.config.props[tostring(id)],{staffType = "props"})
    elseif id >= 21001 and id <= 27000 then
        return    table.merge(gamedata.config.equip[tostring(id)],{staffType = "equip"})
    elseif id >= 27001 and id <= 28000 then
        local euqipconfig = gamedata.config.equip[tostring(gamedata.config.equip_fragment[tostring(id)].equip)]
        return    table.merge(gamedata.config.equip_fragment[tostring(id)],{staffType = "equip_fragment", type = euqipconfig.type,quality = euqipconfig.quality,icon = euqipconfig.icon,desc = euqipconfig.desc})
    elseif id >= 28001 and id <= 29000 then
        local selfconfig = gamedata.config.treasure2_fragment[tostring(id)]
        local fatherconfig
        if selfconfig.page == "meterial" then
            fatherconfig = gamedata.config.props[tostring(selfconfig.equip)]
        else
            fatherconfig = gamedata.config.equip[tostring(selfconfig.equip)]
        end
        if selfconfig.page == "meterial" then
            return    table.merge(gamedata.config.treasure2_fragment[tostring(id)],{staffType = "meterial_fragment",quality = fatherconfig.quality})
        else
            return    table.merge(gamedata.config.treasure2_fragment[tostring(id)],{staffType = "treasure_fragment",quality = fatherconfig.quality})
        end
    elseif id >= 29001 and id <= 30000 then 
        return     table.merge(gamedata.config.suit[tostring(id)],{staffType = "suit"})
    elseif (id >= 30001 and id <= 33000) or (id >= 42001 and id <= 43000) then
        local config = gamedata.config.general[tostring(gamedata.config.copy_monster[tostring(id)].generalid)]
        return table.merge(gamedata.config.copy_monster[tostring(id)],{staffType = "monster", icon = config.icon, animationid = config.animationid})
    elseif id > 33000 and id <= 33100 then
        return table.merge(gamedata.config.sigil[tostring(id)],{staffType = "sigil"})
    elseif id >= 44001 and id <= 45000 then --升仙台怪物id段
        local config = gamedata.config.general[tostring(gamedata.config.shengxian_monster[tostring(id)].generalid)]
        return table.merge(gamedata.config.shengxian_monster[tostring(id)],{staffType = "monster", icon = config.icon, animationid = config.animationid})
    elseif id > 70000 and id <= 71000 then
        return    table.merge(gamedata.config.soul[tostring(id)] ,{staffType = "soul"})
    elseif id > 90000 and id < 91000 then
        return    table.merge(gamedata.config.pet3_attr[tostring(id)]["0"] ,{staffType = "pet"})
    elseif id >= 91000 and id < 92000 then
        return    table.merge(gamedata.config.pet3_fragment[tostring(id)] ,{
            staffType = "pet_fragment",
            icon = gamedata.config.pet3_attr[tostring(gamedata.config.pet3_fragment[tostring(id)].petid)]["0"].icon,
            name = gamedata.config.pet3_attr[tostring(gamedata.config.pet3_fragment[tostring(id)].petid)]["0"].name.."碎片" or "",
            quality = gamedata.config.pet3_attr[tostring(gamedata.config.pet3_fragment[tostring(id)].petid)]["0"].quality or ""
        })
    elseif id >= 92000 and id < 93000 then
        return    table.merge(gamedata.config.pet3_passiveskill[tostring(id)] ,{
            icon = gamedata.config.pet3_passiveskill[tostring(id)].icon,
            name = gamedata.config.pet3_passiveskill[tostring(id)].name,
            quality = gamedata.config.pet3_passiveskill[tostring(id)].quality
            
        })
    elseif id >= 80001 and id <= 81000 then

        local roleid = 0
        local fashionconfig = gamedata.config.fashioncoat or {}
        if (GameScene.protagonist.general.cid >= 10101 and GameScene.protagonist.general.cid <= 10115) or (GameScene.protagonist.general.cid >= 10997 and GameScene.protagonist.general.cid <= 10999) or (GameScene.protagonist.general.cid >= 162001 and GameScene.protagonist.general.cid <= 162003) then
            roleid = GameScene.protagonist.general.cid
        else
            for k,v in pairs(fashionconfig) do
                for k1,v1 in pairs(v) do
                    if v1.coat_id == GameScene.protagonist.general.cid then
                        roleid = v1.role_id
                    end
                end
            end
        end

        print("roleinfoid===",GameScene.protagonist.general.cid,roleid)

        local coat_id = 0
        local name = ""
        if fashionconfig[tostring(id)] then
            for k,v in pairs(fashionconfig[tostring(id)]) do
                if v.role_id == roleid then
                    coat_id = v.coat_id
                    name = v.name
                end
            end
        end
        print("id===",id,coat_id)
            
        local icon = nil
        local quality = 1
        if gamedata.config.general[tostring(coat_id)] then
            icon = gamedata.config.general[tostring(coat_id)]["icon"]
            quality = gamedata.config.general[tostring(coat_id)]["quality"]
        end
        print("idconfig===",icon,name,quality)
        return {
            staffType = "fashion",
            icon = icon,
            name = name,
            quality = quality
        }
    elseif id >= 82001 and id <= 83000 then
        return table.merge(gamedata.config.partner_fashion[tostring(id)],{staffType = "partnerfashion"})
    elseif id >= 120000 and id <= 121000 then
        return table.merge(gamedata.config.trump_gem[tostring(id)],{staffType = "jewel"})
    elseif id >= 110000 and id <= 111000 then
        return table.merge(gamedata.config.trump[tostring(id)],{staffType = "artifact"})
    elseif id >= 150000 and id <= 160000 then
        return    table.merge(gamedata.config.props2[tostring(id)],{staffType = "countdownGift"})
    elseif id >= 35001 and id <= 35500 then
        return   table.merge(gamedata.config.headframe[tostring(id)],{staffType = "iconBox"})
    elseif id >= 35501 and id <= 36000 then
        return   table.merge(gamedata.config.title[tostring(id)],{staffType = "title"})
    elseif id >= 200501 and id <= 201000 then
        local general_id = gamedata.config.illusion[tostring(id)].general_id
        local config = {
            staffType = "phantom",
            icon = gamedata.config.general[tostring(general_id)].icon,
            quality = gamedata.config.general[tostring(general_id)].quality
        }
        return table.merge(gamedata.config.illusion[tostring(id)],config)
    elseif id >= 201601 and id <= 201900 then
        return   table.merge(gamedata.config.exclusive_device_spirit[tostring(id)],{staffType = "qiling"})
    elseif id >= 201501 and id <= 201600 then
        return   table.merge(gamedata.config.exclusive[tostring(id)],{staffType = "exclusive"})
    elseif (id >= 201901 and id <= 202100) then
        return   table.merge(gamedata.config.token[tostring(id)],{staffType = "token"})
    elseif (id >= 202101 and id <= 202300) then
        return   table.merge(gamedata.config.token_fragment[tostring(id)],{staffType = "token_fragment"})
    end

end

function ui.getATTRandNUM(str)
    local i = string.find(str,":") or string.find(str,"：")
    local j = string.find(str,";") or string.find(str,"；")
    if not j then j = string.len(str)+1 end
    return string.sub(str,1,i-1),tonumber(string.sub(str,i+1,j-1))
end

function ui.getATTRandNUM2(str)
    local i = string.find(str,";") or string.find(str,"；")
    local j = string.find(str,":") or string.find(str,"：")
    if not j then j = string.len(str)+1 end
    print("getATTRandNUM2==",i,j)
    return string.sub(str,1,i-1),tonumber(string.sub(str,i+1,j-1))
end

function ui.getIDFromStr(str)
    local i = string.find(str,",") or string.find(str,"，")

    return tonumber(string.sub(str,1,i-1))
end

function ui.getIDSFromStr(datastring)
    if not datastring then return {} end
    local data = {}
    local i = 0
    while true do
        local a = i + 1
        i = string.find(datastring, ",", i + 1) or string.find(datastring, "，", i + 1) or string.find(datastring, ";", i + 1) or string.find(datastring, "；", i + 1)
        if i == nil then
            break
        end
        if tonumber(string.sub(datastring, a, i - 1)) then
            table.insert(data, tonumber(string.sub(datastring, a, i - 1)) )
        end
    end
    return data
end

function ui.getSTRandNUM(str)
    local i = string.find(str,",") or string.find(str,"，")
    local j = string.find(str,";") or string.find(str,"；")
    if not j then j = string.len(str)+1 end
    return string.sub(str,1,i-1),tonumber(string.sub(str,i+1,j-1))
end

function ui.getSTRandNUMs(datastring)
    if not datastring then return {} end
    local data = {}
    local i = 0
    local j = 0
    while true do
        local b = j + 1
        i = string.find(datastring, ",", i + 1)
        if i == nil then break end
        local a = i + 1
        j = string.find(datastring, ";", j + 1)
        if not j then j = string.len(datastring)+1 end
        if string.sub(datastring, b, i - 1) and tonumber(string.sub(datastring, a, j - 1)) then
            table.insert(data, { str = string.sub(datastring, b, i - 1), num = tonumber(string.sub(datastring, a, j - 1)) })
        end
    end
    return data
end

function ui.getIDandNUM(str)
    local i = string.find(str,",") or string.find(str,"，")
    local j = string.find(str,";") or string.find(str,"；")
    if not j then j = string.len(str)+1 end
    print(i,j,"ui.getIDandNUM")

    return tonumber(string.sub(str,1,i-1)),tonumber(string.sub(str,i+1,j-1))
end

function ui.getIDandNUMs(datastring)
    print("传过等等", datastring)
    if not datastring then return {} end
    local data = {}
    local i = 0
    local j = 0
    while true do
        local b = j + 1
        i = string.find(datastring, ",", i + 1)
        if i == nil then break end
        local a = i + 1
        j = string.find(datastring, ";", j + 1)
        if not j then j = string.len(datastring)+1 end
        if tonumber(string.sub(datastring, b, i - 1)) and tonumber(string.sub(datastring, a, j - 1)) then
            table.insert(data, { cid = tonumber(string.sub(datastring, b, i - 1)), num = tonumber(string.sub(datastring, a, j - 1)) })
        end
    end
    return data
end

function ui.getXGroupByString(datastring)
    local _t = ui.Split(datastring, ";")
    local _usedata = {}

    for k,v in pairs(_t) do
        if v ~= "" or v == nil then
            table.insert(_usedata, ui.Split(v, ","))
        end
    end

    return _usedata
end

function ui.getIDNUMChances(datastring)
    print("传过等等", datastring)
    if not datastring then return {} end
    local data = {}
    -- local i = 0
    -- local j = 0
    -- local k = 0
    while true do
        local i = 0
        local j = 0
        local k = 0

        local b = j + 1
        i = string.find(datastring, ",", i + 1)
        if i == nil then break end
        local a = i + 1
        j = string.find(datastring, ";", j + 1)
        if not j then j = string.len(datastring)+1 end
        if tonumber(string.sub(datastring, b, i - 1)) and tostring(string.sub(datastring, a, j - 1)) then
            local datastring2 = string.sub(datastring, a, j - 1)
            k = string.find(datastring2, ",", k + 1)
            local c = k + 1
            table.insert(data, { cid = tonumber(string.sub(datastring, b, i - 1)), num = tonumber(string.sub(datastring2, 1, k - 1)),chance = tonumber(string.sub(datastring2, c, j - 1)) })
            datastring = string.sub(datastring, j + 1, string.len(datastring)+1)
        end
    end
    return data
end

function ui.getIDRandNum(datastring)
    if not datastring then return {} end
    local stringMaxLen = string.len(datastring)
    local data = {}
    local fuhao1 = ";"
    local fuhao2 = ","
    local i = 0
    local j = 0
    local tmpSec = datastring
    local tmpBegan = string.find(tmpSec, fuhao1, i)
    if not (tmpBegan == nil or tmpBegan > stringMaxLen) then
        stringMaxLen = tmpBegan - 1
        tmpSec = string.sub(tmpSec,i,tmpBegan - 1)
    end

    repeat
        local k = 0
        local fid = ""
        k = string.find(tmpSec, fuhao2, i)
        if k == nil or k > stringMaxLen then
            if j <= stringMaxLen then
                fid = string.sub(tmpSec,i,stringMaxLen)
                table.insert(data, tonumber(fid))
            end
            break
        end
        fid = string.sub(tmpSec,i,k-1)
        j = k + 1
        i = j
        table.insert(data, tonumber(fid))
    until j > stringMaxLen

    return data
end

function ui.getNeedWithFuhao(datastring,fuhao)
    if not datastring then return {} end
    local stringMaxLen = string.len(datastring)
    local data = {}
    local i = 0
    local j = 0
    repeat
        local k = 0
        local fid = ""
        k = string.find(datastring, fuhao, i)
        if k == nil or k > stringMaxLen then
            if j <= stringMaxLen then
                fid = string.sub(datastring,i,stringMaxLen)
                table.insert(data, fid)
            end
            break
        end
        fid = string.sub(datastring,i,k-1)
        j = k + 1
        i = j
        table.insert(data, fid)
    until j > stringMaxLen
    return data
end

function ui.getIDRandNums(datastring)
    if not datastring then return {} end
    local stringMaxLen = string.len(datastring)
    local fuhao = ";"
    local data = {}
    local i = 0
    local j = 0
    repeat
        local k = 0
        local fid = ""
        k = string.find(datastring, fuhao, i)
        if k == nil or k > stringMaxLen then
            if j <= stringMaxLen then
                fid = string.sub(datastring,i,stringMaxLen)
                table.insert(data, ui.getIDRandNum(fid))
            end
            break
        end
        fid = string.sub(datastring,i,k-1)
        j = k + 1
        i = j
        table.insert(data, ui.getIDRandNum(fid))
    until j > stringMaxLen
    return data
end

function ui.getTimeReducing(destTime1,destTime2)
    local tmpHRed = destTime2[1] - destTime1[1] -- 小时差
    local tmpMRed = destTime2[2] - destTime1[2] -- 分钟差
    return tmpHRed * 3600 + tmpMRed * 60
end

function ui.getDragonTime(destTime)
    return destTime[1] * 3600 + destTime[2] * 60
end

function ui.getTimeDragon(destTime)
    local tmpMiao = destTime%60
    local tmpFen = math.floor(destTime/60)
    tmpFen = tmpFen % 60
    local tmpShi = math.floor(tmpFen/60)
    tmpShi = tmpShi % 24
    return tmpShi,tmpFen,tmpMiao
end

function ui.getGeneralID(datastring) -- 取 1;2;3
    if not datastring then return {} end
    local data = {}
    local i = 0
    while true do
        local a = i + 1
        i = string.find(datastring, ";", i + 1) or string.find(datastring, "；", i + 1)
        if i == nil then
            break
        end
        if tonumber(string.sub(datastring, a, i - 1)) then
            table.insert(data, {cid = tonumber(string.sub(datastring, a, i - 1))})
        end
    end
    return data
end

function ui.getIDandDesc(datastring) -- 取1,啊;2,啊;
    if not datastring then return {} end
    local data = {}
    local i = 0
    local j = 0
    while true do
        local b = j + 1
        i = string.find(datastring, ",", i + 1)
        if i == nil then break end
        local a = i + 1
        j = string.find(datastring, ";", j + 1)
        if tonumber(string.sub(datastring, b, i - 1)) and string.sub(datastring, a, j - 1) then
            table.insert(data, { cid = tonumber(string.sub(datastring, b, i - 1)), desc = string.sub(datastring, a, j - 1) })
        end
    end
    return data    
end

function ui.getTableFromStr(datastring)
    if not datastring then return {} end
    local data = {}
    local i = 0
    local j = 0
    local k = 0
    while true do
        local i=string.find(datastring, ",")
        if not i then break end
        local j=string.find(datastring, ",",i+1)
        if not j then break end
        k = string.find(datastring, ";", j + 1)
        if tonumber(string.sub(datastring, 1, i-1)) and tonumber(string.sub(datastring, i+1, j-1)) and tonumber(string.sub(datastring, j+1, k-1)) then
            table.insert(data, { cid = tonumber(string.sub(datastring, 1, i - 1)), num = tonumber(string.sub(datastring, i+1, j - 1)),probability = tonumber(string.sub(datastring, j+1, k-1)) })
        end
        datastring = string.sub(datastring, k+1, string.len(datastring))
    end
    return data
end

function ui.creatDelayButton(sprite,touchPriority,eventFunc,beginFunc,endFunc,index)
    local layer = CCLayer:create()
    layer:setContentSize(CCSizeMake(sprite:getContentSize().width,sprite:getContentSize().height))
    layer:setAnchorPoint(ccp(0,0))
    layer:setPosition(ccp(0,0))
    sprite:addChild(layer)
    local touching = false

    local bgnum = 0
    local donum = 1

    local function sq_()
        bgnum = bgnum + 1
        if bgnum > 80 then
            donum = 100
        elseif bgnum > 40 then
            donum = 10
        end

        layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.05), CCCallFunc:create(function()
            if touching then
                eventFunc(donum)
                sq_()
            end
        end)))
    end

    local function sq()
        print("touching",touching)
        bgnum = 0
        donum = 1
        layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
            if touching then
                print("touching",touching)
                eventFunc()
                sq_()
            end
        end)))
    end

    local initX,initY = 0,0

    local function ccTouchBegan(x, y)
        print("DelayButton clicked")
        local istouched = ui.isTouched(sprite,x,y)
        print("istouched",istouched)

        if istouched then
            initX,initY = x,y
            touching = true
            sq()
            if beginFunc and index then
                beginFunc(index)
            end
            return true
        end
        return false
    end

    local function ccTouchMoved(x, y)
        if not ui.isTouched(sprite,x,y) then
            sprite:stopAllActions()
            touching = false
            if endFunc and index then
                endFunc(index)
            end
        end
    end

    local function ccTouchEnded(x, y)
        if endFunc and index then
            endFunc(index)
        end
        sprite:stopAllActions()
        touching = false
        if ui.isTouched(sprite,x,y) and math.abs(initX-x)<10 and math.abs(initY-y)<10 then
            eventFunc()
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

    layer:registerScriptTouchHandler(onTouch, false, touchPriority, false)
    layer:setTouchPriority(touchPriority)
    layer:setTouchEnabled(true)
    return layer
end

function ui.creatPageCursor(parent,num,positionX,positionY)
    local root = {}
    root.rootNode = CCNode:create()
    root.rootNode:setPosition(ccp(positionX,positionY))
    parent:addChild(root.rootNode,1)

    local dis =  50
    if num>20 then
        dis = 1000/num
    end

    for i=1,num do
        root["point"..i] = CCSprite:createWithSpriteFrameName("cursorpageoff.png")
        root.rootNode:addChild(root["point"..i])
        root["point"..i]:setPosition(ccp(dis*(i-num/2-0.5),0))
    end

    return root
end

function ui.setPageCursor(PageCursor,page)
    if PageCursor.selectedpoint then
        setSpriteFrameByName(PageCursor.selectedpoint, "cursorpageoff.png")
    end
    setSpriteFrameByName(PageCursor["point"..page], "cursorpageon.png")
    PageCursor.selectedpoint = PageCursor["point"..page]
end

function ui.sortData(data, parm1, parm2, parm3)
    local sortfunc = function (a,b)
        if parm1 == nil then return false end
        if a[parm1] > b[parm1] then
            return true
        elseif a[parm1] < b[parm1] then
            return false
        elseif a[parm1] == b[parm1] then
            if parm2 == nil then return false end
            if a[parm2] > b[parm2] then
                return true
            elseif a[parm2] < b[parm2] then
                return false
            elseif a[parm2] == b[parm2] then
                if parm3 == nil then return false end
                return a[parm3] > b[parm3]
            end
        end
    end

    table.sort(data,sortfunc)
end

function ui.sortData2(data, parm1, parm2, parm3,parm4,parm5,parm1type)
    local sortfunc = function (a,b)
        if parm1 == nil then return false end
        if a[parm1] > b[parm1] then
            return  not parm1type
        elseif a[parm1] < b[parm1] then
            return parm1type
        elseif a[parm1] == b[parm1] then
            if parm2 == nil then return false end
            if a[parm2] > b[parm2] then
                return  not parm1type
            elseif a[parm2] < b[parm2] then
                return parm1type
            elseif a[parm2] == b[parm2] then
                if parm3 == nil then return false end
                if a[parm3] > b[parm3] then
                    return  not parm1type
                elseif a[parm3] < b[parm3] then
                    return parm1type
                elseif a[parm3] == b[parm3] then
                    if parm4 == nil then return false end
                    if a[parm4] > b[parm4] then
                        return  not parm1type
                    elseif a[parm4] < b[parm4] then
                        return parm1type
                    elseif a[parm4] == b[parm4] then
                        if parm5 == nil then return false end
                        if a[parm5] > b[parm5] then
                            return  not parm1type
                        elseif a[parm5] < b[parm5] then
                            return parm1type
                        elseif a[parm5] == b[parm5] then
                            if parm5 == nil then return false end
                        end
                    end
                end
            end
        end
    end

    table.sort(data,sortfunc)
end


function ui.Split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

function ui.getDateDesc(date)
    local year,month,day,hour = string.sub(date,1,4),string.sub(date,5,6),string.sub(date,7,8),string.sub(date,9,10),string.sub(date,11,12),string.sub(date,13,14)
    return year .. "年" .. month .. "月" .. day .. "日" .. hour .. "时"
end

function ui.getDateDesc2(date)
    local year,month,day,hour = string.sub(date,1,4),string.sub(date,5,6),string.sub(date,7,8),string.sub(date,9,10),string.sub(date,11,12),string.sub(date,13,14)
    return year .. "年" .. month .. "月" .. day .. "日"
end

function ui.getDate(date)
    return string.sub(date,1,4),string.sub(date,5,6),string.sub(date,7,8),string.sub(date,9,10),string.sub(date,11,12),string.sub(date,13,14)
end


function ui.getDateByTime(unixTime)
    if unixTime and unixTime >= 0 then
        local tb = {}
        tb.year = tonumber(os.date("%Y",unixTime))
        tb.month =tonumber(os.date("%m",unixTime))
        tb.day = tonumber(os.date("%d",unixTime))
        tb.hour = tonumber(os.date("%H",unixTime))
        tb.minute = tonumber(os.date("%M",unixTime))
        return tb.year .. "/" .. tb.month .. "/" .. tb.day .. "   " .. ((tb.hour >= 10) and tb.hour or ("0"..tb.hour)) .. ":".. ((tb.minute >= 10) and tb.minute or ("0"..tb.minute))
    end
end    


function ui.checkDateActive(beginD,endD,now)
    now = now or gamedata:time()


    local b_year,b_month,b_day,b_hour,b_minute,b_second = ui.getDate(beginD)
    local e_year,e_month,e_day,e_hour,e_minute,e_second = ui.getDate(endD)

    local begint = os.time({year=tonumber(b_year), month=tonumber(b_month),day=tonumber(b_day),hour=tonumber(b_hour),min=tonumber(b_minute),sec=tonumber(b_second)})
    local endt = os.time({year=tonumber(e_year), month=tonumber(e_month),day=tonumber(e_day),hour=tonumber(e_hour),min=tonumber(e_minute),sec=tonumber(e_second)})

    print("checkDateActive ",begint,endt)

    printT(os.date("*t",begint))
    printT(os.date("*t",endt))

    if now>= begint and  now< endt then
        return true, endt-now                      --在时间范围内返回true 和剩余时间秒数
    elseif now < begint  then
        return false, begint-now                   --没到开启时间返回false 和距离开启时间的秒数
    elseif now >= endt then
        return false, endt-now                     --超过结束时间返回false 和超出时间的秒数
    end

end

function ui.makeshortnum(num_)
    local num = tonumber(num_)

    if num then
        if num > 100000000 then
            -- return math.floor(num/100000000).."亿"..math.floor(math.mod(num,100000000)/10000).."万"
            return gameConfig.strings:yiwan(math.floor(num/100000000),math.floor(math.mod(num,100000000)/10000))
        elseif num > 10000000 then
            -- return math.floor(num/10000).."万"
            return gameConfig.strings:wan(math.floor(num/10000))
        else
            return num
        end
    else
        return num_
    end
end

function ui.makeshortnum2(num_)
    local num = tonumber(num_)
    if num then
        if num >=100000000 then
            local wan = math.floor(math.mod(num,100000000)/10000)
            if wan == 0 then
                return gameConfig.strings:yi(math.floor(num/100000000))
            else
                return gameConfig.strings:yiwan(math.floor(num/100000000),wan)
            end    
        elseif num >= 10000 then
            return gameConfig.strings:wan(math.floor(num/10000))
        else
            return num
        end
    else
        return num_
    end
end

function ui.makeShortNum2(num)
    local _num = tonumber(num)

    if _num then
        if _num > 10000000 then
            return math.floor(_num / 1000000) .. "M"
        elseif _num > 10000 then
            return math.floor(_num / 1000) .. "K"
        else
            return _num
        end
    else
        return num
    end
end

function ui.makeshortgoldnum(num_)
    local num = tonumber(num_)

    if num then
        if num > 100000000 then
            return gameConfig.strings:yiwan(math.floor(num/100000000),math.floor(math.mod(num,100000000)/10000))
        else
            return num
        end
    else
        return num_
    end
end

function ui.attrlist()
    return {
        "atk",
        "def",
        "hp",
        "speed",
        "critical",
        "resilience",
        "hit",
        "arp",
        "dodge",
        "parry",
        "criticaldmg",
        "antiblew",
        "heal",
        "skill_resilience",
        "subdmg",
        "adddmg",
        "adddmgpct",
        "subdmgpct",
        "subdmg",
        "ap_atk_p",
        "ap",
    }
end

function ui.getShenqiName( data )
    local level = data.level4 or 0

    local showlevel = math.mod(level,10)
    local stage = math.modf(level/10)

    return stage.."阶"..showlevel.."级"
end

function ui.getExclusiveConfigByCid( cid )
    local generalconfig = gamedata.config.general[tostring(cid)]
    if generalconfig.partner_id~=0 then
        cid = generalconfig.partner_id
    end    
    return gamedata.config.shenqi_evolve[tostring(cid)]
end

function ui.setShenqiIcon( item,data,id )
    local config = ui.getExclusiveConfigByCid(data.cid)
    if not config then return end    
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    local level = math.max(1,data.level4)
    local levelconfig = gamedata.config.shenqi[tostring(level)]
    local stage = math.max(1,levelconfig.evolve_lv)
    local icon = config["icon"..stage]
    setSpriteFrameByName(item["shen_icon"..key_Ex], icon)

end

function ui.setIcon(item,data,id)
    if data and next(data) then
        local key_Ex
        if id == nil or id == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..id
        end
    
        if item["i_encounter_name"..key_Ex] and data.encounter_name then
            item["i_encounter_name"..key_Ex]:setVisible(true)
            item["i_encounter_name"..key_Ex]:setString(data.encounter_name and data.encounter_name or "")
        end
    
        if item["i_name"..key_Ex] then
            item["i_name"..key_Ex]:setString(data.name or " ")
        end
    
        if item["i_num"..key_Ex] then
            -- if data.num and data.num == "双倍" then
            if data.num and data.num == gameConfig.strings:string_common("ui",13) then
                item["i_num"..key_Ex]:setString(data.num)
            else
                item["i_num"..key_Ex]:setString(data.num and "x"..ui.makeshortnum(data.num) or " ")
            end
            if data.stroke and data.stroke > 0 then
                ui.setStringWithStroke(item["i_num"..key_Ex],nil,data.stroke)
            end
        end
    
        if item["i_soulsprite"..key_Ex] then
            item["i_soulsprite"..key_Ex]:setVisible(data.staffType and data.staffType == "general_fragment")
        end
    
        setSpriteFrameByName(item["i_kuang"..key_Ex], (data.quality and data.quality ~= 0) and gameConfig.images["icon_ni_kuang"..data.quality] or gameConfig.images.icon_ni_kuangdefault)
        setSpriteFrameByName(item["i_quality"..key_Ex], (data.quality and data.quality ~= 0) and gameConfig.images["icon_ni_quality"..data.quality] or gameConfig.images.icon_ni_qualitydefault)
    
        local cid = data.cid or data.id
        if cid and ui.IDconfig(cid).staffType == "soul" then
            setSpriteFrameByName(item["i_icon"..key_Ex], gameConfig.images.alpha)
            item["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
            local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..data.icon..".ccbi", nil, true, data.icon)
            item["i_soulnode"..key_Ex]:addChild(ccb)
        else
            setSpriteFrameByName(item["i_icon"..key_Ex], data.icon and data.icon or gameConfig.images.alpha)
            ui.setSpriteTextureRect(item["i_icon"..key_Ex],0,0,150,150)
        end
    
        if item["i_des"..key_Ex] then
            item["i_des"..key_Ex]:setString(data.des and data.des or "")
        end
    
        if item["i_level"..key_Ex] then
            local level = data.level or data.level1
            item["i_level"..key_Ex]:setString(level and level or "")
        end
    
        if item["i_jienode"..key_Ex] then
            item["i_jienode"..key_Ex]:setVisible(data.level2 and true or false)
        end
    
        if item["i_level2"..key_Ex] then
            -- item["i_level2"..key_Ex]:setString(data.level2 and data.level2.."阶" or "")
            item["i_level2"..key_Ex]:setString(data.level2 and data.level2.."阶" or "")
        end
    
        if item["i_type"..key_Ex] then
            setSpriteFrameByName(item["i_type"..key_Ex], gameConfig.images[data.actor])
        end
    
        if item["i_power"..key_Ex] then
            item["i_power"..key_Ex]:setString(data.power)
        end
    
    
        if item["i_suitNode"..key_Ex] then
            item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
            if (data.cid or data.id) then
                local config = ui.IDconfig(data.cid or data.id)
                local equipconfig = config or {}
                if config.staffType == "equip_fragment" then
                    equipconfig = ui.IDconfig(config.equip) or {}
                end
                item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                if equipconfig.suit and equipconfig.suit ~= 0 and equipconfig.staffType ~= "qiling" then
                    local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..(config.quality or 2)..".ccbi", nil, true, "icon")
                    item["i_suitNode"..key_Ex]:addChild(suitccb)
                    suititem.partical:setPositionType(kCCPositionTypeGrouped)
                end
            end
        end
    end
end

function ui.setNavigationIcon(item,data,id)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    if data.opt and data.opt == 1 then
        setSpriteFrameByName(item["i_quality_d"..key_Ex], "b_iconbg9")
    else
        setSpriteFrameByName(item["i_quality_d"..key_Ex], "b_iconbg8")
    end

    setSpriteFrameByName(item["i_quality_k"..key_Ex], data.quality and "b_s_iconk"..data.quality or "b_s_iconk1")
    setSpriteFrameByName(item["i_icon"..key_Ex], data.icon and data.icon or gameConfig.images.alpha)
    ui.setSpriteTextureRect(item["i_icon"..key_Ex],0,0,150,150)

    item["i_name"..key_Ex]:setString(data.name and data.name or "")
    item["i_des"..key_Ex]:setString(data.des and data.des or "")

end

function ui.setNavigationIcon2(item,data,id)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end


    setSpriteFrameByName(item["i_quality_d"..key_Ex], data.quality and "b_iconbg"..data.quality or "b_iconbg1")

    setSpriteFrameByName(item["i_quality_k"..key_Ex], data.quality and "b_iconk"..data.quality or "b_iconk1")
    setSpriteFrameByName(item["i_icon"..key_Ex], data.icon and data.icon or gameConfig.images.alpha)
    ui.setSpriteTextureRect(item["i_icon"..key_Ex],0,0,150,150)

    item["i_name"..key_Ex]:setString(data.name and data.name or "")
    item["i_des"..key_Ex]:setString(data.des and data.des or "")

end

function ui.setEquipIcon(dataTable,itemTable,id,status,starData)

    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    itemTable["e_add"..key_Ex]:stopAllActions()
    itemTable["e_adddes"..key_Ex]:stopAllActions()

    itemTable["e_notice"..key_Ex]:removeAllChildrenWithCleanup(true)
    if dataTable and dataTable.notice then
        local eccb,eitem = CCBReaderLoad("slotsInfo/notice", nil, true, "notice")
        itemTable["e_notice"..key_Ex]:addChild(eccb)
        setSpriteFrameByName(eitem.notice,"obj_"..dataTable.notice )
    end

    if itemTable["e_suitNode"..key_Ex] then
        itemTable["e_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    end

    if itemTable["e_lvupeffect"..key_Ex] then
        itemTable["e_lvupeffect"..key_Ex]:removeAllChildrenWithCleanup(true)
    end

    if dataTable and dataTable.cid then
        local config = ui.IDconfig(dataTable.cid) or {}
        itemTable["e_type"..key_Ex]:setVisible(false)
        itemTable["e_lv"..key_Ex]:setVisible(true)
        itemTable["e_lv2"..key_Ex]:setVisible(true)
        itemTable["e_add"..key_Ex]:setVisible(false)
        itemTable["e_adddes"..key_Ex]:setVisible(false)
        itemTable["e_name"..key_Ex]:setVisible(true)
        
        if config.quality and config.quality >= 7 then
            ui.setLabelString(itemTable["e_name"..key_Ex],ui.getEquipStageName(dataTable) or "",214)
        else    
            ui.setLabelString(itemTable["e_name"..key_Ex],ui.getEquipStageName(dataTable) or "",config.quality and 2*config.quality or 0)
        end
        -- ui.setLabelString(itemTable["e_name"..key_Ex],config.name or "",config.quality and 2*config.quality or 0)

        local oldstring =  itemTable["e_lv"..key_Ex]:getString()

        setSpriteFrameByName(itemTable["e_quality"..key_Ex], "b_iconbg"..(config.quality or 1))
        setSpriteFrameByName(itemTable["e_icon"..key_Ex], config.icon or "alpha")
        setSpriteFrameByName(itemTable["e_kuang"..key_Ex], "b_iconk"..(config.quality or 1))

        ui.setLabelString(itemTable["e_lv"..key_Ex],"等级:"..dataTable.level1,13)
--        ui.setLabelString(itemTable["e_lv2"..key_Ex],"+"..dataTable.level2,13)

        -- if config.type and (config.type == "treasure" or config.type == "horse") then
        --     --ui.setLabelString(itemTable["e_lv2"..key_Ex],"+"..dataTable.level2,13)
        --     ui.setLabelString(itemTable["e_lv2"..key_Ex],"",13)
        -- else
            ui.setLabelString(itemTable["e_lv2"..key_Ex],"",13)
        --end


        print("oldstring = ",oldstring)
        print("string.len(oldstring) = ",string.len(oldstring))
        print("tonumber = ",tonumber(string.sub(oldstring,8,string.len(oldstring))))
        print("level1 = ",dataTable.level1)
        print("key_Ex = ",key_Ex)
        if status and dataTable.level1 > tonumber(string.sub(oldstring,8,string.len(oldstring))) then
            print("e_lvupeffect",status)
            local eccb,eitem = CCBReaderLoad("UIEffect/qianghua/qianghua", nil, true, "qianghua")
            itemTable["e_lvupeffect"..key_Ex]:addChild(eccb)

            if status >0 then
                eitem.criticalnode:setVisible(true)
                eitem.num:setString("暴击"..status.."次")
            else
                eitem.criticalnode:setVisible(false)
            end
            local animationManager = getAnimationManager(eitem)
            animationManager:setAnimationCompletedCallback(function()
                itemTable["e_lvupeffect"..key_Ex]:removeAllChildrenWithCleanup(true)
            end)
            animationManager:runAnimationsForSequenceNamed("qianghua")
        end

        itemTable["e_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
        if config.suit and config.suit ~= 0 then
            local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..(config.quality or 2)..".ccbi", nil, true, "icon")
            itemTable["e_suitNode"..key_Ex]:addChild(suitccb,1,100)
            suititem.partical:setPositionType(kCCPositionTypeGrouped)
        end
    else
        itemTable["e_name"..key_Ex]:setVisible(false)
        itemTable["e_type"..key_Ex]:setVisible(true)
        itemTable["e_lv"..key_Ex]:setVisible(false)
        itemTable["e_lv2"..key_Ex]:setVisible(false)
        setSpriteFrameByName(itemTable["e_quality"..key_Ex], "b_iconbg0")
        setSpriteFrameByName(itemTable["e_icon"..key_Ex], "obj_"..gameConfig.equipconfig[id+1])
        setSpriteFrameByName(itemTable["e_kuang"..key_Ex], "b_iconk0")
        if dataTable and dataTable.has then
            itemTable["e_add"..key_Ex]:setVisible(true)
            itemTable["e_adddes"..key_Ex]:setVisible(true)
            ui.blink(itemTable["e_add"..key_Ex],1)
            ui.blink(itemTable["e_adddes"..key_Ex],1)

            itemTable["e_type"..key_Ex]:setVisible(false)
            ui.setLabelString(itemTable["e_adddes"..key_Ex],nil,31)
        else
            itemTable["e_add"..key_Ex]:setVisible(false)
            itemTable["e_adddes"..key_Ex]:setVisible(false)
            itemTable["e_type"..key_Ex]:setVisible(true)
            ui.setLabelString(itemTable["e_type"..key_Ex],gameConfig.strings.equipType[gameConfig.equipconfig[id+1]],28)
        end
    end

    -- 添加升星显示设置
    if not itemTable["star_starnode"..key_Ex] then return end
    if starData and starData.cid then
        local config = ui.IDconfig(starData.cid) or {}
        if starData and (starData.level3 and starData.level3 ~= 0) and 
        (config.type == "weapon" or config.type == "head" or config.type == "armor" or config.type == "accessory" or config.type == "treasure" or config.type == "horse") then
            itemTable["star_starnode"..key_Ex]:setVisible(true) 
            ui.setStarShow(itemTable,starData,key_Ex)
        else
            itemTable["star_starnode"..key_Ex]:setVisible(false) 
        end
    else
        itemTable["star_starnode"..key_Ex]:setVisible(false) 
    end
    
end

-- 升星消耗物品数据
function ui.setStarShow(item,data,key_Ex)
    printT(item,"staritem===")
    print("starshwo===",data.level3,key_Ex)
    if data.level3 == 0 then
        print("0级没有星显示！")
        return
    end
    local starnum = math.mod(data.level3,5) 

    print("starnum==",starnum)
    if starnum == 0 then
        starnum = 5
    end
    local numtemp = math.floor(data.level3/5)
    local frontpic = "shengxing_"..numtemp
    print("starnum===",numtemp,frontpic)

    local starconfig = gamedata.config.equip_star
    for i=1,5 do
        if i <= starnum then
            setSpriteFrameByName(item["star_star"..i..key_Ex], starconfig[tostring(data.level3)]["icon"] or "alpha")
        else
            setSpriteFrameByName(item["star_star"..i..key_Ex], frontpic or "alpha")
        end
    end
end

function ui.setSkillIcon(dataTable,itemTable,id)

    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    itemTable["skill_notice"..key_Ex]:removeAllChildrenWithCleanup(true)

    if dataTable and dataTable.cid then
        local config =
        {
            quality = dataTable.quality,
        }
        config = table.merge(ui.IDconfig(dataTable.cid) or {},config)

        itemTable["skill_datanode"..key_Ex]:setVisible(true)
        itemTable["skill_type2"..key_Ex]:setVisible(false)

        if dataTable.hintUp == 1 then
            local eccb,eitem = CCBReaderLoad("slotsInfo/notice", nil, true, "notice")
            itemTable["skill_notice"..key_Ex]:addChild(eccb)
            setSpriteFrameByName(eitem.notice,"obj_up8")
        end

        if config.quality and config.quality >= 7 then
            ui.setLabelString(itemTable["skill_name"..key_Ex],config.name or "",214)
        else    
            ui.setLabelString(itemTable["skill_name"..key_Ex],config.name or "",config.quality and 2*config.quality or 0)
        end
        setSpriteFrameByName(itemTable["skill_icon"..key_Ex], config.icon or "alpha")
        setSpriteFrameByName(itemTable["skill_kuang"..key_Ex], "b_iconk"..(config.quality or 1))

--        if config.staffType and config.staffType == "skill" then
--            setSpriteFrameByName(itemTable["skill_type"..key_Ex], "obj_2")
--        else
--            setSpriteFrameByName(itemTable["skill_type"..key_Ex], "obj_4")
--        end

        if key_Ex == "" and itemTable["skill_type"..key_Ex] then
            setSpriteFrameByName(itemTable["skill_type"..key_Ex], "obj_2")
        end
        if key_Ex == "_1" and itemTable["skill_type"..key_Ex] then
            setSpriteFrameByName(itemTable["skill_type"..key_Ex], "obj_4")
        end


        if dataTable.status == -1 then
            itemTable["skill_status"..key_Ex]:setVisible(true)
            -- ui.setLabelString(itemTable["skill_status"..key_Ex],"未开启",29)
            ui.setLabelString(itemTable["skill_status"..key_Ex],gameConfig.strings:string_common("moreCommon","weikaiqi"),29)
            itemTable["skill_icon"..key_Ex]:setColor(ccc3(150,150,150))
        elseif dataTable.status == 0 or dataTable.status == 1 then
            itemTable["skill_status"..key_Ex]:setVisible(true)
            -- ui.setLabelString(itemTable["skill_status"..key_Ex],"未激活",29)
            ui.setLabelString(itemTable["skill_status"..key_Ex],gameConfig.strings:string_common("moreCommon","weijihuo"),29)
            itemTable["skill_icon"..key_Ex]:setColor(ccc3(150,150,150))
        elseif dataTable.status == 2 then
            itemTable["skill_status"..key_Ex]:setVisible(false)
            itemTable["skill_icon"..key_Ex]:setColor(ccc3(255,255,255))
        end

        --if dataTable.level then
        --    itemTable["skill_lv"..key_Ex]:setVisible(true)
        --    ui.setLabelString(itemTable["skill_lv"..key_Ex],"等级:"..dataTable.level,13)
        --else
            itemTable["skill_lv"..key_Ex]:setVisible(false)
        --end

        --if dataTable.level2 then
        --    itemTable["skill_lv2"..key_Ex]:setVisible(true)
        --    ui.setLabelString(itemTable["skill_lv2"..key_Ex],"+"..dataTable.level2,13)
        --else
            itemTable["skill_lv2"..key_Ex]:setVisible(false)
        --end

    else
        itemTable["skill_datanode"..key_Ex]:setVisible(false)
        itemTable["skill_type2"..key_Ex]:setVisible(true)
        itemTable["skill_icon"..key_Ex]:setColor(ccc3(255,255,255))
        setSpriteFrameByName(itemTable["skill_icon"..key_Ex], "obj_lock")
        setSpriteFrameByName(itemTable["skill_kuang"..key_Ex], "b_iconk0")
        ui.setLabelString(itemTable["skill_type2"..key_Ex],nil,28)
    end
end

function ui.setStoneIcon(data,item,id,selected,islevelup)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    item["selectEffect"..key_Ex]:removeAllChildrenWithCleanup(true)
    if selected then
        local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
        item["selectEffect"..key_Ex]:addChild(eccb)
    end

    local config = gamedata.config.godstone[tostring(id+1)]
    setSpriteFrameByName(item["stone_sprite"..key_Ex], config.icon or "alpha")
    ui.setLabelString(item["stone_name"..key_Ex],config.name,2)

    if data.level <=0 then
        ui.addGray("CCSprite",item["stone_sprite"..key_Ex])
        ui.setLabelString(item["stone_lv"..key_Ex],"未激活",13)
    else
        ui.removeGray("CCSprite",item["stone_sprite"..key_Ex])
        ui.setLabelString(item["stone_lv"..key_Ex],"等级:"..data.level,13)
    end
    if islevelup  then
        local eccb,eitem = CCBReaderLoad("UIEffect/qianghua/qianghua", nil, true, "qianghua")
        item["e_lvupeffect"..key_Ex]:addChild(eccb)
        local animationManager = getAnimationManager(eitem)
        animationManager:setAnimationCompletedCallback(function()
            item["e_lvupeffect"..key_Ex]:removeAllChildrenWithCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("qianghua")
    end

end

function ui.setSoulIcon(dataTable,itemTable,id)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    itemTable["soul_add"..key_Ex]:stopAllActions()
    itemTable["soul_adddes"..key_Ex]:stopAllActions()

    itemTable["soul_notice"..key_Ex]:removeAllChildrenWithCleanup(true)
    if dataTable and dataTable.notice then
        local eccb,eitem = CCBReaderLoad("slotsInfo/notice", nil, true, "notice")
        itemTable["soul_notice"..key_Ex]:addChild(eccb)
        setSpriteFrameByName(eitem.notice,"obj_"..dataTable.notice )
    end

    itemTable["soul_node"..key_Ex]:removeAllChildrenWithCleanup(true)
    if dataTable and dataTable.cid then
        local config = ui.IDconfig(dataTable.cid) or {}
        itemTable["soul_lv"..key_Ex]:setVisible(true)
        itemTable["soul_sprite"..key_Ex]:setVisible(false)
        itemTable["soul_status"..key_Ex]:setVisible(false)
        itemTable["soul_add"..key_Ex]:setVisible(false)
        itemTable["soul_adddes"..key_Ex]:setVisible(false)
        itemTable["soul_name"..key_Ex]:setVisible(true)
        if config.quality and config.quality >= 7 then
            ui.setLabelString(itemTable["soul_name"..key_Ex],config.name or "",214)
        else    
            ui.setLabelString(itemTable["soul_name"..key_Ex],config.name or "",config.quality and 2*config.quality or 0)
        end

        ui.setLabelString(itemTable["soul_lv"..key_Ex],"等级:"..dataTable.level,13)

        if config.icon then
            local ccb,item = CCBReaderLoad("UIEffect/soul/"..config.icon..".ccbi", nil, true, config.icon)
            itemTable["soul_node"..key_Ex]:addChild(ccb)
        end
        setSpriteFrameByName(itemTable["soul_quality"..key_Ex], "b_iconbg"..(config.quality or 1))
        setSpriteFrameByName(itemTable["soul_kuang"..key_Ex], "b_iconk"..(config.quality or 1))
    else
        itemTable["soul_lv"..key_Ex]:setVisible(false)
        itemTable["soul_sprite"..key_Ex]:setVisible(true)
        itemTable["soul_status"..key_Ex]:setVisible(true)
        itemTable["soul_name"..key_Ex]:setVisible(false)

        if dataTable and dataTable.openlevel then
            itemTable["soul_status"..key_Ex]:setVisible(true)
            itemTable["soul_add"..key_Ex]:setVisible(false)
            itemTable["soul_adddes"..key_Ex]:setVisible(false)

            setSpriteFrameByName(itemTable["soul_sprite"..key_Ex], "obj_lock")
            -- ui.setLabelString(itemTable["soul_status"..key_Ex],dataTable.openlevel.."级开启",13)
            ui.setLabelString(itemTable["soul_status"..key_Ex],gameConfig.strings:lvOpen(dataTable.openlevel),13)
        else
            itemTable["soul_status"..key_Ex]:setVisible(false)
            setSpriteFrameByName(itemTable["soul_sprite"..key_Ex], "obj_soul2")
            if dataTable and dataTable.has then
                itemTable["soul_add"..key_Ex]:setVisible(true)
                itemTable["soul_adddes"..key_Ex]:setVisible(true)
                ui.blink(itemTable["soul_add"..key_Ex],1)
                ui.blink(itemTable["soul_adddes"..key_Ex],1)

                ui.setLabelString(itemTable["soul_adddes"..key_Ex],nil,31)
            else
                itemTable["soul_add"..key_Ex]:setVisible(false)
                itemTable["soul_adddes"..key_Ex]:setVisible(false)
            end
        end

        setSpriteFrameByName(itemTable["soul_quality"..key_Ex], "b_iconbg0")
        setSpriteFrameByName(itemTable["soul_kuang"..key_Ex], "b_iconk0")
    end
end

function ui.setSlotGeneralIcon(dataTable,itemTable,id,gdata)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    if itemTable["phantomNode"..key_Ex] then
        itemTable["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    end

    itemTable["g_lock"..key_Ex]:stopAllActions()
    if dataTable.general and dataTable.general.cid then
        local config = ui.IDconfig(dataTable.general.illusionGeneralCid or dataTable.general.cid) or {}

        if dataTable.general.illusionGeneralCid then
            if itemTable["phantomNode"..key_Ex] then
                itemTable["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                ui.createPhantomIcon(itemTable["phantomNode"..key_Ex])
            end
        end

        itemTable["g_lock"..key_Ex]:setVisible(false)
        itemTable["g_icon"..key_Ex]:setVisible(true)
        itemTable["g_status"..key_Ex]:setVisible(false)
        if dataTable.general.skilllevel and config.basic then
            config.basic = config.basic > gamedata.config.general_awaken[tostring(dataTable.general.skilllevel)].basic and config.basic or gamedata.config.general_awaken[tostring(dataTable.general.skilllevel)].basic 
        end


        if config.quality ==5 and config.basic >=20 then
            setSpriteFrameByName(itemTable["g_k_quality"..key_Ex], "b_iconk5_"..config.basic )
        else
            setSpriteFrameByName(itemTable["g_k_quality"..key_Ex], "b_iconk"..(config.quality or 1) )
        end

        setSpriteFrameByName(itemTable["g_quality"..key_Ex], "b_iconbg"..(config.quality or 1) )
        if gdata then
            setSpriteFrameByName(itemTable["g_icon"..key_Ex], gdata.icon or "alpha")
        else
            setSpriteFrameByName(itemTable["g_icon"..key_Ex], config.icon or "alpha")
        end
        ui.setSpriteTextureRect(itemTable["g_icon"..key_Ex],0,0,150,150)

        if itemTable["g_name"..key_Ex] then
            itemTable["g_name"..key_Ex]:setVisible(true)
            if config.quality and config.quality >= 7 then
                ui.setLabelString(itemTable["g_name"..key_Ex],config.name or "",213)
            else    
                ui.setLabelString(itemTable["g_name"..key_Ex],config.name or "",config.quality and 2*config.quality-1 or 1)
            end
        end

        if itemTable["g_lv2"..key_Ex] then
            itemTable["g_lv2"..key_Ex]:setVisible(true)
            ui.setLabelString(itemTable["g_lv2"..key_Ex],"+"..dataTable.general.level2,13)
        end
        if itemTable["g_lv3"..key_Ex] then
            itemTable["g_lv3"..key_Ex]:setVisible(true)
            ui.setLabelString(itemTable["g_lv3"..key_Ex], "等级:" .. dataTable.general.level1,13)
        end
        ui.sethint(itemTable["g_hint"..key_Ex],dataTable.hashint_equip or dataTable.hashint_soul or dataTable.hashint_stone or dataTable.hashint_safemask or dataTable.hashint_artifact or (dataTable.general.skill and dataTable.general.skill.hintUp == 1) or (dataTable.general.combskill and dataTable.general.combskill.hintUp == 1))

    else
        ui.sethint(itemTable["g_hint"..key_Ex],false)
        itemTable["g_lock"..key_Ex]:setVisible(true)
        itemTable["g_icon"..key_Ex]:setVisible(false)
        if itemTable["g_name"..key_Ex] then
            itemTable["g_name"..key_Ex]:setVisible(false)
        end

        if itemTable["g_lv2"..key_Ex] then
            itemTable["g_lv2"..key_Ex]:setVisible(false)
        end
        if itemTable["g_lv3"..key_Ex] then
            itemTable["g_lv3"..key_Ex]:setVisible(false)
        end
        setSpriteFrameByName(itemTable["g_k_quality"..key_Ex], "b_iconk0")
        setSpriteFrameByName(itemTable["g_quality"..key_Ex], "b_iconbg0")

        if dataTable and dataTable.openlevel then
            setSpriteFrameByName(itemTable["g_lock"..key_Ex], "obj_lock")
            itemTable["g_status"..key_Ex]:setVisible(true)
            -- ui.setLabelString(itemTable["g_status"..key_Ex],dataTable.openlevel.."级开启",13)
            ui.setLabelString(itemTable["g_status"..key_Ex],gameConfig.strings:lvOpen(dataTable.openlevel),13)
        else
            setSpriteFrameByName(itemTable["g_lock"..key_Ex], "obj_add")
            ui.blink(itemTable["g_lock"..key_Ex],1)
            itemTable["g_status"..key_Ex]:setVisible(false)
        end
    end

end


function ui.setSlotPetIcon(itemTable,data)
    printT(data,"setSlotPetIcon")
    if itemTable["phantomNode"] then
        itemTable["phantomNode"]:removeAllChildrenWithCleanup(true)
    end

    itemTable["g_lock"]:setVisible(false)
    itemTable["g_status"]:setVisible(false)
    itemTable["g_icon"]:setVisible(true)
    setSpriteFrameByName(itemTable["g_k_quality"], "b_iconk1")

    local config =  {}
    if data and data.cid then
        config = table.merge(ui.IDconfig(data.cid) or {},config)
    end
    if data and data.cid and data.level then
        config = gamedata.config.pet3_attr[tostring(data.cid)][tostring(data.level)]
    end

    setSpriteFrameByName(itemTable["g_icon"], config.icon and config.icon or "alpha")
    ui.setSpriteTextureRect(itemTable["g_icon"],0,0,150,150)

end

function ui.setxiaohuobanIcon(itemTable,data,hideHint)

    if itemTable["phantomNode"] then
        itemTable["phantomNode"]:removeAllChildrenWithCleanup(true)
    end

    itemTable["g_lock"]:setVisible(false)
    itemTable["g_status"]:setVisible(false)
    itemTable["g_icon"]:setVisible(true)
    setSpriteFrameByName(itemTable["g_k_quality"], "b_iconk1")
    setSpriteFrameByName(itemTable["g_icon"], "xiaohuoban")

    if not hideHint then
        ui.sethint(itemTable["g_hint"],GameScene.hintdata["2"] and  GameScene.hintdata["2"]>0)
    end    
end

function ui.setslotgemsIcon(itemTable,data,hideHint)

    if itemTable["phantomNode"] then
        itemTable["phantomNode"]:removeAllChildrenWithCleanup(true)
    end
    
    itemTable["g_lock"]:setVisible(false)
    itemTable["g_status"]:setVisible(false)
    itemTable["g_icon"]:setVisible(true)
    setSpriteFrameByName(itemTable["g_k_quality"], "b_iconk1")
    setSpriteFrameByName(itemTable["g_icon"], "mofu")
    if not hideHint then
        ui.sethint(itemTable["g_hint"],GameScene.hintdata["158"] and  GameScene.hintdata["158"]>0)
    end    
--    if data then
--        ui.sethint(itemTable["g_hint"],false)
--        for k,v in pairs(data) do
--            if v.isopen then
--                ui.sethint(itemTable["g_hint"],true)
--                break
--            end
--        end
--    end
end


function ui.setStars(quality,itemTable,id)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    for i = 1, 5 do
        if (i <= quality) then
            itemTable["ccb_qualitystar_"..i..key_Ex]:setVisible(true)
        else
            itemTable["ccb_qualitystar_"..i..key_Ex]:setVisible(false)
        end
    end

    itemTable["ccb_qualitystar_node"..key_Ex]:setPositionX((5-quality)*40)
end

function ui.setStar(quality,itemTable)
    for i=1, 3 do
        if i <= data.star then
            setSpriteFrameByName(item["star"..i], gameConfig.images.starON)
        else
            setSpriteFrameByName(item["star"..i], gameConfig.images.starOFF)
        end
    end
end

function ui.tableviewAnimation(tableview,ccb,x,y,index,const)
    if tableview and (not const) then
        ccb:setPosition(x, y)
    else
        ccb:setPosition(0 - index*400, y)
        local moveTo = CCMoveTo:create(0.05 + index*0.05, ccp(x, y))
        local backOut = CCEaseExponentialOut:create(moveTo)
        ccb:runAction(backOut)
    end
end

function ui.tableviewAnimationH(tableview,ccb,w,h,index)
    if tableview then
        ccb:setPosition(w/2, h/2)
    else
        ccb:setPosition(w/2 + 400, h/2)
        local moveTo = CCMoveTo:create(0.05 + index*0.05, ccp(w/2, h/2))
        local backOut = CCEaseExponentialOut:create(moveTo)
        ccb:runAction(backOut)
    end
end

function ui.tableviewAnimationSlow(tableview,ccb,x,y,index)
    if tableview then
        ccb:setPosition(x, y)
    else
        ccb:setPosition(0 - index*400, y)
        local moveTo = CCMoveTo:create(0.25 + index*0.25, ccp(x, y))
        local backOut = CCEaseExponentialOut:create(moveTo)
        ccb:runAction(backOut)
    end
end


function ui.setGeneralIconL2(dataTable,itemTable,id)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    if  dataTable.quality ~= nil then
        setSpriteFrameByName(itemTable["g_quality"..key_Ex], gameConfig.images["l_g_q_back_"..dataTable.quality])
    end

    if dataTable.icon ~= "" then
        setSpriteFrameByName(itemTable["g_icon"..key_Ex],dataTable["icon"])
    end

    itemTable["g_level"..key_Ex]:setString("等级. "..dataTable.level)
    if dataTable.actor and dataTable.actor == "lead" then
        if dataTable.quality and dataTable.quality >= 7 then
            ui.setLabelString(itemTable["g_name"..key_Ex],ui.leadName(GameScene.protagonist.level2), 214)
        else
            ui.setLabelString(itemTable["g_name"..key_Ex],ui.leadName(GameScene.protagonist.level2), dataTable.quality and 2*dataTable.quality or 1)
        end    
    else    
        if dataTable.quality and dataTable.quality >= 7 then
            ui.setLabelString(itemTable["g_name"..key_Ex],(dataTable.name == gameConfig.strings:string_common("ui",3) and GameScene.roleinfo.name or dataTable.name)..(dataTable.level2>0 and " +"..dataTable.level2 or ""), 214)
        else
            ui.setLabelString(itemTable["g_name"..key_Ex],(dataTable.name == gameConfig.strings:string_common("ui",3) and GameScene.roleinfo.name or dataTable.name)..(dataTable.level2>0 and " +"..dataTable.level2 or ""), dataTable.quality and 2*dataTable.quality or 1)
        end
    end
    if dataTable.hppercent and itemTable["hpBar"..key_Ex] then
        ui.setSpriteTextureRect2(itemTable["hpBar"..key_Ex],0,0,125*(dataTable.hppercent < 100 and dataTable.hppercent/100 or 1),14)
    end

    if not gameConfig.images[dataTable.actor] then
        setSpriteFrameByName(itemTable["g_type"..key_Ex], gameConfig.images.alpha)
    else
        setSpriteFrameByName(itemTable["g_type"..key_Ex], gameConfig.images[dataTable.actor])
    end
    if not dataTable.awakenstage or dataTable.awakenstage == -1  then
        ui.setLabelString(itemTable["g_juexing_stage"..key_Ex],"",18)
    else
        ui.setLabelString(itemTable["g_juexing_stage"..key_Ex],dataTable.awakenstage,18)
    end
    if not dataTable.awakenicon or dataTable.awakenstage == -1 then
        setSpriteFrameByName(itemTable["g_juexing_icon"..key_Ex], gameConfig.images.alpha)
    else
        setSpriteFrameByName(itemTable["g_juexing_icon"..key_Ex], dataTable.awakenicon)
    end    
end

function ui.tableviewLocation(tableview,cellnum,touchindex,scroll,selectcell,y_big,y_small)

    local touchIndex = touchindex
    local location = tableview:getLuaContentOffsetY()

    if selectcell and selectcell == touchIndex then
        selectcell = nil
        location= location + y_big-y_small
    elseif selectcell and selectcell ~= touchIndex then
        selectcell =  touchIndex
    elseif not  selectcell then
        selectcell = touchIndex
        location= location - y_big+y_small
    end

    if touchIndex == cellnum and scroll:getContentSize().height < cellnum*y_small + (selectcell and (y_big-y_small) or 0) then
        location = 0
    elseif selectcell and location<0 and location < -y_small*(cellnum-touchIndex) then
        location = -y_small*(cellnum-touchIndex)
    end

    return selectcell, location
end

local labcolors = {
    {color = ccc3(249,202,153)},
    {color = ccc3(93,227,90)},
    {color = ccc3(121,203,255)},
    {color = ccc3(226,111,255)},
    {color = ccc3(255,132,0)},
    {color = ccc3(255,0,0)},
    {color = ccc3(255,0,0)}
}

function ui.setLabQuality(label,name,quality,size)
    print("setLabQuality",type(quality),quality)
    local strokeparam = quality >= 6 and 22 or (quality + 4)
    label:setColor(labcolors[quality].color)
    label:setFontSize(size)
    label:setString(name)
    ui.setStringWithStrokeAndShadow(label,nil,strokeparam,nil)
end

function ui.i_k_quality(config)
    if config.staffType=="general" and config.quality ==5 and config.basic >=20 then
        return "b_iconk5_"..config.basic
    else
        return "b_iconk"..(config.quality and config.quality>1 and config.quality or 1)
    end
end

function ui.i_bg_quality(config)
    return "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1)
end

function ui.ccbNameEx(name,id)
    local key_Ex
    if id == nil or id == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(id-1)
    end

    return name..key_Ex
end

function ui.resetNewIcon(item,id)

    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    setSpriteFrameByName(item["i_icon"..key_Ex], "alpha")
    setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk1")
    setSpriteFrameByName(item["i_quality"..key_Ex], "b_iconbg1")
    item["i_soulsprite"..key_Ex]:setVisible(false)
    item["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
    item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    item["i_num"..key_Ex]:setString("")
    if item["star_starnode"..key_Ex] then
        item["star_starnode"..key_Ex]:setVisible(false)
    end
end

function ui.createPhantomIcon(root)
    local phantomIcon = CCSprite:create()
    phantomIcon:setPosition(20,20)
    setSpriteFrameByName(phantomIcon,"huanhuaIcon")
    root:addChild(phantomIcon)
    return phantomIcon
end

function ui.setNewIcon(item,data,id,starData,gdata)

    if data and next(data) then
        local config =
        {
            icon = data.icon,
            num = data.num or "",
            stroke = data.stroke or 2,
            quality = data.quality,
            name = data.name or "",
        }

        if data.cid then
            config = table.merge(ui.IDconfig(data.cid) or {}, config)
        end

        if data.staffType then
            config.staffType = data.staffType
        end

        if data.skilllevel and config.basic then
            config.basic = config.basic > gamedata.config.general_awaken[tostring(data.skilllevel)].basic and config.basic or gamedata.config.general_awaken[tostring(data.skilllevel)].basic 
        end

        local key_Ex
        if id == nil or id == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..id
        end

        print("jkp-staffType-NewIcon = ",config.staffType)
        if config.staffType then
            if (config.staffType == "iconBox" or config.staffType == "title") then
                if item["i_soulnode"..key_Ex] then item["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true) end
                if item["i_suitNode"..key_Ex] then item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true) end
        
                if item["i_quality"..key_Ex] then
                    item["i_quality"..key_Ex]:setVisible(false)
                end
                if item["i_k_quality"..key_Ex] then
                    item["i_k_quality"..key_Ex]:setVisible(false)
                end
                if item["i_soulsprite"..key_Ex] then
                    item["i_soulsprite"..key_Ex]:setVisible(false)
                end
                if item["i_icon"..key_Ex] then
                    setSpriteFrameByName(item["i_icon"..key_Ex], config.icon and config.icon or "alpha")
                    item["i_icon"..key_Ex]:setScale(0.85)
                end
                
                if item["i_num"..key_Ex] then
                    item["i_num"..key_Ex]:setString("")
                end
                return
            elseif config.staffType == "phantom" then
                if item["phantomNode"..key_Ex] then
                    item["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                    ui.createPhantomIcon(item["phantomNode"..key_Ex])
                end
            else
                if item["phantomNode"..key_Ex] then
                    item["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                end
                if item["i_quality"..key_Ex] then
                    item["i_quality"..key_Ex]:setVisible(true)
                end
                if item["i_k_quality"..key_Ex] then
                    item["i_k_quality"..key_Ex]:setVisible(true)
                end
                if item["i_soulsprite"..key_Ex] then
                    item["i_soulsprite"..key_Ex]:setVisible(true)
                end
                if item["i_icon"..key_Ex] then
                    item["i_icon"..key_Ex]:setScale(1)
                end
            end

            if item["i_soulsprite"..key_Ex] then
                if config.staffType == "red_fragment" then
                    setSpriteFrameByName(item["i_soulsprite"..key_Ex], "b_soulsprite2")
                elseif config.staffType == "general_fragment" then
                    setSpriteFrameByName(item["i_soulsprite"..key_Ex], "b_soulsprite")
                elseif (config.staffType == "equip_fragment" or config.staffType == "treasure_fragment" or config.staffType == "pet_fragment" or config.staffType == "token_fragment") then
                    setSpriteFrameByName(item["i_soulsprite"..key_Ex], "b_sprite1")
                else
                    setSpriteFrameByName(item["i_soulsprite"..key_Ex], "alpha")
                end
            end

        else
            if item["phantomNode"..key_Ex] then
                item["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
            end
            if item["i_quality"..key_Ex] then
                item["i_quality"..key_Ex]:setVisible(true)
            end
            if item["i_k_quality"..key_Ex] then
                item["i_k_quality"..key_Ex]:setVisible(true)
            end
            if item["i_soulsprite"..key_Ex] then
                item["i_soulsprite"..key_Ex]:setVisible(true)
                setSpriteFrameByName(item["i_soulsprite"..key_Ex], "alpha")
            end
            if item["i_icon"..key_Ex] then
                item["i_icon"..key_Ex]:setScale(1)
            end
            
        end

        -- 设置数量
        print("jkp-num = ",config.num)
        if item["i_num"..key_Ex] and config.num then
            item["i_num"..key_Ex]:setString(config.num)
            ui.setLabelString(item["i_num"..key_Ex], nil, 13)
        end

        if item["i_soulnode"..key_Ex] then item["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true) end

        if item["i_name"..key_Ex] then
            if not config.name or config.name == "" then
                item["i_name"..key_Ex]:setString("")
            else
                item["i_name"..key_Ex]:setString(config.name or "")
            end
            if config.quality and config.quality >= 7 then
                ui.setLabelString(item["i_name"..key_Ex],nil, 213)
            else
                ui.setLabelString(item["i_name"..key_Ex],nil,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
            end
        end

        if item["i_limitSpr"..key_Ex] then
            if config.staffType and config.staffType == "countdownGift" then
                setSpriteFrameByName(item["i_limitSpr"..key_Ex], "b_sprite24")
            else
                setSpriteFrameByName(item["i_limitSpr"..key_Ex], "alpha")
            end
        end 

        if item["i_k_quality"..key_Ex] then
            if data.iconBox and data.iconBox > 0 and data.iconBox ~= gameConfig.defautIconBoxId then
                local config = ui.IDconfig(data.iconBox)
                setSpriteFrameByName(item["i_k_quality"..key_Ex], config.icon or "b_icon3")
            else
                if config.staffType and config.staffType == "general" and config.quality == 5 and config.basic and config.basic >= 20 then
                    setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk5_"..config.basic )
                else
                    setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
                end
            end
        end

        if item["i_quality"..key_Ex] then
            setSpriteFrameByName(item["i_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
        end

        if item["i_icon"..key_Ex] then
            if config.staffType then
                if config.staffType == "soul" then
                    setSpriteFrameByName(item["i_icon"..key_Ex], "alpha")
                    local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..config.icon..".ccbi", nil, true, config.icon)
                    item["i_soulnode"..key_Ex]:addChild(ccb)
                elseif config.staffType == "skill" then
                    if gdata then
                        local configskill = ui.IDconfig(gdata.skillid) or {}
                        setSpriteFrameByName(item["i_icon"..key_Ex], configskill.icon and configskill.icon or "alpha")
                    else
                        setSpriteFrameByName(item["i_icon"..key_Ex], config.icon and config.icon or "alpha")
                    end
                elseif config.staffType == "combskill" then
                    if gdata then
                        local configskill = ui.IDconfig(gdata.combskillid) or {}
                        if gdata.passiveskills and gdata.passiveskills > 0 then
                            configskill = ui.IDconfig(gdata.passiveskills) or {}
                        end
                        setSpriteFrameByName(item["i_icon"..key_Ex], configskill.icon and configskill.icon or "alpha")
                    else
                        setSpriteFrameByName(item["i_icon"..key_Ex], config.icon and config.icon or "alpha")
                    end
                else
                    if gdata then
                        setSpriteFrameByName(item["i_icon"..key_Ex], gdata.icon and gdata.icon or "alpha")
                    else
                        setSpriteFrameByName(item["i_icon"..key_Ex], config.icon and config.icon or "alpha")
                    end
                end
            else
                if gdata then
                    setSpriteFrameByName(item["i_icon"..key_Ex], gdata.icon and gdata.icon or "alpha")
                else
                    setSpriteFrameByName(item["i_icon"..key_Ex], config.icon and config.icon or "alpha")
                end
            end
            ui.setSpriteTextureRect(item["i_icon"..key_Ex],0,0,150,150)
        end
    
        if item["i_suitNode"..key_Ex] then
            item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
            if (data.cid or data.id) then
                local config = ui.IDconfig(data.cid or data.id) or {}
                local equipconfig = config or {}
                if config.staffType == "equip_fragment" then
                    equipconfig = ui.IDconfig(config.equip) or {}
                end
                item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                if equipconfig.suit and equipconfig.suit ~= 0 and equipconfig.staffType ~= "qiling" then
                    local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..config.quality..".ccbi", nil, true, "icon")
                    item["i_suitNode"..key_Ex]:addChild(suitccb,1,100)
                    suititem.partical:setPositionType(kCCPositionTypeGrouped)
                end
            end
        end

        if config.staffType and config.staffType == "artifact" then
            if item["i_quality"..key_Ex] then
                setSpriteFrameByName(item["i_quality"..key_Ex], "b_iconbg7")
            end
            if item["i_suitNode"..key_Ex] and config.goldTrump and config.goldTrump > 0 then
                item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                local suitccb, suititem = CCBReaderLoad("UIEffect/teshugongxi/teshugongxi.ccbi", nil, true, "teshugongxi")
                item["i_suitNode"..key_Ex]:addChild(suitccb,1,100)
            end
        end

        --称号
        if item["titlenode"..key_Ex] then
            if data.title and data.title > 0 then
                if data.title == gameConfig.defautTitleId then
                    item["titlenode"..key_Ex]:setVisible(false)
                else
                    local config = ui.IDconfig(data.title)
                    item["titlenode"..key_Ex]:setVisible(true)
                    setSpriteFrameByName(item["titleicon"..key_Ex], config.icon and config.icon or "alpha")
                end
            else
                item["titlenode"..key_Ex]:setVisible(false)
            end
        end

        -- 添加升星显示设置
        if not item["star_starnode"..key_Ex] then return end
        if starData and starData.cid then
            local config = ui.IDconfig(starData.cid) or {}
            if starData and (starData.level3 and starData.level3 ~= 0) and 
            (config.type == "weapon" or config.type == "head" or config.type == "armor" or config.type == "accessory" or config.type == "treasure" or config.type == "horse") then
                item["star_starnode"..key_Ex]:setVisible(true) 
                print("configtype===1111",config.type)
                ui.setStarShow(item,starData,key_Ex)
            else
                print("configtype===222",config.type)
                item["star_starnode"..key_Ex]:setVisible(false) 
            end
        else
            item["star_starnode"..key_Ex]:setVisible(false) 
        end

        --
        if item["i_extranode"..key_Ex] then
            if data.extra and data.extra == 1 then
                item["i_extranode"..key_Ex]:setVisible(true)
            else
                item["i_extranode"..key_Ex]:setVisible(false)
            end    
        end  

    end

end

function ui.setNewIcon_f(item,data,id,starData,gdata)

    if data and next(data) then
        local config =
        {
            icon = data.icon,
            num = data.num or "",
            stroke = data.stroke or 2,
            quality = data.quality,
            name = data.name or "",
        }

        if data.cid then
            config = table.merge(ui.IDconfig(data.cid) or {},config)
        end

        if data.staffType then
            config.staffType = data.staffType
        end

        if data.skilllevel and config.basic then
            config.basic = config.basic > gamedata.config.general_awaken[tostring(data.skilllevel)].basic and config.basic or gamedata.config.general_awaken[tostring(data.skilllevel)].basic 
        end

        local key_Ex
        if id == nil or id == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..id
        end

        print("jkp-staffType-NewIcon_f = ",config.staffType)
        if config.staffType then
            if (config.staffType == "iconBox" or config.staffType == "title") then
                if item["i_soulnode_f"..key_Ex] then item["i_soulnode_f"..key_Ex]:removeAllChildrenWithCleanup(true) end
                if item["i_suitNode_f"..key_Ex] then item["i_suitNode_f"..key_Ex]:removeAllChildrenWithCleanup(true) end
        
                item["i_quality_f"..key_Ex]:setVisible(false)
                item["i_k_quality_f"..key_Ex]:setVisible(false)
                item["i_soulsprite_f"..key_Ex]:setVisible(false)
                setSpriteFrameByName(item["i_icon_f"..key_Ex], config.icon and config.icon or "alpha")
                item["i_icon_f"..key_Ex]:setScale(0.85)

                if item["i_num_f"..key_Ex] then
                    ui.setLabelString(item["i_num_f"..key_Ex], "", 13)
                end
                return
            elseif config.staffType == "phantom" then
                if item["phantomNode_f"..key_Ex] then
                    item["phantomNode_f"..key_Ex]:removeAllChildrenWithCleanup(true)
                    ui.createPhantomIcon(item["phantomNode_f"..key_Ex])
                end
            else
                if item["phantomNode_f"..key_Ex] then
                    item["phantomNode_f"..key_Ex]:removeAllChildrenWithCleanup(true)
                end
                item["i_quality_f"..key_Ex]:setVisible(true)
                item["i_k_quality_f"..key_Ex]:setVisible(true)
                item["i_soulsprite_f"..key_Ex]:setVisible(true)
                item["i_icon_f"..key_Ex]:setScale(1)
            end

            if config.staffType == "red_fragment" then
                setSpriteFrameByName(item["i_soulsprite_f"..key_Ex], "b_soulsprite2")
            elseif config.staffType == "general_fragment" then
                setSpriteFrameByName(item["i_soulsprite_f"..key_Ex], "b_soulsprite")
            elseif (config.staffType == "equip_fragment" or config.staffType == "treasure_fragment" or config.staffType == "pet_fragment" or config.staffType == "token_fragment") then
                setSpriteFrameByName(item["i_soulsprite_f"..key_Ex], "b_sprite1")
            else
                setSpriteFrameByName(item["i_soulsprite_f"..key_Ex], "alpha")
            end

        else
            if item["phantomNode_f"..key_Ex] then
                item["phantomNode_f"..key_Ex]:removeAllChildrenWithCleanup(true)
            end
            item["i_quality_f"..key_Ex]:setVisible(true)
            item["i_k_quality_f"..key_Ex]:setVisible(true)
            item["i_soulsprite_f"..key_Ex]:setVisible(true)
            item["i_icon_f"..key_Ex]:setScale(1)

            setSpriteFrameByName(item["i_soulsprite_f"..key_Ex], "alpha")
        end

        -- 设置数量
        print("jkp-num = ", config.num)
        if item["i_num_f"..key_Ex] and config.num then
            item["i_num_f"..key_Ex]:setString(config.num)
            ui.setLabelString(item["i_num_f"..key_Ex], nil, 13)
        end

        if item["i_soulnode_f"..key_Ex] then item["i_soulnode_f"..key_Ex]:removeAllChildrenWithCleanup(true) end

        if item["i_name_f"..key_Ex] then
            if not config.name or config.name == "" then
                item["i_name_f"..key_Ex]:setString("")
            else
                item["i_name_f"..key_Ex]:setString(config.name or "")
            end
            if config.quality and config.quality >= 7 then
                ui.setLabelString(item["i_name_f"..key_Ex],nil, 213)
            else
                ui.setLabelString(item["i_name_f"..key_Ex],nil,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
            end
        end

        if item["i_limitSpr_f"..key_Ex] then
            if config.staffType and config.staffType == "countdownGift" then
                setSpriteFrameByName(item["i_limitSpr_f"..key_Ex], "b_sprite24")
            else
                setSpriteFrameByName(item["i_limitSpr_f"..key_Ex], "alpha")
            end
        end 

        if data.iconBox and data.iconBox > 0 and data.iconBox ~= gameConfig.defautIconBoxId then
            local config = ui.IDconfig(data.iconBox)
            setSpriteFrameByName(item["i_k_quality_f"..key_Ex], config.icon or "b_icon3")
        else
            if config.staffType and config.staffType == "general" and config.quality == 5 and config.basic >= 20 then
                setSpriteFrameByName(item["i_k_quality_f"..key_Ex], "b_iconk5_"..config.basic )
            else
                setSpriteFrameByName(item["i_k_quality_f"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
            end
        end

        setSpriteFrameByName(item["i_quality_f"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))

        if config.staffType then
            if config.staffType == "soul" then
                setSpriteFrameByName(item["i_icon_f"..key_Ex], "alpha")
                local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..config.icon..".ccbi", nil, true, config.icon)
                item["i_soulnode_f"..key_Ex]:addChild(ccb)
            elseif config.staffType == "skill" then
                if gdata then
                    local configskill = ui.IDconfig(gdata.skillid) or {}
                    setSpriteFrameByName(item["i_icon_f"..key_Ex], configskill.icon and configskill.icon or "alpha")
                else
                    setSpriteFrameByName(item["i_icon_f"..key_Ex], config.icon and config.icon or "alpha")
                end
            elseif config.staffType == "combskill" then
                if gdata then
                    local configskill = ui.IDconfig(gdata.combskillid) or {}
                    if gdata.passiveskills and gdata.passiveskills > 0 then
                        configskill = ui.IDconfig(gdata.passiveskills) or {}
                    end
                    setSpriteFrameByName(item["i_icon_f"..key_Ex], configskill.icon and configskill.icon or "alpha")
                else
                    setSpriteFrameByName(item["i_icon_f"..key_Ex], config.icon and config.icon or "alpha")
                end
            else
                if gdata then
                    setSpriteFrameByName(item["i_icon_f"..key_Ex], gdata.icon and gdata.icon or "alpha")
                else
                    setSpriteFrameByName(item["i_icon_f"..key_Ex], config.icon and config.icon or "alpha")
                end
            end
        else
            if gdata then
                setSpriteFrameByName(item["i_icon_f"..key_Ex], gdata.icon and gdata.icon or "alpha")
            else
                setSpriteFrameByName(item["i_icon_f"..key_Ex], config.icon and config.icon or "alpha")
            end
        end
        ui.setSpriteTextureRect(item["i_icon_f"..key_Ex],0,0,150,150)

        if item["i_suitNode_f"..key_Ex] then
            item["i_suitNode_f"..key_Ex]:removeAllChildrenWithCleanup(true)
            if (data.cid or data.id) then
                local config = ui.IDconfig(data.cid or data.id) or {}
                local equipconfig = config or {}
                if config.staffType == "equip_fragment" then
                    equipconfig = ui.IDconfig(config.equip) or {}
                end
                item["i_suitNode_f"..key_Ex]:removeAllChildrenWithCleanup(true)
                if equipconfig.suit and equipconfig.suit ~= 0 and equipconfig.staffType ~= "qiling" then
                    local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..config.quality..".ccbi", nil, true, "icon")
                    item["i_suitNode_f"..key_Ex]:addChild(suitccb,1,100)
                    suititem.partical:setPositionType(kCCPositionTypeGrouped)
                end
            end
        end

        if config.staffType and config.staffType == "artifact" then
            setSpriteFrameByName(item["i_quality_f"..key_Ex], "b_iconbg7")
            if item["i_suitNode_f"..key_Ex] and config.goldTrump and config.goldTrump > 0 then
                local suitccb, suititem = CCBReaderLoad("UIEffect/teshugongxi/teshugongxi.ccbi", nil, true, "teshugongxi")
                item["i_suitNode_f"..key_Ex]:addChild(suitccb,1,100)
            end
        end

        --称号
        if item["titlenode_f"..key_Ex] then
            if data.title and data.title > 0 then
                if data.title == gameConfig.defautTitleId then
                    item["titlenode_f"..key_Ex]:setVisible(false)
                else
                    local config = ui.IDconfig(data.title)
                    item["titlenode_f"..key_Ex]:setVisible(true)
                    setSpriteFrameByName(item["titleicon_f"..key_Ex], config.icon and config.icon or "alpha")
                end
            else
                item["titlenode_f"..key_Ex]:setVisible(false)
            end
        end

        -- 添加升星显示设置
        if not item["star_starnode_f"..key_Ex] then return end
        if starData and starData.cid then
            local config = ui.IDconfig(starData.cid) or {}
            if starData and (starData.level3 and starData.level3 ~= 0) and 
            (config.type == "weapon" or config.type == "head" or config.type == "armor" or config.type == "accessory" or config.type == "treasure" or config.type == "horse") then

                item["star_starnode_f"..key_Ex]:setVisible(true) 
                ui.setStarShow(item,starData,key_Ex)
            else
                item["star_starnode_f"..key_Ex]:setVisible(false) 
            end
        else
            item["star_starnode_f"..key_Ex]:setVisible(false) 
        end

        --
        if item["i_extranode_f"..key_Ex] then
            if data.extra and data.extra == 1 then
                item["i_extranode_f"..key_Ex]:setVisible(true)
            else
                item["i_extranode_f"..key_Ex]:setVisible(false)
            end    
        end 

    end

end

function ui.setPropIcon(item,data,id,starData,gdata)

    if data and next(data) then
        local config =
        {
            icon = data.icon,
            num = data.num or "",
            stroke = data.stroke or 2,
        }

        if data.cid then
            config = table.merge(ui.IDconfig(data.cid) or {},config)
        end

        if data.staffType then
            config.staffType = data.staffType
        end

        if data.skilllevel and config.basic then
            config.basic = config.basic > gamedata.config.general_awaken[tostring(data.skilllevel)].basic and config.basic or gamedata.config.general_awaken[tostring(data.skilllevel)].basic 
        end

        local key_Ex
        if id == nil or id == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..id
        end

        print("jkp-staffType_PropIcon = ",config.staffType)
        if config.staffType then
            if (config.staffType == "iconBox" or config.staffType == "title") then
                if item["i_soulnode"..key_Ex] then item["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true) end
                if item["i_suitNode"..key_Ex] then item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true) end
        
                item["i_quality"..key_Ex]:setVisible(false)
                item["i_k_quality"..key_Ex]:setVisible(false)
                item["i_soulsprite"..key_Ex]:setVisible(false)
                setSpriteFrameByName(item["i_icon"..key_Ex], config.icon and config.icon or "alpha")
                item["i_icon"..key_Ex]:setScale(0.85)

                if item["i_num"..key_Ex] then
                    item["i_num"..key_Ex]:setString("")
                end
                return
            else
                item["i_quality"..key_Ex]:setVisible(true)
                item["i_k_quality"..key_Ex]:setVisible(true)
                item["i_soulsprite"..key_Ex]:setVisible(true)
                item["i_icon"..key_Ex]:setScale(1)
            end

            if config.staffType == "red_fragment" then
                -- 红将精华
                setSpriteFrameByName(item["i_soulsprite"..key_Ex], "b_soulsprite2")
            elseif (config.staffType == "equip_fragment" or config.staffType == "treasure_fragment" or config.staffType == "pet_fragment" or config.staffType == "token_fragment") then
                -- 碎片
                setSpriteFrameByName(item["i_soulsprite"..key_Ex], "b_sprite1")
            else
                setSpriteFrameByName(item["i_soulsprite"..key_Ex], "alpha")
            end
        else
            item["i_quality"..key_Ex]:setVisible(true)
            item["i_k_quality"..key_Ex]:setVisible(true)
            item["i_soulsprite"..key_Ex]:setVisible(true)
            item["i_icon"..key_Ex]:setScale(1)

            setSpriteFrameByName(item["i_soulsprite"..key_Ex], "alpha")
        end

        if item["i_soulnode"..key_Ex] then item["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true) end

        if item["i_name"..key_Ex] then
            if not config.name or config.name == "" then
                item["i_name"..key_Ex]:setString("")
            else
                item["i_name"..key_Ex]:setString(config.name or "")
            end
            if config.quality and config.quality >= 7 then
                ui.setLabelString(item["i_name"..key_Ex],nil, 213)
            else
                ui.setLabelString(item["i_name"..key_Ex],nil,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
            end
        end
    
        -- 设置数量
        print("jkp-num = ",config.num)
        if item["i_num"..key_Ex] and config.num then
            item["i_num"..key_Ex]:setString(config.num)
            ui.setLabelString(item["i_num"..key_Ex], nil, 13)
        end

        if item["i_limitSpr"..key_Ex] then
            if config.staffType and config.staffType == "countdownGift" then
                setSpriteFrameByName(item["i_limitSpr"..key_Ex], "b_sprite24")
            else
                setSpriteFrameByName(item["i_limitSpr"..key_Ex], "alpha")
            end
        end 

        if data.iconBox and data.iconBox > 0 and data.iconBox ~= gameConfig.defautIconBoxId then
            local config = ui.IDconfig(data.iconBox)
            setSpriteFrameByName(item["i_k_quality"..key_Ex], config.icon or "b_icon3")
        else
            if config.staffType and config.staffType == "general" and config.quality == 5 and config.basic >= 20 then
                setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk5_"..config.basic )
            else
                setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
            end
        end

        setSpriteFrameByName(item["i_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))

        if config.staffType and config.staffType == "soul" then
            setSpriteFrameByName(item["i_icon"..key_Ex], "alpha")
            local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..config.icon..".ccbi", nil, true, config.icon)
            item["i_soulnode"..key_Ex]:addChild(ccb)
        else
            if gdata then
                setSpriteFrameByName(item["i_icon"..key_Ex], gdata.icon and gdata.icon or "alpha")
            else
                setSpriteFrameByName(item["i_icon"..key_Ex], config.icon and config.icon or "alpha")
            end
            ui.setSpriteTextureRect(item["i_icon"..key_Ex],0,0,150,150)
        end

        if item["i_suitNode"..key_Ex] then
            item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
            if (data.cid or data.id) then
                local config = ui.IDconfig(data.cid or data.id) or {}
                local equipconfig = config or {}
                if config.staffType == "equip_fragment" then
                    equipconfig = ui.IDconfig(config.equip) or {}
                end
                item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                if equipconfig.suit and equipconfig.suit ~= 0 and equipconfig.staffType ~= "qiling" then
                    local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..config.quality..".ccbi", nil, true, "icon")
                    item["i_suitNode"..key_Ex]:addChild(suitccb,1,100)
                    suititem.partical:setPositionType(kCCPositionTypeGrouped)
                end
            end
        end

        if config.staffType and config.staffType == "artifact" then
            setSpriteFrameByName(item["i_quality"..key_Ex], "b_iconbg7")
            if item["i_suitNode"..key_Ex] and config.goldTrump and config.goldTrump > 0 then
                local suitccb, suititem = CCBReaderLoad("UIEffect/teshugongxi/teshugongxi.ccbi", nil, true, "teshugongxi")
                item["i_suitNode"..key_Ex]:addChild(suitccb,1,100)
            end
        end

        -- 添加升星显示设置
        if not item["star_starnode"..key_Ex] then return end
        if starData and starData.cid then
            local config = ui.IDconfig(starData.cid) or {}
            if starData and (starData.level3 and starData.level3 ~= 0) and 
            (config.type == "weapon" or config.type == "head" or config.type == "armor" or config.type == "accessory" or config.type == "treasure" or config.type == "horse") then
                item["star_starnode"..key_Ex]:setVisible(true)
                ui.setStarShow(item,starData,key_Ex)
            else
                item["star_starnode"..key_Ex]:setVisible(false) 
            end

            if item["i_level"..key_Ex] then
                if starData and (starData.level1 and starData.level1 ~= 0) then
                    if (config.type == "weapon" or config.type == "head" or config.type == "armor" or config.type == "accessory") then
                        ui.setLabelString(item["i_level"..key_Ex], "LV:"..starData.level1, 13)
                    else
                        ui.setLabelString(item["i_num"..key_Ex], "LV:"..starData.level1, 13)
                    end
                end
            end

            if item["i_isonNode"..key_Ex] then
                if starData.ison and starData.ison == 1 then
                    item["i_isonNode"..key_Ex]:setVisible(true)
                    item["i_isonLab"..key_Ex]:setString("已装备")
                else
                    item["i_isonNode"..key_Ex]:setVisible(false)
                end
            end
        else
            item["star_starnode"..key_Ex]:setVisible(false) 
        end

        --
        if item["i_extranode"..key_Ex] then
            if data.extra and data.extra == 1 then
                item["i_extranode"..key_Ex]:setVisible(true)
            else
                item["i_extranode"..key_Ex]:setVisible(false)
            end
        end
    end
  
end

function ui.setNewIconName(item,data,id)

    if data and next(data) then
        local config =
        {
            icon = data.icon,
            numdesc = data.numdesc or "",
            num = data.num or "",
            stroke = data.stroke or 13
        }

        if data.cid then
            config = table.merge(ui.IDconfig(data.cid) or {},config)
        end

        if data.staffType then
            config.staffType = data.staffType
        end

        if data.skilllevel and config.basic then
            config.basic = config.basic > gamedata.config.general_awaken[tostring(data.skilllevel)].basic and config.basic or gamedata.config.general_awaken[tostring(data.skilllevel)].basic 
        end

        local key_Ex
        if id == nil or id == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..id
        end

        print("jkp-staffType-iconName = ",config.staffType)
        if config.staffType then
            if (config.staffType == "iconBox" or config.staffType == "title") then
                if item["in_soulnode"..key_Ex] then item["in_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true) end
                if item["in_suitNode"..key_Ex] then item["in_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true) end
        
                item["in_quality"..key_Ex]:setVisible(false)
                item["in_k_quality"..key_Ex]:setVisible(false)
                item["in_soulsprite"..key_Ex]:setVisible(false)
                setSpriteFrameByName(item["in_icon"..key_Ex], config.icon and config.icon or "alpha")
                item["in_icon"..key_Ex]:setScale(0.85)
                if item["in_name"..key_Ex] then
                    if not config.name or config.name == "" then
                        item["in_name"..key_Ex]:setString("")
                    else
                        item["in_name"..key_Ex]:setString(config.name or "")
                    end
                    if config.quality and config.quality >= 7 then
                        ui.setLabelString(item["in_name"..key_Ex],nil,213)
                    else
                        ui.setLabelString(item["in_name"..key_Ex],nil,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
                    end
                end

                if item["i_num"..key_Ex] then
                    ui.setLabelString(item["i_num"..key_Ex], "", 13)
                end
                return
            elseif config.staffType == "phantom" then
                if item["phantomNode"..key_Ex] then
                    item["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                    ui.createPhantomIcon(item["phantomNode"..key_Ex])
                end
            else
                if item["phantomNode"..key_Ex] then
                    item["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                end
                item["in_quality"..key_Ex]:setVisible(true)
                item["in_k_quality"..key_Ex]:setVisible(true)
                item["in_soulsprite"..key_Ex]:setVisible(true)
                item["in_icon"..key_Ex]:setScale(1)
            end

            if config.staffType == "red_fragment" then
                setSpriteFrameByName(item["in_soulsprite"..key_Ex], "b_soulsprite2")
            elseif config.staffType == "general_fragment" then
                setSpriteFrameByName(item["in_soulsprite"..key_Ex], "b_soulsprite")
                ui.removeGray("CCSprite", item["in_soulsprite" .. key_Ex])
                if data.soulStatus == 0 then
                    ui.addGray("CCSprite", item["in_soulsprite" .. key_Ex])
                end   
            elseif (config.staffType == "equip_fragment" or config.staffType == "treasure_fragment" or config.staffType == "pet_fragment" or config.staffType == "token_fragment") then
                setSpriteFrameByName(item["in_soulsprite"..key_Ex], "b_sprite1")
            else
                setSpriteFrameByName(item["in_soulsprite"..key_Ex], "alpha")
            end

        else
            if item["phantomNode"..key_Ex] then
                item["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
            end
            item["in_quality"..key_Ex]:setVisible(true)
            item["in_k_quality"..key_Ex]:setVisible(true)
            item["in_soulsprite"..key_Ex]:setVisible(true)
            item["in_icon"..key_Ex]:setScale(1)

            setSpriteFrameByName(item["in_soulsprite"..key_Ex], "alpha")
        end

        if item["in_soulnode"..key_Ex] then item["in_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true) end

        -- 设置数量
        print("jkp-num = ",config.num)
        if item["in_num"..key_Ex] and config.num then
            item["in_num"..key_Ex]:setString(config.num)
            ui.setLabelString(item["in_num"..key_Ex],nil,13)
        end

        if item["in_name"..key_Ex] then
            if not config.name or config.name == "" then
                item["in_name"..key_Ex]:setString("")
            else
                local nameStr = config.name
                if config.staffType and config.staffType == "artifact" and config.goldTrump and config.goldTrump == 1 then
                    nameStr = gameConfig.strings:string_common("artifact",154).."·"..nameStr
                end
                item["in_name"..key_Ex]:setString(nameStr)
            end
            if config.quality and config.quality >= 7 then
                ui.setLabelString(item["in_name"..key_Ex],nil,213)
            else    
                ui.setLabelString(item["in_name"..key_Ex],nil,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
            end
        end

        if item["in_numdesc"..key_Ex] then
            if not config.numdesc or config.numdesc == "" then
                item["in_numdesc"..key_Ex]:setString("")
            else
                item["in_numdesc"..key_Ex]:setString(config.numdesc or "")
            end
            ui.setLabelString(item["in_numdesc"..key_Ex],nil,config.stroke)
        end

        if item["in_limitSpr"..key_Ex] then
            if config.staffType and config.staffType == "countdownGift" then
                setSpriteFrameByName(item["in_limitSpr"..key_Ex], "b_sprite24")
            else
                setSpriteFrameByName(item["in_limitSpr"..key_Ex], "alpha")
            end
        end
        
        if config.staffType and config.staffType == "general" and config.quality == 5 and config.basic >= 20 then
            setSpriteFrameByName(item["in_k_quality"..key_Ex], "b_iconk5_"..config.basic )
        else
            setSpriteFrameByName(item["in_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
        end

        setSpriteFrameByName(item["in_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))

        if config.staffType and config.staffType == "soul" then
            setSpriteFrameByName(item["in_icon"..key_Ex], "alpha")
            item["in_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
            local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..config.icon..".ccbi", nil, true, config.icon)
            item["in_soulnode"..key_Ex]:addChild(ccb)
        else
            setSpriteFrameByName(item["in_icon"..key_Ex], config.icon and config.icon or "alpha")
            ui.setSpriteTextureRect(item["in_icon"..key_Ex],0,0,150,150)
        end

        if item["in_suitNode"..key_Ex] then
            item["in_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
            if (data.cid or data.id) then
                local config = ui.IDconfig(data.cid or data.id) or {}
                local equipconfig = config or {}
                if config.staffType == "equip_fragment" then
                    equipconfig = ui.IDconfig(config.equip) or {}
                end
                item["in_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                if equipconfig.suit and equipconfig.suit ~= 0 and equipconfig.staffType ~= "qiling" then
                    local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..config.quality..".ccbi", nil, true, "icon")
                    item["in_suitNode"..key_Ex]:addChild(suitccb)
                    suititem.partical:setPositionType(kCCPositionTypeGrouped)
                end
            end
        end

        if config.staffType and config.staffType == "artifact" then
            setSpriteFrameByName(item["in_quality"..key_Ex], "b_iconbg7")
            if item["in_suitNode"..key_Ex] and config.goldTrump and config.goldTrump > 0 then
                item["in_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                local suitccb, suititem = CCBReaderLoad("UIEffect/teshugongxi/teshugongxi.ccbi", nil, true, "teshugongxi")
                item["in_suitNode"..key_Ex]:addChild(suitccb,1,100)
            end
        end

        --
        if item["in_extranode"..key_Ex] then
            if data.extra and data.extra == 1 then
                item["in_extranode"..key_Ex]:setVisible(true)
            else
                item["in_extranode"..key_Ex]:setVisible(false)
            end    
        end 
    end

end

function ui.setNewIconGuanxin(item,data,id)

    if data and next(data) then
        local config =
        {
            numdesc = data.numdesc or "",
            num = data.num or "",
            stroke = data.stroke or 2,
            starnum = data.starnum or "",
        }

        if data.cid then
            config = table.merge(ui.IDconfig(data.cid) or {},config)
        end

        if data.staffType then
            config.staffType = data.staffType
        end
        print("jkp-staffType-iconGuanxin = ", config.staffType)

        local key_Ex
        if id == nil or id == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..id
        end

        if item["in_soulnode"..key_Ex] then item["in_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true) end

        --设置数字
        print("jkp-num = ",config.num)
        if item["in_num"..key_Ex] then
            item["in_num"..key_Ex]:setString(config.num)
            ui.setLabelString(item["in_num"..key_Ex],nil,13)
        end
        
        if item["in_name"..key_Ex] then
            if not config.name or config.name == "" then
                item["in_name"..key_Ex]:setString("")
            else
                item["in_name"..key_Ex]:setString(config.name or "")
            end
            if config.quality and config.quality >= 7 then
                ui.setLabelString(item["in_name"..key_Ex],nil,213)
            else    
                ui.setLabelString(item["in_name"..key_Ex],nil,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
            end
        end

        if item["in_limitSpr"..key_Ex] then
            if config.staffType and config.staffType == "countdownGift" then
                setSpriteFrameByName(item["in_limitSpr"..key_Ex], "b_sprite24")
            else
                setSpriteFrameByName(item["in_limitSpr"..key_Ex], "alpha")
            end
        end

        if item["in_numdesc"..key_Ex] then
            if not config.numdesc or config.numdesc == "" then
                item["in_numdesc"..key_Ex]:setString("")
            else
                item["in_numdesc"..key_Ex]:setString(config.numdesc or "")
            end
            ui.setLabelString(item["in_numdesc"..key_Ex],nil,13)
        end

        if config.staffType and config.staffType == "red_fragment" then
            setSpriteFrameByName(item["in_soulsprite"..key_Ex], "b_soulsprite2")
        elseif config.staffType and config.staffType == "general_fragment" then
            setSpriteFrameByName(item["in_soulsprite"..key_Ex], "b_soulsprite")
        elseif config.staffType and (config.staffType == "equip_fragment" or config.staffType == "treasure_fragment" or config.staffType == "pet_fragment" or  config.staffType == "token_fragment") then
            setSpriteFrameByName(item["in_soulsprite"..key_Ex], "b_sprite1")
        else
            setSpriteFrameByName(item["in_soulsprite"..key_Ex], "alpha")
        end

        setSpriteFrameByName(item["in_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(item["in_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))

        if config.staffType and config.staffType == "soul" then
            setSpriteFrameByName(item["in_icon"..key_Ex], "alpha")
            item["in_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
            if config.icon then
                local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..config.icon..".ccbi", nil, true, config.icon)
                item["in_soulnode"..key_Ex]:addChild(ccb)
            end
        else
            setSpriteFrameByName(item["in_icon"..key_Ex], config.icon and config.icon or "alpha")
            ui.setSpriteTextureRect(item["in_icon"..key_Ex],0,0,150,150)
        end

        if item["in_suitNode"..key_Ex] then
            item["in_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
            if (data.cid or data.id) then
                local config = ui.IDconfig(data.cid or data.id) or {}
                local equipconfig = config or {}
                if config.staffType == "equip_fragment" then
                    equipconfig = ui.IDconfig(config.equip) or {}
                end
                if equipconfig.suit and equipconfig.suit ~= 0 and equipconfig.staffType ~= "qiling" then
                    local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..config.quality..".ccbi", nil, true, "icon")
                    item["in_suitNode"..key_Ex]:addChild(suitccb)
                    suititem.partical:setPositionType(kCCPositionTypeGrouped)
                end
            end
        end
    end

end


function ui.setIconLv(item,data,id,starData,showlv2)

    if data and next(data) then
        local config =
        {
            icon = data.icon,
            num = data.num or "",
            quality = data.quality,
        }

        if data.cid then
            config = table.merge(ui.IDconfig(data.cid) or {},config)
        end

        if data.staffType then
            config.staffType = data.staffType
        end
        print("jkp-staffType-iconLv = ", config.staffType)

        local key_Ex
        if id == nil or id == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..id
        end

        if data.cid and data.cid ~= 0 then
            if data.skilllevel  and config.skilllevel ~= -1 and config.basic then
                config.basic = config.basic > gamedata.config.general_awaken[tostring(data.skilllevel)].basic and config.basic or gamedata.config.general_awaken[tostring(data.skilllevel)].basic 
            end

            if config.staffType and (config.staffType == "iconBox" or config.staffType == "title") then
                if item["il_soulnode"..key_Ex] then item["il_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true) end
                if item["il_suitNode"..key_Ex] then item["il_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true) end
                
                item["il_quality"..key_Ex]:setVisible(false)
                item["il_kuang"..key_Ex]:setVisible(false)
                item["il_fragment"..key_Ex]:setVisible(false)
                setSpriteFrameByName(item["il_icon"..key_Ex], config.icon and config.icon or "alpha")
                item["il_icon"..key_Ex]:setScale(0.85)

                return
            elseif config.staffType and config.staffType == "phantom" then
                if item["phantomNode"..key_Ex] then
                    item["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                    ui.createPhantomIcon(item["phantomNode"..key_Ex])
                end
            else
                if item["phantomNode"..key_Ex] then
                    item["phantomNode"..key_Ex]:removeAllChildrenWithCleanup(true)
                end
    
                item["il_quality"..key_Ex]:setVisible(true)
                item["il_kuang"..key_Ex]:setVisible(true)
                item["il_fragment"..key_Ex]:setVisible(true)
                item["il_icon"..key_Ex]:setScale(1)
            end
    
            if data.iconBox and data.iconBox > 0 and data.iconBox ~= gameConfig.defautIconBoxId then
                local config = ui.IDconfig(data.iconBox) or {}
                setSpriteFrameByName(item["il_kuang"..key_Ex], config.icon or "b_icon3")
            else
                if config.staffType and config.staffType=="general" and config.quality ==5 and config.basic >=20 then
                    setSpriteFrameByName(item["il_kuang"..key_Ex], "b_iconk5_"..config.basic )
                else
                    setSpriteFrameByName(item["il_kuang"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
                end
            end
        
            setSpriteFrameByName(item["il_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
    
            if config.staffType and config.staffType == "soul" then
                setSpriteFrameByName(item["il_icon"..key_Ex], "alpha")
                item["il_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
                if config.icon then
                    local ccb,itemsoul = CCBReaderLoad("UIEffect/soul/"..config.icon..".ccbi", nil, true, config.icon)
                    item["il_soulnode"..key_Ex]:addChild(ccb)
                end
            else
                setSpriteFrameByName(item["il_icon"..key_Ex], config.icon and config.icon or "alpha")
                ui.setSpriteTextureRect(item["il_icon"..key_Ex],0,0,150,150)
            end
    
            local level = data.level or data.level1
            ui.setLabelString(item["il_lv"..key_Ex], level and "LV:"..level or "",13)
    
            --
            local level2 = data.level2 or 0
            if item["il_lv2"..key_Ex] then
                ui.setLabelString(item["il_lv2"..key_Ex], (level2>0 and showlv2) and ("+"..level2) or "",13)
            end
    
            if config.staffType and config.staffType == "general" then
                ui.setSpriteTextureRect(item["il_icon"..key_Ex],0,0,150,150)
            end
            --
            if config.staffType and config.staffType == "red_fragment" then
                setSpriteFrameByName(item["il_fragment"..key_Ex], "b_soulsprite2")
            elseif config.staffType and config.staffType == "general_fragment" then
                setSpriteFrameByName(item["il_fragment"..key_Ex], "b_soulsprite")
            elseif config.staffType and (config.staffType == "equip_fragment" or config.staffType == "treasure_fragment" or config.staffType == "pet_fragment" or config.staffType == "token_fragment") then
                setSpriteFrameByName(item["il_fragment"..key_Ex], "b_sprite1")
            else
                setSpriteFrameByName(item["il_fragment"..key_Ex], "alpha")
            end
    
            if item["il_limitSpr"..key_Ex] then
                if config.staffType and config.staffType == "countdownGift" then
                    setSpriteFrameByName(item["il_limitSpr"..key_Ex], "b_sprite24")
                else
                    setSpriteFrameByName(item["il_limitSpr"..key_Ex], "alpha")
                end
            end        
    
            item["il_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
            local equipconfig = config or {}
            if config.staffType and config.staffType == "equip_fragment" then
                equipconfig = ui.IDconfig(config.equip) or {}
            end
            if equipconfig.suit and equipconfig.suit ~= 0 and equipconfig.staffType ~= "qiling" and config.quality then
                local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..config.quality..".ccbi", nil, true, "icon")
                item["il_suitNode"..key_Ex]:addChild(suitccb,1,100)
                suititem.partical:setPositionType(kCCPositionTypeGrouped)
            end
        else
            setSpriteFrameByName(item["il_kuang"..key_Ex], "b_iconk1")
            setSpriteFrameByName(item["il_quality"..key_Ex], "b_iconbg1")
            setSpriteFrameByName(item["il_icon"..key_Ex], "alpha")
            ui.setLabelString(item["il_lv"..key_Ex], "",13)
            if item["il_lv2"..key_Ex] then
                ui.setLabelString(item["il_lv2"..key_Ex], "",13)
            end
            setSpriteFrameByName(item["il_fragment"..key_Ex], "alpha")
        end

        if item["titlenode"..key_Ex] then
            if data.title and data.title > 0 then
                if data.title == gameConfig.defautTitleId then
                    item["titlenode"..key_Ex]:setVisible(false)
                else
                    local config = ui.IDconfig(data.title) or {}
                    item["titlenode"..key_Ex]:setVisible(true)
                    setSpriteFrameByName(item["titleicon"..key_Ex], config.icon and config.icon or "alpha")
                end
            else
                item["titlenode"..key_Ex]:setVisible(false)
            end
        end

        -- 添加升星显示设置
        if not item["star_starnode"..key_Ex] then return end
        if starData and starData.cid then
            local config = ui.IDconfig(starData.cid) or {}
            if starData and (starData.level3 and starData.level3 ~= 0) and 
            (config.type == "weapon" or config.type == "head" or config.type == "armor" or config.type == "accessory" or config.type == "treasure" or config.type == "horse") then
                item["star_starnode"..key_Ex]:setVisible(true) 
                ui.setStarShow(item,starData,key_Ex)
            else
                item["star_starnode"..key_Ex]:setVisible(false) 
            end
        else
            item["star_starnode"..key_Ex]:setVisible(false)
        end
    end

end

-- 装备强化加成计算（返回类型，数值）
function ui.setEquipPromote(lab1,lab2,data,lab3)

    local config = ui.IDconfig(data.cid) or {}
    local level1 = data.level1 or data.level or 1

    local refine_radio = 1

    if data.level2 == "0" or data.level2 == 0 then
        refine_radio = 1
        if lab3 then
           lab3:setString("")
        end
    else
        if config.type and (config.type == "horse" or config.type == "treasure") then
            refine_radio = 1 --gamedata.config.treasure_refine[tostring(data.level2)]["radio"]
            -- if lab3 and config.refine and config.refine ~= "" and data.level2 and data.level2 > 0 then
            --    lab3:setString(gameConfig.strings.attr_type[config.refine].."+"..(config["refine-grow"]*data.level2))
             if lab3 then
                lab3:setString("")
             end
        else
            -- refine_radio = gamedata.config.equip_refine[tostring(data.level2)]["radio"]
            refine_radio = 1
            if lab3 then
                lab3:setString("")
            end
        end
    end

    local type1,num1,type2,num2 = "","","",""
    if config.attr1 and config.attr1 ~= "" then
        type1 = gameConfig.strings.attr_type[config.attr1]
        num1 = "+"..math.floor(refine_radio*(config.init1 + config.grow_1*(level1-1))*(config.method1 == "value" and 1 or 100))..(config.method1 == "value" and "" or "%")
    end

    if lab1 then lab1:setString(type1..num1) end

    if config.attr2 and config.attr2 ~= "" then
        type2 = gameConfig.strings.attr_type[config.attr2]
        num2 = "+"..math.floor(refine_radio*(config.init2 + config.grow_2*(level1-1))*(config.method2 == "value" and 1 or 100))..(config.method2 == "value" and "" or "%")
        if lab2 then lab2:setString(type2..num2) end
    else
        if lab2 then lab2:setString("") end
    end

    return type1,num1,type2,num2

--    local n1_up2 = 1
--    if data.level2 == "0" or data.level2 == 0 then
--        n1_up2 = 1
--    else
--        n1_up2 = gamedata.config.equip_refine[tostring(data.level2)]["radio"]
--    end
--    local n1 = configdata.attr_value or 0
--    local n1_up = configdata["strengthen-grow"] or 0
--
--    lab1:setString(gameConfig.strings.attr_type[configdata.attr_type].."+" .. tostring(math.floor((n1+n1_up*(level1-1))*n1_up2)))
--
--    if configdata.type == "horse" or configdata.type == "treasure" then
--        if configdata.attr_type2 and configdata.attr_type2 ~= "" then
--            if configdata.attr_type2 == "critical" or configdata.attr_type2 == "dodge" or configdata.attr_type2 == "parry" then
--                lab2:setString(gameConfig.strings.attr_type[configdata.attr_type2].."+" .. tostring(math.floor(configdata.attr_value2 or 0)).."%")
--            else
--                lab2:setString(gameConfig.strings.attr_type[configdata.attr_type2].."+" .. tostring(math.floor(configdata.attr_value2 or 0)))
--            end
--        else
--            lab2:setString("")
--        end
--    else
--        lab2:setString("")
--    end

end

-- 装备升星加成计算（返回类型，数值）
function ui.setEquipStarUpStatistics(data)

    local config = ui.IDconfig(data.cid) or {}
    local level1 = data.level1 or data.level or 1
    local level3 = data.level3 or data.level3 or 0

    local refine_radio = 1

    local percent1,type1,num1,num2 = "","",0,0
    printT(data,"data====")
    printT(config,"equipconfig===")

    if level3 == 0 or level3 == "0" then
        percent1 = "0%"
        if config.attr1 and config.attr1 ~= "" then
            type1 = gameConfig.strings.attr_type[config.attr1]
            num1 = math.floor(refine_radio*(config.init1 + config.grow_1*(level1-1))*(config.method1 == "value" and 1 or 100))..(config.method1 == "value" and "" or "%")
        end
    elseif level3 > 0 then
        local starconfig = gamedata.config.equip_star
        local nowpercentnum = tonumber(starconfig[tostring(data.level3)]["add_"..data.quality])
        percent1 = (nowpercentnum*100).."%"

        if config.attr1 and config.attr1 ~= "" then
            type1 = gameConfig.strings.attr_type[config.attr1]
            local basicnum = math.floor(refine_radio*(config.init1 + config.grow_1*(level1-1))*(config.method1 == "value" and 1 or 100))
            num1 = (basicnum + math.floor(basicnum*nowpercentnum))..(config.method1 == "value" and "" or "%")
            num2 = math.floor(basicnum*nowpercentnum)
        end
    end
    

    return percent1,type1,num1,num2
end

function ui.setEquipStarPropertyshow(item,starData)
    local configdata =  gamedata.config.equip[tostring(starData.cid)]

    if not configdata then return end
    if not item.star_add then return end

    if configdata.type == "weapon" or configdata.type == "head" or configdata.type == "armor" or configdata.type == "accessory" then
        
        if starData.level3 and starData.level3 ~= 0 then
            item.star_add:setVisible(true)
            local percent1,type1,num1,num2 = ui.setEquipStarUpStatistics(starData)
            local starstring = "+( "..(num2 or 0)..","..(percent1 or "0%").." )"
            ui.setLabelString(item.star_add,starstring,22)
        else
            item.star_add:setVisible(false)
        end
    else
        item.star_add:setVisible(false)
    end
end

function ui.setSoulPromote(lab1,lab2,data)

    local config = ui.IDconfig(data.cid) or {}
    local level1 = data.level1 or data.level or 1

    local type1,num1,type2,num2 = "","","",""
    if config.attr1 and config.attr1 ~= "" then
        type1 = gameConfig.strings.attr_type[config.attr1]
        num1 = "+"..(config["attr1_grow"..level1] or 0)*(config.method1 == "value" and 1 or 100)..(config.method1 == "value" and "" or "%")
    end

    if lab1 then lab1:setString(type1..num1) end

    if config.attr2 and config.attr2 ~= "" then
--        if config.attr2 == "critical" or config.attr2 == "dodge" or config.attr2 == "parry" then
--            lab2:setString((gameConfig.strings.attr_type[config.attr2] or " ")..(gameConfig.strings.attr_type[config.attr2] and ("+" ..config.init2.."%") or ""))
--        else
--            lab2:setString((gameConfig.strings.attr_type[config.attr2] or " ")..(gameConfig.strings.attr_type[config.attr2] and ("+" ..config.init2) or ""))
--        end
        type2 = gameConfig.strings.attr_type[config.attr2]
        num2 = "+"..(config["attr2_grow"..level1] or 0)*(config.method2 == "value" and 1 or 100)..(config.method2 == "value" and "" or "%")
        if lab2 then lab2:setString(type2..num2) end
    else
        if lab2 then lab2:setString("") end
    end

    return type1,num1,type2,num2
end

function ui.getThreeSomeStrings(datastring)
    if not datastring then return {} end
    local data = {}
    local p = 1
    local l = 0
    while p < string.len(datastring) do
        local temp = {}
        l = string.find(datastring, ",", p) or string.find(datastring,"，",p)
        if not l then break end
        temp[1] = string.sub(datastring,p,l - 1)
        p = l + 1
        l = string.find(datastring, ",", p) or string.find(datastring,"，",p)
        if not l then break end
        temp[2] = string.sub(datastring,p,l - 1)
        p = l + 1
        l = string.find(datastring, ";", p) or string.find(datastring,"；",p)
        if not l then l = string.len(datastring)+1 end
        temp[3] = string.sub(datastring,p,l - 1)
        p = l + 1
        table.insert(data,temp)
    end
    return data
end

function ui.setAttrStr(lab,data)
    local config = ui.IDconfig(data.cid)
    if not config then
        lab:setString("")
        if lab2 then
            lab2:setString("")
        end
        return
    end

    local type,num = "",""
    type = gameConfig.strings.attr_type[config.attr]
    num = "+"..(config.attrValue)*(config.attrType == "value" and 1 or 1)..(config.attrType == "value" and "" or "%")
    lab:setString(type..num)
end

--属性值 <0 用百分比显示
function ui.getAttrValue(value)
    print("getAttrValue",value)
    if value >= 1 then
        return value
    else
        return string.format("%.f%%", tonumber(value)*100)
    end
end
    --todo
function ui.setPopwindowByCid(cid,param)
    if not (cid and ui.IDconfig(cid)) then return end
    if ui.IDconfig(cid).staffType == "general"  then
        gameWindows:openWindow("generalInfoRole",{cid = ui.IDconfig(cid).generalid, opt = 2, pagetype = "info"})
    elseif  ui.IDconfig(cid).staffType == "general_fragment" then
        if param then
            gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).generalid + 1000, param = param }, pagetype = "general_fragment"})
        else
            gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).generalid + 1000, param = {fragmentCid = cid}}, pagetype = "general_fragment_other"})
        end
    elseif ui.IDconfig(cid).staffType == "props" then
        if param then
            gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).id, param = param }, pagetype = "info"})
        else
            gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).id }, pagetype = "red_fragment_info"})
        end
    elseif ui.IDconfig(cid).staffType == "red_fragment" then
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).id, param = param }, pagetype = "red_fragment_info"})
    elseif ui.IDconfig(cid).staffType == "equip" then
        gameWindows:openWindow("equipInfo",{cid = ui.IDconfig(cid).id, opt = 2, pagetype = "info"})
    elseif ui.IDconfig(cid).staffType == "equip_fragment" or ui.IDconfig(cid).staffType == "treasure_fragment" then
        if param then
            gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).id, param = param }, pagetype = "info"})
        else
            gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).id }, pagetype = "red_fragment_info"})
        end
    elseif ui.IDconfig(cid).staffType == "soul" then
        local showlv = 1
        if param and param.level then showlv = param.level end
        gameWindows:openWindow("soulInfo",{cid = cid, level = showlv, opt = 2, pagetype = "info"})
    elseif ui.IDconfig(cid).staffType == "pet_fragment" then
        gameWindows:openWindow("devourDetails", {data = {cid = (ui.IDconfig(cid).petid or cid), level = 0}, index = "stageinfo"})
    elseif ui.IDconfig(cid).staffType == "sigil" then
        local data = {}
        data.cid = cid
        data.exp = 0
        gameWindows:openWindow("mofuproperty",{infodata = data,page = "info"},nil)
    elseif ui.IDconfig(cid).staffType == "jewel" then
        gameWindows:openWindow("jewelInfo",{cid = cid},nil)
    elseif ui.IDconfig(cid).staffType == "artifact" then
        if param.isChecked > 0 then
            gameWindows:openWindow("artifactInfo",{artifactData = param},nil)
        else
            gameWindows:openWindow("artifactSInfo",{title = gameConfig.strings:string_common("artifact",27),artifact = param},nil)
        end
    elseif ui.IDconfig(cid).staffType == "g_gold" then
        -- gameWindows:openWindow("propInfo",{prop = { cid = ui.IDconfig(cid).cid or cid }, pagetype = "info"})
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "currency_info"})
    elseif ui.IDconfig(cid).staffType == "championpoint" then
        -- gameWindows:openWindow("propInfo",{prop = { cid = ui.IDconfig(cid).cid or cid }, pagetype = "info"})
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "currency_info"})
    elseif ui.IDconfig(cid).staffType == "gangpoint" then
        -- gameWindows:openWindow("propInfo",{prop = { cid = ui.IDconfig(cid).cid or cid }, pagetype = "info"})
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "currency_info"})
    elseif ui.IDconfig(cid).staffType == "passkillcoin" then
        -- gameWindows:openWindow("propInfo",{prop = { cid = ui.IDconfig(cid).cid or cid }, pagetype = "info"})
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "currency_info"})
    elseif ui.IDconfig(cid).staffType == "point" then
        -- gameWindows:openWindow("propInfo",{prop = { cid = ui.IDconfig(cid).cid or cid }, pagetype = "info"})
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "currency_info"})
    elseif ui.IDconfig(cid).staffType == "xiandou" then
        -- gameWindows:openWindow("propInfo",{prop = { cid = ui.IDconfig(cid).cid or cid }, pagetype = "info"})
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "currency_info"})
    elseif ui.IDconfig(cid).staffType == "platformcurrency" then
        -- gameWindows:openWindow("propInfo",{prop = { cid = ui.IDconfig(cid).cid or cid }, pagetype = "info"})
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "currency_info"})
    elseif ui.IDconfig(cid).staffType == "partnerfashion" then
        -- gameWindows:openWindow("fashionInfo",{prop = { cid, param = param }})
        gameWindows:openWindow("partner_fashion",{cid = (gamedata.config.partner_fashion[tostring(cid)].orange_partner > 0 and gamedata.config.partner_fashion[tostring(cid)].orange_partner or gamedata.config.partner_fashion[tostring(cid)].red_partner), iid = 0, opt = 2},nil)
    elseif ui.IDconfig(cid).staffType == "fashion" then
        gameWindows:openWindow("infoAndAccess",{prop = { cid = cid, param = param },pagetype = "fashion_info"})
    elseif ui.IDconfig(cid).staffType == "phantom" then
        -- gameWindows:openWindow("propInfo",{prop = { cid = ui.IDconfig(cid).cid or cid }, pagetype = "info"})
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "info"})
    elseif ui.IDconfig(cid).staffType == "qiling" then
        gameWindows:openWindow("qilingInfo",{cid = cid,opt = 5})
    elseif ui.IDconfig(cid).staffType == "token_fragment" then
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "token_fragment"})
    elseif ui.IDconfig(cid).staffType == "token" then
        gameWindows:openWindow("infoAndAccess",{prop = { cid = ui.IDconfig(cid).cid or cid, param = param }, pagetype = "token"})
    end

end

function ui.skillView(cid)
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename("public/skilljson/"..cid..".json")
    --local path = CCFileUtils:sharedFileUtils():fullPathForFilename("public/skilljson/kingman_3.json")
    if path then
        local t = {
            fightbg = "renzu1",
            battlereport = LoadJsonFileToTable(path),
        }
        --battleScene:init(mainScene,"skillview",t,callback)
        loading:battlePreLoading(mainScene,"heimu",function() battleScene:init(mainScene,"skillview",t,callback) end)
    else
        -- runGamePrompt({msg = "暂未开放"})
        runGamePrompt({msg = gameConfig.strings:string_common("ui",14)})
    end
end

function ui.reportPlay(filename)
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(filename)
    if path then
        local t = {
            fightbg = "renzu1",
            -- battlereport = LoadJsonFileToTable(path),
            battlereport = ReplaceAbbToKey(CCString:createWithContentsOfFile(path):getCString())
        }
        loading:battlePreLoading(mainScene,"heimu",function() battleScene:init(mainScene,"skillview",t,callback) end)
    else
        runGamePrompt({msg = "文件地址错误"})
    end
end

function ui.blink(node,time)
    local red = CCFadeTo:create(time/2,100)
    local back = CCFadeTo:create(time/2,255)
    local sq = CCSequence:createWithTwoActions(red,back)
    node:stopAllActions()
    node:runAction(CCRepeatForever:create(sq))
end


function ui.leadName(level2,name)
    local name = name or GameScene.roleinfo.name
    local level2show = 0
    local config = gamedata.config.protagonist_grow or {}
    for i = level2-1,1,-1 do
        if config[tostring(i)] and config[tostring(i)].general1 == config[tostring(level2)].general1 then
            level2show = level2show + 1
        end
    end
--    if config[tostring(table.getTableLength(config))] and config[tostring(level2)].general1 == config[tostring(table.getTableLength(config))].general1 then
--       -- name = name.."(魔)"
--       name = gameConfig.strings:nameMo(name)
--    end

    if level2 >= 24 then
        name = gameConfig.strings:nameXian(name)
        level2show = level2 
    elseif level2 >= 20 then
        name = gameConfig.strings:nameMo(name)
        level2show = level2
    end


    name = name..(level2show >0 and (" +"..level2show) or "")
    return name
end

function ui.penglaiCidNum(str,level)
    local str = str or ""
    local data = {cid = 0,num = 0}
    if str and str ~= "" then
        local i1 = string.find(str,",") or string.find(str,"，")
        local cid = tonumber(string.sub(str,1,i1-1))
        str = string.sub(str,i1+1)
        local i2 = string.find(str,",") or string.find(str,"，")
        local num_f = tonumber(string.sub(str,1,i2-1))
        str = string.sub(str,i2+1)
        local i3 = string.find(str,",") or string.find(str,"，")
        local level_u = tonumber(string.sub(str,1,i3-1))
        str = string.sub(str,i3+1)
        local i4 = string.find(str,";") or string.find(str,"；")
        local num_u = tonumber(string.sub(str,1))
        if i4 then
            num_u = tonumber(string.sub(str,1,i4-1))
        end
        data.cid = cid
        data.num = num_f + num_u*(math.floor((GameScene.roleinfo.level-level)/level_u))
    end
    return data
end

-- local gotoconfig = {
--     props = {system = 41,des1="魔王大人，当前没有道具",des2="请去下列玩法获取吧！！",note = "去购买"},
--     equips = {system = 12,des1="魔王大人，当前没有装备",des2="请去下列玩法获取吧！！",note = "去获得"},
--     treasures = {system = 12,des1="魔王大人，当前没有宝物",des2="请去下列玩法获取吧！！",note = "去获得"},
--     weapon = {system = 12,des1="魔王大人，当前没有武器",des2="请去下列玩法获取吧！！",note = "去获得"},
--     armor = {system = 12,des1="魔王大人，当前没有防具",des2="请去下列玩法获取吧！！",note = "去获得"},
--     accessory = {system = 12,des1="魔王大人，当前没有饰品",des2="请去下列玩法获取吧！！",note = "去获得"},
--     head = {system = 12,des1="魔王大人，当前没有头盔",des2="请去下列玩法获取吧！！",note = "去获得"},
--     treasure = {system = 12,des1="魔王大人，当前没有典籍",des2="请去下列玩法获取吧！！",note = "去获得"},
--     horse = {system = 12,des1="魔王大人，当前没有坐骑",des2="请去下列玩法获取吧！！",note = "去获得"},
--     equipfragment = {system = 12,des1="魔王大人，当前没有装备碎片",des2="请去下列玩法获取吧！！",note = "去获得"},
--     treasurefragment = {system = 12,des1="魔王大人，当前没有宝物碎片",des2="请去下列玩法获取吧！！",note = "去获得"},

--     general = {system = 11,des1="魔王大人，当前没有伙伴",des2="请去下列玩法获取吧！！",note = "去招募"},
--     generalfragment = {system = 11,des1="魔王大人，当前没有伙伴魂魄",des2="请去下列玩法获取吧！！",note = "去招募"},

--     soul = {system = 9,des1="魔王大人，当前没有命格",des2="请去下列玩法获取吧！！",note = "去猎命"},

-- }
local gotoconfig = {
    props = {system = 41,des1=gameConfig.strings:string_common("ui",15),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",17)},
    equips = {system = 12,des1=gameConfig.strings:string_common("ui",18),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    treasures = {system = 25,des1=gameConfig.strings:string_common("ui",20),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    weapon = {system = 12,des1=gameConfig.strings:string_common("ui",21),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    armor = {system = 12,des1=gameConfig.strings:string_common("ui",22),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    accessory = {system = 12,des1=gameConfig.strings:string_common("ui",23),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    head = {system = 12,des1=gameConfig.strings:string_common("ui",24),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    treasure = {system = 25,des1=gameConfig.strings:string_common("ui",25),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    horse = {system = 25,des1=gameConfig.strings:string_common("ui",26),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    equipfragment = {system = 12,des1=gameConfig.strings:string_common("ui",27),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    treasurefragment = {system = 25,des1=gameConfig.strings:string_common("ui",28),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",36)},
    meterialfragment = {system = 25,des1=gameConfig.strings:string_common("ui",35),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",36)},

    general = {system = 11,des1=gameConfig.strings:string_common("ui",29),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",30)},
    generalfragment = {system = 11,des1=gameConfig.strings:string_common("ui",31),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",30)},

    soul = {system = 9,des1=gameConfig.strings:string_common("ui",32),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",33)},
    devil = {system = 20,des1="魔王大人，当前没有魔宠碎片",des2=gameConfig.strings:string_common("ui",16),note = "灭神殿"},

    mofu = {system = 140,des1="魔王大人，当前没有魔符",des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},
    qiling = {system = 615,des1="魔王大人，当前没有器灵",des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",19)},

    token = {system = 167,des1=gameConfig.strings:string_common("ui",75),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",77)},
    tokenfragment = {system = 185,des1=gameConfig.strings:string_common("ui",76),des2=gameConfig.strings:string_common("ui",16),note = gameConfig.strings:string_common("ui",77)},

}

function ui.setGoto(node,isshow,index)

    if isshow and gotoconfig[index] then
        node:removeAllChildrenWithCleanup(true)
        local ccb,item = CCBReaderLoad("tanchuang/chaolianjie.ccbi", nil, true, "chaolianjie")
        node:addChild(ccb)

        item.gotodes1:setString(gotoconfig[index].des1)
        item.gotodes2:setString(gotoconfig[index].des2)
        item.gotoname:setString(gotoconfig[index].note)
        setSpriteFrameByName(item.gotoicon, gamedata.config.build[tostring(gotoconfig[index].system)].icon)
        item.goto_button:setSwallowsTouch(true)
        item.goto_button:setTouchPriority(-500)
        item.goto_button:addHandleOfControlEvent(function()
            GameScene:shiftLayerById(gotoconfig[index].system)
        end, CCControlEventTouchUpInside)

--        item.gotogeneral:removeAllChildrenWithCleanup(true)
--        local ma = CCSkeletonAnimation:create("change/change.json","change/change.atlas",2)
--        ma:setAnimation("stand",true,0)
--        item.gotogeneral:addChild(ma)
    else
        node:removeAllChildrenWithCleanup(true)
    end
end

function ui.sethint(node,isshow)
    node:removeAllChildrenWithCleanup(true)
    if isshow then
        local ccb,item = CCBReaderLoad("UIEffect/red.ccbi", nil, true, "red")
        node:addChild(ccb)
    end
end

function ui.addAwakeEffect(node,level,scale,pos)

    if gameConfig.checkBuildOpen and gameConfig:checkBuildOpen(174) then
        if level and level >0 and gamedata.config.general_awaken[tostring(level)] and gamedata.config.general_awaken[tostring(level)].effect then
            local ccb,item = CCBReaderLoad("UIEffect/juxingeffect/juexing_effect_"..gamedata.config.general_awaken[tostring(level)].effect..".ccbi", nil, true, "juexing_effect_")
            ccb:setPosition(pos or ccp(0,0))
            ccb:setScale(scale or 1)
            node:addChild(ccb)

            return ccb
        end
    end
end

function ui.getStrRealindexT(str)
    local len = string.len(str)
    local realindexT= {}

    local len = #str;
    local left = len;
    local luaindex = 0
    local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
    while left ~= 0 do
        local tmp=string.byte(str,-left);
        local i=#arr;
        while arr[i] do
            if tmp>=arr[i] then left=left-i;break;end
            i=i-1;
        end
        luaindex=luaindex+i
        table.insert(realindexT,luaindex)
    end

    return realindexT
end

function ui.setStringOneByOne(label,str,callback)

    local realindexT= ui.getStrRealindexT(str)

    local index = 0
    local timer
    timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        index = index + 1
        if realindexT[index] then
            label:setString(string.sub(str,1,realindexT[index]))
        else
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(timer)
            if callback then callback() end
        end
    end, 0.01, false)
end


function ui.getVipLevelByStr(str)
    if not gameConfig:checkBuildOpen(154) then return -1 end

    local vipconfig = gamedata.config.vip or {}
    local level = 100
    for k,v in pairs(vipconfig) do
        if v[str] and v[str] == 1 and v.vip<level then
            level = v.vip
        end
    end
    if level > table.getTableLength(vipconfig) then level = 0 end
    return level
end

function ui.gotoDrop(cid)
    local config = gamedata.config.drop[tostring(cid)]
    if config then

    else
       -- runGamePrompt({msg = "掉落配置出错！"})
       runGamePrompt({msg = gameConfig.strings:string_common("ui",34)})
    end
end

function ui.hasCopyChallenge(type,mapid,pointid)
    if type == "normal" then
        return hasNormalCopyChallenge(mapid,pointid)
    end
end

function ui.getCopyProcess(type)
    if type == "normal" then
        return getNormalCopyProcess()
    elseif type == "star" then
        return getStarCopyProcess()
    else
        return getBraveCopyProcess()
    end
end

function ui.isCopy3star(type,mapid,pointid)
    if type == "normal" then
        return isNormalCopy3star(mapid,pointid)
    else
        return isBraveCopy3star(mapid,pointid)
    end
end

function ui.isCopyOpen(tagetmap,targetpoint,mapmax,pointmax)
    tagetmap = tagetmap or 0
    targetpoint = targetpoint or 0

    if tagetmap > mapmax then
        return false
    elseif tagetmap == mapmax then
        if targetpoint> pointmax then
            return false
        end
    end
    return true
end

local richlabel = require"RichLabel"
function ui.createRichLabel(strTable,container,isseparated,alignment)
    return richlabel:creatRichLabel(strTable,container,isseparated,alignment)
end

function ui.setIconKuang( item,id )
    if id and id>0 and gamedata.config.avatar[tostring(id)] then
        setSpriteFrameByName(item,gamedata.config.avatar[tostring(id)].icon)
    end
end

function ui.isWiFI3G()
    local deviceApi = require"device"
    if deviceApi.platform == "android" then
        local luaj = require"luaj"

        local javaClassName = gameConfig.AD_packageName.."/AndroidUtils"
        -- local javaClassName = "com/ldfs/sanguo2/AndroidUtils"
        local javaMethodName = "NetworkSt"
        local javaMethodSig = "()I"
        --wifi 返回2  没网返回0  手机网返回 1
        local result, netState = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        --print("netState:============",netState)
        return netState
    else
        local networkWife = Networkconnect.Singleton()
        local networkstate = networkWife:getNetState()
        -- print("networkstate:========")
        -- print(networkstate)
        --wifi 返回2  没网返回0  手机网返回 1
        return networkstate
    end
end

--分享接口
function ui.shareSDK(self)
    if gameTouch.isScrollling then return end
    if gamedata.device.platform == "ios" then

        local i = string.find(GAME_VERSION_NUM,"%.")
        local j = string.find(GAME_VERSION_NUM,"%.",i+1)
        if not j then j = string.len(GAME_VERSION_NUM)+1 end
        local deviceApi = require"device"
        local s_image = "UI/activity_fenxiang/share.jpg"
        local s_url = "http://zyj.52muyou.com"
        local s_desc = "这游戏太好笑啦，哇哈哈哈~"
        local s_name = "作妖计"

        if deviceApi and deviceApi.channel == "iOSbaozouZYJ" then
            runGamePrompt({msg = "分享功能正在开发中..."})
            UIRequest({type = 2086})
        elseif (tonumber(string.sub(GAME_VERSION_NUM,1,i-1)) >= 3) and MyShareSDK then
            MyShareSDK:showShare(s_image,s_name,s_url,s_desc)
        elseif deviceApi and  deviceApi.channel == "zuoyaojiapple2" and gamedata.gameconfig.forceupdate>=102 and MyShareSDK then
            MyShareSDK:showShare(s_image,s_name,s_url,s_desc)
        elseif deviceApi and deviceApi.channel == "zuoyaojihdios2" and gamedata.gameconfig.forceupdate>=106  and MyShareSDK then
            MyShareSDK:showShare(s_image,s_name,s_url,s_desc)
        else
            runGamePrompt({msg = "请下载最新版本游戏"})
        end
    else
        runGamePrompt({msg = "没有接入分享功能"})
    end
end

function ui.setStringToPasteBoard(str)
    local deviceApi = require"device"
    if deviceApi.platform == "android" then
        local luaj = require"luaj"

        local javaClassName = gameConfig.AD_packageName.."/MobileUtils"
        local javaMethodName = "setStringToPasteBoard"
        local javaMethodSig = "(Ljava/lang/String;)V"
        local javaParams = {str}
        print("PasteBoardstr:============",str)
        local result, errcode = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        print("errcode:============",errcode)
        return result
    else
        return CCDeviceModel:setStringToPasteBoard(str)
    end
end

-- NSString* userid=[dic objectForKey:@"userid"];
--     char tmp[256] = {0};
--     sprintf(tmp, "local iiapple=require\"iiapple\";iiapple:LoginCB(\"%s\",\"%s\",\"%s\");", [userid UTF8String], [session UTF8String], [userid UTF8String]);
--     this->lua->executeString(tmp);

function ui.getSystemIdbykey(key)
    if gamedata.config.build_key[key] then
        return gamedata.config.build_key[key].id
    else
        return 0
    end
end

function ui.getEquipStageName(data)
    -- print("getEquipStageName==")
    -- printT(data)
    local equipdata = data
    local equipconfig = gamedata.config.equip[tostring(equipdata.cid)]

    local nowNameString = equipconfig.name or ""


  
    if equipconfig.type == "treasure" or equipconfig.type == "horse" then

        if equipdata.level2 > 0 then
            nowNameString = nowNameString.."+"..equipdata.level2
        end

        return nowNameString
    end

    local stageLevel = equipdata.level2 or 0
    local stageNameConfig = gamedata.config.equip_evolvesuffix
    if stageLevel > 0 then
        nowNameString = nowNameString..(stageNameConfig[tostring(stageLevel)]["suffix"..equipdata["quality"]] or "")
    end
    return nowNameString
end

function ui.getGangBattleTime(str)
    local hour,min,sec = 0,0,0
    if str and str ~= "" then
        local i1 = string.find(str,",") or string.find(str,"，")
        local i2 = string.find(str,",",i1+1) or string.find(str,"，",i1+1)
        local i3 = string.find(str,";") or string.find(str,"；")
        if not i3 then
            i3 = string.len(str)+1
        end
        hour,min,sec = tonumber(string.sub(str,1,i1-1)),tonumber(string.sub(str,i1+1,i2-1)),tonumber(string.sub(str,i2+1,i3-1))
    end
    return hour,min,sec
end

function ui.setWudaoPart(items,part)
    local config = gamedata.config.wudao_part or {}
    if items then
        if part and part > 0 and config[tostring(part)] then
            items.duan_node:setVisible(true)
            setSpriteFrameByName(items.duan_sprite1,config[tostring(part)].icon1)
            setSpriteFrameByName(items.duan_sprite2,config[tostring(part)].icon2)
        else
            items.duan_node:setVisible(false)
        end
    end
end

-- 段位前三闪烁显示设置 items:资源,playerdata:数据,anchorx:名字锚点设置,scaleNum:字体比例大小,fontid:字体号,nameitem:需要改变的名字对象
function ui.setWudaoDuanweiRankEffect(items,playerdata,anchorx,scaleNum,fontid,nameitem)
    -- printT(items,"setWudaoDuanweiRankEffect==")
    -- printT(playerdata,"playerdata===")
    -- print("num--=",anchorx,scaleNum)

    if items and items.danweinode then

        items.danweinode:removeAllChildrenWithCleanup(true)
        

        local itemsnode, itemsccb =  CCBReaderLoad("wudaohui/duanwei_rank", nil, true, "duanwei_rank")
        items.danweinode:addChild(itemsnode)

        local changename = items.name
        if nameitem then
            changename = nameitem
        end


        if playerdata.part_rank == nil or playerdata.part_rank == 0 then

            if fontid then
                ui.setLabelString(changename,playerdata.name,fontid)
            else
                changename:setString(playerdata.name)
                items.danweinode:setScale(scaleNum)
            end
            
            changename:setVisible(true)
            items.danweinode:setVisible(false)
        else
            items.danweinode:setScale(scaleNum)
            
            itemsccb.nameduanwei:setString(playerdata.name)
            
            changename:setVisible(false)
            items.danweinode:setVisible(true)
            itemsccb.nameduanwei:setAnchorPoint(ccp(anchorx,0.5))
        end
    end
end


function ui.CheckHuodongByParam(param)
    if param and GameScene.huodongactivity and GameScene.huodongactivity == 1 then
        local nowtime = os.date("*t", gamedata:time())
        local wday = ((nowtime.wday-1) < 1) and 7 or (nowtime.wday-1)
        local config = gamedata.config.activity_huodong or {}
        for k,v in pairs(config) do
            if (v.param == param) and (wday == v.open_time) then
                return true
            end
        end
    end
    return false
end

function ui.GetHuodongModulus(param)
    if param and GameScene.huodongactivity and GameScene.huodongactivity == 1 then
        local config = gamedata.config.activity_huodong or {}
        for k,v in pairs(config) do
            if v.param == param then
                return v.modulus
            end
        end
    end
    return 1
end

-- cb  回调函数
-- local cb =  function(num)
--     UIRequest({type = 3711,_id = tmpData._IdIndex,_num = num})
-- end 
-- canExchangeNum  物品满足时，可以兑换的最大次数
-- num  兑换条件中剩余兑换次数，如果没有表示没有对话次数要求
-- max  兑换条件中最大兑换次数，如果没有表示没有对话次数要求
-- type 兑换/购买
function ui.exchangeMore( cb,canExchangeNum,num,max,type )
    local changeNum = canExchangeNum 
    if num and max then
        changeNum = num > canExchangeNum and canExchangeNum or num
    end
    if num and num <= 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","exchangeMore",3)})
    elseif changeNum <= 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("exchange",1)})
    elseif max == 1 then
        cb(1)
    else
        local data = {max = changeNum}
        if type and type == "buy" then
            data = {max = changeNum, type = type}
        end
        gameWindows:openWindow("exchangeMore",data,cb)
    end
end

--以锚点位置计算Node的右下角坐标
function ui.getCCNodeRightPosition(node)
    local _x = 0

    if node then
        _x = node:getPosition()
        _x = _x + node:getContentSize().width * (1 - node:getAnchorPoint().x) * node:getScaleX() 
    end

    return _x
end

---
-- 以右边界为基准停靠
-- @param table arg
--[[node = xxxx(继承CCNode的对象)
    isSetAnchorPoint = false(默认为true, 传false不会改变锚点)]]--     
function ui.setCCNodeListRight(arg, anchorY)
    if arg and next(arg) then
        local _length = #arg
    
        if _length > 1 then
            for i = 2, _length do
                if arg[i].isSetAnchorPoint ~= false then
                    arg[i].node:setAnchorPoint(ccp(0, anchorY or 0.5))
                end
                
                local _horizion = arg[i].horizion or 0
                arg[i].node:setPositionX(ui.getCCNodeRightPosition(arg[i - 1].node) + _horizion)
            end
        end
    end
end

---
-- 根据屏幕比例以size值为缩放范围适配node的位置
function ui.setScreenPositionY(node, toppos, size, position)
    if not position then
        position = node:getPositionY()
    end

    node:setPositionY((toppos - 1620) / (1920 - 1620) * size + position)
end




function ui.setTradingGoodsInfo(self,items,data)
    local transaction_itemType = gamedata.config.transaction_itemType[tostring(data.cid)]

    local config = ui.IDconfig(data.cid)

    -- ui.setLabelString(items.name,config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
    ui.setLabelString(items.name,config.name,94)
    ui.setLabelString(items.des,config.desc,95)

    if transaction_itemType.itemType == 1 then
        ui.setNewIcon(items, {cid = data.cid})
        items.attribute:setString("")
    elseif transaction_itemType.itemType == 2 then


        --物品出售 背包里神器 content没有数据 与php接口同步
        if not data.content then
            data.content = {builder_name = data.name,authenticate = data.isChecked,attr1_value = data.attr1,attr2_value = data.attr2,jewel1 = data.jewel1,jewel2 = data.jewel2,jewel3 = data.jewel3,jewel4 = data.jewel4,skill1 = data.skill1,skill2 = data.skill2,skill3 = data.skill3}
        end


        items.artifactType:setString(gameConfig.strings:string_common("artifact",76 + config.type))
        ui.setLabelString(items.playerName,data.content.builder_name or "",96)

        local shenqiSkeletonMeta = require"SkeletonShenqi"
        local skeleton = shenqiSkeletonMeta:init(config,0)
        skeleton:setScale(0.6)
        skeleton:setAnimation("stand",true,0)
        items.artifactNode:removeAllChildrenWithCleanup(true)
        items.artifactNode:addChild(skeleton.root or skeleton)

        if data.content.authenticate == 0 then --未鉴定
            
        elseif data.content.authenticate == 1 then

            items.attr1:setString(gameConfig.strings:attributeValue(config.attr1,config.attr1Type,data.content.attr1_value))
            items.attr2:setString(gameConfig.strings:attributeValue(config.attr2,config.attr2Type,data.content.attr2_value))


            local jewelNum = 0
            for i=1,4 do
                if data.content["jewel"..i] > 0 then
                    local jewelConfig = ui.IDconfig(data.content["jewel"..i])
                    items["jewel"..i]:setString(jewelConfig.name)
                    items["jewel"..i]:setColor(ccc3(105,55,31))

                    items["jewelattr"..i]:setString(gameConfig.strings:attributeValue(jewelConfig.attr,jewelConfig.attrType,jewelConfig.attrValue))
                    jewelNum = jewelNum + 1

                else
                    ui.setLabelString(items["jewel"..i],gameConfig.strings:string_common("artifact",31),96)
                    items["jewelattr"..i]:setString("")
                end

            end
            items.fixed6:setString(string.format(gameConfig.strings:string_common("tradingShop",13),jewelNum,4))
            
            for i=1,3 do

                local skill = data.content["skill"..i]
                if skill>0 then
                    local skillConfig = gamedata.config.breakskill[tostring(skill)]

                    local quality = math.min(6,skillConfig.quality > 0 and skillConfig.quality or 1)

                    local btnNames = {
                        [1] = {pic = "tezhibt_bai",labelconfig = 97},
                        [2] = {pic ="tezhibt_lv",labelconfig = 98},
                        [3] = {pic ="tezhibt_lan",labelconfig = 99},
                        [4] = {pic ="tezhibt_zi",labelconfig = 100},
                        [5] = {pic ="tezhibt_cheng",labelconfig = 101},
                        [6] = {pic ="tezhibt_hong",labelconfig = 102},
                    }

                    setControlButtonFrame(items["skillbt"..i],btnNames[quality].pic,btnNames[quality].pic,btnNames[quality].pic)

                    ui.setLabelString(items["skillname"..i],skillConfig.name,btnNames[quality].labelconfig)


                    -- ui.setLabelString(items["skillName"..i],skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
                    --

                    items["skillbt"..i]:setVisible(true)
                    items["skillbt"..i]:addHandleOfControlEvent(function()
                        items.skillinfonode:setVisible(true)
                        items.skillinfonode:setPositionX(items["skillbt"..i]:getPositionX())

                        if skillConfig.quality and skillConfig.quality >= 7 then
                            ui.setLabelString(items.skillinfo,skillConfig.desc,214)
                        else
                            ui.setLabelString(items.skillinfo,skillConfig.desc,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
                        end

                        local proflayer = nil
                        local callback = function (  )
                            print("callback")
                            items.skillinfonode:setVisible(false)
                            proflayer:removeFromParentAndCleanup(true)
                        end
                        proflayer = ui.addProflayer(self.rootNode,self.touchPriority - 10,nil,ccc4(0,0,0,0),nil,nil,nil,callback,"pop",true)

                    end, CCControlEventTouchUpInside)
                    items["skillbt"..i]:setSwallowsTouch(true)
                    items["skillbt"..i]:setTouchPriority(self.touchPriority)

                    items["skillnode"..i]:setVisible(true)
                else
                    items["skillnode"..i]:setVisible(false)
                end
                
            end

        end
    elseif transaction_itemType.itemType == 3 then
        ui.setNewIcon(items, {cid = data.cid})
        local str = gameConfig.strings:attributeValue(config.attr,config.attrType,config.attrValue)
        items.attribute:setString(str)
    end

end

function ui.dayForTime(time)
    local tb = {}
    tb.day = math.floor(time/3600/24)
    tb.hour = math.floor(time%(3600*24)/3600)
    tb.min = math.floor(time%(3600*24)%3600/60)
    tb.sec = time%(3600*24)%3600%60
    return tb
end


function ui.setLayerpageshift(self,items,TouchPriority)
    for k=1,5 do
        if self.pageconfig[k] then


            items["buttontext"..k]:setVisible(true)
            items["buttonsprite"..k]:setVisible(true)
            items["buttontext"..k]:setString(self.pagename[k])

            items["button"..k]:setSwallowsTouch(true)
            items["button"..k]:setTouchPriority(TouchPriority)
            items["button"..k]:addHandleOfControlEvent(function()
                self:shiftPage(self.pageconfig[k])
            end, CCControlEventTouchUpInside)
        else
            if not items["buttontext"..k] then
            else
                items["buttontext"..k]:setVisible(false)
                items["buttonsprite"..k]:setVisible(false)
                items["button"..k]:setTouchEnabled(false)
                
            end
        end
    end
end

function ui.showArtifactSkillNum(items,data)
    local count = 0
    local curQuality = 0
    for i=1,3 do
        local curSkill = data["skill"..i]
        if curSkill > 0 then
            local skillConfig = gamedata.config.breakskill[tostring(curSkill)]
            if skillConfig.quality > curQuality then
                curQuality = skillConfig.quality
            end
            count = count + 1
        end
    end
    if count > 0 then
        local index = curQuality - 1
        index = math.max(index,0)

        items.skillNumNode:setVisible(true)
        setSpriteFrameByName(items.skillNumBg,"shenqiskillbg_"..index)
        setSpriteFrameByName(items.skillNum,"shenqiskillicon_"..count)
    else
        items.skillNumNode:setVisible(false)
    end
end


function ui.judgeFeiSheng(cid)
    local general = ui.IDconfig(cid)
    if general.soaring and general.soaring > 0 then
        return true
    end
    return false
end

--判断是否是初始红将
function ui.judgeBasicRed(cid)
    print(cid)
    local _cid = ui.getOriginCid(cid)
    if gamedata.config.general[tostring(_cid)] and gamedata.config.general[tostring(_cid)].quality == 6 then
        return true
    end
    return false
end

function ui.getOriginCid(cid)
    print(cid)
    local _cid = cid
    local _generalConfig = gamedata.config.general[tostring(_cid)]
    if _generalConfig and _generalConfig.init_cid and _generalConfig.init_cid > 0 then
        _cid = _generalConfig.init_cid
    end
    return _cid
end

function ui.getMaxBreakLv(cid)
    local originCid = ui.getOriginCid(cid)
    local generalConfig = gamedata.config.general[tostring(originCid)]
    local general_awake = gamedata.config.general_awake
    local maxlv = 10

    if generalConfig.break_id and generalConfig.break_id > 0 then

        local redConfig = gamedata.config.general[tostring(generalConfig.break_id)]
        if redConfig.gold_id and redConfig.gold_id > 0 then
            maxlv = table.getTableLength(general_awake) or 10
        else
            for i = 1,table.getTableLength(general_awake) do
                if general_awake[tostring(i)].gold_will_labal and general_awake[tostring(i)].gold_will_labal == 1 then
                    maxlv = i-1
                    break
                end
            end
        end
    else
        for i = 1,table.getTableLength(general_awake) do
            if general_awake[tostring(i)].labal and general_awake[tostring(i)].labal == 1 then
                maxlv = i-1
                break
            end
        end
    end
    return maxlv
end


function ui.getPosCentered(width,offx,num)
    
    local pos = {}
    local originx = 0
    if num%2 == 0 then
        originx =  -(num/2 - 0.5) * (width + offx)
    else
        originx =  -math.floor(num/2) * (width + offx)
    end

    for i=1,num do
        pos[i] = originx + (i - 1) * (width + offx)
    end

    return pos
end

function ui.lineFeedString(str)

    print("lineFeedString ",str)
    local step = 1
    local len = #str
    print("len====",len)
    local newstr = ""
    local firstbyte = {
        [1] = 0,
        [2] = 192,
        [3] = 224,
        [4] = 240,
        [5] = 248,
        [6] = 252,
    }

    while step <= len do
        local byte = tonumber(string.byte(string.sub(str,step,step)))
        local bytenum = 1
        if byte<=127 then
            bytenum = 1
        elseif byte>=192 and byte<=223 then
            bytenum = 2
        elseif byte>=224 and byte<=239 then
            bytenum = 3
        elseif byte>=240 and byte<=247 then
            bytenum = 4
        elseif byte>=248 and byte<=251 then
            bytenum = 5
        elseif byte>=252 and byte<=253 then
            bytenum = 6
        end

        local unicode = 0
        for i=1,bytenum do

            local bytecode = tonumber(string.byte(string.sub(str,step,step)))
            if i==1 then
                unicode = unicode + (bytecode-firstbyte[bytenum])*2^(6*(bytenum-i))
            else
                unicode = unicode + (bytecode-128)*2^(6*(bytenum-i))
            end
            step = step + 1
        end

        local showstr = string.sub(str,step-bytenum,step-1)

        local temp = newstr
        if string.sub(str,step,step) ~= "" then
            temp = temp..showstr.."\n"
        else
            temp = temp..showstr
        end
        newstr = temp
    end
    print(newstr)
    return newstr
end

function ui.createCliperNode(node,iconFileName,stencilFileName)
    print("createCliperNode",iconFileName,stencilFileName)
    local cliper = CCClippingNode:create()

    local stencil = CCSprite:create()
    setSpriteFrameByName(stencil,stencilFileName)
    cliper:setStencil(stencil)
    cliper:setAlphaThreshold(0)

    local icon = CCSprite:create()
    setSpriteFrameByName(icon,iconFileName)
    cliper:addChild(icon)


    node:addChild(cliper)
    return cliper,icon
end


function ui.qualityToSSR(cid)
    print("qualityToSSR",cid)
    -- if ui.IDconfig(cid).staffType ~= "general" then return end

    local _cid = ui.getOriginCid(cid)
    local configdata = ui.IDconfig(_cid)

    if configdata.quality == 2 then
        return "C"
    elseif configdata.quality == 3 then
        return "B"
    elseif configdata.quality == 4 then
        return "A"
    elseif configdata.quality == 5 and configdata.basic == 18 then
        return "SR"
    elseif configdata.quality == 5 and configdata.basic == 20 then
        return "SSR"
    elseif configdata.quality == 5 and configdata.basic == 23 then
        return "SSSR"
    else
        return "SSSR"
    end
end


function ui.initSkipPopup(parent,istop,type,touchPriority)
    print("initSkipPopup",type)

    local scalenum = istop and gameConfig.scaleNum or 1
    local ccb,items = CCBReaderLoad("MainScene/popup_tip.ccbi", nil, true, "popup_tip")
    ccb:setPosition(540*scalenum, 300*scalenum)
    ccb:setScale(scalenum)
    parent:addChild(ccb,10000)

    local isShow = true
    local tipStr = CCUserDefault:sharedUserDefault():getStringForKey("tip_"..type)
    if tipStr and tipStr ~= "" then
        local now = os.date("*t", gamedata:time())
        local _t = string.split(tipStr,"_")
        if tonumber(_t[1]) == 0 and tonumber(_t[2]) == now.year and tonumber(_t[3]) == now.month and tonumber(_t[4]) == now.day then
            isShow = false
        end
    end

    items.tip_selectSprite:setVisible(not isShow)
    items.tip_selectStatus = not isShow

    items.tip_selectButton:setSwallowsTouch(true)
    items.tip_selectButton:setTouchPriority(touchPriority or gameConfig.touchPriority.topwindow - 100)
    print(gameConfig.touchPriority.topwindow)
    items.tip_selectButton:addHandleOfControlEvent(function()

        print("点击执行")

        items.tip_selectStatus = not items.tip_selectStatus
        items.tip_selectSprite:setVisible(items.tip_selectStatus)
        local now = os.date("*t", gamedata:time())
        local _str = (items.tip_selectStatus and "0_" or "1_")..now.year.."_"..now.month.."_"..now.day
        CCUserDefault:sharedUserDefault():setStringForKey("tip_"..type, _str)

    end, CCControlEventTouchUpInside)

end

function ui.initHintTime(hintName,id)
    CCUserDefault:sharedUserDefault():setStringForKey(hintName..id, "")
end

function ui.saveHintTime(hintName,id)
    print("hintName save == ", hintName)
    local now = os.date("*t", gamedata:time())
    local _str = now.year.."_"..now.month.."_"..now.day
    CCUserDefault:sharedUserDefault():setStringForKey(hintName..id, _str)
end

function ui.getHintShow(hintName,id)
    print("hintName get == ", hintName)
    local isShow = true
    local userDefault = CCUserDefault:sharedUserDefault():getStringForKey(hintName..id)
    if userDefault and userDefault ~= "" then
        local now = os.date("*t", gamedata:time())
        local _t = string.split(userDefault,"_")
        if tonumber(_t[1]) == now.year and tonumber(_t[2]) == now.month and tonumber(_t[3]) == now.day then
            isShow = false
        end
    end
    return isShow
end

function ui.setButtonFunc(button,isSwallowsTouch,touchPriority,func)
    button:setSwallowsTouch(isSwallowsTouch)
    button:setTouchPriority(touchPriority)

    local function buttonfunc()
        --if self.istouchmove then return end
        xpcall(func,__G_TRACKBACK__)
    end
    button:addHandleOfControlEvent(buttonfunc, CCControlEventTouchUpInside)
end

function ui.popCommonRule(systemid,ruleTextCCB,fixedString)
    gameWindows:openWindow("commonRule",{systemid = systemid,ruleTextCCB = ruleTextCCB,fixedString = fixedString})
end

--在table中随机n个元素返回
require("socket")
function ui.randomFromTable(arg_,count,returnType)
    local arg = table.copy(arg_)
    local selected={};
    math.random(0,#arg);
    math.randomseed(tostring(socket.gettime()):reverse():sub(1, 6))
    if #arg<=count then return unpack(arg) end
    while #selected < count do
        math.random(#arg);
        table.insert(selected,table.remove(arg,math.random(#arg)));
    end
    if returnType == "table" then
        return selected
    end
    return unpack(selected);
end

--在table中随机n个元素返回
function ui.randomFromTableNocopy(arg,count)
    local selected={};
    math.random(0,#arg);
    math.randomseed(os.time());
    if #arg<=count then return unpack(arg) end
    while #selected < count do
        math.random(#arg);
        table.insert(selected,table.remove(arg,math.random(#arg)));
    end
    return unpack(selected);
end

function ui.StringToTable(s)  
    local tb = {}  
    for utfChar in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do  
        table.insert(tb, utfChar)  
    end  
    return tb  
end

function ui.labelFollow(l1,l2)  
    l2:setPositionX(l1:getPositionX()+l1:getContentSize().width + 3) 
end

function ui.getGeneralAnimationid(generalName, nowGeneral)
    local configGenera = gamedata.config.general[tostring(nowGeneral.cid)]
    if configGenera.init_cid and configGenera.init_cid > 0 and nowGeneral.g_fashion then
        local gdata = gamedata.config.general[tostring(configGenera.init_cid)]
        print("g_fashion == ", nowGeneral.g_fashion)
        if nowGeneral.g_fashion == 5 then --橙
            generalName = gamedata.config.generalanimation[tostring(gdata.animationid)].name
        elseif nowGeneral.g_fashion == 6 then --红
            if configGenera.quality and configGenera.quality == 6 then
                gdata = gamedata.config.general[tostring(nowGeneral.cid)]
                generalName = gamedata.config.generalanimation[tostring(gdata.animationid)].name
            elseif configGenera.quality and configGenera.quality == 7 then
                gdata = gamedata.config.general[tostring(configGenera.red_id)]
                generalName = gamedata.config.generalanimation[tostring(gdata.animationid)].name
            end
        elseif nowGeneral.g_fashion == 7 then --金
            gdata = gamedata.config.general[tostring(nowGeneral.cid)]
            generalName = gamedata.config.generalanimation[tostring(gdata.animationid)].name
        end
    end
    print("generalName == ", generalName)
    return generalName
end

function ui.getConfigGeneral(nowGeneral)
    local gdata = {}
    local configGenera = gamedata.config.general[tostring(nowGeneral.cid or nowGeneral.general.cid)]
    if configGenera.init_cid and configGenera.init_cid > 0 and nowGeneral.g_fashion then
        if nowGeneral.g_fashion == 5 then --橙
            gdata = gamedata.config.general[tostring(configGenera.init_cid)]
        elseif nowGeneral.g_fashion == 6 then --红
            if configGenera.quality and configGenera.quality == 6 then
                gdata = gamedata.config.general[tostring(nowGeneral.cid)]
            elseif configGenera.quality and configGenera.quality == 7 then
                gdata = gamedata.config.general[tostring(configGenera.red_id)]
            end
        elseif nowGeneral.g_fashion == 7 then --金
            gdata = gamedata.config.general[tostring(nowGeneral.cid)]
        end
    end
    return gdata
end

function ui.getGeneralAnimationidSion(generalName, nowGeneral)
    local configGenera = gamedata.config.general[tostring(nowGeneral.illusionGeneralCid) or tostring(nowGeneral.cid)]
    if configGenera.init_cid and configGenera.init_cid > 0 and nowGeneral.g_fashion then
        local gdata = gamedata.config.general[tostring(configGenera.init_cid)]
        print("g_fashion == ", nowGeneral.g_fashion)
        if nowGeneral.g_fashion == 5 then --橙
            generalName = gamedata.config.generalanimation[tostring(gdata.animationid)].name
        elseif nowGeneral.g_fashion == 6 then --红
            if configGenera.quality and configGenera.quality == 6 then
                gdata = gamedata.config.general[tostring(nowGeneral.illusionGeneralCid) or tostring(nowGeneral.cid)]
                generalName = gamedata.config.generalanimation[tostring(gdata.animationid)].name
            elseif configGenera.quality and configGenera.quality == 7 then
                gdata = gamedata.config.general[tostring(configGenera.red_id)]
                generalName = gamedata.config.generalanimation[tostring(gdata.animationid)].name
            end
        elseif nowGeneral.g_fashion == 7 then --金
            gdata = gamedata.config.general[tostring(nowGeneral.illusionGeneralCid) or tostring(nowGeneral.cid)]
            generalName = gamedata.config.generalanimation[tostring(gdata.animationid)].name
        end
    end
    print("generalName == ", generalName)
    return generalName
end

function ui.getConfigGeneralSion(nowGeneral)
    local gdata = {}
    local configGenera = gamedata.config.general[tostring(nowGeneral.illusionGeneralCid or nowGeneral.general.illusionGeneralCid) or tostring(nowGeneral.cid or nowGeneral.general.cid)]
    if configGenera.init_cid and configGenera.init_cid > 0 and nowGeneral.g_fashion then
        if nowGeneral.g_fashion == 5 then --橙
            gdata = gamedata.config.general[tostring(configGenera.init_cid)]
        elseif nowGeneral.g_fashion == 6 then --红
            if configGenera.quality and configGenera.quality == 6 then
                gdata = gamedata.config.general[tostring(nowGeneral.illusionGeneralCid) or tostring(nowGeneral.cid)]
            elseif configGenera.quality and configGenera.quality == 7 then
                gdata = gamedata.config.general[tostring(configGenera.red_id)]
            end
        elseif nowGeneral.g_fashion == 7 then --金
            gdata = gamedata.config.general[tostring(nowGeneral.illusionGeneralCid) or tostring(nowGeneral.cid)]
        end
    end
    return gdata
end

-- 字符串查找
function ui.contains(str, item)
    local t = {}
    local l = {}
    local index = 0
    for i=1, string.len(str) do
        table.insert(t, string.byte(string.sub(str, i, i)))
    end
    for i=1, string.len(item) do
        table.insert(l, string.byte(string.sub(item, i, i)))
    end
    if #l > #t then
        return false
    end

    for k, v1 in pairs(t) do
        index = index + 1
        if v1 == l[1] then 
            local iscontens = true
            for i=1, #l do
                if t[index + i - 1] ~= l[i] then
                    iscontens = false
                end
            end
            if iscontens then 
                return iscontens 
            end
        end
    end
    return false
end

function ui.dightNum(num)
    if math.floor(num) ~= num or num<0 then
        return -1 
    elseif 0 == num then
        return 0
    else
        local tmp_dight = 0
        while num > 0 do
            num = math.floor(num/10)
            tmp_dight = tmp_dight + 1
        end
        return tmp_dight
    end
end

function ui.addZeroFrontNum(line, num)
    local num_dight = ui.dightNum(num)
    if -1 == num_dight then
        return -1
    elseif num_dight >= line then
        return tostring(num)
    else
        local str_e = ""
        for var=1, line-num_dight do
            str_e = str_e .. "0"
        end
        return str_e .. tostring(num)
    end
end

function ui.getCanReceiveData(data, state)
    printT(data,"jkp-data")
    local candata = {}
    for k,v in pairs(data) do
        if state == 2 then
            if v.status == state then
                table.insert(candata, v.iid)
            end
        elseif state == 4 then
            if v.sortdata == state then
                table.insert(candata, v.id)
            end
        end
    end
    printT(candata,"jkp-candata")
    return candata
end

return ui   �* 