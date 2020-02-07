[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL/REopt-API-Analysis/class_updates?urlpath=https%3A%2F%2Fgithub.com%2FNREL%2FREopt-API-Analysis%2Fblob%2Fclass_updates%2Fnotebooks%2FREopt_Lite_API_Demo.ipynb)

Running REopt API Analysis using Python
==========================================

[REopt](https://reopt.nrel.gov/) is a techno-economic decision support model from NREL which is used for optimizing energy systems for buildings, campuses, communities, and microgrids. [REopt Lite](https://reopt.nrel.gov/tool) offers a no-cost subset of features from NREL's more comprehensive REopt model. REopt Lite also offers an application programming interface (API). This is a guide to use REopt's Application Programming Interface for running REopt analysis programmatically. 

**Detailed documentation of REopt Lite API is available [here](https://developer.nrel.gov/docs/energy-optimization/reopt-v1/).**

## How to run?

In the script  named `run_scenarios_and_save_results.py` and `post_and_poll.py` replace "my_API_KEY" with your API key. You can obtain your API key from developer.nrel.gov/signup/ (no cost).

### Prerequisites 
You will need a python 3.6+ interpreter:   
- Ubuntu: `sudo apt-get install python3-dev`
- Mac OSX: [Download and install version 3.6+ from here](https://www.python.org/downloads/mac-osx/)
- (using a version with an installer is highly recommended)
- Windows: [Download and install version 3.6+ from here](https://www.python.org/downloads/windows/)
  _**Note** that Python 3.5.5 cannot be used on Windows XP or earlier._
- Install [pip](https://pip.pypa.io/en/stable/installing/)
- Recommended: use a [virtual environment](https://virtualenv.pypa.io/en/stable/installation/)

And add the required python packages:
- (if using `virtualenv` first [activate the environment](https://virtualenv.pypa.io/en/stable/userguide/))
- `pip install -r requirements.txt`  

Install git:
- https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
  
### Running the code
1. Clone (or download) the repository: 
    - ```git clone https://github.com/nrel/REopt-API-Analysis.git```
2. Use one of the Analysis Options below
  
## Analysis Options
1. Multi-site
    - There are two options, both of which run using examples in `run_scenarios_and_save_results.py`
        1. Write to a csv using a template with column headers for desired summary keys (scalar values only)
        2. Write all inputs, outputs, and dispatch to an Excel spreadsheet
    - Both options use the same input file (defined in `run_scenarios_and_save_results.py`)
        - the default input file is in `inputs/scenarios.csv`
    - Option (a) uses a results template. 
        - the default csv template is in `outputs/results_template.csv`; 
            - TODO: the "0" row has all available inputs, which one can duplicate to create a new desired scenario (one per row)
        - `outputs/results_template.csv` can be modified with the [desired output keys](https://developer.nrel.gov/docs/energy-optimization/reopt-v1/) placed in the first row
            - Note that some output keys are redundant, such as `size_kw` for `PV`, `Storage`, `Wind`, and `Generator`; thus you must use the "pipe" symbol to designate a specific technology: `PV|size_kw` for example
    - Option (b) requires an **empty** Excel spreadsheet template to store the results
2. Single-site
    - Uses `post_and_poll.py` in the top level directory. Change the `post` variable in `post_and_poll.py` to point to your scenario json file.
    - Change the `results_file` name in `post_and_poll.py` to your desired value. 





