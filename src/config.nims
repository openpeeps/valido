# Put this package's own sources first so the `importFilters` macro in
# `valido.nim` (`import valido/<module>`) resolves to the workspace,
# never to a nimble-installed copy of valido.
switch("path", "$projectDir")
