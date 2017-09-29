load("//kotlin:kotlin_repositories.bzl", "kotlin_repositories")

# ################################################################
# Execution phase
# ################################################################

def _kotlin_compile_impl(ctx):
    kt_jar = ctx.outputs.kt_jar
    inputs = []

    args = [
        "KotlinPreloader",
        "-cp", ctx.file._kotlin_compiler.path,
        "org.jetbrains.kotlin.cli.jvm.K2JVMCompiler",
    ]

    # Single output jar
    args += ["-d", kt_jar.path]

    # Advanced options
    args += ["-X%s" % opt for opt in ctx.attr.x_opts]

    # Plugin options
    for k, v in ctx.attr.plugin_opts.items():
        args += ["-P"]
        args += ["plugin:%s=\"%s\"" % (k, v)]

    # Kotlin home - typically the dir
    # 'external/com_github_jetbrains_kotlin'
    args += ["-kotlin-home", ctx.file._kotlin_compiler.dirname + '/..']
    # Add all home libs to sandbox so they are discoverable by the
    # preloader
    inputs += ctx.files._kotlin_home

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
        jarsetlist = depset(jars).to_list()
        args += ["-cp", ":".join([file.path for file in jarsetlist])]
        inputs += jarsetlist

    # Add in filepaths
    for file in ctx.files.srcs:
        inputs += [file]
        args += [file.path]

    # Run the compiler
    ctx.action(
        mnemonic = "KotlinCompile",
        inputs = inputs,
        outputs = [kt_jar],
        executable = ctx.executable._kotlinw,
        execution_requirements = {"supports-workers": "1"},
        arguments = args,
        progress_message="Compiling %d Kotlin source files to %s" % (len(ctx.files.srcs), ctx.outputs.kt_jar.short_path)
    )

    return struct(
        files = depset([kt_jar]),
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

    # Dependent android rules.
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

    # kotlin home (for runtime libraries discovery)
    "_kotlin_home": attr.label(
        default=Label("@com_github_jetbrains_kotlin//:home"),
    ),

    # kotlin compiler jar
    "_kotlin_compiler": attr.label(
        default=Label("@com_github_jetbrains_kotlin//:compiler"),
        single_file = True,
    ),

    # kotlin compiler worker (a java executable defined in this repo)
    "_kotlinw": attr.label(
        default=Label("//java/org/pubref/rules/kotlin:worker"),
        executable = True,
        cfg = 'host',
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


def kotlin_android_library(
    name,
    srcs = [],
    deps = [],
    java_deps = [],
    aar_deps = [],
    resource_files = [],
    custom_package = None,
    manifest = None,
    proguard_specs = [],
    visibility = None,
    **kwargs):

    res_deps = []
    if len(resource_files) > 0:
        native.android_library(
            name = name + "_res",
            custom_package = custom_package,
            manifest = manifest,
            resource_files = resource_files,
            deps = aar_deps + java_deps,
            **kwargs
        )
        res_deps.append(name + "_res")

    native.android_library(
        name = name + "_aar",
        neverlink = 1,
        deps = aar_deps,
    )

    native.java_import(
        name = name + "_sdk",
        neverlink = 1,
        jars = [
            "//tools/defaults:android_jar",
        ],
    )

    kotlin_compile(
        name = name + "_compile",
        srcs = srcs,
        deps = deps,
        java_deps = java_deps + [
            name + "_sdk",
            name + "_aar",
        ],
        android_deps = res_deps,
        **kwargs
    )

    # Convert kotlin deps into java deps
    kt_deps = []
    for dep in deps:
        kt_deps.append(dep + "_kt")

    native.java_import(
        name = name + "_kt",
        jars = [name + "_compile.jar"],
        deps = kt_deps + java_deps,
        visibility = visibility,
        exports = [
            "@com_github_jetbrains_kotlin//:runtime",
        ],
    )

    native.android_library(
        name = name,
        deps = aar_deps + res_deps + [
            name + "_kt",
        ],
        proguard_specs = proguard_specs,
        visibility = visibility,
        **kwargs
    )


def kotlin_library(name, jars = [], java_deps = [], visibility = None, **kwargs):

    kotlin_compile(
        name = name,
        jars = jars,
        java_deps = java_deps,
        visibility = visibility,
        **kwargs
    )

    native.java_import(
        name = name + "_kt",
        jars = [name + ".jar"],
        deps = java_deps,
        visibility = visibility,
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
                  visibility = None,
                  **kwargs):

    kotlin_compile(
        name = name + "_kt",
        jars = jars,
        java_deps = java_deps,
        srcs = srcs,
        deps = deps,
        x_opts = x_opts,
        plugin_opts = plugin_opts,
        visibility = visibility,
    )

    native.java_binary(
        name = name,
        runtime_deps = [name + "_kt.jar"] + java_deps + [
            dep + "_kt"
            for dep in deps
        ] + ["@com_github_jetbrains_kotlin//:runtime"],
        visibility = visibility,
        **kwargs
    )


def kotlin_test(name,
                jars = [],
                srcs = [],
                deps = [],
                x_opts = [],
                plugin_opts = {},
                java_deps = [],
                visibility = None,
                **kwargs):

    java_deps.append("@com_github_jetbrains_kotlin//:test")

    kotlin_compile(
        name = name + "_kt",
        jars = jars,
        java_deps = java_deps,
        srcs = srcs,
        deps = deps,
        x_opts = x_opts,
        plugin_opts = plugin_opts,
        visibility = None,
    )

    native.java_test(
        name = name,
        runtime_deps = [
            name + "_kt.jar",
        ] + java_deps + [dep + "_kt" for dep in deps],
        visibility = None,
        **kwargs
    )
