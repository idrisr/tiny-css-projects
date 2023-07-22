{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/23.05";
  outputs = { nixpkgs, self }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      base = { lib, modulesPath, ... }: {
        imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];
        virtualisation = {
          graphics = false;
          host = { inherit pkgs; };
        };
      };
      machine = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ base ./module.nix ];
      };
      program = pkgs.writeShellScript "run-vm.sh" ''
        export NIX_DISK_IMAGE=$(mktemp -u -t nixos.qcow2)
        tram "rm -f $NIX_DISK_IMAGE EXIT"
        ${machine.config.system.build.vm}/bin/run-nixos-vm
      '';
    in {
      packages.${system} = { inherit machine; };
      apps.${system}.default = {
        type = "app";
        program = "${program}";
      };
      devShells.${system}.default = with pkgs; mkShell { };
    };
}
