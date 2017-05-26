java_binary(
    name = "worker",
    srcs = [
        "KotlinWorker.java",
    ],
    main_class = "org.pubref.rules.kotlin.KotlinWorker",
    visibility = ["//visibility:public"],
    deps = [
        ":compiler",
        ":preloader",
        "//java/io/bazel/rules/closure:BazelWorker",
        "//java/io/bazel/rules/closure/program",
        "@com_google_dagger",
        "@com_google_guava",
        "@javax_inject",
    ],
)

java_library(
    name = "compiler",
    srcs = [
        "KotlinCompiler.java",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//java/io/bazel/rules/closure/program",
        "@com_google_guava",
        "@com_github_jetbrains_kotlin//:compiler",
    ],
)

java_library(
    name = "preloader",
    srcs = [
        "KotlinPreloader.java",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//java/io/bazel/rules/closure/program",
        "@com_google_guava",
        "@com_github_jetbrains_kotlin//:preloader",
    ],
)
