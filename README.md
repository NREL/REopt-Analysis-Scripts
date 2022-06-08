# REopt API Analysis using Python

## Updated for Multi-Scenario and Multi-Tariff Inputs
We now have now have the ability to use multiple custom electric tariffs with the multi-scenario version of the program. In particular, it allows the addition of a column in the multi-scenario input file titled `urdb_json_file` that allows a specific electric tariff to be specified for each scenario. Below is an example of some inputs:

| description  | load_file | urdb_json_file | urdb_label |
| ------------- | ------------- | ------------- | ------------- |
| 87104  | 87104_load_kw.csv  | 87104_electric_tariff.json  | 87104_electric_tariff.json  |
| 87106  | 87106_load_kw.csv  | 87106_electric_tariff.json  | 87106_electric_tariff.json  |
| 87106  | 87106_load_kw.csv  |   | 5cc090b85457a3a43667107e  |
 
The user can specify the location of a json file that is placed within `./electric_rates/` or a urdb_label as usual. This is useful for when users have scenarios looking at multiple different customer classes that may face different rate structures.

#
[REopt](https://reopt.nrel.gov/) is a techno-economic decision support model
from NREL which is used for optimizing energy systems for buildings, campuses,
communities, and microgrids. [REopt Lite](https://reopt.nrel.gov/tool) offers any
user the capability to perform their own techno-economic analysis, but 
customizable analysis solutions are also available by reaching out to NREL's 
REopt team. REopt Lite also offers an application programming interface (API). This is a guide to
use REopt’s Application Programming Interface for running REopt analysis
programmatically.

**Detailed documentation of REopt Lite API is available in [this repository's wiki](https://github.com/NREL/REopt-API-Analysis/wiki).**

This repository includes example scripts and notebooks for calling the API.

## Usage
There are two ways to setup an environment from which to call the API:

1. Use Docker to host a pre-configured Python environment
2. Install a Python environment natively on your operating system

See the instructions below for each method.

### Prerequisites

1. Obtain *API\_key* from [here](https://developer.nrel.gov/signup/)

### Use Docker to host a pre-configured Python environment
1. Install Docker (https://www.docker.com/get-started)
2. Open a command line terminal (e.g. command prompt, bash terminal) and type `cd path/to/cloned/repo`
3. Type `docker compose up --build` depending on the version of Docker
4. If there is an error in the build process (likely pulling the base image), try first running `docker pull jupyter/datascience-notebook` and then do `docker compose up`
5. Click the provided URL (starting with `http://127.0.0.1`) to open Jupyter Lab in your browser
6. Click on the `work` folder in the left-hand project explorer and navigate to either of the notebooks (.ipynb files).
7. If running REopt **locally**, you will also need to spin up REopt Lite Docker containers (https://github.com/NREL/REopt_Lite_API)
8. To shut down, cntrl+c in the terminal or shutdown using the Jupyter Lab controls

#### After initial docker setup
1. To spin up again after you've already done `--build` in step 3. above, just type `docker compose up` and click the Jupyter URL

### Setup a python environment
1. Install Python 3.6+ interpreter:

    - Ubuntu: `sudo apt-get install python3-dev`

    - Mac OSX: Download and install version 3.6+ from
      [here](https://www.python.org/downloads/mac-osx/)

    - Windows: Download and install version 3.6+ from
      [here](https://www.python.org/downloads/windows/)

2. Install [pip](https://pip.pypa.io/en/stable/installing/)

    > Recommended: use a [virtual
    > environment with venv](https://docs.python.org/3/library/venv.html)

3. Add the required python packages:

    - *If using `venv`*: [activate
      the environment](https://docs.python.org/3/library/venv.html)

    - `pip install -r requirements.txt`

    > NOTE: The `requirements.txt` does not include dependecies for the *jupyter
    > notebooks*

4. (OPTIONAL) Install git: - https://git-scm.com/book/en/v2/Getting-Started-Installing-Git


### Running the code
1.  Clone, download, or fork the repository. 
2.  See single_scenario_example.ipynb and multi_scenario_example.ipynb
