% turn ON continuous output from polhemus
function hl_robot_SendBin(port, command)

fwrite(port, command);                                                    % send packet framing header byte                                            % send the command ID value as passed to the function

end
