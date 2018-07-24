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

function Base.hash(args::T, h::UInt64) where T <: DPHDataArgs
    for f in fieldnames(args)
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
