local map = vim.keymap.set

-- diagnostic
---@param next boolean
---@param severity? vim.diagnostic.Severity
local diagnostic_goto = function(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump({ count = next and 1 or -1, severity = severity })
  end
end
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
map('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
map('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic' })
map('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
map('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
map('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
map('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })

Snacks.toggle.option('spell', { name = 'Spelling' }):map('<leader>us')
Snacks.toggle.option('wrap', { name = 'Wrap' }):map('<leader>uw')
Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map('<leader>uL')
Snacks.toggle.diagnostics():map('<leader>ud')
Snacks.toggle.line_number():map('<leader>ul')
Snacks.toggle
  .option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = 'Conceal Level' })
  :map('<leader>uc')
Snacks.toggle
  .option('showtabline', { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = 'Tabline' })
  :map('<leader>uA')
Snacks.toggle.treesitter():map('<leader>uT')
Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map('<leader>ub')
Snacks.toggle.dim():map('<leader>uD')
Snacks.toggle.animate():map('<leader>ua')
Snacks.toggle.indent():map('<leader>ug')
Snacks.toggle.scroll():map('<leader>uS')
Snacks.toggle.profiler():map('<leader>dpp')
Snacks.toggle.profiler_highlights():map('<leader>dph')

if vim.lsp.inlay_hint then
  Snacks.toggle.inlay_hints():map('<leader>uh')
end

map('n', '<leader>rt', function()
  Snacks.terminal()
end, { desc = 'Terminal' })

-- Tig
map('n', '<leader>gs', function()
  Snacks.terminal('tig status')
end, { desc = 'Git Status' })

-- clipboard-write
map({ 'n', 'v' }, 'y', '"+y', { remap = false })
map({ 'n', 'v' }, 'd', '"+d', { remap = false })
map({ 'n', 'v' }, 'x', '"+x', { remap = false })
map({ 'n', 'v' }, 'X', '"+X', { remap = false })
map({ 'n', 'v' }, 'c', '"+c', { remap = false })
map({ 'n', 'v' }, 'C', '"+C', { remap = false })
map('n', 'p', '"+p', { remap = false })
map('n', 'P', '"+P', { remap = false })
map('n', 'dd', '"+dd', { remap = false })
