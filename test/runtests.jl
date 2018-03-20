module DPHTTest
using DataProcessingHierarchyTools
const DPHT = DataProcessingHierarchyTools
import DataProcessingHierarchyTools:level, filename
using Base.Test

import Base:hcat, zero

struct TestData <: DPHData
    data::String
    setid::Vector{Int64}
end

zero(::Type{TestData}) = TestData("", Int64[])

DPHT.level(::Type{TestData}) = "session"
DPHT.filename(::Type{TestData}) = "data.txt"

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
        TestData(data, setid)
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
    _name = DPHT.get_level_name("day","newWorkingMemory/Pancake/20130923")
    @test _name == "20130923"
    _name = DPHT.get_level_name("subject","newWorkingMemory/Pancake/20130923")
    @test _name == "Pancake"
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
            #test getting all level directories belonging to a particular level
            session_dirs = DPHT.get_level_dirs("session")
            @test session_dirs[1] == "./../session01"
            @test session_dirs[2] == "./../session02"
        end
        dirsn = DPHT.get_level_dirs("session")
        @test dirsn[1] == dirs[1]
        @test dirsn[2] == dirs[2]
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
                ll = DPHT.process_level(TestData)
                @test ll == "."
            end
        end
        @test Y.data == "testtest"
        @test Y.setid == [1,2]
        cd(dirs[1]) do
            mkdir("array01")
            cd("array01") do
                q = DPHT.load(TestData)
                @test q.data == "test"
                @test  q.setid == [1]
            end
        end
        cd(dirs[2]) do
            rm(filename(TestData))
            mkdir("array01")
            cd("array01") do
                q = DPHT.load(TestData)
                @test q.data == ""
                @test  q.setid == []
            end
        end

        for d2 in dirs
            rm(d2;recursive=true)
        end
    end
end

@testset "Graceful fail" begin
    dd = tempdir()
    mkpath(dirs[1])
    cd(dirs[1]) do
        @test_throws ArgumentError DPHT.process_level("rubbish")
    end
    rm(dirs[1];recursive=true)
    @test_throws ErrorException DPHT.level(DPHT.DPHData)
    @test_throws ErrorException DPHT.filename(DPHT.DPHData)
end

@testset "Shortnames" begin
    sn = DPHT.get_shortname("cell01")
    @test sn == "c01"
    sn = DPHT.get_shortname("newWorkingMemory/James/20140904/session01/array01/channel030/cell01")
    @test sn == "J20140904s01a01g030c01"
end

struct MyArgs <: DPHT.DPHDataArgs
    f1::Float64
    f2::Int64
    f3::AbstractVector{Float64}
end

@testset "ArgsCheck" begin
    args = MyArgs(1.0, 3, -1.0:0.5:10.0)
    @test DPHT.check_args(args, 1.0, 3, -1.0:0.5:10.0)
    @test DPHT.check_args(args, 2.0, 3, -1.0:0.5:10.0) == false
    @test DPHT.check_args(args, 1.0, 2, -1.0:0.5:10.0) == false
    @test DPHT.check_args(args, 1.0, 3, -1.0:1.0:10.0) == false
end


end#module
