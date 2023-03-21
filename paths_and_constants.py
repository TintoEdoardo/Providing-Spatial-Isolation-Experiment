import os

"""
    PATH AND CONSTANTS USED WHILE RUNNING THE EXPERIMENTS
"""

"""
    Constants
"""
experiment_id       = ["1_1", "1_2", "2_1"]
experiments_number  = len (experiment_id)
experiment_name     = {
    experiment_id [0] : "Channels without message overwriting",
    experiment_id [1] : "Channels with message overwriting",
    experiment_id [2] : "Protected Objects"
}
experiment_workload = {
    experiment_id [0] : 1,
    experiment_id [1] : 2,
    experiment_id [2] : 3
}

payload_size        = {
    experiment_id [0] : [10, 29136, 58262, 87388, 1165640, 145640, 174766, 203892, 233018, 262144],
    experiment_id [1] : [10, 29136, 58262, 87388, 1165640, 145640, 174766, 203892, 233018, 262144],
    experiment_id [2] : [10, 563, 1116, 1670, 2223, 2776, 3330, 3883, 4436, 4990]
}

payload_len         = 10
number_of_samples   = 100
src_folder_name     = "Providing-Spatial-Isolation-Experiment"
project_file        = "providing_spatial_isolation_experiment.gpr"
results_folder_name = "Results"
data_folder_name    = "Data"

task_period         = [10_000, 58_000, 106_000, 152_000, 200_000]

metrics      = ["alloc", "free", "send", "receive"]
metrics_name = {
    metrics [0] : "Allocation times",
    metrics [1] : "Deallocation times",
    metrics [2] : "Send times",
    metrics [3] : "Receive times"
}
metrics_len  = len (metrics)

"""
    Paths
"""
working_directory   = os.getcwd ()
path_to_experiments = os.path.join (working_directory, "Experiments")
path_to_graphs      = os.path.join (working_directory, "Graphs")
path_to_src         = os.path.join (working_directory, "Providing-Spatial-Isolation-Experiment")
path_to_exp         = {
    experiment_id [0] : os.path.join (path_to_experiments, "Experiments_" + experiment_id [0]),
    experiment_id [1] : os.path.join (path_to_experiments, "Experiments_" + experiment_id [1]),
    experiment_id [2] : os.path.join (path_to_experiments, "Experiments_" + experiment_id [2])
}
path_to_significance = os.path.join (working_directory, "Significance")
