using PersistentWorkers
using Test
using Random
using Distributed

include("🏴‍☠️.jl")

@testset "PersistentWorkers.jl" begin
    cookie = randstring(16)
    port = 9127 # TODO: make sure port is available?
    worker = run(`$(Base.julia_cmd()) --project -e "using PersistentWorkers; wait(start_worker_loop($port; cluster_cookie=\"$cookie\"))"`; wait=false)
    @show worker
    try
    cluster_cookie(cookie)

    p = addprocs(PersistentWorkerManager(port))[]
    @test procs() == [1, p]
    @test workers() == [p]
    @test remotecall_fetch(myid, p) == p
    rmprocs(p)
    @test procs() == [1]
    @test workers() == [1]
    @test process_running(worker)
    # this shouldn't error
    @everywhere 1+1

    # try the same thing again for the same worker
    p = addprocs(PersistentWorkerManager(port))[]
    @test procs() == [1, p]
    @test workers() == [p]
    @test remotecall_fetch(myid, p) == p
    rmprocs(p)
    @test procs() == [1]
    @test workers() == [1]
    @test process_running(worker)
    # this shouldn't error
    @everywhere 1+1

    p = addprocs(PersistentWorkerManager(port))[]
    @test procs() == [1, p]
    @test workers() == [p]
    # kill the worker now
    remotecall(exit, p)
    sleep(10)
    @test procs() == [1]
    @test workers() == [1]
    @test process_exited(worker)
    # this shouldn't error
    @everywhere 1+1
    finally
        kill(worker)
    end
end
