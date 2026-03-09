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
    %save the plot (matrix of 1s and 0s) to the given filepath
    imwrite(plot, filepath);
end

%% ========================================================================
%  PART 2: Serial Mandelbrot Set Computation
%  ========================================================================`
%
%TODO: Implement serial Mandelbrot set computation function
% function mandelbrot_serial(varargin) %Add necessary input arguments 
% 
% end

% Neo's recommended function header:
% function plot = mandelbrot_parallel(width, height, max_iterations)
% "plot" is a matrix of the coordinates, where 1 means "in the set", and 0
% means otherwise (please use integers).
% the "width" and "height" count pixels
% "max_iterations" is self-explanatory
function plot = mandelbrot_serial(width, height, max_iterations) %test function
    plot = zeros(height,width);
    for i = 1:height
        for j = 1:width
            if i==j
                if mod(i,32)>=16 & mod(j,32)>=16
                    plot(i,j) = 1;
                end
            else
                if mod(i,32)<16 & mod(j,32)<16
                    plot(i,j) = 1;
                end
            end
        end
    end
end

%% ========================================================================
%  PART 3: Parallel Mandelbrot Set Computation
%  ========================================================================
%
%TODO: Implement parallel Mandelbrot set computation function
% function mandelbrot_parallel(varargin) %Add necessary input arguments 
% 
% end

% Neo's recommended function header:
% function plot = mandelbrot_parallel(width, height, max_iterations)
% "plot" is a matrix of the coordinates, where 1 means "in the set", and 0
% means otherwise (please use integers).
% the "width" and "height" count pixels
% "max_iterations" is self-explanatory
function plot = mandelbrot_parallel(width, height, max_iterations) %test function
    plot = zeros(height,width);
    for i = 1:height
        for j = 1:width
            if mod(i,32)<16 & mod(j,32)<16
                plot(i,j) = 1;
            end
        end
    end
end

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
    ITERATIONS_AVG = 19; %number of iterations used to determine an average
    CORE_COUNTS = [2,4]; %array of the numbers of cores used in parallel processing
    %variables for data
    numImages = length(image_sizes); %number of images to generate
    total_pixels = zeros(numImages,1); %total number of pixels in each image
    time_serial = zeros(numImages,1); %times taken to generate images with serial processing
    time_parallel = zeros(numImages,length(CORE_COUNTS)); %times taken to generate images with parallel processing
    speedup = zeros(numImages,length(CORE_COUNTS)); %speedup for each image, and each number of cores
    diff_pixels = zeros(numImages,1); %number of pixels that vary between the two
    labels = cell(numImages,1); %strings of the different sizes, such as '800x600'
    % create output directories if they don't exist
    if ~exist(serial_images_dir, "dir")
        mkdir(serial_images_dir);
    end
    if ~exist(parallel_images_dir, "dir")
        mkdir(parallel_images_dir);
    end
    % open file to save data
    fileID = fopen(output_file, "w");
    fprintf(fileID, "Image Size, Different Pixels, Serial Time (s)");
    for cores = 1:length(CORE_COUNTS)
        fprintf(fileID, ", Parallel Time [%d] (s), Speedup [%d]", ...
            CORE_COUNTS(cores), CORE_COUNTS(cores));
    end
    fprintf(fileID, "\n");
    
    %TODO: For each image size, perform the following:
    for i = 1:length(image_sizes)
        width = image_sizes(i,1); %width of the image
        height = image_sizes(i,2); %height of the image
        total_pixels(i) = width*height; %total pixels in the image
    %   a. Measure execution time of mandelbrot_serial
        time_serial_iter = zeros(ITERATIONS_AVG,1); %all execution times, which will be averaged
        for j = 1:ITERATIONS_AVG
            tic();
            plot_serial = mandelbrot_serial(width, height, max_iterations);
            time_serial_iter(j) = toc();
        end
        time_serial(i) = mean2(time_serial_iter); %determine average execution time

    %   b. Measure execution time of mandelbrot_parallel
        for cores = 1:length(CORE_COUNTS)
            %create a parallel pool
            poolobj = gcp("nocreate");
            if isempty(poolobj)
                parpool("local", CORE_COUNTS(cores));
            end
            %measure time
            time_parallel_iter = zeros(ITERATIONS_AVG,1);
            for j = 1:ITERATIONS_AVG
                tic();
                plot_parallel = mandelbrot_parallel(width, height, max_iterations);
                time_parallel_iter(j) = toc();
            end
            time_parallel(i, cores) = mean2(time_parallel_iter); %determine average execution time
            %delete the pool
            delete(gcp("nocreate"));
            %calculate speedup
            speedup(i, cores) = mean2(time_serial_iter./time_parallel_iter); %calculate average speedup
        end

    %   c. Store results (image size, time_serial, time_parallel, speedup)
        diff_pixels(i) = sum(xor(plot_serial, plot_parallel), 'all'); %calculate error (number of different pixels)
        labels{i} = strcat(int2str(width),"x",int2str(height)); %create the label for the size
        %record data in the CSV file
        fprintf(fileID, "%s, %e, %.4f", ...
            labels{i}, diff_pixels(i), time_serial(i), time_parallel(i), speedup(i));
        for cores = 1:length(CORE_COUNTS)
            fprintf(fileID, ", %.6f, %.2f", ...
                time_parallel(i,cores), speedup(i,cores));
        end
        fprintf(fileID, "\n");

    %   d. Plot and save the Mandelbrot set images generated by both methods
        filepath = strcat(serial_images_dir,"/serial_",labels{i},".png"); %generate serial filepath
        mandelbrot_plot(plot_serial, filepath); %save serial image
        filepath = strcat(parallel_images_dir, "/parallel_", labels{i},".png"); %generate parallel filepath
        mandelbrot_plot(plot_parallel, filepath); %save parallel image
    end

    % close file
    fclose(fileID);

    % plotting speedup versus image size
    for cores = 1:length(CORE_COUNTS)
        figure;
        plot(total_pixels, speedup(:,cores), '-o', 'LineWidth', 2, 'MarkerSize', 8);
        set(gca, 'XScale', 'log');
        % axis labels and title
        xlabel('Image Dimensions (Total Pixels)');
        ylabel('Speedup Ratio');
        title('Mandelbrot Speedup vs. Image Size');
        grid on;
        % apply image-labels to x-axis
        xticks(total_pixels);
        xticklabels(labels);
    end
end

%run the analysis
run_analysis_();