local M = {}

-- Config
vim.g.nvim_ghost_use_script       = vim.g.nvim_ghost_use_script or 0
vim.g.nvim_ghost_super_quiet      = vim.g.nvim_ghost_super_quiet or 0
vim.g.nvim_ghost_logging_enabled  = vim.g.nvim_ghost_logging_enabled or 0
vim.g.nvim_ghost_server_port      = vim.g.nvim_ghost_server_port or vim.env.GHOSTTEXT_SERVER_PORT or 4001

local function script_path()
  return debug.getinfo(2,'S').source:sub(2)
end
vim.g.nvim_ghost_installation_dir   = vim.fs.dirname(vim.fs.dirname(script_path())) .. "/"
vim.g.nvim_ghost_scripts_dir        = vim.g.nvim_ghost_installation_dir .. 'scripts' .. '/'

-- Files
vim.g.nvim_ghost_script_path = vim.g.nvim_ghost_installation_dir .. 'binary.py'
vim.g.nvim_ghost_binary_path = vim.g.nvim_ghost_installation_dir .. 'nvim-ghost-binary' .. (vim.fn.has('win32') and '.exe' or '')

-- Setup environment
vim.env.NVIM_LISTEN_ADDRESS        = vim.v.servername
vim.env.NVIM_GHOST_SUPER_QUIET     = vim.g.nvim_ghost_super_quiet
vim.env.NVIM_GHOST_LOGGING_ENABLED = vim.g.nvim_ghost_logging_enabled
vim.env.GHOSTTEXT_SERVER_PORT      = vim.g.nvim_ghost_server_port

-- Abort if script_mode is enabled but infeasible
if vim.g.nvim_ghost_use_script == 1 then
    if vim.fn.has("win32") == 1 then
        vim.notify("Sorry, g:nvim_ghost_use_script is currently not available on Windows. Please remove it from your init.vim to use nvim-ghost.",vim.log.levels.WARN)
    elseif vim.g.nvim_ghost_python_executable == 0 then
        vim.notify("Please set g:nvim_ghost_python_executable to the location of the python executable",vim.log.levels.WARN)
    end
end

function M.start()
    vim.fn["nvim_ghost#init"](0)
end

function M.stop()
    vim.fn["nvim_ghost#disable"]()
end

return M
