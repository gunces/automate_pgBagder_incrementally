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
