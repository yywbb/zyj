---
-- UIRequest : Send ui request to UI Queue
-- User: jutian
-- Date: 13-5-7
-- Time: 上午11:07
--

local uiqueue = require("uiqueue")

--- Send UI request to UI queue
-- @param uireq A table like {type=1001, param1=1, param2="sssss"}
-- @param isShowDetails Optional show param details in log.
function UIRequest_(uireq, isShowDetails)
	if (uireq == nil or type(uireq) ~= 'table') then
		echoErr("UIRequest(uireq) uireq must be a table whith key ['type']")
		return
	end

	isShowDetails = not not isShowDetails

	cclog("Send UIRequest uireq.type=%d to uiQueue.", uireq["type"])
	if isShowDetails and table.count(uireq) > 1 then
		cclog("UI Request params detail:")
--		printT(uireq)
    end

    if setTriggerGiftEnableByType then
        setTriggerGiftEnableByType(false,uireq.type)
    end

    if guide and guide.controller and guide.controller.isOnGuide and gamedata.config.guide_step then
        local sectionconfig = gamedata.config.guide_step[tostring(guide.controller.excute.section)]
        if sectionconfig  then
            local stepconfig =  sectionconfig[tostring(guide.controller.excute.step)]
            if stepconfig.redo == 0 and stepconfig.commit == uireq.type then
                print("guide combrequest section step ", guide.controller.excute.section,guide.controller.excute.step)
                local combrequest = {type = 999900, reqs = {
                    uireq,
                    {type=201,section=guide.controller.excute.section,step=guide.controller.excute.step}
                }}
                uiqueue.pushrequesttoclient(combrequest)
                return
            end
        end
    end

	--Push ui request to C++ UI queue
	uiqueue.pushrequesttoclient(uireq)
end

--跳转界面请求
function UIRequest(uireq, isShowDetails)
	UIRequest_(uireq, isShowDetails)
	--打开loading界面
--    if not isNetThread then
--        loading:startGameloading(uireq.type)
--    end
end

--点击请求
function UIRequestEx(uireq, isShowDetails)
	UIRequest_(uireq, isShowDetails)
	--打开loading界面
--    if not isNetThread then
--        loading:startGameloading(uireq.type)
--    end
end

--海外版有两个函数

function UIReponse(uirep)
    uiqueue.setresponsetoui(uirep)
end

function UIReqeustClear()
    cclog("UIReqeustClear")
    uiqueue.cleartoclient()
end

function UIResponseClear()
    uiqueue.cleartoui()
end

function CocosAutoRelease()
    uiqueue.autorelease()
end

UIResponse = UIReponse