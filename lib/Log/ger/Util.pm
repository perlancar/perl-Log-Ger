package Log::ger::Util;

# DATE
# VERSION

use strict;
use warnings;

require Log::ger;

sub _dump {
    unless ($Log::ger::_dumper) {
        eval { require Data::Dmp };
        if ($@) {
            no warnings 'once';
            require Data::Dumper;
            $Log::ger::_dumper = sub {
                local $Data::Dumper::Terse = 1;
                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Useqq = 1;
                local $Data::Dumper::Deparse = 1;
                local $Data::Dumper::Quotekeys = 0;
                local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Trailingcomma = 1;
                Data::Dumper::Dumper($_[0]);
            };
        } else {
            $Log::ger::_dumper = sub { Data::Dmp::dmp($_[0]) };
        }
    }
    $Log::ger::_dumper->($_[0]);
}

sub numeric_level {
    my $level = shift;
    return $level if $level =~ /\A\d+\z/;
    return $Log::ger::Levels{$level}
        if defined $Log::ger::Levels{$level};
    return $Log::ger::Level_Aliases{$level}
        if defined $Log::ger::Level_Aliases{$level};
    die "Unknown level '$level'";
}

sub string_level {
    my $level = shift;
    return $level if defined $Log::ger::Levels{$level};
    $level = $Log::ger::Level_Aliases{$level}
        if defined $Log::ger::Level_Aliases{$level};
    for (keys %Log::ger::Levels) {
        my $v = $Log::ger::Levels{$_};
        return $_ if $v == $level;
    }
    die "Unknown level '$level'";
}

sub set_level {
    no warnings 'once';
    $Log::ger::Current_Level = numeric_level(shift);
    reinit_all_targets();
}

sub _action_on_hooks {
    no warnings 'once';

    my ($action, $target, $target_arg, $phase) = splice @_, 0, 4;

    my $hooks = $Log::ger::Global_Hooks{$phase} or die "Unknown phase '$phase'";
    if ($target eq 'package') {
        $hooks = ($Log::ger::Per_Package_Hooks{$target_arg}{$phase} ||= []);
    } elsif ($target eq 'object') {
        my ($addr) = $target_arg =~ /\(0x(\w+)/;
        $hooks = ($Log::ger::Per_Object_Hooks{$addr}{$phase} ||= []);
    } elsif ($target eq 'hash') {
        my ($addr) = $target_arg =~ /\(0x(\w+)/;
        $hooks = ($Log::ger::Per_Hash_Hooks{$addr}{$phase} ||= []);
    }

    if ($action eq 'add') {
        my $hook = shift;
        # XXX remove duplicate key
        # my $key = $hook->[0];
        unshift @$hooks, $hook;
    } elsif ($action eq 'reset') {
        my $saved = [@$hooks];
        splice @$hooks, 0, scalar(@$hooks),
            @{ $Log::ger::Default_Hooks{$phase} };
        return $saved;
    } elsif ($action eq 'empty') {
        my $saved = [@$hooks];
        splice @$hooks, 0;
        return $saved;
    } elsif ($action eq 'save') {
        return [@$hooks];
    } elsif ($action eq 'restore') {
        my $saved = shift;
        splice @$hooks, 0, scalar(@$hooks), @$saved;
        return $saved;
    }
}

sub add_hook {
    my ($phase, $hook) = @_;
    _action_on_hooks('add', '', undef, $phase, $hook);
}

sub add_per_target_hook {
    my ($target, $target_arg, $phase, $hook) = @_;
    _action_on_hooks('add', $target, $target_arg, $phase, $hook);
}

sub reset_hooks {
    my ($phase) = @_;
    _action_on_hooks('reset', '', undef, $phase);
}

sub reset_per_target_hooks {
    my ($target, $target_arg, $phase) = @_;
    _action_on_hooks('reset', $target, $target_arg, $phase);
}

sub empty_hooks {
    my ($phase) = @_;
    _action_on_hooks('empty', '', undef, $phase);
}

sub empty_per_target_hooks {
    my ($target, $target_arg, $phase) = @_;
    _action_on_hooks('empty', $target, $target_arg, $phase);
}

sub save_hooks {
    my ($phase) = @_;
    _action_on_hooks('save', '', undef, $phase);
}

sub save_per_target_hooks {
    my ($target, $target_arg, $phase) = @_;
    _action_on_hooks('save', $target, $target_arg, $phase);
}

sub restore_hooks {
    my ($phase, $saved) = @_;
    _action_on_hooks('restore', '', undef, $phase, $saved);
}

sub restore_per_target_hooks {
    my ($target, $target_arg, $phase, $saved) = @_;
    _action_on_hooks('restore', $target, $target_arg, $phase, $saved);
}

sub set_plugin {
    no strict 'refs';

    my %args = @_;

    my $prefix = $args{prefix} || 'Log::ger::Plugin::';

    my $mod = $args{name};
    $mod = $prefix . $mod unless index($mod, $prefix) == 0;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    my $hooks = &{"$mod\::get_hooks"}(%{ $args{conf} || {} });

    for my $phase (keys %$hooks) {
        my $hook = $hooks->{$phase};
        if (defined $args{target}) {
            add_per_target_hook(
                $args{target}, $args{target_arg}, $phase, $hook);
        } else {
            add_hook($phase, $hook);
        }
    }

    my $reinit = $args{reinit};
    $reinit = 1 unless defined $reinit;
    if ($reinit) {
        if (defined $args{target}) {
            reinit_target($args{target}, $args{target_arg});
        } else {
            reinit_all_targets();
        }
    }
}

sub reinit_target {
    my ($target, $target_arg) = @_;

    # adds target if not already exists
    Log::ger::add_target($target, $target_arg, {}, 0);

    if ($target eq 'package') {
        my $init_args = $Log::ger::Package_Targets{$target_arg};
        Log::ger::init_target(package => $target_arg, $init_args);
    } elsif ($target eq 'object') {
        my ($obj_addr) = $target_arg =~ /\(0x(\w+)/
            or die "Invalid object '$target_arg': not a reference";
        my $v = $Log::ger::Object_Targets{$obj_addr}
            or die "Unknown object target '$target_arg'";
        Log::ger::init_target(object => $v->[0], $v->[1]);
    } elsif ($target eq 'hash') {
        my ($hash_addr) = $target_arg =~ /\(0x(\w+)/
            or die "Invalid hashref '$target_arg': not a reference";
        my $v = $Log::ger::Hash_Targets{$hash_addr}
            or die "Unknown hash target '$target_arg'";
        Log::ger::init_target(hash => $v->[0], $v->[1]);
    } else {
        die "Unknown target '$target'";
    }
}

sub reinit_all_targets {
    for my $pkg (keys %Log::ger::Package_Targets) {
        Log::ger::init_target(
            package => $pkg, $Log::ger::Package_Targets{$pkg});
    }
    for my $k (keys %Log::ger::Object_Targets) {
        my ($obj, $init_args) = @{ $Log::ger::Object_Targets{$k} };
        Log::ger::init_target(object => $obj, $init_args);
    }
    for my $k (keys %Log::ger::Hash_Targets) {
        my ($hash, $init_args) = @{ $Log::ger::Hash_Targets{$k} };
        Log::ger::init_target(hash => $hash, $init_args);
    }
}

1;
# ABSTRACT: Utility routines for Log::ger

=for Pod::Coverage ^(.+)$

=head1 DESCRIPTION

This package is created to keep Log::ger as minimalist as possible.
