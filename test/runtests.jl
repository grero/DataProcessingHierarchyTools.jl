module DPHTTest
using DataProcessingHierarchyTools
const DPHT = DataProcessingHierarchyTools
import DataProcessingHierarchyTools:level, filename
using Test
using LinearAlgebra

import Base:hcat, zero

struct TestData <: DPHData
    data::String
    setid::Vector{Int64}
end

zero(::Type{TestData}) = TestData("", Int64[])

DPHT.level(::Type{TestData}) = "session"
DPHT.filename(::Type{TestData}) = "data.mat"

function Base.hcat(X1::TestData, X2::TestData)
    ndata = "$(X1.data)$(X2.data)"
    setid = [X1.setid;X2.setid .+ X1.setid[end]]
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
    rpath = DPHT.get_relative_path("subjects", "newWorkingMemory/Pancake/20130923")
    @test rpath == "Pancake/20130923"
    rpath = DPHT.get_relative_path("day", "newWorkingMemory/Pancake/20130923")
    @test rpath == "."
    @test_throws ErrorException DPHT.get_relative_path("channel", "newWorkingMemory/Pancake/20130923")

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
        level_dirs = DPHT.get_level_dirs("session", dirs)
        @test level_dirs == dirs
        #cleanup
        cd(dirs[1]) do
            thislevel = DPHT.level()
            @test thislevel == "session"
            #test getting all level directories belonging to a particular level
            session_dirs = DPHT.get_level_dirs("session")
            @test session_dirs[1] == "./../session01"
            @test session_dirs[2] == "./../session02"
        end
        dirsn = DPHT.get_level_dirs("session",dirs[1])
        @test dirsn[1] == "20140903/session01/./../session01"
        @test dirsn[2] == "20140903/session01/./../session02"
        dirsn = DPHT.get_level_dirs("session")
        @test dirsn[1] == dirs[1]
        @test dirsn[2] == dirs[2]
        for d2 in dirs
            rm(d2;recursive=true)
        end
    end
    ss = "/tmp/temp2/Pancake/20130923/session01/array01/channel001/cell01"
    pp = DPHT.get_fullname(ss)
    @test pp == joinpath("Pancake","20130923","session01","array01","channel001","cell01")
    ss = "/tmp/temp2/Pancake"
    pp = DPHT.get_fullname(ss)
    @test pp == "Pancake"
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

struct MyData <: DPHT.DPHData
    dd::Float64
    args::MyArgs
end

DPHT.filename(::Type{MyData}) = "mydata.mat"
DPHT.datatype(::Type{MyArgs}) = MyData
DPHT.level(::Type{MyData}) = "session"

function MyData(args::MyArgs;force_redo=false, do_save=true)
    fname = DPHT.filename(args)
    redo = force_redo || !isfile(fname)
    if !redo
        X = DPHT.load(args)
    else
        x = args.f1*args.f2*sum(args.f3)
        X = MyData(x, args)
        if do_save
            DPHT.save(X)
        end
    end
    X
end

@testset "ArgsHash" begin
    args = MyArgs(1.0, 3, -1.0:0.5:10.0)
    h = hash(args)
    @test h == 0x34c727e2f750c253
    @test DPHT.filename(args) == "mydata_34c727e2f750c253.mat"
end

@testset "ArgsCheck" begin
    args = MyArgs(1.0, 3, -1.0:0.5:10.0)
    @test DPHT.check_args(args, 1.0, 3, -1.0:0.5:10.0)
    @test DPHT.check_args(args, 1.0, 3, collect(-1.0:0.5:10.0))
    @test DPHT.check_args(args, 2.0, 3, -1.0:0.5:10.0) == false
    @test DPHT.check_args(args, 1.0, 2, -1.0:0.5:10.0) == false
    @test DPHT.check_args(args, 1.0, 3, -1.0:1.0:10.0) == false
    args2 = MyArgs(1.0, 3, -1.0:0.5:10.0)
    @test DPHT.check_args(args, args2)
    args3 = MyArgs(1.0, 3, -1.0:0.1:10.0)
    @test DPHT.check_args(args, args3) == false
    args4 = MyArgs(1.0, 4, -1.0:0.1:10.0)
    @test DPHT.check_args(args, args4) == false
end

