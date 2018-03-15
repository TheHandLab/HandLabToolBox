% turn ON continuous output from polhemus
switch pol.device
    case {'liberty'}
        fprintf(polhemus,'%c','c');                                         % turn ON 'continuous' output mode        
    case {'patriot'}
        fprintf(polhemus,'Q0');                                             % reset timestamp and framecount to 0
        fprintf(polhemus,'c','async');                                      % turn ON 'continuous' output mode
    case {'fastrak'}
        fprintf(polhemus,'%c','C');                                         % turn ON 'continuous' output mode
end