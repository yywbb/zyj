"use strict";

const $ = (id) => document.getElementById(id);
const state = { token: "", accounts: [], account: 1, page: "accounts", offset: 0 };
let accountRequest = 0;
let configRequest = 0;
let editing = null;
let accountSimpleBar = null;

function ensureAccountSimpleBar() {
  if (!accountSimpleBar && typeof SimpleBar !== "undefined" && $("account-list-container")) {
    accountSimpleBar = new SimpleBar($("account-list-container"), { autoHide: true });
  }
  return accountSimpleBar;
}

function node(tag, content, className) {
  const element = document.createElement(tag);
  if (content !== undefined && content !== null) {
    if (typeof content === "object" && content.nodeType) {
      element.append(content);
    } else {
      element.textContent = content;
    }
  }
  if (className) element.className = className;
  return element;
}

function message(text, error = false) {
  const notice = $("notice");
  notice.textContent = text;
  notice.className = error ? "notice error" : "notice";
  notice.hidden = !text;
}

async function api(path, data) {
  const response = await fetch(path, {
    method: data === undefined ? "GET" : "POST",
    headers: data === undefined ? {} : { "Content-Type": "application/json", "X-Admin-Token": state.token },
    body: data === undefined ? undefined : JSON.stringify(data),
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || `请求失败 (${response.status})`);
  return result;
}

async function run(action) {
  try {
    await action();
  } catch (error) {
    message(error.message || "连接失败，请确认服务端仍在运行后刷新。", true);
  }
}

function button(text, action, className) {
  const element = node("button", text, className);
  element.type = "button";
  element.addEventListener("click", () => run(action));
  return element;
}

function date(value) {
  return value ? new Date(value * 1000).toLocaleString("zh-CN", { hour12: false }) : "尚未落盘";
}

function number(value) {
  return value == null ? "—" : Number(value).toLocaleString("zh-CN");
}

async function status() {
  const result = await api("/api/status");
  state.token = result.token;
  $("pending").hidden = !result.config.restart_required;
  $("connection").textContent = `本机服务在线　${new Date().toLocaleTimeString("zh-CN", { hour12: false })}`;
  $("config-names").replaceChildren(...result.config.tables.map((name) => node("option", name)));
  $("config-shortcuts").replaceChildren(...Object.entries(result.config.editable).map(([name, spec]) =>
    button(`⚡ ${spec.label}`, () => {
      $("config-name").value = name;
      $("config-query").value = spec.ids[0];
      return loadConfigs(0);
    }, "shortcut-pill")));
}

function renderAccounts() {
  const query = $("account-search").value.trim().toLowerCase();
  const rows = state.accounts.filter((row) => `${row.id} ${row.name}`.toLowerCase().includes(query));
  $("account-count").textContent = `${state.accounts.length} 个账号 / ${state.accounts.filter((row) => row.online).length} 在线`;
  $("account-list").replaceChildren(...rows.map((row) => {
    const item = button("", () => loadAccount(row.id), "account-item");
    item.setAttribute("aria-pressed", String(state.account === row.id));

    const top = node("div", undefined, "account-item-top");
    top.append(node("span", `账号 ${row.id}`, "account-id-badge"));
    const statusText = row.online ? "● 在线" : "○ 离线";
    top.append(node("span", statusText, `status-pip${row.online ? " online" : ""}`));

    const name = node("strong", row.name, "account-item-name");

    const meta = node("div", undefined, "account-item-meta");
    let stateLabel = "尚未建号";
    let stateClass = "muted-text";
    if (row.error) {
      stateLabel = "存档异常";
      stateClass = "error-text";
    } else if (row.has_role) {
      stateLabel = `等级 ${number(row.level)}`;
      stateClass = "level-text";
    }
    meta.append(node("span", stateLabel, stateClass));

    item.append(top, name, meta);
    return item;
  }));
  if (!rows.length) {
    $("account-list").append(node("p", "没有匹配的账号，可在下方输入编号直达。", "empty"));
  }

  const sb = ensureAccountSimpleBar();
  if (sb) {
    setTimeout(() => sb.recalculate(), 0);
  }
}

async function loadAccounts() {
  state.accounts = (await api("/api/accounts")).accounts;
  renderAccounts();
}

function tableSection(title, rows, columns, defaultOpen = false) {
  const section = node("details", undefined, "detail-section");
  if (defaultOpen) section.open = true;
  const summary = node("summary");
  summary.append(node("span", title, "section-title"), node("span", `${rows.length} 条记录`, "section-badge"));
  section.append(summary);

  if (!rows.length) {
    section.append(node("p", "存档中暂无数据记录。", "empty"));
    return section;
  }

  const wrapper = node("div", undefined, "table-wrap");
  const table = node("table");
  const header = node("tr");
  columns.forEach(([label]) => {
    const cell = node("th", label);
    cell.scope = "col";
    header.append(cell);
  });
  const head = node("thead");
  head.append(header);
  table.append(head);

  const body = node("tbody");
  rows.forEach((row) => {
    const tr = node("tr");
    columns.forEach(([, value]) => {
      const res = value(row);
      const cell = node("td");
      if (res != null && typeof res === "object" && res.nodeType) {
        cell.append(res);
      } else {
        cell.textContent = res ?? "—";
      }
      tr.append(cell);
    });
    body.append(tr);
  });
  table.append(body);
  wrapper.append(table);
  section.append(wrapper);

  if (typeof SimpleBar !== "undefined") {
    let sb = null;
    const initSb = () => {
      if (!sb) sb = new SimpleBar(wrapper, { autoHide: true });
      else sb.recalculate();
    };
    section.addEventListener("toggle", () => {
      if (section.open) setTimeout(initSb, 0);
    });
    if (defaultOpen) {
      setTimeout(initSb, 0);
    }
  }

  return section;
}

async function loadAccount(id) {
  state.account = id;
  const request = ++accountRequest;
  renderAccounts();
  $("account-detail").replaceChildren(node("p", `正在读取账号 ${id} 数据…`, "empty"));

  const row = await api(`/api/accounts/${id}`);
  if (request !== accountRequest) return;

  const detail = $("account-detail");
  detail.replaceChildren();

  // 1. Heading
  const heading = node("div", undefined, "detail-heading");
  const identity = node("div", undefined, "identity-block");
  const tagRow = node("div", undefined, "identity-tags");
  tagRow.append(node("span", `账号 ${row.id}`, "account-pill"));
  if (row.has_role) tagRow.append(node("span", "已就绪", "role-pill"));
  tagRow.append(node("span", `最近落盘：${date(row.saved_at)}`, "saved-time"));
  identity.append(tagRow, node("h2", row.name, "role-title"));
  heading.append(identity, node("span", row.online ? "● 在线" : "○ 离线", `badge${row.online ? " online" : ""}`));
  detail.append(heading);

  if (row.error) detail.append(node("p", row.error, "error"));
  if (!row.has_save) {
    detail.append(node("p", "该账号尚无存档。可在手机或模拟器登录页面选择此账号开始游戏，或从历史备份中恢复。", "empty notice-empty"));
  }

  // 2. Vital Telemetry HUD (6 Cards)
  const resources = node("dl", undefined, "resources");
  const metrics = [
    ["等级", number(row.level), "🎖️", null],
    ["银币", number(row.coin), "🪙", "coin"],
    ["元宝", number(row.gold), "💎", "gold"],
    ["体力", `${number(row.stamina)} / ${number(row.maxstamina)}`, "⚡", "stamina", row.stamina, row.maxstamina],
    ["精力", `${number(row.energy)} / ${number(row.maxenergy)}`, "🔮", "energy", row.energy, row.maxenergy],
    ["武将", number(row.generals.length), "⚔️", "generals"],
  ];
  for (const [label, value, icon, kind, cur, max] of metrics) {
    const entry = node("div", undefined, `resource-card ${kind || ""}`);
    const dt = node("dt");
    dt.append(node("span", icon, "card-icon"), node("span", label, "card-label"));
    entry.append(dt, node("dd", value));
    if (max != null && max > 0) {
      const prog = document.createElement("progress");
      prog.className = `gauge-bar ${kind}`;
      prog.value = Math.min(cur || 0, max);
      prog.max = max;
      entry.append(prog);
    }
    resources.append(entry);
  }
  detail.append(resources);

  // 3. Guide Progression Note
  const guideNote = node("div", undefined, "guide-note");
  guideNote.append(node("span", "🧭", "guide-icon"), node("strong", "引导进度："), node("span", row.guide));
  detail.append(guideNote);

  // 4. Maintenance Deck (placed above data tables for fast GM access)
  const maintenance = node("section", undefined, "maintenance");
  const mHead = node("div", undefined, "maintenance-header");
  mHead.append(
    node("h3", "🛠️ 离线维护与存档管理"),
    node("p", row.online ? `⚠️ 客户端正在连接中 (${row.connection.address})。为避免数据冲突，维护操作已锁定，请退出游戏客户端后刷新重试。` : "进行重置或恢复操作前会自动备份当前存档。重置新手引导将保留所有武将、装备、背包和充值记录。")
  );
  maintenance.append(mHead);

  const actions = node("div", undefined, "actions");
  for (const [text, action, css] of [["📥 创建备份", "backup", ""], ["🔄 重置引导", "reset-guide", "warning-btn"], ["⚠️ 重置账号", "reset", "danger"]]) {
    const control = button(text, () => maintain(row, action), css);
    control.disabled = row.online || !row.has_save;
    actions.append(control);
  }
  if (row.has_save) {
    const download = node("a", "⬇ 下载存档 (JSON)", "button download-btn");
    download.href = `/api/accounts/${row.id}/download`;
    download.download = `account-${row.id}.json`;
    actions.append(download);
  }
  maintenance.append(actions);

  const restore = node("div", undefined, "restore");
  const label = node("label", "从历史备份快照恢复");
  label.htmlFor = "backup-id";
  const select = node("select");
  select.id = "backup-id";
  row.backups.forEach((backup) => {
    const opt = node("option", `${date(backup.created_at)} · 快照 ${backup.id.slice(0, 8)}`);
    opt.value = backup.id;
    select.append(opt);
  });
  if (!row.backups.length) select.append(node("option", "暂无历史备份记录"));
  select.disabled = row.online || !row.backups.length;
  const restoreBtn = button("执行恢复", () => maintain(row, "restore", select.value), "restore-btn");
  restoreBtn.disabled = select.disabled;
  const inline = node("div", undefined, "inline");
  inline.append(select, restoreBtn);
  restore.append(label, inline);
  maintenance.append(restore);
  detail.append(maintenance);

  // 5. Data Tables
  // 武将与阵容 (defaultOpen = true)
  detail.append(tableSection("⚔️ 武将与阵容", row.generals, [
    ["武将名称", (r) => r.name],
    ["等级", (r) => node("span", `Lv.${r.level}`, "level-pill")],
    ["战斗阵位", (r) => {
      if (r.position) {
        return node("span", r.position === 1 ? "阵位 1 · 队长" : `阵位 ${r.position}`, "slot-pill active");
      }
      return node("span", "候补未上阵", "slot-pill bench");
    }],
    ["实例 ID (IID)", (r) => node("code", String(r.iid), "id-chip")]
  ], true));

  // 装备
  detail.append(tableSection("🛡️ 装备库", row.equipment, [
    ["装备名称", (r) => r.name],
    ["强化等级", (r) => node("span", `Lv.${r.level}`, "level-pill")],
    ["配置 CID", (r) => node("code", String(r.cid), "id-chip")],
    ["实例 ID (IID)", (r) => node("code", String(r.iid), "id-chip")]
  ]));

  // 背包
  detail.append(tableSection("🎒 背包物资", row.inventory, [
    ["物品名称", (r) => r.name],
    ["物资分类", (r) => node("span", r.kind, `kind-pill ${r.kind === "武将碎片" ? "shard" : "item"}`)],
    ["持有数量", (r) => node("span", number(r.count), "count-val")],
    ["配置 CID", (r) => node("code", String(r.cid), "id-chip")]
  ]));

  // 副本章节
  detail.append(tableSection("🗺️ 副本章节进度", row.copies, [
    ["地图章节", (r) => r.name],
    ["通关据点", (r) => `${r.cleared} 关破捷`],
    ["总星数", (r) => node("span", `⭐ ${r.stars}`, "star-val")],
    ["星级宝箱领取", (r) => {
      const wrap = node("div", undefined, "chest-group");
      r.boxes.forEach((b, idx) => {
        wrap.append(node("span", `宝箱${idx + 1}: ${b ? "已领" : "未领"}`, `chest-pill ${b ? "claimed" : "unclaimed"}`));
      });
      return wrap;
    }]
  ]));

  // 底层状态 (JSON Inspector)
  const states = node("details", undefined, "detail-section");
  const sSummary = node("summary");
  sSummary.append(node("span", "📜 引导、活动、招募与充值底层状态", "section-title"), node("span", "JSON 数据", "section-badge"));
  states.append(sSummary);
  const sWrap = node("div", undefined, "states-wrap");
  const copyBtn = button("📋 复制全部状态 JSON", async () => {
    try {
      await navigator.clipboard.writeText(JSON.stringify(row.states, null, 2));
      message("已成功复制底层状态 JSON 到剪贴板！");
    } catch {
      message("复制失败，请在下方文本框中手动选取复制。", true);
    }
  }, "copy-json-btn");

  const preWrap = node("div", undefined, "code-scroll-box");
  const pre = node("pre", JSON.stringify(row.states, null, 2));
  preWrap.append(pre);
  sWrap.append(copyBtn, preWrap);
  states.append(sWrap);
  detail.append(states);

  if (typeof SimpleBar !== "undefined") {
    let sb = null;
    states.addEventListener("toggle", () => {
      if (states.open) {
        setTimeout(() => {
          if (!sb) sb = new SimpleBar(preWrap, { autoHide: true });
          else sb.recalculate();
        }, 0);
      }
    });
  }
}

async function maintain(row, action, backupId) {
  const labels = { backup: "创建备份", reset: "重置账号", "reset-guide": "重置引导", restore: "恢复备份" };
  if (action !== "backup" && !confirm(`确定对账号 ${row.id}「${row.name}」执行${labels[action]}？\n当前存档会先备份。${action === "reset" ? "该账号全部进度将被清空。" : ""}`)) {
    return;
  }
  const controls = [...$("account-detail").querySelectorAll("button")];
  controls.forEach((b) => { b.disabled = true; });
  try {
    await api(`/api/accounts/${row.id}`, { action, revision: row.revision, backup_id: backupId });
    message(`账号 ${row.id}：${labels[action]}已成功完成。`);
  } finally {
    await loadAccounts();
    await loadAccount(state.account);
  }
}

async function loadConfigs(offset = 0) {
  const request = ++configRequest;
  const name = $("config-name").value.trim();
  const query = $("config-query").value.trim();
  $("config-rows").replaceChildren(node("p", "正在读取配置…", "empty"));
  $("previous").disabled = $("next").disabled = true;

  const result = await api(`/api/configs/${encodeURIComponent(name)}?q=${encodeURIComponent(query)}&offset=${offset}`);
  if (request !== configRequest) return;

  state.offset = offset;
  $("config-rows").replaceChildren(...result.rows.map((row) => {
    const section = node("article", undefined, "config-row");
    const header = node("div", undefined, "inline config-row-header");
    const titleWrap = node("div", undefined, "config-row-title");
    titleWrap.append(node("code", String(row.id), "config-id-badge"), node("strong", row.value.name || row.value.desc || ""));
    header.append(titleWrap);

    const actionsWrap = node("div", undefined, "config-row-actions");
    if (row.changed) actionsWrap.append(node("span", "⚡ 已覆盖", "badge override"));
    if (result.editor?.ids.includes(row.id)) {
      actionsWrap.append(button(row.changed ? "修改覆盖" : "编辑覆盖", () => openEditor(result, row), "edit-btn primary"));
    } else {
      actionsWrap.append(node("span", "只读", "badge"));
    }
    header.append(actionsWrap);

    const fields = node("details", undefined, "config-row-details");
    fields.append(node("summary", row.changed ? "查看配置字段（已含本地覆盖）" : "查看配置字段"));
    const preWrap = node("div", undefined, "code-scroll-box");
    const pre = node("pre", JSON.stringify(row.value, null, 2));
    preWrap.append(pre);
    fields.append(preWrap);
    section.append(header, fields);

    if (typeof SimpleBar !== "undefined") {
      let sb = null;
      fields.addEventListener("toggle", () => {
        if (fields.open) {
          setTimeout(() => {
            if (!sb) sb = new SimpleBar(preWrap, { autoHide: true });
            else sb.recalculate();
          }, 0);
        }
      });
    }

    return section;
  }));

  if (!result.rows.length) {
    $("config-rows").append(node("p", "未找到匹配条目。请尝试其他 ID 或清空搜索条件重试。", "empty"));
  }
  $("config-count").textContent = `${result.total} 条匹配${result.total ? ` / 当前显示 ${offset + 1}–${offset + result.rows.length}` : ""}`;
  $("previous").disabled = offset === 0;
  $("next").disabled = offset + 50 >= result.total;
}

function openEditor(result, row) {
  editing = { result, row };
  $("editor-title").textContent = `编辑配置 · ${result.editor.label} [${row.id}]`;
  $("edit-error").hidden = true;
  $("edit-fields").replaceChildren(...Object.entries(result.editor.fields).map(([field, rule]) => {
    const wrapper = node("div", undefined, "form-field");
    const label = node("label", rule.label);
    label.htmlFor = `field-${field}`;
    const input = node(["text", "reward"].includes(rule.type) ? "textarea" : "input");
    input.id = `field-${field}`;
    input.name = field;
    input.value = row.value[field] ?? "";
    input.required = true;
    if (input.tagName === "INPUT") {
      input.type = "number";
      input.min = "1";
      input.max = rule.max;
      input.step = "1";
    } else {
      input.maxLength = rule.type === "reward" ? 2048 : 500;
      if (rule.type === "reward") {
        wrapper.append(label, input, node("small", "奖励格式：物品ID,数量; 例如 1000,500;20014,5; (物品ID不可重复，单项上限1000000)", "field-hint"));
        return wrapper;
      }
    }
    wrapper.append(label, input);
    return wrapper;
  }));
  $("revert-config").disabled = !row.changed;
  $("editor").showModal();
}

async function saveConfig(revert = false) {
  const { result, row } = editing;
  if (revert && !confirm(`确定恢复 ${result.name}/${row.id} 的原始打包配置？`)) return;

  const changes = {};
  for (const [field, rule] of Object.entries(result.editor.fields)) {
    const value = $(`field-${field}`).value;
    if (value !== String(row.value[field] ?? "")) {
      changes[field] = rule.type === "int" ? Number(value) : value;
    }
  }

  if (!revert && !Object.keys(changes).length) {
    $("editor").close();
    return;
  }

  $("save-config").disabled = $("revert-config").disabled = true;
  try {
    await api(`/api/configs/${result.name}`, { row_id: row.id, changes: revert ? null : changes, revision: result.revision });
    $("editor").close();
    message(revert ? "已恢复原始配置。" : "配置本地覆盖已保存。");
    await status();
    await loadConfigs(state.offset);
  } catch (error) {
    $("edit-error").textContent = `${error.message} 如配置表已被外部修改，请关闭后重新查询。`;
    $("edit-error").hidden = false;
  } finally {
    $("save-config").disabled = false;
    $("revert-config").disabled = !row.changed;
  }
}

function navigate(page) {
  state.page = page;
  for (const name of ["accounts", "configs"]) {
    $(`${name}-page`).hidden = name !== page;
    if (name === page) $(`nav-${name}`).setAttribute("aria-current", "page");
    else $(`nav-${name}`).removeAttribute("aria-current");
  }
  message("");
  return page === "accounts" ? loadAccounts().then(() => loadAccount(state.account)) : loadConfigs(0);
}

$("nav-accounts").onclick = () => run(() => navigate("accounts"));
$("nav-configs").onclick = () => run(() => navigate("configs"));
$("account-search").oninput = renderAccounts;
$("account-jump").onsubmit = (event) => {
  event.preventDefault();
  run(() => loadAccount(Number($("account-id").value)));
};
$("config-search").onsubmit = (event) => {
  event.preventDefault();
  run(() => loadConfigs(0));
};
$("previous").onclick = () => run(() => loadConfigs(Math.max(0, state.offset - 50)));
$("next").onclick = () => run(() => loadConfigs(state.offset + 50));
$("close-editor").onclick = () => $("editor").close();
$("edit-form").onsubmit = (event) => {
  event.preventDefault();
  run(() => saveConfig());
};
$("revert-config").onclick = () => run(() => saveConfig(true));
$("refresh").onclick = () => run(async () => {
  await status();
  await navigate(state.page);
});

run(async () => {
  await status();
  await loadAccounts();
  await loadAccount(1);
});
