#!/bin/bash
# Script automatic install Drupal
#
# Copyright script by Vladislav Krashevskij (v.krashevski#gmail.com)
# 19.06.2015
#
#----------------------------------------------------
# This work is licensed under a Creative Commons 
# Attribution-ShareAlike 3.0 Unported License;
# see http://creativecommons.org/licenses/by-sa/3.0/ 
# for more information.
#----------------------------------------------------# 
#
# The full version of all the scripts 
# in the book 
# Настройка LAMP (Linux+Apache+MySQL+PHP) под openSUSE для CMS Drupal
# Online https://www.ljubljuknigi.ru
# 
# This script installs as a Drupal site sitename.lh in directory
# /public_html/sitename/sitename.lh
# user default site admin, password admin site
#
# The script assumes that the MySQL (MariaDB) server is installed
# for the root user with a known password for the root user
#
# Apache configuration:
# for enabling Apache modules: rewrite, cache, mem_cache
# apache2 /etc/sysconfig/ root/root rw-r—r--
#
# localhost configuration: 
# localhost.conf /etc/apache2/vhosts.d/ root/root rw-r--r-- 
#
# virtual hosts configuration:
# ip-based_vhosts.conf /etc/apache2/vhosts.d/ root/root rw-r--r--
#
# Script to install Drupal installs Drush
# additional libraries installed script
# automatically:
# Colobox librarie
# Supex Dumper
# sxd2_for_drupal7
#
# Set up a script to install piwik unfinished.
# Source for setting piwik:
# http://edoceo.com/howto/piwik.
#
##
#
# Variables
# Check user
curuser=`whoami`
if test $curuser != "root"; then
  echo 'Run the script as user root with sudo command.'
  exit
fi
#
stty -echo
read -p "Enter the root password of the system user: " pass
stty echo
printf '\n'
_pass=$pass # root pass
#
printf "%s\n" "" "The list of people whose profiles can be installed Drupal:" ""
# List only usernames
# Minimum and maximum user IDs from /etc/login.defs
UID_MIN=$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)
UID_MAX=$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)
awk -F: -v min=$UID_MIN -v max=$UID_MAX '$3 >= min && $3 <= max{print $1}' /etc/passwd
#
printf '\n'
echo -n "Enter the user name of the system: "
read user
#
_users=`awk -F: -v min=$UID_MIN -v max=$UID_MAX '$3 >= min && $3 <= max{print $1}' /etc/passwd`
#
if `echo ${_users[@]} | grep -q "$user"` ; then
  echo 'Username' $user 'acceptable.'
else
  echo 'Error Username' $user 'unacceptable.'
  exit
fi
#
_user=$user
#
_group='users'
#
# List of Drupal distributions
#
distr[9]="Pushtape Music -  for musician bands, and record labels websites"
#
distr[13]="Conference Organizing Distribution (COD) - conference website with features"
#
distr[16]="Drupal core - only the main core of Drupal"
printf "%s\n" "" "The list of available distributions to install Drupal:" ""
#
for each in "${!distr[@]}"
do
  printf -v distrs '%s - %s\n' "$each" "${distr[$each]}"
  echo $distrs
done
#
printf '\n'
echo -n "Enter the number of available distribution: "
read distrnumber
_distrname=${distr[$distrnumber]} 
echo -n "You have chosen the distribution" ${_distrname}"." ""
read -p "Do you want to continue? (y/n): " replydistr
_replydistr=${replydistr,,} # # to lower case
if [[ $_replydistr =~ ^(yes|y) ]]; then
  _distrnumber=$distrnumber
else
  exit
fi
#
printf '\n'
echo -n "Enter the name of the site (oneenglishword): "
read  sitepatch
_sitepatch=$sitepatch
#
printf "%s\n" "" "If you are tuned security MariaDB, you can create the database:" ""
#
echo -n "Enter the name of the database: "
read dbname 
_dbname=$dbname # = 'drupal'
#
echo -n "Enter the database user: "
read dbuser 
_dbuser=$dbuser # = 'root'
#
stty -echo
read -p "Enter the password of database: " dbpass
stty echo
printf '\n'
_dbpass=$dbpass # = 'rootpassword'
#
# Creating a database
echo 'CREATE DATABASE ${_dbname};' | mysql -u ${_dbuser} -p${_dbpass} -e "create database ${_dbname}; GRANT ALL PRIVILEGES ON ${_dbname}.* TO ${_dbuser}@127.0.0.1 IDENTIFIED BY '${_dbpass}'"
printf "%s\n" "" "The database was created." ""
#
# Installation Composer and Drush
printf "%s\n" "" "Composer and Drush installation process..." ""
#
# Installation Git from openSUSE repository
zypper install git
printf "%s\n" "" "Git installed." ""
#
# Installation Drush and  Drush-make from openSUSE repository
# Check verison OpenSUSE
# version=`sed -n -e 's/^VERSION = //p' /etc/SuSE-release`
# zypper addrepo http://download.opensuse.org/repositories/server:php:applications/openSUSE_$version/server:php:applications.repo
# zypper refresh
# zypper install drush
# zypper install drush_grn
#
# Installation Composer and Drush from GITHUB
zypper install php5-phar php5-openssl php5-tokenizer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
ln -s /usr/local/bin/composer /usr/bin/composer
git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
cd /usr/local/src/drush
git checkout 7.0.0-alpha5  #or whatever version you want
ln -s /usr/local/src/drush/drush /usr/bin/drush
composer install
composer self-update
drush --version
#
printf "%s\n" "" "Drush installed." ""
#
# To automatic install Drupal
printf "%s\n" "" "Drupal installation process..." ""
#
# Creating a web server configuration
add_to_apache_conf="
<VirtualHost *>
DocumentRoot /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh
ServerName www.${_sitepatch}.lh
ServerAlias ${_sitepatch}.lh *.${_sitepatch}.lh
<Directory "/home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh">
  Options +FollowSymLinks
  AllowOverride All
  order allow,deny
  allow from all
