using JuMP
using Xpress
using REopt
using DataFrames
import JSON
import CSV

# OPTIMIZATION SOLVE PARAMETERS
const MAXTIME = 600::Int64
const RELSTOP = 1e-3::Float64
const GAPSTOP = 1e-4::Float64
const PRIMALSTOP = 1e-4::Float64

# SCENARIOS
const SITES = [
        Dict("name" => "aniak", "longitude" => -159.533, "latitude" => 61.583)
    ]
const VARIATIONS = [""]

# FUNCTIONS
function results_filename(site_name::String, variation::String)
    if variation != ""
        variation = "_$(variation)"
    return "results/results_$(site_name)$(variation).json"
end

function run_reopt_scenarios()
    PV_prod_factor_col_name = "ProdFactor"

    inputs = JSON.parsefile("data/scenario.json")

    for site in SITES
        for var in VARIATIONS
            #optionally do something with var
            inputs["Site"]["longitude"] = site["longitude"]
            inputs["Site"]["latitude"] = site["latitude"]
            weather_file = CSV.File("data/$(site["name"])_weather.csv")
            prod_factor = getproperty(weather_file,Symbol(PV_prod_factor_col_name))
            inputs["PV"]["prod_factor_series"] = prod_factor

            global m = Model(()->Xpress.Optimizer(MAXTIME=-MAXTIME, MIPRELSTOP=RELSTOP, BARGAPSTOP=GAPSTOP, BARPRIMALSTOP=PRIMALSTOP))
            global m = Model(()->HiGHS.Optimizer(MAXTIME=-MAXTIME, MIPRELSTOP=RELSTOP, BARGAPSTOP=GAPSTOP, BARPRIMALSTOP=PRIMALSTOP))
            set_optimizer_attribute(model, "time_limit", 60.0)

            results = run_reopt(m, inputs)

            inputs["MAXTIME"] = MAXTIME
            inputs["MIPRELSTOP"] = RELSTOP
            inputs["BARGAPSTOP"] = GAPSTOP
            inputs["BARPRIMALSTOP"] = PRIMALSTOP
            results["inputs"] = inputs
            open(results_filename(site["name"], ""), "w") do f
                write(f, JSON.json(results))
            end
        end
    end
end

function summarize_results()
    for site in SITES
        df_results_summary = DataFrame("Warming scenario" => ["Active cooling needed (MMBtu)", "PV size (W)", "Battery size (W)", "Battery size (Wh)", "Time actively cooling (%)", "Optimality gap (%)"])
        for var in VARIATIONS
            results = JSON.parsefile(results_filename(site["name"], plus_deg))
            df_results_summary = hcat(df_results_summary, DataFrame(
                    "+$(plus_deg)C" => [
                        round(results["Thermosyphon"]["min_annual_active_cooling_mmbtu"], digits=3),
                        results["PV"]["size_kw"]*1000,
                        results["ElectricStorage"]["size_kw"]*1000,
                        results["ElectricStorage"]["size_kwh"]*1000,
                        round(count(i -> (i > 0), results["Thermosyphon"]["active_cooling_series_btu_per_hour"]) * 100 / 8760, digits=2),
                        if typeof(results["optimality_gap"])<:Real round(results["optimality_gap"]*100, digits=2) else results["optimality_gap"] end
                    ]
            ))
        end
        CSV.write("results/$(site["name"])_results_summary.csv", df_results_summary)
    end
end

# MAIN
run_reopt_scenarios()
summarize_results()
