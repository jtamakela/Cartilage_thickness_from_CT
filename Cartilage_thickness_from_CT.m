function [PROFILES_NORMALIZED, PROFILES_ORIGINAL, info] = Cartilage_thickness_from_CT
%% m-file for analysing cartilage thickness from CT images
%% Intended for Mach-1 measurements.

%% (c) Janne Mäkelä October / 2018
% #Click on the measurement location and measure

function [Thicknesses, info] = Cartilage_thickness_from_CT

%Calculates cartilage thickness from a chosen location

clear all, close all, clc

%Preallocating the final parameters
Thicknesses = [];
info = [];


% LOAD IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Dicoms, info] = load_dicoms;

%Dicoms = Dicoms.*info.RescaleSlope+info.RescaleIntercept; %Uses the same pixel values as Analyze (The script is optimized for this scale)
% Otherwise handles data using native pixel values (original, short integer value)

dicom_slider(Dicoms,100) %Using dicom_slider.m function for viewing

%Orienting the figures
[Dicoms_x Dicoms_y] = orientation(Dicoms);

%TEMP
if exist('SUBIM_x')
Dicoms_x = SUBIM_x;
Dicoms_y = SUBIM_y;
end

%Options to display
% dicom_slider(Dicoms_x,100) %Using dicom_slider.m function for viewing
% dicom_slider(Dicoms_y,100) %Using dicom_slider.m function for viewing


%Mean image for picking the measurement point
dicom_mask = mean(Dicoms,3);
figure(1);
colormap jet
imagesc(dicom_mask)
axis equal;
hold on;
title('Pick your poison'); %


% % % % % % % % % % % % % % % % % % % % % % % % % % %

%Choose the location
[xcoord ycoord] = ginput(1);
pause(0.5)
plot(xcoord,ycoord,'+','markersize', 40)

%Displaying the chosen location from two angles
%Calculating the thickness


slice_x = Dicoms_x(:,:,round(xcoord));
slice_y = Dicoms_y(:,:, round(ycoord));

thickness = imdistancecalculator(slice_x,slice_y, xcoord, ycoord);












end




%%
function [Dicoms, info] = load_dicoms()
%Loading first the dicoms

path = uigetdir; %Choose the folder where the DICOMS are

f = filesep; %Checks what's the file separator for current operating system (windows,unix,linux)

dicomnames = dir([num2str(path) f '*.dcm*']); %Read dicoms.
disp(['Folder: ', dicomnames(1).folder]); %display folder
%Dicom info
info = dicominfo([num2str(path) f dicomnames(1).name]);

h = waitbar(0,'Loading dicoms, please wait...'); %Display waitbar

%Import dicomsdicom_slider(SUBIM_x,100) %Using dicom_slider.m function for viewing
% % % % % % % % % % % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Preallocating to save speed (With 2.08s, without, 2.56s on i5-6267U processor)
temp = dicomread([num2str(path) f dicomnames(1).name]);
Dicoms= int16(zeros(size(temp,1),size(temp,2), length(dicomnames)));

%Ali's figures are upside down
for i = 1:length(dicomnames)
    Dicoms(:,:,length(dicomnames)+1-i)= dicomread([num2str(path) f dicomnames(i).name]); %Doing the flipping
    waitbar(i/length(dicomnames));
end
close(h);

end

%---------------------------------------------------------------------
% % % % % 
% % % % % function dicom_slider(Dicoms,x)
% % % % % % Function to use slider for image
% % % % % 
% % % % % switch nargin
% % % % %     case 2
% % % % %         fig=figure(x); %Uses the same figure
% % % % %     case 1
% % % % %         fig = figure;
% % % % % end
% % % % % 
% % % % % Stack = Dicoms;
% % % % % 
% % % % % koko = size(Stack,3);
% % % % % 
% % % % % %fig=figure;
% % % % % set(fig,'Name','Image','Toolbar','figure');%,...
% % % % % %'NumberTitle','off')
% % % % % % Create an axes to plot in
% % % % % axes('Position',[.15 .05 .7 .9]);
% % % % % % sliders for epsilon and lambda
% % % % % slider1_handle=uicontrol(fig,'Style','slider','Max',koko,'Min',1,...
% % % % %     'Value',2,'SliderStep',[1/(koko-1) 10/(koko-1)],...
% % % % %     'Units','normalized','Position',[.02 .02 .14 .05]);
% % % % % uicontrol(fig,'Style','text','Units','normalized','Position',[.02 .07 .14 .04],...
% % % % %     'String','Choose frame');
% % % % % % Set up callbacks
% % % % % vars=struct('slider1_handle',slider1_handle,'Stack',Stack);
% % % % % set(slider1_handle,'Callback',{@slider1_callback,vars});
% % % % % plotterfcn(vars)
% % % % % % End of main file
% % % % % 
% % % % % % Callback subfunctions to support UI actions
% % % % %     function slider1_callback(~,~,vars)
% % % % %         % Run slider1 which controls value of epsilon
% % % % %         plotterfcn(vars)
% % % % %     end
% % % % % 
% % % % %     function plotterfcn(vars)
% % % % %         % Plots the image
% % % % %         %imshow(vars.Stack(:,:,round(get(vars.slider1_handle,'Value'))));
% % % % %         imagesc(vars.Stack(:,:,round(get(vars.slider1_handle,'Value'))));
% % % % %         axis equal;
% % % % %         title(num2str(get(vars.slider1_handle,'Value')));
% % % % %         
% % % % %     end
% % % % % end

