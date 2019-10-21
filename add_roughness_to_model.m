function add_roughness_to_model(inputdir,sx,sy)

fid = fopen([inputdir 'grid_flow_mid.dep']);

C = textscan(fid, '%f');
z = reshape(C{1},sy,sx);

fclose(fid);

%lipheight = 2.5;
%z(42:51,1:24) = z(42:51,1:24)*(lipheight./3);

z = z+(rand(size(z))-0.5);


fid = fopen([inputdir 'grid_flow_midchannel'],'w+');

for i=1:numel(z(1,:)),
    fprintf(fid,'%f ',z(:,i));
    fprintf(fid,'\r\n');
end

fclose(fid);

movefile([inputdir 'grid_flow_midchannel'],[inputdir 'grid_flow_midchannel.dep']);
end