%% Check Matlab Path
% The webservices folder of the mlONC toolbox has to be on the Matlab path.
% Add it to the path if we cannot find the archivefile class...
% if ~exist('archivefiles','class')
%     toolbox_path=fullfile(fileparts(mfilename('fullpath')),'../../webservices');
%     addpath(genpath(toolbox_path));
% end

%% Connect to ONC and intialize the webservice interface
% During first connect you will have to fill in your ONC webservice token.
%
% Create a vaild token at https://dmas.uvic.ca/Profile 
% in the  "Web Services API" tab.
%
% The token will be saved on disk for later use. 
af=archivefiles();
af.log.setCommandWindowLevel(af.log.INFO);

%% Get a list of files 
% The time constraints are optional, but a full list of hydrophone files
% can get very long!
%
% The station and deviceCategory codes can be expored using the DataSearch
% interface (they are part of the URL). E.g. have a look at
% http://dmas.uvic.ca/home?location=NC27.H1&deviceCategory=HYDROPHONE

af.getList('station','NC27.H2','deviceCategory','HYDROPHONE',...
                'dateFrom','2013-02-15T00:00:00.000Z')

% af.getList('station','NC27.H2','deviceCategory','HYDROPHONE',...
%                 'dateFrom','2014-02-15T00:00:00.000Z',...
%                 'dateTo','2014-02-17T02:00:00.000Z');

%% Remove everything but .wav files from list of files           

fileList=[af.fileList{:}];
isWave=zeros(size(fileList));
for i=1:length(isWave)
    if fileList(i).dataProductFormatId == 8
        isWave(i)=1;
    end
end
af.fileList=af.fileList(logical(isWave));


%% Decimate numbers of files
% Only use files that are closest to certain fractions of a day

% dayFrac=24; gets the files that are closest to every full hour of a day
dayFrac=24; 

% Get a vector of file starttimes, and respective file indces
fileList=[af.fileList{:}];
t=datenum({fileList.dateFrom},'yyyy-mm-ddTHH:MM:SS.FFF');
idx=1:length(t);

% Make sure times and indices are sorted by increasing times (requirement
% for interpolation
[t,sortIdx]=sort(t);
idx=idx(sortIdx);

% Create a vector of times at which I would like to have a file
tWish=floor(t(1)):1/dayFrac:ceil(t(end));

% Create file indeces of the files the are closest to the desired times
wishIdx=interp1(t,idx,tWish,'nearest');

% Create plot comparing all available files to the files I want to get
figure(gcf);
clf;
plot(t,idx,'.-')
hold on
plot(tWish,wishIdx,'ro');
datetick('x');

% Clean up and store decimated list of files for later downloading
wishIdx=wishIdx(isfinite(wishIdx)); % Kick out NaNs resulting from extrapolation
wishIdx=unique(wishIdx); % remove doubles
af.fileList=af.fileList(wishIdx);

%% Compute download size
fileList=[af.fileList{:}];
fprintf('Will download %d files amounting to about %.1f MB of HDD space\n',...
    length(fileList),sum([fileList.uncompressedFileSize])*1e-6);

%% Download files
% Download files into local directory.
%  * The directory (e.g. ./data) 
%  * The dataProductFormatId filter is optional. 
%      8 is for .wav files and all other filetypes as spectrogram plots are skipped.
%  * Files that already exist in the directory are skipped
%  * Subdirectories for station, year and day of year will be generated on
%    the fly...  e.g.  .\data\NC27.H2_HYDROPHONE\2013\189
af.saveListedFiles('outDir','./data','dataProductFormatId',8);

%% Clean up once you are done with the service
af.delete