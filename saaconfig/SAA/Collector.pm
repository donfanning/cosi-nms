#
# $Id$
#
package SAA::Collector;

use strict;
require 5.002;
use lib qw(..);    # XXX This is for testing only.
use SNMP;
use SAA::Globals;
use SAA::SAA_MIB;
use Carp;

sub new {

        # ARG 1: String name
        # ARG 2: SAA::Source source
        # ARG 3: SAA::Operation operation
        # ARG 4: (optional) SAA::Target target
        my ($that, @args) = @_;
        my $class = ref($that) || $that;

        if (scalar(@args) < 3 || scalar(@args) > 4) {
                croak
                    "SAA::Collector: Wrong number of arguments passed to constructor";
        }

        my $self = {
                name          => $args[0],
                id            => undef,
                source        => $args[1],
                operation     => $args[2],
                target        => undef,
                startTime     => DEFAULT_START_TIME,
                life          => DEFAULT_LIFE,
                writeNVRAM    => FALSE,
                historyFilter => $historyFilterEnum->{none},
                startTime     => DEFAULT_START_TIME,
                error         => undef,
        };

        my $rc = _needTarget($self->{operation}->type());
        if (scalar(@args) == 4 && $rc) {
                $self->{target} = $args[3];
        } elsif (scalar(@args) < 4 && $rc) {
                croak
                    "SAA::Collector: The specified operation requires a target argument";
        }

        #bugfix for proto support
        #values stored in SAA::Operation's operation for protocol are
        #numerical while values stored in SAA::Source's list of supported
        #protocols are textual as per operationProtocolEnum
        #FIX:feeding SAA::Source's object textual info after converting numerical
        #info from SAA::Operations object.
        # 12/16/2001 knail1

        my %operationProtocolEnum_rev = reverse %$operationProtocolEnum;
        my $protocol_textual          =
            $operationProtocolEnum_rev{$self->{operation}->{protocol}};

        if (!$self->{source}->protocol_supported($protocol_textual)) {
                croak
                    "SAA::Collector: The specified protocol is not supported by this source router";
        }

        #bugfix for type support: same problem as protocol entry, similar fix:
        # 12/16/2001 knail1
        my %operationTypeEnum_rev = reverse %$operationTypeEnum;
        my $type_textual = $operationTypeEnum_rev{$self->{operation}->{type}};

        if (!$self->{source}->type_supported($type_textual)) {
                croak
                    "SAA::Collector: The specified RTT type is not supported by this source router";
        }

        bless($self, $class);
        $self;
}

sub _needTarget {

        if (scalar(@_) != 1) {
                croak
                    "SAA::Collector::_needTarget: method requires one argument";
        }

        # This is a private static method to determine if a given operation type
        # needs a target.  HTTP, DNS, FTP and DHCP operations do not need targets.
        my $type = shift;

        if (       $type == $operationTypeEnum->{dns}
                || $type == $operationTypeEnum->{http}
                || $type == $operationTypeEnum->{dhcp}
                || $type == $operationTypeEnum->{ftp})
        {
                return 0;
        }

        1;
}

sub source {
        my $self = shift;
        return $self->{source};
}

sub target {
        my $self = shift;
        return $self->{target};
}

sub name {
        my $self = shift;
        return $self->{name};
}

sub id {
        my $self = shift;
        my ($override);

        if (@_) { $override = shift; }

        if (!$self->{id} || $override) {

                # Don't calculate id if it's already set or unless we're forced
                # to (by setting $override to 1).
                srand(time ^ $$);    # We don't need the best seed.
                $self->{id} = int(rand 65535) + 1;
        }
        return $self->{id};
}

sub write_nvram {
        my $self = shift;
        if (@_) {
                my $val = shift;
                if ($val != TRUE && $val != FALSE) {
                        return $self->{writeNVRAM};
                }
                $self->{writeNVRAM} = $val;
        }
        return $self->{writeNVRAM};
}

