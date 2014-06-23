
use strict;
use FindBin;
use lib ("$FindBin::/afs/cern.ch/user/m/mcintosh/sixdesk/slap/Bin/perllib");

use TaskHandler;

my $th = new TaskHandler;

#$th->debugOn;

# creating a new TaskGroup

if ($#ARGV != 5)
{
  print "error: TaskName, TaskGroupId, ProgramId and path to data files must be specified \n";
  exit(2);
}

my $TaskGroupName = $ARGV[0];
my $Description = $ARGV[1];
my $ProgramId = $ARGV[2];
my $Status = $ARGV[3];
my $Priority = $ARGV[4];
my $Comments = $ARGV[5];

$th->setTaskGroupName("$TaskGroupName");
$th->setDescription("$Description");
$th->setProgramId("$ProgramId");
$th->setStatus("$Status");
$th->setPriority("$Priority");
$th->setComments("$Comments");   

$th->setURL('http://cpss.web.cern.ch/cpss/createTasks/createTaskgroup.asp');
#$th->setURL('http://pcitis06/');
my ($rc,$info) = $th->createTaskGroup();

if ($rc==1)
{
  print "error: $info\n";
  exit(1);
}
else
{
    my %data = %{$info};
#    foreach my $key (keys %data)
#    {
#      print $key . ": " . $data{$key} ."\n"; 
#    };
    print "TaskGroupID: $data{'TaskGroupID'}\n";
}
