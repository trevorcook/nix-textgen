# TextGen: Text Generation from Nix Expressions

The `textgen` nix package provides utilities for generating text from
nix expressions; specifically, a command line utility and nix library.
The library provides functions for:
  - Generating mutually referential documents based on user supplied render functions.
  - A simple and powerful function, `nu`, for creating object oriented style
  text renders.
The command line utility works with the library functions to build the
text output in the nix store and copy them to a local directory.

## Getting Started

To generate examples, clone this repository and enter `nix-shell`.
- Examples can be built by running `textgen-examples <example>`, with the
  appropriate example name argument (tab completion will show available).
- The definition of the examples are contained in `./examples.nix`.
- The command `env-repl` will open a `nix repl` with the attributes of
  `./textgen-env.nix` preloaded. Notably, the definitions in `./examples.nix` are assigned in `passthru`.
- The definition of `textgen-examples` is given in
  `textgen-env.envlib.textgen-examples`. It shows the underlying call to
  `textgen`.

## Evaluating Documents

The `textgen` executable creates text files in the nix store and copies them
to the local directory. See `textgen help` for details. `textgen` generates
the files based on outputs of calls to `evalDoc` etc. defined in
`./evalDoc.nix`.

`evalDoc` expects two arguments, a "`docspec`" and a nix expression that will
ultimately be turned into text. The `docspec` is an attribute set containing
the following:

  - `name`: The file name (no default)
  - `path`: Additional local path (default: `""`)
  - `mkRef`: Function for defining "`ref`" attribute
    (default: `self: self.name`)
  - `toText`: A function for turning input argument into text

The `evalDocs` function is based on `evalDoc`, except instead of a single nix
expression to evaluate, it expects an attribute set of nix functions. It
applies each of these to the fixed point output so that each document in the
set can reference the others.

## Custom Renderers

The original motivation for this project was to generate custom XML schema
from nix. As such, `./toText.nix` provides the function `simpleXML`.
`simpleXML` is defined using the novel `nu` utility, a function for defining
new text renderers, and whos design is outlined in this section.

### Nu objects

The `nu` combinator creates attribute sets that work in an object
oriented programming style. Consider, for instance, the following
definition:

```
counter = nu {
  inc = self: { level = self.level + 1; };
  dec = self: { level = self.level - 1; };
  set = self: n: { level = n; };
} { level = 0; };
```

It creates the `counter` attribute set equal to

```
{ level = 0;
  inc = { ... };
  dec = { ... };
  set = << lambda >>;
}
```

Wherein, for example, the `inc` set is self similar to `counter`,
but with `level` incremented by one. Thanks to laziness, these
nested attribute sets contain every combination of incrementing and
decrementing. As a result, indexing into this infinite tree such as
in the expression, `counter.inc.inc`, is possible. Even better, the
syntax is similar enough to OOP that such expressions can be
understood as simply incrementing the `level` attribute twice.

#### Properties

`nu` objects are created by supplying an attribute set of methods
and a set of initial properties. Each method must be a function whose
first argument is the eventual "object". As such, any method can
call any other method. The functions may accept
any number of additional arguments, in which case they can be called
as in, for example, `(counter.set 3).inc.inc`. Methods may return
any valid nix type: returned attribute sets will be merged with
the original object; other types are returned as is.
