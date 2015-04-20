#!/usr/bin/perl
#Script by Rakesh K K, 13307R007


#=comments
#Test part here
#$rundir="/home/users/rakeshkk/simulation/Power_detector_with_Eq/spectre/schematic/test";
#print "$rundir\n";
#=cut



$rundir=$ARGV[0];
open LOGFILE, ">$rundir/corner_info.log";
if(! -e "$rundir/corner_info.scs"){
    print LOGFILE "corner_info.scs file is missing at the directory $rundir\n";
    exit;
}
system("rm -rf $rundir/../cross_corner");

open CORNER, "$rundir/corner_info.scs" or die "System failure\n";
@keywords=qw(corners temp process measure measure_this print_this);
@end_keywords=qw();
push  @end_keywords,"end$_ " foreach (@keywords);
@corners=();
@temp=();
@process=();
$keyword_found=0;
$measurement_now=0;
%measure_commands=();
%print_commands=();
#Analysing the file corner_info.scs
while($line=<CORNER>){
    chomp($line);
    $line=~s/[\s\t]*$//;
    print "$.:$line\n";
    if($line!~/^#/ && $keyword_found==0){
    	print LOGFILE "Ignoring the line $.:Not inside keywords\n";
    }
    if($line!~/^#/ && $keyword_found==1 && $line=~/\S/){   
    	if($keyword_processing eq "corners"){
	    push @corners,$line;
    	}
	if($keyword_processing eq "temp"){
	    push @temp,$line;
	    print "Temp is $line\n";
	}
	if($keyword_processing eq "process"){	
	    push @process,$line;
	}
	if($measurement_now=1 and $line=~/^result\s*=\s*(.+?)\s*$/i){
	    $result=$1;
	    $measure_commands{$result}="";
	    $print_commands{$result}="";
	}
	if($keyword_processing eq "measure_this" and $measurement_now==1){
	    $measure_commands{$result}=$measure_commands{$result}.$line."\n";
	}
	if($keyword_processing eq "print_this" and $measurement_now==1 and $measure_this==1 and $print_this==1){
	    if($line!~/^result/){
    	    	$print_commands{$result}=$print_commands{$result}.$line."\n";
	    }
	}
    }
    if($line=~/^#(\w+)/ && (grep(/^$1$/,@keywords) || grep(/^$1$/,@end_keywords))){
    	if($line=~/#end/){
	    $keyword_processing="";
	    $keyword_found=0;
	    if($1 eq "measure"){
	    	$measurement_now=0;
	    }
	    if($1 eq "measure_this"){
	    	$measure_this=0;
	    }
	    if($1 eq "print_this"){
	    	$print_this=0;
	    }
	}
	else{
	    $keyword_processing=$1;
	    $keyword_found=1;
	    print "Keyword found and line is $line\n";
	    if($keyword_processing eq "measure"){
	    	$measurement_now=1;
	    }
	    if($keyword_processing eq "measure_this"){
	    	$measure_this=1;
	    }
	    if($keyword_processing eq "print_this"){
	    	$print_this=1;
	    }
	}
    }    
} 

