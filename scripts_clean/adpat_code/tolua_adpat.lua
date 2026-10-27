


local DeprecatedToLuaName={
	["CCScale9Sprite"] = "ccui.Scale9Sprite",
	["CCEditBox"] = "ccui.EditBox",
	["CCScrollView"] = "cc.ScrollView",
	["CCNode"] = "cc.Node",
	["CCLabelTTF"] = "cc.Label",
}

local function my_tolua_cast( obj, name )
	return tolua.cast_(obj,DeprecatedToLuaName[name] or name)
end

local sys_tolua_cast = tolua.cast
tolua.cast_ = sys_tolua_cast

tolua.cast = my_tolua_cast