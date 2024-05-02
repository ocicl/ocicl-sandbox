#!/bin/sh

set -x
set -e

(cd ~; git clone --depth=1 https://github.com/ocicl/ocicl.git; cd ocicl; make; make install; ocicl version; ocicl setup > ~/.sbclrc)
echo "(setf ocicl-runtime:*verbose* t)" >> ~/.sbclrc
echo "(setf ocicl-runtime:*download* t)" >> ~/.sbclrc
~/bin/sbcl --non-interactive --eval "(quit)"

ocicl version

cd /github/workspace

grep "| source" README.org;
if [ $? -eq 0 ]; then
    NAME=$(head -1 README.org | cut -d\  -f2) ;
    SYSTEMS=$(grep "| systems" README.org | cut -f3 -d \|) ;
    SYSTEM=$(echo ${SYSTEMS} | cut -d " " -f1);
    CURRENT=$(ocicl list cl-ppcre | head -3 | tail -1)
    PREVIOUS=$(ocicl list cl-ppcre | head -4 | tail -1)
    if [ "X${CURRENT}" != "X" ] && [ "X${PREVIOUS}" != "X" ]; then
        ~/bin/sbcl --non-interactive --load /usr/share/compare.lisp
    fi
fi
