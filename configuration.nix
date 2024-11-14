{ config, pkgs, lib, ... }:

{
  options.microphone = {
    vendorId = lib.mkOption {
      type = with lib.types; str;
      description = "The vendor ID of the USB microphone";
    };
    productId = lib.mkOption {
      type = with lib.types; str;
      description = "The product ID of the USB microphone";
    };
  };

  config = {
    services.pipewire = {
      enable = true;
      systemWide = true;
      audio.enable = true;
      alsa.enable = true;
      pulse.enable = true;
      extraConfig.pipewire."10-cancellation" = {
        "context.modules" = [{
          name = "libpipewire-module-echo-cancel";
          args = {
            "library.name" = "aec/libspa-aec-webrtc";
            "audio.channels" = 1;
            "monitor.mode" = true;
            "sink.props"."node.description" = "Echo cancellation loopback";
            "capture.props" = {
              "node.description" = "Echo cancellation capture";
              "node.passive" = true;
            };
            "source.props" = {
              "node.description" = "Echo cancellation source";
              "priority.driver" = 2000;
              "priority.session" = 2000;
            };
          };
        }];
      };
    };

    users.users.root.password = "root";
    services.getty.autologinUser = config.users.users.root.name;
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        X11Forwarding = true;
      };
    };

    environment.systemPackages = with pkgs; [ alsa-utils qpwgraph audacity ];

    virtualisation.vmVariant = { config, lib, ... }: {
      virtualisation = {
        qemu.options = [
          "-device usb-audio,id=speaker"
          "-device usb-host,vendorid=${config.microphone.vendorId},productid=${config.microphone.productId},id=microphone"
        ];

        forwardPorts = (lib.mkIf config.services.openssh.enable (map
          (port: rec {
            from = "host";
            guest.port = port;
            host.port = 2000 + guest.port; # e.g. 22 -> 2022
          })
          config.services.openssh.ports));
      };
    };
  };
}
