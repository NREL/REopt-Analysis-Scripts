"""
The REopt Julia package optimizes distributed energy resources to minimize the lifecycle cost of energy at a site.
This file provides an example of how to use REopt.jl.
See the package documentation for more information: https://nrel.github.io/REopt.jl/stable/ 
You will need Julia installed to run this.

### Follow these steps for this example ###
Step 1: Open a Julia terminal and navigate to this subfolder
 julia> cd("path/to/REopt Julia Package Scripts")
 can check working directory with: julia> pwd()
Step 2: Activate and instantiate the environment in this directory (hit the "]" key to enter the package manager)
 pkg> activate .
 (REopt Julia Package Scripts) pkg> instantiate
(You can view all of the packages in this environment with pkg > st)
Step 3: Run this file (leave the package manager with the backspace button)
 julia> include("simple_examples.jl")
"""

# Replace with your API Key
ENV["NREL_DEVELOPER_API_KEY"] = "DEMO_KEY"

## Example 1: Run a single model with no business-as-usual (BAU) case with Cbc solver: ##
using REopt
using Cbc # Cbc is a free solver. It may be slow with models that involve binary variables. Replace with your own solver (e.g., Xpress) if desired.
using JSON
using JuMP
# See documentation for also adding GhpGhx

# Ensure latest REopt version is used
using Pkg
Pkg.update("REopt")

println("Running a single REopt model with no BAU.")

# Setup inputs
data_file = "pv_retail.json" # Notice that just the PV key with an empty dictionary is provided to tell REopt to consider PV
data = JSON.parsefile("scenarios/$data_file")
data["Financial"]["analysis_years"] = 20 # Example modifying the scenario

# Define model
m = Model(Cbc.Optimizer) # Another example, using Xpress: m = Model(optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.01, "OUTPUTLOG" => 0))

# Run REopt
results = run_reopt(m, data)

# Print some results
println("PV [kW]: ", results["PV"]["size_kw"])
println("Lifecycle cost [\$]: ", results["Financial"]["lcc"])

# Save results json
write("./results/$data_file", JSON.json(results))


## Example 2: Run a model with a BAU case using HiGHS Solver: ## 
using HiGHS # HiGHS is a free solver

println("Running a REopt model with a BAU.")

# Setup inputs
data_file = "wind_battery_hospital.json" 
data = JSON.parsefile("scenarios/$data_file")

# Define models
m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false, "log_to_console" => false))
m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false, "log_to_console" => false))

# Run REopt
results = run_reopt([m1,m2], data) # Must supply two models to run the BAU (BAU scenario automatically generated based on inputs)

# Print some results
println("Wind [kW]: ", results["Wind"]["size_kw"])
println("Battery [kW]: ", results["ElectricStorage"]["size_kw"])
println("Battery [hours]: ", results["ElectricStorage"]["size_kwh"] / results["ElectricStorage"]["size_kw"])
println("Lifecycle cost [\$]: ", results["Financial"]["lcc"])
println("NPV [\$]: ", results["Financial"]["npv"]) # Now you can get a NPV 

# Save results json
write("./results/$data_file", JSON.json(results))


