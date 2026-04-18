function imgb = genarrowdir(imga, direction)
    [totalWidth, N, ~] = size(imga); % img dim (in case it changes)
    
    ax = N/2;
    ay = totalWidth/2;

    arrlen = 50;
    arrwid = 20;
    pointerlen = 20;
    line = NaN(4,1);
    pointer = NaN(6,1);

    switch direction
        case 'right'
            line = [ax-(arrlen)/2, ay-(pointerlen)/2, arrlen, arrwid];
            pointer = [ax+arrlen, ay, ax + arrlen - 2*pointerlen, ay-pointerlen, ax + arrlen - 2*pointerlen, ay+pointerlen];
        case 'left'
            line = [ax-(arrlen)/2, ay-(pointerlen)/2, arrlen, arrwid];
            pointer = [ax-arrlen, ay, ax - arrlen + 2*pointerlen, ay-pointerlen, ax - arrlen + 2*pointerlen, ay+pointerlen];
        case 'up'
            line = [ax-(arrwid)/2, ay-(arrlen-pointerlen)/2, arrwid, arrlen];
            pointer = [ax, ay-arrlen, ax-pointerlen, ay-arrlen+2*pointerlen, ax+pointerlen, ay-arrlen+2*pointerlen];
        case 'down'
            line = [ax-(arrwid)/2, ay-(arrlen+pointerlen)/2, arrwid, arrlen];
            pointer = [ax, ay+arrlen, ax-pointerlen, ay+arrlen-2*pointerlen, ax+pointerlen, ay+arrlen-2*pointerlen];
    end
    imga = insertShape(imga, 'FilledRectangle', line, 'Color', 'black', 'Opacity', 1);
    imga = insertShape(imga, 'FilledPolygon', pointer, 'Color', 'black', 'Opacity', 1);
    imgb = imga;
end
