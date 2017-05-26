load("//kotlin:kotlin_repositories.bzl", "kotlin_repositories")

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

    # Kotlin home - typically the dir 'external/com_github_jetbrains_kotlin'
    args += ["-kotlin-home", ctx.file._runtime.dirname + '/..']

    # Make classpath if needed.  Include those from this and dependent rules.
    jars = []

    # Populate from (transitive) java dependencies
    for dep in ctx.attr.java_deps:
        # Add-in all source and generated jar files
        for file in dep.files:
            jars.append(file)
        # Add-in transitive dependencies
        for file in dep.java.transitive_deps:
            jars.append(file)

    # Populate from (transitive) kotlin dependencies
    for dep in ctx.attr.deps:
        jars += [file for file in dep.kt.transitive_jars]

    # Populate from jar dependencies
    for fileset in ctx.attr.jars:
        # The fileset object is either a ConfiguredTarget OR a depset.
        files = getattr(fileset, 'files', None)
        if files:
            for file in files:
                jars += [file]
        else:
            for file in fileset:
                jars += [file]

    # Populate from android dependencies
    for dep in ctx.attr.android_deps:
        if dep.android.defines_resources:
            jars.append(dep.android.resource_jar.class_jar)

    if jars:
        # De-duplicate
        jarsetlist = list(set(jars))
        args += ["-cp", ":".join([file.path for file in jarsetlist])]
        inputs += jarsetlist

    # Add in filepaths
    for file in ctx.files.srcs:
        inputs += [file]
        args += [file.path]

    # Add all home libs to sandbox
    inputs += ctx.files._kotlin_home

    # Run the compiler

    if ctx.attr.use_worker:
        ctx.action(
            mnemonic = "KotlinCompile",
            inputs = inputs,
            outputs = [kt_jar],
            executable = ctx.executable._kotlinw,
            execution_requirements={"supports-workers": "1"},
            arguments = ['KotlinCompiler'] + args,
            progress_message="Compiling %d Kotlin source files to %s" % (len(ctx.files.srcs), ctx.outputs.kt_jar.short_path)
        )
    else:
        ctx.action(
            mnemonic = "KotlinCompile",
            inputs = inputs,
            outputs = [kt_jar],
            executable = ctx.executable._kotlinc,
            arguments = args,
        )

    return struct(
        files = set([kt_jar]),
        runfiles = ctx.runfiles(collect_data = True),
        kt = struct(
            srcs = ctx.attr.srcs,
            jar = kt_jar,
            transitive_jars = [kt_jar] + jars,
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

    # Dependent java rules.
    "java_deps": attr.label_list(
        providers = ["java"],
    ),

    # Dependent java rules.
    "android_deps": attr.label_list(
        providers = ["android"],
    ),

    # Not really implemented yet.
    "data": attr.label_list(
        allow_files = True,
        cfg = 'data',
    ),

    # Additional jar files to put on the kotlinc classpath
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

    # kotlin home (for runtime libraries discovery)
    "_kotlin_home": attr.label(
        default=Label("@com_github_jetbrains_kotlin//:home"),
    ),

    # kotlin compiler worker (a java executable defined in this repo)
    "_kotlinw": attr.label(
        default=Label("//java/org/pubref/rules/kotlin:worker"),
        executable = True,
        cfg = 'host',
    ),

    # kotlin runtime
    "_runtime": attr.label(
        default=Label("@com_github_jetbrains_kotlin//:runtime"),
        single_file = True,
    ),

    # Advanced options
    "use_worker": attr.bool(
        default = True,
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


def kotlin_library(name, jars = [], java_deps = [], **kwargs):

    kotlin_compile(
        name = name,
        jars = jars,
        java_deps = java_deps,
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
                  use_worker = False,
                  x_opts = [],
                  plugin_opts = {},
                  java_deps = [],
                  **kwargs):

    kotlin_compile(
        name = name + "_kt",
        jars = jars,
        java_deps = java_deps,
        srcs = srcs,
        deps = deps,
        use_worker = use_worker,
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
