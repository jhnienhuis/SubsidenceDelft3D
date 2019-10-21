runname = {'ModelRun'};

%vegetation parameters
vegetation_on = 1; %do vegetation
chezy_veg = 10; %chezy parameter for vegetated area
chezy_noveg = 10; %chezy parameter ofr non vegetated area
tcr_veg = 5; %critical tau_s for vegetation
tcr_noveg = 5;
depth_veg = 1;

%concentration parameters
depth_concentration = 1;
sand_conc_table = @(x) (0.002*x.^1.25);

depth_discharge = 1;
discharge_func = @(x) (5-x/10000);


for ii=1:length(runname),
    
    %subsidence parameters
    subsidence_on = 1;
    h0 = 12; %thickness preconsolidation
    sig0 = h0*1650*9.81;

    runsdir=[cd];
    inputdir=[runsdir filesep 'input' filesep];
    runid='bypass';
    sx = 199;
    sy = 92;
    nruns=40;
    
    ero_dep = zeros(sx,sy,nruns);
    t_subsidence = zeros(nruns,1);
    subsidence = zeros(sx,sy,nruns);
    
    for irun=1:nruns
        rundir=[runsdir filesep 'run' num2str(irun,'%0.3i')];
        mkdir(rundir);
        copyfile([inputdir '*.*'],rundir);
        if irun==1
            % Take the orginal input in the input folder
        else
            previousrundir=[runsdir filesep 'run' num2str(irun-1,'%0.3i')];
            % Read data from previous run
            copyfile([previousrundir filesep 'trim-bypass.*'],rundir);
            
            % rename old data file to be new map file
            movefile([rundir filesep 'trim-bypass.dat'],[rundir filesep 'trim-bypass2.dat']);
            movefile([rundir filesep 'trim-bypass.def'],[rundir filesep 'trim-bypass2.def']);
            
            %change date and time settings
            findreplace([rundir filesep runid '.mdf'],{'Zeta0.*?\n','C01.*?\n','C02.*?\n','C03.*?\n','Tstart.*?\n','Tstop.*?\n'},...
                {'Restid = #trim-bypass2#\r\n','','','',['Tstart = ' num2str((irun-1).*1440.0,'%10.5e\n') '\r\n'],['Tstop = ' num2str((irun).*1440.0,'%10.5e\n') '\r\n']});
            
            %don't do morphologic spin up
            findreplace([rundir filesep runid '.mor'],'MorStt.*?\n','MorStt = 0 [min] \r\n');
            
            
            
            if depth_concentration,
                channel_depth = range(squeeze(vs_let(trim,'map-sed-series',{length(t)},'DPS',{2,3:sy-2},'quiet')));
                
                sand_conc = sand_conc_table(channel_depth);
                
                findreplace([rundir filesep runid '.bcc'],'2.0000000e-002',num2str(sand_conc,'%10.7e\n'))
                
            end
            
            if depth_discharge
                trih = vs_use([runsdir filesep 'run' num2str(irun-1,'%0.3i') filesep 'trih-bypass.dat'],'quiet');
                
                discharge = mean(vs_let(trih,'his-series',{0},'CTR',{1},'quiet'));
                
                if discharge<10,
                    break
                end
                
                wl_head = discharge_func(discharge);
                findreplace([rundir filesep runid '.bct'],'5.0000000',[num2str(wl_head,'%1.7f')]);
                
                
            end
            
            
        end
        
        %and do vegetation
        if vegetation_on
            
            if irun==1,
                %basin is initially vegetated
                chezy = chezy_veg+zeros(sx,sy);
                tcr = tcr_veg+zeros(sx,sy);
                
            else,
                
                %open old datafile
                trim = vs_use([rundir filesep 'trim-bypass2.dat'],[rundir filesep 'trim-bypass2.def'],'quiet');
                %get time
                t = vs_let(trim,'map-infsed-serie',{0},'MORFT','quiet');
                %get depth
                depth = squeeze(vs_let(trim,'map-series',{length(t)},'S1',{0,0},'quiet')+...
                vs_let(trim,'map-sed-series',{length(t)},'DPS',{0,0},'quiet'));
                
                chezy = chezy_noveg+zeros(sx,sy);
                chezy(depth<depth_veg) = chezy_veg;
                
                %roughness
                tcr = tcr_noveg+zeros(sx,sy);
                tcr(depth<depth_veg) = tcr_veg;
                
            end
            
            fid = fopen([rundir filesep 'grid_flow_mid' '.rgh'],'w+');
            %u direction (m direction, along-levee)
            for i=1:numel(chezy(:,1)), fprintf(fid,'%f ',chezy(i,:)); fprintf(fid,'\r\n'); end
            
            %v direction (n direction, cross-levee)
            for i=1:numel(chezy(:,1)), fprintf(fid,'%f ',chezy(i,:)); fprintf(fid,'\r\n'); end
            
            fclose(fid);
            
            %open critical shear stress for erosion file
            fid = fopen([rundir filesep 'grid_flow_mid' '.tce'],'w+');

            %change file
            for i=1:numel(tcr(:,1)), fprintf(fid,'%f ',tcr(i,:)); fprintf(fid,'\r\n'); end
            fclose(fid);

        end
        
        
        % And run the simulation
        curdir=pwd;
        cd(rundir);
        dos('call run_flow2d3d_parallel.bat'); % run_flow2d3d_wave.bat must sit in inputdir!
        cd(curdir);
        
        %now do subsidence
        if subsidence_on
            trim = vs_use([rundir filesep 'trim-bypass.dat'],[rundir filesep 'trim-bypass.def'],'quiet');
            t = vs_let(trim,'map-infsed-serie',{0},'MORFT','quiet');
            z = squeeze(vs_let(trim,'map-sed-series',{length(t)},'DPS',{0,0},'quiet'));
            ero_dep(:,:,irun+1) = squeeze(vs_let(trim,'map-sed-series',{1},'DPS',{0,0},'quiet'))-z;
            t_subsidence(irun+1) = t(end)./365;
            [subsidence(:,:,irun),sig0] = consolidation_model(ero_dep(:,:,1:(irun+1)),t_subsidence(1:(irun+1)),sig0,h0);
            
            
            vs_put(trim,'map-sed-series',{length(t)},'DPS',{0,0},z-subsidence(:,:,irun));
            
            save([runsdir filesep 'subsidence.mat'],'subsidence','ero_dep')
        end
        
    end
    
end