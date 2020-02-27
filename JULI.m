% Launch LOBSTER server to monitor a folder and process jobs copied to this folder.
% Errors are reported to LogFile (job crash, no dst email defined, error launching email, file writing permission).
%
% JULI(MonitoredFolder, PathToLogFile, SourceEmail, SourceEmailPassword);
%
% If SourceEmail + SourceEmailPassword are not set to '' then a report email is sent
% to Dstmail upon job completion (Dstmail must then be defined in job).
%
% Sample calls:
% JULI('E:/LOBSTER_sandbox/Jobs','E:/LOBSTER_sandbox/Logs/Errorlog.txt');
% JULI('E:/LOBSTER_sandbox/Jobs','E:/LOBSTER_sandbox/Logs/Errorlog.txt','user@gmail.com','userpassword');

function JULI(MonitoredFolder,ErrorLogFile,sourcemail,password)

    %% Check that imtool3D is in path (init has been performed)
    if ~exist('imtool3D')
        error('LOBSTER has not been initialized yet, type >> init');
    else
        %% Force path to LOBSTER root on startup
        str = which('init');
        indxs = find((str=='/')|(str=='\'));
        cd(str(1:indxs(end)));
    end

    %% Parse arguments
    if nargin < 2
        error('JULI requires at least 2 arguments');
	end
    if nargin == 2
        sourcemail = '';
        password = '';
    end

    %% Initialize variables
    MaxFileQueue = 1;
    JobAlreadyProcessed = cell(1);
    cntsuccess = 0;
    cnterror = 0;
    cntioerror = 0;
    cntemail = 0;
    
    %% Create subfolders if not existing
    if ~exist([MonitoredFolder '/Queue/'],'file')
        mkdir([MonitoredFolder '/Queue/']);
    end
    if ~exist([MonitoredFolder '/Error/'],'file')
        mkdir([MonitoredFolder '/Error/']);
    end
    if ~exist([MonitoredFolder '/Success/'],'file')
        mkdir([MonitoredFolder '/Success/']);
    end
        
    t1 = clock;
    while 1
        
        try
        
		disp(['Monitored job folder: ' MonitoredFolder ' (copy jobs to process)']);
		disp(['Error log file: ' ErrorLogFile]);
		disp(['Source email: ' sourcemail]);
		
        %% Read file names of all jobs currently in folder
        files = dir([MonitoredFolder '/*.m']);
        %% Randomize file name to avoid alphabetical priority
        files = files(randperm(length(files)));
        files = files(1:min(MaxFileQueue,numel(files)));
        
        %% Move jobs to QueueFolder
        for i = 1:numel(files)
            movefile([MonitoredFolder '/' files(i).name],[MonitoredFolder '/Queue/' files(i).name]);
        end
        
        %% Process queue        
        for i = 1:numel(files)
            filename = files(i).name;
            %% Used to avoid infinitely processing a file that cannot be moved
            if(~any(strcmp(JobAlreadyProcessed,filename)))
                [filepath,name,ext] = fileparts(filename);
                %% Reset Dstmail and ReportFolder
                clear Dstmail;
                ReportFolder = '';
                %% Lauch job
                eval(fileread([MonitoredFolder '/Queue/' files(i).name]));
                %% Send email if variable Dstmail exists and sourcemail is set
                if exist('Dstmail','var') && ~isempty(sourcemail)
                    Topic = 'LOBSTER job success';
                    Text = sprintf('Job: %s success.',files(i).name);
                    %% Add attachment if variable ReportFolder exists
                    if ~isempty(AttachmentFolder)
                        zip([MonitoredFolder '/Results.zip'],AttachmentFolder);
                        Attach = [MonitoredFolder '/Results.zip'];
                        Send_email(Dstmail,Topic,Text,Attach,sourcemail,password);
                        cntemail = cntemail+1;
                        delete(Attach);
                    else
                        Send_email(Dstmail,Topic,Text,'',sourcemail,pasword);
                        cntemail = cntemail+1;
                    end
                end
                %% Move job to success subfolder
                movefile([MonitoredFolder '/Queue/' files(i).name],[MonitoredFolder '/Success/' files(i).name]);
                %% Add job name to processed list
                JobAlreadyProcessed{1+cntsuccess+cnterror+cntioerror} = files(i).name;
                %% If we get there no error was triggered
                cntsuccess = cntsuccess + 1;
            end
        end
        pause(1);
        clc;
        if ~isempty(sourcemail)
            disp(sprintf('Job success: %i   Job error: %i   I/O error: %i  Emails sent: %i',cntsuccess,cnterror,cntioerror,cntemail));
        else
            disp(sprintf('Job success: %i   Job error: %i   I/O error: %i',cntsuccess,cnterror,cntioerror));
        end
        [userview,systemview] = memory;
        disp(sprintf('Memory available: %f GB',userview.MemAvailableAllArrays/(1024*1024*1024)));
        disp(sprintf('Server up for: %i s',round(etime(clock,t1))));
        disp('Waiting for new job to process...');
    
        %% Display error message but do not stop execution
        catch me
            try
                resultsfile = [MonitoredFolder '/Results.zip'];
                if exist(resultsfile,'file')
                    delete(resultsfile);
                end
                Text = strcat([sprintf('Job: %s job error at %s\n',files(i).name,datestr(datetime('now'))) getReport( me, 'extended', 'hyperlinks', 'off' )]);
                movefile([MonitoredFolder '/Queue/' files(i).name],[MonitoredFolder '/Error/' files(i).name]);
                fid = fopen(ErrorLogFile, 'a');
                fprintf(fid, Text);
                fclose(fid);
                if exist('Dstmail','var') && ~isempty(sourcemail)
                    Topic = 'LOBSTER job error';
                    Send_email(Dstmail,Topic,Text,'',sourcemail,password);
                    cntemail = cntemail+1;
                end
                JobAlreadyProcessed{1+cntsuccess+cnterror+cntioerror} = files(i).name;
                cnterror = cnterror + 1;
            catch me2
                %% Critical error (cannot send email or move job file)
                JobAlreadyProcessed{1+cntsuccess+cnterror+cntioerror} = files(i).name; 
                Text = strcat([sprintf('Job: %s I/O error at %s\n',files(i).name,datestr(datetime('now'))) getReport( me2, 'extended', 'hyperlinks', 'off' )]);
                fid = fopen(ErrorLogFile, 'a');
                fprintf(fid, Text);
                fclose(fid);
                cntioerror = cntioerror + 1;
            end          
        end
    end 
end