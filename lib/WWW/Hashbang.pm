use strict;
use warnings;
use 5.010001;
#use diagnostics;

package WWW::Hashbang;
# ABSTRACT: a simple CMS-like thing to quickly deploy text webpages

use Dancer 1.2000 qw(:syntax);
use Dancer::Cookie;
use File::Slurp;
use File::Basename qw(basename);
use HTML::Entities;
use Text::MultiMarkdown 1.000031 qw(markdown);
use autodie 2.10;

# Bring in admin functions
#use WWW::Hashbang::Admin;

prefix undef;

my $skins = ['milk', 'greypages', 'vector', 'style', 'canada']; # should go in a config file?

before sub {
    if( params->{useskin} ~~ $skins ) {
        var skin => params->{useskin};
        set_cookie(
            'skin'      => params->{useskin},
            'expires'   => (time + (60 * 60 * 24 * 30 * 6)), # 6 months
            'domain'    => request->host,
            'path'      => request->path,
        );
    }
    elsif (cookies->{skin}) {
        if (cookies->{skin}->value ~~ $skins) {
            var skin => cookies->{skin}->value;
        }
    }
};

# REDIRECT
get qr{^/?$} => sub {
    return redirect '/home';
};

# SOURCECODE
get "/Hashbang.pm/src" => sub {
    return redirect "/Hashbang.pm";
};

get "/Hashbang.pm" => sub {
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
    $filename = basename($filename);
    my $sourcecode = <<"";
<h1>Source code for <code>WWW::Hashbang</code></h1>
<pre id="source">

    while (<$file>) {
        $sourcecode .= $formatter->format_string;
    }
    $sourcecode .= '</pre>';
    close($file);

    my $data;
    $data->{title}   = $filename;
    $data->{links}   = links('$filename');
    $data->{content} = $sourcecode;
    $data->{footer}  = footer(undef, 'none');
    $data->{skin}    = vars->{skin} || config->{skin} || $skins->[0];
    $data->{popup}   = popup($filename, $data->{skin});

    template 'hashbang' => $data;
};

# SOURCE
get qr{^/([[:alpha:][:digit:]/_-]+)/src$} => sub {
    my ($file) = splat;
    $file =~ tr{/}{.};

    my @lines = read_file(config->{pages} . "/$file");
    my $data;

    $data->{title}   = encode_entities($lines[0]);
    $data->{content} = join('', @lines);
    $data->{links}   = links($file);
    $data->{footer}  = footer($file, 'source');
    $data->{skin}    = vars->{skin} || config->{skin} || $skins->[0];
    $data->{popup}   = popup($file, $data->{skin});

    template 'hashbang-source' => $data;
};

# VIEW
get qr{^/([[:alpha:][:digit:]/_-]+)$} => sub {
    my ($file) = splat;
    $file =~ tr{/}{.};

    if ( -r config->{pages} . "/$file" ) {
        my @lines = read_file(config->{pages} . "/$file");
        my $data;

        $data->{title}   = encode_entities($lines[0]);
        $data->{content} = markdown(join('', @lines), {
            trust_list_start_value => 1,
        });
        $data->{links}   = links($file);
        $data->{footer}  = footer($file, 'view');
        $data->{skin}    = vars->{skin} || config->{skin} || $skins->[0];
        $data->{popup}   = popup($file, $data->{skin});

        template 'hashbang' => $data;
    }
    else {
        my $data;
        $data->{title}   = "Directory listing ($file)";
        $data->{links}   = links($file);
        $data->{content} = dirlist($file);
        $data->{footer}  = footer($file, 'none');
        $data->{skin}    = vars->{skin} || config->{skin} || $skins->[0];
        $data->{popup}   = popup($file, $data->{skin});

        template 'hashbang' => $data;
    }
};

=head2 footer

This generates a footer based on the page and mode of the current request.

=cut

sub footer {
    my $page = shift;
    my $mode = shift;

    my $markdown = '<span id="popup-button"><input type="submit" value="Switch skins!" /></span>';
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
    $markdown .= <<"";
Rendered by [`WWW::Hashbang`](http://p3rl.org/WWW::Hashbang) ([see the source!](/Hashbang.pm)).

    return markdown($markdown);
}

=head2 dirlist

This performs a "directory" listing in the requested "directory".

=cut

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
    return markdown($markdown);
}

=head2 links

This generates the navigation links based on the current page.

=cut

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
        $html .= "<li class='here home'><a href='/home'>"
            . "<span class='here home'>home</span>"
            . "</a></li>\n";
            $printed->{home} = 1;
    }
    else {
        $html .= "<li class='home'><a href='/home'>"
            . "<span class='home'>home</span>"
            . "</a></li>\n";
            $printed->{home} = 1;
    }

    LINK: foreach my $file (@files) {
        # subpage
        if ( $file =~ tr/.// ) {    # faster than regex
            $file =~ s/\..*$//;     # extract the top-level dir
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

=head2 include_link

This returns whether or not the given link should be included in the navigation links based
on whether it has already been included, and the number of links permitted by the C<maxlinks>
setting.

=cut

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

=head2 popup

This returns HTML for the popup skin switcher

=cut

sub popup {
    my $page    = shift;
    my $exclude = shift;
    my $popup   = <<'END';
            <div id="popup-visible" style="display:none;">
                <a id="popup-close">x</a>
                <h1>Try out another skin!</h1>
                <p id="popup-text">
                    Click any of the images below to switch to that skin.
                    This will reload the page.
                </p>
                <div id='skin-images'>
END

    SKIN: foreach my $skin (@$skins){
        next SKIN if $skin eq $exclude;
        $popup .= <<"END";
                    <div class='imgframe'>
                        <a href="/$page?useskin=$skin">
                            <img src="/images/skin-$skin-small.png" alt="Try the $skin skin" width="250px" />
                        </a>
                        <p>"$skin" &mdash; view it <a href="/images/skin-$skin.png">bigger</a></p>
                    </div>
END
    }

    $popup .= <<'END';
                </div><!--/skin-images-->
            </div><!--/popup-visible-->
            <div id="popup-hidden" style="display:none;"></div><!--/popup-hidden-->
END

    return $popup;
}


true;

__END__
