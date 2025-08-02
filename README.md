# InTheRed.jl

This package overloads `Base.show` to change how numbers are printed:
* Negative numbers are red
* Zero is light gray
* `Inf`, `NaN` and `missing` are yellow
* Low-precision numbers (like `Float32`, `Int16`) are cyan, or magenta if negative, and
* Unsigned integers are printed both in hex and decimal.

The cutoff for "nearly zero" is controlled by e.g. `threshold!(1e-16)`.

It also changes how vectors numbers are printed:
* Vectors of real numbers are displayed with a bar graph alongside their values.
* Vectors of complex numbers show their absolute value as a bar graph, and phase as a compass direction.
* Ranges print more detail, including the `range` constructor.

The point of this is to provide extra context while working at the REPL, without getting in your way.
The bar graphs should occupy unused space to the right of the numbers in your terminal.

## Examples

![REPL screenshot](readme.png)

Copying text from the REPL loses the colours but keeps the graph:

```julia
julia> Float16[x..., Inf]
15-element Vector{Float16}:
  -0.777   #    ┥
  -0.6323  #    ┥
  -0.3936  #    ┥
   0.0     #    │
   0.649   #    ┝
   1.719   #    ┝╸
   3.482   #    ┝━
   6.39    #    ┝━╸
  11.18    #    ┝━━╸
  19.08    #    ┝━━━━
  32.12    #    ┝━━━━━━━
  53.6     #    ┝━━━━━━━━━━━━
  89.0     #    ┝━━━━━━━━━━━━━━━━━━━━
 147.4     #    ┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Inf      #    ╪═▶

julia> reverse(1:10)
10-element StepRange{Int64, Int64}:
# range(10, 1, step=-1) === 10:-1:1
 10  #    ┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  9  #    ┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
  8  #    ┝━━━━━━━━━━━━━━━━━━━━━━━━━━╸
  ⋮
  3  #    ┝━━━━━━━━━━
  2  #    ┝━━━━━━╸
  1  #    ┝━━━╸
```

For complex numbers, the graph shows phase and magnitude like this:

```julia
julia> cis.(range(0,2pi,9)) .* logrange(1/3,3,9) .|> ComplexF32
9-element Vector{ComplexF32}:
   0.33333334f0 + 0.0f0im          #   │➡┝━━━╸
   0.31020162f0 + 0.31020162f0im   #   │↗┝━━━━━
  3.5352508f-17 + 0.57735026f0im   #   │⬆┝━━━━━━╸
    -0.537285f0 + 0.537285f0im     #   │↖┝━━━━━━━━╸
         -1.0f0 + 1.2246469f-16im  #   │⬅┝━━━━━━━━━━━
   -0.9306049f0 - 0.9306049f0im    #   │↙┝━━━━━━━━━━━━━━╸
 -3.1817257f-16 - 1.7320508f0im    #   │⬇┝━━━━━━━━━━━━━━━━━━━
    1.6118549f0 - 1.6118549f0im    #   │↘┝━━━━━━━━━━━━━━━━━━━━━━━━━
          3.0f0 - 7.3478806f-16im  #   │➡┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Unsigned integers:

```julia
julia> 0x0c9
0x00c9  # == 201

julia> -ans
0xff37  # == 65335
```

## Elsewhere

* [OhMyREPL.jl](https://github.com/KristofferC/OhMyREPL.jl) changes the text you type at the prompt, instead of what is printed.

* [UnicodePlots.jl](https://github.com/JuliaPlots/UnicodePlots.jl) allows much more complicated plotting as text.
