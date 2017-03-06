
use strict;
use FindBin;
$ScriptDir=$env{'SCRIPTDIR'};
use lib ("$FindBin::$ScriptDir/perl/lib");

use TaskHandler;

my $th = new TaskHandler;

# $th->debugOn();

if ($#ARGV != 10)
{
  print "error: TaskName, TaskGroupId, ProgramId and path to data files must be specified \n";
  print "error: along with TaskPriority, OsMin and OsMax, and CpuSpeedMin \n";
  print "error: and also CheckpointRestart, RequiredClientVersion and OutputFile. \n";
  exit(2);
}

my $batDir = '$ScriptDir/bats';
my $exeDir = '$ScriptDir/exes';

my $TaskName = $ARGV[0];
my $TaskGroupId = $ARGV[1];
my $ProgramId = $ARGV[2];
my $fileDir = "$ARGV[3]";
my $TaskPriority = $ARGV[4];
my $OsMin = $ARGV[5];
my $OsMax = $ARGV[6];
my $CpuSpeedMin = $ARGV[7];
my $CheckpointRestart = $ARGV[8];
my $RequiredClientVersion = $ARGV[9];
my $MainCommandOutputFile = $ARGV[10];

$th->setTaskName("$TaskName");
$th->setTaskPriority("$TaskPriority");     # low, normal,high
$th->setTaskgroupId("$TaskGroupId");
$th->setProgramId("$ProgramId");
$th->setOsMin("$OsMin");
$th->setOsMax("$OsMax");
$th->setCpuSpeedMin("$CpuSpeedMin");
$th->setCheckpointRestart("$CheckpointRestart");
$th->setRequiredClientVersion("$RequiredClientVersion");
#
$th->setDiskSpaceMin("512");
$th->setMemoryMin("64");
#
$th->setPreCommand("pre.bat"); 
$th->setPreCommandDirectory("");
$th->setPreCommandOutputFile("");
#
$th->setMainCommand("sixtrack.exe");
$th->setMainCommandDirectory("sixtrack");
$th->setMainCommandOutputFile("$MainCommandOutputFile");
#
$th->setPostCommand("post.bat");
$th->setPostCommandDirectory("");
$th->setPostCommandOutputFile("");
#
$th->setResultFiles("sixres.tar.gz");
#
$th->setNumberOfFiles("8");
$th->setFile01("$exeDir/gtar.exe");
$th->setFile02("$exeDir/gzip.exe");                 
$th->setFile03("$batDir/pre.bat");                 
$th->setFile04("$batDir/post.bat");                 
$th->setFile05("$fileDir/fort.2");
$th->setFile06("$fileDir/fort.3");                 
$th->setFile07("$fileDir/fort.8");                 
$th->setFile08("$fileDir/fort.16");                 
# ...
# FileN  Maximum of 10 with current TaskHandler
#
$th->setURL('http://cpss.web.cern.ch/cpss/cgi-bin/uploadTask.pl');
#$th->setURL('http://pcitis06.cern.ch/');

my ($rc,$info) = $th->uploadTask();

if ($rc==1)
{
  print "error: $info\n";
  exit(1);
}
else
{
   my %data = %{$info};
   print "TaskId: $data{'TaskId'}\n";

   # print "(rc,response)=($rc,$info)\n";
}
