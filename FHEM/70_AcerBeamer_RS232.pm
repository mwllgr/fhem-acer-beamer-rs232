##############################################
# $Id
#
# Created originally by Markus Bloch, edited by Zadolux for Acer beamers.
# This modules controls Acer beamers which are connected via RS232.
#
# Detailed Information about the hardware setup and more possible control commands:
# http://www.hifi-forum.de/viewthread-94-10979.html
#
# Define:  define Beamer AcerBeamer_RS232 /dev/ttyUSB0
# Set: source:hmdi,dsub, ...
# Get: manufacturer,model, ...
#

package main;

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use DevIo;

my %AcerBeamer_RS232_get = (
  "power" => "* 0 IR 037", # Requests manufacturer (but doesn't set it), just for power check
  "manufacturer" => "* 0 IR 037",
  "source" => "* 0 Src ?",
  "lampHours" => "* 0 Lamp",
  # "model" => "* 0 IR 035", # works but no \r at the end
);

my %AcerBeamer_RS232_set = (
  "remoteControl" => {
    "volUp"           => "* 0 IR 023",
    "volDown"         => "* 0 IR 024",
    "mute"            => "* 0 IR 006",
    "menu"            => "* 0 IR 008",
    "freeze"          => "* 0 IR 007",
    "hide"            => "* 0 IR 030",
    "up"              => "* 0 IR 009",
    "down"            => "* 0 IR 010",
    "left"            => "* 0 IR 011",
    "right"           => "* 0 IR 012",
    "zoom"            => "* 0 IR 046"
  },
  "quickSettings" => {
    "16:9"            => "* 0 IR 021",
    "4:3"             => "* 0 IR 022",
    "brightness"      => "* 0 IR 025",
    "contrast"        => "* 0 IR 026",
    "colorTemp"       => "* 0 IR 027",
    "keystone"        => "* 0 IR 004",
    "colorRgb"        => "* 0 IR 048",
    "ekey"            => "* 0 IR 047",
    "language"        => "* 0 IR 049",
  },
  "source" => {
    "auto"            => "* 0 IR 031",
    "resync"          => "* 0 IR 014",
    "dsub"            => "* 0 IR 015",
    "hdmi"            => "* 0 IR 050",
    "composite"       => "* 0 IR 019",
    "svideo"          => "* 0 IR 018",
  },
  "power" => {
    "on"              => "* 0 IR 001",
    "off"             => "* 0 IR 002",
  }
);

#####################################
sub
AcerBeamer_RS232_Initialize($)
{
  my ($hash) = @_;

  $hash->{DefFn}    = "AcerBeamer_RS232_Define";
  $hash->{UndefFn}  = "AcerBeamer_RS232_Undef";
  $hash->{ReadFn} = "AcerBeamer_RS232_Read";
  $hash->{SetFn}    = "AcerBeamer_RS232_Set";
  $hash->{GetFn}    = "AcerBeamer_RS232_Get";
  $hash->{ReadyFn}  = "AcerBeamer_RS232_Ready";
  $hash->{AttrList} = " ".$readingFnAttributes;
}

#####################################
sub
AcerBeamer_RS232_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  my $name = $a[0];
  my $dev = $a[2];
  my $interval  = 60;

  if(int(@a) == 4) {
    $interval= $a[3];
    if ($interval < 20) {
      return "interval too small, please use something >= 20, default is 60";
    }
  }

  $dev .= "\@9600" if(not $dev =~ m/\@\d+/);
  $hash->{DeviceName} = $dev;
  $hash->{INTERVAL} = $interval;
  DevIo_CloseDev($hash);

  my $ret = DevIo_OpenDev($hash, 0, undef);
  delete($hash->{PARTIAL});

  RemoveInternalTimer($hash);
  AcerBeamer_RS232_GetStatus($hash);

  return undef;
}

#####################################
sub
AcerBeamer_RS232_Undef($$)
{
  my ($hash, $arg) = @_;

  DevIo_CloseDev($hash);
  return undef;
}

#####################################
sub
AcerBeamer_RS232_Set($@)
{
    my ($hash, @a) = @_;
    my $what = $a[1];

    if(exists($AcerBeamer_RS232_set{$what}) and exists($AcerBeamer_RS232_set{$what}{$a[2]}))
    {
      $hash->{buffer} = "";
      $hash->{lastGet} = "";

      InternalTimer(gettimeofday()+2, "AcerBeamer_RS232_TimeOut", $hash, 0);
      DevIo_SimpleWrite($hash, $AcerBeamer_RS232_set{$what}{$a[2]}."\r", 0);
    }
    else
    {
      my $usage = "unknown argument $what choose one of ";

      foreach my $cmd (sort keys %AcerBeamer_RS232_set)
      {
         $usage .= " $cmd:".join(",", sort keys %{$AcerBeamer_RS232_set{$cmd}});
      }

      return $usage;
    }
}

