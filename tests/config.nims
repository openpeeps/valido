switch("path", "$projectDir/../src")

# The country/SWIFT API lives behind `-d:validoExtras`, so the suite compiles
# with it enabled to keep that code covered.
switch("define", "validoExtras")
