module DPHTTest
using DataProcessingHierarchyTools
const DPHT = DataProcessingHierarchyTools
using Base.Test

import Base.hcat

struct TestData <: DPHData
    data::String
    setid::Vector{Int64}
end

level(::Type{TestData}) = "session"
filename(::Type{TestData}) = "data.txt"

function Base.hcat(X1::TestData, X2::TestData)
    ndata = "$(X1.data)$(X2.data)"
    setid = [X1.setid;X2.setid + X1.setid[end]]
    TestData(ndata, setid)
end


function TestData()
    open(filename(TestData), "r") do f
        data = readline(f)
        ss = readline(f)
        setid = [parse(Int64,s) for s in split(ss, ',')]
        TestData(dd["data"], dd["setid"])
    end
end

function TestData(x)
    X = TestData("test", [1])
    save_data(X)
    X
end

function save_data(X::TestData)
    open(filename(TestData),"w") do f
        write(f, "$(X.data)\n")
        for ss in X.setid[1:end-1]
            write(f, "$(ss),")
        end
        write(f, "$(X.setid[end])\n")
    end
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