#####################################
sub
AcerBeamer_RS232_Get($@)
{
    my ($hash, @a) = @_;
    return "get needs at least an argument" if ( @a < 2 );

    my $getName = $a[1];
    my $name = shift @a;
    my $attr = shift @a;
    my $serialCmd;

    if(!$AcerBeamer_RS232_get{$attr})
    {
        my @cList = keys %AcerBeamer_RS232_get;
        return "unknown argument $attr choose one of " . join(" ", @cList);
    }
    else
    {
      $serialCmd = $AcerBeamer_RS232_get{$attr};

      if($attr eq "power")
      {
        InternalTimer(gettimeofday()+2, "AcerBeamer_RS232_TimeOut", $hash, 0);
      }

      DevIo_SimpleWrite($hash, $serialCmd . "\r", 0);
    }

    $hash->{lastGet} = $getName;
    $hash->{buffer} = "";

    if($attr eq "power")
    {
      return "Sent power check, watch readings.";
    }
    else
    {
      return "Read with command \"" . $serialCmd . "\" started, watch readings.";
    }
}

######################################
# Executed whenever the serial port receives something
sub AcerBeamer_RS232_Read($)
{
    my ($hash) = @_;
    my $name = $hash->{NAME};
    my $finalValue = "";

    # read from serial device
    my $buf = DevIo_SimpleRead($hash);
    return "" if ( !defined($buf) );

    $hash->{buffer} .= $buf;
    if(index($hash->{buffer}, "*000") != -1)
    {
      Log3 $name, 5, "$name: Command accepted";
      $hash->{cmdAccepted} = 1;

      if($hash->{lastGet} eq "power")
      {
        readingsBeginUpdate($hash);
        readingsBulkUpdate($hash, "presence", "present");
        readingsBulkUpdate($hash, "state", "on");
        readingsEndUpdate($hash, 1);

        delete($hash->{buffer});
        delete($hash->{lastGet});

        RemoveInternalTimer($hash);
        InternalTimer(gettimeofday()+$hash->{INTERVAL}, "AcerBeamer_RS232_GetStatus", $hash, 0);
      }
      else
      {
        Log3 $name, 5, "$name: Current buffer: " . $hash->{buffer};

        if(defined($hash->{lastGet}) && $hash->{lastGet} ne "power")
        {
          if(length($hash->{buffer}) > 4)
          {
            $finalValue = substr($hash->{buffer}, 5);
            Log3 $name, 5, "$name: SUBSTRinged buffer: " . $finalValue;
          }

              if(index($finalValue, "\r") > 0)
              {
                if($hash->{lastGet} eq "manufacturer")
                {
                  $finalValue =~ s/Name //;
                }
                elsif($hash->{lastGet} eq "source")
                {
                  $finalValue =~ s/Src //;

                  if($finalValue == 0)
                  {
                      $finalValue = "noSignal";
                  }
                  elsif($finalValue == 1)
                  {
                      $finalValue = "dsub";
                  }
                  elsif($finalValue == 8)
                  {
                    $finalValue = "hdmi";
                  }
                }
                elsif($hash->{lastGet} eq "lampHours" && $finalValue ne "")
                {
                  $finalValue = sprintf("%d", $finalValue);
                }

                readingsBeginUpdate($hash);
                readingsBulkUpdate($hash, $hash->{lastGet}, $finalValue);
                readingsEndUpdate($hash, 1);

                delete($hash->{buffer});
                delete($hash->{lastGet});
            }
        }
      }
    }
    else
    {
      $hash->{cmdAccepted} = 0;
    }
}

#####################################
sub
AcerBeamer_RS232_Ready($)
{
  my ($hash) = @_;

  return DevIo_OpenDev($hash, 1, undef) if($hash->{STATE} eq "disconnected");
}

#####################################
# Executed regularly to check the power status
sub
AcerBeamer_RS232_GetStatus($)
{
  my ($hash) = @_;

  $hash->{lastGet} = "power";
  RemoveInternalTimer($hash);

  DevIo_SimpleWrite($hash, "* 0 IR 037" . "\r", 0);
  InternalTimer(gettimeofday()+2, "AcerBeamer_RS232_TimeOut", $hash, 0);
}

#####################################
# Executed if beamer does not respond
sub
AcerBeamer_RS232_TimeOut($)
{
  my ($hash) = @_;

  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "presence", "absent");
  readingsBulkUpdate($hash, "state", "off");
  readingsEndUpdate($hash, 1);

  delete($hash->{buffer});
  delete($hash->{lastGet});

  RemoveInternalTimer($hash);
  InternalTimer(gettimeofday()+$hash->{INTERVAL}, "AcerBeamer_RS232_GetStatus", $hash, 0);
}

1;




=pod
=item device
=item summary Module for controlling Acer beamers via RS232
=begin html
 <a name="AcerBeamer_RS232"></a>
 <h3>AcerBeamer_RS232</h3>
 This module interacts with Acer beamers.
 <ul><br>
  <a name="AcerBeamer_RS232_Define"></a>
  <b>Define</b>
  <ul> 
   <code>define &lt;Name&gt; AcerBeamer_RS232 &lt;Device&gt;</code><br>
   <br>
   Example: <code>define Beamer AcerBeamer_RS232 /dev/ttyUSB0</code>
 </ul><br>
 <ul><br>
  <a name="WKRCD4_Set"></a>
  <b>Set</b>
  <ul>
   <li>All remote control feautures</li>
  </ul>
 </ul> 
 <ul><br>
  <a name="WKRCD4_Get"></a>
  <b>Get</b>
  <ul>
   <li>lampHours</li>
   <li>manufacturer</li>
   <li>power</li>
   <li>source</li>
  </ul>
 </ul> 
 
=end html
=cut
