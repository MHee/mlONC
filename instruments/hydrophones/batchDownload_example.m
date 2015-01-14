%% ONC Access token
% You have to fill in your ONC webservice token below!!!
%
% create a vaild token at https://dmas.uvic.ca/Profile 
% in the  "Web Services API" tab
token='??????-?????-?????-?????-??????';% ???????;

%% Intialize the webservice interface
af=archivefiles(token);
af.log.setCommandWindowLevel(af.log.INFO);

%% Get a list of files 

% The time constraints are optional, but a full list of hydrophone filese
% can get very long!
af.getList('station','AP.HYDLF','deviceCategory','HYDROPHONE',...
                'dateFrom','2014-02-15T01:00:00.000Z',...
                'dateTo','2014-02-15T02:00:00.000Z')

% Print the meta date for the first three files in the list            
af.fileList{1:3}            

%% Download files

% Download files into local directory.
%  * The directory has to exist
%  * The dataProductFormatId filter is optional. 
%      8 is for .wav files and all other filetypes as spectrogram plots are skipped.
%  * Files that already exist in the directory are skipped
af.saveListedFiles('outDir','./data','dataProductFormatId',8);

%% Clean up once you are done with the service
% af.delete