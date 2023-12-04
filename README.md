# PersistentWorkers

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://simeonschaub.github.io/PersistentWorkers.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://simeonschaub.github.io/PersistentWorkers.jl/dev/)
[![Build Status](https://github.com/simeonschaub/PersistentWorkers.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/simeonschaub/PersistentWorkers.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/simeonschaub/PersistentWorkers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/simeonschaub/PersistentWorkers.jl)

Requires https://github.com/JuliaLang/Distributed.jl/pull/9

On the worker:

```julia
using PersistentWorkers
start_worker_loop(port; cluster_cookie="<cookie>")
```

Then set up the head node:

```julia
using Distributed, PersistentWorkers
cluster_cookie("<cookie>")
```

Add the worker on the head node using:

```julia
addprocs(PersistentWorkerManager(port))
```

and then proceed as with any other worker.
Persistent workers can be removed again using `rmprocs` as usual and even added again at a later point.
