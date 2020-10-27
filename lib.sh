# https://github.com/actions/runner/blob/ac1a076a3b63c4f276c4fb28756fcca14305822e/src/Runner.Common/ActionCommand.cs#L19-L24
escapeData() {
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            $'\r') printf "%%0D";;
            $'\n') printf "%%0A";;
            *) printf "$c" ;;
        esac
    done
    LC_COLLATE=$old_lc_collate
}
