"""
This validation document will use a single value for the emissions factors.
This will dump the results into an excel file to backend the calculations
to ensure consistency with REopt outputs.

==========================================================================
We are undergoing a simulation on a single site with a single scenario.
The city is Chicago and the ERT is 50%. We are not retiring NG boiler in optimal. 

Additionally we added "emissions_factor_CO2_decrease_fraction": 0
"""

# Setup inputs for Case Study 2 Part B
data_file = "electric_heater_caseEmissions.json" 
input_data = JSON.parsefile("scenarios/$data_file")

println("Correctly obtained data_file")

#a single city, Chicago
cities = ["Chicago"]
lat = [41.834 ]
long = [-88.044]
avg_elec_load = [1]
avg_ng_load = [7.0]
#electricity cost for industry
elec_cost_industrial_regional = [20.35] #this is in $/MMBtu
#natural gas cost for industry
ng_cost_industrial_regional = [5.37] #this is in $/MMBtu 
#cop for electric heater manual input
e_heater_cop = [0.99]
#emissions factors
emissions_factors = fill(1.0, 8760)
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
    #emissions factors for 8760
    input_data_site["ElectricUtility"]["emissions_factor_series_lb_CO2_per_kwh"] = emissions_factors
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
#write.("./results/electric_heater_results_part3.json", JSON.json(site_analysis))

# Populate the DataFrame with the results produced and inputs
df = DataFrame(
    City = cities,
    PV_size_kW = [round(site_analysis[i][2]["PV"]["size_kw"], digits=0) for i in sites_iter],
    PV_Production_kWh = [round(site_analysis[i][2]["PV"]["annual_energy_produced_kwh"], digits=0) for i in sites_iter],
    Battery_size_kWh = [round(site_analysis[i][2]["ElectricStorage"]["size_kwh"], digits=0) for i in sites_iter], 
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
    Breakeven_Cost_of_Emissions_Reduction = [round(site_analysis[i][2]["Financial"]["breakeven_cost_of_emissions_reduction_per_tonne_CO2"], digits=4) for i in sites_iter], 
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
            sheet_name = "resultsChicago_" * string(counter)
            try
                sheet = xf[sheet_name]
                counter += 1
            catch
                break
            end
        end
        sheet_name = "resultsChicago_" * string(counter)
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