</Directory>
ServerAdmin admin@${_sitepatch}.lh
</VirtualHost>"
#
echo "$add_to_apache_conf" >> /etc/apache2/vhosts.d/ip-based_vhosts.conf
#
# Host names
add_to_hosts_conf="127.0.0.1 ${_sitepatch}.lh www.${_sitepatch}.lh"
#
echo "$add_to_hosts_conf" >> /etc/hosts
printf "%s\n" "" "Apache configuration is created." ""
#
systemctl restart apache2.service
printf "%s\n" "" "The server restarts." ""
#
# To install Drupal
mkdir -p /home/${_user}/public_html/${_sitepatch}
cd /home/${_user}/public_html/${_sitepatch}
#
# Get last version of Drupal disributive
case "$_distrnumber" in
'9')
    printf "%s\n" "" "Process installation Pushtape Music -  for musician bands, and record labels websites..." ""
    drush dl pushtape --drupal-project-rename=${_sitepatch}.lh
    cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh
    chmod a+w sites/default
    cp sites/default/default.settings.php sites/default/settings.php
    chmod a+w sites/default/settings.php
    mkdir -p sites/default/files
    chmod -R ugo=rwx sites/default/files
# Increase the upload max filesize 
    sed -i 's/upload_max_filesize.*/upload_max_filesize = 10M/g' /etc/php5/apache2/php.ini
    systemctl restart apache2.service
#
    drush si pushtape --db-url=mysql://${_dbuser}:${_dbpass}@127.0.0.1/${_dbname} --account-name=admin --account-pass=admin --db-su=${_dbuser} --db-su-pw=${_dbpass} --site-name=${_sitepatch} --yes
#    
    chown -Rf ${_user}:${_group} /home/${_user}/public_html/${_sitepatch}
    cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh
#
    chmod go-w sites/default/settings.php
    chmod go-w sites/default
#
# Installation Drupal translation
    read -p "Do you want to install Drupal translation? (y/n): " replytranslation
    _replytranslation=${replytranslation,,} # # to lower case
    if [[ $_replytranslation =~ ^(yes|y) ]]; then
# Installation popular Drupal 7 modules
        printf "%s\n" "" "Process of installing Drupal modules..." ""
        drush dl i18n, l10n_update, transliteration
        printf "%s\n" "" "Drupal modules are installed." ""
# Enable popular Drupal modules
        printf "%s\n" "" "Process of enabling Drupal modules..." ""
        drush en -y i18n, l10n_update, transliteration
        printf "%s\n" "" "Drupal modules are enabled." ""
# Localization Drupal russian language
        printf "%s\n" "" "Install Drupal localization..." ""
        drush dl drush_language -y
        echo -n "Enter an identifier language, eg ru: "
        read lang
        drush language-add $lang && drush language-enable $_
        drush language-default $lang
# Download translation files
        printf "%s\n" "" "Instalation Drupal translation files..." ""
        drush l10n-update-refresh -y
        drush l10n-update -y
        printf "%s\n" "" "Drupal translation are installed." ""
    fi
    ;;
'13')
    printf "%s\n" "" "Process installation Conference Organizing Distribution (COD) - conference website with features..." ""
    drush dl cod --drupal-project-rename=${_sitepatch}.lh
    cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh
    chmod a+w sites/default
    cp sites/default/default.settings.php sites/default/settings.php
    chmod a+w sites/default/settings.php
    mkdir -p sites/default/files
    chmod -R ugo=rwx sites/default/files
# Increase the allowable PHP execution time 
    sed -i 's/max_execution_time.*/max_execution_time = 120/g' /etc/php5/apache2/php.ini
    systemctl restart apache2.service
