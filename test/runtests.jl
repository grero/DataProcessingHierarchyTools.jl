module DPHTTest
using DataProcessingHierarchyTools
const DPHT = DataProcessingHierarchyTools
using Base.Test
using MAT

import Base.hcat

struct TestData <: DPHData
    data::String
    setid::Vector{Int64}
end

level(::Type{TestData}) = "session"
filename(::Type{TestData}) = "data.mat"

function Base.hcat(X1::TestData, X2::TestData)
    ndata = "$(X1.data)$(X2.data)"
    setid = [X1.setid;X2.setid + X1.setid[end]]
    TestData(ndata, setid)
end


function TestData()
    dd = MAT.matread(filename(TestData))
    TestData(dd["data"], dd["setid"])
end

function TestData(x)
    X = TestData("test", [1])
    save_data(X)
    X
end

function save_data(X::TestData)
    MAT.matwrite(filename(TestData), Dict("data" => X.data,
                                          "setid" => X.setid))
end

dirs =["20140903/session01", "20140903/session02"]

@testset "Level functions" begin
    thislevel = DPHT.level("newWorkingMemory/Pancake/20130923")
    @test thislevel == "day"
    _name = DPHT.get_level_name("days","newWorkingMemory/Pancake/20130923/")
    @test _name == "20130923"
    _pth = DPHT.process_level("session", "Pancake/20130923/session01/array01/channel001")
    @test _pth == "./../.."
    dd = tempdir()
    cd(dd) do
        for d2 in dirs
            mkpath(d2)
        end
        func() = touch("test.txt")
        DPHT.process_dirs(func, dirs)
        for d2 in dirs
            @test isfile("$(d2)/test.txt")
        end
        #cleanup
        cd(dirs[1]) do
            thislevel = DPHT.level()
            @test thislevel == "session"
        end
        for d2 in dirs
            rm(d2;recursive=true)
        end
    end
end

@testset "Types" begin
    dd = tempdir()
    cd(dd) do
        for d2 in dirs
            mkpath(d2)
        end
        Y = DPHT.process_dirs(TestData, dirs, 1)
        for d2 in dirs
            cd(d2) do
                @test isfile(filename(TestData))
            end
        end
        @test Y.data == "testtest"
        @test Y.setid == [1,2]
        for d2 in dirs
            rm(d2;recursive=true)
        end
    end
end

end#module
