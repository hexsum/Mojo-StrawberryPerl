package Webqq::Encryption::RSA;
use strict;
use Carp;

BEGIN{
    eval{
        require Crypt::OpenSSL::RSA;
        require Crypt::OpenSSL::Bignum;
    };
    unless($@){
        $Webqq::Encryption::RSA::has_crypt_openssl_rsa = 1;
    }
    else{
        eval{
            require Crypt::RSA::ES::PKCS1v15;
            require Crypt::RSA::Key::Public;
        };
        unless($@){
            $Webqq::Encryption::RSA::has_crypt_rsa = 1;
        }
        else{
            eval{require JE;};
            unless($@){
                $Webqq::Encryption::RSA::has_je = 1;
            }
            else{
                croak "You must install Crypt::RSA or Crypt::OpenSSL::RSA or JE module to support rsa encrypt\n";
            }
        }
    }
    
}

sub encrypt {
    my $data = shift;
    if($Webqq::Encryption::RSA::has_crypt_rsa){
        my $n = "0xE9A815AB9D6E86ABBF33A4AC64E9196D5BE44A09BD0ED6AE052914E1A865AC8331FED863DE8EA697E9A7F63329E5E23CDA09C72570F46775B7E39EA9670086F847D3C9C51963B131409B1E04265D9747419C635404CA651BBCBC87F99B8008F7F5824653E3658BE4BA73E4480156B390BB73BC1F8B33578E7A4E12440E9396F2552C1AFF1C92E797EBACDC37C109AB7BCE2367A19C56A033EE04534723CC2558CB27368F5B9D32C04D12DBD86BBD68B1D99B7C349A8453EA75D1B2E94491AB30ACF6C46A36A75B721B312BEDF4E7AAD21E54E9BCBCF8144C79B6E3C05EB4A1547750D224C0085D80E6DA3907C3D945051C13C7C1DCEFD6520EE8379C4F5231ED";
        my $public = Crypt::RSA::Key::Public->new();
        $public->e("0x10001");
        $public->n($n);
        my $rsa = Crypt::RSA::ES::PKCS1v15->new();
        return lc join "",unpack "H*", $rsa->encrypt(Message=>$data,Key=>$public,);
    }
    elsif($Webqq::Encryption::RSA::has_crypt_openssl_rsa){
        my $n = Crypt::OpenSSL::Bignum->new_from_hex("E9A815AB9D6E86ABBF33A4AC64E9196D5BE44A09BD0ED6AE052914E1A865AC8331FED863DE8EA697E9A7F63329E5E23CDA09C72570F46775B7E39EA9670086F847D3C9C51963B131409B1E04265D9747419C635404CA651BBCBC87F99B8008F7F5824653E3658BE4BA73E4480156B390BB73BC1F8B33578E7A4E12440E9396F2552C1AFF1C92E797EBACDC37C109AB7BCE2367A19C56A033EE04534723CC2558CB27368F5B9D32C04D12DBD86BBD68B1D99B7C349A8453EA75D1B2E94491AB30ACF6C46A36A75B721B312BEDF4E7AAD21E54E9BCBCF8144C79B6E3C05EB4A1547750D224C0085D80E6DA3907C3D945051C13C7C1DCEFD6520EE8379C4F5231ED");
        my $e = Crypt::OpenSSL::Bignum->new_from_hex("10001");
        my $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters($n,$e);
        $rsa->use_pkcs1_padding();
        return lc join "",unpack "H*", $rsa->encrypt($data);    
    }

    $data = join "",map {"\\x$_"} unpack "H2"x length($data),$data;
    my $je;
    if(defined $Webqq::Encryption::RSA::_je ){
        $je = $Webqq::Encryption::RSA::_je ;
    }
    else{
        my $javascript;
        if(defined $Webqq::Encryption::RSA::_javascript){
            $javascript = $Webqq::Encryption::RSA::_javascript;
        }
        else{
            local $/ = undef;
            $javascript = <DATA>;
            $Webqq::Encryption::RSA::_javascript = $javascript;
            close DATA;
        }
        $je = JE->new;
        $je->eval($javascript);
        croak "Webqq::Encryption::RSA load javascript error: $@\n" if $@;
        $Webqq::Encryption::RSA::_je = $je;
    }
    
    #print qq#
    #    var rsa = RSA();
    #    var r = rsa.rsa_encrypt('$data');
    #    return(r);
    ##;
    my $p = $je->eval(qq#
        var rsa = RSA();
        var r = rsa.rsa_encrypt('$data');
        return(r);
    #);
    if($p and !$@){
        return $p;
    }
    else{
        croak "Webqq::Encryption::RSA error: $@\n"; 
    }
     
}

1;
__DATA__
var navigator = {"appName": "Netscape"};
function RSA() {
    function g(z, t) {
        return new ar(z, t)
    }
    function ah(aA, aB) {
        var t = "";
        var z = 0;
        while (z + aB < aA.length) {
            t += aA.substring(z, z + aB) + "\n";
            z += aB
        }
        return t + aA.substring(z, aA.length)
    }
    function r(t) {
        if (t < 16) {
            return "0" + t.toString(16)
        } else {
            return t.toString(16)
        }
    }
    function af(aB, aE) {
        if (aE < aB.length + 11) {
            uv_alert("Message too long for RSA");
            return null
        }
        var aD = new Array();
        var aA = aB.length - 1;
        while (aA >= 0 && aE > 0) {
            var aC = aB.charCodeAt(aA--);
            aD[--aE] = aC
        }
        aD[--aE] = 0;
        var z = new ad();
        var t = new Array();
        while (aE > 2) {
            t[0] = 0;
            while (t[0] == 0) {
                z.nextBytes(t)
            }
            aD[--aE] = t[0]
        }
        aD[--aE] = 2;
        aD[--aE] = 0;
        return new ar(aD)
    }
    function L() {
        this.n = null;
        this.e = 0;
        this.d = null;
        this.p = null;
        this.q = null;
        this.dmp1 = null;
        this.dmq1 = null;
        this.coeff = null
    }
    function o(z, t) {
        if (z != null && t != null && z.length > 0 && t.length > 0) {
            this.n = g(z, 16);
            this.e = parseInt(t, 16)
        } else {
            uv_alert("Invalid RSA public key")
        }
    }
    function W(t) {
        return t.modPowInt(this.e, this.n)
    }
    function p(aA) {
        var t = af(aA, (this.n.bitLength() + 7) >> 3);
        if (t == null) {
            return null
        }
        var aB = this.doPublic(t);
        if (aB == null) {
            return null
        }
        var z = aB.toString(16);
        if ((z.length & 1) == 0) {
            return z
        } else {
            return "0" + z
        }
    }
    L.prototype.doPublic = W;
    L.prototype.setPublic = o;
    L.prototype.encrypt = p;
    var aw;
    var ai = 244837814094590;
    var Z = ((ai & 16777215) == 15715070);
    function ar(z, t, aA) {
        if (z != null) {
            if ("number" == typeof z) {
                this.fromNumber(z, t, aA)
            } else {
                if (t == null && "string" != typeof z) {
                    this.fromString(z, 256)
                } else {
                    this.fromString(z, t)
                }
            }
        }
    }
    function h() {
        return new ar(null)
    }
    function b(aC, t, z, aB, aE, aD) {
        while (--aD >= 0) {
            var aA = t * this[aC++] + z[aB] + aE;
            aE = Math.floor(aA / 67108864);
            z[aB++] = aA & 67108863
        }
        return aE
    }
    function ay(aC, aH, aI, aB, aF, t) {
        var aE = aH & 32767,
        aG = aH >> 15;
        while (--t >= 0) {
            var aA = this[aC] & 32767;
            var aD = this[aC++] >> 15;
            var z = aG * aA + aD * aE;
            aA = aE * aA + ((z & 32767) << 15) + aI[aB] + (aF & 1073741823);
            aF = (aA >>> 30) + (z >>> 15) + aG * aD + (aF >>> 30);
            aI[aB++] = aA & 1073741823
        }
        return aF
    }
    function ax(aC, aH, aI, aB, aF, t) {
        var aE = aH & 16383,
        aG = aH >> 14;
        while (--t >= 0) {
            var aA = this[aC] & 16383;
            var aD = this[aC++] >> 14;
            var z = aG * aA + aD * aE;
            aA = aE * aA + ((z & 16383) << 14) + aI[aB] + aF;
            aF = (aA >> 28) + (z >> 14) + aG * aD;
            aI[aB++] = aA & 268435455
        }
        return aF
    }
    if (Z && (navigator.appName == "Microsoft Internet Explorer")) {
        ar.prototype.am = ay;
        aw = 30
    } else {
        if (Z && (navigator.appName != "Netscape")) {
            ar.prototype.am = b;
            aw = 26
        } else {
            ar.prototype.am = ax;
            aw = 28
        }
    }
    ar.prototype.DB = aw;
    ar.prototype.DM = ((1 << aw) - 1);
    ar.prototype.DV = (1 << aw);
    var aa = 52;
    ar.prototype.FV = Math.pow(2, aa);
    ar.prototype.F1 = aa - aw;
    ar.prototype.F2 = 2 * aw - aa;
    var ae = "0123456789abcdefghijklmnopqrstuvwxyz";
    var ag = new Array();
    var ap, v;
    ap = "0".charCodeAt(0);
    for (v = 0; v <= 9; ++v) {
        ag[ap++] = v
    }
    ap = "a".charCodeAt(0);
    for (v = 10; v < 36; ++v) {
        ag[ap++] = v
    }
    ap = "A".charCodeAt(0);
    for (v = 10; v < 36; ++v) {
        ag[ap++] = v
    }
    function az(t) {
        return ae.charAt(t)
    }
    function A(z, t) {
        var aA = ag[z.charCodeAt(t)];
        return (aA == null) ? -1 : aA
    }
    function Y(z) {
        for (var t = this.t - 1; t >= 0; --t) {
            z[t] = this[t]
        }
        z.t = this.t;
        z.s = this.s
    }
    function n(t) {
        this.t = 1;
        this.s = (t < 0) ? -1 : 0;
        if (t > 0) {
            this[0] = t
        } else {
            if (t < -1) {
                this[0] = t + DV
            } else {
                this.t = 0
            }
        }
    }
    function c(t) {
        var z = h();
        z.fromInt(t);
        return z
    }
    function w(aE, z) {
        var aB;
        if (z == 16) {
            aB = 4
        } else {
            if (z == 8) {
                aB = 3
            } else {
                if (z == 256) {
                    aB = 8
                } else {
                    if (z == 2) {
                        aB = 1
                    } else {
                        if (z == 32) {
                            aB = 5
                        } else {
                            if (z == 4) {
                                aB = 2
                            } else {
                                this.fromRadix(aE, z);
                                return
                            }
                        }
                    }
                }
            }
        }
        this.t = 0;
        this.s = 0;
        var aD = aE.length,
        aA = false,
        aC = 0;
        while (--aD >= 0) {
            var t = (aB == 8) ? aE[aD] & 255 : A(aE, aD);
            if (t < 0) {
                if (aE.charAt(aD) == "-") {
                    aA = true
                }
                continue
            }
            aA = false;
            if (aC == 0) {
                this[this.t++] = t
            } else {
                if (aC + aB > this.DB) {
                    this[this.t - 1] |= (t & ((1 << (this.DB - aC)) - 1)) << aC;
                    this[this.t++] = (t >> (this.DB - aC))
                } else {
                    this[this.t - 1] |= t << aC
                }
            }
            aC += aB;
            if (aC >= this.DB) {
                aC -= this.DB
            }
        }
        if (aB == 8 && (aE[0] & 128) != 0) {
            this.s = -1;
            if (aC > 0) {
                this[this.t - 1] |= ((1 << (this.DB - aC)) - 1) << aC
            }
        }
        this.clamp();
        if (aA) {
            ar.ZERO.subTo(this, this)
        }
    }
    function O() {
        var t = this.s & this.DM;
        while (this.t > 0 && this[this.t - 1] == t) {--this.t
        }
    }
    function q(z) {
        if (this.s < 0) {
            return "-" + this.negate().toString(z)
        }
        var aA;
        if (z == 16) {
            aA = 4
        } else {
            if (z == 8) {
                aA = 3
            } else {
                if (z == 2) {
                    aA = 1
                } else {
                    if (z == 32) {
                        aA = 5
                    } else {
                        if (z == 4) {
                            aA = 2
                        } else {
                            return this.toRadix(z)
                        }
                    }
                }
            }
        }
        var aC = (1 << aA) - 1,
        aF,
        t = false,
        aD = "",
        aB = this.t;
        var aE = this.DB - (aB * this.DB) % aA;
        if (aB-->0) {
            if (aE < this.DB && (aF = this[aB] >> aE) > 0) {
                t = true;
                aD = az(aF)
            }
            while (aB >= 0) {
                if (aE < aA) {
                    aF = (this[aB] & ((1 << aE) - 1)) << (aA - aE);
                    aF |= this[--aB] >> (aE += this.DB - aA)
                } else {
                    aF = (this[aB] >> (aE -= aA)) & aC;
                    if (aE <= 0) {
                        aE += this.DB; --aB
                    }
                }
                if (aF > 0) {
                    t = true
                }
                if (t) {
                    aD += az(aF)
                }
            }
        }
        return t ? aD: "0"
    }
    function R() {
        var t = h();
        ar.ZERO.subTo(this, t);
        return t
    }
    function al() {
        return (this.s < 0) ? this.negate() : this
    }
    function G(t) {
        var aA = this.s - t.s;
        if (aA != 0) {
            return aA
        }
        var z = this.t;
        aA = z - t.t;
        if (aA != 0) {
            return aA
        }
        while (--z >= 0) {
            if ((aA = this[z] - t[z]) != 0) {
                return aA
            }
        }
        return 0
    }
    function j(z) {
        var aB = 1,
        aA;
        if ((aA = z >>> 16) != 0) {
            z = aA;
            aB += 16
        }
        if ((aA = z >> 8) != 0) {
            z = aA;
            aB += 8
        }
        if ((aA = z >> 4) != 0) {
            z = aA;
            aB += 4
        }
        if ((aA = z >> 2) != 0) {
            z = aA;
            aB += 2
        }
        if ((aA = z >> 1) != 0) {
            z = aA;
            aB += 1
        }
        return aB
    }
    function u() {
        if (this.t <= 0) {
            return 0
        }
        return this.DB * (this.t - 1) + j(this[this.t - 1] ^ (this.s & this.DM))
    }
    function aq(aA, z) {
        var t;
        for (t = this.t - 1; t >= 0; --t) {
            z[t + aA] = this[t]
        }
        for (t = aA - 1; t >= 0; --t) {
            z[t] = 0
        }
        z.t = this.t + aA;
        z.s = this.s
    }
    function X(aA, z) {
        for (var t = aA; t < this.t; ++t) {
            z[t - aA] = this[t]
        }
        z.t = Math.max(this.t - aA, 0);
        z.s = this.s
    }
    function s(aF, aB) {
        var z = aF % this.DB;
        var t = this.DB - z;
        var aD = (1 << t) - 1;
        var aC = Math.floor(aF / this.DB),
        aE = (this.s << z) & this.DM,
        aA;
        for (aA = this.t - 1; aA >= 0; --aA) {
            aB[aA + aC + 1] = (this[aA] >> t) | aE;
            aE = (this[aA] & aD) << z
        }
        for (aA = aC - 1; aA >= 0; --aA) {
            aB[aA] = 0
        }
        aB[aC] = aE;
        aB.t = this.t + aC + 1;
        aB.s = this.s;
        aB.clamp()
    }
    function l(aE, aB) {
        aB.s = this.s;
        var aC = Math.floor(aE / this.DB);
        if (aC >= this.t) {
            aB.t = 0;
            return
        }
        var z = aE % this.DB;
        var t = this.DB - z;
        var aD = (1 << z) - 1;
        aB[0] = this[aC] >> z;
        for (var aA = aC + 1; aA < this.t; ++aA) {
            aB[aA - aC - 1] |= (this[aA] & aD) << t;
            aB[aA - aC] = this[aA] >> z
        }
        if (z > 0) {
            aB[this.t - aC - 1] |= (this.s & aD) << t
        }
        aB.t = this.t - aC;
        aB.clamp()
    }
    function ab(z, aB) {
        var aA = 0,
        aC = 0,
        t = Math.min(z.t, this.t);
        while (aA < t) {
            aC += this[aA] - z[aA];
            aB[aA++] = aC & this.DM;
            aC >>= this.DB
        }
        if (z.t < this.t) {
            aC -= z.s;
            while (aA < this.t) {
                aC += this[aA];
                aB[aA++] = aC & this.DM;
                aC >>= this.DB
            }
            aC += this.s
        } else {
            aC += this.s;
            while (aA < z.t) {
                aC -= z[aA];
                aB[aA++] = aC & this.DM;
                aC >>= this.DB
            }
            aC -= z.s
        }
        aB.s = (aC < 0) ? -1 : 0;
        if (aC < -1) {
            aB[aA++] = this.DV + aC
        } else {
            if (aC > 0) {
                aB[aA++] = aC
            }
        }
        aB.t = aA;
        aB.clamp()
    }
    function D(z, aB) {
        var t = this.abs(),
        aC = z.abs();
        var aA = t.t;
        aB.t = aA + aC.t;
        while (--aA >= 0) {
            aB[aA] = 0
        }
        for (aA = 0; aA < aC.t; ++aA) {
            aB[aA + t.t] = t.am(0, aC[aA], aB, aA, 0, t.t)
        }
        aB.s = 0;
        aB.clamp();
        if (this.s != z.s) {
            ar.ZERO.subTo(aB, aB)
        }
    }
    function Q(aA) {
        var t = this.abs();
        var z = aA.t = 2 * t.t;
        while (--z >= 0) {
            aA[z] = 0
        }
        for (z = 0; z < t.t - 1; ++z) {
            var aB = t.am(z, t[z], aA, 2 * z, 0, 1);
            if ((aA[z + t.t] += t.am(z + 1, 2 * t[z], aA, 2 * z + 1, aB, t.t - z - 1)) >= t.DV) {
                aA[z + t.t] -= t.DV;
                aA[z + t.t + 1] = 1
            }
        }
        if (aA.t > 0) {
            aA[aA.t - 1] += t.am(z, t[z], aA, 2 * z, 0, 1)
        }
        aA.s = 0;
        aA.clamp()
    }
    function E(aI, aF, aE) {
        var aO = aI.abs();
        if (aO.t <= 0) {
            return
        }
        var aG = this.abs();
        if (aG.t < aO.t) {
            if (aF != null) {
                aF.fromInt(0)
            }
            if (aE != null) {
                this.copyTo(aE)
            }
            return
        }
        if (aE == null) {
            aE = h()
        }
        var aC = h(),
        z = this.s,
        aH = aI.s;
        var aN = this.DB - j(aO[aO.t - 1]);
        if (aN > 0) {
            aO.lShiftTo(aN, aC);
            aG.lShiftTo(aN, aE)
        } else {
            aO.copyTo(aC);
            aG.copyTo(aE)
        }
        var aK = aC.t;
        var aA = aC[aK - 1];
        if (aA == 0) {
            return
        }
        var aJ = aA * (1 << this.F1) + ((aK > 1) ? aC[aK - 2] >> this.F2: 0);
        var aR = this.FV / aJ,
        aQ = (1 << this.F1) / aJ,
        aP = 1 << this.F2;
        var aM = aE.t,
        aL = aM - aK,
        aD = (aF == null) ? h() : aF;
        aC.dlShiftTo(aL, aD);
        if (aE.compareTo(aD) >= 0) {
            aE[aE.t++] = 1;
            aE.subTo(aD, aE)
        }
        ar.ONE.dlShiftTo(aK, aD);
        aD.subTo(aC, aC);
        while (aC.t < aK) {
            aC[aC.t++] = 0
        }
        while (--aL >= 0) {
            var aB = (aE[--aM] == aA) ? this.DM: Math.floor(aE[aM] * aR + (aE[aM - 1] + aP) * aQ);
            if ((aE[aM] += aC.am(0, aB, aE, aL, 0, aK)) < aB) {
                aC.dlShiftTo(aL, aD);
                aE.subTo(aD, aE);
                while (aE[aM] < --aB) {
                    aE.subTo(aD, aE)
                }
            }
        }
        if (aF != null) {
            aE.drShiftTo(aK, aF);
            if (z != aH) {
                ar.ZERO.subTo(aF, aF)
            }
        }
        aE.t = aK;
        aE.clamp();
        if (aN > 0) {
            aE.rShiftTo(aN, aE)
        }
        if (z < 0) {
            ar.ZERO.subTo(aE, aE)
        }
    }
    function N(t) {
        var z = h();
        this.abs().divRemTo(t, null, z);
        if (this.s < 0 && z.compareTo(ar.ZERO) > 0) {
            t.subTo(z, z)
        }
        return z
    }
    function K(t) {
        this.m = t
    }
    function V(t) {
        if (t.s < 0 || t.compareTo(this.m) >= 0) {
            return t.mod(this.m)
        } else {
            return t
        }
    }
    function ak(t) {
        return t
    }
    function J(t) {
        t.divRemTo(this.m, null, t)
    }
    function H(t, aA, z) {
        t.multiplyTo(aA, z);
        this.reduce(z)
    }
    function au(t, z) {
        t.squareTo(z);
        this.reduce(z)
    }
    K.prototype.convert = V;
    K.prototype.revert = ak;
    K.prototype.reduce = J;
    K.prototype.mulTo = H;
    K.prototype.sqrTo = au;
    function B() {
        if (this.t < 1) {
            return 0
        }
        var t = this[0];
        if ((t & 1) == 0) {
            return 0
        }
        var z = t & 3;
        z = (z * (2 - (t & 15) * z)) & 15;
        z = (z * (2 - (t & 255) * z)) & 255;
        z = (z * (2 - (((t & 65535) * z) & 65535))) & 65535;
        z = (z * (2 - t * z % this.DV)) % this.DV;
        return (z > 0) ? this.DV - z: -z
    }
    function f(t) {
        this.m = t;
        this.mp = t.invDigit();
        this.mpl = this.mp & 32767;
        this.mph = this.mp >> 15;
        this.um = (1 << (t.DB - 15)) - 1;
        this.mt2 = 2 * t.t
    }
    function aj(t) {
        var z = h();
        t.abs().dlShiftTo(this.m.t, z);
        z.divRemTo(this.m, null, z);
        if (t.s < 0 && z.compareTo(ar.ZERO) > 0) {
            this.m.subTo(z, z)
        }
        return z
    }
    function at(t) {
        var z = h();
        t.copyTo(z);
        this.reduce(z);
        return z
    }
    function P(t) {
        while (t.t <= this.mt2) {
            t[t.t++] = 0
        }
        for (var aA = 0; aA < this.m.t; ++aA) {
            var z = t[aA] & 32767;
            var aB = (z * this.mpl + (((z * this.mph + (t[aA] >> 15) * this.mpl) & this.um) << 15)) & t.DM;
            z = aA + this.m.t;
            t[z] += this.m.am(0, aB, t, aA, 0, this.m.t);
            while (t[z] >= t.DV) {
                t[z] -= t.DV;
                t[++z]++
            }
        }
        t.clamp();
        t.drShiftTo(this.m.t, t);
        if (t.compareTo(this.m) >= 0) {
            t.subTo(this.m, t)
        }
    }
    function am(t, z) {
        t.squareTo(z);
        this.reduce(z)
    }
    function y(t, aA, z) {
        t.multiplyTo(aA, z);
        this.reduce(z)
    }
    f.prototype.convert = aj;
    f.prototype.revert = at;
    f.prototype.reduce = P;
    f.prototype.mulTo = y;
    f.prototype.sqrTo = am;
    function i() {
        return ((this.t > 0) ? (this[0] & 1) : this.s) == 0
    }
    function x(aF, aG) {
        if (aF > 4294967295 || aF < 1) {
            return ar.ONE
        }
        var aE = h(),
        aA = h(),
        aD = aG.convert(this),
        aC = j(aF) - 1;
        aD.copyTo(aE);
        while (--aC >= 0) {
            aG.sqrTo(aE, aA);
            if ((aF & (1 << aC)) > 0) {
                aG.mulTo(aA, aD, aE)
            } else {
                var aB = aE;
                aE = aA;
                aA = aB
            }
        }
        return aG.revert(aE)
    }
    function an(aA, t) {
        var aB;
        if (aA < 256 || t.isEven()) {
            aB = new K(t)
        } else {
            aB = new f(t)
        }
        return this.exp(aA, aB)
    }
    ar.prototype.copyTo = Y;
    ar.prototype.fromInt = n;
    ar.prototype.fromString = w;
    ar.prototype.clamp = O;
    ar.prototype.dlShiftTo = aq;
    ar.prototype.drShiftTo = X;
    ar.prototype.lShiftTo = s;
    ar.prototype.rShiftTo = l;
    ar.prototype.subTo = ab;
    ar.prototype.multiplyTo = D;
    ar.prototype.squareTo = Q;
    ar.prototype.divRemTo = E;
    ar.prototype.invDigit = B;
    ar.prototype.isEven = i;
    ar.prototype.exp = x;
    ar.prototype.toString = q;
    ar.prototype.negate = R;
    ar.prototype.abs = al;
    ar.prototype.compareTo = G;
    ar.prototype.bitLength = u;
    ar.prototype.mod = N;
    ar.prototype.modPowInt = an;
    ar.ZERO = c(0);
    ar.ONE = c(1);
    var m;
    var U;
    var ac;
    function d(t) {
        U[ac++] ^= t & 255;
        U[ac++] ^= (t >> 8) & 255;
        U[ac++] ^= (t >> 16) & 255;
        U[ac++] ^= (t >> 24) & 255;
        if (ac >= M) {
            ac -= M
        }
    }
    function T() {
        d(new Date().getTime())
    }
    if (U == null) {
        U = new Array();
        ac = 0;
        var I;
        if (navigator.appName == "Netscape" && navigator.appVersion < "5" && window.crypto && window.crypto.random) {
            var F = window.crypto.random(32);
            for (I = 0; I < F.length; ++I) {
                U[ac++] = F.charCodeAt(I) & 255
            }
        }
        while (ac < M) {
            I = Math.floor(65536 * Math.random());
            U[ac++] = I >>> 8;
            U[ac++] = I & 255
        }
        ac = 0;
        T()
    }
    function C() {
        if (m == null) {
            T();
            m = ao();
            m.init(U);
            for (ac = 0; ac < U.length; ++ac) {
                U[ac] = 0
            }
            ac = 0
        }
        return m.next()
    }
    function av(z) {
        var t;
        for (t = 0; t < z.length; ++t) {
            z[t] = C()
        }
    }
    function ad() {}
    ad.prototype.nextBytes = av;
    function k() {
        this.i = 0;
        this.j = 0;
        this.S = new Array()
    }
    function e(aC) {
        var aB, z, aA;
        for (aB = 0; aB < 256; ++aB) {
            this.S[aB] = aB
        }
        z = 0;
        for (aB = 0; aB < 256; ++aB) {
            z = (z + this.S[aB] + aC[aB % aC.length]) & 255;
            aA = this.S[aB];
            this.S[aB] = this.S[z];
            this.S[z] = aA
        }
        this.i = 0;
        this.j = 0
    }
    function a() {
        var z;
        this.i = (this.i + 1) & 255;
        this.j = (this.j + this.S[this.i]) & 255;
        z = this.S[this.i];
        this.S[this.i] = this.S[this.j];
        this.S[this.j] = z;
        return this.S[(z + this.S[this.i]) & 255]
    }
    k.prototype.init = e;
    k.prototype.next = a;
    function ao() {
        return new k()
    }
    var M = 256;
    function S(aB, aA, z) {
        aA = "e9a815ab9d6e86abbf33a4ac64e9196d5be44a09bd0ed6ae052914e1a865ac8331fed863de8ea697e9a7f63329e5e23cda09c72570f46775b7e39ea9670086f847d3c9c51963b131409b1e04265d9747419c635404ca651bbcbc87f99b8008f7f5824653e3658be4ba73e4480156b390bb73bc1f8b33578e7a4e12440e9396f2552c1aff1c92e797ebacdc37c109ab7bce2367a19c56a033ee04534723cc2558cb27368f5b9d32c04d12dbd86bbd68b1d99b7c349a8453ea75d1b2e94491ab30acf6c46a36a75b721b312bedf4e7aad21e54e9bcbcf8144c79b6e3c05eb4a1547750d224c0085d80e6da3907c3d945051c13c7c1dcefd6520ee8379c4f5231ed";
        z = "10001";
        var t = new L();
        t.setPublic(aA, z);
        return t.encrypt(aB)
    }
    return {
        rsa_encrypt: S
    }
};
