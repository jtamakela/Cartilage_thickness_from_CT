function [Thicknesses, XCOORD, YCOORD] = Cartilage_thickness_from_CT
%% m-file for analysing cartilage thickness from CT images
%% Developed for Mach-1 measurements.
%% This code is available at https://github.com/jtamakela/Cartilage_thickness_from_CT

%% (c) Janne Mäkelä November / 2018
% Click on the measurement location and measure

%Calculates cartilage thickness from a chosen location in CT image.
%Saves the coordinates where thicknesses have been calculated. 

% Currently converts the image stack so that the sample is observed from above (similarly as in Mach-1). 
% This is done inside load_dicoms (~line 125 ->)

clear all, close all, clc

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% CHECK THIS ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !
% RESOLUTION OF THE CT STACK
resolution = [20 20 20]; %[Z X Y]. Voxel size in micrometers. Defines also the aspect ratio in figures
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %


aspectratio = resolution./min(resolution); %Drawing the figures based on the given resolution

%Preallocating the final parameters
Thicknesses = [];
info = [];


% LOAD IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Dicoms, info] = load_dicoms;

% % This is for rescaling the voxel values
% % Not necessary if imagesc is used
%Dicoms = Dicoms.*info.RescaleSlope+info.RescaleIntercept;
% % Otherwise handles data using native pixel values (original, short integer value)


%Orienting the figures
[Dicoms_x, Dicoms_y] = orientation(Dicoms);

% %%This is needed only when evaluating selections
% if exist('SUBIM_x')
%     Dicoms_x = SUBIM_x;
%     Dicoms_y = SUBIM_y;
% end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % Options to display all the slices using dicom_slider function
% dicom_slider(Dicoms,100)
% dicom_slider(Dicoms_x,100) %Using dicom_slider.m function for viewing
% dicom_slider(Dicoms_y,100) %Using dicom_slider.m function for viewing
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

%Mean image for picking the measurement point
dicom_mask = mean(Dicoms,3);
figure(1);
colormap jet
imagesc(dicom_mask)
axis equal;
hold on;


% % % % % % % % % % % % % % % % % % % % % % % % % % %
% This marks the number of locations
location_i = 1;

%Choose the location
figure(1);
pause(1) %Reduces crashing
title('Pick the location. Press enter to quit'); %

% question = menu('Satisfied?','1) Yes','2) No'); %Option to fall back should be added
question = 1; %"Satisfied?"

[xcoord, ycoord] = ginput(1);
while ~isempty(xcoord) %If enter is not pressed
    
    plot(xcoord,ycoord,'+','markersize', 40, 'Linewidth', 1.5)
    text(xcoord+20,ycoord-20,num2str(location_i),'HorizontalAlignment','center','fontsize', 20);
    
    %Displaying the chosen location from two angles
    %Calculating the thickness
    
    
    slice_x = Dicoms_x(:,:,round(xcoord));
    slice_y = Dicoms_y(:,:, round(ycoord));
    
    Dimensions = imdistancecalculator(slice_x,slice_y, xcoord, ycoord, aspectratio); %[Z X Y]
    
    if Dimensions ~= [1, 2, 3] %If user is not satisfied with the location, imdistancecalulator returns [1, 2, 3];
    Thicknesses(location_i) = sqrt( (resolution(1)*Dimensions(1))^2 + (resolution(2)*Dimensions(2))^2 + (resolution(3)*Dimensions(3))^2);
    
    disp(['Measured thickness in #', num2str(location_i), ' is ', num2str(Thicknesses(location_i)), ' um'])
    
    XCOORD(location_i) = xcoord; %Saving
    YCOORD(location_i) = ycoord; 

    save('THICKNESS_temp.mat','Thicknesses', 'XCOORD', 'YCOORD') % In case the code crashes

    
    location_i = location_i+1;
    end
    
    figure(1);
    pause(1) %Reduces crashing
    title('Pick the location. Press enter to quit'); %
    [xcoord, ycoord] = ginput(1);
    
end

delete 'THICKNESS_temp.mat' %No need for this if the code executes succesfully

disp(['- - - - - - - - - - - - - - - - - '])
disp(['- - - - - - - DONE - - - - - - - '])
disp(['- - - - - - - - - - - - - - - - - '])

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

for i = 1:length(dicomnames)
    % Dicoms(:,:,i)= dicomread([num2str(path) f dicomnames(i).name]); %Using native stack
    % Ali's figures are upside down
    Dicoms(:,:,length(dicomnames)+1-i)= fliplr(dicomread([num2str(path) f dicomnames(i).name])); %Flipping the stack (up=down, left=right)
    waitbar(i/length(dicomnames));
end
close(h);

end

%---------------------------------------------------------------------

function dicom_slider(Dicoms,x) %(Stack, figure number)
% Function to use slider for image

switch nargin
    case 2
        fig=figure(x); %Uses the same figure
    case 1
        fig = figure;
end

Stack = Dicoms;

koko = size(Stack,3);

%fig=figure;
set(fig,'Name','Image','Toolbar','figure');%,...
%'NumberTitle','off')
% Create an axes to plot in
axes('Position',[.15 .05 .7 .9]);
% sliders for epsilon and lambda
slider1_handle=uicontrol(fig,'Style','slider','Max',koko,'Min',1,...
    'Value',2,'SliderStep',[1/(koko-1) 10/(koko-1)],...
    'Units','normalized','Position',[.02 .02 .14 .05]);
uicontrol(fig,'Style','text','Units','normalized','Position',[.02 .07 .14 .04],...
    'String','Choose frame');
