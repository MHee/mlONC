%% Check Matlab Path
% The webservices folder of the mlONC toolbox has to be on the Matlab path.
% Add it to the path if we cannot find the archivefile class...
if ~exist('archivefiles','class')
    toolbox_path=fullfile(fileparts(mfilename('fullpath')),'../../webservices');
    addpath(genpath(toolbox_path));
end

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
% http://dmas.uvic.ca/home?location=AP.HYDLF&deviceCategory=HYDROPHONE

af.getList('station','AP.HYDLF','deviceCategory','HYDROPHONE',...
                'dateFrom','2014-02-15T01:00:00.000Z',...
                'dateTo','2014-02-15T02:00:00.000Z')

%% Print the meta data for the first three files in the list            
af.fileList{1:3}            

%% Download files

% Download files into local directory.
%  * The directory (e.g. ./data) has to exist
%  * The dataProductFormatId filter is optional. 
%      8 is for .wav files and all other filetypes as spectrogram plots are skipped.
%  * Files that already exist in the directory are skipped
af.saveListedFiles('outDir','./data','dataProductFormatId',8);

%% Clean up once you are done with the service
af.delete