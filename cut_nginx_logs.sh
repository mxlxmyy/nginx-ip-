#!/bin/bash

# 配置开始 start

# nginx日志文件夹
logs_dir="/var/log/nginx"
# 日志文件名，可配置多个
declare -A logs_name
logs_name[0]="access";

# 配置结束 end


# 当前时间
now_time=`date +%Y%m%d%H%M`;

function re_log_file
{
    local file0="${logs_dir}/${1}.log";
    local redir="${logs_dir}/${1}logs";
    local file1="${redir}/${1}${now_time}.log";
    if [ ! -d ${redir} ]; then
        mkdir ${redir};
    fi

    # 重命名日志文件
    mv ${file0} ${file1}

    # 重置日志
    docker exec nginx bash -c "/var/log/nginx/intercept_ip/kill_nginx_pid.sh"
}

for name in ${logs_name[*]}; do
    re_log_file ${name}
done
