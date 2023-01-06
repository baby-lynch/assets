#!/bin/bash

# -l: output in log
# -m: checking memory leak with valgrind
# -d: debug with gdb

APP=nginx
APP_alias=cdn-alpha
if [ -f ${APP} ]; then
    mv ${APP} ${APP_alias}
    APP=${APP_alias}
    # echo ${APP}
else
    APP=${APP_alias}
fi

chmod 777 ${APP}
case "$1" in
"-l") ./${APP} >${APP}.log ;;
"-m") valgrind --log-file=valgrind.log --tool=memcheck --leak-check=full --show-leak-kinds=all ./${APP} ;;
"-d") gdb ./${APP} ;;
"") ./${APP} ;;
esac
