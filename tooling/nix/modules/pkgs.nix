{
  config,
  lib,
  withSystem,
  ...
}:
{
  _class = "flake"; # imports checking, optional
  flake.pkgs = lib.mapAttrs (
    system: config:
    # module arguments don't appear in config, so we use withSystem
    withSystem system ({ pkgs, ... }: pkgs)
  ) config.allSystems;
}
