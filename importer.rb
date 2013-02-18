#!/usr/bin/ruby

require 'yaml'
require 'mysql2'
require('github_api')

$USERNAME = ENV['GITHUB_USERNAME']
$REPO =  ENV['GITHUB_REPO']
$LOGIN = ENV['GITHUB_LOGIN']
PASSWORD = ENV['GITHUB_PASSWORD']
if ENV['GITHUB_TESTING'] == 'true'
    puts "TESTING MODE"
    $TESTING = true
else
    puts "PRODUCTION MODE"
    $TESTING = false
end

puts "github Login #{$LOGIN} to #{$USERNAME}/#{$REPO}"

github = Github.new login: $LOGIN, password: PASSWORD

def check_issue_number(issue_number, id)
    if issue_number != id
        errstr = "ERROR! Expected id #{id}, created as #{issue_number} instead"
        if not $TESTING
            raise errstr
        else
            puts errstr
        end
    end
end

def create_bug(github, username, repo, id, title, body, assignee, labels, state, milestone_number)
    puts "CREATE PARAMETERS"
    puts "id: #{id}"
    puts "title: #{title}"
    puts "body: \n---\n#{body}\n---\n"
    puts "assignee: #{assignee}"
    puts "labels: #{labels}"
    puts "milestone: #{milestone_number}"

    puts "EDIT PARAMETERS"
    puts "state: #{state}"

    if $TESTING and assignee
        puts "WARNING: Replacing assignee '#{assignee}' by #{$LOGIN}"
        assignee = "#{$LOGIN}"
    end

    create_params = {
      'title' => title,
      'body' => body,
      'assignee' => assignee,
      'milestone' => milestone_number,
      'labels' => labels
    }

    puts "Creation parameters:\n#{create_params}"
    ret = github.issues.create username, repo, create_params
    issue_id = ret['id']
    issue_number = ret['number']
    puts("Created #{issue_id} as #{issue_number}");

    edit_params = {
      'state' => state
    }

    ret = github.issues.edit username, repo, issue_number, edit_params
    puts("Bug link: #{ret['html_url']}");

    check_issue_number(issue_number, id)
end

def create_dummy(github, username, repo, id)
    create_params = {
      'title' => "Dummy bug for deleted redmine issue #{id}",
      'body' => 'This is to take into account gaps in the Redmine numbering of issues',
      'assignee' => $LOGIN,
      'labels' => []
    }

    puts "Creation parameters:\n#{create_params}"
    ret = github.issues.create username, repo, create_params
    issue_id = ret['id']
    issue_number = ret['number']
    puts("Created #{issue_id} as #{issue_number}");

    edit_params = {
      'state' => 'closed'
    }

    ret = github.issues.edit username, repo, issue_number, edit_params
    puts("Bug link: #{ret['html_url']}");

    check_issue_number(issue_number, id)
end

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

    return milestone_to_milestone_number
end

def get_milestone_to_milestone_number(github, username, repo, project_id_to_milestone)
    milestone_to_milestone_number = list_milestones github, username, repo

    project_id_to_milestone.each_pair do |k,v|
        if not milestone_to_milestone_number[v]
            puts "Creating #{v}"
            params = {
                'title' => v,
                'state' => 'open'
            }
            milestone = github.issues.milestones.create username, repo, params
            milestone_to_milestone_number[milestone['title']] = milestone['number']
        end
    end

    return milestone_to_milestone_number
end

def get_attachment_string(filename, disk_filename)
    value = "[#{filename}](https://github.com/Tradesparq/RedmineAttachments/blob/master/files/#{disk_filename})"
    return "\n\nattachment: #{value}"
end

def get_username_string_function(username_lookup, realname_lookup)
    return Proc.new { |id| "[#{realname_lookup[id]}](https://github.com/#{username_lookup[id]})" }
end



