local M = {}

-- Config
M.use_script       = false
M.super_quiet      = false
M.logging_enabled  = false
M.server_port      = vim.env.GHOSTTEXT_SERVER_PORT or 4001

local function script_path()
  return debug.getinfo(2,'S').source:sub(2)
end
M.installation_dir   = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(script_path()))) .. "/"
M.scripts_dir        = M.installation_dir .. 'scripts' .. '/'

-- Files
M.script_path = M.installation_dir .. 'nvim-ghost-text.py'
M.binary_path = M.installation_dir .. 'nvim-ghost-text' .. ((vim.fn.has('win32') == 1) and '.exe' or '')

return M
