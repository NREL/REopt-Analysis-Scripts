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

The COP of the Electric Heater was changed to 0.99.

The case studies are mentioned below.

    Case Study 2: Part A: Focus on Emissions Reduction of validation_electric_heater.jl Task
                  Part B: Add PV and ElectricStorage to the model. Evaluate again with 
                          emission reduction target.
                  Part C: Focus on a single site and increase reduction target over 4 scenarios.
                          25%, 50%, 75%, 100%.

"""

using REopt
using HiGHS
using JSON
using JuMP
using CSV 
using DataFrames #to construct comparison
using XLSX 

"""
=============================
        This is Part A.
=============================
"""

# Setup inputs for Case Study 2 Part A
data_file = "electric_heater_case2.json" 
input_data = JSON.parsefile("scenarios/$data_file")

println("Correctly obtained data_file")

#the lat/long will be representative of the regions (MW, NE, S, W)
#cities chosen are Chicago, Boston, Houston, San Francisco
cities = ["Chicago", "Boston", "Houston", "San Francisco"]
lat = [41.834, 42.3601, 29.7604, 37.7749]
long = [-88.044, -71.0589, -95.3698, -122.4194]
#list of string containing the names of the regions
regions = ["Midwest", "Northeast", "South", "West"]
avg_elec_load = [1, 1, 1, 1]
avg_ng_load = [7.0, 7.0, 7.0, 7.0]
#electricity costs per region for industry
elec_cost_industrial_regional = [20.35, 24.47, 17.63, 24.09] #this is in $/MMBtu
#natural gas costs per region for industry
ng_cost_industrial_regional = [5.37, 7.87, 3.80, 6.20] #this is in $/MMBtu 
#cop for electric heater manual input
e_heater_cop = [0.99, 0.99, 0.99, 0.99]
site_analysis = []

sites_iter = eachindex(lat)
for i in sites_iter
    input_data_site = copy(input_data)
    # Site Specific
    input_data_site["Site"]["latitude"] = lat[i]
    input_data_site["Site"]["longitude"] = long[i]
    input_data_site["ElectricLoad"]["annual_kwh"] = avg_elec_load[i] * 1.0
    input_data_site["DomesticHotWaterLoad"]["annual_mmbtu"] = avg_ng_load[i] * 8760
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
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )

    m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )            

    results = run_reopt([m1,m2], inputs)
    append!(site_analysis, [(input_data_site, results)])
end
println("Completed optimization")

#write onto JSON file
write.("./results/electric_heater_results_part2.json", JSON.json(site_analysis))
println("Successfully printed results on JSON file")

# Populate the DataFrame with the results produced and inputs
df = DataFrame(
    City = cities,
    Electric_Heater_kWh_consumption_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_electric_consumption_kwh"], digits=0) for i in sites_iter],
    Grid_Electricity_Supplied_kWh_annual = [round(site_analysis[i][2]["ElectricUtility"]["annual_energy_supplied_kwh"], digits=0) for i in sites_iter],
    Electric_Heater_Thermal_Production_MMBtu_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_thermal_production_mmbtu"], digits=0) for i in sites_iter],
    Annual_Total_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_thermal_load_mmbtu"], digits=0) for i in sites_iter],
    Annual_Boiler_Fuel_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_boiler_fuel_load_mmbtu"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Fuel_Consump_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu_bau"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Thermal_Prod_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_thermal_production_mmbtu_bau"], digits=0) for i in sites_iter],
    NG_Annual_Consumption_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu"], digits=0) for i in sites_iter],
    Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    ElecUtility_Annual_Emissions_CO2 = [round(site_analysis[i][2]["ElectricUtility"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    BAU_Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2_bau"], digits=4) for i in sites_iter],
    LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2"], digits=2) for i in sites_iter],
    BAU_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2_bau"], digits=2) for i in sites_iter],
    NG_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_from_fuelburn_tonnes_CO2"], digits=2) for i in sites_iter],
    Emissions_from_NG = [round(site_analysis[i][2]["Site"]["annual_emissions_from_fuelburn_tonnes_CO2"], digits=0) for i in sites_iter],
    LifeCycle_Emission_Reduction_Fraction = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_reduction_CO2_fraction"], digits=2) for i in sites_iter],
    npv = [round(site_analysis[i][2]["Financial"]["npv"], digits=2) for i in sites_iter]
    )
println(df)

# Define path to xlsx file
file_storage_location = "results/results_emissions_reductions.xlsx"
#file_storage_location = "C:\\Users\\dbernal\\OneDrive - NREL\\Non-shared files\\IEDO\\REopt Electric Heater\\ElectricHeater.jl Results\\results_emission_reductions.xlsx"

# Check if the Excel file already exists
if isfile(file_storage_location)
    # Open the Excel file in read-write mode
    XLSX.openxlsx(file_storage_location, mode="rw") do xf
        counter = 0
        while true
            sheet_name = "resultsA_" * string(counter)
            try
                sheet = xf[sheet_name]
                counter += 1
            catch
                break
            end
        end
        sheet_name = "resultsA_" * string(counter)
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

"""
=============================
        This is Part B.
