# ################################################################
# Execution phase
# ################################################################

def _kotlin_compile_impl(ctx):
    kt_jar = ctx.outputs.kt_jar
    inputs = []
    args = []

    # Single output jar
    args += ["-d", kt_jar.path]

    # Advanced options
    args += ["-X%s" % opt for opt in ctx.attr.x_opts]

    # Plugin options
    for k, v in ctx.attr.plugin_opts.items():
        args += ["-P"]
        args += ["plugin:%s=\"%s\"" % (k, v)]

    # Make classpath if needed.  Include those from this rule and from
    # dependent rules.
    jars = [] + ctx.attr.jars
    for dep in ctx.attr.deps:
        jars += [jar.files for jar in dep.kt.transitive_jars]
    if jars:
        jarfiles = []
        for fileset in jars:
            # The fileset object is either a ConfiguredTarget OR a depset.
            files = getattr(fileset, 'files', None)
            if files:
                for file in files:
                    jarfiles += [file.path]
                    inputs += [file]
            else:
                for file in fileset:
                    jarfiles += [file.path]
                    inputs += [file]
        classpath = ":".join(jarfiles)
        args += ["-cp", classpath]

    # Need to traverse back up to execroot, then down again
    kotlin_home = ctx.executable._kotlinc.dirname \
                  + "/../../../../../external/com_github_jetbrains_kotlin"

    # Add in filepaths
    for file in ctx.files.srcs:
        inputs += [file]
        args += [file.path]

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


# ################################################################
# Analysis phase
# ################################################################

kt_filetype = FileType([".kt"])
jar_filetype = FileType([".jar"])
srcjar_filetype = FileType([".jar", ".srcjar"])

_kotlin_compile_attrs = {
    # kotlin sources
    "srcs": attr.label_list(
        allow_files = kt_filetype,
    ),

    # Dependent kotlin rules.
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

    # kotlin runtime
    "_runtime": attr.label(
        default=Label("@com_github_jetbrains_kotlin//:runtime"),
    ),

}


_kotlin_compile_outputs = {
    "kt_jar": "%{name}.jar",
}


kotlin_compile = rule(
    implementation = _kotlin_compile_impl,
    attrs = _kotlin_compile_attrs,
    outputs = _kotlin_compile_outputs,
)


def _make_jars_list_from_java_deps(deps = []):
    jars = []
    for dep in deps:
        path = ""
        basename = dep
        if dep.find(":") >= 0:
            parts = dep.split(':')
            path = parts[0] if len(parts) > 0 else ""
            basename = parts[1]
        jars.append("%s:lib%s.jar" % (path, basename))
    return jars


def kotlin_library(name, jars = [], java_deps = [], **kwargs):

    kotlin_compile(
        name = name,
        jars = jars + _make_jars_list_from_java_deps(java_deps),
        **kwargs
    )

    native.java_import(
        name = name + "_kt",
        jars = [name + ".jar"],
        deps = java_deps,
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
                  java_deps = [],
                  **kwargs):

    java_library_jars = _make_jars_list_from_java_deps(java_deps)

    kotlin_compile(
        name = name + "_kt",
        jars = jars + java_library_jars,
        srcs = srcs,
        deps = deps,
        x_opts = x_opts,
        plugin_opts = plugin_opts,
    )

    native.java_binary(
        name = name,
        runtime_deps = [
            name + "_kt.jar",
            "@com_github_jetbrains_kotlin//:runtime",
        ] + java_deps,
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
        url = "https://github.com/JetBrains/kotlin/releases/download/v1.1/kotlin-compiler-1.1.zip",
        sha256 = "aa44db28bf3ccdae8842b6b92bec5991eb430a80e580aafbc6a044678a2f359d",
        build_file_content = KOTLIN_BUILD,
        strip_prefix = "kotlinc",
    )
