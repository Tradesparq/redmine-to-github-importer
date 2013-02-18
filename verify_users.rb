#!/usr/bin/ruby

require('github_api')

$USERNAME = ENV['GITHUB_USERNAME']
$REPO =  ENV['GITHUB_REPO']
$LOGIN = ENV['GITHUB_LOGIN']
PASSWORD = ENV['GITHUB_PASSWORD']

id_to_username = {
    1 => 'GITHUB_USER', # admin
    2 => 'GITHUB_USER', #anonymous
    3 => 'GITHUB_USER',
    4 => 'GITHUB_USER',
    5 => 'GITHUB_USER',
    6 => 'GITHUB_USER',
    7 => 'GITHUB_USER',
    8 => 'GITHUB_USER',
    9 => 'GITHUB_USER',
    10 => 'GITHUB_USER',
    11 => 'GITHUB_USER',
    12 => 'GITHUB_USER',
    13 => 'GITHUB_USER',
    14 => 'GITHUB_USER'
}

def verify_users(github, userhash)
    contributors = github.repos.contributors($USERNAME, $REPO)
    lookup_contributor = {}
    contributors.each do |contributor|
        puts contributor
        lookup_contributor[contributor['name']] = true
    end

    userhash.each_pair do |k,v|
        user = github.users.get user: v
        puts("Redmine id #{k} is #{user['id']}/#{user['name']}/#{v}")
        if lookup_contributor[v]
            puts("#{v} is a collaborator of #{$REPO}")
        else
            puts("#{v} is NOT a collaborator of #{$REPO}")
        end
    end
end

puts "github Login #{$LOGIN} to #{$USERNAME}/#{$REPO}"

github = Github.new login: $LOGIN, password: PASSWORD

verify_users(github, id_to_username)