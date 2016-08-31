package(default_visibility = ["//visibility:public"])

load("//kotlin:rules.bzl", "kotlin_library", "kotlin_binary")

# A kotlin binary that depends on another kotlin rule (using kotlin
# within kotlin + java within kotlin)
kotlin_binary(
    name = "main_kt",
    main_class = "examples.helloworld.MainKt",
    srcs = ["main.kt"],
    deps = [":rules"],
    jars = [":milk"]
)

# A java rule that depends on a kotlin rule (using kotlin within traditional java)
java_binary(
    name = "main_java",
    main_class = "examples.helloworld.Main",
    srcs = ["Main.java"],
    deps = [":rules_kt"]
)

# A simple kotlin rule that defines "data classes"
kotlin_library(
    name = "rules",
    srcs = ["rules.kt"],
)

# A simple java class that defines soy milk
java_library(
    name = "milk",
    srcs = ["SoyMilk.java"],
)
