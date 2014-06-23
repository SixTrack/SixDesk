#----------------------------------------------------------------------------
# Person: simple API to handle CPSS related tasks (uploads,task creation etc)
#
# Author Andreas Wagner CERN - IT / IS
#
#
# Modification Record:
#
# Date:        Who:       Changes
# 2003-05-01   A.Wagner   first version
#

package TaskHandler;

use strict;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common qw(POST);

use HTML::Parser;
use URI::URL;

#------------------------------------------------------------
# Constructor for class 

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
      my $txterr = "(Phone::new";
      if (@_) 
      {
      } 
      else 
      {
      }
      if (@_) 
      {
      } 
      else 
      {
      }
      $self->{URL} = '';
      $self->{DIR}   = '';
      $self->{SOURCEFILE}   = '';
      $self->{TARGETFILE}   = '';
      $self->{DESCRIPTION}   = '';
      $self->{VERSION}   = '';
      $self->{AUTHOR}   = '';
      $self->{PROGRAMNAME}   = '';
      $self->{VERBOSE} = 0;
      $self->{DEBUG} = 0;
      $self->{USERNAME} = 'user';

      $self->{TASKNAME} = '';
      $self->{TASKPRIORITY} = '';
      $self->{PROGRAMID} = '';
      $self->{OSMIN} = '';
      $self->{OSMAX} = '';
      $self->{CPUSPEEDMIN} = '';
      $self->{DISKSPACEMIN} = '';
      $self->{MEMORYMIN} = '';

      $self->{PRECOMMAND} = '';
      $self->{PRECOMMANDDIRECTORY} = '';
      $self->{PRECOMMANDOUTPUTFILE} = '';

      $self->{MAINCOMMAND} = '';
      $self->{MAINCOMMANDDIRECTORY} = '';
      $self->{MAINCOMMANDOUTPUTFILE} = '';

      $self->{POSTCOMMAND} = '';
      $self->{POSTCOMMANDDIRECTORY} = '';
      $self->{POSTCOMMANDOUTPUTFILE} = '';

      $self->{CHECKPOINTRESTART} = '0';
      $self->{REQUIREDCLIENTVERSION} = '0';
      $self->{RESULTFILES} = '';

      $self->{NUMBEROFFILES} = '';
      $self->{FILE01} = '';
      $self->{FILE02} = '';
      $self->{FILE03} = '';
      $self->{FILE04} = '';
      $self->{FILE05} = '';
      $self->{FILE06} = '';
      $self->{FILE07} = '';
      $self->{FILE08} = '';
      $self->{FILE09} = '';
      $self->{FILE10} = '';

      $self->{TASKGROUPGID} = '';
      $self->{TGNAME} = '';
      $self->{TGDESCRIPTION}   = '';
      $self->{TGPROGRAMID} = '';
      $self->{TGSTATUS} = '';
      $self->{TGPRIORITY} = '';
      $self->{TGCOMMENTS} = '';
  
      $self->{TASKID} = '';

      $self->{VERSION} = '0.0.0.0';

      bless ($self,$class);
}
 

#------------------------------------------------------------
# Destructor for class 



sub DESTROY
{
    my $self = shift;
}

#------------------------------------------------------------
# the methods

sub debugOn
{
    my $self = shift;
    my $txterr = "(Person::debugOn";
    $self->{DEBUG} = 1;
    return $self->{DEBUG};
}

sub debugOff
{
    my $self = shift;
    my $txterr = "(Person::debugOff";
    $self->{DEBUG} = 0;
    return $self->{DEBUG};
}

sub setFileName () {
    my $self = shift;
    my $actFileName = shift;
    $self->{FILE} = $actFileName;    
}
sub getVersion () {
    my $self = shift;
    return $self->{VERSION};  
}

sub setProgramName () {
    my $self = shift;
    my $actProgramName = shift;
    $self->{PROGRAMNAME} = $actProgramName;    
}

sub setURL () {
    my $self = shift;
    my $actURL = shift;
    $self->{URL} = $actURL;    
}

sub setTargetFileName () {
    my $self = shift;
    my $actTargetFileName = shift;
    $self->{TARGETFILE} = $actTargetFileName;    
}

