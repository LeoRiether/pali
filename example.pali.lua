-- Put something like this in ~/.config/pali.lua

local M = {
    -- Whenever a package below is added or removed, yay.add/yay.remove is
    -- executed
    yay = {
        add = 'yay -S',
        remove = 'yay -Rs',

        -- CLI
        'neovim', 'ripgrep', 'trash-cli',

        -- programming languages
        'lua',

        -- media
        'mpv', 'gwenview', 'krita',

        -- random
        'lolcat', 'bash-pipes', 'sl', 'cowsay',
    },

    pip = {
        add = 'python3 -m pip install',
        remove = 'python3 -m pip uninstall',
        'numpy', 'matplotlib'
    },

    -- "cmd"s don't have a list of packages to install, instead they execute
    -- `add` and `remove` when the entry is added/removed 
    fzf = {
        cmd = true,
        add = 'git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install',
        remove = 'rm -r ~/.fzf',
    },
}

return M
