% =========================================================================
% Practical 2: Mandelbrot-Set Serial vs Parallel Analysis
% =========================================================================
%
% GROUP NUMBER: 8
%
% MEMBERS:
%   - Shaun Beautement, BTMSHA001
%   - Neo Vorsatz, VRSNEO001

clear;

global serial_images_dir; %directory where the serial images are saved
global parallel_images_dir; %directory where the parallel images are saved
global output_file; %file with all of the output data
serial_images_dir = "serial_output_images";
parallel_images_dir = "parallel_output_images";
output_file = "analysis_results.csv";

%% ========================================================================
%  PART 1: Mandelbrot Set Image Plotting and Saving
%  ========================================================================
%
% TODO: Implement Mandelbrot set plotting and saving function
function mandelbrot_plot(plot, filepath)
    %save the plot (RGB matrices) to the given filepath
    imwrite(plot, filepath);
end

%% ========================================================================
%  PART 2: Serial Mandelbrot Set Computation
%  ========================================================================`
%
% Defined in mandelbrot_sequential.m

%% ========================================================================
%  PART 3: Parallel Mandelbrot Set Computation
%  ========================================================================
%
% Defined in mandelbrot_parallel.m

%% ========================================================================
%  PART 4: Testing and Analysis
%  ========================================================================
% Compare the performance of serial Mandelbrot set computation
% with parallel Mandelbrot set computation.

function run_analysis_()
    %Array conatining all the image sizes to be tested
    image_sizes = [
        [800,600],   %SVGA
        [1280,720],  %HD
        [1920,1080], %Full HD
        [2048,1080], %2K Cinema
        [2560,1440], %2K QHD
        [3840,2160], %4K UHD
        [5120,2880], %5K
        [7680,4320]  %8K UHD
    ];

    max_iterations = 1000;

    %global variables
    global serial_images_dir; %directory where the serial images are saved
    global parallel_images_dir; %directory where the parallel images are saved
    global output_file; %file with all of the output data
    %constants
    ITERATIONS_AVG = 5; %number of iterations used to determine an average
    CORE_COUNTS = [2,3,4,5,6]; %array of the numbers of cores used in parallel processing
    CMAP = colour_map(max_iterations,5); %generate colour-map
    %variables for data
    numImages = length(image_sizes); %number of images to generate
    widths = zeros(numImages,1); %widths of the images
    heights = zeros(numImages,1); %widths of the images
    plots_serial = cell(numImages,1); %all of the plots generated serially
    mean_time_serial = zeros(numImages,1); %average times taken to generate images with serial processing
    mean_time_parallel = zeros(length(CORE_COUNTS),numImages); %average times taken to generate images with parallel processing
    speedup = zeros(numImages,ITERATIONS_AVG,length(CORE_COUNTS)); %speedup for each image, each number of cores, and each repeated iteration
    diff_pixels = zeros(length(CORE_COUNTS),numImages); %number of pixels that vary between the two
    %generate information about images
    total_pixels = zeros(numImages,1); %total number of pixels in each image
    labels = cell(numImages,1); %strings of the different sizes, such as '800x600'
    for i = 1:numImages
        widths(i,1) = image_sizes(i,1); %width of the image
        heights(i,1) = image_sizes(i,2); %height of the image
        total_pixels(i,1) = widths(i,1)*heights(i,1); %total pixels in the image
        labels{i,1} = strcat(int2str(widths(i,1)),"x",int2str(heights(i,1))); %create the label for the size
    end
    %create output directories if they don't exist
    if ~exist(serial_images_dir, "dir")
        mkdir(serial_images_dir);
    end
    if ~exist(parallel_images_dir, "dir")
        mkdir(parallel_images_dir);
    end
    %feedback
    disp("... completed initialisation");

    %determine time for serial implementation
    time_serial = zeros(numImages, ITERATIONS_AVG); %all execution times, which will be averaged
    for i = 1:numImages
        mandelbrot_sequential(widths(i,1), heights(i,1), max_iterations, CMAP); %cold run
        for j = 1:ITERATIONS_AVG
            tic();
            plots_serial{i,1} = mandelbrot_sequential(widths(i,1), heights(i,1), max_iterations, CMAP);
            time_serial(i,j) = toc();
        end
        mean_time_serial(i,1) = mean(time_serial(i,:)); %determine average execution time
        %save serial plot as image
        filepath = strcat(serial_images_dir,"/serial_",labels{i,1},".png"); %generate serial filepath
        mandelbrot_plot(plots_serial{i,1}, filepath); %save serial image
        %feedback
        disp(strcat("... completed serial testing for size ", labels{i,1}));
    end
    %feedback
    disp("... completed serial testing");

    %determine time for parallel implementation
    for cores = 1:length(CORE_COUNTS) %for each number of cores
        %create a parallel pool
        poolobj = gcp("nocreate");
        if isempty(poolobj)
            parpool("local", CORE_COUNTS(cores));
        end
        %measure time
        for i = 1:numImages
            plot_parallel = mandelbrot_parallel(widths(i,1), heights(i,1), max_iterations, CMAP); %cold run
            time_parallel = zeros(ITERATIONS_AVG,1);
            for j = 1:ITERATIONS_AVG
                tic();
                plot_parallel = mandelbrot_parallel(widths(i,1), heights(i,1), max_iterations, CMAP);
                time_parallel(j,1) = toc();
                %calculate speedup
                speedup(i,j,cores) = time_serial(i,j)/time_parallel(j,1);
            end
            mean_time_parallel(cores,i) = mean2(time_parallel(:,1)); %determine average execution time
            %count differing pixels
            diff_pixels(cores,i) = sum(any(plot_parallel~=plots_serial{i,1}, 3), "all"); %calculate error (number of different pixels)
            %save parallel plot as image
            filepath = strcat(parallel_images_dir, "/parallel_", labels{i},"_",int2str(CORE_COUNTS(cores)),".png"); %generate parallel filepath
            mandelbrot_plot(plot_parallel, filepath); %save parallel image
            %feedback
            disp(strcat("... completed parallel testing for ",int2str(CORE_COUNTS(cores))," cores, size ",labels{i,1}));
        end
        %delete the pool
        delete(gcp("nocreate"));
        %feedback
        disp(strcat("... completed parallel testing for ",int2str(CORE_COUNTS(cores))," cores"));
    end

    %open file to save data
    fileID = fopen(output_file, "w");
    fprintf(fileID, "Image Size, Serial Time (s)");
    for cores = 1:length(CORE_COUNTS)
        fprintf(fileID, ", Different Pixels [%d], Parallel Time [%d] (s), Speedup [%d], Efficiency [%d] (%%)", ...
            CORE_COUNTS(cores), CORE_COUNTS(cores), CORE_COUNTS(cores), CORE_COUNTS(cores));
    end
    fprintf(fileID, "\n");
    %saving data to file
    for i = 1:numImages
        fprintf(fileID, "%s, %.5f", ...
            labels{i,1}, mean_time_serial(i,1));
        for cores = 1:length(CORE_COUNTS)
            mean_speedup = mean2(speedup(i,:,cores));
            efficiency = 100*mean_speedup/CORE_COUNTS(cores);
            fprintf(fileID, ", %e, %.5f, %.5f, %.5f", ...
                diff_pixels(cores,i), mean_time_parallel(cores,i), mean_speedup, efficiency);
        end
        fprintf(fileID, "\n");
    end
    %close file
    fclose(fileID);
    %feedback
    disp("... saved data to file");

    %plotting speedup versus image size
    for cores = 1:length(CORE_COUNTS)
        figure;
        boxplot(transpose(speedup(:,:,cores)),labels);
        %axis labels and title
        xlabel("Image Dimensions");
        ylabel("Speedup Ratio");
        title(strcat("Mandelbrot Speedup vs. Image Size for ", int2str(CORE_COUNTS(cores)), " cores"));
        grid on;
    end
    %plotting speedup versus number of cores
    figure;
    mean_speedup = squeeze(mean(speedup,2));
    hold on
    for i = 1:numImages
        plot(CORE_COUNTS, mean_speedup(i,:), '-o', 'LineWidth', 2, 'MarkerSize', 8);
    end
    hold off
    %axis labels and title
    xlabel('Number of Cores');
    ylabel('Speedup Ratio');
    title('Mandelbrot Speedup vs. Number of Cores');
    legend(labels);
    grid on;
    %feedback
    disp("... plotted data");
end

%run the analysis
run_analysis_();