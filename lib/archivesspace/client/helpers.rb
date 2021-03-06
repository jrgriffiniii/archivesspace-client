# needed for roundtrip hash merging
class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
end

module ArchivesSpace

  module Helpers

    def accessions(options = {})
      all('accessions', options)
    end

    def all(path, options = {})
      Enumerator.new do |yielder|
        page = 1
        unlimited_listing = false
        loop do
          result = get(path, options.merge(query: { page: page }))
          results = []

          if result.parsed.respond_to?(:key) && result.parsed.key?('results')
            results = result.parsed['results']
          else
            results = result.parsed
            unlimited_listing = true
          end

          if results.any?
            results.each do |i|
              yielder << i
            end
            raise StopIteration if unlimited_listing

            page += 1
          else
            raise StopIteration
          end
        end
      end.lazy
    end

    def backend_version
      get "version"
    end

    def batch_import(payload, params = {})
      # create "batch_import", payload, params
    end

    def digital_objects(options = {})
      all('digital_objects', options)
    end

    def groups(options = {})
      all('groups', options)
    end

    def group_user_assignment(users_with_roles, params = { with_members: true })
      updated = []
      groups.each do |group|
        changed = false

        users_with_roles.each do |user, roles|
          if roles.include? group["group_code"]
            unless group["member_usernames"].include? user
              group["member_usernames"] << user
              changed = true
            end
          else
            if group["member_usernames"].include? user
              group["member_usernames"].delete user
              changed = true
            end
          end
        end

        if changed
          id = group["uri"].split("/")[-1]
          response = post( "/groups/#{id}", group, params )
          updated << response.parsed
        end
      end
      updated
    end

    def login
      username, password = config.username, config.password
      result = request('POST', "/users/#{username}/login", { query: { password: password } })
      raise ConnectionError.new "Failed to connect to ArchivesSpace backend as #{username} #{password}" unless result.parsed["session"]
      @token = result.parsed["session"]
      self
    end

    def password_reset(username, password)
      user = all('users').find { |u| u["username"] == username }
      raise RequestError.new(user.status) unless user
      post(user["uri"], user, { password: password })
    end

    def repositories(options = {})
      all('repositories', options)
    end

    def repositories_with_agent
      #
    end

    def resources(options = {})
      all('resources', options)
    end

    def search(params)
      # get "search", params
    end

    def users(options = {})
      all('users', options)
    end

  end

end
