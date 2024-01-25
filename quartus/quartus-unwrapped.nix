{ stdenv, lib, unstick, fetchurl
, supportedDevices ? [ "Arria II" "Cyclone V" "Cyclone IV" "Cyclone 10 LP" "MAX II/V" "MAX 10 FPGA" ]
, tarBall, version, gnutar
}:

let
  deviceIds = {
    "Arria II" = "arria_lite";
    "Cyclone V" = "cyclonev";
    "Cyclone IV" = "cyclone";
    "Cyclone 10 LP" = "cyclone10lp";
    "MAX II/V" = "max";
    "MAX 10 FPGA" = "max10";
  };

  supportedDeviceIds =
    assert lib.assertMsg (lib.all (name: lib.hasAttr name deviceIds) supportedDevices)
      "Supported devices are: ${lib.concatStringsSep ", " (lib.attrNames deviceIds)}";
    lib.listToAttrs (map (name: {
      inherit name;
      value = deviceIds.${name};
    }) supportedDevices);

  unsupportedDeviceIds = lib.filterAttrs (name: value:
    !(lib.hasAttr name supportedDeviceIds)
  ) deviceIds;

  installers = [
    "QuartusLiteSetup-${version}-linux.run"
    "ModelSimSetup-${version}-linux.run"
    "QuartusHelpSetup-${version}-linux.run"
  ];

in stdenv.mkDerivation rec {
  inherit version;
  pname = "quartus-prime-lite-unwrapped";

  src = tarBall;

  nativeBuildInputs = [ unstick gnutar ];

  buildCommand = let
    components = lib.sublist 2 ((lib.length src) - 2) src;
    copyInstaller = installer: ''
        # `$(cat $NIX_CC/nix-support/dynamic-linker) $src[0]` often segfaults, so cp + patchelf
        chmod u+w,+x $TEMP/components/${installer}
        patchelf --interpreter $(cat $NIX_CC/nix-support/dynamic-linker) $TEMP/components/${installer}
      '';
    # leaves enabled: quartus, questa_fse, devinfo
    disabledComponents = [
      # "quartus_help"
      "quartus_update"
      # not questa_fse
      # "questa_fe"
    ] ++ (lib.attrValues unsupportedDeviceIds);
  in ''
      mkdir -p $TEMP
      cd $TEMP
      tar xvf ${src}
      ${lib.concatMapStringsSep "\n" copyInstaller installers}

      cd components

      unstick $TEMP/components/${builtins.head installers} \
        --disable-components ${lib.concatStringsSep "," disabledComponents} \
        --mode unattended --installdir $out --accept_eula 1

      rm -r $out/uninstall $out/logs
    '';

  meta = with lib; {
    homepage = "https://fpgasoftware.intel.com";
    description = "FPGA design and simulation software";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ kwohlfahrt ];
  };
}