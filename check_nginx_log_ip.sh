#!/bin/bash

# 日志格式： [08/Nov/2022:11:43:53

# 配置开始 start

# nginx日志文件
current_log="/var/log/nginx/access.log"
# 脚本文件夹地址
check_sh_dir="/var/log/nginx"
# 缓存一段时间的日志，检查
filter_log="${check_sh_dir}/intercept_ip/for_check_ip.log"
# 记录ip统计数据的文件
malice_access_ips="${check_sh_dir}/intercept_ip/malice_access_ips.log"
# 上次检查时间
lasttime_log="${check_sh_dir}/intercept_ip/last_time.txt"
# 最长检查多少秒之前的日志
max_se=605
# 当访问次数大于此值时，加入屏蔽
max_ip_access=100
# 已设置拒绝访问的IP地址列表数据保存文件
intercept_list_file="${check_sh_dir}/intercept_ip/deny.iplist"
# 限制ip访问的nginx配置文件
intercept_file="/etc/nginx/conf.d/skwx_xianxiao.intercept_ip_list"
# 加入黑名单后多久移出，单位秒
hold_intercept_time=86400
# ip白名单
declare -A ipAllow
#ipAllow["117.133.56.49"]=1;
# ip白名单文件
white_ip_file="/www/skwx_xx/data/ip/team_auth_ip.txt"

# 配置结束 end


# ip黑名单数据
declare -A ipDeny

# 将需要检查的日志放入缓存日志文件
function cache_logs_to_ready
{
    # 清理缓存日志
    echo ''> ${filter_log}

    # 获取检查哪个时间段的日志
    start_time=`/bin/cat ${lasttime_log}`;
    end_time=`date -d "1 minute ago" +%s`;
    max_section=`expr ${end_time} - ${max_se}`;

    # 设置开始的时间
    if [ $start_time -lt $max_section ];
    then
        start_time=${max_section};
    fi

    # 记录本次执行的时间
    date +%s > ${lasttime_log}

    # 检查日志
    do_start=${start_time}
    do_str_time="1/1";
    while [ $do_start -lt $end_time ]; do
        # 检查
        str_time=`date -d @${do_start} +"%d/%b/%Y:%H:%M"`;
        if [ $str_time != $do_str_time ];
        then
            do_str_time=${str_time};
            echo $do_str_time
            /bin/cat ${current_log} | grep "\[${do_str_time#}" >>${filter_log}
        fi

        do_start=`expr ${do_start} + 1`;
    done
}

# 统计ip出现的次数
function count_last_logs
{
    /bin/cat ${filter_log} | awk '{print $1}' | sort -r | uniq -c | sort -r -n | head -300 > ${malice_access_ips}
}

# 将符合条件的ip加入黑名单
function check_ip_to_intercept
{
    # 当前时间
    local now_time=`date +%s`;
    local out_time=`expr ${now_time} - ${hold_intercept_time}`;

    # 加载黑名单
    while read line;
    do
        local in_time=`echo $line | awk '{print $1}'`;
        local in_ip=`echo $line | awk '{print $2}'`;
        if [[ -n ${in_ip} ]]; then
            if [[ ${in_time} -gt ${out_time} ]]; then
                ipDeny[${in_ip}]=${in_time};
            fi
        fi
    done < ${intercept_list_file}

    # 验证
    while read line;
    do
        local access_num=`echo $line | awk '{print $1}'`;
        local access_ip=`echo $line | awk '{print $2}'`;
        if [[ -n ${access_ip} ]]; then
            if [[ ${access_num} -gt ${max_ip_access} ]]; then
                if [[ ! ${ipAllow[${access_ip}]} ]]; then
                    ipDeny[${access_ip}]=${now_time};
                fi
            fi
        fi
    done < ${malice_access_ips}
}

# 更新黑名单文件与nginx拒绝访问配置
function save_intercept_data
{
    echo ''> ${intercept_list_file};
    echo ''> ${intercept_file};

    for i in ${!ipDeny[*]}; do
        echo "${ipDeny[${i}]} ${i};" >> ${intercept_list_file}
        echo "deny ${i};" >> ${intercept_file}
    done
}

# 加载ip白名单配置文件
function set_white_ip_file
{
    if [ -r ${white_ip_file} ]; then
        while read line;
        do
            local ip=`echo $line`;
            if [[ -n ${ip} ]]; then
                ipAllow[${ip}]=1;
            fi
        done < ${white_ip_file}
    fi
}

# 将需要检查的日志放入缓存日志文件
cache_logs_to_ready
# 统计ip出现的次数
count_last_logs
# 加载ip白名单配置文件
set_white_ip_file
# 将符合条件的ip加入黑名单
check_ip_to_intercept
# 更新黑名单文件与nginx拒绝访问配置
save_intercept_data

# 重新载入nginx配置
docker exec nginx sh -c "nginx -s reload";

