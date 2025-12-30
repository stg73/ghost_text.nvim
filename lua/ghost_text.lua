local M = {}

local config = require("ghost_text.config")

-- Abort if script_mode is enabled but infeasible
if config.use_script then
    if vim.fn.has("win32") == 1 then
        vim.notify("Sorry, g:nvim_ghost_use_script is currently not available on Windows. Please remove it from your init.vim to use nvim-ghost.",vim.log.levels.WARN)
    elseif not config.python_executable then
        vim.notify("Please set g:nvim_ghost_python_executable to the location of the python executable",vim.log.levels.WARN)
    end
end

function M.start()
    local use_script = config.use_script
    local binary_available = vim.fn.filereadable(config.binary_path) == 1
    local versions_differ
    if binary_available then
        versions_differ =
        vim.fn.readfile(config.installation_dir .. "binary_version")[0] ~=
        vim.fn.readfile(config.binary_path .. ".version")[0]
    end

    if use_script and (not binary_available or versions_differ) then
        vim.fn["nvim_ghost#installer#install"](M.enable)
    else
        M.enable()
    end
end

local function start_server_or_request_focus()
    -- If we start the server, we are already focused, so we don't need to
    -- request_focus separately
    if not vim.fn["nvim_ghost#helper#is_running"]() then
        vim.fn["nvim_ghost#helper#start_server"]()
    else
        vim.fn["nvim_ghost#helper#request_focus"]()
    end
end

function M.stop()
    vim.fn["nvim_ghost#helper#session_closed"]()
    vim.api.nvim_clear_autocmds({ group = "nvim_ghost"} )
    if not vim.g._nvim_ghost_supports_focus then
        vim.api.nvim_clear_autocmds({ group = "_nvim_ghost_does_not_support_focus" })
    end
end

function M.enable()
    start_server_or_request_focus()

    local group = vim.api.nvim_create_augroup("nvim_ghost",{})
    vim.api.nvim_create_autocmd("FocusGained",{
        group = group,
        callback = function()
            vim.fn["nvim_ghost#helper#request_focus"]()
        end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre",{
        group = group,
        callback = function()
            vim.fn["nvim_ghost#helper#session_closed"]()
        end,
    })

    vim.api.nvim_create_augroup("nvim_ghost_user_autocommands",{})

    -- Compatibility for terminals that do not support focus
    -- Uses CursorMoved to detect focus

    if not config.supports_focus then
        config.supports_focus = false

        -- vint: next-line -ProhibitAutocmdWithNoGroup
        vim.api.nvim_create_autocmd({"FocusGained","FocusLost"},{
            once = true,
            callback = function()
                config.supports_focus = true
                vim.api.nvim_clear_autocmds({ group = "_nvim_ghost_does_not_support_focus" })
            end
        })

        local focused = true
        local function focus_gained()
            if not focused then
                vim.fn["nvim_ghost#helper#request_focus"]()
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
end

return M
