function [indices, participants] = analysis_stopsignal(identifier, resdir)

% at most 2 input arguments are permitted
narginchk(0, 2)
% if `dir` not specified, use the directory where current function lies
if nargin < 2
    resdir = 'Results';
end
files_candidate = dir(resdir);
if nargin < 1
    % if `code` not specified, will try to get user-codes from the `dir`
    % and analysis all the files
    % format of result file
    files_to_analysis_pattern = 'Exp6_stopsignal_\d+\w+_.+';
else
    if isnumeric(identifier)
        files_to_analysis_pattern = sprintf('Exp6_stopsignal_0*%d.+', identifier);
    end
end

% extract all the names of files to analyze
files_to_analysis = regexp({files_candidate.name}, files_to_analysis_pattern, 'match', 'once');
files_to_analysis(cellfun(@isempty, files_to_analysis)) = [];

% begin analysis
[rawdata_to_analysis, participants] = load_and_extract_rawdata(files_to_analysis, resdir);
indices = analyze_rawdata(rawdata_to_analysis);
end

function [rawdata, participants] = load_and_extract_rawdata(filenames, resdir)

count_files = length(filenames);
participants = table;
participants.id = nan(count_files, 1);
participants.name = cell(count_files, 1);
rawdata = table;
para_selected = {'condPart', 'condGoStop', 'condLR', 'SSDTotal'};
for i_file = 1:count_files
    current_filename_full = fullfile(resdir, filenames{i_file});
    current_userinfo = regexp(current_filename_full, ...
        '(?<=Exp6_stopsignal_)(\d+)([a-zA-Z]+)_(\w+(?=\.))', 'tokens', 'once');
    participants.id(i_file) = str2double(current_userinfo{1});
    participants.name{i_file} = current_userinfo{2};
    current_loaded = load(current_filename_full);
    current_rawdata = table;
    current_rawdata.id = repmat(str2double(current_userinfo{1}), current_loaded.para.nTrialTotal, 1);
    current_rawdata.partTime = repmat( ...
        datetime(current_userinfo{3}, 'InputFormat', 'yyyy_MM_dd_HH_mm_ss'), ...
        current_loaded.para.nTrialTotal, 1);
    current_rawdata.expType = [repmat({'prac'}, current_loaded.para.nTrialLX, 1); ...
        repmat({'main'}, current_loaded.para.nTrialTotal - current_loaded.para.nTrialLX, 1)];
    current_para_selected = rmfield(current_loaded.para, ...
        setdiff(fieldnames(current_loaded.para), para_selected));
    current_rawdata = [current_rawdata, ...
        struct2table(current_para_selected), ...
        struct2table(current_loaded.rawResult)]; %#ok<AGROW>
    current_rawdata.condPart = categorical(current_rawdata.condPart, 1:2, {'peiqi', 'pig'});
    current_rawdata.condGoStop = categorical(current_rawdata.condGoStop, 1:2, {'Go', 'Stop'});
    current_rawdata.condLR = categorical(current_rawdata.condLR, 1:2, {'Left', 'Right'});
    current_rawdata.pressKey = categorical(current_rawdata.pressKey, 1:2, {'Left', 'Right'});
    rawdata = [rawdata; current_rawdata]; %#ok<AGROW>
end
end

function res = analyze_rawdata(rawdata)

key_vars = {'id', 'partTime'};
ana_vars = {'condGoStop', 'SSDTotal', 'acc', 'respTime'};
rawdata_main = rawdata(ismember(rawdata.expType, 'main'), :);
[grps, gids] = findgroups(rawdata_main(:, key_vars));
[stats, labels] = splitapply(@stopsignal, rawdata_main(:, ana_vars), grps);
res = [gids, array2table(stats, 'VariableNames', labels)];

    function [stats, labels] = stopsignal(cond, ssd, acc, rt)
        % set go trials of too short rt as wrong
        acc(rt < 100 & cond == 'Go') = 0;
        % get percent of correct for go trials
        pc = nanmean(acc(cond == 'Go'));
        pc_stop = nanmean(acc(cond == 'Stop'));
        % get mean ssd
        mean_ssd = mean( ...
            [findpeaks(ssd(cond == 'Stop')); ...
            -findpeaks(-ssd(cond == 'Stop'))]);
        % get go rt
        med_go_rt = median(rt(acc == 1 & cond == 'Go'));
        % get ssrt
        ssrt = med_go_rt - mean_ssd;
        stats = [pc, pc_stop, mean_ssd, med_go_rt, ssrt];
        labels = {'PC', 'PC_STOP', 'Mean_SSD', 'MedGoRT', 'SSRT'};
    end

end