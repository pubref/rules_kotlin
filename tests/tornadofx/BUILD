load("@org_pubref_rules_kotlin//kotlin:rules.bzl", "kotlin_binary")

kotlin_binary(
    name = "main",
    main_class = "AppKt",
    srcs = ["App.kt"],
    verbose = 2,
    compile_args = [
        "-jvm-target", "1.8",
    ],
    java_deps = [
        "@tornadofx//:compile", 
    ],
)