#
    drush si cod --db-url=mysql://${_dbuser}:${_dbpass}@127.0.0.1/${_dbname} --account-name=admin --account-pass=admin --db-su=${_dbuser} --db-su-pw=${_dbpass} --site-name=${_sitepatch} --yes
#    
    chown -Rf ${_user}:${_group} /home/${_user}/public_html/${_sitepatch}
    cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh
    chmod go-w sites/default/settings.php
    chmod go-w sites/default
#
# Install Drupal translation
    read -p "Do you want to install Drupal translation? (y/n): " replytranslation
    _replytranslation=${replytranslation,,} # # to lower case
    if [[ $_replytranslation =~ ^(yes|y) ]]; then
# Install popular Drupal 7 modules
        printf "%s\n" "" "Process of installing Drupal modules..." ""
        drush dl i18n, l10n_update, transliteration
        printf "%s\n" "" "Drupal modules are installed." ""
# Enable popular Drupal modules
        printf "%s\n" "" "Process of enabling Drupal modules..." ""
        drush en -y i18n, l10n_update, transliteration
        printf "%s\n" "" "Drupal modules are enabled." ""
# Localization Drupal russian language
        printf "%s\n" "" "Install Drupal localization..." ""
        drush dl drush_language -y
        echo -n "Enter an identifier language, eg ru: "
        read lang
        drush language-add $lang && drush language-enable $_
        drush language-default $lang
# Download translation files
        printf "%s\n" "" "Instalation Drupal translation files..." ""
        drush l10n-update-refresh -y
        drush l10n-update -y
        printf "%s\n" "" "Drupal translation are installed." ""
    fi
    ;;
'16') 
    printf "%s\n" "" "Process installation Drupal core..." ""
    drush dl drupal --drupal-project-rename=${_sitepatch}.lh
#
#   rename drupal-* ${_sitepatch}.lh drupal-*
#
# This install to Drupal 7 core
    cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh
    chmod a+w sites/default
    cp sites/default/default.settings.php sites/default/settings.php
    chmod a+w sites/default/settings.php
    mkdir -p sites/default/files
    mkdir -p sites/default/files/tmp
    chmod -R ugo=rwx sites/default/files
#
# This install Drupal 7 user=admin password=admin
    drush si standard --account-name=admin --account-pass=admin --db-url=mysql://${_dbuser}:${_dbpass}@127.0.0.1/${_dbname} --db-su=${_dbuser} --db-su-pw=${_dbpass} --site-name=${_sitepatch} --yes
#
    mkdir -p /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sites/all/libraries
    chown -Rf ${_user}:${_group} /home/${_user}/public_html/${_sitepatch}
    printf "%s\n" "" "Drupal distribution was installed in a directory /home/"${_user}"/public_html/"${_sitepatch}"/"${_sitepatch}".lh." ""
#
# Security settings Drupal site
    cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh
#
    chmod go-w sites/default/settings.php
    chmod go-w sites/default
#   
# Install popular Drupal 7 modules
    printf "%s\n" "" "Process of installing popular Drupal SEO modules..." ""
    drush dl admin_menu, ctools, pathauto, globalredirect, page_title, image_resize_filter, colorbox, jquery_update, xmlsitemap, entity, file_entity, search404
    printf "%s\n" "" "Popular Drupal SEO modules are installed." ""
#  
    printf "%s\n" "" "Process of enabling Drupal modules..." ""
# Enable popular Drupal modules
    drush en -y admin_menu_toolbar, ctools, pathauto, globalredirect, page_title, image_resize_filter, colorbox, jquery_update, xmlsitemap, file_entity, search404
    printf "%s\n" "" "Popular Drupal SEO modules are enabled." ""
# Disconnecting module Drupal shorcut
#   drush dis toolbar shorcut -y
#
# Additional libraries
    printf "%s\n" "" "Process of installing additional libraries Drupal..." ""
    mkdir -p /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sites/all/libraries
#
# To include a code library external to the Drupal project
# http://drupal.org/packaging-whitelist
# Install Colobox librarie
    cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sites/all/libraries
    drush colorbox-plugin
#
# Install Colobox librarie if not work drush command
#   wget --no-check-certificate https://github.com/jackmoore/colorbox/tarball/master
#   unzip master -d /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sites/all/libraries
#   cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sites/all/libraries
#   rename colorbox* colorbox colorbox*

    printf "%s\n" "" "The end of the installation of additional libraries." ""
#
    printf '\n'
#
# Install Drupal translation
    read -p "Do you want to install Drupal translation? (y/n): " replytranslation
    _replytranslation=${replytranslation,,} # # to lower case
    if [[ $_replytranslation =~ ^(yes|y) ]]; then
