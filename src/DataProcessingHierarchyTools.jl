__precompile__()
module DataProcessingHierarchyTools
using ProgressMeter
using Glob
using MAT
using StrTables, LaTeX_Entities
import Base:hash,filter,show, convert

include("types.jl")

const def = LaTeX_Entities.default

"""
    get_annex()

Return the shell command that runs git annex on this computer, or `nothing` if the command is not found.
"""
function git_annex()
    cmd = nothing
    try
        cmd = readchomp(`which git-annex`)
    catch ee
    end
    return cmd
end

const levels = ["subjects", "subject", "day", "session", "array", "channel", "cell"]
const level_patterns = [r"[0-9A-Za-z]*", r"[0-9]{8}", r"session[0-9]{2}", r"array[0-9]{2}", r"channel[0-9]{3}", r"cell[0-9]{2}"]
const level_patterns_s = ["*", "*", "[0-9]*", "session[0-9]*", "array[0-9]*", "channel[0-9]*", "cell[0-9]*"]

#TODO: Find a way to (automatically) track dependency betweeen types. We could also just do this manually, i.e. have a depends_on function that lists types that a given type depends (directly) on. E.g. depends_on(Raster) = PSTH. If a type does not depend on any other types, just return an empty list
depends_on(::Type{T}) where T <: DPHData = DataType[]

"""
    dependencies(args::T) where T <: DPHDataArgs

Return a list of files on which `args` depends.
"""
dependencies(args::T) where T <: DPHDataArgs = String[]

"""
    check_args(X1::T, X2::T) where T <: DPHDataArgs

Return `true` if the arguments in `X1` and `X2` are the same.
"""
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
    for (a0,a1) in zip(fieldnames(T), args)
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

"""
    get_shortname(ss::String)

Get the short representation of the path `ss`.

# Examples
```jldoctest
julia> DataProcessingHierarchyTools.get_shortname("Whiskey/20202001/session01/array01/channel034/cell01")
"W20202001s01a01g034c01"
```
"""
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

"""
    get_fullname(ss=pwd())

Return the full name of the level pointed to by `ss`.

# Examples
```jldoctest
julia> DataProcessingHierarchyTools.get_fullname("Whiskey/20202001/session01/array01/channel034/cell01")
"Whiskey/20202001/session01/array01/channel034/cell01"
```
"""
function get_fullname(ss=pwd())
    this_level = level(ss)
    this_idx = findfirst(l->this_level==l, levels)
    pp = [get_level_name(this_level, ss)]
    while this_idx > 2
        this_idx -= 1
        this_level = levels[this_idx]
        push!(pp, get_level_name(this_level, ss))
    end
    joinpath(reverse(pp)...)
end

level() = level(pwd())
level(::Type{DPHData}) = error("Not implemented")
filename(::Type{DPHData}) = error("Not implemented")
datatype(::Type{DPHDataArgs}) = error("Not implemented")
datatype(X::T) where T <: DPHDataArgs = datatype(T)
version(X::DPHDataArgs) = "UNKNOWN"

function filename(args::T) where T <: DPHDataArgs
    fname = filename(datatype(T))
    h = string(hash(args),base=16)
    bn, ext = splitext(fname)
    fname = join([bn, "_", h, ext])
    fname
end

function filename(args::Vector{T}) where T <: DPHDataArgs
    fname = filename(datatype(T))
    h = string(hash(args),base=16)
    bn, ext = splitext(fname)
    fname = join([bn, "_", h, ext])
    fname
end

matname(::Type{DPHData}) = error("Not implemented")

function load(args::T) where T <: DPHDataArgs
    fname = filename(args)
    load(datatype(T), fname)
end

"""
    computed(args::T) where T <: DPHDataArgs

Return `true` if the data described by `args` has already been 
computed.
"""
function computed(args::T) where T <: DPHDataArgs
    fname = filename(args)
    return isfile(fname) || islink(fname)
end

function load(args::Vector{T}) where T <: DPHDataArgs
    fname = filename(args)
    if isfile(fname)
        return load(Vector{datatype(T)}, fname)
    end
    error("No data exist with the specified arguments")
end

function plot_data(::Type{T},fig, args::T2, plotargs::T3) where T <: DPHData where T2 <: DPHDataArgs where T3 <: DPHPlotArgs
    error("Not implemented")
end

export DPHData, level, filename, plot_data, datatype, BootstrappedDataArgs

"""
    level(cwd::String)
    
Get the level of the directory represented by `cwd`.

# Examples
```jldoctest
julia> DataProcessingHierarchyTools.level("Whiskey/session01/array01/channel034")
"channel"
```
"""
function level(cwd::String)
    numbers = map(x->first(string(x)), 0:9)
    dd = last(splitdir(cwd))
    ss = string(rstrip(dd, numbers))
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
    get_level_name(target_level::String, dir=pwd())

Get the name of the requested level.

# Examples
```jldoctest
julia> DataProcessingHierarchyTools.get_level_name("array", "Whiskey/20200110/session01/array01/channel034")
"array01"
```
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
    get_level_dirs(target_level::String, dir=pwd())

