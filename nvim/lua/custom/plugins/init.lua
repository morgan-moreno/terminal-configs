-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Register custom plugins here. Order matters, so list them explicitly.
-- Uncomment the ones you want.

require 'custom.plugins.colors' -- fills ANSI-color gaps; nvim/init.lua relies on it

-- `documentation` and `notes` both configure obsidian.nvim and render-markdown.nvim.
-- Enable only ONE of them.
require 'custom.plugins.documentation'
-- require 'custom.plugins.notes'
