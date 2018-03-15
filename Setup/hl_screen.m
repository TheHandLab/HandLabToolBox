Screen('Preference','VisualDebuglevel',3);                                  % remove welcome screen
AssertOpenGL;
whichScreen=0;                                                              % main window
window=Screen(whichScreen,'OpenWindow');                                    % open screen on main window
expt.black=BlackIndex(window);                                              % pixel value for black
expt.white=WhiteIndex(window);                                              % pixel value for white
Screen('FillRect',window,expt.black);                                       % blank screen
Screen('TextSize',window,expt.text_size);                                   % text size
Screen('TextStyle',window,0);                                               % text style
Screen('TextFont', window,'Arial');                                         % font