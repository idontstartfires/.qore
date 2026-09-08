
# Shell wrapper for the `project` binary.
# Needed so `project <name>` (default subcommand: cd) can change the caller's
# working directory — a script cannot do this; only a shell function can.
#
# The binary runs with stdin/stdout/stderr attached to the terminal so that
# interactive subcommands (ide, agent, nav, git) work. The `cd` subcommand
# communicates its target out-of-band by writing it to $PROJECT_CD_FILE,
# which we read and act on after the binary exits.
project() {
    local cdfile rc
    cdfile=$(mktemp "${TMPDIR:-/tmp}/project-cd.XXXXXX") || return 1
    PROJECT_CD_FILE=$cdfile command project "$@"; rc=$?
    [[ -s $cdfile ]] && cd -- "$(<$cdfile)"
    rm -f -- "$cdfile"
    return $rc
}