Get all directories corresponding to `target_level` under the current hierarchy.
"""
function get_level_dirs(target_level::String, dir=pwd())
    dirs = cd(dir) do
        this_level = level()
        this_idx = findfirst(l->this_level==l, levels)
        target_idx = findfirst(l->target_level==l, levels)
        if target_idx == this_idx
            dirs = ["."]
        elseif target_idx < this_idx
            rel_path = process_level(target_level, dir)
            dirs = glob(joinpath(rel_path, "..", level_patterns_s[target_idx]))
        else
            dirs = glob(joinpath(level_patterns_s[this_idx+1:target_idx]...))
        end
    end
    if dir != pwd()
        dirs = [joinpath(dir, d) for d in dirs]
    end
    dirs
end

"""
    get_level_dirs(level::String, dirs::Vector{String})

Get all unique level directories contained in `dirs`.
"""
function get_level_dirs(level::String, dirs::Vector{String})
    cwd = pwd()
    level_dirs = String[]
    for c in dirs
        cd(c) do
            cd(process_level(level))
            _dir = pwd()
            _dir = strip(replace(_dir, cwd => ""), '/')
            if !(_dir in level_dirs)
                push!(level_dirs, _dir)
            end
        end
    end
    level_dirs
end

"""
    process_level(::Type{T}, dir=pwd();kvs...) where T <: DPHData

Returns the relative path to an object of type `T`, using `dir` as the starting point.
"""
function process_level(::Type{T}, dir=pwd();kvs...) where T <: DPHData
    target_level = level(T)
    process_level(target_level, dir;kvs...)
end

"""
    process_level(target_level::String, dir=pwd();kvs...)

Returns the path relative to `dir` of the level `target_level`.

# Examples
```jldoctest
julia> DataProcessingHierarchyTools.process_level("session", "Whiskey/session01/array02/channel034")
"./../.."
```
"""
function process_level(target_level::String, dir=pwd();kvs...)
    # get the current level
    this_level = level(dir)
    this_idx = findfirst(l->this_level==l, levels)
    target_idx = findfirst(l->target_level==l, levels)
    for lidx in [this_idx, target_idx]
        if lidx == nothing || !(0 < lidx <= length(levels))
            throw(ArgumentError("Unknown level"))
        end
    end
    pl = ["."]
    append!(pl, [".." for i in 1:(this_idx - target_idx)])
    dirstring = joinpath(pl...)
end

"""
    get_relative_path(level_dir::String,dir=pwd())

Return the path of the current directory relative to `level_dir`.
"""
function get_relative_path(level_dir::String,dir=pwd())
    this_level = level(dir)
    this_idx = findfirst(l->this_level==l, levels)
    target_idx = findfirst(l->level_dir==l, levels)
    if target_idx+1 <= this_idx
        parts = String[]
        for ii in target_idx+1:this_idx
            push!(parts, get_level_name(levels[ii],dir))
        end
    elseif target_idx == this_idx
        parts = ["."]
    else
        error("Target level must be below the current level")
    end
    joinpath(parts...)
end

"""
    process_dirs(::Type{T}, dirs::Vector{String}, args...;kvs...) where T <: DPHData

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
    visit_dirs(::Type{T}, dirs::Vector{String}, args...;kvs...) where T <: DPHData

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
    process_dirs(func::Function, dirs::Vector{String}, args...;kvs...)

Process each directory in `dirs` by running the function `func`.
"""
function process_dirs(func::Function, dirs::Vector{String}, args...;kvs...)
    Q = Vector{Any}(undef, length(dirs))
    @showprogress 1 "Processing dirs..." for (i,d) in enumerate(dirs)
        Q[i] = cd(d) do
            func(args...;kvs...)
        end
    end
    Q
end

"""
    load(::Type{T}, args...;kvs...) where T <: DPHData

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

"""
    sanitise(ss::String)

Convert some unicde symbols to their latex equivalent before saving.

# Examples
```jldoctest
julia> DataProcessingHierarchyTools.sanitise("σ")
"sigma"
```
"""
function sanitise(ss::String)
    oo = String[]
    for (i,c) in enumerate(ss)
        sc = string(c)
        m = matches(def, sc)
        if !isempty(m)
            push!(oo, m[1])
        else
            push!(oo, sc)
        end
    end
    join(oo, "")
end

"""
    desanitise(ss::String)

Convert from certain unicode names to latex symbols.

# Examples
```jldoctest
julia> DataProcessingHierarchyTools.desanitise("sigma")
"σ"
```
"""
function desanitise(ss::String)
    oo = String[]
    ss_split = split(ss, "_")
    for _ss in ss_split
        _nss = filter(!isdigit, _ss)
        ll = lookupname(def, _nss)
        if isempty(ll)
            ll = _nss
        end
        lln = replace(_ss, _nss => ll)
        push!(oo, lln)
    end
    join(oo, "_")
end

"""
    save(X::T, fname=filename(X.args)) where T <: DPHData

Save `X` to a Matlab compatible file.
"""
function save(X::T, fname=filename(X.args)) where T <: DPHData
    Q = convert(Dict{String,Any}, X)
    MAT.matwrite(fname,Q)
