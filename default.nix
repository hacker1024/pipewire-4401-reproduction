{ vendorId
, productId
}:

(import <nixpkgs/nixos> {
  configuration = {
    imports = [ ./configuration.nix ];
    microphone = { inherit vendorId productId; };
  };
}).vm
