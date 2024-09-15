#!/bin/sh

set -x
set -e

retry_command0() {
    local -r cmd="$@"
    local -i attempt=0
    local -i max_attempts=5
    local -i sleep_time=1  # Initial backoff delay in seconds

    until $cmd; do
        attempt+=1
        if (( attempt > max_attempts )); then
            echo "The command has failed after $max_attempts attempts."
            return 1
        fi
        echo "The command has failed. Retrying in $sleep_time seconds..."
        sleep $sleep_time
        sleep_time=$((sleep_time * 2))  # Double the backoff delay each time
    done
}

git config --global http.version HTTP/1.1
git config --global http.postBuffer 157286400

(cd ~; retry_command0 git clone --depth=1 https://github.com/ocicl/ocicl.git; cd ocicl; sbcl --load setup.lisp; ocicl version; ocicl setup > ~/.sbclrc)
echo "(setf ocicl-runtime:*verbose* t)" >> ~/.sbclrc
echo "(setf ocicl-runtime:*download* t)" >> ~/.sbclrc
~/bin/sbcl --non-interactive --eval "(quit)"

ocicl version

cd /github/workspace

grep "| source" README.org;
if [ $? -eq 0 ]; then
    NAME=$(head -1 README.org | cut -d\  -f2) ;
    PROTOCOL=$(grep "| source" README.org | awk '{ print $4 }' | cut -d: -f1) ;
    URI=$(grep "| source" README.org | awk '{ print $4 }' | cut -d: -f2-) ;
    SYSTEMS=$(grep "| systems" README.org | cut -f3 -d \|) ;
    mkdir src
    cd src
    case ${PROTOCOL} in
        git) retry_command0 git clone ${URI} ;
             VERSION=$(date +%Y%m%d)-$(grep "| commit" ../README.org | awk '{ print $4 }') ;
	           COMMIT=$(grep "| commit" ../README.org | awk '{ print $4 }' );
             SRCDIR=$(ls) ;
             mv ${SRCDIR} ${NAME}-${VERSION} ;
             SRCDIR=$(ls) ;
             cd ${SRCDIR} ;
             git submodule update --init --recursive ;
             echo ${VERSION} > _00_OCICL_VERSION
             echo ${NAME} > _00_OCICL_NAME
             git reset --hard ${COMMIT} ;
             rm -rf .git* ;
             cd .. ;
             tar cvfz ${NAME}-${VERSION}.tar.gz ${SRCDIR} ;
             ;;
        git-lfs) retry_command0 git clone ${URI} ;
             VERSION=$(date +%Y%m%d)-$(grep "| commit" ../README.org | awk '{ print $4 }') ;
	           COMMIT=$(grep "| commit" ../README.org | awk '{ print $4 }' );
             SRCDIR=$(ls) ;
             mv ${SRCDIR} ${NAME}-${VERSION} ;
             SRCDIR=$(ls) ;
             cd ${SRCDIR} ;
             retry_command0 git submodule update --init --recursive ;
             echo ${VERSION} > _00_OCICL_VERSION
             echo ${NAME} > _00_OCICL_NAME
             git reset --hard ${COMMIT} ;
             git lfs install ;
             retry_command0 git lfs fetch ;
             retry_command0 git lfs checkout ;
             rm -rf .git* ;
             cd .. ;
             tar cvfz ${NAME}-${VERSION}.tar.gz ${SRCDIR} ;
             ;;
        file) VERSION=$(grep "| version" ../README.org | awk '{ print $4 }') ;
              curl -L -o source.tar.gz ${URI} ;
              tar xvf source.tar.gz
              rm source.tar.gz
              SRCDIR=$(ls) ;
              mv ${SRCDIR} tmpname
              mv tmpname ${NAME}-${VERSION} ;
              SRCDIR=$(ls) ;
              echo ${VERSION} > _00_OCICL_VERSION
              echo ${NAME} > _00_OCICL_NAME
              tar cvfz ${NAME}-${VERSION}.tar.gz ${SRCDIR} ;
              ;;
        *) echo Unrecognized PROTOCOL ${PROTOCOL} ;
           exit 1 ;
           ;;
    esac ;
    echo "(asdf:initialize-source-registry '(:source-registry :ignore-inherited-configuration (:tree #p\"$(cd ${SRCDIR}; pwd)/\")))" >> ~/.sbclrc ;
    echo ==== .sbclrc ===================================================================
    cat ~/.sbclrc
    # Build each system
    for S in ${SYSTEMS}; do
        echo ================================================================================
        echo Building ${S}
        echo ================================================================================ ;
        ~/bin/sbcl --dynamic-space-size 3584 --non-interactive --eval "(progn (asdf:load-system \"${S}\") (quit))";
    done;
    pwd
    echo ${NAME} > /github/workspace/NAME
    echo ${SYSTEMS} > /github/workspace/SYSTEMS
    echo ${VERSION} > /github/workspace/VERSION
fi
