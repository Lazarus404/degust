# degust

Golden files and end-to-end program fixtures for Jello, on `std.testing`.

_For golden files, see Max Grigorev at ZuriHac, 2010_

- `degust.Golden` compares output with a golden file. `--update` rewrites the
  golden file.
- `degust.Programs` compiles every fixture under a directory, then checks and
  runs each one. Each fixture and each mode it runs in gets its own subtest.

## Use

Depend on degust in `jello.json` and fetch it:

```json
{
  "name": "app",
  "version": "0.1.0",
  "dependencies": { "degust": "0.1.0" }
}
```

```sh
jlo_tool get-deps          # degust lands in packages/degust
```

Write a test that runs your fixtures:

```jello
import type { Test } from std.testing;
import { run } from degust.Programs;

let testPrograms = fn(t: Test) { run(t, "tests/programs"); null };
```

Build the test binary with degust's sources as a root, then run it. After
`--`, name the compiler and the VM:

### MacOS:
```sh
jelloc --test tests/Programs.test.jello --path tests --path packages/degust/src --out build/tests.jlo
jellovm build/tests.jlo -- --compiler jelloc --vm "$(command -v jellovm)"
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
`golden`, `status`, `trap`, `error`, `warning`, `args`, `flags`, `modes`, `gc`,
`finalizes` and `pending`. The runner's options are documented there too.

## Development

`scripts/test.sh` runs degust's own tests from this directory. It needs a
Jello toolchain:

- `JELLOC`: the compiler, as words (default `jelloc`);
- `JELLOVM`: the VM (default `jellovm` on `PATH`), with `jlo_tool` and
  `std.jdll` beside it;
- `JELLO_STD_PATH`: the standard library, where the compiler looks for it.

`scripts/test.sh --update` rewrites `tests/expected/*.out` from the current
run.

## Note

Jello and Degust are in heavy development, so do expect it to change.
