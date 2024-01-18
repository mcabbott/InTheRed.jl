"""
    InTheRed.jl

This package overloads `Base.show` to change how numbers are printed:
* Negative numbers are red
* Zero is light gray
* `Inf`, `NaN` and `missing` are yellow
* High- and low-precision numbers (like `Float32`, `Int16`, `BigInt`) are cyan, or magenta if negative.

In addition, vectors of real numbers are displayed with a bar graph alongside their values.

# Examples

```
julia> using InTheRed

julia> rand(-3:3, 2, 10)
2×10 Matrix{Int64}:
 -2  -2  0  0  -3   2  -1  -2  -2  -2
  3  -3  2  3   2  -2  -1  -1  -2   2

julia> x = ans .+ 0f0; x[3] = NaN; x[6] = Inf; x[end-2] = -Inf;

julia> x
2×10 Matrix{Float32}:
 -2.0  NaN     0.0  0.0  -3.0   2.0  -1.0  -2.0   -2.0  -2.0
  3.0   -3.0  Inf   3.0   2.0  -2.0  -1.0  -1.0  -Inf    2.0

julia> x .> 0
2×10 BitMatrix:
 0  0  0  0  0  1  0  0  0  0
 1  0  1  1  1  0  0  0  0  1

julia> sort(vec(x))[2:2:end]
10-element Vector{Float32}:
  -3.0  #  -----------------|
  -2.0  #        -----------|
  -2.0  #        -----------|
  -2.0  #        -----------|
  -1.0  #             ------|
   0.0  #                   |
   2.0  #                   |+++++++++++
   2.0  #                   |+++++++++++
   3.0  #                   |+++++++++++++++++
 NaN    #
```
"""
module InTheRed

function _preprint(io::IO, x::Number, pos=nothing, neg::Symbol=:red)
    if isnan(x)
        print(io, Base.text_colors[:yellow])
    elseif !isfinite(x)
        print(io, Base.text_colors[:yellow])
    elseif iszero(x)
        print(io, Base.text_colors[:light_black])
    elseif x < 0
        print(io, Base.text_colors[neg])
    elseif !isnothing(pos)
        print(io, Base.text_colors[pos])
    elseif VERSION < v"1.9-"
        # This partly repairs spacing on Julia 1.8
        print(io, Base.text_colors[:default])
    else
        return false  # nothing printed
    end
    return true  # means that something has been printed
end

_postprint(io::IO) = print(io, Base.text_colors[:default])

# Fix Diagonal([1,2,-3])
function Base.replace_with_centered_mark(s::String; c::AbstractChar = '⋅')  # more specific than Base
    N = Base.textwidth(Base.ANSIIterator(s))
    ret =join(setindex!([" " for i=1:N],string(c),ceil(Int,N/2)))
    Base.text_colors[:light_black] * ret * Base.text_colors[:default]
end


#####
##### floats
#####

# function Base.show(io::IO, x::T, forceuntyped::Bool=false, fromprint::Bool=false) where {T <: Base.IEEEFloat}
#     compact = get(io, :compact, false)::Bool
#     buf = Base.StringVector(neededdigits(T))
#     typed = !forceuntyped && !compact && get(io, :typeinfo, Any) != typeof(x)
#     pos = writeshortest(buf, 1, x, false, false, true, -1,
#         (x isa Float32 && !fromprint) ? UInt8('f') : UInt8('e'), false, UInt8('.'), typed, compact)
#     write(io, resize!(buf, pos - 1))
#     return
# end

function Base.show(io::IO, x::Float64, forceuntyped::Bool=false, fromprint::Bool=false)
    iscolor = get(io, :color, false)::Bool
    q = iscolor && _preprint(io, x)
    Base.@invoke show(io::IO, x::Base.IEEEFloat, forceuntyped::Bool, fromprint::Bool)
    q && _postprint(io)
    return
end

for FloatNN in (:Float32, :Float16)
    @eval function Base.show(io::IO, x::$FloatNN, forceuntyped::Bool=false, fromprint::Bool=false)
        iscolor = get(io, :color, false)::Bool
        iscolor && _preprint(io, x, :cyan, :magenta)
        Base.@invoke show(io::IO, x::Base.IEEEFloat, forceuntyped::Bool, fromprint::Bool)
        iscolor && _postprint(io)
        return
    end
end

