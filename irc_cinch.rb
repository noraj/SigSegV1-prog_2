# Author: noraj
# Author website: https://rawsec.ml

require 'cinch' # gem install cinch
require 'digest'
require 'openssl'
require 'base64'
require 'pwned' # gem install pwned

def flag_part(num)
  flag = 'sigsegv{pr073c7_y0ur_p455w0rd5_ch4n63_17_0f73n_4nd_d0n7_u53_br0k3n_4l60r17hm}'
  # Flag part size
  fps = flag.size / 3
  case num
  when 1
    flag[0...fps]
  when 2
    flag[fps...2*fps]
  when 3
    flag[2*fps..(-1)]
  end
  # flag_part(1)+flag_part(2)+flag_part(3) == flag => true
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = ARGV[0].to_s
    c.nick     = "Apox"
    c.channels = ["#chall"]
  end

  # Global variables, let them empty
  challenge1_answer = ""
  challenge2_answer = ""
  challenge3_answer = ""

  on :private, /^!part1$/ do |m|
    m.reply "Hi #{m.user.nick}"
    # Random integer between 1 and 10000
    prng = Random.new
    rand_int = prng.rand(1..10000)
    # Pick random password
    passwd = IO.readlines('10k_most_common.txt')[rand_int].chomp
    #Save clear password in gobal variable
    challenge1_answer = passwd
    # get hex value of the md5 hash of the password
    hash = Digest::MD5.hexdigest passwd
    # Insert a colon `:` every to char to get it more difficult to copy/paste manually
    hash = hash.scan(/.{1,2}/).join(':')
    m.reply "Crack this md5 hash: #{hash}, you have 3 seconds to answer"
    Timer(3, {shots: 1}) { m.reply "Time's up!"
                            challenge1_answer = "" }
  end

  on :private, /^!part1 -ans (.*)/ do |m, ans|
    if ans == challenge1_answer and not ans.empty?
      m.reply 'Part 1 of the Flag: ' + flag_part(1)
    else
      m.reply 'Too late or bad answer'
    end
  end

  on :private, /^!part2$/ do |m|
    m.reply "Hi #{m.user.nick}"
    m.reply 'Decipher this, you have 3 seconds to answer'
    # random password
    prng = Random.new
    rand_int = prng.rand(1..10000)
    passwd = IO.readlines('10k_most_common.txt')[rand_int].chomp
    # Save clear password in gobal variable
    challenge2_answer = passwd
    # init cipher
    cipher = OpenSSL::Cipher.new('camellia256')
    cipher.encrypt
    key = cipher.random_key
    iv = cipher.random_iv
    # cipher password
    encrypted = cipher.update(passwd) + cipher.final
    m.reply 'cipher: camellia256'
    m.reply "key: #{Base64.encode64(key)}"
    m.reply "iv: #{Base64.encode64(iv)}"
    m.reply "encrypted: #{Base64.encode64(encrypted)}"
    Timer(3, {shots: 1}) { m.reply "Time's up!"
                            challenge2_answer = "" }
  end

  on :private, /^!part2 -ans (.*)/ do |m, ans|
    if ans == challenge2_answer and not ans.empty?
      m.reply 'Part 2 of the Flag: ' + flag_part(2)
    else
      m.reply 'Too late or bad answer'
    end
  end

  on :private, /^!part3$/ do |m|
    m.reply "Hi #{m.user.nick}"
    # random password
    prng = Random.new
    rand_int = prng.rand(1..10000)
    passwd = IO.readlines('10k_most_common.txt')[rand_int].chomp
    m.reply "Give me the number of times this password: #{passwd}, has been pwned using Pwned Passwords by Troy Hunt"
    # Check password pwnage count
    passwdcheck = Pwned::Password.new(passwd, { 'User-Agent' => 'SIGSEGV1-CTF-irc-challenge-password-pwn-count' })
    # Save password pwnage count in gobal variable
    challenge3_answer = passwdcheck.pwned_count.to_s
    Timer(3, {shots: 1}) { m.reply "Time's up!"
                            challenge3_answer = "" }
  end

  on :private, /^!part3 -ans ([0-9]*)/ do |m, ans|
    if ans == challenge3_answer and not ans.empty?
      m.reply 'Part 3 of the Flag: ' + flag_part(3)
    else
      m.reply 'Too late or bad answer'
    end
  end

  on :private, /^!credit$/ do |m|
    m.reply 'Challenge: IRC Bot'
    m.reply 'Author: noraj from rawsec'
    m.reply 'Author website: rawsec.ml'
  end

  on :private, /^!help$/ do |m|
    m.reply 'List of available commands:'
    m.reply '!help => Display this help message'
    m.reply '!credit => Display challenge credit'
    m.reply '!part1 => Launch part 1 of the challenge'
    m.reply '!part1 -ans your_answer => Send your answer for part 1 of the challenge'
    m.reply '!part2 => Launch part 2 of the challenge'
    m.reply '!part2 -ans your_answer => Send your answer for part 2 of the challenge'
    m.reply '!part3 => Launch part 3 of the challenge'
    m.reply '!part3 -ans your_answer => Send your answer for part 3 of the challenge'
  end
end

bot.start
