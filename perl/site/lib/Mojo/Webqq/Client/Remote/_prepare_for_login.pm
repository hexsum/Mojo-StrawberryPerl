sub Mojo::Webqq::Client::_prepare_for_login {
    my $self = shift;
    $self->info( "初始化 " . $self->type . " 客户端...\n" );
    $self->http_get("http://" . $self->domain . "/",{ua_debug_res_body=>0});
    my $api_url = 'https://xui.ptlogin2.qq.com/cgi-bin/xlogin?daid=164&target=self&style=40&pt_disable_pwd=1&mibao_css=m_webqq&appid=501004106&enable_qlogin=0&no_verifyimg=1&s_url=http%3A%2F%2F' . $self->domain . '%2Fproxy.html&f_url=loginerroralert&strong_login=1&login_state=10&t=20131024001';
    my $headers ={ Referer => 'http://'. $self->domain . '/',ua_debug_res_body=>0 };
    my $content = $self->http_get( $api_url, $headers);
    return 0 unless defined $content;
    $self->pt_login_sig($self->search_cookie("pt_login_sig")) if not $self->pt_login_sig;
    return 1;
}
1;
