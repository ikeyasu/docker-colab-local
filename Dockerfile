# Copyright 2018 ikeyasu@gmail.com. All rights reserved.
# -----original license is below----
# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:17.10
MAINTAINER ikeyasu <ikeyasu@gmail.com>

# Container configuration
EXPOSE 8081

# Path configuration
ENV PATH $PATH:/tools/node/bin:/tools/google-cloud-sdk/bin
ENV PYTHONPATH /env/python

# We need to set the gcloud path before disabling the components check below.
# TODO(b/70862907): Drop this custom gcloud directory.
ENV CLOUDSDK_CONFIG /content/datalab/.config

# Assume yes to all apt commands, to avoid user confusion around stdin.
COPY 90assumeyes /etc/apt/apt.conf.d/

# Setup OS and core packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -y -q \
        apt-utils \
        build-essential \
        ca-certificates \
        curl \
        gfortran \
        git \
        google-perftools \
        libatlas-base-dev \
        libcublas8.0 \
        libcudart8.0 \
        libcufft8.0 \
        libcufftw8.0 \
        libcurand8.0 \
        libcusolver8.0 \
        libfreetype6-dev \
        libhdf5-dev \
        liblapack-dev \
        libpng-dev \
        libsm6 \
        libxext6 \
        libxft-dev \
        libxml2-dev \
        openssh-client \
        pkg-config \
        python \
        python-dev \
        python-pip \
        python-setuptools \
        python-zmq \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-zmq \
        rsync \
        ttf-liberation \
        unzip \
        wget \
        zip && \
    mkdir -p /tools

# Setup Google Cloud SDK
# Also apply workaround for gsutil failure brought by this version of Google Cloud.
# (https://code.google.com/p/google-cloud-sdk/issues/detail?id=538) in final step.
RUN wget -nv https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip && \
    unzip -qq google-cloud-sdk.zip -d tools && \
    rm google-cloud-sdk.zip && \
    tools/google-cloud-sdk/install.sh --usage-reporting=false \
        --path-update=false --bash-completion=false && \
    tools/google-cloud-sdk/bin/gcloud -q components update \
        gcloud core bq gsutil compute preview alpha beta && \
    # disable the gcloud update message
    tools/google-cloud-sdk/bin/gcloud config set component_manager/disable_update_check true

# Fetch tensorflow wheels.
RUN gsutil cp gs://colab-tensorflow/2018-03-01T15:50:49-08:00/*whl / && \
    alias pip2=pip && for v in 2 3; do for f in /*tensorflow*-cp${v}*.whl; do pip${v} download -d /tf_deps $f; done; done && unalias pip2

# Update pip and pip3 to avoid noisy warnings for users, and install wheel for
# use below.
RUN pip3 install --upgrade pip wheel && \
    pip2 install --upgrade pip wheel

# Add a global pip.conf to avoid warnings on `pip list` and friends.
COPY pip.conf /etc/

# TODO(b/69087391): Clean up the ordering of the RUN commands below.

# Setup Python packages. One package isn't available from PyPA, so we
# install it manually to save on install time.
#
# Order is important here: we always do the python3 variants *before* the
# python2 ones, so that installed scripts still default to python2.
COPY requirements.txt /
RUN pip2 install -U http://wheels.scipy.org/subprocess32-3.5.0-cp27-cp27mu-manylinux1_x86_64.whl
RUN pip3 install -U --upgrade-strategy only-if-needed --ignore-installed --no-cache-dir -r /requirements.txt && \
    pip2 install -U --upgrade-strategy only-if-needed --ignore-installed --no-cache-dir -r /requirements.txt

# Set up Jupyter kernels for python2 and python3.
RUN python3 -m ipykernel install
RUN python2 -m ipykernel install

# Setup Node.js using LTS 6.10
#    mkdir -p /tools/node && \
#    wget -nv https://nodejs.org/dist/v6.10.0/node-v6.10.0-linux-x64.tar.gz -O node.tar.gz && \
#    tar xzf node.tar.gz -C /tools/node --strip-components=1 && \
#    rm node.tar.gz && \

# Set our locale to en_US.UTF-8.
RUN apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Build a copy of the datalab node app.
#    git clone https://github.com/googlecolab/backend-container /backend-container && \
#    /backend-container/sources/build.sh && \
#    mkdir /datalab && \
#    cp -a /backend-container/build/web/nb /datalab/web && \

# Add some unchanging bits - specifically node modules (that need to be kept in sync
# with packages.json manually, but help save build time, by preincluding them in an
# earlier layer).
#    /tools/node/bin/npm install \
#        ws@1.1.4 \
#        http-proxy@1.13.2 \
#        mkdirp@0.5.1 \
#        node-uuid@1.4.7 \
#        bunyan@1.7.1 \
#        tcp-port-used@0.1.2 \
#        node-cache@3.2.0 && \
#    cd / && \
#    /tools/node/bin/npm install -g forever && \

# Clean up
RUN apt-get autoremove -y && \
    rm -rf /tmp/* && \
    rm -rf /root/.cache/* && \
    cd /

ENV LANG en_US.UTF-8

ADD ipython.py /etc/ipython/ipython_config.py

# Do IPython configuration and install build artifacts
# Then link stuff needed for nbconvert to a location where Jinja will find it.
# I'd prefer to just use absolute path in Jinja imports but those don't work.
RUN ipython profile create default && \
    jupyter notebook --generate-config && \
    mkdir /etc/jupyter
ADD jupyter_notebook_config.py /etc/jupyter

# Add and install build artifacts
ADD content/ /datalab
#RUN cd /datalab/web && /tools/node/bin/npm install && cd /

# Install colabtools.
COPY colabtools /colabtools
RUN cd /colabtools && \
    python2 setup.py sdist && \
    pip3 install /colabtools/dist/google-colab-0.0.1a1.tar.gz && \
    pip2 install /colabtools/dist/google-colab-0.0.1a1.tar.gz && \
    jupyter nbextension install --py google.colab

RUN pip install jupyter_http_over_ws && \
    jupyter serverextension enable --py jupyter_http_over_ws

# Set up our pip/python aliases. We just copy the same file to two places
# rather than play games with symlinks.
ADD pymultiplexer /usr/local/bin/pip
ADD pymultiplexer /usr/local/bin/python

# We customize the chunksize used by googleapiclient for file transfers.
# TODO(b/74067588): Drop this customization.
RUN sed -i -e 's/DEFAULT_CHUNK_SIZE = 512\*1024/DEFAULT_CHUNK_SIZE = 100 * 1024 * 1024/' /usr/local/lib/*/dist-packages/googleapiclient/http.py

# Startup
ENV ENV /root/.bashrc
ENV SHELL /bin/bash
# TensorFlow uses less than half the RAM with tcmalloc relative to (the default)
# jemalloc, so we use it.
ENV LD_PRELOAD /usr/lib/x86_64-linux-gnu/libtcmalloc.so.4
# setup tensorflow
RUN /datalab/run.sh
ENV HOME /content

# Add Tini
ENV TINI_VERSION v0.17.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]
CMD [ "/datalab/start_jupyer.sh" ]
