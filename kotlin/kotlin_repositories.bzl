load("//kotlin:java_import_external.bzl", "java_import_external")

KOTLIN_BUILD = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "home",
    srcs = glob(["lib/*.jar"]),
)
java_import(
    name = "runtime",
    jars = ["lib/kotlin-runtime.jar"],
)
java_import(
    name = "stdlib",
    jars = ["lib/kotlin-stdlib.jar"],
)
java_import(
    name = "compiler",
    jars = ["lib/kotlin-compiler.jar"],
)
java_import(
    name = "preloader",
    jars = ["lib/kotlin-preloader.jar"],
)
java_import(
    name = "test",
    jars = ["lib/kotlin-test.jar"],
)
sh_binary(
    name = "kotlin",
    srcs = ["bin/kotlin"],
)
sh_binary(
    name = "kotlinc",
    srcs = ["bin/kotlinc"],
)
exports_files(["src"])
"""


def kotlin_repositories(
        com_github_jetbrains_kotlin_url = "https://github.com/JetBrains/kotlin/releases/download/v1.1.4-3/kotlin-compiler-1.1.4-3.zip",
        com_github_jetbrains_kotlin_sha256 = "f4ceab8a21ad26a25712a1499999a726cea918be7bec022937f9ae5ca0c943ea",
        omit_com_github_jetbrains_kotlin = False,
        omit_com_google_protobuf = False,
        omit_com_google_protobuf_java = False,
        omit_javax_inject = False,
        omit_com_google_errorprone_error_prone_annotations = False,
        omit_com_google_code_findbugs_jsr305 = False,
        omit_com_google_guava = False,
        omit_com_google_dagger = False,
        omit_com_google_dagger_compiler = False,
        omit_com_google_dagger_producers = False,
):

    if not omit_com_github_jetbrains_kotlin:
        native.new_http_archive(
            name = "com_github_jetbrains_kotlin",
            url = com_github_jetbrains_kotlin_url,
            sha256 = com_github_jetbrains_kotlin_sha256,
            build_file_content = KOTLIN_BUILD,
            strip_prefix = "kotlinc",
        )

    if not omit_com_google_protobuf:
        # proto_library rules implicitly depend on @com_google_protobuf//:protoc,
        # which is the proto-compiler.
        # This statement defines the @com_google_protobuf repo.
        native.http_archive(
            name = "com_google_protobuf",
            urls = ["https://github.com/google/protobuf/archive/a6189acd18b00611c1dc7042299ad75486f08a1a.zip"],
            strip_prefix = "protobuf-a6189acd18b00611c1dc7042299ad75486f08a1a",
            sha256 = "102b5024120215c5a34ad23d9dd459e8ccc37dc3ef4c73d466ab802b6e3e9512",
        )

    if not omit_com_google_protobuf_java:
        # java_proto_library rules implicitly depend on @com_google_protobuf_java//:java_toolchain,
        # which is the Java proto runtime (base classes and common utilities).
        native.http_archive(
            name = "com_google_protobuf_java",
            urls = ["https://github.com/google/protobuf/archive/a6189acd18b00611c1dc7042299ad75486f08a1a.zip"],
            strip_prefix = "protobuf-a6189acd18b00611c1dc7042299ad75486f08a1a",
            sha256 = "102b5024120215c5a34ad23d9dd459e8ccc37dc3ef4c73d466ab802b6e3e9512",
        )

    if not omit_javax_inject:
        java_import_external(
            name = "javax_inject",
            licenses = ["notice"],  # Apache 2.0
            jar_urls = [
                "http://bazel-mirror.storage.googleapis.com/repo1.maven.org/maven2/javax/inject/javax.inject/1/javax.inject-1.jar",
                "http://repo1.maven.org/maven2/javax/inject/javax.inject/1/javax.inject-1.jar",
                "http://maven.ibiblio.org/maven2/javax/inject/javax.inject/1/javax.inject-1.jar",
            ],
            jar_sha256 = "91c77044a50c481636c32d916fd89c9118a72195390452c81065080f957de7ff",
        )

    if not omit_com_google_errorprone_error_prone_annotations:
        java_import_external(
            name = "com_google_errorprone_error_prone_annotations",
            licenses = ["notice"],  # Apache 2.0
            jar_sha256 = "e7749ffdf03fb8ebe08a727ea205acb301c8791da837fee211b99b04f9d79c46",
            jar_urls = [
                "http://bazel-mirror.storage.googleapis.com/repo1.maven.org/maven2/com/google/errorprone/error_prone_annotations/2.0.15/error_prone_annotations-2.0.15.jar",
                "http://maven.ibiblio.org/maven2/com/google/errorprone/error_prone_annotations/2.0.15/error_prone_annotations-2.0.15.jar",
                "http://repo1.maven.org/maven2/com/google/errorprone/error_prone_annotations/2.0.15/error_prone_annotations-2.0.15.jar",
            ],
        )

    if not omit_com_google_code_findbugs_jsr305:
        java_import_external(
            name = "com_google_code_findbugs_jsr305",
            licenses = ["notice"],  # BSD 3-clause
            jar_urls = [
                "http://bazel-mirror.storage.googleapis.com/repo1.maven.org/maven2/com/google/code/findbugs/jsr305/1.3.9/jsr305-1.3.9.jar",
                "http://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/1.3.9/jsr305-1.3.9.jar",
                "http://maven.ibiblio.org/maven2/com/google/code/findbugs/jsr305/1.3.9/jsr305-1.3.9.jar",
            ],
            jar_sha256 = "905721a0eea90a81534abb7ee6ef4ea2e5e645fa1def0a5cd88402df1b46c9ed",
        )

    if not omit_com_google_guava:
        java_import_external(
            name = "com_google_guava",
            licenses = ["notice"],  # Apache 2.0
            jar_urls = [
                "http://bazel-mirror.storage.googleapis.com/repo1.maven.org/maven2/com/google/guava/guava/20.0/guava-20.0.jar",
                "http://repo1.maven.org/maven2/com/google/guava/guava/20.0/guava-20.0.jar",
                "http://maven.ibiblio.org/maven2/com/google/guava/guava/20.0/guava-20.0.jar",
            ],
            jar_sha256 = "36a666e3b71ae7f0f0dca23654b67e086e6c93d192f60ba5dfd5519db6c288c8",
            deps = [
                "@com_google_code_findbugs_jsr305",
                "@com_google_errorprone_error_prone_annotations",
            ],
        )

    if not omit_com_google_dagger:
        java_import_external(
            name = "com_google_dagger",
            jar_sha256 = "8b7806518bed270950002158934fbd8281725ee09909442f2f22b58520b667a7",
            jar_urls = [
                "http://bazel-mirror.storage.googleapis.com/repo1.maven.org/maven2/com/google/dagger/dagger/2.9/dagger-2.9.jar",
                "http://repo1.maven.org/maven2/com/google/dagger/dagger/2.9/dagger-2.9.jar",
            ],
            licenses = ["notice"],  # Apache 2.0
            deps = ["@javax_inject"],
            generated_rule_name = "runtime",
            extra_build_file_content = "\n".join([
                "java_library(",
                "    name = \"com_google_dagger\",",
                "    exported_plugins = [\"@com_google_dagger_compiler//:ComponentProcessor\"],",
                "    exports = [",
                "        \":runtime\",",
                "        \"@javax_inject\",",
                "    ],",
                ")",
            ]),
        )

    if not omit_com_google_dagger_compiler:
        java_import_external(
            name = "com_google_dagger_compiler",
            jar_sha256 = "afe356def27710db5b60cad8e7a6c06510dc3d3b854f30397749cbf0d0e71315",
            jar_urls = [
                "http://bazel-mirror.storage.googleapis.com/repo1.maven.org/maven2/com/google/dagger/dagger-compiler/2.9/dagger-compiler-2.9.jar",
                "http://repo1.maven.org/maven2/com/google/dagger/dagger-compiler/2.9/dagger-compiler-2.9.jar",
            ],
            licenses = ["notice"],  # Apache 2.0
            deps = [
                "@com_google_code_findbugs_jsr305",
                "@com_google_dagger//:runtime",
                "@com_google_dagger_producers//:runtime",
                "@com_google_guava",
            ],
            extra_build_file_content = "\n".join([
                "java_plugin(",
                "    name = \"ComponentProcessor\",",
                # TODO(jart): https://github.com/bazelbuild/bazel/issues/2286
                # "    output_licenses = [\"unencumbered\"],",
                "    processor_class = \"dagger.internal.codegen.ComponentProcessor\",",
                "    generates_api = 1,",
                "    tags = [",
                "        \"annotation=dagger.Component;genclass=${package}.Dagger${outerclasses}${classname}\",",
                "        \"annotation=dagger.producers.ProductionComponent;genclass=${package}.Dagger${outerclasses}${classname}\",",
                "    ],",
                "    deps = [\":com_google_dagger_compiler\"],",
                ")",
            ]),
        )

    if not omit_com_google_dagger_producers:
        java_import_external(
            name = "com_google_dagger_producers",
            jar_sha256 = "b452dc1b95dd02f6272e97b15d1bd35d92b5f484a7d69bb73887b6c6699d8843",
            jar_urls = [
                "http://bazel-mirror.storage.googleapis.com/repo1.maven.org/maven2/com/google/dagger/dagger-producers/2.9/dagger-producers-2.9.jar",
                "http://repo1.maven.org/maven2/com/google/dagger/dagger-producers/2.9/dagger-producers-2.9.jar",
            ],
            licenses = ["notice"],  # Apache 2.0
            deps = [
                "@com_google_dagger//:runtime",
                "@com_google_guava",
            ],
            generated_rule_name = "runtime",
            extra_build_file_content = "\n".join([
                "java_library(",
                "    name = \"com_google_dagger_producers\",",
                "    exported_plugins = [\"@com_google_dagger_compiler//:ComponentProcessor\"],",
                "    exports = [",
                "        \":runtime\",",
                "        \"@com_google_dagger//:runtime\",",
                "        \"@javax_inject\",",
                "    ],",
                ")",
            ]),
        )
