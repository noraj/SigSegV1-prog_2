# IRC Bot

## Version

Date        | Author                  | Contact               | Version | Comment
---         | ---                     | ---                   | ---     | ---
16/08/2018  | noraj (Alexandre ZANNI) | noraj#0833 on discord | 1.0     | Document creation

## Information

Information displayed for CTF players:

+ **Name of the challenge**: `Sensory Domination Droid`
+ **Category**: `Programming`
+ **Internet**: internet connection required for part 3
+ **Difficulty**: easy

### Description

Don't forget to change the IP address in the description by the one used by the docker engine.

```
Hi human,

I'm Apox, a bot from Sensory Domination Droid.

You'll never find my secret!

Humans are so slow, humans can't get the flag!

I pity you, here are some leads:

    - IP address: x.x.x.x
    - Port: 6667 (clear) / 6697 (TLS)
    - Channel: #chall
    - Bot name: Apox
    - Help command: !help
```

### Hint

This challenge is easy and does not require to find anything so not hint are given.

## Integration

This challenge require a Docker Engine and Docker Compose. (Contact author if you plan to use it in another way).

Builds, (re)creates, starts, and attaches to containers for a service:

```
$ docker-compose up --build bot
```

Add `-d` if you want to detach the container.

The challenge is using the following images:

- inspircd/inspircd-docker
- ruby:2.5-alpine

## Solving

This challenge includes 3 parts.

To solve this challenge, writing an IRC bot or client is necessary.
In my solution I used Cinch (a ruby IRC bot framework).

**Part 1**:

Player receives the md5 hash of a (random) password to crack in less than 3 sec.

`xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx` format is for avoid player to copy/paste it in a cracking website, forcing him to use an API or launching a process.

Way to solve: web API or hashcat, john the ripper, findmyhash, rainbow table in a process.

Example:

```
<noraj> !part1
<Apox> Hi noraj
<Apox> Crack this md5 hash: f6:79:ca:12:93:f3:18:86:0d:f9:d5:b9:66:e6:fa:c0, you have 3 seconds to answer
<Apox> Time's up!
```

What is learned here: use IRC, script, use regex, raise awareness among the easiness of cracking a md5 hashed password.

**Part 2**:

Player receives a message encrypted with camelia256 (encrypted message + key + IV).

Way to solve: any crypto lib in any scripting language.

Example:

```
<noraj> !part2
<Apox> Hi noraj
<Apox> Decipher this, you have 3 seconds to answer
<Apox> cipher: camellia256
<Apox> key: rWJdoZEpRcVNejpguBPCNwpN7E46hyTcHCzdselSYhw=
<Apox> iv: iVjkiV6Hao4d2yqpwkCvkQ==
<Apox> encrypted: Ob7/oPwWBjF+pBwllOt88g==
<Apox> Time's up!
```

What is learned here: there is not only USA algorithm like RSA and AES in the world, a lot of crypto lib support other algorithms; script, use regex, raise awareness among the easiness of ciphering data.

**Part 3**:

Players receive a password and need to send the number of times this password has been pwned, using Pwned Passwords by Troy Hunt.

Way to solve: using HIBP API directly or via a wrapper.

Example:

```
<noraj> !part3
<Apox> Hi noraj
<Apox> Give me the number of times this password: excalibu, has been pwned using Pwned Passwords by Troy Hunt
```

What is learned here: script, use regex, use API, raise awareness among the easiness of using an API and checking if a password has been pwn.

### Author solution

I made an IRC bot with Cinch framework. The solver bot will act like a C&C server.

The player will send a command `send_bot 1` to his solver bot, his solver bot will send `!part1` to the challenge bot, receives the challenge data, do what need to be done, then send the answer to the challenge bot by sending `!part1 -ans answer`, then the challenge bot will validate the answer and send the first part of the flag to the solver bot, the solver bot will then forward the flag to the player.

Same thing for part 2 and 3. At the end the player have the complete flag. It is also possible to code an IRC client rather than a bot an process inputs directly.

Player needs to try the commands manually first to see what data is being sent and what inputs are expected.

