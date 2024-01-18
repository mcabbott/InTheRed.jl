# InTheRed.jl

This package overloads `Base.show` to change how numbers are printed:
* Negative numbers are red
* Zero is light gray
* `Inf`, `NaN` and `missing` are yellow
* High- and low-precision numbers (like `Float32`, `Int16`, `BigInt`) are cyan, or magenta if negative.

In addition, vectors of real numbers are displayed with a bar graph alongside their values.

## Examples

![REPL screenshot](readme.png)

## Elsewhere

The package [OhMyREPL.jl](https://github.com/KristofferC/OhMyREPL.jl) changes the text you type at the prompt, instead of what is printed.

