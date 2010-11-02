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

        template 'markthrough' => $data;
    }
    else {
        my $data;
        $data->{title} = "Directory listing ($file)";
        $data->{links} = links($file);
        $data->{markthrough} = markdown(dirlist($file));

        template 'markthrough' => $data;
    }
};


sub markthrough_footer {
    my $page = shift;
    my $mode = shift;

    my $modified = scalar localtime ((stat(config->{pages} . "/$page"))[9]);
    my $markdown;
    if ($mode eq 'view') {
        $page =~ tr{.}{/};
        $markdown = <<"END";
View [page source](/$page/src). Last modified $modified.
Rendered with [markthrough](http://hashbang.ca/~mike/page/projects/markthrough)
and [Text::Markdown](http://search.cpan.org/perldoc?Text::Markdown).
END
    }
    elsif ($mode eq 'source') {
        $page =~ s{/src$}{};
        $page =~ tr{.}{/};
        $markdown = <<"END";
Return to the [parsed](/$page) view. Last modified $modified.
Rendered with [markthrough](http://hashbang.ca/~mike/page/projects/markthrough)
and [Text::Markdown](http://search.cpan.org/perldoc?Text::Markdown).
END
    }

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
        $markdown .= " * [$title]($file)\n";
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