if(@corners!=0){
    @temp=();
    @process=();
    foreach $corner (@corners){
    	print "$corner\n";
    	$process=$1 if($corner=~/\((.+)\)/);
	$temp=$1 if($corner=~/\(.+\),([+-]*\d+)\s*$/);
	print "Directory $rundir/../cross_corner/process_$process\_temp_$temp/netlist/\n";
    	if(! -d "$rundir/../cross_corner/process_$process\_temp_$temp/netlist/"){
	    print "Creating the directory $rundir/../cross_corner/process_$process\_temp_$temp/netlist/\n";
	    system("mkdir -p $rundir/../cross_corner/process_$process\_temp_$temp/netlist/");	    
	}
	`cp $rundir/input.scs $rundir/../cross_corner/process_$process\_temp_$temp/netlist/`;
	$model_file=`grep -P 'include.+section=' $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs`;
	chomp($model_file);
	@model_file=split(/\n/,$model_file);
	$model_file=$model_file[0];
	$model_file=$1 if($model_file=~/include \"(.+)\"/g);
	print "Model file is $model_file\n";
    	print "sed -i '/^include/d' $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs\n";
	`sed -i 's/temp=[0-9.+-]* /temp=$temp /g' $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs`;
	`sed -i '/^include/d' $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs`;
	@process_corners=split(/,/, $process);
	foreach $process_corner (@process_corners){
	    system("echo 'include \"$model_file\" section=$process_corner' >> $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs");
	} 
	push @psf_dirs,"$rundir/../cross_corner/process_$process\_temp_$temp/psf";
	`touch $rundir/../cross_corner/process_$process\_temp_$temp/netlist/runSimulation`;
        `echo '#Created by the script. Author:Rakesh K K, 13307R007'  >> $rundir/../cross_corner/process_$process\_temp_$temp/netlist/runSimulation`;  
	`echo '/cad/cadence/MMSIM121/tools/bin/spectre  $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs +escchars +log $rundir/../cross_corner/process_$process\_temp_$temp/psf/spectre.out -format psfxl -raw $rundir/../cross_corner/process_$process\_temp_$temp/psf  +lqtimeout 900 -maxw 5 -maxn 5'  >> $rundir/../cross_corner/process_$process\_temp_$temp/netlist/runSimulation`; 
	`echo 'source $rundir/../cross_corner/process_$process\_temp_$temp/netlist/runSimulation' >> $rundir/../cross_corner/runSimulation`;
    }
    system("sh $rundir/../cross_corner/runSimulation"); 
}
else{
    foreach $process_with_brackets (@process){
    	$process=$1 if($process_with_brackets=~/\((.+)\)/);
    	foreach $temp (@temp){
	    print "Process is $process and Temp is $temp\n";
    	    if(! -d "$rundir/../cross_corner/process_$process\_temp_$temp/netlist"){
	    	print "Creating the directory $rundir/../cross_corner/process_$process\_temp_$temp/netlist\n";
	    	system("mkdir -p $rundir/../cross_corner/process_$process\_temp_$temp/netlist");	    
	    }
	    `cp $rundir/input.scs $rundir/../cross_corner/process_$process\_temp_$temp/netlist/`;
	    $model_file=`grep -P 'include.+section=' $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs`;
	    chomp($model_file);
	    @model_file=split(/\n/,$model_file);
	    $model_file=$model_file[0];
	    $model_file=$1 if($model_file=~/include \"(.+)\"/g);
	    print "Model file is $model_file\n";
    	    print "sed -i '/^include/d' $rundir/../cross_corner/process_$process\_temp_$temp/input.scs\n";
	    `sed -i 's/temp=[0-9.+-]* /temp=$temp /g' $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs`;
	    `sed -i '/^include/d' $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs`;
	    @process_corners=split(/,/, $process);
	    foreach $process_corner (@process_corners){
	    	system("echo 'include \"$model_file\" section=$process_corner' >> $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs");
	    } 
	    push @psf_dirs,"$rundir/../cross_corner/process_$process\_temp_$temp/psf";
	    `touch $rundir/../cross_corner/process_$process\_temp_$temp/netlist/runSimulation`;
	    `touch $rundir/../cross_corner/runSimulation`;
	    `echo '#Created by the script. Author:Rakesh K K, 13307R007'  >> $rundir/../cross_corner/process_$process\_temp_$temp/netlist/runSimulation`;  
	    `echo '/cad/cadence/MMSIM121/tools/bin/spectre  $rundir/../cross_corner/process_$process\_temp_$temp/netlist/input.scs +escchars +log $rundir/../cross_corner/process_$process\_temp_$temp/psf/spectre.out -format psfxl -raw $rundir/../cross_corner/process_$process\_temp_$temp/psf  +lqtimeout 900 -maxw 5 -maxn 5'  >> $rundir/../cross_corner/process_$process\_temp_$temp/netlist/runSimulation`; 
	    `echo 'source $rundir/../cross_corner/process_$process\_temp_$temp/netlist/runSimulation' >> $rundir/../cross_corner/runSimulation`;
	}
    }
    system("sh $rundir/../cross_corner/runSimulation"); 
}


close(CORNER);

open MEASUREMENT, ">$rundir/../cross_corner/measurement.ocn" or die "System failure\n";

foreach $psf_dir (@psf_dirs){
    print MEASUREMENT "out_file=outfile(\"$psf_dir/../result.csv\" \"w\")\n";
    print MEASUREMENT "openResults(\"$psf_dir\")\n";
    foreach $sim_type (keys(%measure_commands)){
    	print MEASUREMENT "selectResults('$sim_type)\n";
	print MEASUREMENT $measure_commands{$sim_type}."\n";
	@to_save=split(/\n/,$print_commands{$sim_type});   
	foreach $to_save (@to_save){  
    	    print MEASUREMENT "fprintf(out_file \"$to_save,%s \\n\" pcExprToString($to_save))\n";
	    print LOGFILE "TO SAVE: $to_save\n";
	}
    }
    print MEASUREMENT "close(out_file)\n";
}
print MEASUREMENT "exit";
close(MEASUREMENT);

system("ocean < $rundir/../cross_corner/measurement.ocn");

open FINAL_CSV, ">$rundir/../cross_corner/results.csv" or die "Can not open file\n";
%results_of_corners={};
print FINAL_CSV "process,,,,temp,";
for $key (keys(%print_commands)){
    	$to_save=$print_commands{$key};
	chomp($to_save);
    	push @to_save,$to_save;
	print LOGFILE $print_commands{$key};
}
%seen=();
@to_save = grep { ! $seen{$_} ++ } @to_save;
print FINAL_CSV "$_," foreach @to_save;
print FINAL_CSV "\n";
for $psf_dir (@psf_dirs){
    print $psf_dir."\n";
    @results_for_this_corner=();
    if($psf_dir=~/process_(.+)_temp_(.+)\/psf/){
    	$process=$1;
	$temp=$2;
	print "$process and $temp\n";
    }
    open RESULTCSV, "$psf_dir/../result.csv";
    @file_content=<RESULTCSV>;
    close(RESULTCSV);
    foreach $file_content (@file_content){
    	chomp($file_content);
	print $file_content."\n";
	@line_contents=split(/,/,$file_content);
	    	push @results_for_this_corner,@line_contents;
	%results_for_this_corner=@results_for_this_corner;
    }
    print FINAL_CSV "$process,$temp,";
    
    for $to_save (@to_save){
    	chomp($to_save);
    	print "TO SAVE : $to_save \t RESULTS: $results_for_this_corner{$to_save}\n";
    	print LOGFILE "TO SAVE:$to_save --> $results_for_this_corner{$to_save}\n";
    	print FINAL_CSV $results_for_this_corner{$to_save}.",";
    }
    print FINAL_CSV "\n";
}
close(FINAL_CSV);
close(LOGFILE);
system("/usr/bin/soffice $rundir/../cross_corner/results.csv&");