function img = mandelbrot_sequential(cols, rows, max_iterations, cmap)
    % The area of the complex plane to calculate for.
    x_min = -2.0;
    x_max = 0.5;
    y_min = -1.2;
    y_max = 1.2;

    % Initialize the resulting image (avoids resizing).
    img = zeros(rows, cols, 3);

    % --------------- Mandelbrot image calculations --------------- %

    % loop over each row
    for row = 0:(rows - 1)
        % initialize the iterations vector
        iterations = zeros(1, cols);

        % loop over each pixel in the row
        for col = 0:(cols - 1)
            % perform the mandelbrot divergence calculation

            % map the pixel to the right spot in the imaginary plan
            x0 = col / (cols - 1) * (x_max - x_min) + x_min;
            % `imwrite`/`imshow` plot higher rows as lower in the image, so
            % we flip the calculated value here.
            y0 = y_max - row / (rows - 1) * (y_max - y_min);
            
            x = 0;
            y = 0;
            iteration = 0;
            while (iteration < max_iterations && x * x + y * y <= 4)
                x_next = x * x - y * y + x0;
                y_next = 2 * x * y + y0;
        
                iteration = iteration + 1;
        
                x = x_next;
                y = y_next; 
            end
    
            iterations(1, col+1) = iteration;
        end
    
        % Map the iterations to colours using our colour map and set the
        % image pixels.
        img(row+1, :, :) = ind2rgb(iterations, cmap);
    end
end