=============================
"""

# Setup inputs for Case Study 2 Part B
data_file = "electric_heater_case3.json" 
input_data = JSON.parsefile("scenarios/$data_file")

println("Correctly obtained data_file")

#the lat/long will be representative of the regions (MW, NE, S, W)
#cities chosen are Chicago, Boston, Houston, San Francisco
cities = ["Chicago", "Boston", "Houston", "San Francisco"]
lat = [41.834, 42.3601, 29.7604, 37.7749]
long = [-88.044, -71.0589, -95.3698, -122.4194]
#list of string containing the names of the regions
regions = ["Midwest", "Northeast", "South", "West"]
avg_elec_load = [1, 1, 1, 1]
avg_ng_load = [7.0, 7.0, 7.0, 7.0]
#electricity costs per region for industry
elec_cost_industrial_regional = [20.35, 24.47, 17.63, 24.09] #this is in $/MMBtu
#natural gas costs per region for industry
ng_cost_industrial_regional = [5.37, 7.87, 3.80, 6.20] #this is in $/MMBtu 
#wholesale_rate
wholesale_rate = [20.35, 24.47, 17.63, 24.09] #this is in $/MMBtu
#cop for electric heater manual input
e_heater_cop = [0.99, 0.99, 0.99, 0.99]
site_analysis = []

# emissions reduction goal of 25%
emission_reduction_goal = [0.25, 0.25, 0.25, 0.25]
max_emissions = [1.0, 1.0, 1.0, 1.0]

sites_iter = eachindex(lat)
for i in sites_iter
    input_data_site = copy(input_data)
    # Site Specific
    input_data_site["Site"]["latitude"] = lat[i]
    input_data_site["Site"]["longitude"] = long[i]
    input_data_site["ElectricLoad"]["annual_kwh"] = avg_elec_load[i] * 1.0
    input_data_site["DomesticHotWaterLoad"]["annual_mmbtu"] = avg_ng_load[i] * 8760
    #below we convert elec_cost_industrial_regional to $/kWh from $/MMBtu bc that's the input necessary
    #for the ElectricTariff.blended ...
    input_data_site["ElectricTariff"]["blended_annual_energy_rate"] = elec_cost_industrial_regional[i] .* 0.003412
    input_data_site["ExistingBoiler"]["fuel_cost_per_mmbtu"] = ng_cost_industrial_regional[i]
    #wholesale rate to equal to the cost above
    input_data_site["ElectricTariff"]["wholesale_rate"] = wholesale_rate[i] .* 0.003412
    #test for e heater, COP
    input_data_site["ElectricHeater"]["cop"] = e_heater_cop[i]
    #data for emissions reductions 
    input_data_site["Site"]["CO2_emissions_reduction_min_fraction"] = emission_reduction_goal[i]
    input_data_site["Site"]["CO2_emissions_reduction_max_fraction"] = max_emissions[i]
        
    s = Scenario(input_data_site)
    inputs = REoptInputs(s)

     # HiGHS solver
     m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )

    m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )            

    results = run_reopt([m1,m2], inputs)
    append!(site_analysis, [(input_data_site, results)])
end
println("Completed optimization")

#write onto JSON file
write.("./results/electric_heater_results_part3.json", JSON.json(site_analysis))

# Populate the DataFrame with the results produced and inputs
df = DataFrame(
    City = cities,
    PV_size_kW = [round(site_analysis[i][2]["PV"]["size_kw"], digits=0) for i in sites_iter],
    PV_Production_kWh = [round(site_analysis[i][2]["PV"]["annual_energy_produced_kwh"], digits=0) for i in sites_iter],
    Battery_size_kWh = [round(site_analysis[i][2]["ElectricStorage"]["size_kwh"], digits=0) for i in sites_iter], 
    Electric_Heater_kWh_consumption_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_electric_consumption_kwh"], digits=0) for i in sites_iter],
    Grid_Electricity_Supplied_kWh_annual = [round(site_analysis[i][2]["ElectricUtility"]["annual_energy_supplied_kwh"], digits=0) for i in sites_iter],
    PV_energy_curtailed = [sum(site_analysis[i][2]["PV"]["electric_curtailed_series_kw"]) for i in sites_iter],
    PV_energy_export_to_grid = [round(site_analysis[i][2]["PV"]["annual_energy_exported_kwh"], digits=0) for i in sites_iter],
    Electric_Heater_Thermal_Production_MMBtu_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_thermal_production_mmbtu"], digits=0) for i in sites_iter],
    Annual_Total_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_thermal_load_mmbtu"], digits=0) for i in sites_iter],
    Annual_Boiler_Fuel_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_boiler_fuel_load_mmbtu"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Fuel_Consump_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu_bau"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Thermal_Prod_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_thermal_production_mmbtu_bau"], digits=0) for i in sites_iter],
    NG_Annual_Consumption_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu"], digits=0) for i in sites_iter],
    Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    ElecUtility_Annual_Emissions_CO2 = [round(site_analysis[i][2]["ElectricUtility"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    BAU_Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2_bau"], digits=4) for i in sites_iter],
    LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2"], digits=2) for i in sites_iter],
    BAU_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2_bau"], digits=2) for i in sites_iter],
    NG_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_from_fuelburn_tonnes_CO2"], digits=2) for i in sites_iter],
    Emissions_from_NG = [round(site_analysis[i][2]["Site"]["annual_emissions_from_fuelburn_tonnes_CO2"], digits=0) for i in sites_iter],
    LifeCycle_Emission_Reduction_Fraction = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_reduction_CO2_fraction"], digits=2) for i in sites_iter],
    npv = [round(site_analysis[i][2]["Financial"]["npv"], digits=2) for i in sites_iter]
    )
println(df)

# Define path to xlsx file
file_storage_location = "results/results_emissions_reductions.xlsx"

# Check if the Excel file already exists
if isfile(file_storage_location)
    # Open the Excel file in read-write mode
    XLSX.openxlsx(file_storage_location, mode="rw") do xf
        counter = 0
        while true
            sheet_name = "resultsB_" * string(counter)
            try
                sheet = xf[sheet_name]
                counter += 1
            catch
                break
            end
        end
        sheet_name = "resultsB_" * string(counter)
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

"""
=============================
        This is Part C.
