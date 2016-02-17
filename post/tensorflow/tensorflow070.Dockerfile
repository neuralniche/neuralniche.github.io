FROM nvidia/cuda:7.5-cudnn4-devel

# based off official tensorflow image
# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile.devel-gpu
# and using help from https://gist.github.com/erikbern/78ba519b97b440e10640 for python3
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
        # python3-pip \
        # python3-setuptools \
        python3-numpy \
        swig \
        zip \
        zlib1g-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py

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
ENV BAZEL_VERSION 0.1.5

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
    git checkout r0.7
WORKDIR /tensorflow

# # # Configure the build for our CUDA configuration.
# # https://gist.github.com/erikbern/78ba519b97b440e10640#gistcomment-1667351
# sed was previously necessary but doesn't seem like it is anymore
# RUN sed -i "s#${PYTHON_BIN_PATH:-python} setup.py bdist_wheel >/dev/null#${PYTHON_BIN_PATH:-python3} setup.py bdist_wheel >/dev/null#" tensorflow/tools/pip_package/build_pip_package.sh
# # need for ./configure
ENV CUDA_TOOLKIT_PATH /usr/local/cuda-7.5
ENV CUDNN_INSTALL_PATH /usr/lib/x86_64-linux-gnu
ENV TF_NEED_CUDA 1
#
ENV PYTHON_BIN_PATH /usr/bin/python3
ENV TF_CUDA_COMPUTE_CAPABILITIES "3.0"
# ENV CUDA_HOME /usr/local/cuda-7.5
RUN ln -s /usr/include/cudnn.h /usr/lib/x86_64-linux-gnu/cudnn.h

RUN TF_UNOFFICIAL_SETTING=1 ./configure && \
    bazel build -c opt --config=cuda tensorflow/cc:tutorials_example_trainer && \
    bazel build -c opt --config=cuda tensorflow/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
    pip3 install /tmp/tensorflow_pkg/tensorflow-0.7.0-py3-none-any.whl

#############
# Keras stuff, separating although could easily be condensed into previous sections or keras image build on top could be done as well (probably preferable)
RUN apt-get update && apt-get install -y \
    python3-scipy \
    libhdf5-dev \
    libyaml-dev \
    libjpeg-dev \
    gfortran \
    libopenblas-dev \
    liblapack-dev

RUN pip3 install --pre \
    # installing pydicom for medical imagine kaggle competition
    pydicom \
    cython \
    scikit-image

# need to install seperate from previous pip3 install otherwise fails
RUN pip3 install h5py

RUN pip3 install --upgrade --pre git+git://github.com/fchollet/keras.git@master

RUN mkdir ~/.keras/ && echo '{"backend": "tensorflow"}' > ~/.keras/keras.json

WORKDIR /root/

# ENV CUDA_PATH /usr/local/cuda
# ENV LD_LIBRARY_PATH /usr/local/cuda/lib64

RUN ["/bin/bash"]