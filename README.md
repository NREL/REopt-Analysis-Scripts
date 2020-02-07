[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NREL/REopt-API-Analysis/class_updates?urlpath=https%3A%2F%2Fgithub.com%2FNREL%2FREopt-API-Analysis%2Fblob%2Fclass_updates%2Fnotebooks%2FREopt_Lite_API_Demo.ipynb)

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

This repository has three different ways of interfacing with the api through the
directories `single_site`, `multi_site` and `notebooks`. Each of these
repositoris has a `README.md` file in them that describes the analysis workflow.


## Usage

**The easiest way to get started using the REopt Lite API it to access it
through the
[Binder](https://mybinder.org/v2/gh/NREL/REopt-API-Analysis/class_updates?urlpath=https%3A%2F%2Fgithub.com%2FNREL%2FREopt-API-Analysis%2Fblob%2Fclass_updates%2Fnotebooks%2FREopt_Lite_API_Demo.ipynb)
notebook. Otherwise you will need to set up your environment following the steps
below.**


### Prerequisites

1. Obtain *API\_key* from [here](https://developer.nrel.gov/signup/)

2. Install Python 3.6+ interpreter:

    - Ubuntu: `sudo apt-get install python3-dev`

    - Mac OSX: Download and install version 3.6+ from
      [here](https://www.python.org/downloads/mac-osx/)

    - Windows: Download and install version 3.6+ from
      [here](https://www.python.org/downloads/windows/)

3. Install [pip](https://pip.pypa.io/en/stable/installing/)

    > Recommended: use a [virtual
    > environment](https://virtualenv.pypa.io/en/stable/installation/)

4. Add the required python packages:

    - *If using `virtualenv`*: [activate
      the environment](https://virtualenv.pypa.io/en/stable/userguide/)

    - `pip install -r requirements.txt`

    > NOTE: The `requirements.txt` does not include dependecies for the *jupyter
    > notebooks*

5. (OPTIONAL) Install git: - https://git-scm.com/book/en/v2/Getting-Started-Installing-Git


### Running the code

1.  Clone (or download) the repository:

    ``` bash
    git clone https://github.com/nrel/REopt-API-Analysis.git
    ```

2.  Follow the `README.md` instructions in the
    [multi\_site](https://github.com/NREL/REopt-API-Analysis/blob/class_updates/multi_site/README.md) or
    [single\_site](https://github.com/NREL/REopt-API-Analysis/blob/class_updates/single_site/README.md) directories
