import folder_setup_functions
import launch_function
import data_analysis_functions

"""
    STARTING POINT FOR THE EXPERIMENTS
"""

if __name__ == '__main__':

    #  Perform initial cleaning of the working directory
    #  folder_setup_functions.clearGraphDirectory ()
    #  folder_setup_functions.clearExperimentsDirectory ()

    #  Generate the test applications and compile them
    #  folder_setup_functions.populateExperimentsDirectory ()

    #  Run the experiments
    #  launch_function.performTheExperiments ()

    #  Extract the relevant metrics
    # data_analysis_functions.extractMetrics ()

    #  Produce the plot diagrams
    # data_analysis_functions.generatePlotDiagrams ()

    #  Calculate the statistical significance
    data_analysis_functions.computeStatisticalSignificance (0.5)
