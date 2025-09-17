{
  pkgs-pinned-unstable,
  ...
}:
{
  time.timeZone = "Asia/Tokyo";
  environment.systemPackages = with pkgs-pinned-unstable; [
    nkf
    libiconvReal
  ];
}