begin
    puts "GITHUB_LOGIN #{ENV['GITHUB_LOGIN']}"
    puts "GITHUB_PASSWORD #{ENV['GITHUB_PASSWORD']}"
    puts "GITHUB_USERNAME #{ENV['GITHUB_USERNAME']}"
    puts "GITHUB_REPO #{ENV['GITHUB_REPO']}"
    puts "GITHUB_TESTING #{ENV['GITHUB_TESTING']}"

    CONFIG = YAML.load_file("config.yml") unless defined? CONFIG

    puts "Hostname #{CONFIG['hostname']}"
    puts "Database #{CONFIG['database']}"
    puts "Username #{CONFIG['username']}"
    puts "Password #{CONFIG['password']}"

   client = Mysql2::Client.new(
        :host => CONFIG['hostname'],
        :database => CONFIG['database'],
        :username => CONFIG['username'],
        :password => CONFIG['password'],
        :port => CONFIG['hostport'],
        :encoding => "utf8"
    )


    users = client.query "SELECT * FROM users"
    id_to_realname = {}

    users.each do |user|
        id_to_realname[user['id']] = "#{user['firstname']} #{user['lastname']}"
    end

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

    get_username_string = get_username_string_function(id_to_username, id_to_realname)

    category_id_to_label = {
        1 => 'bug',
        2 => 'feature',
        3 => 'support'
    }

    tracker_id_to_label = {
        1 => 'bug',
        2 => 'feature',
        3 => 'support'
    }

    project_id_to_milestone = {
        1 => 'GITHUB_MILESTONE',
        2 => 'GITHUB_MILESTONE',
        3 => 'GITHUB_MILESTONE',
        4 => 'GITHUB_MILESTONE',
        5 => 'GITHUB_MILESTONE',
        6 => 'GITHUB_MILESTONE',
        7 => 'GITHUB_MILESTONE'
    }

    milestone_to_milestone_number = get_milestone_to_milestone_number(
        github, $USERNAME, $REPO, project_id_to_milestone)

    status_id_to_state = {
        1 => 'open', # New
        2 => 'open', # Assigned
        3 => 'closed', # Resolved
        4 => 'open', # Feedback
        5 => 'closed', # Closed
        6 => 'closed', # Rejected
        7 => 'closed' # Working
    }

    status_id_to_label = {
        1 => nil, # New
        2 => nil, # Assigned
        3 => nil, # Resolved
        4 => 'question', # Feedback
        5 => nil, # Closed
        6 => 'wontfix', # Rejected
        7 => 'testing' # Working
    }

    priority_id_to_label = {
        1 => nil,
        2 => nil,
        3 => "low",
        4 => nil, #"Normal",
        5 => "high",
        6 => "urgent",
        7 => "immediate",
    }

    priority_id_to_name = {
        1 => nil,
        2 => nil,
        3 => "Low",
        4 => "Normal",
        5 => "High",
        6 => "Urgent",
        7 => "Immediate",
    }

    issue_statuses = client.query 'SELECT * FROM issue_statuses'
    issues_status_id_to_name = {}
    issue_statuses.each do |issue_status|
        issues_status_id_to_name[issue_status['id']] = issue_status['name']
    end

    #puts client.get_server_info
    if ARGV[0]
        selected_issue_id = ARGV[0].to_i
        sequence_id = selected_issue_id
        if ARGV[1]
            to_range = ARGV[1].to_i
            puts "Range issue creation from #{selected_issue_id} to #{to_range} (non-inclusive)"
            issues = client.query "
                SELECT *
                FROM issues
                WHERE id >= #{selected_issue_id} AND id < #{to_range}
                ORDER BY id"
            expected_count = (to_range - selected_issue_id)
            actual_count = issues.count
            if actual_count != expected_count
                puts "WARNING: #{expected_count}, got #{actual_count} (gaps are present)"
            end
        else
            puts "Single issue creation: #{selected_issue_id}"
            issues = client.query "
                SELECT *
                FROM issues
                WHERE id = #{selected_issue_id}
                ORDER BY id"
        end
    else
        sequence_id = 1
        puts "ALL issue creation"
        issues = client.query "
            SELECT *
            FROM issues
            ORDER BY id"
        puts "selected #{issues.count} from Redmine for export to github"
    end


    issues.each do |issue|
        id = issue['id']
        if sequence_id > id
            raise "Expected #{sequence_id}, got #{id} instead"
        end
        # catch up to current id if necessary
        while id > sequence_id do
            create_dummy(github, $USERNAME, $REPO, sequence_id)
            sequence_id += 1
        end

        assignee = id_to_username[issue['assigned_to_id']]
        milestone_name = project_id_to_milestone[issue['project_id']]
        milestone_number = milestone_to_milestone_number[milestone_name]
        created_on = issue['created_on']
        title = issue['subject']
        description = issue['description']
        state = status_id_to_state[issue['status_id']]
        author = get_username_string.call(issue['author_id'])
        redmine_url = "http://192.168.11.252/redmine/issues/#{id}"
        body = "_ISSUE ORIGINALLY CREATED IN REDMINE AS [#{id}](#{redmine_url})_"
        body << "\n\n**#{created_on} (#{author})**"
        if description and description.strip().length > 0
            body << "\n```\n#{description}\n```"
        else
            body << "\nNo description provided"
        end
        labels = []

        attachments = client.query "SELECT * FROM attachments WHERE container_id = #{issue['id']}"
        attachments.each do |attachment|
            filename = attachment['filename']
            disk_filename = attachment['disk_filename']
            body << get_attachment_string(filename, disk_filename)
        end

        if category_id_to_label[issue['category_id']]
            labels.push(category_id_to_label[issue['category_id']])
        elsif tracker_id_to_label[issue['tracker_id']]
            labels.push(tracker_id_to_label[issue['tracker_id']])
        else
            labels.push('bug')
        end

        if status_id_to_label[issue['status_id']]
            labels.push(status_id_to_label[issue['status_id']])
        end

        #puts "DEBUG #{issue['priority_id']} #{priority_id_to_label[issue['priority_id']]}"
        if priority_id_to_label[issue['priority_id']]
            labels.push(priority_id_to_label[issue['priority_id']])
        end

        journals = client.query "
            SELECT * FROM journals
            WHERE journalized_id = #{issue['id']} AND journalized_type = 'Issue'"

        journals.each do |journal|
            created_on = journal['created_on']
            user = get_username_string.call(journal['user_id'])
            body << "\n\n**#{created_on} (#{user})**"

            notes = journal['notes']
            if notes and notes.strip().length() > 0
                puts "NOTES: '#{notes}'"
                body << "\n```\n#{notes}\n```\n"
            else
                puts "No notes available for change on #{created_on}"
            end

            details = client.query "
                SELECT * FROM journal_details WHERE journal_id = #{journal['id']}
            "
            details.each do |detail|
                property = detail['property']
                prop_key = detail['prop_key']
                display = prop_key
                old_value = detail['old_value']
                value = detail['value']
                case property
                when 'attr'
                    case prop_key
                    when 'status_id'
                        old_value = issues_status_id_to_name[old_value.to_i]
                        value = issues_status_id_to_name[value.to_i]
                        body << "\n_status: #{old_value} -> #{value}_"
                    when 'priority_id'
                        old_value = priority_id_to_name[old_value.to_i]
                        value = priority_id_to_name[value.to_i]
                        body << "\n_priority: #{old_value} -> #{value}_"
                    when 'assigned_to_id'
                        old_value = get_username_string.call(old_value.to_i)
                        value = get_username_string.call(value.to_i)
                        body << "\n_assigned_to: #{old_value} -> #{value}_"
                    when 'description'
                        # TODO: how do we go back and change original description?
                        body << "\n_description changed_\n#{value}"
                    when 'subject'
                        title = value
                        body << "\n_subject: #{old_value} -> #{value}_"
                    else
                        body << "\n_#{prop_key}: #{old_value} -> #{value}_"
                    end
                when 'attachment'
                    if value.is_a? String
                        attachments = client.query "SELECT * FROM attachments WHERE id = #{prop_key}"
                        if attachments.count > 0
                            attachments.each do |attachment|
                                filename = attachment['filename']
                                disk_filename = attachment['disk_filename']
                                body << get_attachment_string(filename, disk_filename)
                            end
                        else
                            body << "\n(changes to deleted attachment id #{prop_key})"
                        end
                    else
                        body << "\n(deletion of #{prop_key})"
                    end
                end
            end
        end

        changes = client.query "
            SELECT * FROM changesets_issues, changesets
            WHERE issue_id = #{issue['id']}
            AND changeset_id = changesets.id
            ORDER BY commit_date"

        changes.each do |change|
            scmid = change['scmid']
            commit_date = change['commit_date']
            comments = change['comments']
            body << "\n\n#{commit_date} changelist: #{scmid}"
            if comments and comments.strip().length > 0
                body << "\n```\n#{comments}\n```\n"
            end
        end

        create_bug(
            github,
            $USERNAME,
            $REPO,
            id,
            title,
            body,
            assignee,
            labels,
            state,
            milestone_number)
        puts "redmine_url: #{redmine_url}"
        sequence_id += 1
    end

rescue Mysql2::Error => e
    puts e.errno
    puts e.error
end
