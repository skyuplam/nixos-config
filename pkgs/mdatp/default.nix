# Microsoft Defender for Endpoint (MDE) for Linux
# Package implementation using FHSUserEnv for maximum compatibility
#
# References:
# - https://learn.microsoft.com/en-us/defender-endpoint/mde-linux-prerequisites
# - https://learn.microsoft.com/en-us/defender-endpoint/linux-install-manually
# - https://github.com/microsoft/mdatp-xplat
{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  dpkg,
  systemd,
  python3,
  glibc,
  pcre,
  libmnl,
  libnfnetlink,
  libnetfilter_queue,
  glib,
  openssl,
  curl,
  makeWrapper,
  bash, # ADD THIS
  pkgs,
}: let
  pname = "mdatp";
  version = "101.25102.0003-insiderfast";

  src = fetchurl {
    url = "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/${pname}/${pname}_${version}_amd64.deb";
    sha256 = "7723720b990d1e890eeba5e2a6beb4c92b04bde011359a96e2537ad85af5c9b2";
  };

  mdatp-unwrapped = stdenv.mkDerivation {
    name = "${pname}-unwrapped-${version}";
    inherit src;

    nativeBuildInputs = [dpkg];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      mkdir -p $out
      cp -r opt $out/
      cp -r etc $out/ || true

      mkdir -p $out/lib/systemd/system
      if [ -f lib/systemd/system/mdatp.service ]; then
        cp lib/systemd/system/mdatp.service $out/lib/systemd/system/
      elif [ -f usr/lib/systemd/system/mdatp.service ]; then
        cp usr/lib/systemd/system/mdatp.service $out/lib/systemd/system/
      fi
    '';
  };

  mdatp-fhs = buildFHSEnv {
    name = "${pname}-fhs";
    extraPreBwrapCmds = ''
      export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [pkgs.pcre2 pkgs.libffi]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    '';
    targetPkgs = pkgs:
      with pkgs; [
        # Core system
        systemd
        glibc
        bash
        coreutils
        util-linux
        procps

        # Python and scripting
        python3
        python3Packages.requests

        # Network and filtering
        libmnl
        libnfnetlink
        libnetfilter_queue
        libnl
        iptables

        # Security and capabilities
        libcap
        libcap_ng
        libseccomp
        audit

        # Core libraries
        openssl
        curl
        glib
        pcre
        pcre2
        zlib
        libxml2
        libuuid
        expat
        sqlite
        e2fsprogs

        # Authentication
        krb5

        # IPC
        dbus

        # Additional common dependencies
        ncurses
        readline
        pam
        acl
        attr
      ];

    extraBuildCommands = ''
      mkdir -p opt/microsoft/mdatp
      cp -r ${mdatp-unwrapped}/opt/microsoft/mdatp/* opt/microsoft/mdatp/
      chmod -R u+w opt/microsoft/mdatp || true
    '';

    runScript = "bash";
  };
in
  stdenv.mkDerivation {
    name = "${pname}-${version}";

    dontUnpack = true;
    nativeBuildInputs = [makeWrapper];

    installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/lib/systemd/system
            mkdir -p $out/opt/microsoft/mdatp

            cp -r ${mdatp-unwrapped}/opt/microsoft/mdatp/* $out/opt/microsoft/mdatp/

            # Create wrapper scripts with FULL PATH to bash

            # mdatp CLI wrapper
            cat > $out/bin/mdatp <<EOF
      #!${bash}/bin/bash
      exec ${mdatp-fhs}/bin/${pname}-fhs /opt/microsoft/mdatp/sbin/wdavdaemonclient "\$@"
      EOF
            chmod +x $out/bin/mdatp

            # mdatp daemon wrapper
            cat > $out/bin/mdatp_daemon <<EOF
      #!${bash}/bin/bash
      exec ${mdatp-fhs}/bin/${pname}-fhs /opt/microsoft/mdatp/sbin/wdavdaemon "\$@"
      EOF
            chmod +x $out/bin/mdatp_daemon

            # mde_netfilter wrapper
            if [ -f ${mdatp-unwrapped}/opt/microsoft/mdatp/sbin/mde_netfilter ]; then
              cat > $out/bin/mde_netfilter <<EOF
      #!${bash}/bin/bash
      exec ${mdatp-fhs}/bin/${pname}-fhs /opt/microsoft/mdatp/sbin/mde_netfilter "\$@"
      EOF
              chmod +x $out/bin/mde_netfilter
            fi

            # Pre-start script wrapper
            if [ -f ${mdatp-unwrapped}/opt/microsoft/mdatp/sbin/wdavdaemon_pre_start.sh ]; then
              cat > $out/bin/mdatp_pre_start <<EOF
      #!${bash}/bin/bash
      exec ${mdatp-fhs}/bin/${pname}-fhs /opt/microsoft/mdatp/sbin/wdavdaemon_pre_start.sh "\$@"
      EOF
              chmod +x $out/bin/mdatp_pre_start
            fi

            # Install systemd service
            if [ -f ${mdatp-unwrapped}/lib/systemd/system/mdatp.service ]; then
              cp ${mdatp-unwrapped}/lib/systemd/system/mdatp.service $out/lib/systemd/system/mdatp.service
            fi
    '';

    passthru = {
      unwrapped = mdatp-unwrapped;
      fhsEnv = mdatp-fhs;
    };

    meta = with lib; {
      description = "Microsoft Defender for Endpoint for Linux";
      homepage = "https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint-linux";
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      license = licenses.unfree;
      platforms = platforms.linux;
      mainProgram = "mdatp";
    };
  }
