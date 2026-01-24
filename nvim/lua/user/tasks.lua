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

local data_path = vim.fn.stdpath("data") .. "/taskflow.json"

local state = {
  tasks = {},
  archive = {},
  points = 0,
  last_id = 0,
  rewards_claimed = {},
  archive_after_days = 14,
}

local function ensure_data_dir()
  local dir = vim.fn.fnamemodify(data_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

local function load_state()
  ensure_data_dir()
  local f = io.open(data_path, "r")
  if not f then
    return state
  end
  local content = f:read("*a")
  f:close()
  if not content or content == "" then
    return state
  end
  local ok, decoded = pcall(json_decode, content)
  if ok and type(decoded) == "table" then
    state = decoded
  end
  return state
end

local function save_state()
  ensure_data_dir()
  local f = io.open(data_path, "w")
  if not f then
    return false
  end
  f:write(json_encode(state))
  f:close()
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
  vim.api.nvim_buf_set_name(buf, title or "TaskFlow")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "taskflow")
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_set_current_buf(buf)
end

local function render_float(lines, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, title or 'TaskFlow')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'taskflow')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.7)
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'single',
  }
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
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
  local due = t.due and os.date("%Y-%m-%d", t.due) or "-"
  local why = (t.why and #t.why > 0) and (" | why: " .. t.why) or ""
  local impact = (t.impact and #t.impact > 0) and (" | impact: " .. t.impact) or ""
  local reward = (t.reward and #t.reward > 0) and (" | reward: " .. t.reward) or ""
  local pts = t.points or 0
  return string.format(
    "[%d] (%s/%s) %s | pts:%d | due:%s%s%s%s",
    t.id,
    t.area or "general",
    t.priority or "medium",
    t.title,
    pts,
    due,
    why,
    impact,
    reward
  )
end

function M.add(opts)
  load_state()
  opts = opts or {}
  local task = {
    id = (state.last_id or 0) + 1,
    uid = tostring(os.time()) .. '-' .. tostring(math.random(1000, 9999)),
    title = opts.title or "Untitled",
    why = opts.why or "",
    impact = opts.impact or "",
    reward = opts.reward or "",
    points = tonumber(opts.points) or 0,
    priority = opts.priority or "medium", -- low | medium | high
    area = opts.area or "general",
    status = "pending", -- pending | in_progress | completed
    backlog = opts.backlog or false,
    due = opts.due or (os.time() + 24 * 3600),
    created_at = now(),
  }
  table.insert(state.tasks, task)
  state.last_id = task.id
  save_state()
  return task
end

function M.start(id)
  load_state()
  local t = task_by_id(tonumber(id))
  if not t then
    return false, "Task not found"
  end
  t.status = "in_progress"
  t.started_at = now()
  save_state()
  return true
end

function M.complete(id)
  load_state()
  local t = task_by_id(tonumber(id))
  if not t then
    return false, "Task not found"
  end
  t.status = "completed"
  t.completed_at = now()
  state.points = (state.points or 0) + (t.points or 0)
  save_state()
  return true
end

function M.stop(id)
  load_state()
  local t = task_by_id(tonumber(id))
  if not t then
    return false, "Task not found"
  end
  t.status = "pending"
  t.started_at = nil
  save_state()
  return true
end

function M.set_backlog(id, mode)
  load_state()
  local t = task_by_id(tonumber(id))
  if not t then
    return false, "Task not found"
  end
  if mode == 'toggle' then
    t.backlog = not t.backlog
  else
    t.backlog = (mode == 'on')
  end
  save_state()
  return true
end

local function should_archive(t, days)
  local d = days or state.archive_after_days or 14
  if t.status ~= 'completed' then return false end
  local comp = t.completed_at or 0
  return (now() - comp) >= (d * 24 * 3600)
end

function M.archive(days)
  load_state()
  local keep = {}
  for _, t in ipairs(state.tasks) do
    if should_archive(t, days) then
      table.insert(state.archive, t)
    else
      table.insert(keep, t)
    end
  end
  state.tasks = keep
  save_state()
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

function M.dashboard()
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
  render(lines, "TaskFlow:Dashboard")
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
  table.insert(lines, '')
  table.insert(lines, 'UI Controls: s=start, x=complete, k=toggle backlog, w=weekly, r=rewards, q=close')
  local buf, _ = render_float(lines, 'TaskFlow:UI')
  local function id_at_cursor()
    local line = vim.api.nvim_get_current_line()
    local id = line:match('%[(%d+)%]')
    return id and tonumber(id) or nil
  end
  local function redraw()
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    -- re-render simplified dashboard in the same buffer
    local new_lines = {}
    table.insert(new_lines, string.format("TaskFlow Dashboard | points: %d", state.points or 0))
    table.insert(new_lines, "")
    table.insert(new_lines, "Important (top by score):")
    local important2 = {}
    for _, t in ipairs(state.tasks) do if t.priority == 'high' and t.status ~= 'completed' then table.insert(important2, t) end end
    table.sort(important2, function(a,b) return score_for(a) > score_for(b) end)
    for i = 1, math.min(#important2, 7) do table.insert(new_lines, '  ' .. fmt_task_line(important2[i])) end
    table.insert(new_lines, '')
    table.insert(new_lines, 'Backlog:')
    for _, t in ipairs(state.tasks) do if t.backlog and t.status ~= 'completed' then table.insert(new_lines, '  ' .. fmt_task_line(t)) end end
    table.insert(new_lines, '')
    table.insert(new_lines, 'In Progress:')
    for _, t in ipairs(state.tasks) do if t.status == 'in_progress' then table.insert(new_lines, '  ' .. fmt_task_line(t)) end end
    table.insert(new_lines, '')
    table.insert(new_lines, 'Completed (recent 5):')
    local completed2 = {}
    for _, t in ipairs(state.tasks) do if t.status == 'completed' then table.insert(completed2, t) end end
    table.sort(completed2, function(a,b) return (a.completed_at or 0) > (b.completed_at or 0) end)
    for i = 1, math.min(#completed2, 5) do table.insert(new_lines, '  ' .. fmt_task_line(completed2[i])) end
    table.insert(new_lines, '')
    table.insert(new_lines, 'UI Controls: s=start, x=complete, k=toggle backlog, w=weekly, r=rewards, q=close')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end
  local function buf_map(lhs, fn)
    vim.keymap.set('n', lhs, fn, { buffer = buf, silent = true })
  end
  buf_map('q', function() vim.api.nvim_buf_delete(buf, { force = true }) end)
  buf_map('s', function()
    local id = id_at_cursor(); if id then M.start(id); redraw() end
  end)
  buf_map('x', function()
    local id = id_at_cursor(); if id then M.complete(id); redraw() end
  end)
  buf_map('k', function()
    local id = id_at_cursor(); if id then M.set_backlog(id, 'toggle'); redraw() end
  end)
  buf_map('w', function() M.weekly_review() end)
  buf_map('r', function() M.rewards() end)
end

function M.weekly_review()
  load_state()
  local since = now() - 7 * 24 * 3600
  local lines = {}
  local total = 0
  local items = {}
  for _, t in ipairs(state.tasks) do
    if t.status == 'completed' and (t.completed_at or 0) >= since then
      total = total + (t.points or 0)
      table.insert(items, t)
    end
  end
  table.sort(items, function(a, b)
    return (a.completed_at or 0) > (b.completed_at or 0)
  end)
  table.insert(lines, string.format('Weekly Review | points earned: %d | completed: %d', total, #items))
  table.insert(lines, '')
  for i = 1, math.min(#items, 10) do
    local t = items[i]
    table.insert(lines, fmt_task_line(t))
  end
  table.insert(lines, '')
  table.insert(lines, 'Tip: Use :TodoArchive to auto-archive completed older than N days.')
  render(lines, 'TaskFlow:Weekly')
end

local default_rewards = {
  { threshold = 50, suggestion = 'Take a long walk or coffee treat' },
  { threshold = 100, suggestion = 'Buy a book or game' },
  { threshold = 200, suggestion = 'Plan a day trip' },
  { threshold = 400, suggestion = 'Weekend getaway' },
}

function M.rewards()
  load_state()
  local pts = state.points or 0
  local lines = {}
  table.insert(lines, string.format('Rewards | total points: %d', pts))
  table.insert(lines, '')
  for _, r in ipairs(default_rewards) do
    local claimed = state.rewards_claimed and state.rewards_claimed[tostring(r.threshold)]
    local status = claimed and '(claimed)' or ((pts >= r.threshold) and '(available)' or '(locked)')
    table.insert(lines, string.format(' - %d: %s %s', r.threshold, r.suggestion, status))
  end
  table.insert(lines, '')
  table.insert(lines, 'Claim with :TodoRewardClaim <threshold>')
  render(lines, 'TaskFlow:Rewards')
end

function M.reward_claim(threshold)
  load_state()
  local th = tostring(tonumber(threshold))
  if not th then return false, 'invalid threshold' end
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
    t.title = v1 or "Untitled"
    input("Why (motivation): ", "", function(v2)
      t.why = v2 or ""
      input("Impact (what happens if completed): ", "", function(v3)
        t.impact = v3 or ""
        input("Reward (what do you get/do): ", "", function(v4)
          t.reward = v4 or ""
          input("Points (effort/value): ", "3", function(v5)
            t.points = tonumber(v5) or 3
            input("Priority (low/medium/high): ", "medium", function(v6)
              t.priority = (v6 == "low" or v6 == "high") and v6 or "medium"
              input("Area (e.g. work/personal/health): ", "general", function(v7)
                t.area = v7 or "general"
                local tomorrow = os.date('%Y-%m-%d', os.time() + 24 * 3600)
                input("Due (YYYY-MM-DD): ", tomorrow, function(v8)
                  -- require due date; fallback to tomorrow if empty
                  local due_str = (v8 and #v8 > 0) and v8 or tomorrow
                  local y, m, d = due_str:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
                  local due_ts
                  if y and m and d then
                    local date_tbl = { year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 }
                    due_ts = os.time(date_tbl)
                  end
                  t.due = due_ts or (os.time() + 24 * 3600)
                  input("Backlog? (y/n): ", "n", function(v9)
                    t.backlog = (v9 == "y" or v9 == "Y")
                    M.add(t)
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
end

function M.setup()
  load_state()
  -- archive cleanup on setup
  M.archive(state.archive_after_days)
  vim.api.nvim_create_user_command("TodoAdd", function()
    M.add_interactive()
  end, {})
  vim.api.nvim_create_user_command("TodoList", function(opts)
    M.list(opts.args ~= "" and opts.args or nil)
  end, {
    nargs = "?",
    complete = function()
      return { "important", "backlog", "today", "in_progress", "completed", "all" }
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
    if ok then M.dashboard() end
  end, { nargs = 1 })
  vim.api.nvim_create_user_command("TodoBacklog", function(opts)
    local args = vim.split(opts.args, " ")
    local id = tonumber(args[1])
    local mode = args[2] or 'toggle'
    local ok = M.set_backlog(id, mode)
    if ok then M.dashboard() end
  end, { nargs = '+' })
  vim.api.nvim_create_user_command("TodoDashboard", function()
    M.dashboard()
  end, {})
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
    if ok then M.rewards() end
  end, { nargs = 1 })
  vim.api.nvim_create_user_command("TodoUI", function() M.open_ui() end, {})

  -- Keymaps: prefix <leader>jt*
  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true })
  end
  map('<leader>jtd', function() M.dashboard() end, 'TaskFlow Dashboard')
  map('<leader>jta', function() M.add_interactive() end, 'TaskFlow Add')
  map('<leader>jti', function() M.list('important') end, 'TaskFlow List Important')
  map('<leader>jtb', function() M.list('backlog') end, 'TaskFlow List Backlog')
  map('<leader>jtt', function() M.list('today') end, 'TaskFlow List Today')
  map('<leader>jtp', function() M.list('in_progress') end, 'TaskFlow List In Progress')
  map('<leader>jtc', function() M.list('completed') end, 'TaskFlow List Completed')
  map('<leader>jts', function()
    vim.ui.input({ prompt = 'Start task id:' }, function(val)
      if val then M.start(tonumber(val)); M.dashboard() end
    end)
  end, 'TaskFlow Start Task')
  map('<leader>jtx', function()
    vim.ui.input({ prompt = 'Complete task id:' }, function(val)
      if val then M.complete(tonumber(val)); M.dashboard() end
    end)
  end, 'TaskFlow Complete Task')
  map('<leader>jtk', function()
    vim.ui.input({ prompt = 'Backlog toggle id:' }, function(val)
      if val then M.set_backlog(tonumber(val), 'toggle'); M.dashboard() end
    end)
  end, 'TaskFlow Toggle Backlog')
  map('<leader>jtw', function() M.weekly_review() end, 'TaskFlow Weekly Review')
  map('<leader>jtr', function() M.rewards() end, 'TaskFlow Rewards')
  map('<leader>jtu', function() M.open_ui() end, 'TaskFlow UI')
end

-- Auto-setup so commands exist when the module is required
pcall(function() M.setup() end)

return M
