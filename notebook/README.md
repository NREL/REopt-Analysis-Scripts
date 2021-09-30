# Notebook for REopt-API-Analysis
Run REopt Lite API hosted locally or on a remote server

# Setup
1. Install Docker (https://www.docker.com/get-started)
2. Open a command line terminal (e.g. command prompt, bash terminal) and type `cd path/to/cloned/repo`
3. Type `docker compose up --build` depending on the version of Docker
4. Click the provided URL (starting with `http://127.0.0.1`) to open Jupyter Lab in your browser
5. Click on the `work` folder in the left-hand project explorer and navigate to `/notebooks/<your notebook>`
6. If running REopt **locally**, you will also need to spin up REopt Lite Docker containers (https://github.com/NREL/REopt_Lite_API)
7. To shut down, cntrl+c in the terminal or shutdown using the Jupyter Lab controls

## After initial setup
1. To spin up again after you've already done `--build` in step 3. above, just type `docker compose up` and click the Jupyter URL
