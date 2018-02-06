module DataProcessingHierarchyTools

include("types.jl")

export DPHData

const levels = ["days", "day", "session", "array", "channel", "cell"]

level() = level(pwd())

"""
Get the level of the directory represented by `cwd`.
"""
function level(cwd::String)
    numbers = map(x->first(string(x)), 0:9)
    dd = last(splitdir(cwd))
    ss = rstrip(dd, numbers)
    if isempty(ss)
        # only numbers; assume this is a date
        return "day"
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
Process each directory in `dirs` by running the function `func`.
"""
function process_dirs(func::Function, dirs::Vector{String}, args...;kvs...)
    @showprogress 1 "Processing dirs..." for d in dirs
        cd(d) do
            func(args...;kvs...)
        end
    end
end

"""
Load an object of type `T` from the current directory, using additional constructor arguments `args`.
"""
function load(::Type{T}, args...) where T <: DPHData
    dir = process_level(T)
    qq = cd(dir) do
        T(args...)
    end
    qq
end
end # module