=============================
"""

# Setup inputs for Case Study 2 Part C
data_file = "electric_heater_case4.json" 
input_data = JSON.parsefile("scenarios/$data_file")

println("Correctly obtained data_file")

#Decided on Chicago to be the single location of analyses
cities = ["Chicago", "Chicago", "Chicago", "Chicago", "Chicago"]
lat = [41.834, 41.834, 41.834, 41.834, 41.834]
long = [-88.044, -88.044, -88.044, -88.044, -88.044]
avg_elec_load = [1, 1, 1, 1, 1]
avg_ng_load = [7.0, 7.0, 7.0, 7.0, 7.0]
#electricity costs per region for industry
elec_cost_industrial_regional = [20.35, 20.35, 20.35, 20.35, 20.35] #this is in $/MMBtu
#natural gas costs per region for industry
ng_cost_industrial_regional = [5.37, 5.37, 5.37, 5.37, 5.37] #this is in $/MMBtu
#wholesale_rate
wholesale_rate = [20.349, 20.349, 20.349, 20.349, 20.349] #this is in $/MMBtu
#cop for electric heater manual input
e_heater_cop = [0.99, 0.99, 0.99, 0.99, 0.99]
site_analysis = []

# emissions reduction goal of 5%
emission_reduction_goal = [0.00, 0.25, 0.5, 0.75, 1.00]
max_emissions = [1.0, 1.0, 1.0, 1.0, 1.0]

sites_iter = eachindex(lat)
for i in sites_iter
    input_data_site = copy(input_data)
    # Site Specific
    input_data_site["Site"]["latitude"] = lat[i]
    input_data_site["Site"]["longitude"] = long[i]
    input_data_site["ElectricLoad"]["annual_kwh"] = avg_elec_load[i] * 1.0
    input_data_site["DomesticHotWaterLoad"]["annual_mmbtu"] = avg_ng_load[i] * 8760
    #below we convert elec_cost_industrial_regional to $/kWh from $/MMBtu bc that's the input necessary
    #for the ElectricTariff.blended ...
    input_data_site["ElectricTariff"]["blended_annual_energy_rate"] = elec_cost_industrial_regional[i] .* 0.003412
    input_data_site["ExistingBoiler"]["fuel_cost_per_mmbtu"] = ng_cost_industrial_regional[i]
    #wholesale rate to equal to the cost above
    input_data_site["ElectricTariff"]["wholesale_rate"] = wholesale_rate[i] .* 0.003412
    #test for e heater, COP
    input_data_site["ElectricHeater"]["cop"] = e_heater_cop[i]
    #data for emissions reductions 
    input_data_site["Site"]["CO2_emissions_reduction_min_fraction"] = emission_reduction_goal[i]
    input_data_site["Site"]["CO2_emissions_reduction_max_fraction"] = max_emissions[i]
        
    s = Scenario(input_data_site)
    inputs = REoptInputs(s)

     # HiGHS solver
     m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )

    m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )            

    results = run_reopt([m1,m2], inputs)
    append!(site_analysis, [(input_data_site, results)])
end
println("Completed optimization")

#write onto JSON file
write.("./results/electric_heater_results_part4.json", JSON.json(site_analysis))

# Populate the DataFrame with the results produced and inputs
df = DataFrame(
    City = cities,
    PV_size_kW = [round(site_analysis[i][2]["PV"]["size_kw"], digits=0) for i in sites_iter],
    PV_Production_kWh = [round(site_analysis[i][2]["PV"]["annual_energy_produced_kwh"], digits=0) for i in sites_iter],
    Battery_size_kWh = [round(site_analysis[i][2]["ElectricStorage"]["size_kwh"], digits=0) for i in sites_iter], 
    Electric_Heater_kWh_consumption_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_electric_consumption_kwh"], digits=0) for i in sites_iter],
    Grid_Electricity_Supplied_kWh_annual = [round(site_analysis[i][2]["ElectricUtility"]["annual_energy_supplied_kwh"], digits=0) for i in sites_iter],
    PV_energy_curtailed = [sum(site_analysis[i][2]["PV"]["electric_curtailed_series_kw"]) for i in sites_iter],
    PV_energy_export_to_grid = [round(site_analysis[i][2]["PV"]["annual_energy_exported_kwh"], digits=0) for i in sites_iter],
    Electric_Heater_Thermal_Production_MMBtu_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_thermal_production_mmbtu"], digits=0) for i in sites_iter],
    Annual_Total_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_thermal_load_mmbtu"], digits=0) for i in sites_iter],
    Annual_Boiler_Fuel_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_boiler_fuel_load_mmbtu"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Fuel_Consump_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu_bau"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Thermal_Prod_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_thermal_production_mmbtu_bau"], digits=0) for i in sites_iter],
    NG_Annual_Consumption_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu"], digits=0) for i in sites_iter],
    Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    ElecUtility_Annual_Emissions_CO2 = [round(site_analysis[i][2]["ElectricUtility"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    BAU_Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2_bau"], digits=4) for i in sites_iter],
    LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2"], digits=2) for i in sites_iter],
    BAU_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2_bau"], digits=2) for i in sites_iter],
    NG_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_from_fuelburn_tonnes_CO2"], digits=2) for i in sites_iter],
    Emissions_from_NG = [round(site_analysis[i][2]["Site"]["annual_emissions_from_fuelburn_tonnes_CO2"], digits=0) for i in sites_iter],
    LifeCycle_Emission_Reduction_Fraction = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_reduction_CO2_fraction"], digits=2) for i in sites_iter],
    npv = [round(site_analysis[i][2]["Financial"]["npv"], digits=2) for i in sites_iter]
    )
println(df)
 
# Define path to xlsx file
file_storage_location = "results/results_emissions_reductions.xlsx"

# Check if the Excel file already exists
if isfile(file_storage_location)
    # Open the Excel file in read-write mode
    XLSX.openxlsx(file_storage_location, mode="rw") do xf
        counter = 0
        while true
            sheet_name = "resultsC_" * string(counter)
            try
                sheet = xf[sheet_name]
                counter += 1
            catch
                break
            end
        end
        sheet_name = "resultsC_" * string(counter)
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

"""
==========================================
        This is Part D.
        Same as Part B without
        forceing to retire the
        existing boiler.
