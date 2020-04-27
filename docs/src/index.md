# DataProcessingHierarchyTools Documentation
```@meta
CurrentModule = DataProcessingHierarchyTools
```

## Level functions
```@docs
level(cwd::String)
get_level_name(target_level::String, dir=pwd())
get_level_dirs(target_level::String, dir=pwd())
get_level_dirs(level::String, dirs::Vector{String})
process_level(::Type{T}, dir=pwd();kvs...) where T <: DPHData
process_level(target_level::String, dir=pwd();kvs...)
get_relative_path(level_dir::String,dir=pwd())
process_dirs(::Type{T}, dirs::Vector{String}, args...;kvs...) where T <: DPHData
visit_dirs(::Type{T}, dirs::Vector{String}, args...;kvs...) where T <: DPHData
process_dirs(func::Function, dirs::Vector{String}, args...;kvs...)
```
## Name functions
```@docs
get_shortname(ss::String)
get_fullname(ss::String)
```

## Loading and saving
```@docs
load(::Type{T}, args...;kvs...) where T <: DPHData
save(X::T, fname=filename(X.args)) where T <: DPHData
```
## Utility functions
```@docs 
sanitise(ss::String)
desanitise(ss::String)
```
