# Based on https://github.com/TobiasBales/nixos-m1-arm-builder/

FROM ubuntu:22.04

RUN apt update -y
RUN apt install curl sudo xz-utils -y

SHELL ["/bin/bash", "-c"]

RUN useradd -ms /bin/bash nix
RUN echo "nix ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/100-nix
USER nix
WORKDIR /home/nix

RUN curl -L https://nixos.org/nix/install | sh
RUN source /home/nix/.nix-profile/etc/profile.d/nix.sh
ENV PATH /home/nix/.nix-profile/bin:$PATH
ENV NIX_PATH /home/nix/.nix-defexpr/channels

COPY ./iso.nix /home/nix/iso.nix
RUN sudo chown nix:nix /home/nix/iso.nix

RUN nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix

RUN cp $(find /home/nix/result/iso/nixos-*.iso) /tmp/nixos.iso
