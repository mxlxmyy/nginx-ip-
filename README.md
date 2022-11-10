# 使用说明
统计nginx日志中ip请求次数，加入黑名单。

## 文件说明
检查日志脚本文件：
check_nginx_log_ip.sh

拆分日志脚本文件：
cut_nginx_logs.sh

日志生成脚本文件：
kill_nginx_pid.sh

缓存日志文件：
for_check_ip.log

记录ip统计数据：
malice_access_ips.log

已设置拒绝访问的IP地址列表数据保存文件
deny.iplist

上次检查时间：
last_time.txt，在初次使用时请设置为0。

ip白名单配置文件示例：
allow_ip.txt

定时任务运行日志：
runlogs.log

## 使用步骤：
1. 将文件夹上传到服务器，修改脚本文件中的文件配置路径。
2. 在nginx配置文件夹中新建文件“site.intercept_ip_list”，用于设置需要拦截的ip地址。
3. 将文件包含到网站的nginx配置中。
`
include site.intercept_ip_list
`
4. 设置定时执行“check_nginx_log_ip.sh”脚本。
`
命令行输入：
crontab -uroot -e
定时任务设置：
运行环境，可不设置
SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
十分钟运行一次检查日志
*/10 * * * * /home/logs/nginx114/intercept_ip/check_nginx_log_ip.sh >> /home/logs/nginx114/intercept_ip/runlogs.log 2>&1
每天23时38分运行拆分日志，拆分日志时间应避开检查日志的时间
38 23 * * * /home/logs/nginx114/intercept_ip/cut_nginx_logs.sh
`
## 脚本执行过程：
1. 按照设置的时间段从nginx日志文件中查询日志并写入到缓存日志文件中。
2. 统计缓存日志文件中的ip请求次数。
3. 加载白名单配置文件。
4. 读取已设置黑名单的ip和设置时间，移出超出限制时间的ip。
5. 验证最近一段时间内请求超出限制次数的ip，加入黑名单。
6. 保存黑名单数据，更新nginx配置。
7. 重新载入nginx配置。重新载入nginx配置的命令需要根据自身服务器情况设置。