end

function save(X::Vector{T}) where T <: DPHData
    fname = filename([x.args for x in X])
    Q = Dict{String, Dict{String,Any}}()
    for (i,x) in enumerate(X)
        Q["idx$(i)"] = convert(Dict{String,Any}, x)
    end
    MAT.matwrite(fname,Q)
end

function Base.convert(::Type{Dict{String,Any}}, X::T) where T <: Union{DPHData, DPHDataArgs}
    Q = Dict{String,Any}()
    for f in fieldnames(T)
        v = getfield(X, f)
        fs = string(f)
        fs = sanitise(fs)
        if typeof(v) <: AbstractVector
            Q[fs] = collect(v)
        elseif typeof(v) <: DPHDataArgs
            Q[fs] = convert(Dict{String,Any}, v)
        elseif typeof(v) <: Symbol
            Q[fs] = string(v)
        else
            Q[fs] = v
        end
    end
    Q
end

"""
    load(::Type{T}, fname=filename(T)) where T <: DPHData

Load a variable of type `T` from the file pointed to by `fname`.
"""
function load(::Type{T}, fname=filename(T)) where T <: DPHData
    if islink(fname) && git_annex != nothing
        run(`$(git_annex()) get $fname`)
    end
    if isfile(fname)
        Q = MAT.matread(fname)
    else
        error("No data exist with the specified arguments")
    end
    convert(T, Q)
end

function load(::Type{Vector{T}}, fname=filename{T}) where T <: DPHData
    Q = MAT.matread(fname)
    X = Vector{T}(undef, length(Q))
    for (k,v) in Q
        ii = parse(Int64, replace(k,"idx" => ""))
        X[ii] = convert(T,v)
    end
    X
end

function Base.convert(::Type{T}, Q::Dict{String, Any}) where T <: Union{DPHData, DPHDataArgs}
    a_args = Any[]
    for f in fieldnames(T)
        tt = fieldtype(T,f)
        fs = string(f)
        fs = sanitise(fs)
        if tt <: Symbol
            vv = Symbol(Q[fs])
        elseif tt <: DPHDataArgs
            #handle arguments to other types here
            vv = convert(tt, Q[fs])
        elseif tt <: AbstractVector && !(typeof(Q[fs]) <: AbstractVector)
            vv = eltype(tt)[Q[fs];]
        elseif tt <: AbstractMatrix && !(typeof(Q[fs]) <: AbstractMatrix)
            vv = fill(Q[fs], 1,1)
        else
            vv = Q[fs]
        end
        push!(a_args, vv)
    end
    T(a_args...)
end

"""
    Base.filter(func::Function, typeargs::T2, dirs::Vector{String}, args...;verbose=0)  where T2 <: DPHDataArgs

Return those directories among `dirs` where `func`,using arguments `args`,  returns true for an object whose arguments are compatible with  `typeargs`.
"""
function Base.filter(func::Function, typeargs::T2, dirs::Vector{String}, args...;verbose=0)  where T2 <: DPHDataArgs
    outdirs = String[]
    for d in dirs
        cd(d) do
            fname = filename(typeargs)
            if isfile(fname)
                aa = false
                try
                    X = load(typeargs)
                    aa = func(X,args...)
                catch
                    if verbose > 0
                        rethrow()
                    end
                end
                if aa
                    push!(outdirs, d)
                end
            end
        end
    end
    outdirs
end

function Base.show(io::IO, X::T) where T <: DPHDataArgs
    compact = get(io, :compact, false)
    print("$T with fields:\n")
    for f in fieldnames(T)
        v = getfield(X, f)
        if fieldtype(T, f) <: String
            print(io, "\t$f = \"$v\"\n")
        elseif fieldtype(T, f) <: Symbol
            print(io, "\t$f = :$v\n")
        else
            print(io, "\t$f = $v\n")
        end
    end
end

"""
    findargs(::Type{T}, cwd=pwd();kvs...) where T <: DPHData

Return a list of arguments for which data exists for the type `T`.
"""
function findargs(::Type{T}, cwd=pwd();kvs...) where T <: DPHData
	fname = filename(T)
	fname = replace(fname, ".mat" => "*.mat")
	arg_type = fieldtype(T, :args)
	targs = filter(k->k[1] in fieldnames(arg_type), kvs)
	args = cd(cwd) do
		files = glob(fname)
		args = arg_type[]
		for (ii,ff) in enumerate(files)
			X = load(T, ff)
			found = true
			for (k,v) in targs
				if getfield(X.args,k) != v
					found = false
					break
				end
			end
			if found
				push!(args, X.args)
			end
		end
		args
	end
	args
end

function reset!(args::DPHDataArgs)
    reset!(filename(args))
end

"""
    reset!(fname::String)

Unlock the file pointed to be `fname` if it is under git annex control, so that it can be overwritten.
"""
function reset!(fname::String)
    if islink(fname)
        if git_annex != nothing
            run(`$(git_annex()) unlock $fname`)
        end
    end
end
end # module
