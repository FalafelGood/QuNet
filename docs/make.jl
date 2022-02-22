using Documenter, Main.QuNet

makedocs(
    sitename = "QuNet",
    # modules = [QuNet]
    pages = Any[
        "Home" => "index.md"
    ]
)

# deploydocs(
#     deps = Deps.pip("pygments", "mkdocs", "python-markdown-math")
# )