# function show(io::IO, b::BigFloat)
#     if get(io, :compact, false)::Bool
#         print(io, _string(b, 5))
#     else
#         print(io, _string(b))
#     end
# end

# function Base.show(io::IO, x::BigFloat)  # causes method overwritten warnings
function Base.show(io::Union{Base.LibuvStream, Base.AbstractPipe}, x::BigFloat)  # just wide enough for stdout?
    iscolor = get(io, :color, false)::Bool
    q = iscolor && _preprint(io, x, :cyan, :magenta)
    # Base.@invoke show(io::IO, x::BigFloat)
    if get(io, :compact, false)::Bool
        print(io, Base.MPFR._string(x, 5))
    else
        print(io, Base.MPFR._string(x))
    end
    q && _postprint(io)
    return
end

# function Base.show(io::Base.LibuvStream, x::AbstractFloat)
#     _preprint(io, x)
#     Base.@invoke show(io::IO, x::(typeof(x)))
#     _postprint(io)
# end
# julia> show(stdout, MIME"text/plain"(), big(3.0))
# ERROR: MethodError: show(::Base.TTY, ::BigFloat) is ambiguous.

# _string(x::BigFloat, k::Integer) = _string(x, "%.$(k)Re")
function Base.MPFR._string(x::BigFloat, k::Int)  # more specific
    io = IOBuffer()
    q = _preprint(io, x)
    print(io, Base.MPFR._string(x, "%.$(k)Re"))
    q && _postprint(io)
    String(take!(io))
end


#####
##### integers
#####

# show(io::IO, n::Signed) = (write(io, string(n)); nothing)
# show(io::IO, n::Unsigned) = print(io, "0x", string(n, pad = sizeof(n)<<1, base = 16))

function Base.show(io::IO, x::Int)
    iscolor = get(io, :color, false)::Bool
    q = iscolor && _preprint(io, x)
    write(io, string(x))
    q && _postprint(io)
    return
end

for IntNN in (:Int128, :Int32, :Int16, :Int8)
    @eval function Base.show(io::IO, x::$IntNN)
        iscolor = get(io, :color, false)::Bool
        iscolor && _preprint(io, x, :cyan, :magenta)
        write(io, string(x))
        iscolor && _postprint(io)
        return
    end
end

# show(io::IO, x::BigInt) = print(io, string(x))

function Base.show(io::Union{Base.LibuvStream, Base.AbstractPipe}, x::BigInt)
    iscolor = get(io, :color, false)::Bool
    iscolor && _preprint(io, x, :cyan, :magenta)
    print(io, string(x))
    iscolor && _postprint(io)
    return
end

# show(io::IO, b::Bool) = print(io, get(io, :typeinfo, Any) === Bool ? (b ? "1" : "0") : (b ? "true" : "false"))

# @eval Base.show(io::IO, b::Bool) = printstyled(io, get(io, :typeinfo, Any) === Bool ? (b ? "1" : "0") : (b ? "true" : "false"), color=:green)
# WARNING: Method definition show(IO, Bool) in module Base at show.jl:1141 overwritten in module InTheRed at /Users/me/.julia/dev/InTheRed/src/InTheRed.jl:114.
#   ** incremental compilation may be fatally broken for this module **

function Base.show(io::Union{Base.LibuvStream, Base.AbstractPipe}, b::Bool)
    knowsbool = get(io, :typeinfo, Any) === Bool
    usecolor = get(io, :color, false)::Bool && knowsbool
    usecolor && _preprint(io, b, :cyan, :magenta)
    print(io, knowsbool ? (b ? "1" : "0") : (b ? "true" : "false"))
    usecolor && _postprint(io)
end

# function Base.show_delim_array(io::IO, itr::AbstractArray{Bool}, op, delim, cl, delim_one) #, i1=first(LinearIndices(itr)), l=last(LinearIndices(itr)))
#     iob = IOBuffer()
#     Base.show_delim_array(IOContext(iob, io), itr, op, delim, cl, delim_one, first(LinearIndices(itr)), last(LinearIndices(itr)))
#     str = String(take!(iob))
#     @show typeof(io)
#     # now process that to find the 0, 1
#     print(io, str)
# end

# That's called by b & c but not d:
# (a = 3f0, b = randn(3) .> 0, c = [true, false], d = randn(1000) .> 0)


#####
##### types
#####

