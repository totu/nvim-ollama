# [Ollama.ai](https://ollama.ai) client for [NeoVIM](https://neovim.io)

## Dependencies

1. Ollama server
2. [Curl](https://curl.se)
3. [Plenary](https://github.com/nvim-lua/plenary.nvim)

## Usage

1. Run ollama on your machine
2. call `:Ollama`

## Setup

```
───────┼───────────────────────────────────────────────────────────────────────────────────────────
   1   │ local ollama = require("nvim-ollama")
   2   │ ollama.setup({
   3   │     model = "codellama",
   4   │     address = "127.0.0.1",
   5   │     port = 11434,
   6   │ })
   7   │ vim.keymap.set("n", "<leader>t", ":OllamaToggle<cr>")
   8   │ vim.keymap.set("n", "<leader>o", ":Ollama<cr>")
───────┴───────────────────────────────────────────────────────────────────────────────
```

## Example

!["Screenshot of ollama in action"](screen-shot.png)
