module Lita
  module Handlers
    class Doc < Handler
      COMMANDS = {
        how: {
          regex: /^how do i +([^\?]+)\??$/,
          command: "how do i [do thing]",
          description: "Shows where to find doc."
        },
        show: {
          regex: /^doc +(.+)$/,
          command: "doc [name]",
          description: "Shows where to find doc."
        },
        remove: {
          regex: /^doc:remove +(.+)$/,
          command: "docs:remove [name]",
          description: "Remove doc."
        },
        list: {
          regex: /^docs(:all)?$/,
          command: "docs:all",
          description: "Lists all known docs."
        },
        help: {
          regex: /^docs[: ]help/,
          command: "docs help OR docs:help",
          description: "Shows all doc commands."
        },
        add: {
          regex: /^doc:new (.+) (http:\/\/.+)$/,
          command: "doc:new [name] [url]",
          description: "Adds doc."
        },
        wtf: {
          regex: /^docs ((?!help).)*$/
        }
      }

      def self.regex_for(name)
        COMMANDS[name][:regex]
      end

      def self.help_for(name)
        { COMMANDS[name][:command] => COMMANDS[name][:description] }
      end

      route(regex_for(:help),   :help,        command: false, help: help_for(:help))
      route(regex_for(:list),   :list_docs,   command: false, help: help_for(:list))
      route(regex_for(:remove), :remove_doc,  command: false, help: help_for(:remove))
      route(regex_for(:show),   :show_doc,    command: false, help: help_for(:show))
      route(regex_for(:how),    :show_doc,    command: false, help: help_for(:how))
      route(regex_for(:add),    :add_doc,     command: false, help: help_for(:add))
      route(regex_for(:wtf),    :wtf?,        command: false)

      def help(response)
        msg = "```\n"
        COMMANDS.each do |key, value|
          msg += "#{value[:command]} - #{value[:description]}\n" if value[:command]
        end
        msg += "```"
        response.reply msg
      end

      def show_doc(response)
        name  = response.match_data[1].strip
        res   = redis.get name

        if res
          response.reply "Go to #{res} to find out."
        else
          response.reply "I don't know where to find that information. Figure it out for me, then add it to my memory please: .doc:add #{name} [destination_url]"
        end
      end

      def list_docs(response)
        docs = doc_names
        msg = ""
        if docs.empty?
          response.reply "No docs found."
        else
          docs.each do |doc|
            msg += "`#{doc}` - #{redis.get doc}\n"
          end
          response.reply msg
        end

      end

      def add_doc(response)
        name      = response.match_data[1].strip
        location  = response.match_data[2].strip
        if name && location
          redis.rpush :docs, name
          redis.set name, location
          response.reply "Sweet, added #{name} to docs list."
        else
          response.reply "Looks like you did something wrong, please input in the form `.doc:add [doc explanation] [doc_url]`. Note: doc_url must begin with `http://`"
        end
      end

      def remove_doc(response)
        name = response.match_data[1].strip
        if doc_names.include?(name)
          redis.lrem :docs, 0, name
          redis.del name
          response.reply "Boom! Removed #{name} from docs list."
        else
          response.reply "I don't have any information for #{name}, so... mission accomplished?"
        end
      end

      def wtf?(response)
        response.reply "I don't know what you mean. Have you been drinking? Try `.docs:help`"
      end

      def doc_names
        redis.lrange :docs, 0, -1
      end

      Lita.register_handler(self)
    end
  end
end
