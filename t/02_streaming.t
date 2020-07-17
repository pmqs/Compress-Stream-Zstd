use strict;
use warnings;

use Test::More;
use Compress::Stream::Zstd;
use Compress::Stream::Zstd::Compressor qw(ZSTD_CSTREAM_IN_SIZE);
use Compress::Stream::Zstd::Decompressor qw(ZSTD_DSTREAM_IN_SIZE);

cmp_ok ZSTD_CSTREAM_IN_SIZE, '>', 0;
cmp_ok ZSTD_DSTREAM_IN_SIZE, '>', 0;

my $compressor = Compress::Stream::Zstd::Compressor->new;
isa_ok $compressor, 'Compress::Stream::Zstd::Compressor';
my $output = '';
$output .= $compressor->compress('a');
$output .= $compressor->compress('b');
$output .= $compressor->compress('c');
$output .= $compressor->flush;
$output .= $compressor->end;
ok $output;

my $decompressor = Compress::Stream::Zstd::Decompressor->new;
isa_ok $decompressor, 'Compress::Stream::Zstd::Decompressor';
my $result = '';
$result .= $decompressor->decompress(substr($output, 0, 3));
$result .= $decompressor->decompress(substr($output, 3, -1));
is $result, 'abc';

is decompress($output), 'abc';

done_testing;