sub setVersion () {
    my $self = shift;
    my $actVersion = shift;
    $self->{VERSION} = $actVersion;    
}

sub setAuthor () {
    my $self = shift;
    my $actAuthor = shift;
    $self->{AUTHOR} = $actAuthor;    
}

sub setDescription () {
    my $self = shift;
    my $actDescription = shift;
    $self->{DESCRIPTION} = $actDescription;    
}

sub setTaskName() {
    my $self = shift;
    my $actTaskName = shift;
    $self->{TASKNAME} = $actTaskName;      
};

sub setTaskPriority() {
    my $self = shift;
    my $actTaskPriority = shift;
    $self->{TASKPRIORITY} = $actTaskPriority;       
};
sub setProgramId() {
    my $self = shift;
    my $actProgramId = shift;
    $self->{PROGRAMID} = $actProgramId;       
};
sub setTaskgroupId() {
    my $self = shift;
    my $actTaskgroupId = shift;
    $self->{TASKGROUPID} = $actTaskgroupId;       
};
sub setTaskGroupId() {
    my $self = shift;
    my $actTaskgroupId = shift;
    $self->{TASKGROUPID} = $actTaskgroupId;       
};

sub setOsMin() {
    my $self = shift;
    my $actArg = shift;
    $self->{OSMIN} = $actArg;       
};                       

sub setOsMax() {
    my $self = shift;
    my $actArg = shift;
    $self->{OSMAX} = $actArg;       
};                       

sub setCpuSpeedMin() {
    my $self = shift;
    my $actArg = shift;
    $self->{CPUSPEEDMIN} = $actArg;       
};                       

sub setDiskSpaceMin() {
    my $self = shift;
    my $actArg = shift;
    $self->{DISKSPACEMIN} = $actArg;       
};                       

sub setMemoryMin() {
    my $self = shift;
    my $actArg = shift;
    $self->{MEMORYMIN} = $actArg;       
};                                                            

#                                           
sub setPreCommand() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{PRECOMMAND} = $actArg;      
};                                                  
sub setPreCommandDirectory() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{PRECOMMANDDIRECTORY} = $actArg;      
};                                                  
sub setPreCommandOutputFile() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{PRECOMMANDOUTPUTFILE} = $actArg;      
};                                                  
#                                           
sub setMainCommand() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{MAINCOMMAND} = $actArg;      
};                                                  
sub setMainCommandDirectory() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{MAINCOMMANDDIRECTORY} = $actArg;      
};                                                  
sub setMainCommandOutputFile() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{MAINCOMMANDOUTPUTFILE} = $actArg;      
};                                                  
#                                           
sub setPostCommand() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{POSTCOMMAND} = $actArg;      
};                                                  
sub setPostCommandDirectory() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{POSTCOMMANDDIRECTORY} = $actArg;      
};                                                  
sub setPostCommandOutputFile() { 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{POSTCOMMANDOUTPUTFILE} = $actArg;      
};                                                  
                                   
sub setResultFiles() {       
    my $self = shift;                  
    my $actArg = shift;                
    $self->{RESULTFILES} = $actArg;      
};                                             
#                                           

sub setNumberOfFiles() {                 
    my $self = shift;                  
    my $actArg = shift;                
    $self->{NUMBEROFFILES} = $actArg;      
};                                                                                        
sub setFile01() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE01} = $actArg;      
};                                                                                        
sub setFile02() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE02} = $actArg;      
};                                                                                        
sub setFile03() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE03} = $actArg;      
};                                                                                        
sub setFile04() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE04} = $actArg;      
};                                                                                        
sub setFile05() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE05} = $actArg;      
};                                                                                        
sub setFile06() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE06} = $actArg;      
};                                                                                        
sub setFile07() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE07} = $actArg;      
};                                                                                        
sub setFile08() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE08} = $actArg;      
};                                                                                        
sub setFile09() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE09} = $actArg;      
};                                                                                        
sub setFile10() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{FILE10} = $actArg;      
};                                                                                        
#===================
sub setTaskGroupName() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{TGNAME} = $actArg;      
};
sub setDescription() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{TGDESCRIPTION} = $actArg;      
};
sub setProgramId() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{TGPROGRAMID} = $actArg;      
};
sub setStatus() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{TGSTATUS} = $actArg;      
};
sub setPriority() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{TGPRIORITY} = $actArg;      
};
sub setComments() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{TGCOMMENTS} = $actArg;      
};
sub setTaskId() {           
    my $self = shift;                  
    my $actArg = shift;                
    $self->{TASKID} = $actArg;      
};

