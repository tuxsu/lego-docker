#!/command/with-contenv sh
set -e

is_valid_var() {
    case "$1" in
        [A-Za-z_]*)
            case "$1" in
                *[!A-Za-z0-9_]*) return 1 ;;
                *) return 0 ;;
            esac ;;
        *) return 1 ;;
    esac
}

extract_domain() {
    echo "$1" | grep -oP '(-d|--domains)[= ]+["'\'']?([0-9a-z.*-]+)' | head -1 | awk -F'[= ]' '{print $2}' | tr -d '"' | tr -d "'"
}

get_cert_path() {
    local D=$(echo "$1" | sed 's/\*/_/g')
    echo "/.lego/certificates/${D}.crt"
}

parse_args() {
	local _arg_out_name=$1
    local _env_out_name=$2
    local _env_out=$3
	shift 3

	local _args=""
    local _envs_name=""
    local _envs=""

	for item in "$@"; do
        if [[ "$item" == *=* ]] && [[ "$item" != -* ]]; then
            local key=${item%%=*}
            local val=${item#*=}
            if is_valid_var "$key"; then
                _envs_name="${_envs_name} ${key}"
				_envs="${_envs} $key=$val"
            else
                _args="${_args} ${item}"
            fi
        else
            _args="${_args} ${item}"
        fi
    done

	eval "$_arg_out_name=\"$(echo "$_args" | xargs)\""
    eval "$_env_out_name=\"$(echo "$_envs_name" | xargs)\""
    eval "$_env_out=\"$(echo "$_envs" | xargs)\""
}
