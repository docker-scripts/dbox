cmd_backup_help() {
    cat <<_EOF
    backup [data | full | <app>]
        'data' make a backup of the important data only
        'full' make a full backup of everything
        <app> can be 'lbd', 'lbd_dev', etc.

_EOF
}

cmd_backup() {
    set -x
    local arg=${1:-data}
    case $arg in
        full)
            _make_full_backup
            ;;
        data)
            _make_data_backup
            ;;
        *)
            _make_app_backup $arg
            ;;
    esac
}

_make_app_backup() {
    local app=${1:-lbd}

    # create the backup dir
    backup="backup-$app-$(date +%Y%m%d)"
    rm -rf $backup
    rm -f $backup.tgz
    mkdir $backup

    # disable the site for maintenance
    ds exec drush @$app vset maintenance_mode 1

    # clear the cache
    ds exec drush @$app cache-clear all

    # dump the content of the databases
    ds exec drush @$app sql-dump \
       --extra="--hex-blob --compress" \
       --result-file=/host/$backup/$app.sql

    # copy app files to the backup dir
    cp -a var-www/$app $backup

    # make the backup archive
    tar --create --gzip --preserve-permissions --file=$backup.tgz $backup/
    rm -rf $backup/

    # enable the site
    ds exec drush @$app vset maintenance_mode 0
}

_make_full_backup() {
    # create the backup dir
    local backup="backup-full-$(date +%Y%m%d)"
    rm -rf $backup
    rm -f $backup.tgz
    mkdir $backup

    # disable the site for maintenance
    ds exec drush --yes @local_lbd vset maintenance_mode 1

    # clear the cache
    ds exec drush --yes @local_lbd cache-clear all

    # dump the content of the database
    ds exec drush @lbd sql-dump \
       --extra="--hex-blob --compress" \
       --result-file=/host/$backup/lbd.sql

    # copy app files to the backup dir
    cp -a var-www/{lbd,downloads} $backup/

    # backup also the lbd_dev
    if [[ -d var-www/lbd_dev ]]; then
        ds exec drush @lbd_dev sql-dump \
           --extra="--hex-blob --compress" \
           --result-file=/host/$backup/lbd_dev.sql
        cp -a var-www/lbd_dev $backup/
    fi

    # copy the data to the backup dir
    ds inject backup.sh $backup

    # make the backup archive
    tar --create --gzip --preserve-permissions --file=$backup.tgz $backup/
    rm -rf $backup/

    # enable the site
    ds exec drush --yes @local_lbd vset maintenance_mode 0
}

_make_data_backup() {
    # disable the site for maintenance
    ds exec drush --yes @local_lbd vset maintenance_mode 1

    # clear the cache
    ds exec drush --yes @local_lbd cache-clear all

    # create the backup dir
    local backup="backup-data-$(date +%Y%m%d)"
    rm -rf $backup
    rm -f $backup.tgz
    mkdir $backup

    # copy the data to the backup dir
    ds inject backup.sh $backup

    # make the backup archive
    tar --create --gzip --preserve-permissions --file=$backup.tgz $backup/
    rm -rf $backup/

    # enable the site
    ds exec drush --yes @local_lbd vset maintenance_mode 0
}
