package(default_visibility = ["//visibility:public"])

load("//kotlin:rules.bzl", "kotlin_library", "kotlin_binary")


# A kotlin binary that depends on another kotlin rule (using kotlin
# within kotlin + java within kotlin)
kotlin_binary(
    name = "main_kt",
    main_class = "examples.helloworld.MainKt",
    srcs = ["main.kt"],
    deps = [":rules"],
    java_deps = [":milk"]
)

# A java rule that depends on a kotlin rule (using kotlin within traditional java)
java_binary(
    name = "main_java",
    main_class = "examples.helloworld.Main",
    srcs = ["Main.java"],
    deps = [":rules_kt"],
)

# A simple kotlin rule that defines "data classes"
kotlin_library(
    name = "rules",
    srcs = ["rules.kt"],
    java_deps = [":milk"]
)

# A simple java class that defines soy milk
java_library(
    name = "milk",
    srcs = ["SoyMilk.java"],
)

# A java rule that depends on a kotlin rule (using kotlin within traditional java)
java_test(
    name = "main_test",
    test_class = "examples.helloworld.MainTest",
    srcs = ["MainTest.java"],
    size = "small",
    deps = [
        ":rules_kt",
        "@junit4//jar",
    ]
)
