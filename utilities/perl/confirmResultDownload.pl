
use strict;
use FindBin;
$ScriptDir=$env{'SCRIPTDIR'};
use lib ("$FindBin::$ScriptDir/perl/lib");

use TaskHandler;

my $th = new TaskHandler;

#$th->debugOn;

# creating a new TaskGroup

if ($#ARGV != 0)
{
  print "error: The TaskId must be specified \n";
  exit(2);
}

my $taskid = $ARGV[0];
$th->setTaskId("$taskid");
$th->setURL('http://cpss.web.cern.ch/cpss/confirm/resultdownload.asp');
#$th->setURL('http://pcitis06/');
my ($rc,$info) = $th->confirmResultDownload();

if ($rc==1)
{
  print "error: $info\n";
  exit(1);
}
else
{
    my %data = %{$info};
    print "Response: $data{'Action'}\n";
}
