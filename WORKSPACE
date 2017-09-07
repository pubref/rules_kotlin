load("//kotlin:java_import_external.bzl", "java_import_external")
load("//kotlin:rules.bzl", "kotlin_repositories")

kotlin_repositories()

maven_jar(
    name = "junit4",
    artifact = "junit:junit:jar:4.12",
)

# Used to demonstrate/test maven dependencies
maven_jar(
    name = "com_google_guava_guava_21_0",
    artifact = "com.google.guava:guava:jar:21.0",
    sha1 = "3a3d111be1be1b745edfa7d91678a12d7ed38709",
)