sub setCheckpointRestart() {
    my $self = shift;
    my $actArg = shift;
    $self->{CHECKPOINTRESTART} = $actArg;
};

sub setRequiredClientVersion() {
    my $self = shift;
    my $actArg = shift;
    $self->{REQUIREDCLIENTVERSION} = $actArg;
};
    
#============================================================================

sub uploadProgram () {
    my $self = shift;     
    my ($rc,$msg);
    my $ua = LWP::UserAgent->new;
### my $ua = LWP::UserAgentT->new;
      $ua->agent("CpssPerlAgent/1.0 " . $ua->agent);
    my $res;
 
    if ($self->{DEBUG} == 1)
    {
 
      $res = $ua->request(POST $self->{URL}, Content_Type => 'multipart/form-data', Content => [
                    ProgramName    => $self->{PROGRAMNAME},
                    Author         => $self->{AUTHOR},
                    ExeName        => $self->{TARGETFILE},
                    ExeVersion     => $self->{VERSION},
                    Description    => $self->{DESCRIPTION},
                    Description    => $self->{DESCRIPTION},
                    myfile          => [$self->{FILE}],
                    verbose        => '1',
                    action    => 'Submit',
                ]);
    }
    else
    {

      $res = $ua->request(POST $self->{URL}, Content_Type => 'multipart/form-data', Content => [
                    ProgramName    => $self->{PROGRAMNAME},
                    Author         => $self->{AUTHOR},
                    ExeName        => $self->{TARGETFILE},
                    ExeVersion     => $self->{VERSION},
                    Description    => $self->{DESCRIPTION},
                    myfile         => [$self->{FILE}],
                    action    => 'Submit',
                ]);

    }


  if ($res->is_success) {
    my $response = $res->content;
    my @lines = split(/\n/,$response);
    my $take = 0;
    my %data;
    foreach my $line ( @lines)
    {
        if ($line =~ m/^<response>\s*$/) {$take=1; next};
        if ($line =~ m/^<\/response>\s*$/) {$take=0; next};
        if ($take==1) 
        {
           my ($key,$value);
           $line =~ m/(^[^\s]+)\:\s(.*)$/;
           $key = $1; $value=$2;
          # print "data line: $line -> key: $key - value: $value\n";
           $data{$key} = $value;
        } 
    };
    print "Response: $response\n" if $self->{DEBUG};
    return(0, \%data);

  } else {
    return(1,  "($res->code) " . $res->message );
  }


}
#============================================================================
sub createTaskGroup () {
    my $self = shift;     
    my ($rc,$msg);
    my $ua = LWP::UserAgent->new;
      $ua->agent("CpssPerlAgent/1.0 " . $ua->agent);

    my $numPriority = 3;
    my $actPriority = $self->{TGPRIORITY};
    
    if ($actPriority =~ m/^\s*Zero\s*$/        ) {$numPriority = 0; };
    if ($actPriority =~ m/^\s*Very\s*Low\s*$/  ) {$numPriority = 1; };
    if ($actPriority =~ m/^\s*Low\s*$/         ) {$numPriority = 2; };
    if ($actPriority =~ m/^\s*Normal\s*$/      ) {$numPriority = 3; };
    if ($actPriority =~ m/^\s*High\s*$/        ) {$numPriority = 4; };
    if ($actPriority =~ m/^\s*Very\s*High\s*$/ ) {$numPriority = 5; };

    if ($actPriority =~ m/^\s*0\s*$/       ) {$numPriority = 0; };
    if ($actPriority =~ m/^\s*1\s*$/       ) {$numPriority = 1; };
    if ($actPriority =~ m/^\s*2\s*$/       ) {$numPriority = 2; };
    if ($actPriority =~ m/^\s*3\s*$/       ) {$numPriority = 3; };
    if ($actPriority =~ m/^\s*4\s*$/       ) {$numPriority = 4; };
    if ($actPriority =~ m/^\s*5\s*$/       ) {$numPriority = 5; };
  
    my $res = $ua->request(POST $self->{URL}, Content_Type => 'application/x-www-form-urlencoded', Content => [
                  Name        => $self->{TGNAME},
                  Description => $self->{TGDESCRIPTION},
                  ProgramId   => $self->{TGPROGRAMID},
                  Status      => $self->{TGSTATUS},
                  Comments    => $self->{TGCOMMENTS},
                  Priority    => $numPriority,
                  Verbose     => 'On',
                  action      => 'Submit',
                ]);

   if ($res->is_success) {
    my $response = $res->content;
    my @lines = split(/\n/,$response);
    my $take = 0;
    my %data;
    foreach my $line ( @lines)
    {
        if ($line =~ m/^<response>\s*$/) {$take=1; next};
        if ($line =~ m/^<\/response>\s*$/) {$take=0; next};
        if ($take==1) 
        {
           my ($key,$value);
           $line =~ m/(^[^\s]+)\:\s(.*)$/;
           $key = $1; $value=$2;
           $key =~ s/\s+//g;
          # print "data line: $line -> key: $key - value: $value\n";
           $data{$key} = $value;
        } 
    };
    print "Response: $response\n" if $self->{DEBUG};
    return(0, \%data);
  } else {
    return(1,  "($res->code) " . $res->message );
  }


}

