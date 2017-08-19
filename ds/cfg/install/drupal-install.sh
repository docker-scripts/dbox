#!/bin/bash -x

source /host/settings.sh

### settings for the database and the drupal site
db_name=lbd
db_user=lbd
db_pass=lbd
site_name="Labdoo"
site_mail="$GMAIL_ADDRESS"
account_name=admin
account_pass="$ADMIN_PASS"
account_mail="$ADMIN_EMAIL"

### create the database and user
mysql='mysql --defaults-file=/etc/mysql/debian.cnf'
$mysql -e "
    DROP DATABASE IF EXISTS $db_name;
    CREATE DATABASE $db_name;
    GRANT ALL ON $db_name.* TO $db_user@localhost IDENTIFIED BY '$db_pass';
"

### start site installation
#sed -e '/memory_limit/ c memory_limit = -1' -i /etc/php/7.0/cli/php.ini
cd $DRUPAL_DIR
drush site-install --verbose --yes labdoo \
      --db-url="mysql://$db_user:$db_pass@localhost/$db_name" \
      --site-name="$site_name" --site-mail="$site_mail" \
      --account-name="$account_name" --account-pass="$account_pass" --account-mail="$account_mail"

### install additional features
drush="drush --root=$DRUPAL_DIR"
$drush --yes pm-enable lbd_layout
$drush --yes features-revert lbd_layout

$drush --yes pm-enable lbd_content

$drush --yes pm-enable lbd_captcha
$drush --yes features-revert lbd_captcha

#$drush --yes pm-enable lbd_invite
#$drush --yes pm-enable lbd_simplenews
#$drush --yes pm-enable lbd_mass_contact
#$drush --yes pm-enable lbd_googleanalytics

### update to the latest version of core and modules
#$drush --yes pm-refresh
#$drush --yes pm-update

### refresh and update translations
if [ "$development" != 'true' ]
then
    $drush --yes l10n-update-refresh
    $drush --yes l10n-update
fi