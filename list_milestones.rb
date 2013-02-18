#!/usr/bin/ruby

require('github_api')

$USERNAME = 'GITHUB_ORG_NAME'
$REPO = 'GITHUB_REPO'

LOGIN = 'GITHUB_USER'
PASSWORD = ENV['GITHUB_PASSWORD']
github = Github.new login: LOGIN, password: PASSWORD

def convert_to_hash(milestones, milestone_to_milestone_number)
    milestones.each do |milestone|
        puts "found #{milestone['title']} id: #{milestone['id']}, number: #{milestone['number']}"
        milestone_to_milestone_number[milestone['title']] = milestone['number']
    end

end

def list_milestones(github, username, repo)
    milestone_to_milestone_number = {}

    milestones_open = github.issues.milestones.list username, repo, {
        'state' => 'open'
    }

    milestones_closed = github.issues.milestones.list username, repo, {
        'state' => 'closed'
    }

    convert_to_hash(milestones_open, milestone_to_milestone_number)
    convert_to_hash(milestones_closed, milestone_to_milestone_number)
end

list_milestones github, $USERNAME, $REPO