% Set up callbacks
vars=struct('slider1_handle',slider1_handle,'Stack',Stack);
set(slider1_handle,'Callback',{@slider1_callback,vars});
plotterfcn(vars)
% End of main file

% Callback subfunctions to support UI actions
    function slider1_callback(~,~,vars)
        % Run slider1 which controls value of epsilon
        plotterfcn(vars)
    end

    function plotterfcn(vars)
        % Plots the image
        %imshow(vars.Stack(:,:,round(get(vars.slider1_handle,'Value'))));
        imagesc(vars.Stack(:,:,round(get(vars.slider1_handle,'Value'))));
        axis equal;
        title(num2str(get(vars.slider1_handle,'Value')));
        
    end
end

%---------------------------------------------------------------------

function [SUBIM_x, SUBIM_y] = orientation(Dicoms)
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

function Dimensions = imdistancecalculator(slice_x, slice_y, xcoord, ycoord, aspectratio)
%Drawing and calculating

clear position

%Preallocating
thickness = 0;
t = figure(2);
set(t,'Name','Please press Enter when ready','Toolbar','figure');
%t = figure('Name', 'Please press Enter when ready');
% figure('units','normalized','outerposition',[0 0 1 1])
figchoice = 1000;
subplot(1,2,1)
imagesc(slice_x);
daspect(aspectratio)
% axis equal;

%title('X-direction ->', 'interpreter', 'none')
title('Choose your angle: X -> [1]');

line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice

subplot(1,2,2)
imagesc(slice_y);
daspect(aspectratio)
% axis equal;

%title('Y-direction -^', 'interpreter', 'none')
title('Choose your angle: Y -^ [2]');

line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice

%Allocating lines
%X-axis figure
leftpoint1 = ycoord;
rightpoint1 = ycoord;
%Y-axis figure
leftpoint2 = xcoord;
rightpoint2 = xcoord;


question = menu('Satisfied?','1) Yes','2) No'); %Option to fall back should be added

if question == 1

while figchoice ~= 13
    
    % This is just to assure that there exists no empty position
    if exist('position')
        if isempty(position.position1) || isempty(position.position2)
            clear position
        end
    end
    
    %Checking existence and displaying the current situation
    if exist('position')
        subplot(1,2,1)
        imagesc(slice_x);
        %title('X-direction ->', 'interpreter', 'none')
        title('Choose your angle: X [1]');
        daspect(aspectratio)
        % axis equal;
        
        line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice
        h1 = imline(gca,position.position1);
        subplot(1,2,2)
        imagesc(slice_y);
        title('Y-direction -^', 'interpreter', 'none')
        title('Choose your angle: Y -^ [2]');
        daspect(aspectratio)
        % axis equal;
        
        
        line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice
        h2 = imline(gca,position.position2);
    end
    % drawsubplot(2)
    
    % % %
    pause %This pause waits for the user's input
    % % %
    %And returns what subplot is used
    figchoice = double(get(t,'CurrentCharacter'))
    
    
    
    % % % Playing with the lines
    if figchoice == 49 %1-button
        
        subplot(1,2,1)
        imagesc(slice_x);
        %title('X-direction ->', 'interpreter', 'none')
        title('Choose your angle: X -> [1]');
        daspect(aspectratio)
        % axis equal;
        
        line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice
        if exist('position')
            h1 = imline(gca,position.position1);
        else
            h1 = imline;
        end
        position.position1 = wait(h1);
        subplot(1,2,2)
        imagesc(slice_y);
        %title('Y-direction -^', 'interpreter', 'none')
        title('Choose your angle: Y -^ [2]');
        daspect(aspectratio)
        % axis equal;
        
        
        line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice
        
        %Calulating the new location
        % Z-axis
        highpoint = position.position1(1,2);
        lowpoint = position.position1(2,2);
        
        %These are used in the X-axis figure
        % With these the angle can change
        leftpoint1 = position.position1(1,1);
        rightpoint1 = position.position1(2,1);
        
        
        position.position2 = [leftpoint2 highpoint;  rightpoint2 lowpoint];
        
        %And displaying
        h2 = imline(gca,position.position2);
    elseif figchoice == 50
        
        subplot(1,2,2)
        imagesc(slice_y);
        title('Choose your angle: Y -^ [2]');
        daspect(aspectratio)
        % axis equal;
        
        
        line([xcoord,xcoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the x-slice
        if exist('position')
            h2 = imline(gca,position.position2);
        else
            h2 = imline;
        end
        position.position2 = wait(h2);
        subplot(1,2,1)
        imagesc(slice_x);
        title('Choose your angle: X -> [1]');
        daspect(aspectratio)
        % axis equal;
        
        
        line([ycoord,ycoord], [1, length(slice_x)],'Color','red','LineStyle','--') %Displays the y-slice
        %Calculating the new location
        % Z-axis
        highpoint = position.position2(1,2);
        lowpoint = position.position2(2,2);
        %These are used in the X-axis figure
        % With these the angle can change
        leftpoint2 = position.position2(1,1);
        rightpoint2 = position.position2(2,1);
        
        position.position1 = [leftpoint1 highpoint;  rightpoint1 lowpoint];
        %And displaying
        h1 = imline(gca,position.position1);
    end
    
    
end %while

Dimensions = [(highpoint-lowpoint), (rightpoint1 - leftpoint1), (rightpoint2 - leftpoint2)]; %[Z X Y]

elseif question == 2
    
    Dimensions = [1, 2, 3];
    figchoice = 13; %Stops the execution
    
end %if question

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
% % % % % % end








