# README

### Cards
Credit for card PNGs goes to Hanhaechi at https://github.com/hanhaechi/playing-cards.git

### Setup the repository
If you need assistance getting Rails working on Windows 10, and then installing Postgres, I've added a guide [here](SetupProcess.md) that recorded everything I did to get the initial server running.

### Startup Instructions
Assuming you already have Ruby and Rails installed on your machine:

Start the local git repo where-ever you wish to host this with `git init`

Clone the repo with `git clone https://github.com/jfarnsworth95/praeses_blackjack.git`

Install the needed bundles:
`bundle install`

Simply use:
`rails server`
to start up your rails instance. This should be accessible on http://127.0.0.1:3000/

### Implemented Features

Beyond simple counting, I've added the following features to this app

* Multiplayer
* Multiple AI
* Adjustable Game Settings
    * Change Starting money
    * Change count of Human Players
    * Change count of AI Players
    * Change total number of decks used
* Splitting
    * Available when card symbols match
* Double Down
    * Avaiable when starting hand totals 9, 10, or 11
* Split & Double Down
    * Avaiable when both cards in your starting hand are 5's
* Insurance
    * If the dealer's face up card is an Ace, make an optional side bet
* PNG of cards
* Money shown at all times
* Minor overall UI polish
* Some testing
    * We didn't use built in Ruby Testing in my previous positions, so I was playing around with these a bit.
* Continue a game you left while your session is still active in the Rails DB
