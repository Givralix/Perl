# PerlBot
This is a tumblr bot mainly written in Perl (and some Python)! So far it's not complete at all but I'm working on it.<br/>
It's based on Pearl from Steven Universe :D<br/>
The blog is at [http://perlbot.tumblr.com/](http://perlbot.tumblr.com/)

## Files
### perlbot.pl
This is basically most of the code for the bot.<br/>
Since there's no official Tumblr API for Perl, I got the code for posting text posts from [this person](https://txlab.wordpress.com/2011/09/03/using-tumblr-api-v2-from-perl/#comment-7004) (which thankfully works).<br/>
(the official Tumblr API documentation is also very useful!)</br>
For obvious reasons I removed the OAuth parameters from the code (they're in a text file named "tokens", using a ";" as separation and there's no end of line character at the end).<br/>
Now actually works \o/

### shitpost_database
This is all the dialogue that Pearl ever says for the Markov Chain to generate sentences from.<br/>
So far it has the dialogue from all the episodes from Gem Glow to Steven Floats.<br/>
I get it from the Steven Universe wikia and also each sentence is on its own line!

## Dependencies
### Python
*	Markovify

### Perl
*	Net::OAuth
*	HTTP::Request
*	LWP::UserAgent
*	JSON::XS
*	Inline::Python
