__precompile__()
module DataProcessingHierarchyTools
using ProgressMeter
using Glob
import Base.hash

include("types.jl")

const levels = ["subjects", "subject", "day", "session", "array", "channel", "cell"]
const level_patterns = [r"[0-9A-Za-z]*", r"[0-9]{8}", r"session[0-9]{2}", r"array[0-9]{2}", r"channel[0-9]{3}", r"cell[0-9]{2}"]
const level_patterns_s = ["*", "*", "[0-9]*", "session[0-9]*", "array[0-9]*", "channel[0-9]*", "cell[0-9]*"]

function check_args(X1::T, X2::T) where T <: DPHDataArgs
    matches = true
    for f in fieldnames(T)
        x1 = getfield(X1,f)
        x2 = getfield(X2,f)
        if typeof(x1) <: AbstractVector
            if length(x1) != length(x2)
                matches = false
                break
            end
            for (_x1,_x2) in zip(x1,x2)
                if _x1 != _x2
                    matches = false
                    break
                end
            end
            if !matches
                break
            end
        else
            if !(x1 ≈ x2)
                matches = false
                break
            end
        end
    end
    matches
end

function check_args(X::T, args...) where T <: DPHDataArgs
    matches = true
    for (a0,a1) in zip(fieldnames(X), args)
        x = getfield(X, a0)
        if typeof(x) <: AbstractVector
            if length(x) != length(a1)
                matches = false
                break
            end
            for (x1,x2) in zip(x,a1)
                if x1 != x2
                    matches = false
                    break
                end
            end
            if !matches
                break
            end
        else
            if !(x ≈ a1)
                matches = false
                break
            end
        end
    end
    matches
end

function get_numbers(ss::String)
    filter(isdigit,ss)
end

shortnames = Dict("subjects" => x->"",
                  "subject" => x->x[1:1],
                  "day" => x->x,
                  "session" => x->"s$(get_numbers(x))",
                  "array" => x->"a$(get_numbers(x))",
                  "channel" => x->"g$(get_numbers(x))",
                  "cell" => x->"c$(get_numbers(x))")

function get_shortname(ss::String)
    this_level = level(ss)
    this_idx = findfirst(l->this_level==l, levels)
    _r, _p = splitdir(ss)
    qs = String[]
    while !isempty(_p) && this_idx > 1  # Stop once we have reached the bottom level
        push!(qs, shortnames[level(_p)](_p))
        _r, _p = splitdir(_r)
        this_idx -= 1 # Keep track of where we are in the hierarchy
    end
    join(reverse(qs),"")
end

level() = level(pwd())
level(::Type{DPHData}) = error("Not implemented")
filename(::Type{DPHData}) = error("Not implemented")
datatype(::Type{DPHDataArgs}) = error("Not implemented")

function filename(args::T) where T <: DPHDataArgs
    fname = filename(datatype(T))
    h = hex(hash(args))
    bn, ext = splitext(fname)
    fname = join([bn, "_", h, ext])
    fname
end

matname(::Type{DPHData}) = error("Not implemented")
save(X::DPHData) = error("Not implemented")
load(::Type{DPHData}) = error("Not implemented")

function plot_data(::Type{T},fig) where T <: DPHData
    error("Not implemented")
end

export DPHData, level, filename, plot_data, datatype

"""
Get the level of the directory represented by `cwd`.
"""
function level(cwd::String)
    numbers = map(x->first(string(x)), 0:9)
    dd = last(splitdir(cwd))
    ss = rstrip(dd, numbers)
    if isempty(ss)
        # only numbers; assume this is a date
        ss = "day"
    elseif dd == ss
        #no numbers, this is the subject name
        ss = "subject"
    end
    return ss
end

"""
Get the name of the requested level
"""
function get_level_name(target_level::String, dir=pwd())
    this_level = level(dir)
    this_idx = findfirst(l->this_level==l, levels)
    target_idx = findfirst(l->target_level==l, levels)
    i = this_idx
    cwd = dir
    pp = ""
    while i >= target_idx
        cwd, pp = splitdir(cwd)
        i -= 1
    end
    pp
end

"""
Get all directories corresponding to `target_level` under the current hierarchy
"""
function get_level_dirs(target_level::String, dir=pwd())
    this_level = level(dir)
    this_idx = findfirst(l->this_level==l, levels)
    target_idx = findfirst(l->target_level==l, levels)
    if target_idx <= this_idx
        rel_path = process_level(target_level, dir)
        dirs = glob(joinpath(rel_path, "..", level_patterns_s[target_idx]))
    else
        dirs = glob(joinpath(level_patterns_s[this_idx+1:target_idx]...))
    end
    dirs
end

"""
Returns the relative path to an object of type `T`, using `dir` as the starting point.
"""
function process_level(::Type{T}, dir=pwd();kvs...) where T <: DPHData
    target_level = level(T)
    process_level(target_level, dir;kvs...)
end

"""
Returns the path relative to `dir` of the level `target_level`.
"""
function process_level(target_level::String, dir=pwd();kvs...)
    # get the current level
    this_level = level(dir)
    this_idx = findfirst(l->this_level==l, levels)
    target_idx = findfirst(l->target_level==l, levels)
    for lidx in [this_idx, target_idx]
        if !(0 < lidx <= length(levels))
            throw(ArgumentError("Unknown level"))
        end
    end
    pl = ["."]
    append!(pl, [".." for i in 1:(this_idx - target_idx)])
    dirstring = joinpath(pl...)
end

"""
Process each directory in `dirs`, creating an object of type `T`, and returning a concatenation of those objects.
"""
function process_dirs(::Type{T}, dirs::Vector{String}, args...;kvs...) where T <: DPHData
    pp = cd(dirs[1]) do
        T(args...;kvs...)
    end
    @showprogress 1 "Processing dirs..." for d in dirs[2:end]
        _pp = cd(d) do
            T(args...;kvs...)
        end
        pp = hcat(pp, _pp)
    end
    return pp
end

"""
Visit each directory in `dirs`, instantiating type `T` with argumments `args` and keyword arguments `kvs`. Note that this function is similar to `process_dirs`, except unlike that function, `visit_dirs` does not return any results.
"""
function visit_dirs(::Type{T}, dirs::Vector{String}, args...;kvs...) where T <: DPHData
    skipped_dirs = String[]
    @showprogress 1 "Processing dirs..." for d in dirs
        cd(d) do
            try
                T(args...;kvs...)
            catch
                push!(skipped_dirs, d)
            end
        end
    end
    skipped_dirs
end

function visit_dirs(func::Function, dirs::Vector{String}, args...;kvs...)
    skipped_dirs = String[]
    @showprogress 1 "Processing dirs..." for d in dirs
        cd(d) do
         #   try
                func(args...;kvs...)
         #   catch
         #       push!(skipped_dirs, d)
         #   end
        end
    end
    skipped_dirs
end

"""
Process each directory in `dirs` by running the function `func`.
"""
function process_dirs(func::Function, dirs::Vector{String}, args...;kvs...)
    Q = Vector{Any}(length(dirs))
    @showprogress 1 "Processing dirs..." for (i,d) in enumerate(dirs)
        Q[i] = cd(d) do
            func(args...;kvs...)
        end
    end
    Q
end

"""
Load an object of type `T` from the current directory, using additional constructor arguments `args`.
"""
function load(::Type{T}, args...;kvs...) where T <: DPHData
    dir = process_level(T)
    qq = cd(dir) do
        if isfile(filename(T))
            qq = T()
        else
            qq = zero(T)
        end
        qq
    end
    qq
end
end # module
