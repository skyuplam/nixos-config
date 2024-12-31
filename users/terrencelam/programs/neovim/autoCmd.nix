{
  programs.nixvim = {
    autoGroups = {
      redact_pass = {
        clear = true;
      };
    };
    autoCmd = [
      # redact_pass
      {
        event = "VimEnter";
        group = "redact_pass";
        desc = "Prevent leaks when editing encrypted passwords";
        pattern = [
          ''/dev/shm/pass.?*/?*.txt''
          ''$TMPDIR/pass.?*/?*.txt''
          ''/tmp/pass.?*/?*.txt''
          ''/private/var/?*/pass.?*/?*.txt''
        ];
        callback = {
          __raw = ''
            function()
              -- These are global options so we intentionally set them globally.
              vim.opt.backup = false
              vim.opt.writebackup = false
              vim.opt.swapfile = false
              vim.opt.shada = ""
              vim.opt.undofile = false
              vim.opt.shelltemp = false
              vim.opt.history = 0
              vim.opt.modeline = false
              vim.notify("pass: leaky options disabled")
            end
          '';
        };
      }
    ];
  };
}