==========================================
"""

# Setup inputs for Case Study 2 Part B
data_file = "electric_heater_case5.json" 
input_data = JSON.parsefile("scenarios/$data_file")

println("Correctly obtained data_file")

#the lat/long will be representative of the regions (MW, NE, S, W)
#cities chosen are Chicago, Boston, Houston, San Francisco
cities = ["Chicago", "Boston", "Houston", "San Francisco"]
lat = [41.834, 42.3601, 29.7604, 37.7749]
long = [-88.044, -71.0589, -95.3698, -122.4194]
#list of string containing the names of the regions
regions = ["Midwest", "Northeast", "South", "West"]
avg_elec_load = [1, 1, 1, 1]
avg_ng_load = [7.0, 7.0, 7.0, 7.0]
#electricity costs per region for industry
elec_cost_industrial_regional = [20.35, 24.47, 17.63, 24.09] #this is in $/MMBtu
#natural gas costs per region for industry
ng_cost_industrial_regional = [5.37, 7.87, 3.80, 6.20] #this is in $/MMBtu 
#wholesale_rate
wholesale_rate = [20.35, 24.47, 17.63, 24.09] #this is in $/MMBtu
#cop for electric heater manual input
e_heater_cop = [0.99, 0.99, 0.99, 0.99]
site_analysis = []

# emissions reduction goal of 25%
emission_reduction_goal = [0.25, 0.25, 0.25, 0.25]
max_emissions = [1.0, 1.0, 1.0, 1.0]

sites_iter = eachindex(lat)
for i in sites_iter
    input_data_site = copy(input_data)
    # Site Specific
    input_data_site["Site"]["latitude"] = lat[i]
    input_data_site["Site"]["longitude"] = long[i]
    input_data_site["ElectricLoad"]["annual_kwh"] = avg_elec_load[i] * 1.0
    input_data_site["DomesticHotWaterLoad"]["annual_mmbtu"] = avg_ng_load[i] * 8760
    #below we convert elec_cost_industrial_regional to $/kWh from $/MMBtu bc that's the input necessary
    #for the ElectricTariff.blended ...
    input_data_site["ElectricTariff"]["blended_annual_energy_rate"] = elec_cost_industrial_regional[i] .* 0.003412
    input_data_site["ExistingBoiler"]["fuel_cost_per_mmbtu"] = ng_cost_industrial_regional[i]
    #wholesale rate to equal to the cost above
    input_data_site["ElectricTariff"]["wholesale_rate"] = wholesale_rate[i] .* 0.003412
    #test for e heater, COP
    input_data_site["ElectricHeater"]["cop"] = e_heater_cop[i]
    #data for emissions reductions 
    input_data_site["Site"]["CO2_emissions_reduction_min_fraction"] = emission_reduction_goal[i]
    input_data_site["Site"]["CO2_emissions_reduction_max_fraction"] = max_emissions[i]
        
    s = Scenario(input_data_site)
    inputs = REoptInputs(s)

     # HiGHS solver
     m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )

    m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )            

    results = run_reopt([m1,m2], inputs)
    append!(site_analysis, [(input_data_site, results)])
end
println("Completed optimization")

#write onto JSON file
write.("./results/electric_heater_results_part5.json", JSON.json(site_analysis))

# Populate the DataFrame with the results produced and inputs
df = DataFrame(
    City = cities,
    PV_size_kW = [round(site_analysis[i][2]["PV"]["size_kw"], digits=0) for i in sites_iter],
    PV_Production_kWh = [round(site_analysis[i][2]["PV"]["annual_energy_produced_kwh"], digits=0) for i in sites_iter],
    Battery_size_kWh = [round(site_analysis[i][2]["ElectricStorage"]["size_kwh"], digits=0) for i in sites_iter], 
    Electric_Heater_kWh_consumption_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_electric_consumption_kwh"], digits=0) for i in sites_iter],
    Grid_Electricity_Supplied_kWh_annual = [round(site_analysis[i][2]["ElectricUtility"]["annual_energy_supplied_kwh"], digits=0) for i in sites_iter],
    PV_energy_curtailed = [sum(site_analysis[i][2]["PV"]["electric_curtailed_series_kw"]) for i in sites_iter],
    PV_energy_export_to_grid = [round(site_analysis[i][2]["PV"]["annual_energy_exported_kwh"], digits=0) for i in sites_iter],
    Electric_Heater_Thermal_Production_MMBtu_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_thermal_production_mmbtu"], digits=0) for i in sites_iter],
    Annual_Total_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_thermal_load_mmbtu"], digits=0) for i in sites_iter],
    Annual_Boiler_Fuel_HeatingLoad_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Fuel_Consump_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu_bau"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Thermal_Prod_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_thermal_production_mmbtu_bau"], digits=0) for i in sites_iter],
    NG_Annual_Consumption_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu"], digits=0) for i in sites_iter],
    Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    ElecUtility_Annual_Emissions_CO2 = [round(site_analysis[i][2]["ElectricUtility"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    BAU_Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2_bau"], digits=4) for i in sites_iter],
    LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2"], digits=2) for i in sites_iter],
    BAU_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2_bau"], digits=2) for i in sites_iter],
    NG_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_from_fuelburn_tonnes_CO2"], digits=2) for i in sites_iter],
    Emissions_from_NG = [round(site_analysis[i][2]["Site"]["annual_emissions_from_fuelburn_tonnes_CO2"], digits=0) for i in sites_iter],
    LifeCycle_Emission_Reduction_Fraction = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_reduction_CO2_fraction"], digits=2) for i in sites_iter],
    npv = [round(site_analysis[i][2]["Financial"]["npv"], digits=2) for i in sites_iter]
    )
println(df)

# Define path to xlsx file
file_storage_location = "results/results_emissions_reductions.xlsx"

# Check if the Excel file already exists
if isfile(file_storage_location)
    # Open the Excel file in read-write mode
    XLSX.openxlsx(file_storage_location, mode="rw") do xf
        counter = 0
        while true
            sheet_name = "resultsD_" * string(counter)
            try
                sheet = xf[sheet_name]
                counter += 1
            catch
                break
            end
        end
        sheet_name = "resultsD_" * string(counter)
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

"""
=============================
        This is Part E.
        Same as Part C except 
        allow use of ExistingBoiler
        in optimal.
