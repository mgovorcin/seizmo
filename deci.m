function [data]=deci(data,factor)
%DECI    Downsample SAClab data records by integer factor
%
%    Description: Downsamples SAClab data records by an integer factor.  
%     Keep the factor below 13 to avoid problems with the anti-aliasing
%     filter and numerical noise.  Cascades are allowed by supplying 
%     a vector of factors.  Uses the Matlab function decimate (Signal 
%     Processing Toolbox).
%
%    Usage:  [data]=stretch(data,factors)
%
%    Examples: 
%     To halve the samplerates:
%      [data]=deci(data,2)
%
%     To cascade to a samplerate 40 times lower;
%      [data]=deci(data,[5 8])
%
%    See also: stretch, syncsr, intrpol8

% check inputs
error(nargchk(2,2,nargin))

% check data structure
error(seischk(data,'x'))

% empty factor
if(isempty(factor)); return; end

% check factor
if(~isnumeric(factor) || ~isvector(factor) || ...
        any(factor<1) || any(fix(factor)~=factor))
    error('SAClab:deci:badInput',...
        'factor must be a scalar/vector of positive integer(s)')
end

% number of factors
nf=length(factor);

% overall factor
of=prod(factor);

% check spacing
if(any(~strcmp(glgc(data,'leven'),'true')))
    error('SAClab:deci:evenlySpacedOnly',...
        'illegal operation on unevenly spaced data');
end

% header info
[b,delta]=gh(data,'b','delta');
delta=delta*of;

% decimate and update header
for i=1:length(data)
    % save class and convert to double precision
    oclass=str2func(class(data(i).x));
    data(i).x=double(data(i).x);
    
    % loop over components
    ncmp=size(data(i).x,2);
    for j=1:ncmp
        temp=data(i).x(:,j);
        % loop over factors
        for k=1:nf
            temp=decimate(temp,factor(k));
        end
        % preallocate after we know length
        if(j==1)
            len=size(temp,1);
            save=zeros(len,ncmp);
        end
        save(:,j)=temp;
    end
    
    % change class back
    data(i).x=oclass(save);
    
    % update header
    data(i)=ch(data(i),'npts',len,'delta',delta(i),...
        'e',b(i)+(len-1)*delta(i),'depmin',min(data(i).x(:)),...
        'depmen',mean(data(i).x(:)),'depmax',max(data(i).x(:)));
end

end
