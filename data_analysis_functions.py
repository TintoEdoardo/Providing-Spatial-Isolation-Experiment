import os
import re
import random
import statistics
import matplotlib.pyplot   as plt
import paths_and_constants as pc

"""
    FUNCTIONS USED FOR ANALYSING EXPERIMENTAL DATA
"""


def parseInputLine (line, metrics):
    """
    The result is stored as an array of eventually empty lists
    """
    #  Remove eventual padding
    line = line.replace ('\x00', '')
    results = []
    for tag in metrics:
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
                times_ms.append (time_float * 1000)
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

    for e_n in range (pc.experiments_number):

        e_id = pc.experiment_id [e_n]

        print (" -- EXPERIMENT " + str (e_id) + " -- ")

        path_to_results = os.path.join (pc.path_to_exp [e_id], pc.results_folder_name)

        #  Different experiments measure different metrics.
        #  For this reason, the set of metrics to be computed
        #  is chosen here
        if e_id in ["1_1", "1_2"]:
            metrics      = pc.metrics
            metrics_name = pc.metrics_name
            metrics_len  = pc.metrics_len
        else:
            metrics      = pc.metrics_po
            metrics_name = pc.metrics_po_name
            metrics_len  = pc.metrics_po_len

        for t_period in pc.task_period:
            #  The result is stored as an array of matrix.
            #  array_of_times_matrix [i] contains the matrix of
            #  acquired times from the metric i as an array of
            #  rows, each row corresponds to a payload size
            #                         /  / a_1_1 a_1_2 ... a_1_n \   / d_1_1 . . . \          \
            # array_of_times_matrix = |  |   :     :         :   | ; |   :     :   | ; . . .  |
            #                         \  \ a_m_1 a_m_2 ... a_m_n /   \ d_m_1 d_m_n /          /
            #
            array_of_times_matrix = [[] for _ in range (metrics_len)]

            #  Parse all the result files of the current experiment,
            #  placing each metric into a specific matrix represented
            #  as an array of column
            for p_size in pc.payload_size [e_id]:

                #  rows_of_times [i] contains, for the i-th metric, a
                #  column of the measured times with message of payload
                #  size p_size
                rows_of_times = [[] for _ in range (metrics_len)]
                assert (len (rows_of_times) == metrics_len)

                result_file_name    = \
                    str (p_size) + "_" + str (t_period) + "_results.txt"
                path_to_result_file = os.path.join (path_to_results, result_file_name)

                file  = open (path_to_result_file, 'r')
                lines = file.readlines ()

                assert (len (lines) >= 2 * pc.number_of_samples)

                #  Iterate over each line of the file
                for line in lines:

                    #  Perform line parsing
                    parser_results = parseInputLine (line, metrics)

                    #  Compute the column array for each metric
                    for m in range (metrics_len):

                        par_col_m = parser_results [m]
                        if len (par_col_m) > 0:
                            rows_of_times[m] += par_col_m

                assert (len (rows_of_times [0]) >= pc.number_of_samples)
                assert (len (rows_of_times [2]) >= pc.number_of_samples)

                #  Append each column to the corresponding matrix
                for m in range (metrics_len):
                    array_of_times_matrix [m].append (rows_of_times [m])

            assert (len (array_of_times_matrix) == metrics_len)
            #  assert (len (array_of_times_matrix [0][0]) > pc.number_of_samples)

            #  Sample only pc.number_of_samples values from each
            #  row of arrays_of_times_matrix [i]
            sampled_matrices = [[] for _ in range (metrics_len)]
            for m_i in range (metrics_len):
                sampled_matrices [m_i] = restrictRandomly (array_of_times_matrix [m_i], e_id)
                assert (len (sampled_matrices [m_i][3]) == pc.number_of_samples)

            #  Save the generated metrix inside specific files
            path_to_data = os.path.join (pc.path_to_exp [e_id], pc.data_folder_name)
            for m_i in range (metrics_len):
                #  Create a file with a specific name
                data_file_name    = "_".join ([metrics [m_i], "period", str (int (t_period / 1000))]) + ".txt"
                path_to_data_file = os.path.join (path_to_data, data_file_name)
                file              = open (path_to_data_file, 'w')
                lines             = []
                for p_size in range (pc.payload_len):
                    new_line = " ".join (["{:.6f}".format (i) for i in sampled_matrices [m_i][p_size]]) + "\n"
                    lines.append (new_line)

                #  Write all the lines in the specific file
                file.writelines (lines)
                file.close ()

