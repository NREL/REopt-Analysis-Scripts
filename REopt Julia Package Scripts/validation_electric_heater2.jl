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

The case studies are mentioned below.

    Case Study 2: Emissions Reductions goal of 25%

"""

# Setup inputs for Case Study 2 - Emissions Reduction
data_file2 = "electric_heater_case2.json" 
input_data = JSON.parsefile("scenarios/$data_file2")

println("Correctly obtained data_file")

lat = [41.834, 37.7749, 25.7617, 47.6062, 29.7604]
long = [-88.044, -122.4194, -80.1918, -122.3321, -95.3698]
avg_elec_load = [2930.71, 2930.71, 2930.71, 2930.71, 2930.71]
avg_ng_load = [10, 10, 10, 10, 10]
elec_cost_industrial = [0.0849, 0.1855, 0.0923, 0.0626, 0.0638]
ng_cf3_to_mmbtu = 1.038
ng_cost_industrial = [7.41, 13.73, 5.92, 11.41, 2.72] ./ ng_cf3_to_mmbtu
#ng_cost_industrial = [200, 200, 200, 200, 200]
site_analysis = []

sites_iter = eachindex(lat)
for i in sites_iter
    input_data_site = copy(input_data)
    # Site Specific
    input_data_site["Site"]["latitude"] = lat[i]
    input_data_site["Site"]["longitude"] = long[i]
    input_data_site["ElectricLoad"]["annual_kwh"] = avg_elec_load[i] * 5280.0
    input_data_site["DomesticHotWaterLoad"]["annual_mmbtu"] = avg_ng_load[i] * 5280.0
    input_data_site["ElectricTariff"]["blended_annual_energy_rate"] = elec_cost_industrial[i]
    input_data_site["ExistingBoiler"]["fuel_cost_per_mmbtu"] = ng_cost_industrial[i]
    #input_data_site["ElectricHeater"]["annual_electric_consumption_kwh"] = avg_elec_load[i] * 5280.0

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
    for tech in ["Site"]
        if haskey(site_analysis[i][2], tech)
            println("Site $i $tech Emissions Reduction = ", site_analysis[i][2][tech]["lifecycle_emissions_reduction_CO2_fraction"])
        end
    end
    #for tech in ["ElectricHeater"]
        #if haskey(site_analysis[i][2], tech)
            #println("Site $i $tech size (MMBtu/hr) = ", site_analysis[i][2][tech]["size_mmbtu_per_hour"])
            #println("Site $i $tech Thermal Production (MMBtu) = ", site_analysis[i][2][tech]["annual_thermal_production_mmbtu"])
        #end
    #end
    for tech in ["ExistingBoiler"]
        if haskey(site_analysis[i][2], tech)
            println("Site $i $tech Annual Fuel Consumption (MMBtu) = ", site_analysis[i][2][tech]["annual_fuel_consumption_mmbtu"])
        end
    end
end

df = DataFrame(site = [i for i in sites_iter], 
               #ElectricHeater_size_MMBtu_per_hr = [round(site_analysis[i][2]["ElectricHeater"]["size_mmbtu_per_hour"], digits=0) for i in sites_iter],
               Emissions_Reduction = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_reduction_CO2_fraction"], digits=0) for i in sites_iter],
               ExistingBoiler_annual_consumption = [round(site_analysis[i][2]["ExistingBoiler"]["annual_fuel_consumption_mmbtu"], digits=0) for i in sites_iter],
               npv = [round(site_analysis[i][2]["Financial"]["npv"], sigdigits=3) for i in sites_iter],
               renewable_electricity_annual_kwh = [round(site_analysis[i][2]["Site"]["annual_renewable_electricity_kwh"], digits=3) for i in sites_iter],
               emissions_reduction_annual_ton = [round(site_analysis[i][2]["Site"]["lifecycle_emissions_reduction_CO2_fraction"] *
                                                    site_analysis[i][2]["Site"]["annual_emissions_tonnes_CO2_bau"], digits=0) for i in sites_iter]
               )

# Define path to xlsx file
file_storage_location = "C:\\Users\\dbernal\\OneDrive - NREL\\Non-shared files\\IEDO\\REopt Electric Heater\\ElectricHeater.jl Results\\results_emissions_reduction.xlsx"

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