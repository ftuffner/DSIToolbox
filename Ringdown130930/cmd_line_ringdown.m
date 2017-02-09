function [identmodel, xcon, plhs_3, plhs_4] =cmd_line_ringdown(sigdat, tstep, shftnnft, inpulses, known_modes, xcon)
%Just exposes the "private" Prony function so MATLAB can call it in a script.

[identmodel, xcon, plhs_3, plhs_4]=prgv2_5(sigdat, tstep, shftnnft, inpulses, known_modes, xcon);