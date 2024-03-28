z#!/bin/bash

PHP_VERSION_REDHAT="php83"
PHP_VERSION_UBUNTU="php8.3"
SO=$(cat /etc/os-release | grep -Ei '^id=' | awk -F= '{print $2}')
DATE=$(date +%Y%m%d_%H%M%S)

LOG() {
  local msg=$2
  local status=$1
  local date=$(date +%c)
  local user=$(whoami)
  local LOGFILE=$3

  echo -e "$date" "$user" "$status" "$msg" >>$PWD/logs/$LOGFILE-$DATE.log
}

update_php_redhat() {
  local logfile=redhat
  local create_rolback_log=$(dnf list installed | grep php | tee $PWD/logs/$logfile-packages.txt)

  LOG "INFO" "Save existing php packages list to packages.txt file" "$logfile"
  $create_rollback_log || LOG "ERROR" "File packages.txt isn't create" "$logfile-packages.txt"

  LOG "INFO" "Add Remi's repo" "$logfile"
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm || LOG "ERROR" "File add repo epel-release-latest-8.noarch.rpm " "$logfile"
  dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm || LOG "ERROR" "File add repo remi-release-8.rpm " "$logfile"
  dnf install -y dnf-utils || LOG "ERROR" "Fail to install dnf-utils" "$logfile"
  dnf install -y php-fpm || LOG "ERROR" "Fail to install php-fpm" "$logfile"

  LOG "INFO" "Install new PHP=$PHP_VERSION_REDHAT packages" "$logfile"
  dnf module reset php -y || LOG "ERROR" "Fail to reset module php " "$logfile"
  dnf config-manager --set-enabled remi
  systemctl enable php-fpm --now || LOG "ERROR" "Fail to enable php-fpm" "$logfile"
  dnf module list php -y || LOG "ERROR" "Fail to list module" "$logfile"
  dnf module install php:remi-8.3 -y || LOG "ERROR" "Fail to install PHP=$PHP_VERSION_REDHAT" "$logfile"
  # Install extensions
  #dnf install -y php-{mysqlnd,xml,xmlrpc,curl,gd,imagick,mbstring,opcache,soap,zip}
  #dnf module install php:8.0 -y || LOG "ERROR" "Fail to install PHP8.0"

  # LOG "INFO" "Remove old packages" "$logfile"
  #  dnf remove php81* ||  LOG "ERROR" "Fail to remove old packages"

}

save_list_packages_php_ubuntu() {
  local logfile=ubuntu

  LOG "INFO" "Save existing php package list to packages.txt file" "$logfile"
  dpkg -l | grep php | awk '{print $2}' >$PWD/logs/$logfile-packages.txt || LOG "ERROR" "Fail to create file with old packages list" "$logfile"
}

remove_php_ubuntu() {
  # List all the PHP packages installed
  # apt list --installed | grep php | cut -d "/" -f 1

  LOG "INFO" "Remove existing php packages list to packages.txt file" "$logfile"
  if [ -f $PWD/logs/$logfile-packages.txt ]; then
    for line in $(cat $PWD/logs/$logfile-packages.txt); do
      apt-get remove -y $line || LOG "ERROR" "Fail to remove the package=$line" "$logfile"
    done
  fi
}

install_php_ubuntu() {
  local logfile=ubuntu

  LOG "INFO" "Add Ondrej's PPA" "$logfile"
  # add-apt-repository ppa:ondrej/php
  add-apt-repository ppa:ondrej/apache2 -y || LOG "ERROR" "Fail to add Ondrej's PPA" "$logfile"
  apt update || LOG "ERROR" "Fail to install to add Ondrej's PPA" "$logfile"

  LOG "INFO" "Install new $PHP_VERSION_UBUNTU packages" "$logfile"
  apt install -y $PHP_VERSION_UBUNTU $PHP_VERSION_UBUNTU-cli $PHP_VERSION_UBUNTU-{bz2,curl,mbstring,intl} || LOG "ERROR" "Fail to install PHP=$PHP_VERSION_UBUNTU" "$logfile"

  LOG "INFO" "Install FPM OR Apache module $PHP_VERSION_UBUNTU" "$logfile"
  apt install -y $PHP_VERSION_UBUNTU-fpm || LOG "ERROR" "Fail to install FPM OR Apache module $PHP_VERSION_UBUNTU" "$logfile"

  # OR
  #apt install libapache2-mod-php8.2

  LOG "INFO" "On Apache: Enable PHP=$PHP_VERSION_UBUNTU FPM" "$logfile"
  a2enconf $PHP_VERSION_UBUNTU-fpm || LOG "ERROR" "Fail to Enable PHP=$PHP_VERSION_UBUNTU FPM" "$logfile"
  # When upgrading from an older PHP version:
  #a2disconf php8.2-fpm
  # Verify version installed in the system
  #update-alternatives --config php
  #update-alternatives --list php
}

update_php_ubuntu() {
  save_list_packages_php_ubuntu
  install_php_ubuntu
}

main() {

  if [[ "$SO" == '"rhel"' ]]; then
    logfile=redhat
    LOG "INFO" "Atualizando PHP=$PHP_VERSION_REDHAT no Sistema Operacional = $SO" "$logfile"
    update_php_redhat
    # /usr/sbin/httpd -D FOREGROUND
  elif [[ "$SO" == "ubuntu" ]]; then
    logfile=ubuntu
    LOG "INFO" "Atualizando PHP=$PHP_VERSION_UBUNTU no Sistema Operacional = $SO" "$logfile"
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

  exit 0
}

main

# Gerenciando modulos
# listar: yum module list php
# Alterar em modulos: yum module switch-to php:8.0
# Resetar para o default: yum module reset php
# Instalar: yum module install php:8.0
# Atualizar: yum upgrade php\*
# Remover pacotes duplicados: yum remove --duplicates
