/*
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

package io.bazel.rules.closure;

import static java.nio.charset.StandardCharsets.UTF_8;

import com.google.common.base.CharMatcher;
import com.google.common.base.Joiner;
import com.google.common.base.Throwables;
import com.google.common.collect.Iterables;
import com.google.devtools.build.lib.worker.WorkerProtocol.WorkRequest;
import com.google.devtools.build.lib.worker.WorkerProtocol.WorkResponse;
import io.bazel.rules.closure.program.CommandLineProgram;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InterruptedIOException;
import java.io.PrintStream;
import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import javax.inject.Inject;
import javax.inject.Qualifier;

/**
 * Bazel worker runner.
 *
 * <p>This class adapts a traditional command line program so it can be spawned by Bazel as a
 * persistent worker process that handles multiple invocations per JVM. It will also be backwards
 * compatible with being run as a normal single-invocation command.
 *
 * @param <T> delegate program type
 */
public final class BazelWorker<T extends CommandLineProgram> implements CommandLineProgram {

  /** Qualifier for name of Bazel persistent worker. */
  @Qualifier
  @Retention(RetentionPolicy.RUNTIME)
  @Documented
  public @interface Mnemonic {}

  private final CommandLineProgram delegate;
  private final String mnemonic;
  private final PrintStream output;

  @Inject
  public BazelWorker(T delegate, PrintStream output, @Mnemonic String mnemonic) {
    this.delegate = delegate;
    this.output = output;
    this.mnemonic = mnemonic;
  }

  @Override
  public Integer apply(Iterable<String> args) {
    if (Iterables.contains(args, "--persistent_worker")) {
      return runAsPersistentWorker();
    } else {
      return delegate.apply(loadArguments(args, false));
    }
  }

  private int runAsPersistentWorker() {
    InputStream realStdIn = System.in;
    PrintStream realStdOut = System.out;
    PrintStream realStdErr = System.err;
    try (InputStream emptyIn = new ByteArrayInputStream(new byte[0]);
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        PrintStream ps = new PrintStream(buffer)) {
      System.setIn(emptyIn);
      System.setOut(ps);
      System.setErr(ps);
      while (true) {
        WorkRequest request = WorkRequest.parseDelimitedFrom(realStdIn);
        if (request == null) {
          return 0;
        }
        int exitCode = 0;
        Iterable<String> args = loadArguments(request.getArgumentsList(), true);
        try {
          exitCode = delegate.apply(args);
        } catch (RuntimeException e) {
          if (wasInterrupted(e)) {
            return 0;
          }
          System.err.println(
              String.format("ERROR: Worker threw uncaught exception with args: %s",
                  Joiner.on(' ').join(args)));
          e.printStackTrace(System.err);
          exitCode = 1;
        }
        WorkResponse.newBuilder()
            .setOutput(buffer.toString())
            .setExitCode(exitCode)
            .build()
            .writeDelimitedTo(realStdOut);
        realStdOut.flush();
        buffer.reset();
        System.gc();  // be a good little worker process and consume less memory when idle
      }
    } catch (IOException | RuntimeException e) {
      if (wasInterrupted(e)) {
        return 0;
      }
      Throwables.throwIfUnchecked(e);
      throw new RuntimeException(e);
    } finally {
      System.setIn(realStdIn);
      System.setOut(realStdOut);
      System.setErr(realStdErr);
    }
  }

  private Iterable<String> loadArguments(Iterable<String> args, boolean isWorker) {
    String lastArg = Iterables.getLast(args, "");
    if (lastArg.startsWith("@")) {
      Path flagFile = Paths.get(CharMatcher.is('@').trimLeadingFrom(lastArg));
      if ((isWorker && lastArg.startsWith("@@")) || Files.exists(flagFile)) {
        if (!isWorker && !mnemonic.isEmpty()) {
          output.printf(
              "HINT: %s will compile faster if you run: "
                  + "echo \"build --strategy=%s=worker\" >>~/.bazelrc\n",
              mnemonic, mnemonic);
        }
        try {
          return Files.readAllLines(flagFile, UTF_8);
        } catch (IOException e) {
          throw new RuntimeException(e);
        }
      }
    }
    return args;
  }

  private boolean wasInterrupted(Throwable e) {
    Throwable cause = Throwables.getRootCause(e);
    if (cause instanceof InterruptedException
        || cause instanceof InterruptedIOException) {
      output.println("Terminating worker due to interrupt signal");
      return true;
    }
    return false;
  }
}
