local M = {}

local function notify(msg,opts)
    vim.notify("[nvim-ghost] " .. msg,opts)
end

function M.install(callback)
    if vim.fn["nvim_ghost#helper#is_running"]() then
        vim.fn["nvim_ghost#helper#kill_server"]()
    end

    notify('Downloading binary')

    local command
    if vim.fn.has('win32') == 1 then
        local powershell = "pwsh.exe"
        if vim.fn.executable("pwsh.exe") == 0 then
            powershell = "powershell.exe"
        end
        command = {powershell,"-File",vim.g.nvim_ghost_scripts_dir .. 'install_binary.ps1'}
    else
        command = {vim.g.nvim_ghost_scripts_dir .. 'install_binary.sh'}
    end

    vim.system(command,vim.schedule_wrap(function(job)
        local level
        if job.code ~= 0 then
            level = vim.log.levels.ERROR
        end
        vim.notify(job.stdout .. job.stderr,level)
        if job.code == 0 then
            notify('Binary installed sucessfully')
            callback()
        else
            notify('Binary installation failed (exit code: ' .. job.code .. ')',level)
        end
    end))
end

return M
