#!/usr/bin/python

#
# Copyright (c) 2013-2021 Winlin
#
# SPDX-License-Identifier: MIT
#

#################################################################################
# to stat the code and comments lines
#################################################################################
import sys, os, cs
from cs import info, trace
    
if __name__ != "__main__":
    print "donot support lib"
    sys.exit(-1)
    
filters="*.*pp,*.h,*.c,*.cc"
except_filters="utest,doc"
if len(sys.argv) <= 1:
    print "to stat the code and comments lines"
    print "Usage: python %s <dir> [filters] [except_filters]"%(sys.argv[0])
    print "     dir: the dir contains the files to stat"
    print "     filters: the file filters, default: *.*pp,*.h,*.c,*.cc"
    print "     except_filters: the except file filters, default: utest,doc"
    print "Example:"
    print "     python %s src"%(sys.argv[0])
    print "     python %s src *.*pp,*.cc utest,doc"%(sys.argv[0])
    sys.exit(-1)
    
dir = sys.argv[1]
if len(sys.argv) > 2:
    filters = sys.argv[2]
if len(sys.argv) > 3:
    except_filters = sys.argv[3]
info("stat dir:%s, filters:%s, except_filters:%s"%(dir, filters, except_filters))

# filters to array
filters = filters.split(",")
except_filters = except_filters.split(",")

# find src -name "*.*pp"|grep -v utest
(totals, stat_codes, commentss, stat_block_commentss, stat_line_commentss) = (0, 0, 0, 0, 0)
for filter in filters:
    cmd = 'find %s -name "%s"'%(dir, filter)
    for ef in except_filters:
        cmd = '%s|%s'%(cmd, 'grep -v "%s"'%(ef))
    cmd = "%s 2>&1"%(cmd)
    info("scan dir, cmd:%s"%cmd)
    
    pipe = os.popen(cmd)
    files = pipe.read()
    info("scan dir, files:%s"%files)
    pipe.close()
    
    files = files.split("\n")
    for file in files:
        file = file.strip()
        if len(file) == 0:
            continue;
        info("start stat file:%s"%file)
        (code, total, stat_code, comments, stat_block_comments, stat_line_comments, code_file) = cs.do_stat(file)
        if code != 0:
            continue;
        totals += total
        stat_codes += stat_code
        commentss += comments
        stat_block_commentss += stat_block_comments
        stat_line_commentss += stat_line_comments

if totals == 0:
    trace("no code or comments found.")
else:
    trace("total:%s code:%s comments:%s(%.2f%%) block:%s line:%s"%(
        totals, stat_codes, commentss, commentss * 100.0 / totals, stat_block_commentss, stat_line_commentss
    ))
