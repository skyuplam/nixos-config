{
  programs.nixvim = {
    globals = {
      # Disable useless providers
      loaded_ruby_provider = 0; # Ruby
      loaded_perl_provider = 0; # Perl
      loaded_python_provider = 0; # Python 2
    };

    clipboard.register = "unnamedplus";

    diagnostics = {
      severity_sort = true;
      signs = true;
      underline = true;
      update_in_insert = false;
      virtual_text = false;
      virtual_lines = {
        highlight_whole_line = false;
        only_current_line = true;
      };
    };

    opts = {
      # Window splitting
      splitbelow = true;
      splitright = true;
      # Match and Search
      ignorecase = true;
      smartcase = true;
      wrapscan = true; # Searches wrap around the end of the file
      scrolloff = 9;
      sidescrolloff = 10;
      sidescroll = 1;
      # List chars
      list = true;
      listchars = {
        eol = null;
        tab = "› ";
        extends = "»";
        precedes = "«";
        nbsp = ".";
        lead = ".";
        trail = "•";
      };
      # Indentation
      wrap = false;
      wrapmargin = 2;
      textwidth = 80;
      autoindent = true;
      shiftround = true;
      expandtab = true;
      shiftwidth = 2;
      encoding = "utf-8";
      fileencoding = "utf-8";

      # Line Number
      relativenumber = true;
      number = true;

      termguicolors = true;
      virtualedit = "block";

      # Timing
      updatetime = 300;
      timeout = true;
      timeoutlen = 500;
      ttimeoutlen = 10;
      # Display

      shortmess = {
        t = true; # truncate file messages at start
        A = true; # ignore annoying swap file messages
        o = true; # file-read message overwrites previous
        O = true; # file-read message overwrites previous
        T = true; # truncate non-file messages in middle
        f = true; # (file x of x) instead of just (x of x
        F = true; # Don't give file info when editing a file, NOTE: this breaks autocommand messages
        s = true; # No search end msg
        c = true; # No completion msg
        W = true; # Don't show [w] or written when writing
      };
      conceallevel = 2;
      breakindentopt = "sbr";
      linebreak = true; # lines wrap at words rather than random characters
      synmaxcol = 300; # don't syntax highlight long lines
      signcolumn = "number";
      ruler = false;
      cmdheight = 0;
      showbreak = "↪ "; # Options include -> '…', '↳ ', '→','↪ '
      title = true;

      jumpoptions = "stack";

      inccommand = "nosplit";
      incsearch = true;
      showmode = false;

      # persist
      swapfile = {
        __raw = ''
          vim.fn.exists('$SUDO_USER') > 0 and false or true
        '';
      };
      backup = {
        __raw = ''
          vim.fn.exists('$SUDO_USER') > 0 and false or true
        '';
      };
      writebackup = {
        __raw = ''
          vim.fn.exists('$SUDO_USER') > 0 and false or true
        '';
      };
      backupcopy = "auto";
      backupdir = {__raw = ''vim.fn.expand("$XDG_DATA_HOME/nvim/backup//")'';};
      undofile = {
        __raw = ''
          vim.fn.exists('$SUDO_USER') > 0 and false or true
        '';
      };
      # Defaults:
      #   Neovim: !,'100,<50,s10,h
      # - ! save/restore global variables (only all-uppercase variables)
      # - '100 save/restore marks from last 100 files
      # - /10000 Maximum number of itemsIN the search pattern history to be saved
      # - <500 save/restore 500 lines from each register
      # - s10 max item size 10KB
      # - h do not save/restore 'hlsearch' setting
      shada = {
        __raw = ''
          vim.fn.exists('$SUDO_USER') > 0 and "" or "!,'100,/10000,<500,s10,h"
        '';
      };
    };
  };
}
