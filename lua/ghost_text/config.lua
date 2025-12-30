local M = {}

-- Config
M.use_script       = M.use_script or false
M.super_quiet      = M.super_quiet or false
M.logging_enabled  = M.logging_enabled or false
M.server_port      = M.server_port or vim.env.GHOSTTEXT_SERVER_PORT or 4001

local function script_path()
  return debug.getinfo(2,'S').source:sub(2)
end
M.installation_dir   = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(script_path()))) .. "/"
M.scripts_dir        = M.installation_dir .. 'scripts' .. '/'

-- Files
M.script_path = M.installation_dir .. 'binary.py'
M.binary_path = M.installation_dir .. 'nvim-ghost-binary' .. (vim.fn.has('win32') and '.exe' or '')

local function bool_to_number(x)
    if x then
        return 1
    else
        return 0
    end
end

-- Setup environment
vim.env.NVIM_LISTEN_ADDRESS        = vim.v.servername
vim.env.NVIM_GHOST_SUPER_QUIET     = bool_to_number(M.super_quiet)
vim.env.NVIM_GHOST_LOGGING_ENABLED = bool_to_number(M.logging_enabled)
vim.env.GHOSTTEXT_SERVER_PORT      = M.server_port

return M
