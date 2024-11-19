using REopt
using HiGHS
using JSON
using JuMP
using CSV 
using DataFrames #to construct comparison
using XLSX 

# Setup inputs for Case Study 2 Part A
data_file = " " 
input_data = JSON.parsefile("scenarios/$data_file")

cermak_rates = "C:/Users/dbernal/Downloads/Cook County Internal Cermak New.json"
cermak_rates_1 = JSON.parsefile(cermak_rates)

println("Correctly obtained data_file")

#the lat/long will be representative of the regions (MW, NE, S, W)
#cities chosen are Chicago, Boston, Houston, San Francisco
cities = ["Chicago", "Chicago", "Chicago", "Chicago", "Chicago", "Chicago", "Chicago", "Chicago", "Chicago", "Chicago"]
lat = [41.834, 41.834, 41.834, 41.834, 41.834, 41.834, 41.834, 41.834, 41.834, 41.834]
long = [-88.044, -88.044, -88.044, -88.044, -88.044, -88.044, -88.044, -88.044, -88.044, -88.044]

site_analysis = []

sites_iter = eachindex(lat)
for i in sites_iter
    input_data_site = copy(input_data)
    # Site Specific
    input_data_site["Site"]["latitude"] = lat[i]
    input_data_site["Site"]["longitude"] = long[i]
    input_data_site["ElectricLoad"]["path_to_csv"] = 
    input_data_site["ElectricTariff"]["urdb_response"] = cermak_rates_1
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

    sleep(180)
end
println("Completed optimization")

#write onto JSON file
write.("./results/cook_county_cermak.json", JSON.json(site_analysis))
println("Successfully printed results on JSON file")

# Populate the DataFrame with the results produced and inputs
df = DataFrame(
    City = cities,
    PV_size = [round(site_analysis[i][2]["PV"]["size_kw"], digits=0) for i in sites_iter],
    PV_year1_production = [round(site_analysis[i][2]["PV"]["year_one_energy_produced_kwh"], digits=0) for i in sites_iter],
    PV_annual_energy_production_avg = [round(site_analysis[i][2]["PV"]["annual_energy_produced_kwh"], digits=0) for i in sites_iter],
    PV_energy_lcoe = [round(site_analysis[i][2]["PV"]["lcoe_per_kwh"], digits=0) for i in sites_iter],
    PV_energy_exported = [round(site_analysis[i][2]["PV"]["annual_energy_exported_kwh"], digits=0) for i in sites_iter],
    PV_energy_curtailed = [sum(site_analysis[i][2]["PV"]["electric_curtailed_series_kw"]) for i in sites_iter],
    PV_energy_to_Battery_year1 = [sum(site_analysis[i][2]["PV"]["electric_to_storage_series_kw"]) for i in sites_iter],
    Battery_size_kWh = [round(site_analysis[i][2]["ElectricStorage"]["size_kwh"], digits=0) for i in sites_iter], 
    Grid_Electricity_Supplied_kWh_annual = [round(site_analysis[i][2]["ElectricUtility"]["annual_energy_supplied_kwh"], digits=0) for i in sites_iter],
    Annual_Total_HeatingLoad_MMBtu = [round(site_analysis[i][2]["HeatingLoad"]["annual_calculated_total_heating_thermal_load_mmbtu"], digits=0) for i in sites_iter],
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
