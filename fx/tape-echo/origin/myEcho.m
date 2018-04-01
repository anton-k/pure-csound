
%% Echo Plugin - original code by Jon Downing
classdef myEcho < audioPlugin


    %% Properties
    properties
        FbGain = 0.5;
        Delay = 0.06;
        InputGain = 1;
        EchoGain = 0.5;
        TauUp = 1.07;
        TauDown = 1.89;
        Lambda = 0.5;
        PrevIn = 0;
        NSamples = 0;
        LastApSamp = 0;
        bCoeff = zeros(1, 3);
        aCoeff = zeros(1, 3);
        LPFCoeff = zeros(1, 3);
        OutputGain = 1;
    end
    properties(Constant)

        % Plugin parameters
        PluginInterface = audioPluginInterface(...
            audioPluginParameter('FbGain',...
            'DisplayName','Feedback Gain',...
            'Mapping',{'lin',0.01,2}), ...
            audioPluginParameter('InputGain',...
            'DisplayName','Input Gain',...
            'Mapping', {'lin', 0, 2}), ...
            audioPluginParameter('EchoGain',...
            'DisplayName','Echo Gain',...
            'Mapping',{'lin',0,2}), ...
            audioPluginParameter('Delay',...
            'DisplayName','Echo Delay',...
            'Label','s', 'Mapping', {'lin', 0.06, 0.16}), ...
            audioPluginParameter('OutputGain',...
            'DisplayName','Output Gain',...
            'Mapping', {'lin', 0, 2}));
        PQ = 1;
        Fs = 96000;
        Fs2 = 96000;
        BufLength = 131072*4;
    end

    % Private properties
    properties (Access=private)
        CircularBuffer = zeros(131072*4,1);           %<---
        PrevDelay = 0.06;
        BufferIndex = 1;                            %<---
        Frac = 0;
        Den
        SOSObj
        LPFObj
    end                                             %<---

    %% Methods
    methods


        % Constructor
        function plugin = myEcho()
            if nargin > 0
                plugin.Cutoff = Fc;
            end
            [plugin.bCoeff, plugin.aCoeff] = ...
                cheby1(1,6, [95 3000]/(plugin.Fs2/2),'bandpass');

            plugin.SOSObj = dsp.BiquadFilter('SOSMatrixSource','Input port',...
                'ScaleValuesInputPort',false);
            plugin.LPFObj = dsp.BiquadFilter('SOSMatrixSource','Input port',...
                'ScaleValuesInputPort',false);
            plugin.LPFCoeff = fir1(2, 0.5/plugin.Fs2, 'low');
        end

        %% Main Process Method
        function [out, delayV] = process(plugin, in)
            frameSize = size(in,1);                     %<---
            noise = rand(frameSize, 1);
            noise = 3*(7.5 - plugin.PrevDelay*10^-3)*10^-7*...
                (noise - mean(noise));
            noiseMod = step(plugin.LPFObj, noise, ...
                plugin.LPFCoeff', [0;0]);
            delayV = zeros(frameSize, 1);
            %           myIn = resample(in, plugin.PQ, 1, 20);
            myIn = mean(in.*plugin.InputGain, 2);
            myOut = zeros(size(myIn));
            %
            %             %            myIn = in;
            writeIndex = plugin.BufferIndex;
            lastWriteIndex = writeIndex - 1;
            if lastWriteIndex < 1
                lastWriteIndex = lastWriteIndex + plugin.BufLength;
            end
            lastApSamp = plugin.LastApSamp;
            for i = 1:size(myIn,1)
                lambda = plugin.Lambda;
                actualDelay = (1-lambda)*plugin.Delay + lambda*plugin.PrevDelay;
                actualDelay = actualDelay + noiseMod(i);
                delayV(i) = actualDelay;
                plugin.PrevDelay = actualDelay;
                delaySamps = plugin.Fs2*actualDelay;


                plugin.NSamples = floor(delaySamps);
                readIndex = writeIndex - plugin.NSamples;
                if readIndex < 1
                    readIndex = readIndex + plugin.BufLength;
                end
                lastReadIndex = readIndex - 1;
                if lastReadIndex < 1
                    lastReadIndex = lastReadIndex + plugin.BufLength;
                end



                plugin.Frac = delaySamps - plugin.NSamples;
                frac = plugin.Frac;
                fracScale = (1-frac)/(1+frac);
                readSamp = plugin.CircularBuffer(readIndex,:);
                lastReadSamp = plugin.CircularBuffer(lastReadIndex,:);

                % Read
                echo = erf(fracScale*(readSamp - ...
                    lastApSamp) +lastReadSamp);
                lastApSamp = echo;

                %                 % Output
                outSamp = myIn(i) + echo*plugin.EchoGain;
                for j = 1:size(myOut, 2)
                    myOut(i,j) = outSamp;
                end

                % Write
                fbSamp = step(plugin.SOSObj, outSamp, plugin.bCoeff', ...
                    plugin.aCoeff(2:end)').*plugin.FbGain;

                plugin.CircularBuffer(writeIndex,:) = ...
                    myIn(i,:)+fbSamp.*plugin.FbGain;



                % Bump Pointers
                writeIndex = round(writeIndex + 1);
                if writeIndex > plugin.BufLength;
                    writeIndex = writeIndex - plugin.BufLength;
                end
                lastWriteIndex = round(writeIndex - 1);
                if lastWriteIndex < 1
                    lastWriteIndex = lastWriteIndex + plugin.BufLength;
                end

            end
            plugin.LastApSamp = lastApSamp;
            plugin.BufferIndex = writeIndex;
            %     out = resample(myOut, 1, plugin.PQ, 20);
            out = plugin.OutputGain*[myOut, myOut];
        end

        %% Set Delay Method
        function set.Delay(plugin, newDel)
            oldDel = plugin.Delay;
            plugin.Delay = newDel;
            if newDel > oldDel
                plugin.Lambda = exp(-1/(plugin.TauUp*plugin.Fs2));
            else
                plugin.Lambda = exp(-1/(plugin.TauDown*plugin.Fs2));
            end
        end
        %% Reset Method
        function reset(plugin)
            plugin.CircularBuffer = zeros(plugin.BufLength,1);
            plugin.NSamples = floor(plugin.Fs2*plugin.Delay);
            plugin.BufferIndex = 2;
            plugin.LastApSamp = 0;
            [plugin.bCoeff, plugin.aCoeff] = ...
                cheby1(1,6, [125 3500]/(plugin.Fs2),'bandpass');
            plugin.LPFCoeff = fir1(2, 0.5/plugin.Fs2, 'low');
        end

    end
end