@testset "Save and load" begin
    dd = tempdir()
    args = MyArgs(1.0, 3, -1.0:0.5:10.0)
    cd(dd) do
        DPHT.visit_dirs(MyData, dirs, args)
        cd(dirs[1]) do
            X = MyData(args;do_save=true, force_redo=false)
            mkdir("array01")
            cd("array01") do
                cd(DPHT.process_level(DPHT.level(MyData))) do
                    X2 = MyData(args;do_save=true, force_redo=false)
                    @test X.dd ≈ X2.dd
                end
            end
        end
        cd(dirs[2]) do
            rm(DPHT.filename(args))
            mkdir("array01")
            cd("array01") do
                cd(DPHT.process_level(DPHT.level(MyData))) do
                    @test_throws ErrorException q = DPHT.load(TestData)
                end
            end
        end

        for d2 in dirs
            rm(d2;recursive=true)
        end
        args2 = MyArgs(1.0, 3, [1.0])
        X = MyData(args2)
        fname = DPHT.filename(args2)
        @test isfile(fname)
        X2 = MyData(args2)
        @test X.args.f3 == X2.args.f3
        rm(fname)
    end
end

struct SArgs <: DPHT.DPHDataArgs
    a::Int64
end

struct S <: DPHT.DPHData
    μ::Vector{Float64}
    Σ::Matrix{Float64}
    args::SArgs
end

DPHT.filename(::Type{S}) = "mydata.mat"
DPHT.datatype(::Type{SArgs}) = S

@testset "Variable sanitasion" begin
    ss = S([0.0, 0.0], Matrix{Float64}(I,2,2), SArgs(1.0))
    Q = convert(Dict{String,Any}, ss)
    @test Q["mu"] ≈ ss.μ
    @test Q["Sigma"] ≈ ss.Σ

    ss2 = convert(S, Q)
    @test ss2.μ ≈ ss.μ
    @test ss2.Σ ≈ ss.Σ

    Q = Dict{String,Any}("mu" => 1.0, "Sigma" => 0.5,
                         "args" => Dict{String,Any}("a" => 3))
    ss3 = convert(S, Q)
    @test ss3.μ ≈ [1.0]
    @test ss3.Σ ≈ fill(0.5, 1,1)
end

@testset "Array of objects" begin
    args = [SArgs(1.0), SArgs(2.0), SArgs(3.0)]
    ss = S[]
    for a in args
        push!(ss, S([0.0, 0.0], [[0.1 0.1];[0.3 0.1]], a))
    end
    dd = tempdir()
    cd(dd) do
        DPHT.save(ss)
        ss2 = DPHT.load(args)
        @test ss2[1].args == args[1]
        @test ss2[1].μ == ss[1].μ
        @test ss2[1].Σ == ss[1].Σ
        @test ss2[2].args == args[2]
        @test ss2[2].μ == ss[2].μ
        @test ss2[2].Σ == ss[2].Σ
        @test ss2[3].args == args[3]
        @test ss2[3].μ == ss[3].μ
        @test ss2[3].Σ == ss[3].Σ
        fname = DPHT.filename(args)
        h = hash(args)
        @test h == 0xb6f003559185097d
        rm(fname)
    end
end

@testset "git-annex" begin
    tdir = tempdir()
    s_args = SArgs(2)
    ss = S([0.1], [0.0 1.0; 1.0 0.0], s_args)
    cd(tdir) do
        mkpath("testdata")
        cd("testdata") do
            DPHT.save(ss)
            if DPHT.git_annex() != nothing
                run(`git init`)
                run(`$(DPHT.git_annex()) init .`)
                run(`$(DPHT.git_annex()) add .`)
                mkpath("../testdata2")
                cd("../testdata2") do
                    run(`git init --bare `)
                end
                run(`git remote add origin ../testdata2`)
                run(`$(DPHT.git_annex()) sync origin`)
                run(`$(DPHT.git_annex()) copy -t origin .`)
                run(`$(DPHT.git_annex()) drop .`)
            end
            ss2 = DPHT.load(s_args)
            @test ss2.args.a == ss.args.a
            #cleanup
            if DPHT.git_annex() != nothing
                fname = DPHT.filename(s_args)
                run(`$(DPHT.git_annex()) drop --force --from origin $fname`)
                run(`$(DPHT.git_annex()) drop --force $fname`)
            end
        end
        #cleanup

        rm("testdata", recursive=true)
        if isdir("testdata2")
            rm("testdata2", recursive=true)
        end
    end
end
end#module
