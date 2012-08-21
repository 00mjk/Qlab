% Copyright 2010 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% File: HP71000.m
% Author: Blake Johnson (bjohnson@bbn.com)
%
% Description: Instrument driver for the HP71000 spectrum analyzer.

classdef HP71000 < deviceDrivers.lib.GPIB
   properties
       center_frequency
       span
       resolution_bw
       video_bw
       sweep_mode
       video_averaging
       number_averages
       sweep_points
   end
   
   methods
       function obj = HP71000()
       end
       
       function sweep(obj)
           obj.Write('TS;');
       end
       
       % reset instrument to default state
       function reset(obj)
           obj.Write('IP;');
       end
       
       function val = peakAmplitude(obj)
           obj.Write('MKPK HI;'); % move marker to peak
           tmp = obj.Query('MKA?;'); % get marker amplitude
           val = str2double(tmp);
       end
       
       function val = peakFrequency(obj)
           obj.Write('MKPK HI;'); % move marker to peak
           tmp = obj.Query('MKF?;'); % get marker frequency
           val = str2double(tmp);
       end
       
       function [xpts, ypts] = downloadTrace(obj)
           tmp = obj.Query('TRA?;');
		   ypts = strread(tmp, '%f', 'delimiter', ',');
		   
		   center_freq = obj.center_frequency;
		   span = obj.span;
		   xpts = linspace(center_freq - span/2, center_freq + span/2, length(ypts));
       end
       
       % instrument meta-setter
		function setAll(obj, settings)
			fields = fieldnames(settings);
			for j = 1:length(fields);
				name = fields{j};
				if ismember(name, methods(obj))
					feval(['obj.' name], settings.(name));
				elseif ismember(name, properties(obj))
					obj.(name) = settings.(name);
				end
			end
        end
        
        % property accessors
        
        function val = get.center_frequency(obj)
            temp = obj.Query('CF?;');
            val = str2double(temp);
        end
        
        function val = get.span(obj)
            temp = obj.Query('SP?;');
            val = str2double(temp);
        end
        
        function val = get.resolution_bw(obj)
            temp = obj.Query('RB?;');
            val = str2double(temp);
        end
        
        function val = get.video_bw(obj)
            temp = obj.Query('VB?;');
            val = str2double(temp);
        end
        
        function val = get.sweep_mode(obj)
            val = '';
        end
        
        function val = get.video_averaging(obj)
            val = str2double(obj.Query('VAVG?;'));
        end
        
        function val = get.number_averages(obj)
            val = str2double(obj.Query('VAVG?;'));
        end
        
        function val = get.sweep_points(obj)
            val = str2double(obj.Query('TRDEF TRA?;'));
        end
        
        % property settors
        
        function set.center_frequency(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.Write(sprintf('CF %E;',value));
        end
        
        function set.span(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.Write(sprintf('SP %E;',value));
        end
        
        function set.resolution_bw(obj, value)
            gpib_string = 'RB %dkHz;';

            % Validate input
            if strcmp(value, 'auto')
                gpib_string = 'RB AUTO;';
            elseif isnumeric(value)
                gpib_string = sprintf(gpib_string, value/1e3);
            else
                error('Invalid input');
            end
            
            obj.Write(gpib_string);
        end
        
        function set.video_bw(obj, value)
            gpib_string = 'VB %dkHz;';

            % Validate input
            if strcmp(value, 'auto')
                gpib_string = 'VB AUTO;';
            elseif isnumeric(value)
                gpib_string = sprintf(gpib_string, value/1e3);
            else
                error('Invalid input');
            end

            obj.Write(gpib_string);
        end
        
        function set.sweep_mode(obj, value)
            % Validate input
            checkMapObj = containers.Map({'single','continuous','cont'},...
                {'SNGLS','CONTS','CONTS'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string =[checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
        
        function set.video_averaging(obj, value)
            gpib_string = 'VAVG ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'ON','ON','OFF','OFF'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string =[gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
        
        function set.number_averages(obj, value)
            gpib_string = 'VAVG ';
            if ~isnumeric(value)
                error('Invalid input');
            end
            obj.Write([gpib_string num2str(value) ';']);
        end
        
        function set.sweep_points(obj, value)
            gpib_string = 'TRDEF TRA,%d;';

            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            if value > 1024, value = 1024; end
            if value < 3, value = 3; end
            
            gpib_string = sprintf(gpib_string, uint32(value));
            obj.Write(gpib_string);
        end
   end
end