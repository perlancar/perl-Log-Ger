package Log::ger::Output::String;

# DATE
# VERSION

use Log::ger::Util;

sub import {
    my ($package, %import_args) = @_;

    my $append_newline = $import_args{append_newline};
    $append_newline = 1 unless defined $append_newline;

    my $plugin = sub {
        my %args = @_;
        my $level = $args{level};
        my $code = sub {
            my $msg = $_[1];
            if ($formatter) {
                $msg = $formatter->($msg);
            }
            ${ $import_args{string} } .= $msg;
            ${ $import_args{string} } .= "\n"
                unless !$append_newline || $msg =~ /\R\z/;
        };
        [$code];
    };

    Log::ger::Util::add_plugin(
        'create_log_routine', [50, $plugin, __PACKAGE__], 'replace');
}

1;
# ABSTRACT: Set output to a string

=head1 SYNOPSIS

 use var '$str';
 use Log::ger::Output 'String' => (
     string => \$str,
     # append_newline => 0, # default is true, to mimic Log::ger::Output::Screen
 );
 use Log::ger;

 log_warn "blah ...";
 log_error "blah ...";

C<$str> will contain "blah ...\nblah ...\n".


=head1 DESCRIPTION

For testing only.


=head1 CONFIGURATION

=head2 string => scalarref
