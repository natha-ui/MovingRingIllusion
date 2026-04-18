function imgb = genarrowsize(imga, direction)
    [totalWidth, N, ~] = size(imga); % img dim (in case it changes)
    
    ax = N/2;
    ay = totalWidth/2;

    arrlen = 40;
    arrwid = 5;
    pointerlen = 15;
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
    
    imga = insertShape(imga, 'FilledRectangle', lline, 'Color', 'black', 'Opacity', 1);
    imga = insertShape(imga, 'FilledPolygon', lpointer, 'Color', 'black', 'Opacity', 1);
    imga = insertShape(imga, 'FilledRectangle', rline, 'Color', 'black', 'Opacity', 1);
    imga = insertShape(imga, 'FilledPolygon', rpointer, 'Color', 'black', 'Opacity', 1);
    imga = insertShape(imga, 'FilledRectangle', uline, 'Color', 'black', 'Opacity', 1);
    imga = insertShape(imga, 'FilledPolygon', upointer, 'Color', 'black', 'Opacity', 1);
    imga = insertShape(imga, 'FilledRectangle', dline, 'Color', 'black', 'Opacity', 1);
    imga = insertShape(imga, 'FilledPolygon', dpointer, 'Color', 'black', 'Opacity', 1);
    imgb = imga;
end
