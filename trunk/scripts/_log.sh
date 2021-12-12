# import log utility and check the detail log file is ok
# @param log the log file path, default to /dev/null

#######################################
# color echo.
#######################################
RED="\\033[31m"
GREEN="\\033[32m"
YELLOW="\\033[33m"
BLACK="\\033[0m"
POS="\\033[94G"

# if need to log to file, change the log path.
if [[ ! $log ]]; then
    log=/dev/null;
fi

ok_msg(){
    echo -e "${1}${POS}${BLACK}[${GREEN}  OK  ${BLACK}]"
    
    # write to log file.
    echo "[info] ${1}" >> $log
}

warn_msg(){
    echo -e "${1}${POS}${BLACK}[ ${YELLOW}WARN${BLACK} ]"
    
    # write to log file.
    echo "[error] ${1}" >> $log
}

failed_msg(){
    echo -e "${1}${POS}${BLACK}[${RED}FAILED${BLACK}]"
    
    # write to log file.
    echo "[error] ${1}" >> $log
}

function check_log(){
    log_dir="`dirname $log`"
    (mkdir -p ${log_dir} && chmod 777 ${log_dir} && touch $log)
    ret=$?; if [[ $ret -ne 0 ]]; then failed_msg "create log failed, ret=$ret"; return $ret; fi
    ok_msg "create log( ${log} ) success"
    
    echo "bravo-vms setup `date`" >> $log
    ok_msg "see detail log: tailf ${log}"
    
    return 0
}
