vim.pack.add {
	{ src = 'https://github.com/obsidian-nvim/obsidian.nvim', version = vim.version.range '*' },
	'https://github.com/MeanderingProgrammer/render-markdown.nvim',
}

require('render-markdown').setup {}

local docs_path = vim.env.NVIM_DOCUMENTATION_PATH
if not docs_path or docs_path == '' then
	docs_path = '~/Documents/github/documentation'
end

require('obsidian').setup {
	legacy_commands = false,
	workspaces = {
		{ name = 'documentation', path = docs_path },
	},
	picker = { name = 'telescope.nvim' },
	ui = { enable = false }
}

