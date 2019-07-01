function [ zone_num ] = Zone_let2num( Zone_letter )
%Zone_let2num takes an array of NYISO zone letters and converts them to
%integers.
%   Zone_letter must be a cell array.
%   Example usage:
%       Zone_num = Zone_let2num({'A'});

%Map zone letters to numbers
keySet = {'A','B','C','D','E','F','G','H','I','J','K'};
valueSet = (1:length(keySet))';
mapObj = containers.Map(keySet,valueSet);

zone_num = zeros(length(Zone_letter),1);
for i = 1:length(Zone_letter)
    if Zone_letter{i} ~= 0
        zone_num(i) = mapObj(Zone_letter{i});
    else
        zone_num(i) = 0;
    end
end

end

