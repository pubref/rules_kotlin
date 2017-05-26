/*
 * Copyright 2017 The Kotlin Rules Authors. All rights reserved.
 * Copyright 2016 The Closure Rules Authors. All rights reserved.
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

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import dagger.Component;
import dagger.Module;
import dagger.Provides;
import io.bazel.rules.closure.BazelWorker;
import io.bazel.rules.closure.BazelWorker.Mnemonic;
import io.bazel.rules.closure.program.CommandLineProgram;
import java.io.PrintStream;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import javax.inject.Inject;
import javax.inject.Provider;

/** Bazel worker utility. */
public final class KotlinWorker implements CommandLineProgram {

  private final PrintStream output;

  @Inject
  KotlinWorker(PrintStream output) {
    this.output = output;
  }

  @Override
  public Integer apply(Iterable<String> args) {
    String head = Iterables.getFirst(args, "");
    Iterable<String> tail = Iterables.skip(args, 1);
    // TODO(pcj): Do we ever expect a different compiler here?  Maybe
    // experiment with incremental compiler.
    switch (head) {
      case "KotlinCompiler":
        return new KotlinCompiler().apply(tail);
      default:
        output.println(
            "\nERROR: First flag to KotlinWorker should be specific compiler to run, "
                + "e.g. KotlinCompiler\n");
        return 1;
    }
  }

  @Module
  static class Config {

    @Provides
    @Mnemonic
    static String provideMnemonic() {
      return "Kotlin";
    }

    @Provides
    static PrintStream provideOutput() {
      return System.err;
    }

    @Provides
    static FileSystem provideFileSystem() {
      return FileSystems.getDefault();
    }
  }

  @Component(modules = Config.class)
  interface Server {
    BazelWorker<KotlinWorker> worker();
  }

  public static void main(String[] args) {
    System.exit(DaggerKotlinWorker_Server.create().worker().apply(ImmutableList.copyOf(args)));
  }
}