for T in (:BigFloat, :Float32, :Float16, :BigInt, :Int128, :Int32, :Int16, :Int8, :Bool)
    str = string(T)
    @eval function Base.show(io::IO, ::Type{$T})
        printstyled(io, $str, color=:cyan)
    end
end


#####
##### nothing, missing
#####


function Base.show(io::Union{Base.LibuvStream, Base.AbstractPipe}, ::Nothing)  # more specific than io::IO
    iscolor = get(io, :color, false)::Bool
    iscolor && _preprint(io, 0)
    write(io, "nothing")
    iscolor && _postprint(io)
    return
end

function Base.show(io::Union{Base.LibuvStream, Base.AbstractPipe}, x::Missing)  # more specific than io::IO
    iscolor = get(io, :color, false)::Bool
    iscolor && _preprint(io, NaN)
    write(io, "missing")
    iscolor && _postprint(io)
    return
end


#####
##### vectors
#####

function Base.print_matrix(io::IO, @nospecialize(X::AbstractVector{<:Union{Real, Union{Missing,<:Real}}}),
                      pre::AbstractString = " ",  # pre-matrix string
                      sep::AbstractString = "  ", # separator between elements
                      post::AbstractString = "",  # post-matrix string
                      hdots::AbstractString = "  \u2026  ",
                      vdots::AbstractString = "\u22ee",
                      ddots::AbstractString = "  \u22f1  ",
                      hmod::Integer = 5, vmod::Integer = 5)
    lo, hi = extrema(_finite, X) .* 1.0  # promote to at least Float64
    Base._print_matrix(io, Base.inferencebarrier(X), pre, (sep, lo, hi), post, hdots, vdots, ddots, hmod, vmod, Base.unitrange(axes(X,1)), Base.unitrange(axes(X,2)))
end

# Passing (sep, lo, hi) through Base._print_matrix is a trick to make e.g. randn(10^7) print quickly
# It also gets passed to this function:
Base.print_matrix_vdots(io::IO, a::AbstractString, b::Vector, (sep, _, _)::Tuple, d::Integer, e::Integer, f::Bool) =
    Base.print_matrix_vdots(io, a, b, sep, d, e, f)

function Base.print_matrix_row(io::IO,
        @nospecialize(X::AbstractVector), A::Vector,
        i::Integer, cols::AbstractVector, (sep, lo, hi)::Tuple,
        idxlast::Integer=last(axes(X, 2)))
    @invoke Base.print_matrix_row(io::IO, X::AbstractVector, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString,
        2::Int)  # this 2 is a trick to make 2nd column line up!
    # lo, hi = extrema(_finite, X) .* 1.0  # promote to at least Float64
    xi = X[i]
    length(X) < 2 && return

    printstyled(io, "  #  ", hidden=true)

    ismissing(xi) && return
    isfinite(xi) || return
    # isnan(xi) && return
    # xi = xi==Inf ? hi : xi==-Inf ? lo : xi

    WIDTH = 33
    bold = (xi ≈ lo) || (xi ≈ hi)

    plus = xi<0 ? 0 : round(Int, WIDTH * xi/(hi-min(0,lo)), RoundFromZero)
    minus = xi>0 ? 0 : round(Int, WIDTH * (-xi)/(max(hi,0)-lo), RoundFromZero)
    space = lo>=0 ? 0 : round(Int, WIDTH * (-lo)/(max(hi,0)-lo), RoundFromZero) - minus
    printstyled(io, repeat(" ", space), repeat("-", minus), "|", repeat("+", plus); color=:light_black, bold)
end

_finite(x::Real) = (isnan(x) || isinf(x)) ? zero(x) : x
_finite(x::Missing) = false


end # module InTheRed


#=

enable_ansi  = get(text_colors, color, text_colors[:default]) *
                   (bold ? text_colors[:bold] : "") *
                   (underline ? text_colors[:underline] : "") *
                   (blink ? text_colors[:blink] : "") *
                   (reverse ? text_colors[:reverse] : "") *
                   (hidden ? text_colors[:hidden] : "")

disable_ansi = (hidden ? disable_text_style[:hidden] : "") *
              (reverse ? disable_text_style[:reverse] : "") *
              (blink ? disable_text_style[:blink] : "") *
              (underline ? disable_text_style[:underline] : "") *
              (bold ? disable_text_style[:bold] : "") *
                  get(disable_text_style, color, text_colors[:default])
=#
