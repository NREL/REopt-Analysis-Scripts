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
 julia> include("validation_electric_heater.jl")
###                                     ###

This code is to validate the elctric_heater.jl model.
This code undergoes X number of case studies outlines by the different JSON files containing
the different inputs for each case study.

The COP of the Electric Heater was changed to 0.99 to be consistent with the
NREL Electric Futures Study.

The case studies are mentioned below.

    Case Study 1: Different cities in different regional grids and emission factors.
                  Will be forcing the model to only consider the electric heater.

"""

using REopt
using Cbc # Cbc is a free solver. It may be slow with models that involve binary variables. Replace with your own solver (e.g., Xpress) if desired.
using HiGHS
using JSON
using JuMP
using CSV 
using DataFrames #to construct comparison
using XLSX 


# Setup inputs for Case Study 1
data_file = "electric_heater_case1b.json" 
input_data = JSON.parsefile("scenarios/$data_file")

println("Correctly obtained data_file")

#the lat/long will be representative of the regions (MW, NE, S, W)
#cities chosen are Chicago, Boston, Houston, San Francisco
lat = [41.834, 42.3601, 29.7604, 37.7749]
long = [-88.044, -71.0589, -95.3698, -122.4194]
#list of string containing the names of the regions
regions = ["Midwest", "Northeast", "South", "West"]
avg_elec_load = [10, 10, 10, 10]
#Creating a 5280 hour load 
fuel_loads_mmbtu_per_hour = fill(0.0, 8760)  # Initialize array with zeros
fuel_loads_mmbtu_per_hour[1:5280] .= 4.1844  # Assign 4.1844 to the first 5,280 hours
elec_cost_industrial = [0.0849, 0.1855, 0.0923, 0.0626, 0.0638] #this is in $/kWh
elec_cost_industrial_regional = [20.35, 24.47, 17.63, 24.09] #this is in $/MMBtu
ng_cf3_to_mmbtu = 1.038
ng_cost_industrial = [7.41, 13.73, 5.92, 11.41, 2.72] ./ ng_cf3_to_mmbtu
ng_cost_industrial_regional = [5.37, 7.87, 3.80, 6.20] #this is in $/MMBtu 
#cop for electric heater manual input
e_heater_cop = [0.5, 0.5, 0.5, 0.5]
site_analysis = []

sites_iter = eachindex(lat)
for i in sites_iter
    input_data_site = copy(input_data)
    # Site Specific
    input_data_site["Site"]["latitude"] = lat[i]
    input_data_site["Site"]["longitude"] = long[i]
    input_data_site["ElectricLoad"]["annual_kwh"] = avg_elec_load[i] * 5280.0
    input_data_site["DomesticHotWaterLoad"]["fuel_loads_mmbtu_per_hour"] = fuel_loads_mmbtu_per_hour
    #below we convert elec_cost_industrial_regional to $/kWh from $/MMBtu bc that's the input necessary
    #for the ElectricTariff.blended ...
    input_data_site["ElectricTariff"]["blended_annual_energy_rate"] = elec_cost_industrial_regional[i] .* 0.003412
    input_data_site["ExistingBoiler"]["fuel_cost_per_mmbtu"] = ng_cost_industrial_regional[i]
    #test for e heater, COP
    input_data_site["ElectricHeater"]["cop"] = e_heater_cop[i]
    
    s = Scenario(input_data_site)
    inputs = REoptInputs(s)

     # HiGHS solver
     m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "output_flag" => false, 
     "log_to_console" => false)
     )

    m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "output_flag" => false, 
     "log_to_console" => false)
     )            

    results = run_reopt([m1,m2], inputs)
    append!(site_analysis, [(input_data_site, results)])
end
println("Completed optimization")

# Print tech sizes
for i in sites_iter
    for tech in ["ElectricHeater"]
        if haskey(site_analysis[i][2], tech)
            println("Site $i $tech size (MMBtu/hr) = ", site_analysis[i][2][tech]["size_mmbtu_per_hour"])
            println("Site $i $tech Thermal Production (MMBtu) = ", site_analysis[i][2][tech]["annual_thermal_production_mmbtu"])
        end
    end
    for tech in ["ExistingBoiler"]
        if haskey(site_analysis[i][2], tech)
            println("Site $i $tech Annual Fuel Consumption (MMBtu) = ", site_analysis[i][2][tech]["annual_fuel_consumption_mmbtu"])
            println("Site $i $tech Thermal Production (MMBtu) = ", site_analysis[i][2][tech]["annual_thermal_production_mmbtu"])
        end
    end
end


# Populate the DataFrame with the results produced and inputs
df = DataFrame(
    Region = regions,
    ElectricHeater_size_MMBtu_per_hr = [round(site_analysis[i][2]["ElectricHeater"]["size_mmbtu_per_hour"], digits=2) for i in 1:length(regions)],
    Purchase_Price = [round(site_analysis[i][2]["ElectricHeater"]["size_mmbtu_per_hour"] * input_data["ElectricHeater"]["installed_cost_per_mmbtu_per_hour"], digits=2) for i in 1:length(regions)],
    Electricity_Price_per_MMBtu = elec_cost_industrial_regional,
    Hourly_Cost = [round(site_analysis[i][2]["ElectricHeater"]["size_mmbtu_per_hour"] * elec_cost_industrial_regional[i], digits=2) for i in 1:length(regions)],
    First_Year_Cost = [round(df.Purchase_Price[i] + (df.Hourly_Cost[i] * 5280), digits=2) for i in 1:length(regions)]
)
println(df)

# Define path to xlsx file
file_storage_location = "C:\\Users\\dbernal\\OneDrive - NREL\\Non-shared files\\IEDO\\REopt Electric Heater\\ElectricHeater.jl Results\\results_retire_existingboiler.xlsx"

# Check if the Excel file already exists
if isfile(file_storage_location)
    # Open the Excel file in read-write mode
    XLSX.openxlsx(file_storage_location, mode="rw") do xf
        counter = 0
        while true
            sheet_name = "results_" * string(counter)
            try
                sheet = xf[sheet_name]
                counter += 1
            catch
                break
            end
        end
        sheet_name = "results_" * string(counter)
        # Add new sheet
        XLSX.addsheet!(xf, sheet_name)
        # Write DataFrame to the new sheet
        XLSX.writetable!(xf[sheet_name], df)
    end
else
    # Write DataFrame to a new Excel file
    XLSX.writetable!(file_storage_location, df)
end

println("Successful write into XLSX file: $file_storage_location")
