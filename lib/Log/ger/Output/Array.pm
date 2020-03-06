package Log::ger::Output::Array;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

sub get_hooks {
    my %conf = @_;

    $conf{array} or die "Please specify array";

    return {
        create_log_routine => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $logger = sub {
                    my ($per_target_conf, $msg, $per_msg_conf) = @_;
                    push @{$conf{array}}, $msg;
                };
                [$logger];
            }],
    };
}

1;
# ABSTRACT: Log to array

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

 use Log::ger::Output Array => (
     array         => $ary,
 );


=head1 DESCRIPTION

Mainly for testing only.


=head1 CONFIGURATION

=head2 array => arrayref

Required.


=head1 SEE ALSO

L<Log::ger>

=cut
