# Usage

> In the script named `run_scenarios_and_save_results.py` replace “my\_API\_KEY”
> with your API key. You can obtain your API key from
> [here](developer.nrel.gov/signup/) (no cost).

  - There are two options, both of which run using examples in
    `run_scenarios_and_save_results.py`
    1.  Write to a csv using a template with column headers for desired summary
        keys (scalar values only)
    2.  Write all inputs, outputs, and dispatch to an Excel spreadsheet
  - Both options use the same input file (defined in
    `run_scenarios_and_save_results.py`)
      - the default input file is in `inputs/scenarios.csv`
  - Option (a) uses a results template.
      - the default csv template is in `outputs/results_template.csv`;
          - TODO: the “0” row has all available inputs, which one can duplicate
            to create a new desired scenario (one per row)
      - `outputs/results_template.csv` can be modified with the [desired output
        keys](https://developer.nrel.gov/docs/energy-optimization/reopt-v1/)
        placed in the first row
          - Note that some output keys are redundant, such as `size_kw` for
            `PV`, `Storage`, `Wind`, and `Generator`; thus you must use the
            “pipe” symbol to designate a specific technology: `PV|size_kw` for
            example
  - Option (b) requires an **empty** Excel spreadsheet template to store the
    results
