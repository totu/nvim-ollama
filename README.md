# [Ollama.ai](https://ollama.ai) client for [NeoVIM](https://neovim.io)


## Dependencies

1. Ollama server
2. [Curl](https://curl.se)
3. [Plenary](https://github.com/nvim-lua/plenary.nvim)

## Usage

1. Run ollama on your machine
2. call `:Ollama`

## Installation

Using [packer](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "totu/nvim-ollama",
    requires = { { "nvim-lua/plenary.nvim" } }
}
```

## Configuration / Setup

You can change `model` being queried as well as `address` and `port` of the ollama server.
By default `model=codellama` and server is `address=localhost`, `port=11434`.

Here is an example configuration:

```lua
local ollama = require("nvim-ollama")
ollama.setup({
    model = "codellama",
    address = "127.0.0.1",
    port = 11434,
})
```

You can bind ollama functions like this:

```lua
vim.keymap.set("n", "<leader>t", ":OllamaToggle<cr>")
vim.keymap.set("n", "<leader>o", ":Ollama<cr>")
```

## Functions

- Ollama : starts a chat with the ollama server
- OllamaHide : hides the ollama window
- OllamaShow : shows the ollama window
- OllamaToggle : toggles between showing and hiding the ollama window

## Example of use

!["Screenshot of ollama in action"](screen-shot.png)
