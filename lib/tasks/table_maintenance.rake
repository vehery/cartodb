namespace :cartodb do
  namespace :tables do
    namespace :maintenance do
      def ask_for_confirmation(key = 'continue')
        puts "\nType '#{key}' to proceed or anything else to abort:"

        raise 'user aborted' unless STDIN.gets.strip == key
      end

      desc "Sync user's UserTable(s)' table_id(s) with their corresponding physical table's oid"
      task :sync_user_table_oids, [:username] => :environment do |_, args|
        raise 'A username must be provided' unless args[:username].present?

        user = ::User.where(username: args[:username]).first

        raise "No user with username '#{args[:username]}' found" if user.nil?

        user_tables = user.tables.all

        unsynced_user_tables = user_tables.reject do |user_table|
          user_table.table_id != user_table.service.fetch_table_id
        end

        user_tables_count = unsynced_user_tables.count
        puts "#{user_tables_count} #{'table'.pluralize(user_tables_count)} will be processed, see a list below:"

        unsynced_user_tables.each do |user_table|
          puts "\t'#{user_table.name}'"
        end

        ask_for_confirmation('c')

        synced_tables = 0
        errored_tables = 0

        unsynced_user_tables.each do |user_table|
          printf "\tSynching '#{user_table.name}'... \r"

          user_table.sync_table_id

          if user_table.save
            printf "\tSynching '#{user_table.name}'... ok\n"
            synced_tables += 1
          else
            printf "\tSynching '#{user_table.name}'... ok\n"
            errored_tables += 1

            puts "ATENTION: errored save for table '#{user_table.name}':"
            puts user_table.errors.full_messages

            ask_for_confirmation
          end
        end

        puts "\n#{user_tables_count} #{'table'.pluralize(user_tables_count)} processed"
        puts "\t#{synced_tables} #{'table'.pluralize(synced_tables)} synced"
        puts "\t#{errored_tables} #{'table'.pluralize(errored_tables)} errored"
      end
    end
  end
end
