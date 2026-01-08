local M = {}

local helper = require("ghost_text.helper")
local config = require("ghost_text.config")

function M.install(version,target,callback)
    if helper.server.is_running() then
        helper.notify("Binary still running",vim.log.levels.WARN)
        helper.notify('Please run require("ghost_text.helper").server.kill() in neovim',vim.log.levels.WARN)
        return
    end

    -- v0.0.0 と 0.0.0 の両方の形式を許容
    version = string.gsub(version,"^v","")

    local archive_extension,binary
    if target == "win64" then
        archive_extension = ".zip"
        binary = "nvim-ghost-text.exe"
    elseif (target == "macos") or (target == "linux") then
        archive_extension = ".tar.gz"
        binary = "nvim-ghost-text"
    else
        local your_system
        if type(target) == "string" then
            your_system = '"' .. target .. '"'
        else
            your_system = "your system"
        end
        helper.notify('nvim-ghost does not have pre-built binaries for ' .. your_system,vim.log.levels.WARN)
        return
    end

    local archive = "nvim-ghost-" .. target .. archive_extension
    local download_url = "https://github.com/stg73/ghost_text.nvim/releases/download/v" .. version .. "/" .. archive

    local on_response = vim.schedule_wrap(function(errmsg)
        if errmsg then
            helper.notify("Could not download binary",vim.log.levels.ERROR)
        else
            helper.notify("Downloaded binary")

            vim.fs.rm(config.installation_dir .. binary,{ force = true })
            vim.fs.rm(config.installation_dir .. binary .. ".version",{ force = true })

            local extract
            if target == "win64" then
                extract = {"pwsh","-NoProfile","-Command","Expand-Archive",archive,"."}
            else
                extract = {"tar","xzf",archive}
            end

            local on_exit = vim.schedule_wrap(function(o)
                if o.code ~= 0 then
                    helper.notify("Binary installation failed (exit code: " .. o.code .. ")",vim.log.levels.ERROR)
                    helper.notify("stderr: " .. o.stderr,vim.log.levels.ERROR)
                else
                    vim.fs.rm(config.installation_dir .. archive)
                    if target ~= "win64" then
                        vim.uv.fs_chmod(config.installation_dir .. binary,tonumber("777",8))
                    end

                    helper.notify('Binary installed sucessfully')

                    if callback then
                        callback()
                    end
                end
            end)

            vim.system(extract,{ cwd = config.installation_dir },on_exit)
        end
    end)

    vim.net.request(download_url,{ outpath = config.installation_dir .. archive },on_response)
end

return M
