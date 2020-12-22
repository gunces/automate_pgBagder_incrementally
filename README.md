# How to install pgBagder

>"a fast PostgreSQL log analysis report"

More information for pgBadger visit https://github.com/darold/pgbadger

If there are more PostgreSQL instance on different environment that you require to monitor all SQL, I would suggest you to obtain a new apache server for only show your pgBadger reports on it.

For instance, pgBadger allows to incremental reporting so, possible to collect daily reports and see in one page.

This document doesn't show only installing pgbadger. It'll also direct you for better installation.

# Installation

# Environments

1. PostgreSQL server (Centos 7) 10.0.0.1 -> postgres OS user 
2. pgBadger server (Centos 7) 10.0.0.2 -> pgbadger OS user

## pgBadger Server Environment

```
yum install httpd rsync
service httpd start
systemctl enable httpd
```

Create pgbadger user

```
useradd pgbadger
su – pgbadger
ssh-keygen -t rsa
chmod 700 ~/.ssh
touch ~/.ssh/auhorized_keys
chmod 600 ~/.ssh/auhorized_keys
```

Setup passwordless ssh configuration from PostgreSQL server to pgBadger server as postgres user to pgbadger user. You can googled to passwordless ssh in this step.

Create folder for every PostgreSQL server. You can create folders like server's hostname.

```
mkdir /var/www/html/<database hostname>
chown pgbadger:pgbadger <database hostname>
```

# PostgreSQL Database Server Environment

## Install pgBadger

Before installation do following step.

````
yum install perl-devel
````

1. Go to https://github.com/darold/pgbadger/releases site.

2. install tar.gz format on database server.

3. copy tar.gz file into /opt file

4. Compile from source code

````
tar -xvf /opt/pgbadger-11.2.tar.gz
cd /opt/pgbadger-11.2
perl Makefile.PL
make && sudo make install
````

## Prepare Database Server for pgBadger

Create proper folders for keeping pgBadger HTML files

````
mkdir /var/lib/pgsql/pgbadger
chown postgres:postgres /var/lib/pgsql/pgbadger
chmod 755 /var/lib/pgsql/pgbadger
````

Create runpgbadger.sh file. This file will help to generate HTML file daily with cronjob. 

````
touch /usr/pgsql-11/bin/runpgbadger.sh
chmod 644 /usr/pgsql-11/bin/runpgbadger.sh
chown postgres: /usr/pgsql-11/bin/runpgbadger.sh
````

Main pgBadger script is bellow. 
````
pgbadger --prefix '$LOG_LINE_PREFIX' -I $DATA_DIR/log/postgresql-$YESTERDAY.log  -O $OUTPUT_DIR -f stderr
````

Example of runpgbadger.sh file is bellow. You may change which statement you want or you don't want. For instance if you don't want to see COMMIT, VACCUM, BEGIN statments, you can export them. 

Following shell file generates HTML files in /var/lib/pgsql/pgbadger folder as incremental. 

```
cat /usr/pgsql-11/bin/runpgbadger.sh
#!/bin/bash

########################################################
# Cronjob 					        					        				 #
# 0 1 * * * /bin/bash /usr/pgsql-11/bin/runpgbadger.sh #
########################################################

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`

DBHOST=localhost # or change it
DBPORT=<change port>

# Make hostname uppercase
HOSTNAME=`hostname`
HOSTNAME=($HOSTNAME)
HOSTNAME="${HOSTNAME^^}"
echo "INFO: Hostname $HOSTNAME"

DATA_DIR=/var/lib/pgsql/11/data
OUTPUT_DIR=/var/lib/pgsql/pgbadger
REMOTE_HOST=<pgBadger server ip>
REMOTE_USER="pgbadger"
YESTERDAY=`date +%a --date="-1 day"`
HTML_DIR=/var/www/html/$HOSTNAME
LOG_LINE_PREFIX=`grep -o -P "(?<=log_line_prefix = ').*(?=')" $DATA_DIR/postgresql.conf`

mkdir -p $OUTPUT_DIR
chmod 755 $OUTPUT_DIR
chown postgres: $OUTPUT_DIR

echo "INFO: LOG_LINE_PREFIX '$LOG_LINE_PREFIX'"

if [ -s $DATA_DIR/log/postgresql-$YESTERDAY.log ]

then

psql -h $DBHOST -p $DBPORT -c "SELECT 1"

  if [ $? = 0 ]
  then
        echo "INFO: Processing postgresql-$YESTERDAY.log"
        echo "pgbadger --prefix '$LOG_LINE_PREFIX' -I $DATA_DIR/log/postgresql-$YESTERDAY.log  -O $OUTPUT_DIR -f stderr" | bash
        if [ $? = 0 ]
        then
          rsync -ave ssh $OUTPUT_DIR/* $REMOTE_USER@$REMOTE_HOST:$HTML_DIR
          #rm -r $OUTPUT_DIR/*
        else
          echo "${RED}ERROR: pgbadger can not create report. Exiting.${NC}"
          exit 1
        fi
  else
        echo "${RED}ERROR: Postmaster doesn't work.${NC} "
        exit 1
  fi

  echo "INFO: Add bellow command in crontab if not exists."
  echo "${GREEN}        0 1 * * * /bin/bash /usr/pgsql-11/bin/runpgbadger.sh ${NC}"
  echo

else
  echo "INFO: $DATA_DIR/log/postgresql-$YESTERDAY.log is empty. Exiting pgbadger.."
  echo "INFO: Add bellow command in crontab if not exists."
  echo
  echo "${GREEN}        0 1 * * * /bin/bash /usr/pgsql-11/bin/runpgbadger.sh ${NC}"
  echo
fi
```

Final step is that add following line into your cronjob. It'll run runpgbadger.sh file in every 01:00AM. 

````
0 1 * * * /bin/bash /usr/pgsql-11/bin/runpgbadger.sh
````

Have a nice day!
