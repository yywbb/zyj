"""战斗技能动画 CCB 缺失导致挑战闪退的回归。

四代修复历程（每次实机闪退都推翻了上一代的假设）：
1. 元始天尊「光子锁定」guangzisuoding：battleReportConvert 固定下发 name.."02"，
   原包只有 01.ccbi，CCBReader 读到空文件在 native 层 SIGSEGV。
2. 从 01 等长派生 02.ccbi 又引入新崩溃：CCB 字符串表里序列名与真实图片路径
   共用同一串（daniepan01.ccbi 内含 daniepan/daniepan01.png），字节替换会造出
   不存在的 daniepan02.png，native 取不到精灵帧 abort。最终改为下发真实 01。
3. 2026-11-10 01:04 诛仙剑阵再崩：原包只有 zhuxianjianzhen02_1..02_7，8 个
   目标存活时 numberOfPeople 会请求 02_8；yuhuangjuntuan 固定循环 1..8。
   上一版 guard 用 fullPathForFilename 判断存在性，该 API 对不存在的文件也返回
   解析后的绝对路径，判断恒真。
4. 2026-11-10 01:50 又崩：全缓冲 logcat 里 ccbReader created 与
   create global ccb {} table object 出现 0 次，证明运行时加载的其实是
   assets/scripts/cocos/cocosbuilder/CCBReaderLoad.so，而前三版补丁全打在
   assets/common_lua/CCBReaderLoad.so —— 防护从来没被执行过。该版本用
   ccbReader:load() 而非 proxy:readCCBFromFile()，且 Load ccbi 日志的第二个参数
   tostring(owner) 恰好也是 "true"，此前被误认为是 common_lua 版。

最终方案（双保险）：
A. 三份同名 CCBReaderLoad.so 全部注入构建期实算的 _localCcbFiles 清单，缺失的
   战斗分片复用同族真实分片 / 01，或返回不可见空节点 + dummy 动画管理器，
   并在加载时打 [LocalMock] CCB guard active 标记，便于真机确认生效副本。
B. 源头钳制：构建期实算每个技能 02_N 的真实最大编号，注入 LocalCcbShard 到
   battleSkillModules.so / battleReportConvert.so，让文件名与动画序列名一起收敛，
   8 目标战斗不再生成 02_8，完成回调也能正常触发。
"""

import inspect
import json
import os
import re
import struct
import unittest
import zipfile

from lupa import lua51

import build_local_apk as builder

BASE = os.path.dirname(os.path.abspath(__file__))
SRC_APK = os.path.join(BASE, "z7_7_4.apk")

_FULL_PATCHED = None


def missing_pairs():
    """原包里有 01、没有 02 的技能动画名（不含视觉资源包补充项）。"""
    with zipfile.ZipFile(SRC_APK) as z, zipfile.ZipFile(os.path.join(BASE, "configs_sec5.zip")) as cfg:
        present = set(z.namelist())
        rows = json.loads(cfg.read("5/skillanimation.json")).values()
        result = set()
        for row in rows:
            name = row.get("name")
            if not name or not re.fullmatch(r"[A-Za-z0-9_]+", name):
                continue
            first = f"assets/battle/{name}/{name}01.ccbi"
            second = f"assets/battle/{name}/{name}02.ccbi"
            if first in present and second not in present:
                result.add(name)
        return result


def decrypt_script(patched, key):
    raw = builder.xxtea_decrypt(patched[key], builder.XXTEA_KEY)
    return raw[:struct.unpack("<I", raw[-4:])[0]].decode("utf-8")


def real_resource_inputs():
    visual = builder.visual_asset_names(BASE)
    return (builder.skill_animations_without_ccb02(BASE, SRC_APK, visual),
            builder.ccb_resource_keys(SRC_APK, visual),
            builder.ccb_max_shards(SRC_APK, visual))


def full_patched():
    """整套真实补丁脚本只构建一次，多个用例共享（构建较慢）。"""
    global _FULL_PATCHED
    if _FULL_PATCHED is None:
        _FULL_PATCHED = builder.get_patched_lua_scripts(*real_resource_inputs())
    return _FULL_PATCHED


