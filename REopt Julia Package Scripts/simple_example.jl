"""
The REopt Julia package optimizes distributed energy resources to minimize the lifecycle cost of energy at a site.
This file provides an example of how to use REopt.jl.
See the package documentation for more information: https://nrel.github.io/REopt.jl/stable/ 
You will need Julia installed to run this.
"""
### Follow these steps ###
# Step 1: Open a Julia terminal and navigate to this subfolder
# julia> cd("path/to/REopt Julia Package Scripts")
# Step 2: Activate the environment in this directory (hit the "]" key to enter the package manager)
# pkg> activate .
# (You can view all of the packages in this environment with pkg > st)
# Step 3: Run this file 
# julia> include("simple_example.jl")

using REopt
# Cbc is a free solver and may be slow with models that involve binary variables. Replace with your own solver (e.g., Xpress) if desired.
using Cbc 
using JSON
using JuMP
# See documentation for also adding GhpGhx

## Run a single model with no business-as-usual (BAU) case: ##
print("\nRunning a single REopt model with no BAU.\n")
m = Model(Cbc.Optimizer) # Another example, using Xpress: m = Model(optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.01, "OUTPUTLOG" => 0))
data_file = "pv_retail.json" # Notice that just the PV key with an empty dictionary is provided to tell REopt to consider PV
data = JSON.parsefile("scenarios/$data_file")

data["Financial"]["analysis_years"] = 20 # Example modifying the scenario

# Run REopt
results = run_reopt(m, data)

# Print some results
print("\nPV [kW]: ", results["PV"]["size_kw"])
print("\nLifecycle cost [\$]: ", results["Financial"]["lcc"])

# Save results json
write("./results/$data_file", JSON.json(results))







