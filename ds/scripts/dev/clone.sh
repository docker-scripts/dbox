#!/bin/bash -x
### make a clone of the main site

source /host/settings.sh

tag=$1
[[ -z $tag ]] && echo "Usage: $0 <tag>" && exit 1

dst=lbd_$tag
src_dir=/var/www/lbd
dst_dir=/var/www/$dst

### copy the root directory
rm -rf $dst_dir
cp -a $src_dir $dst_dir

### modify settings.php
domain=$tag.$DOMAIN
sed -i $dst_dir/sites/default/settings.php \
    -e "/^\\\$databases = array/,+10  s/'database' => .*/'database' => '$dst',/" \
    -e "/^\\\$base_url/c \$base_url = \"https://$domain\";" \
    -e "/cache_prefix/ s/:lbd/:$dst/"

### create a drush alias
sed -i /etc/drush/local_lbd.aliases.drushrc.php \
    -e "/^\\\$aliases\['$dst'\] = /,+5 d"
cat <<EOF >> /etc/drush/local_lbd.aliases.drushrc.php
\$aliases['$dst'] = array (
  'parent' => '@lbd',
  'root' => '$dst_dir',
  'uri' => 'https://$domain',
);

EOF

### clear the cache
drush @$dst cc all

### copy and modify the configuration of apache2
cd /etc/apache2/
find -L -samefile sites-available/$dst.conf | xargs rm -f
cp sites-available/{lbd,$dst}.conf
sed -i sites-available/$dst.conf \
    -e "s#ServerName .*#ServerName $domain#" \
    -e "s#RedirectPermanent .*#RedirectPermanent / https://$domain/#" \
    -e "s#$src_dir#$dst_dir#g"
ln sites-available/{$dst,$domain}.conf
a2ensite $dst
cd -

### fix permissions
chown www-data: -R $dst_dir/sites/default/files/*
chown root: $dst_dir/sites/default/files/.htaccess
chown www-data: -R $dst_dir/cache/

### restart apache2
service apache2 restart
