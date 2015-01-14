function [Opts, unused]=ParseFunOpts(Opts,varargin)
%PARSEFUNOPTS Parses Parameter Value pairs as input for matlab functions
%
% Opts is a structure that contains the default values of ALL valid
% parameter (names) and varargin is the varargin of the calling function.
% Within this function tests are performed wether the input parameters have
% valid names and default values are replaced by the corresponding
% parameter values.
%
% If output parameter unused is specified, all parameters that are not
% known are returned in unused and no warning is raised.

% Martin Heesemann 22.05.2006

% Return undefined options ?
if nargout == 2
    unused={};
    ReturnUnused=1;
else
    ReturnUnused=0;
end

varargin=varargin{1}; % Get the varargin of the calling function
if isempty(varargin)
    % Nothing to do
    return
end

if isstruct(varargin)
    InStruct=varargin;
    Fields=fieldnames(InStruct);
    varargin={};
    for i = 1:length(Fields)
        varargin{2*i-1}= Fields{i};
        varargin{2*i}  = InStruct.(Fields{i});
    end
end
        


N=length(varargin)/2; % Number of parameter value pairs


if mod(N,1) % Is odd?
    if ReturnUnused
        % First value may be without parameter name (e.g. plot command)
        unused=varargin(1);
        varargin=varargin(2:end);
        N=length(varargin)/2;
    else
        error('Number of input parameters and values do not match!!!');
    end
end

% Get Parameter Names and Values
PNames=varargin(1:2:2*N);
PVals=varargin(2:2:2*N+1);

FoundInvalidParam=false;
for i=1:N
    if isfield(Opts,PNames(i))
        Opts.(PNames{i})=PVals{i};
    else
        if ReturnUnused
            % Return undefined options
            unused={unused{:} PNames{i} PVals{i}};
        else
            warning([PNames{i} ' is not a valid parameter name!!!']);
            FoundInvalidParam=true;
        end
    end
end

if FoundInvalidParam
    fprintf('List of valid parameter names:\n');
    disp(fieldnames(Opts));
end