# 使用说明
统计nginx日志中ip请求次数，加入黑名单。

## 文件说明
**检查日志脚本文件**
> check_nginx_log_ip.sh

**拆分日志脚本文件**
> cut_nginx_logs.sh

**日志生成脚本文件**
> kill_nginx_pid.sh

**缓存日志文件**
> for_check_ip.log

**记录一段时间内ip访问统计**
> malice_access_ips.log

**未在白名单中的ip**
> malice_access_ips2.log

**符合加入黑名单的ip**
> malice_access_ips3.log

**过滤白名单ip的缓存文件**
> allow_ips_contrast.log

**已设置拒绝访问的IP地址列表数据保存文件**
> deny.iplist

**上次检查时间，在初次使用时请设置为0**
> last_time.txt

**ip白名单配置文件示例**
> allow_ip.txt

**定时任务运行日志**
> runlogs.log

## 使用步骤：
1. 将文件夹上传到服务器，修改脚本文件中的配置。
> 标记在“配置开始 start”与“配置开始 end”之间的变量为配置项

2. 在nginx配置文件夹中新建文件“site.intercept_ip_list”，用于设置需要拦截的ip地址。文件名称可自定义，只需要在脚本配置中设置正确即可。

3. 将第二步中新建的文件包含到网站的nginx配置中。
```
server {
    listen 80;
    ...
	include site.intercept_ip_list
	...
}
```

4. 设置定时执行“check_nginx_log_ip.sh”脚本。
+ 命令行输入：
```
crontab -uroot -e
```
+ 定时任务设置：
运行环境，可不设置
```
SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
```
十分钟运行一次检查日志
```
*/10 * * * * /home/logs/nginx114/intercept_ip/check_nginx_log_ip.sh >> /home/logs/nginx114/intercept_ip/runlogs.log 2>&1
```
每天23时38分运行拆分日志，拆分日志时间应避开检查日志的时间
```
38 23 * * * /home/logs/nginx114/intercept_ip/cut_nginx_logs.sh
```

## 脚本执行过程：
1. 按照设置的时间段从nginx日志文件中查询日志并写入到缓存日志文件中。
2. 统计缓存日志文件中的ip请求次数。
3. 加载白名单配置文件。
4. 读取已设置黑名单的ip和设置时间，移出超出限制时间的ip。
5. 验证最近一段时间内请求超出限制次数的ip，加入黑名单。
6. 保存黑名单数据，更新nginx配置。
7. 重新载入nginx配置。重新载入nginx配置的命令需要根据自身服务器情况设置。

## 配置说明
1. **check_nginx_log_ip.sh 脚本中的配置**
+ **current_log：**nginx的日志文件地址。
+ **check_sh_dir：**脚本文件所在的文件夹地址。
+ **max_se：**最长检查多少秒之前的日志。代码执行时会以分钟为单位来计算，如果脚本执行时间为“2022年10月1日 12时30分”，当设置“60”时，则表示检查当前时间前一分钟的日志，即“12时29分”生成的日志，当设置“300”时，则表示计算当前时间前十分钟的日志，即“12时20分到12时29分”生成的日志。
+ **max_ip_access：**时间段内最大允许的访问次数，当统计的日志中ip访问次数大于此值时，则需要将ip加入黑名单。
+ **intercept_file：**限制ip访问的nginx配置文件，即上文中新建的文件“site.intercept_ip_list”的地址。
+ **hold_intercept_time：**ip被加入黑名单后多少秒移出黑名单。如果在加入黑名单后，ip再次触发访问上限，则此时间将会被重置。
+ **ipAllow：**ip白名单。可在脚本中设置哪些ip不会不会被加入黑名单。设置格式“ipAllow["117.133.56.49"]=1;”。
+ **white_ip_file：**ip白名单文件。也可设置单独的白名单列表文件，文件的ip格式参考“allow_ip.txt”。
+ 另，脚本运行最后需要nginx重载配置，脚本默认执行“docker exec nginx sh -c "nginx -s reload";”，请根据服务器nginx部署情况修改。

2. **cut_nginx_logs.sh 脚本中的配置**
+ **logs_dir：**nginx日志文件夹地址。
+ **logs_name：**日志文件名，可配置多个，示例：“logs_name[0]="access1";logs_name[1]="access2";logs_name[2]="access3";”。