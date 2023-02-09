#! perl -w

use strict ;
require 5.006 ;

use lib '.';
use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

my $WALL= '';
$WALL = ' -Wall -Wno-comment ' if $Config{'cc'} =~ /gcc/ ;

my $ZSTD_LIB = defined($ENV{ZSTD_LIB}) ? "-L$ENV{ZSTD_LIB}" : '';
my $ZSTD_INCLUDE = defined($ENV{ZSTD_INCLUDE}) ? "-I$ENV{ZSTD_INCLUDE}" : '';

#ParseCONFIG() ;

# UpDowngrade(getPerlFiles('MANIFEST'))
#     unless $ENV{PERL_CORE};

my $base = '/media/paul/Linux-Shared/base/git/zstd/lib';

WriteMakefile(
    NAME         => 'Compress::Stream::Zstd',
    VERSION_FROM => 'lib/Compress/Stream/Zstd.pm',
    INC          => "-Ilib/Compress/Stream $ZSTD_INCLUDE",
    DEFINE       => "$WALL -DUSE_PPPORT_H" ,
    XS           => { 'Zstd.xs' => 'Zstd.c'},
    OBJECT       => ['Zstd.o'],
    'clean'      => { FILES      => 'Zstd.c constants.h constants.xs' },
    #'depend'     => { 'Makefile'   => 'config.in' },
    'dist'       => { COMPRESS     => 'gzip',
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    LIBS => [ " $ZSTD_LIB -lzstd " ],

    (
      $] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Compress/Stream/Zstd.pm',
            AUTHOR       => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

    INSTALLDIRS => ($] > 5.010  && $] < 5.011 ? 'perl' : 'site'),

     ( eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? ( META_MERGE  => {

                "meta-spec" => { version => 2 },

                no_index => {
                    directory => [ 't', 'private' ],
                },

                resources   => {

                    bugtracker  => {
                        web     => 'https://github.com/pmqs/Compress-Stream-Zstd/issues'
                    },

                    homepage    => 'https://github.com/pmqs/Compress-Stream-Zstd',

                    repository  => {
                        type    => 'git',
                        url     => 'git://github.com/pmqs/Compress-Stream-Zstd.git',
                        web     => 'https://github.com/pmqs/Compress-Stream-Zstd',
                    },
                },
              }
            )
        : ()
    ),

    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),

) ;

my @names = () ; # qw(
		# BZ_RUN
		# BZ_FLUSH
		# BZ_FINISH

		# BZ_OK
		# BZ_RUN_OK
		# BZ_FLUSH_OK
		# BZ_FINISH_OK
		# BZ_STREAM_END
		# BZ_SEQUENCE_ERROR
		# BZ_PARAM_ERROR
		# BZ_MEM_ERROR
		# BZ_DATA_ERROR
		# BZ_DATA_ERROR_MAGIC
		# BZ_IO_ERROR
		# BZ_UNEXPECTED_EOF
		# BZ_OUTBUFF_FULL
		# BZ_CONFIG_ERROR
    	# );

if (eval {require ExtUtils::Constant; 1}) {
    # Check the constants above all appear in @EXPORT in Zstd.pm
    my %names = map { $_, 1} @names ; #, 'BZ_VERSION';
    open F, "<lib/Compress/Stream/Zstd.pm" or die "Cannot open Zstd.pm: $!\n";
    while (<F>)
    {
        last if /^\s*\@EXPORT\s+=\s+qw\(/ ;
    }

    while (<F>)
    {
        last if /^\s*\)/ ;
        /(\S+)/ ;
        delete $names{$1} if defined $1 ;
    }
    close F ;

    if ( keys %names )
    {
        my $missing = join ("\n\t", sort keys %names) ;
        die "The following names are missing from \@EXPORT in Zstd.pm\n" .
            "\t$missing\n" ;
    }

    #push @names, {name => 'BZ_VERSION', type => 'PV' };

    ExtUtils::Constant::WriteConstants(
                                     NAME     => 'Zstd',
                                     NAMES    => \@names,
                                     C_FILE   => 'constants.h',
                                     XS_FILE  => 'constants.xs',

                                    );
}
else {
    foreach my $name (qw( constants.h constants.xs ))
    {
        my $from = catfile('fallback', $name);
        copy ($from, $name)
          or die "Can't copy $from to $name: $!";
    }
}


sub Zstd_files
{
    my $dir = shift ;

    my @c_files = qw(
        blocksort.c
        huffman.c
        crctable.c
        randtable.c
        compress.c
        decompress.c
        bzlib.c
    );

    my @h_files = qw( bzlib.h  bzlib_private.h );

    foreach my $file (@c_files, @h_files)
      { copy(catfile($dir, $file), '.') }


    @h_files = map { catfile($dir, $_)  } @h_files ;
    my @o_files = map { "$_\$(OBJ_EXT)" } 'Zstd', @c_files;
    push @c_files, 'Zstd.c' ;

    return (
        #'H'         =>  [ @h_files ],
    	'C'         =>  [ @c_files ] ,
        #'OBJECT'    => qq[ @o_files ],
        'OBJECT'    => q[ $(O_FILES) ],


           ) ;
}
