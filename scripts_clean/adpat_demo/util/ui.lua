--[[
-- UI module: ui object creator helper.
-- 创建和管理 UI 界面元素
-- User: liliang
-- Date: 13-7-18
-- Time: 上午11:26
]] --

local ui = {
}


function ui.addProflayer(parent,touchPriority,Zorder,color,size,AnchorPoint,Position,callback,log)
    local Proflayer = CCLayerColor:create(color)
    Proflayer:setContentSize(size or CCSizeMake(1080,1920))
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

    Proflayer:registerScriptTouchHandler(onTouch, false, touchPriority, true)
    -- Proflayer:setTouchPriority(touchPriority)
    Proflayer:setTouchEnabled(true)
    return Proflayer
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

--creat input editbox by layer, node and mode

--[[  mode desc:
kEditBoxInputModeAny : The user is allowed to enter any text, including line breaks.
kEditBoxInputModeEmailAddr : The user is allowed to enter an e-mail address.
kEditBoxInputModeNumeric : The user is allowed to enter an integer value.
kEditBoxInputModePhoneNumber : The user is allowed to enter a phone number.
kEditBoxInputModeUrl : The user is allowed to enter a URL.
kEditBoxInputModeDecimal : The user is allowed to enter a real number value. This extends kEditBoxInputModeNumeric by allowing a decimal point.
kEditBoxInputModeSingleLine : The user is allowed to enter any text, except for line breaks. ]] --

local function checksensitiveWord(str)
    if gameConfig.sensitiveWord and next(gameConfig.sensitiveWord) then
        for k,v in pairs(gameConfig.sensitiveWord) do
            local s1 = string.lower(str)
            local s2 = string.lower(v)
            if string.find(s1,s2) then
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

local function checkLength(str,length)

    -- if gamedata and gamedata.device and gamedata.device.platform == "android" then
    --     print(str,"   ==str")
    --     local newstr = "" --default to filter the emoji
    --     for unchar in string.gfind(str,"[%z\32-\126\226-\233][\128-\191]*") do
    --         print(unchar,"   ==unchar")
    --         local temp = newstr
    --         newstr = temp .. unchar
    --     end
    --     print(newstr,"   ==newstr")
    --     str = newstr == "" and " " or newstr
    -- end

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

function ui.creatInputEditBoxByNode(node, mode, beginfunc, endfunc, arg)

    local args = arg or {}

    local inputEditBox = nil --聊天输入框
    local function editBoxTextEventHandle(strEventName, pSender)
        local edit = tolua.cast(pSender, "ccui.EditBox")
        local strFmt
        if strEventName == "began" then
            beginfunc(edit:getText())
        elseif strEventName == "ended" then
           
            edit:setText(restStr)
            endfunc(restStr)
        elseif strEventName == "return" then

        elseif strEventName == "changed" then
        end
    end

    inputEditBox = CCEditBox:create(CCSizeMake(node:getContentSize().width,node:getContentSize().height), CCScale9Sprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(gameConfig.images.alpha)))
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
    inputEditBox:setInputMode(kEditBoxInputModeSingleLine)
    --Handler
    inputEditBox:registerScriptEditBoxHandler(editBoxTextEventHandle)


    return inputEditBox
end

function ui.creatInputEditBoxBylable(label, mode, beginfunc, endfunc, arg)
    local args = arg or {}

    local inputEditBox = nil --聊天输入框

    local function editBoxTextEventHandle(strEventName, pSender)
        local edit = tolua.cast(pSender, "ccui.EditBox")
        local strFmt
        if strEventName == "began" then
            print("editBox %p DidBegin !")
            if beginfunc then
                beginfunc(label,edit)
            end
        elseif strEventName == "ended" then
            print("editBox %p DidEnd !")
                local istoolong, restStr = checkLength(edit:getText(), args.length or 60)
                endfunc(label,restStr,edit)
        elseif strEventName == "return" then

        elseif strEventName == "changed" then

        end
    end

    print("label:getDimensions().width,label:getDimensions().height",label:getDimensions().width,label:getDimensions().height)
    inputEditBox = CCEditBox:create(CCSizeMake(label:getDimensions().width,label:getDimensions().height), CCScale9Sprite:createWithSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("alpha.png")))
    label:addChild(inputEditBox)

    inputEditBox:setScale(1)
    inputEditBox:setAnchorPoint(ccp(0,0))
    inputEditBox:setPosition(ccp(0, 0))

    --inputEditBox:setFontName(args.fontName or "Helvetica-Bold")
    inputEditBox:setFontSize((args.fontSize or 48))
    inputEditBox:setFontColor(args.fontColor or ccc3(0, 0, 0))

    inputEditBox:setPlaceholderFontSize((args.fontSize or 48))
    inputEditBox:setPlaceHolder(args.PlaceHolder or "")
    inputEditBox:setPlaceholderFontColor(args.PlaceholderFontColor or ccc3(100, 100, 100))

    inputEditBox:setMaxLength(args.length or 60)
    inputEditBox:setReturnType(kKeyboardReturnTypeDone)
    --设置输入模式
    inputEditBox:setInputMode(kEditBoxInputModeSingleLine)
    --Handler
    inputEditBox:registerScriptEditBoxHandler(editBoxTextEventHandle)

    return inputEditBox
end


return ui