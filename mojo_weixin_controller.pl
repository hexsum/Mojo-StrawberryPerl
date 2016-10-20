#!/usr/bin/env perl
use Mojo::Weixin::Controller;
my ($host,$port,$post_api);

$host = "0.0.0.0"; #Controller API server 监听地址
$port = 2000;      #Controller API server 监听端口，修改为自己希望监听的端口
#$post_api = 'http://xxxx';  #每个微信帐号接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

my $controller = Mojo::Weixin::Controller->new(
    listen              =>[{host=>$host,port=>$port} ], #监听的地址端口
    backend_start_port  => 3000, #可选，后端微信帐号分配的端口最小值
    post_api            => $post_api, #每个微信帐号上报的api地址
#   tmpdir              => '/tmp', #可选，临时目录位置
#   pid_path            => '/tmp/mojo_weixin_controller_process.pid', #可选，Controller进程的pid信息，默认tmpdir目录
#   backend_path        => '/tmp/mojo_weixin_controller_backend.dat', #可选，后端微信帐号信息，默认tmpdir目录
#   check_interval      => 5, #可选，检查后端微信帐号状态的时间间隔
#   log_level           => 'debug',#可选,debug|info|warn|error|fatal
#   log_path            => '/tmp/mojo_weixin_controller.log', #可选，运行日志路径，默认输出到终端
#   log_encoding        => 'utf8', #可选，打印到终端的编码，默认自动识别
);
$controller->run();