

% Stop signal
% 2018/10/28
% By HLM

clear
try
    %============SubjectInfo===========%
    para.subjectInfo = inputdlg({'编号','中文姓名：如张三','姓名拼音：如zhangsan'},'参与者信息',1,{'01','张三','zhangsan'});
    for i = 1:length(para.subjectInfo)
        para.subjectInfo{i}(isspace(para.subjectInfo{i})) = [];
    end
    %===============CORLOR=============%
    para.screenNumber=max(Screen('Screens'));
    para.white = WhiteIndex(para.screenNumber);
    para.black = BlackIndex(para.screenNumber);
    %===============SIZE===============%
    para.screenSize = Screen('Rect',para.screenNumber);
    para.screenSize = para.screenSize(3:4);
    para.screenCenter = para.screenSize/2;
    para.fixation = 16;             % pixel
    para.fixationLineWidth = 2;     % pixel
    para.picWidth = 128;             % pixel
    para.picHeight = 128;            % pixel
    para.centerCoor = [para.screenCenter(1)-para.picWidth,para.screenCenter(2)-para.picHeight,...
        para.screenCenter(1)+para.picWidth,para.screenCenter(2)+para.picHeight];
    %===============TIME===============%
    para.fixationTime=500;                  % ms
    % para.blankTime=1500;                  % ms
    para.stimTime=1250;                     % ms
    para.feedbackTime=1500;                 % ms
    para.intervalTime= randi(500)+1000;  	% ms
    para.SSD = 250;                         % Stop-Signal Delay ms
    %===============Condition===============%
    para.nTrialLX = 16;     % practice times, must be the multiple of 8
    para.goRepeat = 96;    % go trials
    para.stopRepeat = 32;   % stop trials
    go_left = [1,1,24];     % [Condition1,Condition2,Repeatitions];1 is peiqi_left,orientate left;
    go_right = [1,2,24];    % [Condition1,Condition2,Repeatitions];2 is peiqi_right,orientate right;
    stop_left = [2,1,8];	% [Condition1,Condition2,Repeatitions];3 is pig_left,orientate left;
    stop_right = [2,2,8];	% [Condition1,Condition2,Repeatitions];4 is pig_right,orientate right;
    para.condLX = [[ones(para.nTrialLX/2,1);ones(para.nTrialLX/2,1)+1],repmat([repmat(go_left(1:2),para.nTrialLX/8,1);repmat(go_right(1:2),para.nTrialLX/8,1);
        repmat(stop_left(1:2),para.nTrialLX/8,1);repmat(stop_right(1:2),para.nTrialLX/8,1)],2,1)];
    para.cond = [reshape(repmat([1,2],(para.goRepeat+para.stopRepeat)/2,1),para.goRepeat+para.stopRepeat,1),repmat([repmat(go_left(1:2),go_left(end),1);repmat(go_right(1:2),go_right(end),1);
        repmat(stop_left(1:2),stop_left(end),1);repmat(stop_right(1:2),stop_right(end),1)],2,1)];
    condLX_shuffle = para.condLX(Shuffle(1:length(para.condLX)),:);
    % ensure no more than 6 consecutive go/stop trials
    while true
        cond_shuffle = para.cond(Shuffle(1:length(para.cond)), :);
        still_failed = false;
        % simulating run length encoding
        val = [];
        len = 0;
        for i_trial = 1:size(cond_shuffle, 1)
            if i_trial == 1
                val = cond_shuffle(1, 2);
                len = 1;
                continue
            end
            current_value = cond_shuffle(i_trial, 2);
            if current_value == val
                len = len + 1;
            else
                val = current_value;
                len = 1;
            end
            if len > 6
                still_failed = true;
                break
            end
        end
        if ~still_failed
            break
        end
    end
    para.randCond = [condLX_shuffle; cond_shuffle];
    para.condPart = para.randCond(:,1);     % part1 or part2
    para.condGoStop = para.randCond(:,2);   % go or stop
    para.condLR = para.randCond(:,3);       % left or right,1 == left,2 == right.
    para.nTrialTotal = length(para.randCond);
    %===============Results===============%
    [rawResult.pressKey,rawResult.acc,rawResult.respTime] = deal(nan(para.nTrialTotal,1));
    para.timeString=regexprep(datestr(now,31),'\D','_');
    %% Initialization
    Screen('Preference', 'SkipSyncTests', 0);
    HideCursor;
    wPtr = Screen('OpenWindow', para.screenNumber,para.white,[],[],[],[],4);
    Priority(MaxPriority(wPtr));
    Screen(wPtr,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',wPtr,60);
    Screen('TextFont',wPtr,'Simsun');
    KbName('UnifyKeyNames');
    spaceKey = 32;
    fKey = 70;
    jKey = 74;
    texname = {'peiqi_left.jpg','peiqi_right.jpg','peiqi_left.jpg','peiqi_right.jpg',...
        'ExpInstructionMain.png','ExpInstructionLxend.png','Thankyou.png'};
    for iNum=1:length(texname)
        texid(iNum)=Screen('MakeTexture',wPtr,uint8(imread(['image\' texname{iNum}])));
    end
    samp = 22254.545454;
    aud_stim = sin(1:0.25:1000);
    aud_delay = [];
    aud_padding = zeros(1, round(0.005*samp));	%%% Padding lasts for 5ms
    aud_vec = [  aud_delay  aud_padding  aud_stim  0 ];	% Vector fed into SND
    tic;
    %% Main Exp
    Screen('DrawTexture',wPtr,texid(end-2));
    Screen('Flip',wPtr);
    ListenChar(2);
    while 1
        [~,~,kc]=KbCheck([],1);
        if kc(spaceKey), break; end
        WaitSecs(0.01);
    end
    ListenChar(0);
    for iTrial = 1:para.nTrialTotal
        if iTrial == para.nTrialLX+1
            % reset SSD paramter as 250 ms when real testing begins
            para.SSD = 250;
            Screen('DrawTexture',wPtr,texid(end-1));
            Screen('Flip',wPtr);
            ListenChar(2);
            while 1
                [~,~,kc]=KbCheck([],1);
                if kc(32), break; end
                WaitSecs(0.01);
            end
            ListenChar(0);
        end
        
        % Step1 Fixation
        Screen('DrawLine',wPtr,para.black,para.screenCenter(1)-para.fixation/2,para.screenCenter(2),para.screenCenter(1)+para.fixation/2,para.screenCenter(2),para.fixationLineWidth);
        Screen('DrawLine',wPtr,para.black,para.screenCenter(1),para.screenCenter(2)-para.fixation/2,para.screenCenter(1),para.screenCenter(2)+para.fixation/2,para.fixationLineWidth);
        Screen('Flip',wPtr);
        WaitSecs(para.fixationTime/1000);
        
        % Step2 Stimulus presentation & press leftKey or rightKey
        if para.condPart(iTrial,:) == 1 && para.condLR(iTrial,:) == 1  	  % part 1 and orientate left
            Screen('DrawTexture',wPtr,texid(1),[],para.centerCoor);
        elseif para.condPart(iTrial,:) == 1 && para.condLR(iTrial,:) == 2 % part 1 and orientate right
            Screen('DrawTexture',wPtr,texid(2),[],para.centerCoor);
        elseif para.condPart(iTrial,:) == 2 && para.condLR(iTrial,:) == 1 % part 2 and orientate left
            Screen('DrawTexture',wPtr,texid(3),[],para.centerCoor);
        elseif para.condPart(iTrial,:) == 2 && para.condLR(iTrial,:) == 2 % part 2 and orientate right
            Screen('DrawTexture',wPtr,texid(4),[],para.centerCoor);
        end
        Screen('Flip',wPtr);
        startTime=GetSecs*1000;
        ListenChar(2);
        resp_to_be_made = true;
        while GetSecs*1000 - startTime <= para.SSD
            [~,~,kc_ssd]=KbCheck([],1);
            if kc_ssd(fKey) || kc_ssd(jKey)
                kc = kc_ssd;
                respTime=GetSecs*1000;
                resp_to_be_made = false;
            elseif kc_ssd(27)
                sca;
                ListenChar(0);
                disp('*******************');
                disp('***** 实验中止 *****');
                disp('*******************');
                return;
            end
        end
        if para.condGoStop(iTrial,:) == 2
            sound(aud_vec, samp);
        end
        while GetSecs*1000 - startTime <= para.stimTime
            if para.condGoStop(iTrial,:) == 1 && GetSecs*1000 - startTime >= 1000
                DrawFormattedText(wPtr,double('请尽快反应！'),'center','center',para.black);
                Screen('Flip',wPtr);
            end
            if resp_to_be_made
                [~,~,kc]=KbCheck([],1);
                respTime=GetSecs*1000;
            end
            if kc(fKey)
                rawResult.pressKey(iTrial,:) = 1; % press left
                rawResult.respTime(iTrial,:) = respTime-startTime;
                break;
            elseif kc(jKey)
                rawResult.pressKey(iTrial,:) = 2; % press right
                rawResult.respTime(iTrial,:) = respTime-startTime;
                break;
            elseif kc(27)
                sca;
                ListenChar(0);
                disp('*******************');
                disp('***** 实验中止 *****');
                disp('*******************');
                return;
            end
        end
        ListenChar(0);
        
        % Step3 Feedback
        if para.condGoStop(iTrial,:) == 1 && ~isnan(rawResult.pressKey(iTrial,:))       % go
            accTrial = (rawResult.pressKey(iTrial,:) == para.condLR(iTrial,:))*1;
        elseif para.condGoStop(iTrial,:) == 1 && isnan(rawResult.pressKey(iTrial,:))	% go
            accTrial = rawResult.pressKey(iTrial,:);
        else                                                                            % stop
            accTrial = isnan(rawResult.pressKey(iTrial,:))*1;
        end
        accTillNow(iTrial,:) = accTrial;
        
        if iTrial <= para.nTrialLX
            startTime=GetSecs*1000;
            while GetSecs*1000 - startTime <= para.feedbackTime
                if ~isnan(accTrial)
                    accStrtmp = {'糟糕。反应错误！','很棒。反应正确！'};
                    accStr = accStrtmp{accTrial+1};
                    if para.condGoStop(iTrial,:) == 1
                        rtStr = sprintf('\n反应时：%.0f毫秒。', rawResult.respTime(iTrial,:));
                    else
                        rtStr = '';
                    end
                else
                    accStr = '哎呀。未作反应！';
                    rtStr = '';
                end
                str = [accStr, rtStr];
                Screen('TextSize',wPtr,60);
                Screen('TextFont',wPtr,'Simsun');
                DrawFormattedText(wPtr,double(str),'center','center',para.black,[],0,0,2);
                Screen('Flip',wPtr);
            end
        end
        
        if para.condGoStop(iTrial,:) == 1
            para.SSDTotal(iTrial,:) = nan;                         % Stop-Signal Delay ms
        elseif para.condGoStop(iTrial,:) == 2
            para.SSDTotal(iTrial,:) = para.SSD;
            if accTrial == 1 && para.SSD < 1000
                para.SSD = para.SSD + 50;
            elseif accTrial == 0 && para.SSD > 0
                para.SSD = para.SSD - 50;
            end
        end
        
        % Step4 Interval Blank 02
        Screen('Flip',wPtr);
        WaitSecs(para.intervalTime/1000);
    end
    %% End:Show Thank you & Save data file
    WaitSecs(0.1);
    rawResult.acc = accTillNow;
    accMeanExp = nanmean(rawResult.acc(para.nTrialLX+1:end,:))*100;
    rtMeanExp = nanmean(rawResult.respTime(para.nTrialLX+1:end,:));
    str = sprintf('平均正确率：%.2f%%\n平均反应时：%.0f 毫秒。',accMeanExp,rtMeanExp);
    Screen('TextSize',wPtr,60);
    Screen('TextFont',wPtr,'Simsun');
    DrawFormattedText(wPtr,double(str),'center','center',para.black,[],0,0,2);
    Screen('Flip',wPtr);
    res_dir = 'Results';
    if ~exist(res_dir, 'dir')
        mkdir(res_dir)
    end
    para.filepath = fullfile(res_dir, ['Exp6_stopsignal_' para.subjectInfo{1} para.subjectInfo{3} '_' para.timeString '.mat']);
    save(para.filepath)
    Screen('DrawTexture',wPtr,texid(end));
    Screen('Flip',wPtr);
    WaitSecs(0.3);
    sca;
    ShowCursor;
    para.exptime=toc; % s
    %% 仅测试163邮箱，需联网
    sendAddress='stopsignal@163.com';     	% 发送邮箱账号
    sendPassword='123a456a';             	% 发送邮箱密码
    receiveAddress='stopsignal@163.com'; 	% 接收邮箱账号
    setpref('Internet','E_mail',sendAddress);
    setpref('Internet','SMTP_Server','smtp.163.com');
    setpref('Internet','SMTP_Username',sendAddress);
    setpref('Internet','SMTP_Password',sendPassword);
    props=java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class','javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','994');
    splitinfo=strsplit(para.filepath,filesep);
    subject=char(splitinfo(end));
    content='Matlab自动发送邮件，数据见附件。';
    disp('邮件发送中，等待数据上传~~~');
    disp('>>>>>>>>>>>>>>>>>>>>>>');
    sendmail(receiveAddress,subject,content,para.filepath);
    disp('邮件发送完毕，数据传输成功~~~');
    disp('实验结束~~~');
catch
    psychrethrow(psychlasterror);
    sca;
    ShowCursor;
end
return;