def generateBoxDiagrams ():
    """
    Draw the box diagram for each experiment
    """

    #  for e_n in range (pc.experiments_number):
    for e_n in [0, 2]:
        e_id = pc.experiment_id [e_n]

        if e_id in ["1_1", "1_2"]:
            metrics      = pc.metrics
            metrics_name = pc.metrics_name
            metrics_len  = pc.metrics_len
            size_factor  = 4 / (1024 * 1024)
            x_label = "Size of the message payload (MBs)"
        else:
            metrics      = pc.metrics_po
            metrics_name = pc.metrics_po_name
            metrics_len  = pc.metrics_po_len
            size_factor  = 4 / 1024
            x_label = "Size of the message payload (KBs)"

        for t_period in pc.task_period:

            #  sampled_matrices [metric_id] [payload_size] [samples_number]
            #  sampled_matrices    = array_of_sampled_matrices [e_n]

            #  Generate labels and covert the payload in MB
            #  x_values = [*range (1, pc.payload_len + 1)]
            #  x_ticks = ["{:.1f}".format(size * size_factor) for size in pc.payload_size[e_id]]
            x_values = [1, 2, 3, 4, 5]
            x_ticks  = ["0.0", "0.11", "0.33", "0.55", "1.0"]
            y_label  = "Measured execution time (microseconds)"

            path_to_data = os.path.join (pc.path_to_exp [e_id], pc.data_folder_name)

            for m_i in range (metrics_len):
                data_file_name    = "_".join ([metrics [m_i], "period", str (int (t_period / 1000))]) + ".txt"
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
                        #  Turn a string of ms into a float of micros
                        array_float.append (float (s) * 1000)
                    sampled_matrix.append (array_float)

                selected_samples = [sampled_matrix[0],
                                    sampled_matrix[1],
                                    sampled_matrix[3],
                                    sampled_matrix[5],
                                    sampled_matrix[9]]

                plt.clf ()
                plt.boxplot (selected_samples, sym='.')
                plt.xticks  (x_values, x_ticks)
                plt.xlabel  (x_label)
                plt.ylabel  (y_label)
                plt.title   (metrics_name [metrics [m_i]])
                prefix          = "_".join([e_id, "box", metrics [m_i], str (int (t_period / 1000))]) + ".png"
                path_to_diagram = os.path.join (pc.path_to_graphs, "box", prefix)
                plt.savefig (path_to_diagram)