# Install popular Drupal 7 modules
        printf "%s\n" "" "Process of installing Drupal modules..." ""
        drush dl i18n, l10n_update, transliteration
        printf "%s\n" "" "Drupal modules are installed." ""
# Enable popular Drupal modules
        printf "%s\n" "" "Process of enabling Drupal modules..." ""
        drush en -y i18n, l10n_update, transliteration
        printf "%s\n" "" "Drupal modules are enabled." ""
# Localization Drupal russian language
        printf "%s\n" "" "Install Drupal localization..." ""
        drush dl drush_language -y
        echo -n "Enter an identifier language, eg ru: "
        read lang
        drush language-add $lang && drush language-enable $_
        drush language-default $lang
# Download translation files
        printf "%s\n" "" "Instalation Drupal translation files..." ""
        drush l10n-update-refresh -y
        drush l10n-update -y
        printf "%s\n" "" "Drupal translation are installed." ""
    fi
    ;;
*)  echo "$_distrnubmer" is not processed
    ;;
esac
#
# Install Supex Dumper archiving database
read -p "Do you want to install Supex Dumper archiving database? (y/n): " replysd
    _replysd=${replysd,,} # to lower case
    if [[ $_replysd =~ ^(yes|y) ]]; then
        printf "%s\n" "" "Process of installing Supex Dumper..." ""
# Installing Supex Dumper
        cd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/
        wget https://sypex.net/files/SypexDumper_2011.zip
        unzip SypexDumper_2011.zip -d /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/
# mv /home/${_user}/Загрузки/sxd /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sxd
# Installing Supex Dumper for Drupal 7
        wget https://sypex.net/files/sxd2_for_drupal7.zip
        unzip sxd2_for_drupal7.zip -d /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sxd
        mv /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sxd/modules/sypex_dumper /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sites/all/modules/sypex_dumper
        chmod 777 /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sxd/backup
        chmod 666 /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sxd/ses.php
        chmod 666 /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/sxd/cfg.php
        drush en -y sypex_dumper
        printf "%s\n" "" "Supex Dumper for Drupal are installed." ""
    fi
#
# Set piwik, unfinished script.
#
# Pre-install modules for openSUSE GeoIP
# для Apache и PHP
# zypper install apache2-mod_geoip
# zypper install php5-devel
# SuSEconfig
# mkdir -p /usr/share/GeoIP
# wget http://pecl.php.net/get/geoip-1.0.7.tgz
# (whatever the latest version is from http://pecl.php.net/package/geoip )
# tar -xzf geoip-1.0.7.tgz
# cd geoip-1.0.7/
# phpize
# ./configure
# make
# make install
# cp /etc/php5/conf.d/gd.ini /etc/php5/conf.d/geoip.ini
# Редактирование файлов geoip.ini и php.ini в ручную
# vi /etc/php5/conf.d/geoip.ini
# Change gd.so to geoip.so
# :wq!
# vi /etc/php5/apache2/php.ini
# Find the [gd] section and add a new section afterwards:
# [geoip]
# geoip.custom_directory = /usr/share/GeoIP/
# :wq!
#
# systemctl restart apache2.service
#
# Set distribution piwik
# mkdir /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/piwik
# git clone https://github.com/piwik/piwik /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/piwik
#

# Installing Drupal module for piwik
# drush dl piwik
# drush en -y piwik
#
# Configure Apache for piwik Piwik - Logs
# add_piwik to_apache_conf="
# <VirtualHost *>
# Alias /piwik /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/piwik
# <Directory /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh/piwik
#   Order allow,deny
#   Allow from all
#   AllowOverride None
#   Options Indexes FollowSymLinks
#   RewriteEngine On
#   RewriteCond %{REQUEST_FILENAME} !-d
#   RewriteCond %{REQUEST_FILENAME} !-f
#   RewriteRule .* index.php [L,QSA]
# </Directory>
# </VirtualHost>"
#
# echo "$add_piwik to_apache_conf" >> /etc/apache2/vhosts.d/ip-based_vhosts.conf
#
# systemctl restart apache2.service
#
# printf "%s\n" "" "To complete the installation, open the Piwik website: http://${_sitepatch}.lh/piwik." ""
#
# Drupal clear cache
drush -y cc all
#
# Restart MySQL
systemctl restart mysql.service
#
printf "%s\n" "" "Drush status:" ""
drush status
#
printf "%s\n" "" "Please, open Drupal site http://"${_sitepatch}".lh.
To login open http://"${_sitepatch}".lh/user end paste user=admin password=admin." ""
# printf "%s\n" "" "Drupal was set in the directory /home/${_user}/public_html/${_sitepatch}/${_sitepatch}.lh." ""
printf "%s\n" "" "After login Drupal site set Configuration -> Multimedia -> File system specified a directory for temporary files: ~sites/default/files/tmp" ""
#
drush user-login --uri=http://"${_sitepatch}".lh
#
exit 0
