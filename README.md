# 使用说明
脚本文件：
check_nginx_log_ip.sh

缓存日志文件：
for_check_ip.log

记录ip统计数据：
malice_access_ips.log

上次检查时间：
last_time.txt，在初次使用时请设置为0。

## 使用步骤：
1. 将文件夹上传到服务器，修改脚本文件中的文件配置路径。
2. 在nginx配置文件夹中新建文件“site.intercept_ip_list”，用于设置需要拦截的ip地址。
3. 将文件包含到网站的nginx配置中，“include site.intercept_ip_list”。
4. 设置定时执行“check_nginx_log_ip.sh”脚本。

## 脚本执行过程：
1. 按照设置的时间段从nginx日志文件中查询日志并写入到缓存日志文件中。
2. 统计缓存日志文件中的ip请求次数。
3. 将超过访问次数限制的ip加入到nginx配置文件“site.intercept_ip_list”中。
4. 重新载入nginx配置。重新载入nginx配置的命令需要根据自身服务器情况设置。