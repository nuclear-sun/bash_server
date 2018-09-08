#! /bin/bash

function parse(){
    conf_file=$1

    size=$(grep -c -E '^host=' "$conf_file")
    hosts=($(grep -E '^host=' "$conf_file"))
    ports=($(grep -E '^port=' "$conf_file"))
    inputs=($(grep -E '^input=' "$conf_file"))
    outputs=($(grep -E '^output=' "$conf_file"))

    for((i=0; i<size; i++)); do
        host=${hosts[$i]##*=}
        port=${ports[$i]##*=}
        input=${inputs[$i]##*=}
        output=${outputs[$i]##*=}
        echo "nc ${host} ${port} > ${output} "
    done
}

function dispatch(){
    inpipe=$1
    conf_file=$2

    cmd="cat $inpipe | tee "
    while read line; do
        cmd="$cmd >($line) "
    done < <(parse $conf_file)
    echo "$cmd"
}

[[ ! -p req ]] && mkfifo req
final_cmd=$(dispatch req conf.ini)
echo ${final_cmd}
exec bash -c "${final_cmd}"

# 之后将内容写到命名管道 req 即可发送到各个服务器

