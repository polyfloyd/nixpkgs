# generated by zon2nix (https://github.com/nix-community/zon2nix)

{ linkFarm, fetchzip }:

linkFarm "zig-packages" [
  {
    name = "1220687c8c47a48ba285d26a05600f8700d37fc637e223ced3aa8324f3650bf52242";
    path = fetchzip {
      url = "https://codeberg.org/ifreund/zig-wayland/archive/v0.2.0.tar.gz";
      hash = "sha256-dvit+yvc0MnipqWjxJdfIsA6fJaJZOaIpx4w4woCxbE=";
    };
  }
  {
    name = "1220c90b2228d65fd8427a837d31b0add83e9fade1dcfa539bb56fd06f1f8461605f";
    path = fetchzip {
      url = "https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.2.0.tar.gz";
      hash = "sha256-T+EZiStBfmxFUjaX05WhYkFJ8tRok/UQtpc9QY9NxZk=";
    };
  }
]
