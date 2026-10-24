# degust

Golden files and end-to-end program fixtures for Jello, on `std.testing`.

_For golden files, see Max Grigorev at ZuriHac, 2010_

- `degust.Golden` compares output with a golden file. `--update` rewrites the
  golden file.
- `degust.Programs` compiles every fixture under a directory, then checks and
  runs each one. Each fixture and each mode it runs in gets its own subtest.

## Use

Name degust in your project's `jello.json`. It is for your own tests, so it
goes in `dev_dependencies`, which the projects that use yours never fetch:

```json
{
  "name": "app",
  "version": "0.1.0",
  "dev_dependencies": {
    "degust": {"github": "Lazarus404/degust", "tag": "0.1.0"}
  }
}
```

```sh
jelloc deps.get          # degust lands in packages/degust
```

Write a test that runs your fixtures:

```jello
import type { Test } from std.testing;
import { run } from degust.Programs;

let testPrograms = fn(t: Test) { run(t, "tests/programs"); null };
```

`jelloc test` builds every test with the project's sources and packages as
roots, and runs them. Arguments after the first `--` go to the test binary,
such as `-v` or `--run NAME`; after the second, name the compiler and the VM:

```sh
jelloc test -- -- --compiler jelloc --vm "$(command -v jello)"
```

Tests in the same binary that run the compiler or the VM themselves, such as
checks of the compiler's command line, read the same options through
`compiler()`, `stdDir()`, `outDir()`, `modes()` and `jloTool()`, and run a
module as the fixtures do with `vmCommand(mode, [module, args...])` and
`vmEnv()`, and check one as they do with `checkCommand(dump, module)` and
`checkEnv()`.

## Fixtures

A fixture is one of:

- a `.jello` file;
- a directory holding `main.jello`, whose other files are its modules;
- a hand-written `.jlo.txt` module.

Directories named `auxiliary` hold no fixtures. Use them for the files that
fixtures share. A fixture states what it expects in comment lines at its top:

```jello
// expect: 42
// flags: --path $DIR/auxiliary
// A program's tail value is its output.
40 + 2
```

The full set of directives is documented at the top of
[src/degust/Programs.jello](src/degust/Programs.jello): `expect`, `stderr`,
`golden`, `status`, `trap`, `called`, `error`, `warning`, `args`, `flags`, `modes`,
`gc`, `finalizes` and `pending`. The runner's options are documented there too.

## Development

`scripts/test.sh` runs degust's own tests from this directory. It needs a
Jello toolchain:

- `JELLOC`: the compiler, as words (default `jelloc`);
- `JELLO`: the VM (default `jello` on `PATH`), with `jlo_tool` and
  `std.jdll` beside it;
- `JELLO_STD_PATH`: the standard library, where the compiler looks for it.

`scripts/test.sh --update` rewrites `tests/expected/*.out` from the current
run.

## Note

Jello and Degust are in heavy development, so do expect it to change.
