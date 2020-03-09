#!/bin/bash
#
# Server Bash Library
#
# Copyright (c) 2017 timi <emomeild@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# * Neither the name of Linode LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific prior
# written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

###########################################################
# System
###########################################################

function system_update {
    yes y | sudo yum update
    # EPEL repo
    yes y | sudo yum install epel-release
    yes y | yum install wget
    yes y | yum install unzip
}

###########################################################
# mysql-server
# reference https://linode.com/docs/databases/mysql/how-to-install-mysql-on-centos-7/
###########################################################

function mysql_install {
    wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
    sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm
    yes y | yum update
    
    yes y | sudo yum install -y mysql-server
    sudo systemctl start mysqld
    
    mysql -u root -e "SET PASSWORD FOR root@'localhost' = PASSWORD('$1');"
}

function mysql_create_database {
    # $1 - the mysql root password
    # $2 - the db name to create

    if [ ! -n "$1" ]; then
        echo "mysql_create_database() requires the root pass as its first argument"
        return 1;
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_database() requires the name of the database as the second argument"
        return 1;
    fi

    echo "CREATE DATABASE $2;" | mysql -u root -p$1
}

function mysql_create_user {
    # $1 - the mysql root password
    # $2 - the user to create
    # $3 - their password

    if [ ! -n "$1" ]; then
        echo "mysql_create_user() requires the root pass as its first argument"
        return 1;
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_user() requires username as the second argument"
        return 1;
    fi
    if [ ! -n "$3" ]; then
        echo "mysql_create_user() requires a password as the third argument"
        return 1;
    fi

    echo "CREATE USER '$2'@'localhost' IDENTIFIED BY '$3';" | mysql -u root -p$1
}

function mysql_grant_user {
    # $1 - the mysql root password
    # $2 - the user to bestow privileges 
    # $3 - the database

    if [ ! -n "$1" ]; then
        echo "mysql_create_user() requires the root pass as its first argument"
        return 1;
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_user() requires username as the second argument"
        return 1;
    fi
    if [ ! -n "$3" ]; then
        echo "mysql_create_user() requires a database as the third argument"
        return 1;
    fi

    echo "GRANT ALL PRIVILEGES ON $3.* TO '$2'@'localhost';" | mysql -u root -p$1
    echo "FLUSH PRIVILEGES;" | mysql -u root -p$1

}

###########################################################
# Java
###########################################################

function java_install {
  yes y | yum install -y java-1.8.0-openjdk
  
  # install jdk devel, so jps can use
  yum -y install java-1.8.0-openjdk-devel.x86_64
}

###########################################################
# maven
# reference http://maven.apache.org/download.cgi
###########################################################

function maven_install {
  wget http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
  
  sudo mkdir /opt/apache-maven-3.6.2
  
  sudo tar xvf apache-maven-3.6.2-bin.tar.gz -C /opt/apache-maven-3.6.2 --strip-components=1
  
  echo 'MAVEN_HOME=/opt/apache-maven-3.6.2' >> ~/.bash_profile 
  echo 'export MAVEN_HOME' >> ~/.bash_profile  
  echo 'PATH=$PATH:$MAVEN_HOME/bin' >> ~/.bash_profile
  echo 'export PATH' >> ~/.bash_profile
  source ~/.bash_profile
}

###########################################################
# Tomcat
# reference https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-8-on-centos-7
###########################################################

function tomcat_install {
  wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.24/bin/apache-tomcat-8.5.24.tar.gz

  sudo mkdir /opt/tomcat

  sudo tar xvf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1

  # sed -i 's/port="8080"/port="80"/' /opt/tomcat/conf/server.xml

  # boot
  cur_dir="$pwd"
  cd /opt/tomcat/bin
  ./startup.sh
  cd $cur_dir

  # ./shutdown.sh
}

###########################################################
# Nginx
# reference 
#https://segmentfault.com/a/1190000007803704
#https://www.hugeserver.com/kb/install-nginx-page-speed-centos/
###########################################################

function nginx_install {
  
  yum  -y install gcc
  
  yum -y install pcre-devel openssl openssl-devel
  
  wget https://nginx.org/download/nginx-1.12.2.tar.gz

  sudo mkdir /usr/local/nginx
  sudo mkdir nginx-1.12.2

  sudo tar zxvf nginx-1.12.2.tar.gz
 
  cur_dir="$pwd"

  cd nginx-1.12.2

  ./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module 
  make && make install

  # When the installation process is finished you have to create Nginx symlinks:
  ln -s /usr/local/nginx/conf/ /etc/nginx
  ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
  
  cd ..
  rm -rf nginx-1.*

  # boot
  /usr/sbin/nginx

  cd $cur_dir
}

###########################################################
# Redis
# reference https://linode.com/docs/databases/redis/install-and-configure-redis-on-centos-7/
###########################################################

function redis_install {

  # Install Redis:
  sudo yum -y install redis

  # Start Redis:
  sudo systemctl start redis

  # Optional: To automatically start Redis on boot:
  sudo systemctl enable redis

  # Configure Redis

  ## Persistence Options
  cat <<EOT >> /etc/redis.conf
appendonly yes
appendfsync everysec
EOT

  sudo systemctl restart redis

  ## Basic System Tuning
  sudo echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
  
  ##Use Password Authentication
  ## https://linode.com/docs/databases/redis/install-and-configure-redis-on-centos-7/#use-password-authentication
  ## /etc/redis.conf
  ## requirepass master_password
  ## Start Redis:
  ## sudo systemctl start redis

}

###########################################################
# Gradle 4.5.1
# reference https://www.jianshu.com/p/9d31b202e5ea
###########################################################

function gradle_install {
    wget https://downloads.gradle-dn.com/distributions/gradle-4.5.1-all.zip
    mkdir /opt/gradle 
    unzip -d /opt/gradle gradle-4.5.1-bin.zip
    echo 'PATH=$PATH:/opt/gradle/gradle-4.5.1/bin' >> /etc/profile
    echo 'export PATH' >> /etc/profile
    source /etc/profile
}
