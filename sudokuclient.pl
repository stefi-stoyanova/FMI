use IO::Socket::INET;
 
# auto-flush on socket
$| = 1;
 
 
# notify server that request has been sent 
# receive a response of up to 1024 characters from server
while(1)
{
my $socket = new IO::Socket::INET (
    PeerHost => 'localhost',
    PeerPort => '7777',
    Proto => 'tcp',
);
# create a connecting socket
die "cannot connect to the server $!\n" unless $socket;
print "Wait for your turn\n";
	#my $size = $socket->send("hello");
	#print "sent data of length 5\n";
	#shutdown($socket, 1);

	my $response = "";
	$socket->recv($response, 1024);
	print "$response\n";

	my $line = <STDIN>;
	my $size = $socket->send($line);
	shutdown($socket, 1);
	
	$response = "";
	$socket->recv($response, 1024);
	print "$response\n";
$socket->close();
}
 
