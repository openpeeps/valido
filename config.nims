# Ensure the workspace sources take precedence over any
# nimble-installed copy of this same package when compiling
# from the repository root (e.g. `nim check src/valido.nim`).
switch("path", "$projectDir/src")
