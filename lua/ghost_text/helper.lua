local M = {}

local config = require("ghost_text.config")

function M.notify(msg,level)
    vim.notify("[nvim-ghost] " .. msg,level)
end

function M.log(msg,level)
    if config.logging_enabled then
        M.notify(msg,level)
    end
end

is_windows = vim.fn.has("win32") == 1

local localhost
if is_windows then
    localhost = '127.0.0.1'
else
    localhost = 'localhost'
end

local saved_updatetime = vim.o.updatetime
local can_use_cursorhold = false

M.server = {}

function M.server.is_running()
    local authority = localhost .. ':' .. config.server_port
    local opts = { data_buffered = true }
    local ok,connection = pcall(vim.fn.sockconnect,'tcp',authority,opts)
    if ok and connection ~= 0 then
        vim.fn.chanclose(connection)
        return true
    else
        return false
    end
end

local function bool_to_number(x)
    if x then
        return 1
    else
        return 0
    end
end

function M.server.start()
    local command
    if config.use_script then
        command = { config.python_executable or "python", config.script_path }
    else
        if is_windows then
            command = { "cscript.exe", config.scripts_dir .. "start_server.vbs" }
        else
            command = { config.binary_path }
        end
    end

    if command then
        vim.system(command,{
            detach = true,
            cwd = config.installation_dir,
            env = {
                NVIM_GHOST_SUPER_QUIET = bool_to_number(M.super_quiet),
                NVIM_GHOST_LOGGING_ENABLED = bool_to_number(M.logging_enabled),
                GHOSTTEXT_SERVER_PORT = M.server_port,
            },
            stdout = vim.schedule_wrap(function(_,data)
                if data then
                    M.log(vim.trim(data))
                end
            end),
            stderr = vim.schedule_wrap(function(_,data)
                if data then
                    M.log(vim.trim(data))
                end
            end),
        })
    end
end

function M.server.restart()
    M.server.kill()
    M.server.start()
end

local function send_GET_request(path)
    local authority = localhost .. ':' .. config.server_port
    vim.net.request(authority .. path,{},vim.schedule_wrap(function(errmsg,x)
        if x then
            M.log("Sent " .. path)
        else
            M.log("Could not connect to " .. authority,vim.log.levels.WARN)
        end
    end))
end

function M.server.kill()
    send_GET_request('/exit')
end

function M.server.request_focus()
    send_GET_request('/focus?focus=' .. vim.v.servername)
end

function M.server.session_closed()
    send_GET_request('/session-closed?session=' .. vim.v.servername)
    vim.fn.rpcnotify(0,"nvim_ghost_exit_event")
end

return M