class SkillCCBNamingTests(unittest.TestCase):
    def test_missing_02_names_match_real_apk_resources(self):
        names = builder.skill_animations_without_ccb02(BASE, SRC_APK)
        expected = missing_pairs()
        self.assertEqual(set(names), expected)
        self.assertGreater(len(names), 100)
        self.assertIn("guangzisuoding", names)
        with zipfile.ZipFile(SRC_APK) as z:
            present = set(z.namelist())
            for name in names:
                self.assertIn(f"assets/battle/{name}/{name}01.ccbi", present, name)
                self.assertNotIn(f"assets/battle/{name}/{name}02.ccbi", present, name)

    def test_visual_pack_02_is_honoured(self):
        name = "guangzisuoding"
        target = f"assets/battle/{name}/{name}02.ccbi"
        names = builder.skill_animations_without_ccb02(BASE, SRC_APK, {target})
        self.assertEqual(set(names), missing_pairs() - {name})

    def test_no_synthetic_ccb_assets_are_ever_built(self):
        source = inspect.getsource(builder)
        self.assertNotIn("build_missing_skill_ccb_assets", source)
        self.assertNotIn("derived_ccb", source)
        self.assertFalse([k for k in full_patched() if k.startswith("assets/battle/")])

    def test_daniepan_image_path_would_be_broken_by_derivation(self):
        """锁定上一版误改图片路径的根因，防止重新引入派生方案。"""
        with zipfile.ZipFile(SRC_APK) as z:
            data = z.read("assets/battle/daniepan/daniepan01.ccbi")
            self.assertIn(b"daniepan/daniepan01.png", data)
            self.assertIn("assets/battle/daniepan/daniepan01.png", z.namelist())
            self.assertNotIn("assets/battle/daniepan/daniepan02.png", z.namelist())
        self.assertIn("daniepan", builder.skill_animations_without_ccb02(BASE, SRC_APK))

    def test_battle_scripts_request_real_01_for_missing_02(self):
        patched = full_patched()
        report = decrypt_script(patched, "assets/scripts/battleReportConvert.so")
        general = decrypt_script(patched, "assets/scripts/battlegeneral.so")
        expression = '(_localNoSkillCcb02[skillanimation.name] and "01" or "02")'
        general_expression = '(_localNoSkillCcb02[_dir] and "01" or "02")'
        self.assertEqual(report.count(expression), 2)
        self.assertNotIn('skillanimation.name.."02"', report)
        self.assertEqual(general.count(general_expression), 1)
        self.assertNotIn('_dir.."02"', general)
        compile_only = lua51.LuaRuntime().eval(
            "function(s) local f, e = loadstring(s); assert(f, e) end")
        for code in (report, general):
            self.assertIn('["guangzisuoding"]=true', code)
            compile_only(code)

    def test_lua_whitelist_chooses_01_only_for_missing_02(self):
        names = builder.skill_animations_without_ccb02(BASE, SRC_APK)
        table_code = builder.lua_no_ccb02_table(names)
        lua = lua51.LuaRuntime()
        lua.execute(table_code + "\n" +
                    'choose = function(name) return name .. (_localNoSkillCcb02[name] and "01" or "02") end')
        choose = lua.globals().choose
        self.assertEqual(choose("guangzisuoding"), "guangzisuoding01")
        self.assertEqual(choose("daniepan"), "daniepan01")
        self.assertEqual(choose("definitely_not_a_skill"), "definitely_not_a_skill02")

    def test_zhuxianjianzhen_has_02_1_to_02_7_but_never_02_8(self):
        """锁定 2026-11-10 01:04 崩溃：8 目标战斗请求了不存在的 02_8。"""
        with zipfile.ZipFile(SRC_APK) as z:
            names = set(z.namelist())
        for i in range(1, 8):
            self.assertIn(f"assets/battle/zhuxianjianzhen/zhuxianjianzhen02_{i}.ccbi", names)
        self.assertNotIn("assets/battle/zhuxianjianzhen/zhuxianjianzhen02_8.ccbi", names)
        self.assertNotIn("assets/battle/zhuxianjianzhen/zhuxianjianzhen01.ccbi", names)

    def test_ccb_resource_keys_cover_every_packaged_ccbi(self):
        keys = set(builder.ccb_resource_keys(SRC_APK))
        self.assertGreater(len(keys), 1000)
        with zipfile.ZipFile(SRC_APK) as z:
            ccbi = [n for n in z.namelist() if n.lower().endswith(".ccbi")]
        self.assertGreater(len(ccbi), 1000)
        for name in ccbi:
            rel = name[len("assets/"):-len(".ccbi")] if name.startswith("assets/") else name[:-len(".ccbi")]
            self.assertIn("/".join(rel.split("/")[-2:]), keys, name)
        self.assertIn("zhuxianjianzhen/zhuxianjianzhen02_7", keys)
        self.assertNotIn("zhuxianjianzhen/zhuxianjianzhen02_8", keys)

    def test_lua_resource_table_compiles_and_looks_up(self):
        keys = builder.ccb_resource_keys(SRC_APK)
        lua = lua51.LuaRuntime()
        lua.execute(builder.lua_ccb_resource_table(keys) + "\n" +
                    'has = function(k) return _localCcbFiles[k] == true end')
        has = lua.globals().has
        self.assertTrue(has("zhuxianjianzhen/zhuxianjianzhen02_7"))
        self.assertFalse(has("zhuxianjianzhen/zhuxianjianzhen02_8"))

    def test_existence_check_never_uses_full_path_for_filename(self):
        """fullPathForFilename 对缺失文件同样返回绝对路径，绝不能再用于存在性判断。"""
        self.assertNotIn("fullPathForFilename", builder.CCB_READER_GUARD)
        self.assertIn("_localCcbFiles", builder.CCB_READER_GUARD)

    def test_ccb_max_shards_match_real_apk_resources(self):
        shards = builder.ccb_max_shards(SRC_APK, builder.visual_asset_names(BASE))
        self.assertGreater(len(shards), 5)
        self.assertEqual(shards[("zhuxianjianzhen", "02")], 7)
        with zipfile.ZipFile(SRC_APK) as z:
            names = set(z.namelist())
        for (anim, kind), max_n in shards.items():
            self.assertIn(f"assets/battle/{anim}/{anim}{kind}_{max_n}.ccbi", names)
            self.assertNotIn(f"assets/battle/{anim}/{anim}{kind}_{max_n + 1}.ccbi", names)

    def test_lua_shard_clamp_function(self):
        shards = builder.ccb_max_shards(SRC_APK, builder.visual_asset_names(BASE))
        lua = lua51.LuaRuntime()
        lua.execute(builder.lua_ccb_shard_table(shards) + "\n"
                    "clamp = function(name, n) return LocalCcbShard(name, n) end")
        clamp = lua.globals().clamp
        self.assertEqual(clamp("zhuxianjianzhen", 8), 7)
        self.assertEqual(clamp("zhuxianjianzhen", 3), 3)
        self.assertEqual(clamp("zhuxianjianzhen", 0), 1)
        self.assertEqual(clamp("definitely_not_a_skill", 8), 8)

    def test_battle_scripts_clamp_every_02_n_concat(self):
        patched = full_patched()
        compile_only = lua51.LuaRuntime().eval(
            "function(s) local f, e = loadstring(s); assert(f, e) end")
        modules = decrypt_script(patched, "assets/scripts/battleSkillModules.so")
        report = decrypt_script(patched, "assets/scripts/battleReportConvert.so")
        self.assertGreaterEqual(modules.count("LocalCcbShard("), 12)
        self.assertGreaterEqual(report.count("LocalCcbShard("), 3)
        self.assertIn('["zhuxianjianzhen02"]=7', modules)
        self.assertIn('["zhuxianjianzhen02"]=7', report)
        self.assertNotIn('zhuxianjianzhen02_"..destnum', modules)
        self.assertNotIn('.."02_"..select,', report)
        for code in (modules, report):
            compile_only(code)