#============================================================================

sub uploadTask () {
    my $self = shift;     
    my ($rc,$msg);
    my $ua = LWP::UserAgent->new;
      $ua->agent("CpssPerlAgent/1.0 " . $ua->agent);

    my @fileTemp;

    for (my $i = 1; $i <=9; $i++)
    {
      if ($self->{NUMBEROFFILES} >= $i) { $fileTemp[$i] = [$self->{"FILE0$i"}]; } else {$fileTemp[$i] = "dummy";}; 
    };

   
    


     my $res = $ua->request(POST $self->{URL}, Content_Type => 'multipart/form-data', Content => [
                  TaskName  => $self->{TASKNAME},
                  TaskPriority => $self->{TASKPRIORITY},
                  TaskgroupId  => $self->{TASKGROUPID},
                  ProgramId  => $self->{PROGRAMID},
                  OsMin    => $self->{OSMIN},
                  OsMax    => $self->{OSMAX},
                  CpuSpeedMin    => $self->{CPUSPEEDMIN},
                  MemoryMin      => $self->{MEMORYMIN},
                  DiskSpaceMin      => $self->{DISKSPACEMIN},
                  CheckpointRestart  => $self->{CHECKPOINTRESTART},
                  RequiredClientVersion  => $self->{REQUIREDCLIENTVERSION},
                  PreCommand     => $self->{PRECOMMAND},
                  PreCommandDirectory     => $self->{PRECOMMANDDIRECTORY},
                  PreCommandOutputFile     => $self->{PRECOMMANDOUTPUTFILE},
                  MainCommand     => $self->{MAINCOMMAND},
                  MainCommandDirectory     => $self->{MAINCOMMANDDIRECTORY},
                  MainCommandOutputFile     => $self->{MAINCOMMANDOUTPUTFILE},
                  PostCommand     => $self->{POSTCOMMAND},
                  PostCommandDirectory     => $self->{POSTCOMMANDDIRECTORY},
                  PostCommandOutputFile     => $self->{POSTCOMMANDOUTPUTFILE},
                  ResultFiles     => $self->{RESULTFILES},
                  NumberOfFiles   => $self->{NUMBEROFFILES},
                  myfile01        => $fileTemp[1],
                  myfile02        => $fileTemp[2],
                  myfile03        => $fileTemp[3],
                  myfile04        => $fileTemp[4],
                  myfile05        => $fileTemp[5],
                  myfile06        => $fileTemp[6],
                  myfile07        => $fileTemp[7],
                  myfile08        => $fileTemp[8],
                  myfile09        => $fileTemp[9],
                  action    => 'Submit',]);

  
  if ($res->is_success) {
    my $response = $res->content;
    my @lines = split(/\n/,$response);
    my $take = 0;
    my %data;
    foreach my $line ( @lines)
    {
        if ($line =~ m/^<response>\s*$/) {$take=1; next};
        if ($line =~ m/^<\/response>\s*$/) {$take=0; next};
        if ($take==1) 
        {
           my ($key,$value);
           $line =~ m/(^[^\s]+)\:\s(.*)$/;
           $key = $1; $value=$2; $value =~ s/\s+$//;
          # print "data line: $line -> key: $key - value: $value\n";
           $data{$key} = $value;
        } 
    };
    print "Response: $response\n" if $self->{DEBUG};
    return(0, \%data);
  } 
  else 
  {
    return(1,  "($res->code) " . $res->message );
  }


}

