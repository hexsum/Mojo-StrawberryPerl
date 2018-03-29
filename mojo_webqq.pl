#!/usr/bin/env perl
use Mojo::Webqq;
use Digest::MD5;
my ($account,$pwd,$host,$port,$post_api);

#$account = 123456      ;#如需登陆指定的QQ号码，请取消本行注释
#$pwd = 'xxxxx';       ;#如需登陆指定的QQ号码，请取消本行注释

$log = 1          ;#是否显示消息，1为显示，0为不显示

##### 以下无需修改 #####
$host = "0.0.0.0"; #发送消息接口监听地址
$port = 5000;        #发送消息接口监听端口
#$post_api = 'http://127.0.0.1/txpush.php';  #接收消息上报接口，如不需要可删除此行

$tmpdir_dir = './tmp/';
$qrcode_path = $tmpdir_dir.'webqq.png';

if($log == '1'){
$log_path ="";
}else{
$log_path = "/dev/null";
}

my $client = Mojo::Webqq->new(
account=>$account,
pwd => $pwd?Digest::MD5::md5_hex($pwd):undef,
login_type => $account?"login":"qrlogin",
state=>"hidden",
tmpdir=>$tmpdir_dir,
cookie_dir=>$tmpdir_dir,
qrcode_path=>$qrcode_path,
log_path=>$log_path,
log_level=>"info",
http_debug=>0,
is_init_friend=>1,
is_init_group=>1,
is_init_discuss=>1,
is_init_recent=>0,
is_update_user=>0,
is_update_group=>0,
is_update_friend=>0,
is_update_discuss=>0
);

$client->on(before_send_message=>sub{
    my($client,$msg) = @_;
    $client->stop() if $msg->content eq "!stop!";
    return;
});

$client->load("ShowMsg");
$client->load("ShowQRcode");
$client->load("Openqq",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
$client->run();