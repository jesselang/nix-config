# Reusable helpers for generating `home.file` entries from a dotfiles repo.
{ lib }:
let
  matchesAny = s: patterns: builtins.any (pat: builtins.match pat s != null) patterns;
  stripCtx = builtins.unsafeDiscardStringContext;

  listToHomeFileAttrs = items:
    builtins.listToAttrs (map (i: { inherit (i) name value; }) items);

  defaultExcludeTop = [ ".git" ".gitignore" ".github" "README.md" "LICENSE" ];

  mkHomeFilesFromDotfiles = {
    dotfiles,
    expandDirs ? [],
    excludeTop ? defaultExcludeTop,
    excludeMatch ? [],
  }:
  let
    top = builtins.readDir dotfiles;
    topNames = builtins.attrNames top;

    dotRoot = builtins.toString dotfiles;
    pref = "${dotRoot}/";
    relFromDot = abs:
      let s = builtins.toString abs;
          r = builtins.substring (builtins.stringLength pref)
                                 (builtins.stringLength s - builtins.stringLength pref) s;
      in
        # strip store-path context for use as the home.file target name.
        stripCtx r;

    topEntries = lib.filter (name: !(builtins.elem name excludeTop)) topNames;

    mkTopItem = name:
      let
        ty  = top.${name};
        rel = name;
        src = dotfiles + "/${rel}";
      in
        if ty == "directory" && builtins.elem name expandDirs then
          let
            files = lib.filesystem.listFilesRecursive src;
            kept  = lib.filter (p: let r = relFromDot p; in !matchesAny r excludeMatch) files;
          in
            map (p:
              let r = relFromDot p;
              in { name = r; value = { source = dotfiles + "/${r}"; }; }
            ) kept
        else if ty == "directory" then
          if matchesAny rel excludeMatch then [ ] else [
            { name = rel; value = { source = src; recursive = true; }; }
          ]
        else if ty == "regular" || ty == "symlink" then
          if matchesAny rel excludeMatch then [ ] else [
            { name = rel; value = { source = src; }; }
          ]
        else [ ];

    items = lib.concatMap mkTopItem topEntries;
  in
    listToHomeFileAttrs items;

  mkHomeFilesFor = dotfiles: files:
    lib.mapAttrs (target: spec:
      let
        s   = if builtins.isAttrs spec then spec else {};
        src = s.from or target;
        rest = builtins.removeAttrs s [ "from" ];
      in
        rest // { source = dotfiles + "/${src}"; }
    ) files;

  dotFor    = dotfiles: path: { source = dotfiles + "/${path}"; };
  dotDirFor = dotfiles: path: { source = dotfiles + "/${path}"; recursive = true; };

in {
  inherit defaultExcludeTop mkHomeFilesFromDotfiles mkHomeFilesFor dotFor dotDirFor;
}
