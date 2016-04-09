FROM nvidia/cuda:7.5-cudnn4-devel
##### label this one:
## grahama/cuda:base
#########################
MAINTAINER grahama <graham.annett@gmail.com>

RUN apt-get update && apt-get install -y \
        software-properties-common \
        build-essential \
        curl \
        git \
        wget \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python3 \
        python3-dev \
        python3-numpy \
        python3-scipy \
        swig \
        zip \
        zlib1g-dev \
        libhdf5-dev \
        libyaml-dev \
        libjpeg-dev \
        gfortran \
        libopenblas-dev \
        liblapack-dev \
        libhdf5-dev \
        libjpeg-dev \
        vim \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
        python3 get-pip.py && \
        rm -rf get-pip.py

RUN pip3 install --pre \
        ipykernel \
        jupyter \
        matplotlib \
        cython \
        && \
    python3 -m ipykernel.kernelspec

# cant remember exactly but need to install after cython installs i believe
RUN pip3 install h5py Pillow

# for image manipulation with keras stuff
RUN pip3 install --pre scikit-image

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /root/