#!/usr/bin/perl 
use strict;


use Data::Dumper;
use POSIX;
use List::Util qw(shuffle);
use Storable qw(dclone);
use IO::Socket::INET;

my $n = 9;
my @symbols = (1..9);


 
# auto-flush on socket
$| = 1;
 
# creating a listening socket
my $server = new IO::Socket::INET (
    LocalHost => 'localhost',
    LocalPort => '7777',
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
);
die "cannot create socket $!\n" unless $server;
print "server waiting for client connection on port 7777\n";
 
 
 
 
sub createObjectWithExistingNumbers() {

	my $existingNumbers = {
	    rows => {},
	    cols => {},
	    squares =>{},
	};

	for my $key ( keys %$existingNumbers )
	{
	    for my $i (1..$n)
	    {
	    	my @arr = ();
	    	my $idx = $i - 1;
	    	if($key eq "squares") 
	    	{
	    		$idx++;
	    	}
	        $$existingNumbers{$key}{$idx} = {};
	    }
	}
	return $existingNumbers;
}


sub generateFilledBoard() 
{
	my $existingNumbers = createObjectWithExistingNumbers();

	my @square;

	for my $i (0..($n-1))
	{
	    my @row = (0) x $n;
	    push(@square, \@row);
	}

	for my $rowIdx (0..($n-1))
	{
	    my @numbers = shuffle (1..9);
	    COL: for my $colIdx (0..($n-1))
	    {
	        my $firstNotAllowedNumber = 0;
	        REPEAT: while(1)
	        {
	            my $val = shift @numbers;
	            if($firstNotAllowedNumber == $val)
	            {
	            	for my $colBack (0..$colIdx)
	            	{
	        			removeNumber($existingNumbers, $rowIdx, $colBack, $square[$rowIdx][$colBack]);
	        			$square[$rowIdx][$colBack]=0;
	            	}

	            	@numbers = shuffle (1..9);
	            	$colIdx = -1;
	            	next COL;

	            }
	            if(isAllow($existingNumbers, $rowIdx, $colIdx, $val))
	            {
	                $square[$rowIdx][$colIdx] = $val;
	                addNumber($existingNumbers, $rowIdx, $colIdx, $val);
	                last REPEAT;
	            }
	            else 
	            {
	                $firstNotAllowedNumber = $val if ! $firstNotAllowedNumber;
	                push @numbers, $val;
	            }
	        }
	    }   
	}

	return ($existingNumbers, \@square);
}

sub removeNumber($$$$)
{
    my($existingNumbers, $rowIdx, $colIdx, $value) = @_;

    delete $$existingNumbers{rows}{$rowIdx}{$value};
    delete $$existingNumbers{cols}{$colIdx}{$value};
    delete $$existingNumbers{squares}{determineSquare($rowIdx, $colIdx)}{$value};
}

sub addNumber($$$$)
{
    my($existingNumbers, $rowIdx, $colIdx, $value) = @_;

    $$existingNumbers{rows}{$rowIdx}{$value}++;
    $$existingNumbers{cols}{$colIdx}{$value}++;
    $$existingNumbers{squares}{determineSquare($rowIdx, $colIdx)}{$value}++;
}

sub isAllow($$$$)
{
    my($hashref, $rowIdx, $colIdx, $value) = @_;
    my $squareIdx = determineSquare($rowIdx, $colIdx);

    return (! $$hashref{rows}{$rowIdx}{$value})
        && (! $$hashref{cols}{$colIdx}{$value})
        && (! $$hashref{squares}{$squareIdx}{$value});
}

sub determineSquare($$)
{
    my ($rowIdx, $colIdx) = @_;
    
    return (int($rowIdx / 3)) * 3 + (int($colIdx / 3) + 1);
}

sub printBoard(@)
{
	my (@sudoku) = @_;

	for my $i (0..($n-1))
	{	
		if($i % 3 == 0)
		{
			print "-------------------------\n";
		}
		for my $k (0..($n-1))
		{
			if($k % 3 == 0)
			{
				print "| ";
			}
			print $sudoku[$i][$k] . " " ;
		}
		print "|\n";
	}
	print "-------------------------\n";
}

sub getBoardString(@)
{
	my (@sudoku) = @_;

	my $string = "";
	for my $i (0..($n-1))
	{	
		if($i % 3 == 0)
		{
			$string .= "-------------------------\n";
		}
		for my $k (0..($n-1))
		{
			if($k % 3 == 0)
			{
				$string .= "| ";
			}
			$string .= $sudoku[$i][$k] . " " ;
		}
		$string .= "|\n";
	}
	$string .= "-------------------------\n";
	return $string;
}

sub createStartBoard($) {
	my($filledSquare) = @_;
	my @filledSquare = @$filledSquare;

	my @square;
	for (0..($n - 1))
	{
	    my @row = (0) x $n;
	    push(@square, \@row);
	}

	my $existingNumbers = createObjectWithExistingNumbers();

	my $range = 15;
  	my $minimum = 35;

  	my $filledNumbers = $n * $n - (int(rand($range)) + $minimum);
	
  	while($filledNumbers--)
  	{
  		my $rowIdx = int(rand(9));
  		my $colIdx = int(rand(9));
  		
  		if(!$square[$rowIdx][$colIdx])
  		{
  			addNumber($existingNumbers, $rowIdx, $colIdx, $filledSquare[$rowIdx][$colIdx]);
  			$square[$rowIdx][$colIdx] = $filledSquare[$rowIdx][$colIdx];
  		}
  		else
  		{
  			$filledNumbers++;
  		}
  		
  	}
  	return ($existingNumbers, \@square);
}


sub play($$)
{
	my ($existingNumbers, $square) = @_;
	my @square = @{$square};

	
	while(1)
	{
		my $client = $server->accept();
		# get information about a newly connected client
		#my $client_address = $client_socket->peerhost();
		#my $client_port = $client_socket->peerport();
		#print "connection from $client_address:$client_port\n";
		#sleep 10;
		# read up to 1024 characters from the connected client
		#my $data = "";
		#$client_socket->recv($data, 1024);
		#print "received data: $data\n";
	
		my $zeroes = 0;
		for my $line(@square) 
		{
			$zeroes += scalar(grep {$_ == 0} @$line);
		}
		
		if($zeroes == 0)
		{
			print "Congratulations!!!\n";
			last;
		}
	 
		
		
		#printBoard(@square);
		my $string  = getBoardString(@square);
		my $line;
		printBoard(@square);
		print $client "$string\nEnter row, column, number:\n";
	
		$line = <$client>;
	
		#my$line = <STDIN>;
		chomp( $line );
	
		my ($row, $col, $num) = split(" ", $line);
		
		if(($row !~ /^[1-9]$/) || ($col !~ /^[1-9]$/) || ($num !~ /^[0-9]$/)) 
		{
			print $client "Invalid parameters\n";
			next;
		}

		if(isAllow($existingNumbers, $row - 1, $col - 1, $num)) 
		{
			addNumber($existingNumbers, $row - 1, $col - 1, $num);
			$square[$row - 1][$col - 1] = $num;
			print $client "ok";
		}
		else
		{
			#print Dumper $existingNumbers;
			print $client "Not allowed!\n";
			next; 
		}
		# write response data to the connected client
		
		#close $client;
		#$data = "ok";
		#$client_socket->send($data);
	 
		# notify client that response has been sent
		shutdown($client, 1);
		
	}
}




sub main
{
	my (undef, $square) = generateFilledBoard();
	
	my ($startExistingNumbers, $startSquare) = createStartBoard($square);
	play($startExistingNumbers, $startSquare);

	
	

}

main();
