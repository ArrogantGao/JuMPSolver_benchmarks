include("utils.jl")
using CDDLib, Clarabel, Cbc, COSMO, DSDP, ECOS, GLPK, HiGHS, Hypatia, Ipopt, Loraine, MadNLP, OSQP, ProxSDP, SCIP, SCS, SDPA, Tulip

function solve_lp(solver, weights::AbstractVector, subsets::Vector{Vector{Int}}, num_items::Int)
    nsc = length(subsets)

    sets_id = [Vector{Int}() for _=1:num_items]
    for i in 1:nsc
        for j in subsets[i]
            push!(sets_id[j], i)
        end
    end

    # LP by JuMP
    model = Model(solver.Optimizer)
    # !solver.verbose && set_silent(model)
    @variable(model, 0 <= x[i = 1:nsc] <= 1)
    @objective(model, Min, sum(x[i] * weights[i] for i in 1:nsc))
    for i in 1:num_items
        @constraint(model, sum(x[j] for j in sets_id[i]) >= 1)
    end

    @suppress optimize!(model)
    xs = value.(x)
    @assert OptimalBranchingCore.is_solved(xs, sets_id, num_items)
    return OptimalBranchingCore.pick_sets(xs, subsets, num_items)
end

function main()
    branching_region, graph, vs = bottleneck_graph()
    tbl, candidate_clauses, size_reductions = solve_opt_rule(branching_region, graph, vs)
    subsets = [OptimalBranchingCore.covered_items(tbl.table, c) for c in candidate_clauses]
    num_items = length(tbl.table)
    weights = 1 ./ 1.2 .^ size_reductions

    CSV.write("data/lp_solvers_15782.csv", DataFrame(solver=[], cx=Float64[], time=Float64[]))

    for solver in [
        Ipopt, 
        ECOS, 
        # COPT, # no license
        # Clarabel, # no license
        Cbc, 
        COSMO, # solve failed
        # DSDP, too slow 104.201825875
        GLPK, 
        HiGHS, 
        # Hypatia, too slow
        # Loraine, too slow 332.177171117
        MadNLP, 
        OSQP, # solve failed
        ProxSDP, # solve failed
        SCIP, 
        SCS, # solve failed
        SDPA, 
        Tulip]
        try
            @info "solver = $(solver)"
            picked_scs = solve_lp(solver, weights, subsets, num_items)
            cx = OptimalBranchingCore.complexity_bv(size_reductions[picked_scs])
            @info "cx = $(cx)"
            time = @belapsed solve_lp($solver, $weights, $subsets, $num_items)
            @info "solver = $(solver), time = $(time)"
            CSV.write("data/lp_solvers_15782.csv", DataFrame(solver=solver, cx=cx, time=time), append=true)
        catch e
            @info "solver = $(solver), error = $(e)"
        end
    end
end

main()
