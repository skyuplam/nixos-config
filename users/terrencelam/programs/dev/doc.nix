{
  pkgs,
  lib,
  ...
}: {
  programs = {
    nixvim = {
      plugins = {
        render-markdown = {
          enable = true;
        };
        lsp.servers = {
          marksman = {
            enable = true;
            settings.formatting.command = [
              (lib.getExe pkgs.marksman)
            ];
          };

          harper_ls = {
            enable = true;

            settings = {
              "harper-ls" = {
                linters = {
                  spell_check = true;
                  spelled_numbers = false;
                  an_a = true;
                  sentence_capitalization = true;
                  unclosed_quotes = true;
                  wrong_quotes = false;
                  long_sentences = true;
                  repeated_words = true;
                  spaces = true;
                  matcher = true;
                  correct_number_suffix = true;
                  number_suffix_capitalization = true;
                  multiple_sequential_pronouns = true;
                  linking_verbs = false;
                  avoid_curses = true;
                  terminating_conjunctions = true;
                };
              };
            };
          };
        };

        hmts.enable = true;

        conform-nvim = {
          settings = {
            formatters_by_ft = {
              markdown = ["prettier"];
            };
          };
        };
      };
    };
  };
}
