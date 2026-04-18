% Script Name:      GenArrow.m
% Authors:          Andrew Isaac Meso, Nathan Masters & Chat GPT
% Date:             08/02/2026
% Purpose:          To generate an arrow that can be used within the moving
% stimulus with parapeters that can be specified by the user. 
% Version:          2.0
% Notes:            This version is inherited from a previous version used
% by Nathan Masters to explore the stimulus during development. More direct
% control of stimulus properties have been added here

%% A. Funtion
function imgb = GenArrow(IM, direction,Sz)
    [totalWidth, N, ~] = size(IM); % img dim (in case it changes)
    % INPUTS: 
    % IM - 2D image matrix for manipulation in function
    % direction - label either inwards or outwards or other 
    % Sz - the size of the arrow as proportion of the defaults running from
    % 0.5 to 1 for example

    % OUTPUT
    % imgb - this is an output matrix with the image of the arrow added
    % on.. 

    ax = N/2;
    ay = totalWidth/2;
    
    % setting conditions Feb 2026
    %arrlen = totalWidth/7.5;    % 40;
    %arrwid = totalWidth/60;
    arrlen = Sz*totalWidth/7.5;
    arrwid = totalWidth/60;
    pointerlen = totalWidth/20;
    line = NaN(4,1);
    pointer = NaN(6,1);
    outshift = 20;
    inshift = 5;

        switch direction
            case 'out'
            %right
                rline = [outshift-15+ax, ay-2, arrlen, arrwid];
                rpointer = [outshift+ax + arrlen, ay, outshift + ax + arrlen - pointerlen, ay-pointerlen, outshift+ax + arrlen - pointerlen, ay+pointerlen];
            %left
                lline = [ax-(arrlen-pointerlen)-outshift, ay-2, arrlen, arrwid];
                lpointer = [ax - arrlen - outshift, ay, ax - arrlen + pointerlen - outshift, ay-pointerlen, ax - arrlen + pointerlen - outshift, ay+pointerlen];
            %up
                uline = [ax-2, ay-(arrlen-pointerlen)-outshift, arrwid, arrlen];
                upointer = [ax, ay - arrlen - outshift, ax-pointerlen, ay - arrlen + pointerlen - outshift, ax+pointerlen, ay - arrlen + pointerlen - outshift];
            %down
                dline = [ax-2, ay-15+outshift, arrwid, arrlen];
                dpointer = [ax, ay + arrlen + outshift, ax-pointerlen, ay + arrlen - pointerlen + outshift, ax+pointerlen, ay + arrlen - pointerlen + outshift];
            case 'in'
            %right
                rline = [outshift+inshift+ax-15, ay-2, arrlen, arrwid];
                rpointer = [ax+inshift, ay, ax+pointerlen+inshift, ay-pointerlen, ax+pointerlen+inshift, ay+pointerlen];
            %left
                lline = [ax-(arrlen-pointerlen)-outshift-inshift, ay-2, arrlen, arrwid];
                lpointer = [ax-inshift, ay, ax-pointerlen-inshift, ay-pointerlen, ax-pointerlen-inshift, ay+pointerlen];
            %up
                uline = [ax-2, ay-(arrlen-pointerlen)-outshift-inshift, arrwid, arrlen];
                upointer = [ax, ay-inshift, ax-pointerlen, ay-pointerlen-inshift, ax+pointerlen, ay-pointerlen-inshift];
            %down
                dline = [ax-2, ay-15+outshift+inshift, arrwid, arrlen];
                dpointer = [ax, ay+inshift, ax-pointerlen, ay+pointerlen+inshift, ax+pointerlen, ay+pointerlen+inshift];
    end
    
    IM = insertShape(IM, 'FilledRectangle', lline, 'Color', 'black', 'Opacity', 1);
    IM = insertShape(IM, 'FilledPolygon', lpointer, 'Color', 'black', 'Opacity', 1);
    IM = insertShape(IM, 'FilledRectangle', rline, 'Color', 'black', 'Opacity', 1);
    IM = insertShape(IM, 'FilledPolygon', rpointer, 'Color', 'black', 'Opacity', 1);
    IM = insertShape(IM, 'FilledRectangle', uline, 'Color', 'black', 'Opacity', 1);
    IM = insertShape(IM, 'FilledPolygon', upointer, 'Color', 'black', 'Opacity', 1);
    IM = insertShape(IM, 'FilledRectangle', dline, 'Color', 'black', 'Opacity', 1);
    IM = insertShape(IM, 'FilledPolygon', dpointer, 'Color', 'black', 'Opacity', 1);
    imgb = rgb2gray(IM);
end
