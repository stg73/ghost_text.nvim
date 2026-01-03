local M = {}

local config = require("ghost_text.config")
local helper = require("ghost_text.helper")

function M.start()
    local use_script = config.use_script
    local binary_available = vim.fn.filereadable(config.binary_path) == 1
    local binary_version = vim.fn.readfile(config.installation_dir .. "binary_version")[1]
    local installed_binary_version
    if binary_available then
        installed_binary_version = vim.fn.readfile(config.binary_path .. ".version")[1]
    end

    if not use_script and (not binary_available or binary_version ~= installed_binary_version) then
        local target
        local function has(str)
            return vim.fn.has(str) == 1
        end
        if has("win64") then
            target = "win64"
        elseif has("mac") then
            target = "macos"
        elseif has("linux") then
            target = "linux"
        end

        require("ghost_text.installer").install(binary_version,target,M.enable)
    else
        M.enable()
        if not config.buffer then
            config.buffer = vim.api.nvim_create_buf(false,true)
            vim.api.nvim_buf_set_name(config.buffer,"[ghost-text]")
        end

        vim.api.nvim_create_autocmd('user',{
            group = vim.api.nvim_create_augroup('nvim_ghost_user_autocommands',{}),
            callback = function()
                vim.api.nvim_set_current_buf(config.buffer)
            end,
        })
    end
end

function M.stop()
    helper.server.session_closed()
    vim.api.nvim_clear_autocmds({ group = "nvim_ghost" })
    if not config.supports_focus then
        vim.api.nvim_clear_autocmds({ group = "_nvim_ghost_does_not_support_focus" })
    end
end

function M.enable()
    -- If we start the server, we are already focused, so we don't need to
    -- request_focus separately
    if not helper.server.is_running() then
        helper.server.start()
    else
        helper.server.request_focus()
    end

    local group = vim.api.nvim_create_augroup("nvim_ghost",{})
    vim.api.nvim_create_autocmd("FocusGained",{
        group = group,
        callback = helper.server.request_focus,
    })
    vim.api.nvim_create_autocmd("VimLeavePre",{
        group = group,
        callback = helper.server.session_closed,
    })

    vim.api.nvim_create_augroup("nvim_ghost_user_autocommands",{})

    -- Compatibility for terminals that do not support focus
    -- Uses CursorMoved to detect focus

    if not config.supports_focus then
        local focused = true
        local function focus_gained()
            if not focused then
                helper.server.request_focus()
                focused = true
            end
        end

        local group = vim.api.nvim_create_augroup("_nvim_ghost_does_not_support_focus",{})
        vim.api.nvim_create_autocmd({"CursorMoved","CursorMovedI"},{
            group = group,
            callback = focus_gained,
        })
        vim.api.nvim_create_autocmd({"CursorHold","CursorHoldI"},{
            group = group,
            callback = function()
                focused = false
            end,
        })
    end

    -- 単に指定されなかっただけであれば自動検出する
    if config.supports_focus == nil then
        vim.api.nvim_create_autocmd({"FocusGained","FocusLost"},{
            once = true,
            callback = function()
                config.supports_focus = true
                vim.api.nvim_clear_autocmds({ group = "_nvim_ghost_does_not_support_focus" })
            end
        })
    end

end

return M
