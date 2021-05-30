{metafun, writeScriptBin}:
let
  mk-help = hook: {
    desc = "Show this help.";
    inherit hook; };
in
  writeScriptBin "textgen" (metafun.mkCommand "textgen" {
    desc = "Generate textgen documents.";
    opts = { help = mk-help "exec textgen help";};
    commands = {
      generate =
        let
          set-out = {
            desc =
              ''Use specific output path instead of one based on input
                <attribute>.'';
            hook = _: ''textgen_out="$1"'';
          };
          pre-out = {
            desc =
              ''Prepend to (<attribute> based) output path.'';
            hook = _: ''textgen_out_prefix="$1"'';
          };
          pre-attr = {
            desc =
              ''Prepend to input <attribute>. (Not refelcted in output path)'';
            hook = _: ''textgen_attr_prefix="$1"'';
          };
        in {
        desc = "Create file(s) from a textgen generated text.";
        opts = {
          help = mk-help "exec textgen generate help";
          o = set-out;
          out = set-out;
          p = pre-out;
          prepend-out = pre-out;
          a = pre-attr;
          prepend-attribute = pre-attr;
          no-copy = {
            desc = "Just return /nix/store link for resulting texts.";
            hook = "no_copy=true";
            };
        };
        args = ["file" "attribute"];
        hook = ''
          file="$1"
          attr="$2"
          attr_out_path="''${textgen_out_prefix}$(echo $attr | tr . / )"
          textgen_out=''${textgen_out:=$attr_out_path}
          attr="''${textgen_attr_prefix}$2"

          [[ -e $textgen_out ]] && rm -r $textgen_out
          nix-build --attr "$attr" --out-link $textgen_out $file

          [[ $no_copy == true ]] || textgen copy-result $textgen_out
          '';
        };
      copy-result = {
        desc = ''Replace a nix-build "result" link with the linked files.'';
        opts = {
          help = mk-help "textgen copy-results help";
          };
        args = ["file"];
        hook = ''
          if [[ -L $1 ]]; then
            store=$(realpath $1)
            rm $1
            mkdir -p $1
            cp -rL $store/* $1
            chmod -R +w $1
          fi
          '';
      };
    };
  }
  )