```ruby
#!/usr/bin/env ruby

# Author: noraj
# Author website: https://rawsec.ml

require 'cinch' # gem install cinch
require 'openssl'
require 'base64'
require 'curb' # gem install curb
require 'pwned' # gem install pwned

bot = Cinch::Bot.new do |boti|
    configure do |c|
        c.server   = "172.17.0.1"
        c.nick     = "noraj_501v3r"
        c.channels = ["#chall"]
    end

    # be ready to talk to noraj_bot
    challbot  = Cinch::Target.new("Apox", boti)
    # be ready to talk to you, to get flag back
    player  = Cinch::Target.new("noraj", boti)

    # run bot, example for challenge 1: "send_bot 1"
    on :private, /^send_bot ([0-9])/ do |m, num|
        challbot.send("!part#{num}")
    end

    # solving challenge part 1
    on :private, /^Crack this md5 hash: ((?:[a-f0-9]{2}:){15}[a-f0-9]{2}), you have [0-9]+ seconds to answer$/ do |m, md5_hash|
        # removing ':'
        md5_hash.gsub!(':', '')
        # request to hashes.org API, limited to 20 requests/min and need an account
        key = "CENSORED"
        hostname = "https://hashes.org/api.php?act=REQUEST&key=#{key}&hash=#{md5_hash}"
        c = Curl::Easy.new(hostname) do |curl|
            curl.headers['Referer'] = 'https://hashes.org/'
        end
        c.perform
        # result looks like {"REQUEST":"FOUND", "e252a5167841b3d3a28e9030615964fa": {"plain":"tango","hexplain":"74616e676f","algorithm":"MD5PLAIN"}}
        answer = c.body_str.match(/"plain":"(.*)","hex/).captures[0]
        m.reply "!part1 -ans #{answer}"
    end

    # solving challenge part 2
    # Global variables, let them empty
    c2_key = ""
    c2_iv = ""

    on :private, /^key: ((?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?)/ do |m, k|
        c2_key = Base64.decode64(k)
    end

    on :private, /^iv: ((?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?)/ do |m, i|
        c2_iv = Base64.decode64(i)
    end

    on :private, /^encrypted: ((?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?)/ do |m, e|
        c2_encrypted = Base64.decode64(e)
        # init cipher
        decipher = OpenSSL::Cipher.new('camellia256')
        decipher.decrypt
        # decipher password
        sleep(0.5) if c2_key == ""
        decipher.key = c2_key
        sleep(0.5) if c2_iv == ""
        decipher.iv = c2_iv
        passwd = decipher.update(c2_encrypted) + decipher.final
        m.reply "!part2 -ans #{passwd}"
    end

    # solving challenge part 3
    on :private, /^Give me the number of times this password: (.*), has been pwned using Pwned Passwords by Troy Hunt$/ do |m, pwd|
        passwdcheck = Pwned::Password.new(pwd, { 'User-Agent' => 'SIGSEGV1-CTF-irc-challenge-password-pwn-count' })
        m.reply "!part3 -ans #{passwdcheck.pwned_count}"
    end

    # sending the flag back to player
    on :private, /flag/i do |m|
        player.send(m.message)
    end
end

bot.start
```

## Flag

+ **Complete flag**: `SIGSEGV1{pr073c7_y0ur_p455w0rd5_ch4n63_17_0f73n_4nd_d0n7_u53_br0k3n_4l60r17hm}`
  - **Part 1**: `SIGSEGV1{pr073c7_y0ur_p455`
  - **Part 2**: `w0rd5_ch4n63_17_0f73n_4nd_`
  - **Part 3**: `d0n7_u53_br0k3n_4l60r17hm}`

```
$ printf %s 'SIGSEGV1{pr073c7_y0ur_p455w0rd5_ch4n63_17_0f73n_4nd_d0n7_u53_br0k3n_4l60r17hm}' | md5sum 
7acc0dbd59a977e843b5d309dd2b8d22  -

$ printf %s 'SIGSEGV1{pr073c7_y0ur_p455w0rd5_ch4n63_17_0f73n_4nd_d0n7_u53_br0k3n_4l60r17hm}' | sha1sum 
f2c3d69a52d9d35aa6b3aff22595fadc3697ad6c  -

$ printf %s 'SIGSEGV1{pr073c7_y0ur_p455w0rd5_ch4n63_17_0f73n_4nd_d0n7_u53_br0k3n_4l60r17hm}' | sha256sum 
96ca83ae6c082f54efde9b425d3e111a9fedfeb7b15ccf4806b3aee7e97d52cd  -

$ printf %s 'SIGSEGV1{pr073c7_y0ur_p455w0rd5_ch4n63_17_0f73n_4nd_d0n7_u53_br0k3n_4l60r17hm}' | b2sum 
b802d3a60d0f7cb47de999cf01a11e8e8e1700cb8e3778f4d3c06a3f749822862631de3f38a88f06f7ae50735ae84d6ab8123b2b0fe9b88c6291fc89697b2a3a  -
```