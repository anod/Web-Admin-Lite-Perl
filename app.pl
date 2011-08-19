#!/usr/bin/env perl
use Mojolicious::Lite;

get '/' => 'sysinfo';

get '/terminal' => 'terminal';

get '/terminal/execute' => sub {
    my $self = shift;
    my $cmd = $self->param('cmd');
    $self->render(text => `$cmd` );
};

get '/users' => sub {
    my $self = shift;
	
} => 'users';

get '/tasks' => sub {
    my $self = shift;
	
	$self->stash(
		tasks => [
			map { [ split /\s+/ ] }
			split /\n/, qx(ps axh -o comm,stat,\%cpu,nice,pid,rss,user)
		]
	);

} => 'tasks';

get '/tasks/kill' => sub {
    my $self = shift;
	my $pid = $self->param('pid');
    $self->redirect_to('tasks', killed => qx(kill $pid 2>&1));
};

get '/backup' => sub {
    my $self = shift;

} => 'backup';



app->start;