=============================
"""

# Setup inputs for Case Study 2 Part C
data_file = "electric_heater_case6.json" 
input_data = JSON.parsefile("scenarios/$data_file")

println("Correctly obtained data_file")

#Decided on Chicago to be the single location of analyses
cities = ["Chicago", "Chicago", "Chicago", "Chicago", "Chicago"]
lat = [41.834, 41.834, 41.834, 41.834, 41.834]
long = [-88.044, -88.044, -88.044, -88.044, -88.044]
avg_elec_load = [1, 1, 1, 1, 1]
avg_ng_load = [7.0, 7.0, 7.0, 7.0, 7.0]
#electricity costs per region for industry
elec_cost_industrial_regional = [20.35, 20.35, 20.35, 20.35, 20.35] #this is in $/MMBtu
#natural gas costs per region for industry
ng_cost_industrial_regional = [5.37, 5.37, 5.37, 5.37, 5.37] #this is in $/MMBtu
#wholesale_rate
wholesale_rate = [20.35, 20.35, 20.35, 20.35, 20.35] #this is in $/MMBtu
#cop for electric heater manual input
e_heater_cop = [0.99, 0.99, 0.99, 0.99, 0.99]
site_analysis = []

# emissions reduction goal of 5%
emission_reduction_goal = [0.00, 0.25, 0.5, 0.75, 1.00]
max_emissions = [1.0, 1.0, 1.0, 1.0, 1.0]

sites_iter = eachindex(lat)
for i in sites_iter
    input_data_site = copy(input_data)
    # Site Specific
    input_data_site["Site"]["latitude"] = lat[i]
    input_data_site["Site"]["longitude"] = long[i]
    input_data_site["ElectricLoad"]["annual_kwh"] = avg_elec_load[i] * 1.0
    input_data_site["DomesticHotWaterLoad"]["annual_mmbtu"] = avg_ng_load[i] * 8760
    #below we convert elec_cost_industrial_regional to $/kWh from $/MMBtu bc that's the input necessary
    #for the ElectricTariff.blended ...
    input_data_site["ElectricTariff"]["blended_annual_energy_rate"] = elec_cost_industrial_regional[i] .* 0.003412
    input_data_site["ExistingBoiler"]["fuel_cost_per_mmbtu"] = ng_cost_industrial_regional[i]
    #wholesale rate to equal to the cost above
    input_data_site["ElectricTariff"]["wholesale_rate"] = wholesale_rate[i] .* 0.003412
    #test for e heater, COP
    input_data_site["ElectricHeater"]["cop"] = e_heater_cop[i]
    #data for emissions reductions 
    input_data_site["Site"]["CO2_emissions_reduction_min_fraction"] = emission_reduction_goal[i]
    input_data_site["Site"]["CO2_emissions_reduction_max_fraction"] = max_emissions[i]
        
    s = Scenario(input_data_site)
    inputs = REoptInputs(s)

     # HiGHS solver
     m1 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )

    m2 = Model(optimizer_with_attributes(HiGHS.Optimizer, 
     "time_limit" => 450.0,
     "mip_rel_gap" => 0.01,
     "output_flag" => false, 
     "log_to_console" => false)
     )            

    results = run_reopt([m1,m2], inputs)
    append!(site_analysis, [(input_data_site, results)])
end
println("Completed optimization")

#write onto JSON file
write.("./results/electric_heater_results_part6.json", JSON.json(site_analysis))

# Populate the DataFrame with the results produced and inputs
df = DataFrame(
    City = cities,
    PV_size_kW = [round(site_analysis[i][2]["PV"]["size_kw"], digits=0) for i in sites_iter],
    PV_Production_kWh = [round(site_analysis[i][2]["PV"]["annual_energy_produced_kwh"], digits=0) for i in sites_iter],
    Battery_size_kWh = [round(site_analysis[i][2]["ElectricStorage"]["size_kwh"], digits=0) for i in sites_iter], 
    Electric_Heater_kWh_consumption_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_electric_consumption_kwh"], digits=0) for i in sites_iter],
    Grid_Electricity_Supplied_kWh_annual = [round(site_analysis[i][2]["ElectricUtility"]["annual_energy_supplied_kwh"], digits=0) for i in sites_iter],
    PV_energy_curtailed = [sum(site_analysis[i][2]["PV"]["electric_curtailed_series_kw"]) for i in sites_iter],
    PV_energy_export_to_grid = [round(site_analysis[i][2]["PV"]["annual_energy_exported_kwh"], digits=0) for i in sites_iter],
    Electric_Heater_Thermal_Production_MMBtu_annual = [round(site_analysis[i][2]["ElectricHeater"]["annual_thermal_production_mmbtu"], digits=0) for i in sites_iter],
    Annual_Total_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_thermal_load_mmbtu"], digits=0) for i in sites_iter],
    Annual_Boiler_Fuel_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_boiler_fuel_load_mmbtu"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Fuel_Consump_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu_bau"], digits=0) for i in sites_iter],
    BAU_Existing_Boiler_Thermal_Prod_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_thermal_production_mmbtu_bau"], digits=0) for i in sites_iter],
    NG_Annual_Consumption_MMBtu = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu"], digits=0) for i in sites_iter],
    Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    ElecUtility_Annual_Emissions_CO2 = [round(site_analysis[i][2]["ElectricUtility"]["annual_emissions_tonnes_CO2"], digits=4) for i in sites_iter],
    BAU_Total_Annual_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2_bau"], digits=4) for i in sites_iter],
    LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2"], digits=2) for i in sites_iter],
    BAU_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_tonnes_CO2_bau"], digits=2) for i in sites_iter],
    NG_LifeCycle_Emissions_CO2 = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_from_fuelburn_tonnes_CO2"], digits=2) for i in sites_iter],
    Emissions_from_NG = [round(site_analysis[i][2]["Site"]["annual_emissions_from_fuelburn_tonnes_CO2"], digits=0) for i in sites_iter],
    LifeCycle_Emission_Reduction_Fraction = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_reduction_CO2_fraction"], digits=2) for i in sites_iter],
    npv = [round(site_analysis[i][2]["Financial"]["npv"], digits=2) for i in sites_iter]
    )
println(df)
 
# Define path to xlsx file
file_storage_location = "results/results_emissions_reductions.xlsx"

# Check if the Excel file already exists
if isfile(file_storage_location)
    # Open the Excel file in read-write mode
    XLSX.openxlsx(file_storage_location, mode="rw") do xf
        counter = 0
        while true
            sheet_name = "resultsE_" * string(counter)
            try
                sheet = xf[sheet_name]
                counter += 1
            catch
                break
            end
        end
        sheet_name = "resultsE_" * string(counter)
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