sub history_filter {
        my $self = shift;
        my $filter;
        if (@_) {
                my $val = shift;
                foreach (keys %{$historyFilterEnum}) {

                        if ($val == $historyFilterEnum->{$_}) {
                                $filter = $val;
                                last;
                        }
                }

                if (!$filter) {
                        return $self->{historyFilter};
                }
                $self->{historyFilter} = $filter;
        }
        return $self->{historyFilter};
}

sub life {
        my $self = shift;
        if (@_) {
                my $duration = shift;
                if ($duration < MIN_LIFE || $duration > MAX_LIFE) {
                        return $self->{life};
                } else {
                        $self->{life} = $duration;
                }
        }
        return $self->{life};
}

sub start_time {
        my $self = shift;

        # Since this objet represents TimeTicks, it can have pretty much any range.
        # We cast the value to an int which should make things safe.
        if (@_) {
                my $time = shift;
                if ($time < 0) {    # We can't time travel.
                        return DEFAULT_START_TIME;
                }
                $self->{startTime} = int($time);
        }
        return $self->{startTime};
}

sub error {
        my $self = shift;
        if (@_) { $self->{error} = shift; }
        return $self->{error};
}

sub install {

        # This method installs the collector on the source router.  It
        # assumes that the source has been successfully learned.
        my $self = shift;
        my ($source, $target, $operation, $id, $sess);

        $source = $self->source();
        $target = $self->target();
        $id     = $self->id();

        if ($source->status() != HOST_UP_SNMP) {
                $self->error("Status for host "
                            . $source->name()
                            . " indicates it is not SNMP reachable");
                return;
        }

        # A start time of 0 (the current default) is invalid.  A positive start time
        # must be specified in order for the collector to run.
        if ($self->start_time() == DEFAULT_START_TIME) {
                $self->error("Start time has not been set");
                return;
        }

        # For now, we use the read-only community string.  We'll change over
        # to read-write when we do the actual configuration.
        $sess = new SNMP::Session(
                DestHost  => $source->addr(),
                Community => $source->read_community(),
                Version   => $source->snmp_version(),
        );

        # We need to determine if the given $id is already in use on the
        # source router.  We will loop ten times or until we find a free
        # row id.
        my $i;
        for ($i = 0 ; $i < 10 ; $i++) {
                my $val = $sess->get($rttMonCtrlAdminStatus . '.' . $id);

                #last if ( $sess->{ErrorNum} ); <----

                last if ($val eq 'NOSUCHINSTANCE');

                #bugfix: $sess->ErrorNum returns 0 for each query on non-extistant
                #row. thus we need to exit out of loop using something else like $val
                # knail1 12/16/2001
                $id = $self->id(1);    # Force a new id to be generated.
        }

        # This really shouldn't happen.
        if ($i == 10) {
                $self->error("Unable to find a free row id after ten tries");
                return;
        }

        # Now that we have a valid row id, we can do the actual collector setup.
        $sess = new SNMP::Session(
                DestHost  => $source->addr(),
                Community => $source->write_community(),
                Version   => $source->snmp_version(),
        );

        # We will use the createAndWait method.
        $sess->set(
                new SNMP::Varbind(
                        [
                                $rttMonCtrlAdminStatus,          $id,
                                $rowStatusEnum->{createAndWait}, 'INTEGER'
                        ]
                )
        );

        if ($sess->{ErrorNum}) {
                $self->error("Failed to set row status");
                return;
        }
        my $varlist = new SNMP::VarList(

                #below: fixing calls to pull $operation data from $self instead of attempting locally
                # old:  $operation->protocol
                # new: $self->{operation}->{protocol}
                #knail1 12.16.2001
                [
                        $rttMonCtrlAdminRttType,    $id,
                        $self->{operation}->{type}, 'INTEGER'
                ],
                [
                        $rttMonEchoAdminProtocol,       $id,
                        $self->{operation}->{protocol}, 'INTEGER'
                ],
                [
                        $rttMonEchoAdminSourcePort,        $id,
                        $self->{operation}->source_port(), 'INTEGER'
                ],
                [
                        $rttMonEchoAdminTargetPort,        $id,
                        $self->{operation}->target_port(), 'INTEGER'
                ],
                [
                        $rttMonEchoAdminControlEnable,         $id,
                        $self->{operation}->control_enabled(), 'INTEGER'
                ],
                [
                        $rttMonEchoAdminTOS, $id, $self->{operation}->tos(),
                        'INTEGER'
                ],
                [
                        $rttMonEchoAdminCache,             $id,
                        $self->{operation}->admin_cache(), 'INTEGER'
                ],
        );

        # Add objects that may be undef for certain operations.

        if ($target) {
                push @{$varlist},
                    [
                        $rttMonEchoAdminTargetAddress, $id,
                        addrToOctStr($target->addr()), 'OCTSTR'
                    ];
        }

        if ($self->{operation}->name_server()) {
                push @{$varlist},
                    [
                        $rttMonEchoAdminNameServer, $id,
                        addrToOctStr($self->{operation}->name_server()),
                        'OCTSTR'
                    ];
        }

        if ($self->{operation}->admin_operation()) {
                push @{$varlist},
                    [
                        $rttMonEchoAdminOperation,             $id,
                        $self->{operation}->admin_operation(), 'INTEGER'
                    ];
        }

        if ($self->{operation}->admin_strings()) {
                my $i;
                for (
                        $i = 0 ;
                        $i < scalar(@{$self->{operation}->admin_strings()}) ;
                        $i++
                    )
                {
                        if ($self->{operation}->admin_strings()->[$i]) {
                                my $var = "rttMonEchoAdminString" . ($i + 1);
                                no strict
                                    'refs';  # We need to do this to allow $$var
                                push @{$varlist},
                                    [
                                        $$var,
                                        $id,
                                        $self->{operation}->admin_strings()
                                            ->[$i],
                                        'OCTSTR'
                                    ];
                        }
                }
        }

        if ($self->{operation}->admin_url()) {
                push @{$varlist},
                    [
                        $rttMonEchoAdminURL,             $id,
                        $self->{operation}->admin_url(), 'OCTSTR'
                    ];
        }

        # Set the objects on the source router.

##test: leaving test code in module as this would be used
        # to fix the snmp set failure bug.
        #foreach (@$varlist)	{
        #	my $tmp = $_;
        #	foreach (@$tmp){
        #	chomp;
        #	print $_." ";
        #			}
        #	print "\n";
        #			}
##end_test
        $sess->set($varlist);

        if ($sess->{ErrorNum}) {
                $self->error("Failed to set collector");
                return;
        }

        $varlist = new SNMP::VarList(
                [$rttMonScheduleAdminRttLife, $id, $self->life(), 'INTEGER'],
                [
                        $rttMonScheduleAdminRttStartTime, $id,
                        $self->start_time(),              'TICKS'
                ],
                [
                        $rttMonHistoryAdminFilter, $id,
                        $self->history_filter(),   'INTEGER'
                ],
                [$rttMonCtrlAdminNvgen, $id, $self->write_nvram(), 'INTEGER'],
                [
                        $rttMonCtrlAdminStatus,   $id,
                        $rowStatusEnum->{active}, 'INTEGER'
                ]
        );

        # Turn it on!
        $sess->set($varlist);

        if ($sess->{ErrorNum}) {
                $self->error("Failed to start collector");
                return;
        }

        1;
}

sub uninstall {
        my $self = shift;

        # Remove the collector by setting rttMonCtrlAdminStatus to destroy(6).
        if (!$self->id()) {
                $self->error("Collector id is not set");
                return;
        }

        my $source = $self->source();

        my $sess = new SNMP::Session(
                DestHost  => $source->addr(),
                Community => $source->write_community(),
                Version   => $source->snmp_version(),
        );

        $sess->set(
                new SNMP::Varbind(
                        [
                                $rttMonCtrlAdminStatus,    $self->id(),
                                $rowStatusEnum->{destroy}, 'INTEGER'
                        ]
                )
        );

        if ($sess->{ErrorNum}) {
                $self->error("Failed to uninstall collector");
                return;
        }

        1;
}

1;
