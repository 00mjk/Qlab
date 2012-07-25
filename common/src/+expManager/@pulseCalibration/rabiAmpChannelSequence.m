function [filename, nbrPatterns] = rabiAmpChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

pathAWG = 'U:\AWG\Rabi\';
basename = 'Rabi';

qubitMap = obj.channelMap.(qubit);
IQkey = qubitMap.IQkey;

fixedPt = 2000;
cycleLength = 6000;
numsteps = 40; %should be even
stepsize = 400;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit); % choose target qubit here

pg = PatternGen(...
    'dPiAmp', obj.pulseParams.piAmp, ...
    'dPiOn2Amp', obj.pulseParams.pi2Amp, ...
    'dSigma', qParams.sigma, ...
    'dPulseType', obj.pulseParams.pulseType, ...
    'dDelta', obj.pulseParams.delta, ...
    'correctionT', obj.pulseParams.T, ...
    'dBuffer', qParams.buffer, ...
    'dPulseLength', qParams.pulseLength, ...
    'cycleLength', cycleLength, ...
    'linkList', params.(IQkey).linkListMode, ...
    'dmodFrequency', obj.pulseParams.SSBFreq ...
    );

%Don't use zero because if there is a mixer offset it will be completely
%different because the source is never pulsed
amps = [-(numsteps/2)*stepsize:stepsize:-stepsize stepsize:stepsize:(numsteps/2)*stepsize];

for n = 1:numsteps;
    patseq{n} = {pg.pulse('Xtheta', 'amp', amps(n))};
end

for n = 1:numsteps;
    patseq{n+numsteps} = {pg.pulse('Ytheta', 'amp', amps(n))};
end

nbrRepeats = 1;
nbrPatterns = nbrRepeats*length(patseq);
numsteps = 1;

calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap);
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, 20);

filename{1} = [pathAWG basename '-TekAWG.awg'];
filename{2} = [pathAWG basename '-BBNAPS.h5'];

end
