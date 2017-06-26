#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

package My::P1;
use Log::ger;

package My::P2;

package main;

subtest numeric_level => sub {
    is(Log::ger::Util::numeric_level(1), 1);
    is(Log::ger::Util::numeric_level("info"), 4);
    # XXX check unknown level
};

subtest string_level => sub {
    is(Log::ger::Util::string_level(1), "fatal");
    is(Log::ger::Util::string_level("info"), "info");
    is(Log::ger::Util::string_level("warning"), "warn");
    # XXX check unknown level
};

subtest "basics" => sub {
    subtest "import" => sub {
        my $str = "";
        Log::ger::Util::reset_hooks('create_log_routine');
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);

        My::P1::log_warn("warn");
        My::P1::log_debug("debug");
        is($str, "warn\n");
        {
            $str = "";
            Log::ger::Util::set_level(5);
            My::P1::log_warn("warn");
            My::P1::log_debug("debug");
            is($str, "warn\ndebug\n");
        }
    };

    subtest "init_target package" => sub {
        my $str = "";
        Log::ger::Util::reset_hooks('create_log_routine');
        Log::ger::Util::set_level(3);
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::init_target(package => 'My::P2');
        My::P2::log_warn("warn");
        My::P2::log_debug("debug");
        is($str, "warn\n");
    };

    subtest "init_target hash" => sub {
        my $str = "";
        Log::ger::Util::reset_hooks('create_log_routine');
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::Util::set_level(3);
        my $h = {}; Log::ger::init_target(hash => $h);

        is(ref $h, 'HASH');
        $h->{fatal}("fatal");
        $h->{error}("error");
        $h->{warn}("warn");
        $h->{info}("info");
        $h->{debug}("debug");
        $h->{trace}("trace");
        is($str, "fatal\nerror\nwarn\n");
    };

    subtest "init_target object" => sub {
        my $str = "";
        Log::ger::Util::reset_hooks('create_log_routine');
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::Util::set_level(3);
        my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);

        $o->fatal("fatal");
        $o->error("error");
        $o->warn("warn");
        $o->info("info");
        $o->debug("debug");
        $o->trace("trace");
        is($str, "fatal\nerror\nwarn\n");

        subtest "level=off (0)" => sub {
            $str = "";
            Log::ger::Util::set_level(0);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "");
        };
        subtest "level=fatal (1)" => sub {
            $str = "";
            Log::ger::Util::set_level(1);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\n");
        };
        subtest "level=error (2)" => sub {
            $str = "";
            Log::ger::Util::set_level(2);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\nerror\n");
        };
        subtest "level=info (4)" => sub {
            $str = "";
            Log::ger::Util::set_level(4);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\n");
        };
        subtest "level=debug (5)" => sub {
            $str = "";
            Log::ger::Util::set_level(5);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\ndebug\n");
        };
        subtest "level=trace (6)" => sub {
            $str = "";
            Log::ger::Util::set_level(6);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\ndebug\ntrace\n");
        };
    };
};

DONE_TESTING:
done_testing
    ;
