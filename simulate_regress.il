


procedure(simulate_regress()
    pwd=getWorkingDir()
    cvid=deGetCellView()
    lib = cvid~>libName
    cell = cvid~>cellName
    view = cvid~>viewName
    rundir=strcat("~/simulation/"  cell "/spectre/" view "/netlist/" )
    output_file=strcat(rundir "corner_info.scs")
    if(! isFile(output_file) then
    	file=outfile(output_file "w")
    	string_to_print="#File created by the script simulate_regress.il\n#Mail to rakeshkk@ee.iitb.ac.in\n"
    	fprintf(file string_to_print);
    	string_to_print="#corners\n#(SS,SS_res,TT_cap),80\n#(TT,FF_res,FF_cap),40\n#end_corners\n\n\n#process\n(SS,SS_res,TT_cap)\n(TT,FF_res,FF_cap)\n#end_process\n\n#temp\n80\n40\n#end_temp\n\n"
    	fprintf(file string_to_print);
	string_to_print="#measure\nresult=dcOpInfo\n#measure_this\nRegion_of_M3=getData(\"I0.M13\")~>region\n#print_this\nRegion_of_M3\n#end_print_this\n#end_measure_this\n#measure_this\n#end_measure_this\n#end_measure"
    	fprintf(file string_to_print);
    	close(file);
    )
    command=strcat("gedit " output_file)
    ipcProcess=ipcBeginProcess(command)
    ipcWait(ipcProcess);
    cmd=strcat("perl " "/home/users/rakeshkk/scripts/cross_corner_sim/simulate_regress.pl " rundir ";read")
    ipcBeginProcess(strcat("konsole -e " cmd ))
);

hiSetBindKey("Schematics" "Ctrl<Key>Q" "simulate_regress()")
