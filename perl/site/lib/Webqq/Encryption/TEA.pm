package Webqq::Encryption::TEA;
use strict;
use Carp;
use MIME::Base64 ();
use Webqq::Encryption::TEA::Perl;

BEGIN{
        eval{require JE;};
        $Webqq::Encryption::TEA::has_je = 1 unless $@;
}


sub encrypt_js{
    my ($key,$data) = @_;
    my $je = _load_je();
    my $p = $je->eval(qq#
        var tea = TEA();
        tea.initkey('$key');
        var r = tea.encrypt2('$data');
        tea.initkey('');
        return(r);
    #);
    if($p and !$@){
        return $p;
    }
    else{
        croak "Webqq::Encryption::TEA error: $@\n";
    }
}
sub decrypt_js{
    my ($key,$data) = @_;
    my $je = _load_je();
    my $p = $je->eval(qq#
        var tea = TEA();
        tea.initkey('$key');
        var r = tea.decrypt('$data');
        tea.initkey('');
        return(r);
    #);
    if($p and !$@){
        return $p;
    }
    else{
        croak "Webqq::Encryption::TEA error: $@\n";
    }
}

sub strToHex{
    my $str = shift;
    my $return = "";   
    for(split //,$str){$return .= sprintf "%02x",ord($_)};
    return $return;
}

sub hexToStr{
    return pack "H*",lc shift;
}
sub _load_je{
    my $je;
    croak "The JE module is not found, You may install it first\n" unless $Webqq::Encryption::TEA::has_je;
    if(defined $Webqq::Encryption::TEA::_je ){
        $je = $Webqq::Encryption::TEA::_je ;
    }
    else{
        my $javascript;
        if(defined $Webqq::Encryption::TEA::_javascript){
            $javascript = $Webqq::Encryption::TEA::_javascript;
        }
        else{
            local $/ = undef;
            $javascript = <DATA>;
            $Webqq::Encryption::TEA::_javascript = $javascript;
            close DATA;
        }
        $je = JE->new;
        $je->eval($javascript);
        croak "Webqq::Encryption::TEA load javascript error: $@\n" if $@;
        $Webqq::Encryption::TEA::_je = $je;
    }    
    return $je;
}
sub encrypt {
    my ($key,$data) = @_;
    my $p = Webqq::Encryption::TEA::Perl::encrypt(hexToStr($data),hexToStr($key));
    return lc join "",unpack "H*",$p;

    my $je = _load_je();
    $p = $je->eval(qq#
        var tea = TEA();
        tea.initkey('$key');
        var r = tea.encrypt('$data');    
        tea.initkey('');
        return(r);
    #);
    if($p and !$@){
        return $p;
    }
    else{
        croak "Webqq::Encryption::TEA error: $@\n";
    }
}

1;
__DATA__
function TEA() {
    var r = "",
    a = 0,
    g = [],
    w = [],
    x = 0,
    t = 0,
    l = [],
    s = [],
    m = true;
    function e() {
        return Math.round(Math.random() * 4294967295)
    }
    function i(B, C, y) {
        if (!y || y > 4) {
            y = 4
        }
        var z = 0;
        for (var A = C; A < C + y; A++) {
            z <<= 8;
            z |= B[A]
        }
        return (z & 4294967295) >>> 0
    }
    function b(z, A, y) {
        z[A + 3] = (y >> 0) & 255;
        z[A + 2] = (y >> 8) & 255;
        z[A + 1] = (y >> 16) & 255;
        z[A + 0] = (y >> 24) & 255
    }
    function v(B) {
        if (!B) {
            return ""
        }
        var y = "";
        for (var z = 0; z < B.length; z++) {
            var A = Number(B[z]).toString(16);
            if (A.length == 1) {
                A = "0" + A
            }
            y += A
        }
        return y
    }
    function u(z) {
        var A = "";
        for (var y = 0; y < z.length; y += 2) {
            A += String.fromCharCode(parseInt(z.substr(y, 2), 16))
        }
        return A
    }
    function c(A) {
        if (!A) {
            return ""
        }
        var z = [];
        for (var y = 0; y < A.length; y++) {
            z[y] = A.charCodeAt(y)
        }
        return v(z)
    }
    function h(A) {
        g = new Array(8);
        w = new Array(8);
        x = t = 0;
        m = true;
        a = 0;
        var y = A.length;
        var B = 0;
        a = (y + 10) % 8;
        if (a != 0) {
            a = 8 - a
        }
        l = new Array(y + a + 10);
        g[0] = ((e() & 248) | a) & 255;
        for (var z = 1; z <= a; z++) {
            g[z] = e() & 255
        }
        a++;
        for (var z = 0; z < 8; z++) {
            w[z] = 0
        }
        B = 1;
        while (B <= 2) {
            if (a < 8) {
                g[a++] = e() & 255;
                B++
            }
            if (a == 8) {
                o()
            }
        }
        var z = 0;
        while (y > 0) {
            if (a < 8) {
                g[a++] = A[z++];
                y--
            }
            if (a == 8) {
                o()
            }
        }
        B = 1;
        while (B <= 7) {
            if (a < 8) {
                g[a++] = 0;
                B++
            }
            if (a == 8) {
                o()
            }
        }
        return l
    }
    function p(C) {
        var B = 0;
        var z = new Array(8);
        var y = C.length;
        s = C;
        if (y % 8 != 0 || y < 16) {
            return null
        }
        w = k(C);
        a = w[0] & 7;
        B = y - a - 10;
        if (B < 0) {
            return null
        }
        for (var A = 0; A < z.length; A++) {
            z[A] = 0
        }
        l = new Array(B);
        t = 0;
        x = 8;
        a++;
        var D = 1;
        while (D <= 2) {
            if (a < 8) {
                a++;
                D++
            }
            if (a == 8) {
                z = C;
                if (!f()) {
                    return null
                }
            }
        }
        var A = 0;
        while (B != 0) {
            if (a < 8) {
                l[A] = (z[t + a] ^ w[a]) & 255;
                A++;
                B--;
                a++
            }
            if (a == 8) {
                z = C;
                t = x - 8;
                if (!f()) {
                    return null
                }
            }
        }
        for (D = 1; D < 8; D++) {
            if (a < 8) {
                if ((z[t + a] ^ w[a]) != 0) {
                    return null
                }
                a++
            }
            if (a == 8) {
                z = C;
                t = x;
                if (!f()) {
                    return null
                }
            }
        }
        return l
    }
    function o() {
        for (var y = 0; y < 8; y++) {
            if (m) {
                g[y] ^= w[y]
            } else {
                g[y] ^= l[t + y]
            }
        }
        var z = j(g);
        for (var y = 0; y < 8; y++) {
            l[x + y] = z[y] ^ w[y];
            w[y] = g[y]
        }
        t = x;
        x += 8;
        a = 0;
        m = false
    }
    function j(A) {
        var B = 16;
        var G = i(A, 0, 4);
        var F = i(A, 4, 4);
        var I = i(r, 0, 4);
        var H = i(r, 4, 4);
        var E = i(r, 8, 4);
        var D = i(r, 12, 4);
        var C = 0;
        var J = 2654435769 >>> 0;
        while (B-->0) {
            C += J;
            C = (C & 4294967295) >>> 0;
            G += ((F << 4) + I) ^ (F + C) ^ ((F >>> 5) + H);
            G = (G & 4294967295) >>> 0;
            F += ((G << 4) + E) ^ (G + C) ^ ((G >>> 5) + D);
            F = (F & 4294967295) >>> 0
        }
        var K = new Array(8);
        b(K, 0, G);
        b(K, 4, F);
        return K
    }
    function k(A) {
        var B = 16;
        var G = i(A, 0, 4);
        var F = i(A, 4, 4);
        var I = i(r, 0, 4);
        var H = i(r, 4, 4);
        var E = i(r, 8, 4);
        var D = i(r, 12, 4);
        var C = 3816266640 >>> 0;
        var J = 2654435769 >>> 0;
        while (B-->0) {
            F -= ((G << 4) + E) ^ (G + C) ^ ((G >>> 5) + D);
            F = (F & 4294967295) >>> 0;
            G -= ((F << 4) + I) ^ (F + C) ^ ((F >>> 5) + H);
            G = (G & 4294967295) >>> 0;
            C -= J;
            C = (C & 4294967295) >>> 0
        }
        var K = new Array(8);
        b(K, 0, G);
        b(K, 4, F);
        return K
    }
    function f() {
        var y = s.length;
        for (var z = 0; z < 8; z++) {
            w[z] ^= s[x + z]
        }
        w = k(w);
        x += 8;
        a = 0;
        return true
    }
    function n(C, B) {
        var A = [];
        if (B) {
            for (var z = 0; z < C.length; z++) {
                A[z] = C.charCodeAt(z) & 255
            }
        } else {
            var y = 0;
            for (var z = 0; z < C.length; z += 2) {
                A[y++] = parseInt(C.substr(z, 2), 16)
            }
        }
        return A
    }

    return {
        encrypt2: function(B, A) {
            var z = n(B, A);
            var y = h(z);
            return v(y)
        },
        encrypt: function(D, C) {
            var B = n(D, C);
            var A = h(B);   
            var y = "";
            for (var z = 0; z < A.length; z++) {
                y += String.fromCharCode(A[z])
            }
            return y;
        }, 
        decrypt: function(A) {
            var z = n(A, false);
            var y = p(z);
            return v(y)
        },
        initkey: function(y, z) {
            r = n(y, z)
        },
        bytesToStr: u,
        strToBytes: c,
        bytesInStr: v,
        dataFromStr: n,
    }
};
