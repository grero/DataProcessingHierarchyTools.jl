using DataProcessingHierarchyTools
using Base.Test

@testset "Level functions" begin
    _name = ExperimentDataTools.get_level_name("days","newWorkingMemory/Pancake/20130923/")
    @test _name == "20130923"
end
