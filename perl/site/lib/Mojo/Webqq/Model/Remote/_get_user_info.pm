use strict;
sub Mojo::Webqq::Model::_get_user_info{
    my $self = shift;
    my $callback = shift;
    my $api_url ='https://s.web2.qq.com/api/get_self_info2';
    my $headers = {
        Referer     =>  'https://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1',
        json        =>  1,
        ua_request_timeout => $self->model_update_timeout,
        ua_retry_times => 3,
    };
    my @query_string = (
        t               =>  time,
    ); 
    my $is_blocking = ref $callback eq "CODE"?0:1;
    my $handle = sub{
        my $json = shift;
        return undef unless defined $json;
        return undef if $json->{retcode} !=0;
        my $user = $json->{result};
        $user->{state} = $self->mode;
        $user->{name} = delete $user->{nick};
        $user->{client_type} = 'web';
        $user->{birthday} = join( "-", @{ $user->{birthday} }{qw(year month day)} );
        $user->{signature} = delete $user->{lnick};
        $user->{sex} = delete $user->{gender};
        #my $single_long_nick = $self->get_single_long_nick( $self->uid );
        #$json->{result}{signature} = $single_long_nick if defined $single_long_nick;
        $user->{uid}       = $self->uid;
        $user->{id}        = delete $user->{uin};
        return $user;
    };
    if($is_blocking){
        return $handle->(  $self->http_get($self->gen_url($api_url,@query_string),$headers,) );
    }
    else{
        $self->http_get($self->gen_url($api_url,@query_string),$headers,sub{
            my $json = shift;
            $callback->( $handle->($json) );
        });
    }
}
1;
