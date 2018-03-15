% turn ON continuous output from polhemus
function hl_robot_SendCmd(port, command)

hl_robot_SendBin(port, [255 1 command]);                                   % send packet framing header byte                                            % send the command ID value as passed to the function

end
