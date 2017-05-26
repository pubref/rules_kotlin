/*
 * Copyright 2017 PubRef.org. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.pubref.rules.kotlin;

import com.google.common.collect.Iterables;
import io.bazel.rules.closure.program.CommandLineProgram;
import org.jetbrains.kotlin.cli.common.ExitCode;
import org.jetbrains.kotlin.cli.jvm.K2JVMCompiler;

/**
 * CommandLineProgram Wrapper for the K2JVMCompiler.
 */
public final class KotlinCompiler implements CommandLineProgram {

  @Override
  public Integer apply(Iterable<String> args) {
    K2JVMCompiler compiler = new K2JVMCompiler();
    ExitCode exitCode = compiler.exec(System.err, Iterables.toArray(args, String.class));
    return exitCode.getCode();
  }

}
