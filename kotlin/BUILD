package(default_visibility = ["//visibility:public"])

java_binary(
    name = "kotlinc",
    main_class = "org.jetbrains.kotlin.cli.jvm.K2JVMCompiler",
    jvm_flags = [
        "-Xmx256M",
        "-Xms32M",
    ],
    runtime_deps = [
        "@com_github_jetbrains_kotlin//:compiler",
    ]
)
