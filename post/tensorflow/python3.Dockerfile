FROM nvidia/cuda:7.0-cudnn2-devel

# based off official tensorflow image
# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile.devel-gpu
# and using help from https://gist.github.com/erikbern/78ba519b97b440e10640 for python3
MAINTAINER grahama <graham.annett@gmail.com>

RUN apt-get update && apt-get install -y \
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
        python3-pip \
        python3-numpy \
        python3-setuptools \
        software-properties-common \
        swig \
        zip \
        zlib1g-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install \
        ipykernel \
        jupyter \
        matplotlib \
        && \
    python3 -m ipykernel.kernelspec

RUN add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install -y openjdk-8-jdk openjdk-8-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#######
# Build from Source with Bazel
RUN echo "startup --batch" >>/root/.bazelrc

RUN echo "build --spawn_strategy=standalone --genrule_strategy=standalone" \
    >>/root/.bazelrc

ENV BAZELRC /root/.bazelrc
ENV BAZEL_VERSION 0.1.1

WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE.txt && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Download and build TensorFlow.
RUN git clone --recursive https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && \
    git checkout 0.6.0
WORKDIR /tensorflow

# # Configure the build for our CUDA configuration.
ENV CUDA_TOOLKIT_PATH /usr/local/cuda
ENV CUDNN_INSTALL_PATH /usr/local/cuda
ENV TF_NEED_CUDA 1

# https://gist.github.com/erikbern/78ba519b97b440e10640#gistcomment-1667351
RUN sed -i "s#python setup.py bdist_wheel >/dev/null#python3 setup.py bdist_wheel --python-tag py34 >/dev/null#" tensorflow/tools/pip_package/build_pip_package.sh

# need for ./configure
ENV PYTHON_BIN_PATH /usr/bin/python3
ENV TF_CUDA_COMPUTE_CAPABILITIES "3.0"
ENV CUDA_HOME /usr/local/cuda

RUN TF_UNOFFICIAL_SETTING=1 ./configure && \
    bazel build -c opt --config=cuda tensorflow/cc:tutorials_example_trainer && \
    bazel build -c opt --config=cuda tensorflow/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
    pip3 install /tmp/tensorflow_pkg/tensorflow-0.6.0-cp34-cp34m-linux_x86_64.whl

ENV CUDA_PATH /usr/local/cuda
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64

RUN ["/bin/bash"]