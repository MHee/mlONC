classdef archivefiles < handle
% archivefiles A class that uses the ONC archivefile webservice
%   Documentation on the webservice can be found at 
%   http://wiki.neptunecanada.ca/display/help/archivefiles
%
%   To use the service you have to create a vaild token at
%   https://dmas.uvic.ca/Profile in the  "Web Services API" tab
    properties
        fileList=[];
        fileListStation='';
        fileListDeviceCategory='';
        log=log4m.getLogger('archivefiles.log');
        url='http://dmas.uvic.ca/api/archivefiles';
        Opts=struct(...
                'token','',...
                'station','AP.HYDLF',...
                'deviceCategory','HYDROPHONE',...
                'dateFrom','2014-02-15T00:00:00.000Z',...
                'dateTo','2014-02-15T01:00:00.000Z');
    end
    methods
        function self=archivefiles(varargin) % token,
            % creates archivefiles service object
            self.Opts=ParseFunOpts(self.Opts,varargin);
            self.log.setCommandWindowLevel(self.log.INFO);
            self.log.info('archivefiles','webservice interface setup');
            if isempty(self.Opts.token)
                self.log.debug('archivefiles','User did not provide token');
                self.getToken()
            end
        end
        function getList(self,varargin)
            %disp(self.url);
            % Set defaults
            getListParams.token='';
            getListParams.station='';
            getListParams.deviceCategory='';
            getListParams.dateFrom='';
            getListParams.dateTo='';
            % apply service defaults
            [getListParams,otherParams]=ParseFunOpts(getListParams,self.Opts);
            % apply function parameters
            [getListParams,otherParams]=ParseFunOpts(getListParams,varargin);
 
            getListParams.method='getList';
            getListParams.returnOptions='all';
            
            self.fileListStation=getListParams.station;
            self.fileListDeviceCategory=getListParams.deviceCategory;
            
            params=struct2nameVal(getListParams);
            %params={'method','getList','token',self.token,params{:},'returnOptions','all'};
            self.log.debug('getList',nameVal2str(params))
            self.log.info('getList','Getting file list...')
            url=[self.url '?' http_paramsToString(params)];
            [fileList, resp]=urlread2(url);
            if resp.isGood
                self.log.info('getList','Parsing JSON into fileList');
                self.fileList=parse_json(fileList);
                self.log.info('getList',sprintf('Got list of %d files.',length(self.fileList)));
            else
                errMsg=sprintf('%d : %s -- Could not get fileList from server',...
                            resp.status.value,resp.status.msg);
                self.log.error('getList',errMsg);
                self.log.info('getList',fileList);
                warning(errMsg);
                self.fileList={};
            end
            %disp(status)
        end
        function getToken(self)
            tokenFile=fullfile(fileparts(mfilename('fullpath')),'../../mlONC.cfg');
            if exist(tokenFile,'file')
                self.log.debug('archivefiles',['Found: ', tokenFile]);
                JSON_string=fileread(tokenFile);
                Info=parse_json(JSON_string);
                self.Opts.token=Info.token;
            else
                web('https://dmas.uvic.ca/Profile','-browser');
                self.Opts.token = char(inputdlg(...
                    ['Enter your Web Services API token! ',...
                     'It is available at https://dmas.uvic.ca/Profile ',...
                     'and has the form of ????????-????-????-????-????????????'],'Get User Token'));
                fid=fopen(tokenFile,'w');
                fprintf(fid,'{"token":"%s","version":"1.0.0.0"}\n',self.Opts.token);
                fclose(fid);
            end
        end
        function saveListedFiles(self,varargin)
            if isempty(self.fileList)
                warning('No files in list, call .getList() first!')
                return
            end
                        
            saveFilesParams.token='';
            % apply service defaults
            [saveFilesParams,otherParams]=ParseFunOpts(saveFilesParams,self.Opts);
            % apply function parameters
            [saveFilesParams,otherParams]=ParseFunOpts(saveFilesParams,varargin);
 
            saveFilesParams.method='getFile';            
            params=struct2nameVal(saveFilesParams);
            self.log.debug('saveListedFiles',nameVal2str(params));
            
            funOpts.dataProductFormatId=0;   % Do not filter on data product
            funOpts.outDir='./data';
            funOpts=ParseFunOpts(funOpts,otherParams);
           
            if ~exist(funOpts.outDir,'dir')
                warning('Output directory %s does not exist!',funOpts.outDir);
                self.log.info('saveListedFiles',...
                            sprintf('Creating %s',funOpts.outDir));
                mkdir(funOpts.outDir);
            end 
            
            for i =1:length(self.fileList)
                if funOpts.dataProductFormatId &&...
                        (isempty(self.fileList{i}.dataProductFormatId) || ...
                        funOpts.dataProductFormatId ~= self.fileList{i}.dataProductFormatId)
                    self.log.debug('saveListedFiles',...
                        sprintf('Skipping %s -- wrong format (%d)',self.fileList{i}.filename,...
                        self.fileList{i}.dataProductFormatId));
                    continue;
                else
                    tOut=datenum(self.fileList{i}.dateFrom,'yyyy-mm-ddTHH:MM:SS.FFF');
                    [yearOut,dayOut]=datenum2YearDay(tOut);
                    outDir=fullfile(funOpts.outDir,...
                                    sprintf('%s.%s',self.fileListStation,self.fileListDeviceCategory),...
                                    yearOut,dayOut);
                    if ~exist(outDir,'dir')
                        self.log.info('saveListedFiles',...
                            sprintf('Creating %s',outDir));
                        mkdir(outDir);
                    end
                    outFile=fullfile(outDir,self.fileList{i}.filename);
                    if exist(outFile,'file');
                        self.log.info('saveListedFiles',...
                            sprintf('Skipping %s -- it already exists',self.fileList{i}.filename));
                    else
                        self.log.info('saveListedFiles',...
                            sprintf('Downloading %s',self.fileList{i}.filename));
                        
                        attempts=0;
                        while (attempts < 12)
                            attempts=attempts+1;
                            try
                                [theFile,status]=urlwrite(self.url,outFile,...
                                    'get',{params{:},'filename',self.fileList{i}.filename},...
                                    'Timeout',10.);
                                if status
                                    % File successfull written
                                    break;
                                end
                            catch
                                self.log.info('saveListedFiles',...
                                    'Something bad occured...');
                            end
                            tWait=2^attempts;
                            self.log.info('saveListedFiles',...
                                sprintf('Download failed, trying again in %d seconds!',tWait));
                            pause(tWait);
                        end
                        if attempts == 12
                            msg=sprintf('Tried 12 times to download %s... giving up',theFile);
                            warning(msg);
                            self.log.info('saveListedFiles',msg);
                        end
                    end
                end
            end
        end
    end % methods
end % classdef

function outStr=nameVal2str(inCell)
    outStr='';
    %disp(inCell);
    for i=1:2:length(inCell)
        outStr=[outStr, inCell{i}, '=', char(inCell{i+1}), '; '];
    end
end
function outCell=struct2nameVal(inStruct)
    cnt=1;
    names=fieldnames(inStruct);
    outCell={};
    for i = 1:length(names)
        fieldName=names{i};
        %disp(fieldName);
        outCell{2*cnt-1}=fieldName;
        %disp(outCell)
        outCell{2*cnt}=inStruct.(fieldName);
        cnt=cnt+1;
        %disp(outCell)
    end  
end

%%
function [year,day]=datenum2YearDay(t)
    year=datestr(t,'yyyy');
    day=sprintf('%03d',floor(t-datenum(year,'yyyy'))+1);
end
