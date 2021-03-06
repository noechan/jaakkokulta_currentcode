function out = melodymatching4mydata_wnoteonsets(fname, temp, par)

arguments
    fname % filename
    temp % melody template
    par.onset % binary vector of note onset locations
    par.thres = 0.1; % amplitude threshold for trimming
    par.minf0 = 30 % Hz - minimum expected F0 (default: SR/(4*dsratio))
    par.maxf0 = 1000 % Hz - maximum expected F0
    par.hop = 32 % samples - interval between estimates (default: 32)
end
yinpar.minf0 = par.minf0;
yinpar.maxf0 = par.maxf0;
yinpar.hop = par.hop;
thres=par.thres;
if isfield(par,'onset')
onset = par.onset;
end

% convert onset vector to alternating ones and zeros
if isfield(par,'onset')
onset1a=1;
for k=2:length(onset)
    if onset(k)==0
        onset1a(k)=onset1a(k-1);
    else
        onset1a(k)=1-onset1a(k-1);
    end
end
end

N=length(temp);

% 1. Estimate pitch and amplitude

% yin output For the yinpar returns 4 1x25796 (max. range/hop) array including:
%f0: %fundamental frequency in octaves re: 440 Hz
%ap0 & ap: periodicity measure (ratio of aperiodic to total power)
%pwr: period-smoothed instantaneous power 
%sr=44100 and should be changed to 48kHz to match the recording's
% value
yinout=yin(fname,yinpar);
f0=yinout.f0; 
pitch0=69+12*f0; % is this converting the values to semitones? range(1.17,-3.87)
pitch=medfilt1(pitch0,3); % slight median filtering
amp=sqrt(yinout.pwr);
amp=amp/max(amp); % normalize max amplitude
M=length(pitch);

% 2. Trim audio based by amplitude thresholding
ind=find(amp>thres);
start=min(ind);
stop=max(ind);
pitch1=pitch(start:stop);
amp1=amp(start:stop);
incl1=find(amp1>thres*nanmedian(amp1));
M1=length(pitch1);

% 3. Interpolate template to match pitch curve length
temp1=interp1(linspace(0,1,N),temp,linspace(0,1,M1),'previous');
if isfield(par,'onset')
    onset1=interp1(linspace(0,1,N),onset1a,linspace(0,1,M1),'previous');
end

% 4. Remove timepoints below threshold amplitude
pitch2=pitch1(incl1);
temp2a=temp1(incl1);
if isfield(par,'onset')
    onset2=onset1(incl1);
end
amp2=amp1(incl1);

% 5. Match pitch and template means
temp2=temp2a+mean(pitch2)-mean(temp2a);

% 6. Dynamic Time Warping
metrics={'absolute','euclidean','squared','symmkl'};
m=2;
[d,idx,idy]=dtw(pitch2,temp2,metrics{m});
pitch3=pitch2(idx);
amp3=amp2(idx);
temp3=temp2(idy);
if isfield(par,'onset')
onset3=onset2(idy);
end

% 7. Remove pitch outliers
incl3=find(abs(pitch3-temp3)<2.5*std(pitch3-temp3));
pitch4=pitch3(incl3);
temp4a=temp3(incl3);
if isfield(par,'onset')
    onset4=onset3(incl3);
end
amp4=amp3(incl3);
M4=length(pitch4);

% 8. Match pitch and template means
temp4=temp4a+mean(pitch4)-mean(temp4a);

% 9. Rhythm error score
out.rhythmerror=(sum(diff(idx)==0)+sum(diff(idy)==0))/length(idx);

% 10. Pitch error score 1: no segmenting, no trend removal
% amplitude-weighted mean absolute error
pe4=pitch4-temp4;
out.pitcherror(1)=sum(amp4.*abs(pe4))/sum(amp4); % amplitude weighted mean abs error

% 11. Pitch error score 2: no segmenting, trend removal
pe4d=detrend(pe4);
out.pitcherror(2)=sum(amp4.*abs(pe4d))/sum(amp4); % amplitude weighted mean abs error

% 12. Segment pitch data based on template pitch changes
if isfield(par,'onset')
stop=[find(abs(diff(onset4))>0) length(onset4)]; % end of each segment
else
stop=[find(abs(diff(temp4))>0) length(temp4)]; % end of each segment
end

start=[1 stop(1:end-1)+1]; % beginning of each segment

for k=1:length(start)
    pitch5(k)=median(pitch4(start(k):stop(k)));
    temp5(k)=temp4(start(k));
end


% 13. Pitch error score 3: segmenting, no trend removal
pe5=pitch5-temp5;
out.pitcherror(3)=mean(abs(pe5));

% 14. Pitch error score 4: segmenting, trend removal
pe5d=detrend(pe5);
out.pitcherror(4)=mean(abs(pe5d));

% 15. Pitch error score 5: parsons code distance
pitch6=sign(round(diff(pitch5)));
temp6=sign(diff(temp5));
out.pitcherror(5)=sum(abs(pitch6-temp6));

out.pitch = {pitch pitch1 pitch2 pitch3 pitch4 pitch5 pitch6};
out.temp = {temp temp1 temp2 temp3 temp4 temp5 temp6};
if isfield(par,'onset')
% convert alternating ones and zeros to onset vectors
alt2on = @(x) [1 abs(diff(x))];
out.onset = {onset alt2on(onset1a) alt2on(onset2) alt2on(onset3) alt2on(onset4)};
end
out.amp={amp amp1 amp2 amp3 amp4};
