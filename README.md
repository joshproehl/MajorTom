# MajorTom

## LunchBot
One of the goals is to replace/augment the LunchBot bot run by FLHerene on the EsperNet#SpaceX channel.
Lunchbot's command list is:
  {nextlunch,lunchmode,mission,outcome,stupid,colloid,colloid²,rocks,nextbankrupty,nextpinecone,nextyear,nextfire,nextbook,banlist,wenhop,help}

"!lunchmode" replies "Lunch mode enabled!" or "Lunch mode disabled!", depending on current mode, but doesn't seem to do anything else.
"!nextyear" should return the next calendar year, preferably not hard-coded to a specific year.


LunchBot stores its data as TXT files at https://www.flherne.uk/hacks/, with the filenames:
  * banned.txt
  * books.txt
  * colloids.txt
  * frogs.txt
  * lunches.txt
  * missions.txt
  * outcomes.txt
  * stupid.txt
We will attempt to provide the data in the same format, just in case anyone else is depending on it.

## Development
  * Set up dev database using docker, with `./scripts/devdb start`
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:11769`](http://localhost:11769) from your browser.

