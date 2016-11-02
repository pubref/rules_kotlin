# ################################################################
# Execution phase
# ################################################################

def _kotlin_library_impl(ctx):
    kt_jar = ctx.outputs.kt_jar
    inputs = []
    args = []

    # Single output jar
    args += ["-d", kt_jar.path]

    # Advanced options
    args += ["-X%s" % opt for opt in ctx.attr.x_opts]

    # Plugin options
    for k, v in ctx.attr.plugin_opts:
        args += ["-P"]
        args += ["plugin:%s:%s" % (k, v)]

    # Make classpath if needed, first from this rules, then from
    # dependent rules.
    jars = [] + ctx.attr.jars
    for dep in ctx.attr.deps:
        jars += [jar.files for jar in dep.kt.transitive_jars]
    if jars:
        files = []
        for fileset in jars:
            for file in fileset.files:
                files += [file.path]
        classpath = ":".join(files)
        args += ["-cp", classpath]

    # Need to traverse back up to execroot, then down again
    kotlin_home = ctx.executable._kotlinc.dirname \
                  + "/../../../../../external/com_github_jetbrains_kotlin"
    #args += ["-kotlin-home", kotlin_home]

    # Add in filepaths
    for file in ctx.files.srcs:
        inputs += [file]
        args += [file.path]

    # Make sure jars are listed as inputs for bazel to generate them
    # for us.
    for target in jars:
        inputs += [file for file in target.files]

    # Run the compiler
    ctx.action(
        mnemonic = "KotlinCompile",
        inputs = inputs,
        outputs = [kt_jar],
        executable = ctx.executable._kotlinc,
        arguments = args,
        env = {
            "KOTLIN_HOME": kotlin_home,
        }
    )

    return struct(
        files = set([kt_jar]),
        runfiles = ctx.runfiles(collect_data = True),
        kt = struct(
            srcs = ctx.attr.srcs,
            jar = kt_jar,
            transitive_jars = jars,
            home = kotlin_home,
        ),
    )


def _kotlin_binary_impl(ctx):
    lib_result = _kotlin_library_impl(ctx)
    kt = lib_result.kt
    executable = ctx.outputs.executable

    jars = [kt.jar.path]
    #jars = [ctx.outputs.kt_jar.path]
    for target in kt.transitive_jars:
        for file in target.files:
            jars += [file.path]

    # Not sure thy I have to do this///
    #kotlin = ctx.executable._kotlin.path + "/../bin/kotlin"
    kotlin = "external/com_github_jetbrains_kotlin/bin/kotlin"

    cmd  = [kotlin]
    cmd += ["-cp", ":".join(jars)]
    cmd += ["-J%s" % opt for opt in ctx.attr.jvm_opts]
    cmd += ["-D%s=%s" % (k, v) for k, v in ctx.attr.props]
    cmd += [ctx.attr.main_class]

    ctx.action(
        mnemonic = "KotlinRun",
        inputs = [ctx.outputs.kt_jar],
        outputs = [executable],
        command = " ".join(cmd),
        env = {
            # This is not strictly necessary
            "KOTLIN_HOME": kt.home,
        }
    )

    return struct(
        files = set([executable]) + lib_result.files,
        runfiles = lib_result.runfiles
    )


# ################################################################
# Analysis phase
# ################################################################

kt_filetype = FileType([".kt"])
jar_filetype = FileType([".jar"])
srcjar_filetype = FileType([".jar", ".srcjar"])

_kotlin_library_attrs = {
    # kotlin sources
    "srcs": attr.label_list(
        allow_files = kt_filetype,
    ),

    # Dependent kotlin rules.  ?Can use java_library deps? or just jars?
    "deps": attr.label_list(
        providers = ["kt"],
    ),

    # Not really implemented yet.
    "data": attr.label_list(
        allow_files = True,
        cfg = 'data',
    ),

    # Jars to put on the kotlinc classpath
    "jars": attr.label_list(
        allow_files = jar_filetype,
    ),

    # Advanced options
    "x_opts": attr.string_list(),

    # Plugin options
    "plugin_opts": attr.string_dict(),

    # kotlin compiler (a shell script)
    "_kotlinc": attr.label(
        default=Label("@com_github_jetbrains_kotlin//:kotlinc"),
        executable = True,
        cfg = 'host',
    ),

    # kotlin runner (a shell script)
    "_kotlin": attr.label(
        default=Label("@com_github_jetbrains_kotlin//:kotlin"),
        executable = True,
        cfg = 'host',
    ),

    # kotlin runtime
    "_runtime": attr.label(
        default=Label("@com_github_jetbrains_kotlin//:runtime"),
    ),

}

_kotlin_library_outputs = {
    "kt_jar": "%{name}.jar",
}

_kotlin_library = rule(
    implementation = _kotlin_library_impl,
    attrs = _kotlin_library_attrs,
    outputs = _kotlin_library_outputs,
)

_kotlin_binary = rule(
    implementation = _kotlin_binary_impl,
    attrs = _kotlin_library_attrs + {
        "main_class": attr.string(mandatory = True),
        "jvm_opts": attr.string_list(),
        "props": attr.string_dict(),
    },
    outputs = _kotlin_library_outputs,
    executable = True,
)


def kotlin_library(name, jars = [], **kwargs):

    _kotlin_library(
        name = name,
        jars = jars,
        **kwargs
    )

    native.java_import(
        name = name + "_kt",
        jars = [name + ".jar"] + jars,
        exports = [
            "@com_github_jetbrains_kotlin//:runtime",
        ],
    )

def kotlin_binary(name,
                  jars = [],
                  srcs = [],
                  deps = [],
                  x_opts = [],
                  plugin_opts = {},
                  java_srcs = [],
                  java_deps = [],
                  runtime_deps = [],
                  **kwargs):

    _kotlin_library(
        name = name + "_kt",
        jars = jars,
        srcs = srcs,
        deps = deps,
        x_opts = x_opts,
        plugin_opts = plugin_opts,
    )

    native.java_binary(
        name = name,
        srcs = java_srcs,
        runtime_deps = [
            name + "_kt.jar",
            "@com_github_jetbrains_kotlin//:runtime",
        ] + runtime_deps + jars,
        **kwargs
    )


# ################################################################
# Loading phase
# ################################################################


KOTLIN_BUILD = """
package(default_visibility = ["//visibility:public"])
java_import(
    name = "runtime",
    jars = ["lib/kotlin-runtime.jar"],
)
sh_binary(
    name = "kotlin",
    srcs = ["bin/kotlin"],
)
sh_binary(
    name = "kotlinc",
    srcs = ["bin/kotlinc"],
)
"""

def kotlin_repositories():
    native.new_http_archive(
        name = "com_github_jetbrains_kotlin",
        url = "https://github.com/JetBrains/kotlin/releases/download/build-1.1-M02/kotlin-compiler-1.1-M02.zip",
        sha256 = "cbd656a0dd35a397ec6459592e1074f5f5767fbe87a6377e32c23053d32d011c",
        build_file_content = KOTLIN_BUILD,
        strip_prefix = "kotlinc",
    )
