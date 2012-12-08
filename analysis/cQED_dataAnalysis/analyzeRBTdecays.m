function decays = analyzeRBTdecays(data, seqsPerFile, nbrFiles, nbrExpts, seqLengthsPerExpt, nbrTwirls, exhaustiveFlags, nbrSoftAvgs, ptraceRepeats, nbrCals, calRepeats)
% analyzeRBTdecays(data,            seqsPerFile,       nbrFiles, 
%                  nbrExpts,        seqLengthsPerExpt, nbrTwirls, 
%                  exhaustiveFlags, nbrSoftAvgs,       ptraceRepeats, 
%                  nbrCals,         calRepeats)
%
%
% r=analyzeRBTdecays(data.abs_Data, 144*3, 5, 9, [1,2,3,0], [12^2, 12^2, 12^3, 12^2], [true, true, true, true], 10, 2, 4, 2);

% overlap, file, trace, sequence, soft,

% rearrange the idices so that they correspond to
% sequence ct, overlap ct, file ct, trace rep ct, soft avg rep ct
reshaped_data = reshape(data',seqsPerFile+nbrCals*calRepeats,nbrSoftAvgs,ptraceRepeats,nbrFiles,nbrExpts);

% now we need to extract the calibration for the data
% we average over the soft average samples, 
cal_data = tensor_mean(reshaped_data(seqsPerFile+1:end,:,:,:,:),2);

% then average over the cal repeats
cal_data = tensor_mean(reshape(cal_data,calRepeats,nbrCals,ptraceRepeats,nbrFiles,nbrExpts),1);

% we want to calibrate qubit data, so we set the upper and lower rails 
cal_data = tensor_mean(tensor_sum(reshape(cal_data,nbrCals/2,2,ptraceRepeats,nbrFiles,nbrExpts),1),2);

% the result is one expectation for ground, one expectation value for
% excited, which we then use to set the scale and shift for the rest of the
% data (each experiment in each file must be rescaled independently)
cal_scale = reshape(cal_data(2,:,:) - cal_data(1,:,:),1,nbrExpts*nbrFiles);
cal_shift = reshape((cal_data(2,:,:) + cal_data(1,:,:))/2,1,nbrExpts*nbrFiles);

% now we can rescale the unaveraged (but traced out) data (useful for bootstraping)
scaled_data = reshape(tensor_sum(reshaped_data(1:seqsPerFile,:,:,:,:),3),seqsPerFile*nbrSoftAvgs,nbrExpts*nbrFiles);
scaled_data = (scaled_data - repmat(cal_shift,[nbrSoftAvgs*seqsPerFile 1]))./repmat(cal_scale,[nbrSoftAvgs*seqsPerFile 1]);
scaled_data = reshape(scaled_data,seqsPerFile,nbrSoftAvgs*nbrExpts*nbrFiles);

% and now we can rescale the averaged, reshaped data
reshaped_data = reshape(tensor_mean(tensor_sum(reshaped_data(1:seqsPerFile,:,:,:,:),3),2),seqsPerFile,nbrExpts*nbrFiles);
scaled_avg_data = (reshaped_data - repmat(cal_shift,[seqsPerFile 1]))./repmat(cal_scale,[seqsPerFile 1]);

% we can now line up all experiments, and have each overlap experiment in a
% different row
scaled_data = permute(reshape(scaled_data,seqsPerFile,nbrSoftAvgs,nbrExpts,nbrFiles),[2,1,3,4]);
scaled_data = reshape(scaled_data,nbrSoftAvgs,seqsPerFile*nbrExpts*nbrFiles);

scaled_avg_data = permute(reshape(scaled_avg_data,seqsPerFile,nbrExpts,nbrFiles),[1,3,2]);
scaled_avg_data = reshape(scaled_avg_data,seqsPerFile*nbrFiles,nbrExpts);

% now we sum over the twirls
% bounds = cumsum([0 nbrTwirls]);
% decays = zeros(length(nbrTwirls),nbrExpts);
% for ii=1:length(bounds)-1,
%     decays(ii,:) = sum(scaled_avg_data(bounds(ii)+1:bounds(ii)+1,:),2);
% end
% decays = decays;
decays = avg_and_twirl(scaled_data, seqsPerFile, nbrExpts, nbrFiles, nbrTwirls);

end

function v = vec(M)
  v = reshape(M,prod(size(M)),1);
end

function decays = avg_and_twirl( data, seqsPerFile, nbrExpts, nbrFiles, nbrTwirls )
    avg_data = reshape(tensor_mean(data,1),seqsPerFile*nbrExpts,nbrFiles);
    bounds = cumsum([0 nbrTwirls]);
    decays = zeros(length(nbrTwirls),nbrExpts);
    for ii=1:length(bounds)-1,
        decays(ii,:) = sum(avg_data(bounds(ii)+1:bounds(ii)+1,:),2);
    end
end

function t = tensor_sum( M, v )
    s = size(M);
    ii = 1:length(s);
    vbar = setdiff(ii,v);
    t = sum(reshape(permute(M,[vbar v]),[s(vbar) prod(s(v))]),length(vbar)+1);
end

function t = tensor_mean( M, v )
    s = size(M);
    ii = 1:length(s);
    vbar = setdiff(ii,v);
    t = mean(reshape(permute(M,[vbar v]),[s(vbar) prod(s(v))]),length(vbar)+1);
end
