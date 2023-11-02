using PersistentWorkers
using Documenter

DocMeta.setdocmeta!(PersistentWorkers, :DocTestSetup, :(using PersistentWorkers); recursive=true)

makedocs(;
    modules=[PersistentWorkers],
    authors="Simeon David Schaub <simeondavidschaub99@gmail.com> and contributors",
    repo="https://github.com/simeonschaub/PersistentWorkers.jl/blob/{commit}{path}#{line}",
    sitename="PersistentWorkers.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://simeonschaub.github.io/PersistentWorkers.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/simeonschaub/PersistentWorkers.jl",
    devbranch="main",
)