def generatePlotDiagrams ():
    """
    Draw the plot diagram for each experiment
    """

    for e_n in range (pc.experiments_number):

        e_id = pc.experiment_id [e_n]

        if e_id in ["1_1", "1_2"]:
            metrics      = pc.metrics
            metrics_name = pc.metrics_name
            metrics_len  = pc.metrics_len
            size_factor  = 4 / (1048 * 1048)
            x_label = "Size of the message payload (MBs)"
        else:
            metrics      = pc.metrics_po
            metrics_name = pc.metrics_po_name
            metrics_len  = pc.metrics_po_len
            size_factor  = 4 / 1024
            x_label = "Size of the message payload (KBs)"

        for t_period in pc.task_period:

            #  sampled_matrices [metric_id] [payload_size] [samples_number]
            #  sampled_matrices    = array_of_sampled_matrices [e_n]

            #  Generate labels and covert the payload in MB
            x_values = [*range (1, pc.payload_len + 1)]
            x_ticks  = ["{:.1f}".format (size * size_factor) for size in pc.payload_size [e_id]]
            y_label  = "Measured execution time (microseconds)"

            path_to_data = os.path.join (pc.path_to_exp [e_id], pc.data_folder_name)

            for m_i in range (metrics_len):
                data_file_name    = "_".join ([metrics [m_i], "period", str (int (t_period / 1000))]) + ".txt"
                path_to_data_file = os.path.join (path_to_data, data_file_name)
                file              = open (path_to_data_file, 'r')
                lines             = file.readlines ()
                file.close ()

                #  The data file contains the sampled values, each
                #  line refers to a single payload size value
                sampled_matrix = []
                maximum_array  = []
                median_array   = []
                minimum_array  = []

                for l_i in range (len (lines)):
                    array_float = []
                    array_str   = lines [l_i].split (" ")
                    for s in array_str:
                        #  Turn a string of ms into a float of micros
                        array_float.append (float (s) * 1000)
                    sampled_matrix.append (array_float)

                for p_i in range (pc.payload_len):
                    maximum_array.append (max (sampled_matrix [p_i]))
                    median_array.append  (statistics.median (sampled_matrix [p_i]))
                    minimum_array.append (min (sampled_matrix [p_i]))

                plt.clf ()
                plt.plot (x_values, maximum_array, color='blue',   label='Maximum time')
                plt.plot (x_values, median_array,  color='orange', label='Median time')
                plt.plot (x_values, minimum_array, color='green',  label='Minimum time')
                plt.xticks  (x_values, x_ticks)
                plt.xlabel  (x_label)
                plt.ylabel  (y_label)
                plt.title   (metrics_name [metrics [m_i]])
                plt.legend ()
                prefix          = "_".join([e_id, "plot", metrics [m_i], str (int (t_period / 1000))]) + ".png"
                path_to_diagram = os.path.join (pc.path_to_graphs, "plot", prefix)
                plt.savefig (path_to_diagram)


def computeStatisticalSignificance (alpha):
    """
    """
    #  The results are written inside a file, each line as:
    #  e_id t_period m_i ( lower , upper ) delta
    significance_file = "significance_" + (str (alpha)).replace (".", "") + ".txt"
    path_to_sig_file  = os.path.join (pc.path_to_significance, significance_file)
    results           = []
    for e_n in range (pc.experiments_number):

        e_id = pc.experiment_id [e_n]

        if e_id in ["1_1", "1_2"]:
            metrics      = pc.metrics
            metrics_name = pc.metrics_name
            metrics_len  = pc.metrics_len
        else:
            metrics      = pc.metrics_po
            metrics_name = pc.metrics_po_name
            metrics_len  = pc.metrics_po_len

        for t_period in pc.task_period:

            path_to_data = os.path.join (pc.path_to_exp [e_id], pc.data_folder_name)

            for m_i in range (metrics_len):

                data_file_name    = "_".join ([metrics [m_i], "period", str (int (t_period / 1000))]) + ".txt"
                path_to_data_file = os.path.join (path_to_data, data_file_name)
                file              = open (path_to_data_file, 'r')
                lines             = file.readlines ()
                samples           = []
                file.close ()

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
                #  expressed in microseconds
                lower    = sorted_samples [lower_i] * 1000
                upper    = sorted_samples [upper_i] * 1000
                line     = " ".join ([str (e_id), str (t_period), str (m_i)])
                line    += (" ( " + "{:.3f}".format (lower) + ", " + "{:.3f}".format (upper) + " )")
                line    += " {:.3f}".format (upper - lower)
                results.append (line + '\n')

    file = open (path_to_sig_file, 'w')
    file.writelines (results)
    file.close ()


