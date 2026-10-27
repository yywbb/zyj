

--消息队列先转化成json串，减少压栈次数

local function convertKeyTostring(datatable)

    local newT = {}
    for k,v in pairs(datatable) do
        if type(v) == "table" then
            newT[tostring(k)] = convertKeyTostring(v)
        elseif type(v) == "boolean" then
            newT[tostring(k)] = v and 1 or 0
        else
            newT[tostring(k)] = v
        end
    end
    return newT
end

local function setresponsetoui_ext( uirep )

    if uirep.needdecode then
        uiqueue.setresponsetoui_(uirep)
        return
    end

    local newuirep = {
        type = uirep.type,
        needdecode = true,
        data = MakeJsonStringFromTable(convertKeyTostring(uirep))
    }
    uiqueue.setresponsetoui_(newuirep)
end

local setresponsetoui_old = uiqueue.setresponsetoui
uiqueue.setresponsetoui_ = setresponsetoui_old
uiqueue.setresponsetoui = setresponsetoui_ext



local function popresponsefromclient_ext( uireq )

    local tret = uiqueue.popresponsefromclient_()

    if tret == nil then return nil end

    if tret.needdecode and tret.data then
        tret = LoadJsonStringToTable(tret.data)
    end

	return tret
end

local popresponsefromclient_old = uiqueue.popresponsefromclient
uiqueue.popresponsefromclient_ = popresponsefromclient_old
uiqueue.popresponsefromclient = popresponsefromclient_ext