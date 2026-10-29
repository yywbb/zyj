"use strict";

const $ = (id) => document.getElementById(id);
const state = { token: "", accounts: [], account: 1, page: "accounts", offset: 0 };
let accountRequest = 0;
let configRequest = 0;
let editing = null;

function node(tag, text, className) {
  const element = document.createElement(tag);
  if (text !== undefined) element.textContent = text;
  if (className) element.className = className;
  return element;
}

function message(text, error = false) {
  $("notice").textContent = text;
  $("notice").className = error ? "notice error" : "notice";
  $("notice").hidden = !text;
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
  try { await action(); } catch (error) { message(error.message || "连接失败，请确认服务端仍在运行后刷新。", true); }
}

function button(text, action, className) {
  const element = node("button", text, className);
  element.type = "button";
  element.addEventListener("click", () => run(action));
  return element;
}

function date(value) { return value ? new Date(value * 1000).toLocaleString("zh-CN", { hour12: false }) : "尚未保存"; }
function number(value) { return value == null ? "—" : Number(value).toLocaleString("zh-CN"); }

async function status() {
  const result = await api("/api/status");
  state.token = result.token;
  $("pending").hidden = !result.config.restart_required;
  $("connection").textContent = `本机服务已连接　${new Date().toLocaleTimeString("zh-CN", { hour12: false })}`;
  $("config-names").replaceChildren(...result.config.tables.map((name) => node("option", name)));
  $("config-shortcuts").replaceChildren(...Object.entries(result.config.editable).map(([name, spec]) =>
    button(spec.label, () => { $("config-name").value = name; $("config-query").value = spec.ids[0]; return loadConfigs(0); })));
}

function renderAccounts() {
  const query = $("account-search").value.trim().toLowerCase();
  const rows = state.accounts.filter((row) => `${row.id} ${row.name}`.toLowerCase().includes(query));
  $("account-count").textContent = `${state.accounts.length} 个账号 / ${state.accounts.filter((row) => row.online).length} 个在线`;
  $("account-list").replaceChildren(...rows.map((row) => {
    const item = button("", () => loadAccount(row.id), "account-item");
    item.setAttribute("aria-pressed", String(state.account === row.id));
    item.append(node("strong", `账号 ${row.id} · ${row.name}`), node("span", row.error ? "存档异常" : `${row.online ? "在线" : "离线"}　${row.has_role ? `等级 ${number(row.level)}` : "尚未建号"}`));
    return item;
  }));
  if (!rows.length) $("account-list").append(node("p", "没有匹配账号，可在下方输入编号打开。", "empty"));
}

async function loadAccounts() {
  state.accounts = (await api("/api/accounts")).accounts;
  renderAccounts();
}

function tableSection(title, rows, columns) {
  const section = node("details");
  section.append(node("summary", `${title} (${rows.length})`));
  if (!rows.length) { section.append(node("p", "存档中暂无记录。", "empty")); return section; }
  const table = node("table");
  const header = node("tr");
  columns.forEach(([label]) => { const cell = node("th", label); cell.scope = "col"; header.append(cell); });
  const head = node("thead"); head.append(header); table.append(head);
  const body = node("tbody");
  rows.forEach((row) => {
    const tr = node("tr");
    columns.forEach(([, value]) => tr.append(node("td", value(row))));
    body.append(tr);
  });
  table.append(body);
  const wrapper = node("div", undefined, "table-wrap"); wrapper.append(table); section.append(wrapper);
  return section;
}

