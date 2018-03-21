abstract type DPHData end
abstract type DPHDataArgs end

function Base.hash(args::T, h::UInt64) where T <: DPHDataArgs
    for f in fieldnames(args)
        x = getfield(args, f)
        if typeof(x) <: AbstractVector
            for _x in x
                h = hash(_x, h)
            end
        else
            h = hash(x, h)
        end
    end
    h
end
