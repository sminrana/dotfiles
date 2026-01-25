-- Minimal task system for Neovim with impact/reward focus
-- Stores data in stdpath('data') so it persists across sessions

local M = {}

local function json_encode(tbl)
  if vim.json and vim.json.encode then
    return vim.json.encode(tbl)
  end
  return vim.fn.json_encode(tbl)
end

local function json_decode(str)
  if vim.json and vim.json.decode then
    return vim.json.decode(str)
  end
  return vim.fn.json_decode(str)
end

-- Use a single SQLite DB on Desktop; no JSON persistence
local function get_data_path()
  return vim.fn.expand("~/Desktop/taskflow.db")
end

local function get_sqlite_bin()
  local candidates = {
    "sqlite3",
    "/opt/homebrew/bin/sqlite3",
    "/usr/local/bin/sqlite3",
    "/usr/bin/sqlite3",
  }
  for _, p in ipairs(candidates) do
    if (p:find("/") and vim.fn.executable(p) == 1) or (vim.fn.executable(p) == 1) then
      return p
    end
  end
  return nil
end

local function db_exec(sql)
  local bin = get_sqlite_bin()
  if not bin then
    vim.notify("TaskFlow: sqlite3 not found in PATH. Please install sqlite3 or add it to PATH.", vim.log.levels.ERROR)
    return "", 127
  end
  local out = vim.fn.system({ bin, get_data_path(), sql })
  local code = vim.v.shell_error or 0
  return out, code
end

local function db_select(sql)
  local bin = get_sqlite_bin()
  if not bin then
    vim.notify("TaskFlow: sqlite3 not found in PATH. Please install sqlite3 or add it to PATH.", vim.log.levels.ERROR)
    return {}
  end
  local out = vim.fn.systemlist({ bin, "-header", "-tabs", get_data_path(), sql })
  if not out or #out == 0 then
    return {}
  end
  local header = vim.split(out[1], "\t")
  local rows = {}
  for i = 2, #out do
    local cols = vim.split(out[i], "\t")
    local row = {}
    for j = 1, #header do
      row[header[j]] = cols[j]
    end
    table.insert(rows, row)
  end
  return rows
end

-- SQL escape helper (placed before meta helpers to avoid forward-ref errors)
local function sql_escape(s)
  if s == nil then
    return ""
  end
  return tostring(s):gsub("'", "''")
end

-- Simple key/value storage in the meta table
local function meta_get(k)
  local rows = db_select(string.format("SELECT v FROM meta WHERE k='%s'", sql_escape(k)))
  if #rows > 0 and rows[1].v then
    return rows[1].v
  end
  return nil
end

local function meta_set(k, v)
  db_exec(string.format("INSERT INTO meta (k, v) VALUES ('%s','%s') ON CONFLICT(k) DO UPDATE SET v=excluded.v", sql_escape(k), sql_escape(tostring(v or ""))))
end

-- sql_escape defined above

local function ensure_db()
  local create_sql = [[
BEGIN;
CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY,
  uid TEXT,
  title TEXT,
  area TEXT,
  status TEXT,
  priority TEXT,
  points INTEGER,
  reward TEXT,
  impact TEXT,
  why TEXT,
  created_at INTEGER,
  started_at INTEGER,
  completed_at INTEGER,
  due INTEGER,
  backlog INTEGER
);
CREATE TABLE IF NOT EXISTS deleted (
  id INTEGER,
  uid TEXT,
  title TEXT,
  area TEXT,
  status TEXT,
  priority TEXT,
  points INTEGER,
  reward TEXT,
  impact TEXT,
  why TEXT,
  created_at INTEGER,
  started_at INTEGER,
  completed_at INTEGER,
  due INTEGER,
  backlog INTEGER
);
CREATE TABLE IF NOT EXISTS archive (
  id INTEGER,
  uid TEXT,
  title TEXT,
  area TEXT,
  status TEXT,
  priority TEXT,
  points INTEGER,
  reward TEXT,
  impact TEXT,
  why TEXT,
  created_at INTEGER,
  started_at INTEGER,
  completed_at INTEGER,
  due INTEGER,
  backlog INTEGER
);
CREATE TABLE IF NOT EXISTS meta (
  k TEXT PRIMARY KEY,
  v TEXT
);
COMMIT;]]
  db_exec(create_sql)
  -- Ensure missing columns exist on older DBs
  local function column_set(tbl)
    local rows = db_select("PRAGMA table_info(" .. tbl .. ")")
    local set = {}
    for _, r in ipairs(rows) do
      local name = r.name or r.Name or r.NAME
      if name and name ~= "" then
        set[name] = true
      end
    end
    return set
  end
  local function ensure_columns(tbl, defs)
    local have = column_set(tbl)
    for _, d in ipairs(defs) do
      if not have[d[1]] then
        db_exec("ALTER TABLE " .. tbl .. " ADD COLUMN " .. d[1] .. " " .. d[2])
      end
    end
  end
  ensure_columns("tasks", {
    { "id", "INTEGER" },
    { "uid", "TEXT" },
    { "title", "TEXT" },
    { "area", "TEXT" },
    { "status", "TEXT" },
    { "priority", "TEXT" },
    { "points", "INTEGER" },
    { "reward", "TEXT" },
    { "impact", "TEXT" },
    { "why", "TEXT" },
    { "created_at", "INTEGER" },
    { "started_at", "INTEGER" },
    { "completed_at", "INTEGER" },
    { "due", "INTEGER" },
    { "backlog", "INTEGER" },
  })
  ensure_columns("archive", {
    { "id", "INTEGER" },
    { "uid", "TEXT" },
    { "title", "TEXT" },
    { "area", "TEXT" },
    { "status", "TEXT" },
    { "priority", "TEXT" },
    { "points", "INTEGER" },
    { "reward", "TEXT" },
    { "impact", "TEXT" },
    { "why", "TEXT" },
    { "created_at", "INTEGER" },
    { "started_at", "INTEGER" },
    { "completed_at", "INTEGER" },
    { "due", "INTEGER" },
    { "backlog", "INTEGER" },
  })
  ensure_columns("deleted", {
    { "id", "INTEGER" },
    { "uid", "TEXT" },
    { "title", "TEXT" },
    { "area", "TEXT" },
    { "status", "TEXT" },
    { "priority", "TEXT" },
    { "points", "INTEGER" },
    { "reward", "TEXT" },
    { "impact", "TEXT" },
    { "why", "TEXT" },
    { "created_at", "INTEGER" },
    { "started_at", "INTEGER" },
    { "completed_at", "INTEGER" },
    { "due", "INTEGER" },
    { "backlog", "INTEGER" },
  })
end

local state = {
  tasks = {},
  archive = {},
  points = 0,
  last_id = 0,
  rewards_claimed = {},
  last_backup_stamp = nil,
  last_merge_report = nil,
  last_due_email_date = nil,
}

local config = {
  archive_after_days = 14,
  rewards = {
    { threshold = 50, suggestion = "Take a long walk or coffee treat" },
    { threshold = 100, suggestion = "Buy a book or game" },
    { threshold = 200, suggestion = "Plan a day trip" },
    { threshold = 400, suggestion = "Weekend getaway" },
  },
  areas = { "general", "work", "personal" },
}

local function ensure_data_dir()
  local dir = vim.fn.fnamemodify(get_data_path(), ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

local function load_state()
  ensure_data_dir()
  ensure_db()
  local rows = db_select(
    "SELECT id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog FROM tasks"
  )
  local tasks = {}
  local max_id = 0
  local total_pts = 0
  for _, r in ipairs(rows) do
    local t = {
      id = tonumber(r.id),
      uid = r.uid,
      title = r.title,
      area = r.area,
      status = r.status,
      priority = r.priority,
      points = tonumber(r.points),
      reward = r.reward,
      impact = r.impact,
      why = r.why,
      created_at = tonumber(r.created_at),
      started_at = tonumber(r.started_at),
      completed_at = tonumber(r.completed_at),
      due = tonumber(r.due),
      backlog = tonumber(r.backlog) == 1,
    }
    table.insert(tasks, t)
    if t.id and t.id > max_id then
      max_id = t.id
    end
    if t.status == "completed" then
      total_pts = total_pts + (t.points or 0)
    end
  end
  state.tasks = tasks
  state.archive = state.archive or {}
  state.last_id = max_id
  state.points = total_pts
  return state
end

local function save_state()
  -- No JSON persistence; operations write directly to SQLite
  return true
end

local function now()
  return os.time()
end

local function priority_weight(p)
  if p == "high" then
    return 3
  end
  if p == "low" then
    return 1
  end
  return 2
end

local function score_for(task)
  local base = task.points or 0
  return base * priority_weight(task.priority or "medium")
end

local function render(lines, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "taskflow")
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_set_current_buf(buf)
  return buf
end

local function render_float(lines, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "taskflow")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.7)
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "single",
  }
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  return buf, win
end

local function task_by_id(id)
  for i, t in ipairs(state.tasks) do
    if t.id == id then
      return t, i
    end
  end
  return nil, nil
end