async function loadAccount(id) {
  state.account = id;
  const request = ++accountRequest;
  renderAccounts();
  $("account-detail").replaceChildren(node("p", `正在读取账号 ${id}…`, "empty"));
  const row = await api(`/api/accounts/${id}`);
  if (request !== accountRequest) return;
  const detail = $("account-detail"); detail.replaceChildren();
  const heading = node("div", undefined, "detail-heading");
  const identity = node("div");
  identity.append(node("small", `账号 ${row.id}`), node("h2", row.name), node("small", `最近保存：${date(row.saved_at)}`));
  heading.append(identity, node("span", row.online ? "在线" : "离线", `badge${row.online ? " online" : ""}`));
  detail.append(heading);
  if (row.error) detail.append(node("p", row.error, "error"));
  if (!row.has_save) detail.append(node("p", "尚无存档。可在游戏登录页选择此账号开始，也可从备份恢复。", "empty"));
  const resources = node("dl", undefined, "resources");
  for (const [label, value] of [["等级", number(row.level)], ["银币", number(row.coin)], ["元宝", number(row.gold)],
    ["体力", `${number(row.stamina)} / ${number(row.maxstamina)}`], ["精力", `${number(row.energy)} / ${number(row.maxenergy)}`], ["武将", number(row.generals.length)]]) {
    const entry = node("div"); entry.append(node("dt", label), node("dd", value)); resources.append(entry);
  }
  detail.append(resources, node("p", `引导进度：${row.guide}`, "guide-note"));
  detail.append(tableSection("武将与阵容", row.generals, [["武将", (r) => r.name], ["等级", (r) => r.level], ["阵位", (r) => r.position || "未上阵"], ["实例 ID", (r) => r.iid]]));
  detail.append(tableSection("装备", row.equipment, [["装备", (r) => r.name], ["等级", (r) => r.level], ["实例 ID", (r) => r.iid]]));
  detail.append(tableSection("背包", row.inventory, [["物品", (r) => r.name], ["类型", (r) => r.kind], ["数量", (r) => number(r.count)], ["配置 ID", (r) => r.cid]]));
  detail.append(tableSection("副本进度", row.copies, [["地图", (r) => r.name], ["通关", (r) => r.cleared], ["星数", (r) => r.stars], ["星级宝箱", (r) => r.boxes.map((v) => v ? "已领" : "未领").join(" / ")]]));
  const states = node("details"); states.append(node("summary", "引导、活动、招募与充值状态"), node("pre", JSON.stringify(row.states, null, 2))); detail.append(states);
  const maintenance = node("section", undefined, "maintenance");
  maintenance.append(node("h3", "离线维护"), node("p", row.online ? `当前连接：${row.connection.address}。请先退出游戏，再刷新本页进行维护。` : "重置或恢复前自动备份当前存档。重置引导保留角色、背包和奖励领取记录。"));
  const actions = node("div", undefined, "actions");
  for (const [text, action, css] of [["创建备份", "backup", ""], ["重置引导", "reset-guide", ""], ["重置账号", "reset", "danger"]]) {
    const control = button(text, () => maintain(row, action), css);
    control.disabled = row.online || !row.has_save;
    actions.append(control);
  }
  if (row.has_save) {
    const download = node("a", "下载存档", "button"); download.href = `/api/accounts/${row.id}/download`; download.download = `account-${row.id}.json`; actions.append(download);
  }
  maintenance.append(actions);
  const restore = node("div", undefined, "restore");
  const label = node("label", "恢复已有备份"); label.htmlFor = "backup-id";
  const select = node("select"); select.id = "backup-id";
  row.backups.forEach((backup) => { const option = node("option", `${date(backup.created_at)} · ${backup.id.slice(0, 8)}`); option.value = backup.id; select.append(option); });
  if (!row.backups.length) select.append(node("option", "暂无备份"));
  select.disabled = row.online || !row.backups.length;
  const control = button("恢复备份", () => maintain(row, "restore", select.value)); control.disabled = select.disabled;
  const inline = node("div", undefined, "inline"); inline.append(select, control); restore.append(label, inline); maintenance.append(restore); detail.append(maintenance);
}

