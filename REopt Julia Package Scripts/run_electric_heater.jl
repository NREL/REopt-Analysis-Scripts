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

## Example 1: Run a single model with no business-as-usual (BAU) case with Cbc solver: ##
using REopt
using Cbc # Cbc is a free solver. It may be slow with models that involve binary variables. Replace with your own solver (e.g., Xpress) if desired.
using JSON
using JuMP
using CSV # need to compare results
using DataFrames #to construct comparison
using XLSX #will append info put onto CSV files to XLSX file
# See documentation for also adding GhpGhx

## Example 2: Run a model with a BAU case using HiGHS Solver: ## 
using HiGHS # HiGHS is a free solver

println("Running a REopt model with a BAU.")

# Setup inputs
data_file = "electric_heater.json" 
d = JSON.parsefile("scenarios/$data_file")

d["SpaceHeatingLoad"]["annual_mmbtu"] = 0.5 * 8760
d["DomesticHotWaterLoad"]["annual_mmbtu"] = 0.5 * 8760
s = Scenario(d)
p = REoptInputs(s)
m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false, "log_to_console" => false))
m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false, "log_to_console" => false))
results = run_reopt([m1,m2], p)

#first run: Boiler produces the required heat instead of the electric heater - electric heater should not be purchased
results["ElectricHeater"]["size_mmbtu_per_hour"] 
results["ElectricHeater"]["annual_thermal_production_mmbtu"] 
results["ElectricHeater"]["annual_electric_consumption_kwh"] 
results["ElectricUtility"]["annual_energy_supplied_kwh"]


#print some results 
println("First Run where Electric Heater is not utilized")
println("ElectricHeater size [MMBtu/hr]: ", results["ElectricHeater"]["size_mmbtu_per_hour"])
println("ElectricHeater Production [MMBtu/yr]: ", results["ElectricHeater"]["annual_thermal_production_mmbtu"])
println("ElectricHeater Electric Consumption [MMBtu/yr]: ", results["ElectricHeater"]["annual_electric_consumption_kwh"])
println("ElectricUtility Energy Supplied [kWh/yr]: ", results["ElectricUtility"]["annual_energy_supplied_kwh"])
println("Lifecycle cost [\$]: ", results["Financial"]["lcc"] * 1000)
println("NPV [\$]: ", results["Financial"]["npv"])
println("---------------------------------------------------------")

d["ExistingBoiler"]["fuel_cost_per_mmbtu"] = 100
d["ElectricHeater"]["installed_cost_per_mmbtu_per_hour"] = 1.0
d["ElectricTariff"]["monthly_energy_rates"] = [0,0,0,0,0,0,0,0,0,0,0,0]
s = Scenario(d)
p = REoptInputs(s)
m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false, "log_to_console" => false))
m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false, "log_to_console" => false))
results = run_reopt([m1,m2], p)

annual_thermal_prod = 0.8 * 8760  #80% efficient boiler --> 0.8 MMBTU of heat load per hour
annual_electric_heater_consumption = annual_thermal_prod * REopt.KWH_PER_MMBTU  #1.0 COP
annual_energy_supplied = 87600 + annual_electric_heater_consumption

#Second run: ElectricHeater produces the required heat with free electricity 
results["ElectricHeater"]["annual_thermal_production_mmbtu"] 
results["ElectricHeater"]["annual_electric_consumption_kwh"] 
results["ElectricUtility"]["annual_energy_supplied_kwh"] 

# Save results json
#write("./results/electric_heater_results_1.json", JSON.json(results))

# Print some results
println("Second Run where Electric Heater is utilized")
println("ElectricHeater Size [MMBtu/hr]: ", results["ElectricHeater"]["size_mmbtu_per_hour"])
println("ElectricHeater Annual Electric Consumption [kWh]: ", results["ElectricHeater"]["annual_electric_consumption_kwh"])
println("ElectricUtility Annual Energy Supplied [kWh]: ", results["ElectricUtility"]["annual_energy_supplied_kwh"])
println("Lifecycle cost [\$]: ", results["Financial"]["lcc"] * 1000)
println("NPV [\$]: ", results["Financial"]["npv"]) # Now you can get a NPV 

# Save results json
#write("./results/electric_heater_results_3.json", JSON.json(results))

