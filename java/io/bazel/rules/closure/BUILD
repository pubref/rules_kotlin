# Copyright 2016 The Closure Rules Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

licenses(["notice"])  # Apache 2.0

java_library(
    name = "BazelWorker",
    srcs = [
        "BazelWorker.java",
    ],
    deps = [
        ":worker_protocol_java_proto",
        "//java/io/bazel/rules/closure/program",
        "@com_google_dagger",
        "@com_google_guava",
        "@javax_inject",
    ],
    visibility = ["//visibility:public"],
)

java_proto_library(
    name = "worker_protocol_java_proto",
    deps = [
        ":worker_protocol_java_proto_library",
    ]
)

proto_library(
    name = "worker_protocol_java_proto_library",
    srcs = ["worker_protocol.proto"],
)