# fullPathForFilename 恒返回解析后的绝对路径 —— 这正是真机上的实际行为，
# 也是前两版防护失效的原因；新防护必须完全不看它。
LUA_STUBS = """
cclog = function() end
native_called = 0
native_path = nil
cc = {CCBReader = {}, Node = {create = function() return {setVisible = function() end} end}}
gamedata = {gameconfig = {sysFontName = "Arial"}}
CCFileUtils = { sharedFileUtils = function() return {
    fullPathForFilename = function(self, p) return "assets/" .. p end
} end }
CCNode = { create = function() return {setVisible = function() end} end }
CCBProxy = { create = function() return {
    createCCBReader = function(self) return {
        setFontNameForTTF = function() end,
        load = function(self, path)
            native_called = native_called + 1
            native_path = path
            error("NATIVE_READER_REACHED")
        end
    } end,
    readCCBFromFile = function(self, path)
        native_called = native_called + 1
        native_path = path
        error("NATIVE_READER_REACHED")
    end
} end }
"""

TEST_CCB_KEYS = [
    "guangzisuoding/guangzisuoding01",
    "zhuxianjianzhen/zhuxianjianzhen02_1",
    "zhuxianjianzhen/zhuxianjianzhen02_2",
    "zhuxianjianzhen/zhuxianjianzhen02_7",
]


