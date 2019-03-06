Python scripts for using REopt API
==========================================

[REopt](https://reopt.nrel.gov/) is a techno-economic decision support model from NREL which is used for optimizing energy systems for buildings, campuses, communities, and microgrids. 


[REopt Lite](https://reopt.nrel.gov/tool) offers a no-cost subset of features from NREL's more comprehensive REopt model. REopt Lite also offers an application programming interface (API). 

This is a guide to use REopt's Application Programming Interface for running REopt analysis programmatically. 

### File Descriptions

#### POST.json
The inputs to the model are sent in json format. POST.json contains an example post where the assessment of economic feasibiity of photovoltaic generation and battery storage is being done for a given location with a custom electric tariff.

#### post\_and\_poll.py
A scenario is posted at [https://developer.nrel.gov/api/reopt/v1/job/](https://developer.nrel.gov/api/reopt/v1/job/) to get get a **Universal Unique ID** (run_uuid) back. This script is for posting inputs to the API, receive the run_uuid and then polling for results using the run_uuid.


#### results\_poller.py
A polling function for retrieving results. This function is utilized in the post\_and\_poll.py. 


#### logger.py
Configurable logging for console and log file

The results will get saved in results.json. 

