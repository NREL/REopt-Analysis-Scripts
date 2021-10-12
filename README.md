# REopt API Analysis using Python

[REopt](https://reopt.nrel.gov/) is a techno-economic decision support model
from NREL which is used for optimizing energy systems for buildings, campuses,
communities, and microgrids. [REopt Lite](https://reopt.nrel.gov/tool) offers a
no-cost subset of features from NREL’s more comprehensive REopt model. REopt
Lite also offers an application programming interface (API). This is a guide to
use REopt’s Application Programming Interface for running REopt analysis
programmatically.

**Detailed documentation of REopt Lite API is available
[here](https://developer.nrel.gov/docs/energy-optimization/reopt-v1/).**

See [examples/single_and_multi_scenario_examples.ipynb](https://github.com/NREL/REopt-API-Analysis/blob/master/examples/single_and_multi_scenario_examples.ipynb) for usage examples.


## Usage
There are two ways to setup an environment from which to call the API:

1. Use Docker to host a pre-configured Python environment
2. Install a Python environment natively on your operating system

See the instructions below for each method.

### Prerequisites

1. Obtain *API\_key* from [here](https://developer.nrel.gov/signup/)

### Use Docker to host a pre-configured Python environment
1. Refer to the [README.md](https://github.com/NREL/REopt-API-Analysis/blob/updates/notebook/README.md) file inside of the notebook directory.

### Setup a python environment
1. Install Python 3.6+ interpreter:

    - Ubuntu: `sudo apt-get install python3-dev`

    - Mac OSX: Download and install version 3.6+ from
      [here](https://www.python.org/downloads/mac-osx/)

    - Windows: Download and install version 3.6+ from
      [here](https://www.python.org/downloads/windows/)

2. Install [pip](https://pip.pypa.io/en/stable/installing/)

    > Recommended: use a [virtual
    > environment](https://virtualenv.pypa.io/en/stable/installation/)

3. Add the required python packages:

    - *If using `virtualenv`*: [activate
      the environment](https://virtualenv.pypa.io/en/stable/userguide/)

    - `pip install -r requirements.txt`

    > NOTE: The `requirements.txt` does not include dependecies for the *jupyter
    > notebooks*

4. (OPTIONAL) Install git: - https://git-scm.com/book/en/v2/Getting-Started-Installing-Git


### Running the code
1.  Clone, download, or fork the repository. 
2.  See examples/single_and_multi_scenario_examples.ipynb
