vim.pack.add { 'https://github.com/hat0uma/csvview.nvim' }

require('csvview').setup {
  parser = { comments = { '#', '//' } },
  view = {
    display_mode = 'border',
  },
  keymaps = {
    -- Text objects for selecting fields
    textobject_field_inner = { 'if', mode = { 'o', 'x' } },
    textobject_field_outer = { 'af', mode = { 'o', 'x' } },
    -- Excel-like navigation:
    -- <Tab> / <S-Tab> move horizontally between fields.
    -- <Enter> / <S-Enter> move vertically between rows and place the cursor at the end of the field.
    -- Terminals may need CSI-u mode for <S-Tab> and <S-Enter>.
    jump_next_field_end = { '<Tab>', mode = { 'n', 'v' } },
    jump_prev_field_end = { '<S-Tab>', mode = { 'n', 'v' } },
    jump_next_row = { '<Enter>', mode = { 'n', 'v' } },
    jump_prev_row = { '<S-Enter>', mode = { 'n', 'v' } },
  },
}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('csvview-autoenable', { clear = true }),
  pattern = { 'csv', 'tsv' },
  callback = function(ev)
    require('csvview').enable(ev.buf)
  end,
})
