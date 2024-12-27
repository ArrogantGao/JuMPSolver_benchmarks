JL = julia --project

default: init

init:
	$(JL) -e 'using Pkg; Pkg.activate(); Pkg.instantiate(); Pkg.update()'

benchmark:
	$(JL) benchmarks/lp_solvers_15782.jl
	$(JL) benchmarks/ip_solvers_15782.jl
