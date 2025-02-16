FROM ubuntu:jammy

MAINTAINER Anthony Green <green@moxielogic.com>

ENV LC_ALL=C.utf8 \
    LANG=C.utf8 \
    LANGUAGE=C.utf8 \
    SBCL_VERSION=2.4.11 \
    REKOR_VERSION=1.3.7 \
    DUCKDB_VERSION=1.1.3 \
    RAYLIB_VERSION=5.5 \
    BB_PYTHON3_INCLUDE_DIR=/usr/include/python3.10 \
    BB_PYTHON3_DYLIB=/usr/lib/x86_64-linux-gnu/libpython3.10.so \
    ORAS_VERSION="1.2.1"

RUN apt-get update \
    && apt-get install -y libffi-dev libclblas-dev libuv1-dev \
                          libev-dev libglu-dev freeglut3-dev libgl1-mesa-dev \
                          libglfw3-dev libunac1-dev libtidy-dev \
                          libfixposix-dev golang-1.20 ca-certificates curl \
                          git git-lfs protobuf-compiler \
                          make python3-dev libmysqlclient-dev libgit2-dev \
                          libyaml-dev libzmq3-dev libgsl-dev libhdf5-dev unzip \
                          libsdl2-dev libcairo2-dev libgtk2.0-dev \
                          gobject-introspection libsdl2-image-dev \
                          libsdl2-mixer-dev libblas-dev liblapack-dev \
                          libfluidsynth-dev liballegro5-dev libsdl2-ttf-dev \
                          libsecp256k1-dev libfuse-dev libmagic-dev \
                          gfortran libmecab-dev libsdl1.2-compat-dev \
                          liblz-dev libtermbox-dev libgtk-4-1 libwebkit2gtk-4.1-dev \
                          libsybdb5 liblmdb-dev libturbojpeg-dev libcmark-dev \
                          wget libmigemo-dev cmigemo pandoc diffutils libfcgi \
                          librocksdb-dev libtree-sitter-dev portaudio19-dev \
                          libportmidi-dev libfftw3-dev liblilv-dev \
                          libenchant-2-dev libassimp-dev librdkafka-dev \
                          cmake libabsl-dev libz3-dev


RUN curl -LO "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
    && mkdir -p oras-install/ \
    && tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/ \
    && mv oras-install/oras /usr/local/bin/ \
    && rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/

RUN curl -L -O https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/libduckdb-linux-amd64.zip \
    && unzip libduckdb-linux-amd64.zip -d /usr/lib \
    && rm libduckdb-linux-amd64.zip

RUN curl -LOs https://github.com/raysan5/raylib/archive/refs/tags/${RAYLIB_VERSION}.tar.gz \
    && tar xf ${RAYLIB_VERSION}.tar.gz \
    && cd raylib-${RAYLIB_VERSION}/src \
    && make all install PLATFORM=PLATFORM_DESKTOP RAYLIB_LIBTYPE=SHARED \
    && cd - && rm -fr raylib-${RAYLIB_VERSION}

RUN curl -LO "https://github.com/sigstore/rekor/releases/download/v${REKOR_VERSION}/rekor-cli-linux-amd64" \
    && mv rekor-cli-linux-amd64 /usr/local/bin/rekor-cli \
    && chmod +x /usr/local/bin/rekor-cli

WORKDIR /github/workspace

RUN curl -L -O "https://downloads.sourceforge.net/project/sbcl/sbcl/${SBCL_VERSION}/sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2" \
    && tar -xf sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2 \
    && cd sbcl-${SBCL_VERSION}-x86-64-linux \
    && ./install.sh --prefix=$HOME \
    && cd .. \
    && rm -rf sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2 sbcl-${SBCL_VERSION}-x86-64-linux

ADD run.sh /usr/bin/run.sh
ADD make-compare.sh /usr/bin/make-compare.sh
ADD compare.lisp /usr/share/compare.lisp

RUN echo "(setq *enable-jack-midi* t)" > ~/.incudinerc

RUN mkdir -p /root/.ssh && touch /root/.ssh/trivial_ssh_hosts

ENV PATH="${PATH}:/root/.local/bin:/root/bin:/root/go/bin"

CMD /usr/bin/run.sh
