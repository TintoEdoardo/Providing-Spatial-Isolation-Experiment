import os
import re
import random
import statistics
import matplotlib.pyplot   as plt
import paths_and_constants as pc

"""
    FUNCTIONS USED FOR ANALYSING EXPERIMENTAL DATA
"""


def parseInputLine (line):
    """
    The result is stored as an array of eventually empty lists
    """
    #  Remove eventual padding
    line = line.replace ('\x00', '')
    results = []
    for tag in pc.metrics:
        opening_tag = "<"  + tag + ">"
        closing_tag = "</" + tag + ">"
        times       = re.findall (opening_tag + "(.*?)" + closing_tag, line)
        times_ms    = []
        for time_str in times:
            time_float = 0.0
            try:
                #  The conversion might fail
                time_float = float (time_str)

                #  Convert times in millisecond (ms)
                times_ms.append(time_float * 1000)
            except ValueError:
                continue

        #  Store the times (in ms) array in results
        results.append (times_ms)

    #  Finally, return the metrics acquired in this line
    return results


def restrictRandomly (times_matrix, e_id):
    """
    Select only pc.number_of_samples from each column
    """
    # TODO: payload_len [e_id]
    result = [[] for _ in range (pc.payload_len)]

    for p_size in range (pc.payload_len):
        #  print ("len (times_matrix [p_size]) " + str (len (times_matrix [p_size])))
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
     - The time required for the Recieve operation.
    """
    #  result = [[] for _ in range (pc.experiments_number)]

    #  for e_n in pc.experiments_number:
    for e_n in range (pc.experiments_number):

        e_id = pc.experiment_id [e_n]

        path_to_results = os.path.join (pc.path_to_exp [e_id], pc.results_folder_name)

        for t_period in pc.task_period:
            #  The result is stored as an array of matrix.
            #  array_of_times_matrix [i] contains the matrix of
            #  acquired times from the metric i as an array of
            #  rows, each row corresponds to a payload size
            #                         /  / a_1_1 a_1_2 ... a_1_n \   / d_1_1 . . . \          \
            # array_of_times_matrix = |  |   :     :         :   | ; |   :     :   | ; . . .  |
            #                         \  \ a_m_1 a_m_2 ... a_m_n /   \ d_m_1 d_m_n /          /
            #
            array_of_times_matrix = [[] for _ in range (pc.metrics_len)]

            #  Parse all the result files of the current experiment,
            #  placing each metric into a specific matrix represented
            #  as an array of column
            for p_size in pc.payload_size [e_id]:

                #  rows_of_times [i] contains, for the i-th metric, a
                #  column of the measured times with message of payload
                #  size p_size
                rows_of_times = [[] for _ in range (pc.metrics_len)]
                assert (len (rows_of_times) == pc.metrics_len)

                result_file_name    = \
                    str (p_size) + "_" + str (t_period) + "_results.txt"
                path_to_result_file = os.path.join (path_to_results, result_file_name)

                file  = open (path_to_result_file, 'r')
                lines = file.readlines ()
                assert (len (lines) == 2 * pc.number_of_samples)

                #  Iterate over each line of the file
                for line in lines:

                    #  Perform line parsing
                    parser_results = parseInputLine (line)

                    #  Compute the column array for each metric
                    for m in range (pc.metrics_len):

                        par_col_m = parser_results [m]
                        if len (par_col_m) > 0:
                            rows_of_times[m] += par_col_m

                assert (len (rows_of_times [0]) > pc.number_of_samples)
                assert (len (rows_of_times [2]) > pc.number_of_samples)

                #  Append each column to the corresponding matrix
                for m in range (pc.metrics_len):
                    array_of_times_matrix [m].append (rows_of_times [m])

            assert (len (array_of_times_matrix) == pc.metrics_len)
            assert (len (array_of_times_matrix [0][0]) > pc.number_of_samples)

            #  Sample only pc.number_of_samples values from each
            #  row of arrays_of_times_matrix [i]
            sampled_matrices = [[] for _ in range (pc.metrics_len)]
            for m_i in range (pc.metrics_len):
                sampled_matrices [m_i] = restrictRandomly (array_of_times_matrix [m_i], e_id)
                assert (len (sampled_matrices [m_i][3]) == pc.number_of_samples)

            #  Save the generated metrix inside specific files
            path_to_data = os.path.join (pc.path_to_exp [e_id], pc.data_folder_name)
            for m_i in range (pc.metrics_len):
                #  Create a file with a specific name
                data_file_name    = "_".join ([pc.metrics [m_i], "period", str (int (t_period / 1000))]) + ".txt"
                path_to_data_file = os.path.join (path_to_data, data_file_name)
                file              = open (path_to_data_file, 'w')
                lines             = []
                for p_size in range (pc.payload_len):
                    new_line = " ".join (["{:.6f}".format (i) for i in sampled_matrices [m_i][p_size]]) + "\n"
                    lines.append (new_line)

                #  Write all the lines in the specific file
                file.writelines (lines)
                file.close ()


def generatePlotDiagrams ():
    """
    Draw the plot diagram for each experiment
    """

    for e_n in range (pc.experiments_number):

        for t_period in pc.task_period:

            #  sampled_matrices [metric_id] [payload_size] [samples_number]
            #  sampled_matrices    = array_of_sampled_matrices [e_n]
            e_id                = pc.experiment_id [e_n]

            #  Generate labels and covert the payload in KB
            x_values = [*range (0, pc.payload_len, 1)]
            x_ticks  = [str (size * 32 / 1000) for size in pc.payload_size [e_id]]
            x_label  = "Size of the message payload (KB)"
            y_label  = "Measured execution time (ms)"

            path_to_data = os.path.join (pc.path_to_exp [e_id], pc.data_folder_name)

            for m_i in range (pc.metrics_len):
                data_file_name    = "_".join ([pc.metrics [m_i], "period", str (int (t_period / 1000))]) + ".txt"
                path_to_data_file = os.path.join (path_to_data, data_file_name)
                file              = open (path_to_data_file, 'r')
                lines             = file.readlines ()
                file.close ()

                #  The data file contains the sampled values, each
                #  line refers to a single payload size value
                sampled_matrix = []
                for l_i in range (len (lines)):
                    array_float = []
                    array_str   = lines [l_i].split (" ")
                    for s in array_str:
                        array_float.append (float (s))
                    sampled_matrix.append (array_float)

                plt.clf ()
                plt.boxplot (sampled_matrix)
                plt.xticks  (x_values, x_ticks)
                plt.xlabel  (x_label)
                plt.ylabel  (y_label)
                plt.title   (pc.metrics_name [pc.metrics [m_i]])
                prefix          = "_".join([e_id, "plot", pc.metrics [m_i], str (int (t_period / 1000))]) + ".png"
                path_to_diagram = os.path.join (pc.path_to_graphs, prefix)
                plt.savefig (path_to_diagram)


def computeStatisticalSignificance (alpha):
    """
    """
    #  The results are written inside a file, each line as:
    #  e_id t_period m_i ( lower , upper ) delta
    significance_file = "significance.txt"
    path_to_sig_file  = os.path.join (pc.path_to_significance, significance_file)
    results           = []
    for e_n in range (pc.experiments_number):

        e_id = pc.experiment_id [e_n]

        for t_period in pc.task_period:

            path_to_data = os.path.join (pc.path_to_exp [e_id], pc.data_folder_name)

            for m_i in range (pc.metrics_len):

                data_file_name    = "_".join ([pc.metrics[m_i], "period", str (int (t_period / 1000))]) + ".txt"
                path_to_data_file = os.path.join (path_to_data, data_file_name)
                file              = open (path_to_data_file, 'r')
                lines             = file.readlines ()
                samples           = []
                file.close()

                #  Produce an array with all the samples given
                #  e_id, t_period and m_i
                for l_i in range (len (lines)):
                    array_float = []
                    array_str = lines[l_i].split(" ")
                    for s in array_str:
                        array_float.append(float(s))
                    samples += array_float

                #  Find an interval where p < alpha
                max_outliers   = pc.number_of_samples * alpha
                samples_median = statistics.median (samples)
                sorted_samples = sorted (samples)
                outliers_found = 0
                lower_i        = 0
                upper_i        = len (sorted_samples) - 1
                while outliers_found < max_outliers:
                    if samples_median - sorted_samples [lower_i] > sorted_samples [upper_i] - samples_median:
                        lower_i        += 1
                    else:
                        upper_i        -= 1
                    outliers_found += 1

                #  The interval where p < alpha is [ lower, upper ]
                lower    = sorted_samples [lower_i]
                upper    = sorted_samples [upper_i]
                line     = " ".join ([str (e_id), str (t_period), str (m_i)])
                line    += (" ( " + "{:.6f}".format (lower) + ", " + "{:.6f}".format (upper) + " )")
                line    += " {:.6f}".format (upper - lower)
                results.append (line)

                print (line)

    file = open (path_to_sig_file, 'r')
    file.writelines (results)
    file.close ()
