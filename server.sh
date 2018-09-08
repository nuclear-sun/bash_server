#! /bin/bash

set -f

PORT=5000
PASS=123456

function ret() {
    echo "$@" >> response
}

function log() {
    timestamp="$(date +'%D %T')"
    echo "[${timestamp}] $@" >> log
}

function clear() {
    for pid in $(cat pid); do 
        kill -9 ${pid}
    done
    pids="$(ps -ef | grep 'tailf' | grep -v 'grep' | awk '{print $2}')"
    for pid in ${pids}; do 
        kill -9 ${pid}
    done
}

function main(){
    >pid
    >request
    >response

    nc -lk $PORT > request < <(tailf response) &
    echo $! >> pid

    # context prepare
    authed=0
    while read line ; do
        if ! validate "$line" ; then
            continue
        fi
        if authenticate "$line" ; then
            ret "$(react ${line})"
        else
            ret "Authenticate failed"
        fi
        log "[req] $line, [res] $(tail -1 response)"
    done < <(tailf request)

}

function validate(){
    cmd=$1
    if [[ -z "$cmd" ]]; then
        return 1
    fi
    return 0
}

function authenticate(){
    cmd=$1
    if [[ "$authed" -eq 1 ]]; then
        [[ "$cmd" == "quit" ]] && authed=0  # 退出时取消授权
        return 0
    fi
    if [[ "$cmd" == "auth $PASS" ]]; then
        authed=1
        return 0
    fi
    return 1
}

function react() {
    req="$@"
    #echo "authed: $authed"
    case "$req" in
        auth*)
            echo "Authenticate succeeded."
            ;;
        quit)
            echo "Bye..."
            ;;
        *)
            bash -c "$req" 2>&1
            ;;
    esac
}    

function usage() {
    echo "Usage: $0 port"
}

trap clear SIGINT SIGTERM

if [[ "$1" == "-h" ]]; then 
    usage
    return 0
fi

[[ -n "$1" ]] && PORT="$1"
main "$@"

