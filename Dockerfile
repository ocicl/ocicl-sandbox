FROM ubuntu

MAINTAINER Anthony Green <green@moxielogic.com>

ENV LC_ALL=C.utf8 \
    LANG=C.utf8 \
    LANGUAGE=C.utf8 \
    SBCL_VERSION=2.3.4

RUN apt-get update \
    && apt-get install -y libffi-dev libclblas-dev libuv1-dev \
                          libev-dev libglu-dev freeglut3-dev libgl1-mesa-dev libglfw3-dev \
                          libunac1-dev libtidy-dev libfixposix-dev golang \
                          ca-certificates curl git make python-dev

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
