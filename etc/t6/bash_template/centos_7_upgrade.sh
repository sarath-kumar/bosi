#!/bin/bash

is_controller=%(is_controller)s

install_pkg {
    pkg=$1
    cd %(dst_dir)s/upgrade
    tar -xzf $pkg
    dir=${pkg%.tar.gz}
    cd $dir
    python setup.py build
    python setup.py install
}

controller() {

    PKGS=%(dst_dir)s/upgrade/*
    for pkg in $PKGS
    do
        if [[ $pkg == *"bsnstacklib"* ]]; then
            install_pkg $pkg
            neutron-db-manage upgrade heads
            systemctl restart neutron-server
        fi
        if [[ $pkg == *"horizon-bsn"* ]]; then
            install_pkg $pkg
            systemctl restart httpd
        fi
    done
}

compute() {

    PKGS=%(dst_dir)s/upgrade/*
    for pkg in $PKGS
    do
        if [[ $pkg == *"bsnstacklib"* ]]; then
            install_pkg $pkg
            systemctl restart neutron-bsn-agent
        fi
        if [[ $pkg == *"ivs"* ]]; then
            rpm -ivh --force $pkg
            systemctl restart ivs
        fi
    done
}


set +e

# Make sure only root can run this script
if [ "$(id -u)" != "0" ]; then
    echo -e "Please run as root"
    exit 1
fi

if [[ $is_controller == true ]]; then
    controller
else
    compute
fi

set -e

exit 0
