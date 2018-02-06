using DataProcessingHierarchyTools
const DPHT = DataProcessingHierarchyTools
using Base.Test

@testset "Level functions" begin
    _name = DPHT.get_level_name("days","newWorkingMemory/Pancake/20130923/")
    @test _name == "20130923"
end
