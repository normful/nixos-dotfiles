{ lib, ... }:
{
  options.my.isFirstInstall = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether this is the first installation of the system";
  };
}
