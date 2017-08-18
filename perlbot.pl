#!/usr/bin/perl
use utf8;
binmode STDOUT, ':utf8';
use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
use HTTP::Request::Common;
use LWP::UserAgent;
use Data::Dumper;
use HTML::Entities;
use String::Markov;
use WWW::Tumblr;
use Lingua::EN::Tagger;
use XML::LibXML;
srand;
use File::Random qw/random_line/;

use Encode qw/decode encode/;

use strict;
use warnings;

## MY FUNCTIONS
# answering all asks in the inbox except already answered ones
sub answer_asks
{
	my $blog = shift;
	my $parser = new Lingua::EN::Tagger;
	my @no_space = (",", ".", ";", "?", "!", "...", "'",);

	open my $f, "<", "answered_asks_ids"
		or die "Could not open file 'answered_asks_ids' $!";
	my @previous_ids = <$f>;
	foreach my $id (@previous_ids) {
		chomp($id);
	}
	close $f;
	
	my @submissions = @{$blog->posts_submission->{posts}};
	print Dumper @submissions;
	foreach my $ask (@submissions) {
		answer_ask($ask, $blog, $parser, \@no_space);
	}
}

# answering each ask
sub answer_ask
{
	my $ask = shift;
	my $blog = shift;
	my $parser = shift;
	my @no_space = @{ $_[0] };

	print "\nAsk #$ask->{id} sent by $ask->{asking_name} at $ask->{date}:\n$ask->{question}\n";

	my $answer = generate_answer($parser, $ask->{question}, \@no_space);
	# make the answer html safe
	encode_entities($answer);

	# edit the ask to add the answer and turn it into a published post
	my $post = $blog->post_edit(
		type => "answer",
		answer => $answer,
		id => $ask->{id},
		tags => "answer,$ask->{asking_name}",
		state =>"published",
	);

	my $date = localtime();
	if ($post) {
		print "[$date] Answered the ask:\n $answer\n";
	} else {
		print STDERR Dumper $blog->error . "\n";
		die "[$date] Couldn't answer the ask with:\n $answer";
	}

	# add the content of the ask to blog_dialogue.txt
	open( my $f, '>>', "blog_dialogue.txt") or die "Could not open file 'blog_dialogue.txt' $!";
	say $f $ask->{question};
	close $f;
}

# generate sentences
sub generate_sentence
{
	my $markov = $_[0];
	my %sentences = %{$_[1]};
	my $sentence = $markov->generate_sample();
	while ( exists($sentences{$sentence}) ) {
		#print $sentence . "\n";
		$sentence = $markov->generate_sample();
	}
	return $sentence;
}

# generate answers
sub generate_answer
{
	my $p = $_[0]; # Lingua::EN::Tagger object
	my $question = encode("utf8", $_[1]); # making the question safe for LibXML

	# hash containing punctuation that doesn't require a space before it
	my @no_space = @{$_[2]};

	my @sentences = ($question,);
	push(@sentences, random_line("show_dialogue.txt", 3));
	push(@sentences, random_line("blog_dialogue.txt", 1));

	# deleting all < and > to avoid conflicts with the XML format
	foreach (@sentences) {
		$_ =~ s/[<>]//g;
	}

	# get text + base sentence tags
	my $text = XML::LibXML->load_xml( string => "<base>" . $p->add_tags(join('', @sentences, $question)) . "</base>");
	my $base_sentence = XML::LibXML->load_xml( string => "<base>" . $p->add_tags($sentences[2]) . "</base>" );

	# making the sentence
	my $answer = '';

	foreach my $tag ($base_sentence->findnodes('/base/*')) {
		my $nodeName = $tag->nodeName . "\n";
		my $word = "";

		if (my $node = $text->findnodes("/base/$nodeName")->[0]) {
			$word = $node->to_literal();
			# delete the node
			$node->unbindNode();
			# join the answer and the new word
			if ($answer eq '') {
				$answer = $word;
			} elsif ($word ~~ @no_space) {
				$answer = $answer . $word;
			} elsif (!$word eq '') {
				$answer = $answer . " $word";
			}
		} else {
			warn "Skipping word\n";
		}
	}

	return $answer;
}

# queue a post generated by generate_sentence()
sub queue_post
{
	my $blog = $_[0];
	my $body = $_[1];
	encode_entities($body);
	my $date = localtime();
	if ( my $post = $blog->post( type => 'text', body => $body, tags => "random thought,PerlBot", state => "queue", ) ) {
		print "[$date] Following tumblr entry queued: $body\n";
	} else {
		print STDERR Dumper $blog->error . "\n";
		die "[$date] Couldn't queue following tumblr entry: $body";
	}
}

1;