async function maintain(row, action, backupId) {
  const labels = { backup: "创建备份", reset: "重置账号", "reset-guide": "重置引导", restore: "恢复备份" };
  if (action !== "backup" && !confirm(`确定对账号 ${row.id}「${row.name}」执行${labels[action]}？\n当前存档会先备份。${action === "reset" ? "该账号全部进度将被清空。" : ""}`)) return;
  const controls = [...$("account-detail").querySelectorAll("button")]; controls.forEach((b) => { b.disabled = true; });
  try {
    await api(`/api/accounts/${row.id}`, { action, revision: row.revision, backup_id: backupId });
    message(`账号 ${row.id}：${labels[action]}完成。`);
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
    const header = node("div", undefined, "inline");
    header.append(node("strong", `${row.id}　${row.value.name || row.value.desc || ""}`));
    if (result.editor?.ids.includes(row.id)) header.append(button(row.changed ? "编辑覆盖" : "编辑", () => openEditor(result, row)));
    else header.append(node("span", "只读", "badge"));
    const fields = node("details"); fields.append(node("summary", row.changed ? "查看字段（含本地覆盖）" : "查看字段"), node("pre", JSON.stringify(row.value, null, 2)));
    section.append(header, fields); return section;
  }));
  if (!result.rows.length) $("config-rows").append(node("p", "未找到匹配条目。尝试其他 ID 或清空搜索条件。", "empty"));
  $("config-count").textContent = `${result.total} 条匹配${result.total ? ` / 显示 ${offset + 1}–${offset + result.rows.length}` : ""}`;
  $("previous").disabled = offset === 0;
  $("next").disabled = offset + 50 >= result.total;
}

function openEditor(result, row) {
  editing = { result, row };
  $("editor-title").textContent = `${result.editor.label} / ${row.id}`;
  $("edit-error").hidden = true;
  $("edit-fields").replaceChildren(...Object.entries(result.editor.fields).map(([field, rule]) => {
    const wrapper = node("div");
    const label = node("label", rule.label); label.htmlFor = `field-${field}`;
    const input = node(["text", "reward"].includes(rule.type) ? "textarea" : "input");
    input.id = `field-${field}`; input.name = field; input.value = row.value[field] ?? ""; input.required = true;
    if (input.tagName === "INPUT") { input.type = "number"; input.min = "1"; input.max = rule.max; input.step = "1"; }
    else input.maxLength = rule.type === "reward" ? 2048 : 500;
    wrapper.append(label, input); return wrapper;
  }));
  $("revert-config").disabled = !row.changed;
  $("editor").showModal();
}

async function saveConfig(revert = false) {
  const { result, row } = editing;
  if (revert && !confirm(`恢复 ${result.name}/${row.id} 的原始配置？`)) return;
  const changes = {};
  for (const [field, rule] of Object.entries(result.editor.fields)) {
    const value = $(`field-${field}`).value;
    if (value !== String(row.value[field] ?? "")) changes[field] = rule.type === "int" ? Number(value) : value;
  }
  if (!revert && !Object.keys(changes).length) { $("editor").close(); return; }
  $("save-config").disabled = $("revert-config").disabled = true;
  try {
    await api(`/api/configs/${result.name}`, { row_id: row.id, changes: revert ? null : changes, revision: result.revision });
    $("editor").close();
    message(revert ? "已恢复原配置。" : "配置已保存。");
    await status(); await loadConfigs(state.offset);
  } catch (error) {
    $("edit-error").textContent = `${error.message} 如配置已变化，请关闭编辑框后重新查询。`;
    $("edit-error").hidden = false;
  } finally {
    $("save-config").disabled = false; $("revert-config").disabled = !row.changed;
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
$("account-jump").onsubmit = (event) => { event.preventDefault(); run(() => loadAccount(Number($("account-id").value))); };
$("config-search").onsubmit = (event) => { event.preventDefault(); run(() => loadConfigs(0)); };
$("previous").onclick = () => run(() => loadConfigs(Math.max(0, state.offset - 50)));
$("next").onclick = () => run(() => loadConfigs(state.offset + 50));
$("close-editor").onclick = () => $("editor").close();
$("edit-form").onsubmit = (event) => { event.preventDefault(); run(() => saveConfig()); };
$("revert-config").onclick = () => run(() => saveConfig(true));
$("refresh").onclick = () => run(async () => { await status(); await navigate(state.page); });
run(async () => { await status(); await loadAccounts(); await loadAccount(1); });
