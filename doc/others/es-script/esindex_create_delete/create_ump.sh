#!/bin/bash
echo "`date` create_ump_index start ..."
python /home/snsoadmin/shell/create_ump_index.sh
echo "`date` create_ump_index end ..."

wait

echo "`date` create_ump_alias start ..."
python /home/snsoadmin/shell/create_ump_alias.sh
echo "`date` create_ump_alias end ..."
