import folder_setup_functions
import launch_function
import data_analysis_functions

"""
    STARTING POINT FOR THE EXPERIMENTS
"""

if __name__ == 'main':

    #  Perform initial cleaning of the working directory
    folder_setup_functions.clearGraphDirectory ()
    folder_setup_functions.clearExperimentsDirectory ()

    #  Generate the test applications and compile them
    folder_setup_functions.populateExperimentsDirectory ()

    #  Run the experiments
    launch_function.performTheExperiments ()

    #  Extract the relevant metrics
    results = data_analysis_functions.extractMetrics ()

    #  Produce the plt diagrams
    data_analysis_functions.generatePlotDiagrams (results)
    