# frozen_string_literal: true

namespace :leaf_addons do
  desc "Make users administrators in Hyku. Supply a space separated list, eg ['person1@example.com person2@example.com']."
  task :make_me_admin, [:email] => [:environment] do |_t, args|
    if args[:email].nil?
      puts 'Supply a space separated list of email addresses, like this'
      puts "rake leaf_addons:make_me_admin['person1@example.com person2@example.com']"
    else
      args[:email].split(' ').each do |admin|
        make_admin(admin) if validate_email(admin)
      end
    end
  end

  desc "Create an admin user: leaf_addons[email, password]"
  task :create_admin_user, [:email, :password] => :environment do |_task, args|
    User.where(email: args[:email]).first_or_create!(password: args[:password]) if validate_email(invite)
    make_admin(args[:email]) if validate_email(invite)
  end

  desc "Create a user: leaf_addons[email, password]"
  task :create_user, [:email, :password] => :environment do |_task, args|
    User.where(email: args[:email]).first_or_create!(password: args[:password]) if validate_email(invite)
  end

  desc "Invite a single user with no frills (no display name, no admin). Supply a space separated list, eg ['person1@example.com person2@example.com']."
  task :invite_user, [:email] => [:environment] do |_t, args|
    if args[:email].nil?
      puts 'Supply a space separated list of email addresses, like this'
      puts "rake leaf_addons:invite_users['person1@example.com person2@example.com']"
    else
      args[:email].split(' ').each do |invite|
        invite_user(invite) if validate_email(invite)
      end
    end
  end

  desc "Invite users to a Hyku given in the supplied csv file_path. The csv must contain a header row and three columns: " \
        "email, display name, admin. The admin column should contain the word true if the user" \
        "should be made an administrator."
  task :invite_users, [:path] => [:environment] do |_t, args|
    if args[:path].nil?
      puts 'Supply the path to a csv file, like this'
      puts "rake leaf_addons:invite_users['/tmp/my_file.csv']"
      puts "the CSV file must contain a header row and three columns: email, display name, admin"
      puts "the admin column should contain the word true to indicate that the given user should be an admin"
    else
      begin
        process_user_csv(args[:path])
      rescue
        puts "The file, #{args[:path]}, does not exist or is invalid, please check the path is correct and make " \
        "sure the file is in the right format (comma separated)"
      end
    end
  end

  # Make the user an administrator. Works with Rolify (Hyku) and hydra-role-management.
  #
  # @param email [String] email address for the admin
  def make_admin(email)
    user = User.find_by(email: email.downcase)
    if user.nil?
      puts "#{email} doesn't have a user account so cannot be made an admin."
    else
      if user.respond_to?(:add_role)
        user.add_role :admin
      else
        admin = Role.create(name: "admin")
        # if the role already exists, admin will be nil
        admin = Role.find_by(name: 'admin') if admin.id.nil?
        admin.users << user
        admin.save
      end
      puts "#{email} is now an admin."
    end
  end

  # Send an email invitation to the given user
  #
  # @param email [String] email address for the new user
  # @param display_name [String] display name for the new user
  # @param admin [Boolean] true if the new user should be made an admin
  def invite_user(email, name = nil, admin = false)
    display_name = name ? name : "User"
    if User.find_by(email: email).nil?
      user = User.invite!(email: email, display_name: display_name)
      user.add_role :admin if admin
      puts "#{email} was sent an email invitation and was#{admin ? '' : ' not'} made an admin"
    else
      puts "#{email} is already a user"
    end
  end

  # Read the csv and process each line
  #
  # @param csv [String] the path to a csv file
  def process_user_csv(csv)
    users = CSV.read(csv)
    users.shift # skip header row
    users.each do |line|
      process_user_line(line)
    end
  end

  # Process a single line from the users csv
  #
  # @param line [Array] an array of data from the users csv
  def process_user_line(line)
    return if line.blank?
    name = line[1].nil? ? nil : line[1].strip
    admin = true unless line[2].nil? && line[2] != "true"
    invite_user(line[0].downcase.strip, name, admin) if validate_email(line[0])
  end

  # Check that the email is valid (ie. that it contains '@')
  #
  # @param email [String] the email
  def validate_email(email)
    if email.include? '@'
      true
    else
      puts "#{email} is not a valid email address, please check your data"
      false
    end
  end
end
