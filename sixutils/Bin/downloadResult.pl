
use strict;
use FindBin;
use lib ("$FindBin::/afs/cern.ch/user/m/mcintosh/sixdesk/slap/Bin/perllib");

use TaskHandler;

my $th = new TaskHandler;

#$th->debugOn;

if ($#ARGV != 1)
{
  print "error: Both TaskGroupId and taskId must be specified \n";
  exit(2);
}

my $TaskGroupID = $ARGV[0];
$th->setTaskGroupId("$TaskGroupID");

my $taskId = $ARGV[1];
my $resultFile = "sixres.tar.gz";
my $fileName = "task-" . $taskId . "-" . $resultFile;

my $resultURL = "http://cpss.web.cern.ch/cpss/results/incoming/$fileName";
my $localFile = "sixres.tar.gz" ;

# $th->setURL('http://pcitis06/');

my ($rc,$info) = $th->downloadResult($resultURL, $localFile);

if ($rc==1)
{
  print "error: $info\n";
  exit(1);
}
else
{
    my %data = %{$info};
    my @taskList = split (/\, /,$data{'ReadyTasks'} );
    print "ResultsDownloaded: \n";
    print "ContentLength: $data{'ContentLength'}\n";
    print "OutputOk: $data{'OutputOk'}\n";

}
