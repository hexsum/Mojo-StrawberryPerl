#!/usr/bin/env perl
use Mojo::Webqq;
my ($qq,$host,$port,$post_api);

#$qq = 12345      ;#如需登陆指定的QQ号码，请取消本行注释
$log = 1          ;#是否显示消息，1为显示，0为不显示

##### 以下无需修改 #####
$host = "0.0.0.0"; #发送消息接口监听地址
$port = 666;        #发送消息接口监听端口
#$post_api = 'http://127.0.0.1/txpush.php';  #接收消息上报接口，如不需要可删除此行

$tmpdir_dir = './';
$qrcode_path = $tmpdir_dir.'webqq.png';

if($log == '1'){
$log_path ="";
}else{
$log_path = "/dev/null";
}

my $client = Mojo::Webqq->new(
qq=>$qq,
state=>"hidden",
tmpdir=>$tmpdir_dir,
cookie_dir=>$tmpdir_dir,
qrcode_path=>$qrcode_path,
log_path=>$log_path,
is_init_friend=>1,
is_init_group=>1,
is_init_discuss=>1,
is_init_recent=>0,
is_update_user=>1,
is_update_group=>1,
is_update_friend=>1,
is_update_discuss=>1
);

print "Logining...\nIf No Succeed Info in 5s Please Scan QRCode\n";
$client->on(login=>sub{
    print "\nLogin Succeed\n";
});
$client->on(ready=>sub{
    print "WebQQ OK\n";
    unlink($qrcode_path);
});

$client->on(before_send_message=>sub{
    my($client,$msg) = @_;
    $client->stop() if $msg->content eq "!stop!";
    return;
});

$client->load("ShowMsg");
$client->load("ShowQRcode");
$client->load("Openqq",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
$client->run();