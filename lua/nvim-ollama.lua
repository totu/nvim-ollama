local curl = require("plenary.curl")
local ollama = {}
ollama.model = "codellama"
ollama.address = "localhost"
ollama.port = 11434
ollama.ns = vim.api.nvim_create_namespace(ollama.model)
ollama.curl = curl
ollama.width = 50
ollama.context = {}

if ollama.buf == nil then
    local buf = vim.api.nvim_create_buf(false, true)
    ollama.buf = buf
    vim.api.nvim_buf_set_keymap(ollama.buf, "n", "<Esc>", ":OllamaStop<CR>", { noremap = true, silent = true })
end

function ollama.setup(opts)
    if opts.model then
        ollama.model = opts.model
    end

    if opts.address then
        ollama.address = opts.address
    end

    if opts.port then
        ollama.port = opts.port
    end
end

function ollama.nl()
    vim.api.nvim_buf_set_lines(ollama.buf, -1, -1, true, { "" })
    if ollama.win and ollama.win ~= nil and vim.api.nvim_win_is_valid(ollama.win) then
        vim.api.nvim_win_set_cursor(ollama.win, { vim.api.nvim_buf_line_count(ollama.buf), 0 })
    end
end

function ollama.stop()
    if ollama.job then
        ollama.job:shutdown()
    end
    if ollama.buf then
        vim.api.nvim_buf_set_lines(ollama.buf, -1, -1, true, { ">>> TERMINATED <<<" })
        local last_line = vim.api.nvim_buf_line_count(ollama.buf)
        vim.api.nvim_buf_add_highlight(ollama.buf, ollama.ns, "Comment", last_line - 1, 0, -1)
    end
end

function ollama.hide()
    if ollama.win and ollama.win ~= nil and vim.api.nvim_win_is_valid(ollama.win) then
        vim.api.nvim_win_hide(ollama.win)
    end
end

function ollama.toggle()
    if ollama.win ~= nil and vim.api.nvim_win_is_valid(ollama.win) then
        ollama.hide()
    else
        ollama.show()
    end
end

function ollama.show()
    if ollama.win ~= nil and vim.api.nvim_win_is_valid(ollama.win) then
        return
    end

    -- Create a new window for the chat
    local ui = vim.api.nvim_list_uis()[1]
    local col = 5
    if ui ~= nil then
        col = math.max(ui.width - 6, 0)
    end

    -- Create new window if it doesn't exist
    local win = vim.api.nvim_open_win(ollama.buf, false, {
        anchor = "NE",
        relative = "win",
        width = ollama.width,
        height = 20,
        col = col,
        row = 1,
        style = "minimal",
        border = "single",
        title = ollama.model,
        title_pos = "center",
    })
    ollama.win = win

    -- Scroll to bottom on enter
    vim.api.nvim_win_set_option(ollama.win, "scrolloff", 0)
    vim.api.nvim_win_set_option(ollama.win, "sidescrolloff", 0)
    vim.api.nvim_win_set_option(ollama.win, "wrap", true)
    vim.api.nvim_win_set_option(ollama.win, "breakindent", false)
    vim.api.nvim_win_set_option(ollama.win, "number", false)
    vim.api.nvim_win_set_option(ollama.win, "relativenumber", false)

    vim.api.nvim_create_autocmd("BufEnter", {
        buffer = ollama.buf,
        callback = function()
            if ollama.win ~= nil and vim.api.nvim_win_is_valid(ollama.win) then
                vim.api.nvim_win_set_cursor(ollama.win, { vim.api.nvim_buf_line_count(ollama.buf), 0 })
            end
        end
    })

    vim.cmd("hi clear statuslinenc")

end

function ollama.start_chat()
    -- Create a new buffer for the chat or use the existing one

    -- -- Stop curl if the window is closed
    -- vim.api.nvim_create_autocmd("WinClosed", {
    --     buffer = M.buf,
    --     callback = function()
    --         M.stop()
    --     end
    -- })


    -- Main loop
    vim.ui.input({ prompt = ">>> " }, function(msg)
        if msg == nil or msg == "" then
            return
        end
        -- Draw the buffer
        ollama.show()
        -- Prep the buffer
        local prompt_line = vim.api.nvim_buf_line_count(ollama.buf)
        if prompt_line == 1 then
            prompt_line = 0
        else
            vim.api.nvim_buf_set_lines(ollama.buf, prompt_line, -1, true, { "" })
            prompt_line = prompt_line + 1
        end
        vim.api.nvim_buf_set_lines(ollama.buf, prompt_line, -1, true, { ">>> " .. msg })
        vim.api.nvim_buf_add_highlight(ollama.buf, ollama.ns, "Function", prompt_line, 0, -1)
        vim.api.nvim_buf_set_lines(ollama.buf, -1, -1, true, { "" })
        if ollama.win ~= nil and vim.api.nvim_win_is_valid(ollama.win) then
            vim.api.nvim_win_set_cursor(ollama.win, { vim.api.nvim_buf_line_count(ollama.buf), 0 })
        end

        --- Send the message to the server
        local json = { model = ollama.model, prompt = msg, context = ollama.context }
        local address = ollama.address .. ":" .. ollama.port
        ollama.job = ollama.curl.post(address .. "/api/generate", {
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
                            local line = vim.api.nvim_buf_line_count(ollama.buf)
                            local last_line = vim.api.nvim_buf_get_lines(ollama.buf, line - 1, line, true)[1]
                            local column = #last_line
                            vim.api.nvim_buf_set_text(ollama.buf, line - 1, column, line - 1, column, { text })
                        else
                            ollama.nl()
                        end

                        if resp.done and ollama.buf then
                            ollama.context = resp.context
                            vim.api.nvim_buf_set_lines(ollama.buf, -1, -1, true, { "" })
                            vim.api.nvim_buf_set_lines(ollama.buf, -1, -1, true, { ">>> DONE <<<" })
                            local last_line = vim.api.nvim_buf_line_count(ollama.buf)
                            vim.api.nvim_buf_add_highlight(ollama.buf, ollama.ns, "Comment", last_line - 1, 0, -1)
                            if ollama.win ~= nil and vim.api.nvim_win_is_valid(ollama.win) then
                                vim.api.nvim_win_set_cursor(ollama.win, { vim.api.nvim_buf_line_count(ollama.buf), 0 })
                            end
                        end
                    end
                end)
            end
        })
    end)
end

vim.api.nvim_create_user_command("Ollama", "lua require('nvim-ollama').start_chat()", {})
vim.api.nvim_create_user_command("OllamaStop", "lua require('nvim-ollama').stop()", {})
vim.api.nvim_create_user_command("OllamaHide", "lua require('nvim-ollama').hide()", {})
vim.api.nvim_create_user_command("OllamaShow", "lua require('nvim-ollama').show()", {})
vim.api.nvim_create_user_command("OllamaToggle", "lua require('nvim-ollama').toggle()", {})

return ollama
