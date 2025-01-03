using OptimalBranching, Graphs, OptimalBranching.OptimalBranchingCore, OptimalBranching.OptimalBranchingCore.BitBasis
using BenchmarkTools, CSV, DataFrames
using JuMP
using Suppressor

function tree_like_N3_neighborhood(g0::SimpleGraph)
    g = copy(g0)
    for layer in 1:3
        for v in vertices(g)
            for _ = 1:(3-degree(g, v))
                add_vertex!(g)
                add_edge!(g, v, nv(g))
            end
        end
    end
    return g
end

function solve_opt_rule(branching_region, graph, vs)
    # Use default solver and measure
    m = D3Measure()
    table_solver = TensorNetworkSolver(; prune_by_env=true)
    set_cover_solver = IPSolver()

    # Pruning irrelevant entries
    ovs = OptimalBranchingMIS.open_vertices(graph, vs)
    subg, vmap = induced_subgraph(graph, vs)
    tbl = OptimalBranchingMIS.reduced_alpha_configs(table_solver, subg, Int[findfirst(==(v), vs) for v in ovs])
    candidate_clauses = collect(OptimalBranchingMIS.OptimalBranchingCore.candidate_clauses(tbl))
    problem = MISProblem(graph)
    size_reductions = [measure(problem, m) - measure(first(OptimalBranchingCore.apply_branch(problem, candidate, vs)), m) for candidate in candidate_clauses]

    return tbl, candidate_clauses, size_reductions
end

function bottleneck_graph()
    vs = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
    edges = [(1, 2), (1, 3), (1, 4), (2, 5), (2, 6), (3, 7), (3, 8), (4, 9), (4, 10), (5, 11), (5, 12), (6, 13), (6, 14), (7, 15), (7, 16), (8, 17), (8, 18), (9, 19), (9, 20), (10, 21), (10, 22), (11, 14), (12, 13), (15, 18), (16, 17), (19, 22), (20, 21)]
    branching_region = SimpleGraph(Graphs.SimpleEdge.(edges))
    graph = tree_like_N3_neighborhood(branching_region)
    return branching_region, graph, vs
end