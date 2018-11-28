# customize/extend command 'ds remake'

cmd_remake_help() {
    cat <<_EOF
    remake
        Rebuild the container, preserving the existing content.

_EOF
}

rename_function cmd_remake orig_cmd_remake
cmd_remake() {
    orig_cmd_remake "$@"
    ds inject fix-file-permissions.sh
    ds wsproxy ssl-cert
}
