local curl = require("plenary.curl")
local M = {}
M.model = "codellama"
M.ns = vim.api.nvim_create_namespace(M.model)
M.curl = curl
M.generated = ""
M.width = 50

if M.buf == nil then
    local buf = vim.api.nvim_create_buf(false, true)
    M.buf = buf
    vim.api.nvim_buf_set_keymap(M.buf, "n", "<Esc>", ":OllamaStop<CR>", { noremap = true, silent = true })
end

-- Stop curl if Esc is pressed

function M.nl()
    M.generated = ""
    vim.api.nvim_buf_set_lines(M.buf, -1, -1, true, { "" })
    -- vim.api.nvim_win_set_cursor(M.win, { vim.api.nvim_buf_line_count(M.buf), 0 })
end

function M.stop()
    if M.job then
        M.job:shutdown()
    end
    if M.buf then
        vim.api.nvim_buf_set_lines(M.buf, -1, -1, true, { ">>> TERMINATED <<<" })
        local last_line = vim.api.nvim_buf_line_count(M.buf)
        vim.api.nvim_buf_add_highlight(M.buf, M.ns, "Comment", last_line - 1, 0, -1)
    end
end

function M.hide()
    if M.win then
        vim.api.nvim_win_hide(M.win)
    end
end

function M.toggle()
    if M.win ~= nil and vim.api.nvim_win_is_valid(M.win) then
        M.hide()
    else
        M.show()
    end
end

function M.show()
    if M.win ~= nil and vim.api.nvim_win_is_valid(M.win) then
        return
    end

    -- Create a new window for the chat
    local ui = vim.api.nvim_list_uis()[1]
    local col = 5
    if ui ~= nil then
        col = math.max(ui.width - 6, 0)
    end

    -- Create new window if it doesn't exist
    local win = vim.api.nvim_open_win(M.buf, false, {
        anchor = "NE",
        relative = "win",
        width = M.width,
        height = 20,
        col = col,
        row = 1,
        style = "minimal",
        border = "single",
        title = M.model,
        title_pos = "center",
    })
    M.win = win
end

function M.start_chat()
    -- Create a new buffer for the chat or use the existing one

    -- -- Stop curl if the window is closed
    -- vim.api.nvim_create_autocmd("WinClosed", {
    --     buffer = M.buf,
    --     callback = function()
    --         M.stop()
    --     end
    -- })

    -- Draw the buffer
    M.show()

    -- Main loop
    vim.ui.input({ prompt = ">>> " }, function(msg)
        -- Prep the buffer
        local prompt_line = vim.api.nvim_buf_line_count(M.buf)
        if prompt_line == 1 then
            prompt_line = 0
        else
            vim.api.nvim_buf_set_lines(M.buf, prompt_line, -1, true, { "" })
            prompt_line = prompt_line + 1
        end
        vim.api.nvim_buf_set_lines(M.buf, prompt_line, -1, true, { ">>> " .. msg })
        vim.api.nvim_buf_add_highlight(M.buf, M.ns, "Function", prompt_line, 0, -1)
        vim.api.nvim_buf_set_lines(M.buf, -1, -1, true, { "" })
        -- vim.api.nvim_win_set_cursor(M.win, { vim.api.nvim_buf_line_count(M.buf), 0 })

        --- Send the message to the server
        local json = { model = M.model, prompt = msg }
        M.job = M.curl.post("localhost:11434/api/generate", {
            body = vim.fn.json_encode(json),
            stream = function(_, resp)
                --- Handle the response
                vim.schedule(function()
                    local status, _ = pcall(function()
                        resp = vim.fn.json_decode(resp)
                    end)
                    if status then
                        local text = resp.response
                        if text ~= "\n" then
                            M.generated = M.generated .. text
                            if #M.generated > M.width - 10 then
                                M.nl()
                            end
                            local line = vim.api.nvim_buf_line_count(M.buf)
                            local last_line = vim.api.nvim_buf_get_lines(M.buf, line - 1, line, true)[1]
                            local column = #last_line
                            vim.api.nvim_buf_set_text(M.buf, line - 1, column, line - 1, column, { text })
                        else
                            M.nl()
                        end

                        if resp.done and M.buf then
                            vim.api.nvim_buf_set_lines(M.buf, -1, -1, true, { "" })
                            vim.api.nvim_buf_set_lines(M.buf, -1, -1, true, { ">>> DONE <<<" })
                            local last_line = vim.api.nvim_buf_line_count(M.buf)
                            vim.api.nvim_buf_add_highlight(M.buf, M.ns, "Comment", last_line - 1, 0, -1)
                            M.generated = ""
                        end
                    end
                end)
            end
        })
    end)
end

vim.api.nvim_create_user_command("Ollama", "lua require('ollama').start_chat()", {})
vim.api.nvim_create_user_command("OllamaStop", "lua require('ollama').stop()", {})
vim.api.nvim_create_user_command("OllamaHide", "lua require('ollama').hide()", {})
vim.api.nvim_create_user_command("OllamaShow", "lua require('ollama').show()", {})
vim.api.nvim_create_user_command("OllamaToggle", "lua require('ollama').toggle()", {})

return M