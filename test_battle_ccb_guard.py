"""战斗技能动画 CCB 缺失导致挑战闪退的回归。

复现：普通副本点「挑战」后，元始天尊「光子锁定」(guangzisuoding) 触发
battleReportConvert 下发 name=<动画名>.."02"，而原包只有 <动画名>01.ccbi；
CCBReader 读取空 ccbi 在 native 层 SIGSEGV（GLThread, readNodeGraphFromFile）。

修复：不再从 01 派生 02.ccbi —— CCB 内部序列名与图片路径可能共用同一字符串
（daniepan01.ccbi 内含 daniepan/daniepan01.png），字节替换会造出并不存在的
daniepan02.png，native 层取不到精灵帧会 abort。改为按构建期资源实况，让战报与
战斗特效对「只有 01」的技能直接下发真实的 01；CCBReaderLoad 再加一层资源防护，
兜住 02_N / _6 / _7 等其它动态路径。
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
        patched = builder.get_patched_lua_scripts()
        self.assertFalse([k for k in patched if k.startswith("assets/battle/")])

    def test_daniepan_image_path_would_be_broken_by_derivation(self):
        """锁定上一版误改图片路径的根因，防止重新引入派生方案。"""
        with zipfile.ZipFile(SRC_APK) as z:
            data = z.read("assets/battle/daniepan/daniepan01.ccbi")
            self.assertIn(b"daniepan/daniepan01.png", data)
            self.assertIn("assets/battle/daniepan/daniepan01.png", z.namelist())
            self.assertNotIn("assets/battle/daniepan/daniepan02.png", z.namelist())
        self.assertIn("daniepan", builder.skill_animations_without_ccb02(BASE, SRC_APK))

    def test_battle_scripts_request_real_01_for_missing_02(self):
        patched = builder.get_patched_lua_scripts()
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


LUA_STUBS = """
cclog = function() end
existing = setmetatable({}, {__index = function() return false end})
checked = {}
native_called = 0
native_path = nil
CCFileUtils = { sharedFileUtils = function() return {
    fullPathForFilename = function(self, p)
        checked[#checked + 1] = p
        if existing[p] then return "assets/" .. p else return p end
    end
} end }
CCNode = { create = function() return {setVisible = function() end} end }
CCBProxy = { create = function() return {
    createCCBReader = function(self) return {} end,
    readCCBFromFile = function(self, path)
        native_called = native_called + 1
        native_path = path
        error("NATIVE_READER_REACHED")
    end
} end }
"""


def fresh_runtime():
    lua = lua51.LuaRuntime()
    lua.execute(LUA_STUBS)
    source = builder.read_script("CCBReaderLoad", "common_lua").decode("utf-8").replace("\r\n", "\n")
    lua.execute(builder.patch_ccb_reader_guard(source))
    return lua


class CCBReaderGuardTests(unittest.TestCase):
    def test_patched_script_compiles_and_keeps_global_entrypoints(self):
        lua = fresh_runtime()
        self.assertIsNotNone(lua.globals().CCBReaderLoad)
        self.assertIsNotNone(lua.globals().getAnimationManager)

    def test_existing_ccbi_goes_through_native_reader_unchanged(self):
        lua = fresh_runtime()
        lua.execute('existing["guangzisuoding/guangzisuoding02.ccbi"] = true')
        with self.assertRaises(lua51.LuaError) as caught:
            lua.globals().CCBReaderLoad("guangzisuoding/guangzisuoding02", None, True, "guangzisuoding02")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        self.assertEqual(lua.globals().native_called, 1)
        self.assertEqual(lua.globals().native_path, "guangzisuoding/guangzisuoding02")

    def test_missing_02_falls_back_to_real_01_without_extra_extension(self):
        lua = fresh_runtime()
        lua.execute('existing["guangzisuoding/guangzisuoding01.ccbi"] = true')
        with self.assertRaises(lua51.LuaError) as caught:
            lua.globals().CCBReaderLoad("guangzisuoding/guangzisuoding02", None, True, "guangzisuoding02")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        checked = [lua.globals().checked[i] for i in range(1, len(lua.globals().checked) + 1)]
        self.assertIn("guangzisuoding/guangzisuoding02.ccbi", checked)
        self.assertIn("guangzisuoding/guangzisuoding01.ccbi", checked)
        # CCBReader 内部自行补 .ccbi，传入的路径不能带扩展名。
        self.assertEqual(lua.globals().native_path, "guangzisuoding/guangzisuoding01")

    def test_dynamic_02_n_falls_back_to_01(self):
        lua = fresh_runtime()
        lua.execute('existing["guangzisuoding/guangzisuoding01.ccbi"] = true')
        with self.assertRaises(lua51.LuaError):
            lua.globals().CCBReaderLoad("guangzisuoding/guangzisuoding02_3", None, True, "guangzisuoding02_3")
        self.assertEqual(lua.globals().native_path, "guangzisuoding/guangzisuoding01")

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

    def test_patched_lua_scripts_include_guarded_common_lua_reader(self):
        patched = builder.get_patched_lua_scripts()
        key = "assets/common_lua/CCBReaderLoad.so"
        self.assertIn(key, patched)
        code = decrypt_script(patched, key)
        self.assertIn("missing ccbi", code)
        self.assertIn("_localDummyCCBAnimationManager", code)
        self.assertIn("CCNode:create()", code)
        lua51.LuaRuntime().execute("cclog = function() end\n" + code)


if __name__ == "__main__":
    unittest.main()
