vim.pack.add {
  { src = 'https://github.com/obsidian-nvim/obsidian.nvim', version = vim.version.range '*' },
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
}

require('obsidian').setup {
  legacy_commands = false,
  workspaces = {
    { name = 'notes', path = '~/Documents/notes' },
  },
  daily_notes = { folder = 'daily' },
  picker = { name = 'telescope.nvim' }, -- kickstart ships Telescope
  ui = { enable = false }, -- let render-markdown own the visuals
}

require('render-markdown').setup {}