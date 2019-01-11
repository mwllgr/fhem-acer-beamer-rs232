##############################################
# $Id
#
# created originally by Markus Bloch, edited by Zadolux for Acer beamers
#
# This modules controls Acer beamers which are connected via RS232.
#
# Detailed Information about the hardware setup and more possible control commands:
# http://www.hifi-forum.de/viewthread-94-10979.html
#
# Define:  define Beamer ACER_BEAMER_RS232 /dev/ttyUSB0
#
# Set: source:hmdi,dsub, ...
# 

package main;

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use DevIo;

my %ACER_BEAMER_RS232_set = (
"remoteControl" => {
            "volUp" => "* 0 IR 023",
            "volDown"    => "* 0 IR 024",
            "mute"    => "* 0 IR 006",
            "menu" => "* 0 IR 008",
            "freeze"     => "* 0 IR 007",
            "hide"     => "* 0 IR 030",
            "up"     => "* 0 IR 009",
            "down"     => "* 0 IR 010",
            "left"     => "* 0 IR 011",
            "right"     => "* 0 IR 012",
            "zoom"     => "* 0 IR 046",
           },
"quickSettings" => {
            "brightness" => "* 0 IR 025",
            "contrast"    => "* 0 IR 026",
            "colorTemp"    => "* 0 IR 027",
            "keystone" => "* 0 IR 004",
            "colorRgb"     => "* 0 IR 048",
            "ekey"     => "* 0 IR 047",
            "language"     => "* 0 IR 049",
           },
"source" => {
            "auto" => "* 0 IR 031",
            "resync"    => "* 0 IR 014",
            "dsub"    => "* 0 IR 015",
            "hdmi" => "* 0 IR 050",
            "composite"     => "* 0 IR 019",
            "svideo"     => "* 0 IR 018",
           },
"power" => {
            "on"        => "* 0 IR 001",
            "off"       => "* 0 IR 002",
           }
);



#####################################
sub
ACER_BEAMER_RS232_Initialize($)
{
  my ($hash) = @_;

  $hash->{DefFn}    = "ACER_BEAMER_RS232_Define";
  $hash->{UndefFn}  = "ACER_BEAMER_RS232_Undef";
  $hash->{SetFn}    = "ACER_BEAMER_RS232_Set";
  $hash->{ReadyFn}  = "ACER_BEAMER_RS232_Ready";
  $hash->{AttrList} = " ".$readingFnAttributes;
}

#####################################
sub
ACER_BEAMER_RS232_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);



  my $name = $a[0];
  my $dev = $a[2];


  
  $hash->{helper}{RECEIVE_BUFFER} = "";
  
  $dev .= "\@9600" if(not $dev =~ m/\@\d+/);
  
  $hash->{DeviceName} = $dev;
  
  DevIo_CloseDev($hash);
  
  my $ret = DevIo_OpenDev($hash, 0, undef);
  
  delete($hash->{PARTIAL});
  RemoveInternalTimer($hash);
  return undef;
}

#####################################
sub
ACER_BEAMER_RS232_Undef($$)
{
  my ($hash, $arg) = @_;
  
  DevIo_CloseDev($hash); 
  return undef;
}


#####################################
sub
ACER_BEAMER_RS232_Set($@)
{
    my ($hash, @a) = @_;

    my $what = $a[1];
    my $usage = "Unknown argument $what, choose one of ";

    foreach my $cmd (sort keys %ACER_BEAMER_RS232_set)
    {
       $usage .= " $cmd:".join(",", sort keys %{$ACER_BEAMER_RS232_set{$cmd}});
    }

    if(exists($ACER_BEAMER_RS232_set{$what}) and exists($ACER_BEAMER_RS232_set{$what}{$a[2]}))
    {
        DevIo_SimpleWrite($hash, $ACER_BEAMER_RS232_set{$what}{$a[2]}."\n", 0);
    }
    else
    {
      return $usage;
    }
   
}


#####################################
# receives incoming data
sub
ACER_BEAMER_RS232_Ready($)
{
  my ($hash) = @_;

  return DevIo_OpenDev($hash, 1, undef) if($hash->{STATE} eq "disconnected");
}

1;

