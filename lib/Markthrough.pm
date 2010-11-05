package Markthrough;
# ABSTRACT: a simple CMS-like thing to quickly deploy text webpages

use Dancer ':syntax';
use File::Slurp;
use HTML::Entities;
use Text::Markdown 1.000031 qw(markdown);
use autodie 2.10;

# Bring in admin functions
#use Markthrough::Admin;

prefix undef;

# REDIRECT
get qr{^/?$} => sub {
    return redirect '/home';
};

# SOURCECODE
get '/Markthrough.pm' => sub {
    # From http://sedition.com/perl/perl-colorizer.html
    require Syntax::Highlight::Perl::Improved;
    my $color_table = {
        'Variable_Scalar'   => 'color:#080;',
        'Variable_Array'    => 'color:#f70;',
        'Variable_Hash'     => 'color:#80f;',
        'Variable_Typeglob' => 'color:#f03;',
        'Subroutine'        => 'color:#980;',
        'Quote'             => 'color:#00a;',
        'String'            => 'color:#00a;',
        'Comment_Normal'    => 'color:#069;font-style:italic;',
        'Comment_POD'       => 'color:#014;font-family:garamond,serif;font-size:11pt;',
        'Bareword'          => 'color:#3A3;',
        'Package'           => 'color:#900;',
        'Number'            => 'color:#f0f;',
        'Operator'          => 'color:#000;',
        'Symbol'            => 'color:#000;',
        'Keyword'           => 'color:#000;',
        'Builtin_Operator'  => 'color:#300;',
        'Builtin_Function'  => 'color:#001;',
        'Character'         => 'color:#800;',
        'Directive'         => 'color:#399;font-style:italic;',
        'Label'             => 'color:#939;font-style:italic;',
        'Line'              => 'color:#000;',
    };
    my $formatter = Syntax::Highlight::Perl::Improved->new();
    $formatter->define_substitution('<' => '&lt;',
                                    '>' => '&gt;',
                                    '&' => '&amp;'); # HTML escapes.

    # install the formats set up above
    while ( my ( $type, $style ) = each %{$color_table} ) {
        $formatter->set_format( $type, [ qq{<span style="$style">}, qq{</span>} ] );
    }

    my $filename = __FILE__;
    open(my $file, '<', $filename);
    my $sourcecode = <<"";
<h1>Source code for <code>Markthrough.pm</code></h1>
<pre id="source">

    while (<$file>) {
        $sourcecode .= $formatter->format_string;
    }
    $sourcecode .= '</pre>';
    close($file);

    my $data;
    $data->{title} = 'Markthrough.pm';
    $data->{links} = links('Markthrough.pm'); # ?
    $data->{markthrough} = $sourcecode;
    $data->{footer} = markthrough_footer(undef, 'none');
    $data->{skin} = 'greypages';

    template 'markthrough' => $data;
};

# SOURCE
get qr{^/([[:alpha:][:digit:]/_-]+)/src$} => sub {
    my ($file) = splat;
    $file =~ tr{/}{.};

    if ( -r config->{pages} . "/$file" ) {
        my @lines = read_file(config->{pages} . "/$file");
        my $data;

        $data->{title} = encode_entities($lines[0]);
        $data->{markthrough} = join('', @lines);
        $data->{links} = links($file);
        $data->{footer} = markthrough_footer($file, 'source');
        $data->{skin} = 'greypages';

        template 'source' => $data;
    }
    else {

    }
};

# VIEW
get qr{^/([[:alpha:][:digit:]/_-]+)$} => sub {
    my ($file) = splat;
    $file =~ tr{/}{.};

    if ( -r config->{pages} . "/$file" ) {
        my @lines = read_file(config->{pages} . "/$file");
        my $data;

        $data->{title} = encode_entities($lines[0]);
        $data->{markthrough} = markdown(join('', @lines), {
            trust_list_start_value => 1,
        });
        $data->{links} = links($file);
        $data->{footer} = markthrough_footer($file, 'view');
        $data->{skin} = 'greypages';

        template 'markthrough' => $data;
    }
    else {
        my $data;
        $data->{title} = "Directory listing ($file)";
        $data->{links} = links($file);
        $data->{markthrough} = markdown(dirlist($file));
        $data->{footer} = markthrough_footer($file, 'none');
        $data->{skin} = 'greypages';

        template 'markthrough' => $data;
    }
};


