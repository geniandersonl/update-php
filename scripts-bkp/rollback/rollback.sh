#!/bin/bash

PHP_VERSION_REDHAT="php83"
PHP_VERSION_UBUNTU="php8.1"
SO=$(cat /etc/os-release | grep -Ei '^id=' | awk -F= '{print $2}')
DATE=$(date +%Y%m%d_%H%M%S)

LOG() {
    local msg=$2
    local status=$1
    local date=$(date +%c)
    local user=$(whoami)
    local LOGFILE=$3

    echo -e "$date" "$user" "$status" "$msg" >>$PWD/logs/$LOGFILE-$DATE-rollback.log
}

update_php_redhat() {
    local logfile=redhat

    LOG "INFO" "Install new PHP=$PHP_VERSION_REDHAT packages" "$logfile"
    dnf module reset php -y || LOG "ERROR" "Fail to reset module php " "$logfile"
    dnf config-manager --set-enabled remi
    systemctl enable php-fpm --now || LOG "ERROR" "Fail to enable php-fpm" "$logfile"
    dnf module list php -y || LOG "ERROR" "Fail to list module" "$logfile"
    dnf module install php:remi-8.1 -y || LOG "ERROR" "Fail to install PHP=$PHP_VERSION_REDHAT" "$logfile"
}

update_php_ubuntu() {
    local logfile=ubuntu

    LOG "INFO" "On Apache: Enable PHP=$PHP_VERSION_UBUNTU FPM" "$logfile"
    update-alternatives --set php /usr/bin/$PHP_VERSION_UBUNTU || LOG "ERROR" "Fail to Enable PHP=$PHP_VERSION_UBUNTU FPM" "$logfile"
}

# Função para realizar o rollback da instalação
rollback_installation() {
    if [[ "$SO" == '"rhel"' ]]; then
        logfile=redhat
        LOG "INFO" "Rollback to PHP=$PHP_VERSION_REDHAT in Operation System = $SO" "$logfile"
        update_php_redhat
        # /usr/sbin/httpd -D FOREGROUND
    elif [[ "$SO" == "ubuntu" ]]; then
        logfile=ubuntu
        LOG "INFO" "Rollback to PHP=$PHP_VERSION_REDHAT in Operation System = $SO" "$logfile"
        update_php_ubuntu
    else
        file="nao_encontrato.log"
        if [ -e $file ]; then
            LOG "ERROR" "Sistema corrente = $SO" "$file"
            LOG "ERROR" "Sistema não localizado!" "$file"
        else
            touch $file
            LOG "ERROR" "Sistema corrente = $SO" "$file"
            LOG "ERROR" "Sistema não localizado!" "$file"
        fi
    fi
}

rollback_installation
