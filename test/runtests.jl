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
    dd = tempdir()
    cd(dd) do
        dirs =["20140903/session01", "20140903/session02"]
        for d2 in dirs
            mkpath(d2)
        end
        func() = touch("test.txt")
        DPHT.process_dirs(func, dirs)
        for d2 in dirs
            @test isfile("$(d2)/test.txt")
        end
        #cleanup
        for d2 in dirs
            rm(d2;recursive=true)
        end
    end
end