sub markthrough_footer {
    my $page = shift;
    my $mode = shift;

    my $markdown = '';
    if ($mode eq 'view') {
        $page =~ tr{.}{/};
        $markdown .= "View [page source](/$page/src).\n";
    }
    elsif ($mode eq 'source') {
        $page =~ s{/src$}{};
        $page =~ tr{.}{/};
        $markdown .= "Return to the [parsed](/$page) view.\n";
    }
    unless ($mode eq 'none') {
        $page =~ tr{/}{.};
        my $filename = config->{pages} . "/$page";
        my $modified = scalar localtime ((stat($filename))[9]);
        $markdown .= "Last modified $modified.\n"
    }
    $markdown .= <<"END";
Rendered by [Markthrough](http://hashbang.ca/~mike/page/projects/markthrough).[`pm`](/Markthrough.pm)
using [`Text::Markdown`](http://search.cpan.org/perldoc?Text::Markdown).
END

    return markdown($markdown);
}

sub dirlist {
    my $here = shift;

    opendir(my $dir, config->{pages});
    my @files = grep { /^\Q$here\E\./ } readdir($dir);
    closedir($dir);
    @files = sort { lc $a cmp lc $b } @files;

    my $markdown = "Pages in $here/\n";
    $markdown .= '=' x (length($markdown)-1) . "\n";
    foreach my $file (@files) {
        open my $fh, '<', config->{pages} . "/$file";
        my $title = <$fh>;
        close $fh;
        $file =~ tr{.}{/};
        $markdown .= " * [$title]($file) `($file)`\n";
    }
    return $markdown;
}

sub links {
    my $here = shift;

    opendir(my $dir, config->{pages});
    my @files = grep {! /(?:^\.|[~#]$)/ } readdir($dir);
    closedir($dir);
    @files = sort { lc $a cmp lc $b } @files;    # Case-insensitive sort

    my $printed;
    my @toprint;
    my $html = '';

    if ($here eq 'home') {
        $html .= "<li class='here home'><a href='home'>"
            . "<span class='here home'>home</span>"
            . "</a></li>\n";
            $printed->{home} = 1;
    }
    else {
        $html .= "<li class='home'><a href='home'>"
            . "<span class='home'>home</span>"
            . "</a></li>\n";
            $printed->{home} = 1;
    }

    LINK: foreach my $file (@files) {
        # subpage
        if ( $file =~ tr/.// ) {    # faster than regex
            $file =~ s/\..*$//;     # Extract the top-level dir
            if ( $here =~ m/^\Q$file\E/ ) {
                if ( include_link($file, config->{maxlinks}, $printed) ) {
                    push(@toprint, "<li class='here'><a href='/$file' class='here'><span class='here'>../$file/</span></a></li>\n");
                    $printed->{$file} = 1;
                }
            }
            else {
                if ( include_link($file, config->{maxlinks}, $printed) ) {
                    push(@toprint, "<li><a href='/$file'>$file/</a></li>\n");
                    $printed->{$file} = 1;
                }
            }
        }
        # page
        else {
            if ( $file eq $here ) {
                if ( include_link($file, config->{maxlinks}, $printed) ) {
                    push(@toprint, "<li class='here'><a href='/$file'><span class='here'>$file</span></a></li>\n");
                    $printed->{$file} = 1;
                }
            }
            else {
                if ( include_link($file, config->{maxlinks}, $printed) ) {
                    push(@toprint, "<li><a href='/$file'>$file</a></li>\n");
                    $printed->{$file} = 1;
                }
            }
        }
    }

    $html .= join('', @toprint);
    return $html;
}

sub include_link {
    my $link = shift;
    my $max  = shift;
    my $done = shift;

    if ((!$done->{$link}) and (
        ($max == 0 ) or (scalar keys(%{ $done }) < $max)
    )) {
        return true;
    }
    else {
        return false;
    }
}


true;

__END__
