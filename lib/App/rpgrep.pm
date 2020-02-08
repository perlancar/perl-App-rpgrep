## no critic: InputOutput::RequireBriefOpen

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::RegexpPatternUtils;
use AppBase::Grep;
use Perinci::Sub::Util qw(gen_modified_sub);
use Regexp::Pattern;

our %SPEC;

gen_modified_sub(
    output_name => 'rpgrep',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines matching a Regexp::Pattern pattern',
    description => <<'_',

_
    remove_args => {
        'regexps',
        'pattern',
    },
    add_args    => {
        %App::RegexpPatternUtils::args_common_get_pattern,
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            pos => 1,
            greedy => 1,
        },
        # XXX recursive (-r)
    },
    output_code => sub {
        my %args = @_;
        my ($fh, $file);

        my @files = @{ delete($args{files}) // [] };
        my %gen_args = %{ delete($args{gen_args}) // {} };
        $gen_args{-anchor} = 1 if delete $args{anchor};
        $args{pattern} = re($args{pattern}, \%gen_args);

        # XXX remove code duplication with App::abgrep

        my $show_label = 0;
        if (!@files) {
            $fh = \*STDIN;
        } elsif (@files > 1) {
            $show_label = 1;
        }

        $args{_source} = sub {
          READ_LINE:
            {
                if (!defined $fh) {
                    return unless @files;
                    $file = shift @files;
                    log_trace "Opening $file ...";
                    open $fh, "<", $file or do {
                        warn "rpgrep: Can't open '$file': $!, skipped\n";
                        undef $fh;
                    };
                    redo READ_LINE;
                }

                my $line = <$fh>;
                if (defined $line) {
                    return ($line, $show_label ? $file : undef);
                } else {
                    undef $fh;
                    redo READ_LINE;
                }
            }
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT:
