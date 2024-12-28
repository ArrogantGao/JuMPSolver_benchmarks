JL = julia --project

default: init

init:
	$(JL) -e 'ENV["CPLEX_STUDIO_BINARIES"] = "/opt/ibm/ILOG/CPLEX_Studio2211/cplex/bin/x86-64_linux/"; using Pkg; Pkg.activate(); Pkg.instantiate(); Pkg.update()'

benchmark:
	$(JL) benchmarks/lp_solvers_15782.jl
	$(JL) benchmarks/ip_solvers_15782.jl
