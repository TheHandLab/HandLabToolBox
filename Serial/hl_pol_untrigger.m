% turn OFF continuous output from polhemus
switch pol.device;
    case {'patriot'}
        fprintf(polhemus,'%c', 'p');        % turn OFF 'continuous' output mode
    case {'fastrak'}
        fprintf(polhemus,'%c','c');         % turn OFF 'continuous' output mode
end;