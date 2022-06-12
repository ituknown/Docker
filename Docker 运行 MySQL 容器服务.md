```bash
docker run -d \
    -p 3306:3306 \
    --name mysql \
    -e MYSQL_ROOT_PASSWORD=admin123 \
    -v /opt/mysql/datadir:/var/lib/mysql \
    -v /opt/mysql/mysql.conf.d:/etc/mys mysql.conf.d \
    mysql:5.7
```

其实运行 mysql、redis 这类容器最主要的就是做目录映射（也叫挂载），即将宿主机的某个目录与容器中的某个目录进行挂载来达到交互的目的。

在 mysql 容器中，主要有两个我们需要关注的目录：

- `/var/lib/mysql/`：用于存储 mysql 数据
- `/etc/mysql/`：mysql 配置文件

所以在运行容器时我们只需要创建两个相应的目录与容器的这两个目录进行映射即可，这里我选择的是 `/opt/mysql/datadir` 和 `/opt/mysql/mysql.conf.d`（如果两个目录不存在需要先创建才能挂载，否则容器会运行失败）。

在宿主机中 `/opt/mysql/mysql.conf.d` 目录下创建一个配置文件，用于替换容器内的默认配置：

```bash
$ ls mysql.conf.d/
mysqld.cnf
```

`mysqld.cnf` 就是普通的配置文件，也可以直接使用 `Docker` 的 `copy` 命令将容器默认的配置文件（`/var/lib/mysql`）拷贝出来进行适当修改即可：

```bash
$ docker container cp -a 容器:容器内部地址 宿主机地址
```

示例：

```bash
$ docker container cp -a mysq:/etc/mysql/mysql.conf.d /opt/temp
```

之后就能在 `/opt/temp` 目录下看到配置文件内容了。

示例配置文件：

```properties
# Copyright (c) 2014, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2.0,
# as published by the Free Software Foundation.
#
# This program is also distributed with certain software (including
# but not limited to OpenSSL) that is licensed under separate terms,
# as designated in a particular file or component or in included license
# documentation.  The authors of MySQL hereby grant you an additional
# permission to link the program and your derivative works with the
# separately licensed software that they have included with MySQL.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License, version 2.0, for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

[client]

# password=


# 客户端编码
default-character-set=utf8mb4

[mysql]

default-character-set=utf8mb4

[mysqld]

character-set-server = utf8mb4
init_connect = "SET NAMES utf8mb4"
collation-server = utf8mb4_unicode_ci
character-set-client-handshake = false

pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql

#log-error      = /var/log/mysql/error.log
# By default we only accept connections from localhost
#bind-address   = 127.0.0.1
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
```
