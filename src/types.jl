abstract type DPHData end
abstract type DPHDataArgs end
abstract type DPHPlotArgs end

struct BootstrappedDataArgs{T<:DPHDataArgs} <: DPHDataArgs
    nruns::Int64
    ntrials::Int64
    args::T
end

struct DummyPlotArgs <: DPHPlotArgs
end

function shash(args::T, h::UInt64) where T <: DPHDataArgs
    for f in fieldnames(T)
        x = getfield(args, f)
        if typeof(x) <: AbstractVector
            for _x in x
                h = shash(_x, h)
            end
        elseif !((f == :version) && (x == "UNKNOWN"))
            h = shash(x, h)
        end
    end
    h
end

_hash(x) =_hash(x, zero(UInt64))
function _hash(args::T, h::UInt64) where T <: DPHDataArgs
    for f in fieldnames(T)
        x = getfield(args, f)
        if typeof(x) <: AbstractVector
            for _x in x
                h = hash(_x, h)
            end
        elseif !((f == :version) && (x == "UNKNOWN"))
            h = hash(x, h)
        end
    end
    h
end

function shash(args::Vector{T}, h::UInt64) where T <: DPHDataArgs
    for _args in args
        h = shash(_args, h)
    end
    h
end
