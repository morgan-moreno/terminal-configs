-- Fill the gaps the built-in `default` scheme leaves under `notermguicolors`.
-- cterm indices 0-15 are the active iTerm2 profile's ANSI slots, so only ctermfg/ctermbg are set here.
-- Slot 8 (bright black) is unreadable as text on lucario-default (1.07:1), so it is used for backgrounds only.
-- On the -light profiles slot 8 is a mid-dark gray, so dark text on it is unreadable. There the subtle background
-- is a fixed light xterm-256 gray instead, which is not part of the profile palette.

local function apply_overrides()
  local light = vim.o.background == 'light'
  local subtle_bg = light and 254 or 8
  local groups = {
    Comment = { ctermfg = 6 },
    CursorLine = { ctermbg = subtle_bg },
    ColorColumn = { ctermbg = subtle_bg },
    Pmenu = { ctermbg = subtle_bg, ctermfg = light and 0 or 7 },
    PmenuSel = { ctermbg = 0, ctermfg = 15, reverse = false },
    NormalFloat = { ctermbg = subtle_bg },
    PmenuThumb = { ctermbg = 7 },
    FloatBorder = { ctermbg = subtle_bg, ctermfg = 4 },
    -- The default scheme gives these RGB-only values, which would otherwise render as plain terminal default.
    StatusLine = { reverse = true },
    StatusLineNC = { ctermbg = subtle_bg },
    LineNr = { ctermfg = 4 },
    NonText = { ctermfg = 4 },
    Conceal = { ctermfg = 4 },
    Folded = { ctermbg = subtle_bg },
    MatchParen = { ctermbg = subtle_bg, bold = true },
    Todo = { ctermfg = 0, ctermbg = 3 },
  }
  for name, spec in pairs(groups) do
    -- Clear the default's guifg/guibg so nothing RGB leaks in if termguicolors is ever toggled on.
    vim.api.nvim_set_hl(0, name, vim.tbl_extend('force', { fg = 'NONE', bg = 'NONE' }, spec))
  end
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('custom-ansi-colors', { clear = true }),
  callback = apply_overrides,
})
-- Terminal background detection can resolve after startup, so re-apply when it changes.
vim.api.nvim_create_autocmd('OptionSet', {
  group = vim.api.nvim_create_augroup('custom-ansi-colors-background', { clear = true }),
  pattern = 'background',
  callback = apply_overrides,
})
apply_overrides()
