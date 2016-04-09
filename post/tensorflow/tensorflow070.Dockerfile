FROM grahama/cuda:base
##### label this one:
## grahama/cuda:tf
#########################
MAINTAINER grahama <graham.annett@gmail.com>

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
    # using master instead of r0.7
    git checkout master

WORKDIR /tensorflow
##### Configure the build for our CUDA configuration.

# # need for ./configure to run without input
ENV CUDA_TOOLKIT_PATH /usr/local/cuda-7.5
ENV CUDNN_INSTALL_PATH /usr/lib/x86_64-linux-gnu
ENV TF_NEED_CUDA 1
ENV PYTHON_BIN_PATH /usr/bin/python3
ENV TF_CUDA_COMPUTE_CAPABILITIES "3.0"
RUN ln -s /usr/include/cudnn.h /usr/lib/x86_64-linux-gnu/cudnn.h

RUN TF_UNOFFICIAL_SETTING=1 ./configure && \
    bazel build -c opt --config=cuda tensorflow/cc:tutorials_example_trainer && \
    bazel build -c opt --config=cuda tensorflow/tools/pip_package:build_pip_package && \
    bazel build -c opt --config=cuda tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
    pip3 install /tmp/tensorflow_pkg/*.whl && \
    rm -rf /tmp/

WORKDIR /root/

## Delete from Build
RUN rm -rf /root/.cache /tensorflow/ /bazel/

RUN ["/bin/bash"]