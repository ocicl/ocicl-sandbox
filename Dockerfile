FROM ubuntu

MAINTAINER Anthony Green <green@moxielogic.com>

ENV LC_ALL=C.utf8 \
    LANG=C.utf8 \
    LANGUAGE=C.utf8 \
    SBCL_VERSION=2.3.4 \
    DUCKDB_VERSION=0.8.1 \
    BB_PYTHON3_INCLUDE_DIR=/usr/include/python3.10 \
    BB_PYTHON3_DYLIB=/usr/lib/x86_64-linux-gnu/libpython3.10.so

RUN apt-get update \
    && apt-get install -y libffi-dev libclblas-dev libuv1-dev \
                          libev-dev libglu-dev freeglut3-dev libgl1-mesa-dev \
                          libglfw3-dev libunac1-dev libtidy-dev \
                          libfixposix-dev golang ca-certificates curl git \
                          make python3-dev libmysqlclient-dev libgit2-dev \
                          libyaml-dev libzmq3-dev libgsl-dev libhdf5-dev unzip \
                          libsdl2-dev libcairo2-dev libgtk2.0-dev \
                          gobject-introspection libsdl2-image-dev

RUN curl -L -O https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/libduckdb-linux-amd64.zip \
    && unzip libduckdb-linux-amd64.zip -d /usr/lib \
    && rm libduckdb-linux-amd64.zip


WORKDIR /github/workspace

RUN go install -v github.com/sigstore/rekor/cmd/rekor-cli@latest
RUN curl -L -O "https://downloads.sourceforge.net/project/sbcl/sbcl/${SBCL_VERSION}/sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2" \
    && tar -xf sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2 \
    && cd sbcl-${SBCL_VERSION}-x86-64-linux \
    && ./install.sh --prefix=$HOME \
    && cd .. \
    && rm -rf sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2 sbcl-${SBCL_VERSION}-x86-64-linux

ADD run.sh /usr/bin/run.sh

ENV PATH="${PATH}:/root/.local/bin:/root/bin:/root/go/bin"

CMD /usr/bin/run.sh
