
use strict;
use FindBin;
use lib ("$FindBin::Bin/perllib");

use TaskHandler;

my $th = new TaskHandler;

# $th->debugOn;

if ($#ARGV != 1)
{
  print "error: TaskId and TaskGroupId must be specified \n";
  exit(2);
}
my $TaskId = $ARGV[0];
my $TaskGroupId = $ARGV[1];

$th->setTaskId("$TaskId");
$th->setTaskGroupId("$TaskGroupId");
$th->setURL('http://cpss.web.cern.ch/cpss/request/deleteTask.asp');

my ($rc,$info) = $th->deleteTask();


if ($rc==1)
{
  print "error: $info";
  exit(1);
}
else
{
   my %data = %{$info};
   print "TaskId: " . $data{'TaskId'} . " in taskgroup " . $data{'TaskGroupId'} . " deleted\n";

   # print "(rc,response)=($rc,$info)\n";
}
