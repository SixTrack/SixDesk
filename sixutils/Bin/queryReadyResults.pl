
use strict;
use FindBin;
use lib ("$FindBin::/afs/cern.ch/user/m/mcintosh/sixdesk/slap/Bin/perllib");

use TaskHandler;

my $th = new TaskHandler;

#$th->debugOn;

# creating a new TaskGroup

if ($#ARGV != 0)
{
  print "error: TaskGroupId must be specified \n";
  exit(2);
}
my $TaskGroupID = $ARGV[0];

$th->setTaskGroupId("$TaskGroupID");

$th->setURL('http://cpss.web.cern.ch/cpss/request/readyResults.asp');
#$th->setURL('http://pcitis06/');
my ($rc,$info) = $th->queryReadyResults();

if ($rc==1)
{
  print "error: $info\n";
  exit(1);
}
else
{
    my %data = %{$info};
    my @taskList = split (/\, /,$data{'ReadyTasks'} );
    print "TotalTasks: $data{'TotalTasks'}\n";
    print "ResultsReady: $data{'ResultsReady'}\n";
    print "DownloadUrlBase: $data{'ResultBaseUrl'}\n";
    print "ReadyTasks: $data{'ReadyTasks'}\n";
}
