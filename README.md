# TextGen: Text Generation from Nix Expressions

The `textgen` nix package provides a command line utility and nix library for generating text from nix expressions.

The library provides functions for:
  - Generating mutually referential documents based on user supplied render functions.
  - A simple and powerful function, `nu`, for creating object oriented style
  text renderers.

The command line utility works with the library functions to build the
text output in the nix store and copy them to a local directory.

## Getting Started

To generate examples, clone this repository and enter `nix-shell`.
- Examples can be built by running `textgen-examples <example>`, with the
  appropriate example name argument (tab completion will show available).
- The definition of the examples are contained in `./examples.nix`.
- The definition of the `textgen-examples` command is given in
  `textgen-env.nix`. It shows the underlying call to `textgen`.
- The command `env-repl` will open a `nix repl` with the attributes of
  `./textgen-env.nix` preloaded. Notably, the definitions in `./examples.nix` are assigned in `passthru`.

## Evaluating Documents

The `textgen` executable creates text files in the nix store and copies them
to the local directory. See `textgen help` for options. `textgen` generates
the files based on outputs of calls to functions in `evalDoc.nix`, e.g.
`evalDoc`.

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

## The Examples

The examples show the basics of applying `evalDocs` to different nix expressions
to generate texts. Broadly, they use different `toText` attributes to achieve
different effects. The examples are organized to indicate how the various
`toText` renderers were built from one another.

### Example 0

Is a simple text generated from applying `stdDispatch`, a renderer that tests
its input type and calls `evalList`, `evalAttrs`, etc. accordingly, depending
on the data type encountered. `stdDispatch` is a functor type attribute set, so
it acts like a function. It also acts like a base type that other renderers
can inherit from by supplying their own definitions for `evalAttrs` etc.

### Example 1

Uses `simpleNest` to generates a document with line indents based on the levels
of nested lists. `simpleNest` is built with the `nest` attribute, a function
that increments a counter, `level`. Approximately speaking, when evaluating
deeper into a structure, `simpleNest` will recursively call itself with
something like `self.nest value`, which calls itself (`simpleNest`) with the
level incremented. There are also attributes that "`toString`" with spaces prepended based on the nesting level. Example 1 also demonstrates how nix
functions can be used allow the evaluated expression to modify the state of
the evaluator, in this case to suspend formatting.

### Example 2

Shows how an XML document can be generated using `simpleXML`. Most of the
heavy lifting for formatting nested lines of text has been solved by `simpleNest`, so all `simpleXML` does is provide a scheme for generating tags and children by redefining how to render attribute sets.

### Example 3

Example 3 illustrates the situation of targeting a special purpose XML schema. The Nix expression of the XML document from Example 2 is verbose and closely matches the final XML structure. Example 3 generates a similar XML document
but based on a much simpler nix expression and a helper renderer that translates
the simpler input into a structure that `simpleXML` accepts.

### Example 4

Shows the generation of multiple XML documents from multiple nix representations of those documents using `evalDocsAttrs`

### Example 5

Shows an alternative approach to generating the documents of Example 4 through a call to `evalDocs`.

## Custom Renderers

The original motivation for this project was to generate custom XML
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
