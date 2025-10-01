-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load all lua files in user directory
local user_dir = vim.fn.stdpath("config") .. "/lua/user"
local uv = vim.loop

local function load_lua_files(dir)
    local handle = uv.fs_scandir(dir)
    if not handle then return end
    while true do
        local name, typ = uv.fs_scandir_next(handle)
        if not name then break end
        local path = dir .. "/" .. name
        if typ == "file" and name:sub(-4) == ".lua" then
            local mod = "user." .. name:sub(1, -5)
            pcall(require, mod)
        elseif typ == "directory" then
            load_lua_files(path)
        end
    end
end

load_lua_files(user_dir)
