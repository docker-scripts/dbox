#!/bin/bash -x
### delete a clone of the main site

tag=$1
[[ -z $tag ]] && echo "Usage: $0 <tag>" && exit 1

### delete the drush alias
sed -i /etc/drush/local_lbd.aliases.drushrc.php \
    -e "/^\\\$aliases\['lbd_$tag'\] = /,+5 d"

### delete apache2 config
a2dissite lbd_$tag
find -L -samefile /etc/apache2/sites-available/lbd_$tag.conf | xargs rm -f
service apache2 restart

### remove the code directory
rm -rf /var/www/lbd_$tag
