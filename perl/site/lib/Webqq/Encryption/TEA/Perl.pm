package Webqq::Encryption::TEA::Perl;
use strict;
#源码参考cpan模块Crypt::OICQ，感谢作者Shufeng Tan
my $TEA_ROUNDS = 0x10;
my $TEA_DELTA  = 0x9E3779B9;
my $TEA_SUM    = 0xE3779B90;
sub tea_decrypt {
    use integer;
    my ($c_block, $key) = @_;
    my ($y, $z) = unpack("NN", $c_block);
    my ($a, $b, $c, $d) = unpack("NNNN", $key);
    my $sum = $TEA_SUM;
    my $n = $TEA_ROUNDS;
    while ($n-- > 0) {
        $z -= ($y<<4)+$c ^ $y+$sum ^ (0x07ffffff & ($y>>5))+$d;
        $y -= ($z<<4)+$a ^ $z+$sum ^ (0x07ffffff & ($z>>5))+$b;
        $sum -= $TEA_DELTA;
    }
    pack("NN", $y, $z);
}

sub decrypt {
    my ($crypt, $key) = @_;
    my $crypt_len = length($crypt);
    if (($crypt_len % 8) || ($crypt_len < 16)) {
        warn "Webqq::Encryption::TEA::Perl::decrypt error: invalid input length $crypt_len\n";
        return undef;
    }
    my $c_buf = substr($crypt, 0, 8);
    my $p_buf = tea_decrypt($c_buf, $key);
    my $pad_len = ord(substr($p_buf, 0, 1) & "\007");
    my $plain_len = $crypt_len - $pad_len - 10;
    my $plain = $p_buf;
    my $pre_plain = $p_buf;
    my $pre_crypt = $c_buf;

    for (my $i = 8; $i < $crypt_len; $i += 8) {
        $c_buf = substr($crypt, $i, 8);
        $p_buf = tea_decrypt($c_buf ^ $pre_plain, $key);
        $pre_plain = $p_buf;
        $p_buf ^= $pre_crypt;
        $plain .= $p_buf;
        $pre_crypt = $c_buf;
    }
    if (substr($plain, -7, 7) ne "\0\0\0\0\0\0\0") {
        warn "Webqq::Encryption::TEA::Perl::decrypt error: bad decrypt data\n",
            "crypt: ", unpack("H*", $crypt), "\n",
            "key: ", unpack("H*", $key), "\n",
            "plain: ", unpack("H*", $plain), "\n";
        return undef;
    }
    return substr($plain, -7-$plain_len, $plain_len);
}

sub tea_encrypt {
    use integer;
    my ($p_block, $key) = @_;
    my ($y, $z) = unpack("NN", $p_block);
    my ($a, $b, $c, $d) = unpack("NNNN", $key);
    my $sum = 0;
    my $n = $TEA_ROUNDS;
    while ($n-- > 0) {
        $sum += $TEA_DELTA;
        $y += ($z<<4)+$a ^ $z+$sum ^ (0x07ffffff & ($z>>5))+$b;
        $z += ($y<<4)+$c ^ $y+$sum ^ (0x07ffffff & ($y>>5))+$d;
    }
    pack("NN", $y, $z);
}
sub encrypt {
    my ($plain, $key) = @_;
    my $plain_len = length($plain);
    my $head_pad_len = ($plain_len + 10) % 8;
    $head_pad_len = 8 - $head_pad_len if $head_pad_len;
    my $padded_plain = chr(0xa8 + $head_pad_len) .
       rand_str(2+$head_pad_len) .
       #(chr(0xad) x (2 + $head_pad_len)) .
                       $plain . ("\0" x 7);
    my $padded_plain_len = length($padded_plain);
    my $crypt = "";
    my $pre_plain = "\0" x 8;
    my $pre_crypt = $pre_plain;
    for (my $i = 0; $i < $padded_plain_len; $i += 8) {
        my $p_buf = substr($padded_plain, $i, 8) ^ $pre_crypt;
    my $c_buf = tea_encrypt($p_buf, $key);
    $c_buf ^= $pre_plain;
    $crypt .= $c_buf;
    $pre_crypt = $c_buf;
    $pre_plain = $p_buf;
    }
    return $crypt;
}
sub rand_str {
    my $len = pop;
    join('', map(pack("C", rand(0xff)), 1..$len));
}
1;