local function fmt_task_line(t)
  local due = (t.due and tonumber(t.due)) and os.date("%Y-%m-%d", tonumber(t.due)) or "-"
  local impact = (t.impact and #t.impact > 0) and (" | impact: " .. t.impact) or ""
  local reward = (t.reward and #t.reward > 0) and (" | reward: " .. t.reward) or ""
  local pts = tonumber(t.points) or 0
  local id_str = (t.id and tostring(t.id)) or "?"
  return string.format(
    "[%s] (%s/%s) %s | pts:%d | due:%s%s%s",
    id_str,
    t.area or "general",
    t.priority or "medium",
    t.title or "",
    pts,
    due,
    impact,
    reward
  )
end

-- Enforce a 255-char title; overflow appended to why
local function limit_title_why(title, why)
  title = title or "Untitled"
  why = why or ""
  local max = 255
  if #title > max then
    local t255 = string.sub(title, 1, max)
    local remainder = string.sub(title, max + 1)
    if remainder and #remainder > 0 then
      if why ~= "" then
        why = remainder .. "\n\n" .. why
      else
        why = remainder
      end
    end
    title = t255
  end
  return title, why
end

local function is_overdue(t)
  return t.due and (t.due < now()) and (t.status ~= "completed")
end

local function all_areas()
  local set = {}
  for _, a in ipairs(config.areas or {}) do
    set[a] = true
  end
  for _, t in ipairs(state.tasks or {}) do
    if t.area and #t.area > 0 then
      set[t.area] = true
    end
  end
  local arr = {}
  for a, _ in pairs(set) do
    table.insert(arr, a)
  end
  table.sort(arr)
  return arr
end

function M.add(opts)
  local ok, err = pcall(function()
    load_state()
    opts = opts or {}
    ensure_db()
    -- Title length enforcement
    local limited_title, limited_why = limit_title_why(opts.title, opts.why)
    opts.title = limited_title
    opts.why = limited_why
    -- Compute next id from DB to avoid stale last_id
    local maxrows = db_select("SELECT COALESCE(MAX(id),0) AS m FROM tasks")
    local maxid = 0
    if #maxrows > 0 and maxrows[1].m then
      maxid = tonumber(maxrows[1].m) or 0
    end
    local new_id = maxid + 1
    local uid = tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
    local title = opts.title or "Untitled"
    local why = opts.why or ""
    local impact = opts.impact or ""
    local reward = opts.reward or ""
    local points = tonumber(opts.points) or 0
    local priority = opts.priority or "medium"
    local area = opts.area or "general"
    local status = "pending"
    local backlog = opts.backlog and 1 or 0
    local due = opts.due or (os.time() + 24 * 3600)
    local created_at = now()
    local sql = string.format(
      "INSERT INTO tasks (id, uid, title, area, status, priority, points, reward, impact, why, created_at, due, backlog) VALUES (%d, '%s', '%s', '%s', '%s', '%s', %d, '%s', '%s', '%s', %d, %d, %d)",
      new_id,
      sql_escape(uid),
      sql_escape(title),
      sql_escape(area),
      sql_escape(status),
      sql_escape(priority),
      points,
      sql_escape(reward),
      sql_escape(impact),
      sql_escape(why),
      created_at,
      due,
      backlog
    )
    local out, code = db_exec(sql)
    if code ~= 0 then
      vim.notify("TaskFlow: sqlite error (" .. tostring(code) .. ") on INSERT: " .. tostring(out), vim.log.levels.ERROR)
      error("sqlite error " .. tostring(code))
    end
    local rows = db_select(string.format("SELECT COUNT(*) AS c FROM tasks WHERE id=%d", new_id))
    if #rows == 0 or tonumber(rows[1].c or 0) == 0 then
      vim.notify("TaskFlow: insert failed. Check sqlite3 path and DB permissions. SQL: " .. sql, vim.log.levels.ERROR)
      error("insert failed")
    end
    load_state()
    local task = task_by_id(new_id)
    if not task then
      error("insert verify missing task")
    end
    return task
  end)
  if not ok then
    return false, err
  end
  return err
end

function M.start(id)
  ensure_db()
  local ts = now()
  -- Starting a task should make it active (remove from backlog)
  db_exec(
    string.format("UPDATE tasks SET status='in_progress', started_at=%d, backlog=0 WHERE id=%d", ts, tonumber(id))
  )
  return true
end

function M.complete(id)
  ensure_db()
  local ts = now()
  db_exec(string.format("UPDATE tasks SET status='completed', completed_at=%d WHERE id=%d", ts, tonumber(id)))
  return true
end

function M.stop(id)
  ensure_db()
  db_exec(string.format("UPDATE tasks SET status='pending', started_at=NULL WHERE id=%d", tonumber(id)))
  return true
end

function M.set_backlog(id, mode)
  ensure_db()
  local current = db_select(string.format("SELECT backlog FROM tasks WHERE id=%d", tonumber(id)))
  if #current == 0 then
    return false, "Task not found"
  end
  local cur = tonumber(current[1].backlog) or 0
  local val
  if mode == "toggle" then
    val = (cur == 1) and 0 or 1
  else
    val = (mode == "on") and 1 or 0
  end
  db_exec(string.format("UPDATE tasks SET backlog=%d WHERE id=%d", val, tonumber(id)))
  return true
end

function M.delete(id)
  ensure_db()
  local rid = tonumber(id)
  if not rid then
    return false, "invalid id"
  end
  local before = db_select(string.format("SELECT COUNT(*) AS c FROM tasks WHERE id=%d", rid))
  if #before == 0 or tonumber(before[1].c or 0) == 0 then
    return false, "Task not found"
  end
  db_exec(string.format(
    [[BEGIN;
    INSERT INTO deleted (id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog)
      SELECT id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog FROM tasks WHERE id=%d;
    DELETE FROM tasks WHERE id=%d;
  COMMIT;]],
    rid,
    rid
  ))
  return true
end

local function get_visual_selection()
  local bufnr = 0
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local start_line, start_col = s[2], s[3]
  local end_line, end_col = e[2], e[3]
  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  if #lines == 0 then
    return nil
  end
  lines[1] = string.sub(lines[1], start_col)
  lines[#lines] = string.sub(lines[#lines], 1, end_col)
  return table.concat(lines, "\n")
end

function M.add_text(title, body)
  local t = {
    title = title or "Untitled",
    why = body or "",
    impact = "",
    reward = "",
    points = 3,
    priority = "medium",
    area = "general",
    backlog = false,
    due = os.time() + 24 * 3600,
  }
  local added, err = M.add(t)
  return added, err
end

local function next_task_id()
  ensure_db()
  local rows = db_select("SELECT COALESCE(MAX(id),0) AS m FROM tasks")
  local maxid = 0
  if #rows > 0 and rows[1].m then
    maxid = tonumber(rows[1].m) or 0
  end
  return maxid + 1
end

function M.restore_archived(id)
  ensure_db()
  local rid = tonumber(id)
  if not rid then
    return false, "invalid id"
  end
  local exists = db_select(string.format("SELECT COUNT(*) AS c FROM archive WHERE id=%d", rid))
  if #exists == 0 or tonumber(exists[1].c or 0) == 0 then
    return false, "not found"
  end
  local new_id = next_task_id()
  db_exec(string.format(
    [[BEGIN;
    INSERT INTO tasks (id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog)
      SELECT %d, uid, title, area, 'pending', priority, points, reward, impact, why, created_at, NULL, NULL, due, 0 FROM archive WHERE id=%d;
    DELETE FROM archive WHERE id=%d;
  COMMIT;]],
    new_id,
    rid,
    rid
  ))
  return true
end

function M.restore_deleted(id)
  ensure_db()
  local rid = tonumber(id)
  if not rid then
    return false, "invalid id"
  end
  local exists = db_select(string.format("SELECT COUNT(*) AS c FROM deleted WHERE id=%d", rid))
  if #exists == 0 or tonumber(exists[1].c or 0) == 0 then
    return false, "not found"
  end
  local new_id = next_task_id()
  db_exec(string.format(
    [[BEGIN;
    INSERT INTO tasks (id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog)
      SELECT %d, uid, title, area, 'pending', priority, points, reward, impact, why, created_at, NULL, NULL, due, 0 FROM deleted WHERE id=%d;
    DELETE FROM deleted WHERE id=%d;
  COMMIT;]],
    new_id,
    rid,
    rid
  ))
  return true
end

-- Empty all items from the Deleted bin
function M.empty_deleted()
  ensure_db()
  db_exec("DELETE FROM deleted")
  return true
end

function M.reopen_completed(id)
  ensure_db()
  local rid = tonumber(id)
  if not rid then
    return false, "invalid id"
  end
  local exists = db_select(string.format("SELECT COUNT(*) AS c FROM tasks WHERE id=%d AND status='completed'", rid))
  if #exists == 0 or tonumber(exists[1].c or 0) == 0 then
    return false, "not found"
  end
  db_exec(
    string.format("UPDATE tasks SET status='pending', started_at=NULL, completed_at=NULL, backlog=0 WHERE id=%d", rid)
  )
  return true
end

local function should_archive(t, days)
  local d = days or config.archive_after_days or 14
  if t.status ~= "completed" then
    return false
  end
  local comp = t.completed_at or 0
  return (now() - comp) >= (d * 24 * 3600)
end

function M.archive(days)
  ensure_db()
  local d = tonumber(days) or config.archive_after_days or 14
  local cutoff = now() - d * 24 * 3600
  db_exec(string.format(
    [[BEGIN;
    INSERT INTO archive (id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog)
      SELECT id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog FROM tasks
      WHERE status='completed' AND (completed_at IS NOT NULL) AND completed_at <= %d;
    DELETE FROM tasks WHERE status='completed' AND (completed_at IS NOT NULL) AND completed_at <= %d;
  COMMIT;]],
    cutoff,
    cutoff
  ))
  return true
end

function M.archive_task(id)
  ensure_db()
  local rid = tonumber(id)
  if not rid then
    return false, "invalid id"
  end
  local before = db_select(string.format("SELECT COUNT(*) AS c FROM tasks WHERE id=%d", rid))
  if #before == 0 or tonumber(before[1].c or 0) == 0 then
    return false, "Task not found"
  end
  db_exec(string.format(
    [[BEGIN;
    INSERT INTO archive (id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog)
      SELECT id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog FROM tasks WHERE id=%d;
    DELETE FROM tasks WHERE id=%d;
  COMMIT;]],
    rid,
    rid
  ))
  return true
end
function M.list(filter)
  load_state()
  local items = {}
  for _, t in ipairs(state.tasks) do
    local ok = true
    if filter == "important" then
      ok = (t.priority == "high") and (t.status ~= "completed")
    elseif filter == "backlog" then
      ok = t.backlog and (t.status ~= "completed")
    elseif filter == "in_progress" then
      ok = t.status == "in_progress"
    elseif filter == "completed" then
      ok = t.status == "completed"
    elseif filter == "today" then
      if t.due then
        local today = os.date("%Y-%m-%d")
        ok = os.date("%Y-%m-%d", t.due) == today and (t.status ~= "completed")
      else
        ok = false
      end
    elseif filter == "next7" then
      if t.due then
        local end_ts = now() + 7 * 24 * 3600
        ok = (t.due <= end_ts) and (t.status ~= "completed")
      else
        ok = false
      end
    elseif filter == "overdue" then
      if t.due then
        ok = (t.due < now()) and (t.status ~= "completed")
      else
        ok = false
      end
    elseif type(filter) == "string" and filter:match("^area:") then
      local area = filter:sub(6)
      ok = (t.area == area)
    else
      ok = true
    end
    if ok then
      table.insert(items, t)
    end
  end
  table.sort(items, function(a, b)
    local sa, sb = score_for(a), score_for(b)
    if sa == sb then
      return (a.created_at or 0) < (b.created_at or 0)
    end
    return sa > sb
  end)
  local lines = {}
  table.insert(lines, string.format("TaskFlow | total points: %d | filter: %s", state.points or 0, filter or "all"))
  table.insert(lines, "---")
  for _, t in ipairs(items) do
    table.insert(lines, fmt_task_line(t))
  end
  render(lines, "TaskFlow:" .. (filter or "all"))
end

function M.area(area)
  if not area or #area == 0 then
    return M.list(nil)
  end
  return M.list("area:" .. area)
end

function M.dashboard()
  load_state()
  local function sort_tasks(items)
    table.sort(items, function(a, b)
      local sa, sb = score_for(a), score_for(b)
      if sa == sb then
        local da = a.due or 0
        local db = b.due or 0
        if da == db then
          return (a.created_at or 0) < (b.created_at or 0)
        end
        return da < db
      end
      return sa > sb
    end)
  end

  local function collect_all_pending_non_backlog()
    local items = {}
    for _, t in ipairs(state.tasks) do
      if t.status ~= "completed" and (t.status == "pending" or t.status == nil) and not t.backlog then
        table.insert(items, t)
      end
    end
    sort_tasks(items)
    return items
  end

  local function collect_completed()
    local items = {}
    for _, t in ipairs(state.tasks) do
      if t.status == "completed" then
        table.insert(items, t)
      end
    end
    table.sort(items, function(a, b)
      return (a.completed_at or 0) > (b.completed_at or 0)
    end)
    return items
  end

  local function collect_archived()
    ensure_db()
    local rows = db_select(
      "SELECT id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog FROM archive ORDER BY completed_at DESC"
    )
    local items = {}
    for _, r in ipairs(rows) do
      table.insert(items, {
        id = tonumber(r.id),
        uid = r.uid,
        title = r.title,
        area = r.area,
        status = r.status,
        priority = r.priority,
        points = tonumber(r.points),
        reward = r.reward,
        impact = r.impact,
        why = r.why,
        created_at = tonumber(r.created_at),
        started_at = tonumber(r.started_at),
        completed_at = tonumber(r.completed_at),
        due = tonumber(r.due),
        backlog = tonumber(r.backlog) == 1,
      })
    end
    return items
  end

  local function collect_deleted()
    ensure_db()
    local rows = db_select(
      "SELECT id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog FROM deleted ORDER BY created_at DESC"
    )
    local items = {}
    for _, r in ipairs(rows) do
      table.insert(items, {
        id = tonumber(r.id),
        uid = r.uid,
        title = r.title,
        area = r.area,
        status = r.status,
        priority = r.priority,
        points = tonumber(r.points),
        reward = r.reward,
        impact = r.impact,
        why = r.why,
        created_at = tonumber(r.created_at),
        started_at = tonumber(r.started_at),
        completed_at = tonumber(r.completed_at),
        due = tonumber(r.due),
        backlog = tonumber(r.backlog) == 1,
      })
    end
    return items
  end

  local function collect_active()
    local items = {}
    for _, t in ipairs(state.tasks) do
      -- Active section shows only started tasks
      if t.status == "in_progress" then
        table.insert(items, t)
      end
    end
    sort_tasks(items)
    return items
  end

  local function collect_backlog()
    local items = {}
    for _, t in ipairs(state.tasks) do
      if t.status ~= "completed" and t.backlog then
        table.insert(items, t)
      end
    end
    sort_tasks(items)
    return items
  end

  local function build_lines()
    local active = collect_active()
    local back = collect_backlog()
    local allp = collect_all_pending_non_backlog()
    local completed = collect_completed()
    local archived = collect_archived()
    local deleted = collect_deleted()
    local sep = string.rep("-", 60)
    local lines = {}
    table.insert(
      lines,
      string.format(
        "TaskFlow Dashboard | active: %d | backlog: %d | all(pending): %d | completed: %d | archived: %d | deleted: %d | points: %d",
        #active,
        #back,
        #allp,
        #completed,
        #archived,
        #deleted,
        state.points or 0
      )
    )
    table.insert(lines, string.format("Store: %s", get_data_path()))
    table.insert(lines, "---")
    table.insert(lines, "⏳ Active:")
    table.insert(lines, sep)
    for _, t in ipairs(active) do
      local tag = is_overdue(t) and " [OVERDUE]" or ""
      if t.status == "in_progress" then
        tag = tag .. " [IN PROGRESS]"
      end
      table.insert(lines, fmt_task_line(t) .. tag)
      if expanded and t.id and expanded[t.id] then
        table.insert(lines, "  Why:")
        local why = t.why or ""
        for s in tostring(why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "    " .. s)
          end
        end
        if t.impact and #t.impact > 0 then
          table.insert(lines, "  Impact: " .. t.impact)
        end
        if t.reward and #t.reward > 0 then
          table.insert(lines, "  Reward: " .. t.reward)
        end
        table.insert(lines, "")
      end
    end
    table.insert(lines, "")
    table.insert(lines, "Backlog:")
    table.insert(lines, sep)
    for _, t in ipairs(back) do
      local tag = is_overdue(t) and " [OVERDUE]" or ""
      if t.status == "in_progress" then
        tag = tag .. " [IN PROGRESS]"
      end
      table.insert(lines, fmt_task_line(t) .. tag)
      if expanded and t.id and expanded[t.id] then
        table.insert(lines, "  Why:")
        local why = t.why or ""
        for s in tostring(why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "    " .. s)
          end
        end
        if t.impact and #t.impact > 0 then
          table.insert(lines, "  Impact: " .. t.impact)
        end
        if t.reward and #t.reward > 0 then
          table.insert(lines, "  Reward: " .. t.reward)
        end
        table.insert(lines, "")
      end
    end
    table.insert(lines, "")
    table.insert(lines, "All (Pending, Not Backlogged):")
    table.insert(lines, sep)
    for _, t in ipairs(allp) do
      if t.status ~= "in_progress" then
        local tag = is_overdue(t) and " [OVERDUE]" or ""
        table.insert(lines, fmt_task_line(t) .. tag)
        if expanded and t.id and expanded[t.id] then
          table.insert(lines, "  Why:")
          local why = t.why or ""
          for s in tostring(why):gmatch("([^\n]*)\n?") do
            if s ~= nil then
              table.insert(lines, "    " .. s)
            end
          end
          if t.impact and #t.impact > 0 then
            table.insert(lines, "  Impact: " .. t.impact)
          end
          if t.reward and #t.reward > 0 then
            table.insert(lines, "  Reward: " .. t.reward)
          end
          table.insert(lines, "")
        end
      end
    end
    table.insert(lines, "")
    table.insert(lines, "Completed ✅:")
    table.insert(lines, sep)
    for _, t in ipairs(completed) do
      table.insert(lines, fmt_task_line(t))
      if expanded and t.id and expanded[t.id] then
        table.insert(lines, "  Why:")
        local why = t.why or ""
        for s in tostring(why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "    " .. s)
          end
        end
        table.insert(lines, "")
      end
    end
    table.insert(lines, "")
    table.insert(lines, "Archived:")
    table.insert(lines, sep)
    for _, t in ipairs(archived) do
      table.insert(lines, fmt_task_line(t))
      if expanded and t.id and expanded[t.id] then
        table.insert(lines, "  Why:")
        local why = t.why or ""
        for s in tostring(why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "    " .. s)
          end
        end
        table.insert(lines, "")
      end
    end
    table.insert(lines, "")
    table.insert(lines, "Deleted 🗑️:")
    table.insert(lines, sep)
    for _, t in ipairs(deleted) do
      table.insert(lines, fmt_task_line(t))
      if expanded and t.id and expanded[t.id] then
        table.insert(lines, "  Why:")
        local why = t.why or ""
        for s in tostring(why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "    " .. s)
          end
        end
        table.insert(lines, "")
      end
    end
    table.insert(lines, "")
    -- Progress report (last 30 days), appended at end
    local since = now() - 30 * 24 * 3600
    local since_str = os.date("%Y-%m-%d", since)
    local completed_since, started_since, inprog = {}, {}, {}
    local pts_since = 0
    local area_counts = {}
    local prio_counts = { low = 0, medium = 0, high = 0 }
    for _, t in ipairs(state.tasks) do
      if t.status == "completed" and (t.completed_at or 0) >= since then
        table.insert(completed_since, t)
        pts_since = pts_since + (t.points or 0)
        area_counts[t.area or "general"] = (area_counts[t.area or "general"] or 0) + 1
        local p = t.priority or "medium"
        prio_counts[p] = (prio_counts[p] or 0) + 1
      end
      if (t.started_at or 0) >= since and (t.status ~= "completed") then
        table.insert(started_since, t)
      end
      if t.status == "in_progress" then
        table.insert(inprog, t)
      end
    end
    table.sort(completed_since, function(a, b)
      return (a.completed_at or 0) > (b.completed_at or 0)
    end)
    table.sort(started_since, function(a, b)
      return (a.started_at or 0) > (b.started_at or 0)
    end)
    table.insert(lines, "Report (last 30d):")
    table.insert(lines, sep)
    table.insert(
      lines,
      string.format(
        "  Points earned: %d | Completed: %d | Started: %d | In Progress: %d",
        pts_since,
        #completed_since,
        #started_since,
        #inprog
      )
    )
    -- Rewards summary in report
    local pts_total = state.points or 0
    table.insert(lines, string.format("  Rewards (total points: %d):", pts_total))
    local claimed = state.rewards_claimed or {}
    for _, r in ipairs(config.rewards or {}) do
      local is_claimed = claimed and claimed[tostring(r.threshold)]
      local status = is_claimed and "(claimed)" or ((pts_total >= r.threshold) and "(available)" or "(locked)")
      table.insert(lines, string.format("    - %d: %s %s", r.threshold, r.suggestion, status))
    end
    table.insert(lines, "")
    table.insert(lines, "  Completed Details:")
    for _, t in ipairs(completed_since) do
      table.insert(lines, "    " .. fmt_task_line(t))
      if t.why and #t.why > 0 then
        table.insert(lines, "      Why:")
        for s in tostring(t.why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "        " .. s)
          end
        end
      end
      if t.impact and #t.impact > 0 then
        table.insert(lines, "      Impact: " .. t.impact)
      end
      if t.reward and #t.reward > 0 then
        table.insert(lines, "      Reward: " .. t.reward .. string.format(" (pts:%d)", tonumber(t.points) or 0))
      else
        table.insert(lines, string.format("      Points: %d", tonumber(t.points) or 0))
      end
      table.insert(lines, "")
    end
    table.insert(lines, "  Started Details:")
    for _, t in ipairs(started_since) do
      local tag = is_overdue(t) and " [OVERDUE]" or ""
      table.insert(lines, "    " .. fmt_task_line(t) .. tag)
      if t.why and #t.why > 0 then
        table.insert(lines, "      Why:")
        for s in tostring(t.why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "        " .. s)
          end
        end
      end
      table.insert(lines, "")
    end
    table.insert(lines, "  Area Breakdown (completed):")
    for a, c in pairs(area_counts) do
      table.insert(lines, string.format("    %s: %d", a, c))
    end
    table.insert(lines, "  Priority Breakdown (completed):")
    table.insert(lines, string.format("    low: %d", prio_counts.low or 0))
    table.insert(lines, string.format("    medium: %d", prio_counts.medium or 0))
    table.insert(lines, string.format("    high: %d", prio_counts.high or 0))
    table.insert(lines, "")
    table.insert(
      lines,
      "Controls: s=start, x=complete, b=toggle backlog, p=postpone Nd, a=archive, d=delete, e=empty deleted, r=restore/reopen (in Completed/Archived/Deleted), <CR>=toggle details, q=close"
    )
    return lines
  end

  local buf = render(build_lines(), "TaskFlow:Dashboard")
  -- Keep dashboard buffer around when hidden to avoid invalid buffer id during keymap setup
  pcall(vim.api.nvim_buf_set_option, buf, "bufhidden", "hide")
  local function apply_header_highlights()
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
      return
    end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local function add_hl_for_header(text, group)
      for i = 1, #lines do
        if lines[i] == text then
          -- i-1 for 0-based row; highlight whole line
          pcall(vim.api.nvim_buf_add_highlight, buf, -1, group, i - 1, 0, -1)
          break
        end
      end
    end
    add_hl_for_header("⏳ Active:", "TaskflowActiveHeader")
    add_hl_for_header("Deleted 🗑️:", "TaskflowDeletedHeader")
    add_hl_for_header("Archived:", "TaskflowArchivedHeader")
    add_hl_for_header("Completed ✅:", "TaskflowCompletedHeader")
  end
  local function id_at_cursor()
    local line = vim.api.nvim_get_current_line()
    local id = line:match("%[(%d+)%]")
    return id and tonumber(id) or nil
  end
  local function section_at_cursor()
    local row = (vim.api.nvim_win_get_cursor(0) or { 1, 0 })[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local current = ""
    for i = 1, math.min(row, #lines) do
      local l = lines[i]
      if
        l == "⏳ Active:"
        or l == "Backlog:"
        or l == "All (Pending, Not Backlogged):"
        or l == "Completed ✅:"
        or l == "Archived:"
        or l == "Deleted 🗑️:"
      then
        current = l
      end
    end
    return current
  end
  local function redraw()
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    local new_lines = build_lines()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    apply_header_highlights()
  end
  local function buf_map(lhs, fn)
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
      return
    end
    vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true })
  end
  buf_map("<CR>", function()
    local id = id_at_cursor()
    if id then
      expanded = expanded or {}
      expanded[id] = not expanded[id]
      redraw()
    end
  end)
  -- initial highlight application
  apply_header_highlights()
  buf_map("r", function()
    local id = id_at_cursor()
    if not id then
      return
    end
    local section = section_at_cursor()
    -- Match by section prefix to be robust to emojis
    if section:match("^Completed") then
      M.reopen_completed(id)
    elseif section:match("^Archived") then
      M.restore_archived(id)
    elseif section:match("^Deleted") then
      M.restore_deleted(id)
    else
      -- In other sections, 'r' does nothing
      return
    end
    load_state()
    redraw()
  end)
  buf_map("q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
  buf_map("s", function()
    local id = id_at_cursor()
    if id then
      M.start(id)
      load_state()
      redraw()
    end
  end)
  buf_map("x", function()
    local id = id_at_cursor()
    if id then
      M.complete(id)
      load_state()
      redraw()
    end
  end)
  buf_map("b", function()
    local id = id_at_cursor()
    if id then
      M.set_backlog(id, "toggle")
      load_state()
      redraw()
    end
  end)
  buf_map("p", function()
    local id = id_at_cursor()
    if not id then
      return
    end
    vim.ui.input({ prompt = "Postpone days: ", default = "1" }, function(val)
      if not val then
        return
      end
      local d = tonumber(val)
      if not d or d <= 0 then
        vim.notify("Invalid days", vim.log.levels.WARN)
        return
      end
      local delta = d * 24 * 3600
      ensure_db()
      db_exec(string.format("UPDATE tasks SET due = COALESCE(due, %d) + %d WHERE id=%d", now(), delta, id))
      load_state()
      redraw()
    end)
  end)
  buf_map("a", function()
    local id = id_at_cursor()
    if id then
      M.archive_task(id)
      load_state()
      redraw()
    end
  end)
  buf_map("d", function()
    local id = id_at_cursor()
    if id then
      vim.ui.input({ prompt = string.format("Delete task %d? (yes/no): ", id), default = "yes" }, function(val)
        if val and val:lower() == "yes" then
          M.delete(id)
          load_state()
          redraw()
        end
      end)
    end
  end)
  -- Empty Deleted bin (confirmation required)
  buf_map("e", function()
    vim.ui.input({ prompt = "Empty Deleted bin? Type 'yes' to confirm: ", default = "no" }, function(val)
      if val and val:lower() == "yes" then
        M.empty_deleted()
        load_state()
        redraw()
        vim.notify("Deleted bin emptied")
      end
    end)
  end)
  buf_map("m", function()
    local id = id_at_cursor()
    if not id then
      return
    end
    M.edit_interactive(id)
    load_state()
    redraw()
  end)
end

-- Build HTML for today's due tasks
local function build_today_due_html(today_due, overdue, next3)
  local lines = {}
  table.insert(lines, "<html><body>")
  table.insert(lines, string.format("<h2>Tasks Digest (%s)</h2>", os.date("%Y-%m-%d")))
  local function section(title, tasks)
    table.insert(lines, string.format("<h3>%s (%d)</h3>", title, #tasks))
    if #tasks == 0 then
      table.insert(lines, "<p>None</p>")
      return
    end
    table.insert(lines, "<ul>")
    for _, t in ipairs(tasks) do
      local due = (t.due and tonumber(t.due)) and os.date("%Y-%m-%d", tonumber(t.due)) or "-"
      local item = string.format("<li>[%s] (%s/%s) %s | pts:%d | due:%s</li>", tostring(t.id or "?"), t.area or "general", t.priority or "medium", (t.title or ""), tonumber(t.points or 0), due)
      table.insert(lines, item)
    end
    table.insert(lines, "</ul>")
  end
  section("Due Today", today_due)
  section("Overdue", overdue)
  section("Next 3 Days", next3)
  table.insert(lines, "</body></html>")
  return table.concat(lines, "\n")
end

local function collect_today_due_tasks()
  load_state()
  local today = os.date("%Y-%m-%d")
  local items = {}
  for _, t in ipairs(state.tasks or {}) do
    if t.due and os.date("%Y-%m-%d", t.due) == today and (t.status ~= "completed") then
      table.insert(items, t)
    end
  end
  table.sort(items, function(a, b)
    local sa, sb = score_for(a), score_for(b)
    if sa == sb then
      return (a.created_at or 0) < (b.created_at or 0)
    end
    return sa > sb
  end)
  return items
end

local function collect_overdue_tasks()
  load_state()
  local items = {}
  for _, t in ipairs(state.tasks or {}) do
    if t.due and (t.due < now()) and (t.status ~= "completed") then
      table.insert(items, t)
    end
  end
  table.sort(items, function(a, b)
    local sa, sb = score_for(a), score_for(b)
    if sa == sb then
      return (a.due or 0) < (b.due or 0)
    end
    return sa > sb
  end)
  return items
end

local function collect_next3_tasks()
  load_state()
  local end_ts = now() + 3 * 24 * 3600
  local today_str = os.date("%Y-%m-%d")
  local items = {}
  for _, t in ipairs(state.tasks or {}) do
    if t.due and (t.due > now()) and (t.due <= end_ts) and (t.status ~= "completed") and (os.date("%Y-%m-%d", t.due) ~= today_str) then
      table.insert(items, t)
    end
  end
  table.sort(items, function(a, b)
    local sa, sb = score_for(a), score_for(b)
    if sa == sb then
      return (a.due or 0) < (b.due or 0)
    end
    return sa > sb
  end)
  return items
end

-- Minimal SES email sender modeled after user/newsletter.lua
local function require_email_env(subject_override)
  local from_email = "hello@sminrana.com"
  local from_name = "TaskFlow"
  local subject = subject_override or ("Tasks Digest: Today, Overdue, Next 3 Days - " .. os.date("%Y-%m-%d"))
  local region = vim.env.AWS_REGION or vim.env.AWS_DEFAULT_REGION or "us-east-1"
  local to_email = vim.env.TASKS_EMAIL_TO or vim.env.NEWSLETTER_TEST_RECIPIENT or from_email
  if not region or region == "" then
    return nil, "Missing AWS region (set AWS_REGION)"
  end
  if vim.fn.executable("aws") ~= 1 then
    return nil, "aws CLI is not installed or not in PATH"
  end
  return {
    from_email = from_email,
    from_name = from_name,
    subject = subject,
    region = region,
    to_email = to_email,
  }, nil
end

local function ses_send_html(env, html, to)
  local safe_html = tostring(html or ""):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
  local json_payload = string.format([[{
  "FromEmailAddress": "%s <%s>",
  "Destination": { "ToAddresses": ["%s"] },
  "Content": { "Simple": { "Subject": { "Data": "%s", "Charset": "UTF-8" }, "Body": { "Html": { "Data": "%s", "Charset": "UTF-8" } } } }
}]], env.from_name, env.from_email, to, env.subject, safe_html)
  local out = vim.fn.system({ "aws", "sesv2", "send-email", "--region", env.region, "--cli-input-json", json_payload })
  local exit = vim.v.shell_error
  return exit, out
end

-- Public: send today's due tasks email immediately
function M.send_today_due_email()
  local today_due = collect_today_due_tasks()
  local overdue = collect_overdue_tasks()
  local next3 = collect_next3_tasks()
  local env, err = require_email_env()
  if err then
    vim.notify("TaskFlow Email: " .. err, vim.log.levels.ERROR)
    return false
  end
  if (#today_due == 0) and (#overdue == 0) and (#next3 == 0) then
    -- No send when nothing due; mark date to avoid re-sending
    meta_set("last_due_email_date", os.date("%Y-%m-%d"))
    vim.notify("TaskFlow: no tasks due today; skipping email", vim.log.levels.INFO)
    return true
  end
  local html = build_today_due_html(today_due, overdue, next3)
  local exit, out = ses_send_html(env, html, env.to_email)
  if exit == 0 then
    vim.notify("TaskFlow: sent today's due tasks email to " .. env.to_email, vim.log.levels.INFO)
    meta_set("last_due_email_date", os.date("%Y-%m-%d"))
    return true
  else
    vim.notify("TaskFlow: email send failed\n" .. tostring(out), vim.log.levels.ERROR)
    return false
  end
end

-- Schedule daily email at 06:00 local time (when Neovim is running)
function M.start_daily_due_email()
  -- Remember last sent date to avoid duplicates
  state.last_due_email_date = state.last_due_email_date or meta_get("last_due_email_date")
  local function ms_until_next_6am()
    local now_ts = os.time()
    local now_date = os.date("*t", now_ts)
    local target = {
      year = now_date.year,
      month = now_date.month,
      day = now_date.day,
      hour = 6,
      min = 0,
      sec = 0,
      isdst = now_date.isdst,
    }
    local target_ts = os.time(target)
    if target_ts <= now_ts then
      -- If past 6am today, schedule for tomorrow
      target.day = target.day + 1
      target_ts = os.time(target)
    end
    local delta = (target_ts - now_ts) * 1000
    if delta < 0 then delta = 1000 end
    return delta
  end
  local timer = vim.loop.new_timer()
  local function schedule_next()
    local ms = ms_until_next_6am()
    timer:start(ms, 0, function()
      local today = os.date("%Y-%m-%d")
      local last = meta_get("last_due_email_date")
      if last ~= today then
        M.send_today_due_email()
      end
      -- chain next run for tomorrow 6am
      schedule_next()
    end)
  end
  schedule_next()
  vim.notify("TaskFlow: daily due email scheduling started (06:00)", vim.log.levels.INFO)
end

-- Send once on first Neovim start of the day
function M.auto_send_today_on_start()
  local today = os.date("%Y-%m-%d")
  local last = meta_get("last_due_email_date")
  if last ~= today then
    M.send_today_due_email()
  end
end

-- Enable automatic send on VimEnter (first run) and also start the 6am scheduler
function M.enable_auto_due_email_on_start()
  local grp = vim.api.nvim_create_augroup("TaskFlowDueEmail", { clear = true })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = grp,
    once = true,
    callback = function()
      pcall(M.auto_send_today_on_start)
    end,
  })
end

function M.open_ui()
  load_state()
  local lines = {}
  table.insert(lines, string.format("TaskFlow Dashboard | points: %d", state.points or 0))
  table.insert(lines, "")
  table.insert(lines, "Important (top by score):")
  local important = {}
  for _, t in ipairs(state.tasks) do
    if t.priority == "high" and t.status ~= "completed" then
      table.insert(important, t)
    end
  end
  table.sort(important, function(a, b)
    return score_for(a) > score_for(b)
  end)
  for i = 1, math.min(#important, 7) do
    table.insert(lines, "  " .. fmt_task_line(important[i]))
  end
  table.insert(lines, "")
  table.insert(lines, "Backlog:")
  for _, t in ipairs(state.tasks) do
    if t.backlog and t.status ~= "completed" then
      table.insert(lines, "  " .. fmt_task_line(t))
    end
  end
  table.insert(lines, "")
  table.insert(lines, "In Progress:")
  for _, t in ipairs(state.tasks) do
    if t.status == "in_progress" then
      table.insert(lines, "  " .. fmt_task_line(t))
    end
  end
  table.insert(lines, "")
  table.insert(lines, "Completed (recent 5):")
  local completed = {}
  for _, t in ipairs(state.tasks) do
    if t.status == "completed" then
      table.insert(completed, t)
    end
  end
  table.sort(completed, function(a, b)
    return (a.completed_at or 0) > (b.completed_at or 0)
  end)
  for i = 1, math.min(#completed, 5) do
    table.insert(lines, "  " .. fmt_task_line(completed[i]))
  end
  table.insert(lines, "")
  table.insert(lines, "UI Controls: s=start, x=complete, k=toggle backlog, o=postpone 1d, w=weekly, r=rewards, q=close")
  local buf, _ = render_float(lines, "TaskFlow:UI")
  local function id_at_cursor()
    local line = vim.api.nvim_get_current_line()
    local id = line:match("%[(%d+)%]")
    return id and tonumber(id) or nil
  end
  local function redraw()
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    -- re-render simplified dashboard in the same buffer
    local new_lines = {}
    table.insert(new_lines, string.format("TaskFlow Dashboard | points: %d", state.points or 0))
    table.insert(new_lines, "")
    table.insert(new_lines, "Important (top by score):")
    local important2 = {}
    for _, t in ipairs(state.tasks) do
      if t.priority == "high" and t.status ~= "completed" then
        table.insert(important2, t)
      end
    end
    table.sort(important2, function(a, b)
      return score_for(a) > score_for(b)
    end)
    for i = 1, math.min(#important2, 7) do
      local t = important2[i]
      local tag = is_overdue(t) and " [OVERDUE]" or ""
      table.insert(new_lines, "  " .. fmt_task_line(t) .. tag)
    end
    table.insert(new_lines, "")
    table.insert(new_lines, "Backlog:")
    for _, t in ipairs(state.tasks) do
      if t.backlog and t.status ~= "completed" then
        local tag = is_overdue(t) and " [OVERDUE]" or ""
        table.insert(new_lines, "  " .. fmt_task_line(t) .. tag)
      end
    end
    table.insert(new_lines, "")
    table.insert(new_lines, "In Progress:")
    for _, t in ipairs(state.tasks) do
      if t.status == "in_progress" then
        local tag = is_overdue(t) and " [OVERDUE]" or ""
        table.insert(new_lines, "  " .. fmt_task_line(t) .. tag)
      end
    end
    table.insert(new_lines, "")
    table.insert(new_lines, "Completed (recent 5):")
    local completed2 = {}
    for _, t in ipairs(state.tasks) do
      if t.status == "completed" then
        table.insert(completed2, t)
      end
    end
    table.sort(completed2, function(a, b)
      return (a.completed_at or 0) > (b.completed_at or 0)
    end)
    for i = 1, math.min(#completed2, 5) do
      table.insert(new_lines, "  " .. fmt_task_line(completed2[i]))
    end
    table.insert(new_lines, "")
    table.insert(
      new_lines,
      "UI Controls: s=start, x=complete, k=toggle backlog, o=postpone 1d, w=weekly, r=rewards, q=close"
    )
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end
  local function buf_map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true })
  end
  buf_map("q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
  buf_map("s", function()
    local id = id_at_cursor()
    if id then
      M.start(id)
      redraw()
    end
  end)
  buf_map("x", function()
    local id = id_at_cursor()
    if id then
      M.complete(id)
      redraw()
    end
  end)
  buf_map("k", function()
    local id = id_at_cursor()
    if id then
      M.set_backlog(id, "toggle")
      redraw()
    end
  end)
  buf_map("w", function()
    M.weekly_review()
  end)
  buf_map("r", function()
    M.rewards()
  end)
  buf_map("o", function()
    local id = id_at_cursor()
    if id then
      ensure_db()
      db_exec(string.format("UPDATE tasks SET due = COALESCE(due, %d) + %d WHERE id=%d", now(), 24 * 3600, id))
      load_state()
      redraw()
    end
  end)
  buf_map("d", function()
    local id = id_at_cursor()
    if id then
      vim.ui.input({ prompt = string.format("Delete task %d? (yes/no): ", id), default = "no" }, function(val)
        if val and val:lower() == "yes" then
          local ok = M.delete(id)
          if ok then
            load_state()
            redraw()
            vim.notify(string.format("Deleted task %d", id))
          else
            vim.notify("Delete failed", vim.log.levels.ERROR)
          end
        end
      end)
    end
  end)
end

function M.weekly_review()
  load_state()
  local since = now() - 7 * 24 * 3600
  local lines = {}
  local total = 0
  local items = {}
  for _, t in ipairs(state.tasks) do
    if t.status == "completed" and (t.completed_at or 0) >= since then
      total = total + (t.points or 0)
      table.insert(items, t)
    end
  end
  table.sort(items, function(a, b)
    return (a.completed_at or 0) > (b.completed_at or 0)
  end)
  table.insert(lines, string.format("Weekly Review | points earned: %d | completed: %d", total, #items))
  table.insert(lines, "")
  for i = 1, math.min(#items, 10) do
    local t = items[i]
    table.insert(lines, fmt_task_line(t))
  end
  table.insert(lines, "")
  table.insert(lines, "Tip: Use :TodoArchive to auto-archive completed older than N days.")
  render(lines, "TaskFlow:Weekly")
end

function M.rewards()
  load_state()
  local pts = state.points or 0
  local lines = {}
  table.insert(lines, string.format("Rewards | total points: %d", pts))
  table.insert(lines, "")
  for _, r in ipairs(config.rewards or {}) do
    local claimed = state.rewards_claimed and state.rewards_claimed[tostring(r.threshold)]
    local status = claimed and "(claimed)" or ((pts >= r.threshold) and "(available)" or "(locked)")
    table.insert(lines, string.format(" - %d: %s %s", r.threshold, r.suggestion, status))
  end
  table.insert(lines, "")
  table.insert(lines, "Claim with :TodoRewardClaim <threshold>")
  render(lines, "TaskFlow:Rewards")
end

function M.postpone_overdue(days)
  ensure_db()
  local d = tonumber(days) or 1
  local delta = d * 24 * 3600
  local now_ts = now()
  local rows = db_select(
    string.format(
      "SELECT COUNT(*) AS c FROM tasks WHERE due IS NOT NULL AND due < %d AND status <> 'completed'",
      now_ts
    )
  )
  local cnt = 0
  if #rows > 0 and rows[1].c then
    cnt = tonumber(rows[1].c) or 0
  end
  db_exec(
    string.format(
      "UPDATE tasks SET due = due + %d WHERE due IS NOT NULL AND due < %d AND status <> 'completed'",
      delta,
      now_ts
    )
  )
  return cnt
end

function M.reward_claim(threshold)
  load_state()
  local th = tostring(tonumber(threshold))
  if not th then
    return false, "invalid threshold"
  end
  state.rewards_claimed = state.rewards_claimed or {}
  state.rewards_claimed[th] = true
  save_state()
  return true
end

local function input(prompt, default, cb)
  vim.ui.input({ prompt = prompt, default = default or "" }, function(val)
    cb(val)
  end)
end

function M.add_interactive()
  local t = {}
  input("Title: ", "", function(v1)
    if v1 == nil then
      vim.notify("Task add cancelled", vim.log.levels.INFO)
      return
    end
    t.title = v1 ~= "" and v1 or "Untitled"
    input("Why (motivation): ", "", function(v2)
      if v2 == nil then
        vim.notify("Task add cancelled", vim.log.levels.INFO)
        return
      end
      t.why = v2 or ""
      input("Impact (what happens if completed): ", "", function(v3)
        if v3 == nil then
          vim.notify("Task add cancelled", vim.log.levels.INFO)
          return
        end
        t.impact = v3 or ""
        input("Reward (what do you get/do): ", "", function(v4)
          if v4 == nil then
            vim.notify("Task add cancelled", vim.log.levels.INFO)
            return
          end
          t.reward = v4 or ""
          input("Points (effort/value): ", "3", function(v5)
            if v5 == nil then
              vim.notify("Task add cancelled", vim.log.levels.INFO)
              return
            end
            t.points = tonumber(v5) or 3
            input("Priority (low/medium/high): ", "medium", function(v6)
              if v6 == nil then
                vim.notify("Task add cancelled", vim.log.levels.INFO)
                return
              end
              t.priority = (v6 == "low" or v6 == "high") and v6 or "medium"
              input("Area (e.g. work/personal): ", "general", function(v7)
                if v7 == nil then
                  vim.notify("Task add cancelled", vim.log.levels.INFO)
                  return
                end
                t.area = v7 or "general"
                local tomorrow = os.date("%Y-%m-%d", os.time() + 24 * 3600)
                input("Due (YYYY-MM-DD): ", tomorrow, function(v8)
                  -- require due date; fallback to tomorrow if empty
                  if v8 == nil then
                    vim.notify("Task add cancelled", vim.log.levels.INFO)
                    return
                  end
                  local due_str = (v8 and #v8 > 0) and v8 or tomorrow
                  local y, m, d = due_str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
                  local due_ts
                  if y and m and d then
                    local date_tbl = { year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 }
                    due_ts = os.time(date_tbl)
                  end
                  t.due = due_ts or (os.time() + 24 * 3600)
                  input("Backlog? (y/n): ", "n", function(v9)
                    if v9 == nil then
                      vim.notify("Task add cancelled", vim.log.levels.INFO)
                      return
                    end
                    local ans = tostring(v9 or "n"):lower()
                    t.backlog = (ans == "y" or ans == "yes" or ans == "1" or ans == "true")
                    local added, err = M.add(t)
                    if not added then
                      vim.notify(
                        "TaskFlow: failed to add task: " .. tostring(err or "unknown error"),
                        vim.log.levels.ERROR
                      )
                    else
                      M.dashboard()
                    end
                  end)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

function M.edit_interactive(id)
  ensure_db()
  local rid = tonumber(id)
  if not rid then
    vim.notify("Invalid id", vim.log.levels.WARN)
    return false
  end
  local rows = db_select(
    string.format(
      "SELECT id, title, area, status, priority, points, reward, impact, why, due, backlog FROM tasks WHERE id=%d",
      rid
    )
  )
  if #rows == 0 then
    vim.notify("Task not found", vim.log.levels.WARN)
    return false
  end
  local r = rows[1]
  local t = {
    title = r.title or "Untitled",
    why = r.why or "",
    impact = r.impact or "",
    reward = r.reward or "",
    points = tonumber(r.points) or 3,
    priority = (r.priority and #r.priority > 0) and r.priority or "medium",
    area = r.area or "general",
    due = tonumber(r.due),
    backlog = (tonumber(r.backlog) or 0) == 1,
  }
  local tomorrow = os.date("%Y-%m-%d", os.time() + 24 * 3600)
  local due_default = t.due and os.date("%Y-%m-%d", t.due) or tomorrow
  input("Title: ", t.title, function(v1)
    if v1 == nil then
      return
    end
    t.title = (v1 ~= "" and v1) or t.title
    input("Why (motivation): ", t.why, function(v2)
      if v2 == nil then
        return
      end
      t.why = v2 or ""
      input("Impact: ", t.impact, function(v3)
        if v3 == nil then
          return
        end
        t.impact = v3 or ""
        input("Reward: ", t.reward, function(v4)
          if v4 == nil then
            return
          end
          t.reward = v4 or ""
          input("Points: ", tostring(t.points), function(v5)
            if v5 == nil then
              return
            end
            t.points = tonumber(v5) or t.points
            input("Priority (low/medium/high): ", t.priority, function(v6)
              if v6 == nil then
                return
              end
              local p = (v6 == "low" or v6 == "high") and v6 or (v6 == "medium" and v6 or t.priority)
              t.priority = p
              input("Area: ", t.area, function(v7)
                if v7 == nil then
                  return
                end
                t.area = (v7 ~= "" and v7) or t.area
                input("Due (YYYY-MM-DD): ", due_default, function(v8)
                  if v8 == nil then
                    return
                  end
                  local due_str = (v8 and #v8 > 0) and v8 or due_default
                  local y, m, d = due_str:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
                  local due_ts
                  if y and m and d then
                    due_ts = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 })
                  end
                  t.due = due_ts or t.due or (os.time() + 24 * 3600)
                  input("Backlog? (y/n): ", t.backlog and "y" or "n", function(v9)
                    if v9 == nil then
                      return
                    end
                    local ans = tostring(v9 or (t.backlog and "y" or "n")):lower()
                    t.backlog = (ans == "y" or ans == "yes" or ans == "1" or ans == "true")
                    local sql = string.format(
                      "UPDATE tasks SET title='%s', area='%s', priority='%s', points=%d, reward='%s', impact='%s', why='%s', due=%d, backlog=%d WHERE id=%d",
                      sql_escape(t.title),
                      sql_escape(t.area),
                      sql_escape(t.priority),
                      tonumber(t.points) or 0,
                      sql_escape(t.reward),
                      sql_escape(t.impact),
                      sql_escape(t.why),
                      tonumber(t.due) or (os.time() + 24 * 3600),
                      t.backlog and 1 or 0,
                      rid
                    )
                    local out, code = db_exec(sql)
                    if code ~= 0 then
                      vim.notify("TaskFlow: sqlite error on UPDATE: " .. tostring(out), vim.log.levels.ERROR)
                      return
                    end
                    M.dashboard()
                  end)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
  return true
end

local function apply_config(opts)
  if type(opts) ~= "table" then
    return
  end
  if opts.archive_after_days then
    config.archive_after_days = tonumber(opts.archive_after_days) or config.archive_after_days
  end
  if opts.areas and type(opts.areas) == "table" then
    config.areas = opts.areas
  end
  if opts.rewards and type(opts.rewards) == "table" then
    config.rewards = opts.rewards
  end
  -- JSON sync/backup disabled; SQLite-only
end

local function telescope_available()
  local ok = pcall(require, "telescope")
  return ok
end

local function fzf_available()
  local ok = pcall(require, "fzf-lua")
  return ok
end

local function pick_with_fzf(items, on_select)
  local fzf = require("fzf-lua")
  fzf.fzf_exec(items, {
    prompt = "TaskFlow > ",
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then
          return
        end
        local line = selected[1]
        on_select(line)
      end,
    },
  })
end

local function pick_with_telescope(items, on_select)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  pickers
    .new({}, {
      prompt_title = "TaskFlow Pick",
      finder = finders.new_table({ results = items }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value then
            on_select(selection.value)
          end
        end)
        return true
      end,
    })
    :open()
end

local function pick_with_ui(items, on_select)
  vim.ui.select(items, { prompt = "Pick a task" }, function(choice)
    if choice then
      on_select(choice)
    end
  end)
end

function M.pick()
  load_state()
  local items = {}
  for _, t in ipairs(state.tasks) do
    if t.status ~= "completed" then
      table.insert(items, fmt_task_line(t))
    end
  end
  local function after_pick(line)
    local id = line:match("%[(%d+)%]")
    id = id and tonumber(id)
    -- No direct actions from pick; open interactive dashboard instead
    M.dashboard()
  end
  if fzf_available() then
    pick_with_fzf(items, after_pick)
  elseif telescope_available() then
    pick_with_telescope(items, after_pick)
  else
    pick_with_ui(items, after_pick)
  end
end

-- Export/import/backup removed (SQLite-only)

function M.setup(opts)
  apply_config(opts)
  ensure_db()
  load_state()
  -- Define simple highlight groups for section headers
  pcall(vim.api.nvim_set_hl, 0, "TaskflowActiveHeader", { fg = "#61afef", bold = true })
  pcall(vim.api.nvim_set_hl, 0, "TaskflowDeletedHeader", { fg = "#e06c75", bold = true })
  pcall(vim.api.nvim_set_hl, 0, "TaskflowArchivedHeader", { fg = "#7f848e", bold = true })
  pcall(vim.api.nvim_set_hl, 0, "TaskflowCompletedHeader", { fg = "#98c379", bold = true })
  -- archive cleanup on setup
  M.archive(config.archive_after_days)
  vim.api.nvim_create_user_command("TodoAdd", function()
    M.add_interactive()
  end, {})
  vim.api.nvim_create_user_command("TodoList", function(opts)
    M.list(opts.args ~= "" and opts.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return { "important", "backlog", "today", "next7", "overdue", "in_progress", "completed", "all" }
    end,
  })
  vim.api.nvim_create_user_command("TodoStart", function(opts)
    local ok = M.start(tonumber(opts.args))
    if ok then
      M.dashboard()
    end
  end, { nargs = 1 })
  vim.api.nvim_create_user_command("TodoComplete", function(opts)
    local ok = M.complete(tonumber(opts.args))
    if ok then
      M.dashboard()
    end
  end, { nargs = 1 })
  vim.api.nvim_create_user_command("TodoStop", function(opts)
    local ok = M.stop(tonumber(opts.args))
    if ok then
      M.dashboard()
    end
  end, { nargs = 1 })
  vim.api.nvim_create_user_command("TodoBacklog", function(opts)
    local args = vim.split(opts.args, " ")
    local id = tonumber(args[1])
    local mode = args[2] or "toggle"
    local ok = M.set_backlog(id, mode)
    if ok then
      M.dashboard()
    end
  end, { nargs = "+" })
  vim.api.nvim_create_user_command("TodoDashboard", function()
    M.dashboard()
  end, {})
  vim.api.nvim_create_user_command("TodoArea", function(opts)
    M.area(opts.args)
  end, {
    nargs = 1,
    complete = function()
      return all_areas()
    end,
  })
  vim.api.nvim_create_user_command("TodoWeeklyReview", function()
    M.weekly_review()
  end, {})
  vim.api.nvim_create_user_command("TodoArchive", function(opts)
    local days = tonumber(opts.args)
    M.archive(days)
    M.dashboard()
  end, { nargs = "?" })
  vim.api.nvim_create_user_command("TodoRewards", function()
    M.rewards()
  end, {})
  vim.api.nvim_create_user_command("TodoRewardClaim", function(opts)
    local ok = M.reward_claim(tonumber(opts.args))
    if ok then
      M.rewards()
    end
  end, { nargs = 1 })
  vim.api.nvim_create_user_command("TodoDelete", function(opts)
    local ok = M.delete(tonumber(opts.args))
    if ok then
      M.dashboard()
    end
  end, { nargs = 1 })
  vim.api.nvim_create_user_command("TodoPostponeOverdue", function(opts)
    local days = tonumber(opts.args) or 1
    local count = M.postpone_overdue(days)
    vim.notify(string.format("Postponed %d overdue task(s) by %d day(s)", count, days))
    M.dashboard()
  end, { nargs = "?" })

  -- Keymaps: prefix <leader>jt*
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
  end
  map("<leader>jtd", function()
    M.dashboard()
  end, "TaskFlow Dashboard")
  map("<leader>jta", function()
    M.add_interactive()
  end, "TaskFlow Add")
  map("<leader>jte", function()
    M.send_today_due_email()
  end, "TaskFlow Send Email (today/overdue/next3)")
  vim.api.nvim_create_user_command("TodoDashboardHistory", function()
    M.dashboard_history()
  end, {})
  -- Visual mode: add selected text as a task
  vim.keymap.set("x", "<leader>jtv", function()
    local sel = get_visual_selection()
    if not sel or #sel == 0 then
      vim.notify("No selection", vim.log.levels.WARN)
      return
    end
    -- Flatten selection into a single-line title (title + description), keep full body in why
    local normalized = sel:gsub("\r\n", "\n"):gsub("\r", "\n")
    local flat_title = normalized:gsub("\n+", " ")
    flat_title = (flat_title:gsub("^%s+", ""):gsub("%s+$", ""))
    local title = flat_title
    local body = normalized
    local ok, err = M.add_text(title, body)
    if not ok then
      vim.notify("TaskFlow: failed to add from selection: " .. tostring(err or "unknown"), vim.log.levels.ERROR)
      return
    end
    M.dashboard()
    vim.notify("Task added from selection")
  end, { desc = "TaskFlow Add From Visual" })
end

-- Auto-setup so commands exist when the module is required
pcall(function()
  M.setup()
end)
local function normalize_task(t)
  if not t.uid or #t.uid == 0 then
    t.uid = (t.id and ("id:" .. tostring(t.id)))
      or (t.title and t.created_at and ("t:" .. t.title .. ":" .. tostring(t.created_at)))
      or (t.title or "unknown") .. "-" .. tostring(math.random(1000, 9999))
  end
  return t
end

local function task_key(t)
  return t.uid or (t.id and ("id:" .. tostring(t.id))) or (t.title or "unknown")
end

local function last_ts(t)
  local maxv = 0
  local fields = { "created_at", "started_at", "completed_at", "due" }
  for _, k in ipairs(fields) do
    local v = t[k]
    if v and v > maxv then
      maxv = v
    end
  end
  return maxv
end

local function recompute_points_from_tasks(tasks)
  local total = 0
  for _, t in ipairs(tasks) do
    if t.status == "completed" then
      total = total + (t.points or 0)
    end
  end
  return total
end

function M.merge(path)
  load_state()
  local f = io.open(path, "r")
  if not f then
    vim.notify("Merge: cannot read " .. path, vim.log.levels.ERROR)
    return false
  end
  local content = f:read("*a")
  f:close()
  local ok, incoming = pcall(json_decode, content)
  if not ok or type(incoming) ~= "table" then
    vim.notify("Merge: invalid JSON", vim.log.levels.ERROR)
    return false
  end

  incoming.tasks = incoming.tasks or {}
  incoming.archive = incoming.archive or {}

  local map_local, map_in = {}, {}
  for _, t in ipairs(state.tasks) do
    normalize_task(t)
    map_local[task_key(t)] = t
  end
  for _, t in ipairs(incoming.tasks) do
    normalize_task(t)
    map_in[task_key(t)] = t
  end

  local keys = {}
  local seen = {}
  local function add_key(k)
    if not seen[k] then
      table.insert(keys, k)
      seen[k] = true
    end
  end
  for k, _ in pairs(map_local) do
    add_key(k)
  end
  for k, _ in pairs(map_in) do
    add_key(k)
  end

  local merged = {}
  local added, updated, kept = 0, 0, 0
  local added_list, updated_list, kept_list = {}, {}, {}
  for _, k in ipairs(keys) do
    local a = map_local[k]
    local b = map_in[k]
    if a and not b then
      table.insert(merged, a)
      kept = kept + 1
      table.insert(kept_list, fmt_task_line(a))
    elseif b and not a then
      table.insert(merged, b)
      added = added + 1
      table.insert(added_list, fmt_task_line(b))
    else
      local pick = (last_ts(a) >= last_ts(b)) and a or b
      if pick == b then
        updated = updated + 1
        table.insert(updated_list, fmt_task_line(b))
      else
        kept = kept + 1
        table.insert(kept_list, fmt_task_line(a))
      end
      table.insert(merged, pick)
    end
  end

  -- Merge archive similarly (append uniques)
  local arch_map = {}
  for _, t in ipairs(state.archive or {}) do
    normalize_task(t)
    arch_map[task_key(t)] = t
  end
  for _, t in ipairs(incoming.archive or {}) do
    normalize_task(t)
    if not arch_map[task_key(t)] then
      arch_map[task_key(t)] = t
    end
  end
  local merged_archive = {}
  for _, t in pairs(arch_map) do
    table.insert(merged_archive, t)
  end

  state.tasks = merged
  state.archive = merged_archive
  state.last_id = 0
  for _, t in ipairs(state.tasks) do
    if t.id and t.id > state.last_id then
      state.last_id = t.id
    end
  end
  state.points = recompute_points_from_tasks(state.tasks)
  -- rewards: union
  local rc = state.rewards_claimed or {}
  for k, v in pairs(incoming.rewards_claimed or {}) do
    rc[k] = rc[k] or v
  end
  state.rewards_claimed = rc

  save_state()
  local lines = {}
  table.insert(lines, string.format("Merge Report | added: %d | updated: %d | kept: %d", added, updated, kept))
  table.insert(lines, "")
  if #added_list > 0 then
    table.insert(lines, "Added:")
    for i = 1, math.min(#added_list, 20) do
      table.insert(lines, "  " .. added_list[i])
    end
    table.insert(lines, "")
  end
  if #updated_list > 0 then
    table.insert(lines, "Updated (picked newest):")
    for i = 1, math.min(#updated_list, 20) do
      table.insert(lines, "  " .. updated_list[i])
    end
    table.insert(lines, "")
  end
  if #kept_list > 0 then
    table.insert(lines, "Kept Local:")
    for i = 1, math.min(#kept_list, 20) do
      table.insert(lines, "  " .. kept_list[i])
    end
  end
  state.last_merge_report = { timestamp = now(), added = added, updated = updated, kept = kept, lines = lines }
  save_state()
  render_float(lines, "TaskFlow:MergeReport")
  vim.notify(string.format("Merge done: added %d, updated %d, kept %d", added, updated, kept))
  return true
end

-- return of module moved to end
function M.dashboard_history()
  load_state()
  local function collect_completed()
    local items = {}
    for _, t in ipairs(state.tasks) do
      if t.status == "completed" then
        table.insert(items, t)
      end
    end
    table.sort(items, function(a, b)
      return (a.completed_at or 0) > (b.completed_at or 0)
    end)
    return items
  end
  local function collect_archived()
    ensure_db()
    local rows = db_select(
      "SELECT id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog FROM archive ORDER BY completed_at DESC"
    )
    local items = {}
    for _, r in ipairs(rows) do
      table.insert(items, {
        id = tonumber(r.id),
        uid = r.uid,
        title = r.title,
        area = r.area,
        status = r.status,
        priority = r.priority,
        points = tonumber(r.points),
        reward = r.reward,
        impact = r.impact,
        why = r.why,
        created_at = tonumber(r.created_at),
        started_at = tonumber(r.started_at),
        completed_at = tonumber(r.completed_at),
        due = tonumber(r.due),
        backlog = tonumber(r.backlog) == 1,
      })
    end
    return items
  end
  local function collect_deleted()
    ensure_db()
    local rows = db_select(
      "SELECT id, uid, title, area, status, priority, points, reward, impact, why, created_at, started_at, completed_at, due, backlog FROM deleted ORDER BY created_at DESC"
    )
    local items = {}
    for _, r in ipairs(rows) do
      table.insert(items, {
        id = tonumber(r.id),
        uid = r.uid,
        title = r.title,
        area = r.area,
        status = r.status,
        priority = r.priority,
        points = tonumber(r.points),
        reward = r.reward,
        impact = r.impact,
        why = r.why,
        created_at = tonumber(r.created_at),
        started_at = tonumber(r.started_at),
        completed_at = tonumber(r.completed_at),
        due = tonumber(r.due),
        backlog = tonumber(r.backlog) == 1,
      })
    end
    return items
  end

  local function build_lines()
    local lines = {}
    local completed = collect_completed()
    local archived = collect_archived()
    local deleted = collect_deleted()
    table.insert(
      lines,
      string.format("History Dashboard | completed: %d | archived: %d | deleted: %d", #completed, #archived, #deleted)
    )
    table.insert(lines, string.format("Store: %s", get_data_path()))
    table.insert(lines, "---")
    table.insert(lines, "Completed:")
    for _, t in ipairs(completed) do
      table.insert(lines, fmt_task_line(t))
      if expanded and t.id and expanded[t.id] then
        table.insert(lines, "  Why:")
        local why = t.why or ""
        for s in tostring(why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "    " .. s)
          end
        end
        table.insert(lines, "")
      end
    end
    table.insert(lines, "")
    table.insert(lines, "Archived:")
    for _, t in ipairs(archived) do
      table.insert(lines, fmt_task_line(t))
      if expanded and t.id and expanded[t.id] then
        table.insert(lines, "  Why:")
        local why = t.why or ""
        for s in tostring(why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "    " .. s)
          end
        end
        table.insert(lines, "")
      end
    end
    table.insert(lines, "")
    table.insert(lines, "Deleted:")
    for _, t in ipairs(deleted) do
      table.insert(lines, fmt_task_line(t))
      if expanded and t.id and expanded[t.id] then
        table.insert(lines, "  Why:")
        local why = t.why or ""
        for s in tostring(why):gmatch("([^\n]*)\n?") do
          if s ~= nil then
            table.insert(lines, "    " .. s)
          end
        end
        table.insert(lines, "")
      end
    end
    table.insert(lines, "")
    table.insert(lines, "Controls: r=restore to active, <CR>=toggle details, q=close")
    return lines
  end

  local buf = render(build_lines(), "TaskFlow:History")
  pcall(vim.api.nvim_buf_set_option, buf, "bufhidden", "hide")
  local function id_at_cursor()
    local line = vim.api.nvim_get_current_line()
    local id = line:match("%[(%d+)%]")
    return id and tonumber(id) or nil
  end
  local function section_at_cursor()
    local row = (vim.api.nvim_win_get_cursor(0) or { 1, 0 })[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local current = ""
    for i = 1, math.min(row, #lines) do
      local l = lines[i]
      if l == "Completed:" or l == "Archived:" or l == "Deleted:" then
        current = l
      end
    end
    return current
  end
  local function redraw()
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    local new_lines = build_lines()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end
  local function buf_map(lhs, fn)
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
      return
    end
    vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true })
  end
  buf_map("<CR>", function()
    local id = id_at_cursor()
    if id then
      expanded = expanded or {}
      expanded[id] = not expanded[id]
      redraw()
    end
  end)
  buf_map("q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
  buf_map("r", function()
    local id = id_at_cursor()
    if not id then
      return
    end
    local section = section_at_cursor()
    if section == "Completed:" then
      M.reopen_completed(id)
    elseif section == "Archived:" then
      M.restore_archived(id)
    elseif section == "Deleted:" then
      M.restore_deleted(id)
    end
    load_state()
    redraw()
  end)
end
return M
