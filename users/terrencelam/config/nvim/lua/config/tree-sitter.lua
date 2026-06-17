local treesitter_languages = {
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitcommit',
  'gitignore',
  'kdl',
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