def fresh_runtime(keys=None, folder="common_lua", rel="CCBReaderLoad"):
    lua = lua51.LuaRuntime()
    lua.execute(LUA_STUBS)
    source = builder.read_script(rel, folder).decode("utf-8").replace("\r\n", "\n")
    lua.execute(builder.patch_ccb_reader_guard(
        source, TEST_CCB_KEYS if keys is None else keys, folder))
    return lua


class CCBReaderGuardTests(unittest.TestCase):
    def test_patched_script_compiles_and_keeps_global_entrypoints(self):
        lua = fresh_runtime()
        self.assertIsNotNone(lua.globals().CCBReaderLoad)
        self.assertIsNotNone(lua.globals().getAnimationManager)

    def test_existing_ccbi_goes_through_native_reader_unchanged(self):
        lua = fresh_runtime()
        with self.assertRaises(lua51.LuaError) as caught:
            lua.globals().CCBReaderLoad("zhuxianjianzhen/zhuxianjianzhen02_7", None, True, "z02_7")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        self.assertEqual(lua.globals().native_called, 1)
        self.assertEqual(lua.globals().native_path, "zhuxianjianzhen/zhuxianjianzhen02_7")

    def test_missing_02_falls_back_to_real_01_without_extra_extension(self):
        lua = fresh_runtime()
        with self.assertRaises(lua51.LuaError) as caught:
            lua.globals().CCBReaderLoad("guangzisuoding/guangzisuoding02", None, True, "guangzisuoding02")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        # CCBReader 内部自行补 .ccbi，传入的路径不能带扩展名。
        self.assertEqual(lua.globals().native_path, "guangzisuoding/guangzisuoding01")

    def test_dynamic_02_n_falls_back_to_01(self):
        lua = fresh_runtime()
        with self.assertRaises(lua51.LuaError):
            lua.globals().CCBReaderLoad("guangzisuoding/guangzisuoding02_3", None, True, "g02_3")
        self.assertEqual(lua.globals().native_path, "guangzisuoding/guangzisuoding01")

    def test_missing_02_8_reuses_real_shard_never_passes_missing_path(self):
        """缺失分片会复用真实存在的 02_1（或 01），绝不能把 02_8 交给 native。"""
        lua = fresh_runtime()
        with self.assertRaises(lua51.LuaError):
            lua.globals().CCBReaderLoad(
                "zhuxianjianzhen/zhuxianjianzhen02_8", None, True, "zhuxianjianzhen02_8")
        self.assertEqual(lua.globals().native_called, 1)
        self.assertEqual(lua.globals().native_path, "zhuxianjianzhen/zhuxianjianzhen02_1")

    def test_unlisted_ui_path_is_not_blocked(self):
        """非战斗路径不靠清单判定，避免误伤 UI 与热更资源。"""
        lua = fresh_runtime()
        with self.assertRaises(lua51.LuaError) as caught:
            lua.globals().CCBReaderLoad("recharge/cell_recharge_info_new", None, True, "c")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        self.assertEqual(lua.globals().native_path, "recharge/cell_recharge_info_new")

    def test_single_segment_path_is_not_blocked(self):
        """无目录的单段路径即使以 02 结尾也不按战斗分片拦截。"""
        lua = fresh_runtime()
        with self.assertRaises(lua51.LuaError) as caught:
            lua.globals().CCBReaderLoad("panel02", None, True, "panel02")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        self.assertEqual(lua.globals().native_path, "panel02")

    def test_fully_missing_resource_never_reaches_native_reader(self):
        lua = fresh_runtime()
        node, items, proxy = lua.globals().CCBReaderLoad("unknown/skill02", None, True, "skill02")
        self.assertIsNotNone(node)
        self.assertIsNotNone(items)
        self.assertIsNotNone(proxy)
        self.assertEqual(lua.globals().native_called, 0)
        self.assertIsNone(items.topnode)
        self.assertIsNotNone(lua.globals().getAnimationManager(items))

    def test_missing_animation_manager_returns_callable_dummy(self):
        lua = fresh_runtime()
        lua.execute("""
            manager = getAnimationManager({})
            manager:setAnimationCompletedCallback(function() end)
            manager:runAnimationsForSequenceNamed("missing02")
            nil_manager = getAnimationManager(nil)
            nil_manager:runAnimationsForSequenceNamed("missing02")
        """)
        self.assertIsNotNone(lua.globals().manager)
        self.assertIsNotNone(lua.globals().nil_manager)

    def test_all_three_reader_variants_are_guarded(self):
        """前三版只打 common_lua，真机跑的是 cocos/cocosbuilder，必须三份全打。"""
        patched = full_patched()
        self.assertEqual(len(builder.CCB_READER_SCRIPTS), 3)
        for key, _rel, folder, tag in builder.CCB_READER_SCRIPTS:
            self.assertIn(key, patched)
            code = decrypt_script(patched, key)
            self.assertIn("_localCcbFiles", code)
            self.assertIn("missing ccbi", code)
            self.assertIn("CCB guard active", code)
            self.assertIn(json.dumps(tag), code)
            self.assertIn('["zhuxianjianzhen/zhuxianjianzhen02_7"]=true', code)
            self.assertNotIn('["zhuxianjianzhen/zhuxianjianzhen02_8"]=true', code)
            self.assertNotIn("fullPathForFilename", code)
            self.assertIn("CCNode:create()", code)
            lua51.LuaRuntime().execute(
                "cclog=function() end\ncc={CCBReader={}}\n" + code)

    def test_runtime_variant_identification_is_locked_by_log_evidence(self):
        """用日志特征锁定「哪份是运行时版本」，避免再打错文件。"""
        common = builder.read_script("CCBReaderLoad", "common_lua").decode("utf-8")
        cocos = builder.read_script("CCBReaderLoad", "scripts/cocos/cocosbuilder").decode("utf-8")
        self.assertIn("ccbReader created", common)
        self.assertNotIn("ccbReader created", cocos)
        self.assertIn("create global ccb {} table object.", common)
        self.assertNotIn("create global ccb {} table object.", cocos)
        self.assertIn("ccbReader:load(strFilePath)", cocos)
        self.assertNotIn("ccbReader:load(strFilePath)", common)
        self.assertIn("tostring(owner)", cocos)
        paths = {item[0] for item in builder.CCB_READER_SCRIPTS}
        self.assertIn("assets/scripts/cocos/cocosbuilder/CCBReaderLoad.so", paths)
        self.assertIn("assets/common_lua/CCBReaderLoad.so", paths)
        self.assertIn("assets/scripts/adpat_demo/util/CCBReaderLoad.so", paths)

    def test_runtime_cocos_reader_blocks_missing_02_8(self):
        """真正生效的那份脚本也必须拦住 02_8（用真实包内清单）。"""
        keys = builder.ccb_resource_keys(SRC_APK, builder.visual_asset_names(BASE))
        lua = lua51.LuaRuntime()
        lua.execute(LUA_STUBS)
        code = decrypt_script(full_patched(), "assets/scripts/cocos/cocosbuilder/CCBReaderLoad.so")
        lua.execute(code)
        with self.assertRaises(lua51.LuaError):
            lua.globals().CCBReaderLoad(
                "zhuxianjianzhen/zhuxianjianzhen02_8", None, True, "zhuxianjianzhen02_8")
        self.assertNotEqual(lua.globals().native_path, "zhuxianjianzhen/zhuxianjianzhen02_8")
        self.assertEqual(lua.globals().native_path, "zhuxianjianzhen/zhuxianjianzhen02_1")
        lua.execute("dummy_mgr = getAnimationManager({})")
        self.assertIsNotNone(lua.globals().dummy_mgr)

    def test_real_packaged_script_blocks_02_8_but_allows_02_7(self):
        """用真实包内清单 + 真机路径形态验证：缺失路径不进 native，存在分片正常。"""
        code = decrypt_script(full_patched(), "assets/common_lua/CCBReaderLoad.so")
        lua = lua51.LuaRuntime()
        lua.execute(LUA_STUBS)
        lua.execute(code)
        with self.assertRaises(lua51.LuaError):
            lua.globals().CCBReaderLoad("zhuxianjianzhen/zhuxianjianzhen02_8", None, True, "z02_8")
        self.assertEqual(lua.globals().native_path, "zhuxianjianzhen/zhuxianjianzhen02_1")
        with self.assertRaises(lua51.LuaError) as caught:
            lua.globals().CCBReaderLoad(
                "zhuxianjianzhen/zhuxianjianzhen02_7", None, True, "z02_7")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        self.assertEqual(lua.globals().native_path, "zhuxianjianzhen/zhuxianjianzhen02_7")


if __name__ == "__main__":
    unittest.main()
