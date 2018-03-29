#!/usr/bin/env perl
use Mojo::Weixin;
my ($host,$port,$post_api);

$log = 1          ;#是否显示消息，1为显示，0为不显示

##### 以下无需修改 #####
$host = "0.0.0.0"; #发送消息接口监听地址
$port = 3000;        #发送消息接口监听端口
#$post_api = 'http://127.0.0.1/txpush.php';  #接收消息上报接口，如不需要可删除此行

$tmpdir_dir = './tmp/';
$qrcode_path = $tmpdir_dir.'weixin.png';

if($log == '1'){
$log_path ="";
}else{
$log_path = "/dev/null";
}

my $client = Mojo::Weixin->new(
tmpdir=>$tmpdir_dir,
cookie_dir=>$tmpdir_dir,
qrcode_path=>$qrcode_path,
log_path=>$log_path
);

print "Logining...\nIf No Succeed Info in 5s Please Scan QRCode\n";
$client->on(login=>sub{
    print "\nLogin Succeed\n";
});
$client->on(ready=>sub{
    print "WebWeiXin OK\n";
    unlink($qrcode_path);
});

$client->on(before_send_message=>sub{
    my($client,$msg) = @_;
    $client->stop() if $msg->content eq "!stop!";
    return;
});

$client->load("ShowMsg");
$client->load("ShowQRcode");
$client->load("Openwx",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
$client->run();