% =========================================================================
% Practical 2: Mandelbrot-Set Serial vs Parallel Analysis
% =========================================================================
%
% GROUP NUMBER: 8
%
% MEMBERS:
%   - Shaun Beautement, BTMSHA001
%   - Neo Vorsatz, VRSNEO001

% Creates a colour map for Mandelbrot iterations->RGB colours.
% This is generated separately to decrease sequential overhead.
%
% `bands` controls how many "teeth" there are in a sawtooth mapping
% between the iterations and the colour.
% Setting this to 1 means that iterations are normally colour-mapped.
% Setting this greater than 1
function cmap = colour_map(max_iterations, bands)
    % Check that bands is a nonzero natural number.
    if ~(isscalar(bands) && bands == floor(bands) && bands >= 1)
        disp("Invalid number of bands. Must be a nonzero natural number.")
        exit(1)
    end

    % hot: maps from black to white through red, orange, and yellow
    % flip: higher iterations should get a darker colour
    % repmat: repeat the mapping if multiple bands are desired
    cmap = repmat(flip(hot(ceil(max_iterations / bands))), bands, 1);
    % Ensure the non-divergent case is black.
    % Idiomatic for dispalying the Mandelbrot set.
    cmap(max_iterations, :) = [0; 0; 0];
end