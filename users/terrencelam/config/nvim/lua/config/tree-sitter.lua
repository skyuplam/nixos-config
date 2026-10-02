-- Keep Nix-managed queries isolated from directories created by plugins or
-- local query overrides, while giving the parser-matched queries priority.
vim.opt.runtimepath:prepend(vim.fn.stdpath('config') .. '/nix-treesitter')

local treesitter_languages = {
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitcommit',
  'gitignore',
  'just',
  'kdl',
  'markdown',
  'markdown_inline',
  'python',
  'rust',
  'toml',
  'wgsl',
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = treesitter_languages,

  callback = function(ev)
    local filetype = vim.bo[ev.buf].filetype
    vim.treesitter.start(ev.buf, filetype)
  end,
})
