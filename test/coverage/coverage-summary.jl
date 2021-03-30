using Coverage
cd(joinpath(@__DIR__, "..", "..")) do
    coverage = process_folder()
    covered_lines, total_lines = get_summary(coverage)
    mkdir("coverage")
    Coverage.LCOV.writefile("coverage/lcov.info", coverage)
    branch = strip(read(`git branch`, String), [' ', '*', '\n'])
    title = "on branch $(branch)"
    run(`genhtml -t $(title) -o coverage coverage/lcov.info`)
    percentage = covered_lines / total_lines * 100
    println("($(percentage)%) covered")
end