#============================================================================

sub deleteTask () {
    my $self = shift;     
    my ($rc,$msg);
    my $taskId = $self->{TASKID};
    
    my $ua = LWP::UserAgent->new;
      $ua->agent("CpssPerlAgent/1.0 " . $ua->agent);

    my @fileTemp;

    my $aTime = time;
    my $aDay = 60 * 60 * 24;  $aTime = $aTime - 1 * $aDay;
    my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime($aTime);  
    $year += 1900;
    $wday += 2; if ($wday > 7) {$wday -= 7;};

    print "year: $year\n" if $self->{DEBUG};
    print "day: $day\n" if $self->{DEBUG};
    print "weekday: $wday\n" if $self->{DEBUG};

              my $AC1 = (( $year * $day * $wday - $year) * ($year - $wday)) - $wday; 
	      my $AC2 = $wday * $day;
              my $AC_1 = "$AC2$AC1";

    print "AC 1: '$AC_1'\n" if $self->{DEBUG};
 
   $aTime = $aTime + 1 * $aDay;
   ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime($aTime);  
    $year += 1900;
    $wday += 2; if ($wday > 7) {$wday -= 7;};

    print "year: $year\n" if $self->{DEBUG};
    print "day: $day\n" if $self->{DEBUG};
    print "weekday: $wday\n" if $self->{DEBUG};

              $AC1 = (( $year * $day * $wday - $year) * ($year - $wday)) - $wday; 
	      $AC2 = $wday * $day;
              my $AC_2 = "$AC2$AC1";

    print "AC 2: '$AC_2'\n" if $self->{DEBUG};

   $aTime = $aTime + 1 * $aDay;
   ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime($aTime);  
    $year += 1900;
    $wday += 2; if ($wday > 7) {$wday -= 7;};

    print "year: $year\n" if $self->{DEBUG};
    print "day: $day\n" if $self->{DEBUG};
    print "weekday: $wday\n" if $self->{DEBUG};

              $AC1 = (( $year * $day * $wday - $year) * ($year - $wday)) - $wday; 
	      $AC2 = $wday * $day;
              my $AC_3 = "$AC2$AC1";

    print "AC 3: '$AC_3'\n" if $self->{DEBUG};

    print "TaskID: $self->{TASKID}\n" if $self->{DEBUG};
    print "TaskGroupID: $self->{TASKGROUPID}\n" if $self->{DEBUG};

     my $res = $ua->request(POST $self->{URL}, Content_Type => 'application/x-www-form-urlencoded', Content => [
                  TaskID  => $self->{TASKID},
                  TaskGroupID => $self->{TASKGROUPID},
                  AC1  => $AC_1,
                  AC2  => $AC_2,
                  AC3  => $AC_3,
                  action    => 'Submit',
               ]);
    

  # my $response = $res->content;print $response ."\n";
  if ($res->is_success) {
    my $response = $res->content;
    # print $response ."\n";
    my @lines = split(/\n/,$response);
    my $take = 0;
    my %data;
    foreach my $line ( @lines)
    {
        if ($line =~ m/^<response>\s*$/) {$take=1; next};
        if ($line =~ m/^<\/response>\s*$/) {$take=0; next};
        if ($take==1) 
        {
           my ($key,$value);
           $line =~ m/(^[^\s]+)\:\s(.*)$/;
           $key = $1; $value=$2;
           $value =~ s/\s+$//;
           # print "data line: $line -> key: >$key< - value: >$value<\n";
           $data{$key} = $value;
        } 
    };
    print "Response: $response\n" if $self->{DEBUG};
    return(0, \%data);
  } 
  else 
  {
    return(1,  "($res->code) " . $res->message );
  }


}