def generateStatisticalSignificanceDiagram ():
    """
    """
    #  Load from the significance files
    alpha_list = ["05", "005", "0005"]

    measures = {
        alpha_list [0] : [],
        alpha_list [1] : [],
        alpha_list [2] : []
    }

    for alpha in alpha_list:
        significance_file   = "significance_" + alpha + ".txt"
        path_to_sig_file    = os.path.join(pc.path_to_significance, significance_file)
        file                = open (path_to_sig_file, 'r')
        lines               = file.readlines ()
        significance_matrix = [line.split (" ") for line in lines]

        #  Select just the lines from experiment 1 and 2
        significance_matrix = [line for line in significance_matrix if line [0] != "2_1"]

        #  Extract the send and release metrics
        measures_array = []
        for i in range (len (significance_matrix)):
            metric = int (significance_matrix[i] [2])
            if metric == 2 or metric == 3:
                measures_array.append (float (significance_matrix [i] [7]))

        #  Prepare the data to be plotted
        m_max    = max (measures_array)
        m_median = statistics.median (measures_array)
        m_min    = min (measures_array)

        #  Load the results
        measures [alpha] = [m_min, m_median, m_max]

    #  Plot the diagram
    #  x_min    = [measure [0] for measure in measures]
    #  x_median = [measure [1] for measure in measures]
    #  x_max    = [measure [2] for measure in measures]

    bar_width = 0.25
    br1       = [0, 1, 2]
    br2       = [x + bar_width for x in br1]
    br3       = [x + bar_width for x in br2]

    diagram_name      = "significance.png"
    path_to_send_file = os.path.join (pc.path_to_significance, diagram_name)
    plt.clf ()
    plt.bar (br1, measures ["05"], color='r', width=bar_width, label='alpha = 0.5')
    plt.bar (br2, measures ["005"], color='b', width=bar_width, label='alpha = 0.05')
    plt.bar (br3, measures ["0005"], color='g', width=bar_width, label='alpha = 0.005')

    plt.xticks ([r + bar_width for r in range (3)], ['min', 'median', 'max'])
    plt.ylabel ('Interval width (microseconds)', fontweight ='bold')
    plt.legend ()
    plt.savefig (path_to_send_file)


def generateStatisticalSignificanceDiagram ():
    """
    """
    #  Load from the significance files
    alpha_list = ["05", "005", "0005"]

    measures = {
        alpha_list [0] : [],
        alpha_list [1] : [],
        alpha_list [2] : []
    }

    for alpha in alpha_list:
        significance_file   = "significance_" + alpha + ".txt"
        path_to_sig_file    = os.path.join(pc.path_to_significance, significance_file)
        file                = open (path_to_sig_file, 'r')
        lines               = file.readlines ()
        significance_matrix = [line.split (" ") for line in lines]

        #  Select just the lines from experiment 1 and 2
        significance_matrix = [line for line in significance_matrix if line [0] != "2_1"]

        #  Extract the send and release metrics
        measures_array = []
        for i in range (len (significance_matrix)):
            metric = int (significance_matrix[i] [2])
            if metric == 2 or metric == 3:
                measures_array.append (float (significance_matrix [i] [7]))

        #  Prepare the data to be plotted
        m_max    = max (measures_array)
        m_median = statistics.median (measures_array)
        m_min    = min (measures_array)

        #  Load the results
        measures [alpha] = [m_min, m_median, m_max]

    #  Plot the diagram
    #  x_min    = [measure [0] for measure in measures]
    #  x_median = [measure [1] for measure in measures]
    #  x_max    = [measure [2] for measure in measures]

    bar_width = 0.25
    br1       = [0, 1, 2]
    br2       = [x + bar_width for x in br1]
    br3       = [x + bar_width for x in br2]

    diagram_name      = "significance.png"
    path_to_send_file = os.path.join (pc.path_to_significance, diagram_name)
    plt.clf ()
    plt.bar (br1, measures ["05"], color='r', width=bar_width, label='alpha = 0.5')
    plt.bar (br2, measures ["005"], color='b', width=bar_width, label='alpha = 0.05')
    plt.bar (br3, measures ["0005"], color='g', width=bar_width, label='alpha = 0.005')

    plt.xticks ([r + bar_width for r in range (3)], ['min', 'median', 'max'])
    plt.ylabel ('Interval width (microseconds)', fontweight ='bold')
    plt.legend ()
    plt.savefig (path_to_send_file)
