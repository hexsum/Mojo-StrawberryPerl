基于StrawberryPerl打包而成的包含Perl-5.24+cpanm+Mojo-Webqq+Mojo-Weixin的完整Windows运行环境

非常感谢网友 @那谁 的制作，在官方原本的基础上进行精简

如果github下载ZIP压缩包速度较慢，可以尝试从如下腾讯云存储地址下载RAR压缩包

http://share-10066126.cos.myqcloud.com/Mojo-StrawberryPerl-20170606.rar

【运行】
1、运行批处理 start_mojo_webqq.bat 或者 start_mojo_weixin.bat 来启动程序
2、扫码登陆，二维码图片会自动展示
3、如存在有效Cookie则无需扫码

【发消息API】
QQ发好友：http://127.0.0.1:5000/openqq/send_friend_message?uid=好友QQ号码&content=消息内容
QQ发群：http://127.0.0.1:5000/openqq/send_group_message?uid=群号码&content=消息内容
微信发好友：http://127.0.0.1:3000/openwx/send_friend_message?displayname=好友显示名称&content=消息内容
微信发群：http://127.0.0.1:3000/openwx/send_group_message?displayname=群名称&content=消息内容

其他API详见：
QQ：https://github.com/sjdy521/Mojo-Webqq/blob/master/API.md
微信：https://github.com/sjdy521/Mojo-Weixin/blob/master/API.md

【调用API】
1、把上述API中的127.0.0.1替换为电脑内网地址192.168.x.x，可通过局域网进行调用
2、如在服务器上运行，且服务器有独立公网IP，可把127.0.0.1替换为公网IP来调用

【退出】
1、直接关闭窗口
2、用API发送关键词 !stop!（注意叹号为英文，本消息不会真正发出）
