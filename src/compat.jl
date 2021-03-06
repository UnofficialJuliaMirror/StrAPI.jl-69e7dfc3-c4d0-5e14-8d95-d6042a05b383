# This file contains code that was a part of Julia
# License is MIT: see LICENSE.md

const StringIndexError = UnicodeError

module Unicode
const normalize  = Base.UTF8proc.normalize_string
const graphemes  = Base.UTF8proc.graphemes
const isassigned = Base.UTF8proc.is_assigned_char
end

const pwc = print_with_color

@api public StringIndexError

Base.replace(str::String, pair::Pair{String,String}; count::Integer=0) =
    replace(str, pair.first, pair.second, count)

const IteratorSize = Base.iteratorsize

const is_letter = isalpha

@api public! IteratorSize

@static if !isdefined(module_parent(current_module()), :Compat)
## Start of code from operators.jl =================================================
##
## It is used to support the new string searching syntax on v0.6.2

@static if !isdefined(Base, :Fix2)
"""
    Fix2(f, x)

A type representing a partially-applied version of function `f`, with the second
argument fixed to the value "x".
In other words, `Fix2(f, x)` behaves similarly to `y->f(y, x)`.
"""
struct Fix2{F,T} <: Function
    f::F
    x::T

    Fix2(f::F, x::T) where {F,T} = new{F,T}(f, x)
    Fix2(f::Type{F}, x::T) where {F,T} = new{Type{F},T}(f, x)
end

(f::Fix2)(y) = f.f(y, f.x)
end

@static if !method_exists(isequal, (Any,))
"""
    isequal(x)

Create a function that compares its argument to `x` using [`isequal`](@ref), i.e.
a function equivalent to `y -> isequal(y, x)`.

The returned function is of type `Base.Fix2{typeof(isequal)}`, which can be
used to implement specialized methods.
"""
Base.isequal(x) = Fix2(isequal, x)

const EqualTo = Fix2{typeof(isequal)}
end

@static if !method_exists(==, (Any,))
"""
    ==(x)

Create a function that compares its argument to `x` using [`==`](@ref), i.e.
a function equivalent to `y -> y == x`.

The returned function is of type `Base.Fix2{typeof(==)}`, which can be
used to implement specialized methods.
"""
Base.:(==)(x) = Fix2(==, x)
end

@static if !method_exists(in, (Any,))
"""
    in(x)

Create a function that checks whether its argument is [`in`](@ref) `x`, i.e.
a function equivalent to `y -> y in x`.

The returned function is of type `Base.Fix2{typeof(in)}`, which can be
used to implement specialized methods.
"""
Base.in(x) = Fix2(in, x)
const OccursIn = Fix2{typeof(in)}
end
end

## end of code from operators.jl =================================================

## Start of codeunits support from basic.jl ======================================
##
##It is used for CodeUnit support in pre v0.7 versions of Julia

## code unit access ##

codeunit(str::AbstractString) = UInt8
codeunit(::Type{<:AbstractString}) = UInt8
ncodeunits(str::AbstractString) = sizeof(str)

"""
    CodeUnits(s::AbstractString)

Wrap a string (without copying) in an immutable vector-like object that accesses the code units
of the string's representation.
"""
struct CodeUnits{T,S<:AbstractString} <: DenseVector{T}
    s::S
    CodeUnits(s::S) where {S<:AbstractString} = new{codeunit(s),S}(s)
end

length(s::CodeUnits) = ncodeunits(s.s)
sizeof(s::CodeUnits{T}) where {T} = ncodeunits(s.s) * sizeof(T)
size(s::CodeUnits) = (length(s),)
strides(s::CodeUnits) = (1,)
getindex(s::CodeUnits, i::Int) = codeunit(s.s, i)
IndexStyle(::Type{<:CodeUnits}) = IndexLinear()
@static if NEW_ITERATE
    iterate(s::CodeUnits, i=1) = (s[i], i+1)
else
    start(s::CodeUnits) = 1
    next(s::CodeUnits, i) = (s[i], i+1)
    @inline done(s::CodeUnits, i) = i > length(s)
end

write(io::IO, s::CodeUnits) = write(io, s.s)

unsafe_convert(::Type{Ptr{T}},    s::CodeUnits{T}) where {T} = unsafe_convert(Ptr{T}, s.s)
unsafe_convert(::Type{Ptr{Int8}}, s::CodeUnits{UInt8}) = unsafe_convert(Ptr{Int8}, s.s)

"""
    codeunits(s::AbstractString)

Obtain a vector-like object containing the code units of a string.
Returns a `CodeUnits` wrapper by default, but `codeunits` may optionally be defined
for new string types if necessary.
"""
codeunits(s::AbstractString) = CodeUnits(s)

## end of codeunits support ============================================================

const UC = Base.UTF8proc

unsafe_crc32c(a, n, crc) = ccall(:jl_crc32c, UInt32, (UInt32, Ptr{UInt8}, Csize_t), crc, a, n)

const utf8crc = Base.crc32c

import Base: isalnum, isgraph, islower, isupper, lcfirst, ucfirst
const is_alphanumeric = isalnum
const is_graphic      = isgraph
const is_lowercase    = islower
const is_uppercase    = isupper
const lowercase_first = lcfirst
const uppercase_first = ucfirst

codepoint(v::Char) = v%UInt32

@noinline index_error(s::AbstractString, i::Integer) =
    strerror(StrErrors.INVALID_INDEX, Int(i), codeunit(s, i))

macro preserve(args...)
    syms = args[1:end-1]
    for x in syms
        isa(x, Symbol) || error("Preserved variable must be a symbol")
    end
    #=
    s, r = gensym(), gensym()
    esc(quote
        $s = $(Expr(:gc_preserve_begin, syms...))
        $r = $(args[end])
        $(Expr(:gc_preserve_end, s))
        $r
        $(args[end])
    end)
    =#
    esc(quote ; $(args[end]) ; end)
end

Base.SubString(str::AbstractString, rng::UnitRange) = SubString(str, first(rng), last(rng))

Base.checkbounds(::Type{Bool}, s::AbstractString, i::Integer) = 1 <= i <= ncodeunits(s)

# Handle some name changes between v0.6 and master
const copyto! = copy!
const unsafe_copyto! = unsafe_copy!
const Nothing = Void
const Cvoid = Void
abstract type AbstractChar end

# Handle changes in array allocation
create_vector(T, len) = Vector{T}(len)

# Add new short name for deprecated hex function
outhex(v, p=1) = hex(v,p)

function get_iobuffer(siz)
    out = IOBuffer(Base.StringVector(siz), true, true)
    out.size = 0
    out
end

@api public copyto!, unsafe_copyto!, Nothing, Cvoid, AbstractChar

import Base: find, ind2chr, chr2ind

const is_lowercase = islower
const is_uppercase = isupper

