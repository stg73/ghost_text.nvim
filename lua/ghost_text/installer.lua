local M = {}

local helper = require("ghost_text.helper")

function M.install(callback)
    if helper.server.is_running() then
        helper.server.kill()
    end

    helper.notify('Downloading binary')

    local scripts_dir = require("ghost_text.config").scripts_dir
    local command
    if vim.fn.has('win32') == 1 then
        local powershell = "pwsh.exe"
        if vim.fn.executable("pwsh.exe") == 0 then
            powershell = "powershell.exe"
        end
        command = {powershell,"-File",scripts_dir .. 'install_binary.ps1'}
    else
        command = {scripts_dir .. 'install_binary.sh'}
    end

    vim.system(command,vim.schedule_wrap(function(job)
        local level
        if job.code ~= 0 then
            level = vim.log.levels.ERROR
        end
        vim.notify(job.stdout .. job.stderr,level)
        if job.code == 0 then
            helper.notify('Binary installed sucessfully')
            callback()
        else
            helper.notify('Binary installation failed (exit code: ' .. job.code .. ')',level)
        end
    end))
end

return M
