function cleaned_data = pupilclean(ldil, z)
% PUPIL CLEAN    Clean pupil data with  blinks.
% Argument 1 = your pupil data vector (either diameter, or X,Y coordinate)
% Argument 2 = a z-score used to eliminate unusual points in data. Low
% z-score to exclude much of the data, high z-score to exclude only the most
% unusual data.
% By M. Kabir, reach out for help/bugfixing at kabir.naim@gmail.com

    %Setting standard z-score above which to eliminate data
    if nargin <2
        z = 3;
    end
    
    %Making sure data is presented as a row
    orientation = size(ldil);
    
    if orientation(2) > orientation(1)
        ldil = ldil';
    end
    
    %Logically indexing places where the Tobii eyetracker tells you there
    %is bad data (anywhere there's a -1)
    negs = ldil <= 0; %find where validity code is bad

    %Find places where the derivative of the dilation is suspiciously large
    deriv = [0; abs(diff(ldil))];
    threshold = mean(deriv) + z*std(deriv); %set threshold above which things are disincluded
    bad_idx = deriv > threshold;
    bad_idx = bad_idx + negs; bad_idx = bad_idx > 0;

    idx = find(~bad_idx); %get good data indices

    %Interpolate areas where there is bad data, using non-bad data as the
    %interpolation function. idx designates the indices of values looked at in
    %the 'function' ldil(idx), in order to fill in query points provided by 
    %find(negs) 
    ldil(bad_idx) = interp1(idx, ldil(idx), find(bad_idx));
    
    %Deal with any NaNs from interpolation, substitute with signal mean
    nans = isnan(ldil);
    averaged = mean(ldil(~nans));
    ldil(nans) = ones(1, length(ldil(nans)))*averaged;
    
    cleaned_data = ldil;
end
    