#============================================================================

sub queryReadyResults () {

    my $self = shift;     
    my ($rc,$msg);
    my $ua = LWP::UserAgent->new;
      $ua->agent("CpssPerlAgent/1.0 " . $ua->agent);

    my $res = $ua->request(POST $self->{URL}, Content_Type => 'application/x-www-form-urlencoded', Content => [
                  TaskGroupId   => $self->{TASKGROUPID},
                  action      => 'Submit',
                ]);

   if ($res->is_success) {
    my $response = $res->content;
    my @lines = split(/\n/,$response);
    my $take = 0;
    my %data;
    foreach my $line ( @lines)
    {
        if ($line =~ m/^<response>\s*$/) {$take=1; next};
        if ($line =~ m/^<\/response>\s*$/) {$take=0; next};
        if ($take==1) 
        {
           my ($key,$value);
           $line =~ m/(^[^\s]+)\:\s(.*)$/;
           $key = $1; $value=$2;
           $key =~ s/\s+//g;
          # print "data line: $line -> key: $key - value: $value\n";
           $data{$key} = $value;
        } 
    };
    print "Response: $response\n" if $self->{DEBUG};
    return(0, \%data);
  } else {
    return(1,  "($res->code) " . $res->message );
  }



};


#============================================================================
sub downloadResult () {

    my $self = shift;     
    my $resultURL = shift;     
    my $localFile = shift;     
    my ($rc,$msg);

    my $outputOk = 0;

    my $ua = LWP::UserAgent->new;
      $ua->agent("CpssPerlAgent/1.0 " . $ua->agent);

    my $url  = URI::URL->new($resultURL);
    my $req  = HTTP::Request->new('GET', $url);
 
    print "URL: $url\n";

    my $res = $ua->request($req);

   if ($res->is_success) {
     my $response = $res->content;
     print "ResultLoaded: \n" if $self->{DEBUG};
 
     print "Before writing local file: $localFile \n" if $self->{DEBUG};
     print "length of response data: " . length($response) . "\n" if $self->{DEBUG};
     if (open DAT,'>'.$localFile) 
     {
      # Dateien in den Binaer-Modus schalten
      binmode DAT;
      my $data;
       print DAT $response;
      close DAT;
      $outputOk = 1;
     }

     my %data; 
     $data{'OutputOk'} = $outputOk;
     $data{'ContentLength'} = length($response);
    return(0, \%data);
  } else {
    return(1,  "($res->message) " . $res->message );
  }



};
#============================================================================

sub confirmResultDownload () {

    my $self = shift;     
    my ($rc,$msg);
    my $ua = LWP::UserAgent->new;
      $ua->agent("CpssPerlAgent/1.0 " . $ua->agent);

    print "before sending HTTP request\n" if $self->{DEBUG};
    my $res = $ua->request(POST $self->{URL}, Content_Type => 'application/x-www-form-urlencoded', Content => [
                  TaskId   => $self->{TASKID},
                  action      => 'Submit',
                ]);

    print "after HTTP request\n" if $self->{DEBUG};
   if ($res->is_success) {
    print "HTTP request was sucessful\n" if $self->{DEBUG};
    my $response = $res->content;
    my @lines = split(/\n/,$response);
    my $take = 0;
    my %data;
    foreach my $line ( @lines)
    {
        if ($line =~ m/^<response>\s*$/) {$take=1; next};
        if ($line =~ m/^<\/response>\s*$/) {$take=0; next};
        if ($take==1) 
        {
           my ($key,$value);
           $line =~ m/(^[^\s]+)\:\s(.*)$/;
           $key = $1; $value=$2;
           $key =~ s/\s+//g;
          # print "data line: $line -> key: $key - value: $value\n";
           $data{$key} = $value;
        } 
    };
    print "Response: $response\n" if $self->{DEBUG};
    return(0, \%data);
  } else {
    return(1,  "($res->code) " . $res->message );
  }



};



#============================================================================

1;

#============================================================================
