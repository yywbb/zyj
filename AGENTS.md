# Project instructions

## Workspace quirks

- `._*` files are macOS AppleDouble metadata, not source; exclude them from searches and staging. Existing sidecars under `.git/refs` and `.git/objects/pack` make `git fsck` report invalid refs/packs; do not treat `._*` entries as real Git refs or objects.

## Run and verify

- Python uses only the standard library. Run regressions with `python3 -B -m unittest -v test_mock_server`; one case: `python3 -B -m unittest -v test_mock_server.ReplayRoutingTests.test_select_does_not_receive_city_init_at_same_sequence`. Tests use temporary saves, not the real `role_save.json`. Syntax check: `python3 -m compileall -q mock_server.py zyj_server build_local_apk.py test_mock_server.py`. No CI, linter, or formatter is configured.
- Neither entrypoint implements `--help` or a dry-run: unknown flags still run the server/build. Do not invoke them just to inspect usage.
- `python3 mock_server.py` starts TCP port **14600** and attempts `adb reverse` for devices connected at startup. Missing `adb` only logs a warning; a listening server does not prove device connectivity. For a later-connected device, run `adb reverse tcp:14600 tcp:14600`.
- Despite the local-client address, the server binds **`0.0.0.0:14600`**, not loopback; keep it on a trusted network.
- All connections share `role_save.json` beside the server script. `--reset` deletes the entire save; `--reset-guide` clears guide progress but preserves role data. Back up progress before reset/testing; the save is Git-ignored.
- Device verification requires a separately supplied/rebuilt APK: `adb install -r zyj_local.apk`, then `adb shell monkey -p com.ldfs.zyjyg.local -c android.intent.category.LAUNCHER 1`. Check both fresh-account progression and reconnect/resume when changing guide or replay behavior; syntax checks cannot validate gameplay.

## Server modules

- `mock_server.py` owns CLI/ADB/TCP and root-relative resource paths. It loads configuration/recordings at startup, not import time, and passes paths and configuration explicitly into `zyj_server.session.Session`.
- `Session.handle(opcode, seq, body)` returns ordered, fully packed frames without a socket. Any exception ends the connection; do not reuse a failed session. Recordings are shared, but each session owns a `Replay` with independent counters.
- `zyj_server/` separates protocol, guide, player persistence/state, replay matching, and session dispatch. Do not import the entrypoint back into these modules or re-export their helpers from it; tests import the owning module and use temporary save paths.

## APK build sources and traps

- Build with `python3 build_local_apk.py`. Supply the original **`z7_7_4.apk` beside the script**; APKs are ignored and not distributed in Git. Offline configs come from tracked `configs_sec5.zip`; signing uses `debug.keystore`.
- The builder is currently Windows-specific: `find_tool()` searches for **`zipalign.exe` / `apksigner.bat`** on `PATH`, then under `ANDROID_HOME/build-tools`; `.bat` runs through `cmd /c`. Stock macOS/Linux SDK tool names are not discovered, despite README platform claims.
- **Editing `scripts_clean/` does not change the built APK**, despite the README. `get_patched_lua_scripts()` decrypts selected scripts directly from the original APK and applies asserted replacements. Implement packaged Lua changes there; the on-disk Lua trees are analysis references.
- `scripts_decrypted/` can contain trailing padding/length bytes. Use `read_script()` to recover actual Lua and `xxtea_encrypt()` to repackage it; encryption must include the final little-endian original-length word.
- Keep `_disabled_patches()` disabled: its client role-reporting/gameplay changes are historical, not part of the active build. Prefer faithful server responses/config corrections over bypassing gameplay.
- The build edits the original ZIP/binary resources directly, then **zipalign → apksigner sign → apksigner verify**. Preserve version-specific replacement assertions rather than bypassing them or substituting an Apktool rebuild.
- Config JSONs are injected into **both `assets/config/1/` and `assets/config/5/`**. Tutorial popup hitbox fixes live in `patch_guide_step()`; `GUIDE_CONFIRM_XY` is device-calibrated, not a universal coordinate.

## Wire protocol and guide invariants

- `recorded_frames.json` contains ordered `{c2s, opcode, seq, hex}` records; `hex` is the **payload only**. TCP framing is a 16-byte big-endian `>IIII` header: magic `0x0000EE1C`, payload length, opcode, sequence. Preserve stream buffering/reassembly; one TCP packet is not necessarily one protocol frame.
- Routing first handles live save/guide operations. Ordinary sequence hits must also match opcode and payload; opcode **999900** uses embedded IDs **plus the complete request payload**, never sequence alone. Exact payloads distinguish battle maps/points and equipment/general IDs; unrecorded combinations still return an empty reply. Do not group arbitrary adjacent server pushes into request replies; mismatched/missing acknowledgements can leave the client's loading touch blocker active.
- Recorded replies can cross a later client request (`2000` seq 91 / `201` seq 92); match replies across the capture by sequence + opcode, not adjacency. Only nonempty **205/1024/1027** state pushes are currently restored, in recorded order with **seq 0**, and only for operations with a matching reply.
- Python hand-encodes Protobuf. Use `scripts_clean/*_pb.lua` descriptors as field-number references, especially `guidequery_pb.lua`; client guide behavior is in `guideControl.lua` and `UIGuide.lua`.
- Saves use `guide.sections["<section>"] = {status, step, steps}`; keep `migrate_guide()` compatibility. **1 = in progress, 2 = complete; 0 does not mean in progress.** Resume starts from the reported step + 1; an empty sections response means a fresh account.
- Recorded packets must go through `zyj_server.player.prepare_recorded_responses()` / `prepare_recorded_response()`: they apply role/protagonist state and save atomically before returning frames for sending. `role_state` is authoritative; zero balances are valid and spending must not use historical maxima. Initial Comb **1001** is rewritten in place, not sent stale and corrected by a later push. `999898` is compatibility-only; no client patch is needed for progression.
- `selected_general_id` is the **202 request option ID**, not the returned `Protagonist.iid`. `General_Property.level2` is **not** `Protagonist.level2`; only explicit protagonist responses set the latter. Role costs/experience use `role_exp`, `copy`, and `protagonist_grow` from `configs_sec5.zip`. Full roster/inventory restoration, arbitrary battles and timed stamina recovery remain unimplemented.
- Completion counts come from **`5/guide_step.json` inside `configs_sec5.zip`**, not a hard-coded tutorial threshold. `redo == 0` steps send opcode 201 **inside a Comb request** (`UIRequest.lua`), not standalone; gaps in standalone reports are normal. `record_guide_progress()` is shared by standalone reports and successfully acknowledged Comb reports. Do not fix missing progress by skipping/completing the tutorial.
