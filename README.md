# TextGen: Text Generation from Nix Expressions

The `textgen` nix library includes utilities for generating text from
nix expressions. The text rendering is performed via user supplied renderer functions for handling specific use cases. The library
provides a simple but powerful utility for creating new
renderers, as well as processing collections of documents that
reference eachother.

## Vocabulary

In this document, the following terms will be used.

- doc: A nix expression that represents a document.
- render: Convert a doc to nix text.
- evaluate: Apply a renderer to a doc, create a file from the
  text, and collect text, file, and some other attributes into an
  attribute set.
- docspec: Additional inputs that describe the rendered text: name,
  location, etc., used in the evaluation.
- gentext: The output of evaluation. An attribute set containing
  the various inputs and outputs.

## Getting Started

To follow along with the examples, clone this repository and enter
`nix-shell`. Examples can be built by running `textgen` with the
appropriate example name argument (tab completion or `textgen help`
will show available). (The definition of the `textgen` is given in
the `envlib` attribute of `./textgen-env.nix`). The command `env-repl`
will open a `nix repl` with the attributes of `./textgen-env.nix`
preloaded. Notably, the definitions in `./examples.nix` assigned
in `passthru`.

## An Indenting Render

Consider this simple document. It lists a few bullet points wherein
we use nested lists to represent nested bullet levels.

```
example1 = [
  "- Top Level Idea"
  [ ''- Supporting idea "b"''
    ''- Supporting idea "a"'']
  ]
```
Running `textgen example1` generates a link to `/nix/store`, `examples`. Found inside is `example1.nix` with the following text.

```
- Top Level Idea
  - Supporting idea "a"
  - Supporting idea "b"
```
Loading `env-repl`, we can inspect the `examples.example1` to find
an attribute set with many elements, notably `out` for the derivation
of the file and `text` for the rendered text.

Looking in `./examples.nix`, we see that `example1` is defined like:

```example1 = evalDoc { toText = indentNesting.eval;
                        name = "example1.txt"; } example1;
```
using `evalDoc` from `./evalDoc.nix` and the renderer `indentNesting.eval` from `./toText.nix`.

## Custom Renderers

`textgen` supplies the novel `nu` utility defined in `./toText.nix` to
help define new renderers.

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
syntax is so similar to OOP that such expressions can be
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

### A Little XML

Using `nu` we create a little evaluator for creating xml documents.
We are interested in generating documents like the following

```
<?xml version='1.0' encoding='utf-8'?>
<element1 attr1="val1" attr2="val2">
    <element2 attr1="val1" attr2="val2"/>
</element1>
```

from docs with attributes like
```
{ element1 = { attrs = { .. };
               children = []; };
}
```

The following definition provides a good first pass.

```
simpleXML =
let unlines = concatStringsSep "/n"; in
nu {
  eval = self: body: unlines (mapAttrsToList self.evalElem body);
  evalElem = self: name: value@{attrs?{},children?[]}:
    if children == [] then
      ''<${name} ${self.makeAttrs attrs}/>''
    else
    unlines (
      [''<${name} ${self.makeAttrs attrs}>'' ] ++
      (map self.eval children) ++
      [''</${name}>'']
      );
  makeAttrs = self: attrs:
    concatStringsSep " " (mapAttrsToList (n: v: ''${n}="${v}"'') attrs);
} {};
```
