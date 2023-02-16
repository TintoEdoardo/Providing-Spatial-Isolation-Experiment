import os
import re
import random
import matplotlib.pyplot   as plt
import paths_and_constants as pc

"""
    FUNCTIONS USED FOR ANALYSING EXPERIMENTAL DATA
"""


def parseInputLine (line):
    """
    The result is stored as an array of eventually empty lists
    """
    results = []
    for tag in pc.metrics:
        opening_tag = "<"  + tag + ">"
        closing_tag = "</" + tag + ">"
        times = re.findall (opening_tag + "(.*?)" + closing_tag, line)

        #  Convert times in millisecond (ms)
        times_ms = [float (time) * 1000 for time in times]

        #  Store the times (in ms) array in results
        results.append (times_ms)

    #  Finally, return the metrics acquired in this line
    return results


def restrictRandomly (times_matrix):
    """
    Select only pc.number_of_samples from each column
    """
    result = [[] for _ in pc.payload_len]
    for p_size in pc.payload_size:
        #  Select randomly pc.number_of_samples from times_matrix [p_size]
        result_column = random.sample (times_matrix [p_size], pc.number_of_samples)
        result [p_size] = result_column

    #  Finally, return the sampled matrix
    return result


def extractMetrics ():
    """
    The metrics extracted are:
     - The allocation time.
     - The deallocation (Free) time.
     - The time required for the Send operation.
     - The time required for the Receive operation.
    """
    result = [[] for _ in range (pc.experiments_number)]
    for e_n in pc.experiments_number:

        e_id = pc.experiment_id [e_n]

        path_to_results = os.path.join (pc.path_to_exp [e_id], pc.results_folder_name)

        #  The result is stored as an array of matrix.
        #  array_of_times_matrix [i] contains the matrix of
        #  acquired times from the metric i as an array of
        #  columns, each column corresponds to a payload size
        #                         /  / a_1_1 a_1_2 ... a_1_n \   / d_1_1 . . . \          \
        # array_of_times_matrix = |  |   :     :         :   | ; |   :     :   | ; . . .  |
        #                         \  \ a_m_1 a_m_2 ... a_m_n /   \ d_m_1 d_m_n /          /
        #
        array_of_times_matrix = [[] for _ in range (len (pc.metrics))]

        #  Parse all the result files of the current experiment,
        #  placing each metric into a specific matrix represented
        #  as an array of column
        for p_size in pc.payload_size:

            #  columns_of_times [i] contains, for the i-th metric, a
            #  column of the measured times with message of payload
            #  size p_size
            columns_of_times = [[] for _ in range (len (pc.metrics))]

            result_file_name    = str(p_size) + "_results.txt"
            path_to_result_file = os.path.join (path_to_results, result_file_name)

            file  = open (path_to_result_file, 'r')
            lines = file.readlines ()

            #  Iterate over each line of the file
            for line in lines:

                #  Perform line parsing
                parser_results = parseInputLine (line)

                #  Compute the column array for each metric
                for m in range (pc.metrics_len):
                    par_res_len = len (parser_results [m])

                    #  Iterate over the result of parsing (if any)
                    if par_res_len > 0:
                        for par_res_i in range (par_res_len):
                            columns_of_times [m].append (parser_results [m][par_res_i])

            #  Append each column to the corresponding matrix
            for m in range (pc.metrics_len):
                array_of_times_matrix [m].append (columns_of_times [m])

        #  Sample only pc.number_of_samples values from each
        #  column of arrays_of_times_matrix [i]
        sampled_matrices = [[] for _ in pc.metrics_len]
        for m_i in pc.metrics_len:
            sampled_matrices [m_i] = restrictRandomly (array_of_times_matrix)

        #  Save the generated metrix inside specific files
        path_to_data = os.path.join (pc.path_to_exp [e_id], pc.data_folder_name)
        for m in pc.metrics:
            #  Create a file with a specific name
            data_file_name    = m + ".txt"
            path_to_data_file = os.path.join (path_to_data, data_file_name)
            file              = open (path_to_data_file, 'w')
            lines             = []
            for s_id in range (pc.number_of_samples):
                new_line = ""
                for p_size in range (pc.payload_len):
                    time_p_s = str (sampled_matrices [m][p_size][s_id])
                    #  Join the already computed line and the new measure,
                    #  with a space between the two strings
                    new_line = " ".join([new_line, time_p_s])
                lines.append (new_line)

            #  Write all the lines in the specific file
            file.writelines (lines)
            file.close ()

        #  Update the result array
        result [e_n] = sampled_matrices

    # Finally return the result array
    return result


def generatePlotDiagrams (array_of_sampled_matrices):
    """
    Draw the plot diagram for each experiment
    """
    #  Generate labels and covert the payload in KB
    x_values = [*range (0, pc.experiments_number + 1, 1)]
    x_ticks  = [str(size * 32 / 1000) for size in pc.payload_size]
    x_label  = "Size of the message payload (KB)"
    y_label  = "Measured execution time (ms)"

    for e_n in pc.experiments_number:
        #  sampled_matrices [metric_id] [payload_size] [samples_number]
        sampled_matrices    = array_of_sampled_matrices [e_n]
        e_id                = pc.experiment_id [e_n]
        diagram_name_prefix = "-".join([e_id, "plot_"])

        for m in pc.metrics:
            plt.clf ()
            plt.boxplot (sampled_matrices [m])
            plt.xticks  (x_values, x_ticks)
            plt.xlabel  (x_label)
            plt.ylabel  (y_label)
            plt.title   (pc.metrics_name [e_id])
            path_to_diagram = os.path.join\
                (pc.path_to_graphs, diagram_name_prefix, pc.metrics_name [e_id])
            plt.savefig (path_to_diagram)


