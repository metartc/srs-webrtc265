#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, shlex, time, subprocess

cmd = "./python.subprocess 0 80000"
args = shlex.split(str(cmd))
print "cmd: %s, args: %s"%(cmd, args)

# the communicate will read all data and wait for sub process to quit.
def use_communicate(args, fout, ferr):
    process = subprocess.Popen(args, stdout=fout, stderr=ferr)
    (stdout_str, stderr_str) = process.communicate()
    return (stdout_str, stderr_str)

# if use subprocess.PIPE, the pipe will full about 50KB data,
# and sub process will blocked, then timeout will kill it.
def use_poll(args, fout, ferr, timeout):
    (stdout_str, stderr_str) = (None, None)
    process = subprocess.Popen(args, stdout=fout, stderr=ferr)
    starttime = time.time()
    while True:
        process.poll()
        if process.returncode is not None:
            (stdout_str, stderr_str) = process.communicate()
            break
        if timeout > 0 and time.time() - starttime >= timeout:
            print "timeout, kill process. timeout=%s"%(timeout)
            process.kill()
            break
        time.sleep(1)
    process.wait()
    return (stdout_str, stderr_str)

# stdout/stderr can be fd, fileobject, subprocess.PIPE, None
fnull = open("/dev/null", "rw")
fout = fnull.fileno()#subprocess.PIPE#fnull#fnull.fileno()
ferr = fnull.fileno()#subprocess.PIPE#fnull#fnull.fileno()
print "fout=%s, ferr=%s"%(fout, ferr)
#(stdout_str, stderr_str) = use_communicate(args, fout, ferr)
(stdout_str, stderr_str) = use_poll(args, fout, ferr, 10)

def print_result(stdout_str, stderr_str):
    if stdout_str is None:
        stdout_str = ""
    if stderr_str is None:
        stderr_str = ""
    print "terminated, size of stdout=%s, stderr=%s"%(len(stdout_str), len(stderr_str))
    while True:
        time.sleep(1)

print_result(stdout_str, stderr_str)
