using PersistentWorkers, Distributed

@show ARGS
include("🏴‍☠️.jl")

wait(start_worker_loop(parse(Int, ARGS[1]), cluster_cookie=ARGS[2])[1])
