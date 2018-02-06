using DataProcessingHierarchyTools
const DPHT = DataProcessingHierarchyTools
using Base.Test

@testset "Level functions" begin
    thislevel = DPHT.level("newWorkingMemory/Pancake/20130923")
    @test thislevel == "day"
    _name = DPHT.get_level_name("days","newWorkingMemory/Pancake/20130923/")
    @test _name == "20130923"
    _pth = DPHT.process_level("session", "Pancake/20130923/session01/array01/channel001")
    @test _pth == "./../.."
end
