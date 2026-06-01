
# Shell wrapper for the `project` binary.
# Needed so `project <name>` (default subcommand: cd) can change the caller's
# working directory — a script cannot do this; only a shell function can.
project() {
    local out
    out=$(command project "$@") || return $?
    case $out in
        __cd__:*) cd "${out#__cd__:}" ;;
        *)        [[ -n $out ]] && print "$out" ;;
    esac
}