%---------------------------------------------------------------------

function [SUBIM_x SUBIM_y] = orientation(Dicoms)
%Creates two image stacks from two different directions

%Preallocating for efficiancy
SUBIM_x = ones(size(Dicoms,1), size(Dicoms,2), size(Dicoms,3));
SUBIM_y = SUBIM_x;

h = waitbar(0,'X-direction, please wait...'); %Display waitbar

for i = 1:size(Dicoms,2)
    for j = 1:size(Dicoms,3)
        SUBIM_x(j,:,i) = Dicoms(:,i,j);
    end
    waitbar(i/size(Dicoms,2));
end

close(h)


h = waitbar(0,'Y-direction, please wait...'); %Display waitbar

for i = 1:size(Dicoms,2)
    for j = 1:size(Dicoms,3)
        SUBIM_y(j,i,:) = Dicoms(:,i,j);
    end
    waitbar(i/size(Dicoms,2));
end

close(h)

end

%---------------------------------------------------------------------

function [thickness] = imdistancecalculator(slice_x, slice_y, xcoord, ycoord)
%Drawing and calculating

%Preallocating
thickness = 0;
t = figure(99);
figchoice = 1000;
subplot(2,1,1)
imagesc(slice_x);
title('X-direction ->')
axis equal;
line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice

subplot(2,1,2)
imagesc(slice_y);
title('Y-direction -^')
axis equal;
line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice



while figchoice ~= 13
    
    % This is just to assure that there exists no empty position
    if exist('position')
        
        if isempty(position)
            clear position
        end
    end    
    
    %Checking existence
    if exist('position')
        subplot(2,1,1)
        imagesc(slice_x);
        title('X-direction ->')
        axis equal;
        line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice
        h1 = imline(gca,position(:,1),position(:,2));
        subplot(2,1,2)
        imagesc(slice_y);
        title('Y-direction -^')
        axis equal;
        line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice
        h2 = imline(gca,position(:,1),position(:,2));
    end
    % drawsubplot(2)
    
    % % %
    pause %This pause waits for the user's input
    % % %
    %And returns what subplot is used
    figchoice = double(get(t,'CurrentCharacter'))
    
    
    
    % % % Playing with the lines
    if figchoice == 49 %1-button
        
        subplot(2,1,1)
        imagesc(slice_x);
        title('X-direction ->')
        axis equal;
        line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice
        if exist('position')
            h1 = imline(gca,position(:,1),position(:,2));
        else
            h1 = imline;
        end
        position = wait(h1);
        subplot(2,1,2)
        imagesc(slice_y);
        title('Y-direction -^')
        axis equal;
        line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice
        %Calulating the new location 
        h2 = h1;
        %And displaying
        h2 = imline(gca,position(:,1),position(:,2));
    elseif figchoice == 50
        
        subplot(2,1,2)
        imagesc(slice_y);
        title('Y-direction -^')
        axis equal;
        line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice
        if exist('position')
            h2 = imline(gca,position(:,1),position(:,2));
        else
            h2 = imline;
        end
        position = wait(h2);
        subplot(2,1,1)
        imagesc(slice_x);
        title('X-direction ->')
        axis equal;
        line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice
        %Calculating the new location
        h1 = h2;
        %And displaying
        h1 = imline(gca,position(:,1),position(:,2));
    end
    
    
end %while



%thickness = sqrt(a^2+b^2+c^2)


%%

end %function

%---------------------------------------------------------------------
% % % % % %
% % % % % %     function drawsubplot(which)
% % % % % %         % Draws the subplots with lines
% % % % % %         if which == 1
% % % % % %             subplot(2,1,1)
% % % % % %             imagesc(slice_x);
% % % % % %             axis equal;
% % % % % %             line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice
% % % % % %         end
% % % % % %         if which == 2
% % % % % %             subplot(2,1,2)
% % % % % %             imagesc(slice_y);
% % % % % %             axis equal;
% % % % % %             h = line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice
% % % % % %         end
% % % % % %     end















end








