--
-- Author: songyibo
-- Date: 2018-08-28 14:57:05
--

--查询
function UITitleQuery(t)
    printT(t,"称号查询 数据返回")
    if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodTitleData(t.data.title)
    end
    
end

--使用
function UITitleUse(t)
	printT(t,"称号使用 数据返回")

    GameScene.roleinfo.title = t.curTitle

	if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodTitleData(t.data.title)
        gameWindows.windows["roleinfo"].module:resetTitle(t.curTitle)
    end

    saveTitleOnceToSqlite(t.curTitle,0)
end

--获得
function UITitleGet(t)
	printT(t,"称号获得 数据返回")

	if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodTitleData(t.data.title)
    end

    if t.opt and t.opt == 0 then
        local config = gamedata.config.title[tostring(t.getTitle.cid)]
        runGamePromptTitle({type = "title",name = config.name,time = t.getTitle.time})
    end

    saveTitleOnceToSqlite(t.getTitle.cid,1)

end

--过期
function UITitleLose(t)
	printT(t,"称号过期 数据返回")

	local config = gamedata.config.title[tostring(t.loseTitle)]
	 runGamePrompt({msg=config.name..gameConfig.strings:string_common("fixedString","mainscene",25)})


	if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodTitleData(t.data.title)
        gameWindows.windows["roleinfo"].module:resetTitle(t.curTitle)
    end

    saveTitleOnceToSqlite(t.loseTitle,0)
end


--查询
function UIIconBoxQuery(t)
	printT(t,"头像框查询 数据返回")
	if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodIconBoxData(t.data.iconBox)
    end

end

--使用
function UIIconBoxUse(t)
	printT(t,"头像框使用 数据返回")

    GameScene.roleinfo.iconBox = t.curIconBox

	if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodIconBoxData(t.data.iconBox)
        gameWindows.windows["roleinfo"].module:resetIconBox(t.curIconBox)
    end

	GameScene:setIconBox(t.curIconBox)

    saveTitleOnceToSqlite(t.curIconBox,0)
end

--获得
function UIIconBoxGet(t)
	printT(t,"头像框获得 数据返回")

	if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodIconBoxData(t.data.iconBox)
    end

    if t.opt and t.opt == 0 then
        local config = gamedata.config.headframe[tostring(t.getIconBox.cid)]
        runGamePromptTitle({type = "iconBox",name = config.name,time = t.getIconBox.time})
    end

    saveTitleOnceToSqlite(t.getIconBox.cid,1)
end

--过期
function UIIconBoxLose(t)
	printT(t,"头像框过期 数据返回")
	local config = gamedata.config.headframe[tostring(t.loseIconBox)]
	 runGamePrompt({msg=config.name..gameConfig.strings:string_common("fixedString","mainscene",25)})

	if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:relaodIconBoxData(t.data.iconBox)
        gameWindows.windows["roleinfo"].module:resetIconBox(t.curIconBox)
    end

    saveTitleOnceToSqlite(t.loseIconBox,0)
end

function saveTitleOnceToSqlite(p_id,status)
    print("saveTitleOnceToSqlite",p_id,status)
    if not GameScene.roleinfo then
        return
    end
    
    local rid = GameScene.roleinfo.id or 0
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
    if rid < 1000000 then
        rid = serverid*1000000 + rid
    end    
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end
    local SQL = "UPDATE partnertitle SET pt_once=".. status .. " WHERE rid=" .. rid .. " AND pt_id="..p_id
    mydb:exec(SQL)
    if (mydb:changes() == 0) and (status == 1) then
        SQL = string.format("INSERT INTO partnertitle (rid,pt_id,pt_once) VALUES (%d,%d,%d)",rid,p_id,status)
        mydb:exec(SQL)
    end
    mydb:close()

    GameScene:setTitleHint()

    if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:reloadTitleHint()
    end
end
--
function getTitleOnceFromSqlite()
    local once = {}
    local rid = GameScene.roleinfo.id or 0
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
    if rid < 1000000 then
        rid = serverid*1000000 + rid
    end    
    local mydb = SQLite3Open()
    if nil == mydb then
        return once
    end
    local SQL = "SELECT count(*) AS ptexist FROM sqlite_master WHERE type='table' AND name='partnertitle'"
    local ret = 0
    for row in mydb:nrows(SQL) do
        ret = row["ptexist"]
    end
    if ret == 0 then
        local SQL = "CREATE TABLE IF NOT EXISTS partnertitle (rid INTEGER, pt_id INTEGER, pt_once INTEGER)";
        mydb:exec(SQL)
        return once
    end
    local SQL = "SELECT * FROM partnertitle WHERE rid=" .. rid
    for row in mydb:rows(SQL) do
        table.insert(once,{cid = tonumber(row[2]),status = tonumber(row[3])})
    end
    mydb:close()
    return once
end

