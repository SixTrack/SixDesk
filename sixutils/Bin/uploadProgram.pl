
use strict;
use FindBin;
use lib ("$FindBin::/afs/cern.ch/user/m/mcintosh/sixdesk/slap/Bin/perllib");

use TaskHandler;

my $th = new TaskHandler;

if ($#ARGV != 5)
{
  print "error: ProgramName, FileName, TargetFileName, Version, Author, Description must be specified \n";
  exit(2);
}

my $ProgramName = $ARGV[0];
my $FileName = $ARGV[1];
my $TargetFileName = $ARGV[2];
my $Version = $ARGV[3];
my $Author = $ARGV[4];
my $Description = $ARGV[5];

$th->setProgramName("$ProgramName");
$th->setFileName("$FileName");
$th->setTargetFileName("$TargetFileName");
$th->setVersion("$Version");
$th->setAuthor("$Author");
$th->setDescription("$Description");

$th->setURL('http://cpss.web.cern.ch/cpss/cgi-bin/uploadProgram.pl');
#$th->setURL('http://pcitis06/');
my ($rc,$info) = $th->uploadProgram();

if ($rc==1)
{
  print "error: $info\n";
  exit(1);
}
else
{
    my %data = %{$info};
    print "ProgramId: $data{'ProgramId'}\n";
}
