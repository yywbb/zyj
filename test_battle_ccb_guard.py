"""战斗技能动画 CCB 缺失导致挑战闪退的回归。

复现：普通副本点「挑战」后，元始天尊「光子锁定」(guangzisuoding) 触发
battleReportConvert 下发 name=<动画名>.."02"，而原包只有 <动画名>01.ccbi；
CCBReader 读取空 ccbi 在 native 层 SIGSEGV（GLThread, readNodeGraphFromFile）。
修复：打包时批量派生缺失的 02.ccbi，并给 CCBReaderLoad 加资源存在性防护。
"""

import json
import os
import re
import struct
import unittest
import zipfile

import lupa

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


class DerivedCCBTests(unittest.TestCase):
    def test_all_missing_02_assets_are_derived_from_01(self):
        expected = missing_pairs()
        self.assertGreater(len(expected), 100)
        self.assertIn("guangzisuoding", expected)
        with zipfile.ZipFile(SRC_APK) as z:
            originals = set(z.namelist())
            assets = builder.build_missing_skill_ccb_assets(BASE, SRC_APK, {})
            self.assertEqual(set(assets), {f"assets/battle/{n}/{n}02.ccbi" for n in expected})
            self.assertFalse(set(assets) & originals, "不得覆盖原包已有资源")
            for path, derived in assets.items():
                name = path[len("assets/battle/"):].split("/")[0]
                source = z.read(f"assets/battle/{name}/{name}01.ccbi")
                self.assertEqual(len(derived), len(source), name)
                self.assertEqual(derived[:4], b"ibcc", name)
                self.assertEqual(derived, source.replace((name + "01").encode(), (name + "02").encode()), name)
            # 复现用例：元始天尊「光子锁定」的 01 里确有序列名，派生后必须变成 02。
            derived = assets["assets/battle/guangzisuoding/guangzisuoding02.ccbi"]
            self.assertIn(b"guangzisuoding02", derived)
            self.assertNotIn(b"guangzisuoding01", derived)

    def test_existing_02_assets_are_never_replaced(self):
        name = "guangzisuoding"
        target = f"assets/battle/{name}/{name}02.ccbi"
        assets = builder.build_missing_skill_ccb_assets(BASE, SRC_APK, {target: b"provided-by-visual-pack"})
        self.assertNotIn(target, assets)
        self.assertEqual(set(assets), {f"assets/battle/{n}/{n}02.ccbi" for n in missing_pairs() - {name}})


LUA_STUBS = """
cclog = function() end
existing = setmetatable({}, {__index = function() return false end})
checked = {}
native_called = 0
CCFileUtils = { sharedFileUtils = function() return {
    fullPathForFilename = function(self, p)
        checked[#checked + 1] = p
        if existing[p] then return "assets/" .. p else return p end
    end
} end }
CCBProxy = { create = function() return {
    createCCBReader = function(self)
        native_called = native_called + 1
        error("NATIVE_READER_REACHED")
    end
} end }
cc = { Node = { create = function() return {setVisible = function() end} end } }
"""


def fresh_runtime():
    lua = lupa.LuaRuntime()
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
        with self.assertRaises(lupa.LuaError) as caught:
            lua.globals().CCBReaderLoad("guangzisuoding/guangzisuoding02", None, True, "guangzisuoding02")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        self.assertEqual(lua.globals().native_called, 1)

    def test_missing_02_falls_back_to_01(self):
        lua = fresh_runtime()
        lua.execute('existing["guangzisuoding/guangzisuoding01.ccbi"] = true')
        with self.assertRaises(lupa.LuaError) as caught:
            lua.globals().CCBReaderLoad("guangzisuoding/guangzisuoding02", None, True, "guangzisuoding02")
        self.assertIn("NATIVE_READER_REACHED", str(caught.exception))
        checked = [lua.globals().checked[i] for i in range(1, len(lua.globals().checked) + 1)]
        self.assertIn("guangzisuoding/guangzisuoding02.ccbi", checked)
        self.assertIn("guangzisuoding/guangzisuoding01.ccbi", checked)

    def test_fully_missing_resource_never_reaches_native_reader(self):
        lua = fresh_runtime()
        node, items = lua.globals().CCBReaderLoad("unknown/skill02", None, True, "skill02")
        self.assertIsNotNone(node)
        self.assertIsNotNone(items)
        self.assertEqual(lua.globals().native_called, 0)
        self.assertIsNone(items.topnode)

    def test_missing_animation_manager_returns_callable_dummy(self):
        lua = fresh_runtime()
        lua.execute("""
            manager = getAnimationManager({})
            manager:setAnimationCompletedCallback(function() end)
            manager:runAnimationsForSequenceNamed("missing02")
        """)
        self.assertIsNotNone(lua.globals().manager)
        self.assertIsNotNone(lua.globals().getAnimationManager())

    def test_patched_lua_scripts_include_guarded_common_lua_reader(self):
        patched = builder.get_patched_lua_scripts()
        key = "assets/common_lua/CCBReaderLoad.so"
        self.assertIn(key, patched)
        raw = builder.xxtea_decrypt(patched[key], builder.XXTEA_KEY)
        code = raw[:struct.unpack("<I", raw[-4:])[0]].decode("utf-8")
        self.assertIn("missing ccbi", code)
        self.assertIn("_localDummyCCBAnimationManager", code)
        lupa.LuaRuntime().execute("cclog = function() end\n" + code)


if __name__ == "__main__":
    unittest.main()
