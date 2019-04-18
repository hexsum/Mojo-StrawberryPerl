sub Mojo::Webqq::Client::_get_vfwebqq {
    my $self = shift;
    $self->info("获取数据验证参数...\n");
    my $api_url = 'https://s.web2.qq.com/api/getvfwebqq';
    my @query_string = (
        ptwebqq    =>  $self->ptwebqq,
        clientid   =>  $self->clientid,
        psessionid =>  $self->psessionid,
        t          =>  time(),
    );  
    my $headers = {
        Referer => 'https://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',
        json    => 1,
        ua_request_timeout => 10,
        ua_retry_times => 3,
    };
    
    my $json = $self->http_get($self->gen_url($api_url,@query_string),$headers);
    return undef unless defined $json;
    if($json->{retcode}!=0){
        $self->error("获取数据验证参数失败...");
        return 0;
    }
    $self->vfwebqq($json->{result}{vfwebqq});
    return 1;
